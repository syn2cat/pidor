#!/bin/bash
# add this to /etc/inittab
# P1:2345:respawn:/root/lockbutton.sh
PATH=/bin:/usr/bin:/usr/local/bin
logger -t $(basename $0) "starting..."
gpio -g mode 11 in    # this is usually SCLK as ALT0
                      # transform into GPIO11 as IN
gpio -g mode 11 up    # set internal pullup
while true
do
  logger -t $(basename $0) "change detected (was $state)"
  if [ $(gpio -g read 11) -eq 1 ] && [ "$state" != "pushed" ]
  then
    for plugin in "$0".d/*
    do
      "$plugin" pushed
      logger -t $(basename $0) "called '$plugin pushed' with ret=$?"
    done
    state="pushed"
  else
    if [ "$state" != "released" ]
    then
      for plugin in "$0".d/*
      do
        "$plugin" released
        logger -t $(basename $0) "called '$plugin released' with ret=$?"
      done
      state="released"
    fi
  fi
  if ( [ $(gpio -g read 11) -eq 1 ] && [ "$state" = "released" ] ) ||
     (  [ $(gpio -g read 11) -eq 0 ] && [ "$state" = "pushed" ] )
  then
    logger -t $(basename $0) "inconsistent state $state, aborting"
    break
  fi
  gpio -g wfi 11 both   # wait for change (uses no cpu, but interrupt)
done
