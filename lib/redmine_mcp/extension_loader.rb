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
  class ExtensionLoader
    class << self
      def load_all
        return unless Settings.enabled?

        Logger.info('loading MCP extensions')
        loaded = 0

        # rubocop:disable Rails/FindEach
        Redmine::Plugin.all.each do |plugin|
          next if plugin.id == :redmine_mcp
          next if Settings.extension_disabled?(plugin.id)

          loaded += 1 if load_plugin_extension(plugin)
        end
        # rubocop:enable Rails/FindEach

        Registry.instance.emit(:extensions_loaded, loaded_count: loaded)
        Logger.info("loaded #{loaded} MCP extension(s)")
      end

      def extension_available?(plugin)
        extension_path(plugin).present?
      end

      def load_plugin_extension(plugin)
        path = extension_path(plugin)
        return false unless path

        require path
        Logger.info("loaded extension from #{plugin.id}")
        true
      rescue SyntaxError, LoadError, StandardError => e
        Logger.error("failed to load extension from #{plugin.id}: #{e.class}: #{e.message}")
        false
      end

    private

      def extension_path(plugin)
        candidates_for(plugin).find { |path| File.file?(path) }
      end

      def candidates_for(plugin)
        lib_folder_names(plugin).map { |name| File.join(plugin.directory, 'lib', name, 'mcp.rb') }
      end

      def lib_folder_names(plugin)
        plugin_id = plugin.id.to_s
        [plugin_id, File.basename(plugin.directory), id_without_redmine_prefix(plugin_id)].compact.uniq
      end

      def id_without_redmine_prefix(plugin_id)
        unprefixed = plugin_id.delete_prefix('redmine_')
        unprefixed if unprefixed != plugin_id && unprefixed.present?
      end
    end
  end
end
