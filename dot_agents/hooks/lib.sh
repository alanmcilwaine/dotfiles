# Shared helpers for agent hooks. Source this file; do not run it.
#
# A project overlay is a personal, uncommitted layer for one repository. It
# lives in the private dotfiles checkout, under the repository's origin URL:
#   ~/repos/dotfiles-work/agents/projects/<host>/<owner>/<repo>/AGENTS.md   instructions
#   ~/repos/dotfiles-work/agents/projects/<host>/<owner>/<repo>/checks.sh   gate run when the agent stops
# A project with no overlay skips both.

readonly PRIVATE_ROOT="$HOME/repos/dotfiles-work"

require_command() {
    command -v "$1" >/dev/null || {
        echo "agent hook: required command not found: $1" >&2
        exit 1
    }
}

# Read one field from the hook's JSON input.
hook_field() {
    local input="$1" field="$2"
    jq -r --arg field "$field" '.[$field] // empty' <<<"$input"
}

# Identify the project by its full origin URL, as <host>/<owner>/<repo>, so
# every worktree and clone shares one overlay and an unrelated repository with
# the same name never matches. Fails when the directory has no origin remote.
project_key() {
    local dir="$1" url
    url="$(git -C "$dir" remote get-url origin 2>/dev/null)" || return 1
    url="${url%.git}"
    url="${url#*://}"
    url="${url#*@}"
    echo "${url/://}"
}

# Print the overlay directory for a project. Fails when there is none.
overlay_dir() {
    local key overlay
    key="$(project_key "$1")" || return 1
    overlay="$PRIVATE_ROOT/agents/projects/$key"
    [[ -d "$overlay" ]] || return 1
    echo "$overlay"
}
