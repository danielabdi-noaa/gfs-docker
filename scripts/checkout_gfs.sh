#!/bin/bash

git clone --recursive https://github.com/NOAA-GSD/global-workflow.git
cd global-workflow
git checkout feature/linux-target
cd sorc
bash ./checkout.sh
cd ../..

