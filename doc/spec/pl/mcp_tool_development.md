# Wymagania dotyczące rozwoju narzędzi Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Status:** przewodnik dla deweloperów (dev-guide), nie behawioralna SPEC wtyczki  
**Wersja:** 1.6  
**Data:** 2026-08-20  
**Zakres:** wszystkie nowe narzędzia Redmine MCP oraz istotne zmiany istniejących narzędzi  
**Bazowa wersja MCP:** Protocol Revision `2025-11-25`

Kontrakty behawioralne narzędzi rdzeniowych są w `03-core-tools.md` i powiązanych SPEC. Ten dokument definiuje reguły projektowania i implementacji narzędzi.

---

## 1. Cel tego dokumentu

Ten dokument ustanawia ujednolicone wymagania dotyczące projektowania, implementacji, opisywania, testowania i publikowania narzędzi MCP dla Redmine. Wzorce implementacji architektonicznej zebrane są w załączniku A i nie są mieszane z obowiązkowymi wymaganiami w tekście głównym.

Celem tego standardu jest, aby narzędzia były:

- jednoznaczne przy wyborze przez model językowy;
- bezpieczne przy automatycznym wywoływaniu;
- przewidywalne dla klientów MCP;
- ściśle walidowane;
- łatwe w utrzymaniu i wstecznie kompatybilne;
- odporne na powtarzane wywołania, błędy modelu i częściowo wypełnione argumenty.

Wymagania sformułowano z uwzględnieniem audytu bieżącego Redmine MCP. W momencie przygotowania dokumentu serwer publikuje 46 narzędzi; kontrakt ujawnił parametry bez `type`, listy stringów dozwolonych wartości zamiast `enum`, uniwersalne narzędzia `manage_*` oraz brak `outputSchema`.

---

## 2. Terminologia obowiązkowości

W tym dokumencie używa się następujących poziomów:

- **MUST / MUSI** — wymaganie obowiązkowe. Naruszenie blokuje merge.
- **MUST NOT / ZABRONIONE** — obowiązkowy zakaz.
- **SHOULD / POWINNO** — wymaganie domyślne; odstępstwo musi być uzasadnione w merge request.
- **MAY / MOŻE** — dopuszczalna opcja.

Wzorce architektoniczne i implementacyjne, które nie są obowiązkowe dla każdego narzędzia, zebrane są w **załączniku A**. Nie blokują merge, jeśli świadomie nie zostaną przyjęte dla konkretnego narzędzia.

---

## 3. Podstawowe zasady projektowania

### 3.1. Jedno narzędzie — jedna jasna akcja

Narzędzie MUSI reprezentować jedną atomową intencję użytkownika.

Dobrze:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Źle:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Narzędzia z parametrem typu `action: create | update | delete | list` są ZABRONIONE, jeśli operacje:

- wymagają różnych argumentów obowiązkowych;
- mają różne poziomy ryzyka;
- powinny mieć różne adnotacje MCP;
- zwracają różne struktury danych;
- wymagają różnych uprawnień Redmine.

Wyjątek dopuszczalny jest tylko dla semantycznie jednorodnej operacji, w której wszystkie warianty mają to samo ryzyko i jeden kontrakt. Wyjątek musi być wyraźnie uzasadniony.

### 3.2. Odczyt, dodawanie, aktualizacja i usuwanie są rozdzielone

W jednym narzędziu ZABRONIONE jest łączenie:

- operacji tylko do odczytu i zapisu;
- operacji dodawania i usuwania;
- zwykłych operacji użytkownika i administracyjnych;
- lokalnych operacji Redmine i wysyłania danych na zewnątrz.

Na przykład `list/create/delete relation` muszą być trzema osobnymi narzędziami.

### 3.3. Kontrakt ważniejszy niż wygoda implementacji serwera

Nie publikuj bezpośrednio struktury wewnętrznej metody Ruby/Python/REST tylko dlatego, że łatwiej tak zaimplementować handler.

Kontrakt MCP jest zaprojektowany dla modelu i klienta; adapter wewnątrz serwera konwertuje go do formatu API Redmine.

Wewnętrzne wartości techniczne wtyczki lub Redmine MUSZĄ być znormalizowane, jeśli nie są częścią sensownego kontraktu zewnętrznego.

Nie publikuj bez potrzeby:

- nazw klas Ruby/Rails i typów STI;
- wewnętrznych nazw enum, jeśli MCP już używa innej wartości na wejściu;
- dat zależnych od locale;
- reprezentacji REST tego samego pola, jeśli MCP już definiuje format kanoniczny;
- nazw technicznych, gdy MCP już używa znormalizowanej wartości.

Przykład: filtr wejściowy `type` — `contact` / `company`; w odpowiedzi też `contact` / `company`, a nie `Clientdesk::Contact` / `Clientdesk::Company`. Jeśli serializer zwraca klasę STI lub zlokalizowaną datę, adapter MCP MUSI doprowadzić wartość do opublikowanego schematu.

### 3.4. Serwer nie ufa modelowi

Wszystkie argumenty traktowane są jako niezaufane. Serwer MUSI ponownie sprawdzić:

- typy;
- zakresy;
- wzajemne zależności pól;
- uprawnienia bieżącego użytkownika;
- przynależność obiektu do projektu;
- dostępność wartości w konkretnym workflow;
- ograniczenia Redmine;
- czy operacja jest dozwolona w bieżącym stanie obiektu.

JSON Schema, opisy, adnotacje i potwierdzenia klienta nie zastępują walidacji po stronie serwera.

---

## 4. Nazewnictwo narzędzi

### 4.1. Format nazwy

Wszystkie opublikowane nazwy narzędzi MUSZĄ zaczynać się od `redmine_`.

Dla narzędzi rdzeniowych wtyczki `redmine_mcp` używany jest krótki prefiks `redmine_`:

```text
redmine_<verb>_<entity>
```

Dla narzędzi z wtyczek zewnętrznych pełna nazwa MUSI zaczynać się od `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Wymagania:

- tylko `lower_snake_case`;
- prefiks `redmine_` jest obowiązkowy dla wszystkich narzędzi, w tym rozszerzeń wtyczek zewnętrznych;
- nazwa jest unikalna w obrębie serwera;
- wewnętrzny limit — nie więcej niż 64 znaki;
- nazwa nie zmienia się bez procedury deprecacji.

Przykłady:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Dozwolone czasowniki

Preferowane czasowniki:

| Czasownik | Przeznaczenie |
|---|---|
| `get` | pobranie jednego obiektu po dokładnym identyfikatorze |
| `list` | pobranie kolekcji według ustrukturyzowanych filtrów |
| `search` | wykonanie wyszukiwania tekstowego lub pełnotekstowego |
| `create` | utworzenie obiektu |
| `update` | modyfikacja istniejącego obiektu |
| `set` | ustawienie konkretnego pola lub flagi na podaną wartość |
| `delete` | usunięcie obiektu |
| `add` | dodanie relacji lub członka do istniejącego obiektu |
| `remove` | usunięcie relacji bez usuwania głównego obiektu |
| `copy` | utworzenie kopii |
| `upload` | przesłanie pliku |
| `download` | pobranie zawartości pliku |
| `send` | wysłanie wiadomości lub danych do zewnętrznego odbiorcy |
| `summarize` | zbudowanie zagregowanego raportu po stronie serwera |

Nie używaj niejasnych czasowników (`manage`, `process`, `handle`, `execute`, `do`) — patrz §3.1.

Czasownik MUSI odpowiadać rzeczywistej semantyce operacji. Jeśli narzędzie przełącza flagę logiczną (parametr typu `enabled: true | false`), POWINNO być nazwane z `set`, a nie czasownikiem sugerującym tylko jedną wartość.

Źle:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` sugeruje tylko `enabled = true`, choć parametr dopuszcza też `false`. Nazwa nie odpowiada rzeczywistej akcji.

Dobrze:

```text
redmine_advanced_search_set_semantic_index_enabled
```

Nazwa `set_*` uczciwie odzwierciedla, że operacja ustawia flagę na przekazaną wartość.

### 4.3. Nazwy parametrów identyfikatorów

Nazwa parametru MUSI odpowiadać jego rzeczywistemu typowi:

- `issue_id` — tylko liczbowy ID;
- `project_id` — tylko liczbowy ID;
- `project_identifier` — stringowy identyfikator Redmine;
- `project` — string celowo dopuszczający obie reprezentacje i udokumentowany jako referencja.

Parametr o nazwie `*_id` nie może przyjmować stringowego identyfikatora ani wartości `"me"`.

Liczbowe ID MUSZĄ mieć `minimum: 1` i sensowny `description`. Sformułowania typu `"Issue id"` bez `minimum` są ZABRONIONE.

Źle:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Dobrze:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

Zalecaną ujednoliconą opcją dla projektu jest parametr `project`, przyjmujący liczbowy ID (jako string) lub stringowy identyfikator:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

Tablica `examples` (§6.15) pokazuje modelowi obie dozwolone formy wartości i zmniejsza ryzyko błędnego wejścia.

