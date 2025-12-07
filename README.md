# gcp-postgres

```bash
# add tag to current container image
DOCKER_REPO=asia.gcr.io/re-global-prod/gcp-postgres
gcloud container images list-tags $DOCKER_REPO
gcloud container images add-tag $DOCKER_REPO:old-tag $DOCKER_REPO:new-tag

# manual build with cache base + optional release tag
BASE_TAG=14.11          # tag to use for cache (defaults to latest if unset)
RELEASE_TAG=v1.2.3      # optional release tag to push alongside SHORT_SHA/latest
PUSH_BASE_TAG=true      # set true to tag/push the built image as BASE_TAG (overwrites that tag)
gcloud builds submit . \
  --config cloudbuild.yaml \
  --substitutions _DOCKER_REPO=$DOCKER_REPO,_BASE_TAG=$BASE_TAG,_RELEASE_TAG=$RELEASE_TAG,_PUSH_BASE_TAG=$PUSH_BASE_TAG,SHORT_SHA=f81da2d

# omit _RELEASE_TAG if you only want SHORT_SHA/latest pushed
# omit _BASE_TAG to fall back to latest for cache
# omit _PUSH_BASE_TAG to avoid overwriting BASE_TAG
```
