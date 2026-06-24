#!/usr/bin/env bash
# guard-project-field-mutation.sh
#
# Claude Code PreToolUse hook bundled with the `leadcraft` plugin.
#
# 目的:
#   GitHub Projects (v2) の Single Select フィールド（Epic / Objective /
#   Initiative などのタグ）を CLI / GraphQL から書き換える操作を **完全に
#   ブロック** する。
#
# 適用範囲（重要）:
#   - 本ガードレールは **github プロバイダ運用（opt-in / Phase 2）** 向けである。
#     `references/backends/github.md` の「ガードレール」節と整合する:
#     「Projects (v2) の Single Select フィールド option を CLI / GraphQL から
#      書き換える操作はハードブロックする。option 追加は Web UI からの手動操作
#      のみ許可する」。
#   - 理想的には provider == github のときのみ作動させたい。本フックは
#     `.claude/leadcraft.md` の `tracker.provider` を best-effort で読み、
#     **明示的に `local` と設定されている場合のみ素通し** する（後述）。
#     設定が読めない / 未設定 / github の場合は、安全側に倒して判定を続行する
#     （`gh project ...` / `updateProjectV2Field` 等は github 専用コマンドなので、
#      local 運用なら本来そもそも発行されない。誤って発行されたら止める方が安全）。
#   - 既定の local プロバイダでは Story = ローカル md（OKF concept）であり、
#     Projects フィールドを触る CLI / GraphQL を一切発行しないため、本フックは
#     実質的に発火しない。
#
# なぜブロックするか:
#   `gh api graphql` 経由の `updateProjectV2Field`（singleSelectOptions の
#   再セット）や `gh project field-create` / `field-delete` 系は、見た目は
#   オプション追加でも GitHub 側で **内部 option ID を再発番** することが
#   ある。これにより:
#     - 既存 Issue のフィールド値の紐付けが解除される（実質リセット）
#     - 共有 Project を参照している他ツール / ダッシュボードが全て壊れる
#     - リカバリが手作業になり、影響範囲が読めない
#   共有 Project に対する破壊的変更を CLI から黙って行う運用は事故源で
#   しかないため、本プラグインのスキルから（または LLM が自走して）これら
#   を発行することをハード制約として禁止する。
#
# 唯一の正しい運用:
#   - 新しい Epic / Objective / Initiative のオプションは **GitHub の Web UI
#     から手動で追加** する（既存 option ID を破壊しない）
#   - 自動化したい場合でも、本フックを無効化するのではなく、Project の
#     設計（Text 型に変える、ラベルで管理する、等）を見直すこと
#
# 入出力プロトコル:
#   stdin: Claude Code が渡す PreToolUse の JSON ペイロード
#     {
#       "tool_name": "Bash",
#       "tool_input": { "command": "...", "description": "..." }
#     }
#   stdout: ブロック時のみ JSON を出力（permissionDecision: deny）
#   それ以外は何も出さずに exit 0（ツール実行を許可）
#
# 安全性:
#   - jq が無い環境では noop（ガードしないが、ツール実行は妨げない）
#   - パターンマッチは過剰検出より見逃しを避ける方を優先。曖昧なら通す。
#     ただし「Project の field を変更しうる典型コマンド」は確実に止める。

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

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

# ---- provider 判定（best-effort） -------------------------------------------
# `references/backends/github.md` の通り、本ガードレールは provider == github の
# ときに作動させるのが理想。`.claude/leadcraft.md` を best-effort で読み、
# 明示的に local と設定されている場合のみ素通しする。
#   - 読み取りは grep ベースの軽量実装（YAML パーサに依存しない）
#   - 設定が見つからない / 未設定 / github の場合は判定を続行する（安全側）
# TODO: leadcraft.md の探索パスがプロジェクト構成で異なる場合は候補を追加する。
CONFIG_FILE=""
for cand in \
  "${CLAUDE_PROJECT_DIR:-$PWD}/.claude/leadcraft.md" \
  "$PWD/.claude/leadcraft.md"; do
  if [[ -f "$cand" ]]; then
    CONFIG_FILE="$cand"
    break
  fi
done

