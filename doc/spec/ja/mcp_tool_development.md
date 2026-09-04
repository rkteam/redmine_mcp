# Redmine MCP ツール開発要件

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**ステータス:** 開発者ガイド（dev-guide）。behavioral プラグイン SPEC ではない  
**バージョン:** 1.6  
**日付:** 2026-08-20  
**適用範囲:** すべての新規 Redmine MCP ツールおよび既存ツールの大幅な変更  
**ベース MCP バージョン:** Protocol Revision `2025-11-25`

コアツールの behavioral 契約は `03-core-tools.md` および関連 SPEC に記載されている。本ドキュメントはツールの設計と実装のルールを定義する。

---

## 1. 本ドキュメントの目的

本ドキュメントは、Redmine 向け MCP ツールの設計、実装、記述、テスト、公開に関する統一要件を定める。アーキテクチャ実装パターンは付録 A に集約し、本文の必須要件と混在させない。

本標準の目標は、ツールを次のようにすることである:

- 言語モデルによる選択が明確であること;
- 自動呼び出し時に安全であること;
- MCP クライアントにとって予測可能であること;
- 厳密に検証されること;
- 保守しやすく後方互換であること;
- 繰り返し呼び出し、モデルエラー、部分的に入力された引数に耐性があること。

要件は現在の Redmine MCP の監査を踏まえて策定されている。本ドキュメント作成時点で、サーバーは 46 個のツールを公開している。契約には `type` のないパラメータ、`enum` の代わりに許可値の文字列リスト、汎用 `manage_*` ツール、`outputSchema` の欠如が確認された。

---

## 2. 義務用語

本ドキュメントでは次のレベルを使用する:

- **MUST / MUST** — 必須要件。違反はマージをブロックする。
- **MUST NOT / FORBIDDEN** — 必須禁止。
- **SHOULD / SHOULD** — デフォルトの要件。逸脱はマージリクエストで正当化しなければならない。
- **MAY / MAY** — 許容される選択肢。

すべてのツールに必須ではないアーキテクチャおよび実装パターンは **付録 A** に集約されている。特定のツールで意識的に採用しない場合、マージをブロックしない。

---

## 3. コア設計原則

### 3.1. 1 ツール — 1 つの明確なアクション

ツールは 1 つの原子的なユーザー意図を表さなければならない（MUST）。

良い例:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

悪い例:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

`action: create | update | delete | list` のようなパラメータを持つツールは、次の場合に禁止（FORBIDDEN）される:

- 異なる必須引数を必要とする;
- 異なるリスクレベルを持つ;
- 異なる MCP アノテーションを持つべきである;
- 異なるデータ構造を返す;
- 異なる Redmine 権限を必要とする。

例外は、すべてのバリアントが同じリスクと単一の契約を持つ意味的に均質な操作に限り許容される。例外は明示的に正当化しなければならない。

### 3.2. 読み取り、追加、更新、削除は分離する

1 つのツールで次を組み合わせることは禁止（FORBIDDEN）される:

- 読み取り専用操作と書き込み操作;
- 追加操作と削除操作;
- 通常ユーザー操作と管理操作;
- ローカル Redmine 操作と外部へのデータ送信。

たとえば、`list/create/delete relation` は 3 つの別ツールでなければならない。

### 3.3. 契約はサーバー実装の利便性より重要

ハンドラをそのように実装する方が容易だからという理由だけで、内部 Ruby/Python/REST メソッドの構造を直接公開してはならない。

MCP 契約はモデルとクライアント向けに設計され、サーバー内部のアダプタが Redmine API 形式に変換する。

プラグインまたは Redmine の内部技術値は、意味のある外部契約の一部でない場合、正規化しなければならない（MUST）。

不必要に公開してはならないもの:

- Ruby/Rails クラス名と STI 型;
- MCP が入力で別の値を既に使用している場合の内部 enum 名;
- ロケール依存の日付;
- MCP が既に正規形式を定義している場合の同一フィールドの REST 固有表現;
- MCP が既に正規化された値を使用している場合の技術名。

例: 入力フィルタ `type` — `contact` / `company`; 応答でも `contact` / `company` とし、`Clientdesk::Contact` / `Clientdesk::Company` ではない。シリアライザが STI クラスまたはローカライズされた日付を返す場合、MCP アダプタは値を公開スキーマに合わせなければならない（MUST）。

### 3.4. サーバーはモデルを信頼しない

すべての引数は信頼できないものとみなす。サーバーは次を再確認しなければならない（MUST）:

- 型;
- 範囲;
- フィールド間の依存関係;
- 現在のユーザーの権限;
- オブジェクトのプロジェクト所属;
- 特定ワークフローでの値の利用可否;
- Redmine の制約;
- 現在のオブジェクト状態で操作が許可されるか。

JSON Schema、説明、アノテーション、クライアント確認はサーバー側検証に代わるものではない。

---

## 4. ツール命名

### 4.1. 名前の形式

公開されるすべてのツール名は `redmine_` で始まらなければならない（MUST）。

`redmine_mcp` プラグインのコアツールには短いプレフィックス `redmine_` を使用する:

```text
redmine_<verb>_<entity>
```

サードパーティプラグインのツールでは、完全名は `redmine_` で始まらなければならない（MUST）:

- `redmine_<plugin_id>_<verb>_<entity>`.

要件:

- `lower_snake_case` のみ;
- サードパーティプラグイン拡張を含むすべてのツールで `redmine_` プレフィックスは必須;
- サーバー内で名前は一意;
- 内部制限 — 64 文字以内;
- 非推奨化手順なしに名前を変更しない。

例:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. 許可される動詞

推奨動詞:

| 動詞 | 目的 |
|---|---|
| `get` | 正確な識別子で 1 オブジェクトを取得 |
| `list` | 構造化フィルタでコレクションを取得 |
| `search` | テキストまたは全文検索を実行 |
| `create` | オブジェクトを作成 |
| `update` | 既存オブジェクトを変更 |
| `set` | 特定フィールドまたはフラグを指定値に設定 |
| `delete` | オブジェクトを削除 |
| `add` | 既存オブジェクトにリレーションまたはメンバーを追加 |
| `remove` | メインオブジェクトを削除せずリレーションを除去 |
| `copy` | コピーを作成 |
| `upload` | ファイルをアップロード |
| `download` | ファイル内容を取得 |
| `send` | 外部受信者にメッセージまたはデータを送信 |
| `summarize` | サーバー側集約レポートを構築 |

曖昧な動詞（`manage`、`process`、`handle`、`execute`、`do`）は使用しない — §3.1 参照。

動詞は操作の実際の意味に一致しなければならない（MUST）。ツールがブールフラグを切り替える場合（`enabled: true | false` のようなパラメータ）、1 つの値のみを暗示する動詞ではなく `set` で命名すべき（SHOULD）。

