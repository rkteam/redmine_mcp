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
  module CapabilityNormalizer
    UNAVAILABLE = {available: false}.freeze
    AVAILABLE_REQUIRED_KEYS = %i[tool provider use_when avoid_when].freeze

  module_function

    def normalize(result, plugin_id:, group:, mode:)
      return nil unless result.is_a?(Hash)

      data = result.deep_symbolize_keys
      case data[:available]
      when false
        UNAVAILABLE.dup
      when true
        normalize_available(data, plugin_id: plugin_id, group: group, mode: mode)
      else
        warn_invalid(plugin_id, group, mode, 'available must be true or false')
        UNAVAILABLE.dup
      end
    end

    def normalize_available(data, plugin_id:, group:, mode:)
      missing = AVAILABLE_REQUIRED_KEYS.reject { |key| data.key?(key) }
      unless missing.empty?
        warn_invalid(plugin_id, group, mode, "missing #{missing.join(', ')}")
        return UNAVAILABLE.dup
      end

      tool = data[:tool].to_s.strip
      provider = data[:provider].to_s.strip
      use_when = hint_list(data[:use_when])
      avoid_when = hint_list(data[:avoid_when])

      if tool.blank? || provider.blank? || use_when.nil? || avoid_when.nil?
        warn_invalid(plugin_id, group, mode, 'invalid tool, provider, use_when, or avoid_when')
        return UNAVAILABLE.dup
      end

      {
        available: true,
        tool: tool,
        provider: provider,
        use_when: use_when,
        avoid_when: avoid_when
      }
    end

    def hint_list(value)
      return nil unless value.is_a?(Array) && value.any?
      return nil unless value.all? { |item| item.is_a?(String) || item.is_a?(Symbol) }

      value.map(&:to_s)
    end

    def warn_invalid(plugin_id, group, mode, reason)
      Logger.warn("invalid capability #{group}.#{mode} from #{plugin_id}: #{reason}")
    end
  end
end
