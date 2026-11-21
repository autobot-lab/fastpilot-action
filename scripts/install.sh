#!/usr/bin/env bash
# Download the fastpilot release archive for this runner, check its SHA-256, put it on PATH.
set -euo pipefail
case "${RUNNER_OS}-${RUNNER_ARCH}" in
  Linux-X64) target=x86_64-unknown-linux-gnu ;;
  macOS-ARM64) target=aarch64-apple-darwin ;;
  macOS-X64) target=x86_64-apple-darwin ;;
  *) echo "::error::fastpilot has no prebuilt binary for ${RUNNER_OS} ${RUNNER_ARCH} (Linux x64, macOS arm64/x64)"; exit 1 ;;
esac
version="${INPUT_VERSION#v}"
if [ "$version" = latest ]; then
  version="$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" https://api.github.com/repos/autobot-lab/fastpilot/releases/latest \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
fi
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::version must look like 0.4.1 (or latest), not: ${version}"
  exit 1
fi
name="fastpilot-${version}-${target}"
base="https://github.com/autobot-lab/fastpilot/releases/download/v${version}"
dir="${RUNNER_TEMP}/fastpilot-${version}"
mkdir -p "$dir"
curl -fsSL --retry 3 --retry-all-errors -o "$dir/${name}.tar.gz" "$base/${name}.tar.gz"
curl -fsSL --retry 3 --retry-all-errors -o "$dir/${name}.tar.gz.sha256" "$base/${name}.tar.gz.sha256"
want="$(cut -d' ' -f1 < "$dir/${name}.tar.gz.sha256")"
if command -v sha256sum >/dev/null; then got="$(sha256sum "$dir/${name}.tar.gz" | cut -d' ' -f1)"; else got="$(shasum -a 256 "$dir/${name}.tar.gz" | cut -d' ' -f1)"; fi
if [ -z "$want" ] || [ "$want" != "$got" ]; then
  echo "::error::checksum mismatch for ${name}.tar.gz (expected ${want}, got ${got}); fastpilot was not installed"
  exit 1
fi
tar -xzf "$dir/${name}.tar.gz" -C "$dir"
echo "$dir/${name}" >> "$GITHUB_PATH"
"$dir/${name}/fastpilot" --version
echo "version=${version}" >> "$GITHUB_OUTPUT"