悪い例:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` は `enabled = true` のみを暗示するが、パラメータは `false` も許可する。名前が実際のアクションと一致しない。

良い例:

```text
redmine_advanced_search_set_semantic_index_enabled
```

`set_*` という名前は、操作が渡された値にフラグを設定することを正確に反映する。

### 4.3. 識別子パラメータ名

パラメータ名は実際の型と一致しなければならない（MUST）:

- `issue_id` — 整数 ID のみ;
- `project_id` — 整数 ID のみ;
- `project_identifier` — Redmine 文字列識別子;
- `project` — 両方の表現を意図的に許可し、参照として文書化された文字列。

`*_id` という名前のパラメータは文字列識別子や `"me"` 値を受け付けられない。

数値 ID には `minimum: 1` と意味のある `description` が必須（MUST）。`minimum` なしの `"Issue id"` のような表現は禁止（FORBIDDEN）。

悪い例:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

良い例:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

プロジェクトの推奨統一オプションは、数値 ID（文字列として）または文字列識別子を受け付けるパラメータ `project` である:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

`examples` 配列（§6.15）はモデルに許可される値形式の両方を示し、誤入力の可能性を減らす。

### 4.4. 楽観的ロック: `expected_updated_at`

既知のオブジェクトタイムスタンプを渡して古い変更を拒否するパラメータは、すべてのコアツールおよび拡張で `expected_updated_at` と命名しなければならない（MUST）。

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

この意味での `updated_at` という名前は禁止（FORBIDDEN）: 「新しい変更時刻」のように見えるが、実際は楽観的ロック用の値である。

悪い例（チェックリストおよび任意の拡張）:

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

良い例:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

実際のオブジェクト変更時刻を報告する応答フィールドは引き続き `updated_at` / `updated_on` と命名してよい（MAY） — 混乱はロック入力パラメータでのみ生じる。

競合時の規範的動作は付録 A.2 に記載。

---

## 5. `title` と `description`

### 5.1. `title`

`title` は技術名のコピーではなく、短い人間が読める名前でなければならない（MUST）。

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. ツール説明

`description` は次の重要な質問に簡潔に答えなければならない（MUST）:

1. ツールは何をし、どのオブジェクトを読み取るまたは変更するか?
2. デフォルトで含まれないものは何か、どう要求するか?
3. 重大な副作用はあるか?
4. ID または許可値が不明な場合、どの事前ツールを呼び出すか?

説明は簡潔で読みやすくなければならない（MUST）。すべてのフィールドとすべての include オプションを列挙する長い半ページの段落にすることは禁止（FORBIDDEN）: 過負荷の説明は短い構造化された説明よりモデルにとって読みにくい。

短い数行またはリストで書き、連続テキストにしない（SHOULD）。デフォルトとその変更方法は簡潔に示す。

良い例:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

悪い例 — 短すぎ、結果とデフォルト動作を説明しない:

```text
Gets issue.
```

悪い例 — 過負荷、すべてのフィールドを列挙する長い段落:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. 他ツールへの参照

説明、パラメータ説明、またはサーバー指示が別のツールを参照する場合、プレフィックスなしの短い `name` ではなく、`tools/list` の完全な登録名を使用しなければならない（MUST）。

悪い例:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

良い例:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

短い名前はプラグイン間で曖昧であり、モデルにプレフィックスを推測させる。拡張では特に重要: `redmine_advanced_search_` プレフィックスなしの `semantic_search_issues` は存在しないコアツールと混同されやすい。

### 5.2.2. 返却結果の説明

説明はツール結果を簡潔に説明し、モデルが 1 回の呼び出しで十分か次のツールが必要かを理解できるようにしなければならない（MUST）。

結果の説明は次を示すべきである:

- 1 オブジェクト、コレクション、集約、変更確認、またはリソース参照のいずれが返されるか;
- デフォルトで含まれる関連データ;
- 明示的パラメータなしでは含まれない大きなまたは機密データ;
- ページネーションの有無と標準制限;
- 書き込みツールが完全な更新オブジェクトを返すか、識別子、URL、変更時刻のみか;
- 一括操作で部分的成功が可能か。

読み取りの例:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

リストの例:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

書き込みの例:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

説明と `outputSchema` の関係 — §7.1 および §7.1.1 参照。リストが既にフィールドを返す場合、説明はそのフィールドのためだけにモデルを `get_*` に送ってはならない（MUST NOT）。

### 5.3. 説明はスキーマに代わらない

制約をテキストのみで設定することは禁止（FORBIDDEN）:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

`enum`、`const`、範囲、条件付きスキーマを使用する。

相互排他フィールドにも同様に適用される。`description` が「`user_id` または `group_id` のいずれか 1 つ」と言うが `required` に共通フィールドのみが含まれる場合 — スキーマとテキストが乖離する。制約は `inputSchema` で形式化しなければならない（MUST）（§6.12）。

### 5.4. 予測可能な選択

類似ツールの説明は差異を明示的に説明しなければならない。

たとえば:

- `redmine_list_project_members` — 特定プロジェクトのメンバーとそのロール;
- `redmine_admin_list_users` — インストール全体のユーザーリスト、管理権限が必要。

### 5.5. サーバーレベル指示

サーバーはツール間の関係とワークフロールールを説明する簡潔な一般指示を公開してよい（MAY）。

指示は個別の説明にないコンテキストを追加し、完全名でツールを参照すべき（§5.2.1）。例:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

禁止（FORBIDDEN）:

- サーバー指示にすべてのツールの説明を繰り返すこと;
- サーバーに無関係な一般的なモデル動作指示をそこに置くこと;
- 簡潔なルーティングルールの代わりに長いガイドを書くこと;
- マーケティング文を使用すること;
- プレフィックスなしの短い名前でツールを参照すること（`redmine_list_projects` の代わりに `list_projects`）。

### 5.6. 開発前に Redmine REST API を調査する

ツールを新規作成または大幅に変更する前に、開発者はドキュメント調査を行うべき（SHOULD）。既存 MCP コード、開発者の記憶、単一 HTTP リクエスト例のみから契約を設計することは推奨されない。

調査すべき内容（SHOULD）:

1. Redmine REST API メインページ: 一般認証、ページネーション、`include`、カスタムフィールド、ファイル、検証エラールール。
2. 対応リソースの個別 API ページ（Issues、Time Entries、Versions、Wiki Pages、Project Memberships など）。
3. API 変更履歴セクションとサポート Redmine バージョンの変更。
4. MCP が使用する実際の Redmine バージョンと最小サポートバージョン。
5. ツールがプラグインエンティティまたはフィールドを扱う場合の Redmine プラグインの REST API とソースコード。拡張ツールを公開する前に、ソースシリアライザ / サービス / REST エンドポイントと、各結果形式（list と get の両方が公開される場合は両方）の少なくとも 1 つの実際の成功応答を検証しなければならない（MUST）。
6. 対象インストールの実際の権限、ワークフロー、有効モジュール、トラッカー、カスタムフィールド、制約。
7. 重複または競合する契約を作らないよう、既に公開されている MCP ツール。

メインページ `https://www.redmine.org/projects/redmine/wiki/rest_api` は入り口だが、特定ツールには通常不十分である。対応リソースページに移動し、操作、クエリパラメータ、`include`、リクエストフィールド、応答構造、エラーコード、バージョン制約を検証すべき（SHOULD）。

### 5.7. API カバレッジレポート

新規ツールを実装する前に、開発者はマージリクエストに簡潔な API カバレッジ表を添付すべき（SHOULD）:

| フィールド | 内容 |
|---|---|
| Redmine resource | リソースと公式 API ページへのリンク |
| Endpoint | HTTP メソッドとパス |
| Supported since | 最小 Redmine バージョン |
| Request parameters | 文書化されたすべてのリクエストパラメータ |
| Query filters | 文書化されたすべてのフィルタと特殊値 |
| Include values | 許可される関連データ |
| Required/defaults | 必須フィールドとデフォルト値 |
| Response | 主要フィールドと応答バリアント |
| Errors | HTTP コードとエラー構造 |
| Permissions | 必要な権限となりすましの詳細 |
| MCP exposure | MCP で公開されるパラメータ |
| Intentionally omitted | 公開されないパラメータとその理由 |
| Plugin/version differences | プラグインとサポートバージョンの差異 |

表の目的は必ずしもすべての Redmine パラメータを MCP に公開することではない。パラメータを偶然見落とさず、公開判断を意識的に行うことが目的である。

Redmine パラメータを MCP から除外できる場合:

- 危険または管理的である;
- 別のより明確なツールと重複する;
- サポートバージョン間で不安定である;
- 曖昧なスキーマを生む;
- 対象ユーザーシナリオに不要である;
- 過度に大きな応答を生む。

各実質的な除外は `Intentionally omitted` に簡潔な正当化とともに記録する。

### 5.8. ツールを開発する AI エージェント向け指示

