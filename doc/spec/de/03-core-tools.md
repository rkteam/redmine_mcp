# Eingebaute Tools (Core-Tools)

[Deutsch](03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Überblick

Das Redmine-MCP-Plugin stellt eine Reihe von Tools für die Arbeit mit Redmine-Projekten, Vorgängen, Zeiterfassung, Wiki, Foren, Dateien und Referenzdaten bereit (Lesen und Schreiben).

## Ziel

AI-Clients erhalten Projektmanagement, Vorgangsoperationen, Zeiterfassung, Entdeckung, Suche & Wiki, Foren, Dateioperationen und Meta-Operationen, ohne zusätzliche Plugins zu installieren.

## Betroffene Gebiete

- Projekte
- Versionen
- Mitglieder / Rollen
- Probleme (CRUD, Beziehungen, Beobachter, Notizen, Kategorien, Formularoptionen, Probelaufvalidierung, gespeicherte Abfragen)
- Zeiteinträge
- Tracker, Status, Prioritäten, Abfragen
- Projektaktivität
- Wiki-Seiten
- Foren / Nachrichten
- Projektdateien/Anhänge
- Benutzer
- Berechtigungen
- Einstellungen (schreibgeschützter Modus)

## Geschäftsregeln

### Allgemeine Regeln

- Vollständiger Toolname: `redmine_<name>` (zum Beispiel `redmine_get_issue`).
- Das Ergebnis wird als JSON-Umschlag in `structuredContent` zurückgegeben und als Text in `content` dupliziert.
- Daten werden durch Sichtbarkeit und Berechtigungen von Redmine-Projekten/-Vorgängen gefiltert.
- Der Parameter `project` ist eine Zeichenfolge: numerische ID als Zeichenfolge (z. B. `"1"`) oder Projektkennung (z. B. `"ecookbook"`).
- Wenn der **Schreibgeschützte Modus** aktiviert ist, geben Schreibtools einen Fehler zurück. Schreibgeschützte Tools, einschließlich `list_issue_relations`, `get_issue_form_options`, `validate_issue_create` und `validate_issue_update`, bleiben weiterhin verfügbar.

### Projektmanagement

| Tool | L/S | Berechtigung |
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

### Vorgangsoperationen

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | Attribute — wenn bearbeitbar; `uploads` nur — wenn Anhänge hinzugefügt werden können |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` erfordert zusätzlich `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` für das Quellprojekt und `add_issues` für das Ziel |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | Journaleintrag ist sichtbar und bearbeitbar (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` erfordert zusätzlich `set_notes_private` |
| `set_issue_note_private` | W | Journaleintrag ist sichtbar und bearbeitbar, plus `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Benutzer

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; ohne `project` – nur Administrator |
| `list_groups` | R | `manage_members` (für jedes Projekt) oder admin |

### Zeiterfassung

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | Eintrag kann vom aktuellen Benutzer bearbeitet werden (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

`list_time_entry_activities` — Katalog der Arbeitsaktivitätstypen für die Zeiterfassung, nicht der Projekt-Ereignisfeed (`list_project_activities`).

### Entdeckung / Aufzählung

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `admin_list_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Suche & Wiki

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `search_all` | R | Zugriff auf mindestens einen der durchsuchten Typen (`view_issues` und/oder `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; historische `version` erfordert zusätzlich `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` und die Seite muss bearbeitbar sein |
| `update_wiki_page` | W | `edit_wiki_pages` und die Seite muss bearbeitbar sein |
| `delete_wiki_page` | W | `delete_wiki_pages` und die Seite muss bearbeitbar sein |
| `rename_wiki_page` | W | `rename_wiki_pages` und die Seite muss bearbeitbar sein |

### Foren

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Dateioperationen

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files` (oder Container-Berechtigungen) |
| `get_attachment` | R | Berechtigungen für den Anhangscontainer |
| `download_attachment` | R | Berechtigungen für den Anhangscontainer |

### Meta

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` gibt Metadaten des MCP-Plugins der aktuellen Sitzung zurück, nicht die Redmine-Anwendungsversion oder -Einstellungen: `server_version` (MCP-Plugin-Version), `read_only_mode`, `auth_mode`, kurze aktuelle Benutzerdaten und `capabilities.issue_search`. Die Plugin-Installation von Drittanbietern wird in der Antwort nicht aufgeführt: Ihre MCP-Tools sind über `tools/list` und über `capabilities` sichtbar, die Erweiterungen selbst registrieren.

Kanonischer vollständiger Name — `redmine_get_mcp_info`. Der frühere Name `get_server_info` (`redmine_get_server_info`) bleibt mindestens bis zur nächsten Major-Version ein aufrufbarer Alias: gleiche Berechtigungen, Eingabe, Ausgabe und Verhalten; `tools/call` mit dem alten Namen führt dieselbe Operation aus; der Alias wird nicht in `tools/list` veröffentlicht; Alias-Aufrufe sind im Audit-Log am aufgerufenen Tool-Namen unterscheidbar. Verweise aus anderen Tools verwenden den kanonischen Namen.

`capabilities.issue_search` enthält Suchmodi:

| Modus | Standard | Hinweis |
|------|---------|------|
| `keyword` | `available: true`, Tool `redmine_search_issues` | Immer |
| `cross_resource` | `available: true`, Tool `redmine_search_all` | Immer |
| `semantic` | `available: false` | Plugins können via `register_capability(:issue_search, :semantic)` überschreiben |

Wenn `semantic.available: true` lautet, MUSS die Funktion `tool`, `provider` und `use_when` / `avoid_when` enthalten – kurze Hinweise, wann die semantische Suche ausgewählt werden sollte. `Registry#apply_capabilities` normalisiert die Antwort des Anbieters: Wenn der Vertrag verletzt wird, wird `{ available: false }` veröffentlicht.

### Klarstellungen

- `delete_issue` ohne `confirm_delete` gibt eine Auswirkungsvorschau zurück; Wenn es **irgendwelche** Unteraufgaben gibt (einschließlich derjenigen, die für den Benutzer unsichtbar sind), ist `confirm_delete_with_children` erforderlich. Zähler in `impact` decken nur Journale, Beziehungen, Zeiteinträge, untergeordnete Elemente und Anhänge ab, die für den aktuellen Benutzer sichtbar sind.
- `search_issues` mit `scope=subprojects` erfordert `project` und sucht in diesem Projekt und seinen Nachkommen. Ohne `project` ist dieser Bereich ein Parameterfehler. `scope=my_project` beschränkt die Suche auf Projekte, bei denen der Benutzer Mitglied ist.
- `get_issue`: Journale, Anhänge, Beobachter, Beziehungen, untergeordnete Felder und benutzerdefinierte Felder werden nur mit explizitem `include_*` eingebunden. Verschachtelte Listen haben ein separates `limit`/`offset` und ein `*_pagination`-Feld (Zeitschriften: Standardlimit 25, maximal 100; andere verschachtelte Listen: Standard und maximal 100). Ohne das entsprechende `include_*` ist die Liste leer und die Paginierung ist `null`. Optionale Felder (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) sind in der Antwort immer vorhanden. Benutzerdefinierte Felder – nur diejenigen, die für den aktuellen Benutzer sichtbar sind. Zeitschriften – gleiche Sichtbarkeit wie der Heftverlauf in Redmine: Ein Eintrag erscheint in `journals` und `journal_pagination` nur, wenn er Text oder mindestens eine Detailänderung enthält, die für den Benutzer sichtbar ist. Text, der nur aus Leerzeichen, Tabulatoren oder Zeilenumbrüchen besteht, wird als leer behandelt. Leere Einträge und Einträge mit nur versteckten Details (einschließlich versteckter benutzerdefinierter Felder) werden sowohl von der Liste als auch von `total_count` / `offset` / `has_more` ausgeschlossen. Private Kommentare – eigene Kommentare oder mit der Berechtigung `view_private_notes`. Journalelemente enthalten nur sichtbare Detailänderungen. Beziehungen – nur Links, bei denen beide Seiten für den Benutzer sichtbar sind. Die gleiche Sichtbarkeitsregel für Beziehungen gilt für `list_issue_relations`.
- `get_private_notes` gibt nur private Kommentare mit nicht leerem Text zurück (Leerzeichen, Tabulatoren und Zeilenumbrüche ohne anderen Inhalt zählen als leerer Text). Die Seite wird durch `limit`/`offset` begrenzt, ohne dass der vollständige Problemverlauf geladen wird.
- `list_project_issue_custom_fields` gibt Felder zurück, die für den Benutzer im Projekt sichtbar sind. Wenn `tracker_id` gesetzt ist, muss der Tracker zum Projekt gehören.
- `copy_issue` erfordert die Berechtigung zum Kopieren von Vorgängen im **Quellprojekt** und die Berechtigung zum Erstellen von Vorgängen im **Ziel**. Beobachter werden nur kopiert, wenn der Benutzer die Berechtigung zum Hinzufügen von Beobachtern zum Zielprojekt hat. Der Link zum Original und das Kopieren des Anhangs folgen den Redmine-Einstellungen `link_copied_issue` und `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Ohne Feldüberschreibungen durchläuft die Kopie weiterhin die Formularschreibregeln. Das übergeordnete Problem des Quellproblems bleibt erhalten, wenn dies zulässig ist (auch beim Kopieren innerhalb desselben Projekts).
- `create_issue_relation` wendet nur zulässige Beziehungsattribute an und schreibt die Änderung in das Ausgabejournal. `delete_issue_relation` ist nur zulässig, wenn die Beziehung vom aktuellen Benutzer gelöscht werden kann (beide Probleme sind sichtbar und der Benutzer hat die Berechtigung, Beziehungen auf mindestens einer Seite zu verwalten); Die Löschung wird ebenfalls in das Journal geschrieben.
- `add_project_member` / `update_project_member` akzeptiert nur Rollen, die der aktuelle Benutzer im Projekt verwalten kann. Eine Rolle außerhalb dieser Menge wird abgelehnt; Rollen werden teilweise nicht zugewiesen.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` ist eine Principal-ID (Benutzer oder Gruppe), nicht nur ein Benutzer.
- `delete_attachment` für einen Issue-Anhang folgt der Regel „Können Anhänge zu diesem Issue gelöscht werden“ (einschließlich eigener Issues und Tracker-Berechtigungen), nicht nur global `edit_issues`. In `tools/list` ist das Tool sichtbar, wenn der Benutzer mindestens einen Anhang (Projektdateien, Issues oder Wiki) löschen darf, nicht nur mit globalen `manage_files`.
- `get_wiki_page`: `attachments` ist immer in der Antwort; standardmäßig `[]` und `attachments_pagination: null`; mit `include_attachments=true` – eine paginierte Anhangsliste mit `attachment_limit`/`attachment_offset` (Standard und maximal 100). Für die historische `version` ist die Berechtigung zum Anzeigen von Wiki-Änderungen erforderlich. Das Ändern, Umbenennen oder Löschen einer geschützten Seite erfordert die Erlaubnis zum Schutz von Wiki-Seiten.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: standardmäßig Zusammenfassungsfelder; vollständige Beschreibung über `fields` oder `get_issue`.
- Issue-Objekte von `get_issue`, `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`, `create_issue`, `update_issue` und `copy_issue` enthalten `url` — einen absoluten Web-UI-Link. Der Host stammt aus den Redmine-Einstellungen „Hostname und Pfad“ und dem Protokoll, wie in E-Mails. Wenn „Hostname und Pfad“ leer ist, ist `url` `null` statt eines defekten Links. Die Summary von list/search enthält `url` standardmäßig. `search_all`-Einträge mit `type` `issues` und verschachtelte `children` in `get_issue` enthalten ebenfalls `url`. Beim Zitieren eines Tickets kopiert der Client `url` aus dem Tool-Ergebnis.
- `create_issue` und `update_issue` akzeptieren explizite Problem-**Attribute** (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields` usw.). Alle beim Erstellen explizit übergebenen Attribute, einschließlich `subject` und `description`, durchlaufen dieselben Schreibregeln wie das Redmine-Webformular. Vor dem Erstellen/Aktualisieren SOLLTE der Agent `get_issue_form_options` aufrufen, wenn die zulässigen Feldwerte unbekannt sind. Ein explizit übergebener Wert, den Redmine nicht angewendet hat, führt zu einem Fehler und nicht zu einem Teilerfolg.
- Wenn der Client `start_date` in `create_issue` / `validate_issue_create` **nicht übergeben** hat und Redmine „Startdatum = Erstellungsdatum“ aktiviert hat (`default_issue_start_date_to_creation_date`), setzt MCP `start_date` auf den heutigen Tag des Benutzers – wie das neue Ausgabeformular. Ein explizites `start_date` (einschließlich `null`) deaktiviert diese Ersetzung. `copy_issue` und `update_issue` ersetzen nicht das Datum selbst.
- `update_issue` akzeptiert keine `notes`, `private_notes` oder `watcher_user_ids`. Kommentare – `add_issue_note`; Beobachter – `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` unterstützt auch `uploads` zum Anhängen von Dateien an ein Problem. Anhänge werden erst nach erfolgreicher Attributvalidierung verarbeitet (einschließlich `rejected_fields`). Ein Aufruf nur mit `uploads` (keine Attribute) ist zulässig, wenn der Benutzer Anhänge zum Problem hinzufügen kann – auch wenn das Kommentieren erlaubt ist, Attribute aber nicht bearbeitet werden können. Der optionale `idempotency_key` schützt vor Wiederholungsversuchen nach einer verlorenen Antwort (einschließlich des erneuten Hochladens derselben Dateien). `journal_id` in der Antwort ist der Journaleintrag für **diesen** Aufruf, nicht der letzte Ausgabeeintrag.
- Um ein optionales Feld zu löschen, übergeben Sie `null` für `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` oder `estimated_hours`. Gleiches gilt für `update_version.due_date` / `wiki_page_title` und `update_issue_category.assigned_to_id`.
- `create_issue` unterstützt keine `uploads`.
- `update_issue` akzeptiert `uploads[*].content_base64` und `uploads[*].filename`. Nach einem erfolgreichen Upload enthält die Antwort `added_attachments` – nur Dateien aus diesem Aufruf, nicht die vollständige Liste der Problemanhänge. Beschädigtes Base64 ist ein Parameterfehler.
- `update_issue` akzeptiert `status_name` und löst ihn in `status_id` auf.
- `upload_file` akzeptiert `content_base64` (bis zu 20 MiB); `project`, `filename` und `content_base64` sind erforderlich.
- `get_attachment` gibt `attachment_id`, `filename`, `content_type`, `size` (Dateigröße des Anhangs) und `content_url` (ohne Dateibytes) zurück. Wenn „Hostname und Pfad“ leer ist, ist `content_url` `null`.
- `download_attachment` gibt `attachment_id`, `filename`, `content_type`, `size` (tatsächliche Inhaltsgröße in Bytes) und `content_base64` für einen einzelnen Anhang zurück, der für den aktuellen Benutzer sichtbar ist. Wenn MIME unbekannt ist – `application/octet-stream`. Erhöht den `downloads`-Zähler nicht. Die Größenbeschränkung beträgt 10 MiB (überprüft `File.size` auf der Festplatte vor dem Lesen und `bytesize` nach dem Lesen); wenn überschritten – `FILE_TOO_LARGE`. Server-Dateisystempfade werden in der Antwort nicht zurückgegeben. `attachment_id` kommt von `redmine_get_issue` / `redmine_get_wiki_page` mit `include_attachments=true`, `redmine_list_project_files` oder `redmine_get_attachment`. Um einen Anhang als Datei zu lesen, zu analysieren oder zu verarbeiten, dekodieren Sie `content_base64` lokal. Nicht vorhandene und unzugängliche Anhänge geben die gleiche Antwort „nicht gefunden“ zurück.
- `create_time_entry` und Elemente von `import_time_entries.entries` erfordern `hours` und entweder `project` oder `issue_id`. `hours` kann 0 sein; Gültigkeit von Null und Tagesmaximum werden von Redmine geprüft (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` bei Issue-Erstellung/-Aktualisierung ist eine Prinzipal-ID (Benutzer oder Gruppe aus `get_issue_form_options.assignees`); `null` löscht den Beauftragten. Für `add_issue_watcher` / `remove_issue_watcher` ist die kanonische Eingabe `principal_id` (Benutzer oder Gruppe). Der frühere `user_id` wird als Alias für dieselbe ID akzeptiert; beide können nicht gleichzeitig übergeben werden. Die Antwort enthält `principal_id` und ein Duplikat `user_id` mit demselben Wert. In anderen Tools ist `user_id` eine Benutzer-ID. Verwenden Sie für den aktuellen Benutzer `assignee_ref` oder `user_ref` mit dem Wert `me`.
- `expected_updated_at` (optional) bei sensibler Aktualisierung/Löschung: Wenn es nicht mit `updated_on` übereinstimmt, wird `CONFLICT` zurückgegeben.
- `idempotency_key` (optional) für `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: Ein Wiederholungsversuch mit demselben Schlüssel und **dem gleichen Argumentsatz** (außer dem Schlüssel selbst) gibt das zwischengespeicherte erfolgreiche Ergebnis zurück (TTL 24 h). Derselbe Schlüssel mit einer anderen Nutzlast – `CONFLICT`, kein doppelter Schreibvorgang. Während die erste Anfrage noch läuft, führt ein erneuter Versuch mit demselben Schlüssel nicht zu einem weiteren Schreibvorgang (die Markierung „in Bearbeitung“ bleibt die gleichen 24 Stunden bestehen wie ein erfolgreiches Ergebnis). Ein zwischengespeicherter Eintrag ohne Fingerabdruck (Cache von vor dieser Version) mit demselben Schlüssel wird wie zuvor zurückgegeben, bis TTL abläuft. Für **Lesevorgänge** gilt ein Server-Timeout von 60 s. Schreibvorgänge werden nicht durch Server-Timeout unterbrochen, sodass nach einer erfolgreichen Speicherung das Idempotenzergebnis aufgezeichnet werden kann; Der Client kann es mit demselben Schlüssel erneut versuchen, wenn die Verbindung unterbrochen wurde. Eine unerwartete Ausnahme in `import_time_entries` führt dazu, dass bereits in diesen Aufruf eingefügte Einträge zurückgesetzt werden. Normale Validierungsfehler für einzelne Zeilen werden weiterhin erfasst, ohne dass erfolgreiche Validierungsfehler rückgängig gemacht werden können.
- `delete_attachment` löscht standardmäßig nur Projekt-/Versionsdateien; für Issue-/Wiki-Anhänge ist `confirm_delete_any_attachment=true` erforderlich. Kanonischer vollständiger Name — `redmine_delete_attachment`. Der frühere Name `delete_file` (`redmine_delete_file`) bleibt mindestens bis zur nächsten Major-Version ein aufrufbarer Alias: gleiche Berechtigungen, Eingabe, Ausgabe und Verhalten; `tools/call` mit dem alten Namen führt dieselbe Operation aus; der Alias wird nicht in `tools/list` veröffentlicht; Alias-Aufrufe sind im Audit-Log am aufgerufenen Tool-Namen unterscheidbar. Verweise aus anderen Tools verwenden den kanonischen Namen.
- Liste/Suche verwenden `limit`/`offset`. Bei DB-Abfragen wird die Seite auf Abfrageebene eingeschränkt, nicht durch Beschneiden einer bereits geladenen vollständigen Liste. Jede paginierte MCP-Sammlung hat eine explizite stabile Reihenfolge; Das letzte Kriterium ist immer `id`, damit Seiten keine Elemente überspringen oder duplizieren.
- Die Teilzeichenfolgensuche (`query`, `login`, `name` und der Text `search_issues`) entspricht den Zeichen wörtlich: `%` und `_` sind keine SQL-Platzhalter.
- MCP-Grenzwerte: Timeout 60 s bei Lesetools, Ratenlimit 120 Anfragen/Minute pro Benutzer, MCP-Anfrage-HTTP-Körper 36 MiB, maximale Größe der JSON-Tool-Argumente 32 MiB, Base64-Upload bis zu 20 MiB, Base64-Download bis zu 10 MiB. Beschädigtes Base64 in jedem `content_base64` ist ein Parameterfehler vor der Ausführung des Tools.
- Jeder Tool-Aufruf, einschließlich Zugriffsverweigerung, wird in ein strukturiertes Audit-Protokoll geschrieben (Tool, Benutzer, Ziel-IDs, Ergebnis, Dauer, Korrelations-ID) und auf das Ratenlimit angerechnet; Base64-Inhalte und private Notizen werden nicht protokolliert. Zu den Ziel-IDs gehören unter anderem `board_id`, `message_id`, `query_id`, `user_id`, `group_id`.
- Das `outputSchema` jedes Kerntools beschreibt die oberste Ebene von `data` (für Listen – Elementfelder `items`), kein offenes beliebiges Objekt. Der Schemafeldsatz entspricht der tatsächlichen Antwort: `list_users` ohne `created_on`, `admin_list_users` mit `created_on`; `get_attachment` enthält `size` und `content_url`. Felder, die in der echten Antwort möglicherweise leer sind, erlauben `null` (einschließlich `time_entry.issue`, `*_pagination` ohne include, `estimation_accuracy`, Anhang `content_type`). Benutzerdefinierte Feldwerte und `possible_values` sind nicht auf Objekte beschränkt. `attachments_not_saved` ist ein Array von Dateinamen.
- `summarize_project_status.days` im Schema: Standard 30, Minimum 1, Maximum 365.
- `search_all.resources`: höchstens zwei eindeutige Werte.
- `version_id`, `file_id`, `tracker_id` sind Ganzzahlen nicht kleiner als 1.

### `get_project`

- Eingabe: `project` (erforderlich).
- Ausgabe: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (Objekt `id`/`name`/`identifier` oder `null`), `subprojects` (kurze Liste der sichtbaren untergeordneten Projekte: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` wird nur ausgefüllt, wenn das übergeordnete Projekt für den aktuellen Benutzer sichtbar ist; andernfalls `null`.
- Gibt keine Mitglieder, aktivierten Module oder Ausgabestatistiken zurück. Für Module – `get_project_modules`; für Mitglieder – `list_project_members`; für Problemaggregate – `summarize_project_status`.

### `get_issue_form_options`

- Ein Aufruf statt mehrerer Referenzsuchen vor dem Erstellen/Aktualisieren. Separate `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` bleiben verfügbar.
- Eingabe: `project` (erforderlich); optional `tracker_id`, `issue_id`.
- Der Snapshot spiegelt das **Problemformular für den aktuellen Benutzer** wider, nicht die vollständige Projektkonfiguration: dieselben zulässigen Werte, die die Redmine-Benutzeroberfläche bietet.
- `tracker_id` ohne `issue_id` legt den Kontext zum Erstellen des Formulars fest. Der Tracker muss für den aktuellen Benutzer zur Auswahl im Formular verfügbar sein; andernfalls – Parameterfehler.
- `issue_id` legt das Formular für ein vorhandenes sichtbares Problem in diesem Projekt fest. Bei `issue_id` ist `tracker_id` nur zulässig, wenn sie mit dem aktuellen Tracker des Problems übereinstimmt; andernfalls – Parameterfehler (Tracker-Änderung wird nicht durch dieses Tool modelliert).
- Ausgabe – Formular-Snapshot ohne Paginierung:
- `project`: `id`, `name`, `identifier`;
- `trackers`: Tracker, die der aktuelle Benutzer in diesem Formular auswählen kann (`id`, `name`), nicht alle Tracker sind für das Projekt aktiviert;
- `priorities`: aktive Prioritäten (`id`, `name`, `is_default`);
- `categories`: Projektkategorien (`id`, `name`);
- `versions`: Versionen, die in diesem Formular zur Auswahl stehen (`id`, `name`, `status`, `due_date`);
- `assignees`: Auftraggeber, die in diesem Formularkontext zugewiesen werden können. Element: `id`, `name`, `type` (`user` oder `group`); für `user` zusätzlich `login`. Gruppen sind enthalten, wenn Redmine die Problemzuweisung zu Gruppen aktiviert hat;
- `custom_fields`: Nur Felder, die der aktuelle Benutzer im Formular bearbeiten kann, unter Berücksichtigung von Projekt/Tracker, Sichtbarkeit und schreibgeschütztem Workflow. Element: `id`, `name`, `field_format`, `required` (Feld erforderlich oder vom Workflow erforderlich), `readonly` (in dieser Liste immer `false`), `multiple`, `default_value`, `possible_values`, `trackers`. Formularkontext – Ausgabe von `issue_id` oder Erstellen eines Entwurfs unter Berücksichtigung von `tracker_id`;
- `possible_values` — Array von Objekten `{ "label": "...", "value": "..." }`. Bei Listen ohne separate Beschriftung stimmt `label` mit `value` überein. Für Benutzer/Version/Aufzählung ist `label` der Anzeigename, `value` die Kennung;
- `statuses`: vom Workflow für den aktuellen Benutzer zulässige Status. Mit `issue_id` – Übergänge für dieses sichtbare Problem. Ohne `issue_id` – Anfangsstatus für die Erstellung (unter Berücksichtigung von `tracker_id`, falls festgelegt);
- `editable_fields`: Attributnamen, die dieser MCP-Vertrag beim Erstellen/Aktualisieren akzeptiert und die der aktuelle Benutzer im Formular festlegen kann, sowie bearbeitbare benutzerdefinierte Feld-IDs als Zeichenfolgen. Enthält nicht `notes`, `private_notes`, `watcher_user_ids` und andere Webformularfelder, die in den MCP-Schreibtools fehlen;
- `required_fields`: Feldnamen, die in diesem Formular für den aktuellen Benutzer erforderlich sind, im gleichen Namensformat wie `editable_fields`.
- Nicht vorhandene `tracker_id`, Tracker für den Benutzer nicht zulässig oder `issue_id` außerhalb des Projekts / nicht sichtbar – Parameterfehler.

### `add_issue_note`

- Fügt einen Kommentar zu einem vorhandenen sichtbaren Problem hinzu, ohne die Problemattribute zu ändern.
- Eingabe: `issue_id` (erforderlich), `notes` (erforderlich), optional `private_notes`, `uploads` und `idempotency_key`.
- Berechtigung: Der Benutzer kann Kommentare zu diesem Problem hinzufügen. `private_notes=true` erfordert die Erlaubnis, private Kommentare abzugeben; andernfalls – abgelehnt, es wird kein Kommentar erstellt. Anhänge im selben Anruf sind zulässig, wenn der Benutzer dem Problem Anhänge hinzufügen kann.
- Akzeptiert keine Issue-Felder oder Watcher-Listen.
- Ausgabe: `issue_id`, `journal_id`, `notes`, `private_notes`; mit `uploads` – `added_attachments` (nur Dateien aus diesem Aufruf).
- Im schreibgeschützten Modus nicht verfügbar.

### `update_issue_note` / `set_issue_note_private`

- Arbeiten Sie nur mit einem Journaleintrag, den der aktuelle Benutzer **sieht** (auf die privaten Kommentare eines anderen Benutzers ohne die Berechtigung zum Anzeigen privater Notizen kann nicht zugegriffen werden).
- Der Eintrag muss vom aktuellen Benutzer editierbar sein (Berechtigung zum Bearbeiten von Kommentaren oder eigenen Kommentaren).
- `update_issue_note.notes` kann eine leere Zeichenfolge sein (Löschtext eines vorhandenen Eintrags). Ein neuer Kommentar über `add_issue_note` darf nicht leer sein.
- Das Ändern des Datenschutzes (`private_notes` / `is_private`) erfordert eine gesonderte Berechtigung, um Kommentare privat zu machen. Andersfalls abgelehnt, der Text wurde teilweise nicht geändert.
- Zeichnet auf, wer den Journaleintrag bearbeitet hat.
- Im schreibgeschützten Modus nicht verfügbar.

### `validate_issue_create` / `validate_issue_update`

- Separate schreibgeschützte Tools, kein `validate_only`-Parameter bei Schreibtools. Verfügbar im schreibgeschützten Modus.
- `validate_issue_create`: gleiche Felder wie `create_issue`, ohne `idempotency_key`. `project` und `subject` sind erforderlich. Berechtigung `add_issues`.
- `validate_issue_update`: Probelauf nur für **Problemattribute** (wie `update_issue`, ohne `uploads`). `issue_id` ist erforderlich. Das Problem muss vom aktuellen Benutzer bearbeitet werden können. Vor der Validierung wird ein Benutzerjournalkontext ohne DB-Schreibvorgang erstellt (wie bei einem echten Update).
- Verhalten: Attribute auf das Problem anwenden, ohne es zu speichern. Redmine-Daten werden nicht verändert.
- Attribute durchlaufen weiterhin dieselben Schreibregeln wie das Redmine-Webformular. Wenn der Client einen Wert **explizit übergeben** hat und Redmine ihn nicht angewendet hat, handelt es sich um einen MCP-Fehler und nicht um einen Erfolg.
- Ein explizites Feld, das nicht zu den für das Problem beschreibbaren Feldern gehört (deaktiviert/Workflow schreibgeschützt/abgeleitete Daten usw.), wird in `rejected_fields` abgelegt. Für `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` und `custom_fields` wird zusätzlich überprüft, ob der angeforderte Wert tatsächlich angewendet wurde.
- Die gleiche Regel gilt für `create_issue`, `update_issue` und `copy_issue`: kein Schreiben, wenn ein explizit angeforderter Wert nicht angewendet wurde.
- Erfolg: `{ "valid": true, "errors": [] }`.
- Fehler: `{ "valid": false, "errors": ["..."] }`. Wenn einige explizite Felder nicht angewendet wurden – auch `rejected_fields` (Feldnamen, zum Beispiel `["tracker_id"]`) und bei typischen Fehlern `missing_required_fields` / `hint` in der gleichen Form wie bei create/update.
- Außerdem: Der Tracker steht dem aktuellen Benutzer nicht zur Verfügung. Ungültiger oder nicht verfügbarer benutzerdefinierter Feldwert; Statusübergang durch Workflow verboten; Der Beauftragte ist für die Zuweisung nicht verfügbar.

### `list_issues` — erweiterte Filter

- Vorhandene flache Filter (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) bleiben erhalten.
- Optionale `filters`: Array von Objekten `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` ist ein Array von Strings; Für Operatoren ohne Werte ist ein leeres Array zulässig.
- Erlaubte `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id` und `cf_<id>` für benutzerdefinierte Problemfelder.
- Operatoren sind standardmäßige Redmine-Abfrageoperatoren, einschließlich `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. Der Operator muss für den Feldtyp gültig sein; andernfalls – Parameterfehler.
- Unbekanntes `field` oder ungültiger `operator` – Parameterfehler, Abfrage wird nicht ausgeführt.
- Flache Filter und `filters` werden mit UND verknüpft.
- Filter gelten nur für Probleme, die für den aktuellen Benutzer sichtbar sind.

### `run_issue_query`

- Eingabe: `query_id` (erforderlich, aus `list_queries`); optional `project`, `fields`, `limit`/`offset`.
- Führt eine gespeicherte Problemabfrage aus, die für den aktuellen Benutzer sichtbar ist. Das Antwortformat ist derselbe Listenumschlag wie `list_issues`.
- Wenn die Abfrage projektbezogen ist, sind die Ergebnisse auf dieses Projekt (und die Abfragesichtbarkeitsregeln) beschränkt. Das optionale `project` für eine Projektabfrage muss mit dem Projekt der Abfrage übereinstimmen. andernfalls – Parameterfehler.
- Wenn die Abfrage global ist, schränkt das optionale `project` die Auswahl auf das sichtbare Projekt ein.
- Unsichtbare oder nicht vorhandene `query_id` – Fehler.
- `list_queries` führt die Abfrage nicht aus; Verwenden Sie `run_issue_query` zur Ausführung.

### `list_project_activities`

- Dies ist der Projekt-Ereignisfeed („was passiert ist“), nicht der Katalog der Arbeitsaktivitätstypen für die Zeiterfassung. Arbeitsaktivitätstypen — `list_time_entry_activities`.
- Eingabe: `project` (erforderlich); optional `from`, `to` (Daten `YYYY-MM-DD`), `author_id`, `event_types` (Array von Zeichenfolgen), `limit`/`offset`.
- Standardfenster – letzte 7 Tage (`to` = heute, `from` = heute minus 6 Tage). Maximale Fensterlänge – 90 Tage; bei Überschreitung: Parameterfehler.
- Ereignisse aus dem Projektaktivitäts-Feed: Typ, Zeit, Autor (`id`/`name`), `title`, `description`, `url`. Reihenfolge – neuere Ereignisse zuerst; für gleiche Zeit – höhere `id` zuerst.
- Umschlag wie andere `list_*`.
- `event_types` begrenzt Ereignistypen. Ein für den Benutzer nicht verfügbarer oder im Projekt deaktivierter Typ wird (ohne Fehler) von der Auswahl ausgeschlossen.
- Nicht vorhandene `author_id` – leere Liste, kein Fehler.

### `summarize_project_status`

Dies ist kein Redmine-Objekt, sondern eine serverseitige Aggregation über sichtbare Projekt-Issues und Zeiteinträge.

Vorhandene Felder bleiben erhalten: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

Das Fenster `days` (Standard 30, Bereich 1–365) wirkt sich weiterhin auf `recent_activity` und die unten aufgeführten Zeitraummetriken aus. Ein Wert außerhalb des Bereichs wird vom Schema abgelehnt. `totals` und Aufschlüsselungen werden über alle sichtbaren Projektprobleme ohne Datumsfilter über DB-Aggregation berechnet, ohne dass alle Probleme in den Speicher geladen werden. Teilprojekte sind nicht enthalten.

Zusätzliche Felder:

- `overdue_count` – Anzahl der offenen sichtbaren Probleme mit `due_date` genau vor dem heutigen Tag des Benutzers.
- `unassigned_count` – Anzahl der offenen sichtbaren Probleme ohne Beauftragten.
- `stale_issues_count` – Anzahl der offenen sichtbaren Probleme, deren `updated_on` älter als der Beginn des `days`-Fensters ist.
- `issues_closed_during_period` – Anzahl der sichtbaren Probleme mit `closed_on` innerhalb des `days`-Fensters.
- `estimated_hours` – Summe der Schätzungen sichtbarer Projektprobleme (`null`, wenn keine Schätzung vorhanden ist, andernfalls eine Zahl einschließlich 0).
- `spent_hours` – Summe der Zeit, die für sichtbare Projektprobleme aufgewendet wurde (0, wenn keine Einträge vorhanden sind). Erfordert `view_time_entries` für das Projekt; Ohne Erlaubnis ist das Feld `null`.
- `average_resolution_hours` – Durchschnitt `(closed_on - created_on)` in Stunden für Probleme, die im Fenster `days` geschlossen wurden; `null`, wenn keine derartigen Probleme vorliegen.
- `estimation_accuracy` — für im Fenster geschlossene Probleme, die sowohl eine Schätzung als auch eine ungleich Null/protokollierte Zeit haben: `{ "issues_count", "total_estimated", "total_spent" }`. Wenn keine passenden Probleme vorliegen — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Erfordert `view_time_entries` für das Projekt; ohne Erlaubnis ist das Feld `null`.
- `reopened_count` – Anzahl der sichtbaren Ausgaben, deren Journalstatus sich innerhalb des `days`-Fensters von „geschlossen“ zu „offen“ geändert hat. Jede Ausgabe wird höchstens einmal gezählt.

Das Tool liefert Fakten, keine textliche „Projektgesundheitsanalyse“.

### `list_versions` / `get_version`

`Version` in diesen Tools ist eine Redmine-Entität (Roadmap-Stufe / Meilenstein), nicht eine Softwareproduktversion. `list_versions` gibt Roadmap-Versionen des Projekts zurück, einschließlich freigegebener.

### `get_version`

- Eingabe: `version_id` (erforderlich); optional `project`. Wenn `project` festgelegt ist, ist die Version zugänglich, wenn sie sich in den freigegebenen Versionen dieses sichtbaren Projekts befindet (auch wenn das Quellprojekt der Version für den Benutzer nicht sichtbar ist). Ohne `project` muss die Version in ihrem Quellprojekt sichtbar sein.
- Ausgabe: Felder wie ein `list_versions`-Element (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) plus Aggregate: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Aggregate werden nur für Versionsprobleme berechnet, die für den aktuellen Benutzer sichtbar sind.
- Die Vorgangsliste wird nicht zurückgegeben.
- `spent_hours` erfordert `view_time_entries` für das Projekt der Version; ohne Erlaubnis – `null`. Summieren Sie nur sichtbare Versionsprobleme und nur Zeiteinträge, die der aktuelle Benutzer sehen kann (einschließlich `time_entries_visibility=own`).

### Foren

- Das Modul Projektforen muss aktiviert sein; andernfalls Fehler „Boards-Modul ist für dieses Projekt nicht aktiviert“ (Wiki-Analogon).
- Berechtigung `view_messages`. Keine Forum-Schreibvorgänge.
- `list_boards`: `project` erforderlich; Pagination. Element: `id`, `name`, `description`, `parent_id` (`null` für Root-Board), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` erforderlich; Pagination. Nur Stammnachrichten (kein übergeordnetes Element). Element: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` erforderlich. Ausgabe: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` – kurze Antwortliste (`id`, `subject`, `author`, `created_on`) ohne vollständigen Text von jede Antwort, mit `replies_limit`/`replies_offset` (Standard und maximal 100) und `replies_pagination`.
- Unsichtbares Board/Nachricht oder Board aus einem anderen Projekt – Fehler „nicht gefunden“.

### `list_users`

- Mit `project`: aktive **Benutzer**-Projektmitglieder (Berechtigung `view_members`). Die Gruppenmitgliedschaft im Projekt wird nicht als Gruppe angezeigt. Benutzer aus einer Gruppe nur dann, wenn sie selbst Mitglieder sind. Ohne `project` – nur Administrator.
- Element: `id`, `login`, `firstname`, `lastname`, `mail`. Enthält nicht `created_on` (dieses Feld befindet sich in `admin_list_users`).
- Optionale `query`: Teilzeichenfolge ohne Berücksichtigung der Groß- und Kleinschreibung bei `login`, `firstname` und `lastname`.
- Das optionale `login` wird aus Kompatibilitätsgründen beibehalten (nur Login-Teilzeichenfolge). Wenn sowohl `query` als auch `login` gesetzt sind, gelten beide Bedingungen (AND).

### `admin_list_users`

- Globaler Katalog aktiver Benutzer der Installation. Nur Administrator. Für Projektmitglieder und Projektzuweisung `list_users` mit `project` verwenden.
- Eingabe: optional `name` (Teilzeichenfolge ohne Berücksichtigung der Groß-/Kleinschreibung für login, firstname, lastname oder E-Mail), `group_id`, Paginierung.
- Element: `id`, `login`, `firstname`, `lastname`, `mail`, `created_on`.
- Kanonischer vollständiger Name — `redmine_admin_list_users`.
- Der frühere Name `list_all_users` (`redmine_list_all_users`) bleibt mindestens bis zur nächsten Major-Version ein aufrufbarer Alias: gleiche Berechtigungen, Eingabe, Ausgabe und Verhalten; `tools/call` mit dem alten Namen führt dieselbe Operation aus; der Alias wird nicht in `tools/list` veröffentlicht; Alias-Aufrufe sind im Audit-Log am aufgerufenen Tool-Namen unterscheidbar.
- Server-Anweisungen und Verweise aus anderen Tools verwenden den kanonischen Namen.

### `list_project_files`

- Paginierte Liste der Dateien aus dem Projektabschnitt „Dateien“ und Anhänge seiner Versionen. Enthält keine Issue- oder Wiki-Anhänge — diese lesen Sie über `get_issue` / `get_wiki_page` mit `include_attachments`.
- Eingabe: `project` (erforderlich), Paginierung. Berechtigung `view_files`.
- Kanonischer vollständiger Name — `redmine_list_project_files`.
- Der frühere Name `list_files` (`redmine_list_files`) bleibt mindestens bis zur nächsten Major-Version ein aufrufbarer Alias: gleiche Berechtigungen, Eingabe, Ausgabe und Verhalten; `tools/call` mit dem alten Namen führt dieselbe Operation aus; der Alias wird nicht in `tools/list` veröffentlicht; Alias-Aufrufe sind im Audit-Log am aufgerufenen Tool-Namen unterscheidbar.
- Verweise aus anderen Tools verwenden den kanonischen Namen.

### `list_groups`

- Paginierte Liste der vergebbaren Gruppen (`id`, `name`), **sichtbar** für den aktuellen Benutzer, zur Auswahl von `group_id` in `add_project_member`.
- Optionale `query`: Teilzeichenfolge ohne Berücksichtigung der Groß-/Kleinschreibung für den Gruppennamen; `%` und `_` werden wörtlich abgeglichen.
- Berechtigung: Administrator oder `manage_members` für mindestens ein sichtbares Projekt.
- Gruppenmitgliedschaften oder Mitgliedschaften werden nicht zurückgegeben.

### `list_project_member_candidates`

- Kandidaten für das Hinzufügen zum Projekt: aktive sichtbare Benutzer und Gruppen, die noch nicht im Projekt sind.
- Eingabe: `project` (erforderlich); optional `query` (Teilzeichenfolge, wie in der Redmine-Mitgliederauswahl).
- Umschlag der Ausgabeliste: `id`, `name`, `type` (`user` oder `group`); für Benutzer zusätzlich `login`.
- Berechtigung `manage_members` für das Projekt.
- `add_project_member`: `user_id` nur für Benutzer, `group_id` nur für Gruppen. ID vom falschen Typ – Parameterfehler. Übernehmen Sie vor dem Hinzufügen die IDs aus diesem Tool (oder aus `list_users` / `list_groups`, wenn der Kandidat bereits bekannt ist).

### `list_roles`

- Nur Rollen, die der aktuelle Benutzer im angegebenen Projekt verwalten kann.
- Eingabe: `project` (erforderlich).
- Berechtigung `manage_members` für das Projekt.
- Für Administratoren entspricht das Set den zuweisbaren Projektrollen (ohne Nichtmitglied/Anonym).

## Randfälle

- Nicht vorhandenes/nicht zugängliches Projekt oder Vorgang — `{ "error": "..." }`.
- Schreibgeschützter Modus — `{ "error": "MCP is in read-only mode..." }` für Schreibtools **bevor** der Handler aufgerufen wird, einschließlich Erweiterungs-API-Tools; validieren/Formularoptionen/Liste/Get bleiben verfügbar.
- Leere Liste/Suchergebnis – `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Liste/Suche mit Paginierung gibt immer `data.items` und `meta` zurück (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Standardlimit 25, maximal 100.
- Alle `list_*`-Tools (einschließlich Referenzen: Tracker, Status, Rollen, Abfragen, Boards, Board-Themen usw.) verwenden denselben Umschlag. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` und Validierungstools – einzelne Objekte, kein Listenumschlag.
- `download_attachment`: nicht vorhandener und nicht zugänglicher Anhang – derselbe „not found“-Fehler; Datei auf der Festplatte nicht lesbar – Fehler; Größe auf der Festplatte oder nach dem Lesen über 10 MiB – `FILE_TOO_LARGE` (Grenze wird nicht durch eine niedrigere DB-`filesize` umgangen). Dieselbe nicht unterscheidbare Regel „missing / no access“ – für `get_attachment`.
- `list_project_activities`: Fenster länger als 90 Tage – Parameterfehler; `from` nach `to` – Parameterfehler.
- `run_issue_query`: unsichtbare Abfrage – wird als nicht vorhanden behandelt.
- `get_issue_form_options` mit `issue_id` für ein Problem aus einem anderen Projekt – Parameterfehler.
- `get_issue_form_options` mit `issue_id` und `tracker_id`, die nicht mit dem Tracker dieses Problems übereinstimmen – Parameterfehler.
- Validierungstools erstellen kein Problem, aktualisieren kein Problem, erstellen keine Journaleinträge und verbrauchen keinen `idempotency_key`.
- Schreibvorgänge über MCP laufen über Redmine-Modelle. Model-Callbacks werden ausgeführt; Controller-Hooks der Web-Oberfläche werden nicht aufgerufen.

## Fehlerbehandlung

- Fehlende Berechtigung — Tool nicht in `tools/list` sichtbar oder „Permission denied“.
- Modellvalidierungsfehler — `{ "error": "<messages>" }` (für Tools zum Erstellen/Aktualisieren und Validieren von Problemen zusätzlich `missing_required_fields` als Feldnamen aus Modellfehlersymbolen, ohne Übersetzungstext zu analysieren, und `hint`).
- Wiki/Boards-Modul deaktiviert – separate Fehlermeldung, nicht „nicht gefunden“.
- Der kanonische Fehlercode im Umschlag wird explizit vom Handler festgelegt. Der Code wird nicht vom Nachrichtentext abgeleitet und ist nicht von der Benutzersprache abhängig.

## Testszenarien

1. `list_projects` / `list_issues` Rückgabeumschlag `data.items` + `meta` mit Paginierung.
2. `get_issue` ohne `include_*` gibt keine Zeitschriften/Anhänge zurück; mit `include_journals` – Zeitschriften mit Paginierung.
3. `search_issues` nach Text findet Probleme; `search_all` schließt Wiki ein, wenn mehrere Typen durchsucht werden.
4. `create_issue` / `update_issue` mit gültigen Feldern ist erfolgreich; ohne Erlaubnis oder im schreibgeschützten Zustand – Fehler.
4a. `create_issue` ohne `start_date` mit aktivierter Startdatumseinstellung legt das heutige Datum fest; explizites `start_date` oder `null` wird durch diese Einstellung nicht überschrieben.
5. `delete_issue` ohne `confirm_delete` gibt `INVALID_STATE` und Auswirkungen zurück; mit Bestätigung löscht.
6. `create_time_entry` erfordert `hours` und `project` oder `issue_id`; `import_time_entries` akzeptiert einen Stapel.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` funktionieren mit aktiviertem Wiki-Modul.
8. `upload_file` erfordert `filename` und `content_base64`; `delete_attachment` für den Problemanhang erfordert eine Bestätigung.
9. Benutzer ohne `use_mcp` bestehen die MCP-Authentifizierung nicht; Ohne Tool-Berechtigung wird es nicht in `tools/list` angezeigt.
10. Wenn Sie `create_issue` mit demselben `idempotency_key` und denselben Argumenten erneut versuchen, wird kein Duplikat erstellt. Gleicher Schlüssel mit unterschiedlichem Betreff – `CONFLICT`.
11. `download_attachment` für sichtbare Problemanhänge gibt `content_base64` mit der tatsächlichen Inhaltsgröße `size` zurück; für Dateien > 10 MiB auf der Festplatte (auch mit kleinen Metadaten) – `FILE_TOO_LARGE`; nicht vorhandene und unzugängliche Bindung sind nicht zu unterscheiden.
12. `get_project` nach Kennung gibt Beschreibung, Unterprojekte und `last_activity_date` zurück; unzugängliches Projekt – Fehler.
13. `get_issue_form_options` für Projektrückgabe-Tracker/Status/Prioritäten/Kategorien/Versionen/Assignees/Custom_fields und `editable_fields`/`required_fields`-Listen; `trackers` – nur diejenigen, die dem aktuellen Benutzer zur Verfügung stehen; mit `issue_id` spiegeln Status zulässige Übergänge für dieses Problem wider; `issue_id` + andere `tracker_id` – Fehler; `possible_values` – `label`-/`value`-Objekte.
14. `validate_issue_create` mit ungültigem Tracker oder Status gibt `valid: false` und `rejected_fields` zurück, erstellt kein Problem; Im schreibgeschützten Modus ist der Aufruf erfolgreich.
15. `list_issues` mit `filters` (`due_date` `<=` date, `priority_id` `!`) gibt nur passende sichtbare Probleme zurück; unbekanntes `field` – Fehler.
16. `run_issue_query` mit sichtbarer `query_id` gibt dieselben Probleme zurück wie eine gespeicherte Abfrage in der Benutzeroberfläche; Unsichtbare Abfrage – Fehler.
17. `list_project_activities` für 3 Tage gibt Projektereignisse mit Paginierung zurück; 91-Tage-Fenster – Fehler.
18. `summarize_project_status` enthält `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` und `reopened_count`.
19. `get_version` gibt die Aggregate `open_issues_count` / `completed_percent` ohne Problemliste zurück.
20. `list_boards` / `list_board_topics` / `get_board_message` funktionieren mit aktiviertem Boards-Modul; wenn deaktiviert – Modulfehler.
21. `list_users` mit `project` und `query` nach Namen findet Mitglied, ohne die Anmeldung zu kennen.
22. `get_issue_form_options` gibt Beauftragte mit `type` Benutzer/Gruppe und nur bearbeitbare benutzerdefinierte Felder mit `required`/`readonly` zurück.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` mit explizit übergebenem Wert, den Redmine nicht anwendet (einschließlich deaktivierter/schreibgeschützter Kernfelder, einschließlich `description` beim Erstellen) geben einen Fehler zurück und speichern teilweise Änderungen nicht.
24. `validate_issue_update` akzeptiert keine Notizen; Kommentar wird von `add_issue_note` erstellt. `add_issue_note` mit `add_issue_notes` gelingt ohne `edit_issues`; `private_notes` ohne `set_notes_private` – abgelehnt. `update_issue` mit nur `uploads` ist mit der Berechtigung zum Hinzufügen von Anhängen ohne `edit_issues` erfolgreich.
25. `list_groups` gibt vergebbare Gruppen für Benutzer mit `manage_members` zurück.
26. `update_issue` mit `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` löscht das Feld, wenn es beschreibbar ist.
27. `update_issue_note` / `set_issue_note_private` ändern nicht den privaten Kommentar eines anderen Benutzers, wenn der Benutzer nicht berechtigt ist, private Kommentare anzuzeigen.
28. Benutzer mit der Berechtigung, Kommentare zu bearbeiten, aber nicht privat zu machen, können den öffentlichen Kommentartext ändern und die Datenschutzmarkierung nicht ändern.
29. `add_issue_note` mit `uploads` erstellt Kommentar und Anhang in einem Aufruf; Bei einem erneuten Versuch mit demselben `idempotency_key` werden sie nicht dupliziert.
30. `update_issue` mit `uploads` und `idempotency_key`: Bei einem erneuten Versuch mit derselben Nutzlast wird der Anhang nicht dupliziert. andere Datei mit demselben Schlüssel – `CONFLICT`. Beschädigtes Base64 – Parameterfehler.
31. `get_issue` gibt keine versteckten benutzerdefinierten Felder, unsichtbaren Journaldetails oder Beziehungen zu unsichtbaren Problemen zurück. `get_version` aggregiert nur über sichtbare Probleme.
32. `copy_issue` ohne Berechtigung zum Kopieren im Quellprojekt – verweigert, auch mit `add_issues` im Ziel.
33. `add_project_member` / `update_project_member` mit einer Rolle, die der Benutzer nicht verwalten kann – ohne teilweise Zuweisung abgelehnt.
34. `create_version` / `update_version` mit `sharing` für Benutzer nicht zulässig – abgelehnt. `delete_version` für ausgelastete Version – ohne Löschung abgelehnt.
35. Der Autor von Zeiteinträgen mit `edit_own_time_entries` kann seinen eigenen Eintrag über `update_time_entry` aktualisieren.
36. `search_all` steht Benutzern mit Wiki-Berechtigung ohne `view_issues` zur Verfügung, wenn die Suche Wiki umfasst.
37. `list_project_member_candidates` gibt Benutzer und Gruppen zurück, die noch nicht im Projekt sind; `add_project_member` mit der Gruppe `user_id` – Fehler.
38. `list_roles` für Projekte gibt nur Rollen zurück, die der Benutzer verwalten kann; ohne `project` – Schemafehler. Enthält nicht die integrierten Funktionen „Nicht-Mitglied“ und „Anonym“.
39. Wiederholen Sie `copy_issue` / `create_time_entry` mit demselben `idempotency_key`. Es wird kein Duplikat erstellt. unterschiedliche Nutzlast mit demselben Schlüssel – `CONFLICT`.
40. `search_issues` und Benutzer-/Gruppensuche nach `%` oder `_` entsprechen diesen Zeichen wörtlich, nicht als Platzhalter.
41. `get_version.spent_hours` mit `time_entries_visibility=own` zählt nur eigene Zeiteinträge.
42. `search_issues` mit `scope=subprojects` ohne `project` – Fehler; mit `project` findet Probleme in Nachkommen.
43. `list_project_activities` gibt neuere Ereignisse vor älteren zurück.
44. Die Auswirkung von `delete_issue` umfasst keine versteckten Journale, Beziehungen und Zeiteinträge anderer; Versteckte Unteraufgaben erfordern weiterhin `confirm_delete_with_children`.
45. `get_project` gibt kein übergeordnetes Element zurück, das für den aktuellen Benutzer unsichtbar ist.
46. `update_version` mit `due_date`/`wiki_page_title` = `null` löscht das Feld.
47. `update_issue_category` mit `assigned_to_id` = `null` löscht den Standardbeauftragten.
48. Schema akzeptiert `hours` von 0 und Werte über 24; nur die Redmine-Validierung lehnt ab.
49. `update_issue_note` mit leeren `notes` löscht den Text des vorhandenen Kommentars.
50. `list_users` mit `project` gibt nur Benutzer zurück, auch wenn das Projekt über eine Gruppenmitgliedschaft verfügt.
51. Auf die historische Wiki-Seitenversion ohne `view_wiki_edits` kann nicht zugegriffen werden. Die geschützte Seite kann nicht ohne die Erlaubnis zum Schutz des Wikis geändert werden.
52. `copy_issue` ohne Erlaubnis zum Hinzufügen von Beobachtern kopiert keine Beobachter; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` Link und Anhänge verbieten; Das übergeordnete Element im selben Projekt bleibt erhalten.
53. Das Erweiterungsschreibtool im schreibgeschützten Modus ruft den Handler nicht auf.
54. `delete_attachment` sichtbar in `tools/list` für Benutzer, die Problemanhänge ohne `manage_files` löschen können.
55. `add_issue_watcher` / `remove_issue_watcher` akzeptieren Gruppen-Principal über `principal_id` oder den veralteten `user_id`.
56. `get_version` mit `project` gibt die gemeinsame Version zurück, die `list_versions` für dieses Projekt zurückgegeben hat.
57. `get_issue` / `get_wiki_page` / `get_board_message` begrenzen verschachtelte Listen mit `limit`/`offset` und geben `*_pagination` zurück; ohne Include-Paginierung ist `null`.
58. Tatsächliche Tool-Antworten, einschließlich nullbarer Felder, stimmen mit dem veröffentlichten `outputSchema` überein.
59. `get_issue` mit `include_journals`: Journal mit nur versteckten benutzerdefinierten Felddetails ist nicht in der Liste und wird nicht in `journal_pagination.total_count` gezählt.
60. Ein verstecktes Journal zwischen zwei sichtbaren erzeugt keine Seitenlücke: Bei `journal_limit=2` werden zwei sichtbare Einträge zurückgegeben, `total_count` entspricht der sichtbaren Anzahl.
61. Der private Kommentar eines anderen Benutzers wird in `get_issue` nicht ohne `view_private_notes`-Berechtigung zurückgegeben.
62. `get_private_notes` gibt eine Seite nach `limit`/`offset` zurück, ohne den vollständigen Issue-Verlauf zu laden.
63. `get_issue` mit den Journalen `attr`, `cf` und `relation` gleichzeitig schlägt nicht fehl und gibt nur sichtbare Einträge zurück.
64. Journal mit versteckten benutzerdefinierten Felddetails und Notizen zu Leerzeichen, Tabulatoren oder Zeilenumbrüchen ist nicht in `get_issue` enthalten.
65. `get_private_notes` gibt keinen Kommentar zurück, der nur aus Leerzeichen, Tabulatoren oder Zeilenumbrüchen besteht.
66. Administrator ruft `admin_list_users` auf und erhält den globalen Katalog; Nicht-Administrator sieht das Tool nicht in `tools/list` und erhält bei Aufruf eine Ablehnung.
67. Aufruf des Alias `list_all_users` liefert dasselbe Ergebnis wie `admin_list_users`; `redmine_list_all_users` fehlt in `tools/list`.
68. Aufruf des Alias `list_files` liefert dasselbe Ergebnis wie `list_project_files`; `redmine_list_files` fehlt in `tools/list`.
69. Aufruf des Alias `delete_file` liefert dasselbe Ergebnis wie `delete_attachment`; `redmine_delete_file` fehlt in `tools/list`.
70. Aufruf des Alias `get_server_info` liefert dasselbe Ergebnis wie `get_mcp_info`; `redmine_get_server_info` fehlt in `tools/list`.
