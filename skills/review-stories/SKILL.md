---
name: review-stories
description: `compose-stories` で作成され `draft` ラベルが付いている Story（既定の `local` プロバイダでは `<epic-dir>/<story-slug>.md`＝OKF concept、`github` プロバイダは opt-in / Phase 2 の Issue）をレビューし、品質ゲートを通過したものから `draft` ラベルを外して「計画に組み込み可能」状態へ卒業させるスキル。受け入れ基準の具体性、タスクの粒度、依存関係の妥当性、見積もり（Points > 0）、リスク識別、DoD、階層フィールド整合性を 6 観点でチェックし、ユーザーと対話しながら通過 / 差し戻しを判定する。**通過時には本文には手を加えず、「人間が一目で要点を掴める要約コメント」を `add_comment` で付与してから** `draft` を `remove_label` で外す（必要なら `ready` を `add_label`）。`compose-stories` が作成した本文は項目が多く読みづらいため、卒業の証としてサマリーを別途付ける設計。出力先は `tracker.provider` 設定または `--local` / `--github` 引数で切り替える。「Story をレビューする」「draft を外す」「ストーリーレビュー」「Story の品質ゲート」「スプリント前に Story を整える」「ドラフト卒業」「Story の卒業判定」「Story を ready にする」「Story の最終確認」「Story のサマリーを書く」「要約を作る」と言われたら起動する。単一項目・複数項目・Epic ラベル単位・「draft 全件」の 4 つの入力モードに対応する。`compose-stories` で作成直後の Story を本スキルで品質ゲートに通すことを前提とする。
argument-hint: "（任意：item_ref（local: md パス / github: #番号）/ Epic ラベル epic:<id> / 'all'。モード指定は --local | --github。空なら対話で選択）"
allowed-tools: Read, Edit, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# review-stories

`compose-stories` が作成した Story（`draft` ラベル付き）に対し、**スプリント計画に組み込む前の品質ゲート** として機能するスキル。作成時点では受け入れ基準・見積もり・リスクが薄い、または未完であるのが普通であり、それらを **意図的に分離された卒業手順** を通すことで「計画に組み込み可能な Story」と「下書き」を区別する。

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `get_item` / `list_items` / `add_comment` / `remove_label` / `add_label` / `ensure_label` 等の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド・ファイル書き込み等）は各アダプタ（`references/backends/<provider>.md`）に委譲する。

通過した Story は **人間向けサマリーが付与され**、`draft` ラベルが削除される（任意で `ready` ラベルが付与される）。差し戻された Story は `draft` が維持され、指摘事項がレビュー結果として残る。**本文は compose-stories の作成内容そのままに保たれる**（本文構造を破壊しない、原本性を維持する設計）。

`compose-stories` が **作成** に集中するように、本スキルは **卒業判定 + 人間向けサマリー付与** に集中する。compose-stories の本文は階層・背景・AC・タスク・見積もり・リスク・依存・参考と項目が多く、レビュアー・着手者がぱっと見で要点を掴むのが難しい。本スキルはレビューを通過した時点で「**これは何 / なぜやる / 規模感 / 押さえどころ**」を 8 行以内に凝縮したサマリーを **`add_comment` で別途付与** することで、卒業後の Story を **人間が読める状態** に引き上げる。本文と分離することで (1) 本文は作成時の原本性が保たれる、(2) サマリーは再レビュー時に置換しやすい、(3) サマリー付与は本文編集より追加的・非破壊的な操作、という 3 つの利点が得られる。この責務分離により「とりあえず作成して後で詰める」運用と、「計画に組み込む前に必ず通すゲート」の両立を成立させる。

**出力先（provider）の解決**:

| provider | サマリー付与先 | 状態 |
|----------|----------------|------|
| `local` | `add_comment` は本文末尾に `## レビューサマリー（YYYY-MM-DD）` を追記（`references/backends/local.md`）。`draft` 削除は frontmatter `labels[]` の編集 | **既定** |
| `github` | `add_comment` は Issue コメント投稿、`draft` 削除は Issue ラベル編集（`references/backends/github.md`） | opt-in / **Phase 2** |

