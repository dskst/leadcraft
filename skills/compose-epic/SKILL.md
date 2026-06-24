---
name: compose-epic
description: スクラム文脈の Epic（複数の Story を束ねる大きなプロダクトバックログアイテム）を 1 件、対話を通じて整え、プラグイン同梱の `epic.md` テンプレートから `<root>/<objective>/<initiative>/<epic>/README.md` として生成・更新する。さらに、既存 Epic README に Story 候補が書かれている場合は、それらをトラッカー抽象操作（`create_item`）経由で起票する機能も含む。「Epic を作る」「Epic を起票する」「Epic README を書く」「価値仮説を整える」「DoD を整理する」「ユーザーフローを設計する」「機能のまとまりを言語化する」「Epic を見直す」「Epic を更新する」「Epic を分解する」「Epic から Story を抽出する」「大規模 md をタスクブレイクする」「計画書を Story 分割する」と言われたら起動する。Story を詳細設計しながら新規に複数件作りたい場合は `compose-stories` を案内する。**「Story 候補をざっくり洗い出したい」「ブレストして発散させたい」「Issue 化前に Story の輪郭だけ並べたい」という軽量な発散だけが目的なら `brainstorm-stories` を案内する**（本スキルのモード B は既存 Epic README からの抽出 + 起票だが、brainstorm-stories は起票せず md ドラフトに残す点で目的が異なる）。
argument-hint: "（任意：Epic の概要メモ md パス、ID 候補、URL、既存 Epic README パス）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# compose-epic

5 階層（Objective > Initiative > Epic > Story > Task）における **Epic** を 1 件、丁寧に作り込むための専用スキル。

本スキルは 2 つのモードを内包する。実行時の入力から自動判定し、必要に応じて両方を順に実行する。

| モード | 入力 | 主な動作 |
|--------|------|----------|
| **A. Epic を整える** | 要件メモ / URL / 空（対話） | プラグイン同梱の `epic.md` テンプレートから Epic README を新規作成 or 差分更新する |
| **B. Epic から Story を抽出** | 既存 Epic README のパス | Epic README 内の Story 候補（H2 見出し / リスト等）を機械的に拾い、`compose-stories` 経由でトラッカーへ起票する（Story md ファイルは作成しない） |

両方を同時に実行することもできる（例: 既存の薄い Epic README を整えつつ、そこに書かれた Story 候補も切り出す）。
Story を一から **詳細設計** しながら複数件作る場合は `compose-stories` を案内する。compose-stories は受け入れ基準・タスク・依存関係を踏み込んで作るのに対し、本スキルのモード B は既存テキストの抽出に留める。

## 想定する利用シーン

- 親 Initiative は決まっており、配下に新しい Epic を立てたい
- 既存 Epic の DoD / スコープ / 価値仮説 / ユーザーフローを見直して README を最新化する
- これまで単一 md（例: `docs/plans/<epic-id>.md` 等）で管理してきた計画書を、本プラグイン構成（Epic README + Story 群）に変換したい
- Epic README に「Story 一覧」表だけ書いて、個別 Story が未起票、という状態を解消したい
- ステークホルダー間で「この Epic は何の塊なのか」の共通認識をとるためのドラフトを作りたい

## 出力

| モード | 出力 | 雛形 |
|--------|------|------|
| A. Epic を整える | `<root>/<objective>/<initiative>/<epic>/README.md` | `${CLAUDE_PLUGIN_ROOT}/skills/compose-epic/templates/epic.md` |
| B. Story 抽出 | **`compose-stories` 経由でトラッカーへ N 件起票**（Story md ファイルは作成しない） | `${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story.md`（`compose-stories` が利用） |

`<root>` は設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は `compose-objective` が対話で確定）。
既存 Epic README は **上書きしない**。差分提案 → ユーザー承認後に `Edit` で部分更新する。恒久運用 Epic（例: `hotfix` の受け皿）も本スキルで編集できる。

## 実行手順

### 1. 設定ファイルの読み込み

`.claude/leadcraft.md` を `Read` し、以下を取得する。

- `output.root_dir` … Epic の出力先ルート（未設定なら `compose-objective` を先に実行するよう案内し、フォールバックは `docs/objectives`）
- `tracker.provider` … トラッカー種別（未設定なら `local`）
- `okf.emit_log` … `log.md` 追記の要否（未設定なら `true` とみなす）

