# Requisitos de desenvolvimento de ferramentas Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Status:** guia do desenvolvedor (dev-guide), não uma SPEC comportamental do plugin
**Versão:** 1.6
**Data:** 2026-08-20
**Aplicabilidade:** todas as novas ferramentas Redmine MCP e alterações substanciais em ferramentas existentes
**Versão base do MCP:** Protocol Revision `2025-11-25`

Contratos comportamentais das core tools estão em `03-core-tools.md` e SPECs relacionadas. Este documento define regras para projetar e implementar ferramentas.

---

## 1. Objetivo deste documento

Este documento estabelece requisitos unificados para projetar, implementar, descrever, testar e publicar ferramentas MCP para Redmine. Padrões de implementação arquitetural estão reunidos no apêndice A e não são misturados com requisitos obrigatórios no texto principal.

O objetivo deste padrão é tornar as ferramentas:

- inequívocas para seleção por modelos de linguagem;
- seguras quando invocadas automaticamente;
- previsíveis para clientes MCP;
- rigorosamente validadas;
- fáceis de manter e compatíveis com versões anteriores;
- resilientes a chamadas repetidas, erros de modelo e argumentos parcialmente preenchidos.

Os requisitos são formulados com uma auditoria do Redmine MCP atual em mente. No momento da elaboração deste documento, o servidor publica 46 ferramentas; o contrato revelou parâmetros sem `type`, listas de strings de valores permitidos em vez de `enum`, ferramentas universais `manage_*` e ausência de `outputSchema`.

---

## 2. Terminologia de obrigatoriedade

Os seguintes níveis são usados neste documento:

- **MUST / DEVE** — requisito obrigatório. A violação bloqueia o merge.
- **MUST NOT / PROIBIDO** — proibição obrigatória.
- **SHOULD / DEVERIA** — requisito por padrão; o desvio deve ser justificado no merge request.
- **MAY / PODE** — opção aceitável.

Os padrões de arquitetura e implementação que não são obrigatórios para todas as ferramentas são coletados no **apêndice A**. Eles não bloqueiam a mesclagem se não forem adotados conscientemente para uma ferramenta específica.

---

## 3. Princípios básicos de design

### 3.1. Uma ferramenta — uma ação clara

Uma ferramenta DEVE representar uma intenção atômica do usuário.

Bom:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Ruim:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Ferramentas com um parâmetro como `action: create | update | delete | list` são PROIBIDAS se as operações:

- exigir diferentes argumentos obrigatórios;
- possuem diferentes níveis de risco;
- deve ter anotações MCP diferentes;
- retornar diferentes estruturas de dados;
- requer diferentes permissões do Redmine.

Uma exceção é permitida apenas para uma operação semanticamente homogênea onde todas as variantes apresentam o mesmo risco e um único contrato. A exceção deve ser explicitamente justificada.

### 3.2. Ler, adicionar, atualizar e excluir são separados

Em uma ferramenta é PROIBIDO combinar:

- operações somente leitura e gravação;
- operações de adição e exclusão;
- operações normais de usuário e administrativas;
- operações locais do Redmine e envio de dados para o mundo exterior.

Por exemplo, `list/create/delete relation` deve ser três ferramentas separadas.

### 3.3. O contrato é mais importante do que a conveniência da implementação do servidor

Não publique a estrutura de um método interno Ruby/Python/REST diretamente apenas porque é mais fácil implementar o manipulador dessa forma.

O contrato MCP é desenhado para o modelo e cliente; um adaptador dentro do servidor o converte para o formato API Redmine.

Os valores técnicos internos de um plugin ou Redmine DEVEM ser normalizados se não fizerem parte de um contrato externo significativo.

Não publique desnecessariamente:

- Nomes de classes Ruby/Rails e tipos de STI;
- nomes de enumerações internas se o MCP já estiver usando um valor de entrada diferente;
- datas dependentes da localidade;
- Representações específicas do REST do mesmo campo se o MCP já definir um formato canônico;
- nomes técnicos quando o MCP já utiliza um valor normalizado.

Exemplo: filtro de entrada `type` — `contact` / `company`; na resposta também `contact` / `company`, e não `Clientdesk::Contact` / `Clientdesk::Company`. Se o serializador retornar uma classe STI ou uma data localizada, o adaptador MCP DEVE converter o valor no esquema publicado.

### 3.4. O servidor não confia no modelo

Todos os argumentos são considerados não confiáveis. O servidor DEVE verificar novamente:

- tipos;
- intervalos;
- interdependências de campo;
- direitos do usuário atual;
- objeto pertencente a um projeto;
- disponibilidade de um valor em um fluxo de trabalho específico;
- Restrições redimensionadas;
- se a operação é permitida no estado atual do objeto.

Esquema JSON, descrições, anotações e confirmações do cliente não substituem a validação do lado do servidor.

---

## 4. Nomeação de ferramentas

### 4.1. Formato do nome

Todos os nomes de ferramentas publicadas DEVEM começar com `redmine_`.

Para ferramentas principais do plugin `redmine_mcp`, o prefixo curto `redmine_` é usado:

```text
redmine_<verb>_<entity>
```

Para ferramentas de plugins de terceiros, o nome completo DEVE começar com `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Requisitos:

- apenas `lower_snake_case`;
- o prefixo `redmine_` é necessário para todas as ferramentas, incluindo extensões de plugins de terceiros;
- o nome é único no servidor;
- limite interno - não mais que 64 caracteres;
- o nome não muda sem o procedimento de descontinuação.

Exemplos:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Verbos permitidos

Verbos preferidos:

| Verbo | Finalidade |
|---|---|
| `get` | recuperar um objeto por identificador exato |
| `list` | obter coleção usando filtros estruturados |
| `search` | realizar pesquisa de texto ou texto completo |
| `create` | criar um objeto |
| `update` | modificar um objeto existente |
| `set` | definir um campo ou flag específico para um valor determinado |
| `delete` | excluir um objeto |
| `add` | adicionar uma relação ou membro a um objeto existente |
| `remove` | remover uma relação sem excluir o objeto principal |
| `copy` | criar uma cópia |
| `upload` | carregar um arquivo |
| `download` | recuperar o conteúdo do arquivo |
| `send` | enviar uma mensagem ou dados para um destinatário externo |
| `summarize` | construir um relatório agregado do lado do servidor |

Não use verbos vagos (`manage`, `process`, `handle`, `execute`, `do`) — veja §3.1.

O verbo DEVE corresponder à semântica real da operação. Se uma ferramenta alterna um sinalizador booleano (parâmetro como `enabled: true | false`), ela DEVERIA ser nomeada com `set`, não com um verbo implicando apenas um valor.

Ruim:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` implica apenas `enabled = true`, embora o parâmetro também permita `false`. O nome não corresponde à ação real.

Bom:

```text
redmine_advanced_search_set_semantic_index_enabled
```

O nome `set_*` reflete honestamente que a operação define o sinalizador para o valor passado.

### 4.3. Nomes de parâmetros identificadores

O nome de um parâmetro DEVE corresponder ao seu tipo real:

- `issue_id` — apenas ID inteiro;
- `project_id` — apenas ID inteiro;
- `project_identifier` — identificador de string do Redmine;
- `project` — string que permite deliberadamente ambas as representações e é documentada como referência.

Um parâmetro chamado `*_id` não pode aceitar um identificador de string ou o valor `"me"`.

IDs numéricos DEVEM ter `minimum: 1` e uma `description` significativa. Formulações como `"Issue id"` sem `minimum` são PROIBIDAS.

Ruim:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Bom:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

A única opção recomendada para um projeto é o parâmetro `project`, que aceita um ID numérico (como uma string) ou um identificador de string:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

A matriz `examples` (§6.15) mostra o modelo tanto nas formas de valores permitidas quanto reduz a chance de entrada incorreta.

### 4.4. Bloqueio otimista: `expected_updated_at`

O parâmetro que passa o carimbo de data/hora previamente conhecido do objeto para rejeitar uma alteração desatualizada DEVE ser chamado de `expected_updated_at` em todas as ferramentas e extensões principais.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

