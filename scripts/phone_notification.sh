#!/bin/bash

url=http://$(cat $(dirname "$0")"/phoneip.txt")
run_file="/var/run/phone_ringing_status"
new_status=0
old_status=0
while true
do
  sleep 1
  if ! [ "$(cat /var/run/spacestatus)" = "open" ]; then
	continue
  else
    if ! [ -e "$run_file" ]; then
        touch $run_file
    fi

    curl -q "$url" 2>/dev/null | grep Ringing
    new_status=$?
    old_status=$(cat ${run_file})

    if [ "$new_status" -eq "$old_status" ]; then
        continue
    fi
    logger -t $(basename $0) "phone status change detected"
    if [ "$new_status" -eq 0 ]; then
	logger -t $(basename $0) "phone ring light on"
        $(dirname "$0")/lightcommander alarm on
        #/usr/local/bin/433send 2 15 1 1
    else
	logger -t $(basename $0) "phone ring light off"
        $(dirname "$0")/lightcommander alarm off
        #/usr/local/bin/433send 2 15 1 0
    fi
    echo $new_status > ${run_file}
  fi
done
