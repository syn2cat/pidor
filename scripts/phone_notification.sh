#!/bin/bash

url=http://10.2.113.137
run_file="/var/run/phone_ringing_status"

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
        /usr/local/bin/433send 2 15 1 1
    else
	logger -t $(basename $0) "phone ring light off"
        /usr/local/bin/433send 2 15 1 0
    fi
    echo $new_status > ${run_file}
  fi
done