### 4.4. Optymistyczna blokada: `expected_updated_at`

Parametr przekazujący wcześniej znaną sygnaturę czasową obiektu w celu odrzucenia nieaktualnej zmiany MUSI być nazwany `expected_updated_at` we wszystkich narzędziach rdzeniowych i rozszerzeniach.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Nazwa `updated_at` dla tego znaczenia jest ZABRONIONA: wygląda jak „nowy czas modyfikacji”, choć w rzeczywistości jest wartością optymistycznej blokady.

Źle (checklist i dowolne rozszerzenia):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Dobrze:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Pole odpowiedzi raportujące rzeczywisty czas modyfikacji obiektu MOŻE nadal być nazwane `updated_at` / `updated_on` — nieporozumienie dotyczy tylko wejściowego parametru blokady.

Normatywne zachowanie przy konflikcie jest w załączniku A.2.

---

## 5. `title` i `description`

### 5.1. `title`

`title` MUSI być krótką, czytelną dla człowieka nazwą, a nie kopią nazwy technicznej.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Opis narzędzia

`description` MUSI krótko odpowiadać na kluczowe pytania:

1. Co robi narzędzie i który obiekt jest odczytywany lub modyfikowany?
2. Co nie jest domyślnie uwzględnione i jak to zażądać?
3. Czy są istotne efekty uboczne?
4. Które wstępne narzędzie wywołać, jeśli ID lub dozwolona wartość jest nieznana?

Opis MUSI być krótki i łatwy do czytania. ZABRONIONE jest zamienianie go w długi półstronicowy akapit z listą wszystkich pól i opcji include: przeładowany opis jest trudniejszy do odczytania przez model niż krótki ustrukturyzowany.

POWINNO się pisać kilka krótkich linii lub listę, a nie ciągły tekst. Domyślne wartości i sposób ich zmiany pokazuje się zwięźle.

Dobry przykład:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

Zły przykład — zbyt krótki, nie wyjaśnia wyniku i zachowania domyślnego:

```text
Gets issue.
```

Zły przykład — przeładowany, długi akapit z listą wszystkich pól:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. Odwołania do innych narzędzi

Gdy opis, opis parametru lub instrukcje serwera odnoszą się do innego narzędzia, MUSI być użyta pełna zarejestrowana nazwa z `tools/list`, a nie krótka `name` bez prefiksu.

Źle:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Dobrze:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

Krótkie nazwy są niejednoznaczne między wtyczkami i zmuszają model do zgadywania prefiksu. To szczególnie ważne dla rozszerzeń: `semantic_search_issues` bez prefiksu `redmine_advanced_search_` łatwo pomylić z nieistniejącym narzędziem rdzeniowym.

### 5.2.2. Opis zwracanego wyniku

Opis MUSI krótko wyjaśnić wynik narzędzia, aby model rozumiał, czy wystarczy jedno wywołanie, czy potrzebne jest kolejne narzędzie.

Opis wyniku powinien wskazywać:

- czy zwracany jest jeden obiekt, kolekcja, agregat, potwierdzenie zmiany czy referencja do zasobu;
- które powiązane dane są domyślnie uwzględnione;
- które duże lub wrażliwe dane nie są uwzględnione bez jawnego parametru;
- czy istnieje paginacja i jaki jest standardowy limit;
- czy narzędzie zapisu zwraca pełny zaktualizowany obiekt, czy tylko identyfikator, URL i czas modyfikacji;
- czy częściowy sukces jest możliwy przy operacji zbiorczej.

Przykład dla odczytu:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

Przykład dla listy:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

Przykład dla zapisu:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

O relacji między opisem a `outputSchema` — patrz §7.1 i §7.1.1. Jeśli lista już zwraca pole, opis NIE MOŻE kierować modelu do `get_*` tylko po to pole.

### 5.3. Opis nie zastępuje schematu

ZABRONIONE jest ustawianie ograniczeń tylko w tekście:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Używaj `enum`, `const`, zakresów i schematów warunkowych.

To samo dotyczy wzajemnie wykluczających się pól. Jeśli `description` mówi „dokładnie jedno z `user_id` lub `group_id`”, a `required` zawiera tylko wspólne pola — schemat i tekst się rozchodzą. Ograniczenie MUSI być sformalizowane w `inputSchema` (§6.12).

### 5.4. Przewidywalny wybór

Opisy podobnych narzędzi muszą wyraźnie wyjaśniać różnicę.

Na przykład:

- `redmine_list_project_members` — członkowie konkretnego projektu i ich role;
- `redmine_admin_list_users` — globalna lista użytkowników instalacji, wymaga uprawnień administracyjnych.

### 5.5. Instrukcje na poziomie serwera

Serwer MOŻE publikować krótkie ogólne instrukcje wyjaśniające relacje między narzędziami i reguły workflow.

Instrukcje powinny dodawać kontekst nieobecny w indywidualnych opisach i odnosić się do narzędzi po pełnych nazwach (§5.2.1), na przykład:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

ZABRONIONE:

- powtarzanie opisów wszystkich narzędzi w instrukcjach serwera;
- umieszczanie tam ogólnych instrukcji zachowania modelu niezwiązanych z serwerem;
- pisanie długiego przewodnika zamiast krótkich reguł routingu;
- używanie sformułowań marketingowych;
- odwoływanie się do narzędzi po krótkich nazwach bez prefiksu (`list_projects` zamiast `redmine_list_projects`).

### 5.6. Przestudiuj Redmine REST API przed rozwojem

Przed utworzeniem lub istotną zmianą narzędzia deweloper POWINIEN przeprowadzić badanie dokumentacji. Nie zaleca się projektowania kontraktu wyłącznie na podstawie istniejącego kodu MCP, pamięci dewelopera lub pojedynczego przykładu żądania HTTP.

POWINNO się przestudiować:

1. Główną stronę Redmine REST API: ogólne uwierzytelnianie, paginację, `include`, pola niestandardowe, pliki i reguły błędów walidacji.
2. Osobną stronę API dla odpowiedniego zasobu, np. Issues, Time Entries, Versions, Wiki Pages lub Project Memberships.
3. Sekcję historii zmian API i zmiany dla obsługiwanych wersji Redmine.
4. Rzeczywistą wersję Redmine używaną przez MCP i minimalną obsługiwaną wersję.
5. REST API i kod źródłowy używanych wtyczek Redmine, jeśli narzędzie pracuje z encją lub polami wtyczki. Przed publikacją narzędzia rozszerzenia MUSI zweryfikować serializer źródłowy / serwis / endpoint REST i co najmniej jedną rzeczywistą udaną odpowiedź dla każdej formy wyniku (list i get, jeśli obie są publikowane).
6. Rzeczywiste uprawnienia, workflow, włączone moduły, trackery, pola niestandardowe i ograniczenia docelowej instalacji.
7. Już opublikowane narzędzia MCP, aby uniknąć tworzenia duplikatu lub sprzecznego kontraktu.

Główna strona `https://www.redmine.org/projects/redmine/wiki/rest_api` jest punktem wejścia, ale zwykle niewystarczająca dla konkretnego narzędzia. POWINNO się przejść na odpowiednią stronę zasobu i zweryfikować operacje, parametry zapytania, `include`, pola żądania, strukturę odpowiedzi, kody błędów i ograniczenia wersji.

### 5.7. Raport pokrycia API

Przed implementacją nowego narzędzia deweloper POWINIEN dołączyć krótką tabelę pokrycia API do merge request:

| Pole | Zawartość |
|---|---|
| Zasób Redmine | Zasób i link do oficjalnej strony API |
| Endpoint | Metoda HTTP i ścieżka |
| Obsługiwane od | Minimalna wersja Redmine |
| Parametry żądania | Wszystkie udokumentowane parametry żądania |
| Filtry zapytania | Wszystkie udokumentowane filtry i wartości specjalne |
| Wartości include | Dozwolone powiązane dane |
| Wymagane/defaults | Pola obowiązkowe i wartości domyślne |
| Odpowiedź | Główne pola i warianty odpowiedzi |
| Błędy | Kody HTTP i struktura błędów |
| Uprawnienia | Wymagane prawa i specyfika impersonacji |
| Ekspozycja MCP | Które parametry są publikowane w MCP |
| Celowo pominięte | Które parametry nie są publikowane i dlaczego |
| Różnice wtyczka/wersja | Różnice wtyczek i obsługiwanych wersji |

Celem tabeli nie jest koniecznie publikacja każdego parametru Redmine w MCP. Celem jest niezapomnienie parametrów przypadkowo i świadome podejmowanie decyzji o publikacji.

Parametr Redmine może być wyłączony z MCP, jeśli:

- jest niebezpieczny lub administracyjny;
- duplikuje osobne, jaśniejsze narzędzie;
- jest niestabilny między obsługiwanymi wersjami;
- tworzy niejednoznaczny schemat;
- nie jest potrzebny dla docelowych scenariuszy użytkownika;
- prowadzi do nadmiernie dużych odpowiedzi.

Każde istotne wyłączenie rejestruje się w `Intentionally omitted` z krótkim uzasadnieniem.

