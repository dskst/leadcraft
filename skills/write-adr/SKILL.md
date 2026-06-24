---
name: write-adr
description: 5 階層モデル（Objective / Initiative / Epic / Story / Task）における Objective・Initiative・Epic のいずれか、または **Objective 横断（cross-objective）** に紐づく ADR（Architecture Decision Record）を 1 件、対話を通じて作成・更新するスキル。ADR は親階層の文脈から導出される技術的・組織的決定の記録であるため、特定 Objective 配下の場合は親階層ディレクトリ配下の `adr/` サブディレクトリに固定する（例: `<root>/<objective>/<initiative>/<epic>/adr/<YYYYMMDD>-<kebab-title>.md`）。**複数 Objective を跨ぐ全社・全プロダクト共通の決定（共通技術スタック・全社セキュリティ方針・横断的アーキテクチャ原則など）は `<root>/adr/` 配下に出力する** ことで、特定 Objective に属さない意思決定を一元管理できる。Context / Decision / Consequences の 3 セクション構成で書き、OKF 準拠の YAML frontmatter（`type: adr` ほか）には作成日・ステータス・親階層 ID・関連 Story・supersedes 関係などを保持する。「ADR を書きたい」「ADR を作成して」「アーキテクチャ決定を記録して」「技術選定を記録して」「導入判断をドキュメント化して」「Epic 配下に ADR を作る」「設計判断を残す」「意思決定記録」「Objective 横断の ADR を作る」「全社共通の技術方針を残す」「複数プロダクトに跨る決定を記録する」「横断的なアーキテクチャ原則を文書化する」と言われたら起動する。会話中に ADR・意思決定記録・技術選定への言及があれば、明示的に求められなくても本スキルでの作成を提案する。コードベースを Grep / Glob で調査し、実データ（ファイル数・参照箇所数・依存関係）を Context に含めることで判断の妥当性を読者が再現できる品質を目指す。
argument-hint: "（任意：ADR の概要メモ md パス、親階層 README のパス、または既存 ADR ファイル）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# write-adr

5 階層（Objective > Initiative > Epic > Story > Task）のうち、**Objective / Initiative / Epic のいずれか**、または **Objective 横断（cross-objective; 複数 Objective を跨ぐ全社レベル）** に紐づく ADR（Architecture Decision Record）を 1 件、丁寧に作り込むための専用スキル。

ADR の本質は「**なぜその決定をしたのか**」を残すこと。コードは「何を」「どのように」を伝えるが、「なぜそうしたのか」は伝わらない。本スキルはそのギャップを埋める。

leadcraft プラグインの特徴として、ADR は親階層（Objective / Initiative / Epic）の文脈に紐づけて配置する。例えば「観測性向上 Initiative」配下に「構造化ログライブラリ導入 ADR」を置くことで、後から読む人が「なぜこの決定が必要だったか」を親階層の KPI / 価値仮説と接続して理解できる。

ただし、**特定の Objective に属さない横断的な決定** も実務では存在する。共通技術スタック・全社セキュリティ方針・横断的アーキテクチャ原則・モノレポ運用ルールなど、複数 Objective に跨って影響を及ぼす決定がそれにあたる。こうした決定を無理に特定の Objective 配下に押し込めると、後から「なぜここに？」となり所在が失われる。そのため本スキルは **`cross-objective` レベル** を用意し、`<root>/adr/` 配下に直接配置することで、組織横断の意思決定を一元的に管理できるようにしている。

なお、本スキルが生成するツリーは OKF（Open Knowledge Format）準拠の Knowledge Bundle の一部である（`references/okf-conformance.md` を参照）。ADR concept は OKF 必須の `type: adr` を持ち、OKF 推奨フィールド（`title` / `description` / `resource` / `tags` / `timestamp`）を備える。

## 想定する利用シーン

- Epic 配下の技術選定（ライブラリ・フレームワーク・パターン）を記録したい
- Initiative の方針判断（アーキテクチャ刷新の段階移行戦略など）を残したい
- Objective レベルの基盤決定（マイクロサービス境界・データストア戦略など）をドキュメント化したい
- **複数 Objective に跨る横断的決定**（共通言語選定・全社認証基盤・モノレポ運用ルール・全社セキュリティ方針など）を残したい
- 既存の ADR を `superseded_by` 関係で置き換えたい
- レビューで指摘された設計判断を ADR として明文化したい

Story 単位の細かい実装判断は ADR ではなく Story 本文に書く。ADR は **複数の Story や Epic に跨って影響する判断** を対象とする。

