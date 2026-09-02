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
    module Tools
      module SearchWiki
        ALLOWED_SEARCH_RESOURCES = %w[issues wiki_pages].freeze

      module_function

        def register!
          register_search_all
          register_list_wiki_pages
          register_get_wiki_page
          register_create_wiki_page
          register_update_wiki_page
          register_delete_wiki_page
          register_rename_wiki_page
        end

        def register_search_all
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'search_all',
            title: 'Search Redmine',
            description: 'Search across issues and wiki pages by free-text query. query is required; optional resources ' \
                         'limits results to issues, wiki_pages, or both. Each item includes type, title, project, ' \
                         'status when available, updated_on, excerpt, and url for issues. ' \
                         'Use for broad discovery across resource types. For issue-only text search, use redmine_search_issues instead. ' \
                         'Requires view_issues and/or view_wiki_pages for the requested resource types. ' \
                         'Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                query: {type: 'string', minLength: 1, description: 'Text to search for'},
                resources: {
                  type: 'array',
                  items: {type: 'string', enum: ALLOWED_SEARCH_RESOURCES},
                  maxItems: 2,
                  uniqueItems: true,
                  description: 'Resource types to search. Omit to search all supported resource types.'
                }
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['query']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_SEARCH,
            permission: ->(user, args, _project) { search_all_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:search_all)
          )
        end

        def register_list_wiki_pages
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_wiki_pages',
            title: 'List wiki pages',
            description: 'Return a paginated list of wiki pages in one project. Each item includes title, version, parent_title, created_on, and updated_on without page body text. Use to discover ' \
                         'page titles before redmine_get_wiki_page, redmine_create_wiki_page, redmine_update_wiki_page, or redmine_rename_wiki_page. Requires project and a wiki-enabled project. ' \
                         'Default limit 25, maximum 100. ' \
                         'Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_WIKI_PAGES,
            permission: ->(user, args, project) { wiki_read_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_wiki_pages)
          )
        end

        def register_get_wiki_page
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_wiki_page',
            title: 'Get wiki page',
            description: 'Return one wiki page by project and wiki_page_title, including full text, version, author, and comments. Optional version reads a historical revision. Attachment ' \
                         'metadata is excluded by default; set include_attachments=true to include it. Follows wiki redirects. Use redmine_list_wiki_pages when the title is unknown. Does not ' \
                         'modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                wiki_page_title: Helpers::WIKI_PAGE_TITLE_SCHEMA,
                version: {type: 'integer', minimum: 1, description: 'Historical wiki page version number.'},
                include_attachments: {type: 'boolean', description: 'Include attachment metadata. Default: false. attachments is always present in the response.'},
                attachment_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum attachments when include_attachments is true. Default: 100'
                },
                attachment_offset: {type: 'integer', minimum: 0, default: 0, description: 'Attachments to skip'}
              },
              required: %w[project wiki_page_title]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::WIKI_PAGE,
            permission: ->(user, args, project) { wiki_read_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_wiki_page)
          )
        end

        def register_create_wiki_page
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_wiki_page',
            title: 'Create wiki page',
            description: 'Create one new wiki page in a project. Requires project, wiki_page_title, and text; optional comments store an edit note. Returns the created page with content. ' \
                         'Requires edit_wiki_pages on a wiki-enabled project. Blocked when MCP read-only mode is enabled. Fails if the title already exists; use redmine_update_wiki_page to change ' \
                         'an ' \
                         'existing page.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                wiki_page_title: Helpers::WIKI_PAGE_TITLE_SCHEMA,
                text: {type: 'string', minLength: 1, description: 'Wiki page body text.'},
                comments: {type: 'string', description: 'Optional edit comment.'}
              },
              required: %w[project wiki_page_title text]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::WIKI_PAGE,
            permission: ->(user, args, project) { wiki_edit_allowed?(user, args, project) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_wiki_page)
          )
        end

        def register_update_wiki_page
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_wiki_page',
            title: 'Update wiki page',
            description: 'Update the content of one existing wiki page by project and wiki_page_title. Requires text; optional comments store an edit note. Optional expected_updated_at rejects ' \
                         'the update with CONFLICT if the page changed since that timestamp. Returns the updated page with a new content version. Requires edit_wiki_pages on a wiki-enabled ' \
                         'project. Blocked when MCP read-only mode is enabled. Call redmine_list_wiki_pages or redmine_get_wiki_page when the title is unknown.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                wiki_page_title: Helpers::WIKI_PAGE_TITLE_SCHEMA,
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA,
                text: {type: 'string', minLength: 1, description: 'Wiki page body text.'},
                comments: {type: 'string', description: 'Optional edit comment.'}
              },
              required: %w[project wiki_page_title text]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::WIKI_PAGE,
            permission: ->(user, args, project) { wiki_edit_allowed?(user, args, project) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_wiki_page)
          )
        end

        def register_delete_wiki_page
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_wiki_page',
            title: 'Delete wiki page',
            description: 'Permanently delete one wiki page by project and wiki_page_title. Optional expected_updated_at rejects deletion with CONFLICT if the page changed since that timestamp. ' \
                         'Returns the deleted page title only. Requires delete_wiki_pages on a wiki-enabled project. Blocked when MCP read-only mode is enabled. This operation cannot be undone ' \
                         'through MCP. Call redmine_list_wiki_pages when the title is unknown.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                wiki_page_title: Helpers::WIKI_PAGE_TITLE_SCHEMA,
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA
              },
              required: %w[project wiki_page_title]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_WIKI,
            permission: ->(user, args, project) { wiki_delete_allowed?(user, args, project) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_wiki_page)
          )
        end

        def register_rename_wiki_page
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'rename_wiki_page',
            title: 'Rename wiki page',
            description: 'Rename one wiki page in a project. Requires project, wiki_page_title, and new_title. redirect_existing_links defaults to true. Returns the new title, content version, ' \
                         'and updated_on. Requires rename_wiki_pages on a wiki-enabled project. Blocked when MCP read-only mode is enabled. To change page content without renaming, use ' \
                         'redmine_update_wiki_page.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                wiki_page_title: Helpers::WIKI_PAGE_TITLE_SCHEMA,
                new_title: {type: 'string', minLength: 1, description: 'New wiki page title.'},
                redirect_existing_links: {type: 'boolean', description: 'Whether to redirect old title links. Default: true'}
              },
              required: %w[project wiki_page_title new_title]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::RENAMED_WIKI,
            permission: ->(user, args, project) { wiki_rename_allowed?(user, args, project) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:rename_wiki_page)
          )
        end

        def search_all_allowed?(user, args)
          resources = Array(args[:resources]).map(&:to_s) & ALLOWED_SEARCH_RESOURCES
          resources = ALLOWED_SEARCH_RESOURCES if resources.empty?

          (resources.include?('issues') && Helpers.any_project_allows?(user, :view_issues)) ||
            (resources.include?('wiki_pages') && Helpers.any_wiki_project_allows?(user, :view_wiki_pages))
        end

        def search_all(args, context)
          user = context[:user]
          query = args[:query].to_s
          return Helpers.error_result(:error_mcp_invalid_parameters) if query.blank?

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = normalize_search_resources(args[:resources])
          projects = Project.visible(user).to_a

          fetcher = Redmine::Search::Fetcher.new(
            query,
            user,
            scope,
            projects,
            all_words: true,
            titles_only: false,
            attachments: '0',
            open_issues: false
          )
          records = fetcher.results(offset, limit)
          results = records.map { |record| serialize_search_result(record) }

          Helpers.paginated_list(
            results,
            total_count: fetcher.result_count,
            limit: limit,
            offset: offset,
            query: query,
            results_by_type: fetcher.result_count_by_type
          )
        end

        def list_wiki_pages(args, context)
          _project, wiki, err = find_wiki(context[:user], args[:project])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          pages = wiki.pages.includes(:content_without_text).order(:title, :id)
          Helpers.paginate_collection(pages, limit: limit, offset: offset) do |page|
            serialize_wiki_page_meta(page)
          end
        end

        def get_wiki_page(args, context)
          user = context[:user]
          project, wiki, err = find_wiki(user, args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) if args[:version].present? && !user.allowed_to?(:view_wiki_edits, project)

          page = wiki.find_page(args[:wiki_page_title], with_redirect: true)
          return Helpers.error_result(:error_mcp_wiki_page_not_found) unless page

          content = page.content_for_version(args[:version])
          return Helpers.error_result(:error_mcp_wiki_page_not_found) unless content

          result = serialize_wiki_page(page, content)
          include_attachments = args.key?(:include_attachments) ? Helpers.truthy?(args[:include_attachments]) : false
          if include_attachments
            offset = Helpers.clamp_offset(args[:attachment_offset])
            limit = Helpers.nested_list_limit(args[:attachment_limit])
            result[:attachments], result[:attachments_pagination] = Helpers.paginated_nested(
              page.attachments.reorder(:id),
              limit: limit,
              offset: offset
            ) { |attachment| Helpers.serialize_attachment(attachment) }
          else
            result[:attachments] = []
            result[:attachments_pagination] = nil
          end
          result
        end

        def create_wiki_page(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          _project, wiki, err = find_wiki(context[:user], args[:project])
          return err if err

          page = wiki.find_or_new_page(args[:wiki_page_title])
          return Helpers.error_result(:error_mcp_wiki_page_exists) unless page.new_record?
          return Helpers.error_result(:error_mcp_permission_denied) unless page.editable_by?(context[:user])

          content = WikiContent.new(page: page, text: args[:text], comments: args[:comments], author: context[:user])
          return Helpers.model_errors(page) unless page.save_with_content(content)

          serialize_wiki_page(page, page.content)
        end

        def update_wiki_page(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          _project, wiki, err = find_wiki(context[:user], args[:project])
          return err if err

          page = wiki.find_page(args[:wiki_page_title])
          return Helpers.error_result(:error_mcp_wiki_page_not_found) unless page
          return Helpers.error_result(:error_mcp_permission_denied) unless page.editable_by?(context[:user])

          conflict = Helpers.conflict_if_stale(page, args[:expected_updated_at])
          return conflict if conflict

          content = page.content || WikiContent.new(page: page)
          content.text = args[:text]
          content.comments = args[:comments] if args.key?(:comments)
          content.author = context[:user]
          return Helpers.model_errors(page) unless page.save_with_content(content)

          serialize_wiki_page(page, page.content)
        end

        def delete_wiki_page(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          _project, wiki, err = find_wiki(context[:user], args[:project])
          return err if err

          page = wiki.find_page(args[:wiki_page_title])
          return Helpers.error_result(:error_mcp_wiki_page_not_found) unless page
          return Helpers.error_result(:error_mcp_permission_denied) unless page.editable_by?(context[:user])

          conflict = Helpers.conflict_if_stale(page, args[:expected_updated_at])
          return conflict if conflict

          title = page.title
          page.destroy
          {title: title}
        end

        def rename_wiki_page(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          _project, wiki, err = find_wiki(context[:user], args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_invalid_parameters) if args[:new_title] == args[:wiki_page_title]

          page = wiki.find_page(args[:wiki_page_title])
          return Helpers.error_result(:error_mcp_wiki_page_not_found) unless page
          return Helpers.error_result(:error_mcp_permission_denied) unless page.editable_by?(context[:user])

          page.redirect_existing_links = args.key?(:redirect_existing_links) ? Helpers.truthy?(args[:redirect_existing_links]) : true
          page.title = args[:new_title]
          return Helpers.model_errors(page) unless page.save

          renamed = wiki.find_page(args[:new_title])
          return Helpers.error_result(:error_mcp_wiki_rename_failed) unless renamed

          {title: renamed.title, version: renamed.content&.version, updated_on: renamed.updated_on}
        end

        def find_wiki(user, project)
          project = Helpers.find_project(user, project)
          return [nil, nil, Helpers.error_result(:error_mcp_project_not_found)] unless project
          return [nil, nil, Helpers.error_result(:error_mcp_wiki_not_enabled)] unless project.module_enabled?(:wiki)

          wiki = project.wiki || Wiki.find_by(project_id: project.id)
          return [nil, nil, Helpers.error_result(:error_mcp_wiki_not_found)] unless wiki

          [project, wiki, nil]
        end

        def normalize_search_resources(resources)
          list = Array(resources).map(&:to_s) & ALLOWED_SEARCH_RESOURCES
          list = ALLOWED_SEARCH_RESOURCES if list.empty?
          list
        end

        def serialize_search_result(record)
          case record
          when Issue
            {
              id: record.id,
              type: 'issues',
              url: Helpers.issue_url(record),
              title: record.subject,
              project: record.project.name,
              status: record.status.name,
              updated_on: record.updated_on,
              excerpt: record.description.to_s.truncate(200)
            }
          when WikiPage
            {
              id: record.id,
              type: 'wiki_pages',
              url: nil,
              title: record.title,
              project: record.project.name,
              status: nil,
              updated_on: record.updated_on,
              excerpt: record.content&.text.to_s.truncate(200)
            }
          else
            {
              id: record.try(:id),
              type: record.class.name.underscore.pluralize,
              url: nil,
              title: record.try(:event_title) || record.try(:name) || record.try(:title),
              project: nil,
              status: nil,
              updated_on: record.try(:updated_on) || record.try(:created_on),
              excerpt: ''
            }
          end
        end

        def serialize_wiki_page_meta(page)
          {
            title: page.title,
            version: page.content&.version,
            parent_title: page.parent&.title,
            created_on: page.created_on,
            updated_on: page.updated_on
          }
        end

        def serialize_wiki_page(page, content)
          {
            title: page.title,
            text: content.text.to_s,
            version: content.version,
            created_on: page.created_on,
            updated_on: content.updated_on || page.updated_on,
            author: Helpers.serialize_user_ref(content.author),
            project: Helpers.serialize_named_ref(page.project),
            comments: content.comments.to_s
          }
        end

        def wiki_project(user, args, project)
          project ||= Helpers.find_project(user, args[:project])
          return nil unless project
          return nil unless project.module_enabled?(:wiki)

          project
        end

        def wiki_read_allowed?(user, args, project)
          return Helpers.any_wiki_project_allows?(user, :view_wiki_pages) if args[:project].blank? && project.nil?

          project = wiki_project(user, args, project)
          return false unless project && user.allowed_to?(:view_wiki_pages, project)
          return true if args[:version].blank?

          user.allowed_to?(:view_wiki_edits, project)
        end

        def wiki_edit_allowed?(user, args, project)
          wiki_page_mutating_allowed?(user, args, project, :edit_wiki_pages)
        end

        def wiki_delete_allowed?(user, args, project)
          wiki_page_mutating_allowed?(user, args, project, :delete_wiki_pages)
        end

        def wiki_rename_allowed?(user, args, project)
          wiki_page_mutating_allowed?(user, args, project, :rename_wiki_pages)
        end

        def wiki_page_mutating_allowed?(user, args, project, permission)
          return Helpers.any_wiki_project_allows?(user, permission) if args[:project].blank? && project.nil?

          project = wiki_project(user, args, project)
          return false unless project && user.allowed_to?(permission, project)
          return true if args[:wiki_page_title].blank?

          wiki = project.wiki
          page = wiki&.find_page(args[:wiki_page_title])
          return true if page.nil?

          page.editable_by?(user)
        end
      end
    end
  end
end
