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

require 'timeout'

module RedmineMcp
  class RequestLimits
    TOOL_TIMEOUT_SECONDS = 60
    RATE_LIMIT_PER_MINUTE = 120
    MAX_REQUEST_BYTES = 32 * 1024 * 1024

    class << self
      def check_before_call!(user:, args:)
        rate_limit_error(user) || payload_size_error(args) || base64_fields_error(args)
      end

      def call_with_timeout(enforce: true, &)
        return yield unless enforce

        Timeout.timeout(TOOL_TIMEOUT_SECONDS, &)
      rescue Timeout::Error
        ToolResponse.failure(
          code: 'TIMEOUT',
          message: I18n.t(:error_mcp_tool_timeout),
          retryable: true
        )
      end

    private

      def rate_limit_error(user)
        return nil unless user

        bucket = Time.now.to_i / 60
        key = "redmine_mcp:rate:#{user.id}:#{bucket}"
        count = Rails.cache.increment(key, 1, expires_in: 2.minutes, initial: 0)
        return nil if count.nil?
        return rate_limited_failure if count > RATE_LIMIT_PER_MINUTE

        nil
      end

      def payload_size_error(args)
        return nil if args.to_json.bytesize <= MAX_REQUEST_BYTES

        ToolResponse.failure(
          code: 'FILE_TOO_LARGE',
          message: I18n.t(:error_mcp_request_too_large),
          retryable: false
        )
      end

      def base64_fields_error(args)
        each_base64_field(args) do |_path, value|
          data, decode_err = Core::Helpers.decode_strict_base64(value)
          if decode_err
            return ToolResponse.failure(
              code: 'VALIDATION_ERROR',
              message: I18n.t(:error_mcp_invalid_parameters),
              retryable: false
            )
          end
          if data.bytesize > RedmineMcp::Core::Helpers::MAX_UPLOAD_BYTES
            return ToolResponse.failure(
              code: 'FILE_TOO_LARGE',
              message: RedmineMcp::Core::Helpers.upload_too_large_message,
              retryable: false
            )
          end
        end
        nil
      end

      def each_base64_field(value, path = [], &)
        case value
        when Hash
          value.each do |key, nested|
            current_path = path + [key]
            if key.to_s == 'content_base64' && nested.present?
              yield(current_path, nested)
            else
              each_base64_field(nested, current_path, &)
            end
          end
        when Array
          value.each_with_index do |item, index|
            each_base64_field(item, path + [index], &)
          end
        else
          nil
        end
      end

      def rate_limited_failure
        ToolResponse.failure(
          code: 'RATE_LIMITED',
          message: I18n.t(:error_mcp_rate_limited),
          retryable: true
        )
      end
    end
  end
end
