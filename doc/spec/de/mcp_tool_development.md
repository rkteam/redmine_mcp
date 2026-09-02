# Anforderungen an die Entwicklung von Redmine-MCP-Tools

[Deutsch](mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Status:** Entwicklerleitfaden (dev-guide), kein Verhaltens-SPEC des Plugins  
**Version:** 1.6  
**Datum:** 2026-08-20  
**Anwendbarkeit:** alle neuen Redmine-MCP-Tools und wesentliche Änderungen an bestehenden Tools  
**Basis-MCP-Version:** Protocol Revision `2025-11-25`

Verhaltensverträge für Core Tools stehen in `03-core-tools.md` und den zugehörigen SPECs. Dieses Dokument definiert Regeln für Entwurf und Implementierung von Tools.

---

## 1. Zweck des Dokuments

Dieses Dokument legt einheitliche Anforderungen für das Entwerfen, Implementieren, Beschreiben, Testen und Veröffentlichen von MCP-Tools für Redmine fest. Architekturimplementierungsmuster werden im Anhang A gesammelt und nicht mit verbindlichen Anforderungen im Haupttext vermischt.

Ziel dieses Standards ist, Tools:

- eindeutig für die Auswahl des Sprachmodells;
- sicher bei automatischem Aufruf;
- für MCP-Clients vorhersehbar;
- streng validiert;
- einfach zu warten und abwärtskompatibel;
- resistent gegenüber wiederholten Aufrufen, Modellfehlern und teilweise gefüllten Argumenten.

Die Anforderungen sind unter Berücksichtigung eines Audits des aktuellen Redmine MCP formuliert. Zum Zeitpunkt der Erstellung dieses Dokuments veröffentlichte der Server 46 Tools; im Vertrag wurden Parameter ohne `type`, String-Listen erlaubter Werte statt `enum`, universelle `manage_*`-Tools und fehlendes `outputSchema` festgestellt.

---

## 2. Verpflichtungsterminologie

In diesem Dokument werden die folgenden Ebenen verwendet:

- **MUST / MUSS** — zwingende Anforderung. Verletzung blockiert den Merge.
- **MUST NOT / VERBOTEN** — zwingendes Verbot.
- **SHOULD / SOLLTE** — Anforderung standardmäßig; Abweichung muss im Merge Request begründet werden.
- **MAY / DARF** — zulässige Option.

Architektur- und Implementierungsmuster, die nicht für jedes Tool obligatorisch sind, werden im **Anhang A** gesammelt. Sie blockieren den Merge nicht, wenn sie bewusst nicht für ein bestimmtes Tool übernommen werden.

---

## 3. Grundlegende Designprinzipien

### 3.1. Ein Tool – eine klare Aktion

Ein Tool MUSS eine atomare Benutzerabsicht darstellen.

Gut:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Schlecht:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Tools mit einem Parameter wie `action: create | update | delete | list` sind VERBOTEN, wenn die Operationen:

- erfordern unterschiedliche zwingende Argumente;
- haben unterschiedliche Risikostufen;
- sollte unterschiedliche MCP-Anmerkungen haben;
- verschiedene Datenstrukturen zurückgeben;
- erfordern unterschiedliche Redmine-Berechtigungen.

Eine Ausnahme ist nur für eine semantisch homogene Operation zulässig, bei der alle Varianten das gleiche Risiko und einen einzigen Vertrag haben. Die Ausnahme muss ausdrücklich begründet werden.

### 3.2. Lesen, Hinzufügen, Aktualisieren und Löschen sind getrennt

In einem Tool ist es VERBOTEN, Folgendes zu kombinieren:

- Nur-Lese- und Schreiboperationen;
- Vorgänge hinzufügen und löschen;
- regelmäßige Benutzer- und Verwaltungsvorgänge;
- lokale Redmine-Operationen und das Senden von Daten an die Außenwelt.

Beispielsweise muss es sich bei `list/create/delete relation` um drei separate Tools handeln.

### 3.3. Der Vertrag ist wichtiger als die Bequemlichkeit der Serverimplementierung

Veröffentlichen Sie die Struktur einer internen Ruby/Python/REST-Methode nicht direkt, nur weil es auf diese Weise einfacher ist, den Handler zu implementieren.

Der MCP-Vertrag ist auf das Model und den Kunden zugeschnitten; Ein Adapter im Server konvertiert es in das Redmine-API-Format.

Interne technische Werte eines Plugins oder Redmine MÜSSEN normalisiert werden, wenn sie nicht Teil eines sinnvollen externen Vertrags sind.

Nicht ohne Notwendigkeit veröffentlichen:

- Ruby/Rails-Klassennamen und STI-Typen;
- interne Enum-Namen, wenn MCP bei der Eingabe bereits einen anderen Wert verwendet;
- ortsabhängige Daten;
- REST-spezifische Darstellungen desselben Felds, wenn MCP bereits ein kanonisches Format definiert;
- Technische Namen, wenn MCP bereits einen normalisierten Wert verwendet.

Beispiel: Eingabefilter `type` – `contact` / `company`; in der Antwort auch `contact` / `company`, nicht `Clientdesk::Contact` / `Clientdesk::Company`. Wenn ein Serialisierer eine STI-Klasse oder ein lokalisiertes Datum zurückgibt, MUSS der MCP-Adapter den Wert in das veröffentlichte Schema übertragen.

### 3.4. Der Server vertraut dem Modell nicht

Alle Argumente gelten als nicht vertrauenswürdig. Der Server MUSS erneut prüfen:

- Typen;
- Bereiche;
- Feldinterdependenzen;
- Rechte des aktuellen Benutzers;
- Objekt, das zu einem Projekt gehört;
- Verfügbarkeit eines Werts in einem bestimmten Workflow;
- Redmine-Einschränkungen;
- ob die Operation im aktuellen Objektzustand zulässig ist.

JSON-Schema, Beschreibungen, Anmerkungen und Clientbestätigungen ersetzen nicht die serverseitige Validierung.

---

## 4. Werkzeugbenennung

### 4.1. Namensformat

Alle veröffentlichten Toolnamen MÜSSEN mit `redmine_` beginnen.

Für Kerntools des Plugins `redmine_mcp` wird das kurze Präfix `redmine_` verwendet:

```text
redmine_<verb>_<entity>
```

Bei Tools von Drittanbieter-Plugins MUSS der vollständige Name mit `redmine_` beginnen:

- `redmine_<plugin_id>_<verb>_<entity>`.

Anforderungen:

- nur `lower_snake_case`;
- Das Präfix `redmine_` ist für alle Tools obligatorisch, einschließlich Plugin-Erweiterungen von Drittanbietern.
- Der Name ist innerhalb des Servers eindeutig.
- internes Limit – nicht mehr als 64 Zeichen;
- Der Name ändert sich nicht ohne eine Abwertungsprozedur.

Beispiele:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Erlaubte Verben

Bevorzugte Verben:

| Verb | Zweck |
|---|---|
| `get` | ein Objekt über exakte Kennung abrufen |
| `list` | eine Sammlung über strukturierte Filter abrufen |
| `search` | Textsuche oder Volltextsuche ausführen |
| `create` | ein Objekt erstellen |
| `update` | ein vorhandenes Objekt ändern |
| `set` | ein bestimmtes Feld oder Flag auf einen gegebenen Wert setzen |
| `delete` | ein Objekt löschen |
| `add` | eine Beziehung oder ein Mitglied zu einem vorhandenen Objekt hinzufügen |
| `remove` | eine Beziehung entfernen, ohne das Hauptobjekt zu löschen |
| `copy` | eine Kopie erstellen |
| `upload` | eine Datei hochladen |
| `download` | Dateiinhalt abrufen |
| `send` | eine Nachricht oder Daten an einen externen Empfänger senden |
| `summarize` | einen serverseitig aggregierten Bericht erstellen |

Verwenden Sie keine vagen Verben (`manage`, `process`, `handle`, `execute`, `do`) – siehe §3.1.

Das Verb MUSS mit der tatsächlichen Semantik der Operation übereinstimmen. Wenn ein Tool ein boolesches Flag (Parameter wie `enabled: true | false`) umschaltet, SOLLTE es mit `set` benannt werden, nicht mit einem Verb, das nur einen Wert impliziert.

Schlecht:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` impliziert nur `enabled = true`, obwohl der Parameter auch `false` zulässt. Der Name stimmt nicht mit der tatsächlichen Aktion überein.

Gut:

```text
redmine_advanced_search_set_semantic_index_enabled
```

Der Name `set_*` spiegelt ehrlich wider, dass die Operation ein Flag auf den übergebenen Wert setzt.

### 4.3. Namen der Bezeichnerparameter

Ein Parametername MUSS mit seinem tatsächlichen Typ übereinstimmen:

- `issue_id` — nur Ganzzahl-ID;
- `project_id` — nur Ganzzahl-ID;
- `project_identifier` — Redmine-Zeichenfolgenkennung;
- `project` — Zeichenfolge, die bewusst beide Darstellungen zulässt und als Referenz dokumentiert ist.

Ein Parameter mit dem Namen `*_id` kann keine Zeichenfolgenkennung oder den Wert `"me"` akzeptieren.

Numerische IDs MÜSSEN `minimum: 1` und eine aussagekräftige `description` haben. Formulierungen wie `"Issue id"` ohne `minimum` sind VERBOTEN.

Schlecht:

```json
"issue_id": {
  "type": "integer",
  "description": "Vorgangs-ID"
}
```

Gut:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numerische Vorgangs-ID.",
  "examples": [1]
}
```

Die empfohlene einheitliche Option für das Projekt ist der Parameter `project`, der eine numerische ID (als Zeichenfolge) oder eine Zeichenfolgenkennung akzeptiert:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Projekt-ID als Zeichenfolge oder Projektkennung. Rufe redmine_list_projects auf, wenn der Wert unbekannt ist.",
  "examples": ["1", "ecookbook"]
}
```

Das Array `examples` (§6.15) zeigt dem Modell beide zulässigen Wertformen und verringert die Wahrscheinlichkeit einer falschen Eingabe.

### 4.4. Optimistische Sperre: `expected_updated_at`.

Ein Parameter, der einen zuvor bekannten Objektzeitstempel übergibt, um eine veraltete Änderung abzulehnen, MUSS in allen Kerntools und Erweiterungen `expected_updated_at` heißen.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Lehne die Operation ab, wenn das Objekt nach diesem Zeitstempel geändert wurde."
}
```

Der Name `updated_at` für diese Bedeutung ist VERBOTEN: Es sieht aus wie „neue Änderungszeit“, obwohl es sich tatsächlich um einen Wert für optimistisches Sperren handelt.

Schlecht (Checkliste und eventuelle Erweiterungen):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Aktueller updated_at des Checklisten-Elements."
}
```

Gut:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Lehne die Operation ab, wenn das Objekt nach diesem Zeitstempel geändert wurde."
}
```

Ein Antwortfeld, das die tatsächliche Objektänderungszeit meldet, KANN immer noch `updated_at` / `updated_on` heißen – Verwirrung entsteht nur für den Sperreingabeparameter.