> **Phase 2 の注記**: `github` プロバイダのアダプタは現時点でスタブ（`references/backends/github.md`）であり、Issue / Projects の具体手順は未移植である。`--github` 指定時、アダプタが未実装の操作については「Phase 2 で提供予定。当面は `local` でレビューし、後日 `sync-stories`（Phase 2）でアップロードする」と案内する（graceful degradation。`references/tracker-contract.md` §5）。`sync-stories` および hook 連携（`draft` 付与検知等）は **Phase 2 以降に提供予定**であり、本スキルからは存在しない前提で手順を書かない。
> **本スキルが参照する `estimate-points` / `identify-risks` は現在有効** である（ともに本フェーズで提供される）。

## 起動経路

本スキルは 2 経路で起動する:

| 経路 | きっかけ | 想定される文脈 |
|------|----------|----------------|
| **手動** | ユーザーが `/review-stories` を明示的に呼ぶ、または「Story をレビューしたい」等の自然言語要求 | `estimate-points` / `identify-risks` を実施済で、最終ゲートに通したい段階 |
| **hooks 経由（Phase 2）** | `draft` ラベル付与を検知した hook（**Phase 2**）が system reminder を注入 → Claude が文脈に応じて起動 | `compose-stories` 直後 |

hooks 経由で起動が示唆された場合は、reminder に書かれた **「即時レビュー / 段取りを踏む / 保留」の 3 択** をユーザーに `AskUserQuestion` で提示してから本処理に入るのが望ましい。`compose-stories` 直後の文脈では「段取りを踏む（先に `estimate-points` と `identify-risks` を実施。いずれも現在有効）」を推奨する。これは、作成直後は 6 観点チェックの大半（Points / リスク / DoD）が確実にブロッカー判定になり、無駄な差し戻しが残るのを避けるため。本フェーズでは hook は移植されていないため、当面は手動起動が前提となる。

## 想定する利用シーン

- スプリントプランニング前に、作成済みの Story 群をレビューして卒業させたい
- 作成直後の Story を一つひとつ詰めて、受け入れ基準とタスクを実装可能なレベルまで具体化したい
- `estimate-points` と `identify-risks` を実行したあと、最終仕上げとして卒業判定したい
- `compose-stories` で大量作成した Story（Epic 単位）の状態整理をしたい
- 「ready 状態の Story だけ着手させたい」運用ルールを徹底したい

## 出力

| 項目 | 値 |
|------|----|
| **サマリー（通過時のみ）** | 人間向けサマリーを `add_comment` で付与。マーカー（`<!-- review-stories: summary -->`）を含め、再レビュー時は同マーカーを持つ既存サマリーを置換する。詳細はステップ 5-1。local では本文末尾の `## レビューサマリー（YYYY-MM-DD）` に追記、github（Phase 2）では Issue コメント |
| ラベル編集 | `remove_label(item_ref, "draft")`（必要に応じて `add_label(item_ref, "ready")`）。local では frontmatter `labels[]` 編集、github では Issue ラベル編集 |
| レビュー結果 | 各項目にレビュー結果を `add_comment` で残す（通過時は要約のみ、差し戻し時は指摘リスト） |
| 本文 | **触らない**（compose-stories の作成内容そのまま）|
| 階層フィールド | 本スキルでは原則更新しない（`status` の遷移は別の運用判断。要望があれば `set_field` で設定可） |
| 結果サマリー（対話上） | 通過 / 差し戻し / スキップを項目単位で表示 |

## 前提

### 共通

- 対象 Story が `compose-stories` 経由で作成済み（`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` 構成の本文を持つ）
- `setup-dod` で DoD が設定済みであれば、DoD の存在も確認する（任意）
- `.claude/leadcraft.md` の `split_threshold`（既定 13）を分割推奨判定に使う
- `tracker.provider` で出力先を設定（`local` 既定 / `github` は Phase 2）

### local モード時（既定）

- Epic ディレクトリ配下の Story md を読み書きできること（通常はリポジトリ内なので自然に満たされる）
- 外部依存ゼロのため全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `repo` スコープ、`tracker.github.*` の設定）を満たすこと
- 未設定・未実装の操作は graceful degradation（アダプタがスキップして警告。`tracker-contract.md` §5）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`compose-stories` と同じロジック。`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

引数が常に最優先される。item_ref の形式から provider を推定する場合もある（`#<数値>` 形式は github、`*.md` パス形式は local）。解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の実装で以降の抽象操作を実行する。

