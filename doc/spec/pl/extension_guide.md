# Rozszerzenia MCP dla wtyczek Redmine

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` pozwala innym wtyczkom Redmine dodawać własne narzędzia MCP oraz, w razie potrzeby, rejestrować zasoby, prompty i capabilities bez osobnego serwera MCP i bez zmian w samym `redmine_mcp`.

## Jak to działa

`redmine_mcp` udostępnia wspólny MCP Registry, w którym wtyczki Redmine zewnętrzne rejestrują narzędzia przez `RedmineMcp::ExtensionApi`.

Typowy przepływ wywołania wygląda tak:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` nie może znać logiki biznesowej wtyczki zewnętrznej: wtyczka rejestruje własne narzędzia przez Extension API.

## Stabilność i kompatybilność wsteczna

Od `redmine_mcp 1.0.0` publiczne Extension API uznawane jest za stabilne.

Tylko metody i kontrakty `RedmineMcp::ExtensionApi` opisane w tym przewodniku są publicznym API. Wewnętrzne klasy, moduły i metody `redmine_mcp`, które nie są udokumentowane jako część Extension API, nie są publicznym API i mogą się zmieniać bez gwarancji kompatybilności wstecznej.

W ramach jednej wersji major `redmine_mcp`:

- istniejące publiczne metody Extension API nie są usuwane ani zmieniane niekompatybilnie;
- mogą być dodawane nowe metody i opcjonalne parametry;
- przestarzałe metody są najpierw oznaczane i pozostają dostępne co najmniej do następnej wersji major;
- zmiany wymagające aktualizacji w wtyczkach zewnętrznych są wydawane tylko w nowej wersji major.

Wszystkie zmiany Extension API są wymienione w `CHANGELOG.md`.

Wtyczkom zewnętrznym zaleca się deklarowanie minimalnej wymaganej wersji `redmine_mcp` oraz przeglądanie `CHANGELOG.md` przy aktualizacji.

## Szybki start

1. Utwórz plik `mcp.rb` w jednej z tych ścieżek:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id without the redmine_ prefix>/mcp.rb`, jeśli `plugin.id` zaczyna się od `redmine_`
2. Zdefiniuj moduł `<PluginName>::Mcp`.
3. Rozszerz `RedmineMcp::ExtensionApi`.
4. Ustaw `plugin_id`.
5. Zarejestruj pierwsze narzędzie.

Minimalny przykład rozszerzenia w zakresie zgłoszenia:

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

Przykład używa `register_issue_tool`, zalecanego helpera dla narzędzi pracujących ze zgłoszeniami. Pełny kontrakt narzędzia jest w [mcp_tool_development.md](mcp_tool_development.md).

### Nazwa modułu `Mcp`

Plik rozszerzenia to `mcp.rb`. Zeitwerk wnioskuje `Mcp` z tej nazwy pliku, więc pisz `module Mcp`.

Narzędzia są rejestrowane przy require pliku. Loader nie wyszukuje nazwy stałej modułu.

## Nazewnictwo

Dla narzędzi i promptów używaj krótkiej nazwy:

```ruby
name: 'search_issues'
```

Pełna nazwa MCP jest generowana automatycznie:

```text
redmine_<plugin_id>_<name>
```

Dla narzędzi preferuj `name` w formacie `<verb>_<entity>`.

Preferowane czasowniki:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Nie używaj niejasnych `manage_*`, `process_*`, `handle_*` ani narzędzi z parametrem jak `action: create | update | delete`, gdy operacje można rozdzielić na osobne, jasne narzędzia.

Na przykład:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Jeśli `plugin_id` już zaczyna się od `redmine_` (na przykład `redmine_advanced_checklists`), pełna nazwa nadal ma format `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Dla zasobów używaj unikalnego URI, na przykład:

```text
redmine://<plugin_id>/<type>/<id>
```

Nazwy narzędzi/promptów i URI zasobów muszą być unikalne. Zachowanie przy duplikacji rejestracji zależy od użytej metody; `register_tool_once` nie rejestruje tego samego narzędzia dwukrotnie.

## Rejestracja narzędzi

### Zwykłe narzędzie

Użyj `register_tool_once`, gdy potrzebujesz zwykłego narzędzia MCP niezwiązanego z konkretnym zgłoszeniem.

Typowe przypadki:

