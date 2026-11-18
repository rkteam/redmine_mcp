# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'base64'
require 'uri'
require 'json'

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host! 'localhost'

app = Doorkeeper::Application.find_by!(name: 'ChatGPT MCP Test')

# Login Redmine
session.get '/login'
session.post '/login', params: {
  username: 'jsmith',
  password: ENV.fetch('MCP_TEST_PASSWORD')
}
abort 'Login fallito' unless session.request.session[:user_id] == 2
puts 'Login: OK'

# PKCE S256
verifier = SecureRandom.urlsafe_base64(48)
challenge = Base64.urlsafe_encode64(
  Digest::SHA256.digest(verifier),
  padding: false
)

authorization_params = {
  client_id: app.uid,
  redirect_uri: app.redirect_uri,
  response_type: 'code',
  scope: 'use_mcp',
  state: SecureRandom.hex(16),
  code_challenge: challenge,
  code_challenge_method: 'S256'
}

# Consenso OAuth2
session.get '/oauth/authorize', params: authorization_params
abort 'Pagina consenso fallita' unless session.response.status == 200

session.post '/oauth/authorize', params: authorization_params
abort 'Consenso fallito' unless session.response.status == 302

query = URI.decode_www_form(
  URI.parse(session.response.location).query.to_s
).to_h

abort 'State non valido' unless query['state'] == authorization_params[:state]

code = query.fetch('code')
puts 'Authorization Code: OK'

# Token exchange
session.post '/oauth/token', params: {
  grant_type: 'authorization_code',
  client_id: app.uid,
  redirect_uri: app.redirect_uri,
  code: code,
  code_verifier: verifier
}

puts "Token HTTP: #{session.response.status}"

token_response = JSON.parse(session.response.body)

unless session.response.status == 200
  abort "Token exchange fallito: #{token_response.inspect}"
end

access_token = token_response.fetch('access_token')

puts 'Access Token: OK'
puts "Scope: #{token_response['scope']}"
puts "Refresh Token presente: #{token_response.key?('refresh_token')}"

# MCP initialize
session.post '/mcp',
  params: {
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
    params: {
      protocolVersion: '2025-11-25',
      capabilities: {},
      clientInfo: {name: 'oauth_pkce_test', version: '1.0'}
    }
  },
  as: :json,
  headers: {
    'Authorization' => "Bearer #{access_token}",
    'Accept' => 'application/json, text/event-stream',
    'MCP-Protocol-Version' => '2025-11-25'
  }

puts "MCP HTTP: #{session.response.status}"

if session.response.status == 200
  result = JSON.parse(session.response.body)
  puts "MCP Server: #{result.dig('result', 'serverInfo', 'name')}"
  puts 'OAuth2 + PKCE + MCP: OK'
else
  puts "MCP response: #{session.response.body.to_s[0, 500]}"
  abort 'Accesso MCP fallito'
end

# Refresh token
refresh_token = token_response.fetch('refresh_token')

session.post '/oauth/token', params: {
  grant_type: 'refresh_token',
  client_id: app.uid,
  refresh_token: refresh_token
}

puts "Refresh HTTP: #{session.response.status}"

abort "Refresh fallito: #{session.response.body}" unless session.response.status == 200

refreshed = JSON.parse(session.response.body)
new_access_token = refreshed.fetch('access_token')

puts "Nuovo access token: #{new_access_token != access_token ? 'OK' : 'NON CAMBIATO'}"

# Verifica accesso MCP con il token rinnovato
session.post '/mcp',
  params: {
    jsonrpc: '2.0',
    id: 2,
    method: 'initialize',
    params: {
      protocolVersion: '2025-11-25',
      capabilities: {},
      clientInfo: {name: 'oauth_refresh_test', version: '1.0'}
    }
  },
  as: :json,
  headers: {
    'Authorization' => "Bearer #{new_access_token}",
    'Accept' => 'application/json, text/event-stream',
    'MCP-Protocol-Version' => '2025-11-25'
  }

puts "MCP dopo refresh HTTP: #{session.response.status}"
abort 'Refresh MCP fallito' unless session.response.status == 200

puts 'OAuth2 Refresh + MCP: OK'