## 出力

| 項目 | 値 |
|------|----|
| ファイル（階層配下） | `<root>/<objective>[/<initiative>[/<epic>]]/adr/<id>.md` |
| ファイル（Objective 横断） | `<root>/adr/<id>.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/write-adr/references/adr-template.md` |
| 文体・詳細度 | `${CLAUDE_PLUGIN_ROOT}/skills/write-adr/references/adr-sample.md` に合わせる |
| `<root>` | 設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は `compose-objective` が対話で確定） |
| 既存ファイル | 上書きせず、差分提案 → ユーザー承認後に `Edit` で部分更新 |

`adr/` サブディレクトリは存在しなければ作成する（事前にユーザー承認を取る）。Objective 横断の場合は `<root>/` 直下に各 Objective ディレクトリと並ぶ形で `adr/` を配置する。

## YAML frontmatter（OKF 準拠）

雛形（`references/adr-template.md`）の各フィールドの意味（`references/okf-conformance.md` § 2 参照）:

### OKF 必須

| フィールド | 値 |
|------------|----|
| `type` | `adr` 固定（OKF 必須の非空 `type`）。Glob で ADR のみ列挙する際にも使う |

### OKF 推奨

| フィールド | 値 |
|------------|----|
| `title` | 日本語可。検索・一覧表示に使う |
| `description` | **1 文の要約**。`index.md` の progressive disclosure と AI の関連度判定の土台になるため必ず埋める |
| `resource` | 基礎資産を指す URI。関連 Issue があればその URL、無ければ `null` |
| `tags` | 横断検索用の文字列リスト（例: `[backend, security, migration]`） |
| `timestamp` | ISO 8601 の最終更新日時。`updated_at` と同値でよい |

### leadcraft 拡張

| フィールド | 必須 | 値 |
|------------|------|----|
| `id` | ✅ | `<YYYYMMDD>-<kebab-title>` 形式（例: `20260519-introduce-structured-logging`）。ファイル名（拡張子抜き）と一致させる |
| `status` | ✅ | `accepted` / `deprecated` / `superseded`。本プラグインでは **「ADR は accepted の状態でプルリクエストを起こし、PR マージをもって承認とする」運用** を前提とするため、`proposed` は使わない（草案段階は PR ブランチで完結する） |
| `created_at` | ✅ | `YYYY-MM-DD`。最初に作成した日 |
| `updated_at` | 推奨 | `YYYY-MM-DD`。本文に手を入れたタイミングで更新 |
| `owner` | 推奨 | 提案者（個人 or ロール） |
| `level` | ✅ | `cross-objective` / `objective` / `initiative` / `epic`。階層検索の高速化 |
| `objective` / `initiative` / `epic` | 階層に応じ | 親階層 ID。クロスリファレンスに必須。**`cross-objective` の場合は 3 つとも空文字** |
| `affected_objectives` | 任意 | `cross-objective` 時に推奨。影響を受ける Objective ID の配列（例: `[checkout, growth]`）。横断 ADR の参照範囲を明示するため |
| `supersedes` | 任意 | 本 ADR が置き換える元 ADR の ID |
| `superseded_by` | 任意 | 本 ADR を置き換えた別 ADR の ID |
| `related_stories` | 任意 | 関連 Story を item_ref 語彙で参照する配列（`references/tracker-contract.md` § item_ref）。`local` はバンドル絶対パス（例: `["/customer-retention-2026/auth-overhaul-a1b2c/oidc-a1b2c/password-reset.md"]`）、`github` は Issue 番号（例: `["#123", "#145"]`。Phase 2）|
| `tags` | 任意 | OKF 推奨と兼用（上記）|

## 品質方針

ADR は **読み手が前提知識なしで判断の妥当性を理解できる品質** を目指す。会話中に ADR・意思決定記録・技術選定ドキュメントへの言及があれば、明示的に求められなくても作成を提案する。

- **Context 以降の本文は 1,000 文字以内** に収める。サラッと読める長さを最優先とする
- 想定される疑問・懸念を先回りして本文中で解消する
- 影響範囲を限定的かつ具体的に示す（ファイル数、参照箇所数などの実データを含める）
- ロールバック可能であることを明記する
- ADR には方針レベルの移行方針を記載し、詳細な移行計画・担当・工数は Story 側で管理する
- 既存実装を否定せず「現在はより良い方法がある」というトーンで書く
- 「現状維持」を選択肢に含める — 「何もしない」場合のデメリットを明示すると、変更の必要性が自然に伝わる