Normatives Verhalten bei Konflikten finden Sie im Anhang A.2.

---

## 5. `title` und `description`

### 5.1. `title`

`title` MUSS ein kurzer, für Menschen lesbarer Name sein, keine Kopie des technischen Namens.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Tool-Beschreibung

`description` MUSS wichtige Fragen kurz beantworten:

1. Was macht das Tool und welches Objekt wird gelesen oder verändert?
2. Was ist standardmäßig nicht enthalten und wie kann ich es anfordern?
3. Gibt es erhebliche Nebenwirkungen?
4. Welches vorläufige Tool soll aufgerufen werden, wenn die ID oder ein zulässiger Wert unbekannt ist?

Die Beschreibung MUSS kurz und leicht lesbar sein. Es ist VERBOTEN, daraus einen langen halbseitigen Absatz zu machen, in dem alle Felder und alle Einschlussoptionen aufgeführt sind: Eine überladene Beschreibung ist für das Modell schwerer zu lesen als eine kurze strukturierte Beschreibung.

Es sollten mehrere kurze Zeilen oder eine Liste geschrieben werden, kein Fließtext. Voreinstellungen und deren Änderung werden kompakt dargestellt.

Gutes Beispiel:

```text
Gibt einen Vorgang zurück.

Standard:
- keine Journale
- keine Anhänge

Mit include_* anfordern.
Rufe redmine_search_issues auf, wenn issue_id unbekannt ist.
```

Schlechtes Beispiel – zu kurz, erklärt das Ergebnis und das Standardverhalten nicht:

```text
Gibt einen Vorgang zurück.
```

Schlechtes Beispiel – überladener, langer Absatz, der alle Felder auflistet:

```text
Gibt einen Redmine-Vorgang über numerische issue_id zurück, mit Kernfeldern einschließlich
Betreff, Beschreibung, Status, Priorität, Tracker, Projekt, Beauftragter, Autor,
Daten, erledigt-Anteil, benutzerdefinierte Felder und optional Journale, Anhänge,
Beziehungen, Beobachter, Untervorgänge und zulässige Workflow-Status je nach den
include-Parametern, die an den Aufruf übergeben wurden ...
```

### 5.2.1. Verweise auf andere Tools

Wenn sich Beschreibung, Parameterbeschreibung oder Serveranweisungen auf ein anderes Tool beziehen, MUSS der vollständige registrierte Name aus `tools/list` verwendet werden, kein kurzer `name` ohne Präfix.

Schlecht:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Gut:

```text
Rufe redmine_list_projects auf, wenn das Projekt unbekannt ist.
Rufe redmine_advanced_search_semantic_search_issues vor dem Update auf.
```

Kurznamen sind bei allen Plugins mehrdeutig und zwingen das Modell, das Präfix zu erraten. Dies ist besonders wichtig für Erweiterungen: `semantic_search_issues` ohne das Präfix `redmine_advanced_search_` kann leicht mit einem nicht vorhandenen Kerntool verwechselt werden.

### 5.2.2. Beschreibung des zurückgegebenen Ergebnisses

Die Beschreibung MUSS das Werkzeugergebnis kurz erläutern, damit das Modell versteht, ob ein Aufruf ausreicht oder ein nächstes Werkzeug benötigt wird.

Die Ergebnisbeschreibung sollte Folgendes enthalten:

- ob ein Objekt, eine Sammlung, ein Aggregat, eine Änderungsbestätigung oder eine Ressourcenreferenz zurückgegeben wird;
- welche zugehörigen Daten standardmäßig enthalten sind;
- welche großen oder sensiblen Daten nicht ohne einen expliziten Parameter einbezogen werden;
- ob eine Seitennummerierung vorhanden ist und wie hoch die Standardgrenze ist;
- ob ein Schreibtool das vollständig aktualisierte Objekt zurückgibt oder nur Bezeichner, URL und Änderungszeit;
- ob bei einer Massenoperation ein Teilerfolg möglich ist.

Beispiel zum Lesen:

```text
Gibt einen Vorgang mit Kern- und benutzerdefinierten Feldern zurück.

Standardmäßig nicht enthalten: Journale, Anhänge, Beziehungen, Beobachter, Untervorgänge.
Mit include_* anfordern.
```

Beispiel für Liste:

```text
Gibt eine paginierte Liste von Vorgängen zurück, die den übergebenen strukturierten Filtern entsprechen.
Jedes Element enthält nur Zusammenfassungsfelder; für vollständige Details redmine_get_issue verwenden.
Das Ergebnis enthält total_count, limit, offset und has_more.
```

Beispiel zum Schreiben:

```text
Erstellt einen Vorgang und gibt seine numerische ID, kanonische URL und Erstellungszeitstempel zurück.
Die Antwort enthält keine Journale oder Anhänge.
```

Zur Beziehung zwischen Beschreibung und `outputSchema` – siehe §7.1 und §7.1.1. Wenn eine Liste bereits ein Feld zurückgibt, DARF die Beschreibung das Modell NICHT nur für dieses Feld an `get_*` senden.

### 5.3. Die Beschreibung ersetzt nicht das Schema

Es ist VERBOTEN, Einschränkungen nur im Text festzulegen:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Verwenden Sie `enum`, `const`, Bereiche und bedingte Schemata.

Das Gleiche gilt für sich gegenseitig ausschließende Felder. Wenn in der `description` steht `user_id` oder `group_id`, aber `required` nur gemeinsame Felder enthält, weichen Schema und Text voneinander ab. Die Einschränkung MUSS in `inputSchema` formalisiert werden (§6.12).

### 5.4. Vorhersehbare Auswahl

Beschreibungen ähnlicher Tools müssen den Unterschied explizit erläutern.

Zum Beispiel:

- `redmine_list_project_members` — Mitglieder eines bestimmten Projekts und ihre Rollen;
- `redmine_admin_list_users` — globale Liste der Installation-Benutzer, erfordert Administratorrechte.

### 5.5. Anweisungen auf Serverebene

Der Server KANN kurze allgemeine Anweisungen veröffentlichen, die die Beziehungen zwischen Tools und Workflow-Regeln erläutern.

Anweisungen sollten Kontext hinzufügen, der in einzelnen Beschreibungen nicht vorhanden ist, und auf Werkzeuge mit vollständigen Namen verweisen (§5.2.1), zum Beispiel:

```text
Rufe redmine_search_issues vor redmine_get_issue auf, wenn die Vorgangs-ID unbekannt ist.
Vor dem Erstellen oder Aktualisieren eines Vorgangs rufe redmine_list_project_trackers und
redmine_list_project_issue_custom_fields auf, wenn ihre IDs noch nicht bekannt sind.
Private Notizen nur anfordern, wenn der Benutzer sie explizit benötigt und die
erforderliche Berechtigung hat.
```

VERBOTEN:

- Wiederholte Beschreibungen aller Tools in Serveranweisungen;
- Platzieren allgemeiner Modellverhaltensanweisungen, die nichts mit dem Server zu tun haben;
- Schreiben eines langen Leitfadens anstelle kurzer Routing-Regeln;
- Marketing-Aussagen verwenden;
- auf Tools mit Kurznamen ohne Präfix verweisen (`list_projects` statt `redmine_list_projects`).

### 5.6. Redmine-REST-API vor der Entwicklung studieren

Vor dem Erstellen oder wesentlichen Ändern eines Tools SOLLTE der Entwickler eine Dokumentationsrecherche durchführen. Es ist nicht empfehlenswert, den Vertrag nur aus vorhandenem MCP-Code, Entwicklergedächtnis oder einem einzelnen HTTP-Beispiel zu entwerfen.

SOLLTE studieren:

1. Hauptseite der Redmine-REST-API: allgemeine Authentifizierung, Paginierung, `include`, benutzerdefinierte Felder, Dateien und Validierungsfehlerregeln.
2. Separate API-Seite für die entsprechende Ressource, z. B. Issues, Time Entries, Versions, Wiki Pages oder Project Memberships.
3. API-Änderungshistorie und Änderungen für unterstützte Redmine-Versionen.
4. Tatsächliche von MCP verwendete Redmine-Version und minimal unterstützte Version.
5. REST-API und Quellcode der verwendeten Redmine-Plugins, wenn das Tool mit einer Plugin-Entität oder -Feldern arbeitet. Vor der Veröffentlichung eines Erweiterungstools MÜSSEN der Quellserialisierer/Dienst/REST-Endpunkt und mindestens eine tatsächlich erfolgreiche Antwort für jedes Ergebnisformular überprüft werden (list und get, wenn beide veröffentlicht sind).
6. Tatsächliche Berechtigungen, Workflow, aktivierte Module, Tracker, benutzerdefinierte Felder und Einschränkungen der Zielinstallation.
7. Bereits veröffentlichte MCP-Tools, um einen doppelten oder widersprüchlichen Vertrag zu vermeiden.

Die Hauptseite `https://www.redmine.org/projects/redmine/wiki/rest_api` ist der Einstiegspunkt, reicht für ein bestimmtes Tool jedoch meist nicht aus. SOLLTE zur entsprechenden Ressourcenseite gehen und Vorgänge, Abfrageparameter, `include`, Anfragefelder, Antwortstruktur, Fehlercodes und Versionseinschränkungen prüfen.

### 5.7. API-Abdeckungsbericht

Vor der Implementierung eines neuen Tools SOLLTE der Entwickler der Zusammenführungsanforderung eine kurze API-Abdeckungstabelle beifügen:

| Feld | Inhalt |
|---|---|
| Redmine-Ressource | Ressource und Link zur offiziellen API-Seite |
| Endpunkt | HTTP-Methode und Pfad |
| Unterstützt seit | Minimale Redmine-Version |
| Anfrageparameter | Alle dokumentierten Anfrageparameter |
| Abfragefilter | Alle dokumentierten Filter und Sonderwerte |
| Include-Werte | Erlaubte zugehörige Daten |
| Erforderlich/Standardwerte | Pflichtfelder und Standardwerte |
| Antwort | Hauptfelder und Antwortvarianten |
| Fehler | HTTP-Codes und Fehlerstruktur |
| Berechtigungen | Erforderliche Rechte und Besonderheiten der Impersonation |
| MCP-Veröffentlichung | Welche Parameter in MCP veröffentlicht werden |
| Absichtlich weggelassen | Welche Parameter nicht veröffentlicht werden und warum |
| Plugin-/Version-Unterschiede | Plugin- und unterstützte Version-Unterschiede |

Das Ziel der Tabelle besteht nicht unbedingt darin, jeden Redmine-Parameter in MCP zu veröffentlichen. Ziel ist es, Parameter nicht versehentlich zu vergessen und Veröffentlichungsentscheidungen bewusst zu treffen.

Ein Redmine-Parameter kann von MCP ausgeschlossen werden, wenn er:

