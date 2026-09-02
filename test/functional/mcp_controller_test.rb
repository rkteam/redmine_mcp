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

class McpControllerTest < Redmine::IntegrationTest
  MCP_PROTOCOL_VERSION = '2025-11-25'
  TOOLS_CALL_METHOD = 'tools/call'
  TOOLS_LIST_METHOD = 'tools/list'

  fixtures :users, :roles, :members, :member_roles, :projects

  setup do
    @saved_mcp_settings = Setting.plugin_redmine_mcp&.dup
    @saved_rest_api = Setting.rest_api_enabled?
    Setting.rest_api_enabled = '1'
    Setting.plugin_redmine_mcp = (Setting.plugin_redmine_mcp || {}).merge('enabled' => '1')
  end

  teardown do
    Setting.plugin_redmine_mcp = @saved_mcp_settings if @saved_mcp_settings
    Setting.rest_api_enabled = @saved_rest_api ? '1' : '0'
    User.current = nil
  end

  test 'returns service unavailable when mcp disabled' do
    Setting.plugin_redmine_mcp = (Setting.plugin_redmine_mcp || {}).merge('enabled' => '0')

    post_mcp(User.find(1), 'initialize')

    assert_response :service_unavailable
    assert_includes response.parsed_body['error'], 'MCP'
  end

  test 'returns unauthorized for invalid api key' do
    post_mcp(nil, 'initialize', api_key: 'invalid-api-key')

    assert_response :unauthorized
  end

  test 'returns forbidden when user lacks use_mcp' do
    post_mcp(User.find(7), 'initialize')

    assert_response :forbidden
  end

  test 'initialize succeeds for user with use_mcp' do
    post_mcp(User.find(1), 'initialize')

    assert_response :success
    body = response_json

    assert_equal 'redmine_mcp', body.dig('result', 'serverInfo', 'name'),
                 "unexpected body: #{response.body.to_s[0, 800]}"
    assert_equal MCP_PROTOCOL_VERSION, body.dig('result', 'protocolVersion')
  end

  test 'tools list succeeds for user with use_mcp' do
    post_mcp(User.find(1), TOOLS_LIST_METHOD, params: {})

    assert_response :success
    tools = response_json.dig('result', 'tools')

    assert_kind_of Array, tools, "unexpected body: #{response.body.to_s[0, 800]}"
    assert(tools.any? { |tool| tool['name'] == 'redmine_get_mcp_info' })
  end

  test 'admin_list_users is listed and list_all_users alias is callable but hidden' do
    assert_canonical_tool_listed_alias_hidden(
      canonical: 'redmine_admin_list_users',
      alias_name: 'redmine_list_all_users'
    )

    post_mcp(
      User.find(1),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_list_all_users', arguments: {}}
    )

    assert_response :success
    result = response_json['result']

    assert result.dig('structuredContent', 'ok'), "unexpected body: #{response.body.to_s[0, 800]}"
    assert_kind_of Array, result.dig('structuredContent', 'data', 'items')
  end

  test 'list_project_files is listed and list_files alias is callable but hidden' do
    assert_canonical_tool_listed_alias_hidden(
      canonical: 'redmine_list_project_files',
      alias_name: 'redmine_list_files'
    )

    post_mcp(
      User.find(1),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_list_files', arguments: {project: 'ecookbook'}}
    )

    assert_response :success
    result = response_json['result']

    assert result.dig('structuredContent', 'ok'), "unexpected body: #{response.body.to_s[0, 800]}"
    assert_kind_of Array, result.dig('structuredContent', 'data', 'items')
  end

  test 'delete_attachment is listed and delete_file alias is callable but hidden' do
    assert_canonical_tool_listed_alias_hidden(
      canonical: 'redmine_delete_attachment',
      alias_name: 'redmine_delete_file'
    )

    post_mcp(
      User.find(1),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_delete_file', arguments: {file_id: 999_999}}
    )

    assert_response :success
    result = response_json['result']

    assert_equal false, result.dig('structuredContent', 'ok')
    assert result.dig('structuredContent', 'error')
  end

  test 'get_mcp_info is listed and get_server_info alias is callable but hidden' do
    assert_canonical_tool_listed_alias_hidden(
      canonical: 'redmine_get_mcp_info',
      alias_name: 'redmine_get_server_info'
    )

    post_mcp(
      User.find(1),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_get_server_info', arguments: {}}
    )

    assert_response :success
    result = response_json['result']

    assert result.dig('structuredContent', 'ok'), "unexpected body: #{response.body.to_s[0, 800]}"
    assert result.dig('structuredContent', 'data', 'server_version').present?
  end

  test 'tools call returns structuredContent' do
    post_mcp(User.find(1), TOOLS_CALL_METHOD, params: {name: 'redmine_get_mcp_info', arguments: {}})

    assert_response :success
    result = response_json['result']

    assert_kind_of Hash, result['structuredContent'], "unexpected body: #{response.body.to_s[0, 800]}"
    assert result.dig('structuredContent', 'ok')
    assert result.dig('structuredContent', 'data', 'server_version').present?
    assert_kind_of Array, result['content']
  end

  test 'tools call returns error payload for unknown issue' do
    post_mcp(User.find(1), TOOLS_CALL_METHOD, params: {name: 'redmine_get_issue', arguments: {issue_id: 99_999}})

    assert_response :success
    result = response_json['result']

    assert result['isError']
    assert_equal false, result.dig('structuredContent', 'ok')
    assert_equal 'NOT_FOUND', result.dig('structuredContent', 'error', 'code')
  end

  test 'tools call permission denial is audited' do
    Role.find(1).add_permission!(:use_mcp)
    Role.find(2).add_permission!(:use_mcp)
    project = Project.generate!(is_public: false)
    audits = []
    RedmineMcp::AuditLog.stubs(:record).with { |**kwargs| audits << kwargs }

    post_mcp(
      User.find(2),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_list_users', arguments: {project: project.identifier}}
    )

    assert_response :success
    result = response_json['result']

    assert result['isError']
    assert_equal 'FORBIDDEN', result.dig('structuredContent', 'error', 'code')
    assert audits.any?, 'expected permission denial to be audited'
    assert_equal 'error', audits.last[:outcome]
    assert_equal 'FORBIDDEN', audits.last[:error_code]
  end

  test 'rejects oversized http body before mcp transport' do
    post_mcp(
      User.find(1),
      'initialize',
      content_length: RedmineMcp::Settings.max_request_bytes + 1
    )

    assert_response :payload_too_large
  end

  test 'tools call blocks writes in read-only mode' do
    Setting.plugin_redmine_mcp = (Setting.plugin_redmine_mcp || {}).merge('enabled' => '1', 'read_only' => '1')

    post_mcp(
      User.find(1),
      TOOLS_CALL_METHOD,
      params: {name: 'redmine_add_issue_note', arguments: {issue_id: 1, notes: 'from mcp http test'}}
    )

    assert_response :success
    result = response_json['result']

    assert result['isError']
    assert_equal 'INVALID_STATE', result.dig('structuredContent', 'error', 'code')
  end

  test 'tools call schema violations return validation envelope' do
    [
      ['redmine_get_issue', {}],
      ['redmine_get_issue', {issue_id: 1, unexpected: true}],
      ['redmine_get_issue', {issue_id: 0}],
      ['redmine_get_issue', {issue_id: '1'}],
      ['redmine_get_project', {project: 1}],
      ['redmine_list_projects', {limit: 101}],
    ].each do |name, arguments|
      post_mcp(User.find(1), TOOLS_CALL_METHOD, params: {name: name, arguments: arguments})

      assert_tool_validation_envelope("failed for #{name} #{arguments.inspect}: #{response.body.to_s[0, 800]}")
    end
  end

  test 'tools call schema violation is audited' do
    audits = []
    RedmineMcp::AuditLog.stubs(:record).with { |**kwargs| audits << kwargs }

    post_mcp(User.find(1), TOOLS_CALL_METHOD, params: {name: 'redmine_get_issue', arguments: {}})

    assert_tool_validation_envelope
    assert audits.any?, 'expected schema violation to be audited'
    assert_equal 'error', audits.last[:outcome]
    assert_equal 'VALIDATION_ERROR', audits.last[:error_code]
  end

  test 'resources read denies an inaccessible project' do
    Role.find(1).add_permission!(:use_mcp)
    project = Project.generate!(is_public: false)
    uri = "redmine://mcp_review_test/report?project=#{project.identifier}"
    register_review_resource!(uri)

    post_mcp(User.find(2), 'resources/read', params: {uri: uri})

    assert_response(:success)
    body = response_json

    assert body['error'].present?, "unexpected body: #{response.body.to_s[0, 800]}"
    assert_no_match(/secret-report/, response.body)
  ensure
    unregister_review_resource!(uri)
  end

  test 'prompts get denies an inaccessible project' do
    Role.find(1).add_permission!(:use_mcp)
    project = Project.generate!(is_public: false)
    register_review_prompt!

    post_mcp(
      User.find(2),
      'prompts/get',
      params: {
        name: 'redmine_mcp_review_test_analyze',
        arguments: {project: project.identifier}
      }
    )

    assert_response(:success)
    body = response_json

    assert body['error'].present?, "unexpected body: #{response.body.to_s[0, 800]}"
    assert_nil(body.dig('result', 'messages'))
  ensure
    unregister_review_prompt!
  end

