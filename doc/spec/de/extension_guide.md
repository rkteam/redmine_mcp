# MCP-Erweiterungen für Redmine-Plugins

[Deutsch](extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` ermöglicht anderen Redmine-Plugins, eigene MCP-Tools hinzuzufügen und bei Bedarf Resources, Prompts und Capabilities zu registrieren — ohne separaten MCP-Server und ohne Änderungen an `redmine_mcp` selbst.

## Funktionsweise

`redmine_mcp` stellt eine gemeinsame MCP-Registry bereit, in der Drittanbieter-Redmine-Plugins Tools über `RedmineMcp::ExtensionApi` registrieren.

Ein typischer Aufrufablauf:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` darf die Geschäftslogik eines Drittanbieter-Plugins nicht kennen: das Plugin registriert eigene Tools über die Extension API.

## Stabilität und Abwärtskompatibilität

Ab `redmine_mcp 1.0.0` gilt die öffentliche Extension API als stabil.

Nur Methoden und Verträge von `RedmineMcp::ExtensionApi`, die in diesem Leitfaden beschrieben sind, sind öffentliche API. Interne Klassen, Module und Methoden von `redmine_mcp`, die nicht als Teil der Extension API dokumentiert sind, sind keine öffentliche API und können ohne Abwärtskompatibilitätsgarantien geändert werden.

Innerhalb einer Major-Version von `redmine_mcp`:

- bestehende öffentliche Extension-API-Methoden werden nicht inkompatibel entfernt oder geändert;
- neue Methoden und optionale Parameter können hinzugefügt werden;
- veraltete Methoden werden zuerst markiert und bleiben mindestens bis zur nächsten Major-Version verfügbar;
- Änderungen, die Updates in Drittanbieter-Plugins erfordern, erscheinen nur in einer neuen Major-Version.

Alle Extension-API-Änderungen sind in `CHANGELOG.md` aufgeführt.

Drittanbieter-Plugins sollten die minimale erforderliche `redmine_mcp`-Version deklarieren und `CHANGELOG.md` beim Upgrade prüfen.

## Schnellstart

1. Erstellen Sie eine `mcp.rb`-Datei an einem dieser Pfade:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id without the redmine_ prefix>/mcp.rb`, wenn `plugin.id` mit `redmine_` beginnt
2. Definieren Sie das Modul `<PluginName>::Mcp`.
3. Erweitern Sie `RedmineMcp::ExtensionApi`.
4. Setzen Sie `plugin_id`.
5. Registrieren Sie das erste Tool.

Minimales vorgangsbezogenes Erweiterungsbeispiel:

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

Das Beispiel nutzt `register_issue_tool`, den empfohlenen Helper für Tools, die mit Vorgängen arbeiten. Der vollständige Tool-Vertrag steht in [mcp_tool_development.md](mcp_tool_development.md).

### Der Modulname `Mcp`

Die Erweiterungsdatei heißt `mcp.rb`. Zeitwerk leitet `Mcp` aus diesem Dateinamen ab — schreiben Sie daher `module Mcp`.

Tools werden registriert, wenn die Datei per require geladen wird. Der Loader sucht nicht nach dem Modul-Konstantennamen.

## Benennung

Für Tools und Prompts einen kurzen Namen verwenden:

```ruby
name: 'search_issues'
```

Der vollständige MCP-Name wird automatisch erzeugt:

```text
redmine_<plugin_id>_<name>
```

Für Tools bevorzugt `name` im Format `<verb>_<entity>`.

Bevorzugte Verben:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Verwenden Sie keine vagen `manage_*`, `process_*`, `handle_*` und keine Tools mit Parameter wie `action: create | update | delete`, wenn die Operationen in separate, klare Tools aufgeteilt werden können.

Beispiel:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Beginnt `plugin_id` bereits mit `redmine_` (z. B. `redmine_advanced_checklists`), folgt der vollständige Name weiterhin `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Für Resources eine eindeutige URI verwenden, zum Beispiel:

```text
redmine://<plugin_id>/<type>/<id>
```

Tool-/Prompt-Namen und Resource-URIs müssen eindeutig sein. Das Verhalten bei doppelter Registrierung hängt von der verwendeten Methode ab; `register_tool_once` registriert dasselbe Tool nicht zweimal.

## Tool-Registrierung

### Reguläres Tool

Verwenden Sie `register_tool_once`, wenn ein reguläres MCP-Tool benötigt wird, das nicht an einen bestimmten Vorgang gebunden ist.

Typische Fälle:

- Suche in Plugin-Daten;
- Zusammenfassung zurückgeben;
- serverseitige Validierung oder Berechnung.

Grundbeispiel:

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

Der vollständige Tool-Vertrag — `additionalProperties: false`, Risiko-Annotations und die Hülle über `SchemaNormalizer.envelope_output` — ist in [mcp_tool_development.md](mcp_tool_development.md) beschrieben.

### Vorgangs-Tool

Verwenden Sie `register_issue_tool`, wenn das Tool `issue_id` akzeptiert und mit einem Vorgang arbeitet.

Das ist die empfohlene Option für vorgangsbezogene Szenarien, weil es:

- den Vorgang über `Issue.visible(user)` findet;
- bei Bedarf das Projektmodul prüft;
- die angegebene Berechtigung im Vorgangsprojekt prüft;
- den gefundenen `issue` an den Block übergibt;
- einen Fehler zurückgibt, wenn der Vorgang nicht verfügbar oder nicht gefunden ist.

Siehe auch den Abschnitt Berechtigungen.

`module_name` in `register_issue_tool` ist ein optionaler Redmine-Projektmodul-Identifikator. Er muss nicht `plugin_id` entsprechen. Ist er gesetzt, erscheint das Tool in `tools/list` nur, wenn der Benutzer mindestens ein Projekt mit diesem Modul sehen kann und die deklarierte Berechtigung hat.

### Was der Handler zurückgibt

Der Handler gibt einen Erfolgs-Daten-Hash ohne Hülle zurück oder eine fertige Hülle `{ok: true, data: ...}` / `{ok: false, error: ...}`. Die Registry normalisiert das Ergebnis über `ToolResponse.from_handler_result`: ein einfacher Hash wird in `{ok: true, data: ...}` eingepackt; für Listen kann das fertige Ergebnis von `paginated_list` zurückgegeben werden, das bereits `data` und `meta` enthält.

Für Fehler verwenden Sie `RedmineMcp::Core::Helpers.error_result`, `mcp_error` oder `{ok: false, error: ...}`.

## Input-Schema

`SchemaNormalizer.normalize_input` normalisiert das Objektschema und fügt Service-Constraints hinzu, aber der öffentliche Parametervertrag muss explizit beschrieben werden.

Hauptregeln:

- jeder Parameter muss einen definierten Typ haben;
- numerische `*_id`-Felder verwenden `type: integer`, `minimum: 1` und eine Beschreibung mit Discovery-Pfad;
- endliche Wertemengen werden über `enum` / `const` definiert, nicht nur im Fließtext;
- Arrays müssen `items` haben;
- voneinander abhängige und sich ausschließende Felder werden über JSON Schema (`oneOf`, `if/then/else` usw.) definiert, nicht nur in der Beschreibung;
- optimistisches Locking verwendet `expected_updated_at`, nicht `updated_at`;
- `null` wird nur mit explizit dokumentierter Semantik verwendet, z. B. zum Leeren eines Felds;
- verwenden Sie keine offenen `fields`, `payload` oder `data` statt typisierter Geschäftsparameter;
- akzeptieren Sie kein Objekt als JSON-String;
- akzeptieren Sie keinen beliebigen `file_path` in einem öffentlichen Tool.

Vollständige `inputSchema`-Anforderungen stehen in [mcp_tool_development.md](mcp_tool_development.md).

## Output-Schema

Jedes neue Tool muss ein `output_schema` haben.

Für ein reguläres Ergebnis die Standardhülle verwenden:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Für Listen `SchemaNormalizer.list_envelope_output(item_schema)` verwenden.

Bekannte stabile Ergebnisfelder müssen explizit beschrieben werden. Verwenden Sie `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` nicht statt eines typisierten Vertrags, wenn die Antwortstruktur bekannt ist. Diese Schemas sind nur für wirklich offene oder instabile Strukturen akzeptabel.

Vollständige `outputSchema`-Anforderungen stehen in [mcp_tool_development.md](mcp_tool_development.md).

## Annotations

| Operationstyp | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | hängt von der Implementierung ab | `false` |
| delete / purge | `false` | `true` | nur wenn Wiederholung tatsächlich sicher ist | `false` |
| externer Nebeneffekt | `false` | hängt ab | meist `false` | `true` |

`destructive` bedeutet irreversiblen Datenverlust, nicht jede Schreiboperation.

`open_world` bedeutet, über die bekannte Redmine-Installation hinauszugehen, nicht das Erstellen eines neuen Objekts innerhalb von Redmine.

Annotations ersetzen keine Berechtigungsprüfungen im Handler.

## Berechtigungen

`permission` wird von der Registry für Tool-Verfügbarkeit und Vorprüfungen verwendet, ersetzt aber keine Zugriffsprüfungen für ein bestimmtes Objekt im Handler.

Für vorgangsbezogene Tools `register_issue_tool` verwenden, das Vorgangssichtbarkeit, Projektmodul und Berechtigung prüft.

Für andere Entitäten muss der Handler den Zugriff auf das gefundene Objekt erneut prüfen.

## Fehler

Verwenden Sie die standardmäßigen MCP-Fehlercodes:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Für Standardfehler die `error_result`-Helper verwenden.
Für einen benutzerdefinierten Code `mcp_error` verwenden.
Für optimistisches Locking `conflict_if_stale` verwenden.

Der Handler liefert einen strukturierten Fehler, keinen Stacktrace oder unbehandelte Exception.

## Eingebaute Helper

`RedmineMcp::Core::Helpers` enthält gemeinsame Helper, die wiederverwendet statt dupliziert werden sollten:

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

Fertige Schema-Fragmente sind ebenfalls verfügbar:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Prüfen Sie vor dem Erstellen eines eigenen Helpers, ob ein passender bereits in `redmine_mcp` existiert.

Prüfen Sie den aktuellen Helper-Satz in `RedmineMcp::Core::Helpers` und [04-extensions.md](04-extensions.md): diese Liste zeigt die wichtigsten verfügbaren Fähigkeiten und ersetzt nicht die ExtensionApi-API-Dokumentation.

## Read-only-Modus und Idempotenz

Mutierende Tools müssen den globalen Read-only-Modus respektieren:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Für Operationen, bei denen ein wiederholter Aufruf ein Duplikat erzeugen kann, können `idempotency_key` und `RedmineMcp::IdempotencyStore` verwendet werden.

`idempotentHint: true` ist nur erlaubt, wenn ein wiederholter Aufruf unter Berücksichtigung aller Nebeneffekte tatsächlich sicher ist.

## Code-Organisation

`mcp.rb` sollte hauptsächlich Tool-Registrierung enthalten: Schemas, Beschreibungen, Berechtigungen, Annotations und kurze Handler.

MCP-spezifisches Abrufen, Aggregieren und Datennormalisierung kann verschoben werden nach:

- `mcp_tools.rb`;
- bei wachsender Datei — `mcp_tools/*.rb`.

Reguläre Geschäftslogik bleibt in den Modellen/Services des Plugins und darf nicht von MCP abhängen.

Hat das Plugin bereits einen passenden REST-Endpunkt, der die benötigte Operation implementiert und Aufrufe im Namen des aktuellen Benutzers unterstützt, SOLLTE dieser über `internal_request` wiederverwendet werden (oder `internal_get` für read-only `GET`-Aufrufe).

Das ist die bevorzugte Option: MCP nutzt dieselben Berechtigungsprüfungen, Datenabrufe und Geschäftsverhalten wie die bestehende Plugin-API.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Für `POST`, `PUT` und `PATCH` einen JSON-Anfragebody-String übergeben (oder `nil`, wenn der Endpunkt keinen Body erwartet). Query-Parameter gehören in `params`.

Modell/Service direkt aufrufen, wenn:

- kein passender REST-Endpunkt existiert;
- der Endpunkt die benötigte Operation oder Daten nicht unterstützt;
- REST eine unnötige oder falsche Schicht für die Operation erzeugt;
- die gemeinsame Geschäftslogik bereits bewusst in einen Service extrahiert wurde und der REST-Endpunkt selbst nur ein dünner Wrapper ist.

Implementieren Sie dieselbe Geschäftslogik nicht separat für REST und MCP. Benötigen beide Schichten gemeinsame Logik, extrahieren Sie sie in einen gemeinsamen Service.

## Zusätzliche Fähigkeiten

`RedmineMcp::ExtensionApi` bietet außerdem:

| Methode | Wann verwenden |
|---|---|
| `register_resource` | MCP-Resource benötigt |
| `register_prompt` | MCP-Prompt benötigt |
| `register_capability` | Capability zu `redmine_get_mcp_info` hinzufügen |
| `extend_tool` | bestehendes Tool erweitern statt neues erstellen |
| `on` | Lifecycle-Hook benötigt |
| `internal_request` | Redmine- oder Plugin-REST-Endpunkt in-process als aktueller Benutzer aufrufen (`method`, `path`, optional `params` und `body`) |
| `internal_get` | Kurzform für `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | prüfen, ob ein In-Process-REST-Ergebnis eine MCP-Fehlerhülle ist |

Setzen Sie `plugin_id` einmal oben im Modul. Vor der Tool-Registrierung SOLLTE `mcp_extension_enabled?` geprüft werden, wenn die Registrierung durch die Erweiterung selbst erfolgt. Der standardmäßige `ExtensionLoader` lädt `mcp.rb` für deaktivierte Erweiterungen ebenfalls nicht.

### Erweitern eines bestehenden Tools

Verwenden Sie `extend_tool` nur, wenn ein separates Tool nicht passt.

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` läuft vor dem Handler, `after` danach. `extra_params` werden dem Input-Schema hinzugefügt. Parameternamen dürfen nicht mit dem Basis-Tool oder anderen Erweiterungen desselben Tools kollidieren.

Wird die Erweiterung aus dem `after_initialize` eines Plugins geladen, bevor `redmine_mcp` Core-Tools registriert, `extend_tool` für ein Core-Tool (z. B. `redmine_get_issue`) bis zum Ende der Initialisierung verzögern — verschachteltes `Rails.application.config.after_initialize` verwenden und zuerst `Registry.instance.tool(...)` prüfen.

## Laden und Deaktivieren einer Erweiterung

`redmine_mcp` sucht beim Redmine-Start automatisch nach der Erweiterungsdatei in den unterstützten Pfaden.

Prüfen Sie auf `redmine_mcp` nur am `mcp.rb`-Einstiegspunkt (üblicherweise `lib/<plugin>.rb` oder `after_initialize` des Plugin-Loaders). Aus `mcp.rb` geladene Dateien (`mcp_tools.rb`, `mcp_tools/*.rb` usw.) dürfen dieselben Prüfungen nicht wiederholen.

Rufen Sie `ExtensionLoader.load_plugin_extension` nicht manuell aus einem Drittanbieter-Plugin auf: `ExtensionLoader` ist ein interner `redmine_mcp`-Mechanismus. Ein bedingtes `require` Ihrer `mcp.rb` genügt; verhinderte die Plugin-Ladereihenfolge dieses `require`, greift der standardmäßige `redmine_mcp`-`ExtensionLoader` als Fallback.

Einstiegspunkt-Beispiel:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

Die Erweiterung wird nur registriert, wenn:

- MCP in den `redmine_mcp`-Einstellungen aktiviert ist;
- die `mcp.rb`-Datei gefunden wird;
- das Modul `<PluginName>::Mcp` in `mcp.rb` korrekt lädt;
- die Erweiterung nicht in der Liste `MCP extensions` deaktiviert ist.

Nach Installation einer neuen Erweiterung oder Änderung von `mcp.rb` ist meist ein Redmine-Neustart nötig. Der MCP-Client muss ggf. neu verbunden werden. In manchen Anwendungen wie Cursor reicht das Neuladen des MCP-Servers nicht für neue Tools: erscheinen sie nicht, die Anwendung vollständig neu starten.

## Erweiterung prüfen

Nach der Implementierung das Tool über einen echten MCP-Aufruf prüfen — nicht nur den Handler, sondern auch:

- Registrierung in `tools/list`;
- Input-Schema;
- Berechtigung;
- Output-Hülle;
- Fehler.

Prüfen Sie die Redmine-Logs auf Tool-Registrierung und Erweiterungs-Ladefehler.

Für jedes neue Tool mindestens:

- ein erfolgreiches Schema-Szenario;
- ein negatives Schema-Szenario.

Detaillierte automatisierte Testanforderungen stehen in [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Automatisierte Erweiterungstests

Automatisierte Tests für eine Plugin-MCP-Erweiterung MÜSSEN den **vollständigen Registry-Pfad** abdecken (`inputSchema`-Validierung → Berechtigung → Handler → `{ok, data | error}`-Hülle), nicht nur einen direkten Handler-Aufruf.

Ist `redmine_mcp` nicht installiert oder nicht geladen, **überspringt** die Testklasse Szenarien (`skip` in `setup`) statt beim Laden der Datei zu scheitern:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

Im Test-`setup` ist `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` akzeptabel, um Tools in der `Registry` zu registrieren. Rufen Sie `ExtensionLoader` nicht aus Plugin-Produktionscode auf (siehe „Laden und Deaktivieren einer Erweiterung“).

Zum Vergleich der tatsächlichen Antwort mit dem veröffentlichten `outputSchema` (`mcp_tool_development.md` §7.1) `json_schemer` verwenden — dieselbe Bibliothek, die `RedmineMcp::InputValidator` auf Input-Schemas anwendet.

Lazy Loading von `json_schemer` innerhalb eines Test-Helpers ist erlaubt. Ist die Bibliothek in der Umgebung nicht verfügbar, muss die Prüfung explizit übersprungen werden, damit Plugin-Tests wegen optionaler Abhängigkeit nicht fehlschlagen.

Mindest-Automatisierungstests für ein read-only Erweiterungs-Tool:

- ein erfolgreicher Registry-Aufruf mit `outputSchema`-Validierung;
- ein negativer Aufruf, der von `inputSchema` abgelehnt wird (z. B. `oneOf`-, enum- oder `maxItems`-Verletzung);
- bei Bedarf — separater Handler-Level-Server-Validierungstest (Schema ersetzt keine serverseitigen Prüfungen; siehe `mcp_tool_development.md` §3.4).

## Fehlerbehebung

| Problem | Was prüfen |
|---|---|
| Erweiterung nicht geladen | `mcp.rb`-Pfad, Modulname `Mcp`, ob MCP aktiviert ist, Rails-Log |
| Tool/Resource/Prompt nicht erschienen | ob `plugin_id` gesetzt ist, ob Erweiterung deaktiviert ist, Namens- oder URI-Kollisionen, ob Benutzer erforderliche Berechtigungen hat |
| Änderungen nach Bearbeitung nicht sichtbar | Redmine neu starten; in Cursor und ähnlichen Clients reicht MCP-Server-Neuladen ggf. nicht — Anwendung vollständig neu starten |
| `extend_tool` funktioniert nicht | ob Basis-Tool registriert ist, ob `extra_params` mit bestehendem Schema kollidieren |

### Pre-Merge-Checkliste

- [ ] Das Tool hat `title`, `description`, `input_schema`, `output_schema`, `permission` und `annotations`.
- [ ] Jedes `*_id` hat einen Discovery-Pfad.
- [ ] Beschreibung, output_schema und tatsächliche Antwort sind konsistent.
- [ ] Ein mutierendes Tool respektiert den Read-only-Modus.
- [ ] MCP-spezifische Logik wächst nicht in Lambda/Handler.
- [ ] Gemeinsame Helper werden aus `redmine_mcp` wiederverwendet, nicht kopiert.
- [ ] Mindestens ein erfolgreiches und ein negatives Schema-Szenario wurden ausgeführt.
