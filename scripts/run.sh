#!/usr/bin/env bash
# fastpilot run <tests> --junit … --html … <args>. The reports are written even when tests fail;
# the step fails when a test fails, so the job shows red.
set -uo pipefail
set -f # args are split on spaces, never expanded as file patterns
junit="${GITHUB_WORKSPACE}/fastpilot-junit.xml"
report="${GITHUB_WORKSPACE}/fastpilot-report.html"
echo "junit=${junit}" >> "$GITHUB_OUTPUT"
echo "report=${report}" >> "$GITHUB_OUTPUT"
# shellcheck disable=SC2086
fastpilot run "${INPUT_TESTS}" --junit "$junit" --html "$report" ${INPUT_ARGS}
