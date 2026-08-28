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

require 'fileutils'
require 'timeout'
require File.expand_path('../test_helper', __dir__)

class RedmineMcpExtensionApiTest < RedmineMcpTestCase
  MCP_FILE_NAME = 'mcp.rb'
  MCP_FILE_STUB = "# frozen_string_literal: true\n"
  TEST_OUTPUT_SCHEMA = RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {id: {type: 'integer'}},
    required: ['id']
  ).freeze
  MISSING_OUTPUT_SCHEMA_KEYWORD_PATTERN = /missing keyword: :?output_schema/

  test 'register_issue_tool rejects unknown keyword' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_issue_tool(
        name: 'bad_issue_tool',
        description: 'x',
        permission: :view_issues,
        output_schema: TEST_OUTPUT_SCHEMA,
        output_shema: {type: 'object'}
      ) { |_issue, _args, _context| {} }
    end

    assert_match(/unknown keyword/, error.message)
    assert_match(/output_shema/, error.message)
    assert_nil mcp_registry.tool('test_extension_api_bad_issue_tool')
  end

  test 'register_issue_tool requires output_schema' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_issue_tool(
        name: 'missing_output_schema',
        description: 'x',
        permission: :view_issues
      ) { |_issue, _args, _context| {} }
    end

    assert_match(MISSING_OUTPUT_SCHEMA_KEYWORD_PATTERN, error.message)
  end

  test 'register_issue_tool returns not found when issue is missing in handler' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end
    extension.register_issue_tool(
      name: 'gone_issue',
      description: 'x',
      permission: :view_issues,
      output_schema: TEST_OUTPUT_SCHEMA
    ) { |issue, _args, _context| {id: issue.id} }

    tool = mcp_registry.tool('redmine_test_extension_api_gone_issue')
    result = tool.handler.call({issue_id: 99_999}, {user: User.find(1)})
    payload = RedmineMcp::ToolResponse.from_handler_result(result)

    assert_equal(false, payload[:ok])
    assert_equal('NOT_FOUND', payload.dig(:error, :code))
  ensure
    mcp_registry.instance_variable_get(:@tools).delete('redmine_test_extension_api_gone_issue')
  end

  test 'register_tool_once rejects unknown keyword' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_tool_once(
        name: 'bad_tool',
        description: 'x',
        input_schema: {properties: {}},
        output_schema: TEST_OUTPUT_SCHEMA,
        permission: :view_issues,
        handler: ->(_args, _context) { {} },
        output_shema: {type: 'object'}
      )
    end

    assert_match(/unknown keyword/, error.message)
    assert_match(/output_shema/, error.message)
    assert_nil mcp_registry.tool('test_extension_api_bad_tool')
  end

  test 'register_tool_once requires output_schema' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_tool_once(
        name: 'missing_output_schema',
        description: 'x',
        input_schema: {properties: {}},
        permission: :view_issues,
        handler: ->(_args, _context) { {} }
      )
    end

    assert_match(MISSING_OUTPUT_SCHEMA_KEYWORD_PATTERN, error.message)
  end

  test 'register_tool_once rejects empty output_schema' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_tool_once(
        name: 'empty_output_schema',
        description: 'x',
        input_schema: {properties: {}},
        output_schema: {},
        permission: :view_issues,
        handler: ->(_args, _context) { {} }
      )
    end

    assert_match(/output_schema must be a non-empty Hash/, error.message)
    assert_nil mcp_registry.tool('test_extension_api_empty_output_schema')
  end

  test 'register_tool requires output_schema' do
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    error = assert_raises(ArgumentError) do
      extension.register_tool(
        name: 'missing_output_schema',
        description: 'x',
        input_schema: {properties: {}},
        permission: :view_issues,
        handler: ->(_args, _context) { {} }
      )
    end

    assert_match(MISSING_OUTPUT_SCHEMA_KEYWORD_PATTERN, error.message)
  end

  test 'tool with project permission is visible in discovery when user has permission in a project' do
    user = User.find(2)
    extension = Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id :test_extension_api
    end

    extension.register_tool_once(
      name: 'discovery_visibility',
      description: 'x',
      input_schema: {properties: {}},
      output_schema: TEST_OUTPUT_SCHEMA,
      permission: :view_issues,
      handler: ->(_args, _context) { {} }
    )

    tool = mcp_registry.tool('redmine_test_extension_api_discovery_visibility')

    assert tool.allowed_for?(user, {})
    assert_includes(mcp_registry.tools_for_user(user).map(&:full_name), tool.full_name)
    assert_not(tool.allowed_for?(user, {project: 'does-not-exist'}))
  ensure
    mcp_registry.instance_variable_get(:@tools).delete('redmine_test_extension_api_discovery_visibility')
  end

  test 'extension write tool handler is not called in read-only mode' do
    called = false
    RedmineMcp::Registry.instance.register_tool(
      plugin_id: :mcp_readonly_ext,
      name: 'mutating_ping',
      description: 'test write',
      input_schema: {properties: {}},
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::CREATE_ANNOTATIONS,
      handler: lambda do |_args, _context|
        called = true
        {ok: true, data: {pong: true}}
      end
    )
    RedmineMcp::Registry.instance.register_tool(
      plugin_id: :mcp_readonly_ext,
      name: 'reading_ping',
      description: 'test read',
      input_schema: {properties: {}},
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
      handler: lambda do |_args, _context|
        {ok: true, data: {pong: true}}
      end
    )

    with_read_only_mcp!
    write_payload = invoke_mcp_tool('mcp_readonly_ext_mutating_ping', user: User.find(1), args: {})
    read_payload = invoke_mcp_tool('mcp_readonly_ext_reading_ping', user: User.find(1), args: {})

    assert_equal(false, called)
    assert_equal(false, write_payload[:ok])
    assert_equal('INVALID_STATE', write_payload.dig(:error, :code))
    assert_equal('read_only_mode', write_payload.dig(:error, :details, :reason))
    assert_mcp_ok(read_payload)
  ensure
    tools = mcp_registry.instance_variable_get(:@tools)
    tools.delete('redmine_mcp_readonly_ext_mutating_ping')
    tools.delete('redmine_mcp_readonly_ext_reading_ping')
  end

  test 'register_resource requires unique uri and callable handler' do
    registry = mcp_registry
    handler = ->(_args, _context) { {text: 'ok'} }

    registry.register_resource(
      plugin_id: :test_extension_api,
      uri: 'redmine://test_extension_api/unique/1',
      name: 'unique-resource',
      handler: handler
    )

    error = assert_raises(ArgumentError) do
      registry.register_resource(
        plugin_id: :test_extension_api,
        uri: 'redmine://test_extension_api/unique/1',
        name: 'duplicate-resource',
        handler: handler
      )
    end
    assert_match(/already registered/, error.message)

    error = assert_raises(ArgumentError) do
      RedmineMcp::ResourceDefinition.new(
        plugin_id: :test_extension_api,
        uri: 'redmine://test_extension_api/unique/2',
        name: 'missing-handler',
        handler: nil
      )
    end
    assert_match(/callable/, error.message)
  ensure
    resources = mcp_registry.instance_variable_get(:@resources)
    resources.reject! { |resource| resource.uri.start_with?('redmine://test_extension_api/') }
  end

  test 'extend_tool rejects extra_params that collide with core schema' do
    error = assert_raises(ArgumentError) do
      mcp_registry.extend_tool(
        'redmine_get_issue',
        plugin_id: :test_extension_api,
        extra_params: {issue_id: {type: 'string'}}
      )
    end
    assert_match(/collide/, error.message)
  end

  test 'resource denies a specified unresolved project and allows empty discovery' do
    user = User.find(2)
    resource = RedmineMcp::ResourceDefinition.new(
      plugin_id: :mcp_perm_test,
      uri: 'redmine://mcp_perm_test/report',
      name: 'report',
      permission: :view_issues,
      handler: ->(_args, _context) { {text: 'ok'} }
    )

    assert resource.allowed_for?(user, {})
    assert_not resource.allowed_for?(user, {uri: 'redmine://mcp_perm_test/report?project=does-not-exist'})

    with_resolver = RedmineMcp::ResourceDefinition.new(
      plugin_id: :mcp_perm_test,
      uri: 'redmine://mcp_perm_test/report/missing',
      name: 'resolved-report',
      permission: :view_issues,
      project_resolver: lambda { |current_user, input|
        uri = (input[:uri] || input['uri']).to_s
        RedmineMcp::Core::Helpers.find_project(current_user, uri.split('/').last)
      },
      handler: ->(_args, _context) { {text: 'ok'} }
    )

    assert_not with_resolver.allowed_for?(user, {uri: 'redmine://mcp_perm_test/report/missing'})
  end

  test 'prompt denies a specified unresolved project and allows empty discovery' do
    user = User.find(2)
    prompt = RedmineMcp::PromptDefinition.new(
      plugin_id: :mcp_perm_test,
      name: 'analyze',
      permission: :view_issues,
      handler: ->(_args, _context) { MCP::Prompt::Result.new(messages: []) }
    )

    assert prompt.allowed_for?(user, {})
    assert_not prompt.allowed_for?(user, {project: 'does-not-exist'})
  end

  test 'tool definition requires a callable handler' do
    error = assert_raises(ArgumentError) do
      RedmineMcp::ToolDefinition.new(
        plugin_id: :mcp_perm_test,
        name: 'no_handler',
        description: 'x',
        input_schema: {properties: {}},
        permission: :view_issues,
        handler: Object.new
      )
    end

    assert_match(/callable/, error.message)
  end

  test 'registry hook can register another object without deadlock' do
    registry = mcp_registry
    Timeout.timeout(2) do
      registry.on(:tool_registered, plugin_id: :hook_deadlock_test) do |tool:|
        next if tool.name == 'from_hook'

        registry.register_tool(
          plugin_id: :hook_deadlock_test,
          name: 'from_hook',
          description: 'x',
          input_schema: {properties: {}},
          permission: :view_issues,
          handler: ->(_args, _context) { {} }
        )
      end
      registry.register_tool(
        plugin_id: :hook_deadlock_test,
        name: 'trigger',
        description: 'x',
        input_schema: {properties: {}},
        permission: :view_issues,
        handler: ->(_args, _context) { {} }
      )
    end

    assert registry.tool('redmine_hook_deadlock_test_from_hook')
  ensure
    tools = mcp_registry.instance_variable_get(:@tools)
    tools.delete('redmine_hook_deadlock_test_from_hook')
    tools.delete('redmine_hook_deadlock_test_trigger')
    hooks = mcp_registry.instance_variable_get(:@hooks)
    hooks[:tool_registered]&.reject! { |hook| hook[:plugin_id] == :hook_deadlock_test }
  end

  test 'syntax error in extension file is isolated' do
    dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(dir, 'lib', 'broken_mcp_ext'))
    File.write(File.join(dir, 'lib', 'broken_mcp_ext', MCP_FILE_NAME), "module Broken\n def\n")
    plugin = Struct.new(:id, :directory).new(:broken_mcp_ext, dir)

    assert_equal(false, RedmineMcp::ExtensionLoader.load_plugin_extension(plugin))
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test 'extension_available? is true when the extension file exists' do
    dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(dir, 'lib', 'sample_mcp_ext'))
    File.write(File.join(dir, 'lib', 'sample_mcp_ext', MCP_FILE_NAME), MCP_FILE_STUB)
    plugin = Struct.new(:id, :directory).new(:sample_mcp_ext, dir)

    assert RedmineMcp::ExtensionLoader.extension_available?(plugin)
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test 'extension_available? is false when the extension file is missing' do
    dir = Dir.mktmpdir
    plugin = Struct.new(:id, :directory).new(:missing_mcp_ext, dir)

    assert_equal(false, RedmineMcp::ExtensionLoader.extension_available?(plugin))
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test 'extension_available? is true when mcp.rb is under plugin id without redmine_ prefix' do
    dir = Dir.mktmpdir
    plugin_dir = File.join(dir, 'redmine_mcp_disc_foo')
    FileUtils.mkdir_p(File.join(plugin_dir, 'lib', 'mcp_disc_foo'))
    File.write(File.join(plugin_dir, 'lib', 'mcp_disc_foo', MCP_FILE_NAME), MCP_FILE_STUB)
    plugin = Struct.new(:id, :directory).new(:redmine_mcp_disc_foo, plugin_dir)

    assert RedmineMcp::ExtensionLoader.extension_available?(plugin)
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test 'extension_available? is false when mcp.rb is in unsupported lib folder' do
    dir = Dir.mktmpdir
    plugin_dir = File.join(dir, 'redmine_mcp_disc_bar')
    FileUtils.mkdir_p(File.join(plugin_dir, 'lib', 'other'))
    File.write(File.join(plugin_dir, 'lib', 'other', MCP_FILE_NAME), MCP_FILE_STUB)
    plugin = Struct.new(:id, :directory).new(:redmine_mcp_disc_bar, plugin_dir)

    assert_equal(false, RedmineMcp::ExtensionLoader.extension_available?(plugin))
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test 'load_plugin_extension loads mcp.rb from plugin id without redmine_ prefix' do
    dir = Dir.mktmpdir
    plugin_dir = File.join(dir, 'redmine_mcp_disc_foo')
    FileUtils.mkdir_p(File.join(plugin_dir, 'lib', 'mcp_disc_foo'))
    File.write(
      File.join(plugin_dir, 'lib', 'mcp_disc_foo', MCP_FILE_NAME),
      <<~RUBY
        module RedmineMcpDiscFoo
          module Mcp
            extend RedmineMcp::ExtensionApi
            plugin_id :redmine_mcp_disc_foo
          end
        end
      RUBY
    )
    plugin = Struct.new(:id, :directory).new(:redmine_mcp_disc_foo, plugin_dir)

    assert RedmineMcp::ExtensionLoader.load_plugin_extension(plugin)
    assert Object.const_defined?('RedmineMcpDiscFoo::Mcp')
    assert_includes(RedmineMcpDiscFoo::Mcp.singleton_class, RedmineMcp::ExtensionApi)
  ensure
    Object.send(:remove_const, :RedmineMcpDiscFoo) if Object.const_defined?(:RedmineMcpDiscFoo)
    FileUtils.remove_entry(dir) if dir
  end
end
