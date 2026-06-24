---
name: estimate-points
description: **トラッカーに登録済みの Story**（既定の `local` プロバイダでは Epic 配下のローカル md ＝ OKF concept、`github` プロバイダは opt-in / Phase 2）にフィボナッチ数列でポイント見積もりを行う。PERT（三点見積もり）と単純見積もりの 2 モードから対話的に選択し、本文の「見積もり詳細」セクションと、`set_field` 経由の `points` フィールド（local では frontmatter の `points` / `estimation.*`、github では Projects の `Points`）を同時に更新する。引数で対象（`local` の md ファイルパス / Epic ディレクトリ / `github` の item_ref `#N` / `epic:<id>` ラベル / `all`）を渡せば自動判定する。「見積もりする」「ポイントを付ける」「PERT 見積もりする」「ストーリーポイントを決める」「工数見積もりする」「ローカル Story を見積もる」「md ファイルの見積もりを更新する」と言われたら起動する。完了後、自動的に estimate-validator エージェントを起動する。
argument-hint: "（任意：local の md ファイルパス / Epic ディレクトリ / github の item_ref #N / `epic:<epic-id>` ラベル / `all`。モード指定は --local | --github）"
allowed-tools: Read, Edit, AskUserQuestion, Bash, Glob, Task
---

# estimate-points

**トラッカーに登録済みの Story** にフィボナッチ数列でストーリーポイントを見積もるスキル。

見積もり結果は **2 つの場所に同時に書き戻す**:

1. **本文の「見積もり詳細」セクション**（人間が読む表）
2. **`set_field(item_ref, "points", <値>)`** による `points` フィールド（`references/tracker-contract.md` §3 の正規語彙）

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `get_item` / `set_field` / `update_item` / `list_items` 等の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド・ファイル書き込み等）は各アダプタ（`references/backends/<provider>.md`）に委譲する。

**`points` フィールドの保存先**（`references/tracker-contract.md` §3）:

| provider | `points` の保存先 | `estimation.*` の保存先 |
|----------|-------------------|--------------------------|
| `local`（既定） | frontmatter `points` | frontmatter `estimation.{mode,o,m,p,e,stddev,baseline_comparison}` |
| `github`（opt-in / Phase 2） | Projects Number フィールド `Points` | 本文「見積もり詳細」のみ（Projects には個別保存しない） |

local では **frontmatter が source of truth** であり、本文「見積もり詳細」の表は frontmatter と完全に連動させる（`references/backends/local.md` の不変条件）。github はそこからの同期先である。

> **Phase 2 の注記**: `github` プロバイダのアダプタは現時点でスタブ（`references/backends/github.md`）であり、Issue / Projects の具体手順は未移植である。`--github` 指定時、アダプタが未実装の操作については「Phase 2 で提供予定。当面は `local` で見積もり、後日 `sync-stories`（Phase 2）でアップロードする」と案内する（graceful degradation。`references/tracker-contract.md` §5）。`sync-stories`・`review-stories`・hook 連携も **Phase 2 以降に提供予定** であり、本スキルからは存在しない前提で手順を書かない。
> **本スキルから呼び出す `identify-risks`、および完了後に起動する `estimate-validator` エージェントは現在有効** である（ともに本フェーズで提供される）。

Story を local md と github Issue の両方で同時に管理することは想定しない（provider のいずれか一方が正）。`sync-stories`（Phase 2）でアップロード済みの local md は frontmatter に `github_issue` を持つが、見積もりの正は引き続き local md 側とする（github 側の見積もり詳細は次回の `sync-stories` で同期される設計）。

## 見積もりモード

| モード | 入力 | 計算式 | 用途 |
|--------|------|--------|------|
| **PERT（三点）** | O, M, P | E = (O + 4M + P) / 6, σ = (P - O) / 6 | 標準。ばらつきも算出 |
| **単純** | 1 値 | E = 入力値 | 小さく確信がある Story |

## フィボナッチ数列

`1, 2, 3, 5, 8, 13, 21, 34, 55, 89`

13 以上は分割推奨。89 は理論上の上限。

## 前提

### 共通

