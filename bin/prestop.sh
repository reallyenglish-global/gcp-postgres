#!/bin/bash

set -euo pipefail

ROLE=$(psql -U postgres -tAc "SELECT CASE WHEN pg_is_in_recovery() THEN 'replica' ELSE 'primary' END;")
echo "PreStop hook triggered. Detected role: $ROLE"

# Function to wait for replication to catch up (optional for primary)
wait_for_replicas() {
  echo "Waiting for replicas to catch up..."
  TIMEOUT=30
  INTERVAL=5
  ELAPSED=0

  while [ $ELAPSED -lt $TIMEOUT ]; do
    lag=$(psql -U postgres -tAc "SELECT MAX(write_lag) FROM pg_stat_replication;" | xargs)
    if [[ "$lag" == "" || "$lag" == "0" ]]; then
      echo "Replicas are caught up."
      return 0
    fi
    echo "Replication lag: $lag. Waiting..."
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
  done

  echo "Warning: Replicas may not be fully caught up after $TIMEOUT seconds."
  return 1
}

# Function to gracefully shutdown PostgreSQL
graceful_shutdown() {
  echo "Shutting down PostgreSQL gracefully..."
  pg_ctl -D "$PGDATA" stop -m fast
}

if [[ "$ROLE" == "primary" ]]; then
  # Optionally terminate idle clients
  echo "Terminating client connections..."
  psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid();"

  wait_for_replicas || true
  graceful_shutdown
else
  echo "Replica detected. Waiting briefly to apply remaining WAL..."
  sleep 5
  graceful_shutdown
fi
