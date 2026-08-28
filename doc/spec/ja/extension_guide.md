# Redmine プラグイン向け MCP 拡張

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` により、他の Redmine プラグインは別途 MCP サーバーや `redmine_mcp` 自体の変更なしに、独自の MCP ツールを追加し、必要に応じてリソース、プロンプト、capabilities を登録できます。

## 仕組み

`redmine_mcp` は、サードパーティ Redmine プラグインが `RedmineMcp::ExtensionApi` を通じてツールを登録する共有 MCP Registry を提供します。

典型的な呼び出しフロー:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` はサードパーティプラグインのビジネスロジックを知る必要はありません: プラグインは Extension API を通じて独自のツールを登録します。

## 安定性と後方互換性

`redmine_mcp 1.0.0` 以降、公開 Extension API は安定とみなされます。

公開 API とみなされるのは、このガイドに記載された `RedmineMcp::ExtensionApi` のメソッドと契約のみです。Extension API の一部として文書化されていない `redmine_mcp` の内部クラス、モジュール、メソッドは公開 API ではなく、後方互換性の保証なしに変更される場合があります。

同一 major バージョンの `redmine_mcp` 内では:

- 既存の公開 Extension API メソッドは削除または非互換に変更されない;
- 新しいメソッドとオプションパラメータを追加できる;
- 非推奨メソッドはまず deprecated とマークされ、少なくとも次の major バージョンまで利用可能;
- サードパーティプラグインの更新を要求する変更は、新しい major バージョンでのみリリースされる。

Extension API のすべての変更は `CHANGELOG.md` に記載されます。

サードパーティプラグインは、必要な最小 `redmine_mcp` バージョンを宣言し、アップグレード時に `CHANGELOG.md` を確認することを推奨します。

## クイックスタート

1. 次のいずれかのパスに `mcp.rb` ファイルを作成:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `plugin.id` が `redmine_` で始まる場合は `lib/<plugin.id without the redmine_ prefix>/mcp.rb`
2. `<PluginName>::Mcp` モジュールを定義。
3. `RedmineMcp::ExtensionApi` を extend。
4. `plugin_id` を設定。
5. 最初のツールを登録。

最小の課題スコープ拡張の例:

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

この例では、課題向けツールに推奨される `register_issue_tool` を使用しています。完全なツール契約は [mcp_tool_development.md](mcp_tool_development.md) にあります。

### `Mcp` モジュール名

拡張ファイルは `mcp.rb` です。Zeitwerk はファイル名から `Mcp` を推論するため、`module Mcp` と記述します。

ツールはファイルが require されたときに登録されます。ローダーはモジュール定数名を参照しません。

## 命名

ツールとプロンプトには短い名前を使用:

```ruby
name: 'search_issues'
```

完全な MCP 名は自動生成されます:

```text
redmine_<plugin_id>_<name>
```

ツールでは `name` を `<verb>_<entity>` 形式にすることを推奨します。

推奨動詞:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

操作を別々の明確なツールに分割できる場合、曖昧な `manage_*`、`process_*`、`handle_*` や `action: create | update | delete` のようなパラメータを持つツールは使用しないでください。

例:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

`plugin_id` が既に `redmine_` で始まる場合（例: `redmine_advanced_checklists`）、完全名は引き続き `redmine_<plugin_id>_<name>` に従います: `redmine_redmine_advanced_checklists_<name>`。

リソースには一意の URI を使用（例:

```text
redmine://<plugin_id>/<type>/<id>
```

ツール/プロンプト名とリソース URI は一意である必要があります。重複登録の動作は使用するメソッドに依存します。`register_tool_once` は同じツールを 2 回登録しません。

## ツール登録

### 通常ツール

特定の課題に紐づかない通常の MCP ツールが必要な場合は `register_tool_once` を使用します。

典型的な用途:

- プラグインデータの検索;
- サマリーの返却;
- サーバー側検証または計算。

基本例:

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

完全なツール契約 — `additionalProperties: false`、リスク annotations、`SchemaNormalizer.envelope_output` によるエンベロープ — は [mcp_tool_development.md](mcp_tool_development.md) に記載されています。

### 課題ツール

ツールが `issue_id` を受け取り課題で動作する場合は `register_issue_tool` を使用します。

課題スコープシナリオでは推奨オプションです。理由:

