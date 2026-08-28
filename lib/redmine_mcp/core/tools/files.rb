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

require 'base64'

module RedmineMcp
  module Core
    module Tools
      module Files
        PROJECT_FILE_CONTAINERS = %w[Project Version].freeze
        DOWNLOAD_ATTACHMENT_DATA_SCHEMA = {
          type: 'object',
          additionalProperties: false,
          properties: {
            attachment_id: {
              type: 'integer',
              minimum: 1,
              description: 'Attachment ID.'
            },
            filename: {
              type: 'string',
              minLength: 1,
              description: 'Original attachment filename.'
            },
            content_type: {
              type: 'string',
              minLength: 1,
              description: "Attachment MIME type. Falls back to #{Helpers::DEFAULT_CONTENT_TYPE} when unknown."
            },
            size: {
              type: 'integer',
              minimum: 0,
              description: 'Attachment size in bytes.'
            },
            content_base64: {
              type: 'string',
              contentEncoding: 'base64',
              description: 'Attachment content encoded as Base64.'
            }
          },
          required: %w[attachment_id filename content_type size content_base64]
        }.freeze

      module_function

        def register!
          register_list_files
          register_upload_file
          register_delete_file
          register_get_attachment
          register_download_attachment
        end

        def register_list_files
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_files',
            title: 'List project files',
            description: 'Return a paginated list of files in one project Files section, including attachments on the project and its versions. Each item includes attachment metadata such as ' \
                         'filename, size, author, and version reference. Use to obtain file_id before redmine_delete_file. For issue or wiki attachments, use redmine_get_issue with ' \
                         'include_attachments or ' \
                         'redmine_get_wiki_page with include_attachments. Requires project and view_files. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_FILES,
            permission: :view_files,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_files)
          )
        end

        def register_upload_file
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'upload_file',
            title: 'Upload project file',
            description: 'Upload one file to a project Files section or version. Requires project, filename, and content_base64; optional description and version_id attach the file to a ' \
                         'roadmap version. Optional idempotency_key makes retries after timeout return the same result instead of uploading a duplicate. Returns attachment metadata without file ' \
                         "bytes. Maximum size #{Helpers::MAX_UPLOAD_MIB} MiB. Requires manage_files on the project. " \
                         'Blocked when MCP read-only mode is enabled. To attach files to an issue, use redmine_update_issue with ' \
                         'uploads ' \
                         'instead.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                filename: {type: 'string', minLength: 1, description: 'Name the file should have in Redmine'},
                content_base64: {type: 'string', minLength: 1, description: 'File content as base64'},
                description: {type: 'string', description: 'Human-readable description'},
                version_id: Helpers::POSITIVE_ID_SCHEMA.merge(description: 'Version/release ID to attach the file to'),
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              },
              required: %w[project filename content_base64]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::PROJECT_FILE,
            permission: :manage_files,
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:upload_file)
          )
        end

        def register_delete_file
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_file',
            title: 'Delete project file',
            description: 'Delete one attachment by file_id. By default only project or version files may be deleted; pass confirm_delete_any_attachment=true to delete issue or wiki attachments. ' \
                         'Returns deleted_file_id only. Requires manage_files or the matching edit/delete permission for the attachment container. Blocked when MCP read-only mode is enabled. Call ' \
                         'redmine_list_files or redmine_get_issue with include_attachments to obtain file_id.',
            input_schema: {
              properties: {
                file_id: Helpers::POSITIVE_ID_SCHEMA.merge(description: 'ID of the attachment to delete'),
                confirm_delete_any_attachment: {
                  type: 'boolean',
                  description: 'Bypass project-scope check for issue/wiki attachments'
                }
              },
              required: ['file_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_FILE,
            permission: ->(user, args, _project) { delete_file_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_file)
          )
        end

        def register_get_attachment
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_attachment',
            title: 'Get attachment',
            description: "Return metadata and a downloadable content_url for one attachment by attachment_id.\n\n" \
                         "Does not return file bytes. Use redmine_download_attachment for Base64-encoded content.\n\n" \
                         "Works for project, version, issue, wiki, and document attachments visible to the current user.\n" \
                         "Obtain attachment_id from redmine_get_issue or redmine_get_wiki_page with include_attachments=true, or redmine_list_files.\n" \
                         'Does not modify Redmine.',
            input_schema: {
              properties: {
                attachment_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Attachment ID from redmine_get_issue/redmine_get_wiki_page with include_attachments=true, or redmine_list_files.',
                  examples: [1]
                }
              },
              required: ['attachment_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ATTACHMENT,
            permission: ->(user, args, _project) { get_attachment_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_attachment)
          )
        end

        def register_download_attachment
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'download_attachment',
            title: 'Download attachment',
            description: "Return one Redmine attachment as metadata and Base64-encoded content.\n\n" \
                         "Decode content_base64 locally when the attachment needs to be read, parsed, or processed as a file.\n\n" \
                         "Attachments larger than #{Helpers::MAX_DOWNLOAD_MIB} MiB are rejected with FILE_TOO_LARGE. " \
                         "Base64 expands payload size by about one third (~#{(Helpers::MAX_DOWNLOAD_MIB * 4 / 3.0).round} MiB JSON for a #{Helpers::MAX_DOWNLOAD_MIB} MiB file).\n" \
                         'Does not expose filesystem paths or increment the attachment download counter. ' \
                         "Does not modify Redmine.\n\n" \
                         "For metadata and content_url only, use redmine_get_attachment.\n" \
                         'Obtain attachment_id from redmine_get_issue or redmine_get_wiki_page with ' \
                         'include_attachments=true, or from redmine_list_files.',
            input_schema: {
              properties: {
                attachment_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Attachment ID from redmine_get_issue/redmine_get_wiki_page with include_attachments=true, or redmine_list_files.',
                  examples: [1]
                }
              },
              required: ['attachment_id']
            },
            output_schema: SchemaNormalizer.envelope_output(DOWNLOAD_ATTACHMENT_DATA_SCHEMA),
            permission: ->(user, args, _project) { get_attachment_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:download_attachment)
          )
        end

        def list_files(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:view_files, project)

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          attachments = project_file_attachments(project)
          Helpers.paginate_collection(Helpers.with_id_order(attachments), limit: limit, offset: offset) do |attachment|
            serialize_project_file(attachment)
          end
        end

        def upload_file(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'upload_file', key: args[:idempotency_key], args: args) do
            upload_file_once(args, context)
          end
        end

        def upload_file_once(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:manage_files, project)
          return Helpers.error_result(:error_mcp_invalid_parameters) if args[:content_base64].blank?

          container = resolve_file_container(project, args[:version_id])
          return container if container.is_a?(Hash) && container[:error]

          filename = args[:filename].presence
          return Helpers.error_result(:error_mcp_invalid_parameters) if filename.blank?

          data, decode_err = Helpers.decode_strict_base64(args[:content_base64])
          return decode_err if decode_err
          return Helpers.mcp_error(code: 'FILE_TOO_LARGE', message: Helpers.upload_too_large_message) if data.bytesize > Helpers::MAX_UPLOAD_BYTES

          upload_io = Helpers.build_upload_io(data, filename: filename, content_type: args[:content_type])
          begin
            attachment = Attachment.new(author: user, description: args[:description], container: container)
            attachment.file = upload_io
            attachment.filename = filename
            return Helpers.model_errors(attachment) unless attachment.save

            serialize_project_file(attachment.reload)
          ensure
            Helpers.close_upload_io(upload_io)
          end
        end

        def delete_file(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          attachment = find_visible_attachment(user, args[:file_id])
          return Helpers.error_result(:error_mcp_attachment_not_found) unless attachment
          return Helpers.error_result(:error_mcp_permission_denied) unless attachment.deletable?(user)

          if !Helpers.truthy?(args[:confirm_delete_any_attachment]) && !PROJECT_FILE_CONTAINERS.include?(attachment.container_type)
            return Helpers.error_result(
              :error_mcp_delete_file_confirmation_required,
              details: {
                reason: 'confirmation_required',
                container_type: attachment.container_type
              }
            )
          end

          deleted_id = attachment.id
          if attachment.container
            attachment.container.attachments.delete(attachment)
          else
            attachment.destroy
          end
          {deleted_file_id: deleted_id}
        end

        def get_attachment(args, context)
          user = context[:user]
          attachment = find_visible_attachment(user, args[:attachment_id])
          return Helpers.error_result(:error_mcp_attachment_not_found) unless attachment
          return Helpers.error_result(:error_mcp_attachment_not_readable) unless attachment.readable?

          {
            attachment_id: attachment.id,
            filename: attachment.filename,
            content_type: attachment.content_type,
            size: attachment.filesize,
            content_url: Helpers.attachment_url(attachment)
          }
        end

        def download_attachment(args, context)
          user = context[:user]
          attachment = find_visible_attachment(user, args[:attachment_id])
          return Helpers.error_result(:error_mcp_attachment_not_found) unless attachment
          return Helpers.error_result(:error_mcp_attachment_not_readable) unless attachment.readable?

          disk_path = attachment.diskfile
          disk_size = File.size(disk_path)
          too_large = attachment_download_too_large(disk_size)
          return too_large if too_large

          content = File.binread(disk_path)
          too_large = attachment_download_too_large(content.bytesize)
          return too_large if too_large

          {
            attachment_id: attachment.id,
            filename: attachment.filename,
            content_type: attachment.content_type.presence || Helpers::DEFAULT_CONTENT_TYPE,
            size: content.bytesize,
            content_base64: Base64.strict_encode64(content)
          }
        end

        def attachment_download_too_large(size_bytes)
          return nil if size_bytes <= Helpers::MAX_DOWNLOAD_BYTES

          Helpers.error_result(
            :error_mcp_attachment_download_too_large,
            max_mib: Helpers::MAX_DOWNLOAD_MIB,
            details: {
              size: size_bytes,
              max_bytes: Helpers::MAX_DOWNLOAD_BYTES
            }
          )
        end

        def project_file_attachments(project)
          version_ids = project.versions.select(:id)
          Attachment.where(
            "(container_type = 'Project' AND container_id = :project_id) OR (container_type = 'Version' AND container_id IN (:version_ids))",
            project_id: project.id,
            version_ids: version_ids
          )
        end

        def resolve_file_container(project, version_id)
          if version_id.present?
            version = project.versions.find_by(id: version_id)
            return Helpers.error_result(:error_mcp_version_not_found) unless version

            version
          else
            project
          end
        end

        def serialize_project_file(attachment)
          result = Helpers.serialize_attachment(attachment)
          result[:digest] = attachment.digest
          result[:downloads] = attachment.downloads
          result[:version] = Helpers.serialize_named_ref(attachment.container) if attachment.container_type == 'Version' && attachment.container
          result
        end

        def find_visible_attachment(user, attachment_id)
          return if attachment_id.blank?

          attachment = Attachment.find_by(id: attachment_id)
          return unless attachment&.visible?(user)

          attachment
        end

        def delete_file_allowed?(user, args)
          return attachment_delete_discovery_allowed?(user) if args[:file_id].blank?

          attachment = find_visible_attachment(user, args[:file_id])
          return attachment_delete_discovery_allowed?(user) unless attachment

          attachment.deletable?(user)
        end

        def attachment_delete_discovery_allowed?(user)
          Helpers.any_project_allows?(user, :manage_files) ||
            Helpers.any_project_allows?(user, :edit_issues) ||
            Helpers.any_project_allows?(user, :edit_own_issues) ||
            Helpers.any_project_allows?(user, :edit_wiki_pages) ||
            Helpers.any_project_allows?(user, :protect_wiki_pages) ||
            Helpers.any_project_allows?(user, :delete_wiki_pages)
        end

        def get_attachment_allowed?(user, args)
          return attachment_discovery_allowed?(user) if args[:attachment_id].blank?

          attachment = find_visible_attachment(user, args[:attachment_id])
          return attachment_discovery_allowed?(user) unless attachment

          true
        end

        def attachment_discovery_allowed?(user)
          Helpers.any_project_allows?(user, :view_files) ||
            Helpers.any_project_allows?(user, :view_issues) ||
            Helpers.any_project_allows?(user, :view_wiki_pages) ||
            Helpers.any_project_allows?(user, :view_documents)
        end
      end
    end
  end
end
