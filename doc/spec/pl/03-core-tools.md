# Wbudowane narzędzia (narzędzia podstawowe)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Przegląd

Wtyczka Redmine MCP zapewnia zestaw narzędzi do pracy z projektami Redmine, problemami, śledzeniem czasu, wiki, forami, plikami i danymi referencyjnymi (odczyt i zapis).

## Cel

Zapewnić klientom AI zarządzanie projektami, operacje na zgłoszeniach, śledzenie czasu, odkrywanie, wyszukiwanie i wiki, tablice, operacje na plikach oraz operacje meta bez instalowania dodatkowych wtyczek.

## Dotknięte obszary

- Projekty
- Wersje
- Członkowie / Role
- Zgłoszenia (CRUD, relacje, obserwatorzy, notatki, kategorie, opcje formularza, walidacja próbna, zapisane zapytania)
- Wpisy czasu
- Trackery, statusy, priorytety, zapytania
- Działalność projektowa
- Strony Wiki
- Tablice / wiadomości
- Pliki projektu/załączniki
- Użytkownicy
- Uprawnienia
- Ustawienia (tryb tylko do odczytu)

## Zasady biznesowe

### Ogólne zasady

- Pełna nazwa narzędzia: `redmine_<name>` (na przykład `redmine_get_issue`).
- Wynik jest zwracany jako koperta JSON w `structuredContent` i powielany jako tekst w `content`.
- Dane są filtrowane przez widoczność i uprawnienia projektu/problemu Redmine.
- Parametr `project` jest ciągiem znaków: identyfikator liczbowy w postaci ciągu znaków (na przykład `"1"`) lub identyfikator projektu (na przykład `"ecookbook"`).
- Gdy włączony jest **Tryb tylko do odczytu**, narzędzia zapisu zwracają błąd. Narzędzia tylko do odczytu, w tym `list_issue_relations`, `get_issue_form_options`, `validate_issue_create` i `validate_issue_update`, pozostają dostępne.

### Zarządzanie projektami

| Narzędzie | R/W | Uprawnienie |
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

### Operacje problemowe

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | atrybuty — jeśli można je edytować; tylko `uploads` — jeśli można dodać załączniki |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` dodatkowo wymaga `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` w projekcie źródłowym i `add_issues` w projekcie docelowym |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | wpis do dziennika jest widoczny i edytowalny (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` dodatkowo wymaga `set_notes_private` |
| `set_issue_note_private` | W | wpis do dziennika jest widoczny i edytowalny, plus `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Użytkownicy

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; bez `project` — tylko administrator |
| `list_groups` | R | `manage_members` (w dowolnym projekcie) lub administrator |

### Śledzenie czasu

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | wpis może być edytowany przez bieżącego użytkownika (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

`list_time_entry_activities` — katalog typów aktywności pracy do rejestrowania czasu, a nie feed zdarzeń projektu (`list_project_activities`).

### Odkrycie / Wyliczenie

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `admin_list_users` | R | administrator |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Szukaj i Wiki

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `search_all` | R | dostęp do przynajmniej jednego z wyszukiwanych typów (`view_issues` i/lub `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; historyczna `version` dodatkowo wymaga `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` i strona musi być edytowalna |
| `update_wiki_page` | W | `edit_wiki_pages` i strona musi być edytowalna |
| `delete_wiki_page` | W | `delete_wiki_pages` i strona musi być edytowalna |
| `rename_wiki_page` | W | `rename_wiki_pages` i strona musi być edytowalna |

### Deski

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Operacje na plikach

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files` (lub uprawnienia kontenera) |
| `get_attachment` | R | uprawnienia do kontenera załączników |
| `download_attachment` | R | uprawnienia do kontenera załączników |

### Meta

| Narzędzie | R/W | Uprawnienie |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` zwraca metadane wtyczki MCP bieżącej sesji, a nie wersję ani ustawienia aplikacji Redmine: `server_version` (wersja wtyczki MCP), `read_only_mode`, `auth_mode`, krótkie dane bieżącego użytkownika i `capabilities.issue_search`. Instalacja wtyczek innych firm nie jest wymieniona w odpowiedzi: ich narzędzia MCP są widoczne poprzez `tools/list` i `capabilities`, które same rejestrują rozszerzenia.

Kanoniczna pełna nazwa — `redmine_get_mcp_info`. Dawna nazwa `get_server_info` (`redmine_get_server_info`) pozostaje callable alias co najmniej do następnej wersji major: te same uprawnienia, wejście, wyjście i zachowanie; `tools/call` ze starą nazwą wykonuje tę samą operację; alias nie jest publikowany w `tools/list`; wywołania aliasu są rozróżnialne w audit log po nazwie wywołanego narzędzia. Linki z innych narzędzi używają nazwy kanonicznej.

`capabilities.issue_search` zawiera tryby wyszukiwania:

| Tryb | Domyślnie | Uwagi |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | Zawsze |
| `cross_resource` | `available: true`, tool `redmine_search_all` | Zawsze |
| `semantic` | `available: false` | Wtyczki mogą nadpisać przez `register_capability(:issue_search, :semantic)` |

Gdy `semantic.available: true`, capability MUSI zawierać `tool`, `provider` i `use_when` / `avoid_when` — krótkie wskazówki, kiedy wybrać wyszukiwanie semantyczne. `Registry#apply_capabilities` normalizuje odpowiedź dostawcy: w przypadku naruszenia umowy publikowany jest `{ available: false }`.

### Wyjaśnienia

