FROM scratch
# Metadata-only fixture; no runnable process exists to probe.
HEALTHCHECK NONE
# Nonroot user even for the inert inspect-only test image.
USER 65532:65532
ARG SOURCE_COMMIT
ARG RELEASE_VERSION
ARG PRODUCER_SHA256
ARG HANDOFF_MANIFEST_SHA256
ARG BUILD_KIND
LABEL test.source_commit="${SOURCE_COMMIT}" \
      test.release_version="${RELEASE_VERSION}" \
      test.producer_sha256="${PRODUCER_SHA256}" \
      test.handoff_sha256="${HANDOFF_MANIFEST_SHA256}" \
      test.build_kind="${BUILD_KIND}"
