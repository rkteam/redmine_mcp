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

class RedmineMcpToolPermissionTest < RedmineMcpTestCase
  test 'user without project access cannot read private project issue' do
    outsider = User.find(7)
    payload = invoke_mcp_tool('get_issue', user: outsider, args: {issue_id: 4})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'non admin cannot list all users' do
    user = User.find(2)
    payload = invoke_mcp_tool('list_all_users', user: user, args: {})

    assert_equal false, payload[:ok]
    assert_equal 'FORBIDDEN', payload.dig(:error, :code)
  end

  test 'non admin cannot search users by login without project' do
    user = User.find(2)
    payload = invoke_mcp_tool('list_users', user: user, args: {login: 'admin'})

    assert_equal false, payload[:ok]
    assert_equal 'FORBIDDEN', payload.dig(:error, :code)
  end

  test 'get_issue include_watchers respects view_issue_watchers' do
    user = User.find(2)
    issue = Issue.find(1)
    other = User.find(3)
    issue.add_watcher(other)
    Role.find(1).remove_permission!(:view_issue_watchers)

    payload = invoke_mcp_tool(
      'get_issue',
      user: user,
      args: {issue_id: issue.id, include_watchers: true}
    )

    assert payload[:ok]
    watcher_ids = Array(payload.dig(:data, :watchers)).map { |item| item[:id] || item['id'] }

    assert_not_includes watcher_ids, other.id
  end

  test 'create_time_entry cannot log time for other users without permission' do
    user = User.find(2)
    project = Project.find(1)

    assert_not user.allowed_to?(:log_time_for_other_users, project)

    payload = invoke_mcp_tool(
      'create_time_entry',
      user: user,
      args: {project: 'ecookbook', hours: 1.0, user_id: 3}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
    assert_equal 0, TimeEntry.where(user_id: 3, project_id: project.id, hours: 1.0).count
  end

  test 'list_users hides mail when user prefers hide_mail' do
    viewer = User.find(3)
    payload = invoke_mcp_tool('list_users', user: viewer, args: {project: 'ecookbook'})

    assert payload[:ok]
    items = Array(payload.dig(:data, :items))
    hidden = items.find { |item| (item[:id] || item['id']).to_i == 2 }
    visible = items.find { |item| (item[:id] || item['id']).to_i == 3 }

    assert hidden, 'expected jsmith in project members'
    assert visible, 'expected dlopper in project members'
    assert User.find(2).pref.hide_mail
    assert_not User.find(3).pref.hide_mail
    assert_nil hidden[:mail] || hidden['mail']
    assert_equal User.find(3).mail, visible[:mail] || visible['mail']
  end

  test 'add_issue_watcher does not reveal whether a global user id exists' do
    user = User.find(2)
    missing = invoke_mcp_tool(
      'add_issue_watcher',
      user: user,
      args: {issue_id: 1, user_id: 999_999}
    )
    outsider = invoke_mcp_tool(
      'add_issue_watcher',
      user: user,
      args: {issue_id: 1, user_id: 7}
    )

    assert_equal false, missing[:ok]
    assert_equal false, outsider[:ok]
    assert_equal missing.dig(:error, :code), outsider.dig(:error, :code)
  end

  test 'outsider cannot create issue in private project' do
    outsider = User.find(7)
    payload = invoke_mcp_tool(
      'create_issue',
      user: outsider,
      args: {project: 'onlinestore', subject: 'Should fail'}
    )

    assert_equal false, payload[:ok]
    assert_includes %w[FORBIDDEN NOT_FOUND], payload.dig(:error, :code)
  end

  test 'outsider cannot delete issue' do
    outsider = User.find(7)
    payload = invoke_mcp_tool(
      'delete_issue',
      user: outsider,
      args: {issue_id: 1, confirm_delete: true}
    )

    assert_equal false, payload[:ok]
    assert_includes %w[FORBIDDEN NOT_FOUND], payload.dig(:error, :code)
  end

  test 'tools list includes tools that need runtime args for permission' do
    user = User.find(2)
    names = mcp_registry.tools_for_user(user).map(&:name)

    %w[
      create_time_entry
      update_time_entry
      create_issue_relation
      delete_issue_relation
      add_issue_watcher
      remove_issue_watcher
      list_wiki_pages
      get_wiki_page
      create_wiki_page
      list_users
    ].each do |name|
      assert_includes names, name, "expected #{name} visible in tools/list for user with matching permissions"
    end
  end

  test 'delete_file is listed when the user can delete issue attachments without manage_files' do
    _project, user = generate_stats_project(permissions: %i[view_issues edit_issues add_issues])
    names = mcp_registry.tools_for_user(user).map(&:name)

    assert_includes names, 'delete_file'
  end

  test 'get_issue hides journals that only change an invisible custom field' do
    project, owner, owner_role = generate_stats_project(permissions: %i[view_issues])
    viewer = add_project_member(project, permissions: %i[view_issues])
    field = IssueCustomField.generate!(visible: false, role_ids: [owner_role.id])
    issue = Issue.generate!(project: project, author: owner, subject: 'Hidden CF journal')
    hidden = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 1),
      details: [{property: 'cf', prop_key: field.id.to_s, value: 'secret'}]
    )
    visible = build_issue_journal(
      issue,
      user: owner,
      notes: 'visible note',
      created_on: Time.utc(2026, 1, 1, 12, 0, 2)
    )

    payload = invoke_mcp_tool(
      'get_issue',
      user: viewer,
      args: {issue_id: issue.id, include_journals: true, journal_limit: 10}
    )

    assert_mcp_ok(payload)
    journal_ids = Array(payload.dig(:data, :journals)).map { |item| item[:id] || item['id'] }
    pagination = payload.dig(:data, :journal_pagination)

    assert_not_includes journal_ids, hidden.id
    assert_includes journal_ids, visible.id
    assert_equal 1, pagination[:total_count]
  end

  test 'get_issue journal pagination skips hidden journals between visible ones' do
    project, owner, owner_role = generate_stats_project(permissions: %i[view_issues])
    viewer = add_project_member(project, permissions: %i[view_issues])
    field = IssueCustomField.generate!(visible: false, role_ids: [owner_role.id])
    issue = Issue.generate!(project: project, author: owner, subject: 'Journal page gap')
    first = build_issue_journal(
      issue,
      user: owner,
      notes: 'first',
      created_on: Time.utc(2026, 1, 1, 12, 0, 1)
    )
    build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 2),
      details: [{property: 'cf', prop_key: field.id.to_s, value: 'secret'}]
    )
    second = build_issue_journal(
      issue,
      user: owner,
      notes: 'second',
      created_on: Time.utc(2026, 1, 1, 12, 0, 3)
    )

    payload = invoke_mcp_tool(
      'get_issue',
      user: viewer,
      args: {issue_id: issue.id, include_journals: true, journal_limit: 2}
    )

    assert_mcp_ok(payload)
    journals = Array(payload.dig(:data, :journals))
    journal_ids = journals.map { |item| item[:id] || item['id'] }
    pagination = payload.dig(:data, :journal_pagination)

    assert_equal [first.id, second.id], journal_ids
    assert_equal 2, pagination[:total_count]
    assert_equal false, pagination[:has_more]
  end

  test 'get_issue hides another users private note without view_private_notes' do
    project, owner = generate_stats_project(permissions: %i[view_issues])
    viewer = add_project_member(project, permissions: %i[view_issues])
    author = add_project_member(project, permissions: %i[view_issues])
    issue = Issue.generate!(project: project, author: owner, subject: 'Private note visibility')
    secret = build_issue_journal(
      issue,
      user: author,
      notes: 'secret',
      private_notes: true,
      created_on: Time.utc(2026, 1, 1, 12, 0, 1)
    )
    visible = build_issue_journal(
      issue,
      user: owner,
      notes: 'public',
      created_on: Time.utc(2026, 1, 1, 12, 0, 2)
    )

    payload = invoke_mcp_tool(
      'get_issue',
      user: viewer,
      args: {issue_id: issue.id, include_journals: true, journal_limit: 10}
    )

    assert_mcp_ok(payload)
    journal_ids = Array(payload.dig(:data, :journals)).map { |item| item[:id] || item['id'] }

    assert_not_includes journal_ids, secret.id
    assert_includes journal_ids, visible.id
  end

  test 'get_private_notes paginates private notes without loading all journals' do
    project, user = generate_stats_project(permissions: %i[view_issues view_private_notes])
    issue = Issue.generate!(project: project, author: user, subject: 'Private notes page')
    3.times do |index|
      build_issue_journal(
        issue,
        user: user,
        notes: "private #{index}",
        private_notes: true,
        created_on: Time.utc(2026, 1, 1, 12, 0, index)
      )
    end

    Issue.any_instance.stubs(:visible_journals_with_index).raises(StandardError, 'loaded all journals')

    payload = invoke_mcp_tool(
      'get_private_notes',
      user: user,
      args: {issue_id: issue.id, limit: 1, offset: 1}
    )

    assert_mcp_ok(payload)
    items = Array(payload.dig(:data, :items))

    assert_equal 1, items.size
    assert_equal 'private 1', items.first[:notes] || items.first['notes']
    assert_equal 3, payload.dig(:meta, :total_count)
    assert payload.dig(:meta, :has_more)
  end

  test 'get_issue journals with attr cf and relation details stay visible without cast errors' do
    project, owner, owner_role = generate_stats_project(permissions: %i[view_issues])
    viewer = add_project_member(project, permissions: %i[view_issues])
    hidden_field = IssueCustomField.generate!(visible: false, role_ids: [owner_role.id])
    visible_field = IssueCustomField.generate!
    issue = Issue.generate!(project: project, author: owner, subject: 'Mixed journal details')
    related = Issue.generate!(project: project, author: owner, subject: 'Related visible')
    hidden_project, hidden_owner = generate_stats_project(permissions: %i[view_issues])
    hidden_project.update!(is_public: false)
    hidden_related = Issue.generate!(project: hidden_project, author: hidden_owner, subject: 'Related hidden')

    attr_journal = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 1),
      details: [{property: 'attr', prop_key: 'subject', old_value: 'old', value: 'new'}]
    )
    hidden_cf = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 2),
      details: [{property: 'cf', prop_key: hidden_field.id.to_s, value: 'secret'}]
    )
    visible_cf = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 3),
      details: [{property: 'cf', prop_key: visible_field.id.to_s, value: 'shown'}]
    )
    visible_relation = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 4),
      details: [{property: 'relation', prop_key: 'relates', value: related.id.to_s}]
    )
    hidden_relation = build_issue_journal(
      issue,
      user: owner,
      created_on: Time.utc(2026, 1, 1, 12, 0, 5),
      details: [{property: 'relation', prop_key: 'relates', value: hidden_related.id.to_s}]
    )

    payload = invoke_mcp_tool(
      'get_issue',
      user: viewer,
      args: {issue_id: issue.id, include_journals: true, journal_limit: 20}
    )

    assert_mcp_ok(payload)
    journal_ids = Array(payload.dig(:data, :journals)).map { |item| item[:id] || item['id'] }

    assert_includes journal_ids, attr_journal.id
    assert_includes journal_ids, visible_cf.id
    assert_includes journal_ids, visible_relation.id
    assert_not_includes journal_ids, hidden_cf.id
    assert_not_includes journal_ids, hidden_relation.id
    assert_equal 3, payload.dig(:data, :journal_pagination, :total_count)
  end

  test 'get_issue hides whitespace-only notes with only a hidden custom field' do
    project, owner, owner_role = generate_stats_project(permissions: %i[view_issues])
    viewer = add_project_member(project, permissions: %i[view_issues])
    field = IssueCustomField.generate!(visible: false, role_ids: [owner_role.id])
    issue = Issue.generate!(project: project, author: owner, subject: 'Whitespace notes')
    hidden_ids = ['   ', "\t", "\n"].each_with_index.map do |notes, index|
      build_issue_journal(
        issue,
        user: owner,
        notes: notes,
        created_on: Time.utc(2026, 1, 1, 12, 0, index),
        details: [{property: 'cf', prop_key: field.id.to_s, value: 'secret'}]
      ).id
    end
    visible = build_issue_journal(
      issue,
      user: owner,
      notes: 'visible',
      created_on: Time.utc(2026, 1, 1, 12, 0, 10)
    )

    payload = invoke_mcp_tool(
      'get_issue',
      user: viewer,
      args: {issue_id: issue.id, include_journals: true, journal_limit: 10}
    )

    assert_mcp_ok(payload)
    journal_ids = Array(payload.dig(:data, :journals)).map { |item| item[:id] || item['id'] }

    hidden_ids.each { |id| assert_not_includes journal_ids, id }
    assert_includes journal_ids, visible.id
    assert_equal 1, payload.dig(:data, :journal_pagination, :total_count)
  end

  test 'get_private_notes omits whitespace-only comments' do
    project, user = generate_stats_project(permissions: %i[view_issues view_private_notes])
    issue = Issue.generate!(project: project, author: user, subject: 'Whitespace private notes')
    ['   ', "\t", "\n"].each_with_index do |notes, index|
      journal = build_issue_journal(
        issue,
        user: user,
        notes: 'placeholder',
        private_notes: true,
        created_on: Time.utc(2026, 1, 1, 12, 0, index)
      )
      journal.update_column(:notes, notes)
    end
    visible = build_issue_journal(
      issue,
      user: user,
      notes: 'private note',
      private_notes: true,
      created_on: Time.utc(2026, 1, 1, 12, 0, 10)
    )

    payload = invoke_mcp_tool(
      'get_private_notes',
      user: user,
      args: {issue_id: issue.id, limit: 10}
    )

    assert_mcp_ok(payload)
    items = Array(payload.dig(:data, :items))

    assert_equal 1, items.size
    assert_equal visible.id, items.first[:id] || items.first['id']
    assert_equal 1, payload.dig(:meta, :total_count)
  end

  test 'mysql blank notes sql uses nested replace for each whitespace character' do
    Journal.connection.stubs(:adapter_name).returns('Mysql2')
    predicate = RedmineMcp::Core::Tools::Issues.sql_trim_blank('journals.notes')

    assert_includes predicate, 'REPLACE'
    [32, 9, 10, 13, 12, 11].each do |code|
      assert_includes predicate, "CHAR(#{code})"
    end
    assert_no_match(/TRIM\s*\(\s*BOTH/i, predicate)
  end

  test 'mysql blank notes sql strips space tab and newline on mysql' do
    skip unless Journal.connection.adapter_name.match?(/mysql|trilogy/i)

    ['   ', "\t", "\n", " \t\n "].each do |blank|
      sql = "SELECT #{RedmineMcp::Core::Tools::Issues.sql_trim_blank(Journal.connection.quote(blank))}"

      assert_equal '', Journal.connection.select_value(sql).to_s, "mysql predicate left #{blank.inspect} non-blank"
    end

    kept = Journal.connection.select_value(
      "SELECT #{RedmineMcp::Core::Tools::Issues.sql_trim_blank(Journal.connection.quote('note'))}"
    )

    assert_equal 'note', kept
  end

  def add_project_member(project, permissions:)
    role = Role.generate!(permissions: permissions)
    user = User.generate!
    User.add_to_project(user, project, role)
    user
  end

  def build_issue_journal(issue, user:, created_on:, notes: '', private_notes: false, details: [])
    journal = Journal.new(journalized: issue, user: user, notes: notes, private_notes: private_notes)
    details.each { |detail| journal.details.build(detail) }
    journal.save!
    journal.update_column(:created_on, created_on)
    journal
  end
end
