#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ln -sf ${DIR}/slurm/sbatch /usr/bin/sbatch
ln -sf ${DIR}/slurm/scancel /usr/bin/scancel
ln -sf ${DIR}/slurm/squeue /usr/bin/squeue
ln -sf ${DIR}/slurm/sacct /usr/bin/sacct
ln -sf ${DIR}/slurm/sinfo /usr/bin/sinfo
ln -sf ${DIR}/slurm/srun /usr/bin/srun