### 5.8. Instrukcje dla agenta AI rozwijającego narzędzia

Jeśli narzędzie jest tworzone lub zmieniane przez agenta AI, instrukcje robocze POWINNY odnosić się do tego dokumentu: badanie API (§5.6–5.7), kontrakt (§3–§8), testy (§13), checklista (§14).

Zalecany tekst:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. Wymagania `inputSchema`

### 6.1. Struktura bazowa

Każde narzędzie MUSI mieć poprawny JSON Schema.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Dla narzędzia bez argumentów:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Zakaz nieudokumentowanych właściwości

Na najwyższym poziomie i we wszystkich zagnieżdżonych obiektach:

```json
"additionalProperties": false
```

Otwarty słownik dopuszczalny jest tylko świadomie. W takim przypadku schemat wartości ustawia się jawnie:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Typ każdego parametru

Każda właściwość MUSI zawierać `type`, `$ref` lub kompozycję `oneOf` / `anyOf` / `allOf`.

ZABRONIONE:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Parametry wymagane

Tablica `required` musi odzwierciedlać minimalnie wykonalne wywołanie.

Jeśli operacja jest niemożliwa bez parametru, parametr MUSI być w `required`.

Na przykład przesyłanie pliku wymaga co najmniej:

```json
"required": ["project", "filename", "content_base64"]
```

Sprawdzenie `confirm=true` przy usuwaniu wykonywane jest na serwerze (§3.4), nawet jeśli pole jest w `required`.

### 6.5. Wyliczenia

