ARG BASE_IMAGE_VERSION
FROM postgres:${BASE_IMAGE_VERSION}
ARG BASE_IMAGE_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    PG_MAJOR="${BASE_IMAGE_VERSION%%.*}" && \
    apt-mark hold "postgresql-${PG_MAJOR}" && \
    apt-get install -y --no-install-recommends \
        cron \
        vim \
        curl \
        tmux \
        htop \
        procps \
        "postgresql-${PG_MAJOR}-cron" \
        "postgresql-${PG_MAJOR}-partman" \
        "postgresql-${PG_MAJOR}-pgvector" && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gpg \
        ca-certificates && \
    # Add Google Cloud public key securely
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    # Add Google Cloud SDK repository
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-cli && \
    gsutil version && \
    # Clean up apt cache again
    rm -rf /var/lib/apt/lists/*

# Multi-architecture GHCR builds must verify each platform before export.
RUN actual="$(postgres --version)" && set -- $actual && test "$3" = "$BASE_IMAGE_VERSION"

ADD bin /usr/local/bin

EXPOSE 5432

CMD ["postgres"]
