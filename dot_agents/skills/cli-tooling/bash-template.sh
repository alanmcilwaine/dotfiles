#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly VERSION="0.1.0"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] <target>

Briefly describe what this script does.

Arguments:
  target              Describe the required argument.

Options:
  -h, --help          Show this help message
  -v, --verbose       Enable verbose logging
  -f, --force         Skip confirmation prompts where appropriate
  --version           Show script version

Examples:
  $SCRIPT_NAME demo
  $SCRIPT_NAME --verbose demo
EOF
}

log_info() {
    gum style --foreground 12 --bold "→ $*" >&2
}

log_success() {
    gum style --foreground 10 --bold "✓ $*" >&2
}

log_warn() {
    gum style --foreground 214 --bold "! $*" >&2
}

log_error() {
    gum style --foreground 9 --bold "✗ $*" >&2
}

die() {
    log_error "$SCRIPT_NAME: $*"
    exit 1
}

confirm() {
    local prompt="$1"
    gum confirm "$prompt"
}

require_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null || die "required command not found: $command_name"
}

parse_args() {
    verbose=false
    force=false
    target=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --version)
                printf '%s %s\n' "$SCRIPT_NAME" "$VERSION"
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                die "unknown option: $1 (see --help)"
                ;;
            *)
                break
                ;;
        esac
    done

    [[ $# -ge 1 ]] || {
        usage >&2
        exit 2
    }

    target="$1"
}

validate() {
    require_command gum
    [[ -n "$target" ]] || die "target is required"
}

main() {
    local verbose=false
    local force=false
    local target=""

    parse_args "$@"
    validate

    if [[ "$verbose" == true ]]; then
        log_info "Verbose mode enabled"
    fi

    log_info "Working on: $target"

    if [[ "$force" != true ]]; then
        confirm "Continue with target '$target'?" || die "cancelled"
    fi

    # Put main logic here.
    # Keep functions small and move repeated work into named helpers.

    log_success "Done"
}

main "$@"
