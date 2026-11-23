#!/usr/bin/env bash
# Add the shared agent hooks to a harness's hook configuration.
# The harness and other tools also write this file, so only the two hook
# entries are managed here and everything else passes through unchanged.
set -euo pipefail

current="$(cat)"
[[ -n "$current" ]] || current='{}'

jq '
  def ensure_hook(event; cmd):
    .hooks[event] = (
      (.hooks[event] // [])
      | if any(.[]; any(.hooks[]?; .command == cmd)) then .
        else . + [{hooks: [{type: "command", command: cmd}]}]
        end
    );
  ensure_hook("SessionStart"; "\"$HOME/.agents/hooks/session-start\"")
  | ensure_hook("Stop"; "\"$HOME/.agents/hooks/stop-gate\"")
' <<<"$current"
