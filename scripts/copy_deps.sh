#!/bin/bash

mkdir -p /opt/lib

cp /opt/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/lib/release_mt/libmpi.so.12 /opt/lib/
cp /opt/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/lib/libmpicxx.so.12 /opt/lib
cp /opt/intel/compilers_and_libraries_2018.0.128/linux/mpi/intel64/lib/libmpifort.so.12 /opt/lib/
cp /opt/intel/lib/intel64/libiomp5.so /opt/lib
cp /opt/intel/lib/intel64/libimf.so /opt/lib
cp /opt/intel/lib/intel64/libsvml.so /opt/lib
cp /opt/intel/lib/intel64/libirng.so /opt/lib
cp /opt/intel/lib/intel64/libintlc.so.5 /opt/lib
cp /opt/intel/lib/intel64/libifport.so.5 /opt/lib
cp /opt/intel/lib/intel64/libifcoremt.so.5 /opt/lib

cp -r /opt/intel/compilers_and_libraries_2020.0.166/linux/mpi/intel64/bin /opt