O nome `updated_at` para este significado é PROIBIDO: parece "novo horário de modificação", embora na verdade seja um valor para bloqueio otimista.

Ruim (lista de verificação e quaisquer extensões):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Bom:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Um campo de resposta que informa o tempo real de modificação do objeto PODE ainda ser denominado `updated_at` / `updated_on` - a confusão surge apenas para o parâmetro de entrada de bloqueio.

O comportamento normativo em conflito está no Apêndice A.2.

---

## 5. `title` e `description`

### 5.1. `title`

`title` DEVE ser um nome curto e legível, não uma cópia do nome técnico.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Descrição da ferramenta

`description` DEVE responder brevemente às principais questões:

1. O que a ferramenta faz e qual objeto é lido ou modificado?
2. O que não está incluído por padrão e como solicitá-lo?
3. Existem efeitos colaterais significativos?
4. Qual ferramenta preliminar chamar se o ID ou um valor permitido for desconhecido?

A descrição DEVE ser breve e fácil de ler. É PROIBIDO transformá-lo em um parágrafo longo de meia página listando todos os campos e todas as opções de inclusão: uma descrição sobrecarregada é mais difícil para o modelo ler do que uma descrição curta e estruturada.

DEVERIA escrever várias linhas curtas ou uma lista, não um texto contínuo. Os padrões e como alterá-los são mostrados de forma compacta.

Bom exemplo:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

Exemplo ruim - muito curto, não explica o resultado e o comportamento padrão:

```text
Gets issue.
```

Mau exemplo - parágrafo longo e sobrecarregado listando todos os campos:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. Referências a outras ferramentas

Quando a descrição, a descrição do parâmetro ou as instruções do servidor se referem a outra ferramenta, DEVE ser usado o nome completo registrado em `tools/list`, e não um `name` curto sem prefixo.

Ruim:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Bom:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

Nomes curtos são ambíguos entre plug-ins e forçam o modelo a adivinhar o prefixo. Isto é especialmente importante para extensões: `semantic_search_issues` sem o prefixo `redmine_advanced_search_` é facilmente confundido com uma ferramenta principal inexistente.

### 5.2.2. Descrição do resultado retornado

A descrição DEVE explicar brevemente o resultado da ferramenta para que o modelo entenda se uma chamada é suficiente ou se uma próxima ferramenta é necessária.

A descrição do resultado deve indicar:

- se um objeto, coleção, agregação, confirmação de alteração ou referência de recurso é retornado;
- quais dados relacionados são incluídos por padrão;
- quais dados grandes ou sensíveis não são incluídos sem um parâmetro explícito;
- se existe paginação e qual o limite padrão;
- se uma ferramenta de gravação retorna o objeto atualizado completo ou apenas o identificador, URL e hora da modificação;
- se o sucesso parcial é possível para uma operação em massa.

Exemplo para leitura:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

Exemplo para lista:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

Exemplo para escrita:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

Sobre o relacionamento entre descrição e `outputSchema` — veja §7.1 e §7.1.1. Se uma lista já retorna um campo, a descrição NÃO DEVE enviar o modelo para `get_*` apenas para esse campo.

### 5.3. A descrição não substitui o esquema

É PROIBIDO definir restrições apenas em texto:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Use `enum`, `const`, intervalos e esquemas condicionais.

O mesmo se aplica a campos mutuamente exclusivos. Se `description` disser "exatamente um entre `user_id` ou `group_id`", mas `required` contém apenas campos comuns - o esquema e o texto divergem. A restrição DEVE ser formalizada em `inputSchema` (§6.12).

### 5.4. Seleção previsível

As descrições de ferramentas semelhantes devem explicar claramente as diferenças.

Por exemplo:

- `redmine_list_project_members` — membros de um projeto específico e suas funções;
- `redmine_admin_list_users` — lista global de usuários de instalação, requer direitos administrativos.

### 5.5. Instruções em nível de servidor

O servidor PODE publicar breves instruções gerais que explicam as relações entre ferramentas e regras de fluxo de trabalho.

As instruções devem adicionar contexto não presente nas descrições individuais e referir-se às ferramentas pelos nomes completos (§5.2.1), por exemplo:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

PROIBIDO:

- repetir descrições de todas as ferramentas nas instruções do servidor;
- colocar ali instruções gerais de comportamento do modelo não relacionadas ao servidor;
- escrever um guia longo em vez de regras de roteamento breves;
- usando declarações de marketing;
- referindo-se a ferramentas por nomes curtos sem prefixo (`list_projects` em vez de `redmine_list_projects`).

### 5.6. Estude a API REST do Redmine antes do desenvolvimento

Antes de criar ou alterar substancialmente uma ferramenta, o desenvolvedor DEVERIA realizar uma pesquisa documental. Não é recomendado projetar o contrato apenas a partir do código MCP existente, da memória do desenvolvedor ou de um único exemplo de solicitação HTTP.

DEVERIA estudar:

1. Página principal da API REST do Redmine: autenticação geral, paginação, `include`, campos personalizados, arquivos e regras de erro de validação.
2. Página API separada para o recurso correspondente, por exemplo. Problemas, entradas de tempo, versões, páginas Wiki ou associações a projetos.
3. Seção do histórico de alterações da API e alterações para versões suportadas do Redmine.
4. Versão real do Redmine usada pelo MCP e versão mínima suportada.
5. API REST e código-fonte dos plug-ins Redmine usados se a ferramenta funcionar com uma entidade ou campos de plug-in. Antes de publicar uma ferramenta de extensão, DEVE verificar o serializador/serviço/endpoint REST de origem e pelo menos uma resposta real bem-sucedida para cada formulário de resultado (listar e obter, se ambos forem publicados).
6. Permissões reais, fluxo de trabalho, módulos habilitados, rastreadores, campos personalizados e restrições da instalação de destino.
7. Ferramentas MCP já publicadas para evitar a criação de um contrato duplicado ou conflitante.

A página principal `https://www.redmine.org/projects/redmine/wiki/rest_api` é o ponto de entrada, mas geralmente é insuficiente para uma ferramenta específica. DEVERIA ir para a página de recursos correspondente e verificar as operações, parâmetros de consulta, `include`, campos de solicitação, estrutura de resposta, códigos de erro e restrições de versão.

### 5.7. Relatório de cobertura de API

Antes de implementar uma nova ferramenta, o desenvolvedor DEVERIA anexar uma breve tabela de cobertura da API à solicitação de mesclagem:

| Campo | Conteúdo |
|---|---|
| Recurso Redmine | Recurso e link para página oficial da API |
| Ponto final | Método e caminho HTTP |
| Suportado desde | Versão mínima do Redmine |
| Parâmetros de solicitação | Todos os parâmetros de solicitação documentados |
| Filtros de consulta | Todos os filtros documentados e valores especiais |
| Incluir valores | Dados relacionados permitidos |
| Obrigatório/padrões | Campos obrigatórios e valores padrão |
| Resposta | Principais campos e variantes de resposta |
| Erros | Códigos HTTP e estrutura de erro |
| Permissões | Direitos exigidos e especificações de representação |
| Exposição MCP | Quais parâmetros são publicados no MCP |
| Omitido intencionalmente | Quais parâmetros não são publicados e por quê |
| Diferenças de plug-in/versão | Diferenças de plug-in e versão suportada |

O objetivo da tabela não é necessariamente publicar todos os parâmetros do Redmine no MCP. O objetivo é não esquecer parâmetros acidentalmente e tomar decisões de publicação de forma consciente.

Um parâmetro Redmine pode ser excluído do MCP se:

- é perigoso ou administrativo;
- duplica uma ferramenta clara separada;
- é instável nas versões suportadas;
- cria um esquema ambíguo;
- não é necessário para cenários de usuários alvo;
- leva a respostas excessivamente grandes.

Cada exclusão substancial é registrada em `Intentionally omitted` com uma breve justificativa.

### 5.8. Instruções para um agente de IA desenvolvendo ferramentas

