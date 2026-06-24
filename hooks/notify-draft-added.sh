#!/usr/bin/env bash
# notify-draft-added.sh
#
# Claude Code PostToolUse hook bundled with the `leadcraft` plugin.
#
# 目的:
#   github プロバイダ運用（opt-in / Phase 2）で、compose-stories や hotfix 系
#   スキルが `gh issue create --label "...,draft,..."` または
#   `gh issue edit <N> --add-label "draft"` を実行した直後に、その変化を検知して
#   Claude に次のステップを促すシステムリマインダーを注入する。
#
# 適用範囲（重要）:
#   - 本フックは **github プロバイダ向け** である。`gh issue create` / `gh issue edit`
#     を検知して発火する。
#   - 既定の **local プロバイダでは Story = ローカル md（OKF concept）であり、
#     `gh issue create` を一切実行しない**。そのため local 運用では本フックは
#     発火しない（draft 付与はローカル md の frontmatter で完結するため、CLI の
#     ラベル操作が走らない）。これは意図した挙動である。
#   - github アダプタ（`references/backends/github.md`）および estimate-points /
#     review-stories は Phase 2 で提供予定。本フックはそれらが揃った Phase 2 で
#     有効に機能する。
#
# 2 つの起動経路を出し分ける:
#   - 新規起票（gh issue create）: → estimate-points を促す（compose-stories 直後）
#   - 既存編集（gh issue edit --add-label draft）: → review-stories を促す（再 draft 化）
#
# 入出力プロトコル:
#   stdin: Claude Code が渡す PostToolUse の JSON ペイロード
#     {
#       "tool_name": "Bash",
#       "tool_input": { "command": "...", "description": "..." },
#       "tool_response": { ... }
#     }
#   stdout: 何も出さなければ「特に通知なし」。何か出力すると Claude の
#           次の応答に context として注入される。
#
# 安全性:
#   - 失敗してもツール実行自体は影響を受けない。jq が無くても警告のみで継続。
#   - draft 付与を検知できなくても黙って何もしない（false negative より
#     false trigger を嫌う）。

set -euo pipefail

# jq が無ければ noop（環境差で落とさない）
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# stdin がパイプで来ない環境（手動実行など）でも壊れないようにする
INPUT="$(cat - 2>/dev/null || true)"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true)
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
if [[ -z "$CMD" ]]; then
  exit 0
fi

# Bash コマンドが draft ラベル付与系かを判定する（github プロバイダの CLI 経路）。
#   local プロバイダでは `gh issue create` が走らないため、いずれのパターンにも
#   合致せず exit 0 で終わる（=発火しない）。
#   CLI 経路:
#     - gh issue create ... --label "...draft..."        → CREATE
#     - gh issue edit <N> --add-label "...draft..."      → EDIT
#     - gh issue edit <N> --label "...draft..."          → EDIT
#   GraphQL 経路（gh api graphql で mutation を直接叩くケース）:
#     - gh api graphql ... createIssue ... draft         → CREATE
#     - gh api graphql ... addLabelsToLabelable ... draft → EDIT
#   REST API 経路（gh api /repos/.../issues 経由）:
#     - gh api ... /issues ... -f title=... draft        → CREATE
#     - gh api ... /issues/<N>/labels ... draft          → EDIT
#
# パターンは過剰に厳密にしない（将来別の書き方になっても追従しやすくする）。
# ただし draft という単語が登場するラベル操作系のときのみ反応する。

MODE=""
case "$CMD" in
  *"gh issue create"*"--label"*"draft"*) MODE="CREATE" ;;
  *"gh issue edit"*"--add-label"*"draft"*) MODE="EDIT" ;;
  *"gh issue edit"*"--label"*"draft"*) MODE="EDIT" ;;
  *"gh api"*"createIssue"*"draft"*) MODE="CREATE" ;;
  *"gh api"*"addLabelsToLabelable"*"draft"*) MODE="EDIT" ;;
  *"gh api"*"/labels"*"draft"*) MODE="EDIT" ;;
  *"gh api"*"/issues"*"-f"*"title"*"draft"*) MODE="CREATE" ;;
  *"gh api"*"/issues"*"draft"*"-f"*"title"*) MODE="CREATE" ;;
  *) exit 0 ;;
esac

# Issue 番号の抽出
#   - CREATE: ツール応答（標準出力）の最後の行に Issue URL があるのが gh の慣行
#       https://github.com/<owner>/<repo>/issues/<N>
#   - EDIT: コマンド内の `gh issue edit <N> ...` から拾える
ISSUE_NUMBER=""

# まず tool_response から URL を拾う（create のケース・CLI 経路）
RESPONSE=$(printf '%s' "$INPUT" | jq -r '.tool_response.output // .tool_response.stdout // ""' 2>/dev/null || true)
if [[ -n "$RESPONSE" ]]; then
  CANDIDATE=$(printf '%s' "$RESPONSE" | grep -oE 'issues/[0-9]+' | tail -n1 | sed 's|issues/||' || true)
  if [[ -n "$CANDIDATE" ]]; then
    ISSUE_NUMBER="$CANDIDATE"
  fi
fi