## 実行手順

### 1. 入力モードの判定

引数または対話で次のいずれかを取得する。引数が空なら `AskUserQuestion` で 4 択を提示する。

- **単一項目**: item_ref 1 つ（local: `<epic-dir>/<slug>.md` パス / github: `#123`）
- **複数項目**: item_ref を複数（local: 複数 md パス / github: `#123 #145 #200`）
- **Epic ラベル単位**: `epic:<epic-id>`（その Epic 配下で `draft` のついた Story 全件）
- **`all`**: バンドル全体で `draft` ラベルが付いた Story 全件

項目の列挙・取得は抽象操作で行う:

- 単一 / 複数: `get_item(item_ref)` で `{title, body, fields, labels}` を取得
- Epic 単位: `list_items({epic: "<epic-id>", label: "draft"})` で item_ref を列挙
- 全 draft: `list_items({label: "draft"})` で item_ref を列挙

`list_items` の local 実装は `<root_dir>` 配下の `*.md` を Glob 走査し、frontmatter `type: story` かつ条件合致のものを返す（`references/backends/local.md`）。github 実装（Phase 2）は Issue 一覧 / Projects ビューで絞り込む。

### 1-1. `quick` ラベル付き項目の扱い

対象に `quick` ラベルが付いている（`quick-stories` で簡易作成された）場合、本文には「タスク / 見積もり / リスク / 依存」セクションが **そもそも存在しない**。これらを必須としてレビューに通すと大半がブロッカー判定になり、差し戻しだけが残って意味のあるフィードバックにならない。

仕様: `quick` ラベル付き項目は **本スキルでは品質ゲートに通さず**、次のいずれかを `AskUserQuestion` で確認する:

- **a. `compose-stories <item_ref>` で先に肉付けする**（推奨。本文を埋めてから再度 `review-stories` を実行）
- **b. quick のまま卒業させる**（チームが「quick ラベルのまま計画組み込み可」運用なら可。この場合は本スキルのチェックは 1〜3 の観点のみ適用し、4〜6 はスキップして警告ベースで通す）
- **c. このセッションではスキップ**（後で対応する）

複数件レビュー中に `quick` 混在を検出した場合は、まとめて「`quick` 付きは別フローで対応するか？」をユーザーに確認し、本スキルでは `draft` のみを処理対象に絞る運用が現実的。

候補が複数ある場合、`AskUserQuestion` で「全件レビュー / 個別選択」を確認する。レビュー件数が 5 件を超える場合は「優先度の高いものから順に進める？」と聞いて 1〜2 件ずつ進めるのを推奨する。

### 2. 各項目のレビュー前準備

対象 1 件ごとに、`get_item(item_ref)` で本文・フィールド・ラベル（および取得できる範囲のコメント / 既存サマリー）を読み込む。

本文を「階層 / 背景・目的 / 受け入れ基準 / タスク / 見積もり詳細 / リスクと対応策 / 依存関係 / 参考」のセクションに分解して内部表現にする。雛形（`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md`）の構造を前提とするが、構造が壊れている場合は **構造再構築を提案** する（本文上書きはユーザー承認後、`update_item` で行う）。

local では frontmatter が source of truth であるため、Points / Risk Score / 階層 ID は frontmatter から、AC / タスク / リスク表は本文から読み取り、両者の整合も確認する（`references/backends/local.md` の設計上の不変条件）。

### 3. 6 観点の機械チェック

各項目について以下を自動判定する。判定結果は **ブロッカー（差し戻し）** / **警告（通過可だが要注意）** / **OK** の 3 段階で分類する。

