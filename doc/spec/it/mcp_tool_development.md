# Requisiti per lo sviluppo di strumenti Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Stato:** guida per sviluppatori (dev-guide), non una SPEC comportamentale del plugin  
**Versione:** 1.6  
**Data:** 2026-08-20  
**Applicabilità:** tutti i nuovi strumenti Redmine MCP e cambiamenti sostanziali agli strumenti esistenti  
**Versione MCP di base:** Protocol Revision `2025-11-25`

I contratti comportamentali degli strumenti core sono in `03-core-tools.md` e nelle SPEC correlate. Questo documento definisce le regole per progettare e implementare gli strumenti.

---

## 1. Obiettivo di questo documento

Questo documento stabilisce requisiti unificati per progettare, implementare, descrivere, testare e pubblicare strumenti MCP per Redmine. I pattern di implementazione architetturale sono raccolti nell'appendice A e non sono mescolati con i requisiti obbligatori del testo principale.

L'obiettivo di questo standard è che gli strumenti siano:

- inequivocabili per la selezione da parte dei modelli di linguaggio;
- sicuri quando invocati automaticamente;
- prevedibili per i client MCP;
- rigorosamente validati;
- facili da mantenere e retrocompatibili;
- resilienti a chiamate ripetute, errori del modello e argomenti parzialmente compilati.

I requisiti sono formulati tenendo conto di un audit del Redmine MCP attuale. Al momento della preparazione di questo documento, il server pubblica 46 strumenti; il contratto ha rivelato parametri senza `type`, liste di stringhe di valori consentiti invece di `enum`, strumenti universali `manage_*` e assenza di `outputSchema`.

---

## 2. Terminologia delle obbligazioni

In questo documento si usano i seguenti livelli:

- **MUST / DEVE** — requisito obbligatorio. La violazione blocca la merge.
- **MUST NOT / VIETATO** — divieto obbligatorio.
- **SHOULD / DOVREBBE** — requisito predefinito; lo scostamento deve essere giustificato nella merge request.
- **MAY / PUÒ** — opzione accettabile.

I pattern architetturali e di implementazione che non sono obbligatori per ogni strumento sono raccolti nell'**appendice A**. Non bloccano la merge se non vengono adottati consapevolmente per uno strumento specifico.

---

## 3. Principi di progettazione di base

### 3.1. Uno strumento — un'azione chiara

Uno strumento DEVE rappresentare un'intenzione atomica dell'utente.

Buono:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Cattivo:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Gli strumenti con un parametro come `action: create | update | delete | list` sono VIETATI se le operazioni:

- richiedono argomenti obbligatori diversi;
- hanno livelli di rischio diversi;
- dovrebbero avere annotazioni MCP diverse;
- restituiscono strutture dati diverse;
- richiedono permessi Redmine diversi.

È consentita un'eccezione solo per un'operazione semanticamente omogenea in cui tutte le varianti hanno lo stesso rischio e un singolo contratto. L'eccezione deve essere esplicitamente giustificata.

### 3.2. Lettura, aggiunta, aggiornamento ed eliminazione sono separati

In uno strumento è VIETATO combinare:

- operazioni di sola lettura e di scrittura;
- operazioni di aggiunta e di eliminazione;
- operazioni utente ordinarie e amministrative;
- operazioni locali di Redmine e invio di dati all'esterno.

Ad esempio, `list/create/delete relation` devono essere tre strumenti separati.

### 3.3. Il contratto conta più della comodità di implementazione del server

Non pubblicare direttamente la struttura di un metodo interno Ruby/Python/REST solo perché è più facile implementare l'handler in quel modo.

Il contratto MCP è progettato per il modello e il client; un adattatore nel server lo converte nel formato API di Redmine.

I valori tecnici interni di un plugin o di Redmine DEVONO essere normalizzati se non fanno parte di un contratto esterno significativo.

Non pubblicare senza necessità:

- nomi di classi Ruby/Rails e tipi STI;
- nomi enum interni se MCP usa già un altro valore in input;
- date dipendenti dal locale;
- rappresentazioni REST dello stesso campo se MCP definisce già un formato canonico;
- nomi tecnici quando MCP usa già un valore normalizzato.

Esempio: filtro di input `type` — `contact` / `company`; nella risposta anche `contact` / `company`, non `Clientdesk::Contact` / `Clientdesk::Company`. Se un serializzatore restituisce una classe STI o una data localizzata, l'adattatore MCP DEVE portare il valore allo schema pubblicato.

### 3.4. Il server non si fida del modello

Tutti gli argomenti sono considerati non attendibili. Il server DEVE ricontrollare:

- tipi;
- intervalli;
- interdipendenze dei campi;
- diritti dell'utente attuale;
- appartenenza dell'oggetto a un progetto;
- disponibilità di un valore in un workflow specifico;
- vincoli di Redmine;
- se l'operazione è consentita nello stato attuale dell'oggetto.

JSON Schema, descrizioni, annotazioni e conferme del client non sostituiscono la validazione lato server.

---

## 4. Denominazione degli strumenti

### 4.1. Formato del nome

Tutti i nomi degli strumenti pubblicati DEVONO iniziare con `redmine_`.

Per gli strumenti core del plugin `redmine_mcp`, si usa il prefisso breve `redmine_`:

```text
redmine_<verb>_<entity>
```

Per gli strumenti di plugin di terze parti, il nome completo DEVE iniziare con `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Requisiti:

- solo `lower_snake_case`;
- il prefisso `redmine_` è obbligatorio per tutti gli strumenti, incluse le estensioni di plugin di terze parti;
- il nome è univoco all'interno del server;
- limite interno — non più di 64 caratteri;
- il nome non cambia senza una procedura di deprecazione.

Esempi:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Verbi consentiti

Verbi preferiti:

| Verbo | Scopo |
|---|---|
| `get` | recuperare un oggetto per identificatore esatto |
| `list` | recuperare una raccolta tramite filtri strutturati |
| `search` | eseguire ricerca testuale o full-text |
| `create` | creare un oggetto |
| `update` | modificare un oggetto esistente |
| `set` | impostare un campo o flag specifico a un valore dato |
| `delete` | eliminare un oggetto |
| `add` | aggiungere una relazione o un membro a un oggetto esistente |
| `remove` | rimuovere una relazione senza eliminare l'oggetto principale |
| `copy` | creare una copia |
| `upload` | caricare un file |
| `download` | recuperare il contenuto di un file |
| `send` | inviare un messaggio o dati a un destinatario esterno |
| `summarize` | costruire un report aggregato lato server |

Non usare verbi vaghi (`manage`, `process`, `handle`, `execute`, `do`) — vedi §3.1.

Il verbo DEVE corrispondere alla semantica reale dell'operazione. Se uno strumento attiva un flag booleano (parametro come `enabled: true | false`), DOVREBBE essere nominato con `set`, non con un verbo che implica un solo valore.

Cattivo:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` implica solo `enabled = true`, sebbene il parametro consenta anche `false`. Il nome non corrisponde all'azione reale.

Buono:

```text
redmine_advanced_search_set_semantic_index_enabled
```

Il nome `set_*` riflette onestamente che l'operazione imposta un flag al valore passato.

### 4.3. Nomi dei parametri identificatore

Un nome di parametro DEVE corrispondere al suo tipo reale:

- `issue_id` — solo ID intero;
- `project_id` — solo ID intero;
- `project_identifier` — identificatore stringa Redmine;
- `project` — stringa che consente deliberatamente entrambe le rappresentazioni ed è documentata come riferimento.

Un parametro denominato `*_id` non può accettare un identificatore stringa o il valore `"me"`.

Gli ID numerici DEVONO avere `minimum: 1` e una `description` significativa. Formulazioni come `"Issue id"` senza `minimum` sono VIETATE.

Cattivo:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Buono:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