- ist gefährlich oder administrativ;
- dupliziert ein separates Clearer-Tool;
- ist in allen unterstützten Versionen instabil;
- erstellt ein mehrdeutiges Schema;
- wird für Zielbenutzerszenarien nicht benötigt;
- führt zu zu großen Antworten.

Jeder wesentliche Ausschluss wird unter `Intentionally omitted` mit einer kurzen Begründung erfasst.

### 5.8. Anweisungen für einen KI-Agenten, der Tools entwickelt

Wenn ein Tool von einem KI-Agenten erstellt oder geändert wird, SOLLTEN sich die Arbeitsanweisungen auf dieses Dokument beziehen: API-Recherche (§5.6–5.7), Vertrag (§3–§8), Tests (§13), Checkliste (§14).

Empfohlener Text:

```text
Vor der Implementierung oder Änderung eines Redmine-MCP-Tools MCP_TOOL_DEVELOPMENT.md befolgen:
Redmine-REST-API für die Zielressource studieren (§5.6–5.7), eine Benutzerintention
entwerfen statt das REST-Payload zu kopieren (§3), mit tools/list vergleichen, dann
Schema/Annotations/Fehler implementieren. Für Plugin-Erweiterungen den Serialisierer
oder REST-Antwort prüfen und Beschreibung mit outputSchema abgleichen (§7, §18).
Code-Review-Checkliste bestehen (§14).
```

---

## 6. `inputSchema`-Anforderungen

### 6.1. Grundstruktur

Jedes Tool MUSS über ein gültiges JSON-Schema verfügen.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Für ein Tool ohne Argumente:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Verbot undokumentierter Eigenschaften

Auf der obersten Ebene und in allen verschachtelten Objekten:

```json
"additionalProperties": false
```

Ein offenes Wörterbuch ist nur bewusst erlaubt. In diesem Fall wird das Werteschema explizit festgelegt:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Typ jedes Parameters

Jede Eigenschaft MUSS `type`, `$ref` oder eine `oneOf` / `anyOf` / `allOf`-Komposition enthalten.

VERBOTEN:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Erforderliche Parameter

Das `required` Array muss den minimal ausführbaren Aufruf widerspiegeln.

Wenn die Operation ohne Parameter nicht möglich ist, MUSS der Parameter in `required` enthalten sein.

Für das Hochladen einer Datei ist beispielsweise mindestens Folgendes erforderlich:

```json
"required": ["project", "filename", "content_base64"]
```

Die Prüfung `confirm=true` auf Löschung wird auf dem Server durchgeführt (§3.4), auch wenn das Feld `required` ist.

### 6.5. Aufzählungen

Für eine endliche Menge von Werten MUSS `enum` oder `const` verwendet werden (nicht nur Text in der Beschreibung – siehe §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Zeichenfolgen

Zeichenfolgen müssen entsprechende Einschränkungen haben:

- `minLength` für nicht-leere Werte;
- `maxLength` gemäß Redmine-Einschränkungen oder internen Grenzen;
- `pattern`, wenn das Format strikt definiert ist;
- `format`, wenn ein Standardformat gilt.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

Die `format`-Einschränkung im Schema ersetzt nicht die serverseitige Validierung (§3.4).

### 6.7. Zahlen

Für numerische Parameter MÜSSEN sinnvolle Grenzen festgelegt werden.

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

```json
"hours": {
  "type": "number",
  "exclusiveMinimum": 0,
  "maximum": 24
}
```

Der `default`-Wert ist Teil des Vertrags und der Dokumentation. Der Server darf nicht davon ausgehen, dass der Client den Standardwert selbst ersetzt.

### 6.8. Arrays

Jedes Array MUSS `items` haben.

Bei Bedarf setzen:

- `minItems`;
- `maxItems`;
- `uniqueItems`.

```json
"role_ids": {
  "type": "array",
  "minItems": 1,
  "maxItems": 20,
  "uniqueItems": true,
  "items": {
    "type": "integer",
    "minimum": 1
  }
}
```

Ein Array wie `entries: array` ohne Elementschema ist VERBOTEN.

### 6.9. Verschachtelte Objekte

Alle verschachtelten Objekte werden vollständig beschrieben.

```json
"custom_fields": {
  "type": "array",
  "items": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "id": {"type": "integer", "minimum": 1},
      "value": {
        "oneOf": [
          {"type": "string"},
          {"type": "number"},
          {"type": "boolean"},
          {
            "type": "array",
            "items": {"type": "string"}
          }
        ]
      }
    },
    "required": ["id", "value"]
  }
}
```

### 6.10. „Objekt oder JSON-Zeichenfolge“ kann nicht akzeptiert werden.

Es ist VERBOTEN, einen Parameter als „Objekt oder JSON-String“ zu beschreiben.

MCP übergibt bereits strukturiertes JSON. Das Tool muss ein Objekt akzeptieren, keine Zeichenfolge, die der Server dann erneut analysiert.

### 6.11. Universelle `fields` und `extra_fields`.

Die Parameter `fields`, `extra_fields`, `payload`, `data` und ähnliche offene Objekte sind für den Hauptgeschäftsbetrieb VERBOTEN.

Problemfelder müssen explizit mit einer aussagekräftigen `description` (§6.14) und, wo nützlich, `examples` (§6.15) aufgeführt werden:

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker-ID aus redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Vorgangsstatus-ID aus redmine_list_issue_statuses; muss vom Workflow für den aktuellen Tracker und die Rolle zulässig sein.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Vorgangs-Prioritäts-ID aus redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Benutzer-ID des Beauftragten aus redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Zielversion-ID aus redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numerische ID des übergeordneten Vorgangs."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

Selten verwendete Felder können über ein streng beschriebenes `custom_fields` übergeben werden.

### 6.12. Voneinander abhängige Felder

Bevorzugen Sie Spaltwerkzeuge. Wenn eine Aufteilung nicht möglich ist, wird die Abhängigkeit formalisiert durch:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` mit sich gegenseitig ausschließenden Zweigen.

Text in `description` („exactly one of …“) ersetzt nicht das Schema (§5.3).

Typischer Fall – „genau eines von zwei Feldern“. Schlecht: `required` listet nur gemeinsame Felder auf, XOR bleibt in Prosa:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {"type": "string", "minLength": 1},
    "user_id": {"type": "integer", "minimum": 1},
    "group_id": {"type": "integer", "minimum": 1},
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "integer", "minimum": 1}
    }
  },
  "required": ["project", "role_ids"]
}
```

Ein solches Schema ermöglicht einen Aufruf ohne `user_id`/`group_id` und einen Aufruf mit beiden Feldern gleichzeitig.

Gut – allgemeines `required` plus `oneOf` der obersten Ebene:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Projekt-ID als Zeichenfolge oder Projektkennung. Rufe redmine_list_projects auf, wenn der Wert unbekannt ist."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Benutzer-ID aus redmine_list_users, als Projektmitglied hinzuzufügen."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Gruppen-ID, als Projektmitglied hinzuzufügen."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Rollen-IDs aus redmine_list_roles."
    }
  },
  "required": ["project", "role_ids"],
  "oneOf": [
    {
      "required": ["user_id"],
      "not": {"required": ["group_id"]}
    },
    {
      "required": ["group_id"],
      "not": {"required": ["user_id"]}
    }
  ]
}
```

Die serverseitige Validierung (§3.4) MUSS weiterhin beide fehlerhaften Varianten ablehnen. Ein Schema ist erforderlich, damit Client und Modell die Einschränkung vor dem Aufruf sehen.

Die Kompatibilität ausgewählter Konstrukte mit unterstützten MCP-Clients und SDK muss überprüft werden.

### 6.13. Felder mit `null`-Wert und Löschwerten

`null` ist nur zulässig, wenn es eine separate dokumentierte Bedeutung hat, z. „Fälligkeitsdatum löschen“ oder „Zuweisung aufheben“.

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "Neues Fälligkeitsdatum im Format YYYY-MM-DD oder null zum Löschen."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Benutzer-ID des Beauftragten aus redmine_list_users oder null zum Aufheben der Zuweisung."
}
```

Verwenden Sie keine leere Zeichenfolge als implizites Äquivalent von `null`.

Für `set_*`-Tools, die ein optionales Feld festlegen (Fälligkeitsdatum, Beauftragter usw.), MUSS der Vertrag explizit über die Freigabe entscheiden. Drei Optionen sind zulässig – in der Reihenfolge ihrer Präferenz:

1. **Dasselbe Tool akzeptiert `null`** (bevorzugt), wie oben: eine Intention „setzen oder löschen“.
2. **Separates Tool zum Löschen/Aufheben der Zuweisung**, wenn API oder UX Vorgänge besser trennen, z. B. `redmine_advanced_search_clear_saved_query` und `redmine_advanced_search_unassign_search_owner`.
3. **Ausdrückliche Ablehnung**: Wenn das Clearing über MCP nicht unterstützt wird, MUSS dies in der `description` des Tools und/oder der Parameterbeschreibung angegeben werden. Der stille Vertrag `""` ohne Erklärung ist VERBOTEN – das Modell denkt fälschlicherweise, dass das Löschen unmöglich ist, oder versucht, „““ / `0` zu übergeben.

Schlecht — kann Fälligkeitsdatum setzen, nicht löschen, und nirgends angegeben:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Parameterbeschreibungen

Jeder Parameter in `inputSchema.properties` MUSS eine aussagekräftige `description` haben. Parameter ohne `description` sind VERBOTEN, auch in Erweiterungen (Checklistenpunkt `done`, `sort_order`, `due_date`, ID-Felder usw.) und optionalen Feldern mit eindeutigem `enum`.

Beschreibungen wie „Nach Tracker-ID filtern“, „Tracker-ID“ oder „Problem-ID“ reichen nicht aus: Sie geben keinen Hinweis darauf, wo ein zulässiger Wert zu finden ist und welche Einschränkungen bestehen.

Eine Beschreibung des Bezeichnerparameters MUSS angeben, welches Tool oder Antwortfeld für zulässige Werte verwendet werden soll (vollständiger Name – §5.2.1; Erkennung – §6.16) und wichtige Einschränkungen beachten (Workflow, Berechtigungen, Projektzugehörigkeit).

Schlecht:

```json
"tracker_id": {
  "type": "integer",
  "description": "Nach Tracker-ID filtern."
}
```

```json
"done": {
  "type": "boolean"
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]}
}
```

Gut:

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker-ID aus redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true markiert das Element als erledigt; false als nicht erledigt."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Benutzer-ID aus redmine_list_users, als Projektmitglied hinzuzufügen."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Zu durchsuchende Ressourcentypen. Weglassen, um alle unterstützten Ressourcentypen zu durchsuchen."
}
```

Gut, mit der Einschränkung:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Vorgangsstatus-ID aus redmine_list_issue_statuses; muss vom Workflow für den aktuellen Tracker und die Rolle zulässig sein."
}
```

Die Parameterbeschreibung ersetzt nicht das Schema (§5.3) und die serverseitige Validierung (§3.4).

### 6.15. Wertbeispiele (`examples`)

