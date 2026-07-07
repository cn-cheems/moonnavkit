# Pre-Acceptance Fixes

This note records the review feedback closed for the MoonBit contest
pre-acceptance pass.

## CI

The GitHub workflow now follows the official MoonBit community template style:

- install the latest MoonBit toolchain in CI;
- run `moon version --all` and `moon update`;
- run `moon check --target all`;
- run `moon test --target all`;
- run `moon fmt` followed by `git diff --exit-code`;
- run `moon info` followed by `git diff --exit-code`;
- run deterministic demo and benchmark commands on Ubuntu.

The workflow avoids unsupported `--deny-warn` arguments and keeps checkout on
`actions/checkout@v4`, matching the current official template.

## Library Scope

MoonNavKit now includes route-quality analysis in addition to path search,
flow-field routing, graph export, JSON/SVG/HTML diagnostics, deterministic map
generation, and benchmark scenarios. The added `GridMap::analyze_path` API lets
downstream tools validate route legality, cost, step count, and turn count.

## Local Verification

Before this note was added, the following local checks passed:

```text
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target js
moon info
```

Native test execution needs a C compiler on the host. The local Windows
workstation did not expose `cl`, `cc`, `gcc`, or `clang`, while the GitHub
workflow runs on hosted runners with compiler toolchains available.
