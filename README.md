# Redmine MCP

[Website](https://redmine-kanban.com/)

[Deutsch](doc/spec/de/README.md) | English | [Español](doc/spec/es/README.md) | [Français](doc/spec/fr/README.md) | [Italiano](doc/spec/it/README.md) | [日本語](doc/spec/ja/README.md) | [한국어](doc/spec/ko/README.md) | [Polski](doc/spec/pl/README.md) | [Português (Brasil)](doc/spec/pt-BR/README.md) | [Русский](doc/spec/ru/README.md) | [中文](doc/spec/zh/README.md)

An MCP (Model Context Protocol) server inside Redmine. It lets AI clients work with issues, projects, and users through standard Redmine permissions. Other plugins can add their own tools, resources, prompts, and capabilities without changing this plugin.

## Requirements

| Component | Version |
|---|---|
| Redmine | Redmine 6.0+ (tested: 6.0–6.1) |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

This plugin uses MCP protocol `2025-11-25` and Ruby MCP SDK `0.23.x`.
Support for newer MCP protocol and SDK versions is not currently declared.

- REST API enabled in Redmine
- the `mcp` gem is declared in `plugins/redmine_mcp/Gemfile` and installed with `bundle install`

## Installation and setup

### 1. Install the plugin

Clone the git repository into the Redmine `plugins` directory:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

From the Redmine root directory, install dependencies and restart the application:

```bash
cd /path/to/redmine
bundle install
```

Restart Redmine.

### 2. Enable in Administration

**Administration → Plugins → Redmine MCP → Configure**

| Setting | Description |
|---------|-------------|
| Enable MCP | Enables the `/mcp` endpoint. When enabled, MCP extensions from installed plugins are loaded |
| Read-only mode | Blocks write tools and write actions (create/update/delete, etc.) |
| MCP extensions | Checkboxes to enable MCP integration for installed plugins |

### 3. REST API

**Administration → Settings → API** — enable “Enable REST web service”.

### 4. Permissions

**Administration → Roles and permissions** — for the required roles, manually enable the global permission **Use MCP** (`use_mcp`). Redmine administrators always have MCP access.

### 5. User API key

Every user who will work through MCP must have an API key:

**My account → API access key** (or via the user REST API).

Pass the key in the header:

```
X-Redmine-API-Key: <your_key>
```

## Connecting an MCP client

The server uses **Streamable HTTP** (stateless). Endpoint:

```
https://<your-redmine>/mcp
```

Supported methods: `GET`, `POST`, `DELETE`.

### Cursor example

In MCP settings (`.cursor/mcp.json` or the global config), add a server with HTTP transport. The exact format depends on the client version; a typical example:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "your_api_key"
      }
    }
  }
}
```

After connecting, the client will call `initialize`, then it can call `tools/list`, `tools/call`, `resources/list`, `prompts/list`, and so on.

### Manual check

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: your_key' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0" }
    }
  }'
```

A successful response contains `serverInfo.name: "redmine_mcp"`.

### Host and reverse proxy

MCP transport validates HTTP `Host` and `Origin` to protect against DNS rebinding.

The allowed host is taken from the Redmine setting:

**Administration → Settings → General → Host name and path**

The value must match the public Redmine URL.

For example, if Redmine is available at:

```
https://redmine.example.com
```

the setting should use:

```
redmine.example.com
```

If Redmine runs behind a reverse proxy, the proxy must forward the client's original `Host` header.

If the host does not match, the MCP endpoint may return HTTP `403 Forbidden`.

Clients without an `Origin` header are not affected by the Origin check.

## Built-in tools (core tools)

Full names use the format `redmine_<tool_name>` (for example `redmine_get_issue`).

The server provides tools for projects, issues, users, time tracking, Wiki, forums, and files. The list below is a short overview of built-in tools. Full input schemas and descriptions are available to the MCP client via `tools/list`.

### Common parameters

- `project` — project string ID or identifier.
- `assignee_ref` / `user_ref` with the value `me` — the current user.
- `assigned_to_id` — principal user/group; `null` clears optional fields.
- `create_time_entry` requires `project` or `issue_id`.
- `upload_file` requires `filename` and `content_base64`.

### Operation reliability

