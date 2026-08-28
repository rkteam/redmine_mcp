# Redmine MCP

[Strona](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | Polski | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Serwer MCP (Model Context Protocol) wewnątrz Redmine. Umożliwia klientom AI pracę ze zgłoszeniami, projektami i użytkownikami w ramach standardowych uprawnień Redmine. Inne wtyczki mogą dodawać własne tools, resources, prompts i capabilities bez zmiany tej wtyczki.

## Wymagania

| Komponent | Obsługiwana wersja |
|---|---|
| Redmine | 6.0–6.1 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Ta wtyczka używa MCP protocol `2025-11-25` i Ruby MCP SDK `0.23.x`.
Obsługa nowszych wersji MCP protocol i SDK nie jest obecnie deklarowana.

- Włączone REST API w Redmine
- gem `mcp` jest zadeklarowany w `plugins/redmine_mcp/Gemfile` i instalowany przez `bundle install`

## Instalacja i konfiguracja

### 1. Instalacja wtyczki

Sklonuj repozytorium git do katalogu `plugins` Redmine:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Z katalogu głównego Redmine zainstaluj zależności i uruchom ponownie aplikację:

```bash
cd /path/to/redmine
bundle install
```

Uruchom ponownie Redmine.

### 2. Włączenie w Administracji

**Administracja → Wtyczki → Redmine MCP → Konfiguruj**

| Ustawienie | Opis |
|---------|-------------|
| Włącz MCP | Włącza punkt końcowy `/mcp`. Po włączeniu ładowane są rozszerzenia MCP zainstalowanych wtyczek |
| Tryb tylko do odczytu | Blokuje narzędzia zapisu i operacje zapisu (create/update/delete itd.) |
| Rozszerzenia MCP | Checkboxy do włączania integracji MCP dla zainstalowanych wtyczek |

### 3. REST API

**Administracja → Ustawienia → API** — włącz „Uaktywnij usługę sieciową REST”.

### 4. Uprawnienia

**Administracja → Role i uprawnienia** — dla wymaganych ról ręcznie włącz globalne uprawnienie **Używaj MCP** (`use_mcp`). Administratorzy Redmine zawsze mają dostęp do MCP.

### 5. Klucz API użytkownika

Każdy użytkownik, który będzie pracował przez MCP, musi mieć klucz API:

**Moje konto → Klucz dostępu do API** (lub przez REST API użytkownika).

Przekaż klucz w nagłówku:

```
X-Redmine-API-Key: <twój_klucz>
```

## Podłączenie klienta MCP

Serwer używa **Streamable HTTP** (stateless). Punkt końcowy:

```
https://<twój-redmine>/mcp
```

Obsługiwane metody: `GET`, `POST`, `DELETE`.

### Przykład dla Cursor

W ustawieniach MCP (`.cursor/mcp.json` lub konfiguracja globalna) dodaj serwer z transportem HTTP. Dokładny format zależy od wersji klienta; typowy przykład:

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

Po połączeniu klient wywoła `initialize`, a następnie będzie mógł wywoływać `tools/list`, `tools/call`, `resources/list`, `prompts/list` itd.

### Ręczna weryfikacja

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

Pomyślna odpowiedź zawiera `serverInfo.name: "redmine_mcp"`.

### Host i reverse proxy

Transport MCP weryfikuje HTTP `Host` i `Origin` w celu ochrony przed DNS rebinding.

Dozwolony host jest pobierany z ustawienia Redmine:

**Administracja → Ustawienia → Ogólne → Nazwa hosta i ścieżka**

Wartość musi odpowiadać publicznemu adresowi URL Redmine.

Na przykład, jeśli Redmine jest dostępny pod:

```
https://redmine.example.com
```

w ustawieniu powinno być:

```
redmine.example.com
```

Jeśli Redmine działa za reverse proxy, proxy musi przekazywać oryginalny nagłówek `Host` klienta.

Jeśli host się nie zgadza, punkt końcowy MCP może zwrócić HTTP `403 Forbidden`.

Klienci bez nagłówka `Origin` nie są objęci kontrolą Origin.

## Wbudowane narzędzia (core tools)

Pełne nazwy mają format `redmine_<tool_name>` (na przykład `redmine_get_issue`).

Serwer udostępnia narzędzia do projektów, zgłoszeń, użytkowników, rejestracji czasu, Wiki, forów i plików. Poniższa lista to krótki przegląd wbudowanych narzędzi. Pełne schematy wejściowe i descriptions są dostępne dla klienta MCP przez `tools/list`.

### Wspólne parametry

- `project` — stringowy ID lub identifier projektu.
- `assignee_ref` / `user_ref` z wartością `me` — bieżący użytkownik.
- `assigned_to_id` — użytkownik lub grupa, do których przypisano zgłoszenie; `null` czyści pola opcjonalne.
- `create_time_entry` wymaga `project` lub `issue_id`.
- `upload_file` wymaga `filename` i `content_base64`.

### Niezawodność operacji

- `expected_updated_at` — przy wrażliwych operacjach update/delete.
- `idempotency_key` — przy `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Limity

- timeout odczytu 60 s;
- 120 żądań/min na użytkownika;
- ciało HTTP żądania MCP do 36 MiB;
- JSON args narzędzia do 32 MiB;
- załączniki base64 do 20 MiB;
- pobieranie załączników do 10 MiB.

### Wdrożenie produkcyjne

Ograniczanie częstotliwości i idempotencja używają `Rails.cache`.

Dla instalacji z wieloma workerami aplikacji lub wieloma instancjami Redmine należy używać wspólnego magazynu cache.

Przy cache lokalnym dla procesu gwarancje rate limiting i idempotencji obowiązują tylko w obrębie pojedynczego procesu aplikacji.

### Zarządzanie projektami

| Narzędzie | Opis |
|------|-------------|
| `list_projects` | Lista projektów |
| `get_project` | Szczegóły projektu |
| `list_project_issue_custom_fields` | Niestandardowe pola zgłoszeń projektu |
| `summarize_project_status` | Podsumowanie aktywności i metryk projektu za N dni |
| `list_project_activities` | Kanał aktywności projektu |
| `list_versions` | Wersje projektu |
| `get_version` | Szczegóły wersji z agregatami |
| `create_version` | Utworzenie wersji |
| `update_version` | Aktualizacja wersji |
| `delete_version` | Usunięcie wersji |
| `list_project_members` | Członkowie projektu i ich role |
| `list_project_member_candidates` | Użytkownicy i grupy, które można dodać do projektu |
| `list_roles` | Role, którymi można zarządzać w projekcie |
| `get_project_modules` | Włączone moduły projektu |
| `add_project_member` | Dodanie członka |
| `update_project_member` | Zmiana ról członka |
| `remove_project_member` | Usunięcie członka |

### Zgłoszenia

| Narzędzie | Opis |
|------|-------------|
| `get_issue` | Szczegóły zgłoszenia (dziennik, załączniki, pola niestandardowe itd.) |
| `list_issues` | Lista zgłoszeń z filtrami i paginacją |
| `search_issues` | Wyszukiwanie tekstowe po zgłoszeniach |
| `run_issue_query` | Uruchomienie zapisanego zapytania zgłoszeń |
| `get_issue_form_options` | Dozwolone wartości pól formularza zgłoszenia (jedno wywołanie) |
| `validate_issue_create` | Walidacja parametrów tworzenia zgłoszenia bez zapisu |
| `validate_issue_update` | Walidacja parametrów aktualizacji zgłoszenia bez zapisu |
| `create_issue` | Utworzenie zgłoszenia |
| `update_issue` | Aktualizacja atrybutów zgłoszenia i załączników |
| `add_issue_note` | Dodanie komentarza do zgłoszenia (opcjonalnie z załącznikami) |
| `delete_issue` | Usunięcie zgłoszenia z potwierdzeniem |
| `copy_issue` | Kopiowanie zgłoszenia |
| `list_issue_relations` | Lista relacji zgłoszenia |
| `create_issue_relation` | Utworzenie relacji między zgłoszeniami |
| `delete_issue_relation` | Usunięcie relacji między zgłoszeniami |
| `list_subtasks` | Podzadania |
| `add_issue_watcher` | Dodanie obserwatora |
| `remove_issue_watcher` | Usunięcie obserwatora |
| `update_issue_note` | Edycja wpisu dziennika |
| `set_issue_note_private` | Zmiana prywatności wpisu dziennika |
| `get_private_notes` | Tylko prywatne komentarze |
| `list_issue_categories` | Kategorie zgłoszeń projektu |
| `create_issue_category` | Utworzenie kategorii |
| `update_issue_category` | Aktualizacja kategorii |
| `delete_issue_category` | Usunięcie kategorii |

### Użytkownicy

| Narzędzie | Opis |
|------|-------------|
| `list_users` | Członkowie projektu; filtry `query` (imię/login) i `login`; wyszukiwanie globalne tylko dla administratora |
| `list_groups` | Grupy givable dla `group_id` w `add_project_member` |

### Rejestracja czasu

| Narzędzie | Opis |
|------|-------------|
| `list_time_entries` | Lista wpisów czasu |
| `create_time_entry` | Utworzenie wpisu czasu |
| `update_time_entry` | Aktualizacja wpisu czasu |
| `list_time_entry_activities` | Typy aktywności (globalne lub per projekt) |
| `import_time_entries` | Masowy import wpisów czasu |

### Dane referencyjne

| Narzędzie | Opis |
|------|-------------|
| `list_trackers` | Wszystkie trackery |
| `list_project_trackers` | Trackery projektu |
| `list_issue_statuses` | Statusy zgłoszeń |
| `list_issue_priorities` | Priorytety zgłoszeń |
| `list_all_users` | Użytkownicy z filtrami (tylko administrator) |
| `get_current_user` | Bieżący użytkownik |
| `list_queries` | Zapisane zapytania (metadane; wykonanie to `run_issue_query`) |

### Wyszukiwanie i Wiki

| Narzędzie | Opis |
|------|-------------|
| `search_all` | Wyszukiwanie zgłoszeń i stron Wiki |
| `list_wiki_pages` | Strony Wiki projektu |
| `get_wiki_page` | Pobranie strony Wiki |
| `create_wiki_page` | Utworzenie strony Wiki |
| `update_wiki_page` | Aktualizacja strony Wiki |
| `delete_wiki_page` | Usunięcie strony Wiki |
| `rename_wiki_page` | Zmiana nazwy strony Wiki |

### Fora

| Narzędzie | Opis |
|------|-------------|
| `list_boards` | Tablice forum projektu |
| `list_board_topics` | Tematy wybranej tablicy |
| `get_board_message` | Wiadomość forum z krótkimi odpowiedziami |

### Pliki

| Narzędzie | Opis |
|------|-------------|
| `list_files` | Pliki projektu |
| `upload_file` | Przesłanie pliku |
| `delete_file` | Usunięcie pliku lub załącznika |
| `get_attachment` | Metadane załącznika i `content_url` |
| `download_attachment` | Zawartość załącznika (`content_base64`, do 10 MiB) |

### Narzędzia pomocnicze

| Narzędzie | Opis |
|------|-------------|
| `get_server_info` | Wersja serwera, tryb read-only, bieżący użytkownik i dostępne capabilities |

### Dostęp i odpowiedzi

Narzędzia zwracają envelope JSON w `structuredContent` i reprezentację tekstową w `content`.

Operacje zapisu są blokowane przez ustawienie **Tryb tylko do odczytu**.

Oprócz uprawnień specyficznych dla narzędzia zawsze sprawdzane jest globalne uprawnienie **Używaj MCP**.

Dostęp do danych jest wymuszany przez standardowe uprawnienia i reguły widoczności Redmine. Dla danych projektów i zgłoszeń używane są `Project.visible` i `Issue.visible`.

## Rozszerzenia z innych wtyczek

Każda zainstalowana wtyczka Redmine może dodawać własne MCP tools i w razie potrzeby rejestrować resources, prompts i capabilities.

Szczegółowy przewodnik: [extension_guide.md](extension_guide.md).

Do rozwoju wspomaganego przez AI w Cursor lub podobnych agentach skopiuj katalog skill [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) do folderu skills swojego agenta lub użyj go jako podstawy własnego skill.

## Logowanie

Wiadomości są zapisywane w standardowym logu Rails z prefiksem `[redmine_mcp]`:

- ładowanie rozszerzeń
- rejestracja tools/resources/prompts
- błędy rejestracji i wykonania
- odmowy dostępu

## Rozwiązywanie problemów

| Objaw | Możliwa przyczyna |
|---------|-------------------|
| HTTP 503 „MCP is disabled” | MCP nie jest włączone w ustawieniach wtyczki |
| HTTP 401 | Brakujący lub nieprawidłowy klucz API; REST API wyłączone |
| HTTP 403 (uprawnienie) | Użytkownik nie ma uprawnienia **Używaj MCP** |
| HTTP 403 (`Host`/`Origin`) | **Nazwa hosta i ścieżka** nie odpowiada publicznemu adresowi URL Redmine; reverse proxy nie przekazuje oryginalnego `Host`; URL MCP w kliencie się nie zgadza — transport odrzuca nieznane hosty (ochrona DNS rebinding) |
| Narzędzie nie jest widoczne w `tools/list` | Brak wymaganych uprawnień; rozszerzenie dostarczające narzędzie jest wyłączone |
| Nowe tools nie pojawiły się po przeładowaniu MCP | W Cursor i podobnych klientach przeładowanie serwera może nie odświeżyć listy narzędzi — całkowicie uruchom ponownie aplikację |
| Rozszerzenie się nie ładuje | Brak `lib/.../mcp.rb`; moduł nie wykonuje `extend RedmineMcp::ExtensionApi`; upewnij się, że checkbox rozszerzenia jest włączony w **Rozszerzenia MCP**; jeśli plik ma błąd, sprawdź log |
| `Issue not found` / `Project not found` | Zgłoszenie lub projekt nie jest widoczny dla bieżącego użytkownika według reguł widoczności Redmine |

## Licencja

Ta wtyczka jest licencjonowana na warunkach GNU General Public License,
wersji 2 lub dowolnej późniejszej wersji.

Szczegóły w [LICENSE](../../../LICENSE).