Für Parameter, bei denen das Werteformat nicht offensichtlich ist oder mehrere Darstellungen zulässt, SOLLTE `examples` hinzugefügt werden – Standard-JSON-Schema-Array-Schlüssel. Beispiele helfen dem Modell, einen korrekten Wert einzugeben, und sind besonders nützlich für Referenzparameter, Bezeichner, Datumsangaben und enum-ähnliche Zeichenfolgen.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Projekt-ID als Zeichenfolge oder Projektkennung. Rufe redmine_list_projects auf, wenn der Wert unbekannt ist.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Fälligkeitsdatum im Format YYYY-MM-DD.",
  "examples": ["2026-07-30"]
}
```

Anforderungen:

- `examples`-Werte MÜSSEN gegen das Parameter-Schema selbst gültig sein;
- `examples` veranschaulichen das Format, ersetzen aber nicht `enum`, Bereiche und andere Einschränkungen (§5.3, §6.5);
- Für Parameter mit `enum` sind separate `examples` normalerweise überflüssig.

Wenn ein MCP-Client oder SDK `examples` im Schema nicht unterstützt, KANN `x-examples` als Erweiterungsschlüssel mit derselben Semantik verwendet werden.

### 6.16. Erkennungspfad für ID-Parameter

Ein Parameter der Form `*_id`, den das Modell nicht erraten kann, MUSS einen expliziten Erkennungspfad haben: ein separates Lese-/Listentool oder ein Feld in einer anderen Antwort des Lesetools, auf das im Parameter `description` (§6.14) verwiesen wird.

Zulässige Optionen (in der Reihenfolge ihrer Präferenz für einen Werkzeugsatz):

1. **Separates Listen-/Erkennungstool** – `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Optionen innerhalb der get/list-Antwort** – z.B. Anbieterarray mit `id` und `name` in der Antwort `redmine_advanced_search_semantic_search_issues`. Dann MUSS sich die Beschreibung auf das Antwortfeld mit dem vollständigen Werkzeugnamen beziehen.
3. **Stabiles enum im Schema**, wenn die Wertemenge fest und klein ist.

VERBOTEN, ein Schreibtool mit `status_id` / `role_ids` / Ähnlichem zu veröffentlichen, wenn keine der obigen Optionen erfüllt ist: das Modell muss IDs erraten.

Schlecht — Schreiben ohne Erkennungspfad:

- `redmine_advanced_search_set_search_provider` existiert mit `provider_id`;
- kein `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` gibt nur den aktuellen Anbieternamen zurück (`provider: "…"`), ohne Liste zulässiger Werte und ihrer `id`.

In diesem Fall reicht eine Beschreibung wie `"Search provider ID."` nicht aus. Fügen Sie entweder ein Listentool hinzu oder schließen Sie Anbieteroptionen in Get-Antwort und Schreibtool ein, zum Beispiel:

```text
Suchanbieter-ID aus den Anbieteroptionen in der Antwort von
redmine_advanced_search_semantic_search_issues.
```

Die Regelung gilt für Kern und Erweiterungen (§18).

---

## 7. `outputSchema` und Ergebnisanforderungen

### 7.1. `outputSchema`

Ein neues Tool MUSS `outputSchema` veröffentlichen. Das Schema beschreibt einen stabilen öffentlichen Reaktionsvertrag, nicht nur die Umschlagform `{ ok, data | error }`.

Wenn `description` behauptet, dass das Tool benannte Felder oder eine verschachtelte Struktur zurückgibt, MUSS `outputSchema` diese Felder formalisieren und darf sich nicht auf `data` / `items` der obersten Ebene als „beliebiges Objekt“ beschränken.

Schlecht: Beschreibung listet `query`, `results`, Snippets und Anhangsauszüge auf, aber `outputSchema` fehlt oder beschreibt `items` nur als `{ "type": "object", "additionalProperties": true }`: „object“, „additionalProperties“: true }“.

Für jedes stabile Ergebnisfeld:

- Typ MUSS angegeben werden;
- ein garantiertes Feld MUSS in `required` enthalten sein;
- eine endliche Wertemenge MUSS über `enum` oder `const` festgelegt werden;
- ein Datum MUSS `format: date` oder `date-time` haben, wenn der Server das entsprechende Format garantiert;
- Die numerische ID MUSS einen einheitlichen Typ behalten.
- nullable und optional sind unterschiedliche Verträge: Wenn ein Feld immer zurückgegeben wird, aber keinen Wert haben darf, muss es `required` sein und `null` zulassen;
- Bei numerischen Geschäftswerten MÜSSEN Einheiten angegeben werden, wenn diese nicht aus dem Feldnamen ersichtlich sind.
- Der Geldwert MUSS eine eindeutige Semantik haben: große/kleine Einheiten und wie die Währung bestimmt wird.

`additionalProperties: true` DARF NICHT anstelle der Beschreibung bekannter stabiler Ergebnisfelder verwendet werden. Aus Gründen der Abwärtskompatibilität oder wirklich erweiterbarer Strukturen ist dies zulässig, bekannte Geschäftsfelder innerhalb eines solchen Objekts müssen jedoch weiterhin in `properties` und garantierte Geschäftsfelder in `required` aufgeführt sein.

Bei Listentools MÜSSEN `items`-Elemente mindestens Felder beschreiben, die das Modell zur Identifizierung, Filterung und nachfolgenden Toolaufrufe benötigt.

Gut – Fragmenttypisierung `data` (vollständiger Erfolgs-/Fehlerumschlag – §7.2 und §12):

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ok": {"type": "boolean"},
    "data": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "query": {"type": "string"},
        "results": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": true,
            "properties": {
              "id": {"type": "integer"},
              "subject": {"type": "string"},
              "url": {"type": "string"}
            },
            "required": ["id", "subject"]
          }
        }
      },
      "required": ["query", "results"]
    }
  },
  "required": ["ok"]
}
```

Das Ergebnis SOLLTE Folgendes zurückgeben:

- `structuredContent` — maschinenlesbares Objekt, wenn Clients stabile Struktur benötigen;
- Text `content` – kurze Darstellung für Abwärtskompatibilität und Menschen.

### 7.1.1. Konsistenz öffentlicher Verträge

Vor der Fertigstellung eines Tools MUSS der Entwickler drei Darstellungen vergleichen:

1. tatsächliche Handler-/REST-/Service-Antwort;
2. Werkzeug-`description`;
3. `outputSchema`.

Sie dürfen sich nicht widersprechen.

Wenn die Beschreibung besagt, dass ein Feld immer zurückgegeben wird, muss es in `required` `outputSchema` sein.

Wenn das Schema `enum` / `const` / `format` festlegt, MUSS der eigentliche Serialisierer den Wert auf diesen Vertrag normalisieren. `format: date` kann nicht veröffentlicht und gleichzeitig eine mit dem Gebietsschema formatierte Zeichenfolge versprochen werden.

Wenn eine Liste bereits Daten zurückgibt, DARF die Beschreibung das Modell NICHT nur für dieselben Daten an ein Get-Tool senden.

Geschäftsinvarianten des Ergebnisses MÜSSEN im Schema über `const`, `enum`, `required` oder bedingtes Schema reflektiert werden, nicht nur aus dem Toolnamen abgeleitet werden. Beispiel: Wenn ein Abonnement-Tool per Definition nur Produkte vom Typ `subscription` zurückgibt, muss `product_type` `const: "subscription"` sein, nicht `enum` mit unmöglichen Werten.

### 7.2. Einheitlicher Umschlag

Empfohlenes Erfolgsergebnis:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Fehler:

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "status_id 17 is not available for tracker 3",
    "field": "status_id",
    "retryable": false
  }
}
```

Bei Fehler zusätzlich setzen:

```json
"isError": true
```

Wenn `outputSchema` veröffentlicht wird und ein Fehler auch in `structuredContent` zurückgegeben wird, MUSS das Schema beide Zweige beschreiben – Erfolg und Fehler. Das Nur-Erfolg-Schema kann nicht veröffentlicht werden und ein inkompatibles strukturiertes Fehlerobjekt wird nicht zurückgegeben. Alternative: Bei einem Tool-Ausführungsfehler wird nur der Text `content` mit `isError: true` und nicht `structuredContent` zurückgegeben. Bevorzugte Option – einheitlicher typisierter Umschlag mit zwei Zweigen.

### 7.3. Feldstabilität

Ausgabefelder sind ein öffentlicher Auftrag. VERBOTEN:

- Ändern des Feldtyps ohne große Änderung;
- Umbenennen eines Feldes ohne Ablauffrist;
- manchmal wird ein Objekt zurückgegeben, manchmal ein Array;
- gibt manchmal die ID als Zahl zurück, manchmal als Zeichenfolge;
- Rückgabe unbegrenzter unverarbeiteter Redmine-API-Antworten.

### 7.4. Einzelobjektergebnis

Empfohlenes Format:

```json
{
  "ok": true,
  "data": {
    "id": 12345,
    "subject": "Fix authorization error",
    "status": {"id": 2, "name": "In Progress"},
    "project": {"id": 10, "identifier": "bank-site", "name": "Bank Site"},
    "url": "https://redmine.example/issues/12345",
    "updated_at": "2026-07-22T09:20:00Z"
  }
}
```

### 7.5. Listenergebnis

```json
{
  "ok": true,
  "data": {
    "items": []
  },
  "meta": {
    "total_count": 143,
    "limit": 25,
    "offset": 0,
    "next_offset": 25,
    "has_more": true
  }
}
```

Das Elementschema `items` folgt §7.1: Bezeichner, Routing-Felder und stabile Geschäftsfelder werden explizit beschrieben. Leer `{ "type": "object", "additionalProperties": true }` als einzige Elementbeschreibung ist VERBOTEN.

### 7.6. Minimal notwendiges Volumen

Listen-/Suchtools müssen standardmäßig kurze Datensätze zurückgeben. Vollständige Beschreibung, Journale, Anhänge und große Textfelder sollten über separates `get_*` abgerufen werden.

Dies reduziert Token, Latenz und das Risiko der Weitergabe übermäßig sensibler Daten.

### 7.7. Sensible Daten

Das Ergebnis darf ohne expliziten Bedarf nicht enthalten:

- API-Token;
- Autorisierungsheader;
- Kekse;
- Server-Dateisystempfade;
- interne Stack-Traces;
- Passwörter und Geheimnisse;
- Redmine-Felder sind für den aktuellen Benutzer nicht verfügbar;
- private Notizen ohne gesonderte Berechtigung.

---

## 8. MCP-Anmerkungen

Annotations sind Hinweise für den Client und kein Autorisierungs- oder Schutzmechanismus.

### 8.1. Wertematrix

| Vorgangstyp | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Redmine-Daten abrufen/suchen/listen | `true` | `false` | `true` | `false` |
| Vorgang/Version/Checkliste erstellen | `false` | `false` | `false` | `false` |
| Kommentar/Beobachter/Beziehung hinzufügen | `false` | `false` | `false` | `false` |
| Feld ändern, umbenennen, Flag setzen (`update`, `rename`, `set`) | `false` | `false` | hängt von der Implementierung ab | `false` |
| Löschen, leeren, zurücksetzen (`delete`, `purge`, `reset`) | `false` | `true` | nur mit garantierter Idempotenz | `false` |
| E-Mail an externen Empfänger senden | `false` | `false` | `false` | `true` |
| Beliebige URL / externes System zugreifen | variiert | variiert | variiert | `true` |