| # | チェック観点 | ブロッカー条件 | 警告条件 |
|---|--------------|----------------|----------|
| 1 | 階層情報の整合性 | `objective` / `initiative` / `epic`（local: frontmatter / github: Projects フィールド）のいずれかが空欄、または存在しない README を指している | Epic README へのリンクがバンドル絶対パス（`/` 始まり）でない（`references/okf-conformance.md` §4） |
| 2 | 受け入れ基準（AC）の具体性 | AC が 0 件、または全て `<!-- TODO -->` のまま | AC が 2 件以下 / 検証手段が外部観測不能（実装内部に依存する記述） |
| 3 | タスクの粒度 | タスクが 0 件、または「実装する」「修正する」のような単一汎用語のみ | タスクが 2 件以下 / 「テスト追加」「ドキュメント更新」が含まれていない |
| 4 | 見積もり完了 | `points`（正規語彙。local: frontmatter / github: Projects フィールド）が 0 のまま | `estimation.mode` が `pert` で `o = m = p`（PERT の意味が無い）/ `points` ≥ `split_threshold`（既定 13、分割推奨） |
| 5 | リスク識別（**任意**） | **なし**（リスク分析は `compose-stories` でオプション扱いのため、未識別はブロッカーにしない） | `risks` が空（識別を推奨）/ `risk_score` が 0 のまま（識別自体が形式的な可能性）/ Epic レベルのリスクが本 Story に関連と本文に明記されているのに、Story 表に展開されていない |
| 6 | DoD の存在 | 「Definition of Done」が空（local: 本文に DoD セクションが無い / github: DoD コメントが 0 件）、かつ設定ファイルに `dod` が設定されている | DoD はあるがチェック項目が空配列 |

依存関係（`dependencies` で他 Story の item_ref を参照している場合）は **参照先が実在するか** を `get_item` で軽く確認する。存在しない参照は「警告」とする（差し戻しまでは強制しない）。

> **チェックの正規語彙について**: Points / Risk Score / 階層 ID は `references/tracker-contract.md` §3 の正規語彙（`points` / `risk_score` / `objective` / `initiative` / `epic`）で参照する。local アダプタはこれらを frontmatter から、github アダプタ（Phase 2）は Projects フィールドから取得する。本スキルは provider 内部形式に依存しない。

### 4. ユーザーへのレビュー提示

機械チェック結果と本文の主要部（タイトル / 概要 1〜2 行 / AC 件数 / タスク件数 / Points / 最大リスクスコア）をまとめて `AskUserQuestion` で次の 4 択を提示する:

- **通過**: ブロッカー無しを確認し、`draft` を外す
- **通過（条件付き）**: 警告のみで合意できる場合に、警告内容をレビュー結果に残して `draft` を外す
- **差し戻し**: ブロッカーまたは警告についてレビュー結果に指摘を残し、`draft` を維持
- **保留**: 今は判定しない（次回の `review-stories` に持ち越す）

ブロッカーがある場合は **既定で「差し戻し」を推奨** する。ユーザーが意図的に通過を選んだ場合は確認のうえ進める（卒業の責任はユーザーにある）。

レビュー観点が薄い項目（例: 「AC の具体性が低い」）について、`AskUserQuestion` で「文言を一緒に詰める？」と提案できる。承認なら追加の対話に進み、改善された本文を `update_item(item_ref, {body})` で更新する。**ユーザー承認のない本文書き換えはしない**。

### 5. 通過時の処理

通過判定が確定したら、次の順序で処理する。**順序が重要**: 先にサマリーを付与し、それが成功してから `draft` を外す。サマリー付与が失敗した場合は `draft` を残してエラーを表示する（卒業の証となるサマリーが残らないまま卒業状態にならないようにするため）。

#### 5-1. サマリーの付与（卒業の証）

`compose-stories` が作成した本文は階層・背景・AC・タスク・見積もり・リスク・依存・参考と項目が多く、ぱっと見では要点が掴みづらい。本ステップでレビューを通して得た情報を凝縮し、**人間が一目で要点を掴める「サマリー」を `add_comment` で付与** する。

**設計判断（本文ではなくサマリーを別途付与する理由）**: 本文は compose-stories が作成した内容そのままを保ち、サマリーは別途 `add_comment` で追加する。理由は (1) 本文の原本性が保たれる（後から作成時の状態を辿れる）、(2) 本文構造を破壊するリスクがない、(3) サマリー付与は本文編集より追加的・非破壊的な操作で安全、(4) 再レビュー時はサマリーだけを置換できる、の 4 点。

**サマリーに含める要素**（順序は厳密に守る。読み手がこの順で目を通す前提）:

