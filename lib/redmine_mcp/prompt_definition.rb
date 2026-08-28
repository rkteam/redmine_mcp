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
  class PromptDefinition
    attr_reader :plugin_id, :name, :title, :description, :arguments, :permission, :handler, :meta, :project_resolver

    def initialize(plugin_id:, name:, handler:, title: nil, description: nil, arguments: [], permission: nil, meta: {}, project_resolver: nil)
      raise ArgumentError, 'handler must be callable' unless handler.respond_to?(:call)

      @plugin_id = plugin_id.to_sym
      @name = name.to_s
      @title = title.to_s.presence || @name
      @description = description.to_s
      @arguments = Array(arguments)
      @permission = permission
      @handler = handler
      @meta = meta || {}
      @project_resolver = project_resolver
    end

    def full_name
      if plugin_id == :redmine
        "redmine_#{name}"
      else
        "redmine_#{plugin_id}_#{name}"
      end
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

  private

    def resolve_project(user, input)
      return project_resolver.call(user, input) if project_resolver.respond_to?(:call)

      project = Core::Helpers.extract_project_ref(input)
      return nil if project.blank?

      Core::Helpers.find_project(user, project)
    end
  end
end