Dla skończonego zbioru wartości MUSI używać `enum` lub `const` (nie tylko tekstu w opisie — patrz §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Stringi

Stringi muszą mieć odpowiednie ograniczenia:

- `minLength` dla niepustych wartości;
- `maxLength` zgodnie z ograniczeniami Redmine lub limitami wewnętrznymi;
- `pattern`, gdy format jest ściśle zdefiniowany;
- `format`, gdy stosuje się standardowy format.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

Ograniczenie `format` w schemacie nie zastępuje walidacji po stronie serwera (§3.4).

### 6.7. Liczby

Dla parametrów numerycznych MUSZĄ być ustawione rozsądne granice.

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

Wartość `default` jest częścią kontraktu i dokumentacji. Serwer nie może zakładać, że klient sam podstawi domyślną wartość.

### 6.8. Tablice

Każda tablica MUSI mieć `items`.

W razie potrzeby ustaw:

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

Tablica typu `entries: array` bez schematu elementu jest ZABRONIONA.

### 6.9. Zagnieżdżone obiekty

Wszystkie zagnieżdżone obiekty opisane są w pełni.

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

### 6.10. Nie można przyjmować „obiektu lub stringa JSON”

ZABRONIONE jest opisywanie jednego parametru jako „obiekt lub string JSON”.

MCP już przekazuje ustrukturyzowany JSON. Narzędzie musi przyjmować obiekt, a nie string, który serwer potem ponownie parsuje.

### 6.11. Uniwersalne `fields` i `extra_fields`

Parametry `fields`, `extra_fields`, `payload`, `data` i podobne otwarte obiekty są ZABRONIONE dla głównych operacji biznesowych.

Pola zgłoszenia muszą być wymienione jawnie ze sensownym `description` (§6.14) i, gdzie przydatne, `examples` (§6.15):

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker ID returned by redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue priority ID returned by redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "User ID of the assignee, from redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Target version ID returned by redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numeric ID of the parent issue."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

Rzadko używane pola mogą być przekazywane przez ściśle opisane `custom_fields`.

### 6.12. Wzajemnie zależne pola

Preferuj rozdzielenie narzędzi. Jeśli rozdzielenie jest niemożliwe, zależność formalizuje się przez:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` z wzajemnie wykluczającymi się gałęziami.

Tekst w `description` („dokładnie jedno z …”) nie zastępuje schematu (§5.3).

Typowy przypadek — „dokładnie jedno z dwóch pól”. Źle: `required` wymienia tylko wspólne pola, a XOR pozostaje w prose:

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

Taki schemat dopuszcza wywołanie bez `user_id`/`group_id` i wywołanie z oboma polami jednocześnie.

Dobrze — wspólne `required` plus `oneOf` na najwyższym poziomie:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "User ID from redmine_list_users to add as a project member."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Group ID to add as a project member."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Role IDs from redmine_list_roles."
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

Walidacja po stronie serwera (§3.4) MUSI nadal odrzucać oba niepoprawne warianty. Schemat jest potrzebny, aby klient i model widzieli ograniczenie przed wywołaniem.

Należy zweryfikować zgodność wybranych konstrukcji z obsługiwanymi klientami MCP i SDK.

### 6.13. Pola z wartością `null` i czyszczenie wartości

`null` dopuszczalne jest tylko, gdy ma osobne udokumentowane znaczenie, np. „wyczyść termin” lub „usuń przypisanie”.

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "New due date in YYYY-MM-DD format, or null to clear it."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Assignee user ID from redmine_list_users, or null to unassign."
}
```

Nie używaj pustego stringa jako niejawnego odpowiednika `null`.

Dla narzędzi `set_*` ustawiających opcjonalne pole (termin, przypisanie itd.) kontrakt MUSI jawnie rozstrzygnąć czyszczenie. Dopuszczalne są trzy opcje — w kolejności preferencji:

1. **To samo narzędzie przyjmuje `null`** (preferowane), jak wyżej: jedna intencja „ustaw lub wyczyść”.
2. **Osobne narzędzie clear/unassign**, jeśli API lub UX lepiej rozdziela operacje, np. `redmine_advanced_search_clear_saved_query` i `redmine_advanced_search_unassign_search_owner`.
3. **Jawna odmowa**: jeśli czyszczenie przez MCP nie jest obsługiwane, MUSI to być podane w `description` narzędzia i/lub opisie parametru. Cichy kontrakt „tylko string/integer bez null” bez wyjaśnienia jest ZABRONIONY — model błędnie uzna, że czyszczenie jest niemożliwe, lub spróbuje przekazać `""` / `0`.

Źle — można ustawić termin, nie można wyczyścić i nigdzie tego nie podano:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Opisy parametrów

Każdy parametr w `inputSchema.properties` MUSI mieć sensowny `description`. Parametry bez `description` są ZABRONIONE, w tym w rozszerzeniach (element checklisty `done`, `sort_order`, `due_date`, pola ID itd.) i opcjonalne pola z jasnym `enum`.

Opisy typu „Filter by tracker ID”, „Tracker id” lub „Issue id” są niewystarczające: nie wskazują, skąd wziąć dozwoloną wartość i jakie ograniczenia istnieją.

Opis parametru identyfikatora MUSI wskazywać, którego narzędzia lub pola odpowiedzi użyć dla dozwolonych wartości (pełna nazwa — §5.2.1; discovery — §6.16), i odnotować istotne ograniczenia (workflow, uprawnienia, przynależność do projektu).

Źle:

```json
"tracker_id": {
  "type": "integer",
  "description": "Filter by tracker ID."
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

Dobrze:

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker ID returned by redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true marks the item done; false marks it undone."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "User ID from redmine_list_users to add as a project member."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Resource types to search. Omit to search all supported resource types."
}
```

Dobrze, z odnotowanym ograniczeniem:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

Opis parametru nie zastępuje schematu (§5.3) i walidacji po stronie serwera (§3.4).

### 6.15. Przykłady wartości (`examples`)

Dla parametrów, gdzie format wartości jest nieoczywisty lub dopuszcza wiele reprezentacji, POWINNO dodać `examples` — standardowy klucz tablicy JSON Schema. Przykłady pomagają modelowi wprowadzić poprawną wartość i są szczególnie przydatne dla parametrów referencyjnych, identyfikatorów, dat i stringów podobnych do enum.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format.",
  "examples": ["2026-07-30"]
}
```

Wymagania:

- wartości `examples` MUSZĄ być poprawne względem samego schematu parametru;
- `examples` ilustrują format, ale nie zastępują `enum`, zakresów i innych ograniczeń (§5.3, §6.5);
- dla parametrów z `enum` osobne `examples` są zwykle zbędne.

Jeśli klient MCP lub SDK nie obsługuje `examples` w schemacie, MOŻNA użyć `x-examples` jako klucza rozszerzenia z tą samą semantyką.

### 6.16. Ścieżka discovery dla parametrów ID

Parametr postaci `*_id`, którego model nie może zgadnąć, MUSI mieć jawną ścieżkę discovery: osobne narzędzie read/list lub pole w odpowiedzi innego narzędzia read, na które odnosi się `description` parametru (§6.14).

Dozwolone opcje (w kolejności preferencji dla zestawu narzędzi):

1. **Osobne narzędzie list/discovery** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Opcje w odpowiedzi get/list** — np. tablica providerów z `id` i `name` w odpowiedzi `redmine_advanced_search_semantic_search_issues`. Wtedy description MUSI odnosić się do tego pola odpowiedzi z pełną nazwą narzędzia.
3. **Stabilny enum w schemacie**, jeśli zbiór wartości jest stały i mały.

ZABRONIONE jest publikowanie narzędzia zapisu z `status_id` / `role_ids` / podobnym, jeśli żadne z powyższych nie jest spełnione: model jest zmuszony zgadywać ID.

Źle — zapis bez discovery:

- istnieje `redmine_advanced_search_set_search_provider` z `provider_id`;
- brak `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` zwraca tylko bieżącą nazwę providera (`provider: "…"`), bez listy dozwolonych wartości i ich `id`.

W takim przypadku opis typu `"Search provider ID."` jest niewystarczający. Albo dodaj narzędzie list, albo uwzględnij opcje providerów w odpowiedzi get i napisz, na przykład:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

Reguła dotyczy rdzenia i rozszerzeń (§18).

---

## 7. `outputSchema` i wymagania dotyczące wyniku

### 7.1. `outputSchema`

Nowe narzędzie MUSI publikować `outputSchema`. Schemat opisuje stabilny publiczny kontrakt odpowiedzi, a nie tylko kształt koperty `{ ok, data | error }`.

Jeśli `description` twierdzi, że narzędzie zwraca nazwane pola lub zagnieżdżoną strukturę, `outputSchema` MUSI sformalizować te pola, a nie ograniczać się do `data` / `items` na najwyższym poziomie jako „dowolny obiekt”.

Źle: description wymienia `query`, `results`, snippets i attachment excerpts, a `outputSchema` brakuje lub opisuje `items` tylko jako `{ "type": "object", "additionalProperties": true }`.

Dla każdego stabilnego pola wyniku:

- typ MUSI być określony;
- gwarantowane pole MUSI być w `required`;
- skończony zbiór wartości MUSI być ustawiony przez `enum` lub `const`;
- data MUSI mieć `format: date` lub `date-time`, jeśli serwer gwarantuje odpowiedni format;
- liczbowy ID MUSI zachować ujednolicony typ;
- nullable i optional to różne kontrakty: jeśli pole jest zawsze zwracane, ale może nie mieć wartości, musi być `required` i dopuszczać `null`;
- dla numerycznych wartości biznesowych MUSZĄ być określone jednostki, jeśli nie wynikają z nazwy pola;
- wartość pieniężna MUSI mieć jednoznaczną semantykę: jednostki główne/pomocnicze i sposób określenia waluty.

`additionalProperties: true` NIE MOŻE być używane zamiast opisu znanych stabilnych pól wyniku. Dopuszczalne jest dla wstecznej kompatybilności lub naprawdę rozszerzalnych struktur, ale znane pola biznesowe wewnątrz takiego obiektu muszą nadal być wymienione w `properties`, a gwarantowane w `required`.

Dla narzędzi list elementy `items` MUSZĄ opisywać co najmniej pola potrzebne modelowi do identyfikacji, filtrowania i kolejnych wywołań narzędzi.

Dobrze — fragment typowania `data` (pełna koperta sukcesu/błędu — §7.2 i §12):

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

Wynik POWINIEN zwracać:

- `structuredContent` — obiekt czytelny maszynowo, jeśli klienci potrzebują stabilnej struktury;
- tekstowy `content` — krótką reprezentację dla wstecznej kompatybilności i ludzi.

### 7.1.1. Spójność publicznego kontraktu

Przed ukończeniem narzędzia deweloper MUSI porównać trzy reprezentacje:

1. rzeczywistą odpowiedź handlera / REST / serwisu;
2. `description` narzędzia;
3. `outputSchema`.

Nie mogą sobie przeczyć.

Jeśli opis mówi, że pole jest zawsze zwracane, musi być `required` w `outputSchema`.

Jeśli schemat ustawia `enum` / `const` / `format`, rzeczywisty serializer MUSI znormalizować wartość do tego kontraktu. Nie można publikować `format: date` i jednocześnie obiecywać stringa sformatowanego według locale.

Jeśli lista już zwraca dane, opis NIE MOŻE kierować modelu do narzędzia get tylko po te same dane.

Niezmienniki biznesowe wyniku MUSZĄ być odzwierciedlone w schemacie przez `const`, `enum`, `required` lub schemat warunkowy, a nie tylko wnioskowane z nazwy narzędzia. Przykład: jeśli narzędzie subskrypcji z definicji zwraca tylko produkty typu `subscription`, `product_type` musi być `const: "subscription"`, a nie `enum` z niemożliwymi wartościami.

### 7.2. Ujednolicona koperta

Zalecany wynik sukcesu:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Błąd:

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

Przy błędzie dodatkowo ustaw:

```json
"isError": true
```

Jeśli publikowany jest `outputSchema` i error jest też zwracany w `structuredContent`, schemat MUSI opisywać obie gałęzie — success i error. Nie można publikować success-only schema i zwracać niezgodnego strukturalnego obiektu błędu. Alternatywa: przy tool execution error zwróć tylko tekstowy `content` z `isError: true` i nie zwracaj `structuredContent`. Preferowany wariant — ujednolicona typowana koperta z dwiema gałęziami.

### 7.3. Stabilność pól

Output fields are a public contract. ZABRONIONE:

- zmiana typu pola bez zmiany major;
- zmiana nazwy pola bez okresu deprecacji;
- czasem zwracanie obiektu, czasem tablicy;
- czasem zwracanie ID jako liczby, czasem stringa;
- zwracanie nieograniczonej nieprzetworzonej odpowiedzi Redmine API.

### 7.4. Wynik pojedynczego obiektu

Zalecany format:

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

### 7.5. Wynik listy

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

Schemat elementu `items` zgodnie z §7.1: identyfikatory, pola routingu i stabilne pola biznesowe opisane są jawnie. Pusty `{ "type": "object", "additionalProperties": true }` jako jedyny opis elementu jest ZABRONIONY.

### 7.6. Minimalnie konieczna objętość

Narzędzia list/search muszą domyślnie zwracać krótkie rekordy. Pełny opis, dzienniki, załączniki i duże pola tekstowe należy uzyskiwać przez osobne `get_*`.

To zmniejsza tokeny, opóźnienie i ryzyko przekazania nadmiarowych wrażliwych danych.

### 7.7. Dane wrażliwe

Wynik nie może zawierać bez wyraźnej potrzeby:

- tokenów API;
- nagłówków Authorization;
- ciasteczka;
- ścieżek systemu plików serwera;
- wewnętrznych stack trace;
- haseł i sekretów;
- pól Redmine niedostępnych dla bieżącego użytkownika;
- prywatnych notatek bez osobnego uprawnienia.

---

## 8. Adnotacje MCP

Adnotacje to wskazówki dla klienta i nie są mechanizmem autoryzacji ani ochrony.

### 8.1. Macierz wartości

| Typ operacji | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Pobierz/znajdź/listuj dane Redmine | `true` | `false` | `true` | `false` |
| Utwórz zgłoszenie/wersję/checklistę | `false` | `false` | `false` | `false` |
| Dodaj komentarz/obserwatora/relację | `false` | `false` | `false` | `false` |
| Zmień pole, zmień nazwę, ustaw flagę (`update`, `rename`, `set`) | `false` | `false` | zależy od implementacji | `false` |
| Usuń, wyczyść, zresetuj (`delete`, `purge`, `reset`) | `false` | `true` | tylko przy gwarantowanej idempotencji | `false` |
| Wyślij e-mail do zewnętrznego odbiorcy | `false` | `false` | `false` | `true` |
| Dostęp do dowolnego URL / systemu zewnętrznego | zależy | zależy | zależy | `true` |

### 8.2. Reguły

- `readOnlyHint: true` tylko, jeśli narzędzie nie zmienia stanu i nie powoduje efektów ubocznych.
- `destructiveHint` opisuje nieodwracalną utratę lub zniszczenie danych, a nie sam fakt zapisu. `destructiveHint: true` POWINNO być ustawione tylko dla nieodwracalnych operacji — `delete`, `purge`, `reset`, pełnego czyszczenia pola lub relacji.
- Zwykłe `update`, `rename` i `set` NIE są destrukcyjne: dla nich `destructiveHint: false`. Na przykład `update_checklist_title` lub `rename_wiki_page` to zwykła aktualizacja, nie zniszczenie, i destrukcyjna adnotacja jest dla nich błędna.
- `idempotentHint: true` tylko, jeśli powtórzone wywołanie jest naprawdę bezpieczne; POWINNO potwierdzić testem.
- `openWorldHint` opisuje, czy narzędzie uzyskuje dostęp do otwartego, wcześniej nieznanego świata zewnętrznego, a nie czy tworzony jest nowy obiekt. Praca z jedną skonfigurowaną instalacją Redmine to zamknięty świat: `openWorldHint: false`.
- Dlatego `create_issue`, `create_time_entry` i inne narzędzia zapisu w obrębie swojego Redmine używają `openWorldHint: false`, mimo tworzenia nowych obiektów. Tworzenie obiektu w znanym systemie nie czyni świata otwartym.
- `openWorldHint: true` tylko, gdy odbiorca lub źródło danych nie jest ograniczone do znanego systemu: wysyłanie e-maila do zewnętrznego odbiorcy, dowolne żądanie HTTP, dostęp do zewnętrznego serwisu.
- Wartość `openWorldHint` POWINNA być ustawiana świadomie dla każdego narzędzia, a nie kopiowana domyślnie: zweryfikuj, czy narzędzie faktycznie wykracza poza swoją instalację Redmine.
- Nie można kopiować jednego zestawu adnotacji na wszystkie narzędzia zapisu.

### 8.3. Efekty uboczne Redmine

Przy ocenie idempotencji uwzględniaj nie tylko końcowe pola, ale też:

- tworzenie wpisu w dzienniku;
- wysyłanie powiadomień;
- webhooki;
- dziennik audytu;
- powtórzone przesyłanie pliku;
- powtórzone tworzenie relacji;
- powtórzone logowanie wpisu czasu.

Jeśli powtórzone wywołanie tworzy dodatkowy rekord lub powiadomienie, narzędzie nie jest idempotentne.

---

## 9. Bezpieczeństwo

### 9.1. Autoryzacja

Każde wywołanie MUSI działać w kontekście uwierzytelnionego użytkownika lub jawnie udokumentowanego konta serwisowego.

Serwer MUSI sprawdzać uprawnienia Redmine dla konkretnego projektu i obiektu. Obecność narzędzia w `tools/list` nie oznacza uprawnienia do operacji.

Narzędzia administracyjne powinny:

- być publikowane tylko dla administratorów;
- lub być przeniesione do osobnego profilu/serwera MCP administracyjnego;
- lub być chronione osobnym scope.

### 9.2. Minimalne uprawnienia

Serwer MCP i token Redmine API muszą mieć minimalnie konieczne uprawnienia. Nie można używać globalnego tokena administracyjnego dla wszystkich użytkowników, jeśli model dostępu użytkownika musi być zachowany.

### 9.3. Dowolne ścieżki systemu plików zabronione

Parametry typu:

```json
{"file_path": "/etc/app/.env"}
```

są ZABRONIONE w publicznych narzędziach MCP.

Bezpieczne opcje:

1. `content_base64` z limitem rozmiaru;
2. nieprzezroczysty `upload_token` wydany przez zaufany mechanizm uploadu;
3. URI zasobu MCP, gdzie dostęp sprawdza host;
4. plik tylko z dedykowanego katalogu tymczasowego ze sprawdzeniem `realpath` i allowlist.

Serwer MUSI zweryfikować:

- maksymalny rozmiar;
- typ MIME;
- dozwolone rozszerzenie;
- nazwę pliku;
- brak path traversal;
- sprawdzenie antywirusowe/treści, jeśli wymaga polityka organizacji.

### 9.4. Dowolne URL i SSRF

Narzędzie nie może przyjmować dowolnego URL, chyba że to jego główny cel.

Gdy potrzebny jest dostęp HTTP:

- użyj allowlist domen i schematów;
- zabroń loopback, link-local, endpointów metadanych i sieci wewnętrznych, jeśli nie są potrzebne;
- ogranicz przekierowania;
- ustaw timeout i limit odpowiedzi;
- nie przekazuj wewnętrznych poświadczeń do innego origin.

### 9.5. Usuwanie i niebezpieczne operacje

Dla nieodwracalnych operacji OBOWIĄZKOWE:

- osobne narzędzie;
- `destructiveHint: true`;
- jawny opis nieodwracalności;
- precyzyjne sprawdzenie uprawnień po stronie serwera;
- dziennik audytu;
- ochrona przed usunięciem obiektu poza oczekiwanym projektem;
- sprawdzenie obiektów podrzędnych i powiązanych konsekwencji.

Logiczne `confirm_delete: true` MOŻE być użyte jako dodatkowa ochrona przed przypadkowym wywołaniem, ale nie może być traktowane jako mechanizm autoryzacji.

Dwufazowe usuwanie, optymistyczna blokada i klucz idempotencji — patrz załącznik A.

### 9.6. Logi

Dziennik audytu rejestruje:

- nazwę narzędzia;
- uwierzytelnionego użytkownika;
- ID docelowego projektu/obiektu;
- wynik;
- czas trwania;
- kod błędu;
- ID korelacji żądania.

ZABRONIONE logowanie:

- tokena dostępu;
- nagłówka Authorization;
- ciasteczka;
- zawartości pliku base64;
- tajnych pól niestandardowych;
- pełnego tekstu prywatnych notatek bez osobnej potrzeby.

### 9.7. Limit szybkości i timeout

Każde narzędzie MUSI mieć:

- limit rozmiaru wejścia;
- limit szybkości na użytkownika/token;
- limit liczby zwracanych rekordów;
- limity operacji zbiorczych.

Timeout serwera 60 s dotyczy narzędzi odczytu. Narzędzia zapisu nie są przerywane przez timeout serwera, aby po udanym zapisie można było zarejestrować wynik idempotencji.

---

## 10. Błędy

### 10.1. Rozdzielenie błędów

Używa się dwóch poziomów:

1. **Błąd protokołu** — nieznane narzędzie, uszkodzony JSON-RPC, niemożność przetworzenia żądania MCP.
2. **Tool execution error** z `isError: true` — błąd argumentu, Redmine API, uprawnień, workflow lub błąd logiki biznesowej.

Błędy, które model może naprawić zmieniając argumenty, powinny zwracać się jako błędy wykonania narzędzia.

### 10.2. Struktura błędu

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

### 10.3. Zalecane kody

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

### 10.4. Komunikat musi umożliwiać naprawę

Źle:

```text
Invalid request.
```

Dobrze:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Nie zwracaj stack trace użytkownikowi. Stack trace przechowywany jest tylko w chronionym logu serwera z ID korelacji.

---

## 11. Paginacja i objętość danych

### 11.1. Narzędzia list/search

OBOWIĄZKOWE parametry:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Dla istniejącego Redmine API dopuszczalny jest `offset`. Dla własnej implementacji preferowany jest nieprzezroczysty cursor, jeśli dane mogą aktywnie zmieniać się podczas przechodzenia.

### 11.2. Metadane paginacji

Wynik musi zawierać:

- rzeczywisty `limit`;
- `offset` lub `next_cursor`;
- `has_more`;
- `total_count`, jeśli jego uzyskanie nie tworzy znaczącego obciążenia.

### 11.3. Wybór pól

Parametr `fields` dopuszczalny jest tylko jako tablica z zamkniętej allowlist:

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

Nie można przekazywać dowolnych nazw pól bezpośrednio do SQL, ActiveRecord `select`, serializera lub Redmine API bez allowlist.

### 11.4. Duże wyniki

Duże dzienniki, załączniki i pliki muszą:

- mieć osobną paginację;
- być zwracane przez osobne narzędzie/zasób;
- dla danych binarnych zwracać link do zasobu lub inną ograniczoną referencję zamiast osadzania dużego base64 w odpowiedzi, gdy to możliwe;
- lub obsługiwać wykonanie wspomagane zadaniem, jeśli operacja jest naprawdę długa i klient to obsługuje.

`execution.taskSupport` nie jest ustawiane automatycznie. Domyślnie `forbidden`.

---

## 12. Referencja dla nowego narzędzia

Skrócony przykład narzędzia zapisu z obowiązkowym `title` i typowanym `outputSchema` zgodnie z §7.1. Format błędu — §10. Pełny JSON — w załączniku B.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
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

## 13. Testowanie

### 13.1. Testy schematu

Dla każdego narzędzia OBOWIĄZKOWE:

- co najmniej jedno poprawne wywołanie;
- co najmniej jedno negatywne wywołanie (np. brak wymaganego pola lub zły typ).

POWINNO obejmować, w zależności od schematu:

- pełne poprawne wywołanie;
- brak każdego wymaganego pola;
- zły typ kluczowych parametrów;
- nieznane dodatkowe pole;
- wartość poza enum;
- wartość poza zakresem;
- zła data/date-time;
- przekroczenie `maxItems`, `maxLength` i rozmiaru pliku;
- naruszenie wzajemnej zależności pól (oba pola XOR jednocześnie; żadne z obowiązkowej pary).

### 13.2. Testy uprawnień

Dla operacji zapisu, destrukcyjnych i wrażliwego odczytu POWINNO zweryfikować:

- użytkownika bez dostępu do projektu;
- użytkownika z dostępem tylko do odczytu;
- użytkownika z uprawnieniem edycji;
- administratora, jeśli narzędzie dotyka scenariuszy admin;
- dostęp do prywatnych notatek, jeśli narzędzie je zwraca lub zmienia;
- próbę zmiany obiektu innego projektu przez podstawione ID.

Dla prostych narzędzi tylko do odczytu bez wrażliwych danych testy uprawnień MOGĄ być ograniczone do jednego scenariusza negatywnego lub pominięte z krótkim uzasadnieniem w MR.

### 13.3. Testy idempotencji

Dla `idempotentHint: true` POWINNO być automatyczne lub ręczne testowanie dwóch lub więcej identycznych sekwencyjnych wywołań.

Zweryfikuj brak efektów ubocznych deklarowanych jako idempotentne, np.:

- dodatkowych wpisów w dzienniku;
- powtórzonych e-maili;
- duplikatów plików;
- duplikatów relacji;
- powtórzonych wpisów czasu;
- dodatkowych zdarzeń webhook, jeśli są częścią gwarancji.

### 13.4. Testy kontraktu

POWINNO utrzymywać `tools/list` jako snapshot lub w inny sposób śledzić łamiące zmiany kontraktu. CI MOŻE wykrywać:

- zmianę nazwy;
- usunięcie parametru;
- zmianę typu;
- zmianę `required`;
- wzrost poziomu ryzyka adnotacji;
- zniknięcie `outputSchema`;
- niekompatybilną zmianę pól, typów, `required`, `enum` / `const` lub gałęzi sukcesu/błędu `outputSchema`.

### 13.5. Testy wyboru LLM

Dla podobnych lub łatwo mylonych narzędzi POWINNO być zestaw żądań użytkownika i oczekiwanych wywołań narzędzi. Pełne automatyczne uruchomienie LLM MOŻE być zastąpione statycznymi przykładami w MR lub przeglądem opisu.

Przykłady:

| Żądanie | Oczekiwane narzędzie |
|---|---|
| „Pokaż zgłoszenie 123” | `redmine_get_issue` |
| „Znajdź zgłoszenia o OAuth” | `redmine_search_issues` |
| „Dodaj obserwatora 15 do zgłoszenia 123” | `redmine_add_issue_watcher` |
| „Usuń relację między zgłoszeniami” | `redmine_delete_issue_relation` |
| „Znajdź podobne zgłoszenia” | `redmine_advanced_search_semantic_search_issues` |

Test lub przegląd nie przechodzi, jeśli model z dużym prawdopodobieństwem wybiera uniwersalne destrukcyjne narzędzie dla intencji tylko do odczytu lub jest zmuszony zgadywać wartości `action`.

### 13.6. Testy odzyskiwania po błędzie

POWINNO zweryfikować, że po typowych błędach model otrzymuje wystarczające informacje do poprawnego ponowienia:

- brakującego ID;
- nieprawidłowego statusu;
- konfliktu `expected_updated_at`;
- niewystarczających uprawnień;
- przekroczonego limitu;
- złego typu MIME.

---

## 14. Checklista code review

Nowe narzędzie nie może zostać zmergowane, dopóki wszystkie obowiązkowe pozycje nie otrzymają odpowiedzi „tak”.

### Cel

- [ ] Jedna akcja; brak mieszania operacji `action`/`manage` (§3.1–3.2).
- [ ] Operacja administracyjna rozdzielona od zwykłej.

### Nazwa i opis

- [ ] Nazwa zaczyna się od `redmine_`: rdzeń — `redmine_<verb>_<entity>`; wtyczka zewnętrzna — `redmine_<plugin_id>_…` (§4.1).
- [ ] Opis: cel, efekty uboczne, krótki wynik; podobne narzędzia rozróżnialne (§5).
- [ ] Odwołania krzyżowe do innych narzędzi używają pełnych nazw z `tools/list` (§5.2.1).

### Badanie kontraktu źródłowego

- [ ] Dla narzędzia rdzeniowego przestudiowano REST API zasobu, wersje i wtyczki w razie potrzeby; raport pokrycia POWINIEN być dołączony do MR (§5.6–5.7).
- [ ] Dla narzędzia rozszerzenia MUSI być zweryfikowany serializer źródłowy / serwis / endpoint REST i co najmniej jedna rzeczywista udana odpowiedź dla każdej formy wyniku (§18.5).
- [ ] Kontrakt porównany z bieżącym `tools/list`.

### Input schema

- [ ] Schemat zgodny z §6 (`additionalProperties: false`, typy, `required`, `enum`/`const`, ograniczenia).
- [ ] Każdy parametr ma sensowny `description` (§6.14); `*_id` ma `minimum: 1` (§4.3).
- [ ] Dla `*_id` i innych wartości lookup określona ścieżka discovery (§6.16): narzędzie list, pole odpowiedzi get/list lub `enum`.
- [ ] „Dokładnie jedno z …” / ograniczenia wzajemnej zależności sformalizowane w schemacie, nie tylko w opisie (§5.3, §6.12).
- [ ] Optymistyczna blokada — tylko `expected_updated_at`, nie `updated_at` (§4.4).
- [ ] Dla opcjonalnych pól `set_*` rozstrzygnięte czyszczenie: `null`, osobne narzędzie clear lub jawna odmowa (§6.13).
- [ ] Brak „obiektu lub stringa JSON” i dowolnych `fields`/`payload`.
- [ ] `*_id` — integer; walidacja po stronie serwera zgodnie z §3.4.

### Wyjście i błędy

- [ ] Nowe narzędzie ma `outputSchema` z kopertą sukcesu/błędu (§7.1–7.2).
- [ ] Znane stabilne pola wyniku opisane w `properties`; `additionalProperties: true` nie używane zamiast znanego kontraktu.
- [ ] Wszystkie gwarantowane pola są w `required`.
- [ ] Pola nullable i optional rozróżnione świadomie.
- [ ] `enum`/`const`, `date`/`date-time`, zakresy i inne znane ograniczenia sformalizowane w schemacie.
- [ ] Dla wartości pieniężnych i innych numerycznych wartości biznesowych jasne są jednostki, waluta i jednostki główne/pomocnicze.
- [ ] Niezmienniki biznesowe wyniku odzwierciedlone w schemacie (`const`, `enum`, `required` lub schemat warunkowy), nie tylko wnioskowane z nazwy narzędzia.
- [ ] Opis, `outputSchema` i rzeczywista odpowiedź handlera/REST/serwisu nie przeczą sobie (§7.1.1).
- [ ] Wewnętrzne wartości REST/Ruby/wtyczki znormalizowane do stabilnego kontraktu MCP; brak wycieku STI/nazw klas lub formatu zależnego od locale (§3.3).
- [ ] Narzędzie list zwraca krótką, ale wystarczającą strukturę; opis poprawnie wyjaśnia, kiedy odpowiadające narzędzie get jest naprawdę potrzebne.
- [ ] Błędy: `isError`, stabilny kod, naprawialny komunikat; brak sekretów lub stack trace (§10).

### Adnotacje

- [ ] Adnotacje odpowiadają ryzyku (§8); test zalecany dla `idempotentHint: true`.

### Bezpieczeństwo

- [ ] Uprawnienia, ścieżka pliku, SSRF, limity, logi, destrukcyjne/audyt — zgodnie z §9; wzorce załącznika A w razie potrzeby.

### Testy

- [ ] Minimalne testy schematu; reszta według ryzyka (§13).

---

## 15. Kompatybilność i zmiana istniejących narzędzi

### 15.1. Zmiany łamiące kompatybilność

Zmiana łamiąca kompatybilność:

- zmiana nazwy narzędzia;
- usunięcie pola;
- zmianę typu;
- dodanie nowego wymaganego pola;
- zmiana znaczenia pola;
- niekompatybilna zmiana wyjścia;
- scalenie kilku operacji w jedną;
- zwiększenie ryzyka bez aktualizacji adnotacji i dokumentacji.

### 15.2. Migracja nazw

Przy migracji, na przykład ze starego prefiksu `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

