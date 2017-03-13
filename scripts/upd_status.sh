#!/bin/bash
sleep 5
IGNORE_DOORLOCKBUTTON="no"
LockDir="/run/$(basename "$0").run"
spaceapikey="$(cat "$(dirname $0)"/spaceapikey.txt)"
P() {
  while ! mkdir "$LockDir" 2>/dev/null
  do 
    LockDirStamp=$(stat -c %Y "$LockDir" 2>/dev/null)
    if [ "$LockDirStamp" != "" ] && [ "$LockDirStamp" -lt $(date --date "300 seconds ago" +%s) ]
    then
      rmdir "$LockDir"
      logger -t $(basename $0) "$$ deleting stale semaphore dir $LockDir"
    fi
    sleep 1
  done 
}
V() {
  rmdir "$LockDir" 2>/dev/null
  if [ $? -ne 0 ]
  then
    logger -t $(basename $0) "$$ semaphore dir $LockDir disappeared while running"
  fi
}
P
if [ ! -f /run/spacestatus ]    # self initilizing on new install or boot
then
  if [ -f /root/var/spacestatus ]
  then              # we could also get it from spaceapi, so that could should go here:
    logger -t $(basename $0) "$$ boot detected, restoring spacestatus to $(cat /root/var/spacestatus)"
    cp -p /root/var/spacestatus /run/spacestatus   # restore from backup
  else
    logger -t $(basename $0) "$$ never run before (new install?) setting spacestatus to closed"
    echo "closed" > /run/spacestatus
    echo "closed" > /root/var/spacestatus
  fi
  chown www-data /run/spacestatus
fi

status="$(cat /run/spacestatus)"
oldstatus="$(cat /root/var/spacestatus)"
if [ "$oldstatus" = "" ]
then
  oldstatus="$status"
fi
doorlockbutton="$(cat /run/doorlockbutton)"
nai=$(stat -c "%Y" /run/spacestatus)    # get mtime as status change time
if [ "$status" = "open" ]
then
  /usr/bin/curl --max-time 1 --silent --data key="$spaceapikey" --data-urlencode sensors='{"state":{"open":true,"lastchange":'"$nai"'}}' https://spaceapi.syn2cat.lu/sensor/set
  #logger -t $(basename $0) "$$ sending status $status to spacapi ret=$?"
fi
for plugin in $(ls "$0".d)
do
  if [ -x "$0".d/"$plugin" ]
  then
    "$0".d/"$plugin" "$status" "$oldstatus"
    logger -t $(basename $0) "$$ called $plugin '$status' '$oldstatus'. ret=$?"
  fi
done

if [ "$status" = "closed" ] && ( 
  [ "$IGNORE_DOORLOCKBUTTON" = "yes" ] || [ "$doorlockbutton" = "pushed" ] )
then
  # problem: if closing state but not actually shuting door for a longer time, the status in spaceapi
  # will be the time of closing but not that of actually shutting the door
  # but the status will only be updated once the door is shut
  /usr/bin/curl --max-time 1 --silent --data key="$spaceapikey" --data-urlencode sensors='{"state":{"open":false,"lastchange":'"$nai"'}}' https://spaceapi.syn2cat.lu/sensor/set
  #logger -t $(basename $0) "$$ sending status $status to spacapi ret=$?"
fi

if [ $nai -ne $(stat -c "%Y" /root/var/spacestatus) ]   # backup file in case it changed
then
  cp -p /run/spacestatus /root/var/spacestatus
  logger -t $(basename $0) "$$ spacestatus changed, saving to SD. ret=$?" 
fi
presency=$(cat /run/presency)
if [ "$status" = "closed" ]
then
  presency=0
fi
/usr/bin/curl --max-time 1 --silent --data key="$spaceapikey" --data-urlencode sensors='{"sensors":{"people_now_present":[{"value":'"$presency"'}]}}' https://spaceapi.syn2cat.lu/sensor/set
V
