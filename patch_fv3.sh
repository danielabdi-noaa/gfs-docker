#!/bin/bash
set -exo pipefail

FV3DIR=${FV3DIR:-NEMSfv3gfs}

CWD=${PWD}

cd ${FV3DIR}
patch -p0 -i ${CWD}/patches/fv3gfs/NEMSfv3gfs.diff
cd FV3; patch -p0 -i ${CWD}/patches/fv3gfs/FV3.diff; cd -
cd NEMS; patch -p0 -i ${CWD}/patches/fv3gfs/NEMS.diff; cd -
cd -
