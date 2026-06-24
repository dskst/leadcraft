---
name: convert-points-to-time
description: 見積もり済みの Story のストーリーポイントを実時間（時間 / 日 / 人月）に換算し、合わせて JUAS ソフトウェアメトリックス式に基づく工期（月）も算出する **読み取り中心**のスキル。実行時に 1pt あたりの時間レートを入力し、対象 Story、または Epic 単位 / Initiative 単位 / Objective 単位で集計する。値の取得元は **frontmatter の `points` / `estimation.*`（既定の `local` プロバイダが source of truth）または github の Projects フィールド + Issue 本文「見積もり詳細」セクション**（`get_item` / `list_items` 経由）。本スキルは集計・表示のみを行い、Story 本文・frontmatter を書き換えない（換算結果を md に保存する場合のみ別ファイルを生成）。「ポイントを時間に変換する」「人日に換算する」「工期を算出する」「期間を見積もる」「ベロシティで時間を出す」「pt to hours」「人月から工期を出す」と言われたら起動する。
argument-hint: "（任意：Story の item_ref（local: md パス / github: #N）、`epic:<epic-id>` / `initiative:<...>` / `objective:<...>` 指定、または「all」。モード指定は --local | --github）"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash
---

# convert-points-to-time

ストーリーポイントを実時間に換算し、合わせて工期（月）を算出する **読み取り中心**のスキル。レートは実行時にユーザーが入力する。

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。値の取得は `get_item` / `list_items` の **抽象操作名** で記述し、provider 固有の具体手順は各アダプタ（`references/backends/<provider>.md`）に委譲する。

**値の取得元（provider 別）**:

| provider | source of truth | 取得方法 | 状態 |
|----------|-----------------|----------|------|
| `local` | Story md の frontmatter `points` / `estimation.*` / `risk_score` | `get_item` / `list_items`（frontmatter を読む） | **既定** |
| `github` | Projects フィールド（`Points` 等）+ Issue 本文「見積もり詳細」セクション | `get_item` / `list_items`（Projects + 本文） | opt-in / **Phase 2** |

> **読み取り専用**: 本スキルは Story の本文・frontmatter・Projects フィールドを **一切書き換えない**。集計と表示、および（任意で）換算結果を別 md ファイルに保存するだけである。frontmatter / Issue が source of truth であり、本スキルはそこからの読み取りに徹する。

> **Phase 2 の注記**: `github` プロバイダのアダプタはスタブ（`references/backends/github.md`）であり、Projects / Issue からの取得手順は未移植である。`--github` 指定時は未実装操作を graceful degradation で案内する（`references/tracker-contract.md` §5）。Story を見積もる `estimate-points` も **Phase 2 以降に提供予定**であり、本スキルからは存在しない前提で手順を書かない。

## 換算モデル

