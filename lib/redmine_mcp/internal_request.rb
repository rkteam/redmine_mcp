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
  class InternalRequest
    class << self
      def get(path, user:)
        call(path, user: user, method: 'GET')
      end

      def error_response?(result)
        result.is_a?(Hash) && !result.is_a?(Array) && (result.key?('error') || result.key?(:error))
      end

      def call(path, user:, method: 'GET', params: nil, body: nil)
        env = Rack::MockRequest.env_for(
          normalize_path(path),
          :method => method,
          :params => params,
          :input => body,
          'HTTP_X_REDMINE_API_KEY' => user.api_key,
          'HTTP_HOST' => request_host,
          'CONTENT_TYPE' => 'application/json'
        )
        status, _headers, response_body = Rails.application.call(env)
        parse_response(status.to_i, extract_body(response_body))
      end

    private

      def request_host
        Setting.host_name.presence || 'localhost'
      end

      def normalize_path(path)
        root = Rails.application.config.relative_url_root.to_s.chomp('/')
        normalized = path.start_with?('/') ? path : "/#{path}"
        full_path = "#{root}#{normalized}"
        full_path.end_with?('.json', '.xml') ? full_path : "#{full_path}.json"
      end

      def extract_body(body)
        body.respond_to?(:body) ? body.body : body.join
      end

      def parse_response(status, body_text)
        case status
        when 200
          JSON.parse(body_text)
        when 404
          Core::Helpers.error_result(:error_page_not_found, code: 'NOT_FOUND')
        else
          map_failure(status, parse_json(body_text))
        end
      rescue JSON::ParserError
        map_failure(status, {})
      end

      def parse_json(body_text)
        return {} if body_text.blank?

        JSON.parse(body_text)
      rescue JSON::ParserError
        {}
      end

      def map_failure(status, payload)
        message = extract_error(payload)
        if conflict_message?(message)
          Core::Helpers.mcp_error(
            code: 'CONFLICT',
            message: I18n.t(:notice_locking_conflict),
            details: {hint: I18n.t(:hint_mcp_conflict_stale)}
          )
        elsif validation_messages(payload).present?
          Core::Helpers.mcp_error(
            code: 'VALIDATION_ERROR',
            message: I18n.t(:error_mcp_invalid_parameters),
            details: {validation_errors: validation_messages(payload).map { |text| {message: text} }}
          )
        elsif [401, 403].include?(status)
          Core::Helpers.error_result(:error_mcp_permission_denied)
        else
          Core::Helpers.error_result(:error_mcp_internal_server_error)
        end
      end

      def extract_error(payload)
        return unless payload.is_a?(Hash)

        return payload['error'].to_s if payload['error'].present?

        errors = payload['errors']
        if errors.is_a?(Array)
          errors.join(', ')
        elsif errors.present?
          errors.to_s
        end
      end

      def validation_messages(payload)
        return [] unless payload.is_a?(Hash)

        Array.wrap(payload['errors']).map(&:to_s).reject(&:blank?)
      end

      def conflict_message?(message)
        return false if message.blank?

        [
          I18n.t(:notice_issue_update_conflict),
          I18n.t(:notice_issue_update_conflict, locale: :en),
          I18n.t(:notice_locking_conflict),
          I18n.t(:notice_locking_conflict, locale: :en),
        ].include?(message)
      end
    end
  end
end
