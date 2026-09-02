# API rozszerzeń dla innych wtyczek

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Przegląd

Redmine MCP udostępnia mechanizm rozszerzeń, który pozwala innym zainstalowanym wtyczkom Redmine rejestrować własne narzędzia, zasoby i prompty oraz rozszerzać istniejące narzędzia.

## Cel

Zapewnić jednolite podejście do integracji wtyczek Redmine z AI bez duplikowania serwera MCP i bez zmiany kodu Redmine MCP.

## Obszary objęte

- Wtyczki
- API
- Uprawnienia

## Reguły biznesowe

### Automatyczne wykrywanie

- Przy starcie Redmine (gdy MCP jest włączone) system sprawdza wszystkie zainstalowane wtyczki.
- Wtyczka uznawana jest za posiadającą rozszerzenie MCP, jeśli zawiera plik `mcp.rb` w jednej z tych ścieżek:
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<plugin directory basename>/mcp.rb`;
  - `lib/<plugin.id without redmine_ prefix>/mcp.rb`, jeśli identyfikator zaczyna się od `redmine_` (typowy schemat jak `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- Wtyczka `redmine_mcp` nie ładuje samej siebie jako rozszerzenia.
- Wtyczki z odznaczonym checkboxem rozszerzenia MCP w ustawieniach są pomijane.
- Awaria rozszerzenia jednej wtyczki nie blokuje ładowania innych, w tym błędu składni w pliku rozszerzenia.

### Rejestracja narzędzi

- Wtyczka rozszerzająca może zarejestrować dowolną liczbę narzędzi.
- Każde narzędzie ma: nazwę, opis, schemat wejścia, schemat wyjścia, wymaganie uprawnienia i handler.
- Pełna nazwa narzędzia: `redmine_<plugin_id>_<name>`, na przykład `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Zduplikowane nazwy narzędzi są zabronione.
- Narzędzie pojawia się w MCP tylko dla użytkowników z odpowiednimi uprawnieniami.
- Narzędzie rozszerzenia w zakresie zgłoszenia może wymagać włączonego modułu projektu Redmine (identyfikator modułu nie musi odpowiadać id wtyczki). W `tools/list` takie narzędzie jest widoczne, jeśli użytkownik ma zadeklarowane uprawnienie w co najmniej jednym widocznym projekcie z tym modułem. Bez wymagania modułu wystarczy uprawnienie w co najmniej jednym widocznym projekcie. Wywołanie nadal sprawdza konkretne zgłoszenie: widoczność, uprawnienie w jego projekcie i włączony moduł; w przeciwnym razie odpowiedź to „not found”.
- Narzędzia zapisu rozszerzenia w trybie tylko do odczytu MCP nie uruchamiają handlera: odmowa jest taka sama jak dla narzędzi zapisu rdzeniowych.

### Rozszerzanie istniejących narzędzi

- Wtyczka może rozszerzyć już zarejestrowane narzędzie.
- Rozszerzenie może:
  - dodać dodatkowe parametry wejściowe;
  - uruchomić kod przed głównym handlerem;
  - uruchomić kod po handlerze i zmodyfikować wynik.
- Wiele wtyczek może jednocześnie rozszerzać to samo narzędzie.
- Dodatkowe parametry są scalane do wspólnego schematu wejścia.
- Nazwa dodatkowego parametru nie może odpowiadać parametrowi narzędzia rdzeniowego ani parametrowi innego rozszerzenia tego samego narzędzia.
- Wynikowy schemat jest normalizowany przed publikacją w `tools/list`.
- Kolejność wykonania rozszerzeń odpowiada kolejności ładowania wtyczek.

### Rejestracja zasobów

- Wtyczka może publikować zasoby z unikalnym URI. Ponowna rejestracja tego samego URI jest odrzucana.
- Zasób musi mieć handler odczytu.
- Zalecany schemat URI: `redmine://<plugin_id>/<type>/<id>`.
- Zasób może wymagać kontroli uprawnień; bez uprawnienia zasób jest niedostępny.
- Kontrole uprawnień otrzymują URI i argumenty. Projekt jest pobierany z `project` / `project_id`, z URI (`project`/`project_id` w query lub segmencie `/projects/:id`) lub z jawnego resolvera projektu zdefiniowanego przez rozszerzenie. `resources/read` przekazuje `{uri: ...}` do kontroli.
- Jeśli projekt jest podany w wywołaniu, ale nie został znaleziony lub jest niedostępny dla bieżącego użytkownika, dostęp jest odmawiany. Kontrola „co najmniej jeden projekt” stosuje się tylko, gdy projekt nie jest podany (discovery z pustymi argumentami).
- Odczyt zasobu zwraca treść w formacie tekstowym lub JSON.