- `.claude/leadcraft.md` の `baseline` が設定済み（未設定なら `setup-baseline` へ誘導）
- 対象 Story がトラッカーに登録済み（`compose-stories` / `quick-stories` 経由）
- `tracker.provider` で対象を解決（`local` 既定 / `github` は Phase 2）

### local モード時（既定）

- 対象 Story が `<epic-dir>/<slug>.md`（OKF concept）として書き出し済み
- md ファイルが書き込み可能（通常はリポジトリ内なので自然に満たされる）
- 外部依存ゼロのため全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `project` スコープ、`tracker.github.*`（owner / project number / `Points` フィールド ID）の設定）を満たすこと
- 未設定・未実装の操作は graceful degradation（アダプタがスキップして警告。`tracker-contract.md` §5）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`compose-stories` と同じロジック。`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

引数が常に最優先される。曖昧な場合（例: 設定が `local` で github の item_ref（`#123`）引数が来た）は、引数の形式から provider を推定する。`#<数値>` 形式 / `epic:<id>` ラベル / `all` は github の対象指定、`*.md` パス / ディレクトリパスは local の対象指定とみなす。これは「引数の形が示す provider 側の見積もりを意図している」というユーザー直観を尊重する設計である。

解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の「操作 → 具体手順」マップを参照して以降の抽象操作を実行する。

## 実行手順

### 1. 基準点の確認

`.claude/leadcraft.md` から baseline を読み込む。未設定の場合は `setup-baseline` スキルへ誘導する。

### 2. 対象の特定（対象タイプの自動判定）

引数の形式から provider と対象を判定する:

| 引数 | provider / 対象 | 取得操作 |
|------|------------------|----------|
| `*.md` ファイルパス | local（1 件） | `get_item(item_ref)`（local では md を Read し frontmatter + 本文を返す） |
| ディレクトリパス（Epic ディレクトリ） | local（Epic 配下全件） | `list_items({epic: "<epic-id>"})` または `Glob` で `<dir>/*.md` を列挙し `type: story` でフィルタ |
| `#123` / 複数 item_ref | github（個別。**Phase 2**） | `get_item(item_ref)` |
| `epic:<epic-id>` ラベル | github（Epic 配下。**Phase 2**） | `list_items({label: "epic:<id>", status: "story"})` |
| `all` | github（全 story。**Phase 2**） | `list_items({label: "story"})` |
| 引数なし | 対話で確認（`AskUserQuestion` で local md / Epic ディレクトリ / github の 3 択） | 上記のいずれか |

local の Epic ディレクトリ列挙では、Epic 本人の `README.md` および予約ファイル（`index.md` / `log.md`）を除外する（`references/backends/local.md` の `list_items` 実装に従う）。`get_item` で取得した frontmatter の `type: story` を確認し、`type: story` でないものはスキップする（誤判定回避）。frontmatter の `mode: quick` の md も対象に含める（quick で起票後の見積もりは本スキルで埋める運用）。

すでに見積もり済み（local: frontmatter の `points` > 0、github: 本文の Points > 0）の場合は再見積もりするかユーザーに確認する。

### 3. 見積もりモードの選択

各 Story について `AskUserQuestion` で以下を確認する:

- 「この Story の見積もりモードはどうするか？」
  - PERT（三点見積もり）
  - 単純見積もり

または最初に「以降すべて PERT で」のように一括指定を促す。

### 4. 見積もりの入力

#### PERT モード

3 つの値を順に取得する:

- **楽観値（O）**: 全てが順調に進んだ場合のポイント（フィボナッチ）
- **最頻値（M）**: 最も起こりやすいポイント（フィボナッチ）
- **悲観値（P）**: 想定される最悪ケースのポイント（フィボナッチ）

質問文には基準点を必ず提示する:

- 「2pt 基準: \<reference_story_2\>」
- 「8pt 基準: \<reference_story_8\>」

入力後、PERT 計算を行う:

- E = (O + 4M + P) / 6
- σ = (P - O) / 6
- E をフィボナッチ数列で **最も近い値** に丸めて Points とする

#### 単純モード

