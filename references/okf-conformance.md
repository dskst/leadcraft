# OKF 準拠規約（leadcraft）

leadcraft が生成する成果物ツリー（`<root_dir>/` 配下）は **Open Knowledge Format (OKF) v0.1** に準拠した
**Knowledge Bundle** として扱う。全スキルは本ドキュメントの規約に従って frontmatter・リンク・予約ファイルを生成する。

OKF 仕様: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

> OKF は「ツール不要で人間が読め、AI が解析でき、バージョン管理に乗り、組織を越えて持ち運べる」ことを狙う最小限の
> フォーマット。markdown + YAML frontmatter のディレクトリツリーであり、スキーマレジストリも中央権威も必須ツールも持たない。

## 1. バンドルとコンセプト

| OKF 用語 | leadcraft での対応 |
|----------|--------------------|
| Knowledge Bundle | `<root_dir>/`（既定 `docs/objectives/`）配下のツリー全体 |
| Concept（概念ドキュメント） | 各 `README.md`（Objective/Initiative/Epic）、Story md、ADR、Design Doc、`stories-draft.md` |
| Concept ID | バンドルルートからの相対パスから `.md` を除いたもの（例: `customer-retention-2026/framework-modernization-a1b2c/oauth-login-a1b2c/README`） |
| 予約ファイル | `index.md`（ディレクトリ目次）/ `log.md`（時系列履歴）。これらは概念ではない |

## 2. frontmatter 規約

**すべての非予約 `.md`（概念ドキュメント）は、パース可能な YAML frontmatter と非空の `type` を持たねばならない**（OKF 適合の必須条件）。

### 必須

- `type` … 概念の種別。leadcraft の許容値: `objective` | `initiative` | `epic` | `story` | `adr` | `design-doc` | `stories-draft`

### 推奨（OKF が推奨する順）

- `title` … 人間可読の表示名
- `description` … **1 文の要約**。`index.md` の progressive disclosure と AI の関連度判定の土台になる。全概念に必ず付ける
- `resource` … 基礎となる資産を指す URI。例: Story なら同期済み Issue の URL、Epic なら Issue 一覧フィルタ URL、Objective なら Projects URL。無ければ `null`
- `tags` … 横断検索用の文字列リスト（トラッカーの label を使う運用ならその値をミラーリングする）
- `timestamp` … ISO 8601 の最終更新日時（例: `2026-06-24T09:30:00Z`）。`updated_at` と同値でよい

### 拡張フィールド（leadcraft 固有・OKF の Extension 扱い）

`id` / `id_suffix` / `status` / `created_at` / `updated_at` / `owner` / `objective` / `initiative` / `epic` /
`points` / `estimation` / `risks` / `risk_score` / `dependencies` / `tracker_ref` 等は OKF の拡張フィールド。
**OKF 消費側は未知のキーを許容する**ため、これらは自由に保持してよい。

> `timestamp` は OKF 標準キー、`created_at` / `updated_at` は leadcraft 拡張。両方を保持し、`timestamp` は
> `updated_at` と同じ値を入れる（OKF 対応ツールは `timestamp` を、leadcraft スキルは `updated_at` を見る）。

## 3. 予約ファイル

### `index.md`（ディレクトリ目次）

- バンドルの各階層（root / Objective / Initiative）に置ける。frontmatter は不要
- 子コンセプトを見出し + 1 文 description のリストで列挙し、progressive disclosure を提供する
- **バンドルルートの `index.md` は `okf_version: "0.1"` を宣言する**（leadcraft は frontmatter に `okf_version: "0.1"` を置く方式を採る）
- 生成は `build-bundle` スキルが担当（compose 系スキルは index.md を直接書き換えない）

### `log.md`（時系列履歴）

- 任意。各階層に置ける
- ISO 8601 日付（`YYYY-MM-DD`）でグルーピングし、新しい順に並べる
- 各エントリは action 種別（Creation / Update / Deprecation）を含む
- compose 系・review 系スキルは概念を新規作成・更新した際に該当階層の `log.md` に 1 行追記する

例:
```markdown
# Log

## 2026-06-24
- Update: oidc Epic の DoD を改訂（ステークホルダーデモ条件を追加）
- Creation: Story `password-reset.md` を作成

## 2026-06-20
- Creation: oidc Epic を作成
```

## 4. クロスリンク規約

- **内部リンクはバンドル絶対パス（`/` 始まり、バンドルルート相対）を優先する**（OKF 推奨。ディレクトリ再編に強い）
  - 例: `/customer-retention-2026/increase-usage-a1b2c/oidc-a1b2c/README.md`
  - 親子関係は frontmatter の `objective` / `initiative` / `epic` ID から絶対パスを組み立てられる
- リンクは関係を主張するだけで、意味（親子・参照・依存）は周囲の散文から導く
- **消費側は壊れたリンクを正常として許容する**ため、リンク切れを過度に恐れない

## 5. 慣用見出し

OKF は本文に次の慣用見出しを推奨する。leadcraft では:

- `# Citations`（出典）… ADR / Design Doc がコードベース調査で得た `file:line` 根拠をこの見出し下にまとめる
- `# Examples`（例）… Epic のユーザーフロー等、具体例を置く場合に使う
- `# Schema` … 構造化資産の記述（leadcraft では通常未使用）

## 6. 適合条件（conformance）

バンドルが OKF 適合と見なされる条件:

1. すべての非予約 `.md` がパース可能な YAML frontmatter を持つ
2. すべての frontmatter が非空の `type` を持つ
3. 予約ファイル（`index.md` / `log.md`）が本規約の構造に従う

`build-bundle` スキルは出力前にこの 3 条件を検証する。
