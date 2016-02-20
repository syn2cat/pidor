#!/bin/bash
#update peoplecounter number in realtime
#but: this is too intrusive. should only update when the count of 
# people has not changed for a certain time
if [ "$(basename $0)" = "peoplecounter-realtime-dev.sh" ]
then  # switch between dev and prod config dynamically by script name
  DEV="-dev" 
else
  DEV=""
fi
STATSFILE="/run/peoplecounter$DEV"
SAMPLES=20 # how many records to keep in file
INTERVAL=10 # how long to wait between polls
MAXFILE="/root/var/peoplecountermax$DEV"
PRESENCY="/run/presency$DEV"   # value shown on website
# /run/peoplecounter lists all recent reads, newest at end
# let's have some management functions instead of a database
if [ ! -f "$STATSFILE" ]
then
  touch "$STATSFILE"
fi
function getmaxpeople() {
  awk 'BEGIN {v=0}
       $1 > v {v=$1}
       END {print v}' "$STATSFILE"
}
function getaveragepeople() {
  awk 'BEGIN {t=n=0}
        {t+=$1
         n++}
       END {print int(t/n+0.4)}' "$STATSFILE"
}
function getlastpeople() {
  awk 'BEGIN{v=0}
        {v=$1}
       END{print v}' "$STATSFILE"
}
function addcount() {
  awk -v new="$1" -v samples="$SAMPLES" -v stats="$STATSFILE" '
    BEGIN{n=0}
      {p[++n]=$1}
    END{
        p[++n]=new
        n++   # yes you can do off by 1 errors in awk
        start=n-samples
        if(start<1) {start=1}
        for(i=start;i<n;i++) {
          print p[i] > stats  # welcome to awk world
        }
       }
  ' "$STATSFILE"
}
PEOPLECOUNTERIP=$(cat $(dirname "$0")"/peoplecounterip.txt")
state="online"
while true
do
  # scrape new value
  p="$(
    wget -qO - "http://$PEOPLECOUNTERIP/output.cgi?t=$(date +%s)" |
    sed 's/.*Occupancy://'|
    awk '{print $2}')"
  if [ "$p" != "" ]  # oh we got something
  then
    oldp="$(getlastpeople)"
    addcount "$p"
    if [ "$p" != "$oldp" ]
    then
      logger $(basename $0) changed from $oldp to $p people
      curmax=$(getmaxpeople)
      oldmax=$(cat "$MAXFILE")
      if [ "$curmax" -gt "${oldmax:-0}" ]
      then
        logger $(basename $0) setting max to $curmax because bigger than ${oldmax:-}
        echo "$curmax" > "$MAXFILE"
      fi
    fi
    oldaverage="$(cat "$PRESENCY")"
    newaverage=$(getaveragepeople)
    #logger $(basename $0) averages o=$oldaverage n=$newaverage
    if [ "$oldaverage" != "$newaverage" ]
    then
      logger $(basename $0) updated precency average from $oldaverage to $newaverage people
      echo "$newaverage" > "$PRESENCY"
    fi
    if [ "$state" = "offline" ]
    then
      state="online"
      logger $(basename $0) people counter online
    fi
  else
    if [ "$state" = "online" ]
    then
      state="offline"
      logger $(basename $0) people counter offline
    fi
  fi
  sleep "$INTERVAL"
done
