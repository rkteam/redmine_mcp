# 組み込みツール（コアツール）

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## 概要

Redmine MCP プラグインは、Redmine のプロジェクト、課題、時間記録、Wiki、フォーラム、ファイル、参照データ（読み取りと書き込み）を操作するためのツールセットを提供します。

## 目的

追加プラグインをインストールせずに、AI クライアントにプロジェクト管理、課題操作、時間記録、探索、検索と Wiki、フォーラム、ファイル操作、メタ操作を提供すること。

## 影響範囲

- プロジェクト
- バージョン
- メンバー / ロール
- 課題（CRUD、relations、watchers、notes、categories、form options、dry-run validation、保存クエリ）
- 時間記録
- トラッカー、ステータス、優先度、クエリ
- プロジェクト活動
- Wiki ページ
- フォーラム / メッセージ
- プロジェクトファイル / 添付ファイル
- ユーザー
- 権限
- 設定（読み取り専用モード）

## ビジネスルール

### 一般ルール

- ツールの完全名: `redmine_<name>`（例: `redmine_get_issue`）。
- 結果は `structuredContent` 内の JSON エンベロープとして返され、`content` 内のテキストとしても重複されます。
- データは Redmine のプロジェクト/課題の可視性と権限を通じてフィルタリングされます。
- `project` パラメータは文字列: 数値 id を文字列として（例: `"1"`）、またはプロジェクト識別子（例: `"ecookbook"`）。
- **Read-only mode** が有効な場合、書き込みツールはエラーを返します。`list_issue_relations`、`get_issue_form_options`、`validate_issue_create`、`validate_issue_update` を含む読み取り専用ツールは引き続き利用可能です。

### プロジェクト管理

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### 課題操作

| Tool | R/W | 権限 |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | attributes — 編集可能な場合; `uploads` のみ — 添付ファイルを追加できる場合 |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` には追加で `set_notes_private` が必要 |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | ソースプロジェクトで `copy_issues`、ターゲットで `add_issues` |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | ジャーナルエントリが表示・編集可能（`edit_issue_notes` / `edit_own_issue_notes`）; `private_notes` には追加で `set_notes_private` が必要 |
| `set_issue_note_private` | W | ジャーナルエントリが表示・編集可能、かつ `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### ユーザー

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; `project` なし — 管理者のみ |
| `list_groups` | R | `manage_members`（任意のプロジェクト）または管理者 |

### 時間記録

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | 現在のユーザーが編集可能なエントリ（`edit_time_entries` / `edit_own_time_entries`） |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### 探索 / 列挙

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### 検索と Wiki

| Tool | R/W | 権限 |
|------|-----|------------|
| `search_all` | R | 検索対象の少なくとも 1 種類へのアクセス（`view_issues` および/または `view_wiki_pages`） |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; 履歴 `version` には追加で `view_wiki_edits` が必要 |
| `create_wiki_page` | W | `edit_wiki_pages` かつページが編集可能であること |
| `update_wiki_page` | W | `edit_wiki_pages` かつページが編集可能であること |
| `delete_wiki_page` | W | `delete_wiki_pages` かつページが編集可能であること |
| `rename_wiki_page` | W | `rename_wiki_pages` かつページが編集可能であること |

### フォーラム

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### ファイル操作

| Tool | R/W | 権限 |
|------|-----|------------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files`（またはコンテナ権限） |
| `get_attachment` | R | 添付ファイルコンテナの権限 |
| `download_attachment` | R | 添付ファイルコンテナの権限 |

### Meta

| Tool | R/W | 権限 |
|------|-----|------------|
| `get_server_info` | R | `use_mcp` |

`get_server_info` は `server_version`、`read_only_mode`、`auth_mode`、現在のユーザーの簡易データ、`capabilities.issue_search` を返します。サードパーティプラグインのインストールはレスポンスに含まれません: その MCP ツールは `tools/list` および拡張が自身で登録する `capabilities` を通じて表示されます。

`capabilities.issue_search` には検索モードが含まれます:

| モード | デフォルト | 備考 |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | 常に |
| `cross_resource` | `available: true`, tool `redmine_search_all` | 常に |
| `semantic` | `available: false` | プラグインは `register_capability(:issue_search, :semantic)` で上書き可能 |

`semantic.available: true` の場合、capability には `tool`、`provider`、`use_when` / `avoid_when` を含める MUST — セマンティック検索を選ぶべきタイミングの簡潔なヒント。`Registry#apply_capabilities` はプロバイダーのレスポンスを正規化します: 契約違反の場合、`{ available: false }` が公開されます。

### 補足

