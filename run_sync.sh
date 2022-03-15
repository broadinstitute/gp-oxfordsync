#!/bin/bash
#
# script to sync promethion runs from 
#     /data/LCSET-XXXXXX/SM-YYYYYYY
# to
#     xfer.broadinstitute.org:/seq/gp_ont
#
# start by declaring constants
XFER_HOST=xfer.broadinstitute.org           # remote host for rsync
XFER_USER=gplongreads                       # account to auth on remote host
XFER_KEY=/home/prom/.ssh/datasync           # ssh private key for XFER_USER
LOCK_FILE=/home/prom/gp-oxfordsync/runcount # file to retain state/prevent concurrency
LOGDIR=/home/prom/gp-oxfordsync/logs        # directory to hold output logs of runs
SRC_TLD=/data                               # top level data directory
DST_TLD=/seq/gp_ont                         # directory to sync to on remote host
SRC_DIR_REGEX='LCSET-[0-9]+/SM-[A-Z]*'      # regexp to match direcotries to sync
MAX_DAYS=7                                  # if directory hasn't changed in this many days, skip
EMAIL_DEST=gp_longreads@broadinstitute.org  # gets emails for problems or events
#
# start by verifying whether this job is already running
#
if [ -e $LOCK_FILE ]; do # a lock file is there but is it really running?
  pid=`ps -ef | grep run_sync | awk '{print $1}'`
  if [ -n $pid ]; then # yeah, really running
    typeset -i count
    count=`cat $LOCK_FILE`
    count+=1
    if [ $count -gt 5 ]; then # someone's been running a while!
      mail -s "Promethion data sync seems stuck!" $EMAIL_DEST
      echo $count > $LOCK_FILE
      exit 2
    fi
  else #not really running, but I'll wait until next time
    rm $LOCK_FILE
    exit 1
  fi
#
# we're good to go
#   - first note that we are starting
echo 0 > $LOCK_FILE
typeset -i ERROR=0 # number of failed transfers
#
# now let's make an array of all the directories that match
SYNCDIRS+=$( find $SRC_TLD -maxdepth 2 -mtime -$MAXDAYS | egrep "$SRC_DIR_REGEX" )
#
TOPLOG=controller_`date "+%Y%m%d-$h$M"`
echo Starting master sync > $LOGDIR/$TOPLOG
echo Dirs to sync: $SYNCDIRS >> $LOGDIR/$TOPLOG
#
# maybe we can parallelize here but let's start with the basics
for DIR in ${SYNCDIRS[@]}; do 
  THISLOG=dirsync_`echo $DIR | awk -F/ '{print $(NF-1)"_$NF}'`_`date "+%Y%m%d-$h$M"`
  rsync --rsh="ssh -i $XFER_KEY " -nav $DIR $XFER_USER@$XFER_HOST:$DST_TLD/ > $LOGDIR/$THISLOG 2>&1
  if [ $? ]; then
    echo Transfer of $DIR appears to have completed successfully >> $LOGDIR/$TOPLOG
  else
    echo Transfer of $DIR appears to have failed.  Please review >> $LOGDIR/$TOPLOG
    echo Log file at $LOGDIR/$THISLOG >> $LOGDIR/$TOPLOG
    ERROR+=1
  fi
done

echo A total of $ERROR transfers failed of ${#SYNCDIRS[@]} attempted >> $LOGDIR/$TOPLOG
