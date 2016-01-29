#!/bin/bash
PEOPLECOUNTERIP=$(cat $(dirname "$0")"/peoplecounterip.txt")
# we now have a people counter
p="$(
 wget -qO - "http://$PEOPLECOUNTERIP/output.cgi?t=$(date +%s)" |
 sed 's/.*Occupancy://'|
 awk '{print $2}')"
if [ "$p" != "" ]
then
  :
  #  echo "$p" > /run/presency # handled now in realtime code
else
  logger $0 cannot access people counter. fallback to dhcp value guessing
fi
n=0
for i in $(ls /run/dhcp-leases/)
do
  if ping -qc 1 -W 1 "$i" >/dev/null
  then
    if [ $(cat "/run/dhcp-leases/$i") -gt $(date --date yesterday +%s) ]
    then
      touch "/run/dhcp-leases/$i"
      n=$((n+1))
    fi
  else
    logger -t $(basename $0) "dhcp $i is not pingable anymore"
    if [ $(stat -c %Y /run/dhcp-leases/$i) -lt $(date --date "1 hour ago" +%s) ]
    then
      logger -t $(basename $0) "removing dhcp $i after one hour"
      rm /run/dhcp-leases/$i
    fi
  fi
done
if [ "$p" = "" ]  # write DHCP count if people counter offline
then
  echo "$n" > /run/presency
fi
