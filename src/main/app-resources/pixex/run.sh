#!/bin/bash

# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_NOINPUT=1
ERR_BEAM=2
ERR_NOPARAMS=5

# add a trap to exit gracefully
function cleanExit ()
{
   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)      msg="Processing successfully concluded";;
     $ERR_NOPARAMS) msg="Expression not defined";;
     $ERR_BEAM)    msg="BEAM failed to process product $product (Java returned $res).";;
     *)             msg="Unknown error";;
   esac
   [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
   exit $retval
}
trap cleanExit EXIT

# get the points
:

# create the output folder to store the output products
mkdir -p $TMPDIR/output
export OUTPUTDIR=$TMPDIR/output

# loop and process all MERIS products
while read pair 
do
  # get the run id to keep the traceability
  run="`echo $pair | cut -d ',' -f 1`"

  # get the Level 2
  l2ref="`echo $pair | cut -d ',' -f 2 | ciop-copy -o $TMPDIR -`"
  ciop-log "INFO" "Retrieving $l2ref from storage"
  l2="`echo $l2ref | ciop-copy -o $TMPDIR -`"

  # check if the file was retrieved
  [ "$?" == "0" -a -e "$retrieved" ] || exit $ERR_NOINPUT
  
  ciop-log "INFO" "Apply BEAM PixEx Operator to `basename $l2`"

  # apply PixEx BEAM operator
  $_CIOP_APPLICATION_PATH/shared/bin/gpt.sh \
  	-Pvariable=`basename $l2` \
  	-Pvariable_path=$TMPDIR \
  	-Poutput_path=$OUTPUTDIR \
  	-Pprefix=$run \
  	-Pcoordinates=$TMPDIR/placemark.xml \
  	${_CIOP_APPLICATION_PATH}/pixex/libexec/PixEx.xml &> /dev/null		
  	
  res=$?
  [ $res != 0 ] && exit $ERR_BEAM
  
  ciop-log "INFO" "Publishing extracted pixel values"
  ciop-publish -m $OUTPUTDIR/*
  
  # cleanup
  rm -fr $l2 $OUTPUTDIR/* 

done

exit 0
