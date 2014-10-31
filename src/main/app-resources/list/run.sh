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
while read pair
do
  run="`echo $pair | cut -d ";" -f 1`"
  metalink="`echo $pair | cut -d ";" -f 2`"
  # report activity in log
  ciop-log "INFO" "Listing $run"

  curl -L $metalink | xsltproc /application/list/xsl/metalink.xsl - | while read result
  do 
  	echo "$run,$result" | ciop-publish -s  
  done

done

exit 0

