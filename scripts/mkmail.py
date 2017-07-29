#!/usr/bin/python
import smtplib
import sys
import mailconfig as cnf
server = smtplib.SMTP(cnf.mailserver, 25)
if (len(sys.argv) < 3):
  print "usage: "+sys.argv[0]+" 'subject' 'body text'"
  sys.exit()
msg = "Subject: " + sys.argv[1] + "\n\n" + sys.argv[2]
server.sendmail(cnf.mailsource, cnf.maildestination, msg)
server.quit()