AI エージェントがツールを作成または変更する場合、作業指示は本ドキュメントを参照すべき（SHOULD）: API 調査（§5.6–5.7）、契約（§3–§8）、テスト（§13）、チェックリスト（§14）。

推奨テキスト:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. `inputSchema` 要件

### 6.1. 基本構造

すべてのツールは有効な JSON Schema を持たなければならない（MUST）。

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

引数のないツール:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. 未文書化プロパティの禁止

トップレベルおよびすべてのネストオブジェクトで:

```json
"additionalProperties": false
```

オープン辞書は意識的にのみ許可される。その場合、値スキーマを明示的に設定する:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. 各パラメータの型

すべてのプロパティには `type`、`$ref`、または `oneOf` / `anyOf` / `allOf` 合成が含まれなければならない（MUST）。

禁止（FORBIDDEN）:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. 必須パラメータ

`required` 配列は最小限実行可能な呼び出しを反映しなければならない。

パラメータなしでは操作が不可能な場合、そのパラメータは `required` に含まれなければならない（MUST）。

たとえば、ファイルアップロードには少なくとも次が必要:

```json
"required": ["project", "filename", "content_base64"]
```

削除の `confirm=true` チェックはサーバーで実行される（§3.4）。フィールドが `required` にあっても同様。

### 6.5. 列挙

有限の値集合には `enum` または `const` を使用しなければならない（MUST）（説明のテキストのみでは不可 — §5.3 参照）。

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. 文字列

文字列には適切な制約が必要:

- 非空値には `minLength`;
- Redmine 制約または内部制限に応じた `maxLength`;
- 形式が厳密に定義されている場合は `pattern`;
- 標準形式が適用される場合は `format`。

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

スキーマの `format` 制約はサーバー側検証に代わらない（§3.4）。

### 6.7. 数値

数値パラメータには合理的な境界を設定しなければならない（MUST）。

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

`default` 値は契約とドキュメントの一部である。サーバーはクライアントが独自にデフォルトを代入することを前提としてはならない。

### 6.8. 配列

すべての配列には `items` が必要（MUST）。

必要に応じて設定:

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

要素スキーマなしの `entries: array` のような配列は禁止（FORBIDDEN）。

### 6.9. ネストオブジェクト

すべてのネストオブジェクトは完全に記述する。

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

### 6.10. 「オブジェクトまたは JSON 文字列」は受け付けない

1 つのパラメータを「オブジェクトまたは JSON 文字列」として記述することは禁止（FORBIDDEN）。

MCP は既に構造化 JSON を渡す。ツールはオブジェクトを受け付け、サーバーが再度パースする文字列ではない。

### 6.11. 汎用 `fields` と `extra_fields`

`fields`、`extra_fields`、`payload`、`data` および同様のオープンオブジェクトパラメータは、主要ビジネス操作で禁止（FORBIDDEN）。

課題フィールドは意味のある `description`（§6.14）と、有用な場合は `examples`（§6.15）とともに明示的に列挙しなければならない:

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

まれに使用されるフィールドは、厳密に記述された `custom_fields` を通じて渡してよい。

### 6.12. 相互依存フィールド

ツールの分割を優先する。分割が不可能な場合、依存関係は次で形式化する:

- `dependentRequired`;
- `if` / `then` / `else`;
- 相互排他ブランチを持つ `oneOf`。

`description` のテキスト（「…のいずれか 1 つ」）はスキーマに代わらない（§5.3）。

典型的なケース — 「2 フィールドのいずれか 1 つ」。悪い例: `required` に共通フィールドのみ、XOR は散文に残る:

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

このスキーマは `user_id`/`group_id` なしの呼び出しと、両フィールド同時の呼び出しを許可する。

良い例 — 共通 `required` プラストップレベル `oneOf`:

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

サーバー側検証（§3.4）は両方の不正バリアントを拒否しなければならない（MUST）。スキーマはクライアントとモデルが呼び出し前に制約を見られるために必要。

選択した構成がサポートされる MCP クライアントおよび SDK と互換性があることを検証しなければならない。

### 6.13. `null` 値フィールドと値のクリア

`null` は別途文書化された意味がある場合のみ許可される（たとえば「期限日をクリア」「担当者を解除」）。

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

空文字列を `null` の暗黙的同等物として使用しない。

オプションフィールド（期限日、担当者など）を設定する `set_*` ツールでは、契約はクリア方法を明示的に決定しなければならない（MUST）。3 つのオプションが許可される — 優先順:

1. **同じツールが `null` を受け付ける**（推奨）、上記のとおり: 1 つの意図「設定またはクリア」。
2. **別の clear/unassign ツール**、API または UX が操作をより適切に分離する場合、たとえば `redmine_advanced_search_clear_saved_query` と `redmine_advanced_search_unassign_search_owner`。
3. **明示的拒否**: MCP 経由のクリアがサポートされない場合、ツール `description` および/またはパラメータ説明に明記しなければならない（MUST）。説明なしの「null なしの string/integer のみ」という黙示的契約は禁止（FORBIDDEN） — モデルはクリアが不可能と誤解するか `""` / `0` を渡そうとする。

悪い例 — 期限日は設定できるがクリアできず、どこにも記載なし:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. パラメータ説明

`inputSchema.properties` のすべてのパラメータには意味のある `description` が必要（MUST）。`description` のないパラメータは禁止（FORBIDDEN）。拡張（チェックリスト項目 `done`、`sort_order`、`due_date`、ID フィールドなど）や明確な `enum` を持つオプションフィールドも含む。

「Filter by tracker ID」「Tracker id」「Issue id」のような説明は不十分: 許可値の取得元と制約を示さない。

識別子パラメータの説明は、許可値に使用するツールまたは応答フィールド（完全名 — §5.2.1; ディスカバリ — §6.16）を示し、重要な制約（ワークフロー、権限、プロジェクト所属）に言及しなければならない（MUST）。

悪い例:

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

良い例:

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

制約を記載した良い例:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

パラメータ説明はスキーマ（§5.3）およびサーバー側検証（§3.4）に代わらない。

### 6.15. 値の例（`examples`）

値形式が自明でない、または複数の表現を許可するパラメータには `examples` を追加すべき（SHOULD） — 標準 JSON Schema 配列キー。例はモデルが正しい値を入力するのに役立ち、参照パラメータ、識別子、日付、enum 的な文字列に特に有用。

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

要件:

- `examples` の値はパラメータスキーマ自体に対して有効でなければならない（MUST）;
- `examples` は形式を示すが `enum`、範囲、その他の制約に代わらない（§5.3、§6.5）;
- `enum` を持つパラメータでは、別途 `examples` は通常冗長。

MCP クライアントまたは SDK がスキーマ内の `examples` をサポートしない場合、同じ意味で拡張キー `x-examples` を使用してよい（MAY）。

### 6.16. ID パラメータのディスカバリパス

モデルが推測できない `*_id` 形式のパラメータには、明示的なディスカバリパスが必要（MUST）: 別の read/list ツール、またはパラメータ `description`（§6.14）で参照される別の read ツール応答のフィールド。

許可されるオプション（ツールセットでの優先順）:

1. **別の list/ディスカバリツール** — `redmine_list_issue_statuses`、`redmine_list_roles`、`redmine_advanced_search_list_search_providers`。
2. **get/list 応答内のオプション** — たとえば `redmine_advanced_search_semantic_search_issues` 応答の `id` と `name` を持つ provider 配列。その場合、説明は完全なツール名でその応答フィールドを参照しなければならない（MUST）。
3. **スキーマ内の安定した enum**、値集合が固定で小さい場合。

上記のいずれも満たさない `status_id` / `role_ids` / 同様の書き込みツールの公開は禁止（FORBIDDEN）: モデルは ID を推測せざるを得ない。

悪い例 — ディスカバリなしの書き込み:

