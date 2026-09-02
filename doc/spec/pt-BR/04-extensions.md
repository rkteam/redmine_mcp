# API de extensão para outros plugins

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Visão geral

O Redmine MCP fornece um mecanismo de extensão que permite a outros plugins Redmine instalados registrar suas próprias ferramentas, recursos e prompts, e estender ferramentas existentes.

## Objetivo

Fornecer uma abordagem única para integrar plugins Redmine com IA sem duplicar um servidor MCP e sem alterar o código do Redmine MCP.

## Áreas afetadas

- Plugins
- API
- Permissões

## Regras de negócio

### Descoberta automática

- Na inicialização do Redmine (quando o MCP está habilitado), o sistema verifica todos os plugins instalados.
- Um plugin é considerado com extensão MCP se contém um arquivo `mcp.rb` em um destes caminhos:
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<plugin directory basename>/mcp.rb`;
  - `lib/<plugin.id without redmine_ prefix>/mcp.rb` se o identificador começa com `redmine_` (esquema típico como `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- O plugin `redmine_mcp` não carrega a si mesmo como extensão.
- Plugins cuja checkbox de extensão MCP está desmarcada nas configurações são ignorados.
- Uma falha na extensão de um plugin não bloqueia a carga de outros, incluindo erro de sintaxe no arquivo de extensão.

### Registro de ferramentas

- Um plugin de extensão pode registrar qualquer número de ferramentas.
- Cada ferramenta tem: nome, descrição, schema de entrada, schema de saída, requisito de permissão e handler.
- Nome completo da ferramenta: `redmine_<plugin_id>_<name>`, por exemplo `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Nomes de ferramentas duplicados são proibidos.
- Uma ferramenta aparece no MCP apenas para usuários com as permissões correspondentes.
- Uma ferramenta de extensão com escopo de tarefa pode exigir um módulo de projeto Redmine habilitado (o identificador do módulo não precisa corresponder ao id do plugin). Em `tools/list`, tal ferramenta é visível se o usuário tem a permissão declarada em pelo menos um projeto visível com esse módulo. Sem requisito de módulo, permissão em pelo menos um projeto visível é suficiente. A chamada ainda verifica a tarefa específica: visibilidade, permissão no seu projeto e módulo habilitado; caso contrário a resposta é "not found".
- Ferramentas de escrita de extensão no modo somente leitura do MCP não executam o handler: a negação é a mesma que para ferramentas de escrita principais.

### Estender ferramentas existentes

- Um plugin pode estender uma ferramenta já registrada.
- Uma extensão pode:
  - adicionar parâmetros de entrada extras;
  - executar código antes do handler principal;
  - executar código após o handler e modificar o resultado.
- Múltiplos plugins podem estender a mesma ferramenta ao mesmo tempo.
- Parâmetros extras são mesclados no schema de entrada compartilhado.
- Um nome de parâmetro extra não pode corresponder a um parâmetro da ferramenta principal nem a um parâmetro de outra extensão para a mesma ferramenta.
- O schema resultante é normalizado antes da publicação em `tools/list`.
- A ordem de execução das extensões corresponde à ordem de carga dos plugins.

### Registro de recursos

- Um plugin pode publicar recursos com URI única. Re-registrar a mesma URI é rejeitado.
- Um recurso deve ter um handler de leitura.
- Esquema de URI recomendado: `redmine://<plugin_id>/<type>/<id>`.
- Um recurso pode exigir verificações de permissão; sem permissão o recurso fica indisponível.
- Verificações de permissão recebem a URI e argumentos. O projeto é obtido de `project` / `project_id`, da URI (`project`/`project_id` na query ou segmento `/projects/:id`), ou de um resolvedor de projeto explícito definido pela extensão. `resources/read` passa `{uri: ...}` à verificação.
- Se um projeto é especificado na chamada mas não é encontrado ou não é acessível ao usuário atual, o acesso é negado. A verificação "pelo menos um projeto" aplica-se apenas quando nenhum projeto é especificado (descoberta com argumentos vazios).
- Ler um recurso retorna conteúdo em formato texto ou JSON.