- wyszukiwanie danych wtyczki;
- zwracanie podsumowania;
- walidacja lub obliczenia po stronie serwera.

Podstawowy przykład:

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

Pełny kontrakt narzędzia — `additionalProperties: false`, adnotacje ryzyka i koperta przez `SchemaNormalizer.envelope_output` — opisany jest w [mcp_tool_development.md](mcp_tool_development.md).

### Narzędzie zgłoszenia

Użyj `register_issue_tool`, gdy narzędzie przyjmuje `issue_id` i pracuje ze zgłoszeniem.

To zalecana opcja dla scenariuszy w zakresie zgłoszenia, ponieważ:

- znajduje zgłoszenie przez `Issue.visible(user)`;
- sprawdza moduł projektu, gdy potrzeba;
- sprawdza podane uprawnienie w projekcie zgłoszenia;
- przekazuje znalezione `issue` do bloku;
- zwraca błąd, jeśli zgłoszenie jest niedostępne lub nie znalezione.

Zobacz też sekcję Permissions.

`module_name` w `register_issue_tool` to opcjonalny identyfikator modułu projektu Redmine. Nie musi odpowiadać `plugin_id`. Jeśli jest ustawiony, narzędzie pojawia się w `tools/list` tylko, gdy użytkownik widzi co najmniej jeden projekt z tym modułem i zadeklarowanym uprawnieniem.

### Co zwraca handler

Handler zwraca hash danych sukcesu bez koperty lub gotową kopertę `{ok: true, data: ...}` / `{ok: false, error: ...}`. Registry normalizuje wynik przez `ToolResponse.from_handler_result`: zwykły hash jest opakowywany w `{ok: true, data: ...}`; dla list można zwrócić gotowy wynik `paginated_list`, który już zawiera `data` i `meta`.

Dla błędów używaj `RedmineMcp::Core::Helpers.error_result`, `mcp_error` lub `{ok: false, error: ...}`.

## Input schema

`SchemaNormalizer.normalize_input` normalizuje schemat obiektu i dodaje ograniczenia serwisowe, ale publiczny kontrakt parametrów musi być opisany jawnie.

Główne reguły:

- każdy parametr musi mieć zdefiniowany typ;
- pola numeryczne `*_id` używają `type: integer`, `minimum: 1` i opisu ze ścieżką discovery;
- skończone zbiory wartości są definiowane przez `enum` / `const`, nie tylko w prozie;
- tablice muszą mieć `items`;
- pola wzajemnie zależne i wykluczające się są definiowane przez JSON Schema (`oneOf`, `if/then/else` itd.), nie tylko w opisie;
- optymistyczne blokowanie używa `expected_updated_at`, nie `updated_at`;
- `null` jest używane tylko z jawnie udokumentowaną semantyką, na przykład do wyczyszczenia pola;
- nie używaj otwartych `fields`, `payload` lub `data` zamiast typowanych parametrów biznesowych;
- nie akceptuj obiektu jako ciągu JSON;
- nie akceptuj dowolnego `file_path` w publicznym narzędziu.

Pełne wymagania `inputSchema` są w [mcp_tool_development.md](mcp_tool_development.md).

## Output schema

Każde nowe narzędzie musi mieć `output_schema`.

Dla zwykłego wyniku użyj standardowej koperty:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Dla list użyj `SchemaNormalizer.list_envelope_output(item_schema)`.

Znane stabilne pola wyniku muszą być opisane jawnie. Nie używaj `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` zamiast typowanego kontraktu, gdy struktura odpowiedzi jest znana. Te schematy są akceptowalne tylko dla naprawdę otwartych lub niestabilnych struktur.

Pełne wymagania `outputSchema` są w [mcp_tool_development.md](mcp_tool_development.md).

## Adnotacje

| Typ operacji | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | zależy od implementacji | `false` |
| delete / purge | `false` | `true` | tylko jeśli powtórzenie jest rzeczywiście bezpieczne | `false` |
| zewnętrzny efekt uboczny | `false` | zależy | zwykle `false` | `true` |

`destructive` oznacza nieodwracalną utratę danych, nie każdy zapis.

`open_world` oznacza wyjście poza znaną instalację Redmine, nie tworzenie nowego obiektu wewnątrz Redmine.

Adnotacje nie zastępują kontroli uprawnień w handlerze.

## Uprawnienia