1. **何をやる**: タイトルを言い換える 1〜2 文。「〜することで〜する」の形式が望ましい
2. **なぜ**: 解決したい課題を 1 文。「現状〜なので〜したい」の形式
3. **規模感**: `points` / 最大リスクスコア / σ（PERT で算出済なら）を 1 行に集約
4. **対象スコープ**: 含むものを 1 行で（5 件以下に絞る。本文の AC や「スコープ」から抽出）
5. **やらないこと**: 重要な除外を 1〜2 件（誤解を生みやすいものを優先）
6. **押さえどころ（最大リスク）**: 最大スコアのリスクとその対応策を 1 行
7. **完了の鍵**: AC のうち最も外せないものを 1〜2 件
8. **着手前にやるべきこと**: 調査・前提整理が必要な事項を 1〜2 件（リスク表の Medium 以下の対応策から抽出）

各項目は **1 行（長くて 2 行）に収める**。長文化したくなったら、本文の該当セクションへのリンク（local ではバンドル絶対パス、github では GitHub URL）を貼る判断をする。

**サマリー本文のフォーマット**（マーカー `<!-- review-stories: summary -->` を含めて、再レビュー時の検出を可能にする）:

```markdown
## レビューサマリー（YYYY-MM-DD）

<!-- review-stories: summary -->

- **何をやる**: <1〜2 文>
- **なぜ**: <1 文>
- **規模感**: Points **<N>** / 最大リスクスコア **<N>** / σ=<N>（PERT <O>-<M>-<P>）
- **対象スコープ**: <含むもの 1 行>
- **やらないこと**: <重要な除外 1〜2 件>
- **押さえどころ（最大リスク）**: <最大リスク内容> → <対応策>
- **完了の鍵**: <最重要 AC 1〜2 件>
- **着手前にやるべきこと**: <調査・前提整理事項 1〜2 件>

> 詳細は本文の「背景・目的」「受け入れ基準」「リスクと対応策」を参照。
> 通過時の警告（あれば）: <内容>

<!-- /review-stories: summary -->

---
*Posted by `review-stories` skill. 本文は compose-stories の作成内容そのまま保持されている。*
```

**付与の手順（新規 / 再レビュー両対応・抽象操作）**:

1. ステップ 2 で取得済みの既存コメント / 本文を走査し、`<!-- review-stories: summary -->` を含むもの（既存サマリー）を探す
2. サマリー本文を組み立てる
3. **既存サマリーがある場合**: 同マーカーで囲まれた区間を **置換** する（再レビュー時の冪等性。サマリーは増えない）
4. **存在しない場合**: `add_comment(item_ref, <サマリー本文>)` で **新規付与**

provider 別の展開先（アダプタが振り分ける）:

- **local**: `add_comment` は本文末尾に `## レビューサマリー（YYYY-MM-DD）` セクションとして追記する（`references/backends/local.md` の `add_comment`）。再レビュー時はマーカーで囲まれた既存セクションを `Edit` で置換する（日付は最新に更新）。本文への追記であるため、`updated_at` / `timestamp` の更新と `log.md` への `Update` 行追記を伴う
- **github（Phase 2）**: Issue コメントとして投稿する。再レビュー時は同マーカーを持つコメントを置換する（`references/backends/github.md`）

**サマリー付与が失敗するケース**:
- ユーザーが対話的に「サマリー文言を一緒に詰める」を選んだが、合意に至らなかった
- `add_comment`（github アダプタ。Phase 2）が権限・ネットワーク等で失敗

このいずれの場合も、**`draft` ラベルは外さない**。エラーを表示し、ユーザーに「保留 / 強制通過（draft 削除のみ） / 中止」を再確認する。**サマリー付与なしに draft を外すのは推奨しない**（本機能の本質は「人間が読める形に整えてから卒業させる」ことだから）。

**本文には触れない**。compose-stories の作成内容を保持することが本設計の核（local では DoD セクション・AC 等の既存本文を改変しない。サマリーは本文末尾への追記のみ）。本文の編集が必要なケース（AC を一緒に詰める等）はユーザー承認のうえで `update_item` で例外的に行うが、サマリー追加目的では行わない。

#### 5-2. ラベル更新（draft 削除 / 必要なら ready 付与）

5-1 が成功した後にのみ実行する。

```
remove_label(item_ref, "draft")
# 必要に応じて
add_label(item_ref, "ready")
```

local では frontmatter の `labels[]` を編集する（`draft` を除去し、必要なら `ready` を追加。あわせて `tags` も同期する）。github（Phase 2）では Issue ラベルを編集する（`references/backends/<provider>.md`）。

