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

require 'digest'
require 'json'

module RedmineMcp
  class IdempotencyStore
    TTL = 24.hours
    LOCK_TTL = TTL
    WAIT_SECONDS = 5.0
    POLL_INTERVAL = 0.05
    FINGERPRINT_KEY = :__redmine_mcp_idempotency_fingerprint__
    RESULT_KEY = :__redmine_mcp_idempotency_result__

    class << self
      def fetch(user:, tool_name:, key:, args: {})
        return yield if key.blank? || user.nil?

        fingerprint = payload_fingerprint(args)
        cache_key = "redmine_mcp:idempotency:#{user.id}:#{tool_name}:#{Digest::SHA256.hexdigest(key.to_s)}"
        existing = Rails.cache.read(cache_key)
        resolved = resolve_cached(existing, fingerprint)
        return resolved unless resolved.nil?
        return wait_for_completion(cache_key, fingerprint) if in_progress?(existing)

        claimed = Rails.cache.write(
          cache_key,
          in_progress_marker(fingerprint),
          unless_exist: true,
          expires_in: LOCK_TTL
        )
        return wait_for_completion(cache_key, fingerprint) unless claimed

        begin
          result = yield
          if cacheable?(result)
            Rails.cache.write(cache_key, wrap(result, fingerprint), expires_in: TTL)
          else
            Rails.cache.delete(cache_key)
          end
          result
        rescue Timeout::Error
          raise
        rescue StandardError
          Rails.cache.delete(cache_key)
          raise
        end
      end

    private

      def wait_for_completion(cache_key, fingerprint)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + WAIT_SECONDS
        loop do
          value = Rails.cache.read(cache_key)
          resolved = resolve_cached(value, fingerprint)
          return resolved unless resolved.nil?
          break if value.nil? || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep POLL_INTERVAL
        end

        in_progress_failure
      end

      def resolve_cached(value, fingerprint)
        return unless value.is_a?(Hash)

        if in_progress?(value)
          stored = stored_fingerprint(value)
          return payload_conflict if stored.present? && stored != fingerprint

          return
        end

        stored = stored_fingerprint(value)
        return unwrap(value) if stored.blank?
        return payload_conflict if stored != fingerprint

        unwrap(value)
      end

      def in_progress_marker(fingerprint)
        {
          :__redmine_mcp_idempotency__ => 'in_progress',
          FINGERPRINT_KEY => fingerprint
        }
      end

      def wrap(result, fingerprint)
        {
          FINGERPRINT_KEY => fingerprint,
          RESULT_KEY => result
        }
      end

      def unwrap(value)
        return value[RESULT_KEY] if value.key?(RESULT_KEY)
        return value[RESULT_KEY.to_s] if value.key?(RESULT_KEY.to_s)

        value
      end

      def stored_fingerprint(value)
        value[FINGERPRINT_KEY] || value[FINGERPRINT_KEY.to_s]
      end

      def payload_fingerprint(args)
        payload = args.deep_dup
        payload = payload.deep_symbolize_keys if payload.respond_to?(:deep_symbolize_keys)
        payload.delete(:idempotency_key)
        Digest::SHA256.hexdigest(JSON.generate(canonicalize(payload)))
      end

      def canonicalize(value)
        case value
        when Hash
          value.keys.map { |key| [key.to_s, canonicalize(value[key])] }.sort_by(&:first).to_h
        when Array
          value.map { |item| canonicalize(item) }
        else
          value
        end
      end

      def in_progress?(value)
        return false unless value.is_a?(Hash)

        value[:__redmine_mcp_idempotency__] == 'in_progress' ||
          value['__redmine_mcp_idempotency__'] == 'in_progress'
      end

      def cacheable?(result)
        return false unless result.is_a?(Hash)
        return false if result[:ok] == false
        return false if result[:error].present?
        return false if in_progress?(result)

        true
      end

      def payload_conflict
        ToolResponse.failure(
          code: 'CONFLICT',
          message: I18n.t(:error_mcp_idempotency_payload_mismatch)
        )
      end

      def in_progress_failure
        ToolResponse.failure(
          code: 'CONFLICT',
          message: I18n.t(:error_mcp_idempotency_in_progress),
          retryable: true
        )
      end
    end
  end
end
