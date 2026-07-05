# gcp-postgres

## Replica WAL recovery check

`bin/replica_ready_or_reseed` is a replica-only recovery check for cases where a
standby can no longer receive WAL from the primary, for example:

```text
FATAL:  could not receive data from WAL stream
```

The script:

1. exits successfully immediately when `REPLICA_RESEED_ROLE=primary`;
2. checks `select pg_is_in_recovery()` and exits successfully on primaries;
3. searches the configured Postgres log for the WAL-stream fatal;
4. refuses to clear data unless it has `PRIMARY_CONNINFO` or can read
   `primary_conninfo` from `$PGDATA/postgresql.auto.conf`;
5. stops Postgres, clears `$PGDATA`, runs `pg_basebackup -R` from the primary,
   and exits non-zero so the supervisor can restart Postgres.

Example probe command:

```bash
REPLICA_WAL_ERROR_LOG=/var/lib/postgresql/data/../log/postgresql.log \
REPLICA_RESEED_ROLE=replica \
PRIMARY_CONNINFO='host=primary port=5432 user=replicator' \
bin/replica_ready_or_reseed
```

The default reseed exit code is `1`. Set `RESEED_EXIT_CODE=0` only for manual
runs where an external restart is not expected.
Set `REPLICA_RESEED_ROLE=primary` on primary pods so the check returns `0`
without querying Postgres or reading logs.

```bash
# add tag to current container image
DOCKER_REPO=asia.gcr.io/re-global-prod/gcp-postgres
gcloud container images list-tags $DOCKER_REPO
gcloud container images add-tag $DOCKER_REPO:old-tag $DOCKER_REPO:new-tag

# manual build
BASE_IMAGE_VERSION=18.1
gcloud builds submit . --config cloudbuild.yaml --substitutions _DOCKER_REPO=$DOCKER_REPO,_BASE_IMAGE_VERSION=$BASE_IMAGE_VERSION,SHORT_SHA=f81da2d
```
