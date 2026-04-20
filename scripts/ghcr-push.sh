#!/bin/bash

set -e
cd $(dirname "${BASH_SOURCE[0]}")/..

# GIT_BRANCH is the current branch name
export GIT_BRANCH=$(git branch --show-current)
# GIT_VERSION - always the last verison number, like 1.12.1.
export GIT_VERSION=$(git describe --tags --abbrev=0)
# GIT_COMMIT_SHORT - the short git commit number, like a718ef0.
export GIT_COMMIT_SHORT=$(git rev-parse --short HEAD)
# DOCKER_REPO - the base repository name to push the docker build to.
export DOCKER_REPO=ghcr.io/$GITHUB_USER/tile38

if [ "$GIT_BRANCH" != "master" ]; then
	echo "Not pushing, not on master"
elif [ "$GITHUB_USER" == "" ]; then
	echo "Not pushing, GITHUB_USER not set"
else
	# setup cross platform builder
	# https://github.com/tonistiigi/binfmt
	docker run --privileged --rm tonistiigi/binfmt --install all
	docker buildx create --name multiarch --platform linux/amd64,linux/amd64/v2,linux/amd64/v3,linux/arm64,linux/386,linux/arm/v7 --use default

	if ! docker manifest inspect $DOCKER_REPO:$GIT_VERSION > /dev/null 2>&1; then
  	# build the docker image
		docker buildx build \
			-f Dockerfile \
			--platform linux/arm64,linux/amd64 \
			--build-arg VERSION=$GIT_VERSION \
			--tag $DOCKER_REPO:$GIT_VERSION \
			--tag $DOCKER_REPO:latest \
			--tag $DOCKER_REPO:edge \
			--push \
			.
	else
		# build the docker image
		docker buildx build \
			-f Dockerfile \
			--platform linux/arm64,linux/amd64 \
			--build-arg VERSION=$GIT_VERSION \
			--tag $DOCKER_REPO:edge \
			--push \
			.
	fi
fi
