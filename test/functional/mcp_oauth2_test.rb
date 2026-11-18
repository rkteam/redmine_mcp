# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class McpOauth2Test < Redmine::IntegrationTest
  fixtures :users, :roles, :members, :member_roles, :projects

  setup do
    @old_settings = Setting.plugin_redmine_mcp&.dup
    @old_rest_api = Setting.rest_api_enabled?

    Setting.rest_api_enabled = '1'
    Setting.plugin_redmine_mcp =
      (Setting.plugin_redmine_mcp || {}).merge('enabled' => '1')

    Role.find(2).add_permission!(:use_mcp)

    @user = User.find(2)
    @application = Doorkeeper::Application.create!(
      name: 'MCP OAuth2 Integration Test',
      redirect_uri: 'http://localhost:8080/callback',
      confidential: false,
      scopes: 'use_mcp'
    )
  end

  teardown do
    Setting.plugin_redmine_mcp = @old_settings if @old_settings
    Setting.rest_api_enabled = @old_rest_api ? '1' : '0'
    User.current = nil
  end

  test 'valid bearer token initializes MCP' do
    token = create_token(scopes: 'use_mcp')

    post_initialize(token.plaintext_token)

    assert_response :success
    assert_equal 'redmine_mcp',
                 JSON.parse(response.body).dig('result', 'serverInfo', 'name')
  end

  test 'invalid bearer token is rejected' do
    post_initialize('invalid-token')

    assert_response :unauthorized
  end

  test 'revoked bearer token is rejected' do
    token = create_token(scopes: 'use_mcp')
    token.revoke

    post_initialize(token.plaintext_token)

    assert_response :unauthorized
  end

  test 'expired bearer token is rejected' do
    token = create_token(scopes: 'use_mcp', expires_in: 1)
    token.update!(created_at: 1.hour.ago)

    post_initialize(token.plaintext_token)

    assert_response :unauthorized
  end

  test 'bearer token without use_mcp scope is rejected' do
    token = create_token(scopes: '')

    post_initialize(token.plaintext_token)

    assert_response :unauthorized
  end

  private

  def create_token(scopes:, expires_in: 3600)



 Doorkeeper::AccessToken.find_or_create_for(
    application: @application,
    resource_owner: @user.id,
    scopes: scopes,
    expires_in: expires_in,
    use_refresh_token: false
  )
  end

  def post_initialize(token)
    post '/mcp',
         params: {
           jsonrpc: '2.0',
           id: 1,
           method: 'initialize',
           params: {
             protocolVersion: '2025-11-25',
             capabilities: {},
             clientInfo: {name: 'oauth2_test', version: '1.0'}
           }
         },
         as: :json,
         headers: {
           'Authorization' => "Bearer #{token}",
           'Accept' => 'application/json, text/event-stream',
           'Host' => RedmineMcp::Settings.allowed_hosts.first || 'localhost',
           'MCP-Protocol-Version' => '2025-11-25'
         }
  end
end