`ready` ラベルの運用方針はチーム合意に依存するため、`AskUserQuestion` で「`ready` も付ける？」を初回のみ確認し、以降のセッションでは同じ判断を踏襲する。`ready` ラベルが未存在の場合は `ensure_label("ready")` で保証する（local では no-op、github（Phase 2）ではユーザー確認のうえ作成）。

#### 5-3. レビュー結果の付与

通過時は **チェック結果サマリーのみ** をレビュー結果として `add_comment` で付与する（要点はステップ 5-1 のサマリーで別途付与済なので、本結果は「レビューが行われたこと」と「警告内容」のログ用途）:

```markdown
## レビュー結果: 通過

本 Story は `review-stories` の品質ゲートを通過した。要点は別途付与の「レビューサマリー」を参照（同項目内のマーカー `review-stories: summary` 付き）。

### チェック結果サマリー
- 階層情報: OK
- 受け入れ基準: OK（N 件）
- タスク: OK（N 件）
- 見積もり: Points=N（基準点比較メモあり）
- リスク: 最大スコア N
- DoD: 設定済

### 通過時の警告（参考・あれば）
- <内容>

---
*Reviewed by `review-stories` skill.*
```

local では本文末尾への追記（サマリーとは別セクション）、github（Phase 2）では別コメントとして投稿する。

### 6. 差し戻し時の処理

`draft` は維持したまま、指摘事項を `add_comment` で残す:

```markdown
## レビュー結果: 差し戻し

本 Story は `review-stories` の品質ゲートを通過しなかった。以下の指摘を解消したうえで再レビュー（再度 `/review-stories` 実行）を依頼する。

### ブロッカー（要対応）
- <指摘内容と該当セクション>

### 警告（強く推奨）
- <内容>

### 推奨される次のアクション
- 見積もり未完: `/estimate-points <item_ref>` を実行する
- リスク未識別: `/identify-risks <item_ref>` を実行する
- 受け入れ基準が薄い: `/compose-stories <item_ref>` で既存 Story を肉付けする

---
*Reviewed by `review-stories` skill. `draft` ラベルは維持されている。*
```

ブロッカー条件と推奨アクションは具体的に紐づけて書く（例: 「Points = 0」→「`estimate-points` 実行（Phase 2）」）。曖昧な指摘（「もう少し詳しく」）は避ける。差し戻しは `draft` を外さない（`remove_label` を呼ばない）。

### 7. バッチモード時の運用

複数項目を一括レビューする場合、項目ごとに以下のループを回す:

1. `get_item` → 機械チェック
2. ユーザーに `AskUserQuestion` でレビュー提示 → 判定取得
3. 通過 / 差し戻し / 保留に応じた処理
4. 次の項目へ

1 セッションで 5 件超を扱う場合、3 件ごとに `AskUserQuestion` で「続ける / 中断する」を確認する（疲労による誤判定を避けるため）。中断時は **未レビュー項目の item_ref 一覧** を結果サマリーに残し、次回の起動時に引き継げるようにする。

### 8. 結果サマリー

セッション終了時に以下を表示する:

- **通過**: item_ref / タイトル / 削除されたラベル / 付与されたラベル / provider
- **差し戻し**: item_ref / タイトル / 主要ブロッカー（1 行）
- **保留**: item_ref / タイトル / 次回引き継ぎ用メモ
- **スキップ**: item_ref / 理由（既に卒業済・未存在・quick 混在・provider 前提未充足 等）

次のスキル候補:

- `/estimate-points <item_ref>`（差し戻された項目の見積もりが未完の場合。現在有効）
- `/identify-risks <item_ref>`（差し戻された項目のリスクが未識別の場合。現在有効）
- `/compose-stories <item_ref>`（差し戻された項目の本文を詰める場合）
- `/sync-stories <md-path>`（通過した local Story を github へアップロードする場合。**Phase 2**）
- 通過した項目をスプリント計画に組み込む（手動）

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `get_item` / `list_items` / `add_comment` / `remove_label` / `add_label` / `ensure_label` / `update_item` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **provider 別の出力先**:
  - local（既定）: Story md（OKF concept）のみを編集。サマリーは本文末尾の `## レビューサマリー（YYYY-MM-DD）` に追記、`draft` 削除は frontmatter `labels[]` 編集
  - github（Phase 2）: Issue コメント + Issue ラベルのみ変更
