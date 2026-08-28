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
  class Logger
    PREFIX = '[redmine_mcp]'

    class << self
      def debug(message)
        write(:debug, message)
      end

      def info(message)
        write(:info, message)
      end

      def warn(message)
        write(:warn, message)
      end

      def error(message)
        write(:error, message)
      end

      def write(level, message)
        Rails.logger.public_send(level, "#{PREFIX} #{message}")
      end
    end
  end
end