- `provider_id` を持つ `redmine_advanced_search_set_search_provider` が存在;
- `redmine_advanced_search_list_search_providers` がない;
- `semantic_search_issues` は現在のプロバイダ名（`provider: "…"`）のみを返し、許可値とその `id` のリストなし。

この場合 `"Search provider ID."` のような説明は不十分。list ツールを追加するか、get 応答にプロバイダオプションを含め、次のように記述する:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

このルールはコアと拡張（§18）に適用される。

---

## 7. `outputSchema` と結果要件

### 7.1. 出力スキーマ

新規ツールは `outputSchema` を公開しなければならない（MUST）。スキーマはエンベロープ形状 `{ ok, data | error }` のみでなく、安定した公開応答契約を記述する。

`description` が名前付きフィールドまたはネスト構造を返すと主張する場合、`outputSchema` はそれらのフィールドを形式化しなければならない（MUST）。トップレベル `data` / `items` を「任意オブジェクト」に限定してはならない。

悪い例: 説明が `query`、`results`、スニペット、添付抜粋を列挙するが、`outputSchema` が欠如しているか `items` を `{ "type": "object", "additionalProperties": true }` のみで記述。

各安定結果フィールドについて:

- 型を指定しなければならない（MUST）;
- 保証されるフィールドは `required` に含まれなければならない（MUST）;
- 有限値集合は `enum` または `const` で設定しなければならない（MUST）;
- サーバーが対応形式を保証する場合、日付には `format: date` または `date-time` が必要（MUST）;
- 数値 ID は統一型を維持しなければならない（MUST）;
- nullable と optional は異なる契約: フィールドが常に返されるが値がない場合がありうるなら、`required` で `null` を許可しなければならない;
- 数値ビジネス値には、フィールド名から自明でない場合、単位を指定しなければならない（MUST）;
- 金額値には明確な意味が必要（MUST）: 主要/補助単位と通貨の決定方法。

既知の安定結果フィールドの記述の代わりに `additionalProperties: true` を使用してはならない（MUST NOT）。後方互換性または真に拡張可能な構造では許可されるが、そのようなオブジェクト内の既知ビジネスフィールドは依然として `properties` に列挙し、保証されるものは `required` に含める。

リストツールでは、`items` 要素はモデルが識別、フィルタリング、後続ツール呼び出しに必要な少なくともフィールドを記述しなければならない（MUST）。

良い例 — `data` の型付けフラグメント（完全な成功/エラーエンベロープ — §7.2 および §12）:

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

結果は次を返すべき（SHOULD）:

- `structuredContent` — クライアントが安定構造を必要とする場合の機械可読オブジェクト;
- テキスト `content` — 後方互換性と人間向けの簡潔な表現。

### 7.1.1. 公開契約の一貫性

ツールを完成させる前に、開発者は 3 つの表現を比較しなければならない（MUST）:

1. 実際のハンドラ / REST / サービス応答;
2. ツール `description`;
3. `outputSchema`。

これらは互いに矛盾してはならない。

説明がフィールドが常に返されると言う場合、`outputSchema` で `required` でなければならない。

スキーマが `enum` / `const` / `format` を設定する場合、実際のシリアライザは値をその契約に正規化しなければならない（MUST）。`format: date` を公開しながらロケール形式文字列を約束することはできない。

リストが既にデータを返す場合、説明は同じデータのためだけにモデルを get ツールに送ってはならない（MUST NOT）。

結果のビジネス不変条件は、ツール名から推論するだけでなく、スキーマで `const`、`enum`、`required`、または条件付きスキーマで反映しなければならない（MUST）。例: サブスクリプションツールが定義上 `subscription` 型の製品のみを返す場合、`product_type` は不可能な値を持つ `enum` ではなく `const: "subscription"` でなければならない。

### 7.2. 統一エンベロープ

推奨成功結果:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

エラー:

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

エラー時は追加で設定:

```json
"isError": true
```

`outputSchema` が公開され、エラーも `structuredContent` で返される場合、スキーマは成功とエラーの両ブランチを記述しなければならない（MUST）。成功のみのスキーマを公開し、互換性のない構造化エラーオブジェクトを返すことはできない。代替: ツール実行エラー時は `isError: true` のテキスト `content` のみを返し、`structuredContent` を返さない。推奨オプション — 2 ブランチを持つ統一型付きエンベロープ。

### 7.3. フィールド安定性

出力フィールドは公開契約である。禁止（FORBIDDEN）:

- メジャー変更なしのフィールド型変更;
- 非推奨期間なしのフィールド名変更;
- オブジェクトと配列を状況によって返す;
- ID を数値と文字列を状況によって返す;
- 無制限の未処理 Redmine API 応答を返す。

### 7.4. 単一オブジェクト結果

推奨形式:

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

### 7.5. リスト結果

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

`items` 要素スキーマは §7.1 に従う: 識別子、ルーティングフィールド、安定ビジネスフィールドを明示的に記述。唯一の要素説明として空の `{ "type": "object", "additionalProperties": true }` は禁止（FORBIDDEN）。

### 7.6. 最小限必要なボリューム

リスト/検索ツールはデフォルトで簡潔なレコードを返さなければならない。完全な説明、ジャーナル、添付、大きなテキストフィールドは別の `get_*` で取得すべき。

これによりトークン、レイテンシ、過剰な機密データ渡しのリスクが減る。

### 7.7. 機密データ

明示的な必要がない限り、結果に含めてはならない:

- API トークン;
- Authorization ヘッダー;
- クッキー;
- サーバーファイルシステムパス;
- 内部スタックトレース;
- パスワードとシークレット;
- 現在のユーザーに利用不可の Redmine フィールド;
- 別途権限なしのプライベートノート。

---

## 8. MCP アノテーション

アノテーションはクライアント向けのヒントであり、認可または保護メカニズムではない。

### 8.1. 値マトリックス

| 操作タイプ | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Redmine データの get/find/list | `true` | `false` | `true` | `false` |
| 課題/バージョン/チェックリストの作成 | `false` | `false` | `false` | `false` |
| コメント/ウォッチャー/リレーションの追加 | `false` | `false` | `false` | `false` |
| フィールド変更、名前変更、フラグ設定（`update`、`rename`、`set`） | `false` | `false` | 実装依存 | `false` |
| 削除、クリア、リセット（`delete`、`purge`、`reset`） | `false` | `true` | 保証されたべき等性がある場合のみ | `false` |
| 外部受信者へのメール送信 | `false` | `false` | `false` | `true` |
| 任意 URL / 外部システムへのアクセス | 依存 | 依存 | 依存 | `true` |

### 8.2. ルール

- `readOnlyHint: true` はツールが状態を変更せず副作用を起こさない場合のみ。
- `destructiveHint` は書き込みの事実ではなく、不可逆的なデータ損失または破壊を記述する。`destructiveHint: true` は不可逆操作 — `delete`、`purge`、`reset`、フィールドまたはリレーションの完全クリア — にのみ設定すべき（SHOULD）。
- 通常の `update`、`rename`、`set` は破壊的ではない: これらでは `destructiveHint: false`。たとえば `update_checklist_title` または `rename_wiki_page` は通常の更新であり破壊ではなく、破壊的アノテーションは誤り。
- `idempotentHint: true` は繰り返し呼び出しが真に安全な場合のみ。テストで確認すべき（SHOULD）。
- `openWorldHint` は新しいオブジェクトが作成されるかではなく、ツールがオープンで以前未知の外部世界にアクセスするかを記述する。1 つの設定済み Redmine インストールとの作業は閉じた世界: `openWorldHint: false`。
- したがって `create_issue`、`create_time_entry`、および Redmine 内の他の書き込みツールは、新しいオブジェクトを作成しても `openWorldHint: false`。既知システムでのオブジェクト作成は世界をオープンにしない。
- `openWorldHint: true` は受信者またはデータソースが既知システムに限定されない場合のみ: 外部受信者へのメール送信、任意 HTTP リクエスト、外部サービスへのアクセス。
- `openWorldHint` の値は各ツールで意識的に設定すべき（SHOULD）。デフォルトでコピーしない: ツールが実際に Redmine インストールを超えるか検証する。
- 1 つのアノテーションセットをすべての書き込みツールにコピーできない。

