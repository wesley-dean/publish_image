#!/usr/bin/env bash
# Emit correct OCI tags/labels for a previously independently verified release.
# Never infer release identity from ambient workflow_run github.ref.
set -euo pipefail
set +x

ref="${VERIFIED_RELEASE_REF:-}"
sha="${VERIFIED_SOURCE_SHA:-}"
[[ "$ref" =~ ^refs/tags/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || exit 64
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || exit 64
[[ -n "${GITHUB_OUTPUT:-}" ]] || exit 64

version="${ref#refs/tags/v}"
IFS=. read -r major minor patch <<< "$version"
images=()
for name in DOCKERHUB GHCR QUAY HARBOR ECR CUSTOM; do
  selected="SELECTED_$name"
  registry="REGISTRY_$name"
  image="IMAGE_$name"
  if [[ "${!selected:-false}" != true ]]; then
    continue
  fi
  path="${!registry:-}/${!image:-}"
  [[ "$path" != *$'\n'* && "$path" != *$'\r'* &&
    "$path" =~ ^[a-zA-Z0-9][a-zA-Z0-9._:/-]+$ &&
    "$path" != */ ]] || {
    printf 'publish_image: invalid registry image path in verified mode\n' >&2
    exit 64
  }
  images+=("$path")
done
(( ${#images[@]} > 0 )) || {
  printf 'publish_image: verified mode requires a selected image\n' >&2
  exit 64
}

# One multiline value per output, using a deterministic non-secret delimiter.
{
  echo 'tags<<PUBLISH_IMAGE_TAGS_END'
  for image in "${images[@]}"; do
    for tag in "latest" "$version" "$major.$minor" "$major" "sha-${sha:0:7}" "sha-$sha"; do
      printf '%s:%s\n' "$image" "$tag"
    done
  done
  echo 'PUBLISH_IMAGE_TAGS_END'
  echo 'labels<<PUBLISH_IMAGE_LABELS_END'
  printf 'org.opencontainers.image.version=%s\n' "$version"
  printf 'org.opencontainers.image.revision=%s\n' "$sha"
  printf 'org.opencontainers.image.ref.name=%s\n' "$ref"
  echo 'PUBLISH_IMAGE_LABELS_END'
  echo 'annotations<<PUBLISH_IMAGE_ANNOTATIONS_END'
  printf 'org.opencontainers.image.version=%s\n' "$version"
  printf 'org.opencontainers.image.revision=%s\n' "$sha"
  echo 'PUBLISH_IMAGE_ANNOTATIONS_END'
  printf 'release_version=%s\n' "$version"
  printf 'release_ref=%s\n' "$ref"
  printf 'source_sha=%s\n' "$sha"
} >> "$GITHUB_OUTPUT"
