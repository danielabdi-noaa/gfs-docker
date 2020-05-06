#!/bin/bash

REPO=${REPO:-dshawul}

#build image
build_image() {
    docker build -t ${1} -f ${2} .
}

#netcdf
IMAGE_NAME=${REPO}/netcdf-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-netcdf
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#esmf
IMAGE_NAME=${REPO}/esmf-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-esmf
build_image ${IMAGE_NAME} ${DOCKER_FILE}

#fv3
IMAGE_NAME=${REPO}/fv3-gnu
DOCKER_FILE=Dockerfiles/gnu/Dockerfile-fv3
build_image ${IMAGE_NAME} ${DOCKER_FILE}
