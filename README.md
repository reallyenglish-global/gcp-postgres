# gcp-postgres

```bash
# add tag to current container image
DOCKER_REPO=asia.gcr.io/re-global-prod/gcp-postgres
gcloud container images list-tags $DOCKER_REPO
gcloud container images add-tag $DOCKER_REPO:old-tag $DOCKER_REPO:new-tag

# manual build
gcloud builds submit . --config cloudbuild.yaml --substitutions _DOCKER_REPO=$DOCKER_REPO,SHORT_SHA=f81da2d
```
