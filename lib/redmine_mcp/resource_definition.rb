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
  class ResourceDefinition
    attr_reader :plugin_id, :uri, :name, :title, :description, :mime_type, :permission, :handler, :project_resolver

    def initialize(plugin_id:, uri:, name:, handler:, title: nil, description: nil, mime_type: 'text/plain', permission: nil, project_resolver: nil)
      raise ArgumentError, 'handler must be callable' unless handler.respond_to?(:call)
      raise ArgumentError, 'uri is required' if uri.blank?

      @plugin_id = plugin_id.to_sym
      @uri = uri.to_s
      @name = name.to_s
      @title = title.to_s.presence || @name
      @description = description.to_s
      @mime_type = mime_type.to_s
      @permission = permission
      @handler = handler
      @project_resolver = project_resolver
    end

    def allowed_for?(user, input = {})
      return true if permission.nil?
      return false unless user&.active?

      project = resolve_project(user, input)
      if permission.is_a?(Proc)
        permission.call(user, input, project)
      else
        Core::Helpers.allowed_by_project_permission?(
          user,
          permission,
          project: project,
          project_specified: Core::Helpers.project_specified_in_input?(input, resolver: project_resolver)
        )
      end
    end

    def to_mcp_resource
      MCP::Resource.new(
        uri: uri,
        name: name,
        title: title,
        description: description,
        mime_type: mime_type
      )
    end

  private

    def resolve_project(user, input)
      return project_resolver.call(user, input) if project_resolver.respond_to?(:call)

      project = Core::Helpers.extract_project_ref(input)
      return nil if project.blank?

      Core::Helpers.find_project(user, project)
    end
  end
end
