#!/bin/bash

set -ex

#install directory and compiler flag
INSTALL_DIR=${INSTALL_DIR:-/usr/local}
SRC_DIR=${SRC_DIR:-/opt}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${INSTALL_DIR}/lib

#########################
# IB driver
#########################

##Mellanox driver
#MOFED_VER=4.6-1.0.1.1
#OS_VER=ubuntu18.04
#PLATFORM=x86_64
#MOFED_DIR=MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}
#cd /opt && tar -xvf ${MOFED_DIR}.tgz && \
#    ${MOFED_DIR}/mlnxofedinstall --user-space-only --without-fw-update -q && \
#    cd .. && \
#    rm -rf ${MOFED_DIR} ${MOFED_DIR}.tgz
#

#######################
# mpich or openmpi
########################

IFLAGS=
#IFLAGS="--with-device=ch3:nemesis:mxm --with-mxm=/opt/mellanox/mxm"

VER=3.3a2
PP=mpich-${VER}
DLINK="https://www.mpich.org/static/downloads/${VER}/${PP}.tar.gz"

#MVER=v4.0
#VER=4.0.2
#PP=openmpi-$VER
#DLINK="https://download.open-mpi.org/release/open-mpi/${MVER}/${PP}.tar.gz"

cd $SRC_DIR && wget ${DLINK} && \
    tar -xzvf ${PP}.tar.gz && \
    cd ${PP} && \
    ./configure $IFLAGS --prefix=$INSTALL_DIR && \
    make && \
    make install && \
    cd .. && \
    rm -rf ${PP} ${PP}.tar.gz
