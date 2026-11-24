# gcp-postgres

## Build a selected PostgreSQL version on GitHub

In **Actions → Build PostgreSQL image → Run workflow**, choose `main` and enter an exact supported major.minor. Leave **Publish** unchecked for a disposable verification build. To publish the verified multi-platform image to `ghcr.io/reallyenglish-global/postgres:<version>`, select **Publish** on `main`; no `latest` tag is moved. For example, to verify only:

```bash
gh workflow run ci.yml --ref main -f base_image_version=18.7 -f publish=false
```

Automatic publication on a push to `main` uses the repository variable `BASE_IMAGE_VERSION`; if unset, it is skipped. A version whose upstream image or compatible extension packages are unavailable fails rather than publishing a different binary.

```bash
# add tag to current container image
DOCKER_REPO=asia.gcr.io/re-global-prod/gcp-postgres
gcloud container images list-tags $DOCKER_REPO
gcloud container images add-tag $DOCKER_REPO:old-tag $DOCKER_REPO:new-tag

# Non-publishing test (pick a version supported by the available extension packages)
VERSION=18.7
bash ci/build-verified.sh "$VERSION" "$VERSION" local/gcp-postgres "$(git rev-parse --short HEAD)"

# Release only: uploads the SHA and version tags, NOT latest. Use a clean checkout.
# Set VERSION to the explicitly approved release version before running this.
gcloud builds submit . --config cloudbuild.yaml --substitutions "_DOCKER_REPO=$DOCKER_REPO,_BASE_IMAGE_VERSION=$VERSION,_BASE_TAG=$VERSION,SHORT_SHA=$(git rev-parse --short HEAD)"
```