do krótkiego prefiksu `redmine_`:

```text
redmine_get_issue
```

postępuj:

1. dodaj nową nazwę;
2. tymczasowo zachowaj stary alias;
3. oznacz stare narzędzie jako deprecated w opisie;
4. zbieraj metryki wywołań starej nazwy;
5. usuń alias po uzgodnionym okresie;
6. wyślij `notifications/tools/list_changed`, jeśli serwer deklaruje `listChanged`.

### 15.3. Zmiana opisów

Opis wpływa na wybór narzędzia przez model i jest traktowany jako zmiana behawioralna. Przy istotnej zmianie opisu POWINNO przejrzeć przykłady wyboru LLM lub przeprowadzić powtórny przegląd wyboru.

### 15.4. Wersja serwera

Wersja serwera MCP zwracana jest przez osobne narzędzie tylko do odczytu lub metadane serwera. Nie dodawaj `v1`, `v2` do każdej nazwy bez realnej potrzeby obsługi równoległych niekompatybilnych kontraktów.

---

## 16. Reguły dla bieżących problemów Redmine MCP

Przy rozwijaniu nowych narzędzi zabronione jest powtarzanie wzorców z audytu bieżącego kontraktu. Reguły kanoniczne są w odpowiednich sekcjach; poniżej tylko mapa problemów:

