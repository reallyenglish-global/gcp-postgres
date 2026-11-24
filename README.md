# gcp-postgres

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
