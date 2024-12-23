#!/bin/bash

## Parse input ##
NAME1=debian
NAME2=bookworm
BASE=debian:bookworm-slim
DISTRO=debian
DOCKERFILE=dockerfile-gh-core
REGISTRY=registry.goldenhelix.com/public
DAY=$(date +'%y%m%d')

## Build/Push image to cache endpoint by pipeline ID ##
docker build \
  -t ${REGISTRY}/ghdesktop-core:$(arch)-${NAME1}-${NAME2}-${DAY} \
  --build-arg BASE_IMAGE="${BASE}" \
  --build-arg DISTRO="${DISTRO}" \
  -f ${DOCKERFILE} .
