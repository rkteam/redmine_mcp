# Built-in tools (core tools)

[Deutsch](../de/03-core-tools.md) | [English](03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Overview

The Redmine MCP plugin provides a set of tools for working with Redmine projects, issues, time tracking, wiki, forums, files, and reference data (read and write).

## Goal

Give AI clients Project Management, Issue Operations, Time Tracking, Discovery, Search & Wiki, Boards, File Operations, and Meta operations without installing additional plugins.

## Affected areas

- Projects
- Versions
- Members / Roles
- Issues (CRUD, relations, watchers, notes, categories, form options, dry-run validation, saved queries)
- Time entries
- Trackers, statuses, priorities, queries
- Project activity
- Wiki pages
- Boards / messages
- Project files / attachments
- Users
- Permissions
- Settings (read-only mode)

## Business rules

### General rules

- Full tool name: `redmine_<name>` (for example `redmine_get_issue`).
- The result is returned as a JSON envelope in `structuredContent` and duplicated as text in `content`.
- Data is filtered through Redmine project/issue visibility and permissions.
- The `project` parameter is a string: numeric id as a string (for example `"1"`) or project identifier (for example `"ecookbook"`).
- When **Read-only mode** is enabled, write tools return an error. Read-only tools, including `list_issue_relations`, `get_issue_form_options`, `validate_issue_create`, and `validate_issue_update`, remain available.

### Project Management

| Tool | R/W | Permission |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### Issue Operations

| Tool | R/W | Permission |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | attributes — if they are editable; `uploads` only — if attachments can be added |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` additionally requires `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` on the source project and `add_issues` on the target |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | journal entry is visible and editable (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` additionally requires `set_notes_private` |
| `set_issue_note_private` | W | journal entry is visible and editable, plus `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Users

| Tool | R/W | Permission |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; without `project` — admin only |
| `list_groups` | R | `manage_members` (on any project) or admin |

### Time Tracking

| Tool | R/W | Permission |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | entry is editable by the current user (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### Discovery / Enumeration

| Tool | R/W | Permission |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Search & Wiki

| Tool | R/W | Permission |
|------|-----|------------|
| `search_all` | R | access to at least one of the searched types (`view_issues` and/or `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; historical `version` additionally requires `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` and the page must be editable |
| `update_wiki_page` | W | `edit_wiki_pages` and the page must be editable |
| `delete_wiki_page` | W | `delete_wiki_pages` and the page must be editable |
| `rename_wiki_page` | W | `rename_wiki_pages` and the page must be editable |

### Boards

| Tool | R/W | Permission |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### File Operations

| Tool | R/W | Permission |
|------|-----|------------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files` (or container permissions) |
| `get_attachment` | R | permissions on the attachment container |
| `download_attachment` | R | permissions on the attachment container |

### Meta

| Tool | R/W | Permission |
|------|-----|------------|
| `get_server_info` | R | `use_mcp` |

`get_server_info` returns `server_version`, `read_only_mode`, `auth_mode`, brief current user data, and `capabilities.issue_search`. Third-party plugin installation is not listed in the response: their MCP tools are visible through `tools/list` and through `capabilities` that extensions register themselves.

`capabilities.issue_search` contains search modes:

| Mode | Default | Note |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | Always |
| `cross_resource` | `available: true`, tool `redmine_search_all` | Always |
| `semantic` | `available: false` | Plugins can override via `register_capability(:issue_search, :semantic)` |

When `semantic.available: true`, the capability MUST include `tool`, `provider`, and `use_when` / `avoid_when` — brief hints on when to choose semantic search. `Registry#apply_capabilities` normalizes the provider response: if the contract is violated, `{ available: false }` is published.

### Clarifications

- `delete_issue` without `confirm_delete` returns an impact preview; if there are **any** subtasks (including those invisible to the user), `confirm_delete_with_children` is required. Counters in `impact` cover only journals, relations, time entries, children, and attachments visible to the current user.
- `search_issues` with `scope=subprojects` requires `project` and searches in that project and its descendants. Without `project`, that scope is a parameter error. `scope=my_project` limits the search to projects where the user is a member.
- `get_issue`: journals, attachments, watchers, relations, children, and custom fields are included only with explicit `include_*`. Nested lists have separate `limit`/`offset` and a `*_pagination` field (journals: default limit 25, maximum 100; other nested lists: default and maximum 100). Without the corresponding `include_*`, the list is empty and pagination is `null`. Optional fields (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) are always present in the response. Custom fields — only those visible to the current user. Journals — same visibility as issue history in Redmine: an entry appears in `journals` and `journal_pagination` only if it has text or at least one detail change visible to the user. Text consisting only of spaces, tabs, or line breaks is treated as empty. Empty entries and entries with only hidden details (including hidden custom fields) are excluded from both the list and `total_count` / `offset` / `has_more`. Private comments — own comments or with `view_private_notes` permission. Journal elements contain only visible detail changes. Relations — only links where both sides are visible to the user. The same relation visibility rule applies to `list_issue_relations`.
- `get_private_notes` returns only private comments with non-empty text (spaces, tabs, and line breaks without other content count as empty text). The page is limited by `limit`/`offset` without loading the full issue history.
- `list_project_issue_custom_fields` returns fields visible to the user in the project. If `tracker_id` is set, the tracker must belong to the project.
- `copy_issue` requires permission to copy issues on the **source** project and permission to create issues on the **target**. Watchers are copied only if the user has permission to add watchers on the target project. Link to the original and attachment copying follow Redmine settings `link_copied_issue` and `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Without field overrides, the copy still goes through form write rules. The source issue's parent is preserved when allowed (including when copying within the same project).
- `create_issue_relation` applies only allowed relation attributes and writes the change to the issue journal. `delete_issue_relation` is allowed only if the relation can be deleted by the current user (both issues are visible and the user has permission to manage relations on at least one side); deletion is also written to the journal.
- `add_project_member` / `update_project_member` accept only roles the current user can manage in the project. A role outside that set is rejected; roles are not assigned partially.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` is a principal ID (user or group), not only a user.
- `delete_file` for an issue attachment follows the rule "can attachments on this issue be deleted" (including own issues and tracker permissions), not only global `edit_issues`. In `tools/list`, the tool is visible if the user may delete at least one attachment (project files, issues, or wiki), not only with global `manage_files`.
- `get_wiki_page`: `attachments` is always in the response; by default `[]` and `attachments_pagination: null`; with `include_attachments=true` — a paginated attachment list with `attachment_limit`/`attachment_offset` (default and maximum 100). Historical `version` requires permission to view wiki edits. Changing, renaming, or deleting a protected page requires permission to protect wiki pages.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: summary fields by default; full description via `fields` or `get_issue`.
- `create_issue` and `update_issue` accept explicit issue **attributes** (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields`, etc.). All explicitly passed attributes, including `subject` and `description` on create, go through the same write rules as the Redmine web form. Before create/update, the agent SHOULD call `get_issue_form_options` when allowed field values are unknown. An explicitly passed value that Redmine did not apply results in an error, not partial success.
- If the client **did not pass** `start_date` in `create_issue` / `validate_issue_create`, and Redmine has "start date = creation date" enabled (`default_issue_start_date_to_creation_date`), MCP sets `start_date` to the user's today — like the new issue form. An explicit `start_date` (including `null`) disables this substitution. `copy_issue` and `update_issue` do not substitute the date themselves.
- `update_issue` does not accept `notes`, `private_notes`, or `watcher_user_ids`. Comments — `add_issue_note`; watchers — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` also supports `uploads` for attaching files to an issue. Attachments are processed only after successful attribute validation (including `rejected_fields`). A call with only `uploads` (no attributes) is allowed if the user can add attachments to the issue — including when commenting is allowed but attributes cannot be edited. Optional `idempotency_key` protects against retries after a lost response (including re-uploading the same files). `journal_id` in the response is the journal entry for **this** call, not the latest issue entry.
- To clear an optional field, pass `null` for `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date`, or `estimated_hours`. Same for `update_version.due_date` / `wiki_page_title` and `update_issue_category.assigned_to_id`.
- `create_issue` does not support `uploads`.
- `update_issue` accepts `uploads[*].content_base64` and `uploads[*].filename`. After a successful upload, the response contains `added_attachments` — only files from this call, not the full issue attachment list. Corrupted Base64 is a parameter error.
- `update_issue` accepts `status_name` and resolves it to `status_id`.
- `upload_file` accepts `content_base64` (up to 20 MiB); `project`, `filename`, and `content_base64` are required.
- `get_attachment` returns `attachment_id`, `filename`, `content_type`, `size` (attachment filesize), and `content_url` (without file bytes).
- `download_attachment` returns `attachment_id`, `filename`, `content_type`, `size` (actual content size in bytes), and `content_base64` for a single attachment visible to the current user. If MIME is unknown — `application/octet-stream`. Does not increment the `downloads` counter. Size limit is 10 MiB (checks `File.size` on disk before read and `bytesize` after read); if exceeded — `FILE_TOO_LARGE`. Server filesystem paths are not returned in the response. `attachment_id` comes from `redmine_get_issue` / `redmine_get_wiki_page` with `include_attachments=true`, `redmine_list_files`, or `redmine_get_attachment`. To read, parse, or process an attachment as a file, decode `content_base64` locally. Non-existent and inaccessible attachments return the same "not found" response.
- `create_time_entry` and `import_time_entries.entries` items require `hours` and either `project` or `issue_id`. `hours` may be 0; zero validity and daily maximum are checked by Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` on issue create/update is a principal ID (user or group from `get_issue_form_options.assignees`); `null` clears the assignee. `user_id` on `add_issue_watcher` / `remove_issue_watcher` is a principal ID (user or group). In other tools, `user_id` is a user ID. For the current user, use `assignee_ref` or `user_ref` with value `me`.
- `expected_updated_at` (optional) on sensitive update/delete: if it does not match `updated_on`, returns `CONFLICT`.
- `idempotency_key` (optional) on `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: a retry with the same key and **the same argument set** (except the key itself) returns the cached successful result (TTL 24 h). The same key with a different payload — `CONFLICT`, no duplicate write. While the first request is still running, a retry with the same key does not perform another write (the "in progress" marker lives the same 24 h as a successful result). A cached entry without fingerprint (cache from before this version) with the same key is returned as before until TTL expires. Server timeout of 60 s applies to **reads**. Write operations are not interrupted by server timeout so that after a successful save the idempotency result can be recorded; the client may retry with the same key if it lost the connection. An unexpected exception in `import_time_entries` rolls back entries already inserted in that call; normal validation errors for individual rows are still collected without rolling back successful ones.
- `delete_file` by default deletes only project/version files; for issue/wiki attachments, `confirm_delete_any_attachment=true` is required.
- List/search use `limit`/`offset`. For DB queries, the page is limited at query level, not by trimming an already loaded full list. Any paginated MCP collection has an explicit stable order; the last criterion is always `id` so pages do not skip or duplicate items.
- Substring search (`query`, `login`, `name`, and text `search_issues`) matches characters literally: `%` and `_` are not SQL wildcards.
- MCP limits: timeout 60 s on read tools, rate limit 120 requests/min per user, MCP request HTTP body 36 MiB, maximum JSON tool args size 32 MiB, upload base64 up to 20 MiB, download base64 up to 10 MiB. Corrupted Base64 in any `content_base64` is a parameter error before tool execution.
- Every tool call, including access denial, is written to a structured audit log (tool, user, target IDs, outcome, duration, correlation_id) and counted toward rate limit; base64 content and private notes are not logged. Target IDs include `board_id`, `message_id`, `query_id`, `user_id`, `group_id`, among others.
- Each core tool's `outputSchema` describes the top level of `data` (for lists — `items` element fields), not an open arbitrary object. The schema field set matches the actual response: `list_users` without `created_on`, `list_all_users` with `created_on`; `get_attachment` includes `size` and `content_url`. Fields that may be empty in the real response allow `null` (including `time_entry.issue`, `*_pagination` without include, `estimation_accuracy`, attachment `content_type`). Custom field values and `possible_values` are not limited to objects. `attachments_not_saved` is an array of file names.
- `summarize_project_status.days` in the schema: default 30, minimum 1, maximum 365.
- `search_all.resources`: at most two unique values.
- `version_id`, `file_id`, `tracker_id` are integers not less than 1.

### `get_project`

- Input: `project` (required).
- Output: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (object `id`/`name`/`identifier` or `null`), `subprojects` (brief list of visible child projects: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` is filled only if the parent project is visible to the current user; otherwise `null`.
- Does not return members, enabled modules, or issue statistics. For modules — `get_project_modules`; for members — `list_project_members`; for issue aggregates — `summarize_project_status`.

### `get_issue_form_options`

- One call instead of several reference lookups before create/update. Separate `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` remain available.
- Input: `project` (required); optionally `tracker_id`, `issue_id`.
- The snapshot reflects the **issue form for the current user**, not the full project configuration: the same allowed values the Redmine UI offers.
- `tracker_id` without `issue_id` sets the create-form context. The tracker must be available for the current user to select on the form; otherwise — parameter error.
- `issue_id` sets the form for an existing visible issue in this project. With `issue_id`, `tracker_id` is allowed only if it matches the issue's current tracker; otherwise — parameter error (tracker change is not modeled through this tool).
- Output — form snapshot without pagination:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: trackers the current user can select on this form (`id`, `name`), not all trackers enabled for the project;
  - `priorities`: active priorities (`id`, `name`, `is_default`);
  - `categories`: project categories (`id`, `name`);
  - `versions`: versions available for selection on this form (`id`, `name`, `status`, `due_date`);
  - `assignees`: principals that can be assigned in this form context. Element: `id`, `name`, `type` (`user` or `group`); for `user`, additionally `login`. Groups are included if Redmine has issue assignment to groups enabled;
  - `custom_fields`: only fields the current user can edit on the form, considering project/tracker, visibility, workflow read-only. Element: `id`, `name`, `field_format`, `required` (field required or required by workflow), `readonly` (always `false` in this list), `multiple`, `default_value`, `possible_values`, `trackers`. Form context — issue from `issue_id` or create draft considering `tracker_id`;
  - `possible_values` — array of objects `{ "label": "...", "value": "..." }`. For lists without separate labels, `label` matches `value`. For user/version/enumeration, `label` is the display name, `value` is the identifier;
  - `statuses`: statuses allowed by workflow for the current user. With `issue_id` — transitions for this visible issue. Without `issue_id` — initial statuses for create (considering `tracker_id` if set);
  - `editable_fields`: attribute names this MCP contract accepts on create/update that the current user can set on the form, plus editable custom field ids as strings. Does not include `notes`, `private_notes`, `watcher_user_ids`, and other web form fields absent from MCP write tools;
  - `required_fields`: field names required on this form for the current user, in the same name form as `editable_fields`.
- Non-existent `tracker_id`, tracker not allowed for the user, or `issue_id` outside the project / not visible — parameter error.

### `add_issue_note`

- Adds a comment to an existing visible issue without changing issue attributes.
- Input: `issue_id` (required), `notes` (required), optionally `private_notes`, `uploads`, and `idempotency_key`.
- Permission: the user can add comments to this issue. `private_notes=true` requires permission to make private comments; otherwise — denied, no comment is created. Attachments in the same call are allowed if the user can add attachments to the issue.
- Does not accept issue fields or watcher lists.
- Output: `issue_id`, `journal_id`, `notes`, `private_notes`; with `uploads` — `added_attachments` (only files from this call).
- Not available in Read-only mode.

### `update_issue_note` / `set_issue_note_private`

- Work only with a journal entry the current user **sees** (another user's private comments without permission to view private notes are inaccessible).
- The entry must be editable by the current user (permission to edit comments or own comments).
- `update_issue_note.notes` may be an empty string (clearing text of an existing entry). A new comment via `add_issue_note` cannot be empty.
- Changing privacy (`private_notes` / `is_private`) requires separate permission to make comments private; otherwise denied, text is not partially changed.
- Records who edited the journal entry.
- Not available in Read-only mode.

### `validate_issue_create` / `validate_issue_update`

- Separate read-only tools, not a `validate_only` parameter on write tools. Available in Read-only mode.
- `validate_issue_create`: same fields as `create_issue`, without `idempotency_key`. `project` and `subject` are required. Permission `add_issues`.
- `validate_issue_update`: dry-run for **issue attributes** only (like `update_issue`, without `uploads`). `issue_id` is required. The issue must be editable by the current user. Before validation, a user journal context is created without a DB write (as in a real update).
- Behavior: apply attributes to the issue without saving. Redmine data is not changed.
- Attributes still go through the same write rules as the Redmine web form. If the client **explicitly passed** a value and Redmine did not apply it, that is an MCP error, not success.
- An explicit field not among those writable on the issue (disabled / workflow read-only / derived dates, etc.) goes into `rejected_fields`. For `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id`, and `custom_fields`, it is additionally checked that the requested value was actually applied.
- The same rule applies to `create_issue`, `update_issue`, and `copy_issue`: no write if an explicitly requested value was not applied.
- Success: `{ "valid": true, "errors": [] }`.
- Failure: `{ "valid": false, "errors": ["..."] }`. If some explicit fields were not applied — also `rejected_fields` (field names, for example `["tracker_id"]`) and, for typical errors — `missing_required_fields` / `hint` in the same form as create/update.
- Also catches: tracker not available to the current user; invalid or unavailable custom field value; status transition forbidden by workflow; assignee not available for assignment.

### `list_issues` — extended filters

- Existing flat filters (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) are preserved.
- Optional `filters`: array of objects `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` is an array of strings; an empty array is allowed for operators without values.
- Allowed `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id`, and `cf_<id>` for issue custom fields.
- Operators are standard Redmine query operators, including `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. The operator must be valid for the field type; otherwise — parameter error.
- Unknown `field` or invalid `operator` — parameter error, query is not executed.
- Flat filters and `filters` are combined with AND.
- Filters apply only to issues visible to the current user.

### `run_issue_query`

- Input: `query_id` (required, from `list_queries`); optionally `project`, `fields`, `limit`/`offset`.
- Executes a saved issue query visible to the current user. Response format is the same list envelope as `list_issues`.
- If the query is project-scoped, results are limited to that project (and query visibility rules). Optional `project` for a project query must match the query's project; otherwise — parameter error.
- If the query is global, optional `project` narrows the selection to that visible project.
- Invisible or non-existent `query_id` — error.
- `list_queries` does not execute the query; use `run_issue_query` for execution.

### `list_project_activities`

- Input: `project` (required); optionally `from`, `to` (dates `YYYY-MM-DD`), `author_id`, `event_types` (array of strings), `limit`/`offset`.
- Default window — last 7 days (`to` = today, `from` = today minus 6 days). Maximum window length — 90 days; if exceeded — parameter error.
- Events from the project activity feed: type, time, author (`id`/`name`), `title`, `description`, `url`. Order — newer events first; for equal time — higher `id` first.
- Envelope like other `list_*`.
- `event_types` limits event types. A type unavailable to the user or disabled in the project is excluded from the selection (without error).
- Non-existent `author_id` — empty list, not an error.

### `summarize_project_status`

Existing fields are preserved: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

The `days` window (default 30, range 1–365) still affects `recent_activity` and the period metrics listed below. A value outside the range is rejected by the schema. `totals` and breakdowns are computed over all visible project issues without a date filter, via DB aggregation, without loading all issues into memory. Subprojects are not included.

Additional fields:

- `overdue_count` — number of open visible issues with `due_date` strictly before the user's today.
- `unassigned_count` — number of open visible issues without an assignee.
- `stale_issues_count` — number of open visible issues with `updated_on` older than the start of the `days` window.
- `issues_closed_during_period` — number of visible issues with `closed_on` within the `days` window.
- `estimated_hours` — sum of estimates of visible project issues (`null` if none have an estimate, otherwise a number including 0).
- `spent_hours` — sum of time spent on visible project issues (0 if no entries). Requires `view_time_entries` on the project; without permission the field is `null`.
- `average_resolution_hours` — average `(closed_on - created_on)` in hours for issues closed in the `days` window; `null` if there are no such issues.
- `estimation_accuracy` — for issues closed in the window that have both an estimate and non-zero/logged time: `{ "issues_count", "total_estimated", "total_spent" }`. If no matching issues — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Requires `view_time_entries` on the project; without permission the field is `null`.
- `reopened_count` — number of visible issues whose journal status changed from closed to open within the `days` window. Each issue is counted at most once.

The tool returns facts, not a textual "project health analysis".

### `get_version`

- Input: `version_id` (required); optionally `project`. If `project` is set, the version is accessible when it is in this visible project's shared versions (even if the version's source project is not visible to the user). Without `project`, the version must be visible on its source project.
- Output: fields like a `list_versions` element (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) plus aggregates: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Aggregates are computed only over version issues visible to the current user.
- Issue list is not returned.
- `spent_hours` requires `view_time_entries` on the version's project; without permission — `null`. Sum only over visible version issues and only time entries the current user can see (including `time_entries_visibility=own`).

### Boards

- The project forums module must be enabled; otherwise error "Boards module is not enabled for this project" (wiki analogue).
- Permission `view_messages`. No forum write operations.
- `list_boards`: `project` required; pagination. Element: `id`, `name`, `description`, `parent_id` (`null` for root board), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` required; pagination. Root messages only (no parent). Element: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` required. Output: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — brief reply list (`id`, `subject`, `author`, `created_on`) without full text of each reply, with `replies_limit`/`replies_offset` (default and maximum 100) and `replies_pagination`.
- Invisible board/message or board from another project — "not found" error.

### `list_users`

- With `project`: active **user** project members (permission `view_members`). Group membership in the project does not appear as a group; users from a group only if they are members themselves. Without `project` — administrator only.
- Element: `id`, `login`, `firstname`, `lastname`, `mail`. Does not include `created_on` (that field is on `list_all_users`).
- Optional `query`: case-insensitive substring on `login`, `firstname`, and `lastname`.
- Optional `login` is preserved (login substring only) for compatibility. If both `query` and `login` are set, both conditions apply (AND).

### `list_groups`

- Paginated list of givable groups (`id`, `name`), **visible** to the current user, for selecting `group_id` in `add_project_member`.
- Optional `query`: case-insensitive substring on group name; `%` and `_` are matched literally.
- Permission: administrator or `manage_members` on at least one visible project.
- Does not return group membership or memberships.

### `list_project_member_candidates`

- Candidates for adding to the project: active visible users and groups not yet in the project.
- Input: `project` (required); optionally `query` (substring, as in Redmine member picker).
- Output list envelope: `id`, `name`, `type` (`user` or `group`); for user, additionally `login`.
- Permission `manage_members` on the project.
- `add_project_member`: `user_id` for user only, `group_id` for group only. ID of the wrong type — parameter error. Before adding, take IDs from this tool (or from `list_users` / `list_groups` if the candidate is already known).

### `list_roles`

- Only roles the current user can manage in the specified project.
- Input: `project` (required).
- Permission `manage_members` on the project.
- For administrator, the set matches assignable project roles (without Non member / Anonymous).

## Edge Cases

- Non-existent/inaccessible project or issue — `{ "error": "..." }`.
- Read-only mode — `{ "error": "MCP is in read-only mode..." }` for write tools **before** calling the handler, including Extension API tools; validate/form options/list/get remain available.
- Empty list/search result — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- List/search with pagination always return `data.items` and `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Default limit 25, maximum 100.
- All `list_*` tools (including references: trackers, statuses, roles, queries, boards, board topics, etc.) use the same envelope. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status`, and validate tools — single objects, not list envelope.
- `download_attachment`: non-existent and inaccessible attachment — same "not found" error; file unreadable on disk — error; size on disk or after read above 10 MiB — `FILE_TOO_LARGE` (limit is not bypassed by a lower DB `filesize`). Same indistinguishable "missing / no access" rule — for `get_attachment`.
- `list_project_activities`: window longer than 90 days — parameter error; `from` after `to` — parameter error.
- `run_issue_query`: invisible query — treated as non-existent.
- `get_issue_form_options` with `issue_id` for an issue from another project — parameter error.
- `get_issue_form_options` with `issue_id` and `tracker_id` not equal to that issue's tracker — parameter error.
- Validate tools do not create an issue, do not update an issue, do not create journal entries, and do not consume `idempotency_key`.
- Writes through MCP go through Redmine models. Model callbacks run; web interface controller hooks are not called.

## Error handling

- Missing permission — tool not visible in `tools/list` or "Permission denied".
- Model validation errors — `{ "error": "<messages>" }` (for issue create/update and validate tools additionally `missing_required_fields` as field names from model error symbols, without parsing translation text, and `hint`).
- Disabled wiki/boards module — separate error message, not "not found".
- Canonical error code in the envelope is set explicitly by the handler; the code is not derived from message text and does not depend on user language.

## Test scenarios

1. `list_projects` / `list_issues` return envelope `data.items` + `meta` with pagination.
2. `get_issue` without `include_*` does not return journals/attachments; with `include_journals` — journals with pagination.
3. `search_issues` by text finds issues; `search_all` includes wiki when searching multiple types.
4. `create_issue` / `update_issue` with valid fields succeed; without permission or in read-only — error.
4a. `create_issue` without `start_date` with start-date setting enabled sets today's date; explicit `start_date` or `null` is not overwritten by that setting.
5. `delete_issue` without `confirm_delete` returns `INVALID_STATE` and impact; with confirmation deletes.
6. `create_time_entry` requires `hours` and `project` or `issue_id`; `import_time_entries` accepts a batch.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` work with Wiki module enabled.
8. `upload_file` requires `filename` and `content_base64`; `delete_file` for issue attachment requires confirm.
9. User without `use_mcp` does not pass MCP authentication; without tool permission does not see it in `tools/list`.
10. Retry `create_issue` with the same `idempotency_key` and same arguments does not create a duplicate; same key with different subject — `CONFLICT`.
11. `download_attachment` for visible issue attachment returns `content_base64` with actual content `size`; for file > 10 MiB on disk (even with small metadata) — `FILE_TOO_LARGE`; non-existent and inaccessible attachment are indistinguishable.
12. `get_project` by identifier returns description, subprojects, and `last_activity_date`; inaccessible project — error.
13. `get_issue_form_options` for project returns trackers/statuses/priorities/categories/versions/assignees/custom_fields and `editable_fields` / `required_fields` lists; `trackers` — only those available to the current user; with `issue_id` statuses reflect allowed transitions for that issue; `issue_id` + different `tracker_id` — error; `possible_values` — `label`/`value` objects.
14. `validate_issue_create` with invalid tracker or status returns `valid: false` and `rejected_fields`, does not create issue; in read-only mode call succeeds.
15. `list_issues` with `filters` (`due_date` `<=` date, `priority_id` `!`) returns only matching visible issues; unknown `field` — error.
16. `run_issue_query` with visible `query_id` returns same issues as saved query in UI; invisible query — error.
17. `list_project_activities` for 3 days returns project events with pagination; 91-day window — error.
18. `summarize_project_status` includes `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period`, and `reopened_count`.
19. `get_version` returns aggregates `open_issues_count` / `completed_percent` without issue list.
20. `list_boards` / `list_board_topics` / `get_board_message` work with Boards module enabled; when disabled — module error.
21. `list_users` with `project` and `query` by name finds member without knowing login.
22. `get_issue_form_options` returns assignees with `type` user/group and only editable custom fields with `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` with explicitly passed value that Redmine does not apply (including disabled/read-only core fields, including `description` on create) return error and do not save partial change.
24. `validate_issue_update` does not accept notes; comment is created by `add_issue_note`. `add_issue_note` with `add_issue_notes` succeeds without `edit_issues`; `private_notes` without `set_notes_private` — denied. `update_issue` with only `uploads` succeeds with permission to add attachments without `edit_issues`.
25. `list_groups` returns givable groups for user with `manage_members`.
26. `update_issue` with `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` clears the field if writable.
27. `update_issue_note` / `set_issue_note_private` do not change another user's private comment if the user lacks permission to view private comments.
28. User with permission to edit comments but not to make them private can change public comment text and cannot change privacy flag.
29. `add_issue_note` with `uploads` creates comment and attachment in one call; retry with same `idempotency_key` does not duplicate them.
30. `update_issue` with `uploads` and `idempotency_key`: retry with same payload does not duplicate attachment; different file with same key — `CONFLICT`. Corrupted Base64 — parameter error.
31. `get_issue` does not return hidden custom fields, invisible journal details, or relations with invisible issues. `get_version` aggregates only over visible issues.
32. `copy_issue` without permission to copy on source project — denied, even with `add_issues` on target.
33. `add_project_member` / `update_project_member` with role the user cannot manage — denied without partial assignment.
34. `create_version` / `update_version` with `sharing` not allowed for user — denied. `delete_version` for busy version — denied without deletion.
35. Time entry author with `edit_own_time_entries` can update own entry via `update_time_entry`.
36. `search_all` available to user with wiki permission without `view_issues`, if search includes wiki.
37. `list_project_member_candidates` returns users and groups not yet in project; `add_project_member` with group `user_id` — error.
38. `list_roles` for project returns only roles the user can manage; without `project` — schema error. Does not include built-in Non member and Anonymous.
39. Retry `copy_issue` / `create_time_entry` with same `idempotency_key` does not create duplicate; different payload with same key — `CONFLICT`.
40. `search_issues` and user/group search for `%` or `_` match those characters literally, not as wildcards.
41. `get_version.spent_hours` with `time_entries_visibility=own` counts only own time entries.
42. `search_issues` with `scope=subprojects` without `project` — error; with `project` finds issues in descendants.
43. `list_project_activities` returns newer events before older ones.
44. `delete_issue` impact does not include hidden journals, relations, and others' time entries; hidden subtasks still require `confirm_delete_with_children`.
45. `get_project` does not return parent invisible to the current user.
46. `update_version` with `due_date`/`wiki_page_title` = `null` clears the field.
47. `update_issue_category` with `assigned_to_id` = `null` clears default assignee.
48. Schema accepts `hours` of 0 and values above 24; only Redmine validation rejects.
49. `update_issue_note` with empty `notes` clears text of existing comment.
50. `list_users` with `project` returns only users, even if the project has group membership.
51. Historical wiki page version without `view_wiki_edits` is inaccessible; protected page cannot be changed without permission to protect wiki.
52. `copy_issue` without permission to add watchers does not copy watchers; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` forbid link and attachments; parent in same project is preserved.
53. Extension write tool in read-only mode does not invoke handler.
54. `delete_file` visible in `tools/list` for user who can delete issue attachments, without `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` accept group principal.
56. `get_version` with `project` returns shared version that `list_versions` for that project returned.
57. `get_issue` / `get_wiki_page` / `get_board_message` limit nested lists with `limit`/`offset` and return `*_pagination`; without include pagination is `null`.
58. Actual tool responses, including nullable fields, match published `outputSchema`.
59. `get_issue` with `include_journals`: journal with only hidden custom-field detail is not in the list and not counted in `journal_pagination.total_count`.
60. Hidden journal between two visible ones does not create a page gap: with `journal_limit=2` two visible entries are returned, `total_count` equals visible count.
61. Another user's private comment is not returned in `get_issue` without `view_private_notes` permission.
62. `get_private_notes` returns a page by `limit`/`offset` without loading full issue history.
63. `get_issue` with journals `attr`, `cf`, and `relation` simultaneously does not fail and returns only visible entries.
64. Journal with hidden custom-field detail and notes of spaces, tabs, or line breaks is not included in `get_issue`.
65. `get_private_notes` does not return a comment of only spaces, tabs, or line breaks.
