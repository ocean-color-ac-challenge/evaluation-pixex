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

# get the POIs
echo "`ciop-getparam poi | tr "," "\t"`" > $TMPDIR/poi.csv

# get the window size
window="`ciop-getparam window`"
# get the aggregation
aggregation="`ciop-getparam aggregation`"

# loop and process all MERIS products
while read pair 
do
  
  # get the run id to keep the traceability
  run="`echo $pair | cut -d ',' -f 1`"

  # get the Level 2
  l2ref="`echo $pair | cut -d ',' -f 2`"
  ciop-log "INFO" "Retrieving $l2ref from storage"
  l2="`echo $l2ref | ciop-copy -o $TMPDIR - | sed "s/.L2//"`"

  # check if the file was retrieved
  [ "$?" == "0" ] || exit $ERR_NOINPUT
 
  l2b="`basename $l2`"
  prddate="${l2b:20:2}/${l2b:18:2}/${l2b:14:4}"
 
  ciop-log "INFO" "Apply BEAM PixEx Operator to `basename $l2` of run $run with date $prddate"
set -x  
  # apply PixEx BEAM operator
  $_CIOP_APPLICATION_PATH/shared/bin/gpt.sh \
  	-Pvariable=`basename $l2`.dim \
  	-Pvariable_path=$TMPDIR \
  	-Poutput_path=$OUTPUTDIR \
  	-Pprefix=$run \
  	-Pcoordinates=$TMPDIR/poi.csv \
	-PwindowSize=$window \
	-PaggregatorStrategyType="$aggregation" \
	${_CIOP_APPLICATION_PATH}/pixex/libexec/PixEx.xml &> /tmp/`uuidgen`.log #dev/null		
  	
  res=$?
  [ $res != 0 ] && exit $ERR_BEAM
find $TMPDIR

  result="`find $OUTPUTDIR -name "$run*measurements.txt"`"
  cat "$result" |  tail -n +7 | tr "\t" "," | awk -f $_CIOP_APPLICATION_PATH/pixex/libexec/tidy.awk -v run=$run -v date=$prddate - > $TMPDIR/csv
  mv $TMPDIR/csv "$OUTPUTDIR/`basename $l2`.txt" 

  ciop-log "INFO" "Publishing extracted pixel values"
  ciop-publish -m "$OUTPUTDIR/`basename $l2`.txt"
  ciop-publish -m $TMPDIR/poi.csv
  
  # cleanup
  rm -fr $l2 $OUTPUTDIR/* 

done

exit 0
