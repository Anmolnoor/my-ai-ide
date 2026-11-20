#!/usr/bin/env bash
# Runs agent-stats against a fake HOME and a stub gh. Never touches the real HOME.
set -euo pipefail
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
ago() { jq -nr --argjson s "$1" 'now - $s | todate'; }

P="$T/home/.claude/projects/p1"; mkdir -p "$P/s1/subagents" "$T/home/.codex/sessions/2026" "$T/bin"
# Two lines share message.id (one API call split across blocks): count it once.
# The 3-day-old line counts toward 7d only.
cat > "$P/s1.jsonl" <<EOF
{"type":"assistant","timestamp":"$(ago 3600)","message":{"id":"m1","usage":{"input_tokens":1,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"assistant","timestamp":"$(ago 3600)","message":{"id":"m1","usage":{"input_tokens":1,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"assistant","timestamp":"$(ago 259200)","message":{"id":"m2","usage":{"input_tokens":2,"output_tokens":20,"cache_read_input_tokens":200,"cache_creation_input_tokens":0}}}
EOF
echo '{"type":"assistant","timestamp":"'"$(ago 60)"'","message":{"id":"m3","usage":{"input_tokens":0,"output_tokens":7,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$P/s1/subagents/a1.jsonl"
echo '{}' > "$P/old.jsonl"; touch -t "$(jq -nr 'now - 864000 | strftime("%Y%m%d%H%M")')" "$P/old.jsonl"
echo '{}' > "$T/home/.codex/sessions/2026/c1.jsonl"

cat > "$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in *--created*) echo 4;; *--merged-at*) echo 3;; *--state=open*) echo 2;; *) exit 9;; esac
EOF
chmod +x "$T/bin/gh"

out="$(HOME="$T/home" PATH="$T/bin:$PATH" "$(dirname "$0")/agent-stats" --json)"
check() { jq -e "$1" <<<"$out" >/dev/null || { echo "FAIL: $1"; echo "$out"; exit 1; }; }
check '.open_prs == 2'
check '."24h" == {prs_opened:4, prs_merged:3, claude_sessions:1, claude_subagents:1, codex_sessions:1, output_tokens:17, input_tokens:6, cache_read_tokens:100}'
check '."7d"  == {prs_opened:4, prs_merged:3, claude_sessions:1, claude_subagents:1, codex_sessions:1, output_tokens:37, input_tokens:8, cache_read_tokens:300}'
HOME="$T/home" PATH="$T/bin:$PATH" "$(dirname "$0")/agent-stats" | grep -q 'Output tokens' || { echo "FAIL: table"; exit 1; }
echo PASS
