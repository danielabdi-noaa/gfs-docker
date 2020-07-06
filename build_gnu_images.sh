#!/bin/bash

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: Please install docker first.' >&2
  exit 1
fi

REPO=${REPO:-dshawul}
GERRIT_ID=${GERRIT_ID:-gerrit}
SSH_CONFIG=${SSH_CONFIG:-${HOME}/.ssh/config}

export DOCKER_BUILDKIT=1

#build image
build_image() {
    docker build --ssh default --secret id=${GERRIT_ID},src=${SSH_CONFIG} \
                 --build-arg REPO=${REPO} \
                 --build-arg GERRIT_ID=${GERRIT_ID} \
                 -t ${1} -f ${2} .
}

#netcdf
IMAGE_NAME=${REPO}/netcdf-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-netcdf
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#esmf
IMAGE_NAME=${REPO}/esmf-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-esmf
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#nceplibs
IMAGE_NAME=${REPO}/nceplibs-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-nceplibs
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#gfs
IMAGE_NAME=${REPO}/gfs-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-gfs
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#fv3
IMAGE_NAME=${REPO}/fv3-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-fv3
build_image ${IMAGE_NAME} ${DOCKER_FILE}