- 本スキルは **Story の卒業判定とサマリー付与** を担う。通過時にサマリーを別途付与するのは「卒業の証」かつ「読みやすさの引き上げ」両方の意味がある
- **本文（既存セクション）には触れない**。compose-stories の作成内容を **原本** として保持する。サマリーは独立して付与される（local は本文末尾への追記、github は独立コメント。いずれもマーカー `<!-- review-stories: summary -->` 〜 `<!-- /review-stories: summary -->` を含む）。本文の編集が必要な特殊ケース（AC を一緒に詰める等）はユーザー承認のうえで `update_item` で例外的に許容するが、サマリー追加目的では行わない
- **サマリー付与が成功しないと `draft` ラベルは外さない**。「人間が読める形に整えてから卒業させる」のが本機能の本質のため、サマリー無しで draft だけ外すのは推奨しない。やむを得ない場合はユーザー明示承認のうえで「強制通過（サマリーなし）」を許容する
- **再レビュー時のサマリーは置換**。マーカー `<!-- review-stories: summary -->` を含む既存サマリーを置換するため、サマリーは増えない（local は本文セクションの `Edit` 置換、github（Phase 2）はコメント置換）
- サマリーは **8 行以内 / 各行 1〜2 行** の制約を守る。長文化したくなったら本文の該当セクションへのリンク（local: バンドル絶対パス / github: GitHub 絶対 URL）を貼って詳細を委譲する（サマリーは「読み手の判断起点」、本文は「裏取り」）
- 通過時は **2 つのレビュー出力が残る**: (1) サマリー（ステップ 5-1）、(2) レビュー結果（ステップ 5-3）。役割分担は「(1) は現在の Story 状態の凝縮、(2) はレビューサイクルの履歴ログ」。(1) は再レビューで置換、(2) は毎回新規追加
- **リスク分析の有無はリジェクト理由にしない**。`compose-stories` ではリスク分析をオプション扱い（作成時に `risk_score` = 0 で良い）にしているため、本スキル側で「リスク未識別」をブロッカー扱いすると compose-stories の方針と矛盾する。Check 5 はあくまで「警告」レベルで、`/identify-risks` の実行を **推奨** するに留める
- `draft` ラベルが付いていない項目は **既に卒業済** とみなし、再レビューには意思表示（`AskUserQuestion` で「強制的に再レビューする？」を尋ねる）を要求する。誤って通過済を差し戻さないため
- `ready` ラベルは **任意の運用** である。`ready` を使わないチームでは `draft` 削除のみで卒業とする（チームの好みで設定可）
- 機械チェックの「警告」は通過を妨げないが、ユーザーが意図して見送る判断ができるよう **必ずレビュー結果に残す**。後から経緯を辿れるようにするため
- DoD 未設定の場合（設定ファイルに `dod` があるのに本文に無い / github でコメントが無い）、`compose-stories` の作成時に失敗した可能性があるため、`AskUserQuestion` で「いま付与する？」を提案できる
- Epic 単位レビューで対象が 0 件（その Epic に `draft` 付き Story が無い）の場合は「すでに全件卒業済」と通知して終了する
- **OKF 準拠**: local のサマリー追記・ラベル編集は frontmatter / 本文の OKF concept としての適合（`references/okf-conformance.md` §2）を維持する。サマリー追記・ラベル変更で Story を更新した際は Epic 階層の `log.md` に `Update` 行を追記する（§3）。`index.md` の更新は `build-bundle` の責務（本スキルは触らない）
- 「ブロッカー」と「警告」の境界はチーム合意に依存する部分があるため、`.claude/leadcraft.md` に将来 `review.blockers` / `review.warnings` を加えて override 可能にする余地を残してある（現状はスキル内固定）
- 本スキルは **本文の卒業判定** をする。実装可否（技術的妥当性 / アーキテクチャ整合）は別の責務であり、`/ai-code-review` 等の専用スキルや人間レビュアーに委ねる
- レビュー結果は **「これは自動生成である」と分かる形** で付与する（末尾に `*Reviewed by review-stories skill.*` を付ける運用）。チームメンバーが手動で残したのか、スキル経由なのかを区別できるようにするため
