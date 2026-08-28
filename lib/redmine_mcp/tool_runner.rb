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
  class ToolRunner
    class << self
      def merge_schemas(definition, extensions)
        schema = definition.input_schema.deep_dup
        schema[:properties] ||= {}

        extensions.each do |extension|
          extension.extra_params.each do |key, value|
            schema[:properties][key.to_sym] = value
          end
        end

        SchemaNormalizer.normalize_input(schema)
      end

      def run(definition, extensions, args, context)
        args = args.deep_symbolize_keys
        if definition.mutating?
          blocked = Core::ReadOnly.guard_write!
          return blocked if blocked
        end

        extensions.each do |extension|
          next unless extension.before_hook

          extension.before_hook.call(args, context)
        end

        result = definition.handler.call(args, context)

        extensions.each do |extension|
          next unless extension.after_hook

          begin
            result = extension.after_hook.call(result, args, context)
          rescue Timeout::Error
            raise
          rescue StandardError => e
            Logger.error(
              "tool #{definition.full_name} after hook from #{extension.plugin_id}: #{e.class}: #{e.message}"
            )
          end
        end

        result
      rescue Timeout::Error
        raise
      rescue StandardError => e
        Logger.error("tool #{definition.full_name} execution error: #{e.class}: #{e.message}")
        ToolResponse.failure(
          code: 'INTERNAL_ERROR',
          message: I18n.t(:error_mcp_internal_server_error),
          retryable: true
        )
      end
    end
  end
end