---

## ワークフロー

### Step 1: 参照ドキュメントの読み込み

1. `${CLAUDE_PLUGIN_ROOT}/skills/write-adr/references/adr-template.md` と `${CLAUDE_PLUGIN_ROOT}/skills/write-adr/references/adr-sample.md` を `Read` で読む
2. `references/okf-conformance.md` の frontmatter 規約・クロスリンク規約（§ 2 / § 4 / § 5）を確認する
3. プロジェクトに `docs/glossary.md` があれば読み、表記ルールに従う。なければスキップ
4. 出力先（後述の Step 2 で確定）に既存の ADR があれば、同階層・親階層のものを 1〜2 件 `Read` して、スタイルの一貫性を保つ
5. ユーザーが指定した懸念事項・要件・提案ドキュメントを `Read`

### Step 2: 親階層の特定（出力先確定）

ADR は Objective / Initiative / Epic のいずれか、または **Objective 横断（cross-objective）** に紐づく。引数または対話で次のいずれかを取得する。引数が空ならまず `AskUserQuestion` で選択肢を提示する。

- 親階層 README のパス（推奨。例: `<root>/<objective>/<initiative>/<epic>/README.md`）
- 親階層のディレクトリパス
- 階層 ID + level の組（例: `level=epic, epic=structured-logging`）
- cross-objective を選んだ場合は親階層 ID は不要（`<root>/adr/` に直接配置）

設定ファイル `.claude/leadcraft.md` から `output.root_dir` を読み込む。設定済みなら保存値を使い、未設定なら `compose-objective` で確定してくることを案内する（フォールバックは `docs/objectives`）。

`Glob` で既存の階層を列挙して候補を提示する:

```
<root>/*/README.md          # Objective
<root>/*/*/README.md        # Initiative
<root>/*/*/*/README.md      # Epic
<root>/adr/*.md             # 既存の Objective 横断 ADR
```

`AskUserQuestion` で次を確認する。

- どのレベル（`cross-objective` / `objective` / `initiative` / `epic`）に ADR を紐づけるか
- レベルが Objective 配下の場合、該当する親階層が既存か（既存なら ID 選択 / 無ければ「先に整える必要がある」旨を案内）

#### cross-objective を選ぶ判断基準

次のいずれかに当てはまる場合は `cross-objective` を推奨する。迷ったら `AskUserQuestion` でユーザーと確認する。

- **影響範囲が複数 Objective に明確に跨る**（例: 全社認証基盤、共通技術スタック、モノレポ運用ルール）
- **どの Objective にも一義に属さない横断的方針**（例: 全社セキュリティポリシー、コーディング規約、横断的アーキテクチャ原則）
- **特定 Objective 配下に置くと所在が失われる**（複数チームが「うちの Objective ではない」と扱う性質のもの）

逆に、単一の Objective / Initiative / Epic の文脈で十分説明できる決定は、最も近い親階層に置く（横断ぽく見えても、実態が特定 Objective に紐づくなら無理に cross-objective にしない）。

#### 親階層が無い場合の方針

- **Objective が無い**（level=objective/initiative/epic 時）: `compose-objective` を先に実行するよう推奨。ユーザーが続行を選んだ場合は予定 ID を `objective` に入れる
- **Initiative が無い**（level=initiative or epic 時）: `compose-initiative` を先に実行するよう推奨
- **Epic が無い**（level=epic 時）: `compose-epic` を先に実行するよう推奨
- **cross-objective の場合**: 親階層が存在しなくても作成可能（`<root>` だけあれば良い）

出力ディレクトリの最終形:

| level | 出力先 |
|-------|--------|
| `cross-objective` | `<root>/adr/` |
| `objective` | `<root>/<objective>/adr/` |
| `initiative` | `<root>/<objective>/<initiative>/adr/` |
| `epic` | `<root>/<objective>/<initiative>/<epic>/adr/` |

### Step 3: タイトルと ADR ID の確定

#### 3-1. タイトルの確定

決められなければ `AskUserQuestion` で確認する。

- **タイトル**: 日本語可。決定内容を端的に表す（例:「構造化ログライブラリ導入」「OAuth2.0 認証への移行」）
- **kebab-case タイトル**: ファイル名・ID に使う英小文字 + ハイフン区切り（例: `introduce-structured-logging`）。タイトルから自動生成案を 2〜3 件提示し、ユーザーに選ばせる

#### 3-2. ID の生成

