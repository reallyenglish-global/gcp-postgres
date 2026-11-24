#!/usr/bin/env bash
set -euo pipefail
version=${1:?expected PostgreSQL major.minor}; tag=${2:?expected version tag}
repo=${3:?expected image repository}; revision=${4:?expected commit tag}
[[ $version =~ ^[1-9][0-9]*\.[0-9]+$ && $tag == "$version" ]] || {
  echo 'Expected matching numeric PostgreSQL major.minor and image tag' >&2; exit 2;
}
[[ $revision =~ ^[a-f0-9]{7,40}$ ]] || { echo 'Expected a commit SHA' >&2; exit 2; }
docker build --build-arg "BASE_IMAGE_VERSION=$version" -t "$repo:$revision" -t "$repo:$tag" .
output=$(docker run --rm --network none --entrypoint postgres "$repo:$revision" --version)
printf '%s\n' "$output"
read -r name vendor actual _ <<< "$output"
[[ $name == postgres && $vendor == '(PostgreSQL)' && $actual == "$version" ]] || {
  echo "Built PostgreSQL does not match $version" >&2; exit 1;
}
