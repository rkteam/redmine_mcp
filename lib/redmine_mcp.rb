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

Rails.autoloaders.each { |loader| loader.ignore(__dir__.to_s) } if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk

require "#{__dir__}/redmine_mcp/version"
require "#{__dir__}/redmine_mcp/settings"
require "#{__dir__}/redmine_mcp/logger"
require "#{__dir__}/redmine_mcp/schema_normalizer"
require "#{__dir__}/redmine_mcp/capability_normalizer"
require "#{__dir__}/redmine_mcp/tool_response"
require "#{__dir__}/redmine_mcp/tool_definition"
require "#{__dir__}/redmine_mcp/tool_extension"
require "#{__dir__}/redmine_mcp/tool_runner"
require "#{__dir__}/redmine_mcp/resource_definition"
require "#{__dir__}/redmine_mcp/prompt_definition"
require "#{__dir__}/redmine_mcp/input_validator"
require "#{__dir__}/redmine_mcp/request_limits"
require "#{__dir__}/redmine_mcp/audit_log"
require "#{__dir__}/redmine_mcp/idempotency_store"
require "#{__dir__}/redmine_mcp/registry"
require "#{__dir__}/redmine_mcp/core/read_only"
require "#{__dir__}/redmine_mcp/core/helpers"
require "#{__dir__}/redmine_mcp/extension_api"
require "#{__dir__}/redmine_mcp/internal_request"
require "#{__dir__}/redmine_mcp/extension_loader"
require "#{__dir__}/redmine_mcp/auth"
require "#{__dir__}/redmine_mcp/mcp_server"
require "#{__dir__}/redmine_mcp/server_builder"
require "#{__dir__}/redmine_mcp/core/output_schemas"
require "#{__dir__}/redmine_mcp/core/tools"
require "#{__dir__}/redmine_mcp/patches/settings_controller_patch"

Rails.application.config.after_initialize do
  SettingsController.send(:include, RedmineMcp::Patches::SettingsControllerPatch) unless SettingsController.include?(RedmineMcp::Patches::SettingsControllerPatch)
  RedmineMcp::Core::Tools.register!
  RedmineMcp::ExtensionLoader.load_all
end
