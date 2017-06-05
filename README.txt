Pidor is controlling the state of Level2 on the website, spaceapi and twitter

This documentation is work in progress, sorry about that.

Connectivity
connect the doorlock relay to gpio 7
connect button of doorlock to gpio 11
connect the 433mhz transmitter to pin 2 (gpio 17)


Install

put raspian image on SD card and put into rPi

ssh to pi@<ip address>
if that does not work, edit the SD card and put into etc/rc.local "/etc/init.d/ssh start"
sudo bash   # all is installed under root 
apt-get install php5-curl # for twitter
apt-get install git # for getting this
apt-get install wiringpi # for the buttons and stuff
apt-get install gawk # raspian has mawk by default which lacks time functions

tzselect

comment out the last 4 lines of rsyslogd.conf (for xconsole)
like explained here https://www.raspberrypi.org/forums/viewtopic.php?f=91&t=122601

cp -p systemfiles/sudoers.d/* /etc/sudoers.d/

mkdir /root/var    # kinda important
put your ssh key in git and on the pi's /root/.ssh

cd /root
git clone git@github.com:syn2cat/pidor.git
cd pidor
git config --global user.email "pidor@level2.lu"
git config --global user.name pidor


# set fixed IP at end of /etc/dhcpcd.conf
interface eth0
static ip_address=10.10.10.10/24
static routers=10.10.10.1
static domain_name_servers=10.10.10.1


put discard (for fstrim) in fstab
/dev/mmcblk0p2  /               ext4    discard,defaults,noatime  0       1

reboot

NO systemd:
put this in /etc/inittab (see example in systemfiles/inittab)
# pidor
P0:2345:respawn:/root/pidor/scripts/lockbutton.sh
P1:2345:respawn:/root/pidor/scripts/beamerdetect.sh
P2:2345:respawn:/root/pidor/scripts/ws4beamer_status.py
P3:2345:respawn:/root/pidor/scripts/peoplecounter-realtime.sh
P4:2345:respawn:/root/pidor/scripts/caststatus.py

WITH systemd
cd systemfiles/
cp -p systemd/system/* /etc/systemd/system/
systemctl enable lockbutton.service beamerdetect.service ws4beamer_status.service peoplecounter-realtime.service caststatus.service
systemctl daemon-reload
systemctl start lockbutton.service beamerdetect.service ws4beamer_status.service peoplecounter-realtime.service caststatus.service


# get beamer status on port 5042
apt-get install python-flask


put the beamer IP into beamerip.txt
put the peoplecounter ip into peoplecounterip.txt
put entry for doorbuzz in /etc/hosts

ln lightcommander /usr/local/bin/    # this is quite important

fill in the crontab
* * * * * /root/pidor/scripts/dhcp2presency.sh
* * * * * /root/pidor/scripts/upd_status.sh > /run/spacestatus.out 2>&1


#needs an apache for the lights commander
apt-get install apache2 php5
cd ~/pidor/www && ./intallwebsite.sh
service apache2 restart

# download windos sound bytes to /root/win
# e.g. here http://joshlalonde.deviantart.com/art/Windows-XP-Sounds-158309567
# 
mkdir /root/win
cd /root/win


If you have a chromecast, script to switch off if chromecast is iddle:
cd ~/pidor
git clone git@github.com:balloob/pychromecast.git
cd pychromecast
sudo apt-get install python-dev python-pip
sudo pip install --upgrade pip
sudo pip install -r requirements.txt

