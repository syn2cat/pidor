#!/bin/bash
LockDir="/run/$(basename "$0").run"
P() {
  while ! mkdir "$LockDir" 2>/dev/null
  do 
    echo "cannot lock $LockDir, waiting"
    LockDirStamp=$(stat -c %Y "$LockDir")
    if [ "$LockDirStamp" != "" ] && [ "$LockDirStamp" -lt $(date --date "15 seconds ago" +%s) ]
    then
      echo lock is old, deleting
      rmdir "$LockDir"
    fi
    sleep 1
  done 
  echo got lock
}
V() {
  echo "releasing $LockDir"
  rmdir "$LockDir"
}
P
echo "running protected code"
sleep 10
V
echo "end protected code"
