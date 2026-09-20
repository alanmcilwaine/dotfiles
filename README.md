# dotfiles

I like close to default configurations. This might change in the future. Most of these dots will only really work on MacOS until I can be bothered to support WSL/Ubuntu

Skills go in .agents/skills.

Run `bash scripts/macos.sh`, or choose **macOS settings** in the menu, to
save screenshots to `~/Desktop/Screenshots` and copy new PNGs to the clipboard.
The clipboard helper starts at login. Allow Desktop folder access if macOS asks.
Keep using Command-Shift-3/4/5. Copying takes about two seconds after the file is
saved, so wait for the floating thumbnail to disappear before pasting.
These settings are separate from `chezmoi apply`.

### Commands
```bash
brew bundle install                
chezmoi init --apply alanmcilwaine # Setup
chezmoi update                     # Pull latest dots
./scripts/menu.sh                  # Open the interactive dotfiles menu

# To modify the cursor, download MaCursor, and drag/drop the cursor file in there
```
