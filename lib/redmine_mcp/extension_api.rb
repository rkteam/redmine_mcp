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

module RedmineMcp
  module ExtensionApi
    TOOL_OPTIONS = %i[title annotations].freeze
    ISSUE_TOOL_OPTIONS = (%i[module_name issue_id_key input_schema] + TOOL_OPTIONS).freeze
    PROMPT_OPTIONS = %i[title description arguments permission meta project_resolver].freeze
    RESOURCE_OPTIONS = %i[title description mime_type permission project_resolver].freeze
    INTERNAL_REQUEST_METHODS = %w[GET POST PUT PATCH DELETE].freeze
    ISSUE_ID_SCHEMA = RedmineMcp::Core::Helpers::ISSUE_ID_SCHEMA
    USER_ID_SCHEMA = RedmineMcp::Core::Helpers::USER_ID_SCHEMA
    USER_REF_SCHEMA = RedmineMcp::Core::Helpers::USER_REF_SCHEMA
    EXPECTED_UPDATED_AT_SCHEMA = RedmineMcp::Core::Helpers::EXPECTED_UPDATED_AT_SCHEMA
    READ_ONLY_ANNOTATIONS = RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    CREATE_ANNOTATIONS = RedmineMcp::Core::Helpers::CREATE_ANNOTATIONS
    UPDATE_ANNOTATIONS = RedmineMcp::Core::Helpers::UPDATE_ANNOTATIONS
    DELETE_ANNOTATIONS = RedmineMcp::Core::Helpers::DELETE_ANNOTATIONS

    def self.extended(base)
      base.extend(PluginHelpers)
    end

    module PluginHelpers
      def mcp_extension_enabled?
        Redmine::Plugin.installed?(:redmine_mcp) && !Settings.extension_disabled?(plugin_id)
      end
    end

    def plugin_id(id = nil)
      if id
        @plugin_id = id.to_sym
      else
        @plugin_id
      end
    end

    def registered_tool?(name)
      Registry.instance.tool(tool_full_name(name)).present?
    end

    def register_tool_once(name:, description:, input_schema:, output_schema:, permission:, handler:, **options)
      assert_known_options!(options, TOOL_OPTIONS)
      return if registered_tool?(name)

      register_tool(
        name: name,
        description: description,
        input_schema: input_schema,
        output_schema: output_schema,
        title: options[:title],
        permission: permission,
        handler: handler,
        annotations: options.fetch(:annotations, {})
      )
    end

    def find_accessible_issue(user, issue_id, permission:, module_name: nil)
      return if issue_id.blank?

      issue = Issue.visible(user).find_by(id: issue_id)
      return unless issue
      return unless module_name.nil? || issue.project.module_enabled?(module_name)
      return unless user.allowed_to?(permission, issue.project)

      issue
    end

    def issue_permission(permission, module_name: nil)
      lambda { |user, _args, _project|
        return true if user.admin?
        return Core::Helpers.any_project_module_allows?(user, permission, module_name) if module_name

        Core::Helpers.any_project_allows?(user, permission)
      }
    end

    def register_issue_tool(name:, description:, permission:, output_schema:, **options, &)
      assert_known_options!(options, ISSUE_TOOL_OPTIONS)
      extension = self
      key = options.fetch(:issue_id_key, :issue_id)
      module_name = options[:module_name]
      schema = options[:input_schema] || {
        properties: {
          key => Core::Helpers::ISSUE_ID_SCHEMA
        },
        required: [key.to_s]
      }

      register_tool_once(
        name: name,
        title: options[:title],
        description: description,
        input_schema: schema,
        output_schema: output_schema,
        permission: issue_permission(permission, module_name: module_name),
        annotations: options.fetch(:annotations, {}),
        handler: lambda { |args, context|
          user = context[:user]
          issue = extension.find_accessible_issue(
            user,
            args[key],
            permission: permission,
            module_name: module_name
          )
          return Core::Helpers.error_result(:error_mcp_issue_not_found) unless issue

          yield(issue, args, context)
        }
      )
    end

    def register_tool(name:, description:, input_schema:, output_schema:, permission:, handler:, **options)
      assert_known_options!(options, TOOL_OPTIONS)
      validate_output_schema!(output_schema)
      Registry.instance.register_tool(
        plugin_id: plugin_id,
        name: name,
        title: options[:title],
        description: description,
        input_schema: input_schema,
        output_schema: output_schema,
        permission: permission,
        handler: handler,
        annotations: options.fetch(:annotations, {})
      )
    end

    def extend_tool(tool_name, extra_params: {}, before: nil, after: nil)
      Registry.instance.extend_tool(
        tool_name,
        plugin_id: plugin_id,
        extra_params: extra_params,
        before: before,
        after: after
      )
    end

    def register_resource(uri:, name:, handler:, **options)
      assert_known_options!(options, RESOURCE_OPTIONS)
      Registry.instance.register_resource(
        plugin_id: plugin_id,
        uri: uri,
        name: name,
        title: options[:title],
        description: options[:description],
        mime_type: options[:mime_type] || 'text/plain',
        permission: options[:permission],
        handler: handler,
        project_resolver: options[:project_resolver]
      )
    end

    def register_prompt(name:, handler:, **options)
      assert_known_options!(options, PROMPT_OPTIONS)
      Registry.instance.register_prompt(
        plugin_id: plugin_id,
        name: name,
        title: options[:title],
        description: options[:description],
        arguments: options.fetch(:arguments, []),
        permission: options[:permission],
        handler: handler,
        meta: options.fetch(:meta, {}),
        project_resolver: options[:project_resolver]
      )
    end

    def on(event, &)
      Registry.instance.on(event, plugin_id: plugin_id, &)
    end

    def register_capability(group, mode, &handler)
      raise ArgumentError, 'handler block is required' unless handler

      Registry.instance.register_capability(
        plugin_id: plugin_id,
        group: group,
        mode: mode,
        handler: handler
      )
    end

    def internal_request(method:, path:, user:, params: nil, body: nil)
      normalized_method = method.to_s.upcase
      raise ArgumentError, "unsupported HTTP method: #{method.inspect}" unless INTERNAL_REQUEST_METHODS.include?(normalized_method)

      InternalRequest.call(
        path,
        user: user,
        method: normalized_method,
        params: params,
        body: body
      )
    end

    def internal_get(path, user:)
      internal_request(method: 'GET', path: path, user: user)
    end

    def internal_request_error?(result)
      InternalRequest.error_response?(result)
    end

    def envelope_output(data_schema)
      RedmineMcp::SchemaNormalizer.envelope_output(data_schema)
    end

    def guard_write!
      RedmineMcp::Core::ReadOnly.guard_write!
    end

    def error_result(key, **)
      RedmineMcp::Core::Helpers.error_result(key, **)
    end

    def model_errors(record)
      RedmineMcp::Core::Helpers.model_errors(record)
    end

    def conflict_if_stale(record, expected_updated_at)
      RedmineMcp::Core::Helpers.conflict_if_stale(record, expected_updated_at)
    end

    def resolve_user_ref(user, value)
      RedmineMcp::Core::Helpers.resolve_user_ref(user, value)
    end

  private

    def assert_known_options!(options, allowed)
      unknown = options.keys - allowed
      return if unknown.empty?

      raise ArgumentError, "unknown keyword#{'s' if unknown.size > 1}: #{unknown.map(&:inspect).join(', ')}"
    end

    def validate_output_schema!(schema)
      return if schema.is_a?(Hash) && schema.present?

      raise ArgumentError, 'output_schema must be a non-empty Hash'
    end

    def tool_full_name(name)
      name_str = name.to_s
      prefix = plugin_id == :redmine ? 'redmine_' : "redmine_#{plugin_id}_"
      return name_str if name_str.start_with?(prefix)

      "#{prefix}#{name_str}"
    end
  end
end
