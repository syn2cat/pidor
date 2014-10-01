#!/bin/bash
if [ "$(awk -W version 2>/dev/null|awk '{print $1;exit}')" != "GNU" ]
then
  echo "do 'apt-get install gawk' for this to work"
  exit 1
fi
export PATH=/bin:/usr/bin:/usr/sbin
arps="$( (cat /root/arps.txt     # get old list
          arp -an|               # get current values
          awk -F'[().: ]' '/10.2.113/ && $6 > 100 && !/incomplete/'|   # only our subnet and only addresses above 100
          awk -v now=$(date +%s) '{print $4 " " now}') |               # write them with current timestamp
          awk '{arps[$1]=arps[$1]" "$2}
               END {
                 for(i in arps) {
                   split(arps[i],a)
                   asort(a)
                   print i " " a[1] " " a[length(a)]     # write out mac, oldest seen and newest seen
                 }
               }'|
          sort -k2 |             # sort by timestamp, newest first
          sort -u -k1,1 )"       # remove duplicate arp (keeps the most recent entry by timestamp)
# echo "$arps" | sort -n -k2| awk -v onehour=$(date --date="1 hour ago" +%s) '{print $0 " " $3-onehour};c==1 && (($3 - $2)<3600*24) && ($3 > onehour) {n+=1;print "->"$0}
Current="$(
(date --date="1 hour ago" +"CURRENT: %s"
 echo "$arps" )|
sort -n -k2|
awk 'c==1 && (($3 - $2)<3600*10) && ($3 > c) {n+=1}
     /CURRENT:/{c=1}
     END{print n}'
)"
Current="$(
  echo "$arps" |
  sort -n -k2|
  awk -v onehour=$(date --date="1 hour ago" +%s) '
    $3 > onehour {print $0 " " $3-$2}
    '  |
  awk '$3-$2 < 24*3600' |
  wc -l
)"
echo "$arps" > /root/arps.txt
oldCurrent="$(cat /run/presency)"
echo "$Current" > /run/presency
if [ "$Current" != "$oldCurrent" ]
then
  logger -t $(basename $0) "there are now $Current people in Level2"
fi
