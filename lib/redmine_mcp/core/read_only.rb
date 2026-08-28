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
    module ReadOnly
    module_function

      def guard_write!
        return nil unless Settings.read_only?

        {
          error: I18n.t(:error_mcp_read_only),
          code: 'INVALID_STATE',
          details: {reason: 'read_only_mode'}
        }
      end

      def write_blocked?
        Settings.read_only?
      end
    end
  end
end
