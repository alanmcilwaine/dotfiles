# Shared editor keys

In Vim normal mode, press Space then the letter. `R` means Shift+R.

Chezmoi owns the complete Zed and VS Code user settings files. Both use
Gruvbox Dark, MonoLisa Nerd Font at size 20 for code and terminal text, and
Vim mode. Install the font on each machine before applying these settings.
VS Code also hides inline code predictions while leaving regular completion menus
active.

| Keys | Action |
| --- | --- |
| `Space r` | Run the current target |
| `Space R` | Run all project tests |
| `Space d` | Start debugging |
| `Space b` | Toggle a line breakpoint |
| `Ctrl+backtick` | Switch focus between code and terminal, keeping terminal visible |

Zed provides global Go and Python tasks. Go Run uses `go run .`; Go Test uses
`go test ./...`. Python Run uses the current file, and Python Test uses
`python -m pytest` (`python3` on macOS and Linux). For other languages, the Run
and Test bindings open Zed's task picker. Project-specific commands can live
in `.zed/tasks.json`.

VS Code needs the VSCodeVim and `jdinhlife.gruvbox` extensions. Run uses the
selected launch configuration without debugging. Test uses VS Code's Test
Explorer, so a Go or Python test extension must discover the project tests.

GoLand and PyCharm need IdeaVim. `Space r` runs the selected run configuration;
`Space R` calls the IDE's `RunAllTests` action. Verify that action in the IDE's
Find Action dialog for each installed version. If it is unavailable, create a
project-wide test run configuration and map its action ID in `.ideavimrc`.
IdeaVim does not handle shortcuts while the terminal has focus. To use
`Ctrl+backtick` there, remove its default Quick Switch Scheme binding and assign
it to Terminal under Settings > Keymap. Under Settings > Tools > Terminal, set
"Move focus to the Editor with" to Custom and assign `Ctrl+backtick`. This
terminal-specific action returns focus without closing the panel.

For GoLand and PyCharm, install the
[Gruvbox Theme plugin](https://plugins.jetbrains.com/plugin/12310-gruvbox-theme/)
and select Gruvbox Dark Medium. Set Editor > Font to MonoLisa Nerd Font, size
20, and Tools > Terminal font to the same values. IdeaVim manages only the Vim
mappings; JetBrains stores appearance settings separately. Use JetBrains
Backup and Sync to carry those settings between GoLand and PyCharm. In
Settings > Editor > General > Code Completion > Inline, disable "Enable inline
completion using language models" to hide full-line predictions while keeping
ordinary code completion.
