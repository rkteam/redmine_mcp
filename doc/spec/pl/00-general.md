# Redmine MCP — specyfikacja ogólna

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Przegląd

Wtyczka Redmine MCP udostępnia serwer MCP (Model Context Protocol) wewnątrz instalacji Redmine. Klienci AI łączą się z jednym punktem końcowym HTTP i uzyskują dostęp do danych Redmine przez narzędzia, zasoby i prompty.

Wtyczka zawiera podstawowy zestaw narzędzi do pracy z projektami, zgłoszeniami i użytkownikami. Inne zainstalowane wtyczki Redmine mogą rozszerzać MCP bez zmiany kodu Redmine MCP.

## Cel

Zapewnić jeden mechanizm integracji Redmine z systemami AI, w którym:

- użytkownik działa w ramach swoich uprawnień Redmine;
- deweloperzy wtyczek mogą dodawać własne możliwości MCP;
- nie jest wymagany osobny serwer MCP ani fork pod konkretną instalację.

## Główne scenariusze

1. **Podłączenie klienta AI** — administrator włącza MCP, nadaje uprawnienie `use_mcp` wymaganym rolom i wydaje klucz API; użytkownik podłącza klienta (Cursor itd.) do punktu końcowego `/mcp`.
2. **Praca z danymi Redmine** — klient wywołuje narzędzia w celu pobrania projektów, zgłoszeń i użytkowników.
3. **Rozszerzenie przez inne wtyczki** — po zainstalowaniu wtyczki z rozszerzeniem MCP jej narzędzia automatycznie pojawiają się na wspólnej liście.
4. **Administracja** — włączanie/wyłączanie MCP oraz włączanie integracji MCP dla poszczególnych wtyczek.

## Obszary objęte

- API (MCP przez HTTP)
- Uprawnienia
- Ustawienia
- Zgłoszenia
- Projekty
- Użytkownicy
- Tablice
- Wtyczki (rozszerzenia)

## Reguły biznesowe

- MCP jest dostępne tylko po jawnej aktywacji w ustawieniach wtyczki.
- Wszystkie operacje są wykonywane w imieniu uwierzytelnionego użytkownika Redmine.
- Zapisy przez MCP przechodzą przez modele Redmine: uruchamiane są callbacki modeli. Hooki kontrolera (`controller_issues_*_save`, `controller_journals_edit_post` itd.) nie są wywoływane przez MCP.
- Widoczność danych podlega regułom Redmine: użytkownik nie otrzymuje więcej, niż może zobaczyć w interfejsie webowym.
- Nazwy narzędzi i promptów mają format `<plugin_id>_<name>`, na przykład `redmine_list_projects`.
- Pola `title` i `description` narzędzi rdzeniowych są publikowane po angielsku do wyboru przez LLM i **nie są lokalizowane** przez `en.yml`/`ru.yml` (wyjątek od standardu i18n dla katalogu narzędzi MCP). Komunikaty błędów i interfejs ustawień są lokalizowane.
- Rozszerzenia z innych wtyczek nie tworzą twardej zależności: jeśli Redmine MCP nie jest obecne, wtyczka zewnętrzna nadal działa.

## Przypadki brzegowe

- Gdy MCP jest wyłączone, wszystkie żądania do `/mcp` są odrzucane.
- Gdy jedno rozszerzenie zawiedzie, pozostałe rozszerzenia i narzędzia rdzeniowe nadal działają.
- Nowe narzędzia z rozszerzeń stają się dostępne po restarcie Redmine; klient MCP może wymagać ponownego połączenia, aby odświeżyć listę narzędzi.
- W trybie bezstanowym każde żądanie HTTP jest obsługiwane niezależnie; sesja nie jest zachowywana między żądaniami.

## Obsługa błędów

- Błędy uwierzytelniania i autoryzacji są zwracane na poziomie HTTP.
- Błędy wykonania narzędzia są zwracane w formacie MCP z flagą błędu.
- Błędy ładowania rozszerzeń są logowane i nie blokują startu Redmine.

## Pliki specyfikacji

| Plik | Zawartość |
|------|---------|
| [console-commands.md](console-commands.md) | Polecenia instalacji, weryfikacji i konserwacji |
| [01-mcp-server.md](01-mcp-server.md) | Punkt końcowy HTTP, protokół MCP, transport |
| [02-authentication.md](02-authentication.md) | Uwierzytelnianie i kontrola dostępu |
| [03-core-tools.md](03-core-tools.md) | Wbudowane narzędzia Redmine |
| [04-extensions.md](04-extensions.md) | API rozszerzeń dla innych wtyczek |
| [05-settings.md](05-settings.md) | Ustawienia wtyczki i logowanie |
| [mcp_tool_development.md](mcp_tool_development.md) | Wymagania dotyczące rozwoju narzędzi MCP (dev-guide) |
| [extension_guide.md](extension_guide.md) | Przewodnik dla deweloperów rozszerzeń |

## Scenariusze testowe

1. Po instalacji i włączeniu MCP klient pomyślnie wykonuje `initialize` i otrzymuje informacje o serwerze.
2. Użytkownik z uprawnieniem Use MCP i ważnym kluczem API widzi listę narzędzi dostępnych dla niego.
3. Użytkownik bez uprawnienia Use MCP nie ma dostępu do `/mcp`.
4. Po zainstalowaniu wtyczki rozszerzającej jej narzędzia są obecne w `tools/list` dla użytkownika z odpowiednimi uprawnieniami.
