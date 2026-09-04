# Extensões MCP para plugins Redmine

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` permite que outros plugins Redmine adicionem suas próprias ferramentas MCP e, se necessário, registrem recursos, prompts e capabilities sem um servidor MCP separado e sem alterações no próprio `redmine_mcp`.

## Como funciona

`redmine_mcp` fornece um Registry MCP compartilhado onde plugins Redmine de terceiros registram ferramentas por meio de `RedmineMcp::ExtensionApi`.

Um fluxo típico de chamada:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` não deve conhecer a lógica de negócio de um plugin de terceiros: o plugin registra suas próprias ferramentas pela Extension API.

## Estabilidade e compatibilidade retroativa

Desde `redmine_mcp 1.0.0`, a Extension API pública é considerada estável.

Apenas métodos e contratos de `RedmineMcp::ExtensionApi` descritos neste guia são API pública. Classes, módulos e métodos internos de `redmine_mcp` que não são documentados como parte da Extension API não são API pública e podem mudar sem garantias de compatibilidade retroativa.

Dentro de uma mesma versão major de `redmine_mcp`:

- métodos públicos existentes da Extension API não são removidos nem alterados incompativelmente;
- novos métodos e parâmetros opcionais podem ser adicionados;
- métodos obsoletos são marcados primeiro e permanecem disponíveis pelo menos até a próxima versão major;
- alterações que exigem atualizações em plugins de terceiros são lançadas apenas em nova versão major.

Todas as alterações da Extension API estão listadas em `CHANGELOG.md`.

Plugins de terceiros são recomendados a declarar a versão mínima de `redmine_mcp` que exigem e revisar `CHANGELOG.md` ao atualizar.

## Início rápido

1. Crie um arquivo `mcp.rb` em um destes caminhos:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id without the redmine_ prefix>/mcp.rb` se `plugin.id` começa com `redmine_`
2. Defina o módulo `<PluginName>::Mcp`.
3. Estenda `RedmineMcp::ExtensionApi`.
4. Defina `plugin_id`.
5. Registre a primeira ferramenta.

Exemplo mínimo de extensão com escopo de tarefa:

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

O exemplo usa `register_issue_tool`, o helper recomendado para ferramentas que trabalham com tarefas. O contrato completo da ferramenta está em [mcp_tool_development.md](mcp_tool_development.md).

### O nome do módulo `Mcp`

O arquivo de extensão é `mcp.rb`. Zeitwerk infere `Mcp` desse nome de arquivo, então escreva `module Mcp`.

Ferramentas são registradas quando o arquivo é requerido. O loader não busca o nome da constante do módulo.

## Nomenclatura

Para ferramentas e prompts, use um nome curto:

```ruby
name: 'search_issues'
```

O nome MCP completo é gerado automaticamente:

```text
redmine_<plugin_id>_<name>
```

Para ferramentas, prefira `name` no formato `<verb>_<entity>`.

Verbos preferidos:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Não use `manage_*`, `process_*`, `handle_*` vagos, nem ferramentas com parâmetro como `action: create | update | delete` quando as operações podem ser divididas em ferramentas separadas e claras.

Por exemplo:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Se `plugin_id` já começa com `redmine_` (por exemplo `redmine_advanced_checklists`), o nome completo ainda segue `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Para recursos, use uma URI única, por exemplo:

```text
redmine://<plugin_id>/<type>/<id>
```

Nomes de ferramentas/prompts e URIs de recursos devem ser únicos. O comportamento de registro duplicado depende do método usado; `register_tool_once` não registra a mesma ferramenta duas vezes.

## Registro de ferramentas

### Ferramenta regular

Use `register_tool_once` quando precisa de uma ferramenta MCP regular não vinculada a uma tarefa específica.

Casos típicos:

- buscar dados do plugin;
- retornar um resumo;
- validação ou computação no servidor.

Exemplo básico:

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

O contrato completo da ferramenta — `additionalProperties: false`, anotações de risco e envelope via `SchemaNormalizer.envelope_output` — está descrito em [mcp_tool_development.md](mcp_tool_development.md).

### Ferramenta de tarefa

Use `register_issue_tool` quando a ferramenta aceita `issue_id` e trabalha com uma tarefa.

Esta é a opção recomendada para cenários com escopo de tarefa porque:

- encontra a tarefa por meio de `Issue.visible(user)`;
- verifica o módulo do projeto quando necessário;
- verifica a permissão dada no projeto da tarefa;
- passa a `issue` encontrada ao bloco;
- retorna erro se a tarefa está indisponível ou não é encontrada.

Veja também a seção Permissões.

