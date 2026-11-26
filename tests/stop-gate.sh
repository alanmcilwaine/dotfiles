#!/usr/bin/env bash
# Tests the agent hooks in dot_agents/hooks against a throwaway home folder,
# repository and overlay. Nothing outside a temporary folder is read or changed.
#
# Usage: bash tests/stop-gate.sh
set -uo pipefail

hooks="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dot_agents/hooks" && pwd -P)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

export HOME="$root/home" TMPDIR="$root/tmp" XDG_STATE_HOME="$root/state"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
mkdir -p "$HOME" "$TMPDIR"

repo="$root/repo"
overlay="$HOME/repos/dotfiles-work/agents/projects/example.com/owner/project"
runs="$root/runs"
mkdir -p "$overlay"
git init -q "$repo"
git -C "$repo" remote add origin https://example.com/owner/project.git
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m first

# The overlay's checks count their runs and pass or fail on a switch file.
cat >"$overlay/checks.sh" <<CHECKS
echo run >>"$runs"
echo "== summary"
echo "lint: passed, 2 findings"
[[ ! -e "$root/fail" ]]
CHECKS
echo "cat '$root/outside' 2>/dev/null" >"$overlay/state.sh"

failures=0
expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$want" == "$got" ]]; then
        echo "ok    $name"
    else
        echo "FAIL  $name: wanted $want, got $got"
        failures=$((failures + 1))
    fi
}
run_count() { local n=0; [[ -e "$runs" ]] && n="$(grep -c . "$runs")"; echo "$n"; }
start() { printf '{"cwd":"%s","session_id":"%s"}' "$repo" "$1" | "$hooks/executable_session-start" >/dev/null; }
stop() { printf '{"cwd":"%s","session_id":"%s"}' "${2:-$repo}" "$1" | "$hooks/executable_stop-gate" >"$root/out" 2>"$root/err"; }

echo "instructions" >"$overlay/AGENTS.md"

start one
stop one
expect "a session that changed nothing passes" 0 $?
expect "and the checks did not run" 0 "$(run_count)"

echo change >"$repo/file"
stop one
expect "a changed tree that passes its checks passes" 0 $?
expect "and the checks ran once" 1 "$(run_count)"
expect "and the human is shown the summary" 1 "$(grep -c 'lint: passed, 2 findings' "$root/out")"

stop one
expect "the same state passes again" 0 $?
expect "without running the checks again" 1 "$(run_count)"

echo pushed >"$root/outside"
stop one
expect "a change in the overlay's outside state passes" 0 $?
expect "and runs the checks again" 2 "$(run_count)"

touch "$root/fail"
echo another >"$repo/file"
for attempt in 1 2 3; do
    stop one
    expect "failing checks block the stop, attempt $attempt" 2 $?
done
expect "and the agent is shown the output" 1 "$(grep -c 'Checks failed (attempt 3 of 3)' "$root/err")"
stop one
expect "the fourth failure lets the agent stop" 0 $?
expect "and tells the human" 1 "$(grep -c 'checks still fail' "$root/out")"
expect "and the log records it" 1 "$(grep -c 'let through with the checks still failing' "$XDG_STATE_HOME/agents/stop-gate.log")"

mkdir "$repo/sub"
rm "$root/fail"
echo third >"$repo/sub/new"
stop one "$repo/sub"
expect "a stop in a subdirectory with untracked files passes" 0 $?

printf '{"session_id":"two"}' | "$hooks/executable_stop-gate" >"$root/out" 2>"$root/err"
expect "a gate that fails blocks the first time" 2 $?
expect "and tells the agent the checks did not run" 1 "$(grep -c 'This is a bug in the gate' "$root/err")"
printf '{"session_id":"two"}' | "$hooks/executable_stop-gate" >"$root/out" 2>"$root/err"
expect "a gate that fails again lets the agent stop" 0 $?
expect "and tells the human" 1 "$(grep -c 'failed again' "$root/out")"

if [[ "$failures" -gt 0 ]]; then
    echo "$failures failed"
    exit 1
fi
echo "all passed"
