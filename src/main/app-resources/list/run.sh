#!/bin/bash

# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_NOINPUT=1

# add a trap to exit gracefully
function cleanExit ()
{
   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)      msg="Processing successfully concluded";;
     $ERR_NOPARAMS) msg="Expression not defined";;
     $ERR_BEAM)    msg="Beam failed to process product $product (Java returned $res).";;
     *)             msg="Unknown error";;
   esac
   [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
   exit $retval
}
trap cleanExit EXIT

# loop and process all MERIS products
while read run
do
  # report activity in log
  ciop-log "INFO" "Listing $run"

  hadoop dfs -ls hdfs://10.16.10.45:8020/tmp/sandbox/run/$run/_results/  | grep "/tmp/" | awk '{print $8 }' | while read result
  do 
  	echo "$run,$result" | ciop-publish -s  
  done

done

exit 0

