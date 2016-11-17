#!/usr/bin/env python2.7
from __future__ import print_function
import time,sys,os
sys.path.append(os.path.dirname(__file__) + "/../pychromecast/")
import pychromecast
#mycastname=pychromecast.get_chromecasts_as_dict().keys()[0]
mycastname="Level2 Chillcast DVI1"
cast = pychromecast.get_chromecast(friendly_name=mycastname)
cast.wait()
print(cast.device.friendly_name)
offlinetime=0
while True:
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
    #print("Chromecast not streaming, switching to slideshow")
    offlinetime=0
  time.sleep(10)
cast.quit_app()
