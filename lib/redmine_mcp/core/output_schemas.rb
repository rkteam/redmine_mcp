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
    module OutputSchemas
      N = SchemaNormalizer

      NAMED_REF_PROPS = {id: N::ID, name: N::STRING}.freeze
      USER_REF_PROPS = NAMED_REF_PROPS
      PROJECT_REF_PROPS = {id: N::ID, identifier: N::STRING, name: N::STRING}.freeze
      ATTACHMENT_PROPS = {
        id: N::ID,
        filename: N::STRING,
        filesize: N::ID,
        content_type: N::NULLABLE_STRING,
        description: N::STRING,
        content_url: N::NULLABLE_STRING,
        author: N::USER_REF,
        created_on: N::DATETIME
      }.freeze
      NESTED_PAGINATION = {
        type: %w[object null],
        additionalProperties: true,
        properties: {
          total_count: N::ID,
          offset: N::ID,
          limit: N::ID,
          has_more: N::BOOLEAN,
          next_offset: N::NULLABLE_INTEGER
        }
      }.freeze
      ISSUE_PROPS = {
        id: N::ID,
        url: N::NULLABLE_STRING,
        subject: N::STRING,
        description: N::STRING,
        project: N::PROJECT_REF,
        tracker: N::NAMED_REF,
        status: N::NAMED_REF,
        priority: N::NAMED_REF,
        author: N::USER_REF,
        assigned_to: N::USER_REF,
        category: N::NAMED_REF,
        fixed_version: N::NAMED_REF,
        parent_id: N::NULLABLE_INTEGER,
        start_date: N::DATETIME,
        due_date: N::DATETIME,
        done_ratio: N::ID,
        estimated_hours: N::NULLABLE_NUMBER,
        is_private: N::BOOLEAN,
        created_on: N::DATETIME,
        updated_on: N::DATETIME
      }.freeze
      TIME_ENTRY_PROPS = {
        id: N::ID,
        hours: N::NUMBER,
        comments: N::STRING,
        spent_on: N::DATETIME,
        user: N::USER_REF,
        project: N::NAMED_REF,
        issue: {type: %w[object null], additionalProperties: true, properties: {id: N::ID}},
        activity: N::NAMED_REF,
        created_on: N::DATETIME,
        updated_on: N::DATETIME
      }.freeze
      VERSION_PROPS = {
        id: N::ID,
        name: N::STRING,
        description: N::STRING,
        status: N::STRING,
        due_date: N::NULLABLE_STRING,
        sharing: N::STRING,
        wiki_page_title: N::STRING,
        project: N::NAMED_REF,
        created_on: N::DATETIME,
        updated_on: N::DATETIME
      }.freeze
      WIKI_PAGE_PROPS = {
        title: N::STRING,
        text: N::STRING,
        version: N::ID,
        created_on: N::DATETIME,
        updated_on: N::DATETIME,
        author: N::USER_REF,
        project: N::NAMED_REF,
        comments: N::STRING
      }.freeze
      CATEGORY_PROPS = {
        id: N::ID,
        name: N::STRING,
        project: N::NAMED_REF,
        assigned_to: N::USER_REF
      }.freeze
      RELATION_PROPS = {
        id: N::ID,
        issue_id: N::ID,
        issue_to_id: N::ID,
        relation_type: N::STRING,
        delay: N::NULLABLE_INTEGER
      }.freeze
      JOURNAL_PROPS = {
        id: N::ID,
        user: N::USER_REF,
        notes: N::STRING,
        created_on: N::DATETIME,
        private_notes: N::BOOLEAN,
        details: {type: 'array', items: N::REST_OBJECT_SCHEMA}
      }.freeze
      USER_MEMBER_PROPS = {
        id: N::ID,
        login: N::STRING,
        firstname: N::STRING,
        lastname: N::STRING,
        mail: N::NULLABLE_STRING
      }.freeze
      USER_LIST_PROPS = USER_MEMBER_PROPS.merge(created_on: N::DATETIME).freeze

      LIST_NAMED = N.list_output(NAMED_REF_PROPS).freeze
      LIST_USERS = N.list_output(USER_MEMBER_PROPS).freeze
      LIST_ALL_USERS = N.list_output(USER_LIST_PROPS).freeze
      LIST_GROUPS = LIST_NAMED
      LIST_PROJECTS = N.list_output(
        id: N::ID,
        name: N::STRING,
        identifier: N::STRING,
        description: N::STRING
      ).freeze
      PROJECT = N.object_output(
        id: N::ID,
        name: N::STRING,
        identifier: N::STRING,
        description: N::STRING,
        homepage: N::STRING,
        status: N::ID,
        is_public: N::BOOLEAN,
        inherit_members: N::BOOLEAN,
        created_on: N::DATETIME,
        updated_on: N::DATETIME,
        parent: N::PROJECT_REF,
        subprojects: {type: 'array', items: N::PROJECT_REF},
        custom_fields: {type: 'array', items: N.open_object(id: N::ID, name: N::STRING, value: N::JSON_VALUE)},
        last_activity_date: N::DATETIME
      ).freeze
      LIST_CUSTOM_FIELDS = N.list_output(
        id: N::ID,
        name: N::STRING,
        field_format: N::STRING,
        is_required: N::BOOLEAN,
        multiple: N::BOOLEAN,
        default_value: N::JSON_VALUE,
        possible_values: {type: 'array', items: N::JSON_VALUE},
        trackers: {type: 'array', items: N::NAMED_REF}
      ).freeze
      PROJECT_STATUS = N.object_output(
        project_id: N::ID,
        project_name: N::STRING,
        analysis_period_days: N::ID,
        recent_activity: N.open_object(created_count: N::ID, updated_count: N::ID),
        status_breakdown: {type: 'object', additionalProperties: {type: 'integer'}},
        priority_breakdown: {type: 'object', additionalProperties: {type: 'integer'}},
        assignee_breakdown: {type: 'object', additionalProperties: {type: 'integer'}},
        totals: N.open_object(issues_count: N::ID, open_count: N::ID, closed_count: N::ID),
        overdue_count: N::ID,
        unassigned_count: N::ID,
        stale_issues_count: N::ID,
        issues_closed_during_period: N::ID,
        estimated_hours: N::NULLABLE_NUMBER,
        spent_hours: N::NULLABLE_NUMBER,
        average_resolution_hours: N::NULLABLE_NUMBER,
        estimation_accuracy: {
          type: %w[object null],
          additionalProperties: true,
          properties: {
            issues_count: N::ID,
            total_estimated: N::NUMBER,
            total_spent: N::NUMBER
          }
        },
        reopened_count: N::ID
      ).freeze
      LIST_ACTIVITY_EVENTS = N.list_output(
        type: N::STRING,
        datetime: N::DATETIME,
        author: N::USER_REF,
        title: N::STRING,
        description: N::STRING,
        url: N::NULLABLE_STRING
      ).freeze
      LIST_VERSIONS = N.list_output(VERSION_PROPS).freeze
      VERSION = N.object_output(VERSION_PROPS).freeze
      VERSION_DETAIL = N.object_output(
        VERSION_PROPS.merge(
          issues_count: N::ID,
          open_issues_count: N::ID,
          closed_issues_count: N::ID,
          estimated_hours: N::NUMBER,
          spent_hours: N::NULLABLE_NUMBER,
          completed_percent: N::NUMBER
        )
      ).freeze
      LIST_MEMBERS = N.list_output(
        id: N::ID,
        user: N::USER_REF,
        group: N::NAMED_REF,
        project: N::NAMED_REF,
        roles: {type: 'array', items: N::NAMED_REF}
      ).freeze
      LIST_MEMBER_CANDIDATES = N.list_output(
        id: N::ID,
        name: N::STRING,
        type: N::STRING,
        login: N::STRING
      ).freeze
      LIST_ROLES = LIST_NAMED
      PROJECT_MODULES = N.object_output(
        project_id: N::ID,
        project_name: N::STRING,
        enabled_modules: N::STRING_ARRAY
      ).freeze
      MEMBERSHIP = N.object_output(
        id: N::ID,
        user: N::USER_REF,
        group: N::NAMED_REF,
        project: N::NAMED_REF,
        roles: {type: 'array', items: N::NAMED_REF}
      ).freeze
      DELETED_MEMBERSHIP = N.object_output(deleted_membership_id: N::ID).freeze
      ISSUE = N.object_output(
        ISSUE_PROPS.merge(
          custom_fields: {type: 'array', items: N.open_object(id: N::ID, name: N::STRING, value: N::JSON_VALUE)},
          journals: {type: 'array', items: N.open_object(JOURNAL_PROPS)},
          journal_pagination: NESTED_PAGINATION,
          attachments_pagination: NESTED_PAGINATION,
          watchers_pagination: NESTED_PAGINATION,
          relations_pagination: NESTED_PAGINATION,
          children_pagination: NESTED_PAGINATION,
          attachments: {type: 'array', items: N.open_object(ATTACHMENT_PROPS)},
          watchers: {type: 'array', items: N::USER_REF},
          relations: {type: 'array', items: N.open_object(RELATION_PROPS)},
          children: {type: 'array', items: N::REST_OBJECT_SCHEMA}
        )
      ).freeze
      LIST_ISSUES = N.list_output(ISSUE_PROPS).freeze
      ISSUE_UPDATED = N.object_output(
        ISSUE_PROPS.merge(
          added_attachments: {type: 'array', items: N.open_object(ATTACHMENT_PROPS)},
          journal_id: N::NULLABLE_INTEGER,
          attachments_not_saved_count: N::ID,
          attachments_not_saved: {type: 'array', items: N::STRING},
          warning: N::STRING
        )
      ).freeze
      ISSUE_NOTE = N.object_output(
        issue_id: N::ID,
        journal_id: N::ID,
        notes: N::STRING,
        private_notes: N::BOOLEAN,
        added_attachments: {type: 'array', items: N.open_object(ATTACHMENT_PROPS)},
        attachments_not_saved_count: N::ID,
        attachments_not_saved: {type: 'array', items: N::STRING},
        warning: N::STRING
      ).freeze
      DELETED_ISSUE = N.object_output(
        deleted_issue_id: N::ID,
        cascade_deleted: N::REST_OBJECT_SCHEMA
      ).freeze
      LIST_RELATIONS = N.list_output(RELATION_PROPS).freeze
      RELATION = N.object_output(RELATION_PROPS).freeze
      DELETED_RELATION = N.object_output(deleted_relation_id: N::ID).freeze
      WATCHER = N.object_output(issue_id: N::ID, principal_id: N::ID, user_id: N::ID).freeze
      JOURNAL = N.object_output(JOURNAL_PROPS).freeze
      NOTE_PRIVACY = N.object_output(journal_id: N::ID, private_notes: N::BOOLEAN).freeze
      LIST_JOURNALS = N.list_output(JOURNAL_PROPS).freeze
      LIST_CATEGORIES = N.list_output(CATEGORY_PROPS).freeze
      CATEGORY = N.object_output(CATEGORY_PROPS).freeze
      DELETED_CATEGORY = N.object_output(
        deleted_category_id: N::ID,
        reassigned_to_id: N::NULLABLE_INTEGER
      ).freeze
      VALIDATION = N.object_output(
        valid: N::BOOLEAN,
        errors: {type: 'array', items: N::STRING},
        missing_required_fields: N::STRING_ARRAY,
        rejected_fields: N::STRING_ARRAY,
        hint: N::STRING
      ).freeze
      FORM_OPTIONS = N.object_output(
        project: N::PROJECT_REF,
        trackers: {type: 'array', items: N::NAMED_REF},
        statuses: {type: 'array', items: N.open_object(id: N::ID, name: N::STRING, is_closed: N::BOOLEAN)},
        priorities: {type: 'array', items: N.open_object(id: N::ID, name: N::STRING, is_default: N::BOOLEAN)},
        categories: {type: 'array', items: N::NAMED_REF},
        versions: {type: 'array', items: N::NAMED_REF},
        assignees: {type: 'array', items: N::REST_OBJECT_SCHEMA},
        custom_fields: {type: 'array', items: N.open_object(
          id: N::ID,
          name: N::STRING,
          field_format: N::STRING,
          required: N::BOOLEAN,
          readonly: N::BOOLEAN,
          multiple: N::BOOLEAN,
          default_value: N::JSON_VALUE,
          possible_values: {type: 'array', items: N::JSON_VALUE},
          trackers: {type: 'array', items: N::NAMED_REF}
        )},
        editable_fields: N::STRING_ARRAY,
        required_fields: N::STRING_ARRAY
      ).freeze
      LIST_TIME_ENTRIES = N.list_output(TIME_ENTRY_PROPS).freeze
      TIME_ENTRY = N.object_output(TIME_ENTRY_PROPS).freeze
      LIST_ACTIVITIES = N.list_output(
        id: N::ID,
        name: N::STRING,
        active: N::BOOLEAN,
        is_default: N::BOOLEAN
      ).freeze
      IMPORT_TIME_ENTRIES = N.object_output(
        total: N::ID,
        succeeded: N::ID,
        failed: N::ID,
        created: {type: 'array', items: N.open_object(TIME_ENTRY_PROPS)},
        errors: {type: 'array', items: N::REST_OBJECT_SCHEMA}
      ).freeze
      LIST_TRACKERS = N.list_output(id: N::ID, name: N::STRING, description: N::STRING).freeze
      LIST_PROJECT_TRACKERS = LIST_NAMED
      LIST_STATUSES = N.list_output(id: N::ID, name: N::STRING, is_closed: N::BOOLEAN).freeze
      LIST_PRIORITIES = N.list_output(
        id: N::ID,
        name: N::STRING,
        active: N::BOOLEAN,
        is_default: N::BOOLEAN
      ).freeze
      CURRENT_USER = N.object_output(
        id: N::ID,
        login: N::STRING,
        firstname: N::STRING,
        lastname: N::STRING,
        mail: N::NULLABLE_STRING,
        admin: N::BOOLEAN,
        created_on: N::DATETIME,
        last_login_on: N::DATETIME
      ).freeze
      LIST_QUERIES = N.list_output(
        id: N::ID,
        name: N::STRING,
        is_public: N::BOOLEAN,
        project_id: N::NULLABLE_INTEGER
      ).freeze
      LIST_SEARCH = N.list_output(
        id: N::ID,
        type: N::STRING,
        url: N::NULLABLE_STRING,
        title: N::STRING,
        project: N::NULLABLE_STRING,
        status: N::NULLABLE_STRING,
        updated_on: N::DATETIME,
        excerpt: N::STRING
      ).freeze
      LIST_WIKI_PAGES = N.list_output(
        title: N::STRING,
        version: N::ID,
        parent_title: N::NULLABLE_STRING,
        created_on: N::DATETIME,
        updated_on: N::DATETIME
      ).freeze
      WIKI_PAGE = N.object_output(
        WIKI_PAGE_PROPS.merge(
          attachments: {type: 'array', items: N.open_object(ATTACHMENT_PROPS)},
          attachments_pagination: NESTED_PAGINATION
        )
      ).freeze
      LIST_BOARDS = N.list_output(
        id: N::ID,
        name: N::STRING,
        description: N::STRING,
        parent_id: N::NULLABLE_INTEGER,
        topics_count: N::ID,
        messages_count: N::ID
      ).freeze
      LIST_TOPICS = N.list_output(
        id: N::ID,
        subject: N::STRING,
        author: N::USER_REF,
        created_on: N::DATETIME,
        updated_on: N::DATETIME,
        replies_count: N::ID,
        board_id: N::ID
      ).freeze
      BOARD_MESSAGE = N.object_output(
        id: N::ID,
        subject: N::STRING,
        content: N::STRING,
        author: N::USER_REF,
        created_on: N::DATETIME,
        updated_on: N::DATETIME,
        board: N::NAMED_REF,
        project: N::PROJECT_REF,
        parent_id: N::NULLABLE_INTEGER,
        replies: {type: 'array', items: N::REST_OBJECT_SCHEMA},
        replies_pagination: NESTED_PAGINATION
      ).freeze
      LIST_FILES = N.list_output(
        ATTACHMENT_PROPS.merge(
          digest: N::STRING,
          downloads: N::ID,
          version: N::NAMED_REF
        )
      ).freeze
      PROJECT_FILE = N.object_output(
        ATTACHMENT_PROPS.merge(
          digest: N::STRING,
          downloads: N::ID,
          version: N::NAMED_REF
        )
      ).freeze
      DELETED_FILE = N.object_output(deleted_file_id: N::ID).freeze
      ATTACHMENT = N.object_output(
        attachment_id: N::ID,
        filename: N::STRING,
        content_type: N::NULLABLE_STRING,
        size: N::ID,
        content_url: N::NULLABLE_STRING
      ).freeze
      DELETED_VERSION = N.object_output(version_id: N::ID).freeze
      DELETED_WIKI = N.object_output(title: N::STRING).freeze
      RENAMED_WIKI = N.object_output(title: N::STRING, version: N::ID, updated_on: N::DATETIME).freeze
      SERVER_INFO = N.object_output(
        server_version: N::STRING,
        read_only_mode: N::BOOLEAN,
        auth_mode: N::STRING,
        current_user: N.open_object(id: N::ID, login: N::STRING, name: N::STRING),
        capabilities: {type: 'object', additionalProperties: true}
      ).freeze
    end
  end
end
