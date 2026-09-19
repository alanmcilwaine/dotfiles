#!/usr/bin/env bash
set -euo pipefail

if [[ ! -t 0 || ! -t 1 ]]; then
    gum log --level error 'Run this menu in a terminal.'
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repo_dir"

gum style --bold 'Dotfiles'
selections="$(gum choose --no-limit --selected='' \
    --header 'Choose what to apply' \
    'Dotfiles' 'Packages' 'macOS settings')"

if [[ -z "$selections" ]]; then
    gum log --level info 'Nothing selected.'
    exit 0
fi

while IFS= read -r selection; do
    gum log --level info "Applying $selection"

    case "$selection" in
        'Dotfiles')
            chezmoi --source "$repo_dir" apply
            ;;
        'Packages')
            brew bundle install --file "$repo_dir/Brewfile" --no-upgrade
            ;;
        'macOS settings')
            bash "$repo_dir/scripts/macos.sh"
            ;;
    esac
done <<< "$selections"

gum log --level info 'Done.'