`module_name` em `register_issue_tool` é um identificador opcional de módulo de projeto Redmine. Não precisa corresponder a `plugin_id`. Se definido, a ferramenta aparece em `tools/list` apenas quando o usuário pode ver pelo menos um projeto com esse módulo e a permissão declarada.

### O que o handler retorna

O handler retorna um hash de dados de sucesso sem envelope, ou um envelope pronto `{ok: true, data: ...}` / `{ok: false, error: ...}`. O Registry normaliza o resultado por meio de `ToolResponse.from_handler_result`: um hash simples é encapsulado em `{ok: true, data: ...}`; para listas você pode retornar o resultado pronto de `paginated_list`, que já contém `data` e `meta`.

Para erros, use `RedmineMcp::Core::Helpers.error_result`, `mcp_error`, ou `{ok: false, error: ...}`.

## Input schema

`SchemaNormalizer.normalize_input` normaliza o schema de objeto e adiciona restrições de serviço, mas o contrato público de parâmetros deve ser descrito explicitamente.

Regras principais:

- cada parâmetro deve ter um tipo definido;
- campos numéricos `*_id` usam `type: integer`, `minimum: 1`, e descrição com caminho de descoberta;
- conjuntos finitos de valores são definidos por `enum` / `const`, não apenas em texto;
- arrays devem ter `items`;
- campos interdependentes e mutuamente exclusivos são definidos por JSON Schema (`oneOf`, `if/then/else`, etc.), não apenas na descrição;
- bloqueio otimista usa `expected_updated_at`, não `updated_at`;
- `null` é usado apenas com semântica explicitamente documentada, por exemplo para limpar um campo;
- não use `fields`, `payload` ou `data` abertos em vez de parâmetros de negócio tipados;
- não aceite um objeto como string JSON;
- não aceite `file_path` arbitrário em ferramenta pública.

Requisitos completos de `inputSchema` estão em [mcp_tool_development.md](mcp_tool_development.md).

## Output schema

Toda nova ferramenta deve ter um `output_schema`.

Para resultado regular, use o envelope padrão:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Para listas, use `SchemaNormalizer.list_envelope_output(item_schema)`.

Campos estáveis conhecidos do resultado devem ser descritos explicitamente. Não use `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` em vez de contrato tipado quando a estrutura da resposta é conhecida. Esses schemas são aceitáveis apenas para estruturas verdamente abertas ou instáveis.

Requisitos completos de `outputSchema` estão em [mcp_tool_development.md](mcp_tool_development.md).

## Anotações

| Tipo de operação | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | depende da implementação | `false` |
| delete / purge | `false` | `true` | apenas se repetição é realmente segura | `false` |
| efeito externo | `false` | depende | geralmente `false` | `true` |

`destructive` significa perda irreversível de dados, não qualquer escrita.

`open_world` significa ir além da instalação Redmine conhecida, não criar um novo objeto dentro do Redmine.

Anotações não substituem verificações de permissão no handler.

## Permissões

`permission` é usado pelo Registry para disponibilidade da ferramenta e verificações preliminares, mas não substitui verificações de acesso ao objeto específico dentro do handler.

Para ferramentas com escopo de tarefa, use `register_issue_tool`, que verifica visibilidade da tarefa, módulo do projeto e permissão.

Para outras entidades, o handler deve re-verificar acesso ao objeto encontrado.

## Erros

Use os códigos de erro MCP padrão:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Para erros padrão, use os helpers `error_result`.
Para código customizado, use `mcp_error`.
Para bloqueio otimista, use `conflict_if_stale`.

O handler retorna erro estruturado, não stack trace ou exceção não tratada.

## Helpers integrados

`RedmineMcp::Core::Helpers` contém helpers compartilhados que devem ser reutilizados em vez de duplicados:

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

Fragmentos de schema prontos também estão disponíveis:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Antes de criar seu próprio helper, verifique se um adequado já existe em `redmine_mcp`.

Verifique o conjunto atual de helpers em `RedmineMcp::Core::Helpers` e [04-extensions.md](04-extensions.md): esta lista mostra as principais capacidades disponíveis e não substitui a documentação da API ExtensionApi.

## Modo somente leitura e idempotência

Ferramentas mutantes devem respeitar o modo somente leitura global:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Para operações onde uma chamada repetida pode criar duplicata, você pode usar `idempotency_key` e `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` é permitido apenas quando uma chamada repetida é realmente segura considerando todos os efeitos colaterais.

## Organização do código

`mcp.rb` deve conter principalmente registro de ferramentas: schemas, descrições, permissões, anotações e handlers curtos.

Busca, agregação e normalização de dados específicos do MCP podem ser movidos a:

