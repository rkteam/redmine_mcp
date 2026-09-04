# Extension API für andere Plugins

[Deutsch](04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Überblick

Redmine MCP stellt einen Erweiterungsmechanismus bereit, mit dem andere installierte Redmine-Plugins eigene Tools, Resources und Prompts registrieren und bestehende Tools erweitern können.

## Ziel

Einen einheitlichen Ansatz zur Integration von Redmine-Plugins mit AI bereitstellen, ohne einen MCP-Server zu duplizieren und ohne Änderungen am Redmine-MCP-Code.

## Betroffene Bereiche

- Plugins
- API
- Permissions

## Geschäftsregeln

### Automatische Erkennung

- Beim Redmine-Start (wenn MCP aktiviert ist) prüft das System alle installierten Plugins.
- Ein Plugin gilt als MCP-Erweiterung, wenn eine dieser Quellen gefunden wird:
  - **Erweiterung im Plugin selbst** — `mcp.rb` an einem dieser Pfade:
    - `lib/<plugin.id>/mcp.rb`;
    - `lib/<plugin directory basename>/mcp.rb`;
    - `lib/<plugin.id without redmine_ prefix>/mcp.rb`, wenn der Identifikator mit `redmine_` beginnt (typisches Schema wie `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`);
  - **eingebaute Integration in `redmine_mcp`** — Datei `lib/redmine_mcp/extensions/<plugin.id>.rb` im Plugin `redmine_mcp`, wenn das Ziel-Plugin installiert ist.
- Existieren beide Quellen für ein Plugin, wird zuerst die eigene Erweiterung des Plugins geladen. Die eingebaute Integration dient nur als Fallback, wenn das Laden von `mcp.rb` fehlschlägt. Bei erfolgreichem Laden von `mcp.rb` wird die eingebaute Integration nicht geladen und registriert tools/resources/prompts nicht erneut.
- Eine eingebaute Integration nutzt dieselbe Extension API wie `mcp.rb` eines Drittanbieter-Plugins; es gibt keinen separaten Registrierungsmechanismus.
- Das Plugin `redmine_mcp` lädt sich nicht selbst als Erweiterung.
- Plugins mit deaktivierter MCP-Erweiterungs-Checkbox in den Einstellungen werden übersprungen.
- Ein Fehler in der Erweiterung eines Plugins blockiert das Laden anderer nicht, einschließlich Syntaxfehler in der Erweiterungsdatei.

### Tool-Registrierung

- Ein Erweiterungs-Plugin kann beliebig viele Tools registrieren.
- Jedes Tool hat: Name, Beschreibung, Input-Schema, Output-Schema, Berechtigungsanforderung und Handler.
- Vollständiger Tool-Name: `redmine_<plugin_id>_<name>`, zum Beispiel `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Doppelte Tool-Namen sind verboten.
- Ein Tool erscheint in MCP nur für Benutzer mit den entsprechenden Berechtigungen.
- Ein vorgangsbezogenes Erweiterungs-Tool kann ein aktiviertes Redmine-Projektmodul erfordern (der Modul-Identifikator muss nicht der Plugin-ID entsprechen). In `tools/list` ist ein solches Tool sichtbar, wenn der Benutzer die deklarierte Berechtigung in mindestens einem sichtbaren Projekt mit diesem Modul hat. Ohne Modulanforderung genügt die Berechtigung in mindestens einem sichtbaren Projekt. Der Aufruf prüft weiterhin den konkreten Vorgang: Sichtbarkeit, Berechtigung in seinem Projekt und aktiviertes Modul; sonst liefert die Antwort „not found“.
- Schreib-Tools von Erweiterungen im MCP-Read-only-Modus führen den Handler nicht aus: die Verweigerung entspricht der für Core-Schreib-Tools.

### Erweitern bestehender Tools

- Ein Plugin kann ein bereits registriertes Tool erweitern.
- Eine Erweiterung kann:
  - zusätzliche Eingabeparameter hinzufügen;
  - Code vor dem Haupt-Handler ausführen;
  - Code nach dem Handler ausführen und das Ergebnis ändern.
- Mehrere Plugins können dasselbe Tool gleichzeitig erweitern.
- Zusätzliche Parameter werden ins gemeinsame Input-Schema zusammengeführt.
- Ein zusätzlicher Parametername darf nicht mit einem Core-Tool-Parameter oder dem Parameter einer anderen Erweiterung desselben Tools übereinstimmen.
- Das resultierende Schema wird vor der Veröffentlichung in `tools/list` normalisiert.
- Die Ausführungsreihenfolge der Erweiterungen entspricht der Plugin-Ladereihenfolge.

### Resource-Registrierung

- Ein Plugin kann Resources mit eindeutiger URI veröffentlichen. Erneute Registrierung derselben URI wird abgelehnt.
- Eine Resource muss einen Lese-Handler haben.
- Empfohlenes URI-Schema: `redmine://<plugin_id>/<type>/<id>`.
- Eine Resource kann Berechtigungsprüfungen erfordern; ohne Berechtigung ist die Resource nicht verfügbar.
- Berechtigungsprüfungen erhalten URI und Argumente. Das Projekt stammt aus `project` / `project_id`, aus der URI (`project`/`project_id` in Query oder `/projects/:id`-Segment) oder aus einem expliziten Project-Resolver der Erweiterung. `resources/read` übergibt `{uri: ...}` an die Prüfung.
- Ist in dem Aufruf ein Projekt angegeben, aber nicht gefunden oder für den aktuellen Benutzer nicht zugänglich, wird der Zugriff verweigert. Die Prüfung „mindestens ein Projekt“ gilt nur, wenn kein Projekt angegeben ist (Discovery mit leeren Argumenten).
- Das Lesen einer Resource liefert Inhalt im Text- oder JSON-Format.

### Prompt-Registrierung

- Ein Plugin kann Prompts mit Name, Beschreibung, Argumenten und Handler hinzufügen.
- Vollständiger Prompt-Name: `redmine_<plugin_id>_<name>`.
- Prompts sind für Benutzer mit den entsprechenden Berechtigungen verfügbar. Berechtigungsprüfungen erhalten Aufrufargumente, einschließlich `project` / `project_id`. Ist ein Projekt angegeben, aber nicht gefunden oder nicht zugänglich, wird der Zugriff verweigert; ohne angegebenes Projekt gilt dieselbe Discovery-Regel wie für Resources.

### Events (Hooks)

- Ein Plugin kann MCP-Lifecycle-Events abonnieren, zum Beispiel:
  - Tool-Registrierung;
  - Resource-Registrierung;
  - Prompt-Registrierung;
  - Abschluss des Ladens aller Erweiterungen.
- Ein Fehler in einem Event-Handler wird protokolliert und unterbricht den Hauptprozess nicht.

### Abhängigkeiten

- Ein erweiterndes Plugin muss keine harte Abhängigkeit von Redmine MCP deklarieren.
- Es wird empfohlen, vor der Registrierung `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` zu prüfen.
- Das erweiternde Plugin muss das MCP-Gem nicht einbinden — die Redmine-MCP-API genügt.

### Extension-API-Fähigkeiten

Über die Extension API kann ein Erweiterungs-Plugin:

- prüfen, dass MCP aktiviert ist und die Erweiterung nicht deaktiviert ist;
- ein Tool einmal registrieren (ohne Duplikat beim Reload);
- ein vorgangsbezogenes Tool mit Standard-Berechtigungsprüfungen und Vorgangssuche registrieren; ist der Vorgang vor dem Handler-Lauf verschwunden, liefert die Antwort „not found“, keinen internen Fehler;
- ein bestehendes Core-Tool mit Parametern und before/after-Handlern erweitern;
- Capability-Modi für `redmine_get_mcp_info` registrieren (z. B. `issue_search.semantic`);
- die Redmine- oder Plugin-REST-API in-process im Namen des aktuellen Benutzers über `internal_request` aufrufen (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; der Ziel-Endpunkt muss API-Auth akzeptieren); REST-Fehler werden auf kanonische MCP-Codes abgebildet ohne internen HTTP-Status der Anfrage;
- `outputSchema` im `{ ok, data | error }`-Hüllenformat veröffentlichen.

Die Ruby-API-Methodenliste und Codebeispiele stehen im Plugin-README und in [mcp_tool_development.md](mcp_tool_development.md) (Dev-Guide, kein Verhaltens-SPEC).

## Randfälle

- Ein Plugin ohne Erweiterungsdatei und ohne eingebaute Integration wird ignoriert.
- Existiert eine Erweiterungsdatei, schlägt aber `require` fehl — Log-Eintrag, Erweiterung gilt nicht als geladen; Tool-Registrierung ist Nebeneffekt eines erfolgreichen `require`.
- Versuch, ein nicht existierendes Tool zu erweitern — Fehler bei der Erweiterungsregistrierung.
- Ein Plugin mit deaktivierter MCP-Erweiterungs-Checkbox in den Einstellungen wird nicht geladen, auch wenn die Erweiterungsdatei existiert.
- Nach Installation einer neuen Erweiterung ist ein Redmine-Neustart erforderlich; der MCP-Client muss ggf. neu verbunden werden.

## Fehlerbehandlung

- Fehler beim Laden der Erweiterungsdatei — Log-Eintrag, Laden anderer Plugins fortsetzen.
- Fehler bei der Tool-Registrierung beim Start — Log-Eintrag.
- Fehler in einem Extension-`before`-Handler — bricht die Tool-Ausführung ab.
- Fehler in einem `after`-Handler — protokolliert; das Ergebnis des Haupt-Handlers bleibt erhalten, sofern der Handler den Kontrollfluss nicht geändert hat.

## Testszenarien

8. Resource- und Prompt-Discovery mit leeren Argumenten bleibt verfügbar, wenn die Berechtigung in mindestens einem Projekt existiert.
9. Ein Plugin mit `plugin.id` wie `redmine_*` und Datei `lib/<id without redmine_ prefix>/mcp.rb` gilt als MCP-integriert und erscheint in den MCP-Erweiterungseinstellungen.
10. Ein vorgangsbezogenes Tool mit Modulanforderung ist nicht in `tools/list` für einen Benutzer ohne sichtbares Projekt mit diesem Modul, auch wenn er die Berechtigung in einem anderen Projekt hat.
11. Ein Plugin ohne eigenes `mcp.rb`, aber mit installiertem Ziel-Plugin und Datei `lib/redmine_mcp/extensions/<plugin.id>.rb` in `redmine_mcp`, gilt als MCP-integriert und erscheint in den MCP-Erweiterungseinstellungen.
12. Hat ein Plugin sowohl ein eigenes `mcp.rb` als auch eine eingebaute Integration in `redmine_mcp`, sind bei erfolgreichem Laden von `mcp.rb` nur dessen tools/resources/prompts verfügbar; schlägt das Laden von `mcp.rb` fehl, versucht der Loader die eingebaute Integration.

## Erweiterungsbeispiele

| Plugin | Tool | Zweck |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Semantische Vorgangssuche |
