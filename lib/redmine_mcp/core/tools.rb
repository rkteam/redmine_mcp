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
      PLUGIN_ID = :redmine

    module_function

      def register!
        require_relative 'output_schemas'
        require_relative 'tools/users'
        require_relative 'tools/projects'
        require_relative 'tools/issues'
        require_relative 'tools/time_tracking'
        require_relative 'tools/discovery'
        require_relative 'tools/search_wiki'
        require_relative 'tools/boards'
        require_relative 'tools/files'
        require_relative 'tools/meta'

        Users.register!
        Projects.register!
        Issues.register!
        TimeTracking.register!
        Discovery.register!
        SearchWiki.register!
        Boards.register!
        Files.register!
        Meta.register!
      end
    end
  end
end