- `confirm_delete` なしの `delete_issue` は影響プレビューを返します; **任意の**サブタスク（ユーザーに見えないものを含む）がある場合、`confirm_delete_with_children` が必要です。`impact` のカウンターは、現在のユーザーに表示されるジャーナル、関連、時間記録、子、添付ファイルのみをカバーします。
- `scope=subprojects` の `search_issues` には `project` が必要で、そのプロジェクトと子孫で検索します。`project` なしでは、そのスコープはパラメータエラーです。`scope=my_project` はユーザーがメンバーであるプロジェクトに検索を限定します。
- `get_issue`: ジャーナル、添付ファイル、ウォッチャー、関連、子、カスタムフィールドは明示的な `include_*` がある場合のみ含まれます。ネストされたリストには個別の `limit`/`offset` と `*_pagination` フィールドがあります（ジャーナル: デフォルト limit 25、最大 100; その他のネストリスト: デフォルトおよび最大 100）。対応する `include_*` がない場合、リストは空でページネーションは `null` です。オプションフィールド（`custom_fields`、`journals`、`attachments`、`watchers`、`relations`、`children`）はレスポンスに常に存在します。カスタムフィールド — 現在のユーザーに表示されるもののみ。ジャーナル — Redmine の課題履歴と同じ可視性: エントリは、ユーザーに表示されるテキストまたは少なくとも 1 つの詳細変更がある場合のみ `journals` と `journal_pagination` に表示されます。スペース、タブ、改行のみのテキストは空として扱われます。空のエントリと非表示の詳細のみのエントリ（非表示のカスタムフィールドを含む）は、リストと `total_count` / `offset` / `has_more` の両方から除外されます。非公開コメント — 自分のコメント、または `view_private_notes` 権限を持つ場合。ジャーナル要素には表示可能な詳細変更のみが含まれます。関連 — 両側がユーザーに表示されるリンクのみ。同じ関連の可視性ルールは `list_issue_relations` にも適用されます。
- `get_private_notes` は非公開コメントでテキストが空でないもののみを返します（スペース、タブ、改行のみの内容は空テキストとみなされます）。ページは課題履歴全体を読み込まずに `limit`/`offset` で限定されます。
- `list_project_issue_custom_fields` はプロジェクトでユーザーに表示されるフィールドを返します。`tracker_id` が設定されている場合、トラッカーはプロジェクトに属している必要があります。
- `copy_issue` には**ソース**プロジェクトでの課題コピー権限と**ターゲット**での課題作成権限が必要です。ウォッチャーは、ターゲットプロジェクトでウォッチャー追加権限がある場合のみコピーされます。元へのリンクと添付ファイルのコピーは Redmine 設定 `link_copied_issue` と `copy_attachments_on_issue_copy`（`yes` / `no` / `ask`）に従います。フィールドの上書きがない場合でも、コピーはフォーム書き込みルールを通過します。ソース課題の親は許可される場合に保持されます（同一プロジェクト内のコピーを含む）。
- `create_issue_relation` は許可された関連属性のみを適用し、変更を課題ジャーナルに記録します。`delete_issue_relation` は、現在のユーザーが関連を削除できる場合のみ許可されます（両方の課題が表示され、少なくとも片方で関連管理権限がある）; 削除もジャーナルに記録されます。
- `add_project_member` / `update_project_member` は、現在のユーザーがプロジェクトで管理できるロールのみを受け付けます。そのセット外のロールは拒否されます; ロールは部分的に割り当てられません。
- `create_issue_category` / `update_issue_category`: `assigned_to_id` はプリンシパル ID（ユーザーまたはグループ）であり、ユーザーのみではありません。
- 課題添付ファイルの `delete_file` は「この課題の添付ファイルを削除できるか」のルールに従います（自分の課題とトラッカー権限を含む）、グローバル `edit_issues` のみではありません。`tools/list` では、ユーザーが少なくとも 1 つの添付ファイル（プロジェクトファイル、課題、Wiki）を削除できる場合にツールが表示され、グローバル `manage_files` のみではありません。
- `get_wiki_page`: `attachments` はレスポンスに常に含まれます; デフォルトは `[]` と `attachments_pagination: null`; `include_attachments=true` の場合 — `attachment_limit`/`attachment_offset`（デフォルトおよび最大 100）によるページネーション付き添付ファイルリスト。履歴 `version` には Wiki 編集の表示権限が必要です。保護されたページの変更、名前変更、削除には Wiki ページ保護権限が必要です。
- `list_issues`、`search_issues`、`list_subtasks`、`run_issue_query`: デフォルトは要約フィールド; 完全な説明は `fields` または `get_issue` 経由。
- `create_issue` と `update_issue` は明示的な課題**属性**（`subject`、`description`、`tracker_id`、`status_id`、`custom_fields` など）を受け付けます。明示的に渡されたすべての属性（作成時の `subject` と `description` を含む）は、Redmine Web フォームと同じ書き込みルールを通過します。作成/更新の前に、許可されたフィールド値が不明な場合、エージェントは `get_issue_form_options` を呼び出すべき（SHOULD）です。Redmine が適用しなかった明示的に渡された値は、部分的成功ではなくエラーになります。
- クライアントが `create_issue` / `validate_issue_create` で `start_date` を**渡さなかった**場合、Redmine で「開始日 = 作成日」が有効（`default_issue_start_date_to_creation_date`）であれば、MCP は `start_date` をユーザーの今日に設定します — 新規課題フォームと同様です。明示的な `start_date`（`null` を含む）はこの置換を無効にします。`copy_issue` と `update_issue` は日付を自身で置換しません。
- `update_issue` は `notes`、`private_notes`、`watcher_user_ids` を受け付けません。コメント — `add_issue_note`; ウォッチャー — `add_issue_watcher` / `remove_issue_watcher`。
- `update_issue` は課題へのファイル添付用に `uploads` もサポートします。添付ファイルは属性検証（`rejected_fields` を含む）が成功した後にのみ処理されます。属性なしで `uploads` のみの呼び出しは、ユーザーが課題に添付ファイルを追加できる場合に許可されます — コメントは許可されているが属性を編集できない場合を含みます。オプションの `idempotency_key` は、レスポンス喪失後のリトライから保護します（同じファイルの再アップロードを含む）。レスポンスの `journal_id` は**この**呼び出しのジャーナルエントリであり、最新の課題エントリではありません。
- オプションフィールドをクリアするには、`assigned_to_id`、`category_id`、`fixed_version_id`、`parent_issue_id`、`start_date`、`due_date`、`estimated_hours` に `null` を渡します。`update_version.due_date` / `wiki_page_title` と `update_issue_category.assigned_to_id` も同様です。
- `create_issue` は `uploads` をサポートしません。
- `update_issue` は `uploads[*].content_base64` と `uploads[*].filename` を受け付けます。アップロード成功後、レスポンスには `added_attachments` が含まれます — この呼び出しのファイルのみであり、課題の添付ファイルリスト全体ではありません。破損した Base64 はパラメータエラーです。
- `update_issue` は `status_name` を受け付け、`status_id` に解決します。
- `upload_file` は `content_base64`（最大 20 MiB）を受け付けます; `project`、`filename`、`content_base64` は必須です。
- `get_attachment` は `attachment_id`、`filename`、`content_type`、`size`（添付ファイルのファイルサイズ）、`content_url`（ファイルバイトなし）を返します。
- `download_attachment` は、現在のユーザーに表示される単一の添付ファイルについて `attachment_id`、`filename`、`content_type`、`size`（実際のコンテンツサイズ（バイト））、`content_base64` を返します。MIME が不明な場合 — `application/octet-stream`。`downloads` カウンターはインクリメントしません。サイズ制限は 10 MiB（読み取り前にディスク上の `File.size` と読み取り後の `bytesize` をチェック）; 超過時 — `FILE_TOO_LARGE`。サーバーファイルシステムパスはレスポンスに返されません。`attachment_id` は `redmine_get_issue` / `redmine_get_wiki_page` で `include_attachments=true`、`redmine_list_files`、または `redmine_get_attachment` から取得します。添付ファイルをファイルとして読み取り、解析、処理するには、ローカルで `content_base64` をデコードします。存在しない添付ファイルとアクセスできない添付ファイルは同じ「見つかりません」レスポンスを返します。
- `create_time_entry` と `import_time_entries.entries` の各項目には `hours` と `project` または `issue_id` のいずれかが必要です。`hours` は 0 でもよい; ゼロの妥当性と 1 日の最大値は Redmine がチェックします（`timelog_accept_0_hours`、`timelog_max_hours_per_day`）。
- 課題作成/更新の `assigned_to_id` はプリンシパル ID（`get_issue_form_options.assignees` のユーザーまたはグループ）; `null` は担当者をクリアします。`add_issue_watcher` / `remove_issue_watcher` の `user_id` はプリンシパル ID（ユーザーまたはグループ）です。他のツールでは、`user_id` はユーザー ID です。現在のユーザーには `assignee_ref` または `user_ref` で値 `me` を使用します。
- 機密な更新/削除の `expected_updated_at`（オプション）: `updated_on` と一致しない場合、`CONFLICT` を返します。
- `create_issue`、`copy_issue`、`update_issue`、`add_issue_note`、`create_time_entry`、`import_time_entries`、`upload_file` の `idempotency_key`（オプション）: 同じキーと**同じ引数セット**（キー自体を除く）でのリトライは、キャッシュされた成功結果を返します（TTL 24 時間）。同じキーで異なるペイロード — `CONFLICT`、重複書き込みなし。最初のリクエストがまだ実行中の場合、同じキーでのリトライは別の書き込みを行いません（「実行中」マーカーは成功結果と同じ 24 時間存続します）。フィンガープリントのないキャッシュエントリ（このバージョン以前のキャッシュ）は、TTL 期限まで以前と同様に同じキーで返されます。サーバータイムアウト 60 秒は**読み取り**に適用されます。書き込み操作はサーバータイムアウトで中断されないため、保存成功後にべき等性結果を記録できます; クライアントは接続を失った場合、同じキーでリトライできます。`import_time_entries` の予期しない例外は、その呼び出しで既に挿入されたエントリをロールバックします; 個別行の通常の検証エラーは、成功したものをロールバックせずに収集されます。
- デフォルトの `delete_file` はプロジェクト/バージョンファイルのみを削除します; 課題/Wiki 添付ファイルには `confirm_delete_any_attachment=true` が必要です。
- リスト/検索は `limit`/`offset` を使用します。DB クエリでは、既に読み込まれた完全なリストをトリミングするのではなく、クエリレベルでページが限定されます。ページネーション付き MCP コレクションには明示的な安定した順序があり、最後の基準は常に `id` なので、ページが項目をスキップしたり重複したりしません。
- 部分文字列検索（`query`、`login`、`name`、テキスト `search_issues`）は文字をリテラルに一致させます: `%` と `_` は SQL ワイルドカードではありません。
- MCP 制限: 読み取りツールのタイムアウト 60 秒、ユーザーあたりのレート制限 120 リクエスト/分、MCP リクエスト HTTP ボディ 36 MiB、最大 JSON ツール引数サイズ 32 MiB、アップロード base64 最大 20 MiB、ダウンロード base64 最大 10 MiB。任意の `content_base64` の破損した Base64 はツール実行前のパラメータエラーです。
- アクセス拒否を含むすべてのツール呼び出しは、構造化監査ログ（ツール、ユーザー、ターゲット ID、結果、所要時間、correlation_id）に記録され、レート制限にカウントされます; base64 コンテンツと非公開ノートはログに記録されません。ターゲット ID には `board_id`、`message_id`、`query_id`、`user_id`、`group_id` などが含まれます。
- 各コアツールの `outputSchema` は `data` のトップレベル（リストの場合 — `items` 要素フィールド）を記述し、任意のオブジェクトではありません。スキーマのフィールドセットは実際のレスポンスと一致します: `created_on` なしの `list_users`、`created_on` ありの `list_all_users`; `get_attachment` には `size` と `content_url` が含まれます。実際のレスポンスで空になりうるフィールドは `null` を許可します（`time_entry.issue`、include なしの `*_pagination`、`estimation_accuracy`、添付ファイルの `content_type` を含む）。カスタムフィールド値と `possible_values` はオブジェクトに限定されません。`attachments_not_saved` はファイル名の配列です。
- スキーマ内の `summarize_project_status.days`: デフォルト 30、最小 1、最大 365。
- `search_all.resources`: 最大 2 つの一意の値。
- `version_id`、`file_id`、`tracker_id` は 1 以上の整数です。

