#!/bin/bash

INTEL_COMP_DIR=/data/intel

##################################
#  Jenkins intel compiler
##################################

ln -sf ${INTEL_COMP_DIR} /opt/intel
source /opt/intel/compilers_and_libraries_2020/linux/bin/compilervars.sh intel64
source /opt/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/bin/mpivars.sh
export PATH="/opt/intel/bin:${PATH}"