| Problem z audytu | Sekcja |
|---|---|
| Nazwy bez prefiksu `redmine_` (w tym wtyczki zewnętrzne) / mieszany styl w obrębie jednej wtyczki | §4.1 |
| Czasownik nie odpowiada semantyce (`complete_*` z `done=true/false` zamiast `set_*`) | §4.2 |
| Liczbowy ID bez `minimum: 1` lub z opisem "Issue id" | §4.3 |
| Optymistyczna blokada jako `updated_at` zamiast `expected_updated_at` | §4.4, A.2 |
| Uniwersalne `manage_*` / `patch_*` i parametr `action` | §3.1, §4.2 |
| Parametry bez `type`, enum tylko w opisie, tablice bez `items` | §5.3, §6 |
| Parametry bez `description`; zbyt krótkie opisy bez odwołania do narzędzia lookup | §6.14 |
| Brak `examples` na parametrach referencyjnych i identyfikatorach | §6.15 |
| Narzędzie zapisu z `*_id` bez ścieżki discovery (brak narzędzia list i opcji w odpowiedzi get) | §6.16 |
| Opis obiecuje „dokładnie jedno z A lub B”, schemat tego nie koduje | §5.3, §6.12 |
| Krótkie nazwy narzędzi w odwołaniach krzyżowych (`list_projects` zamiast `redmine_list_projects`) | §5.2.1 |
| Przeładowany opis narzędzia na pół strony | §5.2 |
| `fields` / `extra_fields` bez schematu; dodatkowe `required` | §6.4, §6.11 |
| `set_*` bez sposobu wyczyszczenia pola i bez jawnej odmowy | §6.13 |
| Jeden zestaw adnotacji na wszystkie narzędzia zapisu; nadmiar `openWorldHint` | §8 |
| `destructiveHint: true` na zwykłym `update` / `rename`; zły `openWorldHint` na `create_*` | §8.1, §8.2 |
| Opis obiecuje strukturę odpowiedzi, ale `outputSchema` brakuje lub opisuje tylko dowolny obiekt | §7.1 |
| Opis, schemat i rzeczywista odpowiedź przeczą sobie | §7.1.1 |
| Nazwy STI/klas lub daty locale w odpowiedzi MCP | §3.3 |
| `additionalProperties: true` zamiast znanych pól list/get | §7.1 |
| Dowolny `file_path`, obejście zakresu projektu, SSRF | §9 |
| Efekt e-mail/zewnętrzny w jednym narzędziu ze zmianą lokalną | §3.2 |
| Niejednoznaczne pary podobnych narzędzi | §5.4 |