### 8.2. Regeln

- `readOnlyHint: true` nur, wenn das Tool den Zustand nicht ändert und keine Nebenwirkungen verursacht.
- `destructiveHint` beschreibt irreversiblen Verlust oder Zerstörung von Daten, nicht die Tatsache des Schreibens. `destructiveHint: true` SOLLTE nur für irreversible Operationen gesetzt werden — `delete`, `purge`, `reset`, vollständiges Löschen von Feldern oder Beziehungen.
- Gewöhnliches `update`, `rename` und `set` sind NICHT destruktiv: für sie `destructiveHint: false`. Beispielsweise handelt es sich bei `update_checklist_title` oder `rename_wiki_page` um eine normale Aktualisierung, nicht um eine Zerstörung, und eine destruktive Annotation ist für sie falsch.
- `idempotentHint: true` nur, wenn ein wiederholter Aufruf wirklich sicher ist; SOLLTE mit einem Test bestätigt werden.
- `openWorldHint` beschreibt, ob das Tool eine offene, zuvor unbekannte externe Welt zugreift, nicht ob ein neues Objekt erstellt wird. Arbeit mit einer konfigurierten Redmine-Installation ist eine geschlossene Welt: `openWorldHint: false`.
- Daher verwenden `create_issue`, `create_time_entry` und andere Schreibtools innerhalb ihrer Redmine `openWorldHint: false`, obwohl neue Objekte erstellt werden. Durch das Erstellen eines Objekts in einem bekannten System wird die Welt nicht geöffnet.
- `openWorldHint: true` nur, wenn Empfänger oder Datenquelle nicht auf das bekannte System beschränkt sind: E-Mail an externen Empfänger, beliebige HTTP-Anfrage, Zugriff auf externen Dienst.
- Der Wert von `openWorldHint` SOLLTE für jedes Tool bewusst gesetzt werden, nicht standardmäßig kopiert: prüfen, ob das Tool tatsächlich über die eigene Redmine-Installation hinausgeht.
- Ein Anmerkungssatz kann nicht in alle Schreibwerkzeuge kopiert werden.

### 8.3. Nebenwirkungen von Redmine

Berücksichtigen Sie bei der Beurteilung der Idempotenz nicht nur die endgültigen Felder, sondern auch Folgendes:

- Erstellung von Journaleinträgen;
- Versand von Benachrichtigungen;
- Webhooks;
- Audit-Protokoll;
- wiederholter Datei-Upload;
- wiederholte Beziehungserstellung;
- Protokollierung wiederholter Zeiteinträge.

Wenn ein wiederholter Aufruf einen zusätzlichen Datensatz oder eine zusätzliche Benachrichtigung erstellt, ist das Tool nicht idempotent.

---

## 9. Sicherheit

### 9.1. Autorisierung

Jeder Aufruf MUSS im Kontext eines authentifizierten Benutzers oder eines explizit dokumentierten Dienstkontos ausgeführt werden.

Der Server MUSS die Redmine-Berechtigungen für das jeweilige Projekt und Objekt prüfen. Das Vorhandensein eines Werkzeugs in `tools/list` bedeutet nicht die Erlaubnis für den Vorgang.

Verwaltungstools sollten:

- nur für Administratoren veröffentlicht werden;
- oder in ein separates administratives MCP-Profil/Server verschoben werden;
- oder durch einen separaten Bereich geschützt werden.

### 9.2. Mindestrechte

Der MCP-Server und das Redmine-API-Token müssen über die minimal erforderlichen Rechte verfügen. Ein globales Verwaltungstoken kann nicht für alle Benutzer verwendet werden, wenn das Benutzerzugriffsmodell beibehalten werden muss.

### 9.3. Beliebige Dateisystempfade verboten

Parameter wie:

```json
{"file_path": "/etc/app/.env"}
```

sind in öffentlichen MCP-Tools VERBOTEN.

Sichere Optionen:

1. `content_base64` mit Größenlimit;
2. undurchsichtiger `upload_token`, ausgegeben durch vertrauenswürdigen Upload-Mechanismus;
3. MCP-Ressourcen-URI, bei der der Zugriff vom Host geprüft wird;
4. Datei nur aus einem dedizierten temporären Verzeichnis mit `realpath`-Prüfung und Zulassungsliste.

Der Server MUSS Folgendes überprüfen:

- maximale Größe;
- MIME type;
- erlaubte Verlängerung;
- Dateiname;
- Fehlen einer Pfaddurchquerung;
- Antiviren-/Inhaltsprüfung, falls dies gemäß den Richtlinien der Organisation erforderlich ist.

### 9.4. Beliebige URLs und SSRF

Ein Tool darf keine beliebige URL akzeptieren, es sei denn, dies ist sein Hauptzweck.

Wenn HTTP-Zugriff erforderlich ist:

- Domänen- und Schema-Zulassungsliste verwenden;
- Loopback, Link-Local, Metadaten-Endpunkte und interne Netzwerke verbieten, wenn sie nicht benötigt werden;
- Weiterleitungen begrenzen;
- Timeout und Antwortlimit festlegen;
- interne Anmeldedaten nicht an einen anderen Ursprung weitergeben.

### 9.5. Löschung und gefährliche Vorgänge

Für irreversible Operationen PFLICHT:

- separates Werkzeug;
- `destructiveHint: true`;
- explizite Beschreibung der Irreversibilität;
- präzise serverseitige Berechtigungsprüfung;
- Audit-Protokoll;
- Schutz vor dem Löschen von Objekten außerhalb des erwarteten Projekts;
- Überprüfung von untergeordneten Objekten und damit verbundene Konsequenzen.

Boolean `confirm_delete: true` KANN als zusätzlicher Schutz gegen versehentliche Aufrufe verwendet werden, kann aber nicht als Autorisierungsmechanismus betrachtet werden.

Zweiphasenlöschung, optimistisches Sperren und Idempotenzschlüssel – siehe Anhang A.

### 9.6. Protokolle

Audit-Log-Datensätze:

- Werkzeugname;
- authentifizierter Benutzer;
- Zielprojekt-/Objekt-IDs;
- Ergebnis;
- Dauer;
- Fehlercode;
- Korrelations-ID anfordern.

Das Protokollieren ist VERBOTEN:

- Zugriffstoken;
- Autorisierungsheader;
- Kekse;
- Inhalt der Base64-Datei;
- geheime benutzerdefinierte Felder;
- Volltext privater Notizen ohne gesonderte Notwendigkeit.

### 9.7. Ratenlimit und Timeout

Jedes Werkzeug MUSS Folgendes haben:

- Eingabegrößenbeschränkung;
- Ratenlimit pro Benutzer/Token;
- Begrenzung der Anzahl zurückgegebener Datensätze;
- Grenzen für den Massenbetrieb.

Für Lesetools gilt ein Server-Timeout von 60 s. Schreibwerkzeuge werden nicht durch Server-Timeout unterbrochen, sodass nach erfolgreicher Speicherung das Idempotenzergebnis aufgezeichnet werden kann.

---

## 10. Fehler

### 10.1. Fehlertrennung

Es werden zwei Ebenen verwendet:

1. **Protokollfehler** – unbekanntes Tool, beschädigter JSON-RPC, MCP-Anfrage kann nicht verarbeitet werden.
2. **Tool-Ausführungsfehler** mit `isError: true` – Argumentfehler, Redmine-API, Berechtigungen, Workflow oder Geschäftslogikfehler.

Fehler, die das Modell durch Ändern von Argumenten beheben kann, sollten als Fehler bei der Toolausführung zurückgegeben werden.

