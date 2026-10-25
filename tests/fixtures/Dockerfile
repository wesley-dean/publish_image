FROM scratch
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
