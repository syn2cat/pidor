#!/bin/bash
#update peoplecounter number in realtime
#but: this is too intrusive. should only update when the count of 
@ people has not changed for a certain time
PEOPLECOUNTERIP=$(cat $(dirname "$0")"/peoplecounterip.txt")
state="online"
while true
do
  p="$(
    wget -qO - "http://$PEOPLECOUNTERIP/output.cgi?t=$(date +%s)" |
    sed 's/.*Occupancy://'|
    awk '{print $2}')"
  if [ "$p" != "" ]
  then
    oldp="$(cat /run/peoplecounter)"
    echo "$p" > /run/peoplecounter
    if [ "$p" != "$oldp" ]
    then
      logger $0 changed from $oldp to $p people
    fi
    if [ "$state" = "offline" ]
    then
      state="online"
      logger $0 people counter online
    fi
  else
    if [ "$state" = "online" ]
    then
      state="offline"
      logger $0 people counter offline
    fi
  fi
  sleep 10
done