`permission` jest używane przez Registry do dostępności narzędzia i wstępnych kontroli, ale nie zastępuje kontroli dostępu do konkretnego obiektu wewnątrz handlera.

Dla narzędzi w zakresie zgłoszenia używaj `register_issue_tool`, które sprawdza widoczność zgłoszenia, moduł projektu i uprawnienie.

Dla innych encji handler musi ponownie sprawdzić dostęp do znalezionego obiektu.

## Błędy

Używaj standardowych kodów błędów MCP:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Dla standardowych błędów używaj helperów `error_result`.
Dla niestandardowego kodu używaj `mcp_error`.
Dla optymistycznego blokowania używaj `conflict_if_stale`.

Handler zwraca strukturalny błąd, nie stack trace ani nieobsłużony wyjątek.

## Wbudowane helpery

`RedmineMcp::Core::Helpers` zawiera wspólne helpery, które należy ponownie używać zamiast duplikować:

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

Dostępne są też gotowe fragmenty schematów:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Przed utworzeniem własnego helpera sprawdź, czy odpowiedni już istnieje w `redmine_mcp`.

Sprawdź aktualny zestaw helperów w `RedmineMcp::Core::Helpers` i [04-extensions.md](04-extensions.md): ta lista pokazuje główne dostępne możliwości i nie zastępuje dokumentacji API ExtensionApi.

## Tryb tylko do odczytu i idempotencja

Narzędzia mutujące muszą respektować globalny tryb tylko do odczytu:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Dla operacji, gdzie powtórzone wywołanie może utworzyć duplikat, możesz użyć `idempotency_key` i `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` jest dozwolone tylko, gdy powtórzone wywołanie jest faktycznie bezpieczne uwzględniając wszystkie efekty uboczne.

## Organizacja kodu

`mcp.rb` powinien zawierać głównie rejestrację narzędzi: schematy, opisy, uprawnienia, adnotacje i krótkie handlery.

Pobieranie, agregację i normalizację danych specyficznych dla MCP można przenieść do:

- `mcp_tools.rb`;
- gdy plik rośnie — `mcp_tools/*.rb`.

Zwykła logika biznesowa powinna pozostać w modelach/serwisach wtyczki i nie może zależeć od MCP.

Jeśli wtyczka ma już odpowiedni punkt końcowy REST implementujący potrzebną operację i obsługujący wywołania w imieniu bieżącego użytkownika, NALEŻY go ponownie użyć przez `internal_request` (lub `internal_get` dla wywołań `GET` tylko do odczytu).

To preferowana opcja: MCP używa tych samych kontroli uprawnień, pobierania danych i zachowania biznesowego co istniejące API wtyczki.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Dla `POST`, `PUT` i `PATCH` przekaż ciąg treści żądania JSON (lub `nil`, gdy punkt końcowy nie oczekuje treści). Parametry query idą w `params`.

Wywołuj model/serwis bezpośrednio, gdy:

- nie ma odpowiedniego punktu końcowego REST;
- punkt końcowy nie obsługuje potrzebnej operacji lub danych;
- użycie REST tworzy niepotrzebną lub niepoprawną warstwę dla operacji;
- wspólna logika biznesowa jest już celowo wydzielona do serwisu, a punkt końcowy REST jest tylko cienką nakładką na ten serwis.

Nie implementuj tej samej logiki biznesowej osobno dla REST i MCP. Jeśli obie warstwy potrzebują wspólnej logiki, wydziel ją do wspólnego serwisu.

## Dodatkowe możliwości

`RedmineMcp::ExtensionApi` udostępnia też:

