FROM postgres:13.4

# Apache and PHP 5.6
RUN \
  apt-get update && \
  apt-get install -y \
          cron vim curl tmux

# gsutil with Google Cloud SDK
RUN \
  echo "deb http://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  apt-get update && apt-get install -y google-cloud-sdk && \
  rm -rf /var/lib/apt/lists/*

EXPOSE 5432
CMD ["postgres"]
