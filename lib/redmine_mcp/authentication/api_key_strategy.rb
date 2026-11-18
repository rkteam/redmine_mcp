# frozen_string_literal: true

# Redmine MCP - OAuth2 integration
#
# Copyright (C) 2026 Andrea Costa - CART Software
# https://www.cartsoftware.eu
# assistenza@cartsoftware.eu
#
# SPDX-License-Identifier: GPL-2.0-or-later

# Copyright (C) 2026 RK Team
# Additional OAuth2 authentication support: CART contributors
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineMcp
  module Authentication
    class ApiKeyStrategy
      def self.authenticate!(request)
        key = request.headers['X-Redmine-API-Key'].presence

        # rubocop:disable Rails/DynamicFindBy
        user = User.find_by_api_key(key) if key.present?
        # rubocop:enable Rails/DynamicFindBy

        raise RedmineMcp::Auth::Unauthorized,
              I18n.t(:error_mcp_invalid_api_key) unless user&.active?

        user
      end
    end
  end
end