- `Issue.visible(user)` で課題を検索;
- 必要に応じてプロジェクトモジュールをチェック;
- 課題のプロジェクトで指定された権限をチェック;
- 見つかった `issue` をブロックに渡す;
- 課題が利用不可または見つからない場合はエラーを返す。

Permissions セクションも参照してください。

`register_issue_tool` の `module_name` はオプションの Redmine プロジェクトモジュール識別子です。`plugin_id` と一致する必要はありません。設定すると、そのモジュールと宣言された権限を持つ少なくとも 1 つの可視プロジェクトをユーザーが確認できる場合のみ `tools/list` に表示されます。

### ハンドラーの戻り値

ハンドラーはエンベロープなしの成功データハッシュ、または完成したエンベロープ `{ok: true, data: ...}` / `{ok: false, error: ...}` を返します。Registry は `ToolResponse.from_handler_result` で結果を正規化します: プレーンなハッシュは `{ok: true, data: ...}` にラップされます。リストでは、既に `data` と `meta` を含む `paginated_list` の結果を返せます。

エラーには `RedmineMcp::Core::Helpers.error_result`、`mcp_error`、または `{ok: false, error: ...}` を使用します。

## 入力スキーマ

`SchemaNormalizer.normalize_input` はオブジェクトスキーマを正規化しサービス制約を追加しますが、公開パラメータ契約は明示的に記述する必要があります。

主なルール:

- 各パラメータには定義された型が必要;
- 数値 `*_id` フィールドは `type: integer`、`minimum: 1`、discovery path 付き description を使用;
- 有限値セットは説明文だけでなく `enum` / `const` で定義;
- 配列には `items` が必要;
- 相互依存および相互排他フィールドは JSON Schema（`oneOf`、`if/then/else` など）で定義し、description のみにしない;
- 楽観的ロックは `updated_at` ではなく `expected_updated_at` を使用;
- `null` は明示的に文書化された意味（例: フィールドのクリア）でのみ使用;
- 型付きビジネスパラメータの代わりに開いた `fields`、`payload`、`data` を使用しない;
- オブジェクトを JSON 文字列として受け付けない;
- 公開ツールで任意の `file_path` を受け付けない。

完全な `inputSchema` 要件は [mcp_tool_development.md](mcp_tool_development.md) にあります。

## 出力スキーマ

すべての新しいツールには `output_schema` が必要です。

通常の結果には標準エンベロープを使用:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

リストには `SchemaNormalizer.list_envelope_output(item_schema)` を使用します。

既知の安定結果フィールドは明示的に記述する必要があります。応答構造が既知の場合、型付き契約の代わりに `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` を使用しないでください。これらのスキーマは、本当に開いたまたは不安定な構造にのみ許容されます。

完全な `outputSchema` 要件は [mcp_tool_development.md](mcp_tool_development.md) にあります。

## アノテーション

| 操作タイプ | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | 実装に依存 | `false` |
| delete / purge | `false` | `true` | 繰り返しが実際に安全な場合のみ | `false` |
| 外部副作用 | `false` | 依存 | 通常 `false` | `true` |

`destructive` は任意の書き込みではなく、不可逆的なデータ損失を意味します。

`open_world` は Redmine 内に新オブジェクトを作成することではなく、既知の Redmine インストールを超えることを意味します。

Annotations はハンドラー内の権限チェックを置き換えません。

## 権限

`permission` は Registry がツールの可用性と事前チェックに使用しますが、ハンドラー内の特定オブジェクトへのアクセスチェックを置き換えません。

課題スコープツールには、課題の可視性、プロジェクトモジュール、権限をチェックする `register_issue_tool` を使用します。

他のエンティティでは、ハンドラーが見つかったオブジェクトへのアクセスを再チェックする必要があります。

## エラー

標準 MCP エラーコードを使用:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

標準エラーには `error_result` ヘルパーを使用します。
カスタムコードには `mcp_error` を使用します。
楽観的ロックには `conflict_if_stale` を使用します。

ハンドラーはスタックトレースや未処理例外ではなく、構造化エラーを返します。

## 組み込みヘルパー

`RedmineMcp::Core::Helpers` には、重複の代わりに再利用すべき共有ヘルパーが含まれます:

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

次のスキーマフラグメントも利用可能:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

独自ヘルパーを作成する前に、`redmine_mcp` に適切なものが既に存在するか確認してください。