単一のフィボナッチ値を取得し、Points にそのまま設定する。O = M = P = Points として記録する（後段スキルとの互換性のため）。

### 5. リスク反映の確認

リスクスコアの参照元は provider で異なる:

- **local**: frontmatter の `risk_score` を読む（こちらが正。本文の「最大リスクスコア」と整合しているはずだが、frontmatter を優先）
- **github（Phase 2）**: 本文の「リスクと対応策」セクションの `最大リスクスコア` 行を読む

判定:

- 実行済み（スコア > 0）: 「リスクを P に加算するか？」と確認し、加算する
- 未実行（スコア 0 または未識別）: 「先に `identify-risks` を実行することを推奨」と案内する（強制はしない）

### 6. 書き戻し（provider に応じてアダプタへ委譲）

見積もり結果を **本文の「見積もり詳細」セクション** と **`set_field` 経由の `points` フィールド** の両方へ書き戻す。両者は連動するため、片方だけ更新するのは禁止（不整合が発生し、`sync-stories`（Phase 2）の整合性チェックが警告を出す）。

#### 6-1. 本文「見積もり詳細」セクションの更新

`get_item(item_ref)` で本文を取得し、「見積もり詳細」セクションを次の表構造（テンプレート `story-local.md` 由来）に書き換える:

```markdown
## 見積もり詳細

| 項目 | 値 |
|------|-----|
| Points | <フィボナッチに丸めた E> |
| 見積もりモード | <pert / simple> |
| 楽観値 (O) | <O> |
| 最頻値 (M) | <M> |
| 悲観値 (P) | <P> |
| 期待値 (E) | <E（小数 2 桁）> |
| 標準偏差 (σ) | <σ（小数 2 桁）> |
| 基準点比較 | <2pt基準・8pt基準と比較した位置づけ> |
```

書き換えは **「見積もり詳細」セクションのみ** を対象とし、他のセクション（階層 / 背景・目的 / 受け入れ基準 / タスク / リスクと対応策 / 依存関係 / Definition of Done / 参考）は触らない。

provider 別の反映:

- **local**: 対象 md を `Edit` で更新する。これは `update_item(item_ref, {body})` に相当する。local アダプタは `updated_at` / `timestamp` を現在時刻に更新し、Epic 階層の `log.md` に `Update: Story <slug> の見積もりを更新` を 1 行追記する（`references/backends/local.md` の `update_item`、`references/okf-conformance.md` §3）
- **github（Phase 2）**: `update_item(item_ref, {body})` で Issue 本文の該当セクションを更新する（github アダプタ。**Phase 2**）

#### 6-2. `points` フィールドの更新（`set_field`）

```
set_field(item_ref, "points", <フィボナッチに丸めた E>)
```

provider 別の保存先（アダプタが振り分ける。`references/tracker-contract.md` §3）:

- **local**: frontmatter の `points` を書き込む。**合わせて frontmatter の `estimation.{mode,o,m,p,e,stddev,baseline_comparison}` も `Edit` で更新する**（本文「見積もり詳細」と完全に一致させる）。例:

  ```yaml
  # Before
  points: 0
  estimation:
    mode: "pert"
    o: 0
    m: 0
    p: 0
    e: 0
    stddev: 0
    baseline_comparison: ""

  # After
  points: 5
  estimation:
    mode: "pert"
    o: 3
    m: 5
    p: 8
    e: 5.17
    stddev: 0.83
    baseline_comparison: "2pt 基準より大きく、8pt 基準より小さい中規模"
  ```

  frontmatter の書き換えは `points` / `estimation` のキーのみ。他のキー（`risk_score` / `risks` / `dependencies` / `tracker_ref` / `github_issue` 等）は触らない。

- **github（Phase 2）**: Projects の Number フィールド `Points` に値を反映する。Issue が Projects に未追加の場合や `tracker.github.fields.points` 未設定の場合は、アダプタがスキップして警告する（graceful degradation）。ユーザーに `compose-stories` 再実行または手動追加を案内する。github での `estimation.*` の細目は本文「見積もり詳細」表のみに保持し、Projects には個別フィールドを持たない

### 7. estimate-validator の自動起動