- `mcp_tools.rb`;
- quando o arquivo cresce — `mcp_tools/*.rb`.

Lógica de negócio regular deve permanecer nos models/services do plugin e não deve depender do MCP.

Se o plugin já tem um endpoint REST adequado que implementa a operação necessária e suporta chamadas em nome do usuário atual, você DEVERIA reutilizá-lo por meio de `internal_request` (ou `internal_get` para chamadas `GET` somente leitura).

Esta é a opção preferida: o MCP usa as mesmas verificações de permissão, busca de dados e comportamento de negócio que a API existente do plugin.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Para `POST`, `PUT` e `PATCH`, passe uma string de corpo JSON da requisição (ou `nil` quando o endpoint não espera corpo). Parâmetros de query vão em `params`.

Chame model/service diretamente quando:

- não há endpoint REST adequado;
- o endpoint não suporta a operação ou dados necessários;
- usar REST cria uma camada desnecessária ou incorreta para a operação;
- a lógica de negócio compartilhada já foi intencionalmente extraída em um service e o endpoint REST é apenas um wrapper fino desse service.

Não implemente a mesma lógica de negócio separadamente para REST e MCP. Se ambas as camadas precisam de lógica compartilhada, extraia em um service comum.

## Capacidades adicionais

`RedmineMcp::ExtensionApi` também fornece:

| Método | Quando usar |
|---|---|
| `register_resource` | você precisa de um recurso MCP |
| `register_prompt` | você precisa de um prompt MCP |
| `register_capability` | você precisa adicionar uma capability a `redmine_get_mcp_info` |
| `extend_tool` | você precisa estender uma ferramenta existente em vez de criar nova |
| `on` | você precisa de um hook do ciclo de vida |
| `internal_request` | você precisa chamar um endpoint REST do Redmine ou plugin in-process como usuário atual (`method`, `path`, `params` e `body` opcionais) |
| `internal_get` | atalho para `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | verificar se resultado REST in-process é envelope de erro MCP |

Defina `plugin_id` uma vez no topo do módulo. Antes de registrar ferramentas, você DEVERIA verificar `mcp_extension_enabled?` quando o registro é realizado pela extensão. O `ExtensionLoader` padrão também não carrega `mcp.rb` para extensões desabilitadas.

### Estender uma ferramenta existente

Use `extend_tool` apenas quando uma ferramenta separada não é adequada.

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` executa antes do handler, `after` executa após. `extra_params` são adicionados ao schema de entrada. Nomes de parâmetros não podem conflitar com a ferramenta base nem com outras extensões dessa ferramenta.

Se a extensão é requerida do `after_initialize` de um plugin antes de `redmine_mcp` registrar ferramentas principais, adie `extend_tool` para ferramenta principal (por exemplo `redmine_get_issue`) até a inicialização terminar — use `Rails.application.config.after_initialize` aninhado e verifique `Registry.instance.tool(...)` primeiro.

## Carga e desabilitação de extensão

`redmine_mcp` busca automaticamente o arquivo de extensão nos caminhos suportados quando o Redmine inicia.

Duas variantes de integração:

1. **Extensão em plugin de terceiros** — `lib/<...>/mcp.rb` no diretório do plugin alvo (ver «Início rápido»).
2. **Integração integrada em `redmine_mcp`** — `lib/redmine_mcp/extensions/<plugin.id>.rb` para casos em que o plugin de terceiros não pode ser modificado. O arquivo registra tools/resources/prompts pelo mesmo `RedmineMcp::ExtensionApi`. Se o plugin alvo já tem seu próprio `mcp.rb`, a integração integrada é usada apenas quando a carga desse arquivo falha.

Exemplo de integração integrada:

```ruby
module RedmineMcp
  module Extensions
    module AdvancedSearch
      extend RedmineMcp::ExtensionApi

      plugin_id :advanced_search

      if mcp_extension_enabled?
        register_tool_once(
          name: 'semantic_search_issues',
          description: 'Semantic search for issues.',
          input_schema: {type: 'object', properties: {}},
          output_schema: RedmineMcp::SchemaNormalizer.envelope_output(type: 'object', properties: {}),
          permission: :view_issues,
          handler: ->(_args, _context) { {} }
        )
      end
    end
  end
end
```

O código auxiliar da integração pode ficar em `lib/redmine_mcp/extensions/<plugin_id>/` e ser importado com `require` explícito do arquivo principal.

Verifique `redmine_mcp` apenas no ponto de entrada `mcp.rb` (geralmente `lib/<plugin>.rb` ou `after_initialize` do loader do plugin). Arquivos carregados apenas de `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb`, etc.) não devem repetir as mesmas verificações. Para integrações integradas em `redmine_mcp`, não é necessária verificação separada no ponto de entrada: o arquivo é carregado apenas pelo `ExtensionLoader`.

