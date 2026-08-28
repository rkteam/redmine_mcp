# Uwierzytelnianie i autoryzacja

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Przegląd

Dostęp do MCP wykorzystuje standardowe uwierzytelnianie kluczem API Redmine. Wszystkie operacje są wykonywane w imieniu użytkownika będącego właścicielem klucza.

## Cel

Zapewnić, że MCP nie omija zabezpieczeń Redmine i użytkownicy mogą wykonywać tylko dozwolone im działania.

## Obszary objęte

- Uprawnienia
- API
- Użytkownicy

## Reguły biznesowe

### Uwierzytelnianie

- Aby uzyskać dostęp do `/mcp`, REST API Redmine musi być włączone.
- Klucz API jest przekazywany w nagłówku `X-Redmine-API-Key` (nie z treści żądania JSON ani z query string).
- Akceptowane są tylko klucze aktywnych użytkowników.
- Żądania bez klucza lub z nieprawidłowym kluczem są odrzucane.

### Globalne uprawnienie MCP

- Użytkownik musi mieć globalne uprawnienie **Use MCP** (`use_mcp`) lub być administratorem Redmine.
- Uprawnienie `use_mcp` jest włączane ręcznie dla wymaganych ról w **Administration → Roles and permissions**.
- Administratorzy zawsze mają dostęp do MCP: standardowa globalna kontrola uprawnień Redmine pozwala adminowi niezależnie od ról.
- Dla innych użytkowników bez `use_mcp` żądanie jest odrzucane nawet przy ważnym kluczu API.

### Uprawnienia narzędzi

- Każde narzędzie ma własne wymaganie uprawnienia Redmine.
- Narzędzie pojawia się w `tools/list` tylko wtedy, gdy użytkownik ma uprawnienie do jego użycia.
- Uprawnienia są sprawdzane ponownie przy wywołaniu narzędzia.
- Dane są filtrowane według reguł widoczności Redmine (projekty, zgłoszenia, członkowie).

### Uprawnienia zasobów i promptów

- Zasoby i prompty mogą mieć własne wymagania uprawnień.
- Bez uprawnienia zasób lub prompt nie jest listowany i nie może być odczytany.
- Kontrole uprawnień zasobów i promptów uwzględniają URI i argumenty wejściowe (w tym `project` / `project_id`). Jeśli projekt nie jest podany w argumentach, wystarczy uprawnienie w co najmniej jednym widocznym projekcie.
- Rozszerzenie może zdefiniować jawne reguły rozwiązywania projektu z URI i argumentów.

## Przypadki brzegowe

- Nieaktywny użytkownik nie może korzystać z MCP nawet z wcześniej wydanym kluczem.
- Administrator ma dostęp do MCP bez osobnego przypisania `use_mcp`.
- Narzędzie ze sprawdzaniem uprawnień w zakresie encji (na przykład zgłoszenie) może być widoczne w `tools/list` z pustymi argumentami, jeśli użytkownik ma odpowiednie uprawnienie w co najmniej jednym projekcie.
- Jeśli takie narzędzie wymaga też modułu projektu Redmine, „co najmniej jeden projekt” oznacza widoczny projekt, w którym użytkownik ma uprawnienie i włączony jest wymagany moduł. Bez wymagania modułu wystarczy uprawnienie w co najmniej jednym widocznym projekcie. Obecność w `tools/list` nie oznacza uprawnienia do konkretnego zgłoszenia: uprawnienia i dostępność obiektu są sprawdzane ponownie przy wywołaniu.

## Obsługa błędów

| Sytuacja | Wynik |
|----------|-----------|
| REST API wyłączone | HTTP 401 |
| Nieprawidłowy lub brakujący klucz API | HTTP 401 |
| Brak uprawnienia Use MCP | HTTP 403 |
| Brak uprawnienia do konkretnego narzędzia | Narzędzie nieobecne w `tools/list`; bezpośrednie wywołanie — błąd „Permission denied” |
| Encja niedostępna dla użytkownika | Odpowiedź narzędzia z opisem błędu (na przykład „Issue not found”) |

## Scenariusze testowe

1. Żądanie z ważnym kluczem i uprawnieniem Use MCP — pomyślny dostęp.
2. Żądanie bez nagłówka klucza API — HTTP 401.
3. Żądanie z kluczem nie-admina bez uprawnienia Use MCP — HTTP 403.
4. Klucz administratora bez roli z `use_mcp` — pomyślny dostęp.
5. Użytkownik widzi w `tools/list` tylko narzędzia, do których ma uprawnienie.
6. Wywołanie narzędzia dla niedostępnego zgłoszenia zwraca błąd, a nie dane innego użytkownika.
7. Narzędzie w zakresie zgłoszenia z wymaganiem modułu projektu nie jest widoczne w `tools/list`, jeśli użytkownik ma uprawnienie, ale nie ma widocznego projektu z włączonym modułem; jest widoczne, jeśli taki projekt istnieje.
