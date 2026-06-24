---
name: build-bundle
description: OKFバンドルを生成・検証するスキル。output.root_dir 配下のツリーを走査し、index.mdを作る・log.mdを整備する・OKF準拠チェックを実行する・知識バンドルをエクスポートする。「バンドルを検証」「OKF準拠チェック」「index.mdを再生成」「ルートのindex.mdが欲しい」「OKFバンドルを生成」「バンドルを仕上げる」「log.mdを補完して」と言われたら起動する。
argument-hint: "（任意：--check-only / --no-index / --no-log / --no-links）"
allowed-tools: Read, Write, Edit, Glob, Bash, Grep
---

# build-bundle

`<output.root_dir>` 配下の成果物ツリーを走査し、**OKF 0.1 準拠の Knowledge Bundle** に仕上げる・検証するスキル。

## 役割

leadcraft が生成するドキュメントツリーは OKF（Open Knowledge Format）v0.1 の Knowledge Bundle として扱われる
（詳細は `references/okf-conformance.md`）。このスキルは以下の 4 つの責務を担う。

1. **index.md 生成**（`okf.emit_index: true` の場合）: root / 各 Objective / 各 Initiative 階層に目次を生成
2. **log.md 整備**（`okf.emit_log: true` の場合）: 各階層の log.md が規約構造を満たすか点検し、なければ雛形を生成
3. **OKF 適合検証**（必ず実行）: §6 の 3 条件をすべての非予約 .md に対して検査し、人間が読めるレポートを出力
4. **絶対リンク点検**（`okf.link_style: absolute` の場合）: 内部リンクが `/` 始まりか検査し、逸脱を warning として報告

## 設定参照先

| 設定キー | 役割 |
|----------|------|
| `output.root_dir` | バンドルルート。このパス配下を走査する |
| `okf.version` | ルート index.md の frontmatter `okf_version` に使う値（既定 `"0.1"`） |
| `okf.emit_index` | `true` のとき index.md を生成・更新する |
| `okf.emit_log` | `true` のとき log.md を点検・雛形生成する |
| `okf.link_style` | `absolute` のとき内部リンク検査を行う |

設定ファイルは `.claude/leadcraft.md`。

## 実行手順

### 0. 設定の読み込み

`.claude/leadcraft.md` を読み込み、`output.root_dir` / `okf.*` の値を取得する。
`output.root_dir` が空または未設定の場合はスキルを中止し、
「`output.root_dir` が設定されていない。`setup-baseline` で初期設定するか、`.claude/leadcraft.md` を直接編集してください」と案内する。

### 1. ツリーの走査

`<output.root_dir>` 配下を再帰的に走査し、以下を区別する。

**予約ファイル**（OKF 概念ではない）:
- `index.md`
- `log.md`

**概念ドキュメント**（OKF Concept）:
- `README.md`（Objective / Initiative / Epic の概念ファイル）
- Story の `.md`（Epic 直下の非予約 .md）
- `stories-draft.md`、ADR ファイル（`adr-*.md`）、Design Doc（`dd-*.md`）

階層判定の基準:

```
<root_dir>/                              ← バンドルルート
<root_dir>/<objective>/                  ← Objective 階層
<root_dir>/<objective>/<initiative>/     ← Initiative 階層
<root_dir>/<objective>/<initiative>/<epic>/  ← Epic 階層
```

### 2. OKF 適合検証（§6）

すべての概念ドキュメントに対して以下を検査し、結果をレポートにまとめる。

#### 必須条件（ERROR）

| 条件 | 検査内容 |
|------|----------|
| frontmatter 存在 | ファイル先頭が `---` で始まり、YAML としてパース可能か |
| `type` 非空 | frontmatter に `type` キーがあり、空でないか |

許容される `type` 値: `objective` / `initiative` / `epic` / `story` / `adr` / `design-doc` / `stories-draft`

#### 推奨フィールド（WARNING）

| フィールド | 欠落時の報告内容 |
|------------|-----------------|
| `title` | `title` フィールドが未設定 |
| `description` | `description` フィールドが未設定（index.md 生成の精度に影響） |
| `timestamp` | `timestamp` フィールドが未設定（OKF 標準キー） |

#### レポート形式

```
## OKF 適合検証レポート

### ERROR（必須条件違反）
- <ファイルパス>: frontmatter がパースできない
- <ファイルパス>: `type` フィールドが空または未設定

### WARNING（推奨フィールド欠落）
- <ファイルパス>: `description` が未設定
- <ファイルパス>: `timestamp` が未設定

### サマリー
- 対象ファイル数: N
- ERROR: N 件
- WARNING: N 件
- 適合状態: PASS / FAIL（ERROR が 0 件なら PASS）
```

