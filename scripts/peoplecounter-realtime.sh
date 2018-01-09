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
INTERVAL=1 # how long to wait between polls
INTERVALSKIP=20 # poll with INTERVAL but only consider every INTERVALSKIP's for SAMPLES
MAXFILE="/var/cache/peoplecountermax$DEV"
PRESENCYRT="/run/presencyrt$DEV"
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
rtoldp=0
while true
do
  # scrape new value
  p="$(
    wget --tries=3 --timeout=2 -qO - "http://$PEOPLECOUNTERIP/output.cgi?t=$(date +%s)" |
    sed 's/.*Occupancy://'|
    awk '{print $2}')"
  # echo "p=$p" # debug
  if [ "$p" != "" ]  # oh we got something
  then
    oldp="$(getlastpeople)"
    skipcounter=$((skipcounter+1))
    if [ $skipcounter -gt $INTERVALSKIP ]
    then
      # echo "skipcounter expired. updating" # debug
      skipcounter=0
      addcount "$p"
      # if max then call this:
      if [ "$p" != "$oldp" ]
      then
        logger $(basename $0) changed from $oldp to $p people
        curmax=$(getmaxpeople)
        oldmax=$(cat "$MAXFILE")
        if [ "$curmax" -gt "${oldmax:-0}" ]
        then
          logger $(basename $0) setting max to $curmax because bigger than ${oldmax:-}
          echo "$curmax" > "$MAXFILE"
          chmod a+rw "$MAXFILE"
        fi
      fi
    fi
    if [ $p -gt $rtoldp ]
    then
      echo "$p" > "$PRESENCYRT"
      # echo "p($p) -gt rtoldp($rtoldp)" # debug
      for i in $(seq $((p-rtoldp))) 
      do
        logger "XP logon.wav"
        aplay '/root/win/Windows XP Logon Sound.wav' &
        sleep 0.2
      done &
    fi
    if [ $p -lt $rtoldp ]
    then
      echo "$p" > "$PRESENCYRT"
      # echo "p($p) -lt rtoldp($rtoldp)" # debug
      for i in $(seq $((rtoldp-p))) 
      do
        logger "XP logoff.wav"
        aplay '/root/win/Windows XP Logoff Sound.wav' &
        sleep 0.2
      done &
    fi
    # echo "rtoldp=$p" # debug
    rtoldp=$p

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
      $(dirname "$0")"/mkmail.py 'peoplecounter level2 online' 'peoplecounter is now reachable'
      #python -c 'import smtplib ; server = smtplib.SMTP("mail.syn2cat.lu", 25) ; msg = "Subject: peoplecounter level2 onfline\n\npeoplecounter is now reachable" ; server.sendmail("gkess@pt.lu", "gunstick@syn2cat.lu", msg) ; server.quit()'
    fi
  else
    if [ "$state" = "online" ]
    then
      state="offline"
      logger $(basename $0) people counter offline
      $(dirname "$0")"/mkmail.py 'peoplecounter level2 offline' 'peoplecounter was not reachable'
      #python -c 'import smtplib ; server = smtplib.SMTP("mail.syn2cat.lu", 25) ; msg = "Subject: peoplecounter level2 offline\n\npeoplecounter was not reachable" ; server.sendmail("gkess@pt.lu", "gunstick@syn2cat.lu", msg) ; server.quit()'

    fi
  fi
  sleep "$INTERVAL"
done
