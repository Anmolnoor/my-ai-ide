#!/usr/bin/env bash
# Runs agent-stats against a fake HOME and stub gh/ssh. Never touches the real HOME.
set -euo pipefail
export TZ=UTC   # --days buckets by local day
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
at() { jq -nr --argjson s "$1" '$s | todate'; }
# T1 sits 60s into a 5-minute slot about 2 hours ago, so slot counts are stable.
T1=$(jq -n 'now - 7200 | . / 300 | floor * 300 + 60'); OLD=$(jq -n 'now - 259200 | floor')

P="$T/home/.claude/projects/p1"; mkdir -p "$P/s1/subagents" "$T/home/.codex/sessions/2026" "$T/bin"
# Two lines share message.id (one API call split across blocks): count it once.
# The 3-day-old line counts toward 7d only.
cat > "$P/s1.jsonl" <<EOF
{"type":"assistant","timestamp":"$(at "$T1")","message":{"id":"m1","usage":{"input_tokens":1,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"assistant","timestamp":"$(at "$T1")","message":{"id":"m1","usage":{"input_tokens":1,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"assistant","timestamp":"$(at "$OLD")","message":{"id":"m2","usage":{"input_tokens":2,"output_tokens":20,"cache_read_input_tokens":200,"cache_creation_input_tokens":0}}}
EOF
echo '{"type":"assistant","timestamp":"'"$(at $((T1 + 30)))"'","message":{"id":"m3","usage":{"input_tokens":0,"output_tokens":7,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}' > "$P/s1/subagents/a1.jsonl"
echo '{}' > "$P/old.jsonl"; touch -t "$(jq -nr 'now - 864000 | strftime("%Y%m%d%H%M")')" "$P/old.jsonl"
# Codex logs a running total per turn, sometimes twice: count each total once.
cat > "$T/home/.codex/sessions/2026/c1.jsonl" <<EOF
{"timestamp":"$(at $((T1 + 60)))","type":"event_msg","payload":{"type":"token_count","info":null}}
{"timestamp":"$(at $((T1 + 60)))","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":100},"last_token_usage":{"total_tokens":100}}}}
{"timestamp":"$(at $((T1 + 61)))","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":100},"last_token_usage":{"total_tokens":100}}}}
{"timestamp":"$(at $((T1 + 400)))","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":150},"last_token_usage":{"total_tokens":50}}}}
EOF
# A Codex turn logged twice across midnight counts once, on the day it was first logged.
M=$(jq -n 'now - 86400 | . / 86400 | floor * 86400'); DM=$(jq -nr "$M - 60 | strftime(\"%Y-%m-%d\")")
cat > "$T/home/.codex/sessions/2026/c2.jsonl" <<EOF
{"timestamp":"$(at $((M - 60)))","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":40},"last_token_usage":{"total_tokens":40}}}}
{"timestamp":"$(at $((M + 60)))","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":40},"last_token_usage":{"total_tokens":40}}}}
EOF
touch -t "$(jq -nr "$M + 60 | strftime(\"%Y%m%d%H%M\")")" "$T/home/.codex/sessions/2026/c2.jsonl"

cat > "$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *createdAt*) echo "{\"k\":\"opened\",\"u\":\"pr1\",\"t\":\"$PR_AT\"}";;
  *closedAt*) echo "{\"k\":\"merged\",\"u\":\"pr1\",\"t\":\"$PR_AT\"}";;
  *--created*) echo 4;; *--merged-at*) echo 3;; *--state=open*) echo 2;; *) exit 9;; esac
EOF
# ssh -o BatchMode=yes HOST cmd...: run cmd here, against the same fake HOME.
printf '#!/usr/bin/env bash\nshift 3; exec "$@"\n' > "$T/bin/ssh"
chmod +x "$T/bin/gh" "$T/bin/ssh"
export PR_AT; PR_AT=$(at "$T1")
run() { HOME="$T/home" PATH="$T/bin:$PATH" "$(dirname "$0")/agent-stats" "$@"; }

out="$(run --json)"
check() { jq -e "$1" <<<"$out" >/dev/null || { echo "FAIL: $1"; echo "$out"; exit 1; }; }
check '.open_prs == 2'
# Slots: m1, m3 and the first Codex turn share one; the second Codex turn is the next.
check '."24h" | del(.crashes, .oom_kills, .system_errors) == {prs_opened:4, prs_merged:3, claude_sessions:1, claude_subagents:1, codex_sessions:1, output_tokens:17, input_tokens:6, cache_read_tokens:100, codex_tokens:150, total_tokens:273, active_hours:0.2, agent_hours:0.3}'
check '."7d"  | del(.crashes, .oom_kills, .system_errors) == {prs_opened:4, prs_merged:3, claude_sessions:1, claude_subagents:1, codex_sessions:2, output_tokens:37, input_tokens:8, cache_read_tokens:300, codex_tokens:190, total_tokens:535, active_hours:0.3, agent_hours:0.5}'
check '[."24h", ."7d"] | all(.crashes >= 0 and .oom_kills >= 0 and (.system_errors == null or .system_errors >= 0))'
check '.machine | (.os | length > 0) and .cpus > 0 and .mem_total_gb > 0 and .mem_used_gb > 0 and .disk_free_gb > 0 and .uptime_hours > 0 and .load_1m >= 0'
[ "$(run --with box --json | wc -l)" -eq 2 ] || { echo "FAIL: --with adds a line"; exit 1; }
table=$(run --with box); grep -q 'Total tokens' <<<"$table" || { echo "FAIL: table"; exit 1; }
# --days: one row per local day, empty days included; a PR found twice counts once.
days="$(run --days 4)"; D1=$(jq -nr "$T1 | strftime(\"%Y-%m-%d\")"); D3=$(jq -nr "$OLD | strftime(\"%Y-%m-%d\")")
dcheck() { jq -se --arg d1 "$D1" --arg d3 "$D3" --arg dm "$DM" "$1" <<<"$days" >/dev/null || { echo "FAIL: $1"; echo "$days"; exit 1; }; }
dcheck 'length == 4 and (map(.date) | unique | length) == 4 and all(.host | length > 0)'
dcheck 'map(select(.date == $d1))[0] | del(.date, .host, .crashes, .oom_kills, .system_errors) == {prs_opened:1, prs_merged:1, claude_sessions:1, claude_subagents:1, codex_sessions:1, output_tokens:17, input_tokens:6, cache_read_tokens:100, codex_tokens:150, total_tokens:273, active_hours:0.2, agent_hours:0.3}'
dcheck 'map(select(.date == $d3))[0] | {claude_sessions, claude_subagents, codex_sessions, output_tokens, total_tokens, active_hours} == {claude_sessions:1, claude_subagents:0, codex_sessions:0, output_tokens:20, total_tokens:222, active_hours:0.1}'
dcheck 'map(.codex_tokens) | add == 190'
dcheck 'map(select(.date == $dm))[0].codex_tokens == 40'
[ "$(run --days 12 | jq -s "map(.prs_opened) | add")" -eq 1 ] || { echo "FAIL: overlapping PR searches double-count"; exit 1; }
for bad in 0 -1 x ""; do if run --days "$bad" >/dev/null 2>&1; then echo "FAIL: --days '$bad' accepted"; exit 1; fi; done
[ "$(run --days 4 --with box | wc -l)" -eq 8 ] || { echo "FAIL: --days --with"; exit 1; }
# An unreadable transcript must fail the run, not print partial totals.
chmod 000 "$P/s1.jsonl"
if run --json >/dev/null 2>&1; then echo "FAIL: a read error must fail the run"; exit 1; fi
echo PASS
