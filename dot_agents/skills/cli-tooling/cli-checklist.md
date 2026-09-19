# CLI Checklist

## Environment

- Runs in user space only
- Assumes `gum` and `just` are available
- Treats Windows, macOS, and Linux as first-class targets

## Interface

- Clear command purpose
- Helpful usage or help output
- Sensible argument and flag names
- Destructive actions made explicit
- Good examples included

## Output

- stdout kept useful
- stderr used for errors and diagnostics
- No casual `2>&1`
- Output is tidy and pleasant
- `gum` used where it improves UX

## Code quality

- `#!/usr/bin/env bash`
- `set -euo pipefail`
- Meaningful variable and function names
- Small, focused functions
- Inputs validated early
- Builtins preferred where sensible
- ShellCheck considered or run
- Fails closed: every skip-guard distinguishes expected-absent (may skip) from error (must fail)

## Maintainability

- Readable over clever
- Platform-specific logic isolated
- `just` used for orchestration
- Large inline recipes avoided when a script would be clearer
