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

class RedmineMcpToolsSchemaTest < RedmineMcpTestCase
  test 'every tool publishes a typed output schema' do
    all_mcp_tools.each do |tool|
      assert tool.output_schema.present?, "missing output_schema for #{tool.full_name}"
      assert RedmineMcp::SchemaNormalizer.data_schema_described?(tool.output_schema),
             "output_schema for #{tool.full_name} does not describe data/item fields"
    end
  end

  test 'every tool rejects missing required arguments' do
    all_mcp_tools.each do |tool|
      required = Array(tool.input_schema[:required])
      next if required.empty?

      error = validate_mcp_args(tool, {})

      assert error, "expected validation error for #{tool.full_name} without required args"
      assert_equal 'VALIDATION_ERROR', error.dig(:error, :code)
    end
  end

  test 'every tool accepts minimal valid arguments at schema level' do
    all_mcp_tools.each do |tool|
      args = minimal_valid_args(tool)
      error = validate_mcp_args(tool, args)

      assert_nil error, "schema validation failed for #{tool.full_name} with #{args.inspect}: #{error&.dig(:error, :message)}"
    end
  end

  test 'schema normalizer tightens objects nested in oneOf' do
    schema = {
      type: 'object',
      properties: {
        assignee_ref: {
          oneOf: [
            {type: 'object', properties: {id: {type: 'integer'}}},
            {type: 'string'},
          ]
        }
      }
    }

    normalized = RedmineMcp::SchemaNormalizer.normalize_input(schema)
    branch = normalized[:properties][:assignee_ref][:oneOf].first

    assert_equal false, branch[:additionalProperties]
  end

  test 'output schema accepts typical and nullable payloads' do
    admin = User.find(1)
    issue_payload = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 1})

    assert_mcp_ok(issue_payload)
    assert_nil issue_payload.dig(:data, :journal_pagination)
    assert_mcp_output_schema('get_issue', issue_payload)

    form_payload = invoke_mcp_tool('get_issue_form_options', user: admin, args: {project: 'ecookbook'})

    assert_mcp_ok(form_payload)
    assert form_payload.dig(:data, :project).present?
    assert_mcp_output_schema('get_issue_form_options', form_payload)

    users_payload = invoke_mcp_tool('list_all_users', user: admin, args: {})

    assert_mcp_ok(users_payload)
    assert users_payload.dig(:data, :items).first&.key?(:created_on)
    assert_mcp_output_schema('list_all_users', users_payload)

    listed_users = invoke_mcp_tool('list_users', user: admin, args: {project: 'ecookbook'})
    listed_item = listed_users.dig(:data, :items).first
    user_item_props = output_schema_item_properties('list_users')
    all_user_item_props = output_schema_item_properties('list_all_users')

    assert_mcp_ok(listed_users)
    assert listed_item
    assert_not listed_item.key?(:created_on)
    assert_not(user_item_props.key?(:created_on) || user_item_props.key?('created_on'))
    assert(all_user_item_props.key?(:created_on) || all_user_item_props.key?('created_on'))
    assert_mcp_output_schema('list_users', listed_users)

    project, user = generate_stats_project(permissions: %i[view_issues])
    status_payload = invoke_mcp_tool(
      'summarize_project_status',
      user: user,
      args: {project: project.identifier, days: 30}
    )

    assert_mcp_ok(status_payload)
    assert_nil status_payload.dig(:data, :estimation_accuracy)
    assert_mcp_output_schema('summarize_project_status', status_payload)

    TimeEntry.generate!(project: Project.find(1), issue: nil)
    entries_payload = invoke_mcp_tool('list_time_entries', user: admin, args: {project: 'ecookbook'})

    assert_mcp_ok(entries_payload)
    assert(entries_payload.dig(:data, :items).any? { |item| item[:issue].nil? })
    assert_mcp_output_schema('list_time_entries', entries_payload)

    note_payload = invoke_mcp_tool(
      'add_issue_note',
      user: admin,
      args: {issue_id: 1, notes: 'schema contract note'}
    )

    assert_mcp_ok(note_payload)
    assert_mcp_output_schema('add_issue_note', note_payload)

    note_with_files = {
      ok: true,
      data: {
        issue_id: 1,
        journal_id: 1,
        notes: 'note',
        private_notes: false,
        added_attachments: [],
        attachments_not_saved: ['broken.png'],
        attachments_not_saved_count: 1
      }
    }

    assert_mcp_output_schema('add_issue_note', note_with_files)

    import_payload = {
      ok: true,
      data: {
        total: 2,
        succeeded: 1,
        failed: 1,
        created: [],
        errors: [{index: 1, message: 'hours is invalid'}]
      }
    }

    assert_mcp_output_schema('import_time_entries', import_payload)

    unsaved_payload = {
      ok: true,
      data: {
        id: 1,
        subject: 'Issue',
        attachments_not_saved: ['broken.png'],
        attachments_not_saved_count: 1
      }
    }

    assert_mcp_output_schema('update_issue', unsaved_payload)

    attachment_props = output_schema_data_properties('get_attachment')

    assert attachment_props.key?(:size) || attachment_props.key?('size')
    assert attachment_props.key?(:content_url) || attachment_props.key?('content_url')

    set_tmp_attachments_directory
    attachment = Attachment.create!(
      container: Issue.find(1),
      file: mock_file,
      author: admin
    )
    attachment_payload = invoke_mcp_tool(
      'get_attachment',
      user: admin,
      args: {attachment_id: attachment.id}
    )

    assert_mcp_ok(attachment_payload)
    assert attachment_payload[:data].key?(:size)
    assert attachment_payload[:data].key?(:content_url)
    assert_mcp_output_schema('get_attachment', attachment_payload)
  end
end
