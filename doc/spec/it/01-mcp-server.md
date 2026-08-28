# Server MCP ed endpoint HTTP

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Panoramica

Redmine MCP fornisce un endpoint HTTP `/mcp` che implementa MCP (Model Context Protocol) in modalità Streamable HTTP senza persistenza di sessione tra le richieste (stateless).

## Obiettivo

Consentire ai client AI esterni di interagire con Redmine utilizzando il protocollo MCP standard senza un processo server separato.

## Aree interessate

- API
- Plugin

## Regole di business

- L'endpoint è disponibile su `/mcp` relativo alla radice di Redmine.
- I metodi HTTP `GET`, `POST` e `DELETE` sono supportati secondo la specifica Streamable HTTP.
- Ogni richiesta viene gestita nel contesto dell'utente autenticato corrente.
- Per ogni richiesta viene costruito un insieme aggiornato di strumenti, risorse e prompt in base ai permessi dell'utente.
- Il server annuncia il nome `redmine_mcp` e una versione corrispondente alla versione del plugin.
- MCP Protocol Revision è `2025-11-25` (header `MCP-Protocol-Version` e `protocolVersion` in `initialize`).
- Sono supportati i metodi MCP standard: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` e altri previsti dalla versione del protocollo supportata.
- Le risposte degli strumenti restituiscono un envelope JSON in `structuredContent` (`ok`, `data` o `error`) e una breve rappresentazione testuale in `content` (stringa JSON in caso di successo, messaggio di errore in caso di fallimento).
- La chiave API è accettata solo dall'header `X-Redmine-API-Key`. Il corpo JSON-RPC non viene usato per l'autenticazione e non viene analizzato prima del controllo della dimensione della richiesta.
- La dimensione del corpo HTTP è limitata prima del parsing JSON: quando il limite viene superato, la richiesta viene rifiutata e il trasporto MCP non legge il corpo.

## Casi limite

- Quando MCP è disabilitato, l'endpoint restituisce HTTP 503 e non elabora le richieste MCP.
- In modalità stateless, le richieste `GET` per uno stream SSE autonomo non sono supportate (HTTP 405) — questo è il comportamento previsto.
- Quando si opera dietro un load balancer, le sessioni sticky non sono necessarie.
- L'elenco degli strumenti può differire tra utenti a seconda dei permessi.

## Gestione degli errori

- Richiesta JSON-RPC non valida — risposta di errore del protocollo MCP.
- Errore interno nell'elaborazione della richiesta — HTTP 500 con un messaggio di errore.
- Errore di esecuzione dello strumento — risposta MCP con `isError: true` e una descrizione testuale.
- REST in-process (`InternalRequest`): 404 → `NOT_FOUND`; conflitto di versione → `CONFLICT`; 401/403 senza conflitto → `FORBIDDEN`; array `errors` → `VALIDATION_ERROR`. L'envelope non include lo stato HTTP della richiesta interna né un messaggio di eccezione grezzo.
- Argomenti dello strumento non validi (campi obbligatori mancanti, tipo errato, proprietà extra quando `additionalProperties: false`, fuori dall'intervallo min/max) — errore di esecuzione con `VALIDATION_ERROR` in `structuredContent`. Il testo in `content` corrisponde a `error.message` e non contiene messaggi JSON Schema grezzi.

## Scenari di test

1. `POST /mcp` con metodo `initialize` restituisce capabilities, `serverInfo` e `protocolVersion` `2025-11-25`.
2. `POST /mcp` con metodo `tools/list` restituisce l'elenco degli strumenti dell'utente corrente.
3. `POST /mcp` con metodo `tools/call` e un nome di strumento valido restituisce un risultato con `structuredContent`.
4. Una richiesta a `/mcp` quando MCP è disabilitato restituisce HTTP 503.
5. La chiamata di uno strumento inesistente restituisce un errore "Tool not found".
6. `tools/call` senza permesso per lo strumento restituisce un errore di esecuzione con un codice di accesso negato; la chiamata viene conteggiata nel rate limit e nell'audit strutturato.
7. Un corpo HTTP più grande del limite viene rifiutato prima del parsing JSON.
8. Uno strumento di scrittura con modalità read-only abilitata restituisce un errore tramite lo stesso percorso HTTP/`tools/call`.
9. `resources/read` con un URI per un progetto inaccessibile non restituisce il contenuto della risorsa.
10. `prompts/get` con un argomento progetto inaccessibile nega l'accesso.
11. `tools/call` con argomenti vuoti, un campo extra o un tipo di argomento errato restituisce `isError: true` e `structuredContent.error.code` `VALIDATION_ERROR`.
