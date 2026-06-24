# トラッカーアダプタ: local（既定）

`tracker.provider: local` のときに使うアダプタ。Story を `<epic-dir>/<slug>.md`（OKF concept）として扱い、
**外部サービスに一切依存しない**。leadcraft の source of truth はこのローカル md であり、他プロバイダはここからの同期先。

抽象操作の定義は `references/tracker-contract.md` を参照。本ファイルは各操作の **local 実装** を定める。

## item_ref

バンドル絶対パス（`/<objective>/<initiative>/<epic>/<slug>.md`）。実ファイルは `<root_dir>` を前置したパスで開く。

## 操作の実装

### create_item(title, body, item_type, labels[])

1. `<slug>` を title から生成（小文字・英数とハイフン、日本語は読みやすい transliteration か簡易要約）
2. `<epic-dir>/<slug>.md` に Story テンプレート（`skills/compose-stories/templates/story-local.md`）を展開して書き込む
3. frontmatter をセット:
   - `type: story`
   - `title`, `description`（1 文要約）
   - `status: draft`（quick の場合も draft 起点。`mode` で区別）
   - `mode: composed`（quick-stories からは `quick`）
   - `objective` / `initiative` / `epic`（親 ID）
   - `labels`: 渡された labels（`story` + `draft` または `quick`）
   - `tracker_ref`: 自身のバンドル絶対パス
   - `resource: null`（未同期）
   - `timestamp` / `created_at` / `updated_at`: 現在時刻（ISO 8601）
4. 該当 Epic の `log.md` に `Creation: Story <slug> を作成` を追記（`references/okf-conformance.md` §3）
5. item_ref（バンドル絶対パス）を返す

### update_item(item_ref, {title?, body?})

- 対象 md の本文・`title` を更新し、`updated_at` / `timestamp` を現在時刻に更新
- `log.md` に `Update:` 行を追記

### get_item(item_ref)

- 対象 md を Read し、frontmatter と本文セクションを返す

### list_items({label?, status?, epic?})

- `<epic-dir>/*.md`（または `<root_dir>` 配下を Glob）を走査し、frontmatter の `type: story` かつ
  条件（`labels` に label を含む / `status` 一致 / `epic` 一致）に合致するものを返す
- Epic README（`README.md`）・予約ファイル（`index.md` / `log.md`）は除外する

### add_comment(item_ref, body)

- local にコメント機構は無い。**本文末尾の対応セクションに追記する**:
  - DoD フォローコメント → 本文の `## Definition of Done` セクションに展開
  - review サマリー → 本文末尾に `## レビューサマリー（YYYY-MM-DD）` を追記
- github へ同期する際、これらは sync アダプタがコメントへ振り替える

### set_field(item_ref, field_name, value)

- frontmatter の対応キーに書き込む（`tracker-contract.md` §3 のマッピング）:
  - `objective`/`initiative`/`epic` → 同名キー
  - `points` → `points`（および `estimation.*` は estimate-points が別途更新）
  - `risk_score` → `risk_score`
  - `status` → `status`
- `updated_at` / `timestamp` を更新

### add_label / remove_label(item_ref, label)

- frontmatter の `labels[]` を編集する
- `draft` を外す（ready 卒業）場合は `remove_label(item_ref, "draft")`、必要なら `add_label(item_ref, "ready")`

### ensure_label(label, color?)

- local では no-op（ラベルは frontmatter の文字列にすぎず、事前作成不要）

### resource_uri(item_ref)

- local 単独では `null`（外部資産が無い）
- sync 後は frontmatter の `resource`（同期先 URI）を返す

## 設計上の不変条件

- frontmatter が常に唯一の真実。本文の表（見積もり詳細・リスク表）は frontmatter と連動させる
  （`estimate-points` / `identify-risks` が両方を同時更新）
- すべての Story md は OKF concept として `references/okf-conformance.md` §2 を満たす
