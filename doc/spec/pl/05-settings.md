# Ustawienia i logowanie

[Deutsch](../de/05-settings.md) | [English](../en/05-settings.md) | [Español](../es/05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Przegląd

Wtyczka Redmine MCP jest konfigurowana przez standardowy interfejs ustawień wtyczek Redmine. Działanie MCP jest dodatkowo logowane.

## Cel

Dać administratorowi kontrolę nad włączaniem MCP oraz włączaniem integracji MCP dla poszczególnych wtyczek.

## Obszary objęte

- Ustawienia
- UI
- Wtyczki

## Reguły biznesowe

### Parametry ustawień

Ustawienia są dostępne w **Administration → Plugins → Redmine MCP → Configure**.

| Parametr | Domyślnie | Opis |
|----------|--------------|----------|
| Enable MCP | off | Włącza lub wyłącza punkt końcowy `/mcp`. Po włączeniu rozszerzenia MCP zainstalowanych wtyczek są ładowane automatycznie |
| Read-only mode | off | Blokuje narzędzia zapisu i operacje zapisu |
| MCP extensions | all enabled | Checkboxy obok nazw zainstalowanych wtyczek z integracją MCP |

### Rozszerzenia MCP w interfejsie

- Pole tekstowe na listę identyfikatorów („Disabled extensions”) i referencyjna lista wszystkich zainstalowanych wtyczek nie są używane.
- Osobny checkbox auto-load rozszerzeń nie jest używany.
- Zamiast tego strona ustawień pokazuje listę zainstalowanych wtyczek posiadających integrację MCP.
- Wtyczka uznawana jest za posiadającą integrację MCP, jeśli ma plik rozszerzenia według tej samej konwencji co auto-load (zob. [04-extensions.md](04-extensions.md)).
- Wtyczka `redmine_mcp` nie jest pokazywana na tej liście.
- Każdy element ma checkbox i nazwę wtyczki.
- Legenda listy ma przełącznik Check all / Uncheck all, jak projekty i trackery w formularzu pola niestandardowego.
- Zaznaczony checkbox oznacza, że rozszerzenie MCP wtyczki jest ładowane, gdy MCP jest włączone.
- Odznaczony checkbox oznacza, że rozszerzenie wtyczki nie jest ładowane, nawet jeśli plik rozszerzenia istnieje.
- Jeśli żadna zainstalowana wtyczka nie ma integracji MCP, lista jest pusta: wyświetlany jest standardowy komunikat Redmine „no data”; przełącznik Check all / Uncheck all jest ukryty.
- Wcześniej zapisane identyfikatory wyłączonych wtyczek nadal obowiązują: odpowiednie checkboxy pojawiają się jako odznaczone.

### Zachowanie przy zmianie ustawień

- Wyłączenie MCP natychmiast blokuje wszystkie żądania do `/mcp` (HTTP 503).
- Gdy MCP jest włączone, rozszerzenia ładują się przy starcie Redmine. Gdy MCP jest wyłączone, auto-load rozszerzeń nie działa.
- Zmiana checkboxów rozszerzeń MCP wchodzi w życie po restarcie Redmine.

## Logowanie

### Co jest logowane

- początek i koniec ładowania rozszerzeń;
- pomyślna rejestracja narzędzi, zasobów, promptów;
- rozszerzanie istniejących narzędzi;
- błędy rejestracji i ładowania rozszerzeń;
- błędy wykonania narzędzi;
- odmowy dostępu do MCP i narzędzi.

### Format

- Komunikaty są zapisywane do standardowego logu Rails.
- Każdy komunikat ma prefiks `[redmine_mcp]`.
- Osobne ustawienie poziomu logowania nie jest używane: wtyczka zapisuje wszystkie swoje komunikaty.

## Przypadki brzegowe

- Jeśli wszystkie checkboxy rozszerzeń MCP są włączone (lub żadna wtyczka nie ma integracji), wszystkie znalezione rozszerzenia ładują się, gdy MCP jest włączone.
- Wtyczka bez pliku rozszerzenia MCP nie jest pokazywana na liście i nie jest wyłączana przez te ustawienia.
- Jeśli wtyczka później zyska integrację MCP, jej checkbox jest domyślnie włączony, chyba że wtyczka była wcześniej wyłączona.
- Nieznane lub usunięte identyfikatory wtyczek w zapisanych listach wyłączonych są ignorowane.
- Wcześniej zapisana flaga auto-load rozszerzeń jest ignorowana: ładowanie rozszerzeń zależy od Enable MCP.
- Wcześniej zapisany poziom logowania jest ignorowany i usuwany przy zapisie ustawień.
- Przy włączonym trybie Read-only narzędzia zapisu pozostają w `tools/list` (jeśli użytkownik ma uprawnienia), ale zwracają błąd przy wywołaniu; operacje odczytu narzędzi łączonych nadal działają.

## Obsługa błędów

- Błędy ustawień nie mogą blokować startu Redmine.
- Błędy logowania nie wpływają na przetwarzanie żądań MCP.

## Scenariusze testowe

1. MCP wyłączone — żądania do `/mcp` zwracają HTTP 503.
2. MCP włączone — żądania są przetwarzane.
3. Wtyczka z odznaczoną integracją MCP — jej narzędzia są nieobecne po restarcie.
4. Strona ustawień nie ma pola poziomu logowania; komunikaty MCP są zapisywane do logu Rails.
5. Strona ustawień pokazuje nazwy tylko zainstalowanych wtyczek z integracją MCP; każda ma checkbox.
6. Wtyczka bez integracji MCP nie jest pokazywana na stronie ustawień.
7. Gdy MCP jest wyłączone, rozszerzenia z innych wtyczek nie są ładowane przy starcie.