### 10.2. Fehlerstruktur

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "User cannot edit issues in project bank-site.",
    "field": null,
    "retryable": false,
    "details": {
      "project": "bank-site",
      "required_permission": "edit_issues"
    }
  }
}
```

### 10.3. Empfohlene Codes

```text
VALIDATION_ERROR
NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
REDMINE_API_ERROR
TIMEOUT
FILE_TOO_LARGE
UNSUPPORTED_MEDIA_TYPE
INVALID_STATE
PARTIAL_FAILURE
INTERNAL_ERROR
```

### 10.4. Die Nachricht muss reparierbar sein

Schlecht:

```text
Ungültige Anfrage.
```

Gut:

```text
Feld status_id muss einer von [2, 4, 7] für tracker_id=3 im Projekt bank-site sein.
Rufe redmine_list_allowed_issue_transitions auf, um aktuelle Werte abzurufen.
```

Stack-Trace nicht an den Benutzer zurücksenden. Der Stack-Trace wird nur im geschützten Serverprotokoll mit Korrelations-ID gespeichert.

---

## 11. Paginierung und Datenvolumen

### 11.1. Listen-/Suchtools

OBLIGATORISCHE Parameter:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Für die vorhandene Redmine-API ist `offset` zulässig. Für eine benutzerdefinierte Implementierung wird ein undurchsichtiger Cursor bevorzugt, wenn sich Daten während des Durchlaufs aktiv ändern können.

### 11.2. Paginierungsmetadaten

Das Ergebnis muss Folgendes enthalten:

- tatsächliches `limit`;
- `offset` oder `next_cursor`;
- `has_more`;
- `total_count`, wenn die Ermittlung keine signifikante Last erzeugt.

### 11.3. Feldauswahl

Der Parameter `fields` ist nur als Array aus geschlossener Zulassungsliste erlaubt:

```json
"fields": {
  "type": "array",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": ["id", "subject", "status", "assignee", "updated_at"]
  }
}
```

Ohne Zulassungsliste können keine beliebigen Feldnamen direkt an SQL, ActiveRecord `select`, Serializer oder Redmine API übergeben werden.

### 11.4. Große Ergebnisse

Große Zeitschriften, Anhänge und Dateien müssen:

- eine separate Paginierung haben;
- durch separates Tool/Ressource zurückgegeben werden;
- Geben Sie für Binärdaten nach Möglichkeit einen Ressourcenlink oder eine andere begrenzte Referenz zurück, anstatt große Base64-Daten als Antwort einzubetten.
- oder unterstützen Sie die aufgabenerweiterte Ausführung, wenn der Vorgang wirklich langwierig ist und der Client dies unterstützt.

`execution.taskSupport` wird nicht automatisch gesetzt. Die Standardeinstellung ist `forbidden`.

---

## 12. Referenz für ein neues Tool

Abgekürztes Schreibtool-Beispiel mit obligatorischem `title` und typisiertem `outputSchema` gemäß §7.1. Fehlerformat — §10. Vollständiges JSON — in Anhang B.

```json
{
  "name": "redmine_create_issue",
  "title": "Redmine-Vorgang erstellen",
  "description": "Erstellt einen Vorgang in einem Redmine-Projekt. Rufe redmine_list_project_trackers und redmine_list_project_issue_custom_fields auf, wenn gültige IDs unbekannt sind.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Projekt-ID als Zeichenfolge oder Projektkennung. Rufe redmine_list_projects auf, wenn der Wert unbekannt ist.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Vorgangs-Betreff."
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer", "minimum": 1},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  }
}
```

---

## 13. Testen

### 13.1. Schematests

Für jedes Werkzeug PFLICHT:

- mindestens ein gültiger Anruf;
- mindestens ein negativer Aufruf (z. B. fehlendes Pflichtfeld oder falscher Typ).

SOLLTE Folgendes abdecken, soweit es für das Schema gilt:

- vollständig gültiger Anruf;
- Fehlen jedes erforderlichen Feldes;
- falsche Art von Schlüsselparametern;
- unbekanntes Zusatzfeld;
- Wert außerhalb der Enumeration;
- Wert außerhalb des Bereichs;
- falsches Datum/Uhrzeit;
- Überschreitung von `maxItems`, `maxLength` und Dateigröße;
- Verletzung der Feldabhängigkeit (beide XOR-Felder gleichzeitig; keines der obligatorischen Paare).

### 13.2. Berechtigungstests

Bei Schreib-, destruktiven und sensiblen Lesevorgängen SOLLTE Folgendes überprüft werden:

- Benutzer ohne Projektzugriff;
- Benutzer mit schreibgeschütztem Zugriff;
- Benutzer mit Bearbeitungsberechtigung;
- Administrator, wenn das Tool Admin-Szenarien berührt;
- Zugriff auf private Notizen, wenn das Tool diese zurückgibt oder ändert;
- Versuchen Sie, das Objekt eines anderen Projekts über die ersetzte ID zu ändern.

Für einfache schreibgeschützte Tools ohne sensible Daten KÖNNEN Berechtigungstests auf ein negatives Szenario beschränkt oder mit kurzer Begründung im MR weggelassen werden.

### 13.3. Idempotenztests

Für `idempotentHint: true` SOLLTE ein automatischer oder manueller Test von zwei oder mehr identischen sequentiellen Aufrufen erfolgen.

Prüfen Sie das Fehlen von Nebenwirkungen, die als idempotent behauptet werden, z. B.:

- zusätzliche Tagebucheinträge;
- wiederholte E-Mails;
- Dateiduplikate;
- Beziehungsduplikate;
- wiederholte Zeiteinträge;
- zusätzliche Webhook-Ereignisse, sofern Teil der Garantie.

### 13.4. Vertragstests

SOLLTE `tools/list` als Snapshot speichern oder anderweitig nicht abwärtskompatiblen Vertragsänderungen nachverfolgen. CI KANN Folgendes erkennen:

- Namensänderung;
- Parameterentfernung;
- Typänderung;
- Änderung von `required`;
- Erhöhung des Annotation-Risikoniveaus;
- Verschwinden von `outputSchema`;
- inkompatible Änderung von Feldern, Typen, `required`, `enum` / `const` oder Erfolgs-/Fehlerzweigen von `outputSchema`.

### 13.5. LLM-Auswahltests

Für ähnliche oder leicht zu verwechselnde Tools SOLLTE eine Reihe von Benutzeranforderungen und erwarteten Toolaufrufen vorhanden sein. Der vollautomatische LLM-Lauf kann durch statische Beispiele in MR oder Beschreibungsüberprüfung ersetzt werden.

Beispiele:

| Anfrage | Erwartetes Tool |
|---|---|
| „Vorgang 123 anzeigen“ | `redmine_get_issue` |
| „Vorgänge zu OAuth finden“ | `redmine_search_issues` |
| „Beobachter 15 zu Vorgang 123 hinzufügen“ | `redmine_add_issue_watcher` |
| „Beziehung zwischen Vorgängen löschen“ | `redmine_delete_issue_relation` |
| „Ähnliche Vorgänge finden“ | `redmine_advanced_search_semantic_search_issues` |

Der Test oder die Überprüfung schlägt fehl, wenn das Modell mit hoher Wahrscheinlichkeit ein universelles destruktives Werkzeug für die schreibgeschützte Absicht wählt oder gezwungen ist, `action`-Werte zu erraten.

### 13.6. Fehlerbehebungstests

SOLLTE überprüfen, ob das Modell nach typischen Fehlern genügend Informationen für einen korrekten Wiederholungsversuch erhält:

- fehlender Ausweis;
- ungültiger Status;
- `expected_updated_at` conflict;
- unzureichende Berechtigungen;
- Grenze überschritten;
- falscher MIME-Typ.

---

## 14. Checkliste zur Codeüberprüfung

Ein neues Tool kann erst dann zusammengeführt werden, wenn alle Pflichtelemente mit „Ja“ beantwortet wurden.

### Zweck

- [ ] Eine Aktion; keine `action`/`manage` von Mischvorgängen (§3.1–3.2).
- [ ] Vom gewöhnlichen Verwaltungsbetrieb getrennt.

### Name und Beschreibung

- [ ] Name beginnt mit `redmine_`: core — `redmine_<verb>_<entity>`; Drittanbieter-Plugin – `redmine_<plugin_id>_…` (§4.1).
- [ ] Beschreibung: Zweck, Nebenwirkungen, kurzes Ergebnis; ähnliche Werkzeuge unterscheidbar (§5).
- [ ] Querverweise auf andere Tools verwenden vollständige Namen aus `tools/list` (§5.2.1).

### Quellenvertrag-Recherche

- [ ] Für Kerntool REST-API der Ressource, Versionen und Plugins bei Bedarf studiert; Abdeckungsbericht SOLLTE an MR angehängt werden (§5.6–5.7).
- [ ] Für Erweiterungstool MÜSSEN Quellserialisierer/Dienst/REST-Endpunkt und mindestens eine tatsächlich erfolgreiche Antwort für jedes Ergebnisformular überprüft werden (§18.5).
- [ ] Vertrag mit aktuellem `tools/list` verglichen.

### Input-Schema

- [ ] Schema entspricht §6 (`additionalProperties: false`, Typen, `required`, `enum`/`const`, Einschränkungen).
- [ ] Jeder Parameter hat aussagekräftige `description` (§6.14); `*_id` hat `minimum: 1` (§4.3).
- [ ] Für `*_id` und andere Suchwerte wird der Erkennungspfad angegeben (§6.16): Listentool, Get/List-Antwortfeld oder `enum`.
- [ ] „Genau eines von …“ / voneinander abhängige Einschränkungen im Schema formalisiert, nicht nur in der Beschreibung (§5.3, §6.12).
- [ ] Optimistisches Sperren – nur `expected_updated_at`, nicht `updated_at` (§4.4).
- [ ] Für optionale Felder `set_*` wird beim Löschen entschieden: `null`, separates Löschtool oder explizite Ablehnung (§6.13).
- [ ] Kein `fields` und beliebige `payload`/„Nutzlast“.
- [ ] `*_id` — Ganzzahl; Serverseitige Validierung gemäß §3.4.

### Ausgabe und Fehler

- [ ] Neues Tool verfügt über `outputSchema` mit Erfolgs-/Fehlerumschlag (§7.1–7.2).
- [ ] Bekannte stabile Ergebnisfelder, beschrieben in `properties`; `additionalProperties: true` wird nicht anstelle eines bekannten Vertrags verwendet.
- [ ] Alle garantierten Felder sind `required`.
- [ ] Nullable- und optionale Felder werden bewusst unterschieden.
- [ ] `enum`/`const`, `date`/`date-time`, Bereiche und andere bekannte Einschränkungen, die im Schema formalisiert sind.
- [ ] Für monetäre und andere numerische Geschäftswerte sind Einheiten, Währung und Haupt-/Nebeneinheiten klar.
- [ ] Geschäftsinvarianten des Ergebnisses, die im Schema (`const`, `enum`, `required` oder bedingtes Schema) widergespiegelt werden und nicht nur aus dem Toolnamen abgeleitet werden.
- [ ] Beschreibung, `outputSchema` und tatsächliche Handler-/REST-/Dienstantwort widersprechen nicht (§7.1.1).
- [ ] Interne REST/Ruby/Plugin-Werte normalisiert auf stabilen MCP-Vertrag; Kein STI-/Klassennamen- oder gebietsschemaabhängiger Formatverlust (§3.3).
- [ ] Das Listentool gibt eine kurze, aber ausreichende Struktur zurück. Die Beschreibung erklärt korrekt, wann das entsprechende Get-Tool wirklich benötigt wird.
- [ ] Fehler: `isError`, stabiler Code, behebbare Meldung; keine Geheimnisse oder Stacktrace (§10).

### Anmerkungen

- [ ] Anmerkungen entsprechen dem Risiko (§8); Test empfohlen für `idempotentHint: true`.

### Sicherheit

- [ ] Berechtigungen, Dateipfad, SSRF, Grenzwerte, Protokolle, Zerstörung/Prüfung – gemäß §9; Anhang A Muster nach Bedarf.

### Tests

- [ ] Mindestschematests; Ruhe auf Risiko (§13).

---

## 15. Kompatibilität und Änderung bestehender Tools

### 15.1. Nicht abwärtskompatiblen Änderungen

Nicht abwärtskompatiblen Änderung:

- Werkzeug umbenennen;
- Feldentfernung;
- Typänderung;
- Hinzufügen eines neuen Pflichtfeldes;
- sich ändernde Feldbedeutung;
- inkompatible Ausgabeänderung;
- mehrere Vorgänge zu einem zusammenfassen;
- Erhöhung des Risikos ohne Aktualisierung von Anmerkungen und Dokumentation.

### 15.2. Namensmigration

Bei der Migration beispielsweise vom alten Präfix `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

zum Kurzpräfix `redmine_`:

```text
redmine_get_issue
```

folgen:

1. neuen Namen hinzufügen;
2. alten Alias vorübergehend beibehalten;
3. altes Tool in der Beschreibung als veraltet markieren **oder nicht in `tools/list` veröffentlichen**, wenn der Alias nur für `tools/call` benötigt wird;
4. Metriken alter Namensaufrufe sammeln (das vorhandene Audit-Log nach aufgerufenem Tool-Namen ist ausreichend);
5. Alias nach vereinbarter Frist entfernen (nicht vor der nächsten Major-Version, sofern kein anderer Zeitraum vereinbart wurde);
6. `notifications/tools/list_changed` senden, wenn der Server `listChanged` deklariert.

Aktuelle Beispiele (siehe [03-core-tools.md](03-core-tools.md)): `redmine_list_all_users` → `redmine_admin_list_users`; `redmine_list_files` → `redmine_list_project_files`; `redmine_delete_file` → `redmine_delete_attachment`; `redmine_get_server_info` → `redmine_get_mcp_info`. Ein Alias wird in `tools/call` akzeptiert und nicht in `tools/list` veröffentlicht.

### 15.3. Beschreibungen ändern

