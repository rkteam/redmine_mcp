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
      module Discovery
      module_function

        def register!
          register_list_trackers
          register_list_project_trackers
          register_list_issue_statuses
          register_list_issue_priorities
          register_list_all_users
          register_get_current_user
          register_list_queries
        end

        def register_list_trackers
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_trackers',
            title: 'List issue trackers',
            description: 'Return a paginated list of all issue tracker types defined in the Redmine instance (for example Bug, Feature, Support). Each item includes id, name, and description. Use ' \
                         'before redmine_create_issue or redmine_update_issue when tracker_id is unknown. For trackers enabled in one project only, use redmine_list_project_trackers with project ' \
                         'instead. Default ' \
                         'limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_TRACKERS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_trackers)
          )
        end

        def register_list_project_trackers
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_project_trackers',
            title: 'List project trackers',
            description: 'Return a paginated list of issue trackers enabled for one project. Each item includes id and name. Use before redmine_create_issue or redmine_update_issue when tracker_id ' \
                         'must match ' \
                         'project configuration. For the global tracker catalog with descriptions, use redmine_list_trackers instead. Requires project; call redmine_list_projects first when it is ' \
                         'unknown. ' \
                         'Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_PROJECT_TRACKERS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_project_trackers)
          )
        end

        def register_list_issue_statuses
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_statuses',
            title: 'List issue statuses',
            description: 'Return a paginated list of all issue workflow statuses in the Redmine instance. Each item includes id, name, and is_closed. Use before redmine_create_issue or ' \
                         'redmine_update_issue when ' \
                         'status_id is unknown or to interpret open versus closed issues. Does not include allowed transitions for a specific issue; use redmine_get_issue_form_options ' \
                         'when needed. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_STATUSES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_statuses)
          )
        end

        def register_list_issue_priorities
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_priorities',
            title: 'List issue priorities',
            description: 'Return a paginated list of active issue priority levels in the Redmine instance. Each item includes id, name, active, and is_default. Use before redmine_create_issue or ' \
                         'redmine_update_issue when priority_id is unknown. For workflow states, use redmine_list_issue_statuses instead. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_PRIORITIES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_priorities)
          )
        end

        def register_list_all_users
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_all_users',
            title: 'List all users',
            description: 'Return a paginated global directory of active Redmine users. Requires administrator permission. Optional filters: name substring (login, first name, last name, or email) ' \
                         'and group_id. Use for admin workflows when project scope is irrelevant; for project member lookup or assignment, prefer redmine_list_users with project. Each item ' \
                         'includes id, login, name parts, mail, and created_on. Does not modify Redmine.',
            input_schema: {
              properties: {
                name: {type: 'string', description: 'Case-insensitive substring filter'},
                group_id: {type: 'integer', minimum: 1, description: 'Filter users who belong to a specific group'}
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ALL_USERS,
            permission: ->(user, _args, _project) { user.admin? },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_all_users)
          )
        end

        def register_get_current_user
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_current_user',
            title: 'Get current user',
            description: 'Return the profile of the currently authenticated MCP user: id, login, name parts, mail, admin flag, created_on, and last_login_on. Use to confirm identity and ' \
                         'permissions before user-scoped or admin operations. Does not include project memberships or roles. Does not modify Redmine. For server version and read-only mode, use ' \
                         'redmine_get_server_info.',
            input_schema: {properties: {}},
            output_schema: RedmineMcp::Core::OutputSchemas::CURRENT_USER,
            permission: :use_mcp,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_current_user)
          )
        end

        def register_list_queries
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_queries',
            title: 'List saved queries',
            description: 'Return a paginated list of saved issue queries visible to the current user (private and public). Each item includes id, name, is_public, and project_id when the query is ' \
                         'project-scoped. Use to discover query_id before redmine_run_issue_query. Does not execute the query or return matching issues. Default limit 25, maximum 100. Does not ' \
                         'modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_QUERIES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_queries)
          )
        end

        def list_trackers(args, _context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(Tracker.sorted), limit: limit, offset: offset) do |tracker|
            {id: Helpers.integer_id(tracker.id), name: tracker.name, description: tracker.description.to_s}
          end
        end

        def list_project_trackers(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(project.trackers.sorted), limit: limit, offset: offset) do |tracker|
            {id: Helpers.integer_id(tracker.id), name: tracker.name}
          end
        end

        def list_issue_statuses(args, _context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(IssueStatus.sorted), limit: limit, offset: offset) do |status|
            {id: Helpers.integer_id(status.id), name: status.name, is_closed: status.is_closed?}
          end
        end

        def list_issue_priorities(args, _context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(IssuePriority.active.sorted), limit: limit, offset: offset) do |priority|
            {
              id: Helpers.integer_id(priority.id),
              name: priority.name,
              active: priority.active?,
              is_default: priority.is_default?
            }
          end
        end

        def list_all_users(args, context)
          user = context[:user]
          return Helpers.error_result(:error_mcp_permission_denied) unless user.admin?

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = User.active
          scope = scope.like(args[:name]) if args[:name].present?
          scope = scope.in_group(args[:group_id]) if args[:group_id].present?
          scope = scope.order(:login, :id)

          total = scope.count
          items = scope.offset(offset).limit(limit).map do |item|
            {
              id: Helpers.integer_id(item.id),
              login: item.login,
              firstname: item.firstname,
              lastname: item.lastname,
              mail: item.mail,
              created_on: item.created_on
            }
          end
          Helpers.paginated_list(items, total_count: total, limit: limit, offset: offset)
        end

        def get_current_user(_args, context)
          user = context[:user]
          {
            id: Helpers.integer_id(user.id),
            login: user.login,
            firstname: user.firstname,
            lastname: user.lastname,
            mail: user.mail,
            admin: user.admin?,
            created_on: user.created_on,
            last_login_on: user.last_login_on
          }
        end

        def list_queries(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          queries = IssueQuery.visible(user).sorted
          Helpers.paginate_collection(Helpers.with_id_order(queries), limit: limit, offset: offset) do |query|
            {
              id: Helpers.integer_id(query.id),
              name: query.name,
              is_public: query.visibility == Query::VISIBILITY_PUBLIC,
              project_id: Helpers.integer_id(query.project_id)
            }
          end
        end
      end
    end
  end
end
