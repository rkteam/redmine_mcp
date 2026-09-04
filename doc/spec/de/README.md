# Redmine MCP

[Website](https://redmine-kanban.com/)

Deutsch | [English](../../../README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Ein MCP-Server (Model Context Protocol) innerhalb von Redmine. Er ermöglicht AI-Clients die Arbeit mit Vorgängen, Projekten und Benutzern über die standardmäßigen Redmine-Berechtigungen. Andere Plugins können eigene Tools, Resources, Prompts und Capabilities hinzufügen, ohne dieses Plugin zu ändern. Für Drittanbieter-Plugins, die nicht geändert werden können, kann `redmine_mcp` eingebaute MCP-Integrationen unter `lib/redmine_mcp/extensions/` bereitstellen.

## Anforderungen

| Komponente | Version |
|---|---|
| Redmine | Redmine 6.0–7.0 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Dieses Plugin verwendet MCP protocol `2025-11-25` und Ruby MCP SDK `0.23.x`.
Unterstützung für neuere Versionen von MCP protocol und SDK ist derzeit nicht deklariert.

- REST API in Redmine aktiviert
- das `mcp`-Gem ist in `plugins/redmine_mcp/Gemfile` deklariert und wird mit `bundle install` installiert

## Installation und Einrichtung

### 1. Plugin installieren

Klonen Sie das Git-Repository in das Redmine-`plugins`-Verzeichnis:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Installieren Sie aus dem Redmine-Stammverzeichnis die Abhängigkeiten und starten Sie die Anwendung neu:

```bash
cd /path/to/redmine
bundle install
```

Starten Sie Redmine neu.

### 2. In der Administration aktivieren

**Administration → Plugins → Redmine MCP → Konfigurieren**

| Parameter | Beschreibung |
|---------|-------------|
| MCP aktivieren | Aktiviert den Endpunkt `/mcp`. Bei Aktivierung werden MCP-Erweiterungen installierter Plugins geladen |
| Nur-Lese-Modus | Blockiert Schreib-Tools und Schreibaktionen (create/update/delete usw.) |
| MCP-Erweiterungen | Checkboxen zur Aktivierung der MCP-Integration installierter Plugins |

### 3. REST API

**Administration → Konfiguration → API** — „REST-Schnittstelle aktivieren“ aktivieren.

### 4. Berechtigungen

**Administration → Rollen und Rechte** — für die erforderlichen Rollen manuell die globale Berechtigung **MCP verwenden** (`use_mcp`) aktivieren. Redmine-Administratoren haben immer MCP-Zugriff.

### 5. Benutzer-API-Schlüssel

Jeder Benutzer, der über MCP arbeiten soll, benötigt einen API-Schlüssel:

**Mein Konto → API-Zugriffsschlüssel** (oder über die Benutzer-REST-API).

Den Schlüssel im Header übergeben:

```
X-Redmine-API-Key: <your_key>
```

## MCP-Client verbinden

Der Server verwendet **Streamable HTTP** (stateless). Endpunkt:

```
https://<your-redmine>/mcp
```

Unterstützte Methoden: `GET`, `POST`, `DELETE`.

### Beispiel für Cursor

Fügen Sie in den MCP-Einstellungen (`.cursor/mcp.json` oder die globale Konfiguration) einen Server mit HTTP-Transport hinzu. Das genaue Format hängt von der Client-Version ab; ein typisches Beispiel:

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

Nach der Verbindung ruft der Client `initialize` auf und kann anschließend `tools/list`, `tools/call`, `resources/list`, `prompts/list` usw. aufrufen.

### Manuelle Prüfung

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

Eine erfolgreiche Antwort enthält `serverInfo.name: "redmine_mcp"`.

### Host und Reverse Proxy

Der MCP-Transport validiert HTTP `Host` und `Origin` zum Schutz vor DNS rebinding.

Der erlaubte Host wird aus der Redmine-Einstellung übernommen:

**Administration → Konfiguration → Allgemein → Hostname**

Der Wert muss mit der öffentlichen Redmine-URL übereinstimmen.

Wenn Redmine beispielsweise erreichbar ist unter:

```
https://redmine.example.com
```

sollte in der Einstellung verwendet werden:

```
redmine.example.com
```

Läuft Redmine hinter einem Reverse Proxy, muss der Proxy den ursprünglichen `Host`-Header des Clients weiterleiten.

Stimmt der Host nicht überein, kann der MCP-Endpunkt HTTP `403 Forbidden` zurückgeben.

Clients ohne `Origin`-Header sind von der Origin-Prüfung nicht betroffen.

## Eingebaute Tools (Core-Tools)

Vollständige Namen haben das Format `redmine_<tool_name>` (zum Beispiel `redmine_get_issue`).

Der Server stellt Tools für Projekte, Vorgänge, Benutzer, Zeiterfassung, Wiki, Foren und Dateien bereit. Die folgende Liste ist eine kurze Übersicht der eingebauten Tools. Vollständige Eingabeschemas und Beschreibungen stehen dem MCP-Client über `tools/list` zur Verfügung.

### Allgemeine Parameter

- `project` — Projekt-String-ID oder Kennung.
- `assignee_ref` / `user_ref` mit dem Wert `me` — der aktuelle Benutzer.
- `assigned_to_id` — Benutzer oder Gruppe, der/die die Zuweisung erhält; `null` leert optionale Felder.
- `create_time_entry` erfordert `project` oder `issue_id`.
- `upload_file` erfordert `filename` und `content_base64`.

### Zuverlässigkeit von Operationen

- `expected_updated_at` — bei sensiblen Update-/Delete-Operationen.
- `idempotency_key` — bei `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Beschränkungen

- 60 s Lese-Timeout;
- 120 Anfragen/Min pro Benutzer;
- MCP-Anfrage-HTTP-Body bis 36 MiB;
- Tool-JSON-Args bis 32 MiB;
- Base64-Anhänge bis 20 MiB;
- Anhang-Downloads bis 10 MiB.

### Produktionsbetrieb

Rate Limiting und Idempotenz verwenden `Rails.cache`.

Für Installationen mit mehreren Anwendungs-Workern oder mehreren Redmine-Instanzen sollte ein gemeinsamer Cache-Store verwendet werden.

Bei einem prozesslokalen Cache gelten Rate-Limiting- und Idempotenzgarantien nur innerhalb eines einzelnen Anwendungsprozesses.

### Projektmanagement

| Tool | Beschreibung |
|------|-------------|
| `list_projects` | Projekte auflisten |
| `get_project` | Projektdetails |
| `list_project_issue_custom_fields` | Benutzerdefinierte Vorgangsfelder des Projekts |
| `summarize_project_status` | Vom Server erstellte Projektmetrik-Zusammenfassung für N Tage |
| `list_project_activities` | Projektaktivitäts-Feed (Ereignisse, keine Zeitbuchungs-Aktivitätstypen) |
| `list_versions` | Roadmap-Versionen (Meilensteine) |
| `get_version` | Roadmap-Versionsdetails mit Aggregationen |
| `create_version` | Version erstellen |
| `update_version` | Version aktualisieren |
| `delete_version` | Version löschen |
| `list_project_members` | Projektmitglieder und ihre Rollen |
| `list_project_member_candidates` | Benutzer und Gruppen, die zum Projekt hinzugefügt werden können |
| `list_roles` | Im Projekt verwaltbare Rollen |
| `get_project_modules` | Aktivierte Projektmodule |
| `add_project_member` | Mitglied hinzufügen |
| `update_project_member` | Mitgliedsrollen ändern |
| `remove_project_member` | Mitglied entfernen |

### Vorgänge

| Tool | Beschreibung |
|------|-------------|
| `get_issue` | Vorgangsdetails (Journal, Anhänge, benutzerdefinierte Felder usw.) |
| `list_issues` | Vorgänge mit Filtern und Paginierung auflisten |
| `search_issues` | Textsuche über Vorgänge |
| `run_issue_query` | Gespeicherte Vorgangsabfrage ausführen |
| `get_issue_form_options` | Zulässige Werte der Vorgangsformularfelder (ein Aufruf) |
| `validate_issue_create` | Vorgangserstellungs-Parameter ohne Schreiben validieren |
| `validate_issue_update` | Vorgangsaktualisierungs-Parameter ohne Schreiben validieren |
| `create_issue` | Vorgang erstellen |
| `update_issue` | Vorgangsattribute und Anhänge aktualisieren |
| `add_issue_note` | Kommentar zu einem Vorgang hinzufügen (optional mit Anhängen) |
| `delete_issue` | Vorgang mit Bestätigung löschen |
| `copy_issue` | Vorgang kopieren |
| `list_issue_relations` | Vorgangsbeziehungen auflisten |
| `create_issue_relation` | Beziehung zwischen Vorgängen erstellen |
| `delete_issue_relation` | Vorgangsbeziehung löschen |
| `list_subtasks` | Unteraufgaben |
| `add_issue_watcher` | Beobachter hinzufügen |
| `remove_issue_watcher` | Beobachter entfernen |
| `update_issue_note` | Journaleintrag bearbeiten |
| `set_issue_note_private` | Privatsphäre des Journaleintrags ändern |
| `get_private_notes` | Nur private Kommentare |
| `list_issue_categories` | Vorgangskategorien des Projekts |
| `create_issue_category` | Kategorie erstellen |
| `update_issue_category` | Kategorie aktualisieren |
| `delete_issue_category` | Kategorie löschen |

### Benutzer

| Tool | Beschreibung |
|------|-------------|
| `list_users` | Projektmitglieder; Filter `query` (Name/Login) und `login`; globale Suche nur für Administratoren |
| `list_groups` | Givable-Gruppen für `group_id` in `add_project_member` |

### Zeiterfassung

| Tool | Beschreibung |
|------|-------------|
| `list_time_entries` | Zeiteinträge auflisten |
| `create_time_entry` | Zeiteintrag erstellen |
| `update_time_entry` | Zeiteintrag aktualisieren |
| `list_time_entry_activities` | Aktivitätstypen für Zeitbuchungen (nicht der Projekt-Ereignis-Feed) |
| `import_time_entries` | Massenimport von Zeiteinträgen |

### Referenzdaten

| Tool | Beschreibung |
|------|-------------|
| `list_trackers` | Alle Tracker |
| `list_project_trackers` | Projekt-Tracker |
| `list_issue_statuses` | Vorgangsstatus |
| `list_issue_priorities` | Vorgangsprioritäten |
| `admin_list_users` | Benutzer mit Filtern (nur Administrator) |
| `get_current_user` | Aktueller Benutzer |
| `list_queries` | Gespeicherte Abfragen (Metadaten; Ausführung über `run_issue_query`) |

### Suche und Wiki

| Tool | Beschreibung |
|------|-------------|
| `search_all` | Suche in Vorgängen und Wiki-Seiten |
| `list_wiki_pages` | Wiki-Seiten des Projekts |
| `get_wiki_page` | Wiki-Seite abrufen |
| `create_wiki_page` | Wiki-Seite erstellen |
| `update_wiki_page` | Wiki-Seite aktualisieren |
| `delete_wiki_page` | Wiki-Seite löschen |
| `rename_wiki_page` | Wiki-Seite umbenennen |

### Foren

| Tool | Beschreibung |
|------|-------------|
| `list_boards` | Foren-Boards des Projekts |
| `list_board_topics` | Themen des ausgewählten Boards |
| `get_board_message` | Forumsnachricht mit kurzen Antworten |

### Dateien

| Tool | Beschreibung |
|------|-------------|
| `list_project_files` | Projektdateien |
| `upload_file` | Datei hochladen |
| `delete_attachment` | Anhang löschen |
| `get_attachment` | Anhang-Metadaten und `content_url` |
| `download_attachment` | Anhang-Inhalt (`content_base64`, bis 10 MiB) |

### Hilfsfunktionen

| Tool | Beschreibung |
|------|-------------|
| `get_mcp_info` | MCP-Plugin-Version, Nur-Lese-Modus, aktueller Benutzer und verfügbare Capabilities |

### Zugriff und Antworten

Tools geben ein JSON-Envelope in `structuredContent` und eine Textdarstellung in `content` zurück.

Schreiboperationen werden durch die Einstellung **Nur-Lese-Modus** blockiert.

Zusätzlich zu den tool-spezifischen Berechtigungen wird immer die globale Berechtigung **MCP verwenden** geprüft.

Der Datenzugriff wird über standardmäßige Redmine-Berechtigungen und Sichtbarkeitsregeln erzwungen. Für Projekt- und Vorgangsdaten werden `Project.visible` und `Issue.visible` verwendet.

## Erweiterungen von anderen Plugins

Jedes installierte Redmine-Plugin kann eigene MCP-Tools hinzufügen und bei Bedarf Resources, Prompts und Capabilities registrieren.

Für Plugins, die nicht geändert werden können, liegen eingebaute Integrationen in `redmine_mcp/lib/redmine_mcp/extensions/` und registrieren sich über dieselbe Extension API.

Ausführliche Anleitung: [extension_guide.md](extension_guide.md).

Für die AI-gestützte Entwicklung in Cursor oder ähnlichen Agenten kopieren Sie das mitgelieferte Skill-Verzeichnis [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) in den Skills-Ordner Ihres Agenten oder verwenden Sie es als Grundlage für ein eigenes Skill.

Beim Aufruf des Skills können Sie in der Eingabe angeben, ob die Integration über das Ziel-Plugin (`mcp.rb`) oder als eingebaute Integration in `redmine_mcp` (`lib/redmine_mcp/extensions/`) erfolgen soll. Wenn Sie nichts angeben, wählt der Agent den Pfad.

## Protokollierung

Nachrichten werden in das standardmäßige Rails-Log mit dem Präfix `[redmine_mcp]` geschrieben:

- Laden von Erweiterungen
- Registrierung von Tools/Resources/Prompts
- Registrierungs- und Ausführungsfehler
- Zugriffsverweigerungen

## Fehlerbehebung

| Symptom | Mögliche Ursache |
|---------|------------------|
| HTTP 503 „MCP is disabled“ | MCP ist in den Plugin-Einstellungen nicht aktiviert |
| HTTP 401 | Fehlender oder ungültiger API-Schlüssel; REST API ist deaktiviert |
| HTTP 403 (Berechtigung) | Der Benutzer hat nicht die Berechtigung **MCP verwenden** |
| HTTP 403 (`Host`/`Origin`) | **Hostname** stimmt nicht mit der öffentlichen Redmine-URL überein; Reverse Proxy leitet den ursprünglichen `Host` nicht weiter; MCP-URL im Client stimmt nicht überein — Transport lehnt unbekannte Hosts ab (DNS-rebinding-Schutz) |
| Tool ist in `tools/list` nicht sichtbar | Fehlende erforderliche Berechtigungen; die Erweiterung, die das Tool bereitstellt, ist deaktiviert |
| Neue Tools erschienen nach MCP-Reload nicht | In Cursor und ähnlichen Clients aktualisiert ein Server-Reload die Tool-Liste möglicherweise nicht — Anwendung vollständig neu starten |
| Erweiterung wird nicht geladen | Fehlende `lib/.../mcp.rb` oder `lib/redmine_mcp/extensions/<plugin.id>.rb`; Modul macht nicht `extend RedmineMcp::ExtensionApi`; sicherstellen, dass die Erweiterungs-Checkbox unter **MCP-Erweiterungen** aktiviert ist; bei Fehler in der Datei Log prüfen |
| `Issue not found` / `Project not found` | Der Vorgang oder das Projekt ist für den aktuellen Benutzer nach den Redmine-Sichtbarkeitsregeln nicht sichtbar |

## Lizenz

Dieses Plugin steht unter der GNU General Public License,
Version 2 oder einer späteren Version.

Details siehe [LICENSE](../../../LICENSE).