if [[ -n "$CONFIG_FILE" ]]; then
  # `tracker.provider:` 形式または `provider:` 行から値を拾う（簡易）
  PROVIDER=$(grep -iE '(tracker\.provider|^[[:space:]]*provider)[[:space:]]*:' "$CONFIG_FILE" 2>/dev/null \
    | head -n1 | sed -E 's/.*:[[:space:]]*//' | tr -d '"'"'"' \r' | tr '[:upper:]' '[:lower:]' || true)
  if [[ "$PROVIDER" == "local" ]]; then
    # local 運用では Projects フィールドを触る CLI は本来発行されない。素通しする。
    exit 0
  fi
fi

# ---- 禁止パターン -----------------------------------------------------------
# 1. GraphQL mutation 経由でフィールド定義そのものを書き換える系
#    （`gh api graphql` に updateProjectV2Field / createProjectV2Field /
#     deleteProjectV2Field / updateProjectV2FieldConfiguration 等の mutation
#     名が含まれる場合）
# 2. `gh project field-create` / `field-delete`
#
# `gh project field-list` や `gh project item-edit ... --single-select-option-id`
# のような **既存オプション ID を参照するだけの操作は許可** する（破壊的では
# ないため）。検知は mutation 名 / サブコマンド名で行い、`field-list` を
# 巻き込まないようにする。

REASON=""
case "$CMD" in
  *"updateProjectV2Field"*)
    REASON="GraphQL mutation \`updateProjectV2Field\` の実行を検知した。"
    ;;
  *"createProjectV2Field"*)
    REASON="GraphQL mutation \`createProjectV2Field\` の実行を検知した。"
    ;;
  *"deleteProjectV2Field"*)
    REASON="GraphQL mutation \`deleteProjectV2Field\` の実行を検知した。"
    ;;
  *"updateProjectV2FieldConfiguration"*)
    REASON="GraphQL mutation \`updateProjectV2FieldConfiguration\` の実行を検知した。"
    ;;
  *"gh project field-create"*)
    REASON="\`gh project field-create\` の実行を検知した。"
    ;;
  *"gh project field-delete"*)
    REASON="\`gh project field-delete\` の実行を検知した。"
    ;;
  *)
    exit 0
    ;;
esac

# ---- deny を返す ------------------------------------------------------------
# Claude Code の PreToolUse hook プロトコル:
#   { "hookSpecificOutput": {
#       "hookEventName": "PreToolUse",
#       "permissionDecision": "deny",
#       "permissionDecisionReason": "..."
#   } }
# permissionDecisionReason は LLM にも返されるので、なぜ拒否され、どう
# 回避すべきかを具体的に記述する。

MESSAGE="leadcraft プラグインのガードレールにより、本コマンドは **ブロック** された。

検知: ${REASON}

理由:
- GitHub Projects (v2) の Single Select フィールド（Epic / Objective / Initiative などのタグ）を CLI / GraphQL から書き換えると、GitHub 側で内部 option ID が再発番されることがある。
- これにより、既存 Issue のフィールド値の紐付けが解除され（実質リセット）、共有 Project を参照する他ツールやダッシュボードも壊れる。
- 共有インフラへの不可逆な変更を自動実行することは本プラグインの設計上 **絶対に許可しない**。

唯一の正しい運用:
1. **GitHub の Web UI から手動でオプションを追加する**（既存 option ID は破壊されない）。
   - Project 画面 → 該当フィールドの設定 → \"+ Add option\" で新しい Epic / Objective / Initiative を追加する
2. 追加後、当該フィールドを使う Issue に対しては既存の \`gh project item-edit ... --single-select-option-id <ID>\` で値をセットすればよい（このコマンドは破壊的ではないためガードレールの対象外）。
3. どうしても自動化したい場合は Project のフィールド設計を見直す（Text 型に変える、ラベルで管理する、等）。本フックの無効化で回避してはならない。

次のアクション:
- ユーザーに上記の Web UI 手順を案内し、手動追加が完了したら再開する。
- compose-stories 実行中であれば、当該フィールドの設定を **スキップ** して残りのフィールドだけ埋めて Issue 登録を完了させる選択肢も提示する（後から追いセット可能）。"

jq -n --arg msg "$MESSAGE" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $msg
  }
}'

exit 0