---

## 17. Struktura zestawu narzędzi

Pełna bieżąca lista narzędzi nie jest duplikowana w tym dokumencie — szybko się dezaktualizuje.

**Źródło prawdy:**

- narzędzia rdzeniowe — [03-core-tools.md](03-core-tools.md) i rzeczywisty `tools/list` na instalacji;
- narzędzia wtyczek zewnętrznych — §18 i odpowiedź MCP `tools/list` na instalacji.

**Zasady grupowania** (każda grupa — osobne atomowe narzędzia zgodnie z §3):

| Grupa | Przykładowe intencje | Prefiks |
|---|---|---|
| Zgłoszenia | get, list, search, create, update, delete, copy, subtasks | `redmine_` |
| Relacje i obserwatorzy | list/create/delete relation; add/remove watcher | `redmine_` |
| Projekty i członkowie | projects, modules, members, roles | `redmine_` |
| Wersje i kategorie | versions; issue categories | `redmine_` |
| Wpisy czasu | list, create, update, import, activities | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| Pliki i załączniki | list, upload, delete, download | `redmine_` |
| Admin | users, roles, server info | `redmine_admin_` lub `redmine_get_server_info` |
| Encje wtyczek | checklists, search itd. | `redmine_` + `plugin_id`, np. `redmine_advanced_search_` |

Przed dodaniem nowego narzędzia POWINNO sprawdzić odpowiedź MCP `tools/list` i odpowiednią grupę: nie duplikuj istniejącego narzędzia i nie mieszaj różnych intencji w jednej nazwie.

Jeśli grupa ma narzędzie zapisu z parametrem ID (`status_id`, `role_ids`, …), ta sama grupa MUSI mieć ścieżkę discovery (§6.16).

Narzędzia administracyjne publikowane są tylko dla użytkowników z wymaganymi uprawnieniami (§9.1).

---

## 18. Rozszerzenia wtyczek zewnętrznych

Sekcja dla autorów wtyczek Redmine dodających narzędzia przez Extension API. Techniczny opis API, hooków i przypadków brzegowych — w [04-extensions.md](04-extensions.md).

Rozszerzenia podlegają tym samym regułom kontraktu, bezpieczeństwa i nazewnictwa (§3–§10, §4.1) co narzędzia rdzeniowe `redmine_mcp`.

### 18.1. Kiedy publikować co

| Prymityw | Kiedy używać |
|---|---|
| **Tool** | Jedna akcja na encji wtyczki lub Redmine: create, get, update, delete, search |
| **Resource** | Duża lub statyczna treść po stabilnym URI: treść wiki, plik, długi raport |
| **Prompt** | Powtarzalny szablon scenariusza dla użytkownika, nie operacja z efektem ubocznym |
| **`extend_tool`** | Parametr lub hook logicznie część istniejącego narzędzia rdzeniowego (np. `include_*` przy odczycie zgłoszenia) |

Jeśli model może zrealizować intencję osobnym narzędziem bez zgadywania `action` — preferuj **własne narzędzie**, a nie `extend_tool` rozdmuchujący inny schemat.

### 18.2. Rejestracja

- Plik rozszerzenia ładuje się przy starcie Redmine: `lib/<plugin_id>/mcp.rb` (patrz `ExtensionLoader`).
- Moduł w `mcp.rb` MUSI być `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): Zeitwerk wyprowadza nazwę z pliku.
- Przed rejestracją POWINNO sprawdzić `mcp_extension_enabled?` — twarda zależność od `redmine_mcp` w gemspec nie jest wymagana.
- Użyj `register_tool_once` do rejestracji, aby reload nie duplikował narzędzia.
- Pełna nazwa w `tools/list` MUSI zaczynać się od `redmine_` (§4.1).
- Narzędzie MUSI mieć `title`, `description`, `input_schema`, `output_schema`, `permission` i `annotations`; duplikacja nazwy zabroniona.
- Narzędzie widoczne jest w odpowiedzi MCP `tools/list` tylko dla użytkowników z odpowiednim uprawnieniem.

### 18.3. Nazewnictwo

- Nazwa MUSI zaczynać się od `redmine_`; potem — `plugin_id` i `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Czasowniki i zakaz `manage_*` — zgodnie z §4.2 i §3.1.
- Nie kopiuj nazw narzędzi rdzeniowych i nie publikuj drugiego narzędzia z tą samą intencją pod inną nazwą.

Przed rejestracją POWINNO porównać z odpowiedzią `tools/list` na docelowej instalacji.

### 18.4. Uprawnienia i bezpieczeństwo

- `permission` MUSI odpowiadać rzeczywistym uprawnieniom Redmine lub wtyczki, a nie osobnej roli „tylko mcp”.
- Dla operacji na zgłoszeniach POWINNO używać `register_issue_tool` i `find_accessible_issue` zamiast kopiowania sprawdzeń widoczności i modułu projektu.
- Jeśli `module_name` jest ustawione, narzędzie MUSI być w `tools/list` tylko, gdy użytkownik ma zadeklarowane uprawnienie w co najmniej jednym widocznym projekcie z włączonym modułem. Bez `module_name` wystarczy uprawnienie w co najmniej jednym widocznym projekcie. Handler nadal sprawdza konkretne zgłoszenie, w tym moduł jego projektu.
- Powtórzona walidacja argumentów i uprawnień po stronie serwera w handlerze — zgodnie z §3.4 i §9, nawet jeśli narzędzie jest ukryte w `tools/list` dla innych użytkowników.

### 18.5. Czysta implementacja

**Cienka warstwa MCP.** `mcp.rb` powinien zawierać głównie rejestrację narzędzi: schematy, opisy, uprawnienia, adnotacje i krótkie handlery. Handler waliduje argumenty, sprawdza kontekst i deleguje wykonanie do osobnej klasy/serwisu.

Logika biznesowa wtyczki powinna pozostać w zwykłych modelach i serwisach i nie zależeć od MCP.

Jeśli logika potrzebna jest tylko dla MCP — np. łączenie danych z kilku modeli, normalizacja odpowiedzi REST do kontraktu MCP, obliczanie pól pochodnych lub przygotowanie wyniku narzędzia — MOŻNA przenieść ją do osobnego `mcp_tools.rb`. Jeśli taki plik staje się duży, POWINNO podzielić na klasy według encji lub operacji, np. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Nie umieszczaj logiki biznesowej i dużych transformacji bezpośrednio w lambda/handlerze wewnątrz `mcp.rb`.

**Dostęp do danych.**

- Modele i serwisy wtyczki — jeśli logika już tam jest.
- `internal_request` / `internal_get` / REST — jeśli trzeba ponownie użyć istniejącego kontrolera API; endpoint musi obsługiwać `accept_api_auth`. Użyj `internal_request` dla `POST`, `PUT`, `PATCH` i `DELETE`; użyj `internal_get` lub `internal_request(method: 'GET', ...)` dla odczytów. Sprawdzaj błędy przez `internal_request_error?`.

