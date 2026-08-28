# Autenticazione e autorizzazione

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Panoramica

L'accesso a MCP utilizza l'autenticazione standard tramite chiave API di Redmine. Tutte le operazioni vengono eseguite per conto dell'utente proprietario della chiave.

## Obiettivo

Garantire che MCP non aggirino la sicurezza di Redmine e che gli utenti possano eseguire solo le azioni a loro consentite.

## Aree interessate

- Permessi
- API
- Utenti

## Regole di business

### Autenticazione

- L'API REST di Redmine deve essere abilitata per accedere a `/mcp`.
- La chiave API viene passata nell'header `X-Redmine-API-Key` (non dal corpo della richiesta JSON né dalla query string).
- Sono accettate solo le chiavi di utenti attivi.
- Le richieste senza chiave o con chiave non valida vengono rifiutate.

### Permesso MCP globale

- L'utente deve avere il permesso globale **Use MCP** (`use_mcp`), oppure essere un amministratore Redmine.
- Il permesso `use_mcp` viene abilitato manualmente per i ruoli necessari in **Amministrazione → Ruoli e permessi**.
- Gli amministratori hanno sempre accesso a MCP: il controllo standard dei permessi globali di Redmine consente l'accesso agli admin indipendentemente dai ruoli.
- Per gli altri utenti senza `use_mcp`, la richiesta viene rifiutata anche con una chiave API valida.

### Permessi degli strumenti

- Ogni strumento ha il proprio requisito di permesso Redmine.
- Uno strumento compare in `tools/list` solo se l'utente ha il permesso per usarlo.
- I permessi vengono verificati nuovamente quando lo strumento viene chiamato.
- I dati vengono filtrati secondo le regole di visibilità di Redmine (progetti, issue, membri).

### Permessi di risorse e prompt

- Risorse e prompt possono avere requisiti di permesso propri.
- Senza permesso, una risorsa o un prompt non viene elencato e non può essere letto.
- I controlli dei permessi di risorse e prompt considerano l'URI e gli argomenti di input (inclusi `project` / `project_id`). Se il progetto non è specificato negli argomenti, è sufficiente il permesso in almeno un progetto visibile.
- Un'estensione può definire una regola esplicita per risolvere il progetto dall'URI e dagli argomenti.

## Casi limite

- Un utente inattivo non può usare MCP nemmeno con una chiave precedentemente emessa.
- Un amministratore ha accesso a MCP senza un'assegnazione separata di `use_mcp`.
- Uno strumento con controlli di permesso legati all'entità (ad esempio, un'issue) può essere visibile in `tools/list` con argomenti vuoti se l'utente ha il permesso corrispondente in almeno un progetto.
- Se tale strumento richiede anche un modulo di progetto Redmine, "almeno un progetto" significa un progetto visibile in cui l'utente ha il permesso e il modulo specificato è abilitato. Senza requisito di modulo, è sufficiente il permesso in almeno un progetto visibile. La presenza in `tools/list` non implica il permesso per una issue specifica: permessi e disponibilità dell'oggetto vengono verificati nuovamente alla chiamata.

## Gestione degli errori

| Situazione | Risultato |
|----------|-----------|
| API REST disabilitata | HTTP 401 |
| Chiave API non valida o mancante | HTTP 401 |
| Nessun permesso Use MCP | HTTP 403 |
| Nessun permesso per uno strumento specifico | Strumento assente da `tools/list`; chiamata diretta — errore "Permission denied" |
| Entità non disponibile per l'utente | Risposta dello strumento con una descrizione dell'errore (ad esempio, "Issue not found") |

## Scenari di test

1. Richiesta con chiave valida e permesso Use MCP — accesso riuscito.
2. Richiesta senza header della chiave API — HTTP 401.
3. Richiesta con chiave non admin senza permesso Use MCP — HTTP 403.
4. Chiave amministratore senza un ruolo con `use_mcp` — accesso riuscito.
5. L'utente vede in `tools/list` solo gli strumenti per cui ha il permesso.
6. La chiamata di uno strumento per un'issue inaccessibile restituisce un errore, non i dati di un altro utente.
7. Uno strumento legato alle issue con requisito di modulo di progetto non è visibile in `tools/list` se l'utente ha il permesso ma nessun progetto visibile con il modulo abilitato; è visibile se esiste un tale progetto.
