# No implicit production major: all builds must select a release explicitly.
ARG BASE_IMAGE_VERSION
FROM postgres:${BASE_IMAGE_VERSION}
ARG BASE_IMAGE_VERSION

RUN \
  PG_EXTENSION_MAJOR="${BASE_IMAGE_VERSION%%.*}" && \
  apt-mark hold "postgresql-${PG_EXTENSION_MAJOR}" && \
  apt-get update && \
  apt-get install -y \
          cron vim curl ca-certificates gpg tmux htop pgtop procps "postgresql-${PG_EXTENSION_MAJOR}-cron" "postgresql-${PG_EXTENSION_MAJOR}-partman"

# gsutil with Google Cloud SDK
RUN \
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg -o /tmp/google-cloud-key && \
  gpg --batch --dearmor -o /usr/share/keyrings/google-cloud.gpg /tmp/google-cloud-key && \
  rm /tmp/google-cloud-key && \
  echo "deb [signed-by=/usr/share/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt-get update && apt-get install -y --no-install-recommends google-cloud-cli && \
  gsutil version && \
  rm -rf /var/lib/apt/lists/*

ADD bin /usr/local/bin

EXPOSE 5432
CMD ["postgres"]
