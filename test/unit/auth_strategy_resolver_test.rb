# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class AuthStrategyResolverTest < RedmineMcpTestCase
  def request_with(headers = {})
    Struct.new(:headers).new(headers)
  end

  test 'selects API key strategy' do
    request = request_with('X-Redmine-API-Key' => 'test-key')

    assert_equal RedmineMcp::Authentication::ApiKeyStrategy,
                 RedmineMcp::AuthStrategyResolver.resolve(request)
  end

  test 'selects OAuth2 strategy for bearer token' do
    request = request_with('Authorization' => 'Bearer test-token')

    assert_equal RedmineMcp::Authentication::Oauth2Strategy,
                 RedmineMcp::AuthStrategyResolver.resolve(request)
  end

  test 'rejects ambiguous credentials' do
    request = request_with(
      'Authorization' => 'Bearer test-token',
      'X-Redmine-API-Key' => 'test-key'
    )

    assert_raises(RedmineMcp::Auth::Unauthorized) do
      RedmineMcp::AuthStrategyResolver.resolve(request)
    end
  end

  test 'rejects unsupported authorization schemes' do
    request = request_with('Authorization' => 'Basic abc123')

    assert_raises(RedmineMcp::Auth::Unauthorized) do
      RedmineMcp::AuthStrategyResolver.resolve(request)
    end
  end

  test 'defaults to API key strategy without credentials' do
    assert_equal RedmineMcp::Authentication::ApiKeyStrategy,
                 RedmineMcp::AuthStrategyResolver.resolve(request_with)
  end
end
