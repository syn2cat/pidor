#!/bin/bash
# TODO use functions
nai=`date +%s`;
echo "Content-type: text/html"
echo
echo "<html><body><pre>"
exec 2>&1
. "$(dirname "$0")"/parse_query
parse_query
logger -t $(basename $0) got $FORM_action from $REMOTE_USER
logger -t $(basename $0) spacestatus was $(cat /run/spacestatus)
if [ "$FORM_action" = "open" ]
then
  /usr/local/bin/gpio mode 7 out
  /usr/local/bin/gpio write 7 0
  if [ "$(cat /run/spacestatus)" != "open" ]   # do not modify timestamp on multiple clicks
  then
    echo "open" > /run/spacestatus
  fi
# is now handled in cron Gunstick20140904 #  /usr/bin/curl --max-time 1 --silent --data key=96f7896f97asdf89u0a9s7d7fdasgsda88af --data-urlencode sensors='{"state":{"open":true,"lastchange":'"$nai"'}}' http://spaceapi.syn2cat.lu/sensor/set
fi

if [ "$FORM_action" = "close" ]
then
  /usr/local/bin/gpio mode 7 out
  /usr/local/bin/gpio write 7 1
  if [ "$(cat /run/spacestatus)" != "closed" ]   # do not modify timestamp on multiple clicks
  then
    echo "closed" > /run/spacestatus
  fi
# is now handled in cron Gunstick20140904 #  /usr/bin/curl --max-time 1 --silent --data key=96f7896f97asdf89u0a9s7d7fdasgsda88af --data-urlencode sensors='{"state":{"open":false,"lastchange":'"$nai"'}}' http://spaceapi.syn2cat.lu/sensor/set
  sudo /root/pidor/scripts/closetrigger.sh 
  logger -t $(basename $0) closetrigger ret=$?
fi


logger -t $(basename $0) spacestatus is now $(cat /run/spacestatus)
echo "</pre>"
echo "<script>history.back()</script>"
