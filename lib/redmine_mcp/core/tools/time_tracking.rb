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
  module Core
    module Tools
      module TimeTracking
        ENTRY_WHITELIST = %w[hours user_id user_ref project issue_id activity_id comments spent_on].freeze

        IMPORT_TIME_ENTRY_SCHEMA = {
          type: 'object',
          properties: {
            hours: Helpers::HOURS_SCHEMA,
            project: Helpers::PROJECT_SCHEMA,
            issue_id: Helpers::ISSUE_ID_SCHEMA,
            user_id: Helpers::USER_ID_SCHEMA,
            activity_id: Helpers::ACTIVITY_ID_SCHEMA,
            comments: Helpers::TIME_ENTRY_COMMENTS_SCHEMA,
            spent_on: Helpers::SPENT_ON_SCHEMA
          },
          required: ['hours'],
          oneOf: Helpers::TIME_ENTRY_TARGET_ONE_OF
        }.freeze

      module_function

        def register!
          register_list_time_entries
          register_create_time_entry
          register_update_time_entry
          register_list_time_entry_activities
          register_import_time_entries
        end

        def register_list_time_entries
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_time_entries',
            title: 'List time entries',
            description: 'Return a paginated list of time entries visible to the current user. Optional filters: project, issue_id, user_id, user_ref with me, from_date, and to_date. Each item ' \
                         'includes hours, spent_on, activity, project, issue, user, and comments. Use to review logged time or obtain time_entry_id before redmine_update_time_entry. Default limit ' \
                         '25, ' \
                         'maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                issue_id: {type: 'integer', minimum: 1, description: 'Numeric issue ID to filter time entries.'},
                user_id: Helpers::USER_ID_SCHEMA,
                user_ref: Helpers::USER_REF_SCHEMA,
                from_date: {type: 'string', format: 'date', description: 'Start date filter (YYYY-MM-DD)'},
                to_date: {type: 'string', format: 'date', description: 'End date filter (YYYY-MM-DD)'}
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_TIME_ENTRIES,
            permission: :view_time_entries,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_time_entries)
          )
        end

        def register_create_time_entry
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_time_entry',
            title: 'Create time entry',
            description: 'Log one time entry on a project or issue. Requires hours and either project or issue_id; optional fields include activity_id, comments, spent_on, and user_id. Returns ' \
                         'the created time entry object. Requires log_time on the target project. Blocked when MCP read-only mode is enabled. Call redmine_list_time_entry_activities when ' \
                         'activity_id is ' \
                         'unknown. Optional idempotency_key prevents a duplicate time entry on retry.',
            input_schema: {
              properties: {
                hours: Helpers::HOURS_SCHEMA,
                project: Helpers::PROJECT_SCHEMA,
                issue_id: Helpers::ISSUE_ID_SCHEMA,
                user_id: Helpers::USER_ID_SCHEMA,
                activity_id: Helpers::ACTIVITY_ID_SCHEMA,
                comments: Helpers::TIME_ENTRY_COMMENTS_SCHEMA,
                spent_on: Helpers::SPENT_ON_SCHEMA,
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              },
              required: ['hours'],
              oneOf: Helpers::TIME_ENTRY_TARGET_ONE_OF
            },
            output_schema: RedmineMcp::Core::OutputSchemas::TIME_ENTRY,
            permission: ->(user, args, _project) { create_time_entry_allowed?(user, args) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_time_entry)
          )
        end

        def register_update_time_entry
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_time_entry',
            title: 'Update time entry',
            description: 'Update one existing time entry by time_entry_id. Supply only fields that should change: hours, activity_id, comments, or spent_on; at least one mutable field besides ' \
                         'time_entry_id is required. Optional expected_updated_at rejects the update with CONFLICT if the entry changed since that timestamp. Returns the updated time entry object. ' \
                         'Requires edit_time_entries, or edit_own_time_entries when updating your own entry. Blocked ' \
                         'when MCP read-only mode is enabled. Call redmine_list_time_entries when time_entry_id is unknown.',
            input_schema: {
              properties: {
                time_entry_id: {type: 'integer', minimum: 1, description: 'Time entry ID from redmine_list_time_entries.'},
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA,
                hours: Helpers::HOURS_SCHEMA,
                activity_id: Helpers::ACTIVITY_ID_SCHEMA,
                comments: Helpers::TIME_ENTRY_COMMENTS_SCHEMA,
                spent_on: Helpers::SPENT_ON_SCHEMA
              },
              required: ['time_entry_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::TIME_ENTRY,
            permission: ->(user, args, _project) { update_time_entry_allowed?(user, args) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_time_entry)
          )
        end

        def register_list_time_entry_activities
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_time_entry_activities',
            title: 'List time entry activities',
            description: 'Return a paginated list of time logging activity types. Without project, returns global shared activities; with project, returns activities enabled for that ' \
                         'project. Each item includes id, name, active, and is_default. Use before redmine_create_time_entry or redmine_import_time_entries when activity_id is unknown. Default ' \
                         'limit 25, maximum ' \
                         '100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ACTIVITIES,
            permission: ->(user, args, project) { time_activities_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_time_entry_activities)
          )
        end

        def register_import_time_entries
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'import_time_entries',
            title: 'Import time entries',
            description: 'Bulk-create up to 500 time entries in one call. Each entry uses the same fields as redmine_create_time_entry. Optional idempotency_key makes retries after timeout return ' \
                         'the same ' \
                         'result instead of creating duplicates. Returns total, succeeded, failed, created items, and per-entry errors. By default continues after failures; set stop_on_error=true ' \
                         'to abort on the first error. Requires log_time on each target project. Blocked when MCP read-only mode is enabled. For a single entry, use redmine_create_time_entry ' \
                         'instead.',
            input_schema: {
              properties: {
                entries: {
                  type: 'array',
                  minItems: 1,
                  maxItems: 500,
                  description: 'List of time entries to import (max 500 per call).',
                  items: IMPORT_TIME_ENTRY_SCHEMA
                },
                stop_on_error: {type: 'boolean', description: 'Abort on the first error. Default: false'},
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              },
              required: ['entries']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::IMPORT_TIME_ENTRIES,
            permission: ->(user, _args, _project) { import_time_entries_allowed?(user) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:import_time_entries)
          )
        end

        def list_time_entries(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = TimeEntry.visible(user)

          if args[:project].present?
            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project

            scope = scope.where(project_id: project.id)
          end
          scope = scope.where(issue_id: args[:issue_id]) if args[:issue_id].present?
          if args[:user_ref].present?
            scope = scope.where(user_id: Helpers.resolve_user_ref(user, args[:user_ref]))
          elsif args[:user_id].present?
            scope = scope.where(user_id: args[:user_id])
          end
          scope = scope.where(spent_on: (args[:from_date])..) if args[:from_date].present?
          scope = scope.where(spent_on: ..(args[:to_date])) if args[:to_date].present?

          total = scope.count
          items = scope.order(spent_on: :desc, id: :desc).offset(offset).limit(limit).map do |entry|
            Helpers.serialize_time_entry(entry)
          end
          Helpers.paginated_list(items, total_count: total, limit: limit, offset: offset)
        end

        def create_time_entry(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'create_time_entry', key: args[:idempotency_key], args: args) do
            create_time_entry_once(args, context)
          end
        end

        def create_time_entry_once(args, context)
          user = context[:user]
          return Helpers.error_result(:error_mcp_invalid_parameters) if args[:hours].blank?

          project, issue, err = resolve_time_entry_target(user, args)
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:log_time, project)

          entry = build_time_entry(user, project, issue, args)
          return Helpers.model_errors(entry) unless entry.save

          Helpers.serialize_time_entry(entry)
        end

        def update_time_entry(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          entry = TimeEntry.visible(user).find_by(id: args[:time_entry_id])
          return Helpers.error_result(:error_mcp_time_entry_not_found) unless entry
          return Helpers.error_result(:error_mcp_permission_denied) unless entry.editable_by?(user)

          conflict = Helpers.conflict_if_stale(entry, args[:expected_updated_at])
          return conflict if conflict

          attrs = time_entry_update_attributes(args, user)
          return Helpers.error_result(:error_mcp_invalid_parameters) if attrs.empty?

          entry.send(:safe_attributes=, attrs, user)
          return Helpers.model_errors(entry) unless entry.save

          Helpers.serialize_time_entry(entry.reload)
        end

        def list_time_entry_activities(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])

          if args[:project].present?
            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project
            return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:log_time, project)

            activities = project.activities.to_a.sort_by { |activity| [activity.position.to_i, activity.id.to_i] }
            extra_meta = {project_id: Helpers.integer_id(project.id)}
            extra_meta[:note] = I18n.t(:text_mcp_no_project_activities) if activities.empty?
            Helpers.paginate_collection(activities, limit: limit, offset: offset, **extra_meta) do |activity|
              serialize_activity(activity)
            end
          else
            Helpers.paginate_collection(Helpers.with_id_order(TimeEntryActivity.shared.active.sorted), limit: limit, offset: offset) do |activity|
              serialize_activity(activity)
            end
          end
        end

        def import_time_entries(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'import_time_entries', key: args[:idempotency_key], args: args) do
            import_time_entries_once(args, context)
          end
        end

        def import_time_entries_once(args, context)
          user = context[:user]
          entries = Array(args[:entries])
          return Helpers.error_result(:error_mcp_invalid_parameters) if entries.empty?
          return Helpers.error_result(:error_mcp_invalid_parameters) if entries.size > 500

          stop_on_error = Helpers.truthy?(args[:stop_on_error])
          created = []
          errors = []

          ActiveRecord::Base.transaction do
            entries.each_with_index do |raw_entry, index|
              entry_data = raw_entry.is_a?(Hash) ? raw_entry.deep_symbolize_keys : {}
              filtered = entry_data.slice(*ENTRY_WHITELIST.map(&:to_sym))
              result = create_imported_entry(user, filtered)
              if result[:error]
                errors << {index: index, entry: entry_data, error: result[:error]}
                break if stop_on_error
              else
                created << result
              end
            end
          end

          {
            total: entries.size,
            succeeded: created.size,
            failed: errors.size,
            created: created,
            errors: errors
          }
        end

        def resolve_time_entry_target(user, args)
          if args[:issue_id].present?
            issue = Issue.visible(user).find_by(id: args[:issue_id])
            return [nil, nil, Helpers.error_result(:error_mcp_issue_not_found)] unless issue

            [issue.project, issue, nil]
          elsif args[:project].present?
            project = Helpers.find_project(user, args[:project])
            return [nil, nil, Helpers.error_result(:error_mcp_project_not_found)] unless project

            [project, nil, nil]
          else
            [nil, nil, Helpers.error_result(:error_mcp_invalid_parameters)]
          end
        end

        def create_imported_entry(user, entry_data)
          return Helpers.error_result(:error_mcp_invalid_parameters) if entry_data[:hours].blank?

          project, issue, err = resolve_time_entry_target(user, entry_data)
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:log_time, project)

          entry = build_time_entry(user, project, issue, entry_data)
          return Helpers.model_errors(entry) unless entry.save

          Helpers.serialize_time_entry(entry)
        end

        def build_time_entry(user, project, issue, args)
          entry = TimeEntry.new(project: project, issue: issue, author: user)
          attrs = {
            'hours' => args[:hours],
            'activity_id' => args[:activity_id].presence || TimeEntryActivity.default_activity_id(user, project),
            'spent_on' => parse_spent_on(args[:spent_on], user),
            'user_id' => args[:user_id].presence || user.id
          }
          attrs['comments'] = args[:comments].to_s if args.key?(:comments)
          attrs['issue_id'] = issue.id if issue
          entry.send(:safe_attributes=, attrs, user)
          entry
        end

        def time_entry_update_attributes(args, user)
          attrs = {}
          attrs['hours'] = args[:hours] if args.key?(:hours)
          attrs['activity_id'] = args[:activity_id] if args.key?(:activity_id)
          attrs['comments'] = args[:comments].to_s if args.key?(:comments)
          attrs['spent_on'] = parse_spent_on(args[:spent_on], user) if args.key?(:spent_on)
          attrs
        end

        def parse_spent_on(value, user)
          return user.today if value.blank?

          Date.parse(value.to_s)
        rescue ArgumentError
          nil
        end

        def serialize_activity(activity)
          {
            id: Helpers.integer_id(activity.id),
            name: activity.name,
            active: activity.active?,
            is_default: activity.is_default?
          }
        end

        def create_time_entry_allowed?(user, args)
          return Helpers.any_project_allows?(user, :log_time) if args[:project].blank? && args[:issue_id].blank?

          project, _issue, err = resolve_time_entry_target(user, args)
          return false if err

          user.allowed_to?(:log_time, project)
        end

        def update_time_entry_allowed?(user, _args)
          Helpers.any_project_allows?(user, :edit_time_entries) ||
            Helpers.any_project_allows?(user, :edit_own_time_entries)
        end

        def time_activities_allowed?(user, args, project)
          if args[:project].present?
            project ||= Helpers.find_project(user, args[:project])
            project && user.allowed_to?(:log_time, project)
          else
            import_time_entries_allowed?(user)
          end
        end

        def import_time_entries_allowed?(user)
          Helpers.any_project_allows?(user, :log_time)
        end
      end
    end
  end
end
