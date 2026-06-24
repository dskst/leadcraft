# トラッカー抽象契約（leadcraft）

leadcraft の Story 層（および Hotfix）は、特定のトラッカー（GitHub Issue / Projects など）に直接依存しない。
スキルは本ドキュメントが定義する **抽象操作** だけを呼び、具体コマンドは `references/backends/<provider>.md` の
**アダプタ** が提供する。これにより、新しいトラッカー対応はアダプタ 1 ファイルの追加で完結する。

## 1. provider の解決

設定ファイル `.claude/leadcraft.md` の `tracker.provider` で決まる。

| provider | 状態 | アダプタ |
|----------|------|----------|
| `local` | **既定**。外部依存ゼロ。Story = `<epic-dir>/<slug>.md`（OKF concept） | `references/backends/local.md` |
| `github` | opt-in。Story = GitHub Issue + Projects v2 | `references/backends/github.md`（Phase 2） |

スキルは起動時に provider を読み、対応するアダプタの「操作 → 具体手順」マップを参照する。
`--local` / `--github` 引数で都度オーバーライドできる。

## 2. 抽象操作（Tracker Operations）

すべてのアダプタは以下の操作を実装する。スキル本文ではこの**操作名**で記述し、`gh` 等の具体コマンドを直書きしない。

| 操作 | 引数 | 戻り値 | 意味 |
|------|------|--------|------|
| `create_item` | title, body, item_type(story/hotfix), labels[] | item_ref | 作業項目を作成する |
| `update_item` | item_ref, {title?, body?} | — | 既存項目の本文・タイトルを更新する |
| `get_item` | item_ref | {title, body, fields, labels} | 項目を取得する |
| `list_items` | {label?, status?, epic?} | item_ref[] | 条件で項目を列挙する |
| `add_comment` | item_ref, body | — | 項目にコメント（フォローコメント等）を付ける |
| `set_field` | item_ref, field_name, value | — | 階層タグ・Points・Risk Score・Status を設定する |
| `add_label` | item_ref, label | — | ラベル / タグを付与する |
| `remove_label` | item_ref, label | — | ラベル / タグを外す |
| `ensure_label` | label, color? | — | ラベルの存在を保証する（無ければ作成） |
| `resource_uri` | item_ref | URI or null | OKF `resource` に入れる URI を返す |

### item_ref（項目参照）

provider 非依存の不透明な識別子。

- `local`: バンドル絶対パス（例: `/obj/init/epic/password-reset.md`）
- `github`: Issue 番号（例: `123`）

スキルは item_ref の内部形式に依存しない。OKF concept の frontmatter には `tracker_ref` として保存する。

## 3. フィールド名（field_name）の正規語彙

`set_field` で使うフィールド名は provider 非依存の正規語彙を使う。アダプタが provider 固有名（Projects の
フィールド ID 等）へマッピングする。

| 正規名 | 意味 | local での保存先 | github での保存先 |
|--------|------|------------------|-------------------|
| `objective` | 親 Objective | frontmatter `objective` | Projects フィールド |
| `initiative` | 親 Initiative | frontmatter `initiative` | Projects フィールド |
| `epic` | 親 Epic | frontmatter `epic` | Projects フィールド |
| `points` | 見積もりポイント | frontmatter `points` | Projects Number フィールド |
| `risk_score` | リスクスコア | frontmatter `risk_score` | Projects Number フィールド |
| `status` | ステータス | frontmatter `status` | Projects Status |

## 4. ラベル / ステータスの正規語彙

トラッカーに依存しない概念語を使い、アダプタが具体表現へ変換する。

| 正規概念 | 意味 |
|----------|------|
| `story` | すべての Story 項目に付く基本タグ |
| `draft` | 詳細設計済み・品質ゲート未通過 |
| `quick` | 簡易作成された叩き台 |
| `hotfix` | 緊急対応 Story |
| `ready` | 品質ゲート通過後（任意） |
| `epic:<epic-id>` | Epic 単位の絞り込みタグ |

`local` アダプタはこれらを frontmatter の `status` / `labels[]` に保存する。
`github` アダプタは Issue ラベルに対応させる。

## 5. graceful degradation

- provider 設定が未完（例: github で `tracker.github.project.number` 未設定）の場合、アダプタは
  実行可能な操作だけ行い、不可能な操作（Projects 追加等）はスキップして警告する
- `local` は外部依存ゼロのため常に全操作が成功する。**OSS のゼロ設定起動はこれを既定にすることで成立する**

## 6. スキル実装ルール

1. スキル本文に `gh ...` を直書きしない。抽象操作名で書く
2. provider 固有の手順が必要な箇所は「アダプタ（`references/backends/<provider>.md`）の `<操作>` を参照」と記述する
3. OKF concept の frontmatter（local の Story md）が常に source of truth。github はそこからの同期先