### 8.3. Redmine 副作用

べき等性を評価する際、最終フィールドだけでなく次も考慮する:

- ジャーナルエントリ作成;
- 通知送信;
- Webhook;
- 監査ログ;
- 繰り返しファイルアップロード;
- 繰り返しリレーション作成;
- 繰り返し作業時間記録。

繰り返し呼び出しが追加レコードまたは通知を作成する場合、ツールはべき等ではない。

---

## 9. セキュリティ

### 9.1. 認可

すべての呼び出しは認証済みユーザーまたは明示的に文書化されたサービスアカウントのコンテキストで実行されなければならない（MUST）。

サーバーは特定プロジェクトとオブジェクトの Redmine 権限を確認しなければならない（MUST）。`tools/list` にツールが存在することは操作の権限を意味しない。

管理ツールは次を行うべき:

- 管理者にのみ公開;
- または別の管理 MCP プロファイル/サーバーに移動;
- または別のスコープで保護。

### 9.2. 最小権限

MCP サーバーと Redmine API トークンは最小限必要な権限を持たなければならない。ユーザーアクセスモデルを維持する必要がある場合、すべてのユーザーにグローバル管理トークンを使用できない。

### 9.3. 任意ファイルシステムパス禁止

次のようなパラメータ:

```json
{"file_path": "/etc/app/.env"}
```

は公開 MCP ツールで禁止（FORBIDDEN）。

安全なオプション:

1. サイズ制限付き `content_base64`;
2. 信頼できるアップロードメカニズムが発行する不透明 `upload_token`;
3. ホストがアクセスを確認する MCP リソース URI;
4. `realpath` チェックと許可リストを持つ専用一時ディレクトリからのファイルのみ。

サーバーは次を検証しなければならない（MUST）:

- 最大サイズ;
- MIME タイプ;
- 許可拡張子;
- ファイル名;
- パストラバーサルの不在;
- 組織ポリシーで要求される場合のウイルス対策/コンテンツチェック。

### 9.4. 任意 URL と SSRF

ツールはそれが主目的でない限り、任意 URL を受け付けてはならない。

HTTP アクセスが必要な場合:

- ドメインとスキームの許可リストを使用;
- 不要な場合はループバック、リンクローカル、メタデータエンドポイント、内部ネットワークを禁止;
- リダイレクトを制限;
- タイムアウトと応答制限を設定;
- 内部認証情報を別オリジンに渡さない。

### 9.5. 削除と危険な操作

不可逆操作には必須（MANDATORY）:

- 別ツール;
- `destructiveHint: true`;
- 不可逆性の明示的説明;
- 正確なサーバー側権限チェック;
- 監査ログ;
- 期待プロジェクト外オブジェクト削除の防止;
- 子オブジェクトと関連結果のチェック。

ブール `confirm_delete: true` は誤呼び出し防止の追加保護として使用してよい（MAY）が、認可メカニズムとはみなせない。

2 段階削除、楽観的ロック、べき等性キー — 付録 A 参照。

### 9.6. ログ

監査ログに記録:

- ツール名;
- 認証済みユーザー;
- 対象プロジェクト/オブジェクト ID;
- 結果;
- 所要時間;
- エラーコード;
- リクエスト相関 ID。

ログに記録してはならない（FORBIDDEN）:

- アクセストークン;
- Authorization ヘッダー;
- クッキー;
- base64 ファイル内容;
- シークレットカスタムフィールド;
- 別途必要がない限りプライベートノートの全文。

### 9.7. レート制限とタイムアウト

すべてのツールには次が必要（MUST）:

- 入力サイズ制限;
- ユーザー/トークンごとのレート制限;
- 返却レコード数の制限;
- 一括操作制限。

読み取りツールには 60 秒のサーバータイムアウトが適用される。書き込みツールはサーバータイムアウトで中断されない。保存成功後にべき等性結果を記録できるようにするため。

---

## 10. エラー

### 10.1. エラー分離

2 レベルを使用:

1. **プロトコルエラー** — 未知のツール、破損した JSON-RPC、MCP リクエスト処理不能。
2. **`isError: true` のツール実行エラー** — 引数エラー、Redmine API、権限、ワークフロー、またはビジネスロジックエラー。

モデルが引数変更で修正できるエラーはツール実行エラーとして返すべき。

### 10.2. エラー構造

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

### 10.3. 推奨コード

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

### 10.4. メッセージは修正可能でなければならない

悪い例:

```text
Invalid request.
```

良い例:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

ユーザーにスタックトレースを返さない。スタックトレースは相関 ID 付きの保護されたサーバーログにのみ保存。

---

## 11. ページネーションとデータ量

### 11.1. リスト/検索ツール

必須パラメータ:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

既存 Redmine API では `offset` が許可される。カスタム実装では、走査中にデータが活発に変化する可能性がある場合、不透明カーソルを優先。

### 11.2. ページネーションメタデータ

結果には次を含めなければならない:

- 実際の `limit`;
- `offset` または `next_cursor`;
- `has_more`;
- 取得が大きな負荷を生まない場合の `total_count`。

### 11.3. フィールド選択

`fields` パラメータは閉じた許可リストからの配列としてのみ許可:

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

許可リストなしで任意フィールド名を SQL、ActiveRecord `select`、シリアライザ、または Redmine API に直接渡してはならない。

### 11.4. 大きな結果

大きなジャーナル、添付、ファイルは次を満たさなければならない:

- 別のページネーションを持つ;
- 別ツール/リソースで返す;
- バイナリデータでは、可能な場合、大きな base64 を応答に埋め込む代わりにリソースリンクまたは他の限定参照を返す;
- または操作が真に長くクライアントがサポートする場合、タスク拡張実行をサポート。

`execution.taskSupport` は自動設定されない。デフォルトは `forbidden`。

---

## 12. 新規ツールのリファレンス

§7.1 に従い必須 `title` と型付き `outputSchema` を持つ省略版書き込みツール例。エラー形式 — §10。完全 JSON — 付録 B。

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

## 13. テスト

### 13.1. スキーマテスト

すべてのツールで必須（MANDATORY）:

- 少なくとも 1 つの有効な呼び出し;
- 少なくとも 1 つの否定呼び出し（たとえば必須フィールド欠落または誤った型）。

スキーマに応じてカバーすべき（SHOULD）:

- 完全な有効呼び出し;
- 各必須フィールドの欠落;
- 主要パラメータの誤った型;
- 未知の追加フィールド;
- enum 外の値;
- 範囲外の値;
- 誤った date/date-time;
- `maxItems`、`maxLength`、ファイルサイズの超過;
- フィールド相互依存の違反（XOR フィールド両方同時; 必須ペアのどちらもなし）。

### 13.2. 権限テスト

書き込み、破壊的、機密読み取り操作では次を検証すべき（SHOULD）:

- プロジェクトアクセスのないユーザー;
- 読み取り専用アクセスのユーザー;
- 編集権限のユーザー;
- ツールが管理シナリオに触れる場合の管理者;
- ツールが返すまたは変更するプライベートノートへのアクセス;
- 置換 ID による別プロジェクトオブジェクトの変更試行。

機密データのない単純な読み取り専用ツールでは、権限テストを 1 つの否定シナリオに限定するか、MR で簡潔な正当化とともに省略してよい（MAY）。

### 13.3. べき等性テスト

`idempotentHint: true` では、2 回以上の同一連続呼び出しの自動または手動テストを持つべき（SHOULD）。

べき等と主張される副作用の不在を検証。たとえば:

- 追加ジャーナルエントリ;
- 繰り返しメール;
- ファイル重複;
- リレーション重複;
- 繰り返し作業時間;
- 保証の一部である場合の追加 Webhook イベント。

