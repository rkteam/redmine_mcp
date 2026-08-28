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
  class Auth
    class << self
      def authenticate!(request)
        raise Unauthorized, I18n.t(:error_mcp_rest_api_disabled) unless Setting.rest_api_enabled?

        key = request.headers['X-Redmine-API-Key'].presence
        # rubocop:disable Rails/DynamicFindBy
        user = User.find_by_api_key(key) if key.present?
        # rubocop:enable Rails/DynamicFindBy
        raise Unauthorized, I18n.t(:error_mcp_invalid_api_key) unless user&.active?

        unless user.allowed_to?(:use_mcp, nil, global: true)
          Logger.warn("permission denied for MCP access, user=#{user.login}")
          raise Forbidden, I18n.t(:error_mcp_access_denied)
        end

        user.remote_ip = request.remote_ip
        User.current = user
        user
      end
    end

    class Unauthorized < StandardError; end

    class Forbidden < StandardError; end
  end
end
