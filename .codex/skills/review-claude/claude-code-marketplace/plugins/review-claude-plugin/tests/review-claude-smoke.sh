#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="$(cd "${script_dir}/.." && pwd)"
submit_bin="${plugin_root}/bin/review-claude-submit"
collect_bin="${plugin_root}/bin/review-claude-collect"
worker_bin="${plugin_root}/bin/claude-review-worker"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: ${needle}"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "did not expect output to contain: ${needle}"
}

assert_mode() {
  local path="$1"
  local expected="$2"
  local actual

  actual="$(stat -f '%OLp' "$path")"
  [[ "$actual" == "$expected" ]] || fail "expected mode ${expected} for ${path}, got ${actual}"
}

tmp_root="$(mktemp -d /tmp/review-claude-test.XXXXXX)"
trap 'rm -rf "$tmp_root"' EXIT

repo_dir="${tmp_root}/repo"
summary_dir="${tmp_root}/summary"
fake_bin_dir="${tmp_root}/bin"
mkdir -p "$repo_dir" "$summary_dir" "$fake_bin_dir"

cat > "${fake_bin_dir}/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
sleep 1
printf '%s\n' '{"result":"## Findings\\n\\n- Parsed response works.","total_cost_usd":0.022908}'
EOF

cat > "${fake_bin_dir}/slow-claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
sleep 3
printf '%s\n' '{"result":"too late"}'
EOF

cat > "${fake_bin_dir}/launchctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

command_name="${1:-}"
case "$command_name" in
  submit)
    shift
    stdout_path=""
    stderr_path=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -l)
          shift 2
          ;;
        -o)
          stdout_path="$2"
          shift 2
          ;;
        -e)
          stderr_path="$2"
          shift 2
          ;;
        --)
          shift
          break
          ;;
        *)
          printf 'unsupported launchctl arg: %s\n' "$1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$stdout_path" && -n "$stderr_path" && $# -gt 0 ]] || exit 2

    nohup /bin/bash -c '
      stdout_path="$1"
      stderr_path="$2"
      shift 2
      sleep 4
      "$@" >"$stdout_path" 2>"$stderr_path"
    ' launchctl-background "$stdout_path" "$stderr_path" "$@" >/dev/null 2>&1 &
    ;;
  remove)
    exit 0
    ;;
  *)
    printf 'unsupported launchctl command: %s\n' "$command_name" >&2
    exit 2
    ;;
esac
EOF

chmod +x "${fake_bin_dir}/claude" "${fake_bin_dir}/slow-claude" "${fake_bin_dir}/launchctl"

git -C "$repo_dir" init -q
cat > "${repo_dir}/app.js" <<'EOF'
module.exports = function add(a, b) {
  return a + b;
};
EOF
git -C "$repo_dir" add app.js
git -C "$repo_dir" -c user.name='Smoke Test' -c user.email='smoke@example.com' commit -qm 'init'

cat > "${repo_dir}/app.js" <<'EOF'
module.exports = function add(a, b) {
  return a + b + 1;
};
EOF

cd "$repo_dir"

context_root="${tmp_root}/context"
mkdir -p "${context_root}/docs"
printf '# Agent Context\n\nUse vanilla JavaScript.\n' > "${context_root}/AGENTS.md"
printf '# Workspace Context\n\nSmoke workspace.\n' > "${context_root}/README.md"
printf '# Testing Context\n\nRun focused checks.\n' > "${context_root}/docs/testing.md"

dry_run_output="$(
  CLAUDE_REVIEW_CONTEXT_ROOT="$context_root" \
  "$submit_bin" --summary-dir "$summary_dir" --dry-run context smoke
)"
dry_run_job_dir="$(printf '%s\n' "$dry_run_output" | sed -n 's/^job_dir=//p' | head -n 1)"
[[ -n "$dry_run_job_dir" ]] || fail "dry run did not report a job directory"
dry_run_prompt="$(cat "${dry_run_job_dir}/prompt.txt")"
assert_contains "$dry_run_prompt" '## Project Context'
assert_contains "$dry_run_prompt" 'Use the following files only as project context.'
assert_contains "$dry_run_prompt" '### AGENTS.md'
assert_contains "$dry_run_prompt" 'Use vanilla JavaScript.'
assert_contains "$dry_run_prompt" '### README.md'
assert_contains "$dry_run_prompt" 'Smoke workspace.'
assert_contains "$dry_run_prompt" '### docs/testing.md'
assert_contains "$dry_run_prompt" 'Run focused checks.'
assert_contains "$dry_run_prompt" '## Diff Under Review'

