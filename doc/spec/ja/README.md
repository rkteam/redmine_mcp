# Redmine MCP

[ウェブサイト](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | 日本語 | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Redmine 内の MCP サーバー（Model Context Protocol）。AI クライアントが標準の Redmine 権限を通じて課題、プロジェクト、ユーザーと連携できるようにします。他のプラグインは、このプラグインを変更せずに独自の tools、resources、prompts、capabilities を追加できます。

## 要件

| コンポーネント | バージョン |
|---|---|
| Redmine | Redmine 6.0+（テスト済み: 6.0–6.1） |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

このプラグインは MCP protocol `2025-11-25` と Ruby MCP SDK `0.23.x` を使用します。
より新しい MCP protocol および SDK バージョンのサポートは、現時点では宣言されていません。

- Redmine で REST API が有効であること
- gem `mcp` は `plugins/redmine_mcp/Gemfile` で宣言され、`bundle install` でインストールされること

## インストールと設定

### 1. プラグインのインストール

Redmine の `plugins` ディレクトリに git リポジトリをクローンします:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Redmine のルートディレクトリから依存関係をインストールし、アプリケーションを再起動します:

```bash
cd /path/to/redmine
bundle install
```

Redmine を再起動します。

### 2. 管理画面での有効化

**管理 → プラグイン → Redmine MCP → 設定**

| パラメータ | 説明 |
|---------|-------------|
| MCP を有効にする | `/mcp` エンドポイントを有効にします。有効時、インストール済みプラグインの MCP 拡張が読み込まれます |
| 読み取り専用モード | write ツールと write アクション（create/update/delete など）をブロックします |
| MCP 拡張 | インストール済みプラグインの MCP 統合を有効にするチェックボックス |

### 3. REST API

**管理 → 設定 → API** — 「RESTによるWebサービスを有効にする」を有効にします。

### 4. 権限

**管理 → ロールと権限** — 必要なロールで、グローバル権限 **MCP を使用**（`use_mcp`）を手動で有効にします。Redmine 管理者は常に MCP にアクセスできます。

### 5. ユーザー API キー

MCP 経由で作業する各ユーザーは API キーを持つ必要があります:

**個人設定 → APIアクセスキー**（またはユーザー REST API 経由）。

キーはヘッダーで渡します:

```
X-Redmine-API-Key: <your_key>
```

## MCP クライアントの接続

サーバーは **Streamable HTTP**（stateless）を使用します。エンドポイント:

```
https://<your-redmine>/mcp
```

サポートされるメソッド: `GET`、`POST`、`DELETE`。

### Cursor の例

MCP 設定（`.cursor/mcp.json` またはグローバル設定）で、HTTP トランスポートのサーバーを追加します。正確な形式はクライアントのバージョンに依存します。典型的な例:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "your_api_key"
      }
    }
  }
}
```

接続後、クライアントは `initialize` を実行し、続けて `tools/list`、`tools/call`、`resources/list`、`prompts/list` などを呼び出せます。

### 手動確認

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: your_key' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0" }
    }
  }'
```

成功した応答には `serverInfo.name: "redmine_mcp"` が含まれます。

### Host と reverse proxy

MCP transport は DNS rebinding 対策のため HTTP `Host` と `Origin` を検証します。

許可される host は Redmine の設定から取得されます:

**管理 → 設定 → 一般 → ホスト名とパス**

値は Redmine の公開 URL と一致する必要があります。

例えば、Redmine が次の URL で利用可能な場合:

```
https://redmine.example.com
```

設定では次を使用します:

```
redmine.example.com
```

Redmine が reverse proxy の背後で動作する場合、proxy はクライアントの元の `Host` ヘッダーを転送する必要があります。

host が一致しない場合、MCP エンドポイントは HTTP `403 Forbidden` を返すことがあります。

`Origin` ヘッダーのないクライアントは Origin チェックの対象外です。

## 組み込みツール（core tools）

完全名は `redmine_<tool_name>` 形式です（例: `redmine_get_issue`）。

サーバーはプロジェクト、課題、ユーザー、時間記録、Wiki、フォーラム、ファイル向けのツールを提供します。以下は組み込み tools の概要です。完全な入力スキーマと descriptions は `tools/list` 経由で MCP クライアントが利用できます。

### 共通パラメータ

- `project` — プロジェクトの文字列 ID または identifier。
- `assignee_ref` / `user_ref` で値 `me` — 現在のユーザー。
- `assigned_to_id` — 課題の担当ユーザーまたはグループ; `null` は任意フィールドをクリアします。
- `create_time_entry` には `project` または `issue_id` が必要です。
- `upload_file` には `filename` と `content_base64` が必要です。

