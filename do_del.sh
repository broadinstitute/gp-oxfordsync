#!/bin/bash
#
# script to delete promethion runs from 
#     /data/LCSET-XXXXXX/SM-YYYYYYY
#
# will only delete for real if there is a single argument: commit
#
#
# start by declaring constants
LOGDIR=/home/prom/gp-oxfordsync/logs        # directory to hold output logs of runs
DELDIR=/home/prom/gp-oxfordsync/dele        # directory to hold scripts to do actual deletions
LOGDATEFORMAT='+%Y%m%d-%H%M'                # format of the date portion of logfile names
SRC_TLD=/data                               # top level data directory
SRC_DIR_REGEX='LCSET-[0-9]+/SM-[A-Z]*'      # regexp to match direcotries to clear
MIN_DAYS=30                                 # if directory hasn't changed in this many days, delete
NEXT_DAYS=23                                # number of days old dirs must be to be candidates next week
DOM=broadinstitute.org
EMAIL_DEST=gp_longreads@$DOM,ejon@$DOM      # gets emails for problems or events
#
DELETE_SCRIPT=${DELDIR}/delete_`date $LOGDATEFORMAT`.sh
DELETE_LOG=${LOGDIR}/delete_`date $LOGDATEFORMAT`
#
# put the reamble in the script
#
touch $DELETE_SCRIPT
chmod 755 $DELETE_SCRIPT
echo "#!/bin/bash\n#\n" >> $DELETE_SCRIPT
#
# start the log file
#
echo Starting data deletion script at `date` > $DELETE_LOG
echo >> $DELETE_LOG
echo Will delete: >> $DELETE_LOG
#
# now let's make an array of all the directories that match
SYNCDIRS+=$( find $SRC_TLD -maxdepth 2 -mtime +$MIN_DAYS | egrep "$SRC_DIR_REGEX" )
#
# maybe we can parallelize here but let's start with the basics
for DIR in ${SYNCDIRS[@]}; do 
  echo $DIR >> $DELETE_LOG
  echo rm -rf $DIR >> DELETE_SCRIPT
done

if [ $1 = "commit" ]; then
  bash $DELETE_SCRIPT >> $DELETE_LOG
else
  echo \nThis is a dry run.  To actually delete the data run $DELETE_SCRIPT\n >> $DELETE_LOG
fi

# Now let's figure out what will get deleted next week

NEXTDIRS+=$( find $SRC_TLD -maxdepth 2 -mtime +$NEXT_DAYS | egrep "$SRC_DIR_REGEX" )
echo "\nNext week, the following dirs are scheduled for deletion:\n" >> $DELETE_LOG

for DIR in ${NEXTDIRS[@]}; do 
  echo $DIR >> $DELETE_LOG
done

DATE=`date`
mail -aFrom:noreply@broadinstitute.org -s "Promethion data deletion output $DATE" $EMAIL_DEST < `cat $DELETELOG`
