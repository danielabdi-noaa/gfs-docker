#!/bin/sh

# prepares job by exporting all enviornement variables to a file
function prep_job {
   set +x
   cat /dev/null >$PWD/.envr;
   SIFS=$IFS;
   IFS=$'\n'
   for i in `printenv`; do
      if [[ "$i" = *=* ]] && [[ ! "$i" = *\(* ]] && [[ ! "$i" = *\"* ]] &&  \
         [[ ! "$i" = *PATH=* ]] && [[ ! "$i" = *LD_LIBRARY_PATH* ]]; then
         j=`echo $i | awk -F'=' '{print $1"=\""$2"\""}'`
         echo export $j >>$PWD/.envr
      fi
   done;
   IFS=$SIFS
   set -x
}

# Wait until we get a signal job has finished running on host
function post_job {
   if [ $VERBOSE = "YES" ] ; then
       echo "Waiting for job to finish."
       set +x
   fi

   while [ -s ${HOME}/.servinp ]; do sleep 1; done

   if [ $VERBOSE = "YES" ] ; then
       cat ${HOME}/.output.log
       echo "Job finished."
       set -x
   fi;

   $( exit `tail -1 ${HOME}/.output.log` )
}

# run job
function run_command {
   if [ -z $GFS_SING_CMD ]; then
      eval "$@"
   else
      echo "$@" >${PWD}/.command
      
      prep_job
      echo "cd $PWD; source ./.envr; sh ./.command" >${HOME}/.servinp
      post_job
   fi
}
