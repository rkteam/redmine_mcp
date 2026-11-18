# frozen_string_literal: true

# Redmine MCP - OAuth2 integration
#
# Copyright (C) 2026 Andrea Costa - CART Software
# https://www.cartsoftware.eu
# assistenza@cartsoftware.eu
#
# SPDX-License-Identifier: GPL-2.0-or-later

class McpOauthMetadataController < ApplicationController
  skip_before_action :check_if_login_required

  def protected_resource
    render json: {
      resource: public_url('/mcp'),
      authorization_servers: [public_url('')]
    }
  end

  def authorization_server
    render json: {
      issuer: public_url(''),
      authorization_endpoint: public_url('/oauth/authorize'),
      token_endpoint: public_url('/oauth/token'),
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code'],
      code_challenge_methods_supported: ['S256'],
      scopes_supported: ['use_mcp']
    }
  end

  private

  def public_url(path)
    base = "#{Setting.protocol}://#{Setting.host_name}".sub(%r{/$}, '')
    "#{base}#{request.script_name}#{path}"
  end
end
