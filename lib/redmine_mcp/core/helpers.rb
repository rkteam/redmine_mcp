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
  module Core
    module Helpers
      MAX_ISSUE_UPLOADS = 10
      MAX_UPLOAD_BYTES = 20 * 1024 * 1024
      MAX_UPLOAD_MIB = MAX_UPLOAD_BYTES / (1024 * 1024)
      MAX_DOWNLOAD_BYTES = 10 * 1024 * 1024
      MAX_DOWNLOAD_MIB = MAX_DOWNLOAD_BYTES / (1024 * 1024)
      DEFAULT_LIST_LIMIT = 25
      MAX_LIST_LIMIT = 100
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'

      PAGINATION_INPUT = {
        limit: {
          type: 'integer',
          default: DEFAULT_LIST_LIMIT,
          minimum: 1,
          maximum: MAX_LIST_LIMIT,
          description: 'Maximum number of items to return.'
        },
        offset: {
          type: 'integer',
          minimum: 0,
          default: 0,
          description: 'Number of items to skip.'
        }
      }.freeze

      PROJECT_SCHEMA = {
        type: 'string',
        minLength: 1,
        description: 'Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.',
        examples: ['1', 'ecookbook']
      }.freeze

      POSITIVE_ID_SCHEMA = {
        type: 'integer',
        minimum: 1
      }.freeze

      ISSUE_ID_SCHEMA = POSITIVE_ID_SCHEMA.merge(
        description: 'Numeric issue ID.'
      ).freeze

      ISSUE_UPLOADS_SCHEMA = {
        type: 'array',
        maxItems: MAX_ISSUE_UPLOADS,
        description: 'Files to attach to the issue (max 10). Each item requires content_base64 and filename.',
        items: {
          type: 'object',
          properties: {
            content_base64: {type: 'string', minLength: 1, description: 'File bytes as base64'},
            filename: {type: 'string', minLength: 1, description: 'Attachment filename'},
            content_type: {type: 'string', description: 'MIME type'},
            description: {type: 'string', description: 'Attachment description'}
          },
          required: %w[content_base64 filename]
        }
      }.freeze

      USER_ID_SCHEMA = {
        type: 'integer',
        minimum: 1,
        description: 'Numeric user ID returned by redmine_list_users or redmine_list_project_members.',
        examples: [1, 2]
      }.freeze

      USER_REF_SCHEMA = {
        oneOf: [
          {type: 'integer', minimum: 1},
          {type: 'string', enum: ['me']},
        ],
        description: 'User ID from redmine_list_users, or me for the current user.'
      }.freeze

      HOURS_SCHEMA = {
        type: 'number',
        minimum: 0,
        description: 'Hours spent. Redmine settings determine whether zero and the resulting daily total are allowed.'
      }.freeze

      ACTIVITY_ID_SCHEMA = {
        type: 'integer',
        minimum: 1,
        description: 'Activity ID from redmine_list_time_entry_activities.'
      }.freeze

      TIME_ENTRY_COMMENTS_SCHEMA = {
        type: 'string',
        maxLength: 1024,
        description: 'Time entry comments.'
      }.freeze

      SPENT_ON_SCHEMA = {
        type: 'string',
        format: 'date',
        description: 'Date spent in YYYY-MM-DD format.'
      }.freeze

      TIME_ENTRY_TARGET_ONE_OF = [
        {required: ['project']},
        {required: ['issue_id']},
      ].freeze

      VERSION_STATUS_DESCRIPTION = 'Version status: open, locked, or closed.'

      WIKI_PAGE_TITLE_SCHEMA = {
        type: 'string',
        minLength: 1,
        description: 'Wiki page title. Call redmine_list_wiki_pages when unknown.'
      }.freeze

      EXPECTED_UPDATED_AT_SCHEMA = {
        type: 'string',
        format: 'date-time',
        description: 'Reject the operation if the object changed after this timestamp.'
      }.freeze

      IDEMPOTENCY_KEY_SCHEMA = {
        type: 'string',
        minLength: 8,
        maxLength: 128,
        description: 'Optional key that makes retries after timeout return the same result instead of creating a duplicate.'
      }.freeze

      READ_ONLY_ANNOTATIONS = {
        read_only_hint: true
      }.freeze

      CREATE_ANNOTATIONS = {
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      }.freeze

      UPDATE_ANNOTATIONS = {
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      }.freeze

      DELETE_ANNOTATIONS = {
        read_only_hint: false,
        destructive_hint: true,
        idempotent_hint: true,
        open_world_hint: false
      }.freeze

    module_function

      def find_project(user, project_id)
        return nil if project_id.blank?

        scope = Project.visible(user)
        if project_id.to_s.match?(/\A\d+\z/)
          scope.find_by(id: project_id.to_i) || scope.find_by(identifier: project_id.to_s)
        else
          scope.find_by(identifier: project_id.to_s)
        end
      end

      def any_project_allows?(user, permission)
        return false unless user

        Project.visible(user).where(Project.allowed_to_condition(user, permission)).exists?
      end

      def any_project_module_allows?(user, permission, module_name)
        return false unless user

        Project.visible(user)
               .where(Project.allowed_to_condition(user, permission))
               .joins(:enabled_modules)
               .exists?(enabled_modules: {name: module_name})
      end

      def any_wiki_project_allows?(user, permission)
        any_project_module_allows?(user, permission, 'wiki')
      end

      def any_boards_project_allows?(user, permission)
        any_project_module_allows?(user, permission, 'boards')
      end

      def clamp_limit(value, default: DEFAULT_LIST_LIMIT, max: MAX_LIST_LIMIT)
        limit = (value.presence || default).to_i
        limit = 1 if limit < 1
        limit = max if limit > max
        limit
      end

      def clamp_offset(value)
        offset = (value || 0).to_i
        offset.negative? ? 0 : offset
      end

      def paginated_list(items, total_count:, limit:, offset:, **extra_meta)
        count = items.size
        has_more = (offset + count) < total_count
        meta = {
          total_count: total_count,
          limit: limit,
          offset: offset,
          next_offset: has_more ? offset + limit : nil,
          has_more: has_more
        }.merge(extra_meta)
        {
          ok: true,
          data: {items: items},
          meta: meta
        }
      end

      SQL_LIKE_ESCAPE = '\\'

      def like_contains(value)
        "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"
      end

      def like_binds(value)
        {p: like_contains(value), s: SQL_LIKE_ESCAPE}
      end

      def with_id_order(scope)
        scope.order(scope.klass.arel_table[:id].asc)
      end

      def sort_by_id(records)
        Array(records).sort_by { |record| record.id.to_i }
      end

      def paginate_collection(collection, limit:, offset:, **extra_meta, &)
        if relation?(collection)
          total = relation_total_count(collection)
          page = collection.offset(offset).limit(limit)
          items = block_given? ? page.map(&) : page.to_a
        else
          items_array = Array(collection)
          total = items_array.size
          page = items_array.drop(offset).first(limit)
          items = block_given? ? page.map(&) : page
        end
        paginated_list(items, total_count: total, limit: limit, offset: offset, **extra_meta)
      end

      def paginated_nested(collection, limit:, offset:, &)
        result = paginate_collection(collection, limit: limit, offset: offset, &)
        [
          result.dig(:data, :items) || [],
          {
            total_count: result.dig(:meta, :total_count).to_i,
            offset: offset,
            limit: limit,
            has_more: result.dig(:meta, :has_more) == true,
            next_offset: result.dig(:meta, :next_offset)
          },
        ]
      end

      def relation?(collection)
        defined?(ActiveRecord::Relation) && collection.is_a?(ActiveRecord::Relation)
      end

      def relation_total_count(relation)
        countable = relation.except(:offset, :limit, :order)
        countable = countable.except(:includes, :preload, :eager_load, :select) if countable.eager_loading?
        result = countable.count
        if result.is_a?(Hash)
          grouped = countable.except(:group)
          result = grouped.count
          result = grouped.count(:id) if result.is_a?(Hash)
          result = result.values.sum if result.is_a?(Hash)
        end
        result.to_i
      end

      def nested_list_limit(value)
        clamp_limit(value, default: MAX_LIST_LIMIT, max: MAX_LIST_LIMIT)
      end

      def extract_project_ref(input)
        return if input.blank?

        ref = input[:project] || input['project'] || input[:project_id] || input['project_id']
        return ref if ref.present?

        project_ref_from_uri(input[:uri] || input['uri'])
      end

      def project_ref_from_uri(uri)
        return if uri.blank?

        raw = uri.to_s
        query = raw.split('?', 2)[1]
        if query.present?
          params = Rack::Utils.parse_query(query)
          ref = params['project'].presence || params['project_id'].presence
          return ref if ref
        end

        path = raw.sub(%r{\A[a-zA-Z][a-zA-Z0-9+.-]*://[^/]*}, '')
        segments = path.split('/').reject(&:blank?)
        index = segments.index('projects') || segments.index('project')
        segments[index + 1] if index && segments[index + 1].present?
      end

      def project_specified_in_input?(input, resolver: nil)
        return false if input.blank?
        return true if (input[:project] || input['project'] || input[:project_id] || input['project_id']).present?
        return true if resolver.respond_to?(:call) && (input[:uri] || input['uri']).present?

        extract_project_ref(input).present?
      end

      def allowed_by_project_permission?(user, permission, project:, project_specified:)
        return true if permission.nil?
        return false unless user&.active?
        return user.allowed_to?(permission, project) if project
        return false if project_specified

        user.allowed_to?(permission, nil, global: true) ||
          (permission.is_a?(Symbol) && any_project_allows?(user, permission))
      end

      def resolve_status_id(status_name)
        return nil if status_name.blank?

        status = IssueStatus.find_by('LOWER(name) = ?', status_name.to_s.downcase)
        status&.id
      end

      def integer_id(value)
        return nil if value.nil?

        value.to_i
      end

      def serialize_named_ref(record)
        return nil unless record

        {id: integer_id(record.id), name: record.name}
      end

      def serialize_user_ref(user)
        return nil unless user

        {id: integer_id(user.id), name: user.name}
      end

      def serialize_project(project)
        return nil unless project

        {
          id: integer_id(project.id),
          identifier: project.identifier.to_s,
          name: project.name
        }
      end

      def model_errors(record)
        {
          error: record.errors.full_messages.join(', '),
          code: 'VALIDATION_ERROR'
        }
      end

      def mcp_error(code:, message:, field: nil, retryable: false, details: nil)
        result = {error: message, code: code}
        result[:field] = field if field.present?
        result[:retryable] = true if retryable
        result[:details] = details if details.present?
        result
      end

      I18N_ERROR_CODES = {
        error_mcp_issue_not_found: 'NOT_FOUND',
        error_mcp_project_not_found: 'NOT_FOUND',
        error_mcp_version_not_found: 'NOT_FOUND',
        error_mcp_membership_not_found: 'NOT_FOUND',
        error_mcp_category_not_found: 'NOT_FOUND',
        error_mcp_relation_not_found: 'NOT_FOUND',
        error_mcp_journal_not_found: 'NOT_FOUND',
        error_mcp_time_entry_not_found: 'NOT_FOUND',
        error_mcp_wiki_page_not_found: 'NOT_FOUND',
        error_mcp_wiki_not_found: 'NOT_FOUND',
        error_mcp_attachment_not_found: 'NOT_FOUND',
        error_mcp_status_not_found: 'NOT_FOUND',
        error_mcp_board_not_found: 'NOT_FOUND',
        error_mcp_board_message_not_found: 'NOT_FOUND',
        error_mcp_query_not_found: 'NOT_FOUND',
        error_mcp_permission_denied: 'FORBIDDEN',
        error_mcp_access_denied: 'FORBIDDEN',
        error_mcp_read_only: 'INVALID_STATE',
        error_mcp_invalid_parameters: 'VALIDATION_ERROR',
        error_mcp_invalid_action: 'VALIDATION_ERROR',
        error_mcp_project_required: 'VALIDATION_ERROR',
        error_mcp_project_id_or_login_required: 'VALIDATION_ERROR',
        error_mcp_wiki_not_enabled: 'INVALID_STATE',
        error_mcp_boards_not_enabled: 'INVALID_STATE',
        error_mcp_wiki_page_exists: 'CONFLICT',
        error_mcp_wiki_rename_failed: 'VALIDATION_ERROR',
        error_mcp_attachment_not_readable: 'NOT_FOUND',
        error_attachment_too_big: 'FILE_TOO_LARGE',
        error_mcp_attachment_download_too_large: 'FILE_TOO_LARGE',
        error_mcp_request_too_large: 'FILE_TOO_LARGE',
        error_mcp_rate_limited: 'RATE_LIMITED',
        error_mcp_tool_timeout: 'TIMEOUT',
        notice_locking_conflict: 'CONFLICT',
        error_mcp_idempotency_in_progress: 'CONFLICT',
        error_mcp_idempotency_payload_mismatch: 'CONFLICT',
        error_mcp_file_path_not_allowed: 'VALIDATION_ERROR',
        error_mcp_delete_issue_confirmation_required: 'INVALID_STATE',
        error_mcp_delete_issue_children_present: 'INVALID_STATE',
        error_mcp_delete_file_confirmation_required: 'INVALID_STATE',
        error_mcp_activity_window_too_long: 'VALIDATION_ERROR',
        error_mcp_ambiguous_custom_field: 'VALIDATION_ERROR',
        error_mcp_issue_field_rejected: 'VALIDATION_ERROR',
        error_mcp_http_error: 'REDMINE_API_ERROR'
      }.freeze

      def error_result(key, **options)
        mcp_error(
          code: options[:code] || I18N_ERROR_CODES.fetch(key, 'VALIDATION_ERROR'),
          message: I18n.t(key, **options.except(:code, :field, :retryable, :details)),
          field: options[:field],
          retryable: options[:retryable],
          details: options[:details]
        )
      end

      def truthy?(value)
        [true, 'true', '1', 1].include?(value)
      end

      def absolute_public_url(path)
        return nil if Setting.host_name.to_s.strip.blank?

        normalized_path = path.start_with?('/') ? path : "/#{path}"
        "#{Setting.protocol}://#{Setting.host_name}#{normalized_path}"
      end

      def attachment_url(attachment)
        absolute_public_url(
          "/attachments/download/#{attachment.id}/#{ERB::Util.url_encode(attachment.filename)}"
        )
      end

      def issue_url(issue)
        absolute_public_url("/issues/#{integer_id(issue.id)}")
      end

      def serialize_attachment(attachment)
        {
          id: integer_id(attachment.id),
          filename: attachment.filename,
          filesize: attachment.filesize,
          content_type: attachment.content_type,
          description: attachment.description.to_s,
          content_url: attachment_url(attachment),
          author: serialize_user_ref(attachment.author),
          created_on: attachment.created_on
        }
      end

      def serialize_time_entry(entry)
        {
          id: integer_id(entry.id),
          hours: entry.hours.to_f,
          comments: entry.comments.to_s,
          spent_on: entry.spent_on,
          user: serialize_user_ref(entry.user),
          project: serialize_named_ref(entry.project),
          issue: entry.issue_id ? {id: integer_id(entry.issue_id)} : nil,
          activity: serialize_named_ref(entry.activity),
          created_on: entry.created_on,
          updated_on: entry.updated_on
        }
      end

      def resolve_user_ref(user, value)
        return user.id if value.to_s == 'me'

        value
      end

      alias resolve_user_id resolve_user_ref

      def conflict_if_stale(record, expected_updated_at)
        return nil if expected_updated_at.blank? || record.nil? || !record.respond_to?(:updated_on)

        expected = parse_expected_updated_at(expected_updated_at)
        return mcp_error(code: 'VALIDATION_ERROR', message: I18n.t(:error_mcp_invalid_parameters), field: 'expected_updated_at') unless expected

        actual = record.updated_on
        return nil if actual && actual.to_i == expected.to_i

        mcp_error(
          code: 'CONFLICT',
          message: I18n.t(:notice_locking_conflict),
          details: {
            updated_on: actual&.iso8601,
            hint: I18n.t(:hint_mcp_conflict_stale)
          }
        )
      end

      def parse_expected_updated_at(value)
        Time.iso8601(value.to_s)
      rescue ArgumentError
        Time.zone.parse(value.to_s)
      end

      def decode_strict_base64(encoded)
        [Base64.strict_decode64(encoded.to_s), nil]
      rescue ArgumentError
        [nil, error_result(:error_mcp_invalid_parameters)]
      end

      def build_upload_io(data, filename:, content_type: nil)
        temp = Tempfile.new(['redmine_mcp_upload', File.extname(filename)])
        temp.binmode
        temp.write(data)
        temp.rewind
        temp.define_singleton_method(:original_filename) { filename }
        temp.define_singleton_method(:content_type) { content_type.presence || DEFAULT_CONTENT_TYPE }
        temp
      end

      def close_upload_io(io)
        return unless io.respond_to?(:close!)

        io.close!
      end

      def close_issue_upload_entries(entries)
        Array(entries).each do |entry|
          next unless entry.is_a?(Hash)

          close_upload_io(entry['file'] || entry[:file])
        end
      end

      def with_issue_upload_entries(uploads)
        entries = []
        entries, err = build_issue_upload_entries(uploads)
        yield(entries, err)
      ensure
        close_issue_upload_entries(entries)
      end

      def upload_too_large_message
        I18n.t(
          :error_attachment_too_big,
          max_size: ApplicationController.helpers.number_to_human_size(MAX_UPLOAD_BYTES)
        )
      end

      def build_issue_upload_entries(uploads)
        return [[], nil] if uploads.blank?

        items = uploads
        if items.is_a?(String)
          begin
            items = JSON.parse(items)
          rescue JSON::ParserError
            return [[], error_result(:error_mcp_invalid_parameters)]
          end
        end
        return [[], error_result(:error_mcp_invalid_parameters)] unless items.is_a?(Array)
        return [[], error_result(:error_mcp_invalid_parameters)] if items.empty?
        return [[], error_result(:error_mcp_invalid_parameters)] if items.size > MAX_ISSUE_UPLOADS

        entries = []
        items.each do |raw_item|
          item = raw_item.is_a?(Hash) ? raw_item.deep_symbolize_keys : {}
          filename = item[:filename].presence
          return [entries, error_result(:error_mcp_invalid_parameters)] if item[:content_base64].blank? || filename.blank?

          data, decode_err = decode_strict_base64(item[:content_base64])
          return [entries, decode_err] if decode_err
          return [entries, mcp_error(code: 'FILE_TOO_LARGE', message: upload_too_large_message)] if data.bytesize > MAX_UPLOAD_BYTES

          upload_io = build_upload_io(data, filename: filename, content_type: item[:content_type])
          entries << {
            'file' => upload_io,
            'filename' => filename,
            'content_type' => item[:content_type],
            'description' => item[:description].to_s
          }
        end

        [entries, nil]
      end
    end
  end
end
