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
  module Patches
    module SettingsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :plugin_without_redmine_mcp, :plugin
          alias_method :plugin, :plugin_with_redmine_mcp
        end
      end

      module InstanceMethods
        def plugin_with_redmine_mcp
          params[:settings] = RedmineMcp::Settings.prepare_for_save(params[:settings].permit!.to_h) if params[:id] == 'redmine_mcp' && request.post? && params[:settings]

          plugin_without_redmine_mcp
        end
      end
    end
  end
end