| Metoda | Kiedy używać |
|---|---|
| `register_resource` | potrzebujesz zasobu MCP |
| `register_prompt` | potrzebujesz promptu MCP |
| `register_capability` | potrzebujesz dodać capability do `redmine_get_mcp_info` |
| `extend_tool` | potrzebujesz rozszerzyć istniejące narzędzie zamiast tworzyć nowe |
| `on` | potrzebujesz hooka cyklu życia |
| `internal_request` | potrzebujesz wywołać punkt końcowy REST Redmine lub wtyczki w procesie jako bieżący użytkownik (`method`, `path`, opcjonalnie `params` i `body`) |
| `internal_get` | skrót dla `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | sprawdź, czy wynik REST w procesie to koperta błędu MCP |

Ustaw `plugin_id` raz na górze modułu. Przed rejestracją narzędzi NALEŻY sprawdzić `mcp_extension_enabled?`, gdy rejestrację wykonuje samo rozszerzenie. Standardowy `ExtensionLoader` też nie ładuje `mcp.rb` dla wyłączonych rozszerzeń.

### Rozszerzanie istniejącego narzędzia

Używaj `extend_tool` tylko, gdy osobne narzędzie nie pasuje.

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

`before` uruchamia się przed handlerem, `after` po nim. `extra_params` są dodawane do schematu wejścia. Nazwy parametrów nie mogą kolidować z narzędziem bazowym ani z innymi rozszerzeniami tego narzędzia.

Jeśli rozszerzenie jest require'owane z `after_initialize` wtyczki przed rejestracją narzędzi rdzeniowych przez `redmine_mcp`, odłóż `extend_tool` dla narzędzia rdzeniowego (na przykład `redmine_get_issue`) do zakończenia inicjalizacji — użyj zagnieżdżonego `Rails.application.config.after_initialize` i najpierw sprawdź `Registry.instance.tool(...)`.

## Ładowanie i wyłączanie rozszerzenia

`redmine_mcp` automatycznie szuka pliku rozszerzenia w obsługiwanych ścieżkach przy starcie Redmine.

Dwa warianty integracji:

1. **Rozszerzenie we wtyczce zewnętrznej** — `lib/<...>/mcp.rb` w katalogu wtyczki docelowej (zob. «Szybki start»).
2. **Wbudowana integracja w `redmine_mcp`** — `lib/redmine_mcp/extensions/<plugin.id>.rb` dla przypadków, gdy wtyczki zewnętrznej nie można modyfikować. Plik rejestruje tools/resources/prompts przez ten sam `RedmineMcp::ExtensionApi`. Jeśli wtyczka docelowa ma już własny `mcp.rb`, wbudowana integracja jest używana tylko gdy ładowanie tego pliku się nie powiedzie.

Przykład wbudowanej integracji:

```ruby
module RedmineMcp
  module Extensions
    module AdvancedSearch
      extend RedmineMcp::ExtensionApi

      plugin_id :advanced_search

      if mcp_extension_enabled?
        register_tool_once(
          name: 'semantic_search_issues',
          description: 'Semantic search for issues.',
          input_schema: {type: 'object', properties: {}},
          output_schema: RedmineMcp::SchemaNormalizer.envelope_output(type: 'object', properties: {}),
          permission: :view_issues,
          handler: ->(_args, _context) { {} }
        )
      end
    end
  end