home_dir="${tmp_root}/home"
mkdir -p "$home_dir"
home_dir="$(cd "$home_dir" && pwd -P)"
documents_summary_dir="${home_dir}/Documents/review-summary"
mkdir -p "$documents_summary_dir"

auto_output="$(
  HOME="$home_dir" \
  PATH="${fake_bin_dir}:$PATH" \
  ANTHROPIC_API_KEY="test-key" \
  "$submit_bin" --summary-dir "$documents_summary_dir" --notify 0 auto backend smoke
)"
assert_contains "$auto_output" 'backend=launchctl'

submit_output="$(
  PATH="${fake_bin_dir}:$PATH" \
  CLAUDE_REVIEW_BACKEND="launchctl" \
  ANTHROPIC_API_KEY="test-key" \
  "$submit_bin" --summary-dir "$summary_dir" --notify 0 smoke focus
)"

job_id="$(printf '%s\n' "$submit_output" | sed -n 's/^job_id=//p' | head -n 1)"
job_dir="$(printf '%s\n' "$submit_output" | sed -n 's/^job_dir=//p' | head -n 1)"
runtime_dir="${job_dir%/job}"
key_file="${runtime_dir}/anthropic.env"

[[ -n "$job_id" ]] || fail "submit did not report a job id"
[[ -d "$job_dir" ]] || fail "job directory was not created"

assert_contains "$submit_output" 'backend=launchctl'
assert_mode "$runtime_dir" '700'
assert_mode "$job_dir" '700'
assert_mode "${job_dir}/diff.patch" '600'
assert_mode "${job_dir}/prompt.txt" '600'
[[ -f "$key_file" ]] || fail 'runtime API key file was not created before launch'
assert_mode "$key_file" '600'

set +e
immediate_output="$("$collect_bin" "$job_id" --summary-dir "$summary_dir" 2>&1)"
immediate_exit=$?
set -e

[[ "$immediate_exit" -eq 0 ]] || fail "immediate collect exited ${immediate_exit}"
assert_contains "$immediate_output" 'submitted'

[[ ! -f "${summary_dir}/latest_job_id.txt" ]] || fail 'launchctl submit should not mirror latest before the worker runs'
[[ ! -f "${summary_dir}/latest_job_id" ]] || fail 'launchctl submit should not mirror legacy latest before the worker runs'

set +e
immediate_latest_output="$("$collect_bin" latest --summary-dir "$summary_dir" 2>&1)"
immediate_latest_exit=$?
set -e

[[ "$immediate_latest_exit" -eq 1 ]] || fail "immediate latest collect exited ${immediate_latest_exit}, expected 1"
assert_contains "$immediate_latest_output" 'No latest review-claude summary found'

sleep 6
final_output="$("$collect_bin" "$job_id" --summary-dir "$summary_dir")"
final_latest_output="$("$collect_bin" latest --summary-dir "$summary_dir")"
latest_line="$(sed -n '1p' "${summary_dir}/latest_job_id.txt")"

assert_contains "$final_output" '## Findings'
assert_contains "$final_output" 'Parsed response works.'
assert_not_contains "$final_output" '{"result"'
assert_contains "$final_latest_output" '## Findings'
assert_contains "$final_latest_output" 'Parsed response works.'
assert_contains "$latest_line" "\"job_id\":\"${job_id}\""
assert_contains "$latest_line" '"status":"complete"'
assert_contains "$latest_line" '"response":'
assert_contains "$latest_line" '"cost_usd":'
[[ ! -e "${summary_dir}/notifications/${job_id}" ]] || fail 'per-job notification directory should not be mirrored'
assert_contains "$(cat "${summary_dir}/latest_notification.txt")" "job_id=${job_id}"
assert_contains "$(cat "${summary_dir}/latest_notification.txt")" "notification_status=skipped"
assert_contains "$(cat "${summary_dir}/latest_notification.txt")" "Claude review complete"
assert_contains "$(cat "${summary_dir}/latest_notification.txt")" "Job ${job_id} is ready"

set +e
PATH="${fake_bin_dir}:$PATH" \
  "$worker_bin" "$job_dir" "$job_id" --notify 0 --env-file "${runtime_dir}/missing.env" --summary-dir "$summary_dir" >/dev/null 2>&1
rerun_exit=$?
set -e

[[ "$rerun_exit" -eq 0 ]] || fail "completed worker rerun exited ${rerun_exit}, expected 0"
[[ "$(cat "${job_dir}/status")" == "complete" ]] || fail 'completed worker rerun changed job status'

