Pidor is controlling the state of Level2 on the website, spaceapi and twitter

This documentation is work in progress, sorry about that.

Install
put this in /etc/inittab (see example in systemfiles/inittab)
# pidor
P0:2345:respawn:/root/pidor/scripts/lockbutton.sh
P1:2345:respawn:/root/pidor/scripts/beamerdetect.sh
P2:2345:respawn:/root/pidor/scripts/ws4beamer_status.py
P3:2345:respawn:/root/pidor/scripts/peoplecounter-realtime.sh

put the beamer IP into beamerip.txt
put the peoplecounter ip into peoplecounterip.txt

fill in the crontab
* * * * * /root/pidor/scripts/dhcp2presency.sh
* * * * * /root/pidor/scripts/upd_status.sh > /run/spacestatus.out 2>&1

needs an apache, for some silly historic reason, and for the lights commander
cd ~/pidor/www && ./intallwebsite.sh


