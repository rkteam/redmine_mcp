# frozen_string_literal: true

# Redmine MCP - OAuth2 integration
#
# Copyright (C) 2026 Andrea Costa - CART Software
# https://www.cartsoftware.eu
# assistenza@cartsoftware.eu
#
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineMcp
  class AuthStrategyResolver
    def self.resolve(request)
      authorization = request.headers['Authorization'].to_s
      api_key = request.headers['X-Redmine-API-Key'].presence

      # Non accettiamo due meccanismi di autenticazione
      # contemporaneamente.
      if authorization.present? && api_key.present?
        raise Auth::Unauthorized
      end

      if authorization.present?
        unless authorization.match?(/\ABearer [^\s]+\z/i)
          raise Auth::Unauthorized
        end

        return Authentication::Oauth2Strategy
      end

      Authentication::ApiKeyStrategy
    end
  end
end
