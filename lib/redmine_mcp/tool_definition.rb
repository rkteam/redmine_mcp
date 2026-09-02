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
  class ToolDefinition
    attr_reader :plugin_id, :name, :title, :description, :input_schema, :output_schema,
                :permission, :handler, :annotations

    def initialize(plugin_id:, name:, description:, input_schema:, permission:, handler:, title: nil, output_schema: nil, annotations: {})
      raise ArgumentError, 'handler must be callable' unless handler.respond_to?(:call)

      @plugin_id = plugin_id.to_sym
      @name = name.to_s
      @title = title.presence || self.class.default_title(@name)
      @description = description.to_s
      @input_schema = SchemaNormalizer.normalize_input(input_schema)
      @output_schema = SchemaNormalizer.normalize_output(output_schema)
      @permission = permission
      @handler = handler
      @annotations = self.class.normalize_annotations(annotations)
    end

    def self.default_title(name)
      name.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
    end

    def self.normalize_annotations(annotations)
      result = (annotations || {}).deep_symbolize_keys
      if result[:read_only_hint]
        result[:destructive_hint] = false
        result[:open_world_hint] = false
        result[:idempotent_hint] = true
      else
        result[:destructive_hint] = false unless result.key?(:destructive_hint)
        result[:open_world_hint] = false unless result.key?(:open_world_hint)
        result[:idempotent_hint] = false unless result.key?(:idempotent_hint)
        result[:read_only_hint] = false unless result.key?(:read_only_hint)
      end
      result
    end

    def self.full_name_for(plugin_id, name)
      if plugin_id.to_sym == :redmine
        "redmine_#{name}"
      else
        "redmine_#{plugin_id}_#{name}"
      end
    end

    def full_name
      self.class.full_name_for(plugin_id, name)
    end

    def mutating?
      annotations[:read_only_hint] != true
    end

    def allowed_for?(user, input = {})
      return false unless user&.active?

      project = resolve_project(user, input)
      if permission.is_a?(Proc)
        permission.call(user, input, project)
      else
        Core::Helpers.allowed_by_project_permission?(
          user,
          permission,
          project: project,
          project_specified: Core::Helpers.project_specified_in_input?(input)
        )
      end
    end

  private

    def resolve_project(user, input)
      project = Core::Helpers.extract_project_ref(input)
      return Core::Helpers.find_project(user, project) if project.present?

      issue_id = input[:issue_id] || input['issue_id']
      if issue_id.present?
        issue = Issue.visible(user).find_by(id: issue_id)
        return issue&.project
      end

      nil
    end
  end
end
