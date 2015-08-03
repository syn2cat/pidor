#!/bin/bash
if [ "$1" = "pushed" ]
then
  $(dirname $0)/../beamerdetect.sh off
fi
