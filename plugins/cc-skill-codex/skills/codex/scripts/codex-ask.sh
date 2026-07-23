#!/usr/bin/env bash
# codex-ask.sh — wrapper for `codex exec` used by the codex skill.
#
# Prints ONLY: the final agent message, a SESSION_ID=<id> line, and a
# DETAILS=<dir> line. Everything else (full JSONL event stream with reasoning
# summaries / command executions / token usage, plus stderr) is persisted in
# the DETAILS dir for on-demand inspection instead of flooding the caller's
# context.
#
# Usage (flags are passed through to `codex exec` verbatim):
#   bash codex-ask.sh -c model_reasoning_effort=high <<'CODEX_PROMPT_END'
#   multi-line prompt
#   CODEX_PROMPT_END
#   bash codex-ask.sh resume <SESSION_ID> <<'CODEX_PROMPT_END' ...
#
# Exit codes: 0 success; 3 no final agent message in the event stream — this
# covers most codex failures too (bad flag, auth, interrupt all end the stream
# early; the real cause is in the stderr tail). On failure the last 40 lines
# of stderr are shown (full log stays in DETAILS).
#
# Requires: codex CLI with `codex exec --json` (verified v0.145.0), python3.
set -o pipefail
DIR=$(mktemp -d "${TMPDIR:-/tmp}/codex-ask.XXXXXX") || exit 1
codex exec --json "$@" 2>"$DIR/stderr.log" | tee "$DIR/events.jsonl" | python3 -c '
import json, sys
sid = last = None
for line in sys.stdin:  # streaming: never accumulates the event stream
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if e.get("type") == "thread.started":
        sid = e.get("thread_id")
    elif e.get("type") == "item.completed":
        item = e.get("item", {})
        if item.get("type") == "agent_message":
            last = item.get("text")
if last is None:
    sys.exit(3)
print(last)
if sid:
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