Não chame `ExtensionLoader.load_plugin_extension` manualmente de um plugin de terceiros: `ExtensionLoader` é mecanismo interno de `redmine_mcp`. Um `require` condicional do seu `mcp.rb` é suficiente; se a ordem de carga de plugins impediu esse `require`, o `redmine_mcp` `ExtensionLoader` padrão age como fallback.

Exemplo de ponto de entrada:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

A extensão é registrada apenas se:

- MCP está habilitado nas configurações de `redmine_mcp`;
- o arquivo de extensão é encontrado (`mcp.rb` no plugin ou `lib/redmine_mcp/extensions/<plugin.id>.rb` em `redmine_mcp`, com prioridade do `mcp.rb` do plugin);
- o módulo de extensão carrega corretamente;
- a extensão não está desabilitada na lista `MCP extensions`.

Após instalar nova extensão ou alterar `mcp.rb`, o Redmine geralmente precisa de reinício. O cliente MCP pode precisar reconectar. Em algumas aplicações, como Cursor, recarregar o servidor MCP não é suficiente para pegar novas ferramentas: se não aparecem, reinicie completamente a aplicação.

## Verificação de extensão

Após implementação, verifique a ferramenta por meio de chamada MCP real para checar não apenas o handler, mas também:

- registro em `tools/list`;
- schema de entrada;
- permissão;
- envelope de saída;
- erros.

Verifique os logs do Redmine para registro de ferramentas e erros de carga de extensão.

Para cada nova ferramenta, no mínimo:

- um cenário de schema bem-sucedido;
- um cenário de schema negativo.

Requisitos detalhados de testes automatizados estão em [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Testes automatizados de extensão

Testes automatizados de extensão MCP de plugin DEVEM exercitar o **caminho completo do Registry** (validação `inputSchema` → permissão → handler → envelope `{ok, data | error}`), não apenas chamada direta ao handler.

Se `redmine_mcp` não está instalado ou não carregado, a classe de teste **pula** cenários (`skip` em `setup`) em vez de falhar ao carregar o arquivo:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

No `setup` de teste, chamar `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` é aceitável para registrar ferramentas no `Registry`. Não chame `ExtensionLoader` do código de produção do plugin (ver "Carga e desabilitação de extensão").

Para comparar a resposta real com o `outputSchema` publicado (`mcp_tool_development.md` §7.1), use `json_schemer` — a mesma biblioteca que `RedmineMcp::InputValidator` aplica a schemas de entrada.

Lazy loading de `json_schemer` dentro de um helper de teste é permitido. Se a biblioteca não está disponível no ambiente, a verificação deve ser explicitamente pulada para que testes do plugin não falhem por dependência opcional.

Testes automatizados mínimos para ferramenta de extensão somente leitura:

- uma chamada Registry bem-sucedida com validação `outputSchema`;
- uma chamada negativa rejeitada por `inputSchema` (por exemplo violação de `oneOf`, enum ou `maxItems`);
- quando necessário — teste separado de validação no servidor no nível do handler (schema não substitui verificações no servidor; ver `mcp_tool_development.md` §3.4).

## Solução de problemas

| Problema | O que verificar |
|---|---|
| Extensão não carregou | caminho de `mcp.rb` ou `lib/redmine_mcp/extensions/<plugin.id>.rb`, nome do módulo, se MCP está habilitado, se a extensão está habilitada nas configurações, erros no log Rails |
| Ferramenta/recurso/prompt não apareceu | se `plugin_id` está definido, se extensão está desabilitada, colisões de nome ou URI, se usuário tem permissões necessárias |
| Alterações não apareceram após edições | reinicie Redmine; em Cursor e clientes similares, recarregar servidor MCP pode não pegar novas ferramentas — reinicie completamente a aplicação |
| `extend_tool` não funciona | se ferramenta base está registrada, se `extra_params` conflita com schema existente |

### Checklist pré-merge

- [ ] A ferramenta tem `title`, `description`, `input_schema`, `output_schema`, `permission` e `annotations`.
- [ ] Cada `*_id` tem caminho de descoberta.
- [ ] Descrição, output_schema e resposta real são consistentes.
- [ ] Ferramenta mutante respeita modo somente leitura.
- [ ] Lógica específica do MCP não cresce dentro de lambda/handler.
- [ ] Helpers compartilhados são reutilizados de `redmine_mcp`, não copiados.
- [ ] Pelo menos um cenário de schema bem-sucedido e um negativo foram executados.