### Rejestracja promptów

- Wtyczka może dodawać prompty z nazwą, opisem, argumentami i handlerem.
- Pełna nazwa promptu: `redmine_<plugin_id>_<name>`.
- Prompty są dostępne użytkownikom z odpowiednimi uprawnieniami. Kontrole uprawnień otrzymują argumenty wywołania, w tym `project` / `project_id`. Jeśli projekt jest podany, ale nie został znaleziony lub jest niedostępny, dostęp jest odmawiany; bez podanego projektu obowiązuje ta sama reguła discovery co dla zasobów.

### Zdarzenia (hooks)

- Wtyczka może subskrybować zdarzenia cyklu życia MCP, na przykład:
  - rejestrację narzędzi;
  - rejestrację zasobów;
  - rejestrację promptów;
  - zakończenie ładowania wszystkich rozszerzeń.
- Błąd w handlerze zdarzenia jest logowany i nie przerywa głównego procesu.

### Zależności

- Wtyczka rozszerzająca nie musi deklarować twardej zależności od Redmine MCP.
- Zalecane jest sprawdzenie `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` przed rejestracją.
- Wtyczka rozszerzająca nie musi dołączać gema MCP — wystarczy API Redmine MCP.

### Możliwości Extension API

Przez Extension API wtyczka rozszerzająca może:

- sprawdzić, czy MCP jest włączone i rozszerzenie nie jest wyłączone;
- zarejestrować narzędzie jednorazowo (bez duplikacji przy przeładowaniu);
- zarejestrować narzędzie w zakresie zgłoszenia ze standardowymi kontrolami uprawnień i wyszukiwaniem zgłoszenia; jeśli zgłoszenie zniknęło przed uruchomieniem handlera, odpowiedź to „not found”, a nie błąd wewnętrzny;
- rozszerzyć istniejące narzędzie rdzeniowe parametrami i handlerami before/after;
- zarejestrować tryby capability dla `redmine_get_mcp_info` (na przykład `issue_search.semantic`);
- wywołać REST API Redmine lub wtyczki w procesie w imieniu bieżącego użytkownika przez `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; docelowy punkt końcowy musi akceptować auth API); błędy REST są mapowane na kanoniczne kody MCP bez wewnętrznego statusu HTTP żądania;
- opublikować `outputSchema` w formacie koperty `{ ok, data | error }`.

Lista metod Ruby API i przykłady kodu są w README wtyczki i w [mcp_tool_development.md](mcp_tool_development.md) (przewodnik deweloperski, nie behawioralna SPEC).

## Przypadki brzegowe

- Wtyczka bez pliku rozszerzenia jest ignorowana.
- Jeśli plik rozszerzenia istnieje, ale `require` się nie powiedzie — wpis w logu, rozszerzenie nie jest uznawane za załadowane; rejestracja narzędzi jest efektem ubocznym udanego `require`.
- Próba rozszerzenia nieistniejącego narzędzia — błąd podczas rejestracji rozszerzenia.
- Wtyczka z odznaczonym checkboxem rozszerzenia MCP w ustawieniach nie jest ładowana, nawet jeśli plik rozszerzenia istnieje.
- Po zainstalowaniu nowego rozszerzenia wymagany jest restart Redmine; klient MCP może wymagać ponownego połączenia.

## Obsługa błędów

- Błąd ładowania pliku rozszerzenia — wpis w logu, kontynuacja ładowania innych wtyczek.
- Błąd rejestracji narzędzia przy starcie — wpis w logu.
- Błąd w handlerze `before` rozszerzenia — przerywa wykonanie narzędzia.
- Błąd w handlerze `after` — logowany; wynik głównego handlera jest zachowany, chyba że handler zmienił przepływ sterowania.

## Scenariusze testowe

8. Discovery zasobów i promptów z pustymi argumentami pozostaje dostępne, jeśli uprawnienie istnieje w co najmniej jednym projekcie.
9. Wtyczka z `plugin.id` jak `redmine_*` i plikiem `lib/<id without redmine_ prefix>/mcp.rb` jest uznawana za posiadającą integrację MCP i pojawia się w ustawieniach rozszerzeń MCP.
10. Narzędzie w zakresie zgłoszenia z wymaganiem modułu nie jest w `tools/list` dla użytkownika bez widocznego projektu z tym modułem, nawet jeśli ma uprawnienie w innym projekcie.

## Przykłady rozszerzeń

| Wtyczka | Narzędzie | Cel |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Semantyczne wyszukiwanie zadań |
