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
      module Users
      module_function

        def register!
          register_list_users
          register_list_groups
        end

        def register_list_users
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_users',
            title: 'List users',
            description: 'Return a paginated list of users for lookup and assignment. Provide project ' \
                         'to list active members of one project (requires view_members on that project). ' \
                         'Optional query filters by login, firstname, or lastname substring (case-insensitive; % and _ are literal). ' \
                         'Optional login further filters by login substring and combines with query via AND. ' \
                         'Administrators may omit project to search all active users. For people who are not yet project ' \
                         'members, use redmine_list_project_member_candidates. Each item ' \
                         'includes id, login, name parts, and mail. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                query: {
                  type: 'string',
                  description: 'Case-insensitive substring match against login, firstname, or lastname.'
                },
                login: {type: 'string', description: 'Find user by login substring'}
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_USERS,
            permission: ->(user, args, project) { list_users_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_users)
          )
        end

        def register_list_groups
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_groups',
            title: 'List groups',
            description: 'Return a paginated list of givable Redmine groups visible to the current user (id and name). Use ' \
                         'before redmine_add_project_member when group_id is unknown; prefer ' \
                         'redmine_list_project_member_candidates to find groups that are not yet project members. Optional ' \
                         'query filters by group name substring (case-insensitive; % and _ are literal). Requires ' \
                         'manage_members on any visible project, or administrator. Does not include group members or project ' \
                         'memberships. Does not modify Redmine.',
            input_schema: {
              properties: {
                query: {
                  type: 'string',
                  description: 'Case-insensitive substring match against group name.'
                }
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_GROUPS,
            permission: ->(user, _args, _project) { list_groups_allowed?(user) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_groups)
          )
        end

        def list_users(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])

          if args[:project].present?
            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project

            scope = project.users.order(:login, :id)
            scope = apply_login_scope(scope, args[:login])
            scope = apply_query_scope(scope, args[:query])
          elsif user.admin?
            scope = User.active.order(:login, :id)
            scope = apply_login_scope(scope, args[:login])
            scope = apply_query_scope(scope, args[:query])
          else
            return Helpers.error_result(:error_mcp_project_required)
          end

          Helpers.paginate_collection(scope, limit: limit, offset: offset) do |item|
            serialize_listed_user(item, viewer: user)
          end
        end

        def list_groups(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = Group.givable.visible(user).sorted
          if args[:query].present?
            scope = scope.where(
              'LOWER(lastname) LIKE :p ESCAPE :s',
              Helpers.like_binds(args[:query].to_s.downcase)
            )
          end

          Helpers.paginate_collection(Helpers.with_id_order(scope), limit: limit, offset: offset) do |group|
            {id: Helpers.integer_id(group.id), name: group.name}
          end
        end

        def list_users_allowed?(user, args, project)
          if args[:project].present?
            project ||= Helpers.find_project(user, args[:project])
            return false unless project

            user.allowed_to?(:view_members, project)
          elsif args[:login].present? || args[:query].present?
            user.admin?
          else
            user.admin? || Helpers.any_project_allows?(user, :view_members)
          end
        end

        def list_groups_allowed?(user)
          user.admin? || Helpers.any_project_allows?(user, :manage_members)
        end

        def apply_login_scope(scope, login)
          return scope if login.blank?

          scope.where('LOWER(login) LIKE :p ESCAPE :s', Helpers.like_binds(login.to_s.downcase))
        end

        def apply_query_scope(scope, query)
          return scope if query.blank?

          scope.where(
            'LOWER(login) LIKE :p ESCAPE :s OR LOWER(firstname) LIKE :p ESCAPE :s OR LOWER(lastname) LIKE :p ESCAPE :s',
            Helpers.like_binds(query.to_s.downcase)
          )
        end

        def serialize_listed_user(item, viewer:)
          payload = {
            id: item.id,
            login: item.login,
            firstname: item.firstname,
            lastname: item.lastname
          }
          payload[:mail] = item.mail if viewer.admin? || !item.pref.hide_mail
          payload
        end
      end
    end
  end
end
