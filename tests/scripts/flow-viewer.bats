#!/usr/bin/env bats
# Tests for bin/flow-viewer.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../bin/flow-viewer.sh"
  [ -f "$SCRIPT" ] || skip "script not found: $SCRIPT"
  TMPD="$(mktemp -d)"
  FIXTURE="$TMPD/agents.jsonl"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "exits 2 when no input given" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}

@test "graceful message when no post-events with duration" {
  echo "" > "$FIXTURE"
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no agent post-events"* ]]
}

@test "renders timeline for single agent" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Task","agent":"strategist","desc":"x","duration":120}
EOF
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"strategist"* ]]
  [[ "$output" == *"2m 00s"* ]]
  [[ "$output" == *"Session"* ]]
}

@test "renders timeline for multiple agents in chronological order" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Task","agent":"strategist","desc":"a","duration":60}
{"ts":"2026-05-04T10:02:00Z","epoch":1746360120,"event":"post","tool":"Task","agent":"architect","desc":"b","duration":120}
{"ts":"2026-05-04T10:05:00Z","epoch":1746360300,"event":"post","tool":"Task","agent":"test-engineer","desc":"c","duration":180}
EOF
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"strategist"* ]]
  [[ "$output" == *"architect"* ]]
  [[ "$output" == *"test-engineer"* ]]
  [[ "$output" == *"3 invocations"* ]]
  [[ "$output" == *"3 unique agents"* ]]
}

@test "totals section ranks agents by total duration descending" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Task","agent":"short-runner","desc":"x","duration":10}
{"ts":"2026-05-04T10:01:00Z","epoch":1746360060,"event":"post","tool":"Task","agent":"long-runner","desc":"y","duration":300}
EOF
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  # long-runner should appear before short-runner in the Totals section
  totals_line=$(echo "$output" | grep -n "Totals" | cut -d: -f1)
  [ -n "$totals_line" ]
  long_pos=$(echo "$output" | grep -n "long-runner" | tail -1 | cut -d: -f1)
  short_pos=$(echo "$output" | grep -n "short-runner" | tail -1 | cut -d: -f1)
  [ "$long_pos" -lt "$short_pos" ]
}

@test "filters out Bash and unknown agents" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Bash","agent":"Bash","desc":"x","duration":5}
{"ts":"2026-05-04T10:00:30Z","epoch":1746360030,"event":"post","tool":"Task","agent":"unknown","desc":"y","duration":3}
{"ts":"2026-05-04T10:01:00Z","epoch":1746360060,"event":"post","tool":"Task","agent":"strategist","desc":"z","duration":60}
EOF
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"strategist"* ]]
  [[ "$output" != *"Bash "* ]]   # Bash agent name should not appear in render
  [[ "$output" == *"1 invocations"* ]]
}

@test "skips events without epoch or duration" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","event":"post","tool":"Task","agent":"no-epoch","desc":"x","duration":60}
{"ts":"2026-05-04T10:01:00Z","epoch":1746360060,"event":"post","tool":"Task","agent":"no-duration","desc":"y"}
{"ts":"2026-05-04T10:02:00Z","epoch":1746360120,"event":"post","tool":"Task","agent":"valid","desc":"z","duration":30}
EOF
  run bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"valid"* ]]
  [[ "$output" == *"1 invocations"* ]]
}

@test "honors FLOW_VIEWER_WIDTH env var" {
  cat > "$FIXTURE" <<'EOF'
{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Task","agent":"x","desc":"x","duration":60}
EOF
  run env FLOW_VIEWER_WIDTH=20 bash "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"width=20"* ]]
}

@test "reads from stdin when arg is '-'" {
  data='{"ts":"2026-05-04T10:00:00Z","epoch":1746360000,"event":"post","tool":"Task","agent":"strategist","desc":"x","duration":60}'
  run bash -c "echo '$data' | bash '$SCRIPT' -"
  [ "$status" -eq 0 ]
  [[ "$output" == *"strategist"* ]]
}

@test "exits 1 on missing input file" {
  run bash "$SCRIPT" "$TMPD/does-not-exist.jsonl"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
