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
  class ToolResponse
    LEGACY_KEYS = [:error, :code, :field, :retryable, :success, :hint, :impact, :upstream_status].freeze
    CANONICAL_CODES = %w[
      VALIDATION_ERROR
      NOT_FOUND
      FORBIDDEN
      CONFLICT
      RATE_LIMITED
      REDMINE_API_ERROR
      TIMEOUT
      FILE_TOO_LARGE
      UNSUPPORTED_MEDIA_TYPE
      INVALID_STATE
      PARTIAL_FAILURE
      INTERNAL_ERROR
    ].freeze
    LEGACY_CODE_MAP = {
      'CONFIRMATION_REQUIRED' => 'INVALID_STATE',
      'CHILDREN_PRESENT' => 'INVALID_STATE'
    }.freeze

    class << self
      def success(data, meta: {})
        payload = {ok: true, data: data}
        payload[:meta] = meta if meta.present?
        payload
      end

      def failure(code:, message:, field: nil, retryable: false, details: nil)
        error = {
          code: normalize_code(code),
          message: message.to_s,
          field: field,
          retryable: retryable == true
        }
        error[:details] = details if details.present?
        {ok: false, error: error}
      end

      def from_handler_result(result)
        return result if result.is_a?(Hash) && result.key?(:ok)
        return failure_from_legacy(result) if result.is_a?(Hash) && result[:error].present?
        return success(result.except(:success)) if result.is_a?(Hash) && truthy?(result[:success])

        success(result)
      end

      def error?(payload)
        payload.is_a?(Hash) && payload[:ok] == false
      end

      def summary_text(payload)
        error?(payload) ? payload.dig(:error, :message).to_s.presence || I18n.t(:error_mcp_tool_execution_failed) : JSON.generate(payload)
      end

      def to_mcp_hash(payload)
        MCP::Tool::Response.new(
          [{type: 'text', text: summary_text(payload)}],
          error: error?(payload),
          structured_content: payload
        ).to_h
      end

      def normalize_code(code)
        normalized = code.to_s.upcase
        LEGACY_CODE_MAP.fetch(normalized, normalized).tap do |value|
          return value if CANONICAL_CODES.include?(value)
        end
        'VALIDATION_ERROR'
      end

    private

      def failure_from_legacy(result)
        details = (result[:details] || {}).deep_dup
        result.except(*LEGACY_KEYS, :details).each do |key, value|
          details[key] = value unless value.nil?
        end
        details[:hint] = result[:hint] if result[:hint].present?
        details[:impact] = result[:impact] if result[:impact].present?

        failure(
          code: result[:code].presence || infer_code(result[:error]),
          message: result[:error].to_s,
          field: result[:field],
          retryable: result[:retryable] == true,
          details: details.presence
        )
      end

      def infer_code(message)
        text = message.to_s
        return 'NOT_FOUND' if not_found_message?(text)
        return 'FORBIDDEN' if forbidden_message?(text)
        return 'FILE_TOO_LARGE' if file_too_large_message?(text)
        return 'INVALID_STATE' if invalid_state_message?(text)
        return 'VALIDATION_ERROR' if validation_message?(text)

        case text
        when /not found/i then 'NOT_FOUND'
        when /permission/i, /denied/i, /forbidden/i then 'FORBIDDEN'
        when /confirm/i, /refusing/i then 'INVALID_STATE'
        else 'VALIDATION_ERROR'
        end
      end

      def not_found_message?(text)
        [
          I18n.t(:error_mcp_issue_not_found),
          I18n.t(:error_mcp_project_not_found),
          I18n.t(:error_mcp_version_not_found),
          I18n.t(:error_mcp_membership_not_found),
          I18n.t(:error_mcp_category_not_found),
          I18n.t(:error_mcp_relation_not_found),
          I18n.t(:error_mcp_journal_not_found),
          I18n.t(:error_mcp_time_entry_not_found),
          I18n.t(:error_mcp_wiki_page_not_found),
          I18n.t(:error_mcp_wiki_not_found),
          I18n.t(:error_mcp_attachment_not_found),
          I18n.t(:error_mcp_status_not_found),
          I18n.t(:error_mcp_board_not_found),
          I18n.t(:error_mcp_board_message_not_found),
          I18n.t(:error_mcp_query_not_found),
          I18n.t(:error_page_not_found),
        ].include?(text)
      end

      def forbidden_message?(text)
        text == I18n.t(:error_mcp_permission_denied) || text == I18n.t(:error_mcp_access_denied)
      end

      def file_too_large_message?(text)
        text == Core::Helpers.upload_too_large_message
      end

      def invalid_state_message?(text)
        text == I18n.t(:error_mcp_read_only)
      end

      def validation_message?(text)
        text == I18n.t(:error_mcp_invalid_parameters)
      end

      def truthy?(value)
        value == true || value.to_s == 'true' || value.to_s == '1'
      end
    end
  end
end
