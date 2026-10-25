#!/usr/bin/env bash
# Offline no-registry acceptance for the opt-in verified publishing contract.
set -euo pipefail
set +x
cd "$(dirname "$0")/.."
validate="$PWD/scripts/verify-publisher-inputs.bash"
metadata="$PWD/scripts/verified-release-metadata.bash"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

die() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
must_fail() { if "$@" >"$tmp/log" 2>&1; then die 'unexpected success'; fi; }
must_contain() { grep -F -- "$1" "$2" >/dev/null || die "missing: $1"; }
must_not_contain() { if grep -F -- "$1" "$2" >/dev/null; then die "forbidden: $1"; fi; }

sha='0123456789abcdef0123456789abcdef01234567'
out="$tmp/output"

# Old callers with no new inputs still validate successfully.
env -i PATH="$PATH" bash "$validate"
# Exact v0 tag and source SHA are accepted as an input contract, not proof.
env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA="$sha" PUBLISH_IMAGE_PUSH=false \
  PUBLISH_IMAGE_BUILD_ARGS="SOURCE_COMMIT=$sha
RELEASE_VERSION=0.2.3
PRODUCER_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
HANDOFF_MANIFEST_SHA256=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
BUILD_KIND=release" \
  bash "$validate"
must_fail env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 bash "$validate"
must_fail env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA=bad bash "$validate"
must_fail env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA="$sha" PUBLISH_FORCE_RELEASE=true bash "$validate"
must_fail env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA="$sha" PUBLISH_IMAGE_BUILD_ARGS='SOURCE_COMMIT=deadbeef' bash "$validate"
must_fail env -i PATH="$PATH" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA="$sha" PUBLISH_IMAGE_BUILD_ARGS='RELEASE_VERSION=0.2.4' bash "$validate"
must_fail env -i PATH="$PATH" PUBLISH_IMAGE_BUILD_ARGS='DOCKERHUB_TOKEN=secret' bash "$validate"
must_fail env -i PATH="$PATH" PUBLISH_IMAGE_BUILD_ARGS='GPG_SYMMETRIC_KEY=secret' bash "$validate"
must_fail env -i PATH="$PATH" PUBLISH_IMAGE_BUILD_ARGS='bad key=x' bash "$validate"
must_fail env -i PATH="$PATH" PUBLISH_IMAGE_PUSH=false REQUIRED_REGISTRIES=dockerhub,ghcr bash "$validate"
must_fail env -i PATH="$PATH" REQUIRED_REGISTRIES=dockerhub,ghcr bash "$validate"
must_fail env -i PATH="$PATH" REQUIRED_REGISTRIES=dockerhub,unknown bash "$validate"
env -i PATH="$PATH" REQUIRED_REGISTRIES=dockerhub,ghcr \
  PUBLISH_DOCKERHUB_USERNAME=x PUBLISH_DOCKERHUB_TOKEN=fixture-value \
  PUBLISH_GHCR_USERNAME=x PUBLISH_GHCR_TOKEN=fixture-value bash "$validate"

: > "$out"
env -i PATH="$PATH" GITHUB_OUTPUT="$out" VERIFIED_RELEASE_REF=refs/tags/v0.2.3 \
  VERIFIED_SOURCE_SHA="$sha" SELECTED_GHCR=true REGISTRY_GHCR=ghcr.io \
  IMAGE_GHCR=wesley-dean/certbotbot SELECTED_DOCKERHUB=true \
  REGISTRY_DOCKERHUB=docker.io IMAGE_DOCKERHUB=wesleydean/certbotbot \
  bash "$metadata"
must_contain 'ghcr.io/wesley-dean/certbotbot:latest' "$out"
must_contain 'ghcr.io/wesley-dean/certbotbot:0.2.3' "$out"
must_contain 'ghcr.io/wesley-dean/certbotbot:0.2' "$out"
must_contain 'ghcr.io/wesley-dean/certbotbot:0' "$out"
must_contain 'docker.io/wesleydean/certbotbot:sha-0123456' "$out"
must_contain "docker.io/wesleydean/certbotbot:sha-$sha" "$out"
must_contain "org.opencontainers.image.revision=$sha" "$out"
must_contain 'org.opencontainers.image.version=0.2.3' "$out"
must_contain 'release_ref=refs/tags/v0.2.3' "$out"
must_not_contain 'edge' "$out"
must_not_contain 'refs/heads/main' "$out"
must_fail env -i PATH="$PATH" GITHUB_OUTPUT="$out" VERIFIED_RELEASE_REF=refs/heads/main \
  VERIFIED_SOURCE_SHA="$sha" SELECTED_GHCR=true REGISTRY_GHCR=ghcr.io \
  IMAGE_GHCR=example/test bash "$metadata"

# Static negative checks: no legacy tokens through step outputs.
for key in dockerhub_token ghcr_token quay_token harbor_token custom_token ecr_secret_access_key; do
  if grep -F "echo \"$key=" action.yml >/dev/null; then
    die "credential output remains for $key"
  fi
  if grep -F "steps.customvars.outputs.$key" action.yml >/dev/null; then
    die "credential read from step output: $key"
  fi
done
# The expression is literal GitHub Actions syntax, not Bash expansion.
# shellcheck disable=SC2016
must_contain 'build-args: ${{ inputs.build_args }}' action.yml
must_contain 'type=edge,branch=main' action.yml
printf '%s\n' 'Publisher contract offline checks passed'