### 2. 入力ソースの特定とモード判定

引数または対話で以下のいずれかを取得する。引数が空ならまず `AskUserQuestion` で選択肢を提示する。

- チャットに書かれた Epic 概要テキスト
- Markdown / メモ ファイルパス（`Read`）
- **既存 Epic README** のパス（モード B を有効化するシグナル）
- URL（`WebFetch`）
- 親 Initiative のディレクトリパス（`<root>/<objective>/<initiative>/`）
- 「ゼロから対話で組み立てる」（入力なし）

Notion ページが渡された場合は、現セッションで利用可能な MCP ツール（`mcp__*__notion-fetch` 等）を動的に検出し、あれば呼び出す。無ければ `WebFetch` に切り替える。

モード判定の目安:

| 入力の性質 | モード |
|------------|--------|
| 要件メモ / URL / 空（対話で組み立て） | A |
| 既存 Epic README / 旧形式の単一 Epic md | B（必要なら A も） |
| 既存 Epic README + 新しい変更要件 | A + B |

判定が曖昧な場合は `AskUserQuestion` で「Epic 自体を整える / Story を抽出する / 両方」の 3 択を提示する。

### 3. 親 Objective / Initiative の特定

Epic は必ず Initiative の下にぶら下がる。`Glob` で次の構造を列挙して候補を提示する。

```
<root>/*/            # 既存 Objective
<root>/*/*/          # 既存 Initiative
```

`AskUserQuestion` で次を確認する。

- どの Objective / Initiative の下に Epic を置くか（既存 / 新規）
- Initiative README（`<root>/<objective>/<initiative>/README.md`）が存在するか

存在しない上位階層がある場合の方針:

- **Objective README が無い**: 「Objective を整える時は `compose-objective` を別途実行することを推奨する」と案内したうえで、Epic 作成は続行できる。Epic フロントマターの `objective` には予定 ID を入れる
- **Initiative README が無い**: `compose-initiative` の利用を推奨する。続行する場合は `${CLAUDE_PLUGIN_ROOT}/skills/compose-initiative/templates/initiative.md` から **最小構成の README** を生成する。インセプションデッキ等は `<!-- TODO: ... -->` で空欄を残し、「Initiative の詳細は `compose-initiative` で別途整える必要がある」と明示する

モード B のみで既存 Epic README が渡された場合は、そのパスから Objective / Initiative を逆算する（`<root>/<objective>/<initiative>/<epic>/README.md` のパス構造）。逆算できない（旧形式 `docs/plans/<epic-id>.md` 等）の場合は、`AskUserQuestion` で配置先を確認する。

### 4. Epic ID とタイトルの確定

新規作成の場合は次を確定する。決められなければ `AskUserQuestion` で確認する。

- **base_id（ベース ID）**: kebab-case の英小文字。例: `oauth-login`, `cart-checkout-redesign`
- **ID（フロントマター・ディレクトリ名・ラベルに用いる正式 ID）**: 親 Objective YAML の `id_suffix` を末尾に付けた `<base_id>-<id_suffix>` 形式（suffix 未設定なら `<base_id>` のまま）
- **タイトル**: 日本語可。プロダクト視点で簡潔に
- **オーナー**: プロダクトオーナー / リードエンジニアの氏名 or ロール
- **target_release**: リリース予定（バージョン or 時期）。未確定なら空欄可

ID の候補が思いつかない場合は、タイトルから base_id を 2〜3 案提示してユーザーに選ばせる。

#### 4-1. 親 Objective から id_suffix を継承する

親 Objective README（`<root>/<objective>/README.md`）を `Read` し、YAML フロントマターの `id_suffix` を取得する:

- **`id_suffix` が設定されている**（例: `a1b2c`）: Epic の正式 ID を `<base_id>-<id_suffix>` で組み立てる。ディレクトリ名・YAML `id` フィールド・`label` フィールド（`epic:<full-id>`）すべてにこの正式 ID を使う
- **`id_suffix` が未設定 or 空文字**（後方互換 / 旧 Objective）: `base_id` をそのまま正式 ID として使う（従来動作）。「リポジトリ跨ぎ衝突回避のため `compose-objective` で id_suffix を追加することを推奨」とユーザーに案内する
- **親 Objective README が存在しない**: ステップ 3 の方針に従う（compose-objective を案内するか、暫定 ID で続行）

