# Redmine MCP — allgemeine Spezifikation

[Deutsch](00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Überblick

Das Redmine-MCP-Plugin stellt einen MCP-Server (Model Context Protocol) innerhalb einer Redmine-Installation bereit. AI-Clients verbinden sich mit einem einzigen HTTP-Endpunkt und greifen über Tools, Resources und Prompts auf Redmine-Daten zu.

Das Plugin enthält eine Basismenge von Tools für die Arbeit mit Projekten, Vorgängen und Benutzern. Andere installierte Redmine-Plugins können MCP erweitern, ohne den Redmine-MCP-Code zu ändern.

## Ziel

Einen einheitlichen Integrationsmechanismus zwischen Redmine und AI-Systemen bereitstellen, bei dem:

- der Benutzer innerhalb seiner Redmine-Berechtigungen arbeitet;
- Plugin-Entwickler eigene MCP-Funktionen hinzufügen können;
- kein separater MCP-Server oder installations-spezifischer Fork erforderlich ist.

## Hauptszenarien

1. **Verbinden eines AI-Clients** — ein Administrator aktiviert MCP, erteilt der Rolle `use_mcp` die Berechtigung und stellt einen API-Schlüssel aus; der Benutzer verbindet einen Client (Cursor usw.) mit dem Endpunkt `/mcp`.
2. **Arbeiten mit Redmine-Daten** — der Client ruft Tools auf, um Projekte, Vorgänge und Benutzer abzurufen.
3. **Erweiterung durch andere Plugins** — wenn ein Plugin mit MCP-Erweiterung installiert ist, erscheinen dessen Tools automatisch in der gemeinsamen Liste.
4. **Administration** — Aktivieren/Deaktivieren von MCP und Aktivieren der MCP-Integration einzelner Plugins.

## Betroffene Bereiche

- API (MCP over HTTP)
- Permissions
- Settings
- Issues
- Projects
- Users
- Boards
- Plugins (Erweiterungen)

## Geschäftsregeln

- MCP ist nur verfügbar, wenn es in den Plugin-Einstellungen explizit aktiviert ist.
- Alle Operationen laufen im Namen des authentifizierten Redmine-Benutzers.
- Schreibvorgänge über MCP laufen über Redmine-Modelle: Model-Callbacks werden ausgeführt. Controller-Hooks (`controller_issues_*_save`, `controller_journals_edit_post` usw.) werden von MCP nicht aufgerufen.
- Die Datensichtbarkeit folgt den Redmine-Regeln: der Benutzer erhält nicht mehr, als er in der Web-Oberfläche sehen kann.
- Tool- und Prompt-Namen verwenden das Format `<plugin_id>_<name>`, zum Beispiel `redmine_list_projects`.
- `title` und `description` der Core-Tools werden auf Englisch veröffentlicht (für die LLM-Auswahl) und werden **nicht** über `en.yml`/`ru.yml` lokalisiert (Ausnahme vom i18n-Standard für den MCP-Tool-Katalog). Fehlermeldungen und die Einstellungs-UI werden lokalisiert.
- Erweiterungen anderer Plugins erzeugen keine harte Abhängigkeit: fehlt Redmine MCP, funktioniert das Drittanbieter-Plugin weiter.

## Randfälle

- Ist MCP deaktiviert, werden alle Anfragen an `/mcp` abgelehnt.
- Schlägt eine Erweiterung fehl, funktionieren andere Erweiterungen und Core-Tools weiter.
- Neue Tools aus Erweiterungen sind nach einem Redmine-Neustart verfügbar; der MCP-Client muss ggf. neu verbunden werden, um die Tool-Liste zu aktualisieren.
- Im stateless Modus wird jede HTTP-Anfrage unabhängig verarbeitet; zwischen Anfragen wird keine Session beibehalten.

## Fehlerbehandlung

- Authentifizierungs- und Autorisierungsfehler werden auf HTTP-Ebene zurückgegeben.
- Fehler bei der Tool-Ausführung werden im MCP-Format mit einem Fehler-Flag zurückgegeben.
- Fehler beim Laden von Erweiterungen werden protokolliert und blockieren den Redmine-Start nicht.

## Spezifikationsdateien

| Datei | Inhalt |
|------|---------|
| [console-commands.md](console-commands.md) | Installations-, Prüf- und Wartungsbefehle |
| [01-mcp-server.md](01-mcp-server.md) | HTTP-Endpunkt, MCP-Protokoll, Transport |
| [02-authentication.md](02-authentication.md) | Authentifizierung und Zugriffskontrolle |
| [03-core-tools.md](03-core-tools.md) | Eingebaute Redmine-Tools |
| [04-extensions.md](04-extensions.md) | Extension API für andere Plugins |
| [05-settings.md](05-settings.md) | Plugin-Einstellungen und Protokollierung |
| [mcp_tool_development.md](mcp_tool_development.md) | Anforderungen an die MCP-Tool-Entwicklung (Dev-Guide) |
| [extension_guide.md](extension_guide.md) | Leitfaden für Extension-Entwickler |

## Testszenarien

1. Nach Installation und Aktivierung von MCP führt der Client `initialize` erfolgreich aus und erhält Serverinformationen.
2. Ein Benutzer mit der Berechtigung Use MCP und gültigem API-Schlüssel sieht die für ihn verfügbare Tool-Liste.
3. Ein Benutzer ohne die Berechtigung Use MCP wird der Zugriff auf `/mcp` verweigert.
4. Ist ein Extension-Plugin installiert, sind dessen Tools für einen Benutzer mit den entsprechenden Berechtigungen in `tools/list` vorhanden.