### 13.4. 契約テスト

`tools/list` をスナップショットとして保持するか、破壊的契約変更を別途追跡すべき（SHOULD）。CI は次を検出してよい（MAY）:

- 名前変更;
- パラメータ削除;
- 型変更;
- `required` 変更;
- アノテーションリスクレベル増加;
- `outputSchema` 消失;
- `outputSchema` のフィールド、型、`required`、`enum` / `const`、または成功/エラーブランチの非互換変更。

### 13.5. LLM 選択テスト

類似または混同しやすいツールには、ユーザーリクエストと期待ツール呼び出しのセットを持つべき（SHOULD）。完全自動 LLM 実行は MR の静的例または説明レビューで置き換えてよい（MAY）。

例:

| リクエスト | 期待ツール |
|---|---|
| "課題123を表示" | `redmine_get_issue` |
| "OAuthに関する課題を検索" | `redmine_search_issues` |
| "課題123にウォッチャー15を追加" | `redmine_add_issue_watcher` |
| "課題間のリレーションを削除" | `redmine_delete_issue_relation` |
| "類似課題を検索" | `redmine_advanced_search_semantic_search_issues` |

モデルが高確率で読み取り専用意図に汎用破壊ツールを選択するか、`action` 値を推測せざるを得ない場合、テストまたはレビューは失敗。

### 13.6. エラー回復テスト

典型的エラー後にモデルが正しい再試行に十分な情報を受け取ることを検証すべき（SHOULD）:

- ID 欠落;
- 無効ステータス;
- `expected_updated_at` 競合;
- 権限不足;
- 制限超過;
- 誤った MIME タイプ。

---

## 14. コードレビューチェックリスト

新規ツールはすべての必須項目が「はい」の回答を得るまでマージできない。

### 目的

- [ ] 1 アクション; `action`/`manage` による操作混在なし（§3.1–3.2）。
- [ ] 管理操作は通常操作から分離。

### 名前と説明

- [ ] 名前は `redmine_` で開始: コア — `redmine_<verb>_<entity>`; サードパーティプラグイン — `redmine_<plugin_id>_…`（§4.1）。
- [ ] 説明: 目的、副作用、簡潔な結果; 類似ツールは区別可能（§5）。
- [ ] 他ツールへの相互参照は `tools/list` の完全名を使用（§5.2.1）。

### ソース契約調査

- [ ] コアツールでは、必要に応じてリソースの REST API、バージョン、プラグインを調査; カバレッジレポートを MR に添付すべき（§5.6–5.7）。
- [ ] 拡張ツールでは、ソースシリアライザ / サービス / REST エンドポイントと各結果形式の少なくとも 1 つの実際の成功応答を検証しなければならない（§18.5）。
- [ ] 契約を現在の `tools/list` と比較。

### 入力スキーマ

- [ ] スキーマは §6 に一致（`additionalProperties: false`、型、`required`、`enum`/`const`、制約）。
- [ ] すべてのパラメータに意味のある `description`（§6.14）; `*_id` に `minimum: 1`（§4.3）。
- [ ] `*_id` および他のルックアップ値にディスカバリパスを指定（§6.16）: list ツール、get/list 応答フィールド、または `enum`。
- [ ] 「…のいずれか 1 つ」/ 相互依存制約を説明だけでなくスキーマで形式化（§5.3、§6.12）。
- [ ] 楽観的ロック — `expected_updated_at` のみ、`updated_at` ではない（§4.4）。
- [ ] `set_*` オプションフィールドのクリアを決定: `null`、別 clear ツール、または明示的拒否（§6.13）。
- [ ] 「オブジェクトまたは JSON 文字列」および任意 `fields`/`payload` なし。
- [ ] `*_id` — 整数; §3.4 に従うサーバー側検証。

### 出力とエラー

- [ ] 新規ツールに成功/エラーエンベロープ付き `outputSchema`（§7.1–7.2）。
- [ ] 既知の安定結果フィールドを `properties` で記述; 既知契約の代わりに `additionalProperties: true` を使用しない。
- [ ] すべての保証フィールドが `required` にある。
- [ ] nullable と optional フィールドを意識的に区別。
- [ ] `enum`/`const`、`date`/`date-time`、範囲、その他既知制約をスキーマで形式化。
- [ ] 金額および他の数値ビジネス値について、単位、通貨、主要/補助単位が明確。
- [ ] 結果のビジネス不変条件をツール名からの推論だけでなくスキーマ（`const`、`enum`、`required`、または条件付きスキーマ）で反映。
- [ ] 説明、`outputSchema`、実際のハンドラ/REST/サービス応答が矛盾しない（§7.1.1）。
- [ ] 内部 REST/Ruby/プラグイン値を安定 MCP 契約に正規化; STI/クラス名またはロケール依存形式の漏洩なし（§3.3）。
- [ ] リストツールは簡潔だが十分な構造を返す; 説明は対応 get ツールが真に必要な場合を正しく説明。
- [ ] エラー: `isError`、安定コード、修正可能メッセージ; シークレットまたはスタックトレースなし（§10）。

### アノテーション

- [ ] アノテーションがリスクと一致（§8）; `idempotentHint: true` にはテスト推奨。

### セキュリティ

- [ ] 権限、ファイルパス、SSRF、制限、ログ、破壊的/監査 — §9 に従う; 必要に応じて付録 A パターン。

### テスト

- [ ] 最小スキーマテスト; 残りはリスクに応じて（§13）。

---

## 15. 互換性と既存ツールの変更

### 15.1. 破壊的変更

破壊的変更:

- ツール名変更;
- フィールド削除;
- 型変更;
- 新規必須フィールド追加;
- フィールド意味の変更;
- 非互換出力変更;
- 複数操作を 1 つに統合;
- アノテーションとドキュメント更新なしのリスク増加。

### 15.2. 名前移行

たとえば古いプレフィックス `redmine_mcp_` から移行する場合:

```text
redmine_mcp_get_issue
```

短いプレフィックス `redmine_` へ:

```text
redmine_get_issue
```

次に従う:

1. 新しい名前を追加;
2. 一時的に古いエイリアスを保持;
3. 説明で古いツールを非推奨とマーク**するか、alias が `tools/call` のみに必要な場合は `tools/list` に公開しない**;
4. 古い名前呼び出しのメトリクスを収集（呼び出されたツール名による既存の audit log で十分）;
5. 合意期間後にエイリアスを削除（別途合意がない限り、次のメジャーバージョンより前には削除しない）;
6. サーバーが `listChanged` を宣言する場合 `notifications/tools/list_changed` を送信。

現在の例（[03-core-tools.md](03-core-tools.md) 参照）: `redmine_list_all_users` → `redmine_admin_list_users`; `redmine_list_files` → `redmine_list_project_files`; `redmine_delete_file` → `redmine_delete_attachment`; `redmine_get_server_info` → `redmine_get_mcp_info`。alias は `tools/call` で受け付けられ、`tools/list` には公開されない。

### 15.3. 説明の変更

説明はモデルのツール選択に影響し、behavioral 変更とみなされる。説明の実質的変更時は LLM 選択例をレビューするか、選択レビューを繰り返すべき（SHOULD）。

### 15.4. サーバーバージョン

MCP プラグインバージョンは `redmine_get_mcp_info`（またはサーバーメタデータ）で返される。並行非互換契約をサポートする実際の必要がない限り、すべての名前に `v1`、`v2` を追加しない。並行非互換契約をサポートする実際の必要がない限り、すべての名前に `v1`、`v2` を追加しない。

---

## 16. 現在の Redmine MCP 問題に関するルール

新規ツール開発時、現在の契約監査のパターンを繰り返すことは禁止。規範的ルールは対応セクションにあり; 以下は問題マップのみ:

