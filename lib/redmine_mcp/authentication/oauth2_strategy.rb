# frozen_string_literal: true

# Redmine MCP - OAuth2 integration
#
# Copyright (C) 2026 Andrea Costa - CART Software
# https://www.cartsoftware.eu
# assistenza@cartsoftware.eu
#
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineMcp
  module Authentication
    class Oauth2Strategy
      REQUIRED_SCOPE = 'use_mcp'

      def self.authenticate!(request)
        authorization = request.headers['Authorization'].to_s

        match = /\ABearer ([^\s]+)\z/i.match(authorization)
        raise RedmineMcp::Auth::Unauthorized unless match

        access_token = Doorkeeper::AccessToken.by_token(match[1])


	unless access_token&.acceptable?([REQUIRED_SCOPE])
	  raise RedmineMcp::Auth::Unauthorized
	end

        user = User.find_by(id: access_token.resource_owner_id)

        raise RedmineMcp::Auth::Unauthorized unless user&.active?

        user
      end
    end
  end
end
