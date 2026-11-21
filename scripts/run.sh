#!/usr/bin/env bash
# fastpilot run <tests> --junit … --html … [--changed origin/<base>] <args>. The reports are written
# even when tests fail; the step fails when a test fails, so the job shows red.
set -uo pipefail
set -f # args are split on spaces, never expanded as file patterns
junit="${GITHUB_WORKSPACE}/fastpilot-junit.xml"
report="${GITHUB_WORKSPACE}/fastpilot-report.html"
echo "junit=${junit}" >> "$GITHUB_OUTPUT"
echo "report=${report}" >> "$GITHUB_OUTPUT"
changed=()
if [ "${INPUT_CHANGED:-false}" = "true" ]; then
  installed="${FASTPILOT_INSTALLED:-}"
  major="${installed%%.*}"; rest="${installed#*.}"; minor="${rest%%.*}"
  if [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] && { [ "$major" -gt 0 ] || [ "$minor" -ge 6 ]; }; then
    base="${GITHUB_BASE_REF:-}"
    if [ -z "$base" ]; then
      echo "::notice::changed: not a pull request; comparing with where this branch left main."
      changed=(--changed)
    elif git check-ref-format --branch "$base" >/dev/null 2>&1 && [[ "$base" != -* ]]; then
      # The pull request's base branch, so fastpilot can compare (shallow checkouts have only HEAD).
      git fetch --no-tags --quiet origin "+refs/heads/${base}:refs/remotes/origin/${base}" || echo "::warning::changed: could not fetch origin/${base}; fastpilot will say what it could compare."
      changed=(--changed "origin/${base}")
    else
      echo "::warning::changed: the base branch name is not a valid branch name; running all tests."
    fi
  else
    echo "::warning::changed needs fastpilot 0.6 or newer (installed: ${installed:-unknown}); running all tests."
  fi
fi
# shellcheck disable=SC2086
fastpilot run "${INPUT_TESTS}" --junit "$junit" --html "$report" ${changed[@]+"${changed[@]}"} ${INPUT_ARGS}
