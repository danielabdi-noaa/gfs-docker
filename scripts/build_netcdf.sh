#!/bin/bash

set -ex

export COMP=${COMP:-gnu}

#install directory and compiler flag
INSTALL_DIR=${INSTALL_DIR:-/usr/local}
SRC_DIR=${SRC_DIR:-/opt}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${INSTALL_DIR}/lib

################################
# COMPILER flags
################################

if [ "$COMP" = "intel" ]; then

export ICCCOMP=icc
export ICXXCOMP=icpc
export IFCCOMP=ifort
export CCCOMP=mpiicc
export CXXCOMP=mpiicpc
export FCCOMP=mpiifort
export F77COMP=mpiifort

export CFLAGS='-O3 -xHost -ip -fpic'
export CXXFLAGS='-O3 -xHost -ip -fpic'
export FCFLAGS='-O3 -xHost -ip -fpic'
export F77FLAGS='-O3 -xHost -ip -fpic'
export LDFLAGS='-O3 -xHost -ip -fpic'

else

export ICCCOMP=gcc
export ICXXCOMP=g++
export IFCCOMP=gfortran
export CCCOMP=mpicc
export CXXCOMP=mpicxx
export FCCOMP=mpif90
export F77COMP=mpif77

export CFLAGS='-O3 -march=native -finline-functions -fPIC'
export CXXFLAGS='-O3 -march=native -finline-functions -fPIC'
export FCFLAGS='-O3 -march=native -finline-functions -fPIC'
export F77FLAGS='-O3 -march=native -finline-functions -fPIC'
export LDFLAGS='-O3 -march=native -finline-functions -fPIC'

fi

################################
# NETCDF
################################


#zlib-1.2.11.tar.gz
PP=zlib-1.2.11
    cd $SRC_DIR && wget --no-check-certificate https://www.zlib.net/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$CCCOMP ./configure --prefix=${INSTALL_DIR} 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

#szip-2.1.1.tar.gz
PP=szip-2.1.1
    cd $SRC_DIR && wget --no-check-certificate https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$CCCOMP ./configure --prefix=${INSTALL_DIR} 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

#hdf5-1.8.21.tar.gz
PP=hdf5-1.8.21
    cd $SRC_DIR && wget --no-check-certificate http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$CCCOMP FC=$FCCOMP F9X=$FCCOMP CXX=$CXXCOMP \
    LDFLAGS+=" -L${INSTALL_DIR}/lib" \
    ./configure \
        --enable-parallel \
        --enable-production \
        --enable-fortran \
        --enable-shared \
        --enable-static \
        --with-szlib=${INSTALL_DIR} \
        --with-zlib=${INSTALL_DIR} \
        --prefix=${INSTALL_DIR} 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

#parallel-netcdf-1.8.1.tar.gz
PP=parallel-netcdf-1.8.1
    cd $SRC_DIR && wget --no-check-certificate http://cucis.ece.northwestern.edu/projects/PnetCDF/Release/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$ICCCOMP  CXX=$ICXXCOMP  FC=$IFCCOMP \
    MPICC=$CCCOMP MPICXX=$CXXCOMP MPIF77=$F77COMP MPIF90=$FCCOMP \
    LDFLAGS+=" -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-fortran \
        --enable-largefile \
        --disable-large-file-test 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

#netcdf-4.6.1.tar.gz
PP=netcdf-4.6.1
cd $SRC_DIR && wget --no-check-certificate https://www.unidata.ucar.edu/downloads/netcdf/ftp/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$CCCOMP \
    LDFLAGS+=" -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-netcdf-4 \
        --enable-parallel-tests \
        --disable-dap \
        --enable-cdf5 \
        --disable-large-file-tests \
        --enable-shared \
        --enable-static \
        --enable-parallel4 \
        --enable-pnetcdf 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

#netcdf-fortran-4.4.4.tar.gz
PP=netcdf-fortran-4.4.4
cd $SRC_DIR && wget --no-check-certificate https://www.unidata.ucar.edu/downloads/netcdf/ftp/$PP.tar.gz && \
    tar -xvf $PP.tar.gz && \
    cd $PP && \
    CC=$CCCOMP CFLAGS+=" -I${INSTALL_DIR}/include" \
    FC=$FCCOMP FCFLAGS+=" -I${INSTALL_DIR}/include" \
    F77=$F77COMP F77FLAGS+=" -I${INSTALL_DIR}/include" \
    LDFLAGS+=" -L${INSTALL_DIR}/lib -lhdf5 -lhdf5_hl -lsz -lz" \
    ./configure \
        --enable-parallel-tests \
        --prefix=${INSTALL_DIR} 2>&1 | tee log.config && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install && \
    cd .. && \
    rm -fr $PP $PP.tar.gz