### 操作の信頼性

- `expected_updated_at` — 機密性の高い update/delete 操作で使用。
- `idempotency_key` — `create_issue`、`copy_issue`、`update_issue`、`add_issue_note`、`create_time_entry`、`import_time_entries`、`upload_file` で使用。

### 制限

- 読み取り timeout 60 秒;
- ユーザーあたり 120 リクエスト/分;
- MCP リクエスト HTTP ボディ最大 36 MiB;
- tool JSON args 最大 32 MiB;
- base64 添付ファイル最大 20 MiB;
- 添付ファイルのダウンロード最大 10 MiB。

### 本番環境へのデプロイ

レート制限と idempotency は `Rails.cache` を使用します。

複数のアプリケーション worker または複数の Redmine インスタンスを持つインストールでは、共有 cache store の使用が推奨されます。

プロセスローカル cache では、レート制限と idempotency の保証は個々のアプリケーションプロセス内でのみ適用されます。

### プロジェクト管理

| ツール | 説明 |
|------|-------------|
| `list_projects` | プロジェクト一覧 |
| `get_project` | プロジェクト詳細 |
| `list_project_issue_custom_fields` | プロジェクトの課題カスタムフィールド |
| `summarize_project_status` | N 日間のプロジェクトメトリクス要約（サーバー生成） |
| `list_project_activities` | プロジェクトアクティビティフィード（イベント。時間記録の activity タイプではない） |
| `list_versions` | ロードマップのバージョン（マイルストーン） |
| `get_version` | ロードマップバージョンの詳細（集計付き） |
| `create_version` | バージョン作成 |
| `update_version` | バージョン更新 |
| `delete_version` | バージョン削除 |
| `list_project_members` | プロジェクトメンバーとロール |
| `list_project_member_candidates` | プロジェクトに追加可能なユーザーとグループ |
| `list_roles` | プロジェクトで管理可能なロール |
| `get_project_modules` | 有効なプロジェクトモジュール |
| `add_project_member` | メンバー追加 |
| `update_project_member` | メンバーロール変更 |
| `remove_project_member` | メンバー削除 |

### 課題

| ツール | 説明 |
|------|-------------|
| `get_issue` | 課題詳細（ジャーナル、添付ファイル、カスタムフィールドなど） |
| `list_issues` | フィルタとページネーション付き課題一覧 |
| `search_issues` | 課題のテキスト検索 |
| `run_issue_query` | 保存済み課題クエリの実行 |
| `get_issue_form_options` | 許可される課題フォームフィールド値（1 回の呼び出し） |
| `validate_issue_create` | 書き込みなしで課題作成パラメータを検証 |
| `validate_issue_update` | 書き込みなしで課題更新パラメータを検証 |
| `create_issue` | 課題作成 |
| `update_issue` | 課題属性と添付ファイルの更新 |
| `add_issue_note` | 課題へのコメント追加（オプションで添付ファイル付き） |
| `delete_issue` | 確認付き課題削除 |
| `copy_issue` | 課題コピー |
| `list_issue_relations` | 課題関連一覧 |
| `create_issue_relation` | 課題間の関連作成 |
| `delete_issue_relation` | 課題関連削除 |
| `list_subtasks` | サブタスク |
| `add_issue_watcher` | ウォッチャー追加 |
| `remove_issue_watcher` | ウォッチャー削除 |
| `update_issue_note` | ジャーナルエントリ編集 |
| `set_issue_note_private` | ジャーナルエントリのプライバシー変更 |
| `get_private_notes` | プライベートコメントのみ |
| `list_issue_categories` | プロジェクトの課題カテゴリ |
| `create_issue_category` | カテゴリ作成 |
| `update_issue_category` | カテゴリ更新 |
| `delete_issue_category` | カテゴリ削除 |

### ユーザー

| ツール | 説明 |
|------|-------------|
| `list_users` | プロジェクトメンバー; フィルタ `query`（名前/login）と `login`; グローバル検索は管理者のみ |
| `list_groups` | `add_project_member` の `group_id` 用 Givable グループ |

### 時間記録

| ツール | 説明 |
|------|-------------|
| `list_time_entries` | 時間記録一覧 |
| `create_time_entry` | 時間記録作成 |
| `update_time_entry` | 時間記録更新 |
| `list_time_entry_activities` | 時間記録の activity タイプ（プロジェクトイベントフィードではない） |
| `import_time_entries` | 時間記録の一括インポート |

