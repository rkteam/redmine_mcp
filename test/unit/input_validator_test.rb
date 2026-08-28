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

class RedmineMcpInputValidatorTest < RedmineMcpTestCase
  test 'rejects missing required field' do
    schema = {
      properties: {
        issue_id: {type: 'integer', minimum: 1}
      },
      required: ['issue_id']
    }

    payload = RedmineMcp::InputValidator.validate(schema, {})

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
    assert payload.dig(:error, :details, :validation_errors).present?
  end

  test 'validation message is localized and does not expose json_schemer text' do
    schema = {
      properties: {
        issue_id: {type: 'integer', minimum: 1}
      },
      required: ['issue_id']
    }

    I18n.with_locale(:ru) do
      payload = RedmineMcp::InputValidator.validate(schema, {})

      assert_equal I18n.t(:error_mcp_invalid_parameters), payload.dig(:error, :message)
      assert_no_match(/json_schemer|did not match|property/i, payload.dig(:error, :message).to_s)
    end
  end

  test 'rejects wrong type' do
    schema = {
      properties: {
        issue_id: {type: 'integer', minimum: 1}
      },
      required: ['issue_id']
    }

    payload = RedmineMcp::InputValidator.validate(schema, {issue_id: 'abc'})

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'accepts valid payload' do
    schema = {
      properties: {
        issue_id: {type: 'integer', minimum: 1}
      },
      required: ['issue_id']
    }

    assert_nil RedmineMcp::InputValidator.validate(schema, {issue_id: 1})
  end

  test 'rejects unknown additional property' do
    schema = {
      type: 'object',
      properties: {
        issue_id: {type: 'integer', minimum: 1}
      },
      required: ['issue_id'],
      additionalProperties: false
    }

    payload = RedmineMcp::InputValidator.validate(
      schema,
      {issue_id: 1, unexpected: true}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end
end