現在のヘルパーセットは `RedmineMcp::Core::Helpers` と [04-extensions.md](04-extensions.md) で確認してください: このリストは主な利用可能機能を示し、ExtensionApi API ドキュメントの代替ではありません。

## 読み取り専用モードと冪等性

変更ツールはグローバル読み取り専用モードを尊重する必要があります:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

繰り返し呼び出しで重複が作成される可能性がある操作では、`idempotency_key` と `RedmineMcp::IdempotencyStore` を使用できます。

`idempotentHint: true` は、すべての副作用を考慮して繰り返し呼び出しが実際に安全な場合のみ許容されます。

## コード構成

`mcp.rb` には主にツール登録（スキーマ、説明、権限、annotations、短いハンドラー）を含めるべきです。

MCP 固有の取得、集約、データ正規化は次に移動できます:

- `mcp_tools.rb`;
- ファイルが大きくなった場合 — `mcp_tools/*.rb`。

通常のビジネスロジックはプラグインの models/services に残し、MCP に依存してはなりません。

必要な操作を実装し、現在のユーザーとして呼び出しをサポートする適切な REST エンドポイントが既にある場合、`internal_request`（読み取り専用 `GET` には `internal_get`）経由で再利用**すべき**です。

これが推奨オプションです: MCP は既存プラグイン API と同じ権限チェック、データ取得、ビジネス動作を使用します。

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

`POST`、`PUT`、`PATCH` には JSON リクエストボディ文字列（エンドポイントがボディを期待しない場合は `nil`）を渡します。クエリパラメータは `params` に入れます。

次の場合は model/service を直接呼び出**すべき**です:

- 適切な REST エンドポイントがない;
- エンドポイントが必要な操作またはデータをサポートしない;
- REST の使用が操作に不要または不適切なレイヤーを作る;
- 共有ビジネスロジックが意図的にサービスに抽出されており、REST エンドポイント自体がそのサービスの薄いラッパーである。

REST と MCP で同じビジネスロジックを別々に実装しないでください。両方のレイヤーに共有ロジックが必要な場合、共通サービスに抽出してください。

## 追加機能

`RedmineMcp::ExtensionApi` は次も提供します:

| メソッド | 使用タイミング |
|---|---|
| `register_resource` | MCP リソースが必要 |
| `register_prompt` | MCP プロンプトが必要 |
| `register_capability` | `redmine_get_server_info` に capability を追加 |
| `extend_tool` | 新規作成ではなく既存ツールを拡張 |
| `on` | ライフサイクルフックが必要 |
| `internal_request` | 現在のユーザーとして Redmine またはプラグイン REST エンドポイントをプロセス内で呼び出す（`method`、`path`、オプションで `params` と `body`） |
| `internal_get` | `internal_request(method: 'GET', ...)` の短縮形 |
| `internal_request_error?` | プロセス内 REST 結果が MCP エラーエンベロープか確認 |

`plugin_id` はモジュール先頭で 1 回設定します。拡張自体が登録を行う場合、ツール登録前に `mcp_extension_enabled?` をチェック**すべき**です。標準 `ExtensionLoader` も無効化された拡張の `mcp.rb` を読み込みません。

### 既存ツールの拡張

別ツールが適さない場合のみ `extend_tool` を使用します。

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

`before` はハンドラー前、`after` は後に実行されます。`extra_params` は入力スキーマに追加されます。パラメータ名はベースツールまたはそのツールの他の拡張と競合してはなりません。

`redmine_mcp` がコアツールを登録する前に、プラグインの `after_initialize` から拡張が require される場合、コアツール（例: `redmine_get_issue`）の `extend_tool` は初期化完了まで延期 — ネストした `Rails.application.config.after_initialize` を使用し、先に `Registry.instance.tool(...)` をチェックしてください。

## 拡張の読み込みと無効化

`redmine_mcp` は Redmine 起動時にサポートされるパスで拡張ファイルを自動検索します。

`redmine_mcp` の存在確認は `mcp.rb` エントリポイント（通常 `lib/<plugin>.rb` またはプラグインローダーの `after_initialize`）でのみ行ってください。`mcp.rb` からのみ読み込まれるファイル（`mcp_tools.rb`、`mcp_tools/*.rb` など）では同じチェックを繰り返す必要はありません。