確認: 既存 Initiative 配下に同名の正式 ID が無いことを `Glob` で確認する（`<root>/<objective>/<initiative>/<full-id>/README.md`）。

モード B 専用で既存 Epic を扱う場合は、既存 README のフロントマターから `id` を取得する（既に suffix 付きの正式 ID が入っている前提）。

### 5. （モード A）Epic 本文の項目埋め

`${CLAUDE_PLUGIN_ROOT}/skills/compose-epic/templates/epic.md` の構成を骨格として、以下を埋めにいく。判明している範囲で書き、不明部分は `<!-- TODO: ... -->` で明示する。インセプションデッキ系（なぜここにいるのか / エレベーターピッチ等）は **親 Initiative の責務** であり、Epic では繰り返さない。

#### 5-1. 概要

解決する課題と、提供する価値を 2〜3 行で記述する。長文にしない。

#### 5-2. ユーザーストーリーサマリー

> **\<role\>** として、**\<goal\>** したい。なぜなら **\<reason\>** だから。

Epic レベルでの大枠の物語を 1〜3 行で記述する。Story 分解の出発点となる。
厳密なユーザーストーリー形式に違和感がある場合は、自然言語の説明でも可とする。

#### 5-3. 解きたい問題と価値仮説

- **解きたい課題**: 現状の何が問題か
- **価値仮説**: 「〜することで、〜が改善されると考える」の形で記述する
- **検証指標 / メトリクス**: 仮説の真偽を判定する指標。親 Objective の KPI とつなげられるとよい

価値仮説と検証指標は Epic を「やる価値があるか」を判定する重要な要素のため、薄い場合は `AskUserQuestion` で深掘りする。

#### 5-4. 対象ユーザー / ペルソナ

- 主要ペルソナ（想定する利用者の属性・状況）
- 副次ペルソナ（影響を受ける周辺の利用者）

#### 5-5. スコープ

- **含むもの**: この Epic で対応する機能・変更（箇条書き）
- **含まないもの（スコープ外）**: 混同しがちだが、この Epic では扱わない事項

スコープ外の明示はステークホルダー合意の核になるため、最低 1〜2 件は書くよう促す。

#### 5-6. Epic 完了の定義（Definition of Done）

Epic 全体が完了したと見なすための条件をチェックリスト形式で列挙する。Story 単位の DoD とは独立に、より上位の「ユーザー価値が実利用できる状態」「計測・モニタリングが整っている」「リリースノート / ドキュメントが更新されている」「ステークホルダーへのデモが完了している」などを並べる。
恒久運用 Epic（例: `hotfix`）の場合は、「DoD は設定しない（恒久 Epic として継続運用）」と明示する。

#### 5-7. 主要ユーザーフロー

最低 1 つのフローを記述する。次の構造を推奨する。

- **トリガー**: 何が起点になるか
- **主要ステップ**: 番号付きの 3〜6 ステップ
- **完了条件**: ユーザーから見たゴール

加えて Mermaid の `flowchart LR` で簡易図を併記する。複雑な分岐がある場合は別 Story に切り出す候補としてメモを残す。

#### 5-8. 依存関係（外部）

- 前提となる Epic / システム（あれば内部リンクはバンドル絶対パス `/` 始まりで記述）
- 本 Epic がブロックするもの

#### 5-9. リスクサマリーの初期化

`identify-risks` スキルが後で埋めることを想定し、表のヘッダーと初期行（プレースホルダー）だけ残す。本スキルで具体的なリスクを書くのは、ユーザーから明示的な指摘があった場合に限る。

#### 5-10. オープン課題 / 未決事項

Story 分解前に解消が必要な疑問・調査事項を箇条書きで残す。空でも構わない。

### 6. （モード A）OKF frontmatter の設定

雛形のフロントマターを次のルールで初期化／更新する（`references/okf-conformance.md` § 2 参照）。