### `get_project`

- 入力: `project`（必須）。
- 出力: `id`、`name`、`identifier`、`description`、`homepage`、`status`、`is_public`、`inherit_members`、`created_on`、`updated_on`、`parent`（オブジェクト `id`/`name`/`identifier` または `null`）、`subprojects`（表示可能な子プロジェクトの簡易リスト: `id`/`name`/`identifier`）、`custom_fields`、`last_activity_date`。
- `parent` は親プロジェクトが現在のユーザーに表示される場合のみ入力されます; それ以外は `null`。
- メンバー、有効モジュール、課題統計は返しません。モジュール — `get_project_modules`; メンバー — `list_project_members`; 課題集計 — `summarize_project_status`。

### `get_issue_form_options`

- 作成/更新前の複数の参照ルックアップの代わりに 1 回の呼び出し。個別の `list_project_trackers`、`list_issue_statuses`、`list_issue_priorities`、`list_issue_categories`、`list_versions`、`list_users`、`list_project_issue_custom_fields` は引き続き利用可能です。
- 入力: `project`（必須）; オプションで `tracker_id`、`issue_id`。
- スナップショットはプロジェクト設定全体ではなく、**現在のユーザーの課題フォーム**を反映します: Redmine UI が提供するのと同じ許可値。
- `issue_id` なしの `tracker_id` は作成フォームのコンテキストを設定します。トラッカーは現在のユーザーがフォームで選択可能である必要があります; それ以外 — パラメータエラー。
- `issue_id` はこのプロジェクトの既存の表示可能な課題のフォームを設定します。`issue_id` がある場合、`tracker_id` は課題の現在のトラッカーと一致する場合のみ許可されます; それ以外 — パラメータエラー（トラッカー変更はこのツールではモデル化されません）。
- 出力 — ページネーションなしのフォームスナップショット:
  - `project`: `id`、`name`、`identifier`;
  - `trackers`: 現在のユーザーがこのフォームで選択できるトラッカー（`id`、`name`）、プロジェクトで有効なすべてのトラッカーではない;
  - `priorities`: アクティブな優先度（`id`、`name`、`is_default`）;
  - `categories`: プロジェクトカテゴリ（`id`、`name`）;
  - `versions`: このフォームで選択可能なバージョン（`id`、`name`、`status`、`due_date`）;
  - `assignees`: このフォームコンテキストで割り当て可能なプリンシパル。要素: `id`、`name`、`type`（`user` または `group`）; `user` の場合、追加で `login`。Redmine でグループへの課題割り当てが有効な場合、グループが含まれます;
  - `custom_fields`: プロジェクト/トラッカー、可視性、ワークフロー読み取り専用を考慮し、現在のユーザーがフォームで編集できるフィールドのみ。要素: `id`、`name`、`field_format`、`required`（フィールド必須またはワークフローで必須）、`readonly`（このリストでは常に `false`）、`multiple`、`default_value`、`possible_values`、`trackers`。フォームコンテキスト — `issue_id` の課題、または `tracker_id` を考慮した作成ドラフト;
  - `possible_values` — オブジェクト `{ "label": "...", "value": "..." }` の配列。別ラベルのないリストでは、`label` は `value` と一致します。ユーザー/バージョン/列挙の場合、`label` は表示名、`value` は識別子;
  - `statuses`: 現在のユーザーにワークフローで許可されたステータス。`issue_id` あり — この表示可能な課題の遷移。`issue_id` なし — 作成の初期ステータス（`tracker_id` が設定されている場合は考慮）;
  - `editable_fields`: 現在のユーザーがフォームで設定できる作成/更新でこの MCP 契約が受け付ける属性名、および文字列としての編集可能なカスタムフィールド id。`notes`、`private_notes`、`watcher_user_ids`、および MCP 書き込みツールにない他の Web フォームフィールドは含まれません;
  - `required_fields`: 現在のユーザーのこのフォームで必須のフィールド名、`editable_fields` と同じ名前形式。
