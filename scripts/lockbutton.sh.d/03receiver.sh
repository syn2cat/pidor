#!/bin/bash
if [ "$1" = "pushed" ]
then
  $(dirname $0)/../lightcommander receiver shutdown &
fi
