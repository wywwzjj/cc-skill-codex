#!/usr/bin/env bash
# claude-ask.sh — wrapper for `claude -p` used by the claude skill.
#
# Prints ONLY: the result text, a SESSION_ID=<id> line, and a DETAILS=<dir>
# line. The full JSON envelope (usage, cost, permission_denials, model info)
# and stderr are persisted in the DETAILS dir for on-demand inspection
# instead of flooding the caller's context.
#
# Usage (flags are passed through to `claude -p` verbatim):
#   bash claude-ask.sh --effort high <<'CLAUDE_PROMPT_END'
#   multi-line prompt
#   CLAUDE_PROMPT_END
#   bash claude-ask.sh --resume <SESSION_ID> <<'CLAUDE_PROMPT_END' ...
#
# Exit codes: 0 success; 3 claude reported is_error=true (error text goes to
# stderr, no SESSION_ID is emitted so a failed session is never resumed by
# mistake); 4 no usable JSON envelope (claude died early — bad flag, bad
# session id, auth — or the envelope is missing result/session_id). On
# failure the last 40 lines of stderr are shown (full log stays in DETAILS).
#
# Requires: Claude Code CLI (verified v2.1.206), python3.
set -o pipefail
DIR=$(mktemp -d "${TMPDIR:-/tmp}/claude-ask.XXXXXX") || exit 1
claude -p --output-format json "$@" 2>"$DIR/stderr.log" | tee "$DIR/envelope.json" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    sys.exit(4)
if d.get("is_error"):
    sys.stderr.write((d.get("result") or "claude returned is_error=true") + "\n")
    sys.exit(3)
res, sid = d.get("result"), d.get("session_id")
if not isinstance(res, str) or not isinstance(sid, str) or not sid:
    sys.stderr.write("malformed envelope: missing result or session_id (see envelope.json in DETAILS)\n")
    sys.exit(4)
print(res)
print()
print("SESSION_ID=" + sid)
'
st=$?
echo "DETAILS=$DIR"
if [ "$st" -ne 0 ]; then
  echo "--- stderr tail (full log: $DIR/stderr.log) ---" >&2
  tail -n 40 "$DIR/stderr.log" >&2
fi
exit "$st"
