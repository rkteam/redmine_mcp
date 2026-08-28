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

class RedmineMcpSettingsTest < RedmineMcpTestCase
  test 'prepare_for_save drops log_level' do
    result = RedmineMcp::Settings.prepare_for_save('log_level' => 'debug')

    assert_nil result['log_level']
  end

  test 'prepare_for_save keeps known disabled_extensions and drops unknown' do
    known = (Redmine::Plugin.all.map { |plugin| plugin.id.to_s } - ['redmine_mcp']).first
    raw = known ? "#{known}, not_a_real_plugin" : 'not_a_real_plugin'

    result = RedmineMcp::Settings.prepare_for_save('disabled_extensions' => raw)

    if known
      assert_equal known, result['disabled_extensions']
    else
      assert_equal '', result['disabled_extensions']
    end
  end

  test 'prepare_for_save normalizes blank disabled_extensions' do
    result = RedmineMcp::Settings.prepare_for_save('disabled_extensions' => '  ,  ')

    assert_equal '', result['disabled_extensions']
  end

  test 'prepare_for_save normalizes missing checkbox values to 0' do
    result = RedmineMcp::Settings.prepare_for_save({})

    assert_equal '0', result['enabled']
    assert_equal '0', result['read_only']
  end

  test 'prepare_for_save drops auto_load_extensions' do
    result = RedmineMcp::Settings.prepare_for_save('auto_load_extensions' => '0')

    assert_nil result['auto_load_extensions']
  end

  test 'mcp_extension_plugins includes only plugins with an MCP extension file' do
    plugins = RedmineMcp::Settings.mcp_extension_plugins

    plugins.each do |plugin|
      assert RedmineMcp::ExtensionLoader.extension_available?(plugin)
      assert_not_equal :redmine_mcp, plugin.id
    end

    others = Redmine::Plugin.all.reject { |plugin| plugin.id == :redmine_mcp || plugins.map(&:id).include?(plugin.id) }

    others.each do |plugin|
      assert_equal(false, RedmineMcp::ExtensionLoader.extension_available?(plugin))
    end
  end

  test 'mcp_extension_plugins is empty when no plugin has an MCP extension' do
    RedmineMcp::ExtensionLoader.stubs(:extension_available?).returns(false)

    assert_empty RedmineMcp::Settings.mcp_extension_plugins
  end

  test 'prepare_for_save maps unchecked MCP plugins to disabled_extensions' do
    plugin_a = Struct.new(:id, :name).new(:plugin_a, 'A')
    plugin_b = Struct.new(:id, :name).new(:plugin_b, 'B')
    RedmineMcp::Settings.stubs(:mcp_extension_plugins).returns([plugin_a, plugin_b])

    result = RedmineMcp::Settings.prepare_for_save('enabled_extensions' => ['', 'plugin_a'])

    assert_equal 'plugin_b', result['disabled_extensions']
    assert_nil result['enabled_extensions']
  end

  test 'prepare_for_save enables checked MCP plugins that were previously disabled' do
    listed = Struct.new(:id, :name).new(:mcp_listed, 'Listed')
    saved = Setting.plugin_redmine_mcp&.dup
    Setting.plugin_redmine_mcp = {'disabled_extensions' => 'mcp_listed'}
    RedmineMcp::Settings.stubs(:mcp_extension_plugins).returns([listed])

    result = RedmineMcp::Settings.prepare_for_save('enabled_extensions' => ['', 'mcp_listed'])

    assert_equal('', result['disabled_extensions'])
  ensure
    Setting.plugin_redmine_mcp = saved if saved
  end

  test 'prepare_for_save keeps disabled plugins that are not currently listed as MCP extensions' do
    known = (Redmine::Plugin.all.map { |plugin| plugin.id.to_s } - ['redmine_mcp']).first
    skip unless known

    listed = Struct.new(:id, :name).new(:mcp_listed, 'Listed')
    saved = Setting.plugin_redmine_mcp&.dup
    Setting.plugin_redmine_mcp = {'disabled_extensions' => known}
    RedmineMcp::Settings.stubs(:mcp_extension_plugins).returns([listed])

    begin
      result = RedmineMcp::Settings.prepare_for_save('enabled_extensions' => ['', 'mcp_listed'])

      assert_equal(known, result['disabled_extensions'])
    ensure
      Setting.plugin_redmine_mcp = saved if saved
    end
  end
end