`Bash` で `date +%Y%m%d` を実行して当日日付（例: `20260519`）を取得し、3-1 の kebab-title と結合して ID を生成する: `<YYYYMMDD>-<kebab-title>`。

例: `20260519-introduce-structured-logging`

ファイル名はそのまま `<id>.md`（例: `adr/20260519-introduce-structured-logging.md`）。frontmatter の `id` フィールドとファイル名（拡張子抜き）を一致させる。

同日に同 kebab-title の ADR が同スコープ内に存在することは想定しない。万一 `Glob` で衝突を検出した場合は 3-1 のタイトルを変更するようユーザーに促す。

### Step 4: コードベース調査

ADR に説得力を持たせるために、実データを調査する。**推測ではなく `Grep` / `Glob` の実行結果を使う**。

調査対象の例:

- **参照箇所数**: `Grep` でシングルトン・グローバル変数の参照数を計測（例: `Config.getInstance()` → 45 ファイル / 120 箇所）
- **ファイル数**: `Glob` で対象パターンのファイル数を計測（例: コントローラー 80 ファイル、テンプレート 35 ファイル）
- **依存関係**: パッケージ管理ファイル（`package.json`、`build.gradle`、`Gemfile` 等）から現在の依存状況を確認
- **既存パターン**: 導入しようとする技術の既存使用状況を確認
- **定義箇所**: 変更対象のファイルパスと行番号を特定

これらの実データを Context セクションに含めることで、後から読む人が「この判断が必要だった根拠」を再現できる。調査で得た `file:line` 根拠は、本文末尾の慣用見出し `# Citations`（出典）下にまとめてもよい（`references/okf-conformance.md` § 5）。

### Step 5: 親階層 README の読み込みと文脈接続

#### level = objective / initiative / epic の場合

親階層（Objective / Initiative / Epic）の README を `Read` し、ADR の文脈に接続する:

- **Objective の KPI**: ADR が達成にどう寄与するか
- **Initiative のインセプションデッキ**: ADR の判断が「やらないこと」「諦めるもの」と矛盾していないか
- **Epic のスコープ / DoD**: ADR が Epic の価値仮説と整合的か

文脈接続が見えない ADR は、ADR 自体が不要か親階層を見直すサイン。`AskUserQuestion` で再確認する。

#### level = cross-objective の場合

単一の親 README が存在しないため、代わりに次を行う:

1. `Glob` で `<root>/*/README.md` を列挙し、**影響を受ける Objective を 2 件以上特定** する（特定できなければ cross-objective は不適切なサイン。単一 Objective 配下に置くべきか `AskUserQuestion` で再確認）
2. 影響を受ける各 Objective の README を `Read` し、KPI / スコープを把握する
3. ADR の Context セクションに「本 ADR が影響する Objective 一覧」を箇条書きで明示し、それぞれの KPI / 文脈との関連を 1〜2 行で書く（読み手が「自分の Objective にどう関わるか」を即座に判断できる状態にする）
4. 既存の `<root>/adr/*.md` を `Glob` で列挙し、類似の横断方針が既に存在しないか確認する（重複・矛盾を避けるため）

横断的決定は影響範囲が広いぶん、文脈接続を省くと「いつ・誰のために決めたのか」が見えなくなる。Objective 配下 ADR より丁寧に Context を書く。

### Step 6: ADR 本文の構築

雛形の構造（Context / Decision / Consequences）に厳密に従い、サンプルの文体・詳細度に合わせて記述する。

#### 6-1. Context（背景・現状の課題）

- なぜ今この決定が必要か
- Step 4 で集めた実データを明示
- 親階層（Step 5）の KPI / 価値仮説とどう繋がるか
- 検討した選択肢を最低 2 つ（推奨案 + 現状維持）、できれば 3 つ以上、Pros / Cons とともに列挙

#### 6-2. Decision（決定内容）

- 何を選んだか、なぜか
- 移行の方針（段階的に行う等）を記載
- **具体的なフェーズ・工数・担当は Story に分離**（本 ADR では触れない）

#### 6-3. Consequences（結果）

- ポジティブ・ネガティブ・中立の影響を区別して書く
- 親 Objective / Initiative の KPI への寄与を明示
- ロールバック手順を 1〜2 行で書く

#### 6-4. Citations（出典・任意）

Step 4 のコードベース調査で得た `file:line` 根拠を、本文末尾の慣用見出し `# Citations` 下にまとめる（`references/okf-conformance.md` § 5）。本文中に都度埋め込んでも、ここに集約しても良い。

