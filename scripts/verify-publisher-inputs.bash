#!/usr/bin/env bash
# Validate opt-in metadata, nonsecret args and required dual-registry inputs.
# Caller must independently authenticate its tag, SHA and release evidence.
set -euo pipefail
set +x

fail() {
  printf 'publish_image: %s\n' "$1" >&2
  exit 64
}

push="${PUBLISH_IMAGE_PUSH:-true}"
[[ "$push" == true || "$push" == false ]] || fail 'push must be true or false'

ref="${VERIFIED_RELEASE_REF:-}"
sha="${VERIFIED_SOURCE_SHA:-}"
if [[ -n "$ref" || -n "$sha" ]]; then
  [[ "$ref" =~ ^refs/tags/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
    fail 'verified_release_ref must be refs/tags/vMAJOR.MINOR.PATCH'
  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] ||
    fail 'verified_source_sha must be a lowercase 40-character commit SHA'
fi

# Buildx ARG values are observable in image history/provenance. This only
# detects suspicious key names; callers must never disguise a secret as data.
args="${PUBLISH_IMAGE_BUILD_ARGS:-}"
[[ "$args" != *$'\r'* ]] || fail 'build_args cannot contain CR'
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -n "$line" ]] || continue
  [[ "$line" == *=* ]] || fail 'each build_args line must be NAME=VALUE'
  key="${line%%=*}"
  [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || fail 'invalid build_args key'
  lower="${key,,}"
  # When these widely used identity args are present in verified mode,
  # they must match the verified metadata exactly; other generic callers
  # retain the ability to omit these application-specific build args.
  if [[ -n "$ref" ]]; then
    value="${line#*=}"
    case "$key" in
      SOURCE_COMMIT)
        [[ "$value" == "$sha" ]] ||
          fail 'SOURCE_COMMIT build argument differs from verified source SHA'
        ;;
      RELEASE_VERSION)
        [[ "$value" == "${ref#refs/tags/v}" ]] ||
          fail 'RELEASE_VERSION build argument differs from verified tag'
        ;;
    esac
  fi
  case "$lower" in
    *secret*|*token*|*password*|*credential*|*passwd*|*private*|*access_key*|*apikey*|*api_key*|*auth_key*|gpg_*|ssh_*)
      fail 'credential-like keys are forbidden in build_args; use secret mounts'
      ;;
  esac
done <<< "$args"

required="${REQUIRED_REGISTRIES:-}"
[[ "$required" != *$'\r'* && "$required" != *$'\n'* ]] ||
  fail 'required_registries must be comma-separated without newlines'
if [[ -n "$required" ]]; then
  [[ "$push" == true ]] || fail 'required_registries requires push=true'
  IFS=, read -r -a registries <<< "$required"
  (( ${#registries[@]} > 0 )) || fail 'empty required registry list'
  for reg in "${registries[@]}"; do
    case "$reg" in
      dockerhub)
        [[ -n "${PUBLISH_DOCKERHUB_USERNAME:-}" && -n "${PUBLISH_DOCKERHUB_TOKEN:-}" ]] ||
          fail 'required Docker Hub credentials are missing'
        ;;
      ghcr)
        [[ -n "${PUBLISH_GHCR_USERNAME:-}" && -n "${PUBLISH_GHCR_TOKEN:-}" ]] ||
          fail 'required GHCR credentials are missing'
        ;;
      *)
        fail 'required_registries supports only dockerhub and ghcr'
        ;;
    esac
  done
fi

# Formatting these values is not proof that the release has been verified.
if [[ -n "$ref" ]]; then
  [[ "${PUBLISH_FORCE_RELEASE:-false}" == false ]] ||
    fail 'force_release cannot be combined with verified_release_ref'
fi