ERROR が 1 件以上ある場合は **FAIL** とし、自動修正は行わない。修正方法を提案ベースで案内する。

### 3. index.md 生成（`okf.emit_index: true` の場合）

各階層のディレクトリに `index.md` を生成・更新する。
**概念ファイル（README.md 等）の本文・frontmatter は一切書き換えない。**

#### ルートの index.md

```markdown
---
okf_version: "0.1"
---

# Knowledge Bundle インデックス

<!-- このファイルは build-bundle スキルが自動生成する。手動編集は次回実行時に上書きされる。 -->

## Objectives

### <Objective の title または ディレクトリ名>
<frontmatter の description。未設定の場合は「（description 未設定）」>

### ...
```

#### Objective 階層の index.md

```markdown
# <Objective の title または ディレクトリ名>

<!-- このファイルは build-bundle スキルが自動生成する。手動編集は次回実行時に上書きされる。 -->

## Initiatives

### <Initiative の title または ディレクトリ名>
<frontmatter の description。未設定の場合は「（description 未設定）」>

### ...
```

#### Initiative 階層の index.md

```markdown
# <Initiative の title または ディレクトリ名>

<!-- このファイルは build-bundle スキルが自動生成する。手動編集は次回実行時に上書きされる。 -->

## Epics

### <Epic の title または ディレクトリ名>
<frontmatter の description。未設定の場合は「（description 未設定）」>

### ...
```

**既存の index.md が存在する場合**は上書きせずに、内容が変わる場合のみユーザーに確認してから更新する。
ただし `--no-index` フラグが与えられた場合はこのステップをスキップする。

### 4. log.md 整備（`okf.emit_log: true` の場合）

各階層（root / 各 Objective / 各 Initiative）について log.md を点検する。

#### 点検基準

- 先頭見出しが `# Log` であるか
- 日付グループが `## YYYY-MM-DD` 形式（ISO 8601）であるか
- 日付が降順（新しい日付が上）であるか
- 各エントリに action 種別（`Creation:` / `Update:` / `Deprecation:`）が含まれるか

#### log.md が存在しない場合

以下の雛形を生成する。

```markdown
# Log

<!-- このファイルは build-bundle スキルが自動生成した雛形。compose 系スキルが更新を追記する。 -->

## <実行日 YYYY-MM-DD>
- Creation: Knowledge Bundle を初期化
```

#### 構造が規約を満たさない場合

差分を提示し、修正するか確認を取る。自動で既存内容を書き換えない。
ただし `--no-log` フラグが与えられた場合はこのステップをスキップする。

### 5. 絶対リンク点検（`okf.link_style: absolute` の場合）

すべての概念ドキュメントの内部リンク（`[text](path)` 形式）を検査する。

**対象**: `http://` / `https://` から始まらない相対リンク（外部リンクは対象外）

**検査内容**: リンク先パスが `/` で始まるか（バンドル絶対パス形式か）

**報告形式**:

```
### WARNING（相対リンク検出）
- <ファイルパス> 行<N>: `[text](relative/path)` → 絶対パス `/relative/path` への変更を推奨
```

修正は提案のみ。自動変換は行わない。
ただし `--no-links` フラグが与えられた場合はこのステップをスキップする。

### 6. 結果のサマリー表示

全ステップ完了後に以下を表示する。

```
## build-bundle 実行結果

- 走査ファイル数: N
- index.md 生成・更新: N 件
- log.md 生成・整備: N 件
- OKF 適合: PASS / FAIL（ERROR: N 件、WARNING: N 件）
- リンク警告: N 件

適合状態が FAIL の場合、上記レポートの ERROR 箇所を修正してから再実行してください。
```

## フラグ一覧

| フラグ | 効果 |
|--------|------|
| `--check-only` | 検証のみ実行。index.md / log.md の生成・更新を行わない |
| `--no-index` | index.md 生成ステップをスキップ |
| `--no-log` | log.md 整備ステップをスキップ |
| `--no-links` | 絶対リンク点検をスキップ |

## 注意事項

- 概念ドキュメント（README.md / Story .md / ADR / Design Doc 等）の frontmatter 本体・本文は**絶対に書き換えない**
- index.md / log.md の生成・更新のみが書き込み操作の対象
- index.md には自動生成であることを示すコメント（`<!-- このファイルは build-bundle スキルが自動生成する -->` 等）を必ず入れる
- 既存の index.md を上書きする前に必ずユーザーに確認する
- 既存の log.md を書き換える前に差分を提示してユーザーに確認する
- バンドルルート（`<output.root_dir>`）に `.git` が存在しても走査は行う（git 管理下でも動く）
- `--check-only` はレビューサイクル・CI での利用を想定する