### Step 7: YAML frontmatter の設定

雛形のフロントマターを次のルールで埋める（`references/okf-conformance.md` § 2 参照）:

- `type: adr`（固定。OKF 必須）
- `id`: Step 3 で採番
- `title`: Step 3-1 で確定
- `description`: 決定内容を **1 文** で要約（OKF 推奨。`index.md` と AI 関連度判定の土台になるため必ず埋める）
- `resource`: 関連 Issue があればその URL、無ければ `null`（OKF 推奨）
- `tags`: 横断検索用キーワードのリスト（OKF 推奨）
- `timestamp`: 実行日時の ISO 8601（`Bash` で `date -u +%FT%TZ`）。`updated_at` と同値（OKF 標準キー）
- `status`: 新規は **`accepted` 固定**。本プラグインの運用上、ADR は PR を起こす時点で `accepted` として書く（PR マージ = 承認）。承認後に古くなった場合のみ `deprecated`、別 ADR で置き換えた場合のみ `superseded` に変更する
- `created_at`: 実行日（`Bash` で `date +%Y-%m-%d`）
- `updated_at`: 実行日。新規時は `created_at` と同じ
- `owner`: 提案者の名前 or ロール。**デフォルト取得手順**（複数 Git ホスティングアカウント運用に対応）:
  1. `Bash` で `git remote get-url origin` を実行し、リモート URL からホスト名を抽出する（例: `git remote get-url origin | sed -E 's|^(https?://\|git@)([^:/]+).*|\2|'`）。`github.com` や自己ホスト型 Git ホストが取れる
  2. 抽出したホストに対して `Bash` で `gh auth status --hostname <host> 2>&1 | grep -oE 'account [A-Za-z0-9_-]+' | awk '{print $2}' | sort -u` を実行し、そのホストにログイン中のアカウント一覧を取得する
  3. **0 件 / コマンド失敗**（`gh` 未インストール、未ログイン、リモート未設定 等）: 空欄で `AskUserQuestion` を提示しユーザー手入力に委ねる
  4. **1 件**: その login をデフォルト候補として `AskUserQuestion` 提示（ユーザーは Enter で承認 / Other で別名・ロール名に上書き可能）
  5. **2 件以上**: 全 login を `AskUserQuestion` の選択肢に並べる。`gh auth status` の出力中で `Active account: true` の直前に出るアカウントを Recommended マークにする。Other で任意のロール名や別名にも上書き可能

  承認者は PR レビュー機能で管理するため frontmatter には記録しない
- `level`: Step 2 で確定（`cross-objective` / `objective` / `initiative` / `epic`）
- `objective` / `initiative` / `epic`: Step 2 で確定した階層 ID。該当しないレベルは空文字。**`cross-objective` の場合は 3 つとも空文字**
- `affected_objectives`: `cross-objective` の場合のみ。Step 5 で特定した影響対象 Objective ID を配列で（例: `[checkout, growth]`）。それ以外のレベルでは空配列または省略
- `supersedes`: 既存 ADR を置き換える場合のみ。元 ADR の `superseded_by` も後ほど更新する
- `superseded_by`: 新規時は空
- `related_stories`: 関連 Story を item_ref 語彙で配列に（`AskUserQuestion` で任意取得）。`local` はバンドル絶対パス、`github` は Issue 番号（Phase 2）
- `tags`: 横断検索用のキーワード（OKF 推奨と兼用。任意）

日付・時刻は `Bash` で取得:

```
date +%Y-%m-%d        # created_at / updated_at
date -u +%FT%TZ       # timestamp
```

### Step 8: ファイル出力

`<root>/<objective>[/<initiative>[/<epic>]]/adr/<id>.md` に書き出す。

- ディレクトリが存在しなければ `Bash` の `mkdir -p` で作成する（事前にユーザー承認）
- 雛形（`adr-template.md`）を `Read` し、プレースホルダを埋めて `Write` する
- HTML コメント（`<!-- -->`）は出力に含めない（雛形の編集ガイドコメント）
- 内部リンク（親 README・関連 Story・supersedes 先 ADR）は **バンドル絶対パス（`/` 始まり）** で書く（`references/okf-conformance.md` § 4）

#### 8-1. log.md への追記

設定ファイルの `okf.emit_log` が `true`（または未設定）の場合、出力先の **親階層ディレクトリ** の `log.md` に 1 行追記する（`references/okf-conformance.md` § 3）。

