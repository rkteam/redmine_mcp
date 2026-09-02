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
      module Issues
        ISSUE_SUMMARY_FIELD_KEYS = %w[
          id url subject project status priority tracker author assigned_to created_on updated_on
        ].freeze

        ISSUE_LIST_FIELDS = (
          ISSUE_SUMMARY_FIELD_KEYS + %w[
            description category fixed_version parent_id start_date due_date done_ratio estimated_hours is_private
          ]
        ).freeze

        ISSUE_SEARCH_SCOPES = %w[all my_project subprojects].freeze
        REQUIRED_ERROR_TYPES = [:blank, :empty].freeze

        WATCHER_PRINCIPAL_ID_SCHEMA = {
          type: 'integer',
          minimum: 1,
          description: 'Watcher principal ID (user or group). Call redmine_list_users or redmine_list_groups when unknown.'
        }.freeze
        WATCHER_INPUT_SCHEMA = {
          properties: {
            issue_id: Helpers::ISSUE_ID_SCHEMA,
            principal_id: WATCHER_PRINCIPAL_ID_SCHEMA,
            user_id: WATCHER_PRINCIPAL_ID_SCHEMA.merge(
              description: 'Deprecated alias of principal_id. Same meaning: user or group ID. Do not send together with principal_id.'
            )
          },
          required: ['issue_id'],
          oneOf: [
            {required: ['principal_id'], not: {required: ['user_id']}},
            {required: ['user_id'], not: {required: ['principal_id']}},
          ]
        }.freeze

        PROJECT_SCHEMA = Helpers::PROJECT_SCHEMA

        ISSUE_FIELDS_SCHEMA = {
          type: 'array',
          uniqueItems: true,
          items: {type: 'string', enum: ISSUE_LIST_FIELDS + %w[* all]},
          description: 'Optional field names. Default: summary (id, url, subject, project, status, priority, tracker, ' \
                       'author, assigned_to, created_on, updated_on). Use * or all for all list fields including description.'
        }.freeze

        CUSTOM_FIELD_VALUE_SCHEMA = {
          oneOf: [
            {type: 'string'},
            {type: 'number'},
            {type: 'boolean'},
            {type: 'array', items: {type: 'string'}},
            {type: 'null'},
          ]
        }.freeze

        CUSTOM_FIELDS_SCHEMA = {
          type: 'array',
          maxItems: 100,
          description: 'Custom field values. Call redmine_list_project_issue_custom_fields when field IDs are unknown.',
          items: {
            type: 'object',
            properties: {
              id: {type: 'integer', minimum: 1, description: 'Custom field ID.'},
              value: CUSTOM_FIELD_VALUE_SCHEMA.merge(description: 'Custom field value.')
            },
            required: %w[id value]
          }
        }.freeze

        ISSUE_SUBJECT_SCHEMA = {
          type: 'string',
          minLength: 1,
          maxLength: 255,
          description: 'Issue subject.'
        }.freeze

        ISSUE_DESCRIPTION_SCHEMA = {
          type: 'string',
          description: 'Issue description in Redmine text format.'
        }.freeze

        ISSUE_ATTRIBUTE_PROPERTIES = {
          tracker_id: {
            type: 'integer',
            minimum: 1,
            description: 'Tracker ID returned by redmine_list_trackers or redmine_list_project_trackers.',
            examples: [1, 2]
          },
          status_id: {
            type: 'integer',
            minimum: 1,
            description: 'Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.',
            examples: [1, 2]
          },
          status_name: {
            type: 'string',
            minLength: 1,
            description: 'Issue status name as an alternative to status_id.'
          },
          priority_id: {
            type: 'integer',
            minimum: 1,
            description: 'Issue priority ID returned by redmine_list_issue_priorities.',
            examples: [3, 4]
          },
          category_id: {
            oneOf: [
              {type: 'integer', minimum: 1},
              {type: 'null'},
            ],
            description: 'Issue category ID returned by redmine_list_issue_categories, or null to clear it.'
          },
          assigned_to_id: {
            oneOf: [
              {type: 'integer', minimum: 1},
              {type: 'null'},
            ],
            description: 'Assignee principal ID (user or group) from redmine_get_issue_form_options.assignees, or null to unassign.',
            examples: [2, 3]
          },
          assignee_ref: Helpers::USER_REF_SCHEMA,
          parent_issue_id: {
            oneOf: [
              {type: 'integer', minimum: 1},
              {type: 'null'},
            ],
            description: 'Numeric ID of the parent issue, or null to clear the parent.'
          },
          fixed_version_id: {
            oneOf: [
              {type: 'integer', minimum: 1},
              {type: 'null'},
            ],
            description: 'Target version ID returned by redmine_list_versions, or null to clear it.'
          },
          start_date: {
            oneOf: [
              {type: 'string', format: 'date'},
              {type: 'null'},
            ],
            description: 'Start date in YYYY-MM-DD format, or null to clear it.',
            examples: ['2026-07-30']
          },
          due_date: {
            oneOf: [
              {type: 'string', format: 'date'},
              {type: 'null'},
            ],
            description: 'Due date in YYYY-MM-DD format, or null to clear it.',
            examples: ['2026-07-30']
          },
          estimated_hours: {
            oneOf: [
              {type: 'number', minimum: 0},
              {type: 'null'},
            ],
            description: 'Estimated hours for the issue, or null to clear it.'
          },
          done_ratio: {
            type: 'integer',
            minimum: 0,
            maximum: 100,
            description: 'Percent done from 0 to 100.'
          },
          is_private: {
            type: 'boolean',
            description: 'Whether the issue is private.'
          },
          custom_fields: CUSTOM_FIELDS_SCHEMA
        }.freeze

        ISSUE_MUTABLE_KEYS = %i[
          subject description tracker_id status_id status_name priority_id category_id
          assigned_to_id assignee_ref parent_issue_id fixed_version_id start_date due_date
          estimated_hours done_ratio is_private custom_fields
        ].freeze

        MCP_FORM_ATTRIBUTE_NAMES = (ISSUE_MUTABLE_KEYS.map(&:to_s) - %w[assignee_ref status_name]).freeze

        ISSUE_VALUE_COMPARE_ATTRIBUTES = {
          tracker_id: :tracker_id,
          status_id: :status_id,
          is_private: :is_private,
          parent_issue_id: :parent_id,
          assigned_to_id: :assigned_to_id
        }.freeze

        RELATION_TYPES = %w[
          relates duplicates duplicated blocks blocked precedes follows copied_to copied_from
        ].freeze

        LIST_ISSUE_FILTER_FIELDS = %w[
          status_id tracker_id assigned_to_id priority_id fixed_version_id category_id subject
          due_date start_date created_on updated_on estimated_hours done_ratio author_id watcher_id
        ].freeze

        FILTER_ITEM_SCHEMA = {
          type: 'object',
          properties: {
            field: {
              type: 'string',
              minLength: 1,
              description: 'Issue query field name, e.g. status_id, due_date, or cf_<id>.'
            },
            operator: {
              type: 'string',
              minLength: 1,
              description: 'Redmine query operator, e.g. =, !, >=, <=, ><, ~, o, c, *, !*.'
            },
            values: {
              type: 'array',
              items: {type: 'string'},
              description: 'Filter values as strings. Empty array for operators that need no value.'
            }
          },
          required: %w[field operator values]
        }.freeze

      module_function

        def register!
          register_get_issue
          register_list_issues
          register_search_issues
          register_run_issue_query
          register_get_issue_form_options
          register_validate_issue_create
          register_validate_issue_update
          register_create_issue
          register_update_issue
          register_add_issue_note
          register_delete_issue
          register_copy_issue
          register_list_issue_relations
          register_create_issue_relation
          register_delete_issue_relation
          register_list_subtasks
          register_add_issue_watcher
          register_remove_issue_watcher
          register_update_issue_note
          register_set_issue_note_private
          register_get_private_notes
          register_list_issue_categories
          register_create_issue_category
          register_update_issue_category
          register_delete_issue_category
        end

        def register_get_issue
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_issue',
            title: 'Get Redmine issue',
            description: "Returns one issue.\n\nDefault:\n- no journals\n- no attachments\n- no watchers, relations, or children\n\nUse include_* to request them.\nUse redmine_search_issues when " \
                         'issue_id is unknown.',
            input_schema: {
              properties: {
                issue_id: Helpers::ISSUE_ID_SCHEMA.merge(examples: [1]),
                include_journals: {type: 'boolean', description: 'Include journals. Default: false'},
                include_attachments: {type: 'boolean', description: 'Include attachments. Default: false'},
                include_custom_fields: {type: 'boolean', description: 'Include custom fields. Default: false'},
                journal_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum journals when include_journals is true. Default: 25'
                },
                journal_offset: {type: 'integer', minimum: 0, default: 0, description: 'Journals to skip'},
                include_watchers: {type: 'boolean', description: 'Include watcher list. Default: false'},
                include_relations: {type: 'boolean', description: 'Include issue relations. Default: false'},
                include_children: {type: 'boolean', description: 'Include child issues. Default: false'},
                attachment_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum attachments when include_attachments is true. Default: 100'
                },
                attachment_offset: {type: 'integer', minimum: 0, default: 0, description: 'Attachments to skip'},
                watcher_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum watchers when include_watchers is true. Default: 100'
                },
                watcher_offset: {type: 'integer', minimum: 0, default: 0, description: 'Watchers to skip'},
                relation_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum relations when include_relations is true. Default: 100'
                },
                relation_offset: {type: 'integer', minimum: 0, default: 0, description: 'Relations to skip'},
                children_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum child issues when include_children is true. Default: 100'
                },
                children_offset: {type: 'integer', minimum: 0, default: 0, description: 'Child issues to skip'}
              },
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ISSUE,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_issue)
          )
        end

        def register_list_issues
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issues',
            title: 'List issues',
            description: "Returns a paginated list of issues matching structured filters.\n\nDefault: summary fields only; limit 25, max 100.\nUse redmine_get_issue for full detail.\nUse " \
                         "redmine_search_issues for free-text lookup.\nOptional filters array uses Redmine query operators for advanced filtering.\nCall redmine_get_issue_form_options or " \
                         'redmine_list_projects / redmine_list_issue_statuses / redmine_list_trackers when filter IDs are unknown.',
            input_schema: {
              properties: {
                project: PROJECT_SCHEMA,
                status_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Issue status ID returned by redmine_list_issue_statuses.',
                  examples: [1, 2]
                },
                tracker_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Tracker ID returned by redmine_list_trackers.',
                  examples: [1, 2]
                },
                assigned_to_id: Helpers::USER_ID_SCHEMA,
                assignee_ref: Helpers::USER_REF_SCHEMA,
                priority_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Issue priority ID returned by redmine_list_issue_priorities.',
                  examples: [3, 4]
                },
                fixed_version_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Target version ID returned by redmine_list_versions.'
                },
                filters: {
                  type: 'array',
                  maxItems: 50,
                  items: FILTER_ITEM_SCHEMA,
                  description: 'Advanced Redmine query filters combined with flat filters via AND.'
                },
                sort: {type: 'string', description: 'Sort order, e.g. updated_on:desc', examples: ['updated_on:desc']},
                fields: ISSUE_FIELDS_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ISSUES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issues)
          )
        end

        def register_search_issues
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'search_issues',
            title: 'Search issues',
            description: "Searches issues by free-text query against subject and description.\n\nDefault: summary fields; limit 25, max 100.\nOptional scope: all (default), my_project (projects " \
                         "where the user is a member), or subprojects (requires project; searches that project and its descendants).\nUse redmine_list_issues for structured filters.\nUse " \
                         "redmine_search_all for wiki and other resources.\nUse redmine_get_issue for full detail.",
            input_schema: {
              properties: {
                query: {type: 'string', minLength: 1, description: 'Text to search for in issues'},
                fields: ISSUE_FIELDS_SCHEMA,
                project: PROJECT_SCHEMA,
                scope: {
                  type: 'string',
                  enum: ISSUE_SEARCH_SCOPES,
                  description: 'all (default), my_project, or subprojects. subprojects requires project.'
                },
                open_issues: {type: 'boolean', description: 'Search only open issues'}
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['query']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ISSUES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:search_issues)
          )
        end

        def register_run_issue_query
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'run_issue_query',
            title: 'Run saved issue query',
            description: "Executes one saved issue query by query_id and returns matching issues.\n\nDefault: summary fields; limit 25, max 100.\nCall redmine_list_queries to discover query_id.\n" \
                         'Optional project narrows a global query to one visible project. Does not modify Redmine.',
            input_schema: {
              properties: {
                query_id: {type: 'integer', minimum: 1, description: 'Saved query ID from redmine_list_queries.'},
                project: PROJECT_SCHEMA,
                fields: ISSUE_FIELDS_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['query_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ISSUES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:run_issue_query)
          )
        end

        def register_get_issue_form_options
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_issue_form_options',
            title: 'Get issue form options',
            description: 'Return allowed issue form values for the current user in one call: selectable trackers, statuses, ' \
                         'priorities, categories, versions, assignable users/groups, and editable custom fields (workflow-aware). ' \
                         'Optional tracker_id refines a create form; optional issue_id returns the update form of that issue. ' \
                         'Also returns editable_fields and required_fields for the current user. ' \
                         'Do not pass tracker_id with issue_id unless it matches the issue tracker. Prefer this before ' \
                         'redmine_create_issue or redmine_update_issue when IDs are unknown. Separate list_* reference tools ' \
                         'remain available. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: PROJECT_SCHEMA,
                tracker_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Optional tracker ID for a create form. Must be selectable by the current user. With issue_id, must match the issue tracker.'
                },
                issue_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Optional existing issue ID to return the update form for that issue.'
                }
              },
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::FORM_OPTIONS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_issue_form_options)
          )
        end

        def register_validate_issue_create
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'validate_issue_create',
            title: 'Validate issue create',
            description: 'Validate parameters for creating an issue without saving. Same fields as redmine_create_issue ' \
                         'except idempotency_key. Returns valid/errors; rejected_fields lists explicit values Redmine would ' \
                         'not apply. Available in MCP read-only mode. Use before redmine_create_issue when field values may ' \
                         'violate workflow or project rules.',
            input_schema: {
              properties: {
                project: PROJECT_SCHEMA,
                subject: ISSUE_SUBJECT_SCHEMA,
                description: ISSUE_DESCRIPTION_SCHEMA
              }.merge(ISSUE_ATTRIBUTE_PROPERTIES),
              required: %w[project subject]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::VALIDATION,
            permission: :add_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:validate_issue_create)
          )
        end

        def register_validate_issue_update
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'validate_issue_update',
            title: 'Validate issue update',
            description: 'Validate issue attribute changes without saving and without creating a journal entry. Accepts ' \
                         'the same attribute fields as redmine_update_issue, but not uploads. Returns valid/errors; ' \
                         'rejected_fields lists explicit values Redmine would not apply. Available in MCP read-only mode. ' \
                         'Use before redmine_update_issue when attribute values may violate workflow or assignment rules.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'Numeric ID of the issue to validate.', examples: [1]},
                subject: ISSUE_SUBJECT_SCHEMA,
                description: ISSUE_DESCRIPTION_SCHEMA
              }.merge(ISSUE_ATTRIBUTE_PROPERTIES),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::VALIDATION,
            permission: ->(user, args, _project) { update_issue_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:validate_issue_update)
          )
        end

        def register_create_issue
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_issue',
            title: 'Create issue',
            description: "Creates one issue in a project.\n\nRequires project and subject.\nCall redmine_get_issue_form_options when tracker, status, assignee, or custom field IDs are unknown.\n" \
                         'Optional idempotency_key prevents duplicate creates on retry. Use redmine_validate_issue_create for a dry-run without saving.',
            input_schema: {
              properties: {
                project: PROJECT_SCHEMA,
                subject: ISSUE_SUBJECT_SCHEMA,
                description: ISSUE_DESCRIPTION_SCHEMA,
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              }.merge(ISSUE_ATTRIBUTE_PROPERTIES),
              required: %w[project subject]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ISSUE,
            permission: :add_issues,
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_issue)
          )
        end

        def register_update_issue
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_issue',
            title: 'Update issue',
            description: "Updates one existing issue by issue_id.\n\nSupply only fields that should change. Does not add comments or replace watchers.\n" \
                         "Use redmine_add_issue_note for comments and redmine_add_issue_watcher / redmine_remove_issue_watcher for watchers.\n" \
                         'Optional expected_updated_at rejects stale updates with CONFLICT. ' \
                         'uploads-only calls are allowed when the user can add attachments even without editing attributes. ' \
                         'Optional idempotency_key prevents duplicate attachments on retry. ' \
                         'Call redmine_get_issue_form_options when allowed values are unknown. Use redmine_validate_issue_update for a dry-run without saving. Use redmine_copy_issue to create a ' \
                         'new issue from an existing one.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'Numeric ID of the issue to update.', examples: [1]},
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA,
                subject: ISSUE_SUBJECT_SCHEMA,
                description: ISSUE_DESCRIPTION_SCHEMA,
                uploads: Helpers::ISSUE_UPLOADS_SCHEMA,
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              }.merge(ISSUE_ATTRIBUTE_PROPERTIES),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ISSUE_UPDATED,
            permission: ->(user, args, _project) { update_issue_allowed?(user, args) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_issue)
          )
        end

        def register_add_issue_note
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'add_issue_note',
            title: 'Add issue note',
            description: 'Add a comment to an existing issue without changing issue fields. Requires issue_id and notes. ' \
                         'Optional private_notes marks the comment private and requires set_notes_private. Optional uploads ' \
                         'attach files in the same call. Optional idempotency_key prevents a duplicate comment on retry. ' \
                         'Returns issue_id, journal_id, notes, and private_notes. Requires add_issue_notes on the issue. ' \
                         'Blocked when MCP read-only mode is enabled. To change issue attributes, use redmine_update_issue. ' \
                         'To edit an existing journal entry, use redmine_update_issue_note.',
            input_schema: {
              properties: {
                issue_id: Helpers::ISSUE_ID_SCHEMA,
                notes: {type: 'string', minLength: 1, description: 'Comment text to add to the issue.'},
                private_notes: {type: 'boolean', description: 'Whether the comment is private. Default: false.'},
                uploads: Helpers::ISSUE_UPLOADS_SCHEMA,
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              },
              required: %w[issue_id notes]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ISSUE_NOTE,
            permission: ->(user, args, _project) { add_issue_note_allowed?(user, args) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:add_issue_note)
          )
        end

        def register_delete_issue
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_issue',
            title: 'Delete issue',
            description: 'Permanently delete one issue by issue_id. Requires confirm_delete=true; when the issue has subtasks, also pass confirm_delete_with_children=true. The first call without ' \
                         'confirmation returns impact details instead of deleting. Optional expected_updated_at rejects deletion with CONFLICT if the issue changed since that timestamp. Returns ' \
                         'deleted_issue_id and cascade impact on success. Requires delete_issues. Blocked when MCP read-only mode is enabled. This operation is irreversible and removes journals, ' \
                         'attachments, relations, and time entries.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'Numeric issue ID to delete.'},
                expected_updated_at: Helpers::EXPECTED_UPDATED_AT_SCHEMA,
                confirm_delete: {type: 'boolean', description: 'Pass true to actually delete'},
                confirm_delete_with_children: {
                  type: 'boolean',
                  description: 'Required when the issue has subtasks'
                }
              },
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_ISSUE,
            permission: :delete_issues,
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_issue)
          )
        end

        def register_copy_issue
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'copy_issue',
            title: 'Copy issue',
            description: 'Duplicate one existing issue into the same project or another project via optional project. Optional overrides include subject, description, and standard issue ' \
                         'fields. Linking to the original and copying attachments follow Redmine settings link_copied_issue and copy_attachments_on_issue_copy (yes/no/ask). Watchers are copied ' \
                         'only with add_issue_watchers on the target project. Parent is kept when allowed. Returns the new issue detail. Requires copy_issues on the source project and ' \
                         'add_issues on the target project. Optional idempotency_key prevents a duplicate copy on retry. Blocked ' \
                         'when MCP read-only mode is enabled. For a blank issue without copying content, use redmine_create_issue instead.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'ID of the source issue to copy'},
                project: PROJECT_SCHEMA,
                subject: {type: 'string', minLength: 1, maxLength: 255, description: 'New subject for the copy'},
                description: {type: 'string', description: 'Override description on the copy'},
                link_original: {
                  type: 'boolean',
                  description: 'Create copied_to/copied_from relation when Redmine setting link_copied_issue is ask. Ignored when the setting is yes or no.'
                },
                copy_subtasks: {type: 'boolean', description: 'Recursively copy subtasks. Default: true'},
                copy_attachments: {
                  type: 'boolean',
                  description: 'Copy attachments when Redmine setting copy_attachments_on_issue_copy is ask. Ignored when the setting is yes or no.'
                },
                idempotency_key: Helpers::IDEMPOTENCY_KEY_SCHEMA
              }.merge(ISSUE_ATTRIBUTE_PROPERTIES),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::ISSUE,
            permission: ->(user, args, _project) { copy_issue_allowed?(user, args) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:copy_issue)
          )
        end

        def register_list_issue_relations
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_relations',
            title: 'List issue relations',
            description: 'Return a paginated list of relations linked to one issue by issue_id. Each item includes relation id, type, delay, and linked issue references. Use to inspect blocks, ' \
                         'duplicates, relates, and other links before redmine_create_issue_relation or redmine_delete_issue_relation. For a non-paginated relation snapshot inside full issue ' \
                         'detail, ' \
                         '' \
                         '' \
                         'use redmine_get_issue ' \
                         'with include_relations. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                issue_id: Helpers::ISSUE_ID_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_RELATIONS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_relations)
          )
        end

        def register_create_issue_relation
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_issue_relation',
            title: 'Create issue relation',
            description: 'Create one relation between two issues. Requires issue_id and issue_to_id; relation_type defaults to relates. delay applies to precedes and follows relations. Returns the ' \
                         'created relation object. Requires manage_issue_relations on both issues. Blocked when MCP ' \
                         'read-only mode is enabled. Call redmine_list_issue_relations or redmine_search_issues when ' \
                         'target issue IDs are unknown.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'Source issue ID.'},
                issue_to_id: {type: 'integer', minimum: 1, description: 'Target issue ID.'},
                relation_type: {type: 'string', enum: RELATION_TYPES, description: 'Defaults to relates.'},
                delay: {type: 'integer', minimum: 0, description: 'Delay in days for precedes/follows.'}
              },
              required: ['issue_id', 'issue_to_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::RELATION,
            permission: ->(user, args, _project) { create_issue_relation_allowed?(user, args) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_issue_relation)
          )
        end

        def register_delete_issue_relation
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_issue_relation',
            title: 'Delete issue relation',
            description: 'Permanently delete one issue relation by relation_id. Returns deleted_relation_id only. The relation must be deletable by the current user (both issues visible and ' \
                         'manage_issue_relations on at least one side). Blocked when MCP ' \
                         'read-only mode is enabled. This operation cannot be undone through MCP. Call redmine_list_issue_relations first to obtain relation_id.',
            input_schema: {
              properties: {
                relation_id: {type: 'integer', minimum: 1, description: 'Relation ID to delete.'}
              },
              required: ['relation_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_RELATION,
            permission: ->(user, args, _project) { delete_issue_relation_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_issue_relation)
          )
        end

        def register_list_subtasks
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_subtasks',
            title: 'List subtasks',
            description: 'Return a paginated list of direct child issues for one parent issue_id. Each item uses the same summary fields as redmine_list_issues by default. Use for hierarchy ' \
                         'navigation ' \
                         'when the parent issue is known. For a brief embedded child list inside full issue detail, use redmine_get_issue with include_children. For text search across issues, use ' \
                         'redmine_search_issues. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'ID of the parent issue'}
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_ISSUES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_subtasks)
          )
        end

        def register_add_issue_watcher
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'add_issue_watcher',
            title: 'Add issue watcher',
            description: 'Add one principal (user or group) as a watcher on an issue. Requires issue_id and principal_id. ' \
                         'user_id is a deprecated alias of principal_id. Returns the issue_id, principal_id, and user_id. ' \
                         'Requires permission to add watchers on the issue. ' \
                         'Blocked when MCP read-only mode is enabled. Call redmine_list_users or redmine_list_groups ' \
                         'when the watcher ID is unknown.',
            input_schema: WATCHER_INPUT_SCHEMA,
            output_schema: RedmineMcp::Core::OutputSchemas::WATCHER,
            permission: ->(user, args, _project) { add_issue_watcher_allowed?(user, args) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:add_issue_watcher)
          )
        end

        def register_remove_issue_watcher
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'remove_issue_watcher',
            title: 'Remove issue watcher',
            description: 'Remove one principal (user or group) from the watchers of an issue. Requires issue_id and ' \
                         'principal_id. user_id is a deprecated alias of principal_id. Returns the issue_id, principal_id, ' \
                         'and user_id. Requires permission to delete watchers on ' \
                         'the issue. Blocked when MCP read-only mode is enabled. To inspect current watchers, use ' \
                         'redmine_get_issue with include_watchers.',
            input_schema: WATCHER_INPUT_SCHEMA,
            output_schema: RedmineMcp::Core::OutputSchemas::WATCHER,
            permission: ->(user, args, _project) { remove_issue_watcher_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:remove_issue_watcher)
          )
        end

        def register_update_issue_note
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_issue_note',
            title: 'Update issue note',
            description: 'Edit the text of one visible issue journal entry by journal_id. Requires notes (empty string ' \
                         'clears the existing text); optional private_notes changes visibility and requires ' \
                         'set_notes_private. Returns journal_id, notes, and private_notes. The journal must be visible ' \
                         'and editable by the current user. Blocked when MCP read-only mode is enabled. To add a new ' \
                         'comment instead of editing history, use redmine_add_issue_note.',
            input_schema: {
              properties: {
                journal_id: {type: 'integer', minimum: 1, description: 'Journal entry ID from redmine_get_issue with include_journals.'},
                notes: {type: 'string', description: 'New journal note text. Empty string clears the existing note.'},
                private_notes: {type: 'boolean', description: 'Whether the note is private.'}
              },
              required: %w[journal_id notes]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::JOURNAL,
            permission: ->(user, args, _project) { issue_note_editable?(user, args[:journal_id], privacy_change: args.key?(:private_notes)) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_issue_note)
          )
        end

        def register_set_issue_note_private
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'set_issue_note_private',
            title: 'Set issue note privacy',
            description: 'Set whether one visible issue journal entry is private by journal_id. Requires is_private ' \
                         'and set_notes_private. Returns journal_id and private_notes flag. The journal must be ' \
                         'visible and editable by the current user. Blocked when MCP read-only mode is enabled. To ' \
                         'create a new private comment, use redmine_add_issue_note with notes and private_notes.',
            input_schema: {
              properties: {
                journal_id: {type: 'integer', minimum: 1, description: 'Journal entry ID from redmine_get_issue with include_journals.'},
                is_private: {type: 'boolean', description: 'true marks the note private; false makes it public.'}
              },
              required: %w[journal_id is_private]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::NOTE_PRIVACY,
            permission: ->(user, args, _project) { issue_note_editable?(user, args[:journal_id], privacy_change: true) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:set_issue_note_private)
          )
        end

        def register_get_private_notes
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_private_notes',
            title: 'Get private notes',
            description: 'Return a paginated list of private journal notes for one issue by issue_id. Requires view_private_notes permission and should be used only when the user explicitly needs ' \
                         'private comments. Does not return public comments, issue fields, or attachments. For all journals when permitted, use redmine_get_issue with include_journals. Default ' \
                         'limit 25, ' \
                         'maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                issue_id: {type: 'integer', minimum: 1, description: 'ID of the issue'}
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['issue_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_JOURNALS,
            permission: :view_private_notes,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_private_notes)
          )
        end

        def register_list_issue_categories
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_categories',
            title: 'List issue categories',
            description: 'Return a paginated list of issue categories configured for one project. Each item includes id, name, project reference, and default assignee. Use before ' \
                         'redmine_create_issue or ' \
                         'redmine_update_issue when category_id is unknown. Requires project. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_CATEGORIES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_categories)
          )
        end

        def register_create_issue_category
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'create_issue_category',
            title: 'Create issue category',
            description: 'Create one issue category in a project. Requires project and name; optional assigned_to_id ' \
                         'sets the default assignee principal (user or group). Returns the created category object. ' \
                         'Requires manage_categories on the project. Blocked when MCP read-only mode is enabled.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                name: {type: 'string', minLength: 1, maxLength: 60, description: 'Category name.'},
                assigned_to_id: {
                  type: 'integer',
                  minimum: 1,
                  description: 'Default assignee principal ID (user or group).'
                }
              },
              required: %w[project name]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::CATEGORY,
            permission: ->(user, args, project) { create_issue_category_allowed?(user, args, project) },
            annotations: Helpers::CREATE_ANNOTATIONS,
            handler: method(:create_issue_category)
          )
        end

        def register_update_issue_category
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'update_issue_category',
            title: 'Update issue category',
            description: 'Update one issue category by category_id. Supply name and/or assigned_to_id; at least one field besides category_id is required. Pass null for assigned_to_id to clear the ' \
                         'default assignee. Returns the updated category object. ' \
                         'Requires manage_categories on the category project. Blocked when MCP read-only mode is enabled. Call redmine_list_issue_categories when category_id is unknown.',
            input_schema: {
              properties: {
                category_id: {type: 'integer', minimum: 1, description: 'Category ID from redmine_list_issue_categories.'},
                name: {type: 'string', minLength: 1, maxLength: 60, description: 'Category name.'},
                assigned_to_id: {
                  oneOf: [
                    {type: 'integer', minimum: 1},
                    {type: 'null'},
                  ],
                  description: 'Default assignee principal ID (user or group), or null to clear.'
                }
              },
              required: ['category_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::CATEGORY,
            permission: ->(user, args, _project) { update_issue_category_allowed?(user, args) },
            annotations: Helpers::UPDATE_ANNOTATIONS,
            handler: method(:update_issue_category)
          )
        end

        def register_delete_issue_category
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'delete_issue_category',
            title: 'Delete issue category',
            description: 'Delete one issue category by category_id. Optional reassign_to_id moves existing issues to another category in the same project before deletion. Returns ' \
                         'deleted_category_id and reassigned_to_id when provided. Requires manage_categories on the category project. Blocked when MCP read-only mode is enabled. Call ' \
                         'redmine_list_issue_categories to choose a reassignment target.',
            input_schema: {
              properties: {
                category_id: {type: 'integer', minimum: 1, description: 'Category ID from redmine_list_issue_categories.'},
                reassign_to_id: {type: 'integer', minimum: 1, description: 'Optional category ID to reassign issues before delete.'}
              },
              required: ['category_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::DELETED_CATEGORY,
            permission: ->(user, args, _project) { delete_issue_category_allowed?(user, args) },
            annotations: Helpers::DELETE_ANNOTATIONS,
            handler: method(:delete_issue_category)
          )
        end

        def get_issue(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          include_custom_fields = Helpers.truthy?(args[:include_custom_fields])

          result = serialize_issue_detail(issue)
          result[:custom_fields] = if include_custom_fields
                                     issue.visible_custom_field_values(user).map do |cfv|
                                       {id: Helpers.integer_id(cfv.custom_field_id), name: cfv.custom_field.name, value: cfv.value}
                                     end
                                   else
                                     []
                                   end
          assign_optional_nested_list(
            result,
            enabled: Helpers.truthy?(args[:include_journals]),
            items_key: :journals,
            pagination_key: :journal_pagination,
            collection: visible_journals_scope(issue, user),
            page: {limit: Helpers.clamp_limit(args[:journal_limit]), offset: Helpers.clamp_offset(args[:journal_offset])}
          ) { |journal| serialize_journal(journal, user) }
          assign_optional_nested_list(
            result,
            enabled: Helpers.truthy?(args[:include_attachments]),
            items_key: :attachments,
            pagination_key: :attachments_pagination,
            collection: issue.attachments.reorder(:id),
            page: {limit: Helpers.nested_list_limit(args[:attachment_limit]), offset: Helpers.clamp_offset(args[:attachment_offset])}
          ) { |attachment| Helpers.serialize_attachment(attachment) }
          assign_optional_nested_list(
            result,
            enabled: Helpers.truthy?(args[:include_watchers]),
            items_key: :watchers,
            pagination_key: :watchers_pagination,
            collection: visible_watchers_scope(issue, user),
            page: {limit: Helpers.nested_list_limit(args[:watcher_limit]), offset: Helpers.clamp_offset(args[:watcher_offset])}
          ) { |watcher| Helpers.serialize_user_ref(watcher) }
          assign_optional_nested_list(
            result,
            enabled: Helpers.truthy?(args[:include_relations]),
            items_key: :relations,
            pagination_key: :relations_pagination,
            collection: visible_relations_scope(issue, user),
            page: {limit: Helpers.nested_list_limit(args[:relation_limit]), offset: Helpers.clamp_offset(args[:relation_offset])}
          ) { |relation| serialize_relation(relation) }
          assign_optional_nested_list(
            result,
            enabled: Helpers.truthy?(args[:include_children]),
            items_key: :children,
            pagination_key: :children_pagination,
            collection: issue.children.visible(user).order(:id),
            page: {limit: Helpers.nested_list_limit(args[:children_limit]), offset: Helpers.clamp_offset(args[:children_offset])}
          ) do |child|
            {
              id: Helpers.integer_id(child.id),
              url: Helpers.issue_url(child),
              subject: child.subject,
              tracker: Helpers.serialize_named_ref(child.tracker)
            }
          end
          result
        end

        def list_issues(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope, err = build_issue_scope(user, args)
          return err if err

          total = scope.count
          issues = apply_sort(scope, args[:sort]).offset(offset).limit(limit).to_a
          serialized = issues.map { |issue| serialize_issue_list_item(issue, args[:fields]) }

          Helpers.paginated_list(serialized, total_count: total, limit: limit, offset: offset)
        end

        def run_issue_query(args, context)
          user = context[:user]
          query = IssueQuery.visible(user).find_by(id: args[:query_id])
          return Helpers.error_result(:error_mcp_query_not_found) unless query

          if args[:project].present?
            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project

            return Helpers.error_result(:error_mcp_invalid_parameters) if query.project_id.present? && query.project_id != project.id

            query.project = project if query.project_id.nil?
          end

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          total = query.issue_count
          issues = query.issues(limit: limit, offset: offset)
          serialized = issues.map { |issue| serialize_issue_list_item(issue, args[:fields]) }
          Helpers.paginated_list(serialized, total_count: total, limit: limit, offset: offset)
        end

        def get_issue_form_options(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          issue = nil
          if args[:issue_id].present?
            issue = Issue.visible(user).find_by(id: args[:issue_id], project_id: project.id)
            return Helpers.error_result(:error_mcp_invalid_parameters) unless issue
          end

          return Helpers.error_result(:error_mcp_invalid_parameters) if issue && args[:tracker_id].present? && args[:tracker_id].to_i != issue.tracker_id

          allowed_trackers = if issue
                               issue.allowed_target_trackers(user)
                             else
                               Issue.allowed_target_trackers(project, user)
                             end

          tracker = nil
          if args[:tracker_id].present?
            tracker = allowed_trackers.find_by(id: args[:tracker_id])
            return Helpers.error_result(:error_mcp_invalid_parameters) unless tracker
          end

          form_issue = issue || build_form_draft_issue(project, user, tracker || allowed_trackers.first)
          statuses = form_issue.new_statuses_allowed_to(user, true)

          {
            project: Helpers.serialize_project(project),
            trackers: allowed_trackers.map { |item| {id: Helpers.integer_id(item.id), name: item.name} },
            statuses: statuses.map { |item| {id: Helpers.integer_id(item.id), name: item.name, is_closed: item.is_closed?} },
            priorities: IssuePriority.active.map do |item|
              {id: Helpers.integer_id(item.id), name: item.name, is_default: item.is_default?}
            end,
            categories: project.issue_categories.map { |item| {id: Helpers.integer_id(item.id), name: item.name} },
            versions: form_issue.assignable_versions.map do |item|
              {
                id: Helpers.integer_id(item.id),
                name: item.name,
                status: item.status,
                due_date: item.effective_date&.strftime('%Y-%m-%d')
              }
            end,
            assignees: serialize_form_assignees(form_issue.assignable_users),
            custom_fields: form_issue.editable_custom_field_values(user).map do |custom_value|
              serialize_editable_custom_field(form_issue, custom_value, user)
            end,
            editable_fields: mcp_editable_fields(form_issue, user),
            required_fields: mcp_required_fields(form_issue, user)
          }
        end

        def mcp_editable_fields(form_issue, user)
          core = mcp_form_field_names(form_issue.safe_attribute_names(user))
          custom_ids = form_issue.editable_custom_field_values(user).map { |value| value.custom_field.id.to_s }
          (core + custom_ids).uniq
        end

        def mcp_required_fields(form_issue, user)
          mcp_form_field_names(form_issue.required_attribute_names(user))
        end

        def mcp_form_field_names(names)
          names.map(&:to_s).select do |name|
            MCP_FORM_ATTRIBUTE_NAMES.include?(name) || name.match?(/\A\d+\z/)
          end
        end

        def build_form_draft_issue(project, user, tracker)
          draft = Issue.new(project: project, author: user)
          draft.tracker = tracker if tracker
          draft.status = draft.new_statuses_allowed_to(user, true).first || draft.default_status
          draft
        end

        def serialize_form_assignees(principals)
          principals.map do |item|
            if item.is_a?(Group)
              {id: Helpers.integer_id(item.id), name: item.name, type: 'group'}
            else
              {id: Helpers.integer_id(item.id), name: item.name, login: item.login, type: 'user'}
            end
          end
        end

        def serialize_editable_custom_field(issue, custom_value, user)
          field = custom_value.custom_field
          {
            id: Helpers.integer_id(field.id),
            name: field.name,
            field_format: field.field_format,
            required: field.is_required || issue.required_attribute?(field.id.to_s, user),
            readonly: false,
            multiple: field.multiple?,
            default_value: field.default_value,
            possible_values: custom_field_possible_values(field, issue),
            trackers: field.trackers.map { |tracker| Helpers.serialize_named_ref(tracker) }
          }
        end

        def custom_field_possible_values(field, issue)
          Array(field.possible_values_options(issue)).map { |entry| serialize_custom_field_option(entry) }
        end

        def serialize_custom_field_option(entry)
          if entry.is_a?(Array)
            {label: entry.first.to_s, value: entry.last.to_s}
          else
            {label: entry.to_s, value: entry.to_s}
          end
        end

        def validate_issue_create(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          fields = issue_write_fields_from_args(args, user: user, include_subject: true)
          issue = Issue.new(project: project, author: user)
          apply_create_issue_start_date_default(issue, fields, user)
          rejected_fields = apply_issue_fields(issue, fields, user: user)
          issue.valid?
          append_rejected_field_errors(issue, rejected_fields)
          validation_result(issue, rejected_fields: rejected_fields)
        end

        def validate_issue_update(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          fields = issue_write_fields_from_args(args, user: user, include_subject: true)
          return Helpers.error_result(:error_mcp_invalid_parameters) if fields.empty?

          issue.init_journal(user)
          rejected_fields = apply_issue_fields(issue, fields, user: user)
          issue.valid?
          append_rejected_field_errors(issue, rejected_fields)
          validation_result(issue, rejected_fields: rejected_fields)
        end

        def search_issues(args, context)
          user = context[:user]
          query = args[:query].to_s
          return Helpers.error_result(:error_mcp_invalid_parameters) if query.blank?

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = Issue.visible(user)
          scope = scope.where(
            'LOWER(issues.subject) LIKE :p ESCAPE :s OR LOWER(issues.description) LIKE :p ESCAPE :s',
            Helpers.like_binds(query.downcase)
          )
          scope = scope.open if Helpers.truthy?(args[:open_issues])
          search_scope = args[:scope].to_s
          if search_scope == 'subprojects'
            return Helpers.error_result(:error_mcp_invalid_parameters) if args[:project].blank?

            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project

            scope = scope.where(project_id: project.self_and_descendants.select(:id))
          elsif search_scope == 'my_project'
            project_ids = Project.visible(user).where(Project.allowed_to_condition(user, :view_issues)).pluck(:id)
            member_ids = Member.where(user_id: user.id).pluck(:project_id)
            scope = scope.where(project_id: (project_ids & member_ids))
          end

          total = scope.count
          issues = scope.order(updated_on: :desc, id: :desc).offset(offset).limit(limit).to_a
          serialized = issues.map { |issue| serialize_issue_list_item(issue, args[:fields]) }

          Helpers.paginated_list(serialized, total_count: total, limit: limit, offset: offset)
        end

        def create_issue(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'create_issue', key: args[:idempotency_key], args: args) do
            create_issue_once(args, context)
          end
        end

        def create_issue_once(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          fields = issue_write_fields_from_args(args, user: user, include_subject: true)
          issue = Issue.new(project: project, author: user)
          apply_create_issue_start_date_default(issue, fields, user)
          rejected_fields = apply_issue_fields(issue, fields, user: user)
          write_error = issue_write_validation_error(issue, rejected_fields)
          return write_error if write_error
          return issue_validation_error(issue) unless issue.save

          serialize_issue_detail(issue)
        end

        def update_issue(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'update_issue', key: args[:idempotency_key], args: args) do
            update_issue_once(args, context)
          end
        end

        def update_issue_once(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          conflict = Helpers.conflict_if_stale(issue, args[:expected_updated_at])
          return conflict if conflict

          fields = issue_write_fields_from_args(args, user: user, include_subject: true)

          Helpers.with_issue_upload_entries(args[:uploads]) do |upload_entries, upload_err|
            return upload_err if upload_err
            return Helpers.error_result(:error_mcp_invalid_parameters) if fields.empty? && upload_entries.empty?

            return Helpers.error_result(:error_mcp_permission_denied) if upload_entries.any? && !issue.attachments_addable?(user)

            issue.init_journal(user)
            journal = issue.current_journal
            rejected_fields = fields.empty? ? [] : apply_issue_fields(issue, fields, user: user)
            write_error = issue_write_validation_error(issue, rejected_fields)
            return write_error if write_error

            save_attachments_result = nil
            save_attachments_result = issue.save_attachments(upload_entries, user) if upload_entries.any?
            return issue_validation_error(issue) if issue.errors.any?
            return issue_validation_error(issue) unless issue.save

            build_updated_issue_result(issue.reload, upload_entries, save_attachments_result, journal)
          end
        end

        def build_updated_issue_result(issue, upload_entries, save_attachments_result, journal)
          result = serialize_issue_detail(issue)
          if upload_entries.any?
            result[:added_attachments] = serialize_added_attachments(save_attachments_result)
            result[:journal_id] = Helpers.integer_id(journal&.id)
            merge_unsaved_attachments!(result, issue, save_attachments_result)
          else
            result[:added_attachments] = []
            result[:journal_id] = nil
            result[:attachments_not_saved_count] = 0
            result[:attachments_not_saved] = []
          end
          result
        end

        def serialize_added_attachments(save_attachments_result)
          Array(save_attachments_result&.[](:files)).map { |attachment| Helpers.serialize_attachment(attachment) }
        end

        def merge_unsaved_attachments!(result, issue, save_attachments_result)
          unsaved_count = issue.unsaved_attachments.size
          if unsaved_count.positive?
            result[:warning] = I18n.t(:warning_mcp_attachments_not_saved, count: unsaved_count)
            result[:attachments_not_saved_count] = unsaved_count
            unsaved_attachments = Array(save_attachments_result&.[](:unsaved))
            result[:attachments_not_saved] = unsaved_attachments.map(&:filename)
          else
            result[:attachments_not_saved_count] = 0
            result[:attachments_not_saved] = []
          end
        end

        def delete_issue(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          return Helpers.error_result(:error_mcp_permission_denied) unless issue.deletable?(user)

          conflict = Helpers.conflict_if_stale(issue, args[:expected_updated_at])
          return conflict if conflict

          impact = issue_delete_impact(issue, user)
          unless Helpers.truthy?(args[:confirm_delete])
            return Helpers.error_result(
              :error_mcp_delete_issue_confirmation_required,
              issue_id: issue.id,
              details: {
                reason: 'confirmation_required',
                hint: I18n.t(:hint_mcp_delete_issue_confirmation),
                impact: impact
              }
            )
          end
          if issue.children.exists? && !Helpers.truthy?(args[:confirm_delete_with_children])
            return Helpers.error_result(
              :error_mcp_delete_issue_children_present,
              issue_id: issue.id,
              details: {reason: 'children_present', impact: impact}
            )
          end

          deleted_id = issue.id
          issue.destroy
          {deleted_issue_id: deleted_id, cascade_deleted: impact}
        end

        def copy_issue(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'copy_issue', key: args[:idempotency_key], args: args) do
            copy_issue_once(args, context)
          end
        end

        def copy_issue_once(args, context)
          user = context[:user]
          source, err = find_visible_issue(user, args[:issue_id])
          return err if err

          target_project =
            if args[:project].present?
              Helpers.find_project(user, args[:project])
            else
              source.project
            end
          return Helpers.error_result(:error_mcp_project_not_found) unless target_project
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:copy_issues, source.project)
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:add_issues, target_project)

          copy_options = {
            link: copy_flag_from_setting?(Setting.link_copied_issue, args[:link_original]),
            subtasks: args.key?(:copy_subtasks) ? Helpers.truthy?(args[:copy_subtasks]) : true,
            attachments: copy_flag_from_setting?(Setting.copy_attachments_on_issue_copy, args[:copy_attachments]),
            watchers: user.allowed_to?(:add_issue_watchers, target_project)
          }

          issue = source.copy({project_id: target_project.id}, copy_options)
          issue.author = user
          issue.parent_issue_id = source.parent_id
          issue.public_send(:safe_attributes=, {}, user)
          fields = issue_write_fields_from_args(args, user: user, include_subject: true)
          rejected_fields = apply_issue_fields(issue, fields, user: user)
          write_error = issue_write_validation_error(issue, rejected_fields)
          return write_error if write_error
          return issue_validation_error(issue) unless issue.save

          serialize_issue_detail(issue)
        end

        def list_issue_relations(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(
            visible_relations_scope(issue, user),
            limit: limit,
            offset: offset
          ) do |relation|
            serialize_relation(relation)
          end
        end

        def create_issue_relation(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          relation = IssueRelation.new
          relation.issue_from = issue
          relation.safe_attributes = {
            'issue_to_id' => args[:issue_to_id],
            'relation_type' => args[:relation_type].presence || IssueRelation::TYPE_RELATES,
            'delay' => args[:delay]
          }
          relation.init_journals(user)
          return Helpers.model_errors(relation) unless relation.save

          serialize_relation(relation)
        end

        def delete_issue_relation(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          relation = IssueRelation.find_by(id: args[:relation_id])
          return Helpers.error_result(:error_mcp_relation_not_found) unless relation
          return Helpers.error_result(:error_mcp_relation_not_found) unless relation.deletable?(user)

          deleted_id = relation.id
          relation.init_journals(user)
          relation.destroy
          {deleted_relation_id: deleted_id}
        end

        def list_subtasks(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(
            issue.children.visible(user).reorder(:id),
            limit: limit,
            offset: offset
          ) do |child|
            serialize_issue_list_item(child, nil)
          end
        end

        def add_issue_watcher(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          principal_id, id_err = watcher_principal_id_from_args(args)
          return id_err if id_err

          target = resolve_addable_watcher(issue, principal_id)
          return watcher_add_error(user, issue, principal_id) unless target

          issue.add_watcher(target)
          serialize_watcher(issue, target)
        end

        def remove_issue_watcher(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          principal_id, id_err = watcher_principal_id_from_args(args)
          return id_err if id_err

          target = resolve_removable_watcher(issue, principal_id)
          return watcher_remove_error(user, issue, principal_id) unless target

          issue.remove_watcher(target)
          serialize_watcher(issue, target)
        end

        def add_issue_note(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          IdempotencyStore.fetch(user: context[:user], tool_name: 'add_issue_note', key: args[:idempotency_key], args: args) do
            add_issue_note_once(args, context)
          end
        end

        def add_issue_note_once(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless issue.notes_addable?(user)

          private_note = args.key?(:private_notes) && Helpers.truthy?(args[:private_notes])
          return Helpers.error_result(:error_mcp_permission_denied) if private_note && !user.allowed_to?(:set_notes_private, issue.project)

          Helpers.with_issue_upload_entries(args[:uploads]) do |upload_entries, upload_err|
            return upload_err if upload_err
            return Helpers.error_result(:error_mcp_permission_denied) if upload_entries.any? && !issue.attachments_addable?(user)

            journal = issue.init_journal(user, args[:notes])
            issue.private_notes = private_note if args.key?(:private_notes)
            save_attachments_result = nil
            save_attachments_result = issue.save_attachments(upload_entries, user) if upload_entries.any?
            return issue_validation_error(issue) if issue.errors.any?
            return issue_validation_error(issue) unless issue.save

            result = {
              issue_id: Helpers.integer_id(issue.id),
              journal_id: Helpers.integer_id(journal.id),
              notes: journal.notes.to_s,
              private_notes: journal.private_notes?
            }
            if upload_entries.any?
              result[:added_attachments] = serialize_added_attachments(save_attachments_result)
              merge_unsaved_attachments!(result, issue, save_attachments_result)
            end
            result
          end
        end

        def update_issue_note(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          journal, err = find_editable_journal(user, args[:journal_id])
          return err if err

          attributes = {notes: args[:notes], updated_by: user}
          attributes[:private_notes] = Helpers.truthy?(args[:private_notes]) if args.key?(:private_notes)
          apply_journal_attributes(journal, attributes, user)
          return Helpers.error_result(:error_mcp_permission_denied) if args.key?(:private_notes) && journal.private_notes? != Helpers.truthy?(args[:private_notes])
          return Helpers.model_errors(journal) unless journal.save

          {journal_id: journal.id, notes: journal.notes, private_notes: journal.private_notes?}
        end

        def set_issue_note_private(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          journal, err = find_editable_journal(user, args[:journal_id])
          return err if err

          requested = Helpers.truthy?(args[:is_private])
          apply_journal_attributes(journal, {private_notes: requested, updated_by: user}, user)
          return Helpers.error_result(:error_mcp_permission_denied) unless journal.private_notes? == requested
          return Helpers.model_errors(journal) unless journal.save

          {journal_id: journal.id, private_notes: journal.private_notes?}
        end

        def get_private_notes(args, context)
          user = context[:user]
          issue, err = find_visible_issue(user, args[:issue_id])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(private_notes_scope(issue, user), limit: limit, offset: offset) do |journal|
            serialize_journal(journal, user)
          end
        end

        def list_issue_categories(args, context)
          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(project.issue_categories.order(:name, :id), limit: limit, offset: offset) do |category|
            serialize_category(category)
          end
        end

        def create_issue_category(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          project = Helpers.find_project(user, args[:project])
          return Helpers.error_result(:error_mcp_project_not_found) unless project

          category = project.issue_categories.build(name: args[:name])
          category.assigned_to_id = args[:assigned_to_id] if args.key?(:assigned_to_id)
          return Helpers.model_errors(category) unless category.save

          serialize_category(category)
        end

        def update_issue_category(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          category = find_manageable_category(user, args[:category_id])
          return Helpers.error_result(:error_mcp_category_not_found) unless category
          return Helpers.error_result(:error_mcp_invalid_parameters) unless args.key?(:name) || args.key?(:assigned_to_id)

          category.name = args[:name] if args.key?(:name)
          category.assigned_to_id = args[:assigned_to_id] if args.key?(:assigned_to_id)
          return Helpers.model_errors(category) unless category.save

          serialize_category(category)
        end

        def delete_issue_category(args, context)
          blocked = ReadOnly.guard_write!
          return blocked if blocked

          user = context[:user]
          category = find_manageable_category(user, args[:category_id])
          return Helpers.error_result(:error_mcp_category_not_found) unless category

          deleted_id = category.id
          reassign_to_id = args[:reassign_to_id]
          if reassign_to_id.present?
            reassign = IssueCategory.find_by(id: reassign_to_id, project_id: category.project_id)
            return Helpers.error_result(:error_mcp_category_not_found) unless reassign

            category.destroy(reassign)
          else
            category.destroy
          end
          {deleted_category_id: deleted_id, reassigned_to_id: reassign_to_id}
        end

        def visible_issue(user, issue_id)
          Issue.visible(user).find_by(id: issue_id)
        end

        def find_visible_issue(user, issue_id)
          issue = visible_issue(user, issue_id)
          return [issue, nil] if issue

          [nil, Helpers.error_result(:error_mcp_issue_not_found)]
        end

        def assign_optional_nested_list(result, enabled:, items_key:, pagination_key:, collection:, page:, &)
          if enabled
            result[items_key], result[pagination_key] = Helpers.paginated_nested(
              collection,
              limit: page[:limit],
              offset: page[:offset],
              &
            )
          else
            result[items_key] = []
            result[pagination_key] = nil
          end
        end

        def find_editable_journal(user, journal_id)
          journal = visible_issue_journal(user, journal_id)
          return [nil, Helpers.error_result(:error_mcp_journal_not_found)] unless journal
          return [nil, Helpers.error_result(:error_mcp_permission_denied)] unless journal.editable_by?(user)

          [journal, nil]
        end

        def visible_issue_journal(user, journal_id)
          journal = Journal.visible(user).find_by(id: journal_id)
          return unless journal&.journalized.is_a?(Issue)

          journal
        end

        def apply_journal_attributes(journal, attributes, user)
          journal.public_send(:safe_attributes=, attributes.stringify_keys, user)
        end

        def build_issue_scope(user, args)
          scope = Issue.visible(user)
          if args[:project].present?
            project = Helpers.find_project(user, args[:project])
            scope = project ? scope.where(project_id: project.id) : scope.none
          end
          scope = scope.where(status_id: args[:status_id]) if args[:status_id].present?
          scope = scope.where(tracker_id: args[:tracker_id]) if args[:tracker_id].present?
          scope = scope.where(priority_id: args[:priority_id]) if args[:priority_id].present?
          scope = scope.where(fixed_version_id: args[:fixed_version_id]) if args[:fixed_version_id].present?
          if args[:assignee_ref].present?
            scope = scope.where(assigned_to_id: Helpers.resolve_user_ref(user, args[:assignee_ref]))
          elsif args[:assigned_to_id].present?
            scope = scope.where(assigned_to_id: args[:assigned_to_id])
          end

          if args[:filters].present?
            filtered, err = apply_issue_filters(scope, user, args)
            return [nil, err] if err

            scope = filtered
          end

          [scope, nil]
        end

        def apply_issue_filters(scope, user, args)
          project = args[:project].present? ? Helpers.find_project(user, args[:project]) : nil
          query = IssueQuery.new(name: '_', project: project)
          query.filters = {}
          query.user = user

          Array(args[:filters]).each do |raw|
            filter = raw.is_a?(Hash) ? raw.deep_symbolize_keys : {}
            field = filter[:field].to_s
            operator = filter[:operator].to_s
            values = Array(filter[:values]).map(&:to_s)

            return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] unless allowed_filter_field?(field)
            return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] unless query.available_filters.key?(field)

            filter_type = query.available_filters[field][:type]
            allowed_ops = Query.operators_by_filter_type[filter_type] || []
            return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] unless allowed_ops.include?(operator)

            query.add_filter(field, operator, values)
            return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] unless query.has_filter?(field)
          end

          statement = query.statement
          return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] if statement.blank? && args[:filters].present?

          [scope.where(statement), nil]
        rescue Query::StatementInvalid, ActiveRecord::StatementInvalid
          [nil, Helpers.error_result(:error_mcp_invalid_parameters)]
        end

        def allowed_filter_field?(field)
          return true if LIST_ISSUE_FILTER_FIELDS.include?(field)
          return true if field.match?(/\Acf_\d+\z/)

          false
        end

        def validation_result(issue, rejected_fields: [])
          if issue.errors.empty?
            {valid: true, errors: []}
          else
            result = {valid: false, errors: issue.errors.full_messages}
            details = issue_validation_error(issue, rejected_fields: rejected_fields)
            result[:missing_required_fields] = details.dig(:details, :missing_required_fields) if details.dig(:details, :missing_required_fields)
            result[:hint] = details[:hint] if details[:hint]
            result[:rejected_fields] = rejected_fields if rejected_fields.any?
            result
          end
        end

        def apply_sort(scope, sort)
          return scope.order(updated_on: :desc, id: :desc) if sort.blank?

          field, direction = sort.to_s.split(':', 2)
          direction = direction.to_s.downcase == 'asc' ? :asc : :desc
          allowed = %w[id subject created_on updated_on status_id priority_id tracker_id assigned_to_id]
          return scope.order(updated_on: :desc, id: :desc) unless allowed.include?(field)
          return scope.order(id: direction) if field == 'id'

          scope.order(field => direction, :id => direction)
        end

        def issue_write_fields_from_args(args, user: nil, include_subject: false)
          keys = ISSUE_MUTABLE_KEYS
          keys -= [:subject] unless include_subject
          fields = {}
          keys.each do |key|
            fields[key] = args[key] if args.key?(key)
          end
          fields[:assigned_to_id] = Helpers.resolve_user_ref(user, args[:assignee_ref]) if args.key?(:assignee_ref) && user
          fields.delete(:assignee_ref)
          fields
        end

        def apply_create_issue_start_date_default(issue, fields, user)
          return unless Setting.default_issue_start_date_to_creation_date?
          return if fields.key?(:start_date)

          issue.start_date ||= user.today
        end

        def apply_issue_fields(issue, fields, user: User.current)
          return [] if fields.blank?

          attrs = fields.deep_dup
          if attrs.key?(:status_name)
            status_id = Helpers.resolve_status_id(attrs.delete(:status_name))
            return ['status_name'] unless status_id

            attrs[:status_id] = status_id
          end

          if attrs.key?(:custom_fields)
            attrs[:custom_fields] = Array(attrs[:custom_fields]).map do |item|
              item = item.deep_symbolize_keys
              {'id' => item[:id], 'value' => item[:value]}
            end
          end

          clear_assigned_to = attrs.key?(:assigned_to_id) && attrs[:assigned_to_id].nil?
          issue.public_send(:safe_attributes=, attrs.stringify_keys, user)
          issue.assigned_to_id = nil if clear_assigned_to && issue.safe_attribute_names(user).include?('assigned_to_id')
          rejected_issue_fields(issue, attrs, user)
        end

        def rejected_issue_fields(issue, attrs, user)
          rejected = []
          safe_names = issue.safe_attribute_names(user).map(&:to_s)

          attrs.each_key do |key|
            next if key == :custom_fields

            name = key.to_s
            rejected << name unless safe_names.include?(name)
          end

          ISSUE_VALUE_COMPARE_ATTRIBUTES.each do |requested_key, issue_attribute|
            next unless attrs.key?(requested_key)
            next if requested_attribute_applied?(issue, issue_attribute, attrs[requested_key])

            rejected << requested_key.to_s
          end
          rejected << 'custom_fields' if rejected_custom_fields?(issue, attrs)
          rejected.uniq
        end

        def requested_attribute_applied?(issue, attribute, requested)
          return issue.is_private? == Helpers.truthy?(requested) if attribute == :is_private

          actual = issue.public_send(attribute)
          return actual.blank? if requested.nil? || requested == ''

          actual.to_i == requested.to_i
        end

        def rejected_custom_fields?(issue, attrs)
          requested = Array(attrs[:custom_fields])
          return false if requested.empty?

          requested.any? do |item|
            item = item.stringify_keys
            actual = issue.custom_field_value(item['id'])
            !custom_field_values_equal?(actual, item['value'])
          end
        end

        def custom_field_values_equal?(actual, requested)
          normalize_custom_field_value(actual) == normalize_custom_field_value(requested)
        end

        def normalize_custom_field_value(value)
          values = value.is_a?(Array) ? value : [value]
          values.map { |item| normalize_custom_field_item(item) }.sort
        end

        def normalize_custom_field_item(item)
          return '' if item.nil?
          return '1' if item == true
          return '0' if item == false

          item.to_s
        end

        def append_rejected_field_errors(issue, rejected_fields)
          rejected_fields.each do |field|
            message =
              if field == 'status_name'
                I18n.t(:error_mcp_status_not_found)
              else
                I18n.t(:error_mcp_issue_field_rejected, field: field)
              end
            issue.errors.add(:base, message)
          end
        end

        def issue_write_validation_error(issue, rejected_fields)
          preexisting_messages = issue.errors.full_messages
          valid = issue.valid?
          preexisting_messages.each do |message|
            next if issue.errors.full_messages.include?(message)

            issue.errors.add(:base, message)
          end
          append_rejected_field_errors(issue, rejected_fields)
          return if valid && rejected_fields.empty? && preexisting_messages.empty?

          issue_validation_error(issue, rejected_fields: rejected_fields)
        end

        def issue_validation_error(issue, rejected_fields: [])
          missing = missing_required_field_names(issue)
          details = {}
          if missing.any?
            details[:missing_required_fields] = missing
            details[:hint] = I18n.t(:hint_mcp_missing_required_fields)
          end
          result = Helpers.model_errors(issue)
          result[:details] = details if details.present?
          result[:hint] = details[:hint] if details[:hint].present?
          if rejected_fields.any?
            result[:rejected_fields] = rejected_fields
            result[:hint] = I18n.t(:hint_mcp_issue_field_rejected)
          end
          result
        end

        def missing_required_field_names(record)
          record.errors.details.each_with_object([]) do |(attribute, entries), names|
            next unless entries.any? { |entry| REQUIRED_ERROR_TYPES.include?(entry[:error]) }

            names << attribute.to_s
          end
        end

        def issue_delete_impact(issue, user)
          {
            issue_id: issue.id,
            subject: issue.subject,
            children_count: issue.children.visible(user).count,
            journals_count: issue.visible_journals_with_index(user).size,
            attachments_count: issue.attachments.count { |attachment| attachment.visible?(user) },
            relations_count: issue.relations.count { |relation| relation.visible?(user) },
            time_entries_count: TimeEntry.visible(user).where(issue_id: issue.id).count
          }
        end

        def serialize_issue_detail(issue)
          {
            id: Helpers.integer_id(issue.id),
            url: Helpers.issue_url(issue),
            subject: issue.subject,
            description: issue.description.to_s,
            project: Helpers.serialize_project(issue.project),
            tracker: Helpers.serialize_named_ref(issue.tracker),
            status: Helpers.serialize_named_ref(issue.status),
            priority: Helpers.serialize_named_ref(issue.priority),
            author: Helpers.serialize_user_ref(issue.author),
            assigned_to: Helpers.serialize_user_ref(issue.assigned_to),
            category: Helpers.serialize_named_ref(issue.category),
            fixed_version: Helpers.serialize_named_ref(issue.fixed_version),
            parent_id: Helpers.integer_id(issue.parent_id),
            start_date: issue.start_date,
            due_date: issue.due_date,
            done_ratio: issue.done_ratio,
            estimated_hours: issue.estimated_hours,
            is_private: issue.is_private?,
            created_on: issue.created_on,
            updated_on: issue.updated_on
          }
        end

        def serialize_issue_list_item(issue, fields)
          detail = serialize_issue_detail(issue)
          keys = issue_list_field_keys(fields)
          keys.each_with_object({}) do |key, result|
            sym = key.to_sym
            result[sym] = detail[sym] if detail.key?(sym)
          end
        end

        def issue_list_field_keys(fields)
          return ISSUE_SUMMARY_FIELD_KEYS if fields.blank?

          list = Array(fields).map(&:to_s)
          return ISSUE_LIST_FIELDS if list.include?('*') || list.include?('all')

          list & ISSUE_LIST_FIELDS
        end

        def serialize_journal(journal, user)
          {
            id: Helpers.integer_id(journal.id),
            user: Helpers.serialize_user_ref(journal.user),
            notes: journal.notes.to_s,
            created_on: journal.created_on,
            private_notes: journal.private_notes?,
            details: journal.visible_details(user).map do |detail|
              {property: detail.property, name: detail.prop_key, old_value: detail.old_value, new_value: detail.value}
            end
          }
        end

        def visible_journals_scope(issue, user)
          scope = issue.journals
          scope = apply_private_notes_visibility(scope, issue, user)
          scope = scope.where(visible_journal_content_sql(issue, user))
          scope.preload(:details, user: :email_address).reorder(:created_on, :id)
        end

        def private_notes_scope(issue, user)
          scope = issue.journals.where(private_notes: true).where(journal_notes_present_sql)
          scope = apply_private_notes_visibility(scope, issue, user)
          scope.preload(:details, user: :email_address).reorder(:created_on, :id)
        end

        def apply_private_notes_visibility(scope, issue, user)
          return scope if user.allowed_to?(:view_private_notes, issue.project)

          scope.where(
            "#{Journal.table_name}.private_notes = ? OR #{Journal.table_name}.user_id = ?",
            false,
            user.id
          )
        end

        def journal_notes_present_sql
          notes = "#{Journal.table_name}.notes"
          "#{notes} IS NOT NULL AND #{sql_trim_blank(notes)} != ''"
        end

        def sql_trim_blank(expression)
          if Journal.connection.adapter_name.match?(/postgres/i)
            "BTRIM(#{expression}, CHR(32) || CHR(9) || CHR(10) || CHR(13) || CHR(12) || CHR(11))"
          elsif Journal.connection.adapter_name.match?(/sqlite/i)
            "TRIM(#{expression}, CHAR(32, 9, 10, 13, 12, 11))"
          else
            [32, 9, 10, 13, 12, 11].reduce(expression) do |sql, code|
              "REPLACE(#{sql}, CHAR(#{code}), '')"
            end
          end
        end

        def visible_journal_content_sql(issue, user)
          details = JournalDetail.table_name
          journals = Journal.table_name
          <<~SQL.squish
            (#{journal_notes_present_sql})
            OR EXISTS (
              SELECT 1 FROM #{details}
              WHERE #{details}.journal_id = #{journals}.id
                AND (#{visible_journal_detail_sql(issue, user)})
            )
          SQL
        end

        def visible_journal_detail_sql(issue, user)
          details = JournalDetail.table_name
          [
            "#{details}.property NOT IN ('cf', 'relation')",
            visible_custom_field_detail_sql(issue, user),
            visible_relation_detail_sql(user),
          ].join(' OR ')
        end

        def visible_custom_field_detail_sql(issue, user)
          details = JournalDetail.table_name
          fields = CustomField.table_name
          <<~SQL.squish
            (#{details}.property = 'cf'
             AND EXISTS (
               SELECT 1 FROM #{fields}
               WHERE #{sql_id_equals_text("#{fields}.id", "#{details}.prop_key")}
                 AND (#{custom_field_visible_sql(issue, user, fields)})
             ))
          SQL
        end

        def custom_field_visible_sql(issue, user, fields)
          return '1=1' if user.admin?

          quoted_true = Journal.connection.quoted_true
          role_ids = user.roles_for_project(issue.project).map(&:id)
          role_match = if role_ids.empty?
                         '1=0'
                       else
                         quoted_ids = role_ids.map { |id| Journal.connection.quote(id) }.join(', ')
                         roles_table = "#{CustomField.table_name_prefix}custom_fields_roles#{CustomField.table_name_suffix}"
                         <<~SQL.squish
                           EXISTS (
                             SELECT 1 FROM #{roles_table} cfr
                             WHERE cfr.custom_field_id = #{fields}.id
                               AND cfr.role_id IN (#{quoted_ids})
                           )
                         SQL
                       end
          "#{fields}.visible = #{quoted_true} OR (#{role_match})"
        end

        def visible_relation_detail_sql(user)
          details = JournalDetail.table_name
          issues = Issue.table_name
          projects = Project.table_name
          <<~SQL.squish
            (#{details}.property = 'relation'
             AND EXISTS (
               SELECT 1
               FROM #{issues}
               INNER JOIN #{projects} ON #{projects}.id = #{issues}.project_id
               WHERE #{Issue.visible_condition(user)}
                 AND #{sql_id_equals_text("#{issues}.id", "COALESCE(#{details}.value, #{details}.old_value)")}
             ))
          SQL
        end

        def sql_id_as_text(expression)
          if Journal.connection.adapter_name.match?(/mysql|trilogy/i)
            "CAST(#{expression} AS CHAR)"
          else
            "CAST(#{expression} AS text)"
          end
        end

        def sql_id_equals_text(id_expression, text_expression)
          id_as_text = sql_id_as_text(id_expression)
          if Journal.connection.adapter_name.match?(/mysql|trilogy/i)
            "BINARY #{id_as_text} = BINARY #{text_expression}"
          else
            "#{id_as_text} = #{text_expression}"
          end
        end

        def visible_watchers_scope(issue, user)
          scope = issue.watcher_users
          scope = scope.where(id: user.id) unless user.allowed_to?(:view_issue_watchers, issue.project)
          scope.reorder(:id)
        end

        def visible_relations_scope(issue, user)
          visible_issue_ids = Issue.visible(user).select(:id)
          IssueRelation
            .where('issue_from_id = :id OR issue_to_id = :id', id: issue.id)
            .where(issue_from_id: visible_issue_ids)
            .where(issue_to_id: visible_issue_ids)
            .reorder(:id)
        end

        def serialize_relation(relation)
          {
            id: Helpers.integer_id(relation.id),
            issue_id: Helpers.integer_id(relation.issue_from_id),
            issue_to_id: Helpers.integer_id(relation.issue_to_id),
            relation_type: relation.relation_type,
            delay: relation.delay
          }
        end

        def serialize_category(category)
          {
            id: Helpers.integer_id(category.id),
            name: category.name,
            project: Helpers.serialize_named_ref(category.project),
            assigned_to: Helpers.serialize_user_ref(category.assigned_to)
          }
        end

        def find_manageable_category(user, category_id)
          category = IssueCategory.find_by(id: category_id)
          return nil unless category
          return nil unless Project.visible(user).exists?(id: category.project_id)
          return nil unless user.allowed_to?(:manage_categories, category.project)

          category
        end

        def watcher_principal_id_from_args(args)
          principal_id = args[:principal_id]
          user_id = args[:user_id]
          return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] if principal_id.present? && user_id.present? && principal_id.to_i != user_id.to_i

          id = principal_id.presence || user_id
          return [nil, Helpers.error_result(:error_mcp_invalid_parameters)] if id.blank?

          [id, nil]
        end

        def serialize_watcher(issue, principal)
          {issue_id: issue.id, principal_id: principal.id, user_id: principal.id}
        end

        def resolve_addable_watcher(issue, user_id)
          return nil if user_id.blank?

          user_id = user_id.to_i

          return issue.addable_watcher_users.find { |candidate| candidate.id == user_id } if issue.respond_to?(:addable_watcher_users)

          principal = issue.project.principals.assignable_watchers.find_by(id: user_id)
          return nil unless principal
          return nil if issue.watcher_users.any? { |watcher| watcher.id == principal.id }
          return nil unless issue.valid_watcher?(principal)

          principal
        end

        def watcher_add_error(user, issue, principal_id)
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:add_issue_watchers, issue.project)
          return Helpers.error_result(:error_mcp_invalid_parameters) if issue.watchers.exists?(user_id: principal_id.to_i)
          return Helpers.error_result(:error_mcp_permission_denied) if principal_id.to_i == user.id

          Helpers.error_result(:error_mcp_invalid_parameters)
        end

        def watcher_remove_error(user, issue, _principal_id)
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:delete_issue_watchers, issue.project)

          Helpers.error_result(:error_mcp_invalid_parameters)
        end

        def resolve_removable_watcher(issue, principal_id)
          return nil if principal_id.blank?

          issue.watchers.find_by(user_id: principal_id.to_i)&.user
        end

        def copy_flag_from_setting?(setting_value, explicit)
          case setting_value.to_s
          when 'yes'
            true
          when 'no'
            false
          else
            explicit.nil? || Helpers.truthy?(explicit)
          end
        end

        def copy_issue_allowed?(user, args)
          return Helpers.any_project_allows?(user, :copy_issues) && Helpers.any_project_allows?(user, :add_issues) if args[:issue_id].blank?

          source = visible_issue(user, args[:issue_id])
          return false unless source
          return false unless user.allowed_to?(:copy_issues, source.project)

          target =
            if args[:project].present?
              Helpers.find_project(user, args[:project])
            else
              source.project
            end
          target && user.allowed_to?(:add_issues, target)
        end

        def create_issue_relation_allowed?(user, args)
          return Helpers.any_project_allows?(user, :manage_issue_relations) if args[:issue_id].blank?

          issue = visible_issue(user, args[:issue_id])
          return false unless issue
          return false unless user.allowed_to?(:manage_issue_relations, issue.project)

          return true if args[:issue_to_id].blank?

          target_issue = visible_issue(user, args[:issue_to_id])
          target_issue && user.allowed_to?(:manage_issue_relations, target_issue.project)
        end

        def delete_issue_relation_allowed?(user, args)
          return Helpers.any_project_allows?(user, :manage_issue_relations) if args[:relation_id].blank?

          relation = IssueRelation.find_by(id: args[:relation_id])
          relation&.deletable?(user)
        end

        def add_issue_watcher_allowed?(user, args)
          return Helpers.any_project_allows?(user, :add_issue_watchers) if args[:issue_id].blank?

          issue = visible_issue(user, args[:issue_id])
          issue && user.allowed_to?(:add_issue_watchers, issue.project)
        end

        def add_issue_note_allowed?(user, args)
          return Helpers.any_project_allows?(user, :add_issue_notes) if args[:issue_id].blank?

          issue = visible_issue(user, args[:issue_id])
          return false unless issue&.notes_addable?(user)
          return true unless args.key?(:private_notes) && Helpers.truthy?(args[:private_notes])

          user.allowed_to?(:set_notes_private, issue.project)
        end

        def update_issue_allowed?(user, args)
          if args[:issue_id].blank?
            return Helpers.any_project_allows?(user, :edit_issues) ||
                   Helpers.any_project_allows?(user, :edit_own_issues) ||
                   Helpers.any_project_allows?(user, :add_issue_notes)
          end

          issue = visible_issue(user, args[:issue_id])
          return false unless issue

          fields = issue_write_fields_from_args(args, user: user, include_subject: true)
          return issue.attachments_addable?(user) if fields.empty? && Array(args[:uploads]).any?

          issue.attributes_editable?(user)
        end

        def remove_issue_watcher_allowed?(user, args)
          return Helpers.any_project_allows?(user, :delete_issue_watchers) if args[:issue_id].blank?

          issue = visible_issue(user, args[:issue_id])
          issue && user.allowed_to?(:delete_issue_watchers, issue.project)
        end

        def issue_note_editable?(user, journal_id, privacy_change: false)
          if journal_id.blank?
            editable = Helpers.any_project_allows?(user, :edit_issue_notes) ||
                       Helpers.any_project_allows?(user, :edit_own_issue_notes)
            return false unless editable
            return true unless privacy_change

            return Helpers.any_project_allows?(user, :set_notes_private)
          end

          journal = visible_issue_journal(user, journal_id)
          return false unless journal&.editable_by?(user)
          return true unless privacy_change

          user.allowed_to?(:set_notes_private, journal.project)
        end

        def create_issue_category_allowed?(user, args, project)
          project ||= Helpers.find_project(user, args[:project])
          return Helpers.any_project_allows?(user, :manage_categories) if project.nil? && args[:project].blank?

          project && user.allowed_to?(:manage_categories, project)
        end

        def update_issue_category_allowed?(user, args)
          return Helpers.any_project_allows?(user, :manage_categories) if args[:category_id].blank?

          category = find_manageable_category(user, args[:category_id])
          category.present?
        end

        def delete_issue_category_allowed?(user, args)
          update_issue_category_allowed?(user, args)
        end
      end
    end
  end
end