# それでも取れなければ JSON レスポンスの "number": N を拾う（GraphQL/REST 経路）
#   - GraphQL createIssue: { "data": { "createIssue": { "issue": { "number": N } } } }
#   - REST POST /issues:   { "number": N, ... }
if [[ -z "$ISSUE_NUMBER" && -n "$RESPONSE" ]]; then
  CANDIDATE=$(printf '%s' "$RESPONSE" | grep -oE '"number"[[:space:]]*:[[:space:]]*[0-9]+' | head -n1 | grep -oE '[0-9]+' || true)
  if [[ -n "$CANDIDATE" ]]; then
    ISSUE_NUMBER="$CANDIDATE"
  fi
fi

# 取れなければコマンド文字列から拾う（edit のケース）
#   - `gh issue edit <N>` 形式
#   - REST API パス `/issues/<N>` 形式（gh api /repos/owner/repo/issues/123/labels 等）
if [[ -z "$ISSUE_NUMBER" ]]; then
  CANDIDATE=$(printf '%s' "$CMD" | grep -oE 'gh issue edit[[:space:]]+[0-9]+' | grep -oE '[0-9]+' | head -n1 || true)
  if [[ -n "$CANDIDATE" ]]; then
    ISSUE_NUMBER="$CANDIDATE"
  fi
fi
if [[ -z "$ISSUE_NUMBER" ]]; then
  CANDIDATE=$(printf '%s' "$CMD" | grep -oE '/issues/[0-9]+' | tail -n1 | sed 's|/issues/||' || true)
  if [[ -n "$CANDIDATE" ]]; then
    ISSUE_NUMBER="$CANDIDATE"
  fi
fi

# 番号が無い場合は弱めの通知（Issue 番号を Claude に推測してもらう）
if [[ -z "$ISSUE_NUMBER" ]]; then
  if [[ "$MODE" == "CREATE" ]]; then
    cat <<'EOF'
<system-reminder source="hooks/notify-draft-added" mode="create-unknown-number">
Story Issue が新規作成された（`gh issue create --label "...,draft,..."` を検知）。Issue 番号は本フックでは特定できなかった。

本プロジェクトの設計では、起票直後の Story は **続けて `estimate-points` を実行する** ことになっている（Points=0 のままだと `review-stories` でブロッカー判定になるため）。

次に行うべき行動:
- 直前のコマンド出力から対象 Issue 番号を特定し、`estimate-points` スキルを起動する
- 複数件起票された場合は番号を全て拾って `estimate-points #N #N+1 ...` で一括実行する
- baseline 未設定なら `setup-baseline` を先に案内
</system-reminder>
EOF
  else
    cat <<'EOF'
<system-reminder source="hooks/notify-draft-added" mode="edit-unknown-number">
既存 Issue に `draft` ラベルが再付与された（Issue 番号は本フックでは特定できなかった）。

本プロジェクトの設計では、`draft` 付き Story は **計画に組み込む前に必ず `review-stories` で品質ゲートを通す** ことになっている。

次に行うべき行動:
- 直前のコマンド出力から対象 Issue 番号を特定し、`review-stories` スキルを起動する
</system-reminder>
EOF
  fi
  exit 0
fi

# CREATE モード: estimate-points を促す
if [[ "$MODE" == "CREATE" ]]; then
  cat <<EOF
<system-reminder source="hooks/notify-draft-added" mode="create">
Story Issue #${ISSUE_NUMBER} が新規作成された（\`compose-stories\` 直後の文脈と推測される）。

本プロジェクトの設計では、起票直後の Story は **続けて \`estimate-points\` を実行** することになっている。理由:
- 起票直後は内容と規模感の記憶が新鮮で、PERT 三点見積もりの精度が高くなる
- Points=0 のまま放置されると \`review-stories\` でブロッカー判定になり、後で見直す手戻りが発生する
- 連続起票時の「起票だけして見積もりを忘れる」運用ミスを防ぐ

次のアクション:
1. **\`estimate-points\` を Issue #${ISSUE_NUMBER} に対して実行する**（既定。compose-stories の自然な続き）
2. もし複数 Issue を連続起票した場合は、全件の番号を集めて \`estimate-points #N #N+1 ...\` で一括実行する
3. \`setup-baseline\` 未設定なら先に案内する

その後の遷移（\`identify-risks\` は任意 / \`review-stories\` でドラフト卒業）は estimate-points 完了後に検討する。
</system-reminder>
EOF
  exit 0
fi

# EDIT モード: review-stories を促す（既存 Issue の再 draft 化）
cat <<EOF
<system-reminder source="hooks/notify-draft-added" mode="edit">
既存 Story Issue #${ISSUE_NUMBER} に \`draft\` ラベルが（再）付与された。

本プロジェクトの設計では、\`draft\` 付き Story は **計画に組み込む前に必ず \`review-stories\` で品質ゲートを通す** ことになっている。

次に行うべき行動の選択肢:
1. **即時レビュー**: \`review-stories\` を Issue #${ISSUE_NUMBER} に対して起動する
2. **段取りを踏む**: 先に \`estimate-points\` や \`identify-risks\` で内容を整えてから \`review-stories\`
3. **保留**: 今は何もせず、後ほどユーザーが明示的に \`/review-stories\` を起動する

ユーザーの意図がはっきりしない場合は AskUserQuestion で確認する。
</system-reminder>
EOF

exit 0
