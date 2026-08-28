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

class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :session_expiration, only: [:handle]
  skip_before_action :user_setup, only: [:handle]
  skip_before_action :check_if_login_required, only: [:handle]
  skip_before_action :set_localization, only: [:handle]
  skip_before_action :check_password_change, only: [:handle]
  skip_before_action :check_twofa_activation, only: [:handle]

  def handle
    Setting.check_cache

    unless RedmineMcp::Settings.enabled?
      render(json: {error: l(:error_mcp_disabled)}, status: :service_unavailable)
      return
    end

    if request_body_too_large?
      render(json: {error: l(:error_mcp_request_too_large)}, status: :payload_too_large)
      return
    end

    user = RedmineMcp::Auth.authenticate!(request)
    set_mcp_locale(user)
    server = RedmineMcp::ServerBuilder.build(user: user)
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, **RedmineMcp::Settings.transport_options)
    status, headers, body = transport.call(request.env)

    response.status = status
    headers.each { |key, value| response.headers[key] = value }
    self.response_body = body
  rescue RedmineMcp::Auth::Unauthorized
    head(:unauthorized)
  rescue RedmineMcp::Auth::Forbidden
    head(:forbidden)
  rescue StandardError => e
    RedmineMcp::Logger.error("request error: #{e.class}: #{e.message}")
    render(json: {error: l(:error_mcp_internal_server_error)}, status: :internal_server_error)
  end

private

  def request_body_too_large?
    length = request.content_length
    return false if length.blank?

    length > RedmineMcp::Settings.max_request_bytes
  end

  def set_mcp_locale(user)
    lang = user.language.presence
    I18n.locale = lang.to_sym if lang && I18n.available_locales.include?(lang.to_sym)
  end
end
