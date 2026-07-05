#!/bin/bash

ARCHIVE_PATH=${ARCHIVE_PATH:-${PGDATA}/..}

archive_wal() {
  local wal_file="$1"  # WAL file path
  local archive_file
  archive_file="$ARCHIVE_PATH/$(basename "$wal_file")"

  mkdir -p "$ARCHIVE_PATH"

  if cp "$wal_file" "$archive_file"; then
    echo "Successfully archived $wal_file to $archive_file"
    exit 0
  else
    echo "Failed to archive $wal_file"
    exit 1
  fi
}

archive_wal "$1"