- 存在しない `tracker_id`、ユーザーに許可されていないトラッカー、プロジェクト外の `issue_id` / 非表示 — パラメータエラー。

### `add_issue_note`

- 課題属性を変更せずに、既存の表示可能な課題にコメントを追加します。
- 入力: `issue_id`（必須）、`notes`（必須）、オプションで `private_notes`、`uploads`、`idempotency_key`。
- 権限: ユーザーはこの課題にコメントを追加できます。`private_notes=true` には非公開コメント作成権限が必要; それ以外 — 拒否、コメントは作成されません。同じ呼び出しの添付ファイルは、ユーザーが課題に添付ファイルを追加できる場合に許可されます。
- 課題フィールドやウォッチャーリストは受け付けません。
- 出力: `issue_id`、`journal_id`、`notes`、`private_notes`; `uploads` あり — `added_attachments`（この呼び出しのファイルのみ）。
- Read-only mode では利用不可。

### `update_issue_note` / `set_issue_note_private`

- 現在のユーザーが**見える**ジャーナルエントリでのみ動作します（非公開コメント表示権限のない他ユーザーの非公開コメントはアクセス不可）。
- エントリは現在のユーザーが編集可能である必要があります（コメント編集権限または自分のコメント編集権限）。
- `update_issue_note.notes` は空文字列でもよい（既存エントリのテキストをクリア）。`add_issue_note` による新規コメントは空にできません。
- プライバシー変更（`private_notes` / `is_private`）には、コメントを非公開にする別の権限が必要; それ以外は拒否、テキストは部分的に変更されません。
- ジャーナルエントリを編集したユーザーを記録します。
- Read-only mode では利用不可。

### `validate_issue_create` / `validate_issue_update`

