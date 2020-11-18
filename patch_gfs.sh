#!/bin/bash

GFSDIR=${GFSDIR:-global-workflow}

FV3DIR=${GFSDIR}/sorc/fv3gfs.fd ./patch_fv3.sh
CWD=${PWD}

cd ${GFSDIR}
patch -p0 -i ${CWD}/patches/workflow/GFS.diff
cd -

cd ${GFSDIR}/sorc/gsi.fd
if [ -d /opt/intel ]; then
patch -p0 -i ${CWD}/patches/workflow/GSI-intel.diff
else
patch -p0 -i ${CWD}/patches/workflow/GSI.diff
fi
cd -

cd ${GFSDIR}/sorc/ufs_utils.fd
patch -p0 -i ${CWD}/patches/workflow/UFS_UTILS.diff
cd -

cd ${GFSDIR}/sorc/gfs_post.fd
patch -p0 -i ${CWD}/patches/workflow/GFS_POST.diff
cd -

cd ${GFSDIR}/sorc/gldas.fd
patch -p0 -i ${CWD}/patches/workflow/GLDAS.diff
cd -

cd ${GFSDIR}/sorc/gfs_wafs.fd
patch -p0 -i ${CWD}/patches/workflow/GFS_WAFS.diff
cd -
