#!/bin/bash
exec 2>/tmp/out.log
set -x
PATH=/bin:/usr/bin
mkdir /run/dhcp-leases 2>/dev/null
while read l
do
  ip="$(echo "$l" |
    fgrep Address-Request|
    fgrep "10.2.113" |
    sed 's/^.* //')"
  if [ "$ip" != "" ]
  then
    t=$(date +%s)
    if [ -f "/run/dhcp-leases/$ip" ]
    then
      touch "/run/dhcp-leases/$ip"
    else
      logget -t $(basename $0) "new dhcp for $ip"
      echo "$t" > "/run/dhcp-leases/$ip" 
    fi
    echo "========== $t $ip" >> /tmp/out.log
  fi
done