| 監査問題 | セクション |
|---|---|
| `redmine_` プレフィックスなしの名前（サードパーティプラグイン含む）/ 1 プラグイン内の混在スタイル | §4.1 |
| 動詞が意味と一致しない（`set_*` の代わりに `done=true/false` の `complete_*`） | §4.2 |
| `minimum: 1` なしまたは "Issue id" 説明の数値 ID | §4.3 |
| `expected_updated_at` の代わりに `updated_at` による楽観的ロック | §4.4, A.2 |
| 汎用 `manage_*` / `patch_*` と `action` パラメータ | §3.1, §4.2 |
| `type` なしパラメータ、説明のみの enum、 `items` なし配列 | §5.3, §6 |
| `description` なしパラメータ; ルックアップツール参照なしの短すぎる説明 | §6.14 |
| 参照パラメータと識別子に `examples` なし | §6.15 |
| ディスカバリパスなしの `*_id` 書き込みツール（list ツールと get 応答オプションなし） | §6.16 |
| 説明が「A または B のいずれか 1 つ」を約束するがスキーマがエンコードしない | §5.3, §6.12 |
| 相互参照の短いツール名（`redmine_list_projects` の代わりに `list_projects`） | §5.2.1 |
| 半ページの過負荷ツール説明 | §5.2 |
| スキーマなしの `fields` / `extra_fields`; 余分な `required` | §6.4, §6.11 |
| フィールドクリア方法も明示的拒否もない `set_*` | §6.13 |
| すべての書き込みツールに 1 つのアノテーションセット; 過剰な `openWorldHint` | §8 |
| 通常 `update` / `rename` に `destructiveHint: true`; `create_*` に誤った `openWorldHint` | §8.1, §8.2 |
| 説明が応答構造を約束するが `outputSchema` 欠如または任意オブジェクトのみ記述 | §7.1 |
| 説明、スキーマ、実際の応答が矛盾 | §7.1.1 |
| MCP 応答の STI/クラス名またはロケール日付 | §3.3 |
| 既知 list/get フィールドの代わりに `additionalProperties: true` | §7.1 |
| 任意 `file_path`、プロジェクトスコープバイパス、SSRF | §9 |
| ローカル変更と 1 ツールでのメール/外部効果 | §3.2 |
| 類似ツールの曖昧なペア | §5.4 |

---

## 17. ツールセット構造

完全な現在のツールリストは本ドキュメントに重複しない — すぐに古くなる。

**真実の源:**

- コアツール — [03-core-tools.md](03-core-tools.md) とインストール上の実際の `tools/list`;
- サードパーティプラグインツール — §18 とインストール上の MCP `tools/list` 応答。

**グループ化原則**（各グループ — §3 に従う別の原子的ツール）:

| グループ | 意図の例 | プレフィックス |
|---|---|---|
| 課題 | get, list, search, create, update, delete, copy, サブタスク | `redmine_` |
| リレーションとウォッチャー | リレーションの list/create/delete; ウォッチャーの add/remove | `redmine_` |
| プロジェクトとメンバー | プロジェクト、モジュール、メンバー、ロール | `redmine_` |
| バージョンとカテゴリ | バージョン; 課題カテゴリ | `redmine_` |
| 工数記録 | list, create, update, import, 活動 | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| ファイルと添付 | list, upload, delete, download | `redmine_` |
| 管理 | ユーザー、ロール、MCP セッション情報 | `redmine_admin_` または `redmine_get_mcp_info` |
| プラグインエンティティ | チェックリスト、検索など | `redmine_` + `plugin_id`、たとえば `redmine_advanced_search_` |

新規ツール追加前に MCP `tools/list` 応答と対応グループを確認すべき（SHOULD）: 既存ツールを重複させず、異なる意図を 1 つの名前に混在させない。

グループに ID パラメータ（`status_id`、`role_ids`、…）を持つ書き込みツールがある場合、同じグループにディスカバリパスが必要（§6.16）。

管理ツールは必要権限を持つユーザーにのみ公開（§9.1）。

---

## 18. サードパーティプラグイン拡張

Extension API 経由でツールを追加する Redmine プラグイン作者向けセクション。API、フック、エッジケースの技術説明 — [04-extensions.md](04-extensions.md)。

拡張は `redmine_mcp` コアツールと同じ契約、セキュリティ、命名ルール（§3–§10、§4.1）に従う。

### 18.1. 何をいつ公開するか

| プリミティブ | 使用タイミング |
|---|---|
| **Tool** | プラグインエンティティまたは Redmine への 1 アクション: create, get, update, delete, search |
| **Resource** | 安定 URI による大きなまたは静的コンテンツ: wiki 本文、ファイル、長いレポート |
| **Prompt** | 副作用のある操作ではなく、ユーザー向けの反復可能シナリオテンプレート |
| **`extend_tool`** | 既存コアツールの論理的部分であるパラメータまたはフック（たとえば課題読み取り時の `include_*`） |

モデルが `action` を推測せずに別ツールで意図を満たせる場合 — 別スキーマを肥大化させる `extend_tool` より **独自ツール** を優先。

### 18.2. 登録

- 拡張ファイルは Redmine 起動時にロードされる（`ExtensionLoader` 参照）:
  - サードパーティプラグイン — `lib/<plugin_id>/mcp.rb`（および他のサポートされるパス、[04-extensions.md](04-extensions.md) 参照）;
  - `redmine_mcp` 内蔵統合 — 対象プラグインに独自の `mcp.rb` がない場合、またはその `mcp.rb` の読み込みが失敗した場合の fallback として `lib/redmine_mcp/extensions/<plugin.id>.rb`。
- `mcp.rb` のモジュールは `PluginName::Mcp`（`extend RedmineMcp::ExtensionApi`）でなければならない（MUST）: Zeitwerk がファイルから名前を導出。
- 登録前に `mcp_extension_enabled?` を確認すべき（SHOULD） — gemspec での `redmine_mcp` へのハード依存は不要。
- リロードでツールを重複させないよう `register_tool_once` を使用。
- `tools/list` の完全名は `redmine_` で始まらなければならない（§4.1）。
- ツールには `title`、`description`、`input_schema`、`output_schema`、`permission`、`annotations` が必要（MUST）; 名前の重複禁止。
- ツールは対応権限を持つユーザーにのみ MCP `tools/list` 応答に表示。

### 18.3. 命名

- 名前は `redmine_` で始まらなければならない（MUST）; 次に — `plugin_id` と `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`、`redmine_advanced_search_<verb>_<entity>`。
- 動詞と `manage_*` 禁止 — §4.2 および §3.1 に従う。
- コアツール名をコピーせず、同じ意図の 2 つ目のツールを別名で公開しない。

登録前に対象インストールの `tools/list` 応答と比較すべき（SHOULD）。

### 18.4. 権限とセキュリティ

- `permission` は別の「mcp のみ」ロールではなく、実際の Redmine またはプラグイン権限と一致しなければならない（MUST）。
- 課題操作では可視性とプロジェクトモジュールチェックをコピーする代わりに `register_issue_tool` と `find_accessible_issue` を使用すべき（SHOULD）。
- `module_name` が設定されている場合、ユーザーが有効モジュールを持つ少なくとも 1 つの可視プロジェクトで宣言権限を持つ場合のみツールは `tools/list` に含まれる（MUST）。`module_name` なしでは、少なくとも 1 つの可視プロジェクトでの権限で十分。ハンドラは特定課題（プロジェクトモジュール含む）を依然として確認。
- 他ユーザー向けに `tools/list` から非表示でも、ハンドラでの繰り返しサーバー側引数および権限検証 — §3.4 および §9 に従う。

### 18.5. クリーンな実装

**薄い MCP レイヤー。** `mcp.rb` には主にツール登録を含める: スキーマ、説明、権限、アノテーション、短いハンドラ。ハンドラは引数を検証し、コンテキストを確認し、実行を別クラス/サービスに委譲。

プラグインビジネスロジックは通常のモデルとサービスに残し、MCP に依存しない。

