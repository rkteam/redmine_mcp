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
      module Projects
        VERSION_STATUSES = %w[open locked closed].freeze
        VERSION_SHARING = %w[none descendants hierarchy tree system].freeze
        VERSION_ID_SCHEMA = {
          type: 'integer',
          minimum: 1,
          description: 'Roadmap version (milestone) ID from redmine_list_versions.'
        }.freeze
        VERSION_NAME_SCHEMA = {
          type: 'string',
          minLength: 1,
          maxLength: 60,
          description: 'Version name.'
        }.freeze
        VERSION_DESCRIPTION_SCHEMA = {
          type: 'string',
          maxLength: 255,
          description: 'Version description.'
        }.freeze
        VERSION_DUE_DATE_SCHEMA = {
          type: 'string',
          format: 'date',
          description: 'Due date in YYYY-MM-DD format.'
        }.freeze
        VERSION_WIKI_PAGE_TITLE_SCHEMA = {
          type: 'string',
          minLength: 1,
          maxLength: 255,
          description: 'Linked wiki page title.'
        }.freeze

      module_function

        def register!
          register_list_projects
          register_get_project
          register_list_project_issue_custom_fields
          register_summarize_project_status
          register_list_project_activities
          register_list_versions
          register_get_version
          register_create_version
          register_update_version
          register_delete_version
          register_list_project_members
          register_list_project_member_candidates
          register_list_roles
          register_get_project_modules
          register_add_project_member
          register_update_project_member
          register_remove_project_member
        end

        def register_list_projects
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_projects',
            title: 'List projects',
            description: 'Return a paginated list of Redmine projects visible to the current user. Each item includes id, name, identifier, and description. Use when project is unknown before ' \
                         'project-scoped tools such as redmine_list_issues or redmine_list_project_members. Default limit 25, maximum 100; result includes total_count, limit, offset, and has_more. ' \
                         'Does not ' \
                         'include members, modules, or issue statistics. Does not modify Redmine.',
            input_schema: {
              properties: Helpers::PAGINATION_INPUT.merge({})
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_PROJECTS,
            permission: :view_project,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_projects)
          )
        end

        def register_get_project
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_project',
            title: 'Get project',
            description: 'Return one Redmine project by id or identifier, including description, homepage, status, ' \
                         'visibility, parent, visible subprojects, custom fields, and last_activity_date. Use when ' \
                         'project details are needed beyond redmine_list_projects. Does not include members, modules, ' \
                         'or issue statistics. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              },
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::PROJECT,
            permission: :view_project,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_project)
          )
        end

        def register_list_project_issue_custom_fields
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_project_issue_custom_fields',
            title: 'List project issue custom fields',
            description: 'Return a paginated list of issue custom fields available in one project, including field format, required flag, default value, possible values, and tracker bindings. Use ' \
                         'before redmine_create_issue or redmine_update_issue when custom field IDs or allowed values are unknown. Optional tracker_id limits fields to one tracker. Requires project' \
                         '; call ' \
                         'redmine_list_projects or redmine_list_project_trackers first when needed. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                tracker_id: Helpers::POSITIVE_ID_SCHEMA.merge(description: 'Restrict output to fields applicable to the given tracker ID')
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_CUSTOM_FIELDS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_project_issue_custom_fields)
          )
        end

        def register_summarize_project_status
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'summarize_project_status',
            title: 'Summarize project status',
            description: 'Return a server-built project health summary for one project over a recent time window. This is not a Redmine object; the MCP server computes deterministic metrics from ' \
                         'visible issues and time entries. Includes issue totals, open and closed counts, recent created and updated counts, ' \
                         'breakdowns by status, priority, and assignee, plus metrics such as overdue_count, unassigned_count, stale_issues_count, issues_closed_during_period, ' \
                         'estimated_hours, spent_hours, average_resolution_hours, estimation_accuracy, and reopened_count. Use for dashboards instead of aggregating redmine_list_issues manually. ' \
                         'days defaults to 30 and is clamped between 1 and 365. Requires project. Does not return individual issues; use redmine_list_issues for issue lists. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                days: {
                  type: 'integer',
                  default: 30,
                  minimum: 1,
                  maximum: 365,
                  description: 'Number of days to analyze. Default: 30'
                }
              },
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::PROJECT_STATUS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:summarize_project_status)
          )
        end

        def register_list_project_activities
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_project_activities',
            title: 'List project activities',
            description: 'Return a paginated activity feed for one project (events such as issue and wiki changes). This is not the time-logging activity catalog; for time entry activity types use ' \
                         'redmine_list_time_entry_activities. Each item includes event type, datetime, ' \
                         'author, title, description, and url. Newest events first. Optional from/to (YYYY-MM-DD), author_id, and ' \
                         'event_types. Default window is the last 7 days; maximum window length is 90 days. Requires ' \
                         'project. Use for "what happened" timelines; use redmine_summarize_project_status for aggregates. ' \
                         'Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                from: {type: 'string', format: 'date', description: 'Start date YYYY-MM-DD. Default: today minus 6 days.'},
                to: {type: 'string', format: 'date', description: 'End date YYYY-MM-DD. Default: today.'},
                author_id: Helpers::USER_ID_SCHEMA.merge(description: 'Restrict events to this author user ID.'),
                event_types: {
                  type: 'array',
                  items: {type: 'string', minLength: 1},
                  description: 'Activity event types to include. Unavailable types are skipped.'
                }
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ACTIVITY_EVENTS,
            permission: :view_project,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_project_activities)
          )
        end

        def register_list_versions
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_versions',
            title: 'List project versions',
            description: 'Return a paginated list of Redmine roadmap versions (milestones) for one project, including shared versions. A version is a project milestone, not a software product ' \
                         'release. Each item includes id, name, status, due date, sharing, and project ' \
                         'reference. Optional status_filter accepts open, locked, or closed. Use before redmine_create_issue or redmine_update_issue when fixed_version_id is unknown. Requires ' \
                         'project. For ' \
                         'creating or changing versions, use redmine_create_version or redmine_update_version. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                status_filter: {
                  type: 'string',
                  enum: VERSION_STATUSES,
                  description: Helpers::VERSION_STATUS_DESCRIPTION
                }
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_VERSIONS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_versions)
          )
        end

        def register_get_version
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_version',
            title: 'Get project version',
            description: 'Return one Redmine roadmap version (milestone, not a software product release) by version_id with aggregates: issues_count, open_issues_count, ' \
                         'closed_issues_count, estimated_hours, spent_hours, and completed_percent. Optional project selects a ' \
                         'visible project whose shared versions include this version_id. Without project, the version must be ' \
                         'visible on its source project. Does not return the issue list. Call ' \
                         'redmine_list_versions when version_id is unknown. Does not modify Redmine.',
            input_schema: {
              properties: {
                version_id: VERSION_ID_SCHEMA,
                project: Helpers::PROJECT_SCHEMA
              },
              required: ['version_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::VERSION_DETAIL,
            permission: ->(user, args, _project) { get_version_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_version)
          )
        end

        def register_create_version
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_version',
            title: 'Create project version',
            description: 'Create one roadmap version in a Redmine project. Requires project and name; optional fields include description, status, due_date, sharing, and wiki_page_title. ' \
                         'Returns the created version object. Requires manage_versions on the project. Blocked when MCP read-only mode is enabled. Call redmine_list_versions first when checking ' \
                         'for ' \
                         '' \
                         '' \
                         '' \
                         'duplicate names. To change an existing version, use redmine_update_version.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                name: VERSION_NAME_SCHEMA,
                description: VERSION_DESCRIPTION_SCHEMA,
                status: {type: 'string', enum: VERSION_STATUSES, description: Helpers::VERSION_STATUS_DESCRIPTION},
                due_date: VERSION_DUE_DATE_SCHEMA,
                sharing: {type: 'string', enum: VERSION_SHARING, description: 'Version sharing scope.'},
                wiki_page_title: VERSION_WIKI_PAGE_TITLE_SCHEMA
              },
              required: %w[project name]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::VERSION,
            permission: ->(user, args, project) { create_version_allowed?(user, args, project) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_version)
          )
        end

        def register_update_version
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_version',
            title: 'Update project version',
            description: 'Update one roadmap version by version_id. Supply only fields that should change: name, ' \
                         'description, status, due_date, sharing, or wiki_page_title. Pass null for due_date or ' \
                         'wiki_page_title to clear them. Optional expected_updated_at rejects the update with ' \
                         'CONFLICT if the version changed since that timestamp. Returns the updated version object. ' \
                         'Requires manage_versions on the version project. Blocked when MCP read-only mode is ' \
                         'enabled. Call redmine_list_versions when version_id is unknown.',
            input_schema: {
              properties: {
                version_id: VERSION_ID_SCHEMA,
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA,
                name: VERSION_NAME_SCHEMA,
                description: VERSION_DESCRIPTION_SCHEMA,
                status: {type: 'string', enum: VERSION_STATUSES, description: Helpers::VERSION_STATUS_DESCRIPTION},
                due_date: {
                  oneOf: [
                    {type: 'string', format: 'date'},
                    {type: 'null'},
                  ],
                  description: 'Due date in YYYY-MM-DD format, or null to clear it.'
                },
                sharing: {type: 'string', enum: VERSION_SHARING, description: 'Version sharing scope.'},
                wiki_page_title: {
                  oneOf: [
                    {type: 'string', maxLength: 255},
                    {type: 'null'},
                  ],
                  description: 'Linked wiki page title, or null to clear it.'
                }
              },
              required: ['version_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::VERSION,
            permission: ->(user, args, _project) { update_version_allowed?(user, args) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_version)
          )
        end

        def register_delete_version
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_version',
            title: 'Delete project version',
            description: 'Permanently delete one roadmap version by version_id. Optional expected_updated_at rejects deletion with CONFLICT if the version changed since that timestamp. Returns the ' \
                         'deleted version_id only, not the full former record. Requires manage_versions on the version project. Versions that still have issues, custom field references, or ' \
                         'attachments cannot be deleted. Blocked when MCP read-only mode is enabled. This operation cannot be ' \
                         'undone through MCP. Call redmine_list_versions when version_id is unknown.',
            input_schema: {
              properties: {
                version_id: VERSION_ID_SCHEMA,
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA
              },
              required: ['version_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_VERSION,
            permission: ->(user, args, _project) { delete_version_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_version)
          )
        end

        def register_list_project_members
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_project_members',
            title: 'List project members',
            description: 'Return a paginated list of members for one project, including users or groups and their assigned roles. Each item includes membership id, principal reference, project ' \
                         'reference, and role list. Use to obtain membership_id before redmine_update_project_member or redmine_remove_project_member, and to distinguish project members from the ' \
                         'global user ' \
                         'directory in redmine_list_users or redmine_admin_list_users. To find people or groups to add, use ' \
                         'redmine_list_project_member_candidates. Requires project and view_members. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_MEMBERS,
            permission: :view_members,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_project_members)
          )
        end

        def register_list_project_member_candidates
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_project_member_candidates',
            title: 'List project member candidates',
            description: 'Return a paginated list of active users and groups that the current user can see and that are not ' \
                         'already members of the project. Each item includes id, name, and type (user or group); users also ' \
                         'include login. Optional query filters by the same substring rules as the Redmine member picker. ' \
                         'Use before redmine_add_project_member when adding someone who is not yet on the project. Requires ' \
                         'project and manage_members. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                query: {
                  type: 'string',
                  description: 'Case-insensitive substring match against principal name or login.'
                }
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_MEMBER_CANDIDATES,
            permission: :manage_members,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_project_member_candidates)
          )
        end

        def register_list_roles
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_roles',
            title: 'List roles',
            description: 'Return a paginated list of roles the current user can assign on one project (id and name). ' \
                         'Requires project and manage_members. Use before redmine_add_project_member or ' \
                         'redmine_update_project_member when role IDs are unknown. Does not include builtin Non member or ' \
                         'Anonymous roles. Does not show users assigned to each role; for project membership with roles, use ' \
                         'redmine_list_project_members. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ROLES,
            permission: ->(user, args, project) { list_roles_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_roles)
          )
        end

        def register_get_project_modules
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_project_modules',
            title: 'Get project modules',
            description: 'Return enabled Redmine module names for one project, such as issue_tracking, wiki, or time_tracking. Use before project-scoped tools when a feature may be disabled for ' \
                         'the project. Requires project. Returns one object with project_id, project_name, and enabled_modules. Does not include member, issue, or version data. Does not modify ' \
                         'Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              },
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::PROJECT_MODULES,
            permission: :view_project,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_project_modules)
          )
        end

        def register_add_project_member
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'add_project_member',
            title: 'Add project member',
            description: 'Add one user or group to a project with one or more roles. Requires project, role_ids, and exactly one of user_id or group_id. Returns the created membership with ' \
                         'principal and role references. Requires manage_members on the project. Requested roles must all be manageable by the current user; unmanaged roles are rejected, not ' \
                         'silently dropped. Blocked when MCP read-only mode is enabled. Call redmine_list_roles for role IDs and ' \
                         'redmine_list_project_member_candidates for user or group IDs of people not yet on the project.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                user_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'User ID from redmine_list_project_member_candidates (type user).'
                },
                group_id: {type: 'integer', minimum: 1, description: 'Group ID from redmine_list_project_member_candidates (type group).'},
                role_ids: {
                  type: 'array',
                  minItems: 1,
                  uniqueItems: true,
                  items: {type: 'integer', minimum: 1},
                  description: 'Role IDs from redmine_list_roles.'
                }
              },
              required: %w[project role_ids],
              oneOf: [
                {required: ['user_id'], not: {required: ['group_id']}},
                {required: ['group_id'], not: {required: ['user_id']}},
              ]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::MEMBERSHIP,
            permission: ->(user, args, project) { add_project_member_allowed?(user, args, project) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:add_project_member)
          )
        end

        def register_update_project_member
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_project_member',
            title: 'Update project member',
            description: 'Replace the role set for one existing project membership by membership_id. Requires role_ids with at least one role. Returns the updated membership with principal and ' \
                         'role references. Requires manage_members on the membership project. Requested roles must all be manageable by the current user; unmanaged roles are rejected, not silently ' \
                         'dropped. Blocked when MCP read-only mode is enabled. Call redmine_list_project_members first to obtain ' \
                         'membership_id ' \
                         'and redmine_list_roles for role IDs.',
            input_schema: {
              properties: {
                membership_id: {type: 'integer', minimum: 1, description: 'Membership ID from redmine_list_project_members.'},
                role_ids: {
                  type: 'array',
                  minItems: 1,
                  uniqueItems: true,
                  items: {type: 'integer', minimum: 1},
                  description: 'Role IDs from redmine_list_roles.'
                }
              },
              required: %w[membership_id role_ids]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::MEMBERSHIP,
            permission: ->(user, args, _project) { update_project_member_allowed?(user, args) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_project_member)
          )
        end

        def register_remove_project_member
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'remove_project_member',
            title: 'Remove project member',
            description: 'Remove one project membership by membership_id. Returns deleted_membership_id only. Requires manage_members on the membership project. Blocked when MCP read-only mode is ' \
                         'enabled. This removes project access for the user or group and cannot be undone through MCP. Call redmine_list_project_members first to obtain membership_id.',
            input_schema: {
              properties: {
                membership_id: {type: 'integer', minimum: 1, description: 'Membership ID from redmine_list_project_members.'}
              },
              required: ['membership_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_MEMBERSHIP,
            permission: ->(user, args, _project) { remove_project_member_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:remove_project_member)
          )
        end

        def list_projects(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = Project.visible(user).sorted
          total = scope.count
          items = Helpers.with_id_order(scope).offset(offset).limit(limit).map do |project|
            {
              id: project.id,
              name: project.name,
              identifier: project.identifier,
              description: project.description.to_s
            }
          end
          Helpers.paginated_list(items, total_count: total, limit: limit, offset: offset)
        end

        def get_project(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          serialize_project_detail(project, user)
        end

        def list_project_issue_custom_fields(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          fields = project.all_issue_custom_fields.select { |field| field.visible_by?(project, user) }
          if args[:tracker_id].present?
            tracker = project.trackers.find_by(id: args[:tracker_id])
            return Helpers.error_result(:error_mcp_invalid_parameters) unless tracker

            fields = fields.select { |cf| cf.trackers.empty? || cf.trackers.include?(tracker) }
          end

          fields = fields.sort_by { |field| [field.position.to_i, field.id.to_i] }

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(fields, limit: limit, offset: offset) do |field|
            serialize_custom_field(field)
          end
        end

        def summarize_project_status(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          days = (args[:days].presence || 30).to_i
          days = 1 if days < 1
          days = 365 if days > 365
          since = days.days.ago
          today = user.today

          scope = Issue.visible(user).where(project_id: project.id)
          open_scope = scope.open
          created = scope.where(issues: {created_on: since..})
          updated = scope.where('issues.updated_on >= ? AND issues.created_on < ?', since, since)
          closed_in_period = scope.where(issues: {closed_on: since..})

          {
            project_id: project.id,
            project_name: project.name,
            analysis_period_days: days,
            recent_activity: {
              created_count: created.count,
              updated_count: updated.count
            },
            status_breakdown: count_by_name(scope, :status),
            priority_breakdown: count_by_name(scope, :priority),
            assignee_breakdown: assignee_breakdown(scope),
            totals: {
              issues_count: scope.count,
              open_count: open_scope.count,
              closed_count: scope.where(status_id: IssueStatus.where(is_closed: true).select(:id)).count
            },
            overdue_count: open_scope.where('issues.due_date < ?', today).count,
            unassigned_count: open_scope.where(assigned_to_id: nil).count,
            stale_issues_count: open_scope.where('issues.updated_on < ?', since).count,
            issues_closed_during_period: closed_in_period.count,
            estimated_hours: summarize_estimated_hours(scope),
            spent_hours: summarize_spent_hours(user, project, scope),
            average_resolution_hours: average_resolution_hours(closed_in_period),
            estimation_accuracy: estimation_accuracy(user, project, closed_in_period),
            reopened_count: reopened_count(scope, since)
          }
        end

        def list_project_activities(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          date_to, date_from, date_err = resolve_activity_window(user, args)
          return date_err if date_err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])

          author = nil
          if args[:author_id].present?
            author = User.active.find_by(id: args[:author_id])
            return Helpers.paginated_list([], total_count: 0, limit: limit, offset: offset) unless author
          end

          fetcher = Redmine::Activity::Fetcher.new(user, project: project, with_subprojects: false, author: author)
          if args[:event_types].present?
            requested = Array(args[:event_types]).map(&:to_s)
            fetcher.scope = requested
          else
            fetcher.scope = :all
          end

          events = fetcher.events(date_from, date_to + 1)
          events = events.sort_by do |event|
            datetime = event.event_datetime
            identifier = event.respond_to?(:id) ? event.id.to_i : 0
            [datetime || Time.zone.at(0), identifier]
          end.reverse
          Helpers.paginate_collection(events, limit: limit, offset: offset) do |event|
            serialize_activity_event(event)
          end
        end

        def list_versions(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          versions = project.shared_versions.sorted
          if args[:status_filter].present?
            status = args[:status_filter].to_s
            return Helpers.error_result(:error_mcp_invalid_parameters) unless %w[open locked closed].include?(status)

            versions = versions.where(status: status)
          end

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(versions), limit: limit, offset: offset) do |version|
            serialize_version(version)
          end
        end

        def get_version(args, context)
          user = context[:user]
          version = find_visible_version(user, args[:version_id], project: args[:project])
          return Helpers.error_result(:error_mcp_version_not_found) unless version

          serialize_version_detail(version, user)
        end

        def create_version(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          version = project.versions.build
          assign_err = assign_version_attrs(version, args, user: user, create: true)
          return assign_err if assign_err
          return Helpers.model_errors(version) unless version.save

          serialize_version(version)
        end

        def update_version(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          version = find_manageable_version(user, args[:version_id])
          return Helpers.error_result(:error_mcp_version_not_found) unless version

          conflict = Helpers.conflict_if_stale(version, args[:expected_updated_at])
          return conflict if conflict

          assign_err = assign_version_attrs(version, args, user: user, create: false)
          return assign_err if assign_err
          return Helpers.model_errors(version) unless version.save

          serialize_version(version)
        end

        def delete_version(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          version = find_manageable_version(user, args[:version_id])
          return Helpers.error_result(:error_mcp_version_not_found) unless version

          conflict = Helpers.conflict_if_stale(version, args[:expected_updated_at])
          return conflict if conflict

          unless version.deletable?
            return Helpers.mcp_error(
              code: 'INVALID_STATE',
              message: I18n.t(:notice_unable_delete_version),
              details: {reason: 'not_deletable'}
            )
          end

          version_id = version.id
          version.destroy
          {version_id: version_id}
        end

        def list_project_members(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          members = project.memberships.includes(:principal, :roles, :member_roles).order(:id)
          Helpers.paginate_collection(members, limit: limit, offset: offset) do |member|
            serialize_membership(member, project)
          end
        end

        def list_project_member_candidates(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = Principal.active.visible(user).sorted.not_member_of(project).like(args[:query])
          Helpers.paginate_collection(Helpers.with_id_order(scope), limit: limit, offset: offset) do |principal|
            serialize_member_candidate(principal)
          end
        end

        def list_roles(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          roles = user.managed_roles(project).sort_by { |role| [role.position.to_i, role.id.to_i] }
          Helpers.paginate_collection(roles, limit: limit, offset: offset) do |role|
            {id: Helpers.integer_id(role.id), name: role.name}
          end
        end

        def get_project_modules(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          {
            project_id: project.id,
            project_name: project.name,
            enabled_modules: project.enabled_module_names
          }
        end

        def add_project_member(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project
          return Helpers.error_result(:error_mcp_invalid_parameters) if args[:user_id].present? == args[:group_id].present?

          principal =
            if args[:user_id].present?
              User.active.visible(user).find_by(id: args[:user_id])
            else
              Group.givable.visible(user).find_by(id: args[:group_id])
            end
          return Helpers.error_result(:error_mcp_invalid_parameters) unless principal

          role_ids = Array(args[:role_ids]).map(&:to_i)
          return Helpers.error_result(:error_mcp_permission_denied) unless managed_role_ids?(user, project, role_ids)

          member = Member.new(project: project, user_id: principal.id)
          member.set_editable_role_ids(role_ids, user)
          return Helpers.model_errors(member) unless member.save

          serialize_membership(member.reload, project)
        end

        def update_project_member(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          member = find_manageable_membership(user, args[:membership_id])
          return Helpers.error_result(:error_mcp_membership_not_found) unless member

          role_ids = Array(args[:role_ids]).map(&:to_i)
          return Helpers.error_result(:error_mcp_permission_denied) unless managed_role_ids?(user, member.project, role_ids)

          member.set_editable_role_ids(role_ids, user)
          return Helpers.model_errors(member) unless member.save

          serialize_membership(member.reload, member.project)
        end

        def remove_project_member(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          member = find_manageable_membership(user, args[:membership_id])
          return Helpers.error_result(:error_mcp_membership_not_found) unless member
          return Helpers.error_result(:error_mcp_permission_denied) unless member.deletable?

          membership_id = member.id
          member.destroy
          {deleted_membership_id: membership_id}
        end

        def create_version_allowed?(user, args, project)
          project ||= Helpers.find_project(user, args[:project])
          return Helpers.any_project_allows?(user, :manage_versions) if project.nil? && args[:project].blank?

          project && user.allowed_to?(:manage_versions, project)
        end

        def update_version_allowed?(user, args)
          return Helpers.any_project_allows?(user, :manage_versions) if args[:version_id].blank?

          version = ::Version.find_by(id: args[:version_id])
          version && user.allowed_to?(:manage_versions, version.project)
        end

        def delete_version_allowed?(user, args)
          update_version_allowed?(user, args)
        end

        def list_roles_allowed?(user, args, project)
          add_project_member_allowed?(user, args, project)
        end

        def add_project_member_allowed?(user, args, project)
          project ||= Helpers.find_project(user, args[:project])
          return Helpers.any_project_allows?(user, :manage_members) if project.nil? && args[:project].blank?

          project && user.allowed_to?(:manage_members, project)
        end

        def update_project_member_allowed?(user, _args)
          Helpers.any_project_allows?(user, :manage_members)
        end

        def remove_project_member_allowed?(user, args)
          update_project_member_allowed?(user, args)
        end

        def find_manageable_version(user, version_id)
          version = ::Version.find_by(id: version_id)
          return nil unless version
          return nil unless Project.visible(user).exists?(id: version.project_id)
          return nil unless user.allowed_to?(:manage_versions, version.project)

          version
        end

        def find_visible_version(user, version_id, project: nil)
          version = ::Version.find_by(id: version_id)
          return nil unless version

          if project.present?
            target = project.is_a?(Project) ? project : Helpers.find_project(user, project)
            return nil unless target
            return nil unless user.allowed_to?(:view_issues, target)
            return nil unless target.shared_versions.exists?(id: version.id)

            return version
          end

          version = ::Version.visible(user).find_by(id: version_id)
          return nil unless version
          return nil unless Project.visible(user).exists?(id: version.project_id)

          version
        end

        def get_version_allowed?(user, args)
          return Helpers.any_project_allows?(user, :view_issues) if args[:version_id].blank?

          find_visible_version(user, args[:version_id], project: args[:project]).present?
        end

        def find_manageable_membership(user, membership_id)
          member = Member.find_by(id: membership_id)
          return nil unless member
          return nil unless Project.visible(user).exists?(id: member.project_id)
          return nil unless user.allowed_to?(:manage_members, member.project)

          member
        end

        def managed_role_ids?(user, project, role_ids)
          managed = user.managed_roles(project).map(&:id)
          (Array(role_ids).map(&:to_i) - managed).empty?
        end

        def assign_version_attrs(version, args, user:, create:)
          version.name = args[:name] if args.key?(:name) || create
          version.description = args[:description] if args.key?(:description)
          version.status = args[:status].presence || (create ? 'open' : version.status) if args.key?(:status) || create
          version.effective_date = args[:due_date] if args.key?(:due_date)
          sharing_error = assign_version_sharing(version, args, user: user, create: create)
          return sharing_error if sharing_error

          version.wiki_page_title = args[:wiki_page_title] if args.key?(:wiki_page_title)
          nil
        end

        def assign_version_sharing(version, args, user:, create:)
          return unless args.key?(:sharing) || create

          sharing = args[:sharing].presence || (create ? 'none' : version.sharing)
          return Helpers.error_result(:error_mcp_permission_denied) unless version.allowed_sharings(user).include?(sharing)

          version.sharing = sharing
          nil
        end

        def serialize_version(version)
          {
            id: version.id,
            name: version.name,
            description: version.description.to_s,
            status: version.status,
            due_date: version.effective_date&.strftime('%Y-%m-%d'),
            sharing: version.sharing,
            wiki_page_title: version.wiki_page_title.to_s,
            project: Helpers.serialize_named_ref(version.project),
            created_on: version.created_on,
            updated_on: version.updated_on
          }
        end

        def serialize_version_detail(version, user)
          visible_issues = version.fixed_issues.visible(user)
          payload = serialize_version(version).merge(
            issues_count: visible_issues.count,
            open_issues_count: visible_issues.open_count,
            closed_issues_count: visible_issues.closed_count,
            estimated_hours: visible_issues.estimated_hours.to_f,
            completed_percent: visible_issues.completed_percent.to_f
          )
          payload[:spent_hours] =
            (TimeEntry.visible(user).where(issue_id: visible_issues.select(:id)).sum(:hours).to_f if user.allowed_to?(:view_time_entries, version.project))
          payload
        end

        def serialize_project_detail(project, user)
          {
            id: Helpers.integer_id(project.id),
            name: project.name,
            identifier: project.identifier,
            description: project.description.to_s,
            homepage: project.homepage.to_s,
            status: project.status,
            is_public: project.is_public?,
            inherit_members: project.inherit_members?,
            created_on: project.created_on,
            updated_on: project.updated_on,
            parent: (Helpers.serialize_project(project.parent) if project.parent&.visible?(user)),
            subprojects: project.children.visible(user).sorted.map { |child| Helpers.serialize_project(child) },
            custom_fields: project.visible_custom_field_values(user).map do |value|
              {
                id: Helpers.integer_id(value.custom_field_id),
                name: value.custom_field.name,
                value: value.value
              }
            end,
            last_activity_date: project.last_activity_date
          }
        end

        def serialize_activity_event(event)
          url =
            begin
              path = event.event_url
              path.is_a?(Hash) ? Rails.application.routes.url_helpers.url_for(path.merge(only_path: true)) : path.to_s
            rescue StandardError
              nil
            end

          {
            type: event.event_type.to_s,
            datetime: event.event_datetime,
            author: Helpers.serialize_user_ref(event.event_author),
            title: event.event_title.to_s,
            description: event.event_description.to_s,
            url: url
          }
        end

        def resolve_activity_window(user, args)
          today = user.today
          date_to =
            if args[:to].present?
              Date.parse(args[:to].to_s)
            else
              today
            end
          date_from =
            if args[:from].present?
              Date.parse(args[:from].to_s)
            else
              date_to - 6
            end
          return [nil, nil, Helpers.error_result(:error_mcp_invalid_parameters)] if date_from > date_to
          return [nil, nil, Helpers.error_result(:error_mcp_activity_window_too_long)] if (date_to - date_from).to_i > 89

          [date_to, date_from, nil]
        rescue ArgumentError, TypeError
          [nil, nil, Helpers.error_result(:error_mcp_invalid_parameters)]
        end

        def summarize_estimated_hours(scope)
          values = scope.where.not(estimated_hours: nil).pluck(:estimated_hours)
          return nil if values.empty?

          values.sum.to_f
        end

        def summarize_spent_hours(user, project, scope)
          return nil unless user.allowed_to?(:view_time_entries, project)

          TimeEntry.visible(user).where(issue_id: scope.select(:id)).sum(:hours).to_f
        end

        def average_resolution_hours(closed_scope)
          pairs = closed_scope.where.not(closed_on: nil).pluck(:created_on, :closed_on)
          return nil if pairs.empty?

          total = pairs.sum { |created_on, closed_on| (closed_on - created_on).to_f }
          (total / pairs.size / 3600.0).round(2)
        end

        def estimation_accuracy(user, project, closed_scope)
          return unless user.allowed_to?(:view_time_entries, project)

          issues = closed_scope.where.not(estimated_hours: nil).to_a
          return {issues_count: 0, total_estimated: 0.0, total_spent: 0.0} if issues.empty?

          Issue.load_visible_spent_hours(issues)
          matched = issues.select { |issue| issue.spent_hours.to_f.positive? }
          {
            issues_count: matched.size,
            total_estimated: matched.sum { |issue| issue.estimated_hours.to_f }.round(2),
            total_spent: matched.sum { |issue| issue.spent_hours.to_f }.round(2)
          }
        end

        def reopened_count(scope, since)
          closed_ids = IssueStatus.where(is_closed: true).pluck(:id).map(&:to_s)
          open_ids = IssueStatus.where(is_closed: false).pluck(:id).map(&:to_s)
          return 0 if closed_ids.empty? || open_ids.empty?

          JournalDetail
            .joins(:journal)
            .where(journals: {journalized_type: 'Issue', journalized_id: scope.select(:id)})
            .where(journals: {created_on: since..})
            .where(property: 'attr', prop_key: 'status_id')
            .where(old_value: closed_ids, value: open_ids)
            .distinct
            .count('journals.journalized_id')
        end

        def serialize_member_candidate(principal)
          payload = {
            id: Helpers.integer_id(principal.id),
            name: principal.name,
            type: principal.is_a?(Group) ? 'group' : 'user'
          }
          payload[:login] = principal.login if principal.is_a?(User)
          payload
        end

        def serialize_membership(member, project)
          principal = member.principal
          user_ref = principal.is_a?(User) ? Helpers.serialize_user_ref(principal) : nil
          group_ref = principal.is_a?(Group) ? Helpers.serialize_named_ref(principal) : nil
          {
            id: member.id,
            user: user_ref,
            group: group_ref,
            project: Helpers.serialize_named_ref(project),
            roles: member.roles.map { |role| Helpers.serialize_named_ref(role) }
          }
        end

        def serialize_custom_field(field)
          {
            id: field.id,
            name: field.name,
            field_format: field.field_format,
            is_required: field.is_required,
            multiple: field.multiple?,
            default_value: field.default_value,
            possible_values: field.possible_values,
            trackers: field.trackers.map { |tracker| Helpers.serialize_named_ref(tracker) }
          }
        end

        def count_by_name(scope, association)
          reflection = Issue.reflect_on_association(association)
          counts = scope.group(reflection.foreign_key).count
          ids = counts.keys.compact
          names = association_names(association, ids)
          none_label = I18n.t(:label_none)
          breakdown_from_counts(counts, names, none_label)
        end

        def assignee_breakdown(scope)
          counts = scope.group(:assigned_to_id).count
          ids = counts.keys.compact
          names = Principal.where(id: ids).to_h do |principal|
            [principal.id, principal.name]
          end
          breakdown_from_counts(counts, names, I18n.t(:label_nobody))
        end

        def association_names(association, ids)
          return {} if ids.empty?

          case association
          when :status
            IssueStatus.where(id: ids).pluck(:id, :name).to_h
          when :priority
            IssuePriority.where(id: ids).pluck(:id, :name).to_h
          else
            {}
          end
        end

        def breakdown_from_counts(counts, names, missing_label)
          result = {}
          counts.each do |id, count|
            key = id.nil? ? missing_label : (names[id] || missing_label)
            result[key] = result.fetch(key, 0) + count
          end
          result
        end
      end
    end
  end
end
