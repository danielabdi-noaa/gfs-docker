#!/bin/bash

cd NEMSfv3gfs; patch -p0 -i ../patches/NEMSfv3gfs.diff
cd FV3; patch -p0 -i ../../patches/FV3.diff
cd ../NEMS; patch -p0 -i ../../patches/NEMS.diff
