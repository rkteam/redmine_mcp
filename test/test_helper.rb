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

require File.expand_path('../../../test/test_helper', __dir__)
require 'json_schemer'

class RedmineMcpTestCase < ActiveSupport::TestCase
  ARG_OVERRIDES = {
    project: 'ecookbook',
    issue_id: 1,
    issue_to_id: 2,
    query: 'recipe',
    wiki_page_title: 'CookBook',
    new_title: 'CookBookRenamed',
    subject: 'MCP test issue',
    text: 'Wiki page body',
    notes: 'Updated note',
    name: 'MCP test',
    filename: 'test.txt',
    content_base64: Base64.strict_encode64('test'),
    hours: 1.0,
    time_entry_id: 1,
    version_id: 1,
    category_id: 1,
    relation_id: 1,
    journal_id: 1,
    membership_id: 1,
    file_id: 1,
    attachment_id: 1,
    user_id: 2,
    principal_id: 2,
    role_ids: [1],
    entries: [{hours: 1.0, project: 'ecookbook'}]
  }.freeze

  fixtures :users, :email_addresses, :user_preferences, :projects, :issues, :members, :member_roles, :roles, :trackers, :issue_statuses, :enumerations, :enabled_modules

  setup do
    ensure_mcp_tools_registered!
    User.current = nil
  end

  teardown do
    User.current = nil
    restore_mcp_settings!
  end

  def ensure_mcp_tools_registered!
    return if @mcp_tools_registered

    RedmineMcp::Core::Tools.register! unless mcp_registry.tools_for_user(User.find(1)).any?
    @mcp_tools_registered = true
  end

  def mcp_registry
    RedmineMcp::Registry.instance
  end

  def all_mcp_tools
    mcp_registry.instance_variable_get(:@tools).values.select do |tool|
      tool.plugin_id == RedmineMcp::Core::Tools::PLUGIN_ID
    end
  end

  def invoke_registered_mcp_tool(tool_name, user:, args: {})
    definition = mcp_registry.tool(tool_name)

    assert definition, "tool not registered: #{tool_name}"

    extensions = mcp_registry.tool_extensions(definition.full_name)
    input_schema = RedmineMcp::ToolRunner.merge_schemas(definition, extensions)

    limit_error = RedmineMcp::RequestLimits.check_before_call!(user: user, args: args)
    return RedmineMcp::ToolResponse.from_handler_result(limit_error) if limit_error

    unless definition.allowed_for?(user, args)
      return RedmineMcp::ToolResponse.failure(
        code: 'FORBIDDEN',
        message: I18n.t(:error_mcp_permission_denied)
      )
    end

    validation_error = RedmineMcp::InputValidator.validate(input_schema, args)
    return validation_error if validation_error

    if definition.mutating?
      read_only_error = RedmineMcp::Core::ReadOnly.guard_write!
      return RedmineMcp::ToolResponse.from_handler_result(read_only_error) if read_only_error
    end

    previous_user = User.current
    User.current = user
    begin
      context = {user: user}
      result = RedmineMcp::RequestLimits.call_with_timeout(enforce: definition.annotations[:read_only_hint]) do
        RedmineMcp::ToolRunner.run(definition, extensions, args, context)
      end
      RedmineMcp::ToolResponse.from_handler_result(result)
    ensure
      User.current = previous_user
    end
  end

  def ensure_additionals_extension_loaded!
    return if @additionals_extension_loaded

    skip('Additionals plugin is not installed') unless Redmine::Plugin.installed?(:additionals)

    tool_name = 'redmine_additionals_set_issue_author'
    unless mcp_registry.tool(tool_name)
      plugin = Redmine::Plugin.find(:additionals)
      RedmineMcp::ExtensionLoader.load_plugin_extension(plugin)
    end

    assert mcp_registry.tool(tool_name), "additionals extension tool not registered: #{tool_name}"
    @additionals_extension_loaded = true
  end

  def grant_edit_issue_author!(role)
    role.add_permission!(:edit_issue_author)
  end

  def invoke_mcp_tool(tool_name, user:, args: {})
    definition = mcp_registry.tool(tool_name)

    assert definition, "tool not registered: #{tool_name}"

    extensions = mcp_registry.tool_extensions(definition.full_name)
    input_schema = RedmineMcp::ToolRunner.merge_schemas(definition, extensions)

    unless definition.allowed_for?(user, args)
      return RedmineMcp::ToolResponse.failure(
        code: 'FORBIDDEN',
        message: I18n.t(:error_mcp_permission_denied)
      )
    end

    validation_error = RedmineMcp::InputValidator.validate(input_schema, args)
    return validation_error if validation_error

    previous_user = User.current
    User.current = user
    begin
      context = {user: user}
      result = RedmineMcp::ToolRunner.run(definition, extensions, args, context)
      RedmineMcp::ToolResponse.from_handler_result(result)
    ensure
      User.current = previous_user
    end
  end

  def assert_mcp_ok(payload)
    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
  end

  def assert_mcp_output_schema(tool_name, payload)
    definition = mcp_registry.tool(tool_name)

    assert definition, "tool not registered: #{tool_name}"
    assert definition.output_schema.present?, "missing output_schema for #{tool_name}"

    schema = JSON.parse(JSON.generate(definition.output_schema))
    data = JSON.parse(JSON.generate(payload))
    errors = JSONSchemer.schema(schema).validate(data).to_a

    assert_empty(errors, "outputSchema mismatch for #{tool_name}: #{errors.inspect}")
  end

  def output_schema_data_properties(tool_name)
    definition = mcp_registry.tool(tool_name)

    assert definition, "tool not registered: #{tool_name}"

    schema = definition.output_schema
    data = schema.dig(:properties, :data) || schema.dig('properties', 'data')
    properties = data && (data[:properties] || data['properties'])

    assert properties.present?, "missing data properties in output_schema for #{tool_name}"
    properties
  end

  def output_schema_item_properties(tool_name)
    items = output_schema_data_properties(tool_name)[:items] || output_schema_data_properties(tool_name)['items']
    item = items && (items[:items] || items['items'])
    properties = item && (item[:properties] || item['properties'])

    assert properties.present?, "missing item properties in output_schema for #{tool_name}"
    properties
  end

  def generate_stats_project(permissions: %i[view_issues add_issues edit_issues log_time view_time_entries])
    project = Project.generate!
    project.trackers << Tracker.find(1) unless project.trackers.exists?(id: 1)
    project.enabled_module_names = %w[issue_tracking time_tracking]
    project.save!
    role = Role.generate!(permissions: permissions)
    user = User.generate!
    User.add_to_project(user, project, role)
    [project, user, role]
  end

  def close_issue!(issue, at:)
    issue.update_columns(status_id: IssueStatus.where(is_closed: true).first.id, closed_on: at, updated_on: at)
  end

  def add_reopen_journal!(issue, at:)
    journal = Journal.create!(journalized: issue, user: User.find(1), notes: '')
    journal.update_column(:created_on, at)
    JournalDetail.create!(
      journal: journal,
      property: 'attr',
      prop_key: 'status_id',
      old_value: IssueStatus.where(is_closed: true).first.id.to_s,
      value: IssueStatus.where(is_closed: false).first.id.to_s
    )
  end

  def validate_mcp_args(tool, args)
    definition = tool.is_a?(RedmineMcp::ToolDefinition) ? tool : mcp_registry.tool(tool)
    extensions = mcp_registry.tool_extensions(definition.full_name)
    input_schema = RedmineMcp::ToolRunner.merge_schemas(definition, extensions)
    RedmineMcp::InputValidator.validate(input_schema, args)
  end

  def minimal_valid_args(definition)
    schema = RedmineMcp::ToolRunner.merge_schemas(definition, mcp_registry.tool_extensions(definition.full_name))
    properties = schema[:properties] || {}
    args = Array(schema[:required]).each_with_object({}) do |key, result|
      sym = key.to_sym
      result[sym] = ARG_OVERRIDES[sym] || sample_value_for_schema(properties[sym] || properties[key.to_s])
    end
    satisfy_schema_constraints!(schema, args, properties)
    args
  end

  def satisfy_schema_constraints!(schema, args, properties)
    return if schema[:oneOf].blank?

    branch = schema[:oneOf].find do |candidate|
      Array(candidate[:required]).all? { |key| args.key?(key.to_sym) || args.key?(key) }
    end
    branch ||= schema[:oneOf].first

    Array(branch[:required]).each do |key|
      sym = key.to_sym
      next if args.key?(sym)

      args[sym] = ARG_OVERRIDES[sym] || sample_value_for_schema(properties[sym] || properties[key.to_s])
    end
  end

  def sample_value_for_schema(prop)
    return 'test' unless prop.is_a?(Hash)

    if prop[:oneOf]
      branch = prop[:oneOf].find { |item| item[:type] == 'integer' } || prop[:oneOf].first
      return sample_value_for_schema(branch)
    end

    return prop[:enum].first if prop[:enum].is_a?(Array) && prop[:enum].any?

    type = prop[:type]
    type = type.first if type.is_a?(Array)
    sample_value_for_type(type, prop)
  end

  def sample_value_for_type(type, prop)
    case type
    when 'integer'
      prop[:minimum].to_i.positive? ? prop[:minimum] : 1
    when 'number'
      1.0
    when 'boolean'
      true
    when 'string'
      sample_value_for_string(prop)
    when 'array'
      item_schema = prop[:items].is_a?(Hash) ? prop[:items] : {type: 'string'}
      [sample_value_for_schema(item_schema)]
    when 'object'
      sample_object_for_schema(prop)
    else
      'test'
    end
  end

  def sample_value_for_string(prop)
    case prop[:format]
    when 'date'
      User.find(1).today.to_s
    when 'date-time'
      Time.zone.now.iso8601
    else
      'test'
    end
  end

  def sample_object_for_schema(prop)
    properties = prop[:properties] || {}
    Array(prop[:required]).each_with_object({}) do |key, object|
      sym = key.to_sym
      object[sym] = ARG_OVERRIDES[sym] || sample_value_for_schema(properties[sym] || properties[key.to_s])
    end
  end

  def with_read_only_mcp!
    @saved_mcp_settings = Setting.plugin_redmine_mcp&.dup
    Setting.plugin_redmine_mcp = (Setting.plugin_redmine_mcp || {}).merge('read_only' => '1')
  end

  def restore_mcp_settings!
    return unless @saved_mcp_settings

    Setting.plugin_redmine_mcp = @saved_mcp_settings
    @saved_mcp_settings = nil
  end

  def tool_contract_snapshot
    all_mcp_tools.sort_by(&:full_name).each_with_object({}) do |tool, snapshot|
      schema = tool.input_schema
      snapshot[tool.full_name] = {
        'required' => Array(schema[:required]).sort,
        'read_only' => tool.annotations[:read_only_hint] == true,
        'destructive' => tool.annotations[:destructive_hint] == true,
        'idempotent' => tool.annotations[:idempotent_hint] == true,
        'has_output_schema' => tool.output_schema.present?
      }
    end
  end
end
