#!/bin/bash

GFSDIR=${GFSDIR:-global-workflow}

FV3DIR=${GFSDIR}/sorc/fv3gfs.fd ./patch_fv3.sh
CWD=${PWD}

cd ${GFSDIR}
patch -p0 -i ${CWD}/patches/workflow/GFS.diff
cd -

cd ${GFSDIR}/sorc/gsi.fd
patch -p0 -i ${CWD}/patches/workflow/GSI.diff
cd -

cd ${GFSDIR}/sorc/ufs_utils.fd
patch -p0 -i ${CWD}/patches/workflow/UFS_UTILS.diff
cd -
