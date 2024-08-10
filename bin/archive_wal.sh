#!/bin/bash

if [ -z "$ARCHIVE_PATH" ]; then
  echo "ARCHIVE_PATH is not set."
  exit 1
fi

archive_wal() {
  local wal_file="$1"  # WAL file path
  local archive_file="$ARCHIVE_PATH/`basename $wal_file`"

  mkdir -p "$ARCHIVE_PATH"

  cp "$wal_file" "$archive_file"

  if [ $? -eq 0 ]; then
    echo "Successfully archived $wal_file to $archive_file"
    exit 0
  else
    echo "Failed to archive $wal_file"
    exit 1
  fi
}

archive_wal "$1"
