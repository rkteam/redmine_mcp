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

require File.expand_path('../test_helper', __dir__)

class RedmineMcpToolResponseTest < RedmineMcpTestCase
  CONFIRM_DELETE_HINT = 'Pass confirm_delete=true'

  test 'success wraps plain data' do
    payload = RedmineMcp::ToolResponse.from_handler_result({id: 1, subject: 'Test'})

    assert payload[:ok]
    assert_equal 1, payload.dig(:data, :id)
    assert_nil payload[:error]
  end

  test 'legacy error maps confirmation code to invalid state' do
    payload = RedmineMcp::ToolResponse.from_handler_result(
      error: 'confirm required',
      code: 'CONFIRMATION_REQUIRED',
      hint: CONFIRM_DELETE_HINT
    )

    assert_equal false, payload[:ok]
    assert_equal 'INVALID_STATE', payload.dig(:error, :code)
    assert_equal CONFIRM_DELETE_HINT, payload.dig(:error, :details, :hint)
  end

  test 'legacy not found infers NOT_FOUND code' do
    payload = RedmineMcp::ToolResponse.from_handler_result(
      error: I18n.t(:error_mcp_issue_not_found)
    )

    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'legacy error keeps structured details' do
    payload = RedmineMcp::ToolResponse.from_handler_result(
      error: 'confirm required',
      code: 'INVALID_STATE',
      details: {reason: 'confirmation_required'},
      hint: CONFIRM_DELETE_HINT
    )

    assert_equal 'confirmation_required', payload.dig(:error, :details, :reason)
    assert_equal CONFIRM_DELETE_HINT, payload.dig(:error, :details, :hint)
  end

  test 'failure envelope is stable' do
    payload = RedmineMcp::ToolResponse.failure(
      code: 'VALIDATION_ERROR',
      message: 'bad input',
      field: 'issue_id',
      details: {pointer: '/issue_id'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
    assert_equal 'bad input', payload.dig(:error, :message)
    assert_equal 'issue_id', payload.dig(:error, :field)
    assert_equal false, payload.dig(:error, :retryable)
    assert_equal({pointer: '/issue_id'}, payload.dig(:error, :details))
  end

  test 'legacy board query and page not found keep NOT_FOUND in Russian' do
    I18n.with_locale(:ru) do
      %i[
        error_mcp_board_not_found
        error_mcp_board_message_not_found
        error_mcp_query_not_found
      ].each do |key|
        payload = RedmineMcp::ToolResponse.from_handler_result(error: I18n.t(key))

        assert_equal 'NOT_FOUND', payload.dig(:error, :code), key.to_s
        assert_equal I18n.t(key), payload.dig(:error, :message)
      end
    end
  end
end
