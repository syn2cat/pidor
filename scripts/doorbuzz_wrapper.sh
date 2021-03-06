#!/bin/bash
# put into /root/.ssh/authorized_keys this:
# command="/root/pidor/scripts/doorbuzz_wrapper.sh" ssh-rsa AAAAB3.......................7fEbKbG2UcaO4d0YZ67T pi@doorbuzz

while read cmd
do
  if [ "$cmd" = "spacestatus" ]
  then
    cat /var/run/spacestatus
  fi
  if [ "$cmd" = "peoplecounter" ]
  then
    tail -1 /run/presencyrt
  fi
  
  if [ "$cmd" = "flashon" ]
  then
    logger -t $(basename $0) "phone status change detected"
    logger -t $(basename $0) "phone ring light on"
    $(dirname "$0")/lightcommander alarm on >&2
    sleep 20   # make sure it switches off some time
    $(dirname "$0")/lightcommander alarm off >&2
    #/usr/local/bin/433send 2 15 1 1 >&2
  fi
  
  if [ "$cmd" = "flashoff" ]
  then
    logger -t $(basename $0) "phone status change detected"
    logger -t $(basename $0) "phone ring light off"
    $(dirname "$0")/lightcommander alarm off >&2
    #/usr/local/bin/433send 2 15 1 0 >&2
  fi
done