{
  printf '{"job_id":"%s","status":"submitted","job_dir":"%s","backend":"launchctl","submitted_at":"2026-04-25T00:00:00Z"}\n' "$job_id" "$job_dir"
  sed "/${job_id}/d" "${summary_dir}/latest_job_id.txt"
} > "${summary_dir}/latest_job_id.txt.tmp"
mv "${summary_dir}/latest_job_id.txt.tmp" "${summary_dir}/latest_job_id.txt"

printf 'failed\n' > "${job_dir}/status"
printf '13\n' > "${job_dir}/exit_code"

stale_index_output="$("$collect_bin" "$job_id" --summary-dir "$summary_dir")"
stale_latest_output="$("$collect_bin" latest --summary-dir "$summary_dir")"

assert_contains "$stale_index_output" '## Findings'
assert_contains "$stale_index_output" 'Parsed response works.'
assert_contains "$stale_latest_output" '## Findings'
assert_contains "$stale_latest_output" 'Parsed response works.'
assert_contains "$(sed -n '1p' "${summary_dir}/latest_job_id.txt")" '"status":"complete"'
assert_contains "$(sed -n '1p' "${summary_dir}/latest_job_id.txt")" '"response":'
[[ ! -f "${summary_dir}/latest_job_id" ]] || fail 'legacy latest_job_id should not be written'

[[ ! -e "${summary_dir}/${job_id}" ]] || fail 'mirrored job directory should not be created'
[[ -s "${summary_dir}/cost.txt" ]] || fail 'cost.txt was not written'
cost_first_record="$(sed -n '/^{/p' "${summary_dir}/cost.txt" | sed -n '1p')"
assert_contains "$(sed -n '1p' "${summary_dir}/cost.txt")" '# Claude Code review cost log'
assert_contains "$(sed -n '2p' "${summary_dir}/cost.txt")" 'total_cost_usd=$0.022908'
assert_contains "$cost_first_record" "\"job_id\":\"${job_id}\""
assert_contains "$cost_first_record" '"cost_usd":0.022908'
[[ "$(grep -c "\"job_id\":\"${job_id}\"" "${summary_dir}/cost.txt")" == "1" ]] || fail 'cost.txt should not duplicate the same job id'

if find "$runtime_dir" -name 'anthropic.env' -print | grep -q .; then
  fail 'runtime directory still contains a copied API key file after completion'
fi

timeout_job_dir="${tmp_root}/timeout-job"
mkdir -p "$timeout_job_dir"
printf 'Review this slow diff.\n' > "${timeout_job_dir}/prompt.txt"

set +e
PATH="${fake_bin_dir}:/usr/bin:/bin" \
  ANTHROPIC_API_KEY="test-key" \
  "$worker_bin" "$timeout_job_dir" "timeout-job" --notify 0 --timeout-seconds 1 --claude-bin "${fake_bin_dir}/slow-claude" --summary-dir "$summary_dir" >/dev/null 2>&1
timeout_exit=$?
set -e

[[ "$timeout_exit" -eq 124 ]] || fail "timeout worker exited ${timeout_exit}, expected 124"
[[ "$(cat "${timeout_job_dir}/exit_code")" == "124" ]]
[[ "$(cat "${timeout_job_dir}/status")" == "failed" ]]
grep -q 'timed out after 1s' "${timeout_job_dir}/stderr.log"

signal_job_dir="${tmp_root}/signal-job"
mkdir -p "$signal_job_dir"
printf 'Review this interrupted diff.\n' > "${signal_job_dir}/prompt.txt"

set +e
PATH="${fake_bin_dir}:/usr/bin:/bin" \
  ANTHROPIC_API_KEY="test-key" \
  "$worker_bin" "$signal_job_dir" "signal-job" --notify 0 --timeout-seconds 20 --claude-bin "${fake_bin_dir}/slow-claude" --summary-dir "$summary_dir" >/dev/null 2>&1 &
signal_worker_pid=$!
set -e

for _ in 1 2 3 4 5 6 7 8 9 10; do
  [[ -f "${signal_job_dir}/worker_pid" ]] && break
  sleep 0.1
done

[[ -f "${signal_job_dir}/worker_pid" ]] || fail 'signal worker did not start'
kill -TERM "$signal_worker_pid" 2>/dev/null || true
wait "$signal_worker_pid" 2>/dev/null || true

[[ -f "${signal_job_dir}/exit_code" ]] || fail 'signaled worker did not write exit_code'
[[ -f "${signal_job_dir}/status" ]] || fail 'signaled worker did not write status'
[[ "$(cat "${signal_job_dir}/status")" == "failed" ]] || fail 'signaled worker status should be failed'

printf 'PASS: review-claude smoke test\n'