### Registro de prompts

- Um plugin pode adicionar prompts com nome, descrição, argumentos e handler.
- Nome completo do prompt: `redmine_<plugin_id>_<name>`.
- Prompts estão disponíveis para usuários com as permissões correspondentes. Verificações de permissão recebem argumentos da chamada, incluindo `project` / `project_id`. Se um projeto é especificado mas não é encontrado ou não é acessível, o acesso é negado; sem projeto especificado aplica-se a mesma regra de descoberta que para recursos.

### Eventos (hooks)

- Um plugin pode subscrever eventos do ciclo de vida do MCP, por exemplo:
  - registro de ferramentas;
  - registro de recursos;
  - registro de prompts;
  - conclusão da carga de todas as extensões.
- Um erro em um handler de evento é registrado em log e não interrompe o processo principal.

### Dependências

- Um plugin de extensão não precisa declarar dependência rígida do Redmine MCP.
- É recomendado verificar `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` antes do registro.
- O plugin de extensão não precisa incluir a gem MCP — a API do Redmine MCP é suficiente.

### Capacidades da API de extensão

Por meio da Extension API, um plugin de extensão pode:

- verificar que o MCP está habilitado e a extensão não está desabilitada;
- registrar uma ferramenta uma vez (sem duplicação no reload);
- registrar uma ferramenta com escopo de tarefa com verificações de permissão padrão e busca de tarefa; se a tarefa desapareceu antes do handler executar, a resposta é "not found", não erro interno;
- estender uma ferramenta principal existente com parâmetros e handlers before/after;
- registrar modos de capability para `redmine_get_mcp_info` (por exemplo `issue_search.semantic`);
- chamar a REST API do Redmine ou do plugin in-process em nome do usuário atual por meio de `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; o endpoint de destino deve aceitar autenticação de API); erros REST são mapeados a códigos MCP canônicos sem o status HTTP da requisição interna;
- publicar `outputSchema` no formato de envelope `{ ok, data | error }`.

A lista de métodos da API Ruby e exemplos de código estão no README do plugin e em [mcp_tool_development.md](mcp_tool_development.md) (um dev guide, não SPEC comportamental).

## Casos extremos

- Um plugin sem arquivo de extensão é ignorado.
- Se o arquivo de extensão existe mas `require` falha — entrada de log, extensão não é considerada carregada; registro de ferramentas é efeito colateral de um `require` bem-sucedido.
- Tentativa de estender ferramenta inexistente — erro durante o registro da extensão.
- Um plugin com checkbox de extensão MCP desmarcada nas configurações não é carregado mesmo se o arquivo de extensão existe.
- Após instalar nova extensão, é necessário reiniciar o Redmine; o cliente MCP pode precisar reconectar.

## Tratamento de erros

- Erro de carga do arquivo de extensão — entrada de log, continua carga de outros plugins.
- Erro de registro de ferramenta na inicialização — entrada de log.
- Erro no handler `before` da extensão — aborta execução da ferramenta.
- Erro no handler `after` — registrado em log; o resultado do handler principal é preservado a menos que o handler alterou o fluxo de controle.

## Cenários de teste

8. Descoberta de recursos e prompts com argumentos vazios permanece disponível se permissão existe em pelo menos um projeto.
9. Um plugin com `plugin.id` como `redmine_*` e arquivo `lib/<id without redmine_ prefix>/mcp.rb` é considerado com integração MCP e aparece nas configurações de extensão MCP.
10. Uma ferramenta com escopo de tarefa e requisito de módulo não está em `tools/list` para usuário sem qualquer projeto visível com esse módulo, mesmo se tem a permissão em outro projeto.

## Exemplos de extensões

| Plugin | Ferramenta | Objetivo |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Busca semântica de tarefas |