- `delete_issue` bez `confirm_delete` zwraca podgląd wpływu; jeśli istnieją **jakiekolwiek** podzadania (w tym niewidoczne dla użytkownika), wymagane jest `confirm_delete_with_children`. Liczniki w `impact` obejmują tylko dzienniki, relacje, wpisy czasu, podzadania i załączniki widoczne dla bieżącego użytkownika.
- `search_issues` z `scope=subprojects` wymaga `project` i przeszukuje ten projekt i jego potomków. Bez `project` ten zakres to błąd parametru. `scope=my_project` ogranicza wyszukiwanie do projektów, w których użytkownik jest członkiem.
- `get_issue`: dzienniki, załączniki, obserwatorzy, relacje, podzadania i pola niestandardowe są uwzględniane tylko z jawnym `include_*`. Listy zagnieżdżone mają osobne `limit`/`offset` i pole `*_pagination` (dzienniki: domyślny limit 25, maksimum 100; inne listy zagnieżdżone: domyślny i maksimum 100). Bez odpowiedniego `include_*` lista jest pusta i paginacja to `null`. Pola opcjonalne (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) są zawsze obecne w odpowiedzi. Pola niestandardowe — tylko te widoczne dla bieżącego użytkownika. Dzienniki — ta sama widoczność co historia zgłoszenia w Redmine: wpis pojawia się w `journals` i `journal_pagination` tylko jeśli ma tekst lub co najmniej jedną widoczną dla użytkownika zmianę szczegółu. Tekst składający się wyłącznie ze spacji, tabulatorów lub podziałów wiersza jest traktowany jako pusty. Puste wpisy i wpisy z samymi ukrytymi szczegółami (w tym ukryte pola niestandardowe) są wyłączone zarówno z listy, jak i z `total_count` / `offset` / `has_more`. Prywatne komentarze — własne lub z uprawnieniem `view_private_notes`. Elementy dziennika zawierają tylko widoczne zmiany szczegółów. Relacje — tylko powiązania, gdzie obie strony są widoczne dla użytkownika. Ta sama reguła widoczności relacji dotyczy `list_issue_relations`.
- `get_private_notes` zwraca tylko prywatne komentarze z niepustym tekstem (spacje, tabulatory i podziały wiersza bez innej treści liczą się jako pusty tekst). Strona jest ograniczona przez `limit`/`offset` bez ładowania pełnej historii zgłoszenia.
- `list_project_issue_custom_fields` zwraca pola widoczne dla użytkownika w projekcie. Jeśli ustawiono `tracker_id`, tracker musi należeć do projektu.
- `copy_issue` wymaga uprawnienia do kopiowania zgłoszeń w projekcie **źródłowym** i uprawnienia do tworzenia zgłoszeń w projekcie **docelowym**. Obserwatorzy są kopiowani tylko jeśli użytkownik ma uprawnienie do dodawania obserwatorów w projekcie docelowym. Link do oryginału i kopiowanie załączników podążają za ustawieniami Redmine `link_copied_issue` i `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Bez nadpisania pól kopia nadal przechodzi przez reguły zapisu formularza. Nadrzędne zgłoszenie źródłowe jest zachowane, gdy dozwolone (w tym przy kopiowaniu w tym samym projekcie).
- `create_issue_relation` stosuje tylko dozwolone atrybuty relacji i zapisuje zmianę w dzienniku zgłoszenia. `delete_issue_relation` jest dozwolone tylko jeśli relacja może zostać usunięta przez bieżącego użytkownika (obie zgłoszenia są widoczne i użytkownik ma uprawnienie do zarządzania relacjami po co najmniej jednej stronie); usunięcie jest także zapisane w dzienniku.
- `add_project_member` / `update_project_member` akceptują tylko role, którymi bieżący użytkownik może zarządzać w projekcie. Rola spoza tego zestawu jest odrzucana; role nie są przypisywane częściowo.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` to identyfikator podmiotu (użytkownik lub grupa), nie tylko użytkownika.
- `delete_attachment` dla załącznika zgłoszenia podąża za regułą „czy załączniki w tym zgłoszeniu mogą zostać usunięte” (w tym własne zgłoszenia i uprawnienia trackera), a nie tylko globalnym `edit_issues`. W `tools/list` narzędzie jest widoczne, jeśli użytkownik może usunąć co najmniej jeden załącznik (pliki projektu, zgłoszenia lub wiki), a nie tylko z globalnym `manage_files`.
- `get_wiki_page`: `attachments` jest zawsze w odpowiedzi; domyślnie `[]` i `attachments_pagination: null`; z `include_attachments=true` — paginowana lista załączników z `attachment_limit`/`attachment_offset` (domyślny i maksimum 100). Historyczna `version` wymaga uprawnienia do przeglądania edycji wiki. Zmiana, zmiana nazwy lub usunięcie chronionej strony wymaga uprawnienia do ochrony stron wiki.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: domyślnie pola podsumowania; pełny opis przez `fields` lub `get_issue`.
- Obiekty zgłoszeń z `get_issue`, `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`, `create_issue`, `update_issue` i `copy_issue` zawierają `url` — bezwzględny link do UI WWW. Host pochodzi z ustawień Redmine «Nazwa hosta i ścieżka» oraz protokołu, jak w e-mailach. Jeśli «Nazwa hosta i ścieżka» jest pusta, `url` ma wartość `null` zamiast uszkodzonego linku. Podsumowanie list/search zawiera `url` domyślnie. Elementy `search_all` z `type` `issues` i zagnieżdżone `children` w `get_issue` też zawierają `url`. Cytując zgłoszenie użytkownikowi, klient kopiuje `url` z wyniku narzędzia.
- `create_issue` i `update_issue` akceptują jawne **atrybuty** zgłoszenia (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields` itd.). Wszystkie jawnie przekazane atrybuty, w tym `subject` i `description` przy tworzeniu, przechodzą przez te same reguły zapisu co formularz webowy Redmine. Przed utworzeniem/aktualizacją agent POWINIEN wywołać `get_issue_form_options`, gdy dozwolone wartości pól są nieznane. Jawnie przekazana wartość, którą Redmine nie zastosował, skutkuje błędem, a nie częściowym sukcesem.
- Jeśli klient **nie przekazał** `start_date` w `create_issue` / `validate_issue_create`, a Redmine ma włączoną opcję „data początkowa = data utworzenia” (`default_issue_start_date_to_creation_date`), MCP ustawia `start_date` na dzisiejszą datę użytkownika — jak w formularzu nowego zgłoszenia. Jawne `start_date` (w tym `null`) wyłącza to podstawienie. `copy_issue` i `update_issue` same nie zastępują daty.
- `update_issue` nie akceptuje `notes`, `private_notes` ani `watcher_user_ids`. Komentarz — `add_issue_note`; obserwatorzy — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` obsługuje także `uploads` do dołączania plików do zgłoszenia. Załączniki są przetwarzane tylko po pomyślnej walidacji atrybutów (w tym `rejected_fields`). Wywołanie z samymi `uploads` (bez atrybutów) jest dozwolone, jeśli użytkownik może dodawać załączniki do zgłoszenia — w tym gdy komentowanie jest dozwolone, ale atrybutów nie można edytować. Opcjonalny `idempotency_key` chroni przed ponowieniami po utraconej odpowiedzi (w tym ponownym przesłaniu tych samych plików). `journal_id` w odpowiedzi to wpis dziennika dla **tego** wywołania, a nie najnowszy wpis zgłoszenia.
- Aby wyczyścić opcjonalne pole, przekaż `null` dla `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` lub `estimated_hours`. To samo dla `update_version.due_date` / `wiki_page_title` i `update_issue_category.assigned_to_id`.
- `create_issue` nie obsługuje `uploads`.
- `update_issue` akceptuje `uploads[*].content_base64` i `uploads[*].filename`. Po pomyślnym przesłaniu odpowiedź zawiera `added_attachments` — tylko pliki z tego wywołania, a nie pełną listę załączników zgłoszenia. Uszkodzony Base64 to błąd parametru.
- `update_issue` akceptuje `status_name` i mapuje go na `status_id`.
- `upload_file` akceptuje `content_base64` (do 20 MiB); `project`, `filename` i `content_base64` są wymagane.
- `get_attachment` zwraca `attachment_id`, `filename`, `content_type`, `size` (rozmiar pliku załącznika) i `content_url` (bez bajtów pliku). Jeśli «Nazwa hosta i ścieżka» jest pusta, `content_url` ma wartość `null`.
- `download_attachment` zwraca `attachment_id`, `filename`, `content_type`, `size` (rzeczywisty rozmiar treści w bajtach) i `content_base64` dla pojedynczego załącznika widocznego dla bieżącego użytkownika. Jeśli MIME jest nieznany — `application/octet-stream`. Nie zwiększa licznika `downloads`. Limit rozmiaru to 10 MiB (sprawdza `File.size` na dysku przed odczytem i `bytesize` po odczycie); jeśli przekroczony — `FILE_TOO_LARGE`. Ścieżki plików na serwerze nie są zwracane w odpowiedzi. `attachment_id` pochodzi z `redmine_get_issue` / `redmine_get_wiki_page` z `include_attachments=true`, `redmine_list_project_files` lub `redmine_get_attachment`. Aby odczytać, przeanalizować lub przetworzyć załącznik jako plik, zdekoduj `content_base64` lokalnie. Nieistniejące i niedostępne załączniki zwracają tę samą odpowiedź „not found”.
- `create_time_entry` i elementy `import_time_entries.entries` wymagają `hours` oraz `project` lub `issue_id`. `hours` może być 0; ważność zera i dzienny limit są sprawdzane przez Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` przy tworzeniu/aktualizacji zgłoszenia to ID principal (użytkownik lub grupa z `get_issue_form_options.assignees`); `null` czyści wykonawcę. Kanoniczne wejście dla `add_issue_watcher` / `remove_issue_watcher` to `principal_id` (użytkownik lub grupa). Dawny `user_id` jest akceptowany jako alias tego samego ID; obu naraz przekazać nie można. Odpowiedź zawiera `principal_id` i duplikat `user_id` z tą samą wartością. W innych narzędziach `user_id` to ID użytkownika. Dla bieżącego użytkownika użyj `assignee_ref` lub `user_ref` z wartością `me`.
- `expected_updated_at` (opcjonalny) przy wrażliwej aktualizacji/usuwaniu: jeśli nie odpowiada `updated_on`, zwraca `CONFLICT`.
- `idempotency_key` (opcjonalny) w `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: ponowienie z tym samym kluczem i **tym samym zestawem argumentów** (poza samym kluczem) zwraca zapisany wynik sukcesu (TTL 24 h). Ten sam klucz z innym payloadem — `CONFLICT`, bez zduplikowanego zapisu. Gdy pierwsze żądanie nadal działa, ponowienie z tym samym kluczem nie wykonuje kolejnego zapisu (znacznik „in progress” żyje te same 24 h co wynik sukcesu). Zapisany wpis bez fingerprintu (cache sprzed tej wersji) z tym samym kluczem jest zwracany jak wcześniej do wygaśnięcia TTL. Limit czasu serwera 60 s dotyczy **odczytów**. Operacje zapisu nie są przerywane przez limit czasu serwera, aby po pomyślnym zapisie można zarejestrować wynik idempotencji; klient może ponowić z tym samym kluczem, jeśli utracił połączenie. Nieoczekiwany wyjątek w `import_time_entries` cofa wpisy już wstawione w tym wywołaniu; normalne błędy walidacji dla poszczególnych wierszy są nadal zbierane bez cofania udanych.
- `delete_attachment` domyślnie usuwa tylko pliki projektu/wersji; dla załączników zgłoszenia/wiki wymagane jest `confirm_delete_any_attachment=true`. Kanoniczna pełna nazwa — `redmine_delete_attachment`. Dawna nazwa `delete_file` (`redmine_delete_file`) pozostaje callable alias co najmniej do następnej wersji major: te same uprawnienia, wejście, wyjście i zachowanie; `tools/call` ze starą nazwą wykonuje tę samą operację; alias nie jest publikowany w `tools/list`; wywołania aliasu są rozróżnialne w audit log po nazwie wywołanego narzędzia. Linki z innych narzędzi używają nazwy kanonicznej.
- Lista/wyszukiwanie używają `limit`/`offset`. W przypadku zapytań DB strona jest ograniczona na poziomie zapytania, a nie poprzez przycięcie już załadowanej pełnej listy. Każda paginowana kolekcja MCP ma wyraźny, stabilny porządek; ostatnim kryterium jest zawsze `id`, więc strony nie pomijają ani nie duplikują elementów.
- Wyszukiwanie podciągów (`query`, `login`, `name` i tekst `search_issues`) dopasowuje znaki dosłownie: `%` i `_` nie są symbolami wieloznacznymi SQL.
- Limity MCP: limit czasu 60 s dla narzędzi do odczytu, limit szybkości 120 żądań/min na użytkownika, treść żądania MCP HTTP 36 MiB, maksymalny rozmiar argumentów narzędzia JSON 32 MiB, przesyłanie base64 do 20 MiB, pobieranie base64 do 10 MiB. Uszkodzony Base64 w dowolnym `content_base64` jest błędem parametru przed wykonaniem narzędzia.
- Każde wywołanie narzędzia, w tym odmowa dostępu, jest zapisywane w ustrukturyzowanym dzienniku audytu (narzędzie, użytkownik, identyfikatory obiektów docelowych, wynik, czas trwania, identyfikator korelacji) i wliczane do limitu szybkości; Treść base64 i prywatne notatki nie są rejestrowane. Identyfikatory docelowe obejmują między innymi `board_id`, `message_id`, `query_id`, `user_id`, `group_id`.
- `outputSchema` każdego podstawowego narzędzia opisuje najwyższy poziom `data` (w przypadku list — pola elementów `items`), a nie otwarty dowolny obiekt. Zestaw pól schematu odpowiada rzeczywistej odpowiedzi: `list_users` bez `created_on`, `admin_list_users` z `created_on`; `get_attachment` zawiera `size` i `content_url`. Pola, które w prawdziwej odpowiedzi mogą być puste, dopuszczają wartość `null` (w tym `time_entry.issue`, `*_pagination` bez include, `estimation_accuracy`, `content_type` załącznika). Niestandardowe wartości pól i `possible_values` nie są ograniczone do obiektów. `attachments_not_saved` to tablica nazw plików.
- `summarize_project_status.days` w schemacie: domyślnie 30, minimum 1, maksimum 365.
- `search_all.resources`: co najmniej dwa unikalne wartości.
- `version_id`, `file_id`, `tracker_id` to liczby całkowite nie mniejsze niż 1.

### `get_project`

- Wejście: `project` (wymagane).
- Dane wyjściowe: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (obiekt `id`/`name`/`identifier` lub `null`), `subprojects` (krótka lista widocznych projektów podrzędnych: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` jest wypełniony tylko jeśli projekt nadrzędny jest widoczny dla bieżącego użytkownika; w przeciwnym razie `null`.
- Nie zwraca członków, włączonych modułów ani statystyk zgłoszeń. Dla modułów — `get_project_modules`; dla członków — `list_project_members`; dla agregatów zgłoszeń — `summarize_project_status`.

### `get_issue_form_options`

- Jedno wywołanie zamiast kilku wyszukiwań referencji przed utworzeniem/aktualizacją. Oddzielne `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` pozostają dostępne.
- Wejście: `project` (wymagane); opcjonalnie `tracker_id`, `issue_id`.
- Migawka odzwierciedla **formularz zgłoszenia dla bieżącego użytkownika**, a nie pełną konfigurację projektu: te same dozwolone wartości, które oferuje interfejs użytkownika Redmine.
- `tracker_id` bez `issue_id` ustawia kontekst formularza tworzenia. Tracker musi być dostępny do wyboru przez bieżącego użytkownika na formularzu; w przeciwnym razie — błąd parametru.
- `issue_id` ustawia formularz dla istniejącego widocznego zgłoszenia w tym projekcie. Z `issue_id` `tracker_id` jest dozwolony tylko jeśli odpowiada bieżącemu trackerowi zgłoszenia; w przeciwnym razie — błąd parametru (zmiana trackera nie jest modelowana przez to narzędzie).
- Dane wyjściowe — migawka formularza bez paginacji:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: trackery, które bieżący użytkownik może wybrać na tym formularzu (`id`, `name`), a nie wszystkie trackery włączone dla projektu;
  - `priorities`: aktywne priorytety (`id`, `name`, `is_default`);
  - `categories`: kategorie projektu (`id`, `name`);
  - `versions`: wersje dostępne do wyboru na tym formularzu (`id`, `name`, `status`, `due_date`);
  - `assignees`: podmioty, które mogą zostać przypisane w tym kontekście formularza. Element: `id`, `name`, `type` (`user` lub `group`); dla `user` dodatkowo `login`. Grupy są uwzględniane, jeśli Redmine ma włączone przypisywanie zgłoszeń do grup;
  - `custom_fields`: tylko pola, które bieżący użytkownik może edytować na formularzu, z uwzględnieniem projektu/trackera, widoczności i tylko do odczytu w przepływie pracy. Element: `id`, `name`, `field_format`, `required` (pole wymagane lub wymagane przez przepływ pracy), `readonly` (zawsze `false` na tej liście), `multiple`, `default_value`, `possible_values`, `trackers`. Kontekst formularza — zgłoszenie z `issue_id` lub draft tworzenia z uwzględnieniem `tracker_id`;
  - `possible_values` — tablica obiektów `{ "label": "...", "value": "..." }`. Dla list bez osobnych etykiet `label` odpowiada `value`. Dla user/version/enumeration `label` to nazwa wyświetlana, `value` to identyfikator;
  - `statuses`: statusy dozwolone przez przepływ pracy dla bieżącego użytkownika. Z `issue_id` — przejścia dla tego widocznego zgłoszenia. Bez `issue_id` — statusy początkowe przy tworzeniu (z uwzględnieniem `tracker_id`, jeśli ustawiony);
  - `editable_fields`: nazwy atrybutów, które ten kontrakt MCP akceptuje przy tworzeniu/aktualizacji i które bieżący użytkownik może ustawić na formularzu, plus identyfikatory edytowalnych pól niestandardowych jako ciągi znaków. Nie zawiera `notes`, `private_notes`, `watcher_user_ids` i innych pól formularza webowego nieobecnych w narzędziach zapisu MCP;
  - `required_fields`: nazwy pól wymaganych na tym formularzu dla bieżącego użytkownika, w tej samej formie nazw co `editable_fields`.
- Nieistniejący `tracker_id`, tracker niedozwolony dla użytkownika lub `issue_id` poza projektem / niewidoczny — błąd parametru.

### `add_issue_note`

- Dodaje komentarz do istniejącego widocznego zgłoszenia bez zmiany atrybutów zgłoszenia.
- Dane wejściowe: `issue_id` (wymagane), `notes` (wymagane), opcjonalnie `private_notes`, `uploads` i `idempotency_key`.
- Zezwolenie: użytkownik może dodawać komentarze do tego zgłoszenia. `private_notes=true` wymaga uprawnienia do tworzenia prywatnych komentarzy; w przeciwnym razie — odrzucono, nie zostanie utworzony żaden komentarz. Załączniki w tej samej rozmowie są dozwolone, jeśli użytkownik może dodać załączniki do zgłoszenia.
- Nie akceptuje pól zgłoszenia ani list obserwatorów.
- Dane wyjściowe: `issue_id`, `journal_id`, `notes`, `private_notes`; z `uploads` — `added_attachments` (tylko pliki z tego wywołania).
- Niedostępne w trybie tylko do odczytu.

### `update_issue_note` / `set_issue_note_private`

- Pracuj tylko z wpisem do dziennika, który **widzi** bieżący użytkownik (prywatne komentarze innego użytkownika bez pozwolenia na przeglądanie prywatnych notatek są niedostępne).
- Wpis musi być edytowalny przez aktualnego użytkownika (zezwolenie na edycję komentarzy lub własne komentarze).
- `update_issue_note.notes` może być pustym ciągiem znaków (czyszczenie tekstu istniejącego wpisu). Nowy komentarz przez `add_issue_note` nie może być pusty.
- Zmiana prywatności (`private_notes` / `is_private`) wymaga osobnego uprawnienia do ustawienia komentarzy jako prywatnych; w przeciwnym razie odrzucono, tekst nie jest częściowo zmieniony.
- Rejestruje, kto edytował wpis do dziennika.
- Niedostępne w trybie tylko do odczytu.

### `validate_issue_create` / `validate_issue_update`

- Oddzielne narzędzia tylko do odczytu, a nie parametr `validate_only` w narzędziach do zapisu. Dostępne w trybie tylko do odczytu.
- `validate_issue_create`: te same pola co `create_issue`, bez `idempotency_key`. `project` i `subject` są wymagane. Uprawnienie `add_issues`.
- `validate_issue_update`: próba bez zapisu tylko dla **atrybutów zgłoszenia** (jak `update_issue`, bez `uploads`). `issue_id` jest wymagane. Zgłoszenie musi być edytowalne przez bieżącego użytkownika. Przed walidacją tworzony jest kontekst dziennika użytkownika bez zapisu do bazy (jak przy rzeczywistej aktualizacji).
- Zachowanie: zastosuj atrybuty do zgłoszenia bez zapisywania. Dane Redmine nie ulegają zmianie.
- Atrybuty nadal podlegają tym samym regułom zapisu, co formularz internetowy Redmine. Jeśli klient **jawnie przekazał** wartość, a Redmine jej nie zastosował, jest to błąd MCP, a nie sukces.
- Wyraźne pole, którego nie można zapisać w danym zgłoszeniu (wyłączone / przepływ pracy tylko do odczytu / daty pochodne itp.) trafia do `rejected_fields`. Dla `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` i `custom_fields` dodatkowo sprawdza się, czy żądana wartość została faktycznie zastosowana.
- Ta sama zasada dotyczy `create_issue`, `update_issue` i `copy_issue`: brak zapisu, jeśli nie zastosowano wyraźnie żądanej wartości.
- Sukces: `{ "valid": true, "errors": [] }`.
- Błąd: `{ "valid": false, "errors": ["..."] }`. Jeśli nie zastosowano niektórych jawnych pól — także `rejected_fields` (nazwy pól, na przykład `["tracker_id"]`) oraz w przypadku typowych błędów — `missing_required_fields` / `hint` w tej samej formie, co tworzenie/aktualizacja.
- Łapie również: tracker niedostępny dla bieżącego użytkownika; nieprawidłowa lub niedostępna wartość pola niestandardowego; zmiana statusu zabroniona przez przepływ pracy; cesjonariusz niedostępny do przypisania.

### `list_issues` — rozszerzone filtry

- Istniejące filtry płaskie (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) zostają zachowane.
- Opcjonalne `filters`: tablica obiektów `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` to tablica ciągów znaków; pusta tablica jest dozwolona dla operatorów bez wartości.
- Dozwolone `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id` i `cf_<id>` dla niestandardowych pól zgłoszenia.
- Operatory to standardowe operatory zapytań Redmine, w tym `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. Operator musi być poprawny dla typu pola; w przeciwnym razie — błąd parametru.
- Nieznane `field` lub nieprawidłowy `operator` — błąd parametru, zapytanie nie jest wykonywane.
- Filtry płaskie i `filters` są łączone za pomocą AND.
- Filtry dotyczą tylko zgłoszeń widocznych dla bieżącego użytkownika.

### `run_issue_query`

- Wejście: `query_id` (wymagane, z `list_queries`); opcjonalnie `project`, `fields`, `limit`/`offset`.
- Wykonuje zapisane zapytanie dotyczące zgłoszenia widoczne dla bieżącego użytkownika. Format odpowiedzi to ta sama koperta listy, co w przypadku `list_issues`.
- Jeśli zapytanie ma zakres projektu, wyniki są ograniczone do tego projektu (i reguł widoczności zapytania). Opcjonalny `project` w zapytaniu dotyczącym projektu musi odpowiadać projektowi zapytania; w przeciwnym razie — błąd parametru.
- Jeśli zapytanie ma charakter globalny, opcjonalny `project` zawęża wybór do widocznego projektu.
- Niewidoczny lub nieistniejący `query_id` — błąd.
- `list_queries` nie wykonuje zapytania; do wykonania użyj `run_issue_query`.

### `list_project_activities`

- To feed zdarzeń projektu („co się wydarzyło”), a nie katalog typów aktywności pracy do rejestrowania czasu. Typy aktywności pracy — `list_time_entry_activities`.
- Wejście: `project` (wymagane); opcjonalnie `from`, `to` (daty `YYYY-MM-DD`), `author_id`, `event_types` (tablica ciągów znaków), `limit`/`offset`.
- Domyślne okno — ostatnie 7 dni (`to` = dzisiaj, `from` = dzisiaj minus 6 dni). Maksymalna długość okna — 90 dni; w przypadku przekroczenia — błąd parametru.
- Zdarzenia z kanału aktywności projektu: typ, czas, autor (`id`/`name`), `title`, `description`, `url`. Kolejność — najpierw nowsze wydarzenia; przy tym samym czasie — najpierw wyższy `id`.
- Koperta jak inne `list_*`.
- `event_types` ogranicza typy zdarzeń. Typ niedostępny dla użytkownika lub wyłączony w projekcie jest wyłączony z wyboru (bez błędu).
- Nieistniejący `author_id` — pusta lista, a nie błąd.

### `summarize_project_status`

To nie obiekt Redmine, lecz agregacja po stronie serwera nad widocznymi zgłoszeniami projektu i wpisami czasu.

Istniejące pola zostają zachowane: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

Okno `days` (domyślnie 30, zakres 1–365) nadal wpływa na `recent_activity` i dane okresowe wymienione poniżej. Wartość spoza zakresu jest odrzucana przez schemat. `totals` i podziały są obliczane dla wszystkich widocznych zgłoszeń projektu bez filtra dat, poprzez agregację bazy danych, bez ładowania wszystkich zgłoszeń do pamięci. Podprojekty nie są uwzględniane.

Dodatkowe pola:

- `overdue_count` — liczba otwartych widocznych zgłoszeń z `due_date` ściśle przed dzisiejszą datą użytkownika.
- `unassigned_count` — liczba otwartych widocznych zgłoszeń bez cesjonariusza.
- `stale_issues_count` — liczba otwartych widocznych zgłoszeń z `updated_on` starszym niż początek okna `days`.
- `issues_closed_during_period` — liczba widocznych zgłoszeń z `closed_on` w oknie `days`.
- `estimated_hours` — suma szacunków widocznych zgłoszeń projektu (`null`, jeśli żadne nie ma szacunku, w przeciwnym razie liczba, w tym 0).
- `spent_hours` — suma czasu spędzonego na widocznych zgłoszeniach projektu (0, jeśli brak wpisów). Wymaga `view_time_entries` w projekcie; bez uprawnienia pole to `null`.
- `average_resolution_hours` — średnia `(closed_on - created_on)` w godzinach dla zgłoszeń zamkniętych w oknie `days`; `null`, jeśli nie ma takich zgłoszeń.
- `estimation_accuracy` — dla zgłoszeń zamkniętych w oknie, które mają zarówno szacunek, jak i niezerowy/zalogowany czas: `{ "issues_count", "total_estimated", "total_spent" }`. Jeśli brak pasujących zgłoszeń — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Wymaga `view_time_entries` w projekcie; bez uprawnienia pole to `null`.
- `reopened_count` — liczba widocznych zgłoszeń, których status w dzienniku zmienił się z zamkniętego na otwarty w oknie `days`. Każde zgłoszenie jest liczone co najmniej raz.

Narzędzie zwraca fakty, a nie tekstową „analizę stanu projektu”.

### `list_versions` / `get_version`

`Version` w tych narzędziach to encja Redmine (etap roadmap / milestone), a nie wersja produktu oprogramowania. `list_versions` zwraca wersje roadmap projektu, w tym współdzielone.

### `get_version`

- Wejście: `version_id` (wymagane); opcjonalnie `project`. Jeśli ustawiony jest `project`, wersja jest dostępna, gdy znajduje się w udostępnionych wersjach tego widocznego projektu (nawet jeśli projekt źródłowy tej wersji nie jest widoczny dla użytkownika). Bez `project` wersja musi być widoczna w projekcie źródłowym.
- Dane wyjściowe: pola jak element `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) plus agregaty: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Agregaty są obliczane tylko dla zgłoszeń wersji widocznych dla bieżącego użytkownika.
- Lista zgłoszeń nie jest zwracana.
- `spent_hours` wymaga `view_time_entries` w projekcie wersji; bez uprawnienia — `null`. Sumuj tylko nad widoczne zgłoszenia wersji i tylko wpisy czasu, które bieżący użytkownik może zobaczyć (w tym `time_entries_visibility=own`).

### Deski

- Moduł forów projektowych musi być włączony; w przeciwnym razie błąd „Boards module is not enabled for this project” (analog wiki).
- Uprawnienie `view_messages`. Brak operacji zapisu na forum.
- `list_boards`: `project` wymagane; paginacja. Element: `id`, `name`, `description`, `parent_id` (`null` dla tablicy głównej), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` wymagane; paginacja. Tylko wiadomości główne (bez nadrzędnej). Element: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` wymagane. Dane wyjściowe: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — krótka lista odpowiedzi (`id`, `subject`, `author`, `created_on`) bez pełnego tekstu każdej odpowiedzi, z `replies_limit`/`replies_offset` (domyślny i maksimum 100) i `replies_pagination`.
- Niewidoczna tablica/wiadomość lub tablica z innego projektu — błąd „not found”.

### `list_users`

- Z `project`: aktywni **użytkownicy** członkowie projektu (uprawnienie `view_members`). Członkostwo grupowe w projekcie nie pojawia się jako grupa; użytkownicy z grupy tylko wtedy, gdy sami są jej członkami. Bez `project` — tylko administrator.
- Element: `id`, `login`, `firstname`, `lastname`, `mail`. Nie obejmuje `created_on` (to pole znajduje się w `admin_list_users`).
- Opcjonalne `query`: podciąg bez uwzględniania wielkości liter w `login`, `firstname` i `lastname`.
- Opcjonalne `login` zostaje zachowane (tylko podciąg logowania) w celu zapewnienia zgodności. Jeśli ustawione są zarówno `query`, jak i `login`, obowiązują oba warunki (AND).

### `admin_list_users`

- Globalny katalog aktywnych użytkowników instalacji. Tylko administrator. Do członków projektu i przypisania w projekcie użyj `list_users` z `project`.
- Wejście: opcjonalnie `name` (bez rozróżniania wielkości liter, substring po login, firstname, lastname lub email), `group_id`, paginacja.
- Element: `id`, `login`, `firstname`, `lastname`, `mail`, `created_on`.
- Kanoniczna pełna nazwa — `redmine_admin_list_users`.
- Dawna nazwa `list_all_users` (`redmine_list_all_users`) pozostaje callable alias co najmniej do następnej wersji major: te same uprawnienia, wejście, wyjście i zachowanie; `tools/call` ze starą nazwą wykonuje tę samą operację; alias nie jest publikowany w `tools/list`; wywołania aliasu są rozróżnialne w audit log po nazwie wywołanego narzędzia.
- Server instructions i linki z innych narzędzi używają nazwy kanonicznej.

### `list_project_files`

- Paginowana lista plików z sekcji Pliki projektu i załączników jego wersji. Nie obejmuje załączników zgłoszeń ani Wiki — odczytuj je przez `get_issue` / `get_wiki_page` z `include_attachments`.
- Wejście: `project` (wymagane), paginacja. Uprawnienie `view_files`.
- Kanoniczna pełna nazwa — `redmine_list_project_files`.
- Dawna nazwa `list_files` (`redmine_list_files`) pozostaje callable alias co najmniej do następnej wersji major: te same uprawnienia, wejście, wyjście i zachowanie; `tools/call` ze starą nazwą wykonuje tę samą operację; alias nie jest publikowany w `tools/list`; wywołania aliasu są rozróżnialne w audit log po nazwie wywołanego narzędzia.
- Linki z innych narzędzi używają nazwy kanonicznej.

### `list_groups`

- Paginowana lista grup, które można podać (`id`, `name`), **widoczna** dla bieżącego użytkownika, do wybrania `group_id` w `add_project_member`.
- Opcjonalne `query`: podciąg w nazwie grupy nieuwzględniający wielkości liter; `%` i `_` są dopasowywane dosłownie.
- Uprawnienia: administrator lub `manage_members` w co najmniej jednym widocznym projekcie.
- Nie zwraca członkostwa w grupie ani członkostw.

### `list_project_member_candidates`

- Kandydaci do dodania do projektu: aktywni widoczni użytkownicy i grupy, które nie są jeszcze w projekcie.
- Wejście: `project` (wymagane); opcjonalnie `query` (podciąg, jak w selektorze członków Redmine).
- Koperta listy wyjściowej: `id`, `name`, `type` (`user` lub `group`); dla użytkownika dodatkowo `login`.
- Uprawnienie `manage_members` do projektu.
- `add_project_member`: `user_id` tylko dla użytkownika, `group_id` tylko dla grupy. Identyfikator niewłaściwego typu — błąd parametru. Przed dodaniem pobierz identyfikatory z tego narzędzia (lub z `list_users` / `list_groups`, jeśli kandydat jest już znany).

### `list_roles`

- Tylko role, którymi bieżący użytkownik może zarządzać w określonym projekcie.
- Wejście: `project` (wymagane).
- Uprawnienie `manage_members` do projektu.
- W przypadku administratora zestaw odpowiada możliwym do przypisania rolom projektu (bez Non member / Anonymous).

## Przypadki brzegowe

- Nieistniejący/niedostępny projekt lub zgłoszenie — `{ "error": "..." }`.
- Tryb tylko do odczytu — `{ "error": "MCP is in read-only mode..." }` dla narzędzi zapisu **przed** wywołaniem procedury obsługi, w tym narzędzi Extension API; validate/form options/list/get pozostają dostępne.
- Pusta lista/wynik wyszukiwania — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Lista/wyszukiwanie z podziałem na strony zawsze zwracają `data.items` i `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Domyślny limit 25, maksymalnie 100.
- Wszystkie narzędzia `list_*` (w tym odniesienia: trackery, statusy, role, zapytania, tablice, tematy tablic itp.) korzystają z tej samej koperty. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` i narzędzia walidacji — pojedyncze obiekty, a nie koperta listy.
- `download_attachment`: nieistniejący i niedostępny załącznik — ten sam błąd „not found”; plik nieczytelny na dysku — błąd; rozmiar na dysku lub po odczycie powyżej 10 MiB — `FILE_TOO_LARGE` (limitu nie omija mniejszy `filesize` w bazie). Ta sama nierozróżnialna reguła „brak / brak dostępu” — dla `get_attachment`.
- `list_project_activities`: okno dłuższe niż 90 dni — błąd parametru; `from` po `to` — błąd parametru.
- `run_issue_query`: niewidoczne zapytanie — traktowane jako nieistniejące.
- `get_issue_form_options` z `issue_id` dla zgłoszenia z innego projektu — błąd parametru.
- `get_issue_form_options` z `issue_id` i `tracker_id` różnym od trackera tego zgłoszenia — błąd parametru.
- Narzędzia walidacji nie tworzą zgłoszenia, nie aktualizują zgłoszenia, nie tworzą wpisów dziennika i nie zużywają `idempotency_key`.
- Zapisy przez MCP przechodzą przez modele Redmine. Wykonują się callbacki modelu; hooki kontrolera interfejsu webowego nie są wywoływane.

## Obsługa błędów

- Brak uprawnienia — narzędzie niewidoczne w `tools/list` lub „Permission denied”.
- Błędy walidacji modelu — `{ "error": "<messages>" }` (dla tworzenia/aktualizacji zgłoszenia i narzędzi walidacji dodatkowo `missing_required_fields` jako nazwy pól ze symbolów błędów modelu, bez parsowania tekstu tłumaczenia, i `hint`).
- Wyłączony moduł wiki/tablic — osobny komunikat błędu, a nie „not found”.
- Kanoniczny kod błędu w kopercie jest jawnie ustawiany przez procedurę obsługi; kod nie pochodzi z tekstu wiadomości i nie zależy od języka użytkownika.

## Scenariusze testowe

1. `list_projects` / `list_issues` zwracają kopertę `data.items` + `meta` z paginacją.
2. `get_issue` bez `include_*` nie zwraca dzienników/załączników; z `include_journals` — dzienniki z paginacją.
3. `search_issues` według tekstu znajduje zgłoszenia; `search_all` obejmuje wiki podczas wyszukiwania wielu typów.
4. `create_issue` / `update_issue` z prawidłowymi polami powiodły się; bez uprawnienia lub w trybie tylko do odczytu — błąd.
4a. `create_issue` bez `start_date` z włączonym ustawieniem daty początkowej ustawia dzisiejszą datę; jawne `start_date` lub `null` nie jest zastępowane przez to ustawienie.
5. `delete_issue` bez `confirm_delete` zwraca `INVALID_STATE` i wpływ; z potwierdzeniem usuwa.
6. `create_time_entry` wymaga `hours` i `project` lub `issue_id`; `import_time_entries` akceptuje partię.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` działają z włączonym modułem Wiki.
8. `upload_file` wymaga `filename` i `content_base64`; `delete_attachment` dla załącznika zgłoszenia wymaga potwierdzenia.
9. Użytkownik bez `use_mcp` nie przechodzi uwierzytelnienia MCP; bez uprawnienia do narzędzia nie widzi go w `tools/list`.
10. Ponowienie `create_issue` z tym samym `idempotency_key` i tymi samymi argumentami nie tworzy duplikatu; ten sam klucz z innym subject — `CONFLICT`.
11. `download_attachment` dla widocznego załącznika zgłoszenia zwraca `content_base64` z rzeczywistym `size` treści; dla pliku > 10 MiB na dysku (nawet z małymi metadanymi) — `FILE_TOO_LARGE`; nieistniejący i niedostępny załącznik są nierozróżnialne.
12. `get_project` według identyfikatora zwraca opis, podprojekty i `last_activity_date`; niedostępny projekt — błąd.
13. `get_issue_form_options` dla projektu zwraca trackery/statusy/priorytety/kategorie/wersje/cesjonariuszy/pola niestandardowe oraz listy `editable_fields` / `required_fields`; `trackers` — tylko te dostępne dla bieżącego użytkownika; ze `issue_id` statusy odzwierciedlają dozwolone przejścia dla tego zgłoszenia; `issue_id` + inny `tracker_id` — błąd; `possible_values` — obiekty `label`/`value`.
14. `validate_issue_create` z nieprawidłowym trackerem lub statusem zwraca `valid: false` i `rejected_fields`, nie tworzy zgłoszenia; w trybie tylko do odczytu wywołanie powiodło się.
15. `list_issues` z `filters` (`due_date` `<=` data, `priority_id` `!`) zwraca tylko pasujące widoczne zgłoszenia; nieznane `field` — błąd.
16. `run_issue_query` z widocznym `query_id` zwraca te same zgłoszenia co zapisane zapytanie w interfejsie; niewidoczne zapytanie — błąd.
17. `list_project_activities` na 3 dni zwraca zdarzenia projektu z paginacją; okno 91-dniowe — błąd.
18. `summarize_project_status` obejmuje `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` i `reopened_count`.
19. `get_version` zwraca agregaty `open_issues_count` / `completed_percent` bez listy zgłoszeń.
20. `list_boards` / `list_board_topics` / `get_board_message` działają z włączonym modułem Boards; gdy wyłączony — błąd modułu.
21. `list_users` z `project` i `query` po nazwie znajduje członka bez znajomości loginu.
22. `get_issue_form_options` zwraca cesjonariuszy z `type` user/group i tylko edytowalne pola niestandardowe z `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` z jawnie przekazaną wartością, którą Redmine nie stosuje (w tym wyłączone/tylko do odczytu pola rdzeniowe, w tym `description` przy tworzeniu) zwracają błąd i nie zapisują częściowej zmiany.
24. `validate_issue_update` nie akceptuje notes; komentarz jest tworzony przez `add_issue_note`. `add_issue_note` z `add_issue_notes` powiedzie się bez `edit_issues`; `private_notes` bez `set_notes_private` — odrzucone. `update_issue` z samymi `uploads` powiedzie się z uprawnieniem do dodawania załączników bez `edit_issues`.
25. `list_groups` zwraca grupy przypisywalne dla użytkownika z `manage_members`.
26. `update_issue` z `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` czyści pole, jeśli można zapisać.
27. `update_issue_note` / `set_issue_note_private` nie zmieniają prywatnego komentarza innego użytkownika, jeśli użytkownik nie ma uprawnienia do przeglądania prywatnych komentarzy.
28. Użytkownik z uprawnieniem do edycji komentarzy, ale bez uprawnienia do ustawiania ich jako prywatnych, może zmieniać tekst publicznych komentarzy i nie może zmieniać flagi prywatności.
29. `add_issue_note` z `uploads` tworzy komentarz i załącznik w jednym wywołaniu; ponowienie z tym samym `idempotency_key` nie powoduje ich duplikowania.
30. `update_issue` z `uploads` i `idempotency_key`: ponowienie z tym samym payloadem nie powoduje zduplikowania załącznika; inny plik z tym samym kluczem — `CONFLICT`. Uszkodzony Base64 — błąd parametru.
31. `get_issue` nie zwraca ukrytych pól niestandardowych, niewidocznych szczegółów dziennika ani relacji z niewidocznymi zgłoszeniami. `get_version` agreguje tylko widoczne zgłoszenia.
32. `copy_issue` bez uprawnienia do kopiowania w projekcie źródłowym — odmowa, nawet z `add_issues` w projekcie docelowym.
33. `add_project_member` / `update_project_member` z rolą, którą użytkownik nie może zarządzać — odmowa bez częściowego przypisania.
34. `create_version` / `update_version` z `sharing` niedozwolonym dla użytkownika — odmowa. `delete_version` dla zajętej wersji — odrzucona bez usunięcia.
35. Autor wpisu czasu z `edit_own_time_entries` może aktualizować własny wpis przez `update_time_entry`.
36. `search_all` dostępne dla użytkownika z uprawnieniem wiki bez `view_issues`, jeśli wyszukiwanie obejmuje wiki.
37. `list_project_member_candidates` zwraca użytkowników i grupy, które nie są jeszcze w projekcie; `add_project_member` z `user_id` grupy — błąd.
38. `list_roles` dla projektu zwraca tylko role, którymi użytkownik może zarządzać; bez `project` — błąd schematu. Nie obejmuje wbudowanych Non member i Anonymous.
39. Ponowienie `copy_issue` / `create_time_entry` z tym samym `idempotency_key` nie tworzy duplikatu; inny payload z tym samym kluczem — `CONFLICT`.
40. `search_issues` i wyszukiwanie użytkownika/grupy dla `%` lub `_` dopasowują te znaki dosłownie, a nie jako symbole wieloznaczne.
41. `get_version.spent_hours` z `time_entries_visibility=own` zlicza tylko własne wpisy czasu.
42. `search_issues` z `scope=subprojects` bez `project` — błąd; z `project` znajduje zgłoszenia u potomków.
43. `list_project_activities` zwraca nowsze zdarzenia przed starszymi.
44. Wpływ `delete_issue` nie obejmuje ukrytych dzienników, relacji i wpisów czasu innych użytkowników; ukryte podzadania nadal wymagają `confirm_delete_with_children`.
45. `get_project` nie zwraca nadrzędnego projektu niewidocznego dla bieżącego użytkownika.
46. `update_version` z `due_date`/`wiki_page_title` = `null` czyści pole.
47. `update_issue_category` z `assigned_to_id` = `null` czyści domyślnego cesjonariusza.
48. Schemat akceptuje `hours` równe 0 i wartości powyżej 24; odrzuca tylko walidacja Redmine.
49. `update_issue_note` z pustym `notes` czyści tekst istniejącego komentarza.
50. `list_users` z `project` zwraca tylko użytkowników, nawet jeśli projekt ma członkostwo grupowe.
51. Historyczna wersja strony wiki bez `view_wiki_edits` jest niedostępna; chroniona strona nie może zostać zmieniona bez uprawnienia do ochrony wiki.
52. `copy_issue` bez uprawnienia do dodawania obserwatorów nie kopiuje obserwatorów; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` zabrania linku i załączników; nadrzędne zgłoszenie w tym samym projekcie zostaje zachowane.
53. Narzędzie zapisu rozszerzenia w trybie tylko do odczytu nie wywołuje procedury obsługi.
54. `delete_attachment` widoczne w `tools/list` dla użytkownika, który może usuwać załączniki zgłoszeń, bez `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` akceptują group principal przez `principal_id` lub deprecated `user_id`.
56. `get_version` z `project` zwraca udostępnioną wersję, którą zwróciło `list_versions` dla tego projektu.
57. `get_issue` / `get_wiki_page` / `get_board_message` ograniczają listy zagnieżdżone przez `limit`/`offset` i zwracają `*_pagination`; bez include paginacja to `null`.
58. Rzeczywiste odpowiedzi narzędzi, w tym pola dopuszczające null, odpowiadają opublikowanemu `outputSchema`.
59. `get_issue` z `include_journals`: dziennik z samym ukrytym szczegółem pola niestandardowego nie jest na liście i nie jest wliczany do `journal_pagination.total_count`.
60. Ukryty dziennik między dwoma widocznymi nie tworzy luki na stronie: przy `journal_limit=2` zwracane są dwa widoczne wpisy, `total_count` równa się liczbie widocznych.
61. Prywatny komentarz innego użytkownika nie jest zwracany w `get_issue` bez uprawnienia `view_private_notes`.
62. `get_private_notes` zwraca stronę według `limit`/`offset` bez ładowania pełnej historii zgłoszenia.
63. `get_issue` z dziennikami `attr`, `cf` i `relation` jednocześnie nie kończy się błędem i zwraca tylko widoczne wpisy.
64. Dziennik z ukrytym szczegółem pola niestandardowego i notatkami ze spacjami, tabulatorami lub podziałami wiersza nie jest uwzględniony w `get_issue`.
65. `get_private_notes` nie zwraca komentarza składającego się wyłącznie ze spacji, tabulatorów lub podziałów wiersza.
66. Administrator wywołuje `admin_list_users` i otrzymuje globalny katalog; nie-administrator nie widzi narzędzia w `tools/list` i otrzymuje odmowę przy wywołaniu.
67. Wywołanie aliasu `list_all_users` daje ten sam wynik co `admin_list_users`; `redmine_list_all_users` nie ma w `tools/list`.
68. Wywołanie aliasu `list_files` daje ten sam wynik co `list_project_files`; `redmine_list_files` nie ma w `tools/list`.
69. Wywołanie aliasu `delete_file` daje ten sam wynik co `delete_attachment`; `redmine_delete_file` nie ma w `tools/list`.
70. Wywołanie aliasu `get_server_info` daje ten sam wynik co `get_mcp_info`; `redmine_get_server_info` nie ma w `tools/list`.
