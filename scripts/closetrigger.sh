#!/bin/bash
logger -t $(basename $0) adding upd_status.sh to at
#echo "$(dirname "$0")/upd_status.sh" | at -t $(date --date "2 seconds" +%Y%m%d%H%M%S)
"$(dirname "$0")/upd_status.sh" </dev/null >/dev/null 2>&1 & 
logger -t $(basename $0) added $(dirname "$0")/upd_status.sh as at job with ret=$?
