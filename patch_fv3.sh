#!/bin/bash

cd NEMSfv3gfs
patch -p0 -i ../patches/fv3gfs/NEMSfv3gfs.diff
cd FV3; patch -p0 -i ../../patches/fv3gfs/FV3.diff; cd -
cd NEMS; patch -p0 -i ../../patches/fv3gfs/NEMS.diff; cd -
cd ..
