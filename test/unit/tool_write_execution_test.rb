# frozen_string_literal: true

# Redmine MCP plugin
#
# Copyright (C) 2026 RK Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require File.expand_path('../test_helper', __dir__)

class RedmineMcpToolWriteExecutionTest < RedmineMcpTestCase
  PUBLIC_EDIT_NOTES = 'Public edit'
  fixtures :users, :email_addresses, :user_preferences, :projects, :issues, :members, :member_roles,
           :roles, :trackers, :issue_statuses, :enumerations, :enabled_modules, :versions, :wikis,
           :wiki_pages, :wiki_contents, :issue_categories, :issue_relations, :time_entries, :journals,
           :watchers

  def setup
    super
    @admin = User.find(1)
  end

  test 'create_time_entry creates entry for project' do
    before = TimeEntry.count
    payload = invoke_mcp_tool(
      'create_time_entry',
      user: @admin,
      args: {project: 'ecookbook', hours: 1.5, comments: 'mcp project time'}
    )

    assert_mcp_ok(payload)
    assert_equal before + 1, TimeEntry.count
    assert_in_delta(1.5, payload.dig(:data, :hours))
    assert_equal 1, payload.dig(:data, :user, :id)
    assert_nil payload.dig(:data, :issue)
  end

  test 'create_time_entry creates entry for issue' do
    issue = Issue.find(1)
    before = TimeEntry.count
    payload = invoke_mcp_tool(
      'create_time_entry',
      user: @admin,
      args: {issue_id: issue.id, hours: 0.5, comments: 'mcp issue time'}
    )

    assert_mcp_ok(payload)
    assert_equal before + 1, TimeEntry.count
    assert_equal issue.id, payload.dig(:data, :issue, :id)
  end

  test 'create_time_entry retries with the same idempotency_key' do
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    args = {project: 'ecookbook', hours: 1.25, comments: 'idempotent time', idempotency_key: 'time-key-123'}
    first = invoke_mcp_tool('create_time_entry', user: @admin, args: args)
    count = TimeEntry.count

    second = invoke_mcp_tool('create_time_entry', user: @admin, args: args)

    assert_mcp_ok(first)
    assert_mcp_ok(second)
    assert_equal(first.dig(:data, :id), second.dig(:data, :id))
    assert_equal(count, TimeEntry.count)

    conflicted = invoke_mcp_tool(
      'create_time_entry',
      user: @admin,
      args: {project: 'ecookbook', hours: 2.0, comments: 'idempotent time', idempotency_key: 'time-key-123'}
    )

    assert_equal(false, conflicted[:ok])
    assert_equal('CONFLICT', conflicted.dig(:error, :code))
    assert_equal(count, TimeEntry.count)
  ensure
    Rails.cache = previous_cache
  end

  test 'update_time_entry updates hours' do
    entry = TimeEntry.find(1)
    payload = invoke_mcp_tool(
      'update_time_entry',
      user: @admin,
      args: {time_entry_id: entry.id, hours: 2.0, comments: 'updated by mcp'}
    )

    assert_mcp_ok(payload)
    assert_in_delta(2.0, payload.dig(:data, :hours))
    assert_equal 'updated by mcp', payload.dig(:data, :comments)
  end

  test 'import_time_entries creates entries' do
    before = TimeEntry.count
    payload = invoke_mcp_tool(
      'import_time_entries',
      user: @admin,
      args: {
        entries: [
          {project: 'ecookbook', hours: 1.0, comments: 'import one'},
          {issue_id: 1, hours: 0.25, comments: 'import two'},
        ]
      }
    )

    assert_mcp_ok(payload)
    assert_equal 2, payload.dig(:data, :succeeded)
    assert_equal 0, payload.dig(:data, :failed)
    assert_equal before + 2, TimeEntry.count
  end

  test 'create_issue creates issue' do
    before = Issue.count
    payload = invoke_mcp_tool(
      'create_issue',
      user: @admin,
      args: {project: 'ecookbook', subject: 'MCP write create issue', tracker_id: 1, status_id: 1}
    )

    assert_mcp_ok(payload)
    assert_equal before + 1, Issue.count
    assert_equal 'MCP write create issue', payload.dig(:data, :subject)
  end

  test 'update_issue updates subject' do
    issue = Issue.find(1)
    payload = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {issue_id: issue.id, subject: 'MCP updated subject'}
    )

    assert_mcp_ok(payload)
    assert_equal 'MCP updated subject', payload.dig(:data, :subject)
  end

  test 'update_issue rejects notes and watcher fields' do
    payload = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {issue_id: 1, watcher_user_ids: [3]}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'update_issue rejects a disabled core field' do
    tracker = Tracker.find(1)
    original_fields = tracker.core_fields
    tracker.core_fields = original_fields - ['due_date']
    tracker.save!

    payload = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {issue_id: 1, due_date: '2026-12-31'}
    )

    assert_equal(false, payload[:ok])
    assert_includes(Array(payload.dig(:error, :details, :rejected_fields)), 'due_date')
  ensure
    tracker.core_fields = original_fields
    tracker.save!
  end

  test 'add_issue_note adds a comment without changing attributes' do
    issue = Issue.find(1)
    subject = issue.subject
    payload = invoke_mcp_tool(
      'add_issue_note',
      user: @admin,
      args: {issue_id: issue.id, notes: 'MCP comment'}
    )

    assert_mcp_ok(payload)
    assert_equal issue.id, payload.dig(:data, :issue_id)
    assert payload.dig(:data, :journal_id)
    assert_equal 'MCP comment', payload.dig(:data, :notes)
    assert_equal subject, issue.reload.subject
  end

  test 'add_issue_note is allowed without edit_issues' do
    role = Role.generate!(permissions: %i[view_issues add_issue_notes])
    user = User.generate!
    User.add_to_project(user, Project.find(1), role)

    payload = invoke_mcp_tool(
      'add_issue_note',
      user: user,
      args: {issue_id: 1, notes: 'Notes only'}
    )

    assert_mcp_ok(payload)
    assert_equal 'Notes only', payload.dig(:data, :notes)
  end

  test 'add_issue_note private_notes requires set_notes_private' do
    role = Role.generate!(permissions: %i[view_issues add_issue_notes])
    user = User.generate!
    User.add_to_project(user, Project.find(1), role)

    payload = invoke_mcp_tool(
      'add_issue_note',
      user: user,
      args: {issue_id: 1, notes: 'Secret', private_notes: true}
    )

    assert_equal false, payload[:ok]
    assert_equal 'FORBIDDEN', payload.dig(:error, :code)
  end

  test 'add_issue_note retries with the same idempotency_key' do
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    args = {issue_id: 1, notes: 'Idempotent note', idempotency_key: 'note-key-123'}
    first = invoke_mcp_tool('add_issue_note', user: @admin, args: args)
    count = Journal.where(journalized_type: 'Issue', journalized_id: 1).count

    second = invoke_mcp_tool('add_issue_note', user: @admin, args: args)

    assert_mcp_ok(first)
    assert_mcp_ok(second)
    assert_equal(first.dig(:data, :journal_id), second.dig(:data, :journal_id))
    assert_equal(count, Journal.where(journalized_type: 'Issue', journalized_id: 1).count)

    conflicted = invoke_mcp_tool(
      'add_issue_note',
      user: @admin,
      args: {issue_id: 1, notes: 'Different note', idempotency_key: 'note-key-123'}
    )

    assert_equal(false, conflicted[:ok])
    assert_equal('CONFLICT', conflicted.dig(:error, :code))
    assert_equal(count, Journal.where(journalized_type: 'Issue', journalized_id: 1).count)
  ensure
    Rails.cache = previous_cache
  end

  test 'add_issue_note attaches uploads in the same call' do
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    before = Attachment.count
    args = {
      issue_id: 1,
      notes: 'Report attached',
      uploads: [{filename: 'report.txt', content_base64: Base64.strict_encode64('report')}],
      idempotency_key: 'note-upload-key-1'
    }

    first = invoke_mcp_tool('add_issue_note', user: @admin, args: args)
    second = invoke_mcp_tool('add_issue_note', user: @admin, args: args)

    assert_mcp_ok(first)
    assert_mcp_ok(second)
    assert_equal(first.dig(:data, :journal_id), second.dig(:data, :journal_id))
    assert_equal(before + 1, Attachment.count)
    assert_equal(1, Array(first.dig(:data, :added_attachments)).size)
  ensure
    Rails.cache = previous_cache
  end

  test 'update_issue uploads retries with the same idempotency_key' do
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    before = Attachment.count
    args = {
      issue_id: 1,
      uploads: [{filename: 'update.txt', content_base64: Base64.strict_encode64('update')}],
      idempotency_key: 'update-upload-key-1'
    }

    first = invoke_mcp_tool('update_issue', user: @admin, args: args)
    second = invoke_mcp_tool('update_issue', user: @admin, args: args)
    conflicted = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {
        issue_id: 1,
        uploads: [{filename: 'other.txt', content_base64: Base64.strict_encode64('other')}],
        idempotency_key: 'update-upload-key-1'
      }
    )

    assert_mcp_ok(first)
    assert_mcp_ok(second)
    assert_equal(first.dig(:data, :journal_id), second.dig(:data, :journal_id))
    assert_equal(before + 1, Attachment.count)
    assert_equal(1, Array(first.dig(:data, :added_attachments)).size)
    assert_equal(false, conflicted[:ok])
    assert_equal('CONFLICT', conflicted.dig(:error, :code))
  ensure
    Rails.cache = previous_cache
  end

  test 'update_issue rejects invalid upload base64' do
    payload = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {issue_id: 1, uploads: [{filename: 'bad.txt', content_base64: '%%%'}]}
    )

    assert_equal false, payload[:ok]
  end

  test 'update_issue clears assigned_to_id with null' do
    issue = Issue.find(2)
    issue.update!(assigned_to_id: 3)

    payload = invoke_mcp_tool(
      'update_issue',
      user: @admin,
      args: {issue_id: issue.id, assigned_to_id: nil}
    )

    assert_mcp_ok(payload)
    assert_nil issue.reload.assigned_to_id
  end

  test 'update_issue uploads without edit_issues' do
    role = Role.generate!(permissions: %i[view_issues add_issue_notes])
    user = User.generate!
    User.add_to_project(user, Project.find(1), role)
    before = Attachment.count

    payload = invoke_mcp_tool(
      'update_issue',
      user: user,
      args: {
        issue_id: 1,
        uploads: [{filename: 'note.txt', content_base64: Base64.strict_encode64('hello')}]
      }
    )

    assert_mcp_ok(payload)
    assert_equal before + 1, Attachment.count

    denied = invoke_mcp_tool(
      'update_issue',
      user: user,
      args: {issue_id: 1, subject: 'Should be forbidden'}
    )

    assert_equal false, denied[:ok]
    assert_equal 'FORBIDDEN', denied.dig(:error, :code)
  end

  test 'copy_issue copies issue' do
    before = Issue.count
    payload = invoke_mcp_tool('copy_issue', user: @admin, args: {issue_id: 1})

    assert_mcp_ok(payload)
    assert_equal before + 1, Issue.count
    assert payload.dig(:data, :id)
    assert_not_equal 1, payload.dig(:data, :id)
  end

  test 'copy_issue keeps parent and respects copy settings and watcher permission' do
    project, user, role = generate_stats_project(
      permissions: %i[view_issues add_issues copy_issues edit_issues]
    )
    parent = Issue.generate!(project: project, author: user, subject: 'MCP copy parent')
    source = Issue.generate!(project: project, author: user, subject: 'MCP copy child', parent_issue_id: parent.id)
    source.add_watcher(user)

    copied = invoke_mcp_tool('copy_issue', user: user, args: {issue_id: source.id})
    copied_issue = Issue.find(copied.dig(:data, :id))

    assert_mcp_ok(copied)
    assert_equal parent.id, copied.dig(:data, :parent_id)
    assert_empty copied_issue.watcher_users

    role.add_permission!(:add_issue_watchers)
    with_watchers = invoke_mcp_tool('copy_issue', user: user.reload, args: {issue_id: source.id})
    watched_copy = Issue.find(with_watchers.dig(:data, :id))

    assert_mcp_ok(with_watchers)
    assert_includes watched_copy.watcher_user_ids, user.id

    with_settings({link_copied_issue: 'no', copy_attachments_on_issue_copy: 'no'}) do
      unlinked = invoke_mcp_tool(
        'copy_issue',
        user: user,
        args: {issue_id: source.id, link_original: true, copy_attachments: true}
      )
      clone = Issue.find(unlinked.dig(:data, :id))

      assert_mcp_ok(unlinked)
      assert_equal 0, clone.relations.count
    end
  end

  test 'copy_issue retries with the same idempotency_key' do
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    args = {issue_id: 1, copy_subtasks: false, copy_attachments: false, idempotency_key: 'copy-key-123'}
    first = invoke_mcp_tool('copy_issue', user: @admin, args: args)
    count = Issue.count

    second = invoke_mcp_tool('copy_issue', user: @admin, args: args)

    assert_mcp_ok(first)
    assert_mcp_ok(second)
    assert_equal(first.dig(:data, :id), second.dig(:data, :id))
    assert_equal(count, Issue.count)

    conflicted = invoke_mcp_tool(
      'copy_issue',
      user: @admin,
      args: {issue_id: 1, copy_subtasks: false, copy_attachments: false, subject: 'Other copy', idempotency_key: 'copy-key-123'}
    )

    assert_equal(false, conflicted[:ok])
    assert_equal('CONFLICT', conflicted.dig(:error, :code))
    assert_equal(count, Issue.count)
  ensure
    Rails.cache = previous_cache
  end

  test 'delete_issue deletes issue with confirmation' do
    created = invoke_mcp_tool(
      'create_issue',
      user: @admin,
      args: {project: 'ecookbook', subject: 'MCP delete me', tracker_id: 1, status_id: 1}
    )

    assert_mcp_ok(created)
    issue_id = created.dig(:data, :id)

    payload = invoke_mcp_tool(
      'delete_issue',
      user: @admin,
      args: {issue_id: issue_id, confirm_delete: true}
    )

    assert_mcp_ok(payload)
    assert_equal issue_id, payload.dig(:data, :deleted_issue_id)
    assert_not Issue.exists?(issue_id)
  end

  test 'delete_issue impact hides invisible related data and still requires children confirmation' do
    project, user, role = generate_stats_project(
      permissions: %i[view_issues add_issues delete_issues view_time_entries log_time manage_issue_relations]
    )
    role.update!(issues_visibility: 'own', time_entries_visibility: 'own')
    other = User.generate!
    User.add_to_project(other, project, role)
    parent = Issue.generate!(project: project, author: user, subject: 'MCP parent delete impact')
    Issue.generate!(
      project: project,
      author: other,
      subject: 'MCP hidden child',
      is_private: true,
      parent_issue_id: parent.id
    )
    hidden_related = Issue.generate!(
      project: project,
      author: other,
      subject: 'MCP hidden related',
      is_private: true
    )
    IssueRelation.create!(issue_from: parent, issue_to: hidden_related, relation_type: 'relates')
    Journal.create!(journalized: parent, user: other, notes: 'secret', private_notes: true)
    TimeEntry.generate!(project: project, issue: parent, user: user, hours: 1.0)
    TimeEntry.generate!(project: project, issue: parent, user: other, hours: 5.0)

    preview = invoke_mcp_tool('delete_issue', user: user, args: {issue_id: parent.id})
    parent.reload
    impact = preview.dig(:error, :details, :impact)
    blocked = invoke_mcp_tool(
      'delete_issue',
      user: user,
      args: {issue_id: parent.id, confirm_delete: true}
    )

    assert_equal false, preview[:ok]
    assert_equal 0, impact[:children_count]
    assert_equal parent.visible_journals_with_index(user).size, impact[:journals_count]
    assert_operator parent.journals.count, :>, impact[:journals_count]
    assert_equal 0, impact[:relations_count]
    assert_equal 1, impact[:time_entries_count]
    assert_equal false, blocked[:ok]
    assert_equal 'INVALID_STATE', blocked.dig(:error, :code)
    assert_equal 'children_present', blocked.dig(:error, :details, :reason)
    assert Issue.exists?(parent.id)
  end

  test 'create_issue_relation and delete_issue_relation' do
    created = invoke_mcp_tool(
      'create_issue_relation',
      user: @admin,
      args: {issue_id: 1, issue_to_id: 7, relation_type: 'relates'}
    )

    assert_mcp_ok(created)
    relation_id = created.dig(:data, :id)

    assert relation_id

    deleted = invoke_mcp_tool(
      'delete_issue_relation',
      user: @admin,
      args: {relation_id: relation_id}
    )

    assert_mcp_ok(deleted)
  end

  test 'add_issue_watcher and remove_issue_watcher' do
    added = invoke_mcp_tool(
      'add_issue_watcher',
      user: @admin,
      args: {issue_id: 1, user_id: 3}
    )

    assert_mcp_ok(added)

    removed = invoke_mcp_tool(
      'remove_issue_watcher',
      user: @admin,
      args: {issue_id: 1, user_id: 3}
    )

    assert_mcp_ok(removed)
  end

  test 'add_issue_watcher and remove_issue_watcher support groups' do
    Member.create!(project: Project.find(1), principal: Group.find(10), role_ids: [1]) unless
      Member.exists?(project_id: 1, user_id: 10)

    added = invoke_mcp_tool(
      'add_issue_watcher',
      user: @admin,
      args: {issue_id: 1, user_id: 10}
    )

    assert_mcp_ok(added)
    assert_equal 10, added.dig(:data, :user_id)
    assert_includes Issue.find(1).watcher_users.map(&:id), 10

    removed = invoke_mcp_tool(
      'remove_issue_watcher',
      user: @admin,
      args: {issue_id: 1, user_id: 10}
    )

    assert_mcp_ok(removed)
  end

  test 'update_issue_note and set_issue_note_private' do
    updated = invoke_mcp_tool(
      'update_issue_note',
      user: @admin,
      args: {journal_id: 1, notes: 'MCP edited note'}
    )

    assert_mcp_ok(updated)
    assert_equal 'MCP edited note', updated.dig(:data, :notes)

    cleared = invoke_mcp_tool(
      'update_issue_note',
      user: @admin,
      args: {journal_id: 1, notes: ''}
    )

    assert_mcp_ok(cleared)
    assert_equal '', cleared.dig(:data, :notes)

    privacy = invoke_mcp_tool(
      'set_issue_note_private',
      user: @admin,
      args: {journal_id: 1, is_private: true}
    )

    assert_mcp_ok(privacy)
    assert privacy.dig(:data, :private_notes)
  end

  test 'update_issue_note cannot edit an invisible private journal' do
    journal = Journal.create!(journalized: Issue.find(1), user: User.find(1), notes: 'Secret note', private_notes: true)
    role = Role.generate!(permissions: %i[view_issues edit_issue_notes])
    user = User.generate!
    User.add_to_project(user, Project.find(1), role)

    payload = invoke_mcp_tool(
      'update_issue_note',
      user: user,
      args: {journal_id: journal.id, notes: 'Hijacked'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'Secret note', journal.reload.notes
  end

  test 'update_issue_note cannot change privacy without set_notes_private' do
    role = Role.generate!(permissions: %i[view_issues edit_issue_notes])
    user = User.generate!
    User.add_to_project(user, Project.find(1), role)
    journal = Journal.find(1)

    updated = invoke_mcp_tool(
      'update_issue_note',
      user: user,
      args: {journal_id: journal.id, notes: PUBLIC_EDIT_NOTES}
    )

    assert_mcp_ok(updated)
    assert_equal PUBLIC_EDIT_NOTES, journal.reload.notes
    assert_equal user.id, journal.updated_by_id

    privacy = invoke_mcp_tool(
      'set_issue_note_private',
      user: user,
      args: {journal_id: journal.id, is_private: true}
    )
    via_update = invoke_mcp_tool(
      'update_issue_note',
      user: user,
      args: {journal_id: journal.id, notes: PUBLIC_EDIT_NOTES, private_notes: true}
    )

    assert_equal false, privacy[:ok]
    assert_equal false, via_update[:ok]
    assert_equal false, journal.reload.private_notes?
  end

  test 'create_issue_category update_issue_category delete_issue_category' do
    created = invoke_mcp_tool(
      'create_issue_category',
      user: @admin,
      args: {project: 'ecookbook', name: 'MCP Category'}
    )

    assert_mcp_ok(created)
    category_id = created.dig(:data, :id)

    updated = invoke_mcp_tool(
      'update_issue_category',
      user: @admin,
      args: {category_id: category_id, assigned_to_id: 3}
    )

    assert_mcp_ok(updated)
    assert_equal 3, updated.dig(:data, :assigned_to, :id)

    cleared = invoke_mcp_tool(
      'update_issue_category',
      user: @admin,
      args: {category_id: category_id, assigned_to_id: nil}
    )

    assert_mcp_ok(cleared)
    assert_nil cleared.dig(:data, :assigned_to)

    deleted = invoke_mcp_tool(
      'delete_issue_category',
      user: @admin,
      args: {category_id: category_id}
    )

    assert_mcp_ok(deleted)
    assert_not IssueCategory.exists?(category_id)
  end

  test 'create_version update_version delete_version' do
    created = invoke_mcp_tool(
      'create_version',
      user: @admin,
      args: {project: 'ecookbook', name: 'MCP Version', due_date: '2026-08-20', wiki_page_title: 'CookBook'}
    )

    assert_mcp_ok(created)
    version_id = created.dig(:data, :id)

    updated = invoke_mcp_tool(
      'update_version',
      user: @admin,
      args: {version_id: version_id, name: 'MCP Version 2', description: 'updated'}
    )

    assert_mcp_ok(updated)
    assert_equal 'MCP Version 2', updated.dig(:data, :name)

    cleared = invoke_mcp_tool(
      'update_version',
      user: @admin,
      args: {version_id: version_id, due_date: nil, wiki_page_title: nil}
    )

    assert_mcp_ok(cleared)
    assert_nil cleared.dig(:data, :due_date)
    assert_equal '', cleared.dig(:data, :wiki_page_title)

    deleted = invoke_mcp_tool(
      'delete_version',
      user: @admin,
      args: {version_id: version_id}
    )

    assert_mcp_ok(deleted)
    assert_not Version.exists?(version_id)
  end

  test 'add_project_member update_project_member remove_project_member' do
    created = invoke_mcp_tool(
      'add_project_member',
      user: @admin,
      args: {project: 'ecookbook', user_id: 4, role_ids: [1]}
    )

    assert_mcp_ok(created)
    membership_id = created.dig(:data, :id) || created.dig(:data, :membership_id)

    assert membership_id

    updated = invoke_mcp_tool(
      'update_project_member',
      user: @admin,
      args: {membership_id: membership_id, role_ids: [1, 2]}
    )

    assert_mcp_ok(updated)

    removed = invoke_mcp_tool(
      'remove_project_member',
      user: @admin,
      args: {membership_id: membership_id}
    )

    assert_mcp_ok(removed)
    assert_not Member.exists?(membership_id)
  end

  test 'create_wiki_page update_wiki_page rename_wiki_page delete_wiki_page' do
    title = 'McpWritePage'
    created = invoke_mcp_tool(
      'create_wiki_page',
      user: @admin,
      args: {project: 'ecookbook', wiki_page_title: title, text: 'initial wiki body'}
    )

    assert_mcp_ok(created)
    assert_equal title, created.dig(:data, :title)

    updated = invoke_mcp_tool(
      'update_wiki_page',
      user: @admin,
      args: {project: 'ecookbook', wiki_page_title: title, text: 'updated wiki body'}
    )

    assert_mcp_ok(updated)
    assert_equal 'updated wiki body', updated.dig(:data, :text)

    renamed_title = 'McpWritePageRenamed'
    renamed = invoke_mcp_tool(
      'rename_wiki_page',
      user: @admin,
      args: {project: 'ecookbook', wiki_page_title: title, new_title: renamed_title}
    )

    assert_mcp_ok(renamed)
    assert_equal renamed_title, renamed.dig(:data, :title)

    deleted = invoke_mcp_tool(
      'delete_wiki_page',
      user: @admin,
      args: {project: 'ecookbook', wiki_page_title: renamed_title}
    )

    assert_mcp_ok(deleted)
  end

  test 'upload_file and delete_file' do
    uploaded = invoke_mcp_tool(
      'upload_file',
      user: @admin,
      args: {
        project: 'ecookbook',
        filename: 'mcp-write.txt',
        content_base64: Base64.strict_encode64('mcp upload body')
      }
    )

    assert_mcp_ok(uploaded)
    file_id = uploaded.dig(:data, :id)

    assert file_id

    deleted = invoke_mcp_tool(
      'delete_file',
      user: @admin,
      args: {file_id: file_id}
    )

    assert_mcp_ok(deleted)
    assert_equal file_id, deleted.dig(:data, :deleted_file_id)
    assert_not Attachment.exists?(file_id)
  end

  test 'protected wiki pages require protect_wiki_pages and history requires view_wiki_edits' do
    permissions = %i[
      view_project view_wiki_pages edit_wiki_pages delete_wiki_pages rename_wiki_pages
    ]
    project, user, role = generate_stats_project(permissions: permissions)
    project.enable_module!(:wiki)
    Wiki.create!(project: project, start_page: 'Wiki') unless project.wiki
    title = 'MCPProtectedWiki'

    created = invoke_mcp_tool(
      'create_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, text: 'v1 body'}
    )

    assert_mcp_ok(created)
    updated = invoke_mcp_tool(
      'update_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, text: 'v2 body'}
    )

    assert_mcp_ok(updated)
    history_denied = invoke_mcp_tool(
      'get_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, version: 1}
    )
    current = invoke_mcp_tool(
      'get_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title}
    )

    assert_equal false, history_denied[:ok]
    assert_mcp_ok(current)

    page = project.wiki.find_page(title)
    page.update_column(:protected, true)
    denied_update = invoke_mcp_tool(
      'update_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, text: 'v3 body'}
    )
    denied_rename = invoke_mcp_tool(
      'rename_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, new_title: 'MCPProtectedWiki2'}
    )
    denied_delete = invoke_mcp_tool(
      'delete_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title}
    )

    assert_equal false, denied_update[:ok]
    assert_equal false, denied_rename[:ok]
    assert_equal false, denied_delete[:ok]
    assert project.wiki.find_page(title)

    role.add_permission!(:protect_wiki_pages, :view_wiki_edits)
    user.reload
    history = invoke_mcp_tool(
      'get_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, version: 1}
    )
    allowed_update = invoke_mcp_tool(
      'update_wiki_page',
      user: user,
      args: {project: project.identifier, wiki_page_title: title, text: 'v3 allowed'}
    )

    assert_mcp_ok(history)
    assert_mcp_ok(allowed_update)
  end
end
