#!/bin/bash
set -exo pipefail

export COMP=${COMP:-gnu}

#install directory and compiler flag
INSTALL_DIR=/usr/local
SRC_DIR=/opt
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALL_DIR/lib

#use make
ln -sf /usr/bin/make /usr/bin/gmake

##############
# Compiler
##############

if [ "$COMP" = "intel" ]; then
   FC=ifort
   CC=icc
   FCOMP=mpiifort
else
   FC=gfortran
   CC=gcc
   FCOMP=mpif90
fi

################################
# libjasper
################################
cd $SRC_DIR && git clone https://github.com/mdadams/jasper.git && \
    cd jasper && \
    mkdir -p mybuild && \
    cmake -G "Unix Makefiles" -H./ -B./mybuild -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} && \
    cd mybuild && make clean all && make install && \
    cd ../.. && \
    rm -fr jasper

#############################################################
# Compile NCEP libraries needed for gfs. Clone the required 
# reposistories from https://vlab.ncep.noaa.gov
#############################################################

# g2tmpl
cd $SRC_DIR && git clone https://github.com/Hang-Lei-NOAA/NCEPLIBS-g2tmpl.git && \
    cd NCEPLIBS-g2tmpl && \
    git checkout master && \
    mkdir -p ${INSTALL_DIR}/g2tmpl/v1.5.0 && \
    ./build_g2tmpl.sh gnu_general prefix=${INSTALL_DIR}/g2tmpl/v1.5.0 build install && \
    cd .. && \
    rm -fr NCEPLIBS-g2tmpl

#bufr
cd ${SRC_DIR}/NCEPLIBS-bufr/src && COMP=${COMP} ./makebufrlib.sh && cd ../..

#bacio
cd ${SRC_DIR}/NCEPLIBS-bacio && ./make_bacio_lib.sh ${FC}.setup && cd ..

#ip 
cd ${SRC_DIR}/NCEPLIBS-ip && ./make_ip_lib.sh ${FC}.setup && cd ..

#landsfcutil
cd ${SRC_DIR}/NCEPLIBS-landsfcutil && ./make_landsfcutil_lib.sh ${FC}.setup && cd ..

#sfcio
cd ${SRC_DIR}/NCEPLIBS-sfcio && ./make_sfcio_lib.sh ${FC}.setup && cd ..

#sigio
cd ${SRC_DIR}/NCEPLIBS-sigio && ./make_sigio_lib.sh ${FC}.setup && cd ..

#nemsio
cd ${SRC_DIR}/NCEPLIBS-nemsio/src && VER="v2.2.4" FCOMP=${FCOMP} LIBDIR=../ make && cd ..

#nemsiogfs
cd ${SRC_DIR}/NCEPLIBS-nemsiogfs/src && \
   VER="v2.2.0" FCOMP=${FCOMP} FCFLAGS="-O3 -I${SRC_DIR}/NCEPLIBS-nemsio/nemsio_v2.2.4" LIBDIR=../ make && cd ..

#w3emc
cd ${SRC_DIR}/NCEPLIBS-w3emc && \
    SIGIO_INC4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/incmod/sigio_v2.1.0 \
    SIGIO_LIB4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/libsigio_v2.1.0.a \
    NEMSIO_INC=${SRC_DIR}/NCEPLIBS-nemsio/nemsio_v2.2.4 \
    NEMSIO_LIB=${SRC_DIR}/NCEPLIBS-nemsio/libnemsio_v2.2.4.a \
    ./make_w3emc_lib.sh ${FC}.setup && cd ..

#w3nco
cd ${SRC_DIR}/NCEPLIBS-w3nco && \
    SIGIO_INC4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/incmod/sigio_v2.1.0 \
    COMP=${COMP} ./makelibw3_nco.sh  && cd ..

#sp 
cd ${SRC_DIR}/NCEPLIBS-sp && COMP=${COMP} ./makelibsp.sh_Linux && cd ..

#g2 
cd ${SRC_DIR}/NCEPLIBS-g2 && COMP=${COMP} source ./modulefiles/g2.linux \
	&& cd src && COMP=${COMP} bash ./makeg2lib_linux.sh && cd ..

#prod_util
cd ${SRC_DIR}/NCEPLIBS-prod_util/sorc && \
   cd fsync_file.cd && CC=${CC} make && cd .. && \
   cd mdate.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd ndate.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd nhour.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd ../../

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
    yes | ./make_ncep_libs.sh -s linux -c ${COMP} -d ${INSTALL_DIR}/${VER} -o 0 && \
    cd .. && \
    rm -fr ${VER}

##############
# CRTM
##############
cd ${SRC_DIR}/CRTM-2.3.0 && \
    /bin/bash -c "source config-setup/${FC}.setup" && \
    ./configure \
       --disable-big-endian \
       --prefix=${PWD} && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install

##############
# GEMPAK7
##############
cd $SRC_DIR && git clone https://github.com/Unidata/gempak.git GEMPAK7 && \
    cd GEMPAK7 && sed -i 's,^NAWIPS=.*,NAWIPS='"${SRC_DIR}"'\/GEMPAK7,g' Gemenviron.profile && \
    export NA_OS=linux64_gfortran && \
    . ./Gemenviron.profile && make everything && cd ..

#graphics
cd ${SRC_DIR}/NCEPLIBS-graphics/v2.0.0/src && \
   GFS_LIBS_DIR=/opt COMP=${COMP} ./compile_all_graphics_lib_wcoss.sh linux && cd ../../../

