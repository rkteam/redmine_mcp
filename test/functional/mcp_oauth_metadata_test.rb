
# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class McpOauthMetadataTest < Redmine::IntegrationTest
  setup do
    @old_protocol = Setting.protocol
    @old_host = Setting.host_name

    Setting.protocol = 'https'
    Setting.host_name = 'redmine.example.org'
  end

  teardown do
    Setting.protocol = @old_protocol
    Setting.host_name = @old_host
  end

  test 'protected resource metadata' do
    get '/.well-known/oauth-protected-resource'

    assert_response :success

    data = JSON.parse(response.body)

    assert_equal 'https://redmine.example.org/mcp',
                 data['resource']
    assert_equal ['https://redmine.example.org'],
                 data['authorization_servers']
  end

  test 'authorization server metadata' do
    get '/.well-known/oauth-authorization-server'

    assert_response :success

    data = JSON.parse(response.body)

    assert_equal 'https://redmine.example.org',
                 data['issuer']
    assert_equal 'https://redmine.example.org/oauth/authorize',
                 data['authorization_endpoint']
    assert_equal 'https://redmine.example.org/oauth/token',
                 data['token_endpoint']
    assert_includes data['code_challenge_methods_supported'], 'S256'
    assert_includes data['scopes_supported'], 'use_mcp'
  end
end
