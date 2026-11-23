# TimescaleDB extension image for CloudNativePG ImageVolume
#
# Follows the postgres-extensions-containers pattern:
# https://github.com/cloudnative-pg/postgres-extensions-containers
#
# Uses the FULL TimescaleDB package from Timescale's apt repo
# (not the PGDG dfsg repack which strips TSL-licensed code).
# This includes the TSL module needed for compression,
# continuous aggregates, and other licensed features.

ARG BASE=ghcr.io/cloudnative-pg/postgresql:19-minimal-trixie@sha256:12688a494f25aa0b7e1e3cd1800abe85b427fd1a09c991668a48162e3431a2af
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