**`extend_tool` — umiarkowanie.** Właściwe, gdy parametr jest częścią jednej intencji z narzędziem rdzeniowym. Niewłaściwe, gdy wtyczka zasadniczo dodaje osobny podsystem: lepiej własny prefiks i własne narzędzia, powiązanie z rdzeniem opisane w `description` lub instrukcjach serwera.

**Kontrakt jak rdzeń.** Wejście — zgodnie z §6. Wyjście — zgodnie z §7.1 i §7.1.1: stabilne pola, `required`, `enum`/`const`, jednostki, normalizacja wewnętrznego API. Adnotacje według ryzyka, naprawialne błędy (§8, §10). Optymistyczna blokada — `expected_updated_at` (§4.4). Każdy parametr — `description` (§6.14). Odwołania krzyżowe — pełne nazwy (§5.2.1). Każdy parametr zapisu `*_id` — ścieżka discovery (§6.16): osobne `list_*` lub opcje z `id` w odpowiedzi get/list i jawne odwołanie w opisie parametru.

Przed publikacją narzędzia rozszerzenia MUSI zweryfikować serializer źródłowy / serwis / endpoint REST i co najmniej jedną rzeczywistą udaną odpowiedź dla każdej formy wyniku.

**Współdzielony kod — w `redmine_mcp`.** Przy rozwijaniu rozszerzenia, jeśli fragment może być potrzebny innej wtyczce MCP, POWINNO dodać go do rdzenia `redmine_mcp` natychmiast, a nie kopiować do `lib/<plugin>/mcp*.rb`.

Kryterium: logika nie jest związana z jedną domeną wtyczki (checklists, search, …) i opisuje kontrakt MCP, Extension API lub typowy wzorzec integracji.

| Gdzie | Co |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, rozszerzenie `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, wspólne helpery uprawnień po `issue_id` / `project_id` |
| **Rozszerzenie wtyczki** | `mcp.rb` — rejestracja narzędzi i krótkie handlery; `mcp_tools.rb` / `mcp_tools/*.rb` — pobieranie, agregacja, normalizacja specyficzne dla MCP; zwykłe modele/serwisy — logika biznesowa niezależna od MCP |

**Zalecane rozmieszczenie dla rozszerzenia:**

- `mcp.rb` — rejestracja narzędzi i krótkie handlery;
- `mcp_tools.rb` / `mcp_tools/*.rb` — pobieranie, agregacja i normalizacja danych specyficzne dla MCP;
- zwykłe modele/serwisy — logika biznesowa niezależna od MCP.

Przed skopiowaniem helpera z innego rozszerzenia POWINNO sprawdzić, czy analog już istnieje w `redmine_mcp`; jeśli brak — przenieś do rdzenia w tym samym PR, nie duplikuj.

Więcej o Extension API — [04-extensions.md](04-extensions.md) (§ „ExtensionApi helper methods”).

### 18.6. Antywzorce

ZABRONIONE lub niezalecane:

- rejestrowanie narzędzi przy każdym żądaniu HTTP;
- awaria przy błędzie sąsiedniej wtyczki przy starcie;
- mieszanie odczytu, zapisu i admin w jednym narzędziu;
- duplikowanie narzędzia rdzeniowego „pod inną nazwą”;
- rozszerzanie innego narzędzia opcjonalnymi parametrami „na przyszłość”;
- zwracanie w MCP wewnętrznych pól niedostępnych użytkownikowi w UI/API wtyczki;
- publikowanie nazw klas STI, dat locale lub reprezentacji REST, jeśli schemat MCP definiuje inny kontrakt (§3.3, §7.1.1);
- opisywanie elementu listy tylko jako `{ "type": "object", "additionalProperties": true }` (§7.1);
- publikowanie `set_*_status` / podobnego z `status_id` bez dawania modelowi sposobu poznania dozwolonych ID (§6.16);
- duplikowanie wspólnych helperów MCP w rozszerzeniu (koperta `outputSchema`, wrappery `internal_request`, uprawnienia zgłoszenia), jeśli ich miejsce jest w `redmine_mcp` — patrz §18.5.

### 18.7. Weryfikacja przed merge

- [ ] Nazwa narzędzia zaczyna się od `redmine_` zgodnie z §4.1 / §18.3.
- [ ] Rozszerzenie ładuje się przy starcie; narzędzie pojawia się w `tools/list` dla użytkownika z uprawnieniami.
- [ ] Narzędzie nieobecne dla użytkownika bez uprawnień i gdy flaga rozszerzenia MCP wtyczki wyłączona.
- [ ] Kontrakt i checklista (§14) spełnione, w tym porównanie opisu / outputSchema / rzeczywistej odpowiedzi (§7.1.1); testy zgodnie z §13 w razie potrzeby.
- [ ] Serializer / REST / serwis zweryfikowany na co najmniej jednej rzeczywistej udanej odpowiedzi dla każdej opublikowanej formy wyniku (np. list i get, jeśli obie publikowane).
- [ ] Brak duplikacji istniejącego narzędzia w `tools/list`.
- [ ] Dla każdego parametru zapisu `*_id` istnieje ścieżka discovery (§6.16).

---

## 19. Źródła i podstawa normatywna

Dokument przygotowany na dzień 2026-07-22 na podstawie następujących źródeł podstawowych:

1. Model Context Protocol, **Protocol Revision 2025-11-25**  
   https://modelcontextprotocol.io/specification/2025-11-25

2. Model Context Protocol, **Tools**  
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Model Context Protocol, **Schema Reference**  
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Model Context Protocol, **Security Best Practices**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Model Context Protocol, **Understanding Authorization in MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog, **Tool Annotations as Risk Vocabulary: What Hints Can and Can't Do**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Server Instructions: Giving LLMs a user manual for your server**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON Schema, **Reference**  
   https://json-schema.org/understanding-json-schema/reference

9. JSON Schema, **Enumerated values**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON Schema, **Conditional schema validation**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **REST API overview**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **REST Issues**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **REST API changes**  
    Link `API changes for each version` na stronie REST API; zweryfikowany dla wszystkich obsługiwanych wersji.

---

## 20. Kryterium gotowości nowego narzędzia

Nowe narzędzie MCP uznaje się za gotowe, gdy obowiązkowe pozycje checklisty code review (§14) są spełnione.

Dla narzędzi wtyczek zewnętrznych dodatkowo — checklista §18.7.

Zalecenia ryzyka: raport pokrycia (§5.7), dodatkowe testy §13.2–13.6 i załącznik A. Minimalne testy schematu (§13.1) i reguły `outputSchema` (§7.1, §7.1.1) są obowiązkowe.

---

## Załącznik A. Zalecane wzorce implementacji

Wzorce poniżej nie są obowiązkowe dla każdego narzędzia MCP. POWINNO się je rozważyć przy podwyższonym ryzyku: operacje destrukcyjne, narzędzia admin, zbiorczy zapis, zewnętrzne efekty uboczne, powtarzane wywołania z powodu timeout.

### A.1. Dwufazowe usuwanie (prepare / confirm)

Dla szczególnie niebezpiecznych operacji administracyjnych:

1. `redmine_prepare_delete_*` zwraca krótki opis konsekwencji i jednorazowy token;
2. `redmine_confirm_delete_*` przyjmuje token z krótkim TTL.

Wymagania normatywne dla operacji destrukcyjnych — w §9.5.

### A.2. Optymistyczna blokada

Przy update/delete przy równoczesnej zmianie parametr MUSI być nazwany `expected_updated_at` (§4.4), nie `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Nazwa jest ujednolicona dla narzędzi rdzeniowych i rozszerzeń (w tym narzędzi zapisu checklisty).

Przy konflikcie zwraca `CONFLICT`, rzeczywisty czas modyfikacji obiektu (`updated_at` / `updated_on` w odpowiedzi) i zalecenie ponownego odczytu obiektu.

### A.3. Klucz idempotencji

Dla operacji, gdzie powtórzenie z powodu timeout może utworzyć duplikat:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Szczególnie właściwe dla:

- tworzenia zgłoszenia;
- importu wpisu czasu;
- przesyłania pliku;
- operacji zbiorczych;
- wysyłania e-maila.

Jeśli narzędzie publikuje `idempotentHint: true`, powtórzone wywołanie musi być bezpieczne (§8.2); `idempotency_key` to jeden ze sposobów zapewnienia tego.

---

## Załącznik B. Pełny przykład narzędzia

Referencja `redmine_create_issue`. Gdy zmienia się format błędu lub koperta, zaktualizuj §7, §10 i tę sekcję; §12 pozostaje skrócony.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown. This operation may create notifications and is not idempotent unless idempotency_key is supplied.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Issue description in Redmine text format."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker ID returned by redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Issue priority ID returned by redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "User ID of the assignee, from redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format.",
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

Uwaga: jeśli serwer gwarantuje idempotencję przy obecności `idempotency_key`, adnotacja nadal opisuje narzędzie jako całość. Dlatego bezpieczna wartość pozostaje `false`, jeśli dopuszczalne jest wywołanie bez klucza.