Se uma ferramenta for criada ou alterada por um agente de IA, as instruções de trabalho DEVERIAM referir-se a este documento: pesquisa de API (§5.6–5.7), contrato (§3–§8), testes (§13), lista de verificação (§14).

Texto recomendado:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. Requisitos `inputSchema`

### 6.1. Estrutura básica

Cada ferramenta DEVE ter um esquema JSON válido.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Para uma ferramenta sem argumentos:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Proibição de propriedades indocumentadas

No nível superior e em todos os objetos aninhados:

```json
"additionalProperties": false
```

Um dicionário aberto só é permitido conscientemente. Nesse caso, o esquema de valor é definido explicitamente:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Tipo de cada parâmetro

Cada propriedade DEVE conter `type`, `$ref` ou uma composição `oneOf` / `anyOf` / `allOf`.

PROIBIDO:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Parâmetros obrigatórios

O array `required` deve refletir a chamada minimamente executável.

Se a operação for impossível sem um parâmetro, o parâmetro DEVE estar em `required`.

Por exemplo, o upload de arquivo requer pelo menos:

```json
"required": ["project", "filename", "content_base64"]
```

A verificação `confirm=true` para exclusão é realizada no servidor (§3.4), mesmo se o campo estiver em `required`.

### 6.5. Transferências

