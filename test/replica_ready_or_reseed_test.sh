#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT_DIR}/bin/replica_ready_or_reseed"
export SCRIPT

fail() {
  echo "not ok - $1" >&2
  exit 1
}

assert_file_exists() {
  [[ -e "$1" ]] || fail "expected $1 to exist"
}

assert_file_missing() {
  [[ ! -e "$1" ]] || fail "expected $1 to be missing"
}

make_stub_bin() {
  local dir="$1"

  cat > "${dir}/psql" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${PSQL_CALL_LOG:-}" ]]; then
  echo "$*" >> "$PSQL_CALL_LOG"
fi
case "${PSQL_RECOVERY_STATE:-replica}" in
  replica) echo t ;;
  primary) echo f ;;
  error) exit 2 ;;
esac
STUB
  chmod +x "${dir}/psql"

  cat > "${dir}/pg_ctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "${CALL_LOG}"
STUB
  chmod +x "${dir}/pg_ctl"

  cat > "${dir}/pg_basebackup" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "${CALL_LOG}"
mkdir -p "${PGDATA}"
touch "${PGDATA}/PG_VERSION"
STUB
  chmod +x "${dir}/pg_basebackup"
}

export -f fail assert_file_exists assert_file_missing make_stub_bin

run_case() {
  local name="$1"
  shift
  local tmp
  tmp="$(mktemp -d)"
  (
    mkdir -p "${tmp}/bin" "${tmp}/pgdata" "${tmp}/logs"
    make_stub_bin "${tmp}/bin"
    touch "${tmp}/pgdata/PG_VERSION" "${tmp}/pgdata/old-file"
    export PATH="${tmp}/bin:${PATH}"
    export PGDATA="${tmp}/pgdata"
    export REPLICA_WAL_ERROR_LOG="${tmp}/logs/postgres.log"
    export PRIMARY_CONNINFO="host=primary port=5432 user=replicator"
    export CALL_LOG="${tmp}/calls.log"
    "$@" "${tmp}"
  )
  rm -rf "${tmp}"
  echo "ok - ${name}"
}

# shellcheck disable=SC2016
run_case "passes without touching primary data" bash -c '
  set -euo pipefail
  tmp="$1"
  export PSQL_RECOVERY_STATE=primary
  echo "FATAL:  could not receive data from WAL stream" > "$REPLICA_WAL_ERROR_LOG"
  "$SCRIPT"
  assert_file_exists "$PGDATA/old-file"
  [[ ! -e "$CALL_LOG" ]] || fail "primary should not stop or reseed"
' _

# shellcheck disable=SC2016
run_case "passes immediately when configured pod role is primary" bash -c '
  set -euo pipefail
  tmp="$1"
  export REPLICA_RESEED_ROLE=primary
  export PSQL_RECOVERY_STATE=error
  export PSQL_CALL_LOG="${tmp}/psql-calls.log"
  echo "FATAL:  could not receive data from WAL stream" > "$REPLICA_WAL_ERROR_LOG"
  "$SCRIPT"
  assert_file_exists "$PGDATA/old-file"
  [[ ! -e "$PSQL_CALL_LOG" ]] || fail "configured primary should not query postgres"
  [[ ! -e "$CALL_LOG" ]] || fail "configured primary should not stop or reseed"
' _

# shellcheck disable=SC2016
run_case "passes healthy replica without reseeding" bash -c '
  set -euo pipefail
  tmp="$1"
  export PSQL_RECOVERY_STATE=replica
  echo "database system is ready to accept read only connections" > "$REPLICA_WAL_ERROR_LOG"
  "$SCRIPT"
  assert_file_exists "$PGDATA/old-file"
  [[ ! -e "$CALL_LOG" ]] || fail "healthy replica should not stop or reseed"
' _

# shellcheck disable=SC2016
run_case "reinitializes replica when WAL stream cannot continue" bash -c '
  set -euo pipefail
  tmp="$1"
  export PSQL_RECOVERY_STATE=replica
  export RESEED_EXIT_CODE=0
  echo "FATAL:  could not receive data from WAL stream" > "$REPLICA_WAL_ERROR_LOG"
  "$SCRIPT"
  assert_file_missing "$PGDATA/old-file"
  assert_file_exists "$PGDATA/PG_VERSION"
  grep -q "stop -D $PGDATA -m fast -w" "$CALL_LOG" || fail "expected pg_ctl stop"
  grep -q " -D $PGDATA " "$CALL_LOG" || fail "expected pg_basebackup into PGDATA"
' _

# shellcheck disable=SC2016
run_case "refuses to wipe replica without primary connection info" bash -c '
  set -euo pipefail
  tmp="$1"
  export PSQL_RECOVERY_STATE=replica
  unset PRIMARY_CONNINFO
  echo "FATAL:  could not receive data from WAL stream" > "$REPLICA_WAL_ERROR_LOG"
  if "$SCRIPT"; then
    fail "expected missing primary conninfo to fail"
  fi
  assert_file_exists "$PGDATA/old-file"
  [[ ! -e "$CALL_LOG" ]] || fail "should not stop without conninfo"
' _
