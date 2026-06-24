---
name: write-dd
description: 5 階層モデル（Objective / Initiative / Epic / Story / Task）における Objective・Initiative・Epic のいずれか、または **Objective 横断（cross-objective）** に紐づく Design Doc（設計ドキュメント）を 1 件、対話を通じて作成・更新するスキル。Design Doc は Google の "Design Docs at Google"（industrialempathy.com）の構造を日本語化したテンプレートを使い、特定 Objective 配下の場合は親階層ディレクトリ配下の `design-docs/` サブディレクトリに固定する（例: `<root>/<objective>/<initiative>/<epic>/design-docs/<kebab-title>.md`）。**複数 Objective を跨ぐ全社・全プロダクト共通の設計（共通基盤・全社認証プラットフォーム・横断データパイプライン・モノレポ全体のビルド方式など）は `<root>/design-docs/` 配下に出力する** ことで、特定 Objective に属さない設計を一元管理できる。本文は「背景とスコープ / ゴールと非ゴール / 設計 / 検討した代替案 / 横断的な関心事」の 5 セクション構成で書き、OKF 準拠の YAML frontmatter（`type: design-doc` ほか）には作成日・ステータス・親階層 ID・関連 Story・関連 ADR などを保持する。**Design Doc は「常に生きたドキュメント」として運用する**: 設計の改訂は新規ファイルを作らず同ファイルを上書き編集し、過去の経緯は git log で追う（ADR と違って supersedes は使わない）。「Design Doc を書きたい」「設計ドキュメントを作成して」「設計書を書く」「アーキテクチャの設計書」「技術設計書を作る」「Epic 配下に Design Doc を作る」「設計を文書化する」「DD を書く」「デザインドキュメント」「Objective 横断の設計書を書く」「全社共通基盤の設計を残す」「複数プロダクトに跨る設計をドキュメント化する」「横断データパイプラインの設計書」と言われたら起動する。会話中に「設計を残したい」「設計書として書く」「設計をドキュメント化したい」等の言及があれば、明示的に求められなくても本スキルでの作成を提案する。**ADR との使い分け**: ADR は単一の意思決定（"なぜそう決めたか"）の記録、Design Doc は複数の決定を内包した広めの設計記述（"どう作るか"）。点の決定なら `write-adr`、面の設計なら本スキルを使う。コードベースを Grep / Glob で調査し、実データを背景に含めることで判断の妥当性を読者が再現できる品質を目指す。
argument-hint: "（任意：Design Doc の概要メモ md パス、親階層 README のパス、または既存 DD ファイル）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# write-dd

5 階層（Objective > Initiative > Epic > Story > Task）のうち、**Objective / Initiative / Epic のいずれか**、または **Objective 横断（cross-objective; 複数 Objective を跨ぐ全社レベル）** に紐づく **Design Doc（設計ドキュメント）** を 1 件、丁寧に作り込むための専用スキル。

特定の Objective に属さない横断的な設計（共通基盤・全社認証プラットフォーム・横断データパイプライン・モノレポ全体のビルド方式など）も実務では存在する。こうした設計を無理に特定 Objective 配下に押し込めると所在が失われるため、本スキルは **`cross-objective` レベル** を用意し `<root>/design-docs/` 配下に直接配置する選択肢を提供する。判断基準は write-adr と同じ（複数 Objective に明確に跨る / 一義の親が決められない / 特定 Objective 配下に置くと所在が失われる、のいずれか）。

Design Doc は「**問題を解くためにどう設計するか**」を関係者間で共有するためのドキュメント。コードは "どう動くか" を伝えるが、設計の "なぜそうしたか / 他の選択肢と比較して何が良いか / どんな横断要件を考慮したか" は伝わらない。本スキルはそのギャップを埋める。