Die Beschreibung wirkt sich auf die Auswahl des Modellwerkzeugs aus und gilt als Verhaltensänderung. Bei erheblichen Änderungen in der Beschreibung SOLLTEN die LLM-Auswahlbeispiele überprüft oder eine erneute Auswahlüberprüfung durchgeführt werden.

### 15.4. Serverversion

Die MCP-Plugin-Version wird von `redmine_get_mcp_info` (oder Server-Metadaten) zurückgegeben. Fügen Sie nicht `v1` oder `v2` zu jedem Namen hinzu, ohne dass die Unterstützung paralleler inkompatibler Verträge wirklich erforderlich ist.

---

## 16. Regeln für aktuelle Redmine MCP-Probleme

Bei der Entwicklung neuer Tools ist es verboten, Muster aus der Prüfung des aktuellen Vertrags zu wiederholen. Kanonische Regeln finden Sie in den entsprechenden Abschnitten; Unten ist nur eine Problemkarte:

| Audit-Problem | Abschnitt |
|---|---|
| Namen ohne `redmine_`-Präfix (einschließlich Drittanbieter-Plugins) / gemischter Stil innerhalb eines Plugins | §4.1 |
| Verb stimmt nicht mit Semantik überein (`complete_*` mit `done=true/false` statt `set_*`) | §4.2 |
| Numerische ID ohne `minimum: 1` oder mit „Issue id“-Beschreibung | §4.3 |
| Optimistische Sperre als `updated_at` statt `expected_updated_at` | §4.4, A.2 |
| Universelles `manage_*` / `patch_*` und `action`-Parameter | §3.1, §4.2 |
| Parameter ohne `type`, enum nur in Beschreibung, Arrays ohne `items` | §5.3, §6 |
| Parameter ohne `description`; zu kurze Beschreibungen ohne Lookup-Tool-Referenz | §6.14 |
| Keine `examples` bei Referenzparametern und Bezeichnern | §6.15 |
| Schreibtool mit `*_id` ohne Erkennungspfad (kein Listentool und keine Optionen in Get-Antwort) | §6.16 |
| Beschreibung verspricht „genau eines von A oder B“, Schema codiert es nicht | §5.3, §6.12 |
| Kurze Toolnamen in Querverweisen (`list_projects` statt `redmine_list_projects`) | §5.2.1 |
| Überladene Tool-Beschreibung über eine halbe Seite | §5.2 |
| `fields` / `extra_fields` ohne Schema; zusätzliche `required` | §6.4, §6.11 |
| `set_*` ohne Möglichkeit zum Löschen und ohne explizite Ablehnung | §6.13 |
| Ein Annotationssatz für alle Schreibtools; übermäßiges `openWorldHint` | §8 |
| `destructiveHint: true` bei gewöhnlichem `update` / `rename`; falsches `openWorldHint` bei `create_*` | §8.1, §8.2 |
| Beschreibung verspricht Antwortstruktur, aber `outputSchema` fehlt oder beschreibt nur beliebiges Objekt | §7.1 |
| Beschreibung, Schema und tatsächliche Antwort widersprechen sich | §7.1.1 |
| STI/Klassennamen oder Locale-Daten in MCP-Antwort | §3.3 |
| `additionalProperties: true` statt bekannter List-/Get-Felder | §7.1 |
| Beliebiger `file_path`, Projektumgehung, SSRF | §9 |
| E-Mail/externer Effekt in einem Tool mit lokaler Änderung | §3.2 |
| Mehrdeutige Paare ähnlicher Tools | §5.4 |

---

## 17. Struktur des Werkzeugsatzes

Die vollständige aktuelle Werkzeugliste ist in diesem Dokument nicht dupliziert – sie veraltet schnell.

**Quelle der Wahrheit:**

- Kernwerkzeuge – [03-core-tools.md](03-core-tools.md) und tatsächliche `tools/list` in der Installation;
- Drittanbieter-Plugin-Tools – §18 und MCP-Antwort `tools/list` bei der Installation.

**Gruppierungsprinzipien** (jede Gruppe – separate atomare Werkzeuge gemäß §3):

| Gruppe | Beispiel-Intents | Präfix |
|---|---|---|
| Vorgänge | get, list, search, create, update, delete, copy, Untervorgänge | `redmine_` |
| Beziehungen und Beobachter | Beziehung listen/erstellen/löschen; Beobachter hinzufügen/entfernen | `redmine_` |
| Projekte und Mitglieder | Projekte, Module, Mitglieder, Rollen | `redmine_` |
| Versionen und Kategorien | Versionen; Vorgangskategorien | `redmine_` |
| Zeiteinträge | list, create, update, import, Aktivitäten | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| Dateien und Anhänge | list, upload, delete, download | `redmine_` |
| Administration | Benutzer, Rollen, MCP-Sitzungsinfo | `redmine_admin_` oder `redmine_get_mcp_info` |
| Plugin-Entitäten | Checklisten, Suche usw. | `redmine_` + `plugin_id`, z. B. `redmine_advanced_search_` |

Bevor Sie ein neues Tool hinzufügen, SOLLTEN Sie die MCP-Antwort `tools/list` und die entsprechende Gruppe überprüfen: Vorhandenes Tool nicht duplizieren und keine unterschiedlichen Absichten in einem Namen vermischen.

Wenn eine Gruppe über ein Schreibtool mit ID-Parametern (`status_id`, `role_ids`, …) verfügt, MUSS dieselbe Gruppe über einen Erkennungspfad verfügen (§6.16).

Verwaltungstools werden nur für Benutzer mit den erforderlichen Rechten veröffentlicht (§9.1).

---

## 18. Plugin-Erweiterungen von Drittanbietern

Abschnitt für Autoren von Redmine-Plugins, die Tools über die Erweiterungs-API hinzufügen. Technische Beschreibung von API, Hooks und Randfällen – in [04-extensions.md](04-extensions.md).

Erweiterungen folgen denselben Vertrags-, Sicherheits- und Namensregeln (§3–§10, §4.1) wie die Kerntools von `redmine_mcp`.

### 18.1. Wann was veröffentlichen?

| Primitive | Wann verwenden |
|---|---|
| **Tool** | Eine Aktion auf Plugin-Entität oder Redmine: create, get, update, delete, search |
| **Resource** | Große oder statische Inhalte über stabile URI: Wiki-Text, Datei, langer Bericht |
| **Prompt** | Wiederholbares Szenario-Template für den Benutzer, kein Vorgang mit Nebenwirkung |
| **`extend_tool`** | Parameter oder Hook, logisch Teil eines bestehenden Kerntools (z. B. `include_*` beim Lesen eines Vorgangs) |

Wenn das Modell die Absicht mit einem separaten Tool erfüllen kann, ohne die `action` zu erraten, bevorzugen Sie **eigenes Tool**, nicht `extend_tool`, das ein anderes Schema aufbläht.

### 18.2. Anmeldung

- Die Erweiterungsdatei wird beim Start von Redmine geladen: `lib/<plugin_id>/mcp.rb` (siehe `ExtensionLoader`).
- Modul in `mcp.rb` MUSS `PluginName::Mcp` sein (`extend RedmineMcp::ExtensionApi`): Zeitwerk leitet Namen aus Datei ab.
- SOLLTE vor der Registrierung `mcp_extension_enabled?` überprüft werden – eine starke Abhängigkeit von `redmine_mcp` in gemspec ist nicht erforderlich.
- Verwenden Sie `register_tool_once` für die Registrierung, damit beim erneuten Laden kein Duplikat des Tools entsteht.
- Der vollständige Name in `tools/list` MUSS mit `redmine_` beginnen (§4.1).
- Das Tool MUSS über `title`, `description`, `input_schema`, `output_schema`, `permission` und `annotations` verfügen. Namensvervielfältigung verboten.
- Das Tool ist in der MCP-Antwort `tools/list` nur für Benutzer mit entsprechender Berechtigung sichtbar.

### 18.3. Benennung

- Der Name MUSS mit `redmine_` beginnen; dann – `plugin_id` und `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verben und `manage_*`-Verbot – gemäß §4.2 und §3.1.
- Kopieren Sie keine Kernwerkzeugnamen und veröffentlichen Sie kein zweites Werkzeug mit derselben Absicht unter einem anderen Namen.

Vor der Registrierung SOLLTE ein Vergleich mit der Antwort `tools/list` bei der Zielinstallation durchgeführt werden.

### 18.4. Berechtigungen und Sicherheit

- `permission` MUSS echten Redmine- oder Plugin-Berechtigungen entsprechen, nicht einer separaten „nur MCP“-Rolle.
- Für Issue-Vorgänge SOLLTEN `register_issue_tool` und `find_accessible_issue` verwendet werden, anstatt Sichtbarkeits- und Projektmodulprüfungen zu kopieren.
- Wenn `module_name` festgelegt ist, MUSS das Tool nur dann in `tools/list` enthalten sein, wenn der Benutzer die Berechtigung für mindestens ein sichtbares Projekt mit aktiviertem Modul erklärt hat. Ohne `module_name` reicht die Berechtigung in mindestens einem sichtbaren Projekt aus. Der Handler prüft weiterhin bestimmte Probleme, einschließlich seines Projektmoduls.
- Wiederholte serverseitige Argument- und Berechtigungsvalidierung im Handler – gemäß §3.4 und §9, auch wenn das Tool für andere Benutzer aus `tools/list` ausgeblendet ist.

### 18.5. Saubere Umsetzung

**Dünne MCP-Schicht.** `mcp.rb` sollte hauptsächlich die Tool-Registrierung enthalten: Schemata, Beschreibungen, Berechtigungen, Anmerkungen und kurze Handler. Der Handler validiert Argumente, prüft den Kontext und delegiert die Ausführung an eine separate Klasse/einen separaten Dienst.

Die Plugin-Geschäftslogik sollte in gewöhnlichen Modellen und Diensten verbleiben und nicht von MCP abhängen.

Wenn Logik nur für MCP benötigt wird – z.B. Daten aus mehreren Modellen zusammenführen, REST-Antworten auf MCP-Verträge normalisieren, abgeleitete Felder berechnen oder Tool-Ergebnisse vorbereiten – KANN in eine separate Datei `mcp_tools.rb` verschoben werden. Wenn eine solche Datei groß wird, SOLLTE sie nach Entität oder Operation in Klassen aufgeteilt werden, z. B. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Platzieren Sie Geschäftslogik und große Transformationen nicht direkt in Lambda/Handler in `mcp.rb`.

**Datenzugriff.**

- Plugin-Modelle und -Dienste – wenn die Logik bereits vorhanden ist.
- `internal_request` / `internal_get` / REST — wenn ein vorhandener API-Controller wiederverwendet werden muss; Endpunkt muss `accept_api_auth` unterstützen. `internal_request` für `POST`, `PUT`, `PATCH` und `DELETE` verwenden; `internal_get` oder `internal_request(method: 'GET', ...)` für Lesevorgänge. Fehler mit `internal_request_error?` prüfen.

**`extend_tool` — mäßig.** Geeignet, wenn der Parameter Teil einer Absicht mit dem Kerntool ist. Unangemessen, wenn das Plugin im Wesentlichen ein separates Subsystem hinzufügt: besser eigenes Präfix und eigene Tools, Link zum in der `description` oder in den Serveranweisungen beschriebenen Kern.

**Vertrag wie Kern.** Eingabe – gemäß §6. Ausgabe – gemäß §7.1 und §7.1.1: stabile Felder, `required`, `enum`/`const`, Einheiten, interne API-Normalisierung. Anmerkungen nach Risiko, behebbare Fehler (§8, §10). Optimistisches Sperren – `expected_updated_at` (§4.4). Jeder Parameter – `description` (§6.14). Querverweise – vollständige Namen (§5.2.1). Jeder Schreibparameter `*_id` – Erkennungspfad (§6.16): separate `list_*` oder Optionen mit `id` in der Get/List-Antwort und expliziter Verweis in der Parameterbeschreibung.

Vor der Veröffentlichung des Erweiterungstools MUSS der Quellserialisierer/Dienst/REST-Endpunkt und mindestens eine tatsächlich erfolgreiche Antwort für jedes Ergebnisformular überprüft werden.

**Gemeinsamer Code – in `redmine_mcp`.** Wenn bei der Entwicklung einer Erweiterung ein Fragment möglicherweise von einem anderen MCP-Plugin benötigt wird, SOLLTE es sofort zum Kern `redmine_mcp` hinzugefügt und nicht nach `lib/<plugin>/mcp*.rb` kopiert werden.

Kriterium: Die Logik ist nicht an eine Plugin-Domäne gebunden (Checklisten, Suche usw.) und beschreibt den MCP-Vertrag, die Erweiterungs-API oder ein typisches Integrationsmuster.

| Wo | Was |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, `ExtensionApi`-Erweiterung (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, gemeinsame Berechtigungs-Helfer nach `issue_id` / `project_id` |
| **Plugin-Erweiterung** | `mcp.rb` — Tool-Registrierung und kurze Handler; `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-spezifisches Abrufen, Aggregation, Normalisierung; gewöhnliche Modelle/Dienste — Geschäftslogik ohne MCP-Abhängigkeit |

