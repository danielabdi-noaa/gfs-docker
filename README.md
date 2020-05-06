# Containers for fv3gfs

Included are scripts for generating Docker images for fv3gfs using either the GNU or Intel compiler collection.

## Requirements
Docker should be already installed on the system to generate images.
You need to have access to NEMSfv3gfs source code.

## Preparing NEMSfv3gfs

You would need to clone the NEMSfv3gfs repository from vlab and put it in the main directory.
If you have already setup gerrit for ssh clone, this is how to do it

    git clone --recursive gerrit:NEMSfv3gfs

We have made changes to the code to add new linux.intel target, make it work with Intel 19.0 etc.
Untile these are merged to the main branch, you will need to patch your freshly cloned repository with

    ./patch_fv3.sh

## Compiling

You can compile with GNU or INTEL compiler collection as follows

### GNU

Generating the GNU images is straightforward

    ./build_gnu_images.sh

This will generate three separate images for mpi+netcdf, ESMF and NEMSfv3gfs libraries.
The OS within the container is ubuntu:18.04

You can install a version of mpi you like by modifying `build_mpi.sh`

### Intel

Using Intel compiler is a bit more complicated because we chose to use the host compiler in the container as well.
Licensing issues coupled with complicated installation procedure within container make using Intel compiler
inside a container difficult. This also means the host and container OS should be the same, we use centos:8
for our purpose.

First, set the location of the intel compiler collection in `build_intel_images.sh` and `scripts/intel_comp.sh`

    INTEL_COMP_DIR=/data/intel

This directory will be mounted to the container whenever we want to compile something with icc/ifort.
Also modify other parts of `scripts/intel_comp.sh` as needed. This script will be sourced before compilation begins.

After these steps, compilation of the images is straightforward

    ./build_intel_images.sh

You can also build using Intel MPI with GNU compiler with

    COMP=gnu ./build_intel_images.sh

Though, currently this breaks down when building HDF5 (will be installed in local directory instead of /usr/local).

Also the Intel build does not work properly with OpenMP -- I suspect it is because of Intel 19.0 version that is probably
untested. You can turn off OpenMP in conf/configure.fv3.linux.intel or don't use threads in your forecasts.
   
