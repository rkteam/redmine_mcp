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
  class AuditLog
    TARGET_KEYS = %i[
      project issue_id issue_to_id time_entry_id version_id category_id relation_id
      journal_id membership_id file_id attachment_id wiki_page_title
      board_id message_id query_id user_id group_id
    ].freeze

    REDACTED_KEYS = %w[
      content_base64 uploads entries notes text private_notes authorization cookie token
    ].freeze

    class << self
      def record(tool_name:, user:, args:, outcome:, duration_ms:, error_code: nil, correlation_id: nil)
        Logger.info(
          {
            event: 'mcp_tool_audit',
            correlation_id: correlation_id,
            tool: tool_name,
            user_id: user&.id,
            user_login: user&.login,
            target: extract_target(args),
            outcome: outcome,
            duration_ms: duration_ms,
            error_code: error_code
          }.to_json
        )
      end

    private

      def extract_target(args)
        normalized = args.deep_symbolize_keys
        TARGET_KEYS.each_with_object({}) do |key, target|
          value = normalized[key]
          target[key] = value if value.present?
        end
      end
    end
  end
end
