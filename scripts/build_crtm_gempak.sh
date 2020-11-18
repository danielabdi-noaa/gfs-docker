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
else
   FC=gfortran
fi

##############
# CRTM
##############

VER=2.3.0

cd $SRC_DIR

# From github - /fix files need git-lfs
#git clone https://github.com/NOAA-EMC/JCSDA_CRTM.git
#cd JCSDA_CRTM; git checkout release/REL-2.3.0; cd -
#mv JCSDA_CRTM CRTM-2.3.0

# From tarball
PP=crtm_v${VER}.tar.gz
LNK="https://ftp.emc.ncep.noaa.gov/jcsda/CRTM/REL-${VER}/crtm_v${VER}.tar.gz"
wget ${LNK}
tar -xvf ${PP}
mv REL-${VER} CRTM-${VER}
rm -rf ${PP}
cd CRTM-${VER}
patch -p0 -i ../patches/nceplibs/crtm.diff
cd ..

#Build
cd ${SRC_DIR}/CRTM-${VER} && \
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