Para um conjunto finito de valores, DEVE usar `enum` ou `const` (não apenas texto na descrição — veja §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Cordas

As strings devem ter restrições apropriadas:

- `minLength` para valores não vazios;
- `maxLength` de acordo com restrições ou limites internos do Redmine;
- `pattern` quando o formato é estritamente definido;
- `format` quando um formato padrão se aplica.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

A restrição `format` no esquema não substitui a validação do lado do servidor (§3.4).

### 6.7. Números

Para parâmetros numéricos, limites razoáveis DEVEM ser definidos.

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

O valor `default` faz parte do contrato e da documentação. O servidor não deve presumir que o cliente substituirá o padrão por conta própria.

### 6.8. Matrizes

Cada array DEVE ter `items`.

Quando necessário, defina:

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

Um array como `entries: array` sem esquema de elemento é PROIBIDO.

### 6.9. Objetos aninhados

Todos os objetos aninhados são descritos completamente.

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

### 6.10. Não é possível aceitar "objeto ou string JSON"

É PROIBIDO descrever um parâmetro como "objeto ou string JSON".

O MCP já passa JSON estruturado. A ferramenta deve aceitar um objeto, não uma string que o servidor analisa novamente.

### 6.11. Universal `fields` and `extra_fields`

Os parâmetros `fields`, `extra_fields`, `payload`, `data` e objetos abertos semelhantes são PROIBIDOS para as principais operações de negócios.

Os campos da tarefa devem ser listados explicitamente, com uma `description` significativa (§6.14) e, quando útil, `examples` (§6.15):

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

Campos raramente usados podem ser passados através de `custom_fields` estritamente descritos.

### 6.12. Campos interdependentes

É preferível separar os instrumentos. Caso a separação não seja possível, a dependência é formalizada através de:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` com ramificações mutuamente exclusivas.

O texto na `description` ("exatamente um de…") não substitui o esquema (§5.3).

Caso típico — “exatamente um dos dois campos”. Ruim: `required` lista apenas campos comuns, XOR permanece em prosa:

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

Esse esquema permite uma chamada sem `user_id`/`group_id` e uma chamada com os dois campos ao mesmo tempo.

Bom — `required` comum mais `oneOf` de nível superior:

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

A verificação do servidor (§3.4) DEVE ainda rejeitar ambas as opções incorretas. O esquema é necessário para que o cliente e o modelo possam ver a restrição antes de chamá-la.

Deve verificar a compatibilidade das construções escolhidas com clientes MCP e SDK suportados.

### 6.13. Campos com valor `null` e limpeza de valores

`null` é permitido apenas quando tem um significado documentado separado, por ex. "limpar data de vencimento" ou "cancelar atribuição".

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

Não use string vazia como equivalente implícito de `null`.

Para ferramentas `set_*` que definem um campo opcional (prazo, responsável, etc.), o contrato DEVE abordar explicitamente a limpeza. São permitidas três opções, em ordem de preferência:

1. **A mesma ferramenta aceita `null`** (preferencial), como acima: uma intenção "definir ou limpar".
2. **Ferramenta separada para limpar/não atribuir**, se a API ou UX separar melhor as operações, por exemplo. `redmine_advanced_search_clear_saved_query` e `redmine_advanced_search_unassign_search_owner`.
3. **Recusa explícita**: se a compensação via MCP não for suportada, isso DEVE ser declarado na `description` da ferramenta e/ou na descrição do parâmetro. Contrato silencioso "apenas string/inteiro sem nulo" sem explicação é PROIBIDO - o modelo pensará erroneamente que a compensação é impossível ou tentará passar `""` / `0`.

Ruim – pode definir a data de vencimento, não pode limpar e não foi indicado em nenhum lugar:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Descrições dos parâmetros

Cada parâmetro em `inputSchema.properties` DEVE ter uma `description` significativa. Parâmetros sem `description` são PROIBIDOS, incluindo extensões (item de checklist `done`, `sort_order`, `due_date`, campos de ID, etc.) e campos opcionais com `enum` claro.

Descrições como "Filtrar por ID do rastreador", "ID do rastreador" ou "ID do problema" são insuficientes: elas não sugerem onde obter um valor permitido e quais restrições existem.

Uma descrição do parâmetro identificador DEVE indicar qual ferramenta ou campo de resposta usar para valores permitidos (nome completo — §5.2.1; descoberta — §6.16) e observar restrições significativas (fluxo de trabalho, permissões, pertencimento ao projeto).

Ruim:

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

Bom:

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

Bom, com restrição observada:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

A descrição do parâmetro não substitui o esquema (§5.3) e a validação do lado do servidor (§3.4).

### 6.15. Exemplos de valores (`examples`)

Para parâmetros onde o formato do valor não é óbvio ou permite múltiplas representações, DEVERIA adicionar `examples` - chave de matriz do esquema JSON padrão. Os exemplos ajudam o modelo a inserir um valor correto e são especialmente úteis para parâmetros de referência, identificadores, datas e strings semelhantes a enum.

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

Requisitos:

- os valores de `examples` DEVEM ser válidos em relação ao próprio esquema de parâmetros;
- `examples` ilustram o formato, mas não substituem `enum`, intervalos e outras restrições (§5.3, §6.5);
- para parâmetros com `enum`, `examples` separados são geralmente redundantes.

Se um cliente MCP ou SDK não suportar `examples` no esquema, `x-examples` PODERÁ ser usado como uma chave de extensão com a mesma semântica.

### 6.16. Caminho de descoberta para parâmetros de ID

Um parâmetro no formato `*_id` que o modelo não consegue adivinhar DEVE ter um caminho de descoberta explícito: uma ferramenta de leitura/lista separada ou um campo em outra resposta da ferramenta de leitura referenciada no parâmetro `description` (§6.14).

Opções permitidas (em ordem de preferência para um conjunto de ferramentas):

1. **Ferramenta de lista/descoberta separada** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Opções dentro de obter/listar resposta** — por exemplo. matriz de provedor com `id` e `name` na resposta `redmine_advanced_search_semantic_search_issues`. Então a descrição DEVE referir-se a esse campo de resposta com o nome completo da ferramenta.
3. **Enum estável no esquema**, se o conjunto de valores for fixo e pequeno.

PROIBIDO publicar uma ferramenta de gravação com `status_id` / `role_ids` / semelhante se nenhuma das opções acima for satisfeita: o modelo é forçado a adivinhar IDs.

Ruim - escreva sem descobrir:

- `redmine_advanced_search_set_search_provider` existe com `provider_id`;
- não `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` retorna apenas o nome do provedor atual (`provider: "…"`), sem lista de valores permitidos e seu `id`.

Nesse caso, uma descrição como `"Search provider ID."` é insuficiente. Adicione uma ferramenta de lista ou inclua opções de provedor na resposta get e na escrita, por exemplo:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

A regra se aplica ao núcleo e às extensões (§18).

---

## 7. `outputSchema` e requisitos de resultado

### 7.1. `outputSchema`

Uma nova ferramenta DEVE publicar `outputSchema`. O esquema descreve um contrato de resposta pública estável, não apenas o formato do envelope `{ ok, data | error }`.

Se `description` afirma que a ferramenta retorna campos nomeados ou estrutura aninhada, `outputSchema` DEVE formalizar esses campos, não se limitando a `data` / `items` de nível superior como "objeto arbitrário".

Ruim: a descrição lista `query`, `results`, trechos e trechos de anexos, mas `outputSchema` está faltando ou descreve `items` apenas como `{ "type": "object", "additionalProperties": true }`.

Para cada campo de resultado estável:

- o tipo DEVE ser especificado;
- um campo garantido DEVE estar em `required`;
- um conjunto de valores finitos DEVE ser definido via `enum` ou `const`;
- uma data DEVE ter `format: date` ou `date-time` se o servidor garantir o formato correspondente;
- o ID numérico DEVE manter um tipo unificado;
- anulável e opcional são contratos diferentes: se um campo é sempre retornado mas pode não ter valor, ele deve ser `required` e permitir `null`;
- para valores comerciais numéricos, as unidades DEVEM ser especificadas, caso não sejam óbvias no nome do campo;
- o valor monetário DEVE ter uma semântica inequívoca: unidades maiores/secundárias e como a moeda é determinada.

`additionalProperties: true` NÃO DEVE ser usado em vez de descrever campos de resultados estáveis conhecidos. É permitido para compatibilidade com versões anteriores ou estruturas verdadeiramente extensíveis, mas os campos de negócios conhecidos dentro de tal objeto ainda devem ser listados em `properties`, e os garantidos em `required`.

Para ferramentas de lista, os elementos `items` DEVEM descrever pelo menos os campos necessários ao modelo para identificação, filtragem e subsequentes chamadas de ferramenta.

Bom - fragmento digitando `data` (envelope completo de sucesso/erro - §7.2 e §12):

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

O resultado DEVERIA retornar:

- `structuredContent` — objeto legível por máquina se os clientes precisarem de uma estrutura estável;
- texto `content` — breve representação para compatibilidade com versões anteriores e humanos.

### 7.1.1. Consistência do contrato público

Antes de completar uma ferramenta, o desenvolvedor DEVE comparar três representações:

1. resposta real do manipulador/REST/serviço;
2. ferramenta `description`;
3. `outputSchema`.

Eles não devem se contradizer.

Se a descrição disser que um campo é sempre retornado, ele deverá ser `required` em `outputSchema`.

Se o esquema definir `enum` / `const` / `format`, o serializador real DEVE normalizar o valor para esse contrato. Não é possível publicar `format: date` e simultaneamente prometer uma string formatada pelo local.

Se a lista já estiver retornando dados, a descrição NÃO DEVE enviar o modelo para get-tool apenas para os mesmos dados.

Os invariantes de negócios do resultado DEVEM ser refletidos pelo esquema via `const`, `enum`, `required` ou um esquema condicional, e não apenas implícitos no nome da ferramenta. Exemplo: se a ferramenta de assinatura, por definição, retorna apenas produtos do tipo `subscription`, `product_type` deve ser `const: "subscription"` em vez de `enum` com valores impossíveis.

### 7.2. Envelope unificado

Resultado de sucesso recomendado:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Erro:

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

Em caso de erro, defina adicionalmente:

```json
"isError": true
```

Se `outputSchema` for publicado e um erro também for retornado em `structuredContent`, o esquema DEVE descrever ambas as ramificações - sucesso e erro. Não é possível publicar o esquema somente com sucesso e retornar um objeto de erro estruturado incompatível. Alternativa: em caso de erro de execução da ferramenta, retorne apenas o texto `content` com `isError: true` e não retorne `structuredContent`. Opção preferida — envelope digitado unificado com duas ramificações.

### 7.3. Estabilidade de campo

Os campos de saída são um contrato público. PROIBIDO:

- alterar o tipo de campo sem grandes alterações;
- renomear um campo sem período de depreciação;
- às vezes retornando objeto, às vezes array;
- retornando ID como número às vezes, string às vezes;
- retornando resposta ilimitada da API Redmine não processada.

### 7.4. Resultado de objeto único

Formato recomendado:

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

### 7.5. Resultado da lista

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

O esquema do elemento `items` segue §7.1: identificadores, campos de roteamento e campos de negócios estáveis são descritos explicitamente. Vazio `{ "type": "object", "additionalProperties": true }` como única descrição do elemento é PROIBIDO.

### 7.6. Volume minimamente necessário

As ferramentas de lista/pesquisa devem retornar entradas curtas por padrão. Descrições completas, logs, anexos e campos de texto grandes devem ser recuperados com um `get_*` separado.

Isso reduz tokens, latência e risco de transmissão excessiva de dados confidenciais.

### 7.7. Dados confidenciais

O resultado não deve conter sem necessidade explícita:

- Tokens de API;
- Cabeçalhos de autorização;
- biscoitos;
- caminhos do sistema de arquivos do servidor;
- rastreamentos de pilha internos;
- senhas e segredos;
- Campos Redmine indisponíveis para o usuário atual;
- notas privadas sem permissão separada.

---

## 8. Anotações MCP

As anotações são dicas para o cliente e não são um mecanismo de autorização ou proteção.

### 8.1. Matriz de valores

| Tipo de operação | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Obter/encontrar/listar dados Redmine | `true` | `false` | `true` | `false` |
| Criar problema/versão/lista de verificação | `false` | `false` | `false` | `false` |
| Adicionar comentário/observador/relação | `false` | `false` | `false` | `false` |
| Alterar campo, renomear, definir sinalizador (`update`, `rename`, `set`) | `false` | `false` | depende da implementação | `false` |
| Excluir, limpar, redefinir (`delete`, `purge`, `reset`) | `false` | `true` | apenas com idempotência garantida | `false` |
| Enviar email para destinatário externo | `false` | `false` | `false` | `true` |
| Acesse URL arbitrária/sistema externo | depende | depende | depende | `true` |

### 8.2. Regras

- `readOnlyHint: true` somente se a ferramenta não mudar de estado e não causar efeitos colaterais.
- `destructiveHint` descreve a perda ou destruição irreversível de dados, e não o fato da gravação em si. `destructiveHint: true` DEVERIA ser definido apenas para operações irreversíveis - `delete`, `purge`, `reset`, limpando completamente um campo ou link.
- Os usuais `update`, `rename` e `set` NÃO são destrutivos: para eles `destructiveHint: false`. Por exemplo, `update_checklist_title` ou `rename_wiki_page` é uma atualização normal, não uma destruição, e a anotação destrutiva para eles está incorreta.
- `idempotentHint: true` somente se a chamada repetida for realmente segura; DEVERIA confirmar com um teste.
- `openWorldHint` descreve se a ferramenta acessa um mundo externo aberto e anteriormente desconhecido, e não se um novo objeto é criado. Trabalhar com uma instalação configurada do Redmine é um mundo fechado: `openWorldHint: false`.
- Portanto `create_issue`, `create_time_entry` e outras ferramentas de escrita dentro de seu Redmine usam `openWorldHint: false`, apesar de criarem novos objetos. Criar um objeto em um sistema conhecido não torna o mundo aberto.
- `openWorldHint: true` somente quando o destinatário ou fonte de dados não está limitado ao sistema conhecido: envio de email para destinatário externo, solicitação HTTP arbitrária, acesso a serviço externo.
- O valor `openWorldHint` DEVERIA ser definido conscientemente para cada ferramenta, não copiado por padrão: verifique se a ferramenta realmente vai além da instalação do Redmine.
- Não é possível copiar um conjunto de anotações para todas as ferramentas de gravação.

### 8.3. Efeitos colaterais do Redmine

Ao avaliar a idempotência, considere não apenas os campos finais, mas também:

- criação de lançamento contábil manual;
- envio de notificação;
- webhooks;
- registro de auditoria;
- upload repetido de arquivos;
- criação de relações repetidas;
- registro repetido de entrada de tempo.

Se uma chamada repetida criar um registro ou notificação adicional, a ferramenta não será idempotente.

---

## 9. Segurança

### 9.1. Autorização

Cada chamada DEVE ser executada no contexto de um usuário autenticado ou de uma conta de serviço explicitamente documentada.

O servidor DEVE verificar as permissões do Redmine para o projeto e objeto específico. A presença da ferramenta em `tools/list` não significa permissão para a operação.

As ferramentas administrativas devem:

- ser publicado apenas para administradores;
- ou ser movido para um perfil/servidor administrativo MCP separado;
- ou ser protegido por um escopo separado.

### 9.2. Direitos mínimos

O servidor MCP e o token da API Redmine devem ter os direitos mínimos necessários. Você não poderá usar um token administrativo global para todos os usuários se quiser preservar o modelo de acesso do usuário.

### 9.3. Caminhos arbitrários do sistema de arquivos são proibidos

Ver opções:

```json
{"file_path": "/etc/app/.env"}
```

são PROIBIDOS em ferramentas MCP públicas.

Opções seguras:

1. `content_base64` com limite de tamanho;
2. `upload_token` opaco emitido por mecanismo de upload confiável;
3. URI do recurso MCP onde o acesso é verificado pelo host;
4. arquivo apenas do diretório temporário dedicado com verificação e lista de permissões `realpath`.

O servidor DEVE verificar:

- tamanho máximo;
- tipo MIME;
- extensão permitida;
- nome do arquivo;
- ausência de travessia de caminho;
- verificação de antivírus/conteúdo, se exigido pela política da organização.

### 9.4. URLs personalizados e SSRF

Uma ferramenta não deve aceitar uma URL arbitrária, a menos que esse seja seu objetivo principal.

Quando o acesso HTTP é necessário:

- usar lista de permissões de domínios e esquemas;
- proibir loopback, link local, endpoints de metadados e redes internas se não forem necessários;
- limitar redirecionamentos;
- definir tempo limite e limite de resposta;
- não passe credenciais internas para outra origem.

### 9.5. Exclusão e operações perigosas

Para operações irreversíveis, OBRIGATÓRIO:

- ferramenta separada;
- `destructiveHint: true`;
- descrição explícita da irreversibilidade;
- verificação precisa de direitos no lado do servidor;
- registro de auditoria;
- proteção contra exclusão de objeto fora do projeto esperado;
- verificação de objetos infantis e consequências relacionadas.

O booleano `confirm_delete: true` PODE ser usado como proteção adicional contra chamadas acidentais, mas não pode ser considerado um mecanismo de autorização.

Exclusão bifásica, bloqueio otimista e chave de idempotência - consulte o Apêndice A.

### 9.6. Registros

Registros de log de auditoria:

- nome da ferramenta;
- usuário autenticado;
- IDs de projeto/objeto de destino;
- resultado;
- duração;
- código de erro;
- solicitar ID de correlação.

PROIBIDO registrar:

- token de acesso;
- Cabeçalho de autorização;
- biscoitos;
- conteúdo do arquivo base64;
- campos personalizados secretos;
- texto completo de notas privadas sem necessidade separada.

### 9.7. Limite de taxa e tempo limite

Cada ferramenta DEVE ter:

- limite de tamanho de entrada;
- limite de taxa por usuário/token;
- limite no número de registros retornados;
- limites de operação em massa.

O tempo limite do servidor de 60 s aplica-se às ferramentas de leitura. As ferramentas de gravação não são interrompidas pelo tempo limite do servidor para que, após o salvamento bem-sucedido, o resultado da idempotência possa ser registrado.

---

## 10. Erros

### 10.1. Separação de erros

Dois níveis são usados:

1. **Erro de protocolo** - ferramenta desconhecida, JSON-RPC corrompido, incapacidade de processar a solicitação MCP.
2. **Erro de execução da ferramenta** com `isError: true` — erro de argumento, API Redmine, permissões, fluxo de trabalho ou erro de lógica de negócios.

Erros que o modelo pode corrigir alterando argumentos devem retornar como erros de execução da ferramenta.

### 10.2. Estrutura de erro

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

### 10.3. Códigos Recomendados

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

### 10.4. A mensagem deve ser corrigível

Ruim:

```text
Invalid request.
```

Bom:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Não retorne o rastreamento de pilha ao usuário. O rastreamento de pilha é armazenado somente no log do servidor protegido com ID de correlação.

---

## 11. Paginação e volume de dados

### 11.1. Ferramentas de lista/pesquisa

Parâmetros OBRIGATÓRIOS:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Para a API Redmine existente, `offset` é permitido. Para implementação personalizada, o cursor opaco é preferido se os dados puderem mudar ativamente durante a passagem.

### 11.2. Metadados de paginação

O resultado deve conter:

- `limit` real;
- `offset` ou `next_cursor`;
- `has_more`;
- `total_count`, se obtê-lo não cria uma carga significativa.

### 11.3. Selecione os campos

O parâmetro `fields` só é permitido como uma matriz de uma lista de permissões privada:

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

Não é possível passar nomes de campos arbitrários diretamente para SQL, ActiveRecord `select`, serializador ou API Redmine sem lista de permissões.

### 11.4. Ótimos resultados

Diários, anexos e arquivos grandes devem:

- possuem paginação separada;
- ser devolvido por ferramenta/recurso separado;
- para dados binários, retorno de link de recurso ou outra referência limitada, em vez de incorporar base64 grande em resposta, quando possível;
- ou oferecer suporte à execução aumentada de tarefas se a operação for muito longa e o cliente a suportar.

`execution.taskSupport` não é definido automaticamente. O padrão é `forbidden`.

---

## 12. Novo padrão de ferramenta

Exemplo de ferramenta de gravação abreviada com `title` obrigatório e `outputSchema` digitado conforme §7.1. Formato do erro — §10. JSON completo - no apêndice B.

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

## 13. Teste

### 13.1. Testes de esquema

Para cada ferramenta, OBRIGATÓRIO:

- pelo menos uma chamada válida;
- pelo menos uma chamada negativa (por exemplo, campo obrigatório ausente ou tipo errado).

DEVERIA cobrir conforme aplicável ao esquema:

- chamada válida completa;
- ausência de cada campo obrigatório;
- tipo errado de parâmetros-chave;
- campo adicional desconhecido;
- valor fora do enum;
- valor fora da faixa;
- data/data e hora incorretas;
- excedendo `maxItems`, `maxLength` e tamanho do arquivo;
- violação da interdependência dos campos (ambos os campos XOR ao mesmo tempo; nenhum dos pares obrigatórios).

### 13.2. Testes de permissão

Para operações de gravação, leitura destrutiva e sensível, DEVERIA verificar:

- usuário sem acesso ao projeto;
- usuário com acesso somente leitura;
- usuário com permissão de edição;
- administrador se a ferramenta tocar em cenários administrativos;
- acesso a notas privadas caso a ferramenta as devolva ou altere;
- tentativa de alteração de objeto de outro projeto via ID substituído.

Para ferramentas simples somente leitura sem dados confidenciais, os testes de permissão PODEM ser limitados a um cenário negativo ou omitidos com uma breve justificativa em MR.

### 13.3. Testes de idempotência

`idempotentHint: true` DEVERIA ter um teste automático ou manual para duas ou mais chamadas sequenciais idênticas.

É verificada a ausência de efeitos colaterais declarados como idempotentes, por exemplo:

- lançamentos contábeis adicionais;
- e-mails repetidos;
- arquivar duplicatas;
- duplicatas de relação;
- entradas de tempo repetidas;
- eventos extras de webhook se fizerem parte da garantia.

### 13.4. Testes de contrato

DEVERIA manter `tools/list` como instantâneo ou de outra forma rastrear alterações contratuais. CI PODE detectar:

- mudança de nome;
- remoção de parâmetros;
- mudança de tipo;
- mudança em `required`;
- aumento do nível de risco de anotação;
- desaparecimento de `outputSchema`;
- alteração incompatível de campos, tipos, `required`, `enum` / `const` ou ramificações de sucesso/erro de `outputSchema`.

### 13.5. Testes de seleção LLM

Para ferramentas semelhantes ou facilmente confundidas, DEVERIA ter um conjunto de solicitações de usuários e chamadas de ferramentas esperadas. A execução totalmente automática do LLM PODE ser substituída por exemplos estáticos em MR ou revisão de descrição.

Exemplos:

| Solicitação | Ferramenta esperada |
|---|---|
| "Mostrar edição 123" | `redmine_get_issue` |
| "Encontrar tarefas sobre OAuth" | `redmine_search_issues` |
| "Adicionar observador 15 à edição 123" | `redmine_add_issue_watcher` |
| “Remover a ligação entre tarefas” | `redmine_delete_issue_relation` |
| "Encontre problemas semelhantes" | `redmine_advanced_search_semantic_search_issues` |

O teste ou revisão falha se o modelo com alta probabilidade escolher uma ferramenta destrutiva universal para intenção somente leitura ou for forçado a adivinhar valores de `action`.

### 13.6. Testes de recuperação de erros

DEVERIA verificar se após erros típicos o modelo recebe informações suficientes para uma nova tentativa correta:

- falta de identificação;
- status inválido;
- conflito `expected_updated_at`;
- permissões insuficientes;
- limite excedido;
- tipo MIME incorreto.

---

## 14. Lista de verificação de revisão de código

A nova ferramenta não poderá ser mesclada até que a resposta “sim” seja recebida para todos os itens obrigatórios.

### Propósito

- [ ] Uma ação; nenhuma operação de mixagem `action`/`manage` (§3.1–3.2).
- [ ] A operação administrativa é separada da operação normal.

### Nome e descrição

- [ ] O nome começa com `redmine_`: core — `redmine_<verb>_<entity>`; plugin de terceiros — `redmine_<plugin_id>_…` (§4.1).
- [ ] Descrição: finalidade, efeitos colaterais, resultado breve; ferramentas semelhantes distinguíveis (§5).
- [ ] Referências cruzadas para outras ferramentas usam nomes completos de `tools/list` (§5.2.1).

### Pesquisa de contrato de origem

- [ ] Para core-tool, foram estudadas a API REST do recurso, versões e, se necessário, plugins; o relatório de cobertura DEVERIA ser anexado ao MR (§5.6–5.7).
- [ ] Para ferramenta de extensão, o serializador/serviço/endpoint REST original e pelo menos uma resposta real bem-sucedida para cada formulário de resultado DEVEM ser verificados (§18.5).
- [ ] Contrato comparado com `tools/list` atuais.

### Input schema

- [ ] Esquema corresponde a §6 (`additionalProperties: false`, tipos, `required`, `enum`/`const`, restrições).
- [ ] Todo parâmetro possui uma `description` significativa (§6.14); `*_id` tem `minimum: 1` (§4.3).
- [ ] Para `*_id` e outros valores de pesquisa, caminho de descoberta especificado (§6.16): ferramenta de lista, campo de resposta get/list ou `enum`.
- [ ] "Exatamente um de…" / restrições de interdependência formalizadas em esquema, não apenas em descrição (§5.3, §6.12).
- [ ] Bloqueio otimista - apenas `expected_updated_at`, não `updated_at` (§4.4).
- [ ] Para campos opcionais `set_*`, compensação decidida: `null`, ferramenta de compensação separada ou recusa explícita (§6.13).
- [ ] Sem "objeto ou string JSON" e `fields`/`payload` arbitrários.
- [ ] `*_id` — inteiro; validação do lado do servidor conforme §3.4.

### Saída e erros

- [ ] A nova ferramenta possui `outputSchema` com envelope de sucesso/erro (§7.1–7.2).
- [ ] Campos de resultados estáveis conhecidos descritos em `properties`; `additionalProperties: true` não usado em vez do contrato conhecido.
- [ ] Todos os campos garantidos estão em `required`.
- [ ] Campos anuláveis e opcionais diferenciados conscientemente.
- [ ] `enum`/`const`, `date`/`date-time`, intervalos e outras restrições conhecidas formalizadas no esquema.
- [ ] Para valores comerciais monetários e outros valores numéricos, as unidades, a moeda e as unidades maiores/secundárias são claras.
- [ ] Invariantes de negócios de resultado refletidos no esquema (`const`, `enum`, `required` ou esquema condicional), não apenas inferidos do nome da ferramenta.
- [ ] Descrição, `outputSchema` e a resposta real do manipulador/REST/serviço não se contradizem (§7.1.1).
- [ ] Valores internos REST/Ruby/plugin normalizados para contrato MCP estável; nenhum nome de STI/classe ou vazamento de formato dependente de localidade (§3.3).
- [ ] A ferramenta Lista retorna uma estrutura breve, mas suficiente; a descrição explica corretamente quando a ferramenta get correspondente é realmente necessária.
- [ ] Erros: `isError`, código estável, mensagem corrigível; sem segredos ou rastreamento de pilha (§10).

### Anotações

- [ ] Anotações correspondem ao risco (§8); teste recomendado para `idempotentHint: true`.

### Segurança

- [ ] Permissões, caminho de arquivo, SSRF, limites, logs, destrutivos/auditoria — conforme §9; padrões do apêndice A conforme necessário.

### Testes

- [ ] Testes mínimos de esquema; o resto está em risco (§13).

---

## 15. Compatibilidade e alteração de ferramentas existentes

### 15.1. Quebrando mudanças

Mudança significativa:

- renomear ferramenta;
- remoção de campo;
- mudança de tipo;
- adicionar um novo campo obrigatório;
- alteração do significado do campo;
- alteração de saída incompatível;
- combinar várias operações em uma;
- aumentar o risco sem atualizar anotações e documentação.

### 15.2. Migração de nomes

Ao mudar, por exemplo, do antigo prefixo `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

para o prefixo curto `redmine_`:

```text
redmine_get_issue
```

seguir:

1. adicione novo nome;
2. mantenha temporariamente o alias antigo;
3. marque a ferramenta antiga como obsoleta na descrição;
4. colete métricas de chamadas com nome antigo;
5. remova o alias após o período acordado;
6. envie `notifications/tools/list_changed` se o servidor declarar `listChanged`.

### 15.3. Alterando descrições

A descrição afeta a seleção da ferramenta do modelo e é considerada uma mudança comportamental. Em caso de mudança substancial na descrição, DEVERIA revisar os exemplos de seleção do LLM ou realizar uma revisão repetida da seleção.

### 15.4. Versão do servidor

A versão do servidor MCP é retornada por uma ferramenta somente leitura separada ou por metadados do servidor. Você não deve adicionar `v1`, `v2` a cada nome, a menos que haja uma necessidade real de suportar contratos simultâneos incompatíveis.

---

## 16. Regras para problemas atuais do Redmine MCP

No desenvolvimento de novas ferramentas, é proibido repetir padrões da auditoria do contrato atual. As regras canônicas estão nas seções correspondentes; abaixo está apenas um mapa do problema:

| Problema de auditoria | Seção |
|---|---|
| Nomes sem prefixo `redmine_` (incluindo plugins de terceiros) / estilo misto dentro de um plugin | §4.1 |
| O verbo não corresponde à semântica (`complete_*` com `done=true/false` em vez de `set_*`) | §4.2 |
| ID numérico sem `minimum: 1` ou com descrição "Issue id" | §4.3 |
| Bloqueio otimista como `updated_at` em vez de `expected_updated_at` | §4.4, A.2 |
| Parâmetro universal `manage_*` / `patch_*` e `action` | §3.1, §4.2 |
| Parâmetros sem `type`, enum apenas na descrição, arrays sem `items` | §5.3, §6 |
| Parâmetros sem `description`; descrições muito curtas sem referência da ferramenta de pesquisa | §6.14 |
| Sem `examples` em parâmetros de referência e identificadores | §6.15 |
| Ferramenta de gravação com `*_id` sem caminho de descoberta (sem ferramenta de lista e sem opções para obter resposta) | §6.16 |
| A descrição promete "exatamente um de A ou B", o esquema não o codifica | §5.3, §6.12 |
| Nomes curtos de ferramentas em referências cruzadas (`list_projects` em vez de `redmine_list_projects`) | §5.2.1 |
| Descrição da ferramenta sobrecarregada com meia página | §5.2 |
| `fields` / `extra_fields` sem esquema; extra `required` | §6.4, §6.11 |
| `set_*` sem forma de limpar campo e sem recusa explícita | §6.13 |
| Um conjunto de anotações para todas as ferramentas de gravação; extra `openWorldHint` | §8 |
| `destructiveHint: true` em `update` / `rename` comum; `openWorldHint` errado em `create_*` | §8.1, §8.2 |
| Descrição promete estrutura de resposta, mas `outputSchema` está faltando ou descreve apenas objeto arbitrário | §7.1 |
| Descrição, esquema e resposta real se contradizem | §7.1.1 |
| Nomes de STI/classe ou datas de localidade na resposta do MCP | §3.3 |
| `additionalProperties: true` em vez de campos conhecidos listar/obter | §7.1 |
| `file_path` arbitrário, desvio do escopo do projeto, SSRF | §9 |
| Email/efeito externo em uma ferramenta com mudança local | §3.2 |
| Pares ambíguos de ferramentas semelhantes | §5.4 |

---

## 17. Estrutura do conjunto de ferramentas

A lista completa de ferramentas atuais não está duplicada neste documento — ela rapidamente se torna desatualizada.

**Fonte da verdade:**

- ferramentas principais — [03-core-tools.md](03-core-tools.md) e `tools/list` reais na instalação;
- ferramentas de plugins de terceiros — §18 e resposta `tools/list` do MCP na instalação.

**Princípios de agrupamento** (cada grupo — ferramentas atômicas separadas conforme §3):

| Grupo | Exemplos de intenções | Prefixo |
|---|---|---|
| Problemas | obter, listar, pesquisar, criar, atualizar, excluir, copiar, subtarefas | `redmine_` |
| Relações e observadores | listar/criar/excluir relação; adicionar/remover observador | `redmine_` |
| Projetos e membros | projetos, módulos, membros, funções | `redmine_` |
| Versões e categorias | versões; categorias de problemas | `redmine_` |
| Entradas de tempo | listar, criar, atualizar, importar atividades | `redmine_` |
| Wiki | listar, obter, criar, atualizar, renomear, excluir | `redmine_` |
| Arquivos e anexos | listar, fazer upload, excluir, baixar | `redmine_` |
| Administrador | usuários, funções, informações do servidor | `redmine_admin_` ou `redmine_get_server_info` |
| Entidades de plug-in | listas de verificação, pesquisa, etc. | `redmine_` + `plugin_id`, por exemplo. `redmine_advanced_search_` |

Antes de adicionar uma nova ferramenta DEVERIA verificar a resposta `tools/list` do MCP e o grupo correspondente: não duplique a ferramenta existente e não misture intenções diferentes em um nome.

Se um grupo possui ferramenta de gravação com parâmetro ID (`status_id`, `role_ids`,…), o mesmo grupo DEVE ter caminho de descoberta (§6.16).

As ferramentas administrativas são publicadas apenas para usuários com os direitos exigidos (§9.1).

---

## 18. Extensões de plugins de terceiros

Seção para autores de plugins Redmine que adicionam ferramentas via API de extensão. Descrição técnica de API, ganchos e casos extremos - em [04-extensions.md](04-extensions.md).

As extensões seguem as mesmas regras de contrato, segurança e nomenclatura (§3–§10, §4.1) que as ferramentas principais do `redmine_mcp`.

### 18.1. Quando publicar o que

| Primitivo | Quando usar |
|---|---|
| **Ferramenta** | Uma ação na entidade do plugin ou Redmine: criar, obter, atualizar, excluir, pesquisar |
| **Recurso** | Conteúdo grande ou estático por URI estável: corpo do wiki, arquivo, relatório longo |
| **Aviso** | Modelo de cenário repetível para usuário, não operação com efeito colateral |
| **`extend_tool`** | Parâmetro ou gancho logicamente parte da ferramenta principal existente (por exemplo, `include_*` ao ler o problema) |

Se o modelo puder cumprir a intenção com uma ferramenta separada sem adivinhar `action` — prefira **ferramenta própria**, não `extend_tool` inflando outro esquema.

### 18.2. Cadastro

- O arquivo de extensão é carregado no início do Redmine: `lib/<plugin_id>/mcp.rb` (veja `ExtensionLoader`).
- O módulo em `mcp.rb` DEVE ser `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): Zeitwerk deriva o nome do arquivo.
- Antes do registro DEVERIA verificar `mcp_extension_enabled?` — a dependência rígida de `redmine_mcp` no gemspec não é necessária.
- Use `register_tool_once` para registro para que recarregar não duplique a ferramenta.
- O nome completo em `tools/list` DEVE começar com `redmine_` (§4.1).
- A ferramenta DEVE ter `title`, `description`, `input_schema`, `output_schema`, `permission` e `annotations`; duplicação de nome proibida.
- A ferramenta é visível na resposta `tools/list` do MCP apenas para usuários com permissão correspondente.

### 18.3. Nomeação

- O nome DEVE começar com `redmine_`; depois — `plugin_id` e `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verbos e proibição `manage_*` — conforme §4.2 e §3.1.
- Não copie os nomes das ferramentas principais e não publique a segunda ferramenta com a mesma intenção e com nomes diferentes.

Antes do registro DEVERIA comparar com a resposta `tools/list` na instalação de destino.

### 18.4. Permissões e segurança

- `permission` DEVE corresponder às permissões reais do Redmine ou do plugin, não a uma função separada "somente mcp".
- Para operações de issue DEVERIA usar `register_issue_tool` e `find_accessible_issue` em vez de copiar verificações de visibilidade e módulo do projeto.
- Se `module_name` estiver definido, a ferramenta DEVE estar em `tools/list` somente quando o usuário tiver declarado permissão em pelo menos um projeto visível com módulo habilitado. Sem `module_name`, a permissão em pelo menos um projeto visível é suficiente. O manipulador ainda verifica problemas específicos, incluindo seu módulo de projeto.
- Argumento repetido do lado do servidor e validação de permissão no manipulador - conforme §3.4 e §9, mesmo se a ferramenta estiver oculta em `tools/list` para outros usuários.

### 18.5. Implementação limpa

**Camada MCP fina.** `mcp.rb` deve conter principalmente registro de ferramentas: esquemas, descrições, permissões, anotações e manipuladores curtos. O manipulador valida argumentos, verifica o contexto e delega a execução para separar classe/serviço.

A lógica de negócios do plug-in deve permanecer nos modelos e serviços comuns e não depender do MCP.

Se a lógica for necessária apenas para MCP - por ex. mesclar dados de vários modelos, normalizar a resposta REST ao contrato MCP, calcular campos derivados ou preparar o resultado da ferramenta - PODE movê-lo para `mcp_tools.rb` separado. Se esse arquivo ficar grande, DEVERIA ser dividido em classes por entidade ou operação, por exemplo. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Não coloque lógica de negócios e grandes transformações diretamente em lambda/handler dentro de `mcp.rb`.

**Acesso a dados.**

- Modelos e serviços de plug-in — se a lógica já existir.
- `internal_request` / `internal_get` / REST — se necessário reutilizar o controlador API existente; o endpoint deve suportar `accept_api_auth`. Use `internal_request` para `POST`, `PUT`, `PATCH` e `DELETE`; use `internal_get` ou `internal_request(method: 'GET', ...)` para leituras. Verifique as falhas com `internal_request_error?`.

**`extend_tool` — moderadamente.** Apropriado quando o parâmetro faz parte de uma intenção com a ferramenta principal. Inapropriado quando o plugin essencialmente adiciona subsistema separado: melhor prefixo próprio e ferramentas próprias, link para o núcleo descrito na `description` ou instruções do servidor.

**Contrato como núcleo.** Entrada — conforme §6. Saída - de acordo com §7.1 e §7.1.1: campos estáveis, `required`, `enum`/`const`, unidades, normalização interna da API. Anotações por risco, erros corrigíveis (§8, §10). Bloqueio otimista — `expected_updated_at` (§4.4). Cada parâmetro — `description` (§6.14). Referências cruzadas — nomes completos (§5.2.1). Cada parâmetro de gravação `*_id` — caminho de descoberta (§6.16): `list_*` separado ou opções com `id` na resposta get/list e referência explícita na descrição do parâmetro.

Antes de publicar a ferramenta de extensão DEVE verificar o serializador de origem/serviço/endpoint REST e pelo menos uma resposta real bem-sucedida para cada formulário de resultado.

**Código compartilhado — em `redmine_mcp`.** Ao desenvolver uma extensão, se um fragmento for necessário para outro plugin MCP, DEVERIA adicioná-lo ao núcleo `redmine_mcp` imediatamente, e não copiá-lo para `lib/<plugin>/mcp*.rb`.

Critério: a lógica não está vinculada a um domínio de plugin (listas de verificação, pesquisa,…) e descreve o contrato MCP, API de extensão ou padrão de integração típico.

| Onde | O que |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, extensão `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, auxiliares de permissão comuns por `issue_id` / `project_id` |
| **Extensão de plug-in** | `mcp.rb` — registro de ferramentas e manipuladores curtos; `mcp_tools.rb` / `mcp_tools/*.rb` — busca, agregação e normalização específicas do MCP; modelos/serviços comuns — lógica de negócios independente do MCP |

**Posicionamento recomendado para extensão:**

- `mcp.rb` — registro de ferramentas e manipuladores curtos;
- `mcp_tools.rb` / `mcp_tools/*.rb` — busca, agregação e normalização de dados específicos do MCP;
- modelos/serviços comuns — lógica de negócio que não depende do MCP.

Antes de copiar o helper de outra extensão DEVERIA verificar se o análogo já existe em `redmine_mcp`; se ausente – vá para o núcleo no mesmo PR, não duplique.

Mais sobre API de extensão — [04-extensions.md](04-extensions.md) (§ "Métodos auxiliares ExtensionApi").

### 18.6. Antipadrões

PROIBIDO ou não recomendado:

- registrar ferramentas em cada solicitação HTTP;
- falha no erro do plugin vizinho na inicialização;
- misturar leitura, gravação e administração em uma ferramenta;
- duplicação da ferramenta principal “com nome diferente”;
- ampliação de outra ferramenta com parâmetros opcionais “para o futuro”;
- retorno em campos internos do MCP indisponíveis ao usuário na UI/API do plugin;
- publicar nomes de classes STI, datas de localidade ou representação REST se o esquema MCP definir contrato diferente (§3.3, §7.1.1);
- descrever o elemento da lista apenas como `{ "type": "object", "additionalProperties": true }` (§7.1);
- publicar `set_*_status` / similar com `status_id` sem fornecer ao modelo uma maneira de saber os IDs permitidos (§6.16);
- duplicar auxiliares MCP comuns na extensão (envelope `outputSchema`, wrappers `internal_request`, permissão de emissão) se seu lugar estiver em `redmine_mcp` — veja §18.5.

### 18.7. Verificação pré-mesclagem

- [ ] O nome da ferramenta começa com `redmine_` conforme §4.1 / §18.3.
- [ ] Cargas de extensão na partida; A ferramenta aparece em `tools/list` para usuários com direitos.
- [ ] Ferramenta ausente para usuário sem direitos e quando o sinalizador de extensão MCP do plugin está desabilitado.
- [ ] Contrato e checklist (§14) satisfeitos, incluindo description/outputSchema/comparação de resposta real (§7.1.1); testes de acordo com §13, se necessário.
- [ ] Serializer/REST/serviço verificado em pelo menos uma resposta real bem-sucedida para cada formulário de resultado publicado (por exemplo, listar e obter se ambos forem publicados).
- [ ] Nenhuma duplicação da ferramenta existente em `tools/list`.
- [ ] Para cada parâmetro de gravação `*_id` existe um caminho de descoberta (§6.16).

---

## 19. Fontes e base normativa

Documento elaborado em 22/07/2026 com base nas seguintes fontes primárias:

1. Protocolo de Contexto do Modelo, **Revisão do Protocolo 2025-11-25**
   https://modelcontextprotocol.io/specification/2025-11-25

2. Protocolo de Contexto do Modelo, **Ferramentas**
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Protocolo de Contexto do Modelo, **Referência de Esquema**
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Protocolo de contexto do modelo, **Práticas recomendadas de segurança**
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Protocolo de contexto do modelo, **Compreendendo a autorização no MCP**
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Blog do protocolo de contexto do modelo, **Anotações de ferramentas como vocabulário de risco: o que as dicas podem e não podem fazer**
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Instruções do servidor: Fornecendo aos LLMs um manual do usuário para o seu servidor**
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. Esquema JSON, **Referência**
   https://json-schema.org/understanding-json-schema/reference

9. Esquema JSON, **Valores enumerados**
   https://json-schema.org/understanding-json-schema/reference/enum

10. Esquema JSON, **Validação de esquema condicional**
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **Visão geral da API REST**
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **Problemas REST**
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **Alterações na API REST**
    Link `API changes for each version` na página da API REST; verificado para todas as versões suportadas.

---

## 20. Critério de prontidão da nova ferramenta

Uma nova ferramenta MCP é considerada pronta quando os itens obrigatórios da lista de verificação de revisão de código (§14) são satisfeitos.

Adicionalmente para ferramentas de plug-in de terceiros – lista de verificação §18.7.

Recomendações de risco: relatório de cobertura (§5.7), testes adicionais §13.2–13.6 e apêndice A. Testes de esquema mínimos (§13.1) e regras `outputSchema` (§7.1, §7.1.1) são obrigatórios.

---

## Apêndice A. Padrões de implementação recomendados

Os padrões abaixo não são obrigatórios para todas as ferramentas MCP. DEVERIA considerá-los de risco elevado: operações destrutivas, ferramentas administrativas, gravação em massa, efeitos colaterais externos, chamadas repetidas devido ao tempo limite.

### A.1. Exclusão em duas fases (preparar/confirmar)

Para operações administrativas especialmente perigosas:

1. `redmine_prepare_delete_*` retorna uma breve descrição das consequências e um token único;
2. `redmine_confirm_delete_*` aceita token com TTL curto.

Requisitos normativos para operações destrutivas — em §9.5.

### A.2. Bloqueio otimista

Para atualização/exclusão sob alteração simultânea, o parâmetro DEVE ser nomeado `expected_updated_at` (§4.4), não `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

O nome é unificado para ferramentas e extensões principais (incluindo ferramentas de gravação de lista de verificação).

Em caso de conflito, retorna `CONFLICT`, hora real de modificação do objeto (`updated_at` / `updated_on` em resposta) e recomendação para reler o objeto.

### A.3. Chave de idempotência

Para operações onde a repetição devido ao tempo limite pode criar duplicatas:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Especialmente apropriado para:

- criação de problemas;
- importação de entrada de horas;
- upload de arquivo;
- operações em massa;
- envio de e-mail.

Se a ferramenta publicar `idempotentHint: true`, a chamada repetida deve ser segura (§8.2); `idempotency_key` é uma maneira de garantir isso.

---

## Apêndice B. Exemplo completo de ferramenta

Referência `redmine_create_issue`. Quando o formato do erro ou o envelope mudarem, atualize §7, §10 e esta seção; §12 permanece abreviado.

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

Nota: se o servidor garantir idempotência quando `idempotency_key` estiver presente, a anotação ainda descreve a ferramenta como um todo. Portanto, o valor seguro permanece `false` se a chamada sem chave for permitida.

