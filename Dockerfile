ARG VERSION=18beta2
FROM postgres:${VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        vim \
        curl \
        tmux \
        htop \
        procps \
        # Ensure you match the postgresql-xx-extension name to your Postgres version
        postgresql-17-cron \
        postgresql-17-partman \
        postgresql-17-pgvector && \
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
    apt-get install -y --no-install-recommends google-cloud-sdk && \
    # Clean up apt cache again
    rm -rf /var/lib/apt/lists/*

ADD bin /usr/local/bin

EXPOSE 5432

CMD ["postgres"]
