# fastpilot GitHub Action

Run your [fastpilot](https://github.com/autobot-lab/fastpilot) tests (plain-language `tests/*.md`
files) in GitHub Actions and get a JUnit file for the checks tab and an HTML report with every
step. The action downloads the fastpilot release for the runner, checks its SHA-256, and runs
`fastpilot run <tests> --junit fastpilot-junit.xml --html fastpilot-report.html <args>`.

## Use it

```yaml
name: fastpilot
on: [pull_request]
permissions:
  contents: read
  checks: write # for the test report on the pull request
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # fastpilot run drives Claude Code; it needs an API key from your repository secrets.
      - run: npm install -g @anthropic-ai/claude-code
      - id: fastpilot
        uses: autobot-lab/fastpilot-action@v1
        with:
          tests: tests/
          args: --workers 2
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          DEMO_PASS: ${{ secrets.DEMO_PASS }} # every ${NAME} your tests use
      - uses: mikepenz/action-junit-report@v6
        if: always()
        with:
          report_paths: ${{ steps.fastpilot.outputs.junit }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: fastpilot-report
          path: ${{ steps.fastpilot.outputs.report }}
```

| Input | Default | |
|---|---|---|
| `version` | `latest` | fastpilot version, e.g. `0.4.1` |
| `tests` | `tests/` | a folder of tests or one test file |
| `args` | | more `fastpilot run` arguments, e.g. `--workers 2` |
| `install-only` | `false` | only put `fastpilot` on PATH |

Outputs: `junit`, `report` (file paths) and `version`.

## Good to know

- **Runners:** Linux x64 and macOS (arm64, x64). Web tests run on GitHub's runners. Android needs an
  emulator and iPhone a Mac with Xcode and a simulator, so start with web tests.
- **Secrets:** the AI key and the values your tests use (`${NAME}`) come from repository secrets.
  Pull requests from forks do not get secrets, so their tests are reported as "could not run", not as
  passed.
- **Limits apply in CI too:** fastpilot never presses Pay or delete-account buttons, and the AI cannot
  loosen limits. Change limits in `.fastpilot` / `fastpilot config`, as on your computer.
- **Exit code:** the step fails when a test fails, so the job shows red. The reports are written
  either way; use `if: always()` for the report steps.

## License

Apache-2.0, like fastpilot.
