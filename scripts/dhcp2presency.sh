#!/bin/bash
n=0
for i in $(ls /run/dhcp-leases/)
do
  if ping -qc 1 -W 1 "$i" >/dev/null
  then
    touch "/run/dhcp-leases/$ip"
    n=$((n+1))
  else
    logger -t $(basename $0) "dhcp $i is not pingable anymore"
    if [ $(stat -c %Y /run/dhcp-leases/$i) -lt $(date --date "1 hour ago" +%s) ]
    then
      logger -t $(basename $0) "removing dhcp $i after one hour"
      rm /run/dhcp-leases/$i
    fi
  fi
done
echo "$n" > /run/presency