- 書き込みツールの `validate_only` パラメータではなく、別の読み取り専用ツール。Read-only mode で利用可能。
- `validate_issue_create`: `create_issue` と同じフィールド、`idempotency_key` なし。`project` と `subject` は必須。権限 `add_issues`。
- `validate_issue_update`: **課題属性**のみのドライラン（`update_issue` と同様、`uploads` なし）。`issue_id` は必須。課題は現在のユーザーが編集可能である必要があります。検証前に、DB 書き込みなしでユーザージャーナルコンテキストが作成されます（実際の更新と同様）。
- 動作: 属性を課題に適用するが保存しない。Redmine データは変更されません。
- 属性は Redmine Web フォームと同じ書き込みルールを通過します。クライアントが値を**明示的に渡し**、Redmine が適用しなかった場合、それは成功ではなく MCP エラーです。
- 課題で書き込み可能でない明示的なフィールド（無効 / ワークフロー読み取り専用 / 派生日付など）は `rejected_fields` に入ります。`tracker_id`、`status_id`、`assigned_to_id`、`is_private`、`parent_issue_id`、`custom_fields` については、要求された値が実際に適用されたかどうかが追加でチェックされます。
- 同じルールは `create_issue`、`update_issue`、`copy_issue` に適用されます: 明示的に要求された値が適用されなかった場合、書き込みなし。
- 成功: `{ "valid": true, "errors": [] }`。
- 失敗: `{ "valid": false, "errors": ["..."] }`。一部の明示的フィールドが適用されなかった場合 — さらに `rejected_fields`（フィールド名、例: `["tracker_id"]`）および、典型的なエラーの場合 — create/update と同じ形式の `missing_required_fields` / `hint`。
- また検出: 現在のユーザーに利用不可のトラッカー; 無効または利用不可のカスタムフィールド値; ワークフローで禁止されたステータス遷移; 割り当てに利用不可の担当者。

### `list_issues` — 拡張フィルター

- 既存のフラットフィルター（`project`、`status_id`、`tracker_id`、`assigned_to_id` / `assignee_ref`、`priority_id`、`fixed_version_id`、`sort`、`fields`）は保持されます。
- オプションの `filters`: オブジェクト `{ "field": "...", "operator": "...", "values": ["..."] }` の配列。`values` は文字列の配列; 値のない演算子では空配列が許可されます。
- 許可される `field`: `status_id`、`tracker_id`、`assigned_to_id`、`priority_id`、`fixed_version_id`、`category_id`、`subject`、`due_date`、`start_date`、`created_on`、`updated_on`、`estimated_hours`、`done_ratio`、`author_id`、`watcher_id`、および課題カスタムフィールドの `cf_<id>`。
- 演算子は標準の Redmine クエリ演算子で、`=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*` を含みます。演算子はフィールドタイプに対して有効である必要があります; それ以外 — パラメータエラー。
- 不明な `field` または無効な `operator` — パラメータエラー、クエリは実行されません。
- フラットフィルターと `filters` は AND で結合されます。
- フィルターは現在のユーザーに表示される課題にのみ適用されます。

### `run_issue_query`

- 入力: `query_id`（必須、`list_queries` から）; オプションで `project`、`fields`、`limit`/`offset`。
- 現在のユーザーに表示される保存済み課題クエリを実行します。レスポンス形式は `list_issues` と同じリストエンベロープです。
- クエリがプロジェクトスコープの場合、結果はそのプロジェクト（およびクエリ可視性ルール）に限定されます。プロジェクトクエリのオプション `project` はクエリのプロジェクトと一致する必要があります; それ以外 — パラメータエラー。
- クエリがグローバルの場合、オプション `project` は選択をその表示可能なプロジェクトに絞り込みます。
- 非表示または存在しない `query_id` — エラー。
- `list_queries` はクエリを実行しません; 実行には `run_issue_query` を使用します。

### `list_project_activities`

- 入力: `project`（必須）; オプションで `from`、`to`（日付 `YYYY-MM-DD`）、`author_id`、`event_types`（文字列の配列）、`limit`/`offset`。
- デフォルトウィンドウ — 直近 7 日（`to` = 今日、`from` = 今日の 6 日前）。最大ウィンドウ長 — 90 日; 超過時 — パラメータエラー。
- プロジェクトアクティビティフィードのイベント: タイプ、時刻、作成者（`id`/`name`）、`title`、`description`、`url`。順序 — 新しいイベントが先; 同じ時刻の場合 — 大きい `id` が先。
- 他の `list_*` と同様のエンベロープ。
- `event_types` はイベントタイプを限定します。ユーザーに利用不可またはプロジェクトで無効なタイプは選択から除外されます（エラーなし）。
- 存在しない `author_id` — 空リスト、エラーではありません。

### `summarize_project_status`

既存フィールドは保持されます: `project_id`、`project_name`、`analysis_period_days`、`recent_activity`（`created_count`、`updated_count`）、`totals`（`issues_count`、`open_count`、`closed_count`）、`status_breakdown`、`priority_breakdown`、`assignee_breakdown`。

`days` ウィンドウ（デフォルト 30、範囲 1–365）は引き続き `recent_activity` と以下に記載の期間メトリクスに影響します。範囲外の値はスキーマで拒否されます。`totals` と breakdown は、日付フィルターなしで表示可能なプロジェクト課題全体について計算され、DB 集計により、すべての課題をメモリに読み込まずに行われます。サブプロジェクトは含まれません。

追加フィールド:

