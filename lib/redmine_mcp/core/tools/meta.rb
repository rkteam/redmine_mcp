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
      module Meta
      module_function

        def register!
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_server_info',
            title: 'Get MCP server info',
            description: 'Return MCP server metadata for the current session: plugin version, ' \
                         'read-only mode, search capabilities (capabilities.issue_search), ' \
                         'and a brief authenticated-user summary. ' \
                         'Use at session start to learn server capabilities, which search modes ' \
                         'are available, and whether writes are allowed. Does not modify Redmine. ' \
                         'For full user profile fields, use redmine_get_current_user.',
            input_schema: {properties: {}},
            output_schema: RedmineMcp::Core::OutputSchemas::SERVER_INFO,
            permission: :use_mcp,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_server_info)
          )
        end

        def get_server_info(_args, context)
          user = context[:user]
          {
            server_version: RedmineMcp::VERSION,
            read_only_mode: Settings.read_only?,
            auth_mode: 'legacy',
            current_user: {
              id: user.id,
              login: user.login,
              name: user.name
            },
            capabilities: {
              issue_search: issue_search_capabilities(user)
            }
          }
        end

        def issue_search_capabilities(user)
          modes = {
            keyword: {
              available: true,
              tool: 'redmine_search_issues'
            },
            cross_resource: {
              available: true,
              tool: 'redmine_search_all'
            },
            semantic: {
              available: false
            }
          }
          Registry.instance.apply_capabilities(:issue_search, modes, user)
        end
      end
    end
  end
end