end
```

Kod pomocniczy integracji można umieścić w `lib/redmine_mcp/extensions/<plugin_id>/` i importować przez jawny `require` z pliku głównego.

Sprawdzaj `redmine_mcp` tylko w punkcie wejścia `mcp.rb` (zwykle `lib/<plugin>.rb` lub `after_initialize` loadera wtyczki). Pliki ładowane tylko z `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb` itd.) nie powinny powtarzać tych samych kontroli. Dla wbudowanych integracji w `redmine_mcp` osobna kontrola w punkcie wejścia nie jest potrzebna: plik ładuje tylko `ExtensionLoader`.

Nie wywołuj `ExtensionLoader.load_plugin_extension` ręcznie z wtyczki zewnętrznej: `ExtensionLoader` to wewnętrzny mechanizm `redmine_mcp`. Warunkowy `require` twojego `mcp.rb` wystarczy; jeśli kolejność ładowania wtyczek uniemożliwiła ten `require`, standardowy `redmine_mcp` `ExtensionLoader` działa jako fallback.

Przykład punktu wejścia:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

Rozszerzenie jest rejestrowane tylko, jeśli:

- MCP jest włączone w ustawieniach `redmine_mcp`;
- znaleziono plik rozszerzenia (`mcp.rb` we wtyczce lub `lib/redmine_mcp/extensions/<plugin.id>.rb` w `redmine_mcp`, z priorytetem własnego `mcp.rb`);
- moduł rozszerzenia ładuje się poprawnie;
- rozszerzenie nie jest wyłączone na liście `MCP extensions`.

Po zainstalowaniu nowego rozszerzenia lub zmianie `mcp.rb` zwykle wymagany jest restart Redmine. Klient MCP może wtedy wymagać ponownego połączenia. W niektórych aplikacjach, takich jak Cursor, przeładowanie serwera MCP nie wystarczy, aby zobaczyć nowe narzędzia: jeśli się nie pojawiają, w pełni zrestartuj aplikację.

## Weryfikacja rozszerzenia

Po implementacji zweryfikuj narzędzie przez rzeczywiste wywołanie MCP, sprawdzając nie tylko handler, ale też:

- rejestrację w `tools/list`;
- schemat wejścia;
- uprawnienie;
- kopertę wyjścia;
- błędy.

Sprawdź logi Redmine pod kątem rejestracji narzędzi i błędów ładowania rozszerzeń.

Dla każdego nowego narzędzia minimum:

- jeden pomyślny scenariusz schematu;
- jeden negatywny scenariusz schematu.

Szczegółowe wymagania testów automatycznych są w [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Testy automatyczne rozszerzenia

Testy automatyczne rozszerzenia MCP wtyczki MUSZĄ ćwiczyć **pełną ścieżkę Registry** (walidacja `inputSchema` → uprawnienie → handler → koperta `{ok, data | error}`), nie tylko bezpośrednie wywołanie handlera.

Jeśli `redmine_mcp` nie jest zainstalowane lub nie załadowane, klasa testowa **pomija** scenariusze (`skip` w `setup`) zamiast padać przy ładowaniu pliku:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

W `setup` testu wywołanie `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` jest akceptowalne, aby zarejestrować narzędzia w `Registry`. Nie wywołuj `ExtensionLoader` z kodu produkcyjnego wtyczki (zob. „Ładowanie i wyłączanie rozszerzenia”).

Aby porównać rzeczywistą odpowiedź z opublikowanym `outputSchema` (`mcp_tool_development.md` §7.1), użyj `json_schemer` — tej samej biblioteki, którą `RedmineMcp::InputValidator` stosuje do schematów wejścia.

Leniwe ładowanie `json_schemer` wewnątrz helpera testowego jest dozwolone. Jeśli biblioteka nie jest dostępna w środowisku, kontrola musi być jawnie pominięta, aby testy wtyczki nie padały z powodu opcjonalnej zależności.

Minimalne testy automatyczne dla narzędzia rozszerzenia tylko do odczytu:

- jedno pomyślne wywołanie Registry z walidacją `outputSchema`;
- jedno negatywne wywołanie odrzucone przez `inputSchema` (na przykład naruszenie `oneOf`, enum lub `maxItems`);
- gdy potrzeba — osobny test walidacji serwera na poziomie handlera (schemat nie zastępuje kontroli po stronie serwera; zob. `mcp_tool_development.md` §3.4).

## Rozwiązywanie problemów

| Problem | Co sprawdzić |
|---|---|
| Rozszerzenie się nie załadowało | ścieżka `mcp.rb` lub `lib/redmine_mcp/extensions/<plugin.id>.rb`, nazwa modułu, czy MCP jest włączone, czy rozszerzenie jest włączone w ustawieniach, błędy w logu Rails |
| Narzędzie/zasób/prompt się nie pojawił | czy ustawiono `plugin_id`, czy rozszerzenie jest wyłączone, kolizje nazw lub URI, czy użytkownik ma wymagane uprawnienia |
| Zmiany nie pojawiły się po edycji | restart Redmine; w Cursor i podobnych klientach przeładowanie serwera MCP może nie wykryć nowych narzędzi — w pełni zrestartuj aplikację |
| `extend_tool` nie działa | czy narzędzie bazowe jest zarejestrowane, czy `extra_params` kolidują z istniejącym schematem |

### Lista kontrolna przed merge

- [ ] Narzędzie ma `title`, `description`, `input_schema`, `output_schema`, `permission` i `annotations`.
- [ ] Każde `*_id` ma ścieżkę discovery.
- [ ] Opis, output_schema i rzeczywista odpowiedź są spójne.
- [ ] Narzędzie mutujące respektuje tryb tylko do odczytu.
- [ ] Logika specyficzna dla MCP nie rośnie wewnątrz lambda/handlera.
- [ ] Wspólne helpery są ponownie używane z `redmine_mcp`, nie kopiowane.
- [ ] Uruchomiono co najmniej jeden pomyślny i jeden negatywny scenariusz schematu.