- level=epic なら `<root>/<objective>/<initiative>/<epic>/log.md`、cross-objective なら `<root>/log.md`
- **新規作成**: `Creation: ADR <id>（<title>）を作成`
- **既存更新**: `Update: ADR <id> を更新（変更概要を簡潔に）`

`log.md` が存在しない場合は `# Log\n\n` ヘッダーから新規作成する。エントリは ISO 8601 日付（`YYYY-MM-DD`）でグルーピングし新しい順に並べる。

### Step 9: 既存 ADR との関係性の更新（任意）

`supersedes` が設定された場合、被参照側の ADR を更新する:

1. `Read` で元 ADR を取得
2. フロントマターの `superseded_by` を本 ADR の ID で更新
3. `status` を `superseded` に変更
4. `updated_at` を実行日で更新
5. `Edit` で反映（ユーザー承認後）

本文中で元 ADR を参照する場合のリンクも **バンドル絶対パス** で書く。

### Step 10: レビュー・修正

作成後にユーザーのフィードバックを受け、選択肢の追加 / 削除、表現調整などを行う。

更新時は本文の該当セクションのみを `Edit` で差し替え、`updated_at` と `timestamp` を実行日（時）に上書きする。**全体上書きはしない**。

### Step 11: 次のステップ案内

完成した ADR のパスを表示し、状況に応じて次のスキル候補を提示する:

- 関連 Story を作成したい: `/compose-stories <epic-readme-path>`（Story の本文に「本 Story は ADR `<id>` に基づく」と明記する旨を案内）
- 親 Epic / Initiative の更新が必要: `/compose-epic` / `/compose-initiative`
- リスクを Story に展開: `/identify-risks`
- 既存 ADR を一覧したい: `Glob` で `<root>/**/adr/*.md` を列挙して提示（`cross-objective` の `<root>/adr/` も同パターンに含まれる）
- `cross-objective` の場合は、影響を受ける各 Objective README の「関連 ADR」セクションに本 ADR のバンドル絶対パスを追記することを推奨（横断 ADR は所在が見えづらいため、各 Objective から逆引きできる導線を残す）

---

## 記述ルール

- **全て日本語** で記述する。技術用語・コード識別子・ライブラリ名は原語のまま
- プロジェクトに用語集（`docs/glossary.md`）があれば表記ルールに従う
- コード名・クラス名はバッククォート付き英語（例: `Config.getInstance()`）
- 機能・概念の説明は日本語（例: ユーザー認証、通知設定）
- カタカナ長音「ー」を付ける（サーバー、ユーザー、エンドポイント）

---

## 必須事項

- 選択肢は最低 2 つ（推奨案 + 現状維持）を必ず提示する。できれば 3 つ以上
- コード例にはファイルパス:行番号を必ず付ける（`# Citations` に集約してもよい）
- 移行の方針は Decision に記載し、具体的なフェーズ・工数・担当は Story に分離する
- テンプレートの HTML コメント（`<!-- -->`）は出力に含めない
- ファイル名の prefix（`id`）と frontmatter の `id` は一致させる
- OKF 必須の `type: adr` と OKF 推奨フィールド（`description` / `tags` / `resource` / `timestamp`）を必ず埋める
- 親階層の README が存在する場合は、その KPI / 価値仮説と接続して Context を書く
- `cross-objective` の場合は、影響を受ける Objective を 2 件以上 Context に明示し、各 Objective の KPI / スコープに対する関連を 1〜2 行で記述する
- 内部リンクはバンドル絶対パス（`/` 始まり）で書く

## 禁止事項

- コードベースを調査せずに影響範囲を記述することは禁止 → 必ず `Grep` / `Glob` で実データを取得してから記述する
- タイトルに `ADR-XXXX:` 等の連番プレフィックスを付けることは禁止（採番は frontmatter の `id` で管理する。他ツールへの移植時の二重採番を防ぐ）
- 配置先を曖昧にした ADR は禁止 → `cross-objective` / `objective` / `initiative` / `epic` のいずれかに **明示的に分類** する。単一 Objective に紐づけられるなら最も近い親階層に置き、複数 Objective を跨ぐ場合は `cross-objective` を選ぶ（「とりあえずどこかに置く」は不可）
- `cross-objective` を安易に選ぶことは禁止 → 影響範囲が単一 Objective で説明できるなら、無理に横断扱いせず親階層配下に置く（横断 ADR の濫用は所在の曖昧化を招く）
- 既存 ADR の `status` を手動で `superseded` にする際、`superseded_by` の指定を省略しない（双方向リンクを保つ）
