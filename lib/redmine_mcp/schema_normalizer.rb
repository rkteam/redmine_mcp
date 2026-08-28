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
  class SchemaNormalizer
    ERROR_OUTPUT_SCHEMA = {
      type: 'object',
      additionalProperties: false,
      properties: {
        code: {type: 'string'},
        message: {type: 'string'},
        field: {type: %w[string null]},
        retryable: {type: 'boolean'},
        details: {type: 'object', additionalProperties: true}
      },
      required: %w[code message retryable]
    }.freeze

    REST_OBJECT_SCHEMA = {type: 'object', additionalProperties: true}.freeze
    REST_ARRAY_SCHEMA = {type: 'array', items: REST_OBJECT_SCHEMA}.freeze

    ID = {type: 'integer'}.freeze
    STRING = {type: 'string'}.freeze
    BOOLEAN = {type: 'boolean'}.freeze
    NUMBER = {type: 'number'}.freeze
    NULLABLE_INTEGER = {type: %w[integer null]}.freeze
    NULLABLE_NUMBER = {type: %w[number null]}.freeze
    NULLABLE_STRING = {type: %w[string null]}.freeze
    JSON_VALUE = {}.freeze
    STRING_OR_OBJECT = {
      type: %w[string object number integer boolean null],
      additionalProperties: true
    }.freeze
    DATETIME = {type: %w[string null]}.freeze
    STRING_ARRAY = {type: 'array', items: STRING}.freeze

    NAMED_REF = {
      type: %w[object null],
      additionalProperties: true,
      properties: {id: ID, name: STRING}
    }.freeze

    USER_REF = NAMED_REF

    PROJECT_REF = {
      type: %w[object null],
      additionalProperties: true,
      properties: {id: ID, identifier: STRING, name: STRING}
    }.freeze

    class << self
      def normalize_input(schema)
        normalize(schema || {}, object_defaults: true)
      end

      def normalize_output(schema)
        return nil if schema.blank?

        normalize(schema)
      end

      def envelope_output(data_schema)
        {
          type: 'object',
          additionalProperties: false,
          properties: {
            ok: {type: 'boolean'},
            data: data_schema,
            meta: {type: 'object', additionalProperties: true},
            error: ERROR_OUTPUT_SCHEMA
          },
          required: ['ok'],
          oneOf: [
            {
              properties: {ok: {const: true}},
              required: ['data'],
              additionalProperties: true,
              not: {required: ['error']}
            },
            {
              properties: {ok: {const: false}},
              required: ['error'],
              additionalProperties: true,
              not: {required: ['data']}
            },
          ]
        }
      end

      def list_envelope_output(item_schema)
        envelope_output(
          type: 'object',
          additionalProperties: false,
          properties: {
            items: {type: 'array', items: item_schema}
          },
          required: ['items']
        )
      end

      def open_object(properties = nil, **kwargs)
        {
          type: 'object',
          additionalProperties: true,
          properties: schema_properties(properties, kwargs)
        }
      end

      def object_output(properties = nil, **kwargs)
        envelope_output(open_object(schema_properties(properties, kwargs)))
      end

      def list_output(properties = nil, **kwargs)
        list_envelope_output(open_object(schema_properties(properties, kwargs)))
      end

      def data_schema_described?(schema)
        data = schema_value(schema, :properties, :data)
        return false unless data.is_a?(Hash)

        items = schema_value(data, :properties, :items)
        if items.is_a?(Hash)
          item_schema = schema_value(items, :items) || items
          return properties_present?(item_schema)
        end

        properties_present?(data)
      end

    private

      def schema_properties(properties, kwargs)
        return kwargs if properties.nil?
        return properties.merge(kwargs) if properties.is_a?(Hash) && kwargs.any?

        properties
      end

      def schema_value(schema, *keys)
        keys.reduce(schema) do |node, key|
          break unless node.is_a?(Hash)

          node[key] || node[key.to_s]
        end
      end

      def properties_present?(schema)
        properties = schema_value(schema, :properties)
        properties.is_a?(Hash) && properties.any?
      end

      def normalize(schema, object_defaults: false)
        schema = schema.deep_symbolize_keys
        if object_defaults
          schema[:type] ||= 'object'
          schema[:properties] ||= {}
        end
        walk(schema)
        schema
      end

      def object_like?(schema)
        schema[:type] == 'object' || schema[:properties].present?
      end

      def tighten!(schema)
        if object_like?(schema)
          schema[:additionalProperties] = false unless schema.key?(:additionalProperties)
          schema[:properties]&.each_value { |property| walk(property) }
        end
        walk(schema[:items])
        [:oneOf, :anyOf, :allOf].each do |key|
          Array(schema[key]).each { |branch| walk(branch) if branch.is_a?(Hash) }
        end
      end

      def walk(node)
        return unless node.is_a?(Hash)

        tighten!(node)
      end
    end

    OBJECT_OUTPUT_SCHEMA = envelope_output(REST_OBJECT_SCHEMA).freeze
    LIST_OUTPUT_SCHEMA = list_envelope_output(REST_OBJECT_SCHEMA).freeze
  end
end