サードパーティプラグインから `ExtensionLoader.load_plugin_extension` を手動で呼び出さないでください: `ExtensionLoader` は `redmine_mcp` の内部メカニズムです。条件付き `require` で自分の `mcp.rb` を読み込めば十分です。プラグイン読み込み順序でその `require` が実行されなかった場合、標準 `redmine_mcp` の `ExtensionLoader` がフォールバックとして動作します。

エントリポイント例:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

拡張は次の場合のみ登録されます:

- `redmine_mcp` 設定で MCP が有効;
- `mcp.rb` ファイルが見つかる;
- `mcp.rb` 内の `<PluginName>::Mcp` モジュールが正しく読み込まれる;
- `MCP extensions` リストで拡張が無効化されていない。

新しい拡張のインストールまたは `mcp.rb` 変更後、通常 Redmine の再起動が必要です。その後 MCP クライアントは再接続が必要な場合があります。Cursor などのアプリケーションでは、MCP サーバーのリロードだけでは新しいツールを取得できない場合があります: 表示されない場合はアプリケーションを完全に再起動してください。

## 拡張の検証

実装後、ハンドラーだけでなく次も確認するため、実際の MCP 呼び出しでツールを検証してください:

- `tools/list` への登録;
- 入力スキーマ;
- 権限;
- 出力エンベロープ;
- エラー。

Redmine ログでツール登録と拡張読み込みエラーを確認してください。

各新しいツールについて、最低限:

- 1 つの成功スキーマシナリオ;
- 1 つの否定スキーマシナリオ。

詳細な自動テスト要件は [mcp_tool_development.md](mcp_tool_development.md)（§13）にあります。

### 拡張の自動テスト

プラグイン MCP 拡張の自動テストは、ハンドラーの直接呼び出しだけでなく、**完全な Registry パス**（`inputSchema` 検証 → permission → handler → `{ok, data | error}` エンベロープ）を実行**しなければなりません**。

`redmine_mcp` がインストールまたは読み込まれていない場合、テストクラスはファイル読み込み時に失敗せず、シナリオを**スキップ**します（`setup` で `skip`）:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

テスト `setup` で `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` を呼び出して `Registry` にツールを登録することは許容されます。プラグイン本番コードから `ExtensionLoader` を呼び出さないでください（「拡張の読み込みと無効化」参照）。

公開 `outputSchema`（`mcp_tool_development.md` §7.1）と実際の応答を比較するには `json_schemer` を使用 — `RedmineMcp::InputValidator` が入力スキーマに適用するのと同じライブラリです。

テストヘルパー内での `json_schemer` の遅延読み込みは許容されます。環境にライブラリがない場合、チェックは明示的にスキップし、オプション依存関係でプラグインテストが失敗しないようにしてください。

読み取り専用拡張ツールの最小自動テスト:

- `outputSchema` 検証付きの成功 Registry 呼び出し 1 件;
- `inputSchema` によって拒否される否定呼び出し 1 件（例: `oneOf`、enum、`maxItems` 違反）;
- 必要に応じて — ハンドラーレベルの別サーバー検証テスト（スキーマはサーバー側チェックを置き換えない; `mcp_tool_development.md` §3.4 参照）。

## トラブルシューティング

| 問題 | 確認事項 |
|---|---|
| 拡張が読み込まれない | `mcp.rb` パス、モジュール名 `Mcp`、MCP が有効か、Rails ログ |
| ツール/リソース/プロンプトが表示されない | `plugin_id` が設定されているか、拡張が無効化されていないか、名前または URI の衝突、ユーザーが必要権限を持つか |
| 編集後に変更が反映されない | Redmine 再起動; Cursor などでは MCP サーバーリロードでは新ツールを取得できない場合がある — アプリケーションを完全再起動 |
| `extend_tool` が動作しない | ベースツールが登録されているか、`extra_params` が既存スキーマと競合していないか |

### マージ前チェックリスト

- [ ] ツールに `title`、`description`、`input_schema`、`output_schema`、`permission`、`annotations` がある。
- [ ] 各 `*_id` に discovery path がある。
- [ ] description、output_schema、実際の応答が一致している。
- [ ] 変更ツールが読み取り専用モードを尊重している。
- [ ] MCP 固有ロジックが lambda/handler 内に肥大化していない。
- [ ] 共有ヘルパーは `redmine_mcp` から再利用され、コピーされていない。
- [ ] 最低 1 つの成功と 1 つの否定スキーマシナリオが実行された。