- 入力: `1pt = X 時間`
- 出力: Story 単位、Epic / Initiative / Objective 単位の時間集計（時間 / 日 / 人月）と工期（月）
- 標準偏差も時間換算（PERT モードの Story のみ）
- 工期（月）= `3.23 × 工数(人月)^(1/3) × 1.08`
  - 出典: JUAS『ソフトウェアメトリックス調査 2025』(<https://juas.or.jp/cms/media/2025/03/25swm_pr.pdf>)
  - 工期は集計単位（Epic / Initiative / Objective / all）の合計工数に対してのみ算出する。Story 単位では算出しない（小規模では式の前提から外れるため）
  - 工数（人月）= `合計期待時間 / (hours_per_day × days_per_month)`。`days_per_month` のデフォルトは 20（営業日）

## 前提

### 共通

- 対象 Story が見積もり済みであること（`estimate-points`（Phase 2）実行済み、または手動で frontmatter の `points` / `estimation.*` が埋まっている）
- `.claude/leadcraft.md` の `tracker.provider` / `output.root_dir` が設定済み（root_dir 未設定時は compose-objective が対話で確定した値を使う）

### local モード時（既定）

- 対象 Story md が `<epic-dir>/<slug>.md` に存在し、frontmatter の `points` / `estimation.*` が埋まっていること
- 外部依存ゼロのため全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `project` スコープ、`tracker.github.*` の設定）を満たすこと
- 未設定・未実装操作は graceful degradation（アダプタがスキップして警告）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`compose-stories` と同じロジック。`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の実装で抽象操作（`get_item` / `list_items`）を行う。

## 実行手順

### 1. レートの取得

`AskUserQuestion` で以下を確認する:

- 「1 ストーリーポイントを何時間として換算するか？」
- ヒント:
  - 例 1: 「2pt = 半日 → 1pt = 4 時間」
  - 例 2: 「8pt = 1 週間（40 時間） → 1pt = 5 時間」
  - 例 3: 「ベロシティから算出 → 過去スプリントの完了 pt 合計 / 投入時間合計」

設定ファイル `.claude/leadcraft.md` に `points_to_hours` が保存されている場合、それをデフォルト値として提示し、「設定値を使う / 別の値を入れる」を選ばせる。

加えて、人月換算と工期算出に必要な以下の値も確認する:

- `hours_per_day`（1 人日の時間数）— 設定値があればそれを既定、無ければ `8` を既定として提示
- `days_per_month`（1 人月の営業日数）— 設定値があればそれを既定、無ければ `20` を既定として提示

これらは工期算出（JUAS 式）の前提となる「工数（人月）」算出に直接効くため、レート確認と同じステップで一括して `AskUserQuestion` で確認する。

### 2. 対象 Story の特定

引数または対話で対象を決定する:

- 単一 Story の item_ref（local: md パス / github: `#123`）
- 複数 Story の item_ref
- `epic:<epic-id>` 指定 → 指定 Epic 配下の全 Story
- `initiative:<initiative-id>` / `objective:<objective-id>` 指定 → 指定階層配下の全 Story
- `"all"` → バンドル全体の `story` 項目全件

#### 2-1. 対象一覧の取得（抽象操作）

`list_items` で条件に合致する Story を列挙する（`references/tracker-contract.md` §2）:

- Epic 単位: `list_items({epic: "<epic-id>"})`
- Initiative 単位: `list_items()` の結果を frontmatter / フィールドの `initiative` でフィルタ
- Objective 単位: 同様に `objective` でフィルタ
- "all": `list_items({label: "story"})`

provider 別の実装:

- **local**: `<epic-dir>/*.md`（または `<root_dir>` 配下を Glob）を走査し、`type: story` かつ条件に合致する md を返す。Epic README・予約ファイル（`index.md` / `log.md`）は除外する（`references/backends/local.md` の `list_items`）
- **github（Phase 2）**: `epic:<id>` ラベルや Projects のフィールド絞り込みで対象を取得する。Initiative / Objective 単位はラベルだけでは絞り込めないため Projects フィールドで絞る（`references/backends/github.md`）

#### 2-2. 見積もり値の取得（抽象操作）

各 Story について **`get_item(item_ref)`** で値を取得し、以下を読む:

- `points`（必須）
- 見積もりモード（`estimation.mode`: `pert` / `simple`）
- 期待値 (E) = `estimation.e`、標準偏差 (σ) = `estimation.stddev`（PERT モードのみ）

provider 別の取得元:

- **local**: frontmatter の `points` / `estimation.{mode,e,stddev}` を読む（source of truth）。本文の「見積もり詳細」テーブルは frontmatter と連動しているため frontmatter を正とする（`references/backends/local.md`）
- **github（Phase 2）**: Projects フィールド `Points` と Issue 本文の「見積もり詳細」セクション（`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` の「見積もり詳細」テーブル形式に準拠）からパースする。集計グルーピング用に Projects の `Objective` / `Initiative` / `Epic` フィールドも取得する

### 3. 換算計算

各 Story について:

- 期待時間: `Points × rate`
- PERT モードの場合:
  - 期待時間: `E × rate`
  - 標準偏差時間: `σ × rate`
  - 信頼区間: `期待時間 ± 標準偏差時間` を表示
- 単純モードの場合: 期待時間のみ

### 4. 集計と表示

#### Story 単位の表

| Story | タイトル | Points | 期待(h) | σ(h) | 範囲(h) |
|-------|----------|--------|---------|------|---------|
| <item_ref> | ...      | 5      | 20.0    | 2.5  | 17.5 〜 22.5 |

> `Story` 列は item_ref（local: md のバンドル絶対パスまたは slug / github: `#123`）を表示する。

#### Epic / Initiative / Objective 単位の集計

対象範囲に応じて、以下の単位で集計表を出力する:

- Epic 単位（指定 Epic 配下のすべての Story）
- Initiative 単位（指定 Initiative 配下のすべての Epic）
- Objective 単位（指定 Objective 配下のすべての Initiative）

各単位ごとに:

- 合計期待時間: `Σ(E × rate)`
- 合計標準偏差時間: `√(Σ((σ × rate)²))`
- 人日換算: 1 人日 = 8 時間（または設定値 `hours_per_day`）として日数表示
- 人月換算: 1 人月 = `hours_per_day × days_per_month` 時間（`days_per_month` の既定値 20）として人月表示
- **工期（月）**: `3.23 × 工数(人月)^(1/3) × 1.08`（JUAS 式）
- 工期の信頼区間: 期待工数の代わりに `期待工数 ± 標準偏差工数` を代入して算出し、`下限 〜 上限` の月数として表示
- 信頼区間（68%, 95%）の表示（工数・工期それぞれ）

集計表のイメージ:

| 範囲 | 合計 Points | 期待工数(h) | 期待工数(人月) | σ(人月) | 工期(月) | 工期 範囲(月) |
|------|-------------|-------------|----------------|---------|----------|---------------|
| Epic A | 21 | 84.0 | 0.53 | 0.08 | 2.95 | 2.78 〜 3.10 |

グルーピングは階層 ID（`epic` / `initiative` / `objective`）の値で行う。local では frontmatter の `epic_id` / `initiative_id` / `objective_id`、github（Phase 2）では Projects フィールド `Epic` / `Initiative` / `Objective` を使う。

#### 補足表示

- 「リスク反映後の P で換算済みのため、これは『リスク織り込み済み見積もり』」（`identify-risks`（Phase 2）で P をリスク調整済みの場合）
- 13pt 以上の Story がある場合は警告（換算精度が低い）
- 単純モードの Story は標準偏差なし（`-` 表示）
- 工期算出時には JUAS 式の出典（<https://juas.or.jp/cms/media/2025/03/25swm_pr.pdf>）と、用いた `hours_per_day` / `days_per_month` の値を併記する
- 合計工数が 0.5 人月未満の場合は「JUAS 式は中〜大規模プロジェクト想定のため、参考値として扱う」と注記する

### 5. 出力形式

ユーザーに確認する:

- チャットに表で表示するのみ
- Markdown ファイルに保存

ファイル保存を選んだ場合、レート・換算日時・対象範囲を明記したヘッダーを付ける。**この md は換算結果のレポートであり、Story 本文・frontmatter は書き換えない**。保存先は対象範囲に応じて以下を提案する。`<root>` は設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は compose-objective が対話で確定）:

- Epic 範囲: `<root>/<objective>/<initiative>/<epic>/time-estimate.md`
- Initiative 範囲: `<root>/<objective>/<initiative>/time-estimate.md`
- Objective 範囲: `<root>/<objective>/time-estimate.md`
- "all" 範囲: ユーザーに確認（バンドルルート直下の `time-estimate.md` を提案）

> `time-estimate.md` は OKF concept ではなく派生レポートである。frontmatter を持たせる場合は `type: stories-draft` 等の概念タイプを誤って付けない（`build-bundle` の適合検証で概念と誤認させないため）。レポートであることが分かるヘッダー（換算条件・出典・対象範囲）を本文先頭に置けば足りる。<!-- TODO: 派生レポートの OKF 上の位置づけ（予約ファイル扱いにするか、frontmatter なしの非概念とするか）を build-bundle の仕様確定時に整理する -->

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `get_item` / `list_items` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **値の取得元**:
  - local（既定）: Story md の frontmatter `points` / `estimation.*`（source of truth）
  - github（Phase 2）: Projects フィールド + Issue 本文「見積もり詳細」セクション
- **読み取り専用**: Story 本文・frontmatter・Projects フィールドを書き換えない（あくまで参照のみ）。換算結果を保存する場合のみ別 md（`time-estimate.md`）を生成する
- レートは設定ファイルに保存されている場合のみデフォルト値として提示し、それ以外は実行時にユーザーから取得する。本スキルは設定ファイルへの書き込みを行わない（保存したい場合はユーザーに `points_to_hours` 手動設定を案内する）
- 人日換算用の `hours_per_day` は設定ファイルに保存されていればそれを使い、未設定なら `8` をデフォルトとして提示する
- ベロシティ算出機能は本スキルでは扱わない（将来拡張）
- 信頼区間（68%, 95%）は対象 Story が 3 件以上の場合のみ表示する。少数の場合は「件数不足のため信頼区間は省略」と明示する
- `points: 0` の Story がある場合は警告し、`estimate-points`（Phase 2）への誘導を行う
- 「見積もり詳細」が見つからない / パースできない（frontmatter / 本文に値が無い）Story は警告を出してスキップする
- 工期（月）の式は JUAS『ソフトウェアメトリックス調査 2025』に基づく実績回帰式であり、入力前提として「工数 = 人月」「工期 = 月」を想定している。人月換算には `hours_per_day` と `days_per_month` の双方が必要なため、欠落している場合は必ず対話で確認する
- 工期は **集計単位（Epic / Initiative / Objective / all）でのみ算出**する。単一 Story や 0.5 人月未満の合計工数では参考値扱いとし、その旨を明示する