- `type: epic`（固定）
- `id`: ステップ 4 で組み立てた正式 ID
- `title`: ステップ 4 で決めたタイトル
- `description`: Epic の価値を **1 文**で要約。index.md と AI 関連度判定の土台になるため必ず埋める
- `tags`: トラッカーのラベルをミラーリングする場合はラベル名のリストを入れる（例: `["epic:oauth-login-a1b2c"]`）
- `resource`: provider が `github` の場合は Issue 一覧フィルタ URL（例: `https://github.com/<owner>/<repo>/issues?q=label%3Aepic%3A<epic-id>`）。provider が `local` または URL を生成できない場合は `null`
- `timestamp`: 実行日時（`Bash` で `date -u +%FT%TZ`）。`updated_at` と同値
- `objective`: ステップ 3 で確定した親 Objective の id
- `initiative`: ステップ 3 で確定した親 Initiative の正式 ID
- `status`: 新規は `planning`。更新時はユーザー確認のうえ `planning | in_progress | done | cancelled` から選択
- `created_at`: 新規時のみ実行日（`Bash` で `date -u +%FT%TZ`）
- `updated_at`: 常に実行日で上書き
- `owner`: ステップ 4 で取得
- `target_release`: ステップ 4 で取得（未確定なら空）
- `label`: `epic:<id>` 形式の文字列（suffix 付き正式 ID。配下 Story に付与し Epic 単位の絞り込みに使う）

### 7. （モード A）Epic README のファイル出力

- **新規作成**: `<root>/<objective>/<initiative>/<epic>/` を `Bash` の `mkdir -p` で作成し、雛形を読み込んで本文を埋めたうえで `Write` する
- **既存更新**: 差分パッチを提案し、ユーザー承認の後に `Edit` で部分更新する。フロントマター・既存記述を破壊しない

ディレクトリ作成前に、作成先パスをユーザーに提示して承認を得る。

#### 7-1. Epic ラベル / タグの保証

配下 Story 項目をトラッカー上で絞り込むためのラベル `epic:<epic-id>` を保証する。
トラッカー抽象操作 `ensure_label` を使う（provider のアダプタ `references/backends/<provider>.md` に委譲）。

> **注意**: スキル本文に `gh label create` 等の具体コマンドを直書きしない。
> github アダプタが `ensure_label` を `gh label list / gh label create` に変換する。

ラベル保証に失敗した場合（既存ラベルとの衝突など）は警告を表示し、`compose-stories` での Story 起票時にも再試行する前提を伝える。

#### 7-2. log.md への追記

`okf.emit_log` が `true`（または未設定）の場合、Epic ディレクトリ（`<root>/<objective>/<initiative>/<epic>/log.md`）に以下を追記する:

```
## YYYY-MM-DD
- Creation: <epic-title> Epic を作成
```

更新の場合は `Creation` を `Update` に替え、変更概要を 1 行で記す。
`log.md` が存在しない場合は `# Log\n\n` ヘッダーから新規作成する。

### 8. （モード B）Epic README から Story 候補の抽出 → 起票

入力が既存 Epic README（または旧形式の単一 Epic md）の場合、または「Story 抽出を続けたい」とユーザーが指示した場合に実行する。

#### 8-1. Story 候補の検出

Epic README または旧 Epic md を `Read` し、以下のパターンから Story 候補を拾う:

- H2 / H3 見出しのうち「Story」「機能」「タスク」を含むもの
- 「やること」「ToDo」「機能一覧」リスト内の項目
- 旧形式 md にあれば「Story 一覧」表の各行
- mermaid 図のノードラベル

これらを統合して候補リストを作り、`AskUserQuestion` で「以下の Story 候補で抽出を進めるか？修正があれば指摘してほしい」と提示する。

#### 8-2. 各 Story への情報マッピング

各 Story 候補について、Epic README 内から関連情報を集約する:

- タイトル、概要
- 受け入れ基準があれば抽出
- リスクサマリーで該当 Story に紐づくものがあれば抽出
- 依存関係があれば抽出

情報が不足する Story は、ユーザーに補完情報を求めるか、空欄のまま `<!-- TODO: ... -->` を残す。**Story の詳細設計（受け入れ基準やタスクを一から作る）には踏み込まない**。それは `compose-stories` の責務である。

#### 8-3. `compose-stories` への引き渡しによる起票

抽出した Story 候補群を **`compose-stories` スキルに渡して起票する**。

`compose-stories` が次を一括で行う:

- 雛形から Story 本文を構築
- トラッカー抽象操作 `create_item` で起票する（provider のアダプタ `references/backends/<provider>.md` に委譲）
  - `local`: Story md を `<epic-dir>/<slug>.md` として生成
  - `github`: GitHub Issue + Projects に起票（Phase 2）
