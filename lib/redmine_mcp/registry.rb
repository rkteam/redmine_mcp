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

require 'securerandom'
require 'singleton'

module RedmineMcp
  class Registry
    include Singleton

    def initialize
      @mutex = Mutex.new
      @tools = {}
      @tool_aliases = {}
      @tool_extensions = Hash.new { |hash, key| hash[key] = [] }
      @resources = []
      @prompts = {}
      @hooks = Hash.new { |hash, key| hash[key] = [] }
      @capabilities = {}
    end

    def register_tool(plugin_id:, name:, description:, input_schema:, permission:, handler:, **options)
      alias_names = Array(options[:aliases])
      definition = @mutex.synchronize do
        tool = ToolDefinition.new(
          plugin_id: plugin_id,
          name: name,
          title: options[:title],
          description: description,
          input_schema: input_schema,
          output_schema: options[:output_schema],
          permission: permission,
          handler: handler,
          annotations: options.fetch(:annotations, {})
        )
        key = tool.full_name
        raise ArgumentError, "tool already registered: #{key}" if @tools.key?(key) || @tool_aliases.key?(key)

        alias_keys = alias_names.map { |alias_name| ToolDefinition.full_name_for(plugin_id, alias_name) }
        alias_keys.each do |alias_key|
          raise ArgumentError, "tool already registered: #{alias_key}" if @tools.key?(alias_key) || @tool_aliases.key?(alias_key)
        end

        @tools[key] = tool
        alias_keys.each do |alias_key|
          @tool_aliases[alias_key] = key
          Logger.info("registered tool alias #{alias_key} -> #{key} from #{plugin_id}")
        end
        Logger.info("registered tool #{key} from #{plugin_id}")
        tool
      end
      emit(:tool_registered, tool: definition)
      definition
    rescue StandardError => e
      Logger.error("failed to register tool #{plugin_id}.#{name}: #{e.class}: #{e.message}")
      raise
    end

    def extend_tool(tool_name, plugin_id:, extra_params: {}, before: nil, after: nil)
      extension = @mutex.synchronize do
        key = resolve_tool_key(tool_name)
        raise ArgumentError, "tool not found: #{tool_name}" unless @tools.key?(key)

        extra_params ||= {}
        core_keys = Array((@tools[key].input_schema[:properties] || {}).keys).map(&:to_sym)
        extra_keys = extra_params.keys.map(&:to_sym)
        collision = extra_keys & core_keys
        raise ArgumentError, "extra_params collide with core tool #{key}: #{collision.join(', ')}" if collision.any?

        existing_extra = @tool_extensions[key].flat_map { |item| item.extra_params.keys.map(&:to_sym) }
        extension_collision = extra_keys & existing_extra
        raise ArgumentError, "extra_params already registered for #{key}: #{extension_collision.join(', ')}" if extension_collision.any?

        item = ToolExtension.new(
          plugin_id: plugin_id,
          tool_name: key,
          extra_params: extra_params,
          before: before,
          after: after
        )
        @tool_extensions[key] << item
        Logger.info("extended tool #{key} from #{plugin_id}")
        item
      end
      emit(:tool_extended, tool_name: extension.tool_name, extension: extension)
      extension
    rescue StandardError => e
      Logger.error("failed to extend tool #{tool_name} from #{plugin_id}: #{e.class}: #{e.message}")
      raise
    end

    def register_resource(plugin_id:, uri:, name:, handler:, **options)
      definition = @mutex.synchronize do
        raise ArgumentError, "resource already registered: #{uri}" if @resources.any? { |resource| resource.uri == uri.to_s }

        resource = ResourceDefinition.new(
          plugin_id: plugin_id,
          uri: uri,
          name: name,
          title: options[:title],
          description: options[:description],
          mime_type: options.fetch(:mime_type, 'text/plain'),
          permission: options[:permission],
          handler: handler,
          project_resolver: options[:project_resolver]
        )
        @resources << resource
        Logger.info("registered resource #{uri} from #{plugin_id}")
        resource
      end
      emit(:resource_registered, resource: definition)
      definition
    rescue StandardError => e
      Logger.error("failed to register resource #{uri} from #{plugin_id}: #{e.class}: #{e.message}")
      raise
    end

    def register_prompt(plugin_id:, name:, handler:, **options)
      definition = @mutex.synchronize do
        prompt = PromptDefinition.new(
          plugin_id: plugin_id,
          name: name,
          title: options[:title],
          description: options[:description],
          arguments: options.fetch(:arguments, []),
          permission: options[:permission],
          handler: handler,
          meta: options.fetch(:meta, {}),
          project_resolver: options[:project_resolver]
        )
        key = prompt.full_name
        raise ArgumentError, "prompt already registered: #{key}" if @prompts.key?(key)

        @prompts[key] = prompt
        Logger.info("registered prompt #{key} from #{plugin_id}")
        prompt
      end
      emit(:prompt_registered, prompt: definition)
      definition
    rescue StandardError => e
      Logger.error("failed to register prompt #{plugin_id}.#{name}: #{e.class}: #{e.message}")
      raise
    end

    def on(event, plugin_id:, &block)
      @mutex.synchronize do
        @hooks[event.to_sym] << {plugin_id: plugin_id.to_sym, block: block}
      end
    end

    def register_capability(plugin_id:, group:, mode:, handler:)
      raise ArgumentError, 'plugin_id is required' if plugin_id.blank?
      raise ArgumentError, 'group is required' if group.blank?
      raise ArgumentError, 'mode is required' if mode.blank?
      raise ArgumentError, 'handler is required' unless handler.respond_to?(:call)

      key = [group.to_sym, mode.to_sym]
      @mutex.synchronize do
        @capabilities[key] = {plugin_id: plugin_id.to_sym, handler: handler}
        Logger.info("registered capability #{group}.#{mode} from #{plugin_id}")
      end
    end

    def apply_capabilities(group, modes, user)
      providers = @mutex.synchronize { @capabilities.dup }
      providers.each do |(provider_group, mode), entry|
        next unless provider_group == group.to_sym

        begin
          result = entry[:handler].call(user)
        rescue StandardError => e
          Logger.error(
            "capability #{group}.#{mode} from #{entry[:plugin_id]}: #{e.class}: #{e.message}"
          )
          next
        end

        normalized = CapabilityNormalizer.normalize(
          result,
          plugin_id: entry[:plugin_id],
          group: group,
          mode: mode
        )
        next if normalized.nil?

        modes[mode] = normalized
      end
      modes
    end

    def emit(event, **payload)
      hooks = @mutex.synchronize { @hooks[event.to_sym].dup }
      hooks.each do |hook|
        hook[:block].call(**payload)
      rescue StandardError => e
        Logger.error("hook #{event} error from #{hook[:plugin_id]}: #{e.class}: #{e.message}")
      end
    end

    def tools_for_user(user)
      @tools.values.select { |tool| tool.allowed_for?(user) }
    end

    def resources_for_user(user)
      @resources.select { |resource| resource.allowed_for?(user) }
    end

    def prompts_for_user(user)
      @prompts.values.select { |prompt| prompt.allowed_for?(user) }
    end

    def tool(key)
      @tools[resolve_tool_key(key)]
    end

    def tool_extensions(key)
      @tool_extensions[resolve_tool_key(key)]
    end

    def find_resource(uri)
      @resources.find { |resource| resource.uri == uri }
    end

    def find_prompt(key)
      @prompts[resolve_tool_key(key)]
    end

    def to_mcp_tools(user)
      tools_for_user(user).map do |definition|
        build_mcp_tool(definition)
      end
    end

    def to_mcp_alias_tools(user)
      tools_for_user(user).flat_map do |definition|
        alias_keys_for(definition).map do |alias_key|
          build_mcp_tool(definition, published_name: alias_key)
        end
      end
    end

    def to_mcp_resources(user)
      resources_for_user(user).map(&:to_mcp_resource)
    end

    def to_mcp_prompts(user)
      prompts_for_user(user).map do |definition|
        build_mcp_prompt(definition)
      end
    end

    def self.extract_server_context(server_context)
      if server_context.is_a?(MCP::ServerContext)
        server_context.instance_variable_get(:@context) || {}
      else
        server_context || {}
      end
    end

  private

    def resolve_tool_key(tool_name)
      name = tool_name.to_s
      return name if @tools.key?(name)

      aliased = @tool_aliases[name]
      return aliased if aliased

      named = @tools.values.select { |tool| tool.name == name }
      return named.first.full_name if named.one?

      matching = @tools.keys.select { |key| key.end_with?("_#{name}") }
      return matching.first if matching.one?

      alias_matching = @tool_aliases.keys.select { |key| key.end_with?("_#{name}") }
      return @tool_aliases[alias_matching.first] if alias_matching.one?

      name
    end

    def alias_keys_for(definition)
      canonical = definition.full_name
      @tool_aliases.each_with_object([]) do |(alias_key, target), keys|
        keys << alias_key if target == canonical
      end
    end

    def build_mcp_tool(definition, published_name: nil)
      call_name = published_name || definition.full_name
      extensions = tool_extensions(definition.full_name)
      input_schema = ToolRunner.merge_schemas(definition, extensions)
      set_locale = method(:set_user_locale)
      finish = method(:audited_tool_response)

      MCP::Tool.define(
        name: call_name,
        title: definition.title,
        description: definition.description,
        input_schema: input_schema,
        output_schema: definition.output_schema,
        annotations: definition.annotations
      ) do |server_context:, **args|
        context_hash = RedmineMcp::Registry.extract_server_context(server_context)
        current_user = User.find_by(id: context_hash[:user_id])
        User.current = current_user if current_user
        set_locale.call(current_user)

        correlation_id = SecureRandom.uuid
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        call_meta = {
          tool_name: call_name,
          user: current_user,
          args: args,
          correlation_id: correlation_id,
          started_at: started_at
        }
        limit_error = RequestLimits.check_before_call!(user: current_user, args: args)
        return finish.call(**call_meta, payload: limit_error) if limit_error

        unless definition.allowed_for?(current_user, args)
          Logger.warn("permission denied for tool #{call_name}, user=#{current_user&.login}")
          payload = ToolResponse.failure(
            code: 'FORBIDDEN',
            message: I18n.t(:error_mcp_permission_denied)
          )
          return finish.call(**call_meta, payload: payload)
        end

        context = context_hash.merge(user: current_user, correlation_id: correlation_id)
        validation_error = InputValidator.validate(input_schema, args)
        return finish.call(**call_meta, payload: validation_error) if validation_error

        if definition.mutating?
          read_only_error = Core::ReadOnly.guard_write!
          if read_only_error
            payload = ToolResponse.from_handler_result(read_only_error)
            return finish.call(**call_meta, payload: payload)
          end
        end

        result = RequestLimits.call_with_timeout(enforce: definition.annotations[:read_only_hint]) do
          ToolRunner.run(definition, extensions, args, context)
        end
        return finish.call(**call_meta, payload: result) if ToolResponse.error?(result)

        finish.call(**call_meta, payload: ToolResponse.from_handler_result(result))
      end
    end

    def audited_tool_response(tool_name:, user:, args:, correlation_id:, started_at:, payload:)
      audit_tool_call(
        tool_name: tool_name,
        user: user,
        args: args,
        correlation_id: correlation_id,
        started_at: started_at,
        payload: payload
      )
      tool_response(payload)
    end

    def audit_tool_call(tool_name:, user:, args:, correlation_id:, started_at:, payload:)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      AuditLog.record(
        tool_name: tool_name,
        user: user,
        args: args,
        outcome: ToolResponse.error?(payload) ? 'error' : 'success',
        duration_ms: duration_ms,
        error_code: payload.dig(:error, :code),
        correlation_id: correlation_id
      )
    end

    def tool_response(payload)
      MCP::Tool::Response.new(
        [{type: 'text', text: ToolResponse.summary_text(payload)}],
        error: ToolResponse.error?(payload),
        structured_content: payload
      )
    end

    def set_user_locale(user)
      return if user.nil?

      lang = user.language.presence
      I18n.locale = lang.to_sym if lang && I18n.available_locales.include?(lang.to_sym)
    end

    def build_mcp_prompt(definition)
      MCP::Prompt.define(
        name: definition.full_name,
        title: definition.title,
        description: definition.description,
        arguments: definition.arguments,
        meta: definition.meta
      ) do |args, server_context:|
        context_hash = RedmineMcp::Registry.extract_server_context(server_context)
        current_user = User.find_by(id: context_hash[:user_id])
        User.current = current_user if current_user

        unless definition.allowed_for?(current_user, args)
          Logger.warn("permission denied for prompt #{definition.full_name}, user=#{current_user&.login}")
          raise MCP::Server::RequestHandlerError.new(
            I18n.t(:error_mcp_permission_denied),
            nil,
            error_type: :invalid_params
          )
        end

        context = context_hash.merge(user: current_user)
        definition.handler.call(args, context)
      end
    end
  end
end
