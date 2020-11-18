# How to run global-workflow on hera using singularity

These are the steps you need to do to run GFS v16b workflow using rocoto

## Getting the image

First you need to get a copy of the docker image for the global-workflow
   
    docker pull dshawul/gfs-gnu

Then, convert the docker image to singularity image using

    singularity pull docker://dshawul/gfs-gnu

You can't do these steps directly on hera so you will have to do it on your laptop
and copy the singularity image to hera.

## Sandbox

We will extract the singularity image to a "sandbox" as it is more convienient
and faster to run and work with. The sandbox is a regular directory with all contents
of the image.

    singularity build --sandbox workflow gfs-gnu_latest.sif

The directory `workflow` contains the contents of the image, and you can find global-workflow
under `workflow/opt/global-workflow`. You can setup a test case and run forecast using
this directory in place of the raw singularity image.

## Setting environement variables

This particular image uses GNU compilers and MPICH library so we will load modules that
will work with it. Moreover, we need to set environement variables needed for running
the workflow. Here is the content of my `set_environment.sh` script I use for this purpose

    #!/bin/tcsh
    
    set COLON=':'
    setenv GFS_FIX_DIR "/scratch1/NCEPDEV/global/glopara/fix"
    setenv GFS_IMG_DIR "/scratch2/BMC/gsd-hpcs/NCEPDEV/stmp3/Daniel.Abdi/containers/workflow"
    setenv GFS_NPE_NODE_MAX 24
    setenv GFS_SING_CMD "singularity exec --bind $GFS_FIX_DIR$COLON/fix $GFS_IMG_DIR run_bash_command"
    setenv GFS_DAEMON_RUN "$GFS_IMG_DIR/opt/global-workflow/cloud/scripts/run_sing_job.sh"
    setenv GFS_DAEMON_KILL "$GFS_IMG_DIR/opt/global-workflow/cloud/scripts/kill_sing_job.sh"
    
    module use /scratch2/BMC/gsd-hpcs/bass/modulefiles/ 
    module use /scratch2/BMC/gsd-hpcs/dlibs/modulefiles/ 
    
    module purge
    module load rocoto
    module load hpss
    module load gcc/9.3.0
    module load mpich/3.3a2

Then we source this script
   
    source ./set_environment.sh

## Setting up a test case

To setup a test case, we follow the same procedure as the one used without containers.
We write a script to set paths for EXPDIR, COMROT etc. Here is an example script for the C48 test case

    BASE=/scratch2/BMC/gsd-hpcs/NCEPDEV             ## Make sure you have access to the base directory
    COMROT=$BASE/global/noscrub/$USER/fv3gfs/comrot ## default COMROT directory
    EXPDIR=$BASE/global/save/$USER/fv3gfs/expdir    ## default EXPDIR directory
    PTMP=$BASE/stmp2/$USER                          ## default PTMP directory
    STMP=$BASE/stmp4/$USER                          ## default STMP directory
    HOMEDIR=$BASE/global/$USER                      ## default HOMEDIR directory
    ACCOUNT=gsd-hpcs                                ## default ACCOUNT
    
    GITDIR=$GFS_IMG_DIR/opt/global-workflow
    #GITDIR=/opt/global-workflow
    #    ICSDIR is assumed to be under $COMROT/FV3ICS
    #         create link $COMROT/FV3ICS to point to /scratch4/BMC/rtfim/rtruns/FV3ICS
    
    
    PSLOT=c48
    IDATE=2018082700
    EDATE=2018082700
    RESDET=48               ## 96 192 384 768
    GFSCYCLE=2
    
    
    ./setup_expt_fcstonly.py --pslot $PSLOT  \
           --gfs_cyc $GFSCYCLE --idate $IDATE --edate $EDATE \
           --configdir $GITDIR/parm/config \
           --res $RESDET --comrot $COMROT --expdir $EXPDIR \
           --homedir $HOMEDIR --ptmp $PTMP --stmp $STMP --account $ACCOUNT
    
    
    #for running chgres, forecast, and post 
    ./setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

Note that the `GITDIR` variable points to the location of our sandbox for the singularity image.
Save this script as c48.sh under `$GFS_IMG_DIR/opt/global-workflow/ush/rocoto`.

## Generating the test case directories and setting up a run

Run the c48.sh script to generate the directories and scripts needed for running the C48 workflow.
Under our experiment directory, we find a bunch of scripts sourced during the run.
We will modify a couple of them to fit our needs

### config.base

Set LEVS to 65 instead of 128. The new default of LEVS=128 does not work properly for some reason

    export LEVS=65

You can set the hours of forecast and write interval, e.g. for 3 hrs fcst 

    export FHMAX_GFS_00=3
    export FHMAX_GFS_06=3
    export FHMAX_GFS_12=3
    export FHMAX_GFS_18=3
   
    export FHOUT_GFS=3

Comment out or set to .false. the inline postprocessing option
   
    export WRITE_DOPOST=".false."

Set to NO wave processing, and optionally gldas
 
    export DO_GLDAS=NO
    export DO_WAVE=NO

### config.fv3

Here is where you control the number of mpi ranks and threads for your test case
if you so wish. Usually leave it to default.

Just as an example, to run C48 with as low as 6 mpi ranks, modify as follows

    export layout_x=1
    export layout_y=1
    export layout_x_gfs=1
    export layout_y_gfs=1

To use just 1 mpi rank for writing output

    export WRITE_GROUP=1
    export WRTTASK_PER_GROUP=1
    export WRITE_GROUP_GFS=1
    export WRTTASK_PER_GROUP_GFS=1

### config.fcst

There is a variable defined here for `io_layout` that you may need to turn off in some cases
This is a new additon in v16b and may already have been removed in other branches of GFS.

    #export io_layout=4,4

### the rocoto xml file, c48.xml

Edit lines like below to modify the number of nodes, processors per node, threads per process

    <!ENTITY RESOURCES_FCST_GFS "<nodes>1:ppn=40:tpp=1</nodes>">

## Running the test case

Now that the test case is setup we can run different steps of the workflow using rocoto.
There is no difference between running GFS on hera with or without containers

For a forecast only run, make sure you have FV3ICS directory under $COMROT.

To run specific steps of the workflow, run rocotoboot under the $EXPDIR as follows

    rocotoboot -v 10 -w c48.xml -d c48.db -c all -t gfsfv3ic
    rocotoboot -v 10 -w c48.xml -d c48.db -c all -t gfsfcst
    rocotoboot -v 10 -w c48.xml -d c48.db -c all -t gfspost001

Log files for your runs are stored under $COMROT/c48/logs, so you can investigate there
if something goes wrong.
   


