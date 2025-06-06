FROM postgres:17.5

RUN \
  apt-get update && \
  apt-get install -y \
          cron vim curl tmux htop pgtop procps postgresql-17-cron postgresql-17-partman

# gsutil with Google Cloud SDK
RUN \
  echo "deb http://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  apt-get update && apt-get install -y google-cloud-sdk && \
  rm -rf /var/lib/apt/lists/*

ADD bin /usr/local/bin

EXPOSE 5432
CMD ["postgres"]
