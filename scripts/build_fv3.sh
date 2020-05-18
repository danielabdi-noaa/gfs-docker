#!/bin/bash

set -ex

export COMP=${COMP:-gnu}

#install directory and compiler flag
INSTALL_DIR=${INSTALL_DIR:-/usr/local}
SRC_DIR=${SRC_DIR:-/opt}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${INSTALL_DIR}/lib

######################################
# Old nceplibs
######################################
VER=NCEPlibs-20190820
cd $SRC_DIR && \
    git clone https://github.com/NCAR/NCEPlibs.git && \
    mv NCEPlibs $VER && \
    cd $VER && \
    git checkout 4fc8335c42a54db77b6586189 -b temp
    mkdir $INSTALL_DIR/$VER && \
    yes | ./make_ncep_libs.sh -s linux -c ${COMP} -d ${INSTALL_DIR}/${VER} -o 1 && \
    cd .. && \
    rm -fr ${VER}

##########################
#  checkout fv3gfs.fd
##########################
topdir=${SRC_DIR}

echo fv3gfs checkout ...
if [[ ! -d fv3gfs.fd ]] ; then
    rm -f ${topdir}/checkout-fv3gfs.log
    git clone https://github.com/ufs-community/ufs-weather-model NEMSfv3gfs >> ${topdir}/checkout-fv3gfs.log 2>&1
    cd NEMSfv3gfs
    git checkout GFS.v16.0.0
    git submodule update --init --recursive
    cd ${topdir}
else
    echo 'Skip.  Directory fv3gfs.fd already exists.'
fi

./patch_fv3.sh

##########################
#  build fv3gfs.fd
##########################
if [ "$COMP" = "intel" ]; then
    export CC=mpiicc
    export CXX=mpiicpc
    export F77=mpiifort
    export F90=mpiifort
    export FC=mpiifort
else
    export CC=mpicc
    export CXX=mpicxx
    export F77=mpif77
    export F90=mpif90
    export FC=mpif90
fi

export NETCDF=${INSTALL_DIR}
export NCEPLIBS_DIR=$INSTALL_DIR/$VER
export ESMFMKFILE=${INSTALL_DIR}/esmf-8.0.0_bs40/lib/esmf.mk
export NEMS_COMPILER=${COMP}

cd NEMSfv3gfs
FV3=$( pwd -P )/FV3
cd tests/
./compile.sh "$FV3" linux.${COMP} "NCEP64LEV=Y HYDRO=N 32BIT=Y" 1 NO NO

