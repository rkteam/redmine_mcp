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

require 'json_schemer'

module RedmineMcp
  class InputValidator
    class << self
      def validate(schema, args)
        return nil if schema.blank?

        normalized = SchemaNormalizer.normalize_input(schema.deep_dup)
        schemer = JSONSchemer.schema(stringify_keys(normalized))
        data = stringify_keys(args)
        errors = schemer.validate(data).to_a
        return nil if errors.empty?

        ToolResponse.failure(
          code: 'VALIDATION_ERROR',
          message: I18n.t(:error_mcp_invalid_parameters),
          details: {validation_errors: summarize_errors(errors)}
        )
      end

    private

      def stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key.to_s] = stringify_keys(nested)
          end
        when Array
          value.map { |item| stringify_keys(item) }
        else
          value
        end
      end

      def summarize_errors(errors)
        errors.map do |error|
          {
            pointer: error['data_pointer'],
            type: error['type']
          }.compact
        end
      end
    end
  end
end