private

  def assert_tool_validation_envelope(message = nil)
    assert_response(:success)
    result = response_json['result']
    error_message = message || "unexpected body: #{response.body.to_s[0, 800]}"

    assert(result['isError'], "isError should be true (#{error_message})")
    assert_equal(false, result.dig('structuredContent', 'ok'), error_message)
    assert_equal('VALIDATION_ERROR', result.dig('structuredContent', 'error', 'code'), error_message)
    assert_equal(I18n.t(:error_mcp_invalid_parameters), result.dig('structuredContent', 'error', 'message'), error_message)
    assert_equal(result.dig('structuredContent', 'error', 'message'), result.dig('content', 0, 'text'), error_message)
    assert_no_match(/Invalid arguments:|Missing required arguments:/, response.body)
  end

  def post_mcp(user, method, params: nil, api_key: nil, content_length: nil)
    key = api_key || user&.api_key
    payload = {
      jsonrpc: '2.0',
      id: 1,
      method: method,
      params: params || default_params(method)
    }
    headers = {
      'ACCEPT' => 'application/json, text/event-stream',
      'X-Redmine-API-Key' => key,
      'Host' => RedmineMcp::Settings.allowed_hosts.first || 'localhost',
      'MCP-Protocol-Version' => MCP_PROTOCOL_VERSION
    }
    headers['CONTENT_LENGTH'] = content_length.to_s if content_length

    post(
      '/mcp',
      params: payload,
      as: :json,
      headers: headers
    )
  end

  def default_params(method)
    if method == 'initialize'
      {
        protocolVersion: MCP_PROTOCOL_VERSION,
        capabilities: {},
        clientInfo: {name: 'redmine_mcp_test', version: '1.0'}
      }
    else
      {}
    end
  end

  def response_json
    JSON.parse(response.body)
  rescue JSON::ParserError
    flunk("expected JSON body, got: #{response.body.to_s[0, 500]}")
  end

  def assert_canonical_tool_listed_alias_hidden(canonical:, alias_name:)
    post_mcp(User.find(1), TOOLS_LIST_METHOD, params: {})

    assert_response(:success)
    names = response_json.dig('result', 'tools').map { |tool| tool['name'] }

    assert_includes(names, canonical)
    assert_not_includes(names, alias_name)
  end

  def register_review_resource!(uri)
    RedmineMcp::Registry.instance.register_resource(
      plugin_id: :mcp_review_test,
      uri: uri,
      name: 'review-report',
      permission: :view_issues,
      handler: ->(_args, _context) { {text: 'secret-report'} }
    )
  end

  def unregister_review_resource!(uri)
    resources = RedmineMcp::Registry.instance.instance_variable_get(:@resources)
    resources.reject! { |resource| resource.uri == uri }
  end

  def register_review_prompt!
    RedmineMcp::Registry.instance.register_prompt(
      plugin_id: :mcp_review_test,
      name: 'analyze',
      description: 'Review prompt',
      arguments: [MCP::Prompt::Argument.new(name: 'project', required: false)],
      permission: :view_issues,
      handler: ->(_args, _context) { MCP::Prompt::Result.new(messages: []) }
    )
  end

  def unregister_review_prompt!
    prompts = RedmineMcp::Registry.instance.instance_variable_get(:@prompts)
    prompts.delete('redmine_mcp_review_test_analyze')
  end
end
