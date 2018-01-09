#!/usr/bin/env python2.7
from __future__ import print_function
from subprocess import call
import time,sys,os,syslog
sys.path.append(os.path.dirname(__file__) + "/../pychromecast/")
import pychromecast
import subprocess
#mycastname=pychromecast.get_chromecasts_as_dict().keys()[0]
mycastname="Level2 Chillcast DVI1"
print(mycastname)
syslog.syslog(mycastname)
chromecasts = pychromecast.get_chromecasts()
cast=next(cc for cc in chromecasts if cc.device.friendly_name == mycastname)
cast.wait()
print(cast.device.friendly_name)
offlinetime=0
oldcaststatus="None"
if(len(sys.argv)>0):
  caststatus=cast.status.display_name
  print(caststatus)
  sys.exit
maxloop=1000
while maxloop:
  maxloop=maxloop-1
  caststatus=cast.status.display_name
  print(caststatus)
  text_file = open("/var/run/caststatus", "w")
  text_file.write("%s" % caststatus)
  text_file.close()
  if(caststatus == "Backdrop"):
    offlinetime+=1
  else:
    offlinetime=0
  if(offlinetime>10):
    if(subprocess.check_output(["lightcommander","projector","query"]).rstrip('\n') == "15"):
      print("Chromecast not streaming, switching from hdmi2 to slideshow")
      syslog.syslog("Chromecast not streaming, switching from hdmi2 to slideshow")
      call(["lightcommander","projector","dvionly"])
    offlinetime=0
  if(oldcaststatus != caststatus):
    syslog.syslog("Chromecast changed from "+oldcaststatus+" to "+caststatus)
    oldcaststatus=caststatus 
  time.sleep(10)
cast.quit_app()
print("exiting normally")
syslog.syslog("exiting normally")