Google の "Design Docs at Google"（[industrialempathy.com/posts/design-docs-at-google](https://www.industrialempathy.com/posts/design-docs-at-google/)）で示される 5 セクション構成（Context and Scope / Goals and Non-Goals / The Actual Design / Alternatives Considered / Cross-Cutting Concerns）を日本語化したテンプレートを使う。

なお、本スキルが生成するツリーは OKF（Open Knowledge Format）準拠の Knowledge Bundle の一部である（`references/okf-conformance.md` を参照）。Design Doc concept は OKF 必須の `type: design-doc` を持ち、OKF 推奨フィールド（`title` / `description` / `resource` / `tags` / `timestamp`）を備える。

## ADR との使い分け

| | write-adr | write-dd（本スキル） |
|---|---|---|
| 性質 | **点の決定**: 単一の意思決定の記録 | **面の設計**: 複数の決定を内包する広めの設計記述 |
| 例 | 「ログライブラリは Zap を採用する」 | 「観測性プラットフォーム全体の設計」 |
| 長さ | 短く（本文 1,000 字以内目安） | 中〜長（本文 ~10,000 字目安、small は 2,000 字でも可） |
| セクション | Context / Decision / Consequences の 3 | 背景とスコープ / ゴールと非ゴール / 設計 / 検討した代替案 / 横断的な関心事 の 5 |
| 関係 | Design Doc に内包・参照される | Design Doc の `related_adrs` に列挙する |
| バージョニング | `supersedes` で別ファイルとして履歴を残す | **同ファイル上書きで常に最新版を維持**（履歴は git log） |

判断に迷ったら: 「決定が 1 つだけで、Pros/Cons が短く書けるなら ADR」「複数のコンポーネントや段階的移行を含むなら Design Doc」。

### Design Doc は生きたドキュメント

ADR は意思決定の歴史を残すため過去の決定を別ファイルで保存する（`supersedes` / `superseded_by` で双方向リンク）。一方 **Design Doc は「現時点での最良の設計」を 1 ファイルで表現する**ため、改訂は同ファイル上書きで行い、過去版は git log で追う。複数バージョンの DD ファイルが並ぶ運用は避ける（「現在の設計はどれか」が一目で分かる状態を保つ）。

設計対象自体が完全に別物に置き換わる（例: `auth-platform` → `decentralized-identity` で全く違う方向性に転換した）場合は、旧 DD の `status: deprecated` に更新したうえで放置するか手動で削除し、新規 DD を別 kebab-title で起こす（このときも `supersedes` フィールドは使わず、本文中の参照で関係性を示す）。

## 想定する利用シーン

- Epic 配下の新機能・刷新の設計を関係者に共有したい
- Initiative レベルの基盤刷新（認証 / 観測性 / データ移行）の設計を残したい
- Objective レベルのアーキテクチャ方針（マイクロサービス分割・データストア戦略）をドキュメント化したい
- **複数 Objective に跨る横断的設計**（全社認証プラットフォーム・共通 API gateway・横断データパイプライン・モノレポ全体のビルド方式など）を残したい
- 既存 Design Doc を改訂したい（同ファイル上書きで現状を反映）
- ADR 群を集約して「全体としてどう作るか」を 1 つの設計に統合したい
- レビューで指摘された設計判断を Design Doc として明文化したい

Story 単位の細かい実装は Design Doc ではなく Story 本文に書く。Design Doc は **Epic 規模以上の設計** を対象とする。

## 出力

| 項目 | 値 |
|------|----|
| ファイル（階層配下） | `<root>/<objective>[/<initiative>[/<epic>]]/design-docs/<id>.md` |
| ファイル（Objective 横断） | `<root>/design-docs/<id>.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/write-dd/references/dd-template.md` |
| 文体・詳細度 | `${CLAUDE_PLUGIN_ROOT}/skills/write-dd/references/dd-sample.md` に合わせる |
| `<root>` | 設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は `compose-objective` が対話で確定） |
| 既存ファイル | 上書きせず、差分提案 → ユーザー承認後に `Edit` で部分更新 |

`design-docs/` サブディレクトリは存在しなければ作成する（事前にユーザー承認を取る）。Objective 横断の場合は `<root>/` 直下に各 Objective ディレクトリと並ぶ形で `design-docs/` を配置する。

## YAML frontmatter（OKF 準拠）

雛形（`references/dd-template.md`）の各フィールドの意味（`references/okf-conformance.md` § 2 参照）:

### OKF 必須

| フィールド | 値 |
|------------|----|
| `type` | `design-doc` 固定（OKF 必須の非空 `type`）。Glob で Design Doc のみ列挙する際にも使う |

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
| `id` | ✅ | `<kebab-title>` 形式（例: `unified-auth-platform`）。ファイル名（拡張子抜き）と一致させる |
| `status` | ✅ | `accepted` / `deprecated` の 2 値。本プラグインでは **PR を起こす時点で `accepted`** とする運用（草案は PR ブランチで完結）。設計対象自体が廃止された場合のみ `deprecated`。**`superseded` は使わない**（DD は同ファイル上書きで改訂するため） |
| `created_at` | ✅ | `YYYY-MM-DD`。最初に作成した日 |
| `updated_at` | 推奨 | `YYYY-MM-DD`。本文に手を入れたタイミングで更新 |
| `owner` | 推奨 | 主たる設計者（個人 or ロール） |
| `level` | ✅ | `cross-objective` / `objective` / `initiative` / `epic`。階層検索の高速化 |
| `objective` / `initiative` / `epic` | 階層に応じ | 親階層 ID。クロスリファレンスに必須。**`cross-objective` の場合は 3 つとも空文字** |
| `affected_objectives` | 任意 | `cross-objective` 時に推奨。影響を受ける Objective ID の配列（例: `[checkout, growth]`）。横断 Design Doc の参照範囲を明示するため |
| `related_adrs` | 任意 | 本設計が依拠する ADR の ID リスト（例: `["20251101-introduce-structured-logging", "20251115-adopt-oidc"]`）。ADR は点の決定、Design Doc はそれらを統合する面の設計 |
| `related_stories` | 任意 | 関連 Story を item_ref 語彙で参照する配列（`references/tracker-contract.md` § item_ref）。`local` はバンドル絶対パス、`github` は Issue 番号（例: `["#123", "#145"]`。Phase 2）|
| `tags` | 任意 | OKF 推奨と兼用（上記）|

## 品質方針

Design Doc は **読み手が前提知識なしで設計の妥当性を理解でき、レビューでフィードバックできる品質** を目指す。会話中に「設計書」「Design Doc」「設計をドキュメント化」への言及があれば、明示的に求められなくても作成を提案する。

- **長さは目安として ~10,000 字以内**（small DD は 2,000 字でも可）。Google 推奨の "10〜20 ページ" は英語前提なので日本語ではこの目安に圧縮する
- 簡潔性を最優先する。図と表で代替できる説明は本文に書かない
- 想定される疑問・懸念を先回りして本文中で解消する
- 実データ（ファイル数 / 参照箇所数 / 依存関係）を Grep / Glob で取得して背景に含める
- ロールバック可能であることを「横断的な関心事 > 運用」で明記する
- 「現状維持」を「検討した代替案」に必ず含める — 「何もしない」場合のデメリットを明示すると、変更の必要性が自然に伝わる
- 既存実装を否定せず「現在はより良い方法がある」というトーンで書く
- 詳細な実装フェーズ・工数・担当は Story に分離する（本 DD では方針までに留める）

---

## ワークフロー

### Step 1: 参照ドキュメントの読み込み

1. `${CLAUDE_PLUGIN_ROOT}/skills/write-dd/references/dd-template.md` と `${CLAUDE_PLUGIN_ROOT}/skills/write-dd/references/dd-sample.md` を `Read` で読む
2. `references/okf-conformance.md` の frontmatter 規約・クロスリンク規約（§ 2 / § 4 / § 5）を確認する
3. プロジェクトに `docs/glossary.md` があれば読み、表記ルールに従う。なければスキップ
4. 出力先（後述の Step 2 で確定）に既存の Design Doc があれば、同階層・親階層のものを 1〜2 件 `Read` して、スタイルの一貫性を保つ
5. 親階層配下の `adr/` に既存 ADR があれば、後述の Step 5 で参照するため列挙しておく
6. ユーザーが指定した懸念事項・要件・提案ドキュメントを `Read`

### Step 2: 親階層の特定（出力先確定）

Design Doc は Objective / Initiative / Epic のいずれか、または **Objective 横断（cross-objective）** に紐づく。引数または対話で次のいずれかを取得する。引数が空ならまず `AskUserQuestion` で選択肢を提示する。

- 親階層 README のパス（推奨。例: `<root>/<objective>/<initiative>/<epic>/README.md`）
- 親階層のディレクトリパス
- 階層 ID + level の組（例: `level=epic, epic=oidc-migration`）
- cross-objective を選んだ場合は親階層 ID は不要（`<root>/design-docs/` に直接配置）

設定ファイル `.claude/leadcraft.md` から `output.root_dir` を読み込む。設定済みなら保存値を使い、未設定なら `compose-objective` で確定してくることを案内する（フォールバックは `docs/objectives`）。

`Glob` で既存の階層を列挙して候補を提示する:

```
<root>/*/README.md          # Objective
<root>/*/*/README.md        # Initiative
<root>/*/*/*/README.md      # Epic
<root>/design-docs/*.md     # 既存の Objective 横断 Design Doc
```

`AskUserQuestion` で次を確認する。

- どのレベル（`cross-objective` / `objective` / `initiative` / `epic`）に Design Doc を紐づけるか
- レベルが Objective 配下の場合、該当する親階層が既存か（既存なら ID 選択 / 無ければ「先に整える必要がある」旨を案内）

#### cross-objective を選ぶ判断基準

次のいずれかに当てはまる場合は `cross-objective` を推奨する。迷ったら `AskUserQuestion` でユーザーと確認する。

- **影響範囲が複数 Objective に明確に跨る**（例: 全社認証プラットフォーム、共通 API gateway、横断データパイプライン）
- **どの Objective にも一義に属さない横断的設計**（例: モノレポ全体のビルド方式、全社共通の観測性基盤）
- **特定 Objective 配下に置くと所在が失われる**（複数チームが「うちの Objective ではない」と扱う性質のもの）

逆に、単一の Objective / Initiative / Epic の文脈で十分説明できる設計は、最も近い親階層に置く（横断ぽく見えても、実態が特定 Objective に紐づくなら無理に cross-objective にしない）。横断 Design Doc の濫用は所在の曖昧化を招く。

#### 親階層が無い場合の方針

- **Objective が無い**（level=objective/initiative/epic 時）: `compose-objective` を先に実行するよう推奨
- **Initiative が無い**（level=initiative or epic 時）: `compose-initiative` を先に実行するよう推奨
- **Epic が無い**（level=epic 時）: `compose-epic` を先に実行するよう推奨
- **cross-objective の場合**: 親階層が存在しなくても作成可能（`<root>` だけあれば良い）

出力ディレクトリの最終形:

| level | 出力先 |
|-------|--------|
| `cross-objective` | `<root>/design-docs/` |
| `objective` | `<root>/<objective>/design-docs/` |
| `initiative` | `<root>/<objective>/<initiative>/design-docs/` |
| `epic` | `<root>/<objective>/<initiative>/<epic>/design-docs/` |

### Step 3: タイトルと Design Doc ID の確定

#### 3-1. タイトルの確定

決められなければ `AskUserQuestion` で確認する。

- **タイトル**: 日本語可。設計内容を端的に表す（例:「認証基盤の OIDC 移行設計」「通知ハブの統合設計」）
- **kebab-case タイトル**: ファイル名・ID に使う英小文字 + ハイフン区切り（例: `unified-auth-platform`）。タイトルから自動生成案を 2〜3 件提示し、ユーザーに選ばせる

#### 3-2. ID の確定

3-1 の kebab-title をそのまま ID とする（例: `unified-auth-platform`）。日付や連番は付けない。ファイル名はそのまま `<id>.md`（例: `design-docs/unified-auth-platform.md`）。frontmatter の `id` フィールドとファイル名（拡張子抜き）を一致させる。

#### 3-3. 既存 DD との衝突チェック

`Glob` で出力先 `design-docs/` 配下に同 kebab-title の DD が存在しないか確認する:

- **既存ファイルあり**: 「既存の Design Doc を上書き更新するか / 別タイトルで新規作成するか」を `AskUserQuestion` で確認する。Design Doc は生きたドキュメントの運用が原則なので、**同じ設計対象なら上書き更新を推奨** する
- **既存ファイルなし**: そのまま新規作成へ進む

### Step 4: コードベース調査

Design Doc に説得力を持たせるために、実データを調査する。**推測ではなく `Grep` / `Glob` の実行結果を使う**。

調査対象の例:

- **影響範囲の規模**: `Grep` で対象機能の参照箇所数を計測（例: `auth.session.create` → 12 ファイル / 47 箇所）
- **既存コンポーネント**: `Glob` で対象パッケージのファイル数（例: `src/auth/**/*.ts` → 35 ファイル）
- **依存関係**: パッケージ管理ファイル（`package.json`、`build.gradle`、`Gemfile` 等）から現在の依存状況
- **既存パターン**: 導入しようとする技術が既に他の箇所で使われているか
- **データモデル**: スキーマ定義（マイグレーションファイル、ORM モデル、proto 定義）

これらの実データを「背景とスコープ」「設計」セクションに含めることで、後から読む人が「この設計が妥当である根拠」を再現できる。調査で得た `file:line` 根拠は、本文末尾の慣用見出し `# Citations`（出典）下にまとめてもよい（`references/okf-conformance.md` § 5）。

### Step 5: 親階層 README と関連 ADR の読み込み

#### 5-1. 親階層 README

##### level = objective / initiative / epic の場合

親階層（Objective / Initiative / Epic）の README を `Read` し、Design Doc の文脈に接続する:

- **Objective の KPI**: 本設計がどう寄与するか
- **Initiative のインセプションデッキ**: 「やらないこと」「諦めるもの」と矛盾しないか
- **Epic のスコープ / DoD / 価値仮説**: 設計が Epic のゴールと整合的か

文脈接続が見えない Design Doc は、Design Doc 自体が不要か親階層を見直すサイン。`AskUserQuestion` で再確認する。

##### level = cross-objective の場合

単一の親 README が存在しないため、代わりに次を行う:

1. `Glob` で `<root>/*/README.md` を列挙し、**影響を受ける Objective を 2 件以上特定** する（特定できなければ cross-objective は不適切なサイン。単一 Objective 配下に置くべきか `AskUserQuestion` で再確認）
2. 影響を受ける各 Objective の README を `Read` し、KPI / スコープを把握する
3. Design Doc の「背景とスコープ」に「本設計が影響する Objective 一覧」を箇条書きで明示し、それぞれの KPI / 文脈との関連を 1〜2 行で書く（読み手が「自分の Objective にどう関わるか」を即座に判断できる状態にする）
4. 既存の `<root>/design-docs/*.md` を `Glob` で列挙し、類似の横断設計が既に存在しないか確認する（重複・矛盾を避けるため）

横断的設計は影響範囲が広いぶん、文脈接続を省くと「いつ・誰のために設計したのか」が見えなくなる。Objective 配下 Design Doc より丁寧に背景を書く。

#### 5-2. 関連 ADR の列挙

Step 1 で列挙した親階層配下の ADR を再確認し、本 Design Doc が依拠する ADR があれば `related_adrs` に列挙する。

例: 認証移行 Design Doc が ADR `20251101-select-idp`（IdP 選定）と ADR `20251108-adopt-token-exchange`（トークン形式）を前提とする場合、`related_adrs: ["20251101-select-idp", "20251108-adopt-token-exchange"]` をセットし、本文中でも「ADR `20251101-select-idp` で選定済みの ...」のように参照する。本文中のリンクは **バンドル絶対パス（`/` 始まり）** で書く（`references/okf-conformance.md` § 4）。

cross-objective の Design Doc は、横断 ADR (`<root>/adr/*.md`) を主に参照する。横断 ADR が無く新たな点の決定が必要そうなら、Design Doc 内で深追いせず `/write-adr` の利用を案内する（`cross-objective` レベルの ADR としての登録を勧める）。

### Step 6: Design Doc 本文の構築

雛形の 5 セクション構造に厳密に従う。サンプル（`dd-sample.md`）の文体・詳細度に合わせて記述する。

#### 6-1. 背景とスコープ（Context and Scope）

- なぜ今この設計が必要か（1〜3 段落）
- Step 4 で集めた実データを明示
- 親階層（Step 5-1）の KPI / 価値仮説とどう繋がるか
- **スコープ**: 本設計が扱う範囲
- **スコープ外**: 混同しがちだが扱わない範囲（明示が重要。後のスコープクリープを防ぐ）

#### 6-2. ゴールと非ゴール（Goals and Non-Goals）

- **ゴール**: 達成すべきことを箇条書きで 3〜6 件
- **非ゴール**: 意図的にやらないことを 2〜4 件。なぜやらないかの一言を併記すると親切

非ゴールは Google Design Doc の重要な特徴。Goals と一緒に書くことでスコープが明確になる。

#### 6-3. 設計（The Actual Design）

- **概要**: 高レベル設計を 3〜5 行 + mermaid 図 1 つ
- **詳細**: コンポーネント / データフロー / API / データモデル / 状態遷移などをサブセクションで
- トレードオフと、なぜこの設計がゴールを最もよく満たすかを明示
- **詳細な実装フェーズ・工数・担当は Story に分離**（本 DD では「Story `password-reset` で対応」のように参照のみ）

設計の中核セクション。図（mermaid）と表を活用し、長文を避ける。

#### 6-4. 検討した代替案（Alternatives Considered）

最低 2 案、できれば 3 案以上。**「現状維持」を必ず含める**。各案について:

- **概要**: 何を提案する案か（2〜3 行）
- **採用しなかった理由**: ゴールに対して何が不足するか、どんなリスクがあるか

代替案の検討は Design Doc の信頼性の核。「他に何も考えなかった」と読まれないために必須。

#### 6-5. 横断的な関心事（Cross-Cutting Concerns）

設計が組織の標準・横断要件にどう影響するかを明示する。各項目は 1〜2 行。**該当しない項目は「該当なし（理由）」で残し、空欄にしない**。

- セキュリティ
- プライバシー
- 可観測性（ログ / メトリクス / トレース）
- パフォーマンス（SLO / レイテンシ）
- 運用（デプロイ / ロールバック / 障害対応）
- コスト（インフラ / 運用費）

組織で特有の関心事（i18n / アクセシビリティ / コンプライアンス等）があれば追加してよい。

#### 6-6. Citations（出典・任意）

Step 4 のコードベース調査で得た `file:line` 根拠を、本文末尾の慣用見出し `# Citations` 下にまとめる（`references/okf-conformance.md` § 5）。

### Step 7: YAML frontmatter の設定

雛形のフロントマターを次のルールで埋める（`references/okf-conformance.md` § 2 参照）:

- `type: design-doc`（固定。OKF 必須）
- `id`: Step 3-2 で確定（= kebab-title）
- `title`: Step 3-1 で確定
- `description`: 設計内容を **1 文** で要約（OKF 推奨。`index.md` と AI 関連度判定の土台になるため必ず埋める）
- `resource`: 関連 Issue があればその URL、無ければ `null`（OKF 推奨）
- `tags`: 横断検索用キーワードのリスト（OKF 推奨）
- `timestamp`: 実行日時の ISO 8601（`Bash` で `date -u +%FT%TZ`）。`updated_at` と同値（OKF 標準キー）
- `status`: 新規は **`accepted` 固定**（PR マージ = 承認）。設計対象自体が廃止になった場合のみ `deprecated` に変更する
- `created_at`: 実行日（`Bash` で `date +%Y-%m-%d`）
- `updated_at`: 実行日。新規時は `created_at` と同じ
- `owner`: 主たる設計者の名前 or ロール。**デフォルト取得手順**（複数 Git ホスティングアカウント運用に対応）:
  1. `Bash` で `git remote get-url origin` を実行し、リモート URL からホスト名を抽出する（例: `git remote get-url origin | sed -E 's|^(https?://\|git@)([^:/]+).*|\2|'`）。`github.com` や自己ホスト型 Git ホストが取れる
  2. 抽出したホストに対して `Bash` で `gh auth status --hostname <host> 2>&1 | grep -oE 'account [A-Za-z0-9_-]+' | awk '{print $2}' | sort -u` を実行し、そのホストにログイン中のアカウント一覧を取得する
  3. **0 件 / コマンド失敗**（`gh` 未インストール、未ログイン、リモート未設定 等）: 空欄で `AskUserQuestion` を提示しユーザー手入力に委ねる
  4. **1 件**: その login をデフォルト候補として `AskUserQuestion` 提示（ユーザーは Enter で承認 / Other で別名・ロール名に上書き可能）
  5. **2 件以上**: 全 login を `AskUserQuestion` の選択肢に並べる。`gh auth status` の出力中で `Active account: true` の直前に出るアカウントを Recommended マークにする。Other で任意のロール名や別名にも上書き可能

  レビュアー / 承認者は PR レビュー機能で管理するため frontmatter には記録しない
- `level`: Step 2 で確定（`cross-objective` / `objective` / `initiative` / `epic`）
- `objective` / `initiative` / `epic`: Step 2 で確定した階層 ID。該当しないレベルは空文字。**`cross-objective` の場合は 3 つとも空文字**
- `affected_objectives`: `cross-objective` の場合のみ。Step 5-1 で特定した影響対象 Objective ID を配列で（例: `[checkout, growth]`）。それ以外のレベルでは空配列または省略
- `related_adrs`: Step 5-2 で列挙した ADR ID 配列
- `related_stories`: 関連 Story を item_ref 語彙で配列に（`local` はバンドル絶対パス、`github` は Issue 番号。Phase 2）
- `tags`: 横断検索用のキーワード（OKF 推奨と兼用）

日付・時刻は `Bash` で取得:

```
date +%Y-%m-%d        # created_at / updated_at
date -u +%FT%TZ       # timestamp
```

### Step 8: ファイル出力

`<root>/<objective>[/<initiative>[/<epic>]]/design-docs/<id>.md` に書き出す。

- ディレクトリが存在しなければ `Bash` の `mkdir -p` で作成する（事前にユーザー承認）
- 雛形（`dd-template.md`）を `Read` し、プレースホルダを埋めて `Write` する
- HTML コメント（`<!-- -->`）は出力に含めない（雛形の編集ガイドコメント）
- mermaid 図のソースをコードブロックとして残す（GitHub UI で自動レンダリングされる）
- 内部リンク（親 README・関連 Story・関連 ADR）は **バンドル絶対パス（`/` 始まり）** で書く（`references/okf-conformance.md` § 4）

#### 8-1. log.md への追記

設定ファイルの `okf.emit_log` が `true`（または未設定）の場合、出力先の **親階層ディレクトリ** の `log.md` に 1 行追記する（`references/okf-conformance.md` § 3）。

- level=epic なら `<root>/<objective>/<initiative>/<epic>/log.md`、cross-objective なら `<root>/log.md`
- **新規作成**: `Creation: Design Doc <id>（<title>）を作成`
- **既存改訂**: `Update: Design Doc <id> を改訂（変更概要を簡潔に）`

`log.md` が存在しない場合は `# Log\n\n` ヘッダーから新規作成する。エントリは ISO 8601 日付（`YYYY-MM-DD`）でグルーピングし新しい順に並べる。

### Step 9: レビュー・修正 / 既存 DD の改訂

作成後にユーザーのフィードバックを受け、図の追加、代替案の補強、横断的関心事の追記などを行う。

**Design Doc は生きたドキュメントなので、既存 DD の改訂も本スキルで扱う**（新規ファイルを作らない）。改訂時の手順:

1. 対象 DD を `Read` で取得
2. 本文の該当セクションのみを `Edit` で差し替え（**全体上書きはしない**）
3. `updated_at` と `timestamp` を実行日（時）に上書き
4. 設計の意図・前後関係を理解したい場合は git log で履歴を辿る

新規作成も改訂も、ファイル名 = `<kebab-title>.md` は変えない。設計対象自体が別物に置き換わった場合のみ別 kebab-title の新規 DD を起こす（旧 DD は `status: deprecated` に変更）。

### Step 10: 次のステップ案内

完成した Design Doc のパスを表示し、状況に応じて次のスキル候補を提示する:

- 設計内の点の決定を ADR として分離したい: `/write-adr`
- 関連 Story を起票したい: `/compose-stories <epic-readme-path>`（Story 本文に「本 Story は DD `<id>` に基づく」と明記する旨を案内）
- 親 Epic / Initiative の更新が必要: `/compose-epic` / `/compose-initiative`
- リスクを Story に展開: `/identify-risks`
- 既存 Design Doc を一覧したい: `Glob` で `<root>/**/design-docs/*.md` を列挙して提示（`cross-objective` の `<root>/design-docs/` も同パターンに含まれる）
- `cross-objective` の場合は、影響を受ける各 Objective README の「関連 Design Doc」セクションに本 DD のバンドル絶対パスを追記することを推奨（横断 DD は所在が見えづらいため、各 Objective から逆引きできる導線を残す）

---

## 記述ルール

- **全て日本語** で記述する。技術用語・コード識別子・ライブラリ名は原語のまま
- プロジェクトに用語集（`docs/glossary.md`）があれば表記ルールに従う
- コード名・クラス名はバッククォート付き英語（例: `AuthClient.verify()`）
- 機能・概念の説明は日本語（例: ユーザー認証、セッション管理）
- カタカナ長音「ー」を付ける（サーバー、ユーザー、エンドポイント）
- アーキテクチャ図は mermaid（`flowchart` / `sequenceDiagram` / `classDiagram` 等）で記述

---

## 必須事項

- 「ゴールと非ゴール」「検討した代替案」「横断的な関心事」セクションを空欄にしない（Design Doc の信頼性の核）
- 検討した代替案は最低 2 つ、「現状維持」を必ず含める
- コードベースを `Grep` / `Glob` で調査し、影響範囲を実データで示す（`file:line` 根拠は `# Citations` に集約してもよい）
- ファイル名（拡張子抜き）と frontmatter の `id` を一致させる（どちらも `<kebab-title>`）
- OKF 必須の `type: design-doc` と OKF 推奨フィールド（`description` / `tags` / `resource` / `timestamp`）を必ず埋める
- 親階層の README が存在する場合は、その KPI / 価値仮説と接続して「背景とスコープ」を書く
- 関連 ADR がある場合は `related_adrs` に列挙し、本文中でも参照する
- `cross-objective` の場合は、影響を受ける Objective を 2 件以上「背景とスコープ」に明示し、各 Objective の KPI / スコープに対する関連を 1〜2 行で記述する
- 内部リンクはバンドル絶対パス（`/` 始まり）で書く

## 禁止事項

- コードベースを調査せずに影響範囲を記述することは禁止 → 必ず `Grep` / `Glob` で実データを取得してから記述する
- タイトルに `DD-XXXX:` 等の ID プレフィックスを付けることは禁止（ID は frontmatter の `id` とファイル名で管理する）
- 配置先を曖昧にした Design Doc は禁止 → `cross-objective` / `objective` / `initiative` / `epic` のいずれかに **明示的に分類** する。単一 Objective に紐づけられるなら最も近い親階層に置き、複数 Objective を跨ぐ場合は `cross-objective` を選ぶ（「とりあえずどこかに置く」は不可）
- `cross-objective` を安易に選ぶことは禁止 → 影響範囲が単一 Objective で説明できるなら、無理に横断扱いせず親階層配下に置く（横断 DD の濫用は所在の曖昧化を招く）
- 詳細な実装計画（フェーズごとの工数・担当・期日）を Design Doc に書くことは禁止 → Story に分離する。本 DD は方針までに留める
- 同じ設計対象に対して複数バージョンの DD ファイルを並べて残すことは禁止（`*-v2.md` / `*-old.md` のような suffix 命名も不可）→ 改訂は同ファイル上書きで行い、過去版は git log で追う
