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

gum log --level info 'Saving screenshots to Desktop/Screenshots'
screenshots_dir="$HOME/Desktop/Screenshots"
mkdir -p "$screenshots_dir"
# Keep the legacy keys for older macOS versions. macOS 27 uses the screenshot-specific keys.
defaults write com.apple.screencapture location -string "$screenshots_dir"
defaults write com.apple.screencapture location-screenshot -string "$screenshots_dir"
defaults write com.apple.screencapture target -string file
defaults write com.apple.screencapture target-screenshot -string file
defaults write com.apple.screencapture type -string png

# Copy new screenshots to the clipboard while preserving the standard shortcuts.
gum log --level info 'Installing screenshot clipboard helper'
helper_dir="$HOME/Library/Application Support/dotfiles"
clipboard_agent="$HOME/Library/LaunchAgents/local.screenshot-clipboard.plist"
launch_domain="gui/$(id -u)"
mkdir -p "$helper_dir" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
install -m 644 "$script_dir/macos/screenshot-clipboard.js" "$helper_dir/screenshot-clipboard.js"
install -m 644 "$script_dir/macos/local.screenshot-clipboard.plist" "$clipboard_agent"
/usr/bin/plutil -insert ProgramArguments.3 -string "$helper_dir/screenshot-clipboard.js" "$clipboard_agent"
/usr/bin/plutil -insert StandardErrorPath -string "$HOME/Library/Logs/screenshot-clipboard.log" "$clipboard_agent"
if launchctl print "$launch_domain/local.screenshot-clipboard" >/dev/null 2>&1; then
    launchctl bootout "$launch_domain/local.screenshot-clipboard"
fi
launchctl bootstrap "$launch_domain" "$clipboard_agent"

# Install the login agent and apply its keyboard mapping to this session.
gum log --level info 'Setting Caps Lock → Escape'
mapping="$(/usr/bin/plutil -extract ProgramArguments.3 raw -o - "$agent")"
mkdir -p "$HOME/Library/LaunchAgents"
install -m 644 "$agent" "$HOME/Library/LaunchAgents/local.caps-to-escape.plist"
/usr/bin/hidutil property --set "$mapping"
