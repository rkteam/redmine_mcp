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
  class Settings
    MAX_TRANSPORT_REQUEST_BYTES = 36 * 1024 * 1024

    class << self
      def plugin_settings
        return {} unless ActiveRecord::Base.connection.table_exists?('settings')

        Setting.plugin_redmine_mcp || {}
      end

      def enabled?
        plugin_settings['enabled'] == '1'
      end

      def read_only?
        plugin_settings['read_only'] == '1'
      end

      def disabled_extensions
        plugin_settings['disabled_extensions'].to_s.split(/[\s,]+/).map(&:strip).reject(&:blank?).map(&:to_sym)
      end

      def extension_disabled?(plugin_id)
        disabled_extensions.include?(plugin_id.to_sym)
      end

      def mcp_extension_plugins
        Redmine::Plugin.all
                       .reject { |plugin| plugin.id == :redmine_mcp }
                       .select { |plugin| ExtensionLoader.extension_available?(plugin) }
                       .sort_by { |plugin| plugin.name.to_s.downcase }
      end

      def prepare_for_save(raw_settings)
        settings = (raw_settings || {}).stringify_keys
        settings['disabled_extensions'] = disabled_extensions_for_save(settings)
        settings.delete('enabled_extensions')
        settings.delete('auto_load_extensions')
        settings.delete('log_level')
        %w[enabled read_only].each do |key|
          settings[key] = settings[key].to_s == '1' ? '1' : '0'
        end
        settings
      end

      def allowed_hosts
        host_name = Setting.host_name.to_s.strip
        return [] if host_name.blank?

        if host_name =~ %r{\A(?:https?://)?(.+?)(?::(\d+))?(/.+)?\z}i
          [::Regexp.last_match(1).downcase]
        else
          [host_name.split('/').first.downcase]
        end
      end

      def max_request_bytes
        MAX_TRANSPORT_REQUEST_BYTES
      end

      def transport_options
        options = {
          stateless: true,
          max_request_bytes: MAX_TRANSPORT_REQUEST_BYTES
        }
        options[:allowed_hosts] = allowed_hosts if mcp_gem_supports_allowed_hosts? && allowed_hosts.any?
        options
      end

      def mcp_gem_supports_allowed_hosts?
        spec = Gem.loaded_specs['mcp']
        spec && spec.version >= Gem::Version.new('0.23.0')
      end

    private

      def disabled_extensions_for_save(prepared)
        if prepared.key?('enabled_extensions')
          disabled_from_enabled_checkboxes(prepared['enabled_extensions'])
        else
          sanitize_disabled_extensions(prepared['disabled_extensions'])
        end
      end

      def disabled_from_enabled_checkboxes(enabled_value)
        enabled_ids = Array(enabled_value).map { |id| id.to_s.strip }.reject(&:blank?)
        available_ids = mcp_extension_plugins.map { |plugin| plugin.id.to_s }
        form_disabled = available_ids - enabled_ids
        preserved = disabled_extensions.map(&:to_s).select do |id|
          installed_extension_plugin_ids.include?(id) && available_ids.exclude?(id)
        end
        (form_disabled + preserved).uniq.join(', ')
      end

      def sanitize_disabled_extensions(value)
        ids = value.to_s.split(/[\s,]+/).map(&:strip).reject(&:blank?)
        ids.select { |id| installed_extension_plugin_ids.include?(id) }.join(', ')
      end

      def installed_extension_plugin_ids
        Redmine::Plugin.all.map { |plugin| plugin.id.to_s } - ['redmine_mcp']
      end
    end
  end
end
