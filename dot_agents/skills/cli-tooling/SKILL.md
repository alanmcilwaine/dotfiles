---
name: cli-tooling
description: Write, review, and refine command-line tooling for a gum-and-just-based environment. Use when creating Bash scripts, justfiles, CLI workflows, bootstrap helpers, or polished terminal automation intended to work across Windows, macOS, and Linux in user space.
---

# CLI Tooling

Write personal CLI tooling deliberately.

Use this skill when creating or reviewing scripts, justfiles, and command-line workflows for a cross-platform environment where `gum` and `just` are standard dependencies.

This skill favours readability, maintainability, composability, and polished terminal UX over cleverness.

## Assumed environment

Assume the user's personal tooling environment includes:

- `gum`
- `just`

You may rely on them directly.

## Core principles

1. User-space first.
   - Do not require administrator or sudo privileges by default.
   - Prefer per-user paths, installs, and configuration.

2. Cross-platform by design.
   - Treat Windows, macOS, and Linux as first-class targets.
   - Avoid unnecessary OS-specific assumptions.
   - Isolate platform-specific logic when needed.

3. Polished CLI UX.
   - Produce attractive, structured, humane command-line experiences.
   - Use `gum` for prompts, formatting, confirmation, and status output where appropriate.
   - Follow the spirit of clig.dev.

4. Readability over cleverness.
   - Prefer clear structure, meaningful names, and small functions.
   - Avoid dense one-liners and fragile shell tricks.
   - Write code another human can comfortably maintain.

5. Unix composability.
   - Keep stdout useful.
   - Keep stderr for errors and diagnostics.
   - Avoid mixing streams without a deliberate reason.
   - Prefer small, composable tools and scripts.

6. Simplicity and inspectability.
   - Keep scripts focused.
   - Use `just` for orchestration and discoverable entry points.
   - Use shell scripts for implementation details where appropriate.

## Bash standards

When writing Bash, default to:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Also prefer:

- `[[ ... ]]` for conditionals
- `(( ... ))` for arithmetic
- quoted expansions: `"$var"`
- meaningful variable and function names
- `local` inside functions
- builtins over unnecessary external commands
- early validation of inputs
- explicit `usage` or help text when the script has an interface
- ShellCheck-friendly patterns

Do not use `2>&1` casually.

Only combine stderr and stdout when there is a deliberate need to merge streams. If doing so, keep the reason clear from context or explain it briefly.

Fail closed, not open. Every guard that skips must distinguish expected-absent from error. Absence may skip; failure must fail. A missing optional input can be skipped. A missing required tool, an unreadable file, or a failed command must exit non-zero, never silently degrade the result. The recurring offenders are `command -v tool || skip-the-gate`, `dasel ... 2>/dev/null || echo '{}'`, and `[[ -x hook ]] || skip`.

## Justfile guidance

When writing `just` recipes:

- treat `just` as a command runner, not a build system
- prefer `just` as the main entrypoint for common workflows
- use clear, descriptive recipe names
- keep the `justfile` thin and readable
- use recipe dependencies where they improve clarity
- prefer `just --list` or `set default-list` for discoverability
- avoid cramming large opaque scripts directly into recipes when a separate script would be clearer
- use `just` to expose and organise tasks, not to hide complexity
- avoid hardcoding shell assumptions unless they are deliberate and documented
- consider platform-specific shell settings or platform-specific recipes when cross-platform behaviour differs

## CLI design guidance

Follow these habits:

- provide clear help and usage
- use sensible flag names
- validate before side effects
- make destructive actions explicit
- keep output tidy and informative
- make commands discoverable
- favour predictable behaviour
- show the user what is happening without being noisy

## Workflow

When asked to create or refine CLI tooling:

1. Clarify the task.
   - What is the script or command for?
   - Who will run it?
   - Is it interactive, non-interactive, or both?
   - Is Bash, PowerShell, or `just` the right tool?
   - What platforms matter?

2. Choose the right shape.
   - Should this be a Bash script?
   - A PowerShell script?
   - A `justfile` recipe calling helper scripts?
   - A small combination of these?
   - Should `just` only orchestrate, with the real logic moved into scripts?

3. Design the interface.
   - Inputs
   - flags
   - output
   - errors
   - examples
   - interactivity via `gum` where useful

4. Write for clarity.
   - structure the code cleanly
   - extract small functions
   - name things well
   - comment intent where needed

5. Validate the result.
   - check edge cases
   - check quoting
   - check failure paths
   - suggest ShellCheck for Bash

## Output expectations

When producing a script or CLI workflow, provide:

1. the complete code
2. a short explanation of key design decisions
3. example usage
4. validation suggestions where relevant

## Review checklist

Before finalising, check:

- Does this require admin unnecessarily?
- Will it work in the user's cross-platform personal environment?
- Is `gum` used appropriately?
- Is `just` used appropriately as orchestration rather than a dumping ground for logic?
- Is the code readable?
- Are stdout and stderr used cleanly?
- Is `2>&1` avoided unless justified?
- Are inputs validated early?
- Is the interface pleasant to use?
- Would ShellCheck be reasonably happy?

## Style

Prefer:

- concise, direct instructions
- practical defaults
- humane CLI output
- British English
- clean formatting
- small composable parts

Avoid:

- overengineering
- unreadable shell tricks
- unnecessary fallback code
- hidden side effects
- generic advice without concrete action
