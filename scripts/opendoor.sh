#!/bin/bash
RELAYURL="$(cat "$(dirname "$0")"/secret.txt)/state.xml?relay1State=2&pulseTime1=5"
wget -O - --timeout=1 --tries=1 $RELAYURL