- `overdue_count` — `due_date` がユーザーの今日より厳密に前の、開いている表示可能な課題の数。
- `unassigned_count` — 担当者のない開いている表示可能な課題の数。
- `stale_issues_count` — `updated_on` が `days` ウィンドウの開始より古い開いている表示可能な課題の数。
- `issues_closed_during_period` — `closed_on` が `days` ウィンドウ内の表示可能な課題の数。
- `estimated_hours` — 表示可能なプロジェクト課題の見積もりの合計（見積もりがない場合は `null`、それ以外は 0 を含む数値）。
- `spent_hours` — 表示可能なプロジェクト課題に費やされた時間の合計（エントリがない場合は 0）。プロジェクトで `view_time_entries` が必要; 権限がない場合、フィールドは `null`。
- `average_resolution_hours` — `days` ウィンドウでクローズされた課題の `(closed_on - created_on)` の平均時間（時間）; 該当課題がない場合は `null`。
- `estimation_accuracy` — ウィンドウでクローズされ、見積もりと非ゼロ/記録済み時間の両方がある課題について: `{ "issues_count", "total_estimated", "total_spent" }`。該当課題がない場合 — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`。プロジェクトで `view_time_entries` が必要; 権限がない場合、フィールドは `null`。
- `reopened_count` — `days` ウィンドウ内でジャーナルステータスがクローズからオープンに変更された表示可能な課題の数。各課題は最大 1 回カウントされます。

このツールはテキストの「プロジェクト健全性分析」ではなく、事実を返します。

### `get_version`

- 入力: `version_id`（必須）; オプションで `project`。`project` が設定されている場合、バージョンはこの表示可能なプロジェクトの共有バージョンにある場合にアクセス可能です（バージョンのソースプロジェクトがユーザーに表示されなくても）。`project` なしでは、バージョンはソースプロジェクトで表示可能である必要があります。
- 出力: `list_versions` 要素と同様のフィールド（`id`、`name`、`description`、`status`、`due_date`、`sharing`、`wiki_page_title`、`project`、`created_on`、`updated_on`）に加え、集計: `issues_count`、`open_issues_count`、`closed_issues_count`、`estimated_hours`、`spent_hours`、`completed_percent`。
- 集計は現在のユーザーに表示されるバージョン課題のみについて計算されます。
- 課題リストは返されません。
- `spent_hours` にはバージョンのプロジェクトで `view_time_entries` が必要; 権限がない場合 — `null`。表示可能なバージョン課題のみ、かつ現在のユーザーが見られる時間記録のみの合計（`time_entries_visibility=own` を含む）。

### フォーラム

- プロジェクトのフォーラムモジュールが有効である必要があります; それ以外はエラー「Boards module is not enabled for this project」（Wiki の類似）。
- 権限 `view_messages`。フォーラムの書き込み操作はありません。
- `list_boards`: `project` 必須; ページネーション。要素: `id`、`name`、`description`、`parent_id`（ルート掲示板は `null`）、`topics_count`、`messages_count`。
- `list_board_topics`: `board_id` 必須; ページネーション。ルートメッセージのみ（親なし）。要素: `id`、`subject`、`author`、`created_on`、`updated_on`、`replies_count`、`board_id`。
- `get_board_message`: `message_id` 必須。出力: `id`、`subject`、`content`、`author`、`created_on`、`updated_on`、`board`（`id`/`name`）、`project`（`id`/`name`/`identifier`）、`parent_id`、`replies` — 各返信の全文なしの簡易返信リスト（`id`、`subject`、`author`、`created_on`）、`replies_limit`/`replies_offset`（デフォルトおよび最大 100）と `replies_pagination` 付き。
- 非表示の掲示板/メッセージ、または別プロジェクトの掲示板 — 「見つかりません」エラー。

### `list_users`

- `project` あり: アクティブな**ユーザー**プロジェクトメンバー（権限 `view_members`）。プロジェクトのグループメンバーシップはグループとして表示されません; グループのユーザーは自身がメンバーの場合のみ。`project` なし — 管理者のみ。
- 要素: `id`、`login`、`firstname`、`lastname`、`mail`。`created_on` は含まれません（そのフィールドは `list_all_users` にあります）。
- オプション `query`: `login`、`firstname`、`lastname` の大文字小文字を区別しない部分文字列。
- 互換性のためオプション `login` は保持されます（login の部分文字列のみ）。`query` と `login` の両方が設定されている場合、両方の条件が適用されます（AND）。

### `list_groups`

- 付与可能なグループ（`id`、`name`）のページネーションリスト、現在のユーザーに**表示**され、`add_project_member` で `group_id` を選択するため。
- オプション `query`: グループ名の大文字小文字を区別しない部分文字列; `%` と `_` はリテラルに一致します。
- 権限: 管理者、または少なくとも 1 つの表示可能なプロジェクトで `manage_members`。
- グループメンバーシップやメンバーシップは返しません。

### `list_project_member_candidates`

- プロジェクトに追加する候補: まだプロジェクトにいないアクティブな表示可能なユーザーとグループ。
- 入力: `project`（必須）; オプションで `query`（部分文字列、Redmine メンバーピッカーと同様）。
- 出力リストエンベロープ: `id`、`name`、`type`（`user` または `group`）; ユーザーの場合、追加で `login`。
- プロジェクトで権限 `manage_members`。
- `add_project_member`: ユーザーのみ `user_id`、グループのみ `group_id`。誤ったタイプの ID — パラメータエラー。追加前に、このツール（または候補が既知の場合は `list_users` / `list_groups`）から ID を取得します。

### `list_roles`

- 指定プロジェクトで現在のユーザーが管理できるロールのみ。
- 入力: `project`（必須）。
- プロジェクトで権限 `manage_members`。
- 管理者の場合、セットは割り当て可能なプロジェクトロールと一致します（Non member / Anonymous なし）。

## エッジケース

- 存在しない/アクセスできないプロジェクトまたは課題 — `{ "error": "..." }`。
- Read-only mode — 書き込みツールに対してハンドラ呼び出し**前**に `{ "error": "MCP is in read-only mode..." }`、Extension API ツールを含む; validate/form options/list/get は引き続き利用可能。
- 空のリスト/検索結果 — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`。
- ページネーション付きリスト/検索は常に `data.items` と `meta`（`total_count`、`limit`、`offset`、`has_more`、`next_offset`）を返します。デフォルト limit 25、最大 100。
- すべての `list_*` ツール（参照を含む: trackers、statuses、roles、queries、boards、board topics など）は同じエンベロープを使用します。`get_issue_form_options`、`get_project`、`get_version`、`get_board_message`、`summarize_project_status`、および validate ツール — 単一オブジェクト、リストエンベロープではありません。
- `download_attachment`: 存在しない添付ファイルとアクセスできない添付ファイル — 同じ「見つかりません」エラー; ディスク上で読み取り不能なファイル — エラー; ディスク上または読み取り後のサイズが 10 MiB 超 — `FILE_TOO_LARGE`（制限は DB の小さい `filesize` では回避されません）。同じ区別不能な「欠落 / アクセスなし」ルール — `get_attachment` にも適用。
- `list_project_activities`: 90 日超のウィンドウ — パラメータエラー; `from` が `to` より後 — パラメータエラー。
- `run_issue_query`: 非表示クエリ — 存在しないものとして扱われます。
- 別プロジェクトの課題の `issue_id` 付き `get_issue_form_options` — パラメータエラー。
- その課題のトラッカーと等しくない `issue_id` と `tracker_id` 付き `get_issue_form_options` — パラメータエラー。
- Validate ツールは課題を作成せず、課題を更新せず、ジャーナルエントリを作成せず、`idempotency_key` を消費しません。
- MCP 経由の書き込みは Redmine モデルを通ります。モデルコールバックは実行されます; Web インターフェースのコントローラフックは呼び出されません。

