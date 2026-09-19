#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
    gum log --level error 'These settings require macOS.'
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
agent="$script_dir/macos/local.caps-to-escape.plist"

# Trackpad tracking speed.
gum log --level info 'Setting trackpad tracking speed'
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 5.0

# Show hidden files in Finder.
gum log --level info 'Showing hidden files in Finder'
defaults write com.apple.finder AppleShowAllFiles -bool true

# Install the login agent and apply its keyboard mapping to this session.
gum log --level info 'Setting Caps Lock → Escape'
mapping="$(/usr/bin/plutil -extract ProgramArguments.3 raw -o - "$agent")"
mkdir -p "$HOME/Library/LaunchAgents"
install -m 644 "$agent" "$HOME/Library/LaunchAgents/local.caps-to-escape.plist"
/usr/bin/hidutil property --set "$mapping"
