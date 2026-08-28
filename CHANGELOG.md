# Changelog

## [1.0.0] - 2026-08-25

### Added
- Redmine MCP plugin: `/mcp` endpoint, core tools (projects, issues, time tracking, wiki, boards, files, search), extension API, permission-aware `tools/list`, audit logging; MCP protocol revision `2025-11-25`; admin settings for MCP, read-only mode, and per-plugin extensions;
- `redmine_download_attachment`: read attachment bytes as `content_base64` (max 10 MiB);

### Improved
- Developer documentation: specs, extension guide, and MCP tool development guide;
