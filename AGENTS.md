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
