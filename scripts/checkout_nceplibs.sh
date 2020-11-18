#!/bin/bash

set -ex

#grib_util
git clone https://github.com/NOAA-EMC/NCEPLIBS-grib_util.git
cd NCEPLIBS-grib_util
git checkout grib_util_v1.1.1 -b temp
patch -p0 -i ../patches/nceplibs/grib_util.diff 
cd -

#g2tmpl
git clone https://github.com/NOAA-EMC/NCEPLIBS-g2tmpl.git
cd NCEPLIBS-g2tmpl
git checkout g2tmpl_v1.6.0 -b temp
patch -p0 -i ../patches/nceplibs/g2tmpl.diff 
cd -

#gfsio
git clone https://github.com/NOAA-EMC/NCEPLIBS-gfsio.git
cd NCEPLIBS-gfsio; git checkout 6cdaff1c441f58d2a8b5c9 -b temp; cd -

#bacio
git clone https://github.com/NOAA-EMC/NCEPLIBS-bacio.git
cd NCEPLIBS-bacio; git checkout 13cff73cf82aa45bbb8158 -b temp; cd -

#bufr
git clone https://github.com/NOAA-EMC/NCEPLIBS-bufr.git
#cd NCEPLIBS-bufr; git checkout  06203bec14358f99b130a -b temp; cd -
cd NCEPLIBS-bufr 
git checkout  5ee8300028479a8c76437 -b temp
patch -p0 -i ../patches/nceplibs/bufr.diff 
cd -

#g2
git clone https://github.com/NOAA-EMC/NCEPLIBS-g2.git
cd NCEPLIBS-g2
git checkout  74630183e77dd63194e77 -b temp
patch -p0 -i ../patches/nceplibs/g2.diff 
cd -

#ip
git clone https://github.com/NOAA-EMC/NCEPLIBS-ip.git
cd NCEPLIBS-ip; git checkout  87b07768883122a9b5d58 -b temp; cd -

#landsfcutil
git clone https://github.com/NOAA-EMC/NCEPLIBS-landsfcutil.git
cd NCEPLIBS-landsfcutil; git checkout  ff60eee8f56a0b178d58a -b temp; cd -

#nemsio
git clone https://github.com/NOAA-EMC/NCEPLIBS-nemsio.git
cd NCEPLIBS-nemsio; git checkout  c2c7700f9062f6c699192 -b temp; cd -

#nemsiogfs
git clone https://github.com/NOAA-EMC/NCEPLIBS-nemsiogfs.git
cd NCEPLIBS-nemsiogfs
git checkout  f94ade4703103e5b29adc6ed -b temp
patch -p0 -i ../patches/nceplibs/nemsiogfs.diff 
cd -

#sfcio
git clone https://github.com/NOAA-EMC/NCEPLIBS-sfcio.git
cd NCEPLIBS-sfcio; git checkout  e921d5b990db4e07e56e8 -b temp; cd -

#sigio
git clone https://github.com/NOAA-EMC/NCEPLIBS-sigio.git
cd NCEPLIBS-sigio; git checkout  b8faaa378530eb9f98bdb -b temp; cd -

#sp
git clone https://github.com/NOAA-EMC/NCEPLIBS-sp.git
#cd NCEPLIBS-sp; git checkout  8ca5f9a483df8dd07d367 -b temp; cd -
cd NCEPLIBS-sp
git checkout  4dc9b461a69e2a3b3b880 -b temp
patch -p0 -i ../patches/nceplibs/sp.diff 
cd -

#w3emc
git clone https://github.com/NOAA-EMC/NCEPLIBS-w3emc.git
cd NCEPLIBS-w3emc; git checkout  0296442efa1d13e2117b4 -b temp; cd -

#w3nco
git clone https://github.com/NOAA-EMC/NCEPLIBS-w3nco.git
cd NCEPLIBS-w3nco
git checkout  3729a6e1721d8843c111e -b temp
patch -p0 -i ../patches/nceplibs/w3nco.diff 
cd -

#graphics
git clone https://github.com/Hang-Lei-NOAA/NCEPLIBS-graphics.git
cd NCEPLIBS-graphics
git checkout 48f076e70a4f010d234b7 -b temp
patch -p0 -i ../patches/nceplibs/graphics.diff 
cd -

#prod_utl
git clone https://github.com/NOAA-EMC/NCEPLIBS-prod_util.git
cd NCEPLIBS-prod_util
git checkout de699056db15a49e39bc82fd -b temp
patch -p0 -i ../patches/nceplibs/prod_util.diff 
cd -