## エラー処理

- 権限不足 — `tools/list` にツールが表示されない、または「Permission denied」。
- モデル検証エラー — `{ "error": "<messages>" }`（課題作成/更新および validate ツールには追加で、翻訳テキストを解析せずモデルエラーシンボルからのフィールド名として `missing_required_fields` と `hint`）。
- 無効な wiki/boards モジュール — 「見つかりません」ではなく別のエラーメッセージ。
- エンベロープ内の正規エラーコードはハンドラが明示的に設定します; コードはメッセージテキストから導出されず、ユーザーの言語に依存しません。

## テストシナリオ

1. `list_projects` / `list_issues` はページネーション付きエンベロープ `data.items` + `meta` を返します。
2. `include_*` なしの `get_issue` はジャーナル/添付ファイルを返しません; `include_journals` あり — ページネーション付きジャーナル。
3. テキストによる `search_issues` は課題を見つけます; `search_all` は複数タイプ検索時に wiki を含みます。
4. 有効なフィールドでの `create_issue` / `update_issue` は成功します; 権限なしまたは read-only — エラー。
4a. 開始日設定が有効で `start_date` なしの `create_issue` は今日の日付を設定します; 明示的な `start_date` または `null` はその設定で上書きされません。
5. `confirm_delete` なしの `delete_issue` は `INVALID_STATE` と impact を返します; 確認ありで削除します。
6. `create_time_entry` には `hours` と `project` または `issue_id` が必要です; `import_time_entries` はバッチを受け付けます。
7. Wiki モジュール有効時、`list_wiki_pages` / `get_wiki_page` / `create_wiki_page` が動作します。
8. `upload_file` には `filename` と `content_base64` が必要です; 課題添付ファイルの `delete_file` には確認が必要です。
9. `use_mcp` のないユーザーは MCP 認証を通過しません; ツール権限のないユーザーは `tools/list` に表示されません。
10. 同じ `idempotency_key` と同じ引数での `create_issue` リトライは重複を作成しません; 同じキーで異なる subject — `CONFLICT`。
11. 表示可能な課題添付ファイルの `download_attachment` は実際のコンテンツ `size` 付き `content_base64` を返します; ディスク上で 10 MiB 超のファイル（メタデータが小さくても）— `FILE_TOO_LARGE`; 存在しない添付ファイルとアクセスできない添付ファイルは区別できません。
12. 識別子による `get_project` は description、subprojects、`last_activity_date` を返します; アクセスできないプロジェクト — エラー。
13. プロジェクトの `get_issue_form_options` は trackers/statuses/priorities/categories/versions/assignees/custom_fields と `editable_fields` / `required_fields` リストを返します; `trackers` — 現在のユーザーに利用可能なもののみ; `issue_id` ありでステータスはその課題の許可された遷移を反映; `issue_id` + 異なる `tracker_id` — エラー; `possible_values` — `label`/`value` オブジェクト。
14. 無効なトラッカーまたはステータスの `validate_issue_create` は `valid: false` と `rejected_fields` を返し、課題を作成しません; read-only mode では呼び出しは成功します。
15. `filters`（`due_date` `<=` 日付、`priority_id` `!`）付き `list_issues` は一致する表示可能な課題のみを返します; 不明な `field` — エラー。
16. 表示可能な `query_id` の `run_issue_query` は UI の保存クエリと同じ課題を返します; 非表示クエリ — エラー。
17. 3 日間の `list_project_activities` はページネーション付きプロジェクトイベントを返します; 91 日ウィンドウ — エラー。
18. `summarize_project_status` には `overdue_count`、`unassigned_count`、`stale_issues_count`、`issues_closed_during_period`、`reopened_count` が含まれます。
19. `get_version` は課題リストなしで集計 `open_issues_count` / `completed_percent` を返します。
20. Boards モジュール有効時、`list_boards` / `list_board_topics` / `get_board_message` が動作します; 無効時 — モジュールエラー。
21. `project` と名前による `query` 付き `list_users` は login を知らずにメンバーを見つけます。
22. `get_issue_form_options` は `type` user/group の assignees と `required`/`readonly` のみの編集可能カスタムフィールドを返します。
23. Redmine が適用しない明示的に渡された値（無効/読み取り専用コアフィールド、作成時の `description` を含む）での `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` はエラーを返し、部分変更を保存しません。
24. `validate_issue_update` は notes を受け付けません; コメントは `add_issue_note` で作成されます。`add_issue_notes` 付き `add_issue_note` は `edit_issues` なしで成功します; `set_notes_private` なしの `private_notes` — 拒否。添付ファイル追加権限のみの `uploads` のみの `update_issue` は `edit_issues` なしで成功します。
25. `manage_members` を持つユーザー向けに `list_groups` は付与可能なグループを返します。
26. `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` の `update_issue` は、書き込み可能な場合にフィールドをクリアします。
27. `update_issue_note` / `set_issue_note_private` は、非公開コメント表示権限がない場合、他ユーザーの非公開コメントを変更しません。
28. コメント編集権限はあるが非公開化権限がないユーザーは、公開コメントのテキストを変更でき、プライバシーフラグは変更できません。
29. `uploads` 付き `add_issue_note` は 1 回の呼び出しでコメントと添付ファイルを作成します; 同じ `idempotency_key` でのリトライは重複しません。
30. `uploads` と `idempotency_key` 付き `update_issue`: 同じペイロードでのリトライは添付ファイルを重複しません; 同じキーで異なるファイル — `CONFLICT`。破損した Base64 — パラメータエラー。
31. `get_issue` は非表示のカスタムフィールド、非表示のジャーナル詳細、非表示課題との関連を返しません。`get_version` の集計は表示可能な課題のみです。
32. ソースプロジェクトでのコピー権限なしの `copy_issue` — ターゲットで `add_issues` があっても拒否されます。
33. ユーザーが管理できないロールでの `add_project_member` / `update_project_member` — 部分割り当てなしで拒否されます。
34. ユーザーに許可されていない `sharing` の `create_version` / `update_version` — 拒否。使用中バージョンの `delete_version` — 削除なしで拒否されます。
35. `edit_own_time_entries` を持つ時間記録作成者は `update_time_entry` で自分のエントリを更新できます。
36. `view_issues` なしで wiki 権限を持つユーザー向けに `search_all` が利用可能、検索に wiki が含まれる場合。
37. `list_project_member_candidates` はまだプロジェクトにいないユーザーとグループを返します; グループの `user_id` 付き `add_project_member` — エラー。
38. プロジェクトの `list_roles` はユーザーが管理できるロールのみを返します; `project` なし — スキーマエラー。組み込みの Non member と Anonymous は含まれません。
39. 同じ `idempotency_key` での `copy_issue` / `create_time_entry` リトライは重複を作成しません; 同じキーで異なるペイロード — `CONFLICT`。
40. `%` または `_` の `search_issues` とユーザー/グループ検索は、ワイルドカードではなくそれらの文字をリテラルに一致させます。
41. `time_entries_visibility=own` の `get_version.spent_hours` は自分の時間記録のみをカウントします。
42. `project` なしの `scope=subprojects` の `search_issues` — エラー; `project` ありで子孫の課題を見つけます。
43. `list_project_activities` は新しいイベントを古いものより前に返します。
44. `delete_issue` の impact には非表示ジャーナル、関連、他者の時間記録は含まれません; 非表示サブタスクでも `confirm_delete_with_children` が必要です。
45. `get_project` は現在のユーザーに表示されない親を返しません。
46. `due_date`/`wiki_page_title` = `null` の `update_version` はフィールドをクリアします。
47. `assigned_to_id` = `null` の `update_issue_category` はデフォルト担当者をクリアします。
48. スキーマは 0 の `hours` と 24 超の値を受け付けます; Redmine 検証のみが拒否します。
49. 空の `notes` 付き `update_issue_note` は既存コメントのテキストをクリアします。
50. `project` 付き `list_users` は、プロジェクトにグループメンバーシップがあってもユーザーのみを返します。
51. `view_wiki_edits` なしの履歴 wiki ページバージョンはアクセス不可; 保護ページは Wiki 保護権限なしでは変更できません。
52. ウォッチャー追加権限なしの `copy_issue` はウォッチャーをコピーしません; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` はリンクと添付ファイルを禁止します; 同一プロジェクト内の親は保持されます。
53. Read-only mode の拡張書き込みツールはハンドラを呼び出しません。
54. `delete_file` は `manage_files` なしで、課題添付ファイルを削除できるユーザー向けに `tools/list` に表示されます。
55. `add_issue_watcher` / `remove_issue_watcher` はグループプリンシパルを受け付けます。
56. `project` 付き `get_version` は、そのプロジェクトの `list_versions` が返した共有バージョンを返します。
57. `get_issue` / `get_wiki_page` / `get_board_message` は `limit`/`offset` でネストリストを限定し、`*_pagination` を返します; include なしではページネーションは `null` です。
58. nullable フィールドを含む実際のツールレスポンスは、公開された `outputSchema` と一致します。
59. `include_journals` 付き `get_issue`: 非表示カスタムフィールド詳細のみのジャーナルはリストに含まれず、`journal_pagination.total_count` にもカウントされません。
60. 2 つの表示可能エントリの間の非表示ジャーナルはページギャップを作りません: `journal_limit=2` で 2 つの表示可能エントリが返され、`total_count` は表示可能数と等しくなります。
61. 他ユーザーの非公開コメントは、`view_private_notes` 権限なしでは `get_issue` に返されません。
62. `get_private_notes` は課題履歴全体を読み込まずに `limit`/`offset` でページを返します。
63. ジャーナル `attr`、`cf`、`relation` を同時に持つ `get_issue` は失敗せず、表示可能なエントリのみを返します。
64. 非表示カスタムフィールド詳細とスペース、タブ、改行のみのノートを持つジャーナルは `get_issue` に含まれません。
65. `get_private_notes` はスペース、タブ、改行のみのコメントを返しません。
