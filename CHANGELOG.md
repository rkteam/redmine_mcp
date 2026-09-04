# Changelog

## [1.1.0] - 2026-09-04

### Added
- Built-in MCP extensions via `lib/redmine_mcp/extensions/<plugin.id>.rb` for third-party plugins that cannot be modified
- Compatibility with Redmine 7.0;

## [1.0.1] - 2026-09-01

### Added
- Issue and attachment tools expose canonical web UI links (`url`, `content_url`); `null` when Redmine "Host name and path" is blank;

### Improved
- Core tool renames and watcher `principal_id` (previous names remain callable); permission denials in `add_issue_watcher`, `remove_issue_watcher`, and `remove_project_member` return `FORBIDDEN` instead of a generic parameter error;

## [1.0.0] - 2026-08-25

### Added
- Redmine MCP plugin: `/mcp` endpoint, core tools (projects, issues, time tracking, wiki, boards, files, search), extension API, permission-aware `tools/list`, audit logging; MCP protocol revision `2025-11-25`; admin settings for MCP, read-only mode, and per-plugin extensions;
- `redmine_download_attachment`: read attachment bytes as `content_base64` (max 10 MiB);

### Improved
- Developer documentation: specs, extension guide, and MCP tool development guide;