L'opzione unificata raccomandata per il progetto è il parametro `project`, che accetta ID numerico (come stringa) o identificatore stringa:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

L'array `examples` (§6.15) mostra al modello entrambe le forme di valore consentite e riduce la probabilità di input errato.

### 4.4. Blocco ottimistico: `expected_updated_at`

Un parametro che passa un timestamp noto dell'oggetto per rifiutare una modifica obsoleta DEVE essere denominato `expected_updated_at` in tutti gli strumenti core e nelle estensioni.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Il nome `updated_at` per questo significato è VIETATO: sembra «nuovo orario di modifica», sebbene sia in realtà un valore per l'optimistic locking.

Cattivo (checklist e qualsiasi estensione):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Buono:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Un campo di risposta che riporta l'orario reale di modifica dell'oggetto PUÒ ancora essere denominato `updated_at` / `updated_on` — la confusione sorge solo per il parametro di input per il locking.

Il comportamento normativo in caso di conflitto è nell'appendice A.2.

---

## 5. `title` e `description`

### 5.1. `title`

`title` DEVE essere un nome breve leggibile dall'uomo, non una copia del nome tecnico.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Descrizione dello strumento

`description` DEVE rispondere brevemente alle domande chiave:

1. Cosa fa lo strumento e quale oggetto viene letto o modificato?
2. Cosa non è incluso per impostazione predefinita e come richiederlo?
3. Ci sono effetti collaterali significativi?
4. Quale strumento preliminare chiamare se l'ID o un valore consentito è sconosciuto?

La descrizione DEVE essere breve e facile da leggere. È VIETATO trasformarla in un lungo paragrafo di mezza pagina che elenca tutti i campi e tutte le opzioni include: una descrizione sovraccarica è più difficile da leggere per il modello di una descrizione breve e strutturata.

DOVREBBE scrivere diverse righe brevi o un elenco, non testo continuo. I valori predefiniti e come modificarli sono mostrati in modo compatto.

Esempio buono:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

Esempio cattivo — troppo breve, non spiega il risultato e il comportamento predefinito:

```text
Gets issue.
```

Esempio cattivo — sovraccarico, lungo paragrafo che elenca tutti i campi:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. Riferimenti ad altri strumenti

Quando la descrizione, la descrizione del parametro o le istruzioni del server fanno riferimento a un altro strumento, DEVE essere usato il nome completo registrato da `tools/list`, non un `name` breve senza prefisso.

Cattivo:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Buono:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

I nomi brevi sono ambigui tra i plugin e costringono il modello a indovinare il prefisso. Questo è particolarmente importante per le estensioni: `semantic_search_issues` senza il prefisso `redmine_advanced_search_` è facilmente confuso con uno strumento core inesistente.

### 5.2.2. Descrizione del risultato restituito

La descrizione DEVE spiegare brevemente il risultato dello strumento affinché il modello capisca se una chiamata è sufficiente o se serve uno strumento successivo.

La descrizione del risultato deve indicare:

- se viene restituito un oggetto, una raccolta, un aggregato, una conferma di modifica o un riferimento a risorsa;
- quali dati correlati sono inclusi per impostazione predefinita;
- quali dati voluminosi o sensibili non sono inclusi senza un parametro esplicito;
- se esiste la paginazione e qual è il limite standard;
- se uno strumento di scrittura restituisce l'oggetto aggiornato completo o solo identificatore, URL e orario di modifica;
- se è possibile un successo parziale per un'operazione bulk.

Esempio per lettura:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

Esempio per elenco:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

Esempio per scrittura:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

Sulla relazione tra descrizione e `outputSchema` — vedi §7.1 e §7.1.1. Se un elenco restituisce già un campo, la descrizione NON DEVE inviare il modello a `get_*` solo per quel campo.

### 5.3. La descrizione non sostituisce lo schema

È VIETATO impostare vincoli solo nel testo:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Usare `enum`, `const`, intervalli e schemi condizionali.

Lo stesso vale per i campi mutuamente esclusivi. Se `description` dice "exactly one of `user_id` or `group_id`" ma `required` contiene solo campi comuni — schema e testo divergono. Il vincolo DEVE essere formalizzato in `inputSchema` (§6.12).

### 5.4. Selezione prevedibile

Le descrizioni di strumenti simili devono spiegare esplicitamente la differenza.

Ad esempio:

- `redmine_list_project_members` — membri di un progetto specifico e i loro ruoli;
- `redmine_admin_list_users` — elenco globale degli utenti dell'installazione, richiede diritti amministrativi.

### 5.5. Istruzioni a livello server

Il server PUÒ pubblicare brevi istruzioni generali che spiegano le relazioni tra strumenti e le regole di workflow.

Le istruzioni devono aggiungere contesto non presente nelle descrizioni individuali e fare riferimento agli strumenti con nomi completi (§5.2.1), ad esempio:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

VIETATO:

- ripetere le descrizioni di tutti gli strumenti nelle istruzioni del server;
- inserire lì istruzioni generali sul comportamento del modello non correlate al server;
- scrivere una lunga guida invece di brevi regole di routing;
- usare dichiarazioni di marketing;
- fare riferimento agli strumenti con nomi brevi senza prefisso (`list_projects` invece di `redmine_list_projects`).

### 5.6. Studiare l'API REST Redmine prima dello sviluppo

Prima di creare o modificare sostanzialmente uno strumento, lo sviluppatore DOVREBBE effettuare una ricerca documentale. Non è raccomandato progettare il contratto solo dal codice MCP esistente, dalla memoria dello sviluppatore o da un singolo esempio di richiesta HTTP.

DOVREBBE studiare:

1. Pagina principale dell'API REST Redmine: autenticazione generale, paginazione, `include`, campi personalizzati, file e regole di errore di validazione.
2. Pagina API separata per la risorsa corrispondente, ad es. Issues, Time Entries, Versions, Wiki Pages o Project Memberships.
3. Sezione cronologia modifiche API e modifiche per le versioni Redmine supportate.
4. Versione Redmine effettiva usata da MCP e versione minima supportata.
5. API REST e codice sorgente dei plugin Redmine usati se lo strumento lavora con un'entità o campi di plugin. Prima di pubblicare uno strumento di estensione, DEVE verificare il serializzatore sorgente / servizio / endpoint REST e almeno una risposta reale di successo per ogni forma di risultato (list e get, se entrambi sono pubblicati).
6. Permessi reali, workflow, moduli abilitati, tracker, campi personalizzati e vincoli dell'installazione target.
7. Strumenti MCP già pubblicati per evitare di creare un contratto duplicato o conflittuale.

La pagina principale `https://www.redmine.org/projects/redmine/wiki/rest_api` è il punto di ingresso ma di solito è insufficiente per uno strumento specifico. DOVREBBE andare alla pagina della risorsa corrispondente e verificare operazioni, parametri di query, `include`, campi di richiesta, struttura di risposta, codici di errore e vincoli di versione.

### 5.7. Report di copertura API

Prima di implementare un nuovo strumento, lo sviluppatore DOVREBBE allegare una breve tabella di copertura API alla merge request:

| Campo | Contenuto |
|---|---|
| Risorsa Redmine | Risorsa e link alla pagina API ufficiale |
| Endpoint | Metodo HTTP e percorso |
| Supportato da | Versione minima Redmine |
| Parametri richiesta | Tutti i parametri di richiesta documentati |
| Filtri query | Tutti i filtri documentati e valori speciali |
| Valori include | Dati correlati consentiti |
| Obbligatori/predefiniti | Campi obbligatori e valori predefiniti |
| Risposta | Campi principali e varianti di risposta |
| Errori | Codici HTTP e struttura errori |
| Permessi | Diritti richiesti e particolarità di impersonation |
| Esposizione MCP | Quali parametri sono pubblicati in MCP |
| Intenzionalmente omessi | Quali parametri non sono pubblicati e perché |
| Differenze plugin/versione | Differenze tra plugin e versioni supportate |

