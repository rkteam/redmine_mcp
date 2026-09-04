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

Redmine::Plugin.register(:redmine_mcp) do
  name 'Redmine MCP'
  author 'RK Team'
  description 'MCP server for Redmine with extensible plugin integration'
  version '1.1.0'
  url 'https://redmine-kanban.com'
  author_url 'https://redmine-kanban.com'

  requires_redmine version_or_higher: '6'

  settings default: {
    'enabled' => '0',
    'read_only' => '0',
    'disabled_extensions' => ''
  }, partial: 'settings/redmine_mcp_settings'

  permission :use_mcp, {mcp: [:handle]}, global: true, require: :loggedin
end

require File.expand_path('lib/redmine_mcp', __dir__)
