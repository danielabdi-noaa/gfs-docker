#!/bin/bash

set -exo pipefail

export COMP=${COMP:-gnu}

NPROCS=`nproc`
export MAKEFLAGS="-j ${NPROCS}"
#install directory and compiler flag
INSTALL_DIR=${INSTALL_DIR:-/usr/local}
SRC_DIR=${SRC_DIR:-/opt}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${INSTALL_DIR}/lib

######################################
# esmf
#####################################

VER=esmf-8.0.0_bs40

#clone the specific snapshot of the repo
git clone -b ESMF_8_0_0_beta_snapshot_40 --depth 1 https://git.code.sf.net/p/esmf/esmf esmf

#set compiler
if [ "$COMP" = "intel" ]; then
    export ESMF_COMPILER=intel
    export ESMF_CXXCOMPILER=mpiicpc
    export ESMF_CXXLINKER=mpiicpc
    export ESMF_F90COMPILER=mpiifort
    export ESMF_F90LINKER=mpiifort
    export ESMF_COMM=intelmpi
    export ESMF_MPIRUN=mpirun
    export ESMF_SL_LIBLIBS="-L$INSTALL_DIR/lib -lmpicxx -lmpifort -lmpi"
else
    export ESMF_CXXCOMPILER=mpicxx
    export ESMF_CXXLINKER=mpicxx
    export ESMF_F90COMPILER=mpif90
    export ESMF_F90LINKER=mpif90
    export ESMF_COMM=mpich3
    export ESMF_MPIRUN=mpiexec
    export ESMF_SL_LIBLIBS="-L$INSTALL_DIR/lib -lmpichcxx -lmpichf90 -lmpich"
fi

export ESMF_NETCDF=nc-config
export ESMF_INSTALL_BINDIR=bin
export ESMF_INSTALL_LIBDIR=lib
export ESMF_INSTALL_MODDIR=mod
export ESMF_INSTALL_PREFIX=${INSTALL_DIR}/${VER}

cd $SRC_DIR && \
    cd esmf && \
    export ESMF_DIR=`pwd` && \
    make info 2>&1 | tee log.info && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    make installcheck 2>&1 | tee log.installcheck && \
    cd .. && \
    rm -fr esmf

