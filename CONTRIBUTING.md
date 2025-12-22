# Contributing to WrkstrmLog

Thanks for your interest in contributing! We welcome issues, ideas, and pull requests.

## Quick start

1) Fork the repo and create a feature branch

```bash
git checkout -b feature/amazing-feature
```

2) Make focused changes and add tests where appropriate

3) Run tests and lint locally

```bash
swift test --parallel
swift format lint --configuration code/mono/apple/spm/configs/linting/.swift-format --strict --recursive code/mono/apple/spm/universal/WrkstrmLog
```

4) Open a Pull Request with a clear summary and rationale

## Style and expectations

- Swift 6.1+ via SwiftPM (cross‑platform). Prefer Linux‑safe APIs.
- Formatting: use the repo swift-format config at `code/mono/apple/spm/configs/linting/.swift-format`.
- Tests: use Swift Testing (`import Testing`), avoid XCTest for new tests.
- Naming: CamelCase for identifiers; kebab‑case for files/directories where applicable.
- No macOS‑only assumptions in shared code paths; WASM support should not pull in Foundation.

## CI and coverage

- GitHub Actions run tests and upload coverage via Codecov on Linux; a separate job can run on a self‑hosted macOS runner.
- PRs should remain green; if tests must be flaky‑tolerant, annotate why and keep the scope minimal.

## Code of conduct

Be kind and constructive. We value clarity, small PRs, and good test coverage.