Lo scopo della tabella non è necessariamente pubblicare ogni parametro Redmine in MCP. Lo scopo è non dimenticare accidentalmente parametri e prendere decisioni di pubblicazione consapevolmente.

Un parametro Redmine può essere escluso da MCP se:

- è pericoloso o amministrativo;
- duplica uno strumento separato più chiaro;
- è instabile tra le versioni supportate;
- crea uno schema ambiguo;
- non è necessario per gli scenari utente target;
- porta a risposte eccessivamente ampie.

Ogni esclusione sostanziale è registrata in `Intentionally omitted` con una breve giustificazione.

### 5.8. Istruzioni per un agente IA che sviluppa strumenti

Se uno strumento è creato o modificato da un agente IA, le istruzioni di lavoro DOVREBBERO fare riferimento a questo documento: ricerca API (§5.6–5.7), contratto (§3–§8), test (§13), checklist (§14).

Testo raccomandato:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. Requisiti `inputSchema`

### 6.1. Struttura di base

Ogni strumento DEVE avere uno schema JSON valido.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Per uno strumento senza argomenti:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Divieto di proprietà non documentate

Al livello superiore e in tutti gli oggetti annidati:

```json
"additionalProperties": false
```

Un dizionario aperto è consentito solo consapevolmente. In quel caso, lo schema del valore è impostato esplicitamente:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Tipo di ogni parametro

Ogni proprietà DEVE contenere `type`, `$ref` o una composizione `oneOf` / `anyOf` / `allOf`.

VIETATO:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Parametri obbligatori

L'array `required` deve riflettere la chiamata minimamente eseguibile.

Se l'operazione è impossibile senza un parametro, il parametro DEVE essere in `required`.

Ad esempio, il caricamento file richiede almeno:

```json
"required": ["project", "filename", "content_base64"]
```

Il controllo `confirm=true` per l'eliminazione è eseguito sul server (§3.4), anche se il campo è in `required`.

### 6.5. Enumerazioni

