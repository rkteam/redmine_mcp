# Redmine MCP — especificação geral

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Visão geral

O plugin Redmine MCP fornece um servidor MCP (Model Context Protocol) dentro de uma instalação Redmine. Clientes de IA conectam-se a um único endpoint HTTP e acessam dados do Redmine por meio de ferramentas, recursos e prompts.

O plugin inclui um conjunto base de ferramentas para trabalhar com projetos, tarefas e usuários. Outros plugins Redmine instalados podem estender o MCP sem alterar o código do Redmine MCP.

## Objetivo

Fornecer um mecanismo único de integração entre Redmine e sistemas de IA em que:

- o usuário opera dentro das suas permissões do Redmine;
- desenvolvedores de plugins podem adicionar suas próprias capacidades MCP;
- não é necessário um servidor MCP separado nem um fork específico da instalação.

## Principais cenários

1. **Conectar um cliente de IA** — um administrador habilita o MCP, concede a permissão `use_mcp` às roles necessárias e emite uma chave de API; o usuário conecta um cliente (Cursor, etc.) ao endpoint `/mcp`.
2. **Trabalhar com dados do Redmine** — o cliente chama ferramentas para buscar projetos, tarefas e usuários.
3. **Extensão por outros plugins** — quando um plugin com extensão MCP é instalado, suas ferramentas aparecem automaticamente na lista compartilhada.
4. **Administração** — habilitar/desabilitar o MCP e habilitar a integração MCP para plugins individuais.

## Áreas afetadas

- API (MCP sobre HTTP)
- Permissões
- Configurações
- Tarefas (issues)
- Projetos
- Usuários
- Fóruns (boards)
- Plugins (extensões)

## Regras de negócio

- O MCP está disponível apenas quando explicitamente habilitado nas configurações do plugin.
- Todas as operações são executadas em nome do usuário Redmine autenticado.
- Escritas via MCP passam pelos modelos do Redmine: callbacks de modelo são executados. Hooks de controller (`controller_issues_*_save`, `controller_journals_edit_post`, etc.) não são invocados pelo MCP.
- A visibilidade de dados segue as regras do Redmine: o usuário não recebe mais do que pode ver na interface web.
- Nomes de ferramentas e prompts usam o formato `<plugin_id>_<name>`, por exemplo `redmine_list_projects`.
- `title` e `description` das ferramentas principais são publicados em inglês para seleção por LLM e **não são localizados** via `en.yml`/`ru.yml` (exceção ao padrão i18n do catálogo de ferramentas MCP). Mensagens de erro e a UI de configurações são localizadas.
- Extensões de outros plugins não criam dependência rígida: se o Redmine MCP estiver ausente, o plugin de terceiros continua funcionando.

## Casos extremos

- Com o MCP desabilitado, todas as requisições a `/mcp` são rejeitadas.
- Quando uma extensão falha, outras extensões e ferramentas principais continuam funcionando.
- Novas ferramentas de extensões ficam disponíveis após reinício do Redmine; o cliente MCP pode precisar reconectar para atualizar a lista de ferramentas.
- No modo stateless, cada requisição HTTP é tratada independentemente; nenhuma sessão é preservada entre requisições.

## Tratamento de erros

- Erros de autenticação e autorização são retornados no nível HTTP.
- Erros de execução de ferramentas são retornados no formato MCP com flag de erro.
- Erros de carga de extensões são registrados em log e não bloqueiam a inicialização do Redmine.

## Arquivos da especificação

| Arquivo | Conteúdo |
|------|---------|
| [console-commands.md](console-commands.md) | Comandos de instalação, verificação e manutenção |
| [01-mcp-server.md](01-mcp-server.md) | Endpoint HTTP, protocolo MCP, transporte |
| [02-authentication.md](02-authentication.md) | Autenticação e controle de acesso |
| [03-core-tools.md](03-core-tools.md) | Ferramentas Redmine integradas |
| [04-extensions.md](04-extensions.md) | API de extensão para outros plugins |
| [05-settings.md](05-settings.md) | Configurações do plugin e logging |
| [mcp_tool_development.md](mcp_tool_development.md) | Requisitos de desenvolvimento de ferramentas MCP (dev-guide) |
| [extension_guide.md](extension_guide.md) | Guia do desenvolvedor de extensões |

## Cenários de teste

1. Após instalação e habilitação do MCP, o cliente executa `initialize` com sucesso e recebe informações do servidor.
2. Um usuário com a permissão Use MCP e uma chave de API válida vê a lista de ferramentas disponíveis para ele.
3. Um usuário sem a permissão Use MCP é negado acesso a `/mcp`.
4. Quando um plugin de extensão é instalado, suas ferramentas estão presentes em `tools/list` para um usuário com as permissões correspondentes.
