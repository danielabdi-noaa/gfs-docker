#!/bin/bash

./patch_gfs.sh

cd global-workflow/sorc
bash ./build_all.sh
