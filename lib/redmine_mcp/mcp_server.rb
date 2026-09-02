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
  class McpServer < MCP::Server
    def initialize(listed_tool_names: nil, **)
      super(**)
      @listed_tool_names = listed_tool_names
      skip_sdk_required_argument_check
    end

  private

    def list_tools(request)
      items = if @listed_tool_names
                @listed_tool_names.filter_map { |name| @tools[name] }
              else
                @tools.values
              end
      page = paginate(items, cursor: cursor_from(request), page_size: @page_size, request: request, &:to_h)

      {tools: page[:items], nextCursor: page[:next_cursor]}.compact
    end

    def error_tool_response(*)
      ToolResponse.to_mcp_hash(
        ToolResponse.failure(
          code: 'VALIDATION_ERROR',
          message: I18n.t(:error_mcp_invalid_parameters)
        )
      )
    end

    def skip_sdk_required_argument_check
      tools.each_value do |tool|
        schema = tool.input_schema
        next unless schema

        schema.define_singleton_method(:missing_required_arguments?) { |_arguments| false }
      end
    end
  end
end
