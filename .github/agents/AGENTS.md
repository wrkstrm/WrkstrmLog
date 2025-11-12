# Agent Instructions for WrkstrmLog

WrkstrmLog is a Swift logging framework. Use these guidelines when contributing to this repository.

## Scope

These instructions apply to all files in the WrkstrmLog repository unless a more specific
`AGENTS.md` file overrides them.

## Contribution Guidelines

- Format any modified Swift files with
  `swift format --configuration https://raw.githubusercontent.com/wrkstrm/configs/main/linting/.swift-format -i -r -p`.
  This is the only Swift formatting step to run.
- Lint the project with `swiftlint` using the included configuration.
- Run the full test suite with `swift test` and ensure it passes.
- Write descriptive commit messages and keep pull requests focused.

## Documentation

- Tutorials and how-to material for WrkstrmLog must live in this package's `.docc`
  bundle. DocC keeps the guides human-grade and still approachable for LLMs, so do not park
  them in standalone Markdown files.

## Platform notes

- WASM (wasi) support: the library builds on WASM by excluding Foundation- and OSLog-dependent code via conditional compilation. Available backends on WASM: Print (and SwiftLog if available). OSLog backend and Xcode helpers are excluded.
- Apple platforms (macOS/iOS) retain full functionality.

## Release Naming Convention

WrkstrmLog releases are nicknamed after tree species in alphabetical order—a nod to logging. For
example, v2.1.0 is "Aspen"; upcoming releases will continue with names like "Birch", "Cedar", etc.
Use the codename in release notes, tags, and announcements.

## Assistant Operating Mode

- Git command approval: do not run any `git` commands without explicit user approval
  (including but not limited to `clone`, `status`, `add`, `commit`, `reset`, `rebase`, `push`,
  `submodule`, `config`). Prefer reading workspace files over invoking `git` when possible.

## CLIA canonicals and first launch

- Canonical loaders: JSON triads under `.clia/agents/**`.
- Canonical MD (human): persona and system‑instructions alongside triads.
- Mirrors: `.generated/agent.md` is non‑canonical; use to validate rendering.
- Default agent: `^codex` unless an explicit agent load is requested via
  `>agentSlug` (e.g., `>clia`, `>carrie`).

Checklist

- `!sync` → reset, thin‑scan, determine scope; load triads; apply sandbox/approvals; announce mode.

Diverge paths

- If in submodule: stage a DocC request with diffs/rationale in parent repo.
- Use CommonShell/CommonProcess; avoid `Foundation.Process`.

DocC link: `code/.clia/docc/agents-onboarding.docc` (preview from repo root).

# Agent Instructions for Documentation Articles

## Naming Standard

- The introductory article in this directory must be named `TheProblemSpace.md`.
- Consolidate duplicated introductory content into this file when necessary.

## Assistant Operating Mode

- Git command approval: do not run any `git` commands without explicit user approval
  (including but not limited to `clone`, `status`, `add`, `commit`, `reset`, `rebase`, `push`,
  `submodule`, `config`). Prefer reading workspace files over invoking `git` when possible.