すべての対象 Story の見積もりが完了したら、`Task` ツールで `estimate-validator` エージェントを起動する。

- 呼び出し方: `Task` ツールに `subagent_type: estimate-validator` を指定
- 入力プロンプトに含める情報:
  - 見積もり対象だった Story の item_ref 一覧（local: 各 md のバンドル絶対パス / github: Issue 番号）
  - provider（local / github）
  - 該当 Epic README.md の絶対パス（あれば）
  - 該当 Initiative README.md の絶対パス（あれば）
  - `.claude/leadcraft.md` のパス（baseline 参照のため）
- 期待出力: 妥当性レビュー、警告、改善提案

`Task` ツールが利用不可な環境では、ユーザーに「`estimate-validator` agent を以下の Story に対して起動してほしい: \<item_ref 一覧\>」と案内する。

### 8. 結果サマリーの表示

ユーザーに以下を表示する:

- 各 Story の Points・PERT 値・基準点比較・item_ref（local: 書き戻した md の絶対パス / github: Issue URL）
- Epic 単位の集計（`epic:<id>` ラベル / Epic ディレクトリで分類した場合）
- 13pt 以上の Story リスト（分割推奨）
- `estimate-validator` の主な指摘

local モードの場合、サマリーの末尾に次のアクション候補を案内する:

- `identify-risks`: 同じ Story のリスクを識別し P に反映する（現在有効）
- `sync-stories`: ローカル Story を github トラッカーへアップロードする（**Phase 2**）
- `review-stories`: 品質ゲートを通して `draft` を外す（**Phase 2**）
- `build-bundle`: OKF バンドルの `index.md` / `log.md` を補完・検証する

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `get_item` / `set_field` / `update_item` / `list_items` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **本文「見積もり詳細」と `points` フィールドを必ず両方更新する**。local では本文表と frontmatter の `points` / `estimation.*` の連動を保たないと `sync-stories`（Phase 2）のアップロード時に整合性チェックが警告を出す（`references/backends/local.md` の不変条件）
- **OKF 準拠**: local の Story md は更新後も OKF concept として `references/okf-conformance.md` §2 を満たす。更新時は Epic 階層の `log.md` に `Update` 行を追記する（§3）。`index.md` の更新は `build-bundle` の責務（本スキルは触らない）
- O ≤ M ≤ P を必ずチェックする。違反していたら入力し直しを促す
- O = M = P の場合（確信度高い）、σ=0 を許容するが「単純見積もりに切り替えるか」をユーザーに確認する
- PERT の E がフィボナッチ非整数になる場合、必ずフィボナッチに丸める
  - 丸めルール: 最も近い値（同距離なら大きい方）
  - 例: E=4 → 5（3 より 5 に近い）、E=6.5 → 8（5 と 8 の中間で同距離 → 大きい方）、E=10 → 8（13 より 8 に近い）
- σ が大きすぎる（例: σ ≥ M）Story は分割を推奨する
- 基準点（baseline）が未設定の状態では実行しない。`setup-baseline` へ誘導する
- 本スキルは **Story 階層のみ** を扱う。Epic README は触らない（Story 集計は github の Projects フィールド合算 / local の frontmatter 集計で参照する設計）。Initiative / Objective レベルの見積もりは行わない
- 本文の書き換えは「見積もり詳細」セクションのみ。他のセクション（背景・受け入れ基準・タスク・リスクと対応策・依存関係）を破壊しない
- local の frontmatter 書き換えは `points` / `estimation` のキーのみ。他のキー（`risk_score` / `risks` / `dependencies` / `tracker_ref` / `github_issue` 等）は触らない
- **github（Phase 2）の注意**: `sync-stories`（Phase 2）でアップロード済みの local md（frontmatter に `github_issue` を持つ）を local モードで見積もっても、本スキルは github Issue 側を直接更新しない。次回 `sync-stories` で同期される設計。ユーザーに「github 側も同期する場合は `/sync-stories <md-path>` を実行してほしい（Phase 2）」と案内する。github Projects への反映・`project` スコープ要件・フィールド ID 解決は github アダプタの責務（`references/backends/github.md`、**Phase 2**）