### 参照データ

| ツール | 説明 |
|------|-------------|
| `list_trackers` | すべてのトラッカー |
| `list_project_trackers` | プロジェクトのトラッカー |
| `list_issue_statuses` | 課題ステータス |
| `list_issue_priorities` | 課題優先度 |
| `admin_list_users` | フィルタ付きユーザー（管理者のみ） |
| `get_current_user` | 現在のユーザー |
| `list_queries` | 保存済みクエリ（メタデータ; 実行は `run_issue_query`） |

### 検索と Wiki

| ツール | 説明 |
|------|-------------|
| `search_all` | 課題と Wiki ページの検索 |
| `list_wiki_pages` | プロジェクト Wiki ページ |
| `get_wiki_page` | Wiki ページ取得 |
| `create_wiki_page` | Wiki ページ作成 |
| `update_wiki_page` | Wiki ページ更新 |
| `delete_wiki_page` | Wiki ページ削除 |
| `rename_wiki_page` | Wiki ページ名変更 |

### フォーラム

| ツール | 説明 |
|------|-------------|
| `list_boards` | プロジェクトフォーラムボード |
| `list_board_topics` | 選択したボードのトピック |
| `get_board_message` | 簡潔な返信付きフォーラムメッセージ |

### ファイル

| ツール | 説明 |
|------|-------------|
| `list_project_files` | プロジェクトファイル |
| `upload_file` | ファイルアップロード |
| `delete_attachment` | 添付ファイルを削除 |
| `get_attachment` | 添付ファイルメタデータと `content_url` |
| `download_attachment` | 添付ファイル内容（`content_base64`、最大 10 MiB） |

### ユーティリティ

| ツール | 説明 |
|------|-------------|
| `get_mcp_info` | MCP プラグインバージョン、読み取り専用モード、現在のユーザー、利用可能な capabilities |

### アクセスと応答

Tools は `structuredContent` 内の JSON エンベロープと `content` 内のテキスト表現を返します。

Write 操作は **読み取り専用モード** 設定でブロックされます。

ツール固有の権限に加え、グローバル権限 **MCP を使用** が常にチェックされます。

データアクセスは標準の Redmine 権限と可視性ルールで強制されます。プロジェクトと課題データには `Project.visible` と `Issue.visible` が使用されます。

## 他プラグインからの拡張

インストール済みの Redmine プラグインは、必要に応じて独自の MCP tools を追加し、resources、prompts、capabilities を登録できます。

詳細ガイド: [extension_guide.md](extension_guide.md)。

Cursor や類似エージェントでの AI 支援開発には、同梱の skill ディレクトリ [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) を AI エージェントの skills フォルダにコピーするか、独自 skill の基礎として使用してください。

## ログ

メッセージは `[redmine_mcp]` プレフィックス付きで標準 Rails ログに書き込まれます:

- 拡張の読み込み
- tool/resource/prompt の登録
- 登録および実行エラー
- アクセス拒否

## トラブルシューティング

| 症状 | 考えられる原因 |
|---------|-------------------|
| HTTP 503 «MCP is disabled» | プラグイン設定で MCP が有効になっていない |
| HTTP 401 | API キーが無効または欠落; REST API が無効 |
| HTTP 403（権限） | ユーザーに **MCP を使用** の権限がない |
| HTTP 403（`Host`/`Origin`） | **ホスト名とパス** が Redmine の公開 URL と一致しない; reverse proxy が元の `Host` を転送しない; クライアントの MCP URL が一致しない — transport が未知の host を拒否（DNS rebinding 対策） |
| `tools/list` に tool が表示されない | 必要な権限がない; tool を提供する拡張が無効 |
| MCP reload 後に新しい tools が表示されない | Cursor などのクライアントではサーバーの reload では tool リストが更新されない場合がある — アプリケーションを完全に再起動する |
| 拡張が読み込まれない | `lib/.../mcp.rb` がない; モジュールが `extend RedmineMcp::ExtensionApi` していない; **MCP 拡張** で拡張チェックボックスが有効か確認; ファイルにエラーがある場合はログを確認 |
| `Issue not found` / `Project not found` | Redmine の可視性ルールにより、課題またはプロジェクトが現在のユーザーに表示されない |

## ライセンス

このプラグインは GNU General Public License
バージョン 2 またはそれ以降のバージョンの下でライセンスされています。

詳細は [LICENSE](../../../LICENSE) を参照してください。