MCP にのみ必要なロジック — たとえば複数モデルからのデータマージ、REST 応答の MCP 契約への正規化、派生フィールド計算、ツール結果準備 — は別の `mcp_tools.rb` に移動してよい（MAY）。そのようなファイルが大きくなる場合、エンティティまたは操作ごとにクラスに分割すべき（SHOULD）。たとえば `mcp_tools/clients.rb`、`mcp_tools/deals.rb`、`mcp_tools/subscriptions.rb`。

ビジネスロジックと大きな変換を `mcp.rb` 内の lambda/ハンドラに直接置かない。

**データアクセス。**

- プラグインモデルとサービス — ロジックが既にある場合。
- `internal_request` / `internal_get` / REST — 既存 API コントローラを再利用する場合; エンドポイントは `accept_api_auth` をサポートしなければならない。`POST`、`PUT`、`PATCH`、`DELETE` には `internal_request` を使用; 読み取りには `internal_get` または `internal_request(method: 'GET', ...)` を使用。`internal_request_error?` で失敗を確認。

**`extend_tool` — 適度に。** パラメータがコアツールと 1 つの意図の一部である場合に適切。プラグインが本質的に別サブシステムを追加する場合は不適切: 独自プレフィックスと独自ツールが良い。コアへのリンクは `description` またはサーバー指示で記述。

**コアと同様の契約。** 入力 — §6 に従う。出力 — §7.1 および §7.1.1: 安定フィールド、`required`、`enum`/`const`、単位、内部 API 正規化。リスクに応じたアノテーション、修正可能エラー（§8、§10）。楽観的ロック — `expected_updated_at`（§4.4）。すべてのパラメータ — `description`（§6.14）。相互参照 — 完全名（§5.2.1）。すべての書き込み `*_id` パラメータ — ディスカバリパス（§6.16）: 別の `list_*` または get/list 応答の `id` 付きオプション、パラメータ説明での明示的参照。

拡張ツール公開前に、ソースシリアライザ / サービス / REST エンドポイントと各結果形式の少なくとも 1 つの実際の成功応答を検証しなければならない（MUST）。

**共有コード — `redmine_mcp` に。** 拡張開発時、フラグメントが別の MCP プラグインに必要になる可能性がある場合、すぐにコア `redmine_mcp` に追加すべき（SHOULD）。`lib/<plugin>/mcp*.rb` にコピーしない。

基準: ロジックが 1 つのプラグインドメイン（チェックリスト、検索、…）に限定されず、MCP 契約、Extension API、または典型的統合パターンを記述する。

| 場所 | 内容 |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`、`REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`、`ExtensionApi` 拡張（`register_issue_tool`、`issue_permission`、`internal_request`、…）、`ToolResponse`、`issue_id` / `project_id` による共通権限ヘルパー |
| **プラグイン拡張** | `mcp.rb` — ツール登録と短いハンドラ; `mcp_tools.rb` / `mcp_tools/*.rb` — MCP 固有の取得、集約、正規化; 通常モデル/サービス — MCP に依存しないビジネスロジック |

**拡張の推奨配置:**

- `mcp.rb` — ツール登録と短いハンドラ;
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP 固有の取得、集約、データ正規化;
- 通常モデル/サービス — MCP に依存しないビジネスロジック。

別拡張からヘルパーをコピーする前に、`redmine_mcp` に類似が既に存在するか確認すべき（SHOULD）; なければ同じ PR でコアに移動し、重複しない。

拡張 API の詳細 — [04-extensions.md](04-extensions.md)（§ "ExtensionApi helper methods"）。

### 18.6. アンチパターン

禁止または非推奨:

- すべての HTTP リクエストでツールを登録;
- 起動時の隣接プラグインエラーで失敗;
- 1 ツールで読み取り、書き込み、管理を混在;
- 「別名」のコアツール重複;
- 「将来のため」のオプションパラメータで別ツールを拡張;
- プラグイン UI/API でユーザーに利用不可の内部フィールドを MCP で返す;
- MCP スキーマが異なる契約を定義する場合の STI クラス名、ロケール日付、REST 表現の公開（§3.3、§7.1.1）;
- リスト要素を `{ "type": "object", "additionalProperties": true }` のみで記述（§7.1）;
- モデルが許可 ID を知る方法なしで `status_id` を持つ `set_*_status` / 同様を公開（§6.16）;
- 場所が `redmine_mcp` にある場合、拡張で共通 MCP ヘルパー（エンベロープ `outputSchema`、`internal_request` ラッパー、課題権限）を重複 — §18.5 参照。

### 18.7. マージ前検証

- [ ] ツール名は §4.1 / §18.3 に従い `redmine_` で開始。
- [ ] 拡張は起動時にロード; 権限を持つユーザーの `tools/list` にツールが表示。
- [ ] 権限のないユーザーおよびプラグイン MCP 拡張フラグ無効時にツールが不在。
- [ ] 契約とチェックリスト（§14）を満たす。説明 / outputSchema / 実際の応答比較（§7.1.1）含む; 必要に応じて §13 のテスト。
- [ ] 各公開結果形式（たとえば list と get の両方が公開される場合は両方）について、シリアライザ / REST / サービスを少なくとも 1 つの実際の成功応答で検証。
- [ ] `tools/list` の既存ツールとの重複なし。
- [ ] 各 `*_id` 書き込みパラメータにディスカバリパスあり（§6.16）。

---

## 19. 出典と規範的基盤

本ドキュメントは 2026-07-22 時点で次の主要出典に基づいて作成された:

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
    REST API ページのリンク `API changes for each version`; すべてのサポートバージョンで検証。

---

## 20. 新規ツール準備完了基準

新規 MCP ツールは、必須コードレビューチェックリスト項目（§14）が満たされたとき準備完了とみなされる。

サードパーティプラグインツールでは追加で — チェックリスト §18.7。

リスク推奨: カバレッジレポート（§5.7）、追加テスト §13.2–13.6 および付録 A。最小スキーマテスト（§13.1）と `outputSchema` ルール（§7.1、§7.1.1）は必須。

---

## 付録 A. 推奨実装パターン

以下のパターンはすべての MCP ツールに必須ではない。リスクが高い場合に検討すべき（SHOULD）: 破壊的操作、管理ツール、一括書き込み、外部副作用、タイムアウトによる繰り返し呼び出し。

### A.1. 2 段階削除（prepare / confirm）

特に危険な管理操作の場合:

1. `redmine_prepare_delete_*` は簡潔な結果説明と 1 回限りトークンを返す;
2. `redmine_confirm_delete_*` は短い TTL のトークンを受け付ける。

破壊的操作の規範的要件 — §9.5。

### A.2. 楽観的ロック

並行変更下の更新/削除では、パラメータは `updated_at` ではなく `expected_updated_at`（§4.4）と命名しなければならない（MUST）:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

名前はコアツールと拡張（チェックリスト書き込みツール含む）で統一。

競合時は `CONFLICT`、実際のオブジェクト変更時刻（応答の `updated_at` / `updated_on`）、オブジェクト再読み取りの推奨を返す。

### A.3. べき等性キー

タイムアウトによる繰り返しで重複が生じる可能性がある操作:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

特に適切:

- 課題作成;
- 作業時間インポート;
- ファイルアップロード;
- 一括操作;
- メール送信。

ツールが `idempotentHint: true` を公開する場合、繰り返し呼び出しは安全でなければならない（§8.2）; `idempotency_key` はそれを保証する 1 つの方法。

---

## 付録 B. 完全ツール例

リファレンス `redmine_create_issue`。エラー形式またはエンベロープが変更された場合、§7、§10、本セクションを更新; §12 は省略版のまま。

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

注: サーバーが `idempotency_key` 存在時にべき等性を保証する場合でも、アノテーションはツール全体を記述する。したがってキーなし呼び出しが許可される場合、安全な値は `false` のまま。

