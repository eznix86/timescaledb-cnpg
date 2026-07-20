# TimescaleDB extension image for CloudNativePG ImageVolume
#
# Follows the postgres-extensions-containers pattern:
# https://github.com/cloudnative-pg/postgres-extensions-containers
#
# Uses the FULL TimescaleDB package from Timescale's apt repo
# (not the PGDG dfsg repack which strips TSL-licensed code).
# This includes the TSL module needed for compression,
# continuous aggregates, and other licensed features.

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie@sha256:538f1b327b8dc7621a94aac79c9c3e5c50dfa29115a6c291e19372a5b876f415
FROM $BASE AS builder

ARG PG_MAJOR=18
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -sL https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash && \
    apt-get install -y --no-install-recommends \
        "timescaledb-2-${EXT_VERSION}-postgresql-${PG_MAJOR}" && \
    rm -rf /var/lib/apt/lists/*

FROM scratch
ARG PG_MAJOR=18

# Licenses
COPY --from=builder /usr/share/doc/timescaledb-2-loader-postgresql-${PG_MAJOR}/copyright /licenses/timescaledb-loader/
COPY --from=builder /usr/share/doc/timescaledb-2-*-postgresql-${PG_MAJOR}/copyright /licenses/timescaledb/

# Shared libraries (loader + versioned core + TSL module)
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/timescaledb*.so /lib/

# Extension control + SQL files
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/timescaledb* /share/extension/

USER 65532:65532