**Empfohlene Platzierung für Erweiterung:**

- `mcp.rb` — Tool-Registrierung und kurze Handler;
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-spezifisches Abrufen, Aggregation und Daten-Normalisierung;
- Gewöhnliche Modelle/Dienste – Geschäftslogik, die nicht von MCP abhängt.

Bevor Sie den Helfer von einer anderen Erweiterung kopieren, SOLLTEN Sie prüfen, ob ein Analogon bereits in `redmine_mcp` vorhanden ist; falls nicht vorhanden – in demselben PR zum Kern verschieben, nicht duplizieren.

Mehr zur Erweiterungs-API – [04-extensions.md](04-extensions.md) (§ „ExtensionApi-Hilfsmethoden“).

### 18.6. Anti-Muster

VERBOTEN oder nicht empfohlen:

- Registrieren von Tools bei jeder HTTP-Anfrage;
- Fehler bei Nachbar-Plugin beim Start fehlgeschlagen;
- Mischen von Lese-, Schreib- und Verwaltungsfunktionen in einem Tool;
- Duplizieren des Kerntools „mit anderem Namen“;
- Erweiterung eines weiteren Tools um optionale Parameter „für die Zukunft“;
- Rückgabe von MCP-internen Feldern, die für den Benutzer in der Plugin-UI/API nicht verfügbar sind;
- Veröffentlichung von STI-Klassennamen, Gebietsschemadaten oder REST-Darstellungen, wenn das MCP-Schema einen anderen Vertrag definiert (§3.3, §7.1.1);
- Listenelement nur als `{ "type": "object", "additionalProperties": true }`: „object“, „additionalProperties“: true }“ beschreiben (§7.1);
- Veröffentlichung von `set_*_status` / ähnlich mit `status_id`, ohne dem Modell die Möglichkeit zu geben, zulässige IDs zu kennen (§6.16);
- Duplizieren allgemeiner MCP-Helfer in der Erweiterung (Envelope `outputSchema`, `internal_request`-Wrapper, Ausgabeberechtigung), wenn ihr Platz in `redmine_mcp` liegt – siehe §18.5.

### 18.7. Überprüfung vor dem Zusammenführen

- [ ] Der Toolname beginnt mit `redmine_` gemäß §4.1 / §18.3.
- [ ] Erweiterung lädt beim Start; Das Tool erscheint in `tools/list` für Benutzer mit Rechten.
- [ ] Tool fehlt für Benutzer ohne Rechte und wenn das Plugin-MCP-Erweiterungsflag deaktiviert ist.
- [ ] Vertrag und Checkliste (§14) erfüllt, einschließlich Beschreibung/Ausgabeschema/tatsächlicher Antwortvergleich (§7.1.1); Tests gemäß §13 bei Bedarf.
- [ ] Serialisierer/REST/Dienst, überprüft auf mindestens eine wirklich erfolgreiche Antwort für jedes veröffentlichte Ergebnisformular (z. B. auflisten und abrufen, wenn beide veröffentlicht sind).
- [ ] Keine Duplizierung des vorhandenen Tools in `tools/list`.
- [ ] Für jeden `*_id`-Schreibparameter gibt es einen Erkennungspfad (§6.16).

---

## 19. Quellen und normative Grundlage

Dokument erstellt am 22.07.2026 basierend auf den folgenden Primärquellen:

1. Modellkontextprotokoll, **Protokollrevision 25.11.2025**
   https://modelcontextprotocol.io/specification/2025-11-25

2. Modellkontextprotokoll, **Tools**
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Modellkontextprotokoll, **Schemareferenz**
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Modellkontextprotokoll, **Best Practices für die Sicherheit**
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Modellkontextprotokoll, **Grundlegendes zur Autorisierung in MCP**
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog, **Tool-Anmerkungen als Risikovokabular: Was Hinweise können und was nicht**
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Serveranweisungen: Geben Sie LLMs ein Benutzerhandbuch für Ihren Server**
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON-Schema, **Referenz**
   https://json-schema.org/understanding-json-schema/reference

9. JSON-Schema, **Aufzählungswerte**
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON-Schema, **Bedingte Schemavalidierung**
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **REST-API-Übersicht**
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **REST-Probleme**
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **REST-API-Änderungen**
Verknüpfen Sie `API changes for each version` auf der REST-API-Seite. für alle unterstützten Versionen überprüft.

---

## 20. Neues Werkzeugbereitschaftskriterium

Ein neues MCP-Tool gilt als bereit, wenn die obligatorischen Pflichtpunkte der Code-Review-Checkliste (§14) erfüllt sind.

Für Drittanbieter-Plugin-Tools zusätzlich – Checkliste §18.7.

Risikoempfehlungen: Abdeckungsbericht (§5.7), zusätzliche Tests §13.2–13.6 und Anhang A. Mindestschematests (§13.1) und `outputSchema`-Regeln (§7.1, §7.1.1) sind obligatorisch.

---

## Anhang A. Empfohlene Implementierungsmuster

Die folgenden Muster sind nicht für jedes MCP-Tool obligatorisch. SOLLTEN sie wegen eines erhöhten Risikos in Betracht ziehen: destruktive Vorgänge, Admin-Tools, Massenschreibvorgänge, externe Nebenwirkungen, wiederholte Aufrufe aufgrund von Zeitüberschreitungen.

### A.1. Zweistufiges Löschen (vorbereiten/bestätigen)

Für besonders gefährliche Verwaltungsvorgänge:

1. `redmine_prepare_delete_*` liefert eine kurze Beschreibung der Folgen und ein Einmal-Token;
2. `redmine_confirm_delete_*` akzeptiert das Token mit kurzer TTL.

Normative Anforderungen für destruktive Operationen – in §9.5.

### A.2. Optimistische Sperre

Zum Aktualisieren/Löschen bei gleichzeitiger Änderung MUSS der Parameter `expected_updated_at` (§4.4) und nicht `updated_at` heißen:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Lehne die Operation ab, wenn das Objekt nach diesem Zeitstempel geändert wurde."
}
```

Der Name ist für Kerntools und Erweiterungen (einschließlich Tools zum Schreiben von Checklisten) einheitlich.

Bei einem Konflikt werden `CONFLICT`, die tatsächliche Objektänderungszeit (`updated_at` / `updated_on` als Antwort) und die Empfehlung zurückgegeben, das Objekt erneut zu lesen.

### A.3. Idempotenzschlüssel

Für Vorgänge, bei denen eine Wiederholung aufgrund einer Zeitüberschreitung zu Duplikaten führen kann:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Besonders geeignet für:

- Problemerstellung;
- Import von Zeiteinträgen;
- Datei-Upload;
- Massenoperationen;
- E-Mail-Versand.

Wenn das Tool `idempotentHint: true` veröffentlicht, muss der wiederholte Aufruf sicher sein (§8.2); `idempotency_key` ist eine Möglichkeit, dies sicherzustellen.

---

## Anhang B. Vollständiges Tool-Beispiel

Verweisen Sie auf `redmine_create_issue`. Wenn sich das Fehlerformat oder der Umschlag ändert, aktualisieren Sie §7, §10 und diesen Abschnitt. §12 bleibt gekürzt.

```json
{
  "name": "redmine_create_issue",
  "title": "Redmine-Vorgang erstellen",
  "description": "Erstellt einen Vorgang in einem Redmine-Projekt. Rufe redmine_list_project_trackers und redmine_list_project_issue_custom_fields auf, wenn gültige IDs unbekannt sind. Dieser Vorgang kann Benachrichtigungen erzeugen und ist nicht idempotent, es sei denn idempotency_key wird übergeben.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Projekt-ID als Zeichenfolge oder Projektkennung. Rufe redmine_list_projects auf, wenn der Wert unbekannt ist.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Vorgangs-Betreff."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Vorgangs-Beschreibung im Redmine-Textformat."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker-ID aus redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Vorgangs-Prioritäts-ID aus redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Benutzer-ID des Beauftragten aus redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Fälligkeitsdatum im Format YYYY-MM-DD.",
        "examples": ["2026-07-30"]
      },
      "custom_fields": {
        "type": "array",
        "maxItems": 100,
        "items": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {"type": "integer", "minimum": 1},
            "value": {
              "oneOf": [
                {"type": "string"},
                {"type": "number"},
                {"type": "boolean"},
                {
                  "type": "array",
                  "items": {"type": "string"}
                }
              ]
            }
          },
          "required": ["id", "value"]
        }
      },
      "idempotency_key": {
        "type": "string",
        "minLength": 8,
        "maxLength": 128
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer"},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  },
  "execution": {
    "taskSupport": "forbidden"
  }
}
```

Hinweis: Wenn der Server Idempotenz garantiert, wenn `idempotency_key` vorhanden ist, beschreibt die Annotation das Tool weiterhin als Ganzes. Daher bleibt der sichere Wert `false`, wenn ein Aufruf ohne Schlüssel zulässig ist.