- `expected_updated_at` — on sensitive update/delete operations.
- `idempotency_key` — on `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Limits

- 60 s read timeout;
- 120 requests/min per user;
- MCP request HTTP body up to 36 MiB;
- tool JSON args up to 32 MiB;
- base64 attachments up to 20 MiB;
- attachment downloads up to 10 MiB.

### Production deployment

Rate limiting and idempotency use `Rails.cache`.

For installations with multiple application workers or multiple Redmine instances, a shared cache store should be used.

With a process-local cache, rate limiting and idempotency guarantees apply only within an individual application process.

### Project management

| Tool | Description |
|------|-------------|
| `list_projects` | List projects |
| `get_project` | Project details |
| `list_project_issue_custom_fields` | Project issue custom fields |
| `summarize_project_status` | Server-built project metrics summary for N days |
| `list_project_activities` | Project activity feed (events, not time-entry types) |
| `list_versions` | Roadmap versions (milestones) |
| `get_version` | Roadmap version details with aggregates |
| `create_version` | Create a version |
| `update_version` | Update a version |
| `delete_version` | Delete a version |
| `list_project_members` | Project members and their roles |
| `list_project_member_candidates` | Users and groups that can be added to the project |
| `list_roles` | Roles that can be managed in the project |
| `get_project_modules` | Enabled project modules |
| `add_project_member` | Add a member |
| `update_project_member` | Change member roles |
| `remove_project_member` | Remove a member |

### Issues

| Tool | Description |
|------|-------------|
| `get_issue` | Issue details (journal, attachments, custom fields, etc.) |
| `list_issues` | List issues with filters and pagination |
| `search_issues` | Text search over issues |
| `run_issue_query` | Run a saved issue query |
| `get_issue_form_options` | Allowed issue form field values (single call) |
| `validate_issue_create` | Validate issue create parameters without writing |
| `validate_issue_update` | Validate issue update parameters without writing |
| `create_issue` | Create an issue |
| `update_issue` | Update issue attributes and attachments |
| `add_issue_note` | Add a comment to an issue (optionally with attachments) |
| `delete_issue` | Delete an issue with confirmation |
| `copy_issue` | Copy an issue |
| `list_issue_relations` | List issue relations |
| `create_issue_relation` | Create a relation between issues |
| `delete_issue_relation` | Delete an issue relation |
| `list_subtasks` | Subtasks |
| `add_issue_watcher` | Add a watcher |
| `remove_issue_watcher` | Remove a watcher |
| `update_issue_note` | Edit a journal entry |
| `set_issue_note_private` | Change journal entry privacy |
| `get_private_notes` | Private comments only |
| `list_issue_categories` | Project issue categories |
| `create_issue_category` | Create a category |
| `update_issue_category` | Update a category |
| `delete_issue_category` | Delete a category |

### Users

| Tool | Description |
|------|-------------|
| `list_users` | Project members; `query` (name/login) and `login` filters; global search is admin-only |
| `list_groups` | Givable groups for `group_id` in `add_project_member` |

### Time tracking

| Tool | Description |
|------|-------------|
| `list_time_entries` | List time entries |
| `create_time_entry` | Create a time entry |
| `update_time_entry` | Update a time entry |
| `list_time_entry_activities` | Time-logging activity types (not the project event feed) |
| `import_time_entries` | Bulk import of time entries |

### Reference data

| Tool | Description |
|------|-------------|
| `list_trackers` | All trackers |
| `list_project_trackers` | Project trackers |
| `list_issue_statuses` | Issue statuses |
| `list_issue_priorities` | Issue priorities |
| `admin_list_users` | Users with filters (admin only) |
| `get_current_user` | Current user |
| `list_queries` | Saved queries (metadata; execution is `run_issue_query`) |

### Search and Wiki

| Tool | Description |
|------|-------------|
| `search_all` | Search issues and Wiki pages |
| `list_wiki_pages` | Project Wiki pages |
| `get_wiki_page` | Get a Wiki page |
| `create_wiki_page` | Create a Wiki page |
| `update_wiki_page` | Update a Wiki page |
| `delete_wiki_page` | Delete a Wiki page |
| `rename_wiki_page` | Rename a Wiki page |

### Forums

| Tool | Description |
|------|-------------|
| `list_boards` | Project forum boards |
| `list_board_topics` | Topics of the selected board |
| `get_board_message` | Forum message with brief replies |

### Files

| Tool | Description |
|------|-------------|
| `list_project_files` | Project files |
| `upload_file` | Upload a file |
| `delete_attachment` | Delete an attachment |
| `get_attachment` | Attachment metadata and `content_url` |
| `download_attachment` | Attachment content (`content_base64`, up to 10 MiB) |

### Utility

| Tool | Description |
|------|-------------|
| `get_mcp_info` | MCP plugin version, read-only mode, current user, and available capabilities |

### Access and responses

Tools return a JSON envelope in `structuredContent` and a text representation in `content`.

Write operations are blocked by the **Read-only mode** setting.

In addition to tool-specific permissions, the global **Use MCP** permission is always checked.

Data access is enforced through standard Redmine permissions and visibility rules. For project and issue data, `Project.visible` and `Issue.visible` are used.

## Extensions from other plugins

Any installed Redmine plugin can add its own MCP tools and, if needed, register resources, prompts, and capabilities.

Detailed guide: [extension_guide.md](doc/spec/en/extension_guide.md).

For AI-assisted development in Cursor or similar agents, copy the bundled skill directory [`redmine-mcp-plugin-integration`](doc/skills/redmine-mcp-plugin-integration/) into your agent's skills folder, or use it as a basis for your own skill.

## Logging

Messages are written to the standard Rails log with the `[redmine_mcp]` prefix:

- extension loading
- tool/resource/prompt registration
- registration and execution errors
- access denials

## Troubleshooting

| Symptom | Possible cause |
|---------|----------------|
| HTTP 503 “MCP is disabled” | MCP is not enabled in plugin settings |
| HTTP 401 | Missing or invalid API key; REST API is disabled |
| HTTP 403 (permission) | The user does not have the **Use MCP** permission |
| HTTP 403 (`Host`/`Origin`) | **Host name and path** does not match the public Redmine URL; reverse proxy does not forward the original `Host`; MCP URL in the client does not match — transport rejects unknown hosts (DNS rebinding protection) |
| Tool is not visible in `tools/list` | Missing required permissions; the extension that provides the tool is disabled |
| New tools did not appear after MCP reload | In Cursor and similar clients, reloading the server may not refresh the tool list — fully restart the application |
| Extension does not load | Missing `lib/.../mcp.rb`; the module does not `extend RedmineMcp::ExtensionApi`; make sure the extension checkbox is enabled under **MCP extensions**; if the file has an error, check the log |
| `Issue not found` / `Project not found` | The issue or project is not visible to the current user under Redmine visibility rules |

## License

This plugin is licensed under the GNU General Public License,
version 2 or any later version.

See [LICENSE](LICENSE) for details.