- ラベル / タグ `story` + `epic:<epic-id>` を付与（`add_label` 操作）

委譲時に渡す情報:

- 親 Epic の `objective` / `initiative` / `epic` ID と README パス
- 抽出した各 Story 候補の構造化データ（タイトル / 概要 / 抽出済みの受け入れ基準・タスク・依存）
- 「既存 Epic README からの抽出である」旨のメモ（Story 本文中に出典として残せるように）

抽出時点で受け入れ基準やタスクが薄い候補については、`compose-stories` 側で対話的に補完する（本スキルでは深追いしない）。

### 9. 旧形式 Epic md からの移行（任意）

入力が旧 `docs/plans/<epic-id>.md` のような単一 md ファイルだった場合は、上記 8 の前に次を行う:

- 新形式の `<root>/<objective>/<initiative>/<epic>/README.md` を生成（モード A の手順を流用）
- 元 md の内容を該当セクションに移植
- 移植後、元 md の削除可否をユーザーに確認

### 10. リンク整合性の確認

- 親 Initiative README（`<root>/<objective>/<initiative>/README.md`）の「関連 Epic」表に、本 Epic の行を追加 / 更新する
- 内部リンクは**バンドル絶対パス（`/` 始まり、バンドルルート相対）**で記述する（`okf.link_style` が `absolute` の場合。既定）
  - 例: `/customer-retention-2026/framework-modernization-a1b2c/oauth-login-a1b2c/README.md`
- Epic README に書かれた「依存関係（外部）」のリンクが、実在する Epic README を指しているかを `Glob` で軽く確認する。リンク切れは TODO コメントを残す
- モード B で Story を起票した場合、Epic README に **Story 一覧表は作らない**（`list_items` 操作や各トラッカーのビューで参照する方針）

### 11. 次のステップ案内

完成 / 更新したファイルパスと、モード B で起票した Story 項目の参照先を表示し、次のスキル候補を提示する:

- **Story を新規追加したい**: `/compose-stories <epic-readme-path>`（対話で詳細設計しつつ起票）
- **既存 Story を見積もりたい**: `/estimate-points`
- **リスクを洗い出したい**: `/identify-risks`
- **基準点未設定**: `/setup-baseline`
- **DoD 未設定**: `/setup-dod`

## 注意事項

- Epic は単独のトラッカー項目を持たない。本スキルが触るのは Epic README（および親 Initiative README の「関連 Epic」表）のみ
- 既存 README を **上書きしない**。差分提案 → 承認 → `Edit` の流れを徹底する
- **OKF frontmatter の `description` / `tags` / `timestamp` / `resource` は必ず埋める**（OKF 適合の推奨フィールド）
- **Epic の正式 ID は親 Objective の `id_suffix` を末尾に付ける**（リポジトリ跨ぎで衝突しないため）。ID を後から変更すると、ディレクトリ rename・ラベル rename・既存 Story のラベル付け替えがすべて必要になるため、Epic 作成時に確定する
- インセプションデッキ系の項目（なぜここにいるのか / エレベーターピッチ等）は **親 Initiative README** の責務であり、Epic README では繰り返さない
- **モード B は既存テキストからの Story 候補抽出に留め、実際の起票は `compose-stories` に委譲する**。本スキル単体では `create_item` を直接呼ばない
- **スキル本文に `gh` 等の具体コマンドを直書きしない**。トラッカー操作は抽象操作名（`ensure_label` / `create_item` 等）で記述し、`references/backends/<provider>.md` のアダプタに委譲する
- 旧形式の単一 Epic md を入力された場合、ステップ 9 の移行を経てから Story 抽出に進む
- Story 候補を抽出できない（情報が薄い）場合は、`compose-stories` に切り替えるよう案内する
- 価値仮説が出てこない Epic は「やる価値が言語化できていない」サイン。`AskUserQuestion` で深掘りを促すが、それでも詰められない場合は「価値仮説は要確認」を TODO として残し、Epic 自体の優先度を再考するよう案内する
- 出力先 `<root>` は `output.root_dir` 設定を必ず確認する。未設定なら `compose-objective` を先に実行することを案内する
- **Epic README に Story 一覧表を作らない / 維持しない**。Story の参照はトラッカー（`list_items` 操作）または各プロバイダのビューで行う
