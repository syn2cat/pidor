#!/bin/bash
# this is called by lightcommander
logger $0 1=$1 2=$2
BEAMERIP=$(cat $(dirname "$0")"/beamerip.txt")
function raisescreen() {
  echo "Rolling projection screen up"
  ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh up'
}
function lowerscreen() {
  echo "Rolling projection screen down"
  ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh down'
}
function beamerquery() {
  signalsource="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info' |awk -F'[<>]' '/<info>/{print substr($3,33,2)}')"
  if [ "$signalsource" = "" ]
  then
    signalsource="off"  # I know bash can do this in 1 line, but this should still be readable
  fi
  echo "$signalsource"
}
#             vv-- volume
# 2a3140bf1c150a3230072a0101050300010001000001000100010185</control>
#          1111111111222
# 1234567890123456789012
function beamervolumedown() {
  curvol="ff"
  rept=20 
  while [ "$curvol" != "00" ] && [ $rept -gt 0 ]
  do
    curvol="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=control' |awk -F'[<>]' '/<control>/{print substr($3,13,2)}')"
    echo "beamervolume was: $curvol"
    if [ "$curvol" != "00" ]
    then
      wget -qO - 'http://'"$projip"'/tgi/return.tgi?command=2a310bf4070263'
    fi
    rept=$((rept-1))
  done
}

function beameroff() {
  echo "Switching beamer off"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3102fd0660 #projector off
}
function beameron() {
  currstatus="$(beamerquery)"
  echo "Switching beamer on (input was $currstatus)"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3101fe0660 #projector on
  if [ "$currstatus" = "off" ]
  then
    lowerscreen &
    echo "Waiting for beamer to boot..."
    sleep 18
    echo "... is now booted"
    return 0
  fi
  return 1
}
function dvi() {
  currstatus="$(beamerquery)"
  if [ "$currstatus" = "02" ] || [ "$currstatus" = "off" ]
  then
    echo "not switching, already displaying DVI (or off)"
    return 0
  else
    echo "Switching to dvi"
    wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070566 #switch to DVI
    return 0
  fi
}
function hdmi1() {
  echo "Switching to hdmi1"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6071475 #switch to hdmi1
}
function hdmi2() {
  echo "Switching to hdmi2"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6071576 #switch to hdmi2
}
function vga1() {
  echo "Switching to vga1"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070162 #switch to vga1
}
function vga2() {
  echo "Switching to vga2"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070263 #switch to vga2
}
function receiveron() {
  echo "switching receiver on"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_POWER"'
}
function receiveroff() {
  echo "switching receiver off"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_POWER2"'
}

function receiverhdmi() {
  echo "Switching receiver to hdmi"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_DVD"'
}
function receiverjack1() {
  echo "Switching receiver to jack1"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_VCR"'
}
function receiverjack2() {
  echo "Switching receiver to jack2"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_VCR2"'

}
function receiveroptical() {
  echo "Switching receiver to optical"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_TAPE"'
}
function receivertuner() {
  echo "Switching receiver to tuner"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_TUNER"'
}
function receivercd() {
  echo "Switching receiver to cd"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_CD"'
}
function receivervolumeup() {
  #echo "Turning reciever volume up"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_VOLUMEUP"'
}
function receivervolumedown() {
  #echo "Turning reciever volume down"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE pioneer "KEY_VOLUMEDOWN"'
}
function bluray() {
  echo "Sending bluray player $1"
  ssh pi@doorbuzz '/usr/bin/irsend SEND_ONCE SONY_RMT_B104P '"KEY_$(tr [:lower:] [:upper:] <<<$1)"
}
function usage() {
  echo "Usage: $0 (beamer|screen|receiver|bluray) (on|dvi|hdmi1|hdmi2|vga|off|down|up|left|right|vol-|vol+|query)"
  exit
}
projip="$(cat $(dirname "$0")"/beamerip.txt")"
case $1 in 
  beamer)
    case $2 in
      on) beameron
        ;;
      off) beameroff
        ;;
      dvi) dvi && beameron && dvi
        ;;
      dvioff) dvi && beameroff
        ;;
      dvionly) dvi 
        ;;
      hdmi1) hdmi1 ; beameron && hdmi1
        ;;
      hdmi2) hdmi2 
             ( receiveron 
               sleep 4 
               receiverhdmi ) & 
             beameron && hdmi2
        ;;
      vga1) vga1 ; beameron && vga1
        ;;
      "vol-") beamervolumedown 
        ;;
      "query") beamerquery 
        ;;
      *) usage
    esac
    ;;
  screen)
    case $2 in
      down|on) lowerscreen
      ;;
      up|off) raisescreen
      ;;
      *) usage
    esac
    ;;
  bluray)
    case $2 in
      down|up|left|right|ok|audio|subtitle|menu|pause|play) bluray $2
      ;;
      on|off) bluray power
      ;;
      *) usage
    esac
    ;;
  receiver)
    case $2 in
      on) receiveron
      ;;
      off) receiveroff
      ;;
      shutdown)
        echo "Receiver shutdown initiated..."
        for i in {1..90}
        do
          if [ "$(cat /run/spacestatus)" = "open" ]
          then
            echo "space open, stopping receiver shutdown"
            exit
          fi
          receivervolumedown
        done
        for i in {1..50}
        do
          if [ "$(cat /run/spacestatus)" = "open" ]
          then
            echo "space open, stopping receiver shutdown"
            exit
          fi
          receivervolumeup
        done
        receiveroff
        echo "Receiver shutdown finished."
      ;;
      hdmi) receiverhdmi
      ;;
      jack1) receiverjack1
      ;;
      jack2) receiverjack2
      ;;
      optical) receiveroptical
      ;;
      tuner) receivertuner
      ;;
      cd) receivercd
      ;;
      "vol+") receivervolumeup
      ;;
      "vol-") receivervolumedown
      ;;
      *) usage
    esac
    ;;
  *)
    usage
    ;;
esac 2>&1 | tee >(logger -t $0)