Per un insieme finito di valori, DEVE usare `enum` o `const` (non solo testo nella descrizione — vedi §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Stringhe

Le stringhe devono avere vincoli appropriati:

- `minLength` per valori non vuoti;
- `maxLength` secondo i vincoli Redmine o limiti interni;
- `pattern` quando il formato è strettamente definito;
- `format` quando si applica un formato standard.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

Il vincolo `format` nello schema non sostituisce la validazione lato server (§3.4).

### 6.7. Numeri

Per i parametri numerici, DEVONO essere impostati limiti ragionevoli.

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

Il valore `default` fa parte del contratto e della documentazione. Il server non deve presumere che il client sostituisca il default da solo.

### 6.8. Array

Ogni array DEVE avere `items`.

Quando necessario, impostare:

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

Un array come `entries: array` senza schema degli elementi è VIETATO.

### 6.9. Oggetti annidati

Tutti gli oggetti annidati sono descritti completamente.

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

### 6.10. Non accettare "oggetto o stringa JSON"

È VIETATO descrivere un parametro come "object or JSON string".

MCP passa già JSON strutturato. Lo strumento deve accettare un oggetto, non una stringa che il server poi analizza di nuovo.

### 6.11. `fields` e `extra_fields` universali

I parametri `fields`, `extra_fields`, `payload`, `data` e oggetti aperti simili sono VIETATI per le operazioni di business principali.

I campi delle issue devono essere elencati esplicitamente con `description` significativa (§6.14) e, dove utile, `examples` (§6.15):

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

I campi raramente usati possono essere passati tramite `custom_fields` strettamente descritto.

### 6.12. Campi interdipendenti

Preferire la divisione degli strumenti. Se la divisione è impossibile, la dipendenza è formalizzata tramite:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` con rami mutuamente esclusivi.

Il testo in `description` ("exactly one of …") non sostituisce lo schema (§5.3).

Caso tipico — "exactly one of two fields". Cattivo: `required` elenca solo campi comuni, XOR resta in prosa:

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

Tale schema consente una chiamata senza `user_id`/`group_id` e una chiamata con entrambi i campi contemporaneamente.

Buono — `required` comune più `oneOf` di livello superiore:

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

La validazione lato server (§3.4) DEVE comunque rifiutare entrambe le varianti errate. Lo schema serve affinché client e modello vedano il vincolo prima della chiamata.

Deve verificare la compatibilità delle costrutti scelti con i client MCP e SDK supportati.

### 6.13. Campi con valore `null` e cancellazione valori

`null` è consentito solo quando ha un significato documentato separato, ad es. "cancellare due date" o "rimuovere assegnazione".

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

Non usare stringa vuota come equivalente implicito di `null`.

Per gli strumenti `set_*` che impostano un campo opzionale (due date, assegnatario, ecc.), il contratto DEVE decidere esplicitamente la cancellazione. Sono consentite tre opzioni — in ordine di preferenza:

1. **Lo stesso strumento accetta `null`** (preferito), come sopra: un'intenzione "imposta o cancella".
2. **Strumento separato clear/unassign**, se API o UX separano meglio le operazioni, ad es. `redmine_advanced_search_clear_saved_query` e `redmine_advanced_search_unassign_search_owner`.
3. **Rifiuto esplicito**: se la cancellazione via MCP non è supportata, questo DEVE essere indicato nella `description` dello strumento e/o nella descrizione del parametro. Contratto silenzioso "solo stringa/intero senza null" senza spiegazione è VIETATO — il modello penserà erroneamente che la cancellazione sia impossibile o proverà a passare `""` / `0`.

Cattivo — può impostare due date, non può cancellare, e da nessuna parte indicato:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Descrizioni dei parametri

Ogni parametro in `inputSchema.properties` DEVE avere una `description` significativa. Parametri senza `description` sono VIETATI, incluse le estensioni (elemento checklist `done`, `sort_order`, `due_date`, campi ID, ecc.) e campi opzionali con `enum` chiaro.

Descrizioni come "Filter by tracker ID", "Tracker id" o "Issue id" sono insufficienti: non suggeriscono dove ottenere un valore consentito e quali vincoli esistono.

La descrizione di un parametro identificatore DEVE indicare quale strumento o campo di risposta usare per i valori consentiti (nome completo — §5.2.1; discovery — §6.16), e notare vincoli significativi (workflow, permessi, appartenenza al progetto).

Cattivo:

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

Buono:

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

Buono, con vincolo indicato:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

La descrizione del parametro non sostituisce lo schema (§5.3) e la validazione lato server (§3.4).

### 6.15. Esempi di valore (`examples`)

Per i parametri in cui il formato del valore non è ovvio o consente più rappresentazioni, DOVREBBE aggiungere `examples` — chiave array standard JSON Schema. Gli esempi aiutano il modello a inserire un valore corretto e sono particolarmente utili per parametri di riferimento, identificatori, date e stringhe simili a enum.

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

Requisiti:

- i valori `examples` DEVONO essere validi rispetto allo schema del parametro stesso;
- `examples` illustrano il formato ma non sostituiscono `enum`, intervalli e altri vincoli (§5.3, §6.5);
- per i parametri con `enum`, `examples` separati sono di solito ridondanti.

Se un client MCP o SDK non supporta `examples` nello schema, PUÒ essere usato `x-examples` come chiave di estensione con la stessa semantica.

### 6.16. Percorso di discovery per parametri ID

Un parametro della forma `*_id` che il modello non può indovinare DEVE avere un percorso di discovery esplicito: uno strumento read/list separato o un campo nella risposta di un altro strumento read referenziato nella `description` del parametro (§6.14).

Opzioni consentite (in ordine di preferenza per un insieme di strumenti):

1. **Strumento list/discovery separato** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Opzioni nella risposta get/list** — ad es. array provider con `id` e `name` nella risposta di `redmine_advanced_search_semantic_search_issues`. Allora la descrizione DEVE fare riferimento a quel campo di risposta con il nome completo dello strumento.
3. **`enum` stabile nello schema**, se l'insieme di valori è fisso e piccolo.

VIETATO pubblicare uno strumento di scrittura con `status_id` / `role_ids` / simili se nessuna delle opzioni sopra è soddisfatta: il modello è costretto a indovinare gli ID.

Cattivo — scrittura senza discovery:

- esiste `redmine_advanced_search_set_search_provider` con `provider_id`;
- non esiste `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` restituisce solo il nome del provider corrente (`provider: "…"`), senza elenco dei valori consentiti e relativi `id`.

In quel caso una descrizione come `"Search provider ID."` è insufficiente. Aggiungere uno strumento list, oppure includere le opzioni provider nella risposta get e scrivere, ad esempio:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

La regola si applica a core ed estensioni (§18).

---

## 7. Requisiti `outputSchema` e risultato

### 7.1. Schema di output

Un nuovo strumento DEVE pubblicare `outputSchema`. Lo schema descrive un contratto di risposta pubblico stabile, non solo la forma dell'envelope `{ ok, data | error }`.

Se `description` afferma che lo strumento restituisce campi nominati o struttura annidata, `outputSchema` DEVE formalizzare quei campi, non limitarsi a `data` / `items` di livello superiore come "oggetto arbitrario".

Cattivo: la descrizione elenca `query`, `results`, snippet e estratti di allegati, ma `outputSchema` manca o descrive `items` solo come `{ "type": "object", "additionalProperties": true }`.

Per ogni campo di risultato stabile:

- il tipo DEVE essere specificato;
- un campo garantito DEVE essere in `required`;
- un insieme finito di valori DEVE essere impostato tramite `enum` o `const`;
- una data DEVE avere `format: date` o `date-time` se il server garantisce il formato corrispondente;
- un ID numerico DEVE mantenere un tipo unificato;
- nullable e optional sono contratti diversi: se un campo è sempre restituito ma può non avere valore, deve essere `required` e consentire `null`;
- per valori di business numerici, le unità DEVONO essere specificate se non ovvie dal nome del campo;
- un valore monetario DEVE avere semantica non ambigua: unità major/minor e come è determinata la valuta.

`additionalProperties: true` NON DEVE essere usato al posto della descrizione di campi di risultato stabili noti. È consentito per compatibilità retroattiva o strutture veramente estensibili, ma i campi di business noti all'interno di tale oggetto devono comunque essere elencati in `properties`, e quelli garantiti in `required`.

Per gli strumenti list, gli elementi `items` DEVONO descrivere almeno i campi necessari al modello per identificazione, filtraggio e chiamate a strumenti successivi.

Buono — frammento di tipizzazione `data` (envelope successo/errore completo — §7.2 e §12):

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

Il risultato DOVREBBE restituire:

- `structuredContent` — oggetto leggibile dalla macchina se i client necessitano struttura stabile;
- `content` testuale — rappresentazione breve per compatibilità retroattiva e umani.

### 7.1.1. Coerenza del contratto pubblico

Prima di completare uno strumento, lo sviluppatore DEVE confrontare tre rappresentazioni:

1. risposta effettiva handler / REST / servizio;
2. `description` dello strumento;
3. `outputSchema`.

Non devono contraddirsi.

Se la descrizione dice che un campo è sempre restituito, deve essere `required` in `outputSchema`.

Se lo schema imposta `enum` / `const` / `format`, il serializzatore effettivo DEVE normalizzare il valore a quel contratto. Non si può pubblicare `format: date` e contemporaneamente promettere stringa formattata per locale.

Se un elenco restituisce già dati, la descrizione NON DEVE inviare il modello a uno strumento get solo per gli stessi dati.

Gli invarianti di business del risultato DEVONO essere riflessi nello schema tramite `const`, `enum`, `required` o schema condizionale, non solo dedotti dal nome dello strumento. Esempio: se uno strumento di sottoscrizione per definizione restituisce solo prodotti di tipo `subscription`, `product_type` deve essere `const: "subscription"`, non `enum` con valori impossibili.

### 7.2. Envelope unificato

Risultato di successo raccomandato:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Errore:

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

In caso di errore, impostare inoltre:

```json
"isError": true
```

Se `outputSchema` è pubblicato e l'errore è restituito anche in `structuredContent`, lo schema DEVE descrivere entrambi i rami — successo ed errore. Non si può pubblicare uno schema solo di successo e restituire un oggetto errore strutturato incompatibile. Alternativa: in caso di errore di esecuzione dello strumento restituire solo `content` testuale con `isError: true` e non restituire `structuredContent`. Opzione preferita — envelope tipizzato unificato con due rami.

### 7.3. Stabilità dei campi

I campi di output sono un contratto pubblico. VIETATO:

- cambiare il tipo di campo senza un cambiamento major;
- rinominare un campo senza periodo di deprecazione;
- restituire a volte oggetto, a volte array;
- restituire ID a volte come numero, a volte come stringa;
- restituire risposta API Redmine non elaborata illimitata.

### 7.4. Risultato oggetto singolo

Formato raccomandato:

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

### 7.5. Risultato elenco

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

Lo schema degli elementi `items` segue §7.1: identificatori, campi di routing e campi di business stabili sono descritti esplicitamente. `{ "type": "object", "additionalProperties": true }` come unica descrizione dell'elemento è VIETATO.

### 7.6. Volume minimamente necessario

Gli strumenti list/search devono per impostazione predefinita restituire record brevi. Descrizione completa, journal, allegati e campi di testo grandi devono essere ottenuti tramite `get_*` separato.

Questo riduce token, latenza e rischio di passare dati sensibili in eccesso.

### 7.7. Dati sensibili

Il risultato non deve contenere senza necessità esplicita:

- token API;
- header Authorization;
- cookie;
- percorsi filesystem del server;
- stack trace interni;
- password e segreti;
- campi Redmine non disponibili all'utente corrente;
- note private senza permesso separato.

---

## 8. Annotazioni MCP

Le annotazioni sono suggerimenti per il client e non sono un meccanismo di autorizzazione o protezione.

### 8.1. Matrice dei valori

| Tipo operazione | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Get/find/list dati Redmine | `true` | `false` | `true` | `false` |
| Creare issue/versione/checklist | `false` | `false` | `false` | `false` |
| Aggiungere commento/osservatore/relazione | `false` | `false` | `false` | `false` |
| Modificare campo, rinominare, impostare flag (`update`, `rename`, `set`) | `false` | `false` | dipende dall'implementazione | `false` |
| Eliminare, cancellare, resettare (`delete`, `purge`, `reset`) | `false` | `true` | solo con idempotenza garantita | `false` |
| Inviare email a destinatario esterno | `false` | `false` | `false` | `true` |
| Accedere a URL arbitrario / sistema esterno | dipende | dipende | dipende | `true` |

### 8.2. Regole

- `readOnlyHint: true` solo se lo strumento non cambia stato e non causa effetti collaterali.
- `destructiveHint` descrive perdita irreversibile o distruzione di dati, non il fatto di scrivere. `destructiveHint: true` DOVREBBE essere impostato solo per operazioni irreversibili — `delete`, `purge`, `reset`, cancellazione completa di campo o relazione.
- `update`, `rename` e `set` ordinari NON sono distruttivi: per essi `destructiveHint: false`. Ad esempio, `update_checklist_title` o `rename_wiki_page` è un update ordinario, non distruzione, e l'annotazione destructive è errata per essi.
- `idempotentHint: true` solo se la chiamata ripetuta è veramente sicura; DOVREBBE confermare con un test.
- `openWorldHint` descrive se lo strumento accede a un mondo esterno aperto e precedentemente sconosciuto, non se viene creato un nuovo oggetto. Il lavoro con un'installazione Redmine configurata è un mondo chiuso: `openWorldHint: false`.
- Pertanto `create_issue`, `create_time_entry` e altri strumenti di scrittura nella propria Redmine usano `openWorldHint: false`, nonostante creino nuovi oggetti. Creare un oggetto in un sistema noto non rende il mondo aperto.
- `openWorldHint: true` solo quando destinatario o fonte dati non è limitata al sistema noto: invio email a destinatario esterno, richiesta HTTP arbitraria, accesso a servizio esterno.
- Il valore `openWorldHint` DOVREBBE essere impostato consapevolmente per ogni strumento, non copiato per impostazione predefinita: verificare se lo strumento va effettivamente oltre la propria installazione Redmine.
- Non si può copiare un insieme di annotazioni su tutti gli strumenti di scrittura.

### 8.3. Effetti collaterali Redmine

Nel valutare l'idempotenza, considerare non solo i campi finali ma anche:

- creazione voci journal;
- invio notifiche;
- webhook;
- log di audit;
- caricamento file ripetuto;
- creazione relazione ripetuta;
- registrazione voci di tempo ripetuta.

Se una chiamata ripetuta crea un record o notifica aggiuntivo, lo strumento non è idempotente.

---

## 9. Sicurezza

### 9.1. Autorizzazione

Ogni chiamata DEVE essere eseguita nel contesto di un utente autenticato o di un service account esplicitamente documentato.

Il server DEVE verificare i permessi Redmine per il progetto e l'oggetto specifici. La presenza dello strumento in `tools/list` non significa permesso per l'operazione.

Gli strumenti amministrativi dovrebbero:

- essere pubblicati solo agli amministratori;
- oppure essere spostati in un profilo/server MCP amministrativo separato;
- oppure essere protetti da uno scope separato.

### 9.2. Diritti minimi

Il server MCP e il token API Redmine devono avere diritti minimamente necessari. Non si può usare un token amministrativo globale per tutti gli utenti se deve essere preservato il modello di accesso utente.

### 9.3. Percorsi filesystem arbitrari vietati

Parametri come:

```json
{"file_path": "/etc/app/.env"}
```

sono VIETATI negli strumenti MCP pubblici.

Opzioni sicure:

1. `content_base64` con limite di dimensione;
2. `upload_token` opaco emesso da meccanismo di upload attendibile;
3. URI risorsa MCP dove l'accesso è verificato dall'host;
4. file solo da directory temporanea dedicata con controllo `realpath` e allowlist.

Il server DEVE verificare:

- dimensione massima;
- tipo MIME;
- estensione consentita;
- nome file;
- assenza di path traversal;
- controllo antivirus/contenuto se richiesto dalla policy organizzativa.

### 9.4. URL arbitrari e SSRF

Uno strumento non deve accettare URL arbitrario a meno che non sia il suo scopo principale.

Quando è necessario l'accesso HTTP:

- usare allowlist di dominio e schema;
- vietare loopback, link-local, endpoint metadata e reti interne se non necessari;
- limitare i redirect;
- impostare timeout e limite di risposta;
- non passare credenziali interne a un'altra origine.

### 9.5. Eliminazione e operazioni pericolose

Per operazioni irreversibili, OBBLIGATORIO:

- strumento separato;
- `destructiveHint: true`;
- descrizione esplicita dell'irreversibilità;
- verifica precisa dei permessi lato server;
- log di audit;
- protezione contro eliminazione di oggetto fuori dal progetto previsto;
- verifica di oggetti figli e conseguenze correlate.

Il booleano `confirm_delete: true` PUÒ essere usato come protezione aggiuntiva contro chiamate accidentali, ma non può essere considerato un meccanismo di autorizzazione.

Eliminazione in due fasi, optimistic locking e chiave di idempotenza — vedi appendice A.

### 9.6. Log

Il log di audit registra:

- nome strumento;
- utente autenticato;
- ID progetto/oggetto target;
- esito;
- durata;
- codice errore;
- ID di correlazione richiesta.

VIETATO registrare nei log:

- token di accesso;
- header Authorization;
- cookie;
- contenuto file base64;
- campi personalizzati segreti;
- testo completo di note private senza necessità separata.

### 9.7. Rate limit e timeout

Ogni strumento DEVE avere:

- limite dimensione input;
- rate limit per utente/token;
- limite sul numero di record restituiti;
- limiti operazioni bulk.

Il timeout del server di 60 s si applica agli strumenti di lettura. Gli strumenti di scrittura non sono interrotti dal timeout del server affinché dopo un salvataggio riuscito possa essere registrato il risultato di idempotenza.

---

## 10. Errori

### 10.1. Separazione errori

Si usano due livelli:

1. **Errore di protocollo** — strumento sconosciuto, JSON-RPC corrotto, impossibilità di elaborare la richiesta MCP.
2. **Errore di esecuzione strumento** con `isError: true` — errore argomento, API Redmine, permessi, workflow o logica di business.

Gli errori che il modello può correggere modificando gli argomenti devono essere restituiti come errori di esecuzione strumento.

### 10.2. Struttura errore

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

### 10.3. Codici raccomandati

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

### 10.4. Il messaggio deve essere correggibile

Cattivo:

```text
Invalid request.
```

Buono:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Non restituire stack trace all'utente. Lo stack trace è memorizzato solo nel log server protetto con ID di correlazione.

---

## 11. Paginazione e volume dati

### 11.1. Strumenti list/search

Parametri OBBLIGATORI:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Per l'API Redmine esistente, `offset` è consentito. Per implementazione personalizzata, è preferito un cursore opaco se i dati possono cambiare attivamente durante l'attraversamento.

### 11.2. Metadati paginazione

Il risultato deve contenere:

- `limit` effettivo;
- `offset` o `next_cursor`;
- `has_more`;
- `total_count` se ottenerlo non crea carico significativo.

### 11.3. Selezione campi

Il parametro `fields` è consentito solo come array da allowlist chiusa:

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

Non si possono passare nomi di campo arbitrari direttamente a SQL, `select` ActiveRecord, serializzatore o API Redmine senza allowlist.

### 11.4. Risultati grandi

Journal, allegati e file grandi devono:

- avere paginazione separata;
- essere restituiti da strumento/risorsa separato;
- per dati binari, restituire link risorsa o altro riferimento limitato invece di incorporare base64 grande nella risposta quando possibile;
- oppure supportare esecuzione aumentata da task se l'operazione è veramente lunga e il client la supporta.

`execution.taskSupport` non è impostato automaticamente. Il valore predefinito è `forbidden`.

---

## 12. Riferimento per un nuovo strumento

Esempio abbreviato di strumento di scrittura con `title` obbligatorio e `outputSchema` tipizzato secondo §7.1. Formato errore — §10. JSON completo — nell'appendice B.

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

## 13. Test

### 13.1. Test schema

Per ogni strumento, OBBLIGATORIO:

- almeno una chiamata valida;
- almeno una chiamata negativa (ad es. campo obbligatorio mancante o tipo errato).

DOVREBBE coprire, se applicabile allo schema:

- chiamata valida completa;
- assenza di ogni campo obbligatorio;
- tipo errato dei parametri chiave;
- campo aggiuntivo sconosciuto;
- valore fuori enum;
- valore fuori intervallo;
- data/date-time errata;
- superamento di `maxItems`, `maxLength` e dimensione file;
- violazione interdipendenza campi (entrambi i campi XOR contemporaneamente; nessuno della coppia obbligatoria).

### 13.2. Test permessi

Per operazioni di scrittura, distruttive e lettura sensibile DOVREBBE verificare:

- utente senza accesso al progetto;
- utente con accesso read-only;
- utente con permesso di modifica;
- amministratore se lo strumento tocca scenari admin;
- accesso a note private se lo strumento le restituisce o modifica;
- tentativo di modificare oggetto di un altro progetto tramite ID sostituito.

Per strumenti read-only semplici senza dati sensibili, i test permessi POSSONO essere limitati a uno scenario negativo o omessi con breve giustificazione nella merge request.

### 13.3. Test idempotenza

Per `idempotentHint: true`, DOVREBBE esserci test automatico o manuale di due o più chiamate sequenziali identiche.

Verificare assenza di effetti collaterali dichiarati idempotenti, ad es.:

- voci journal aggiuntive;
- email ripetute;
- duplicati file;
- duplicati relazione;
- voci di tempo ripetute;
- eventi webhook extra se parte della garanzia.

### 13.4. Test contratto

DOVREBBE mantenere `tools/list` come snapshot o altrimenti tracciare cambiamenti breaking del contratto. La CI PUÒ rilevare:

- cambio nome;
- rimozione parametro;
- cambio tipo;
- cambio `required`;
- aumento livello rischio annotazioni;
- scomparsa `outputSchema`;
- cambio incompatibile di campi, tipi, `required`, `enum` / `const`, o rami successo/errore di `outputSchema`.

### 13.5. Test selezione LLM

Per strumenti simili o facilmente confusi DOVREBBE esserci un insieme di richieste utente e chiamate strumento attese. L'esecuzione LLM automatica completa PUÒ essere sostituita da esempi statici nella merge request o revisione descrizione.

Esempi:

| Richiesta | Strumento atteso |
|---|---|
| "Mostra issue 123" | `redmine_get_issue` |
| "Trova issue su OAuth" | `redmine_search_issues` |
| "Aggiungi osservatore 15 all'issue 123" | `redmine_add_issue_watcher` |
| "Elimina relazione tra issue" | `redmine_delete_issue_relation` |
| "Trova issue simili" | `redmine_advanced_search_semantic_search_issues` |

Il test o la revisione fallisce se il modello con alta probabilità sceglie uno strumento distruttivo universale per un'intenzione read-only o è costretto a indovinare valori `action`.

### 13.6. Test recupero errori

DOVREBBE verificare che dopo errori tipici il modello riceva informazioni sufficienti per un retry corretto:

- ID mancante;
- stato non valido;
- conflitto `expected_updated_at`;
- permessi insufficienti;
- limite superato;
- tipo MIME errato.

---

## 14. Checklist code review

Un nuovo strumento non può essere mergiato finché tutti gli elementi obbligatori non ricevono risposta "sì".

### Scopo

- [ ] Un'azione; nessuna operazione mista `action`/`manage` (§3.1–3.2).
- [ ] Operazione amministrativa separata da quella ordinaria.

### Nome e descrizione

- [ ] Il nome inizia con `redmine_`: core — `redmine_<verb>_<entity>`; plugin di terze parti — `redmine_<plugin_id>_…` (§4.1).
- [ ] Descrizione: scopo, effetti collaterali, risultato breve; strumenti simili distinguibili (§5).
- [ ] Riferimenti incrociati ad altri strumenti usano nomi completi da `tools/list` (§5.2.1).

### Ricerca contratto sorgente

- [ ] Per strumento core, API REST della risorsa, versioni e plugin se necessario studiati; report di copertura DOVREBBE essere allegato alla merge request (§5.6–5.7).
- [ ] Per strumento di estensione, serializzatore sorgente / servizio / endpoint REST e almeno una risposta reale di successo per ogni forma di risultato DEVE essere verificato (§18.5).
- [ ] Contratto confrontato con `tools/list` attuale.

### Schema di input

- [ ] Lo schema corrisponde a §6 (`additionalProperties: false`, tipi, `required`, `enum`/`const`, vincoli).
- [ ] Ogni parametro ha `description` significativa (§6.14); `*_id` ha `minimum: 1` (§4.3).
- [ ] Per `*_id` e altri valori di lookup, percorso discovery specificato (§6.16): strumento list, campo risposta get/list, o `enum`.
- [ ] Vincoli "exactly one of …" / interdipendenza formalizzati nello schema, non solo nella descrizione (§5.3, §6.12).
- [ ] Optimistic locking — solo `expected_updated_at`, non `updated_at` (§4.4).
- [ ] Per campi opzionali `set_*`, cancellazione decisa: `null`, strumento clear separato, o rifiuto esplicito (§6.13).
- [ ] Nessun "object or JSON string" e `fields`/`payload` arbitrari.
- [ ] `*_id` — intero; validazione lato server secondo §3.4.

### Output ed errori

- [ ] Il nuovo strumento ha `outputSchema` con envelope successo/errore (§7.1–7.2).
- [ ] Campi di risultato stabili noti descritti in `properties`; `additionalProperties: true` non usato al posto del contratto noto.
- [ ] Tutti i campi garantiti sono in `required`.
- [ ] Campi nullable e optional distinti consapevolmente.
- [ ] `enum`/`const`, `date`/`date-time`, intervalli e altri vincoli noti formalizzati nello schema.
- [ ] Per valori di business monetari e numerici, unità, valuta e unità major/minor sono chiare.
- [ ] Invarianti di business del risultato riflessi nello schema (`const`, `enum`, `required`, o schema condizionale), non solo dedotti dal nome dello strumento.
- [ ] Descrizione, `outputSchema` e risposta effettiva handler/REST/servizio non si contraddicono (§7.1.1).
- [ ] Valori REST/Ruby/plugin interni normalizzati a contratto MCP stabile; nessuna perdita nome STI/classe o formato dipendente da locale (§3.3).
- [ ] Lo strumento list restituisce struttura breve ma sufficiente; la descrizione spiega correttamente quando lo strumento get corrispondente è veramente necessario.
- [ ] Errori: `isError`, codice stabile, messaggio correggibile; nessun segreto o stack trace (§10).

### Annotazioni

- [ ] Le annotazioni corrispondono al rischio (§8); test raccomandato per `idempotentHint: true`.

### Sicurezza

- [ ] Permessi, percorso file, SSRF, limiti, log, distruttivo/audit — secondo §9; pattern appendice A se necessario.

### Test

- [ ] Test schema minimi; il resto per rischio (§13).

---

## 15. Compatibilità e modifica strumenti esistenti

### 15.1. Cambiamenti breaking

Cambiamento breaking:

- rinomina strumento;
- rimozione campo;
- cambio tipo;
- aggiunta nuovo campo obbligatorio;
- cambio significato campo;
- cambio output incompatibile;
- unione di diverse operazioni in una;
- aumento rischio senza aggiornare annotazioni e documentazione.

### 15.2. Migrazione nome

Quando si migra, ad esempio, dal vecchio prefisso `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

al prefisso breve `redmine_`:

```text
redmine_get_issue
```

seguire:

1. aggiungere il nuovo nome;
2. mantenere temporaneamente il vecchio alias;
3. contrassegnare il vecchio strumento come deprecato nella descrizione **o non pubblicarlo in `tools/list`** se l'alias serve solo per `tools/call`;
4. raccogliere metriche delle chiamate al vecchio nome (l'audit log esistente per nome strumento invocato è sufficiente);
5. rimuovere l'alias dopo il periodo concordato (non prima della prossima versione major, salvo periodo concordato separatamente);
6. inviare `notifications/tools/list_changed` se il server dichiara `listChanged`.

Esempi attuali (vedere [03-core-tools.md](03-core-tools.md)): `redmine_list_all_users` → `redmine_admin_list_users`; `redmine_list_files` → `redmine_list_project_files`; `redmine_delete_file` → `redmine_delete_attachment`; `redmine_get_server_info` → `redmine_get_mcp_info`. Un alias è accettato in `tools/call` e non è pubblicato in `tools/list`.

### 15.3. Modifica descrizioni

La descrizione influenza la selezione strumento del modello ed è considerata un cambiamento comportamentale. Su cambiamento sostanziale della descrizione DOVREBBE revisionare gli esempi di selezione LLM o condurre una revisione di selezione ripetuta.

### 15.4. Versione server

La versione del plugin MCP è restituita da `redmine_get_mcp_info` (o metadati server). Non aggiungere `v1`, `v2` a ogni nome senza reale necessità di supportare contratti incompatibili paralleli.

---

## 16. Regole per i problemi attuali di Redmine MCP

Nello sviluppo di nuovi strumenti, è vietato ripetere i pattern dall'audit del contratto attuale. Le regole canoniche sono nelle sezioni corrispondenti; sotto c'è solo una mappa dei problemi:

| Problema audit | Sezione |
|---|---|
| Nomi senza prefisso `redmine_` (inclusi plugin di terze parti) / stile misto in un plugin | §4.1 |
| Verbo non corrisponde alla semantica (`complete_*` con `done=true/false` invece di `set_*`) | §4.2 |
| ID numerico senza `minimum: 1` o con descrizione "Issue id" | §4.3 |
| Optimistic locking come `updated_at` invece di `expected_updated_at` | §4.4, A.2 |
| `manage_*` / `patch_*` universali e parametro `action` | §3.1, §4.2 |
| Parametri senza `type`, enum solo in descrizione, array senza `items` | §5.3, §6 |
| Parametri senza `description`; descrizioni troppo brevi senza riferimento strumento lookup | §6.14 |
| Nessun `examples` su parametri di riferimento e identificatori | §6.15 |
| Strumento di scrittura con `*_id` senza percorso discovery (nessuno strumento list e opzioni in risposta get) | §6.16 |
| Descrizione promette "exactly one of A or B", schema non lo codifica | §5.3, §6.12 |
| Nomi strumento brevi nei riferimenti incrociati (`list_projects` invece di `redmine_list_projects`) | §5.2.1 |
| Descrizione strumento sovraccarica di mezza pagina | §5.2 |
| `fields` / `extra_fields` senza schema; `required` extra | §6.4, §6.11 |
| `set_*` senza modo di cancellare campo e senza rifiuto esplicito | §6.13 |
| Un insieme di annotazioni su tutti gli strumenti di scrittura; eccesso `openWorldHint` | §8 |
| `destructiveHint: true` su `update` / `rename` ordinari; `openWorldHint` errato su `create_*` | §8.1, §8.2 |
| Descrizione promette struttura risposta, ma `outputSchema` manca o descrive solo oggetto arbitrario | §7.1 |
| Descrizione, schema e risposta effettiva si contraddicono | §7.1.1 |
| Nomi STI/classe o date localizzate nella risposta MCP | §3.3 |
| `additionalProperties: true` al posto di campi list/get noti | §7.1 |
| `file_path` arbitrario, bypass scope progetto, SSRF | §9 |
| Effetto email/esterno in uno strumento con modifica locale | §3.2 |
| Coppie ambigue di strumenti simili | §5.4 |

---

## 17. Struttura insieme strumenti

L'elenco completo attuale degli strumenti non è duplicato in questo documento — diventa rapidamente obsoleto.

**Fonte di verità:**

- strumenti core — [03-core-tools.md](03-core-tools.md) e `tools/list` effettivo sull'installazione;
- strumenti plugin di terze parti — §18 e risposta MCP `tools/list` sull'installazione.

**Principi di raggruppamento** (ogni gruppo — strumenti atomici separati secondo §3):

| Gruppo | Intenzioni di esempio | Prefisso |
|---|---|---|
| Issue | get, list, search, create, update, delete, copy, sottotask | `redmine_` |
| Relazioni e osservatori | list/create/delete relazione; add/remove osservatore | `redmine_` |
| Progetti e membri | progetti, moduli, membri, ruoli | `redmine_` |
| Versioni e categorie | versioni; categorie issue | `redmine_` |
| Voci di tempo | list, create, update, import, attività | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| File e allegati | list, upload, delete, download | `redmine_` |
| Admin | utenti, ruoli, info sessione MCP | `redmine_admin_` o `redmine_get_mcp_info` |
| Entità plugin | checklist, search, ecc. | `redmine_` + `plugin_id`, ad es. `redmine_advanced_search_` |

Prima di aggiungere un nuovo strumento DOVREBBE verificare la risposta MCP `tools/list` e il gruppo corrispondente: non duplicare strumento esistente e non mescolare intenzioni diverse in un nome.

Se un gruppo ha strumento di scrittura con parametro ID (`status_id`, `role_ids`, …), lo stesso gruppo DEVE avere percorso discovery (§6.16).

Gli strumenti amministrativi sono pubblicati solo per utenti con diritti richiesti (§9.1).

---

## 18. Estensioni plugin di terze parti

Sezione per autori di plugin Redmine che aggiungono strumenti tramite Extension API. Descrizione tecnica di API, hook e casi limite — in [04-extensions.md](04-extensions.md).

Le estensioni seguono le stesse regole di contratto, sicurezza e denominazione (§3–§10, §4.1) degli strumenti core di `redmine_mcp`.

### 18.1. Cosa pubblicare e quando

| Primitiva | Quando usare |
|---|---|
| **Tool** | Un'azione su entità plugin o Redmine: create, get, update, delete, search |
| **Resource** | Contenuto grande o statico per URI stabile: corpo wiki, file, report lungo |
| **Prompt** | Template scenario ripetibile per utente, non operazione con effetto collaterale |
| **`extend_tool`** | Parametro o hook logicamente parte di uno strumento core esistente (ad es. `include_*` in lettura issue) |

Se il modello può soddisfare l'intenzione con strumento separato senza indovinare `action` — preferire **strumento proprio**, non `extend_tool` che gonfia lo schema di un altro.

### 18.2. Registrazione

- Il file di estensione si carica all'avvio Redmine: `lib/<plugin_id>/mcp.rb` (vedi `ExtensionLoader`).
- Il modulo in `mcp.rb` DEVE essere `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): Zeitwerk deriva il nome dal file.
- Prima della registrazione DOVREBBE verificare `mcp_extension_enabled?` — dipendenza hard da `redmine_mcp` nel gemspec non è richiesta.
- Usare `register_tool_once` per la registrazione affinché il reload non duplichi lo strumento.
- Il nome completo in `tools/list` DEVE iniziare con `redmine_` (§4.1).
- Lo strumento DEVE avere `title`, `description`, `input_schema`, `output_schema`, `permission` e `annotations`; duplicazione nome vietata.
- Lo strumento è visibile nella risposta MCP `tools/list` solo agli utenti con permesso corrispondente.

### 18.3. Denominazione

- Il nome DEVE iniziare con `redmine_`; poi — `plugin_id` e `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verbi e divieto `manage_*` — secondo §4.2 e §3.1.
- Non copiare nomi strumenti core e non pubblicare secondo strumento con stessa intenzione sotto nome diverso.

Prima della registrazione DOVREBBE confrontare con la risposta `tools/list` sull'installazione target.

### 18.4. Permessi e sicurezza

- `permission` DEVE corrispondere ai permessi Redmine o plugin reali, non a un ruolo separato "solo mcp".
- Per operazioni sulle issue DOVREBBE usare `register_issue_tool` e `find_accessible_issue` invece di copiare controlli visibilità e modulo progetto.
- Se `module_name` è impostato, lo strumento DEVE essere in `tools/list` solo quando l'utente ha il permesso dichiarato in almeno un progetto visibile con modulo abilitato. Senza `module_name`, basta il permesso in almeno un progetto visibile. L'handler verifica comunque l'issue specifica, incluso il suo modulo progetto.
- Validazione ripetuta argomenti e permessi lato server nell'handler — secondo §3.4 e §9, anche se lo strumento è nascosto da `tools/list` per altri utenti.

### 18.5. Implementazione pulita

**Livello MCP sottile.** `mcp.rb` dovrebbe contenere principalmente registrazione strumenti: schemi, descrizioni, permessi, annotazioni e handler brevi. L'handler valida argomenti, verifica contesto e delega l'esecuzione a classe/servizio separato.

La logica di business del plugin dovrebbe restare in modelli e servizi ordinari e non dipendere da MCP.

Se la logica serve solo per MCP — ad es. unire dati da più modelli, normalizzare risposta REST al contratto MCP, calcolare campi derivati o preparare risultato strumento — PUÒ spostarla in `mcp_tools.rb` separato. Se tale file diventa grande, DOVREBBE dividerlo in classi per entità o operazione, ad es. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Non inserire logica di business e grandi trasformazioni direttamente in lambda/handler dentro `mcp.rb`.

**Accesso dati.**

- Modelli e servizi plugin — se la logica è già lì.
- `internal_request` / `internal_get` / REST — se serve riusare controller API esistente; l'endpoint deve supportare `accept_api_auth`. Usare `internal_request` per `POST`, `PUT`, `PATCH` e `DELETE`; usare `internal_get` o `internal_request(method: 'GET', ...)` per letture. Verificare errori con `internal_request_error?`.

**`extend_tool` — con moderazione.** Appropriato quando il parametro è parte di un'intenzione con lo strumento core. Inappropriato quando il plugin aggiunge essenzialmente un sottosistema separato: meglio prefisso proprio e strumenti propri, collegamento al core descritto in `description` o istruzioni server.

**Contratto come core.** Input — secondo §6. Output — secondo §7.1 e §7.1.1: campi stabili, `required`, `enum`/`const`, unità, normalizzazione API interna. Annotazioni per rischio, errori correggibili (§8, §10). Optimistic locking — `expected_updated_at` (§4.4). Ogni parametro — `description` (§6.14). Riferimenti incrociati — nomi completi (§5.2.1). Ogni parametro di scrittura `*_id` — percorso discovery (§6.16): `list_*` separato o opzioni con `id` in risposta get/list, e riferimento esplicito nella descrizione del parametro.

Prima di pubblicare strumento di estensione DEVE verificare serializzatore sorgente / servizio / endpoint REST e almeno una risposta reale di successo per ogni forma di risultato.

**Codice condiviso — in `redmine_mcp`.** Nello sviluppo dell'estensione, se un frammento può servire a un altro plugin MCP, DOVREBBE aggiungerlo subito al core `redmine_mcp`, non copiarlo in `lib/<plugin>/mcp*.rb`.

Criterio: la logica non è legata a un dominio plugin (checklist, search, …) e descrive contratto MCP, Extension API o pattern di integrazione tipico.

| Dove | Cosa |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, estensione `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, helper permessi comuni per `issue_id` / `project_id` |
| **Estensione plugin** | `mcp.rb` — registrazione strumenti e handler brevi; `mcp_tools.rb` / `mcp_tools/*.rb` — fetch MCP-specifico, aggregazione, normalizzazione; modelli/servizi ordinari — logica di business non dipendente da MCP |

**Posizionamento raccomandato per estensione:**

- `mcp.rb` — registrazione strumenti e handler brevi;
- `mcp_tools.rb` / `mcp_tools/*.rb` — fetch, aggregazione e normalizzazione dati MCP-specifici;
- modelli/servizi ordinari — logica di business non dipendente da MCP.

Prima di copiare helper da un'altra estensione DOVREBBE verificare se l'analogo esiste già in `redmine_mcp`; se assente — spostare nel core nella stessa PR, non duplicare.

Altro sull'extension API — [04-extensions.md](04-extensions.md) (§ "ExtensionApi helper methods").

### 18.6. Anti-pattern

VIETATO o non raccomandato:

- registrare strumenti a ogni richiesta HTTP;
- fallire su errore plugin vicino all'avvio;
- mescolare read, write e admin in uno strumento;
- duplicare strumento core "con nome diverso";
- estendere altro strumento con parametri opzionali "per il futuro";
- restituire in MCP campi interni non disponibili all'utente nell'UI/API plugin;
- pubblicare nomi classe STI, date localizzate o rappresentazione REST se lo schema MCP definisce contratto diverso (§3.3, §7.1.1);
- descrivere elemento list solo come `{ "type": "object", "additionalProperties": true }` (§7.1);
- pubblicare `set_*_status` / simili con `status_id` senza dare al modello modo di conoscere ID consentiti (§6.16);
- duplicare helper MCP comuni nell'estensione (envelope `outputSchema`, wrapper `internal_request`, permesso issue) se il loro posto è in `redmine_mcp` — vedi §18.5.

### 18.7. Verifica pre-merge

- [ ] Il nome strumento inizia con `redmine_` secondo §4.1 / §18.3.
- [ ] L'estensione si carica all'avvio; lo strumento appare in `tools/list` per utente con diritti.
- [ ] Lo strumento assente per utente senza diritti e quando il flag estensione MCP del plugin è disabilitato.
- [ ] Contratto e checklist (§14) soddisfatti, incluso confronto descrizione / outputSchema / risposta effettiva (§7.1.1); test secondo §13 se necessario.
- [ ] Serializzatore / REST / servizio verificato su almeno una risposta reale di successo per ogni forma di risultato pubblicata (ad es. list e get se entrambi pubblicati).
- [ ] Nessuna duplicazione di strumento esistente in `tools/list`.
- [ ] Per ogni parametro di scrittura `*_id` esiste percorso discovery (§6.16).

---

## 19. Fonti e base normativa

Documento preparato al 2026-07-22 sulla base delle seguenti fonti primarie:

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
    Link `API changes for each version` sulla pagina REST API; verificato per tutte le versioni supportate.

---

## 20. Criterio di prontezza del nuovo strumento

Un nuovo strumento MCP è considerato pronto quando sono soddisfatti gli elementi obbligatori della checklist code review (§14).

Per gli strumenti di plugin di terze parti in aggiunta — checklist §18.7.

Raccomandazioni sul rischio: report di copertura (§5.7), test aggiuntivi §13.2–13.6 e appendice A. Test minimi dello schema (§13.1) e regole `outputSchema` (§7.1, §7.1.1) sono obbligatori.

---

## Appendice A. Pattern di implementazione raccomandati

I pattern seguenti non sono obbligatori per ogni strumento MCP. SI DOVREBBE considerarli per rischio elevato: operazioni distruttive, strumenti amministrativi, scritture massive, effetti collaterali esterni, chiamate ripetute per timeout.

### A.1. Eliminazione in due fasi (prepare / confirm)

Per operazioni amministrative particolarmente pericolose:

1. `redmine_prepare_delete_*` restituisce una breve descrizione delle conseguenze e un token monouso;
2. `redmine_confirm_delete_*` accetta il token con TTL breve.

Requisiti normativi per operazioni distruttive — in §9.5.

### A.2. Blocco ottimistico

Per update/delete in caso di modifica concorrente, il parametro DEVE essere denominato `expected_updated_at` (§4.4), non `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Il nome è unificato per strumenti core ed estensioni (inclusi gli strumenti di scrittura checklist).

In caso di conflitto restituisce `CONFLICT`, l'orario reale di modifica dell'oggetto (`updated_at` / `updated_on` nella risposta) e la raccomandazione di rileggere l'oggetto.

### A.3. Chiave di idempotenza

Per operazioni in cui una ripetizione per timeout può creare un duplicato:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Particolarmente appropriato per:

- creazione issue;
- importazione voci di tempo;
- upload file;
- operazioni massive;
- invio email.

Se lo strumento pubblica `idempotentHint: true`, la chiamata ripetuta deve essere sicura (§8.2); `idempotency_key` è un modo per garantirlo.

---

## Appendice B. Esempio completo di strumento

Riferimento `redmine_create_issue`. Quando cambiano formato errore o envelope, aggiornare §7, §10 e questa sezione; §12 resta abbreviato.

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

Nota: se il server garantisce l'idempotenza quando è presente `idempotency_key`, l'annotazione descrive comunque lo strumento nel suo insieme. Pertanto il valore sicuro resta `false` se è consentita la chiamata senza chiave.

