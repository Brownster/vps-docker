#!/bin/bash

## PROMPT TO SET VARIABLES

echo           You are about to set the variables for the docker build 
echo                  there are a few deatils to enter.... 

echo Please enter DYNDNS / noip host name that resolves into your vps ip address:
read DYNDNS
sed -i 's/ENV DYNDNS someplace.dydns-remote.com/ENV DYNDNS $DYNDNS' /home/installsh/Dockerfile

echo Please enter a user name for accessing sickbeard, couchpotato etc:
read WEBUSER
sed -i 's/ENV WEBUSER webuser/ENV WEBUSER $WEBUSER' /home/installsh/Dockerfile

echo Please enter a password for accessing all the web apps sickbeard, couchpotato ect:
read WEBPASS
sed -i 's/ENV WEBPASS webpass/ENV WEBPASS $WEBPASS' /home/installsh/Dockerfile

#Please enter a Username for Squid Proxy Server
SQUIDUSER=squid

#Please enter a password for Squid Proxy Server
SQUIDPASS=hideme

#squid Proxy please enter the port for web access
SQUIDPORT=7629

#SSH please enter the port for access
SSHPORT=2022

#FTP server address eith ip address if you have static address or 
#dyn dns / no ip account resolving to your home ip if you are dynamic
FTPHOST=somewhere.dyndns-remote.com

#ftp user
FTPUSER=ftpuser

#ftp password
FTPPASS=ftppass

#film ftp location - relative to ftp home directory
FILMFTPDIR=films

#TV ftp location
TVFTPDIR=tvseries

#Music ftp location
MUSICFTPDIR=music

#Books ftp location
BOOKSFTPDIR=ebooks

#Books ftp location
GAMESFTPDIR=games

#Books ftp location
COMICSFTPDIR=comics

#games mount location
GAMESMNTDIR=/home/media/games

#comics mount location
COMICSMNTDIR=/home/media/comics

#films mount location
FILMMNTDIR=/home/media/films

#tv series mount location
TVMNTDIR=/home/media/tv

#music mount location
MUSICMNTDIR=/home/media/music

#books mount location
BOOKSMNTDIR=/home/media/books


## OPTIONAL TO CHANGE BELOW BUT RECOMMENDED ##

#SABNZB Please enter the port for web access
SABPORT=7960

#SICKBEARD Please enter the port for web access
SICKPORT=7961

#COUCHPOTATO Please enter the port for web access
COUCHPORT=7962

#Headphones Please enter the port for web access
HEADPORT=7963

#Lazy Librarian Please enter the port for web access
BOOKPORT=7964

#Mylar Please enter the port for web access
MYLARPORT=7965

#Gamez Please enter the port for web access
GAMESPORT=7966

#Transmission RPC Port (web ui)
TRANPORT=7967

#Transmission peer port
TRANPPORT=61724

#Maraschino Web UI port
MARAPORT=7979


apt-get upadate && apt-get install -y apt-transport-https
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
apt-get upadte && apt-get install -y lxc-docker


echo "####################"
echo "## installing ufw ##"
echo "####################"
sleep 2
apt-get install ufw -y
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"' /etc/default/ufw

echo "###############################"
echo "## opening ports on firewall ##"
echo "###############################"
ufw allow $SSHPORT
echo "opening old ssh port just for now to make sure we dont lose our connetcion"
ufw allow ssh
echo "opening new Sab web UI port"
ufw allow $SABPORT
echo "opening new Sickbeard web UI port"
ufw allow $SICKPORT
echo "opening new Couchpotato web UI port"
ufw allow $COUCHPORT
echo "opening new Headphones web UI port"
ufw allow $HEADPORT
echo "opening new Lazy Librarian web UI port"
ufw allow $BOOKPORT
echo "opening new Squid Proxy server Port"
ufw allow $SQUIDPORT
echo "opening new Transmission web UI Port"
ufw allow $TRANPORT
echo "opening port for Maraschino"
ufw allow $MARAPORT
echo "nZEDb web port"
ufw allow 80
echo "editing sshd config"
sed -i "s/port 22/port $sshport/" /etc/ssh/sshd_config
sed -i "s/protocol 3,2/protocol 2/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/DebianBanner yes/DebianBanner no/" /etc/ssh/sshd_config
echo "restarting ssh"
sleep 2
/etc/init.d/ssh restart -y
echo "enabling firewall"
sleep 2
ufw enable -y


echo "##########################"
echo "## secure shared memory ##"
echo "##########################"
sleep 2
echo "tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab
echo "adding admin group"
sleep 2
groupadd admin
usermod -a -G admin $username
echo "protect su by limiting access to admin group only"
dpkg-statoverride --update --add $username admin 4750 /bin/su


echo "############################################"
echo "# adding $username to sudo and fuse groups #"
echo "############################################"
sleep 3
usermod -a -G sudo $username
usermod -a -G fuse $username


echo "############################"
echo "## ip spoofing protection ##"
echo "############################"
cat > /etc/host.conf << EOF
order bind,hosts
nospoof on
EOF

echo "##############################"
echo "# Harden Network with sysctl #"
echo "##############################"
sleep 3

cat > /etc/sysctl.conf << EOF
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0 
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0 
net.ipv6.conf.default.accept_redirects = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
EOF

sysctl -p

echo "#######################"
echo "# installing fail2ban #"
echo "#######################"
sleep 2
sudo apt-get install fail2ban -y
echo "setting up fail2ban"
sed -i 's/enabled = false/enabled = true/' /etc/fail2ban/jail.conf
sed -i 's/port = sshd/port = $SSHPORT/' /etc/fail2ban/jail.conf
sed -i 's/port = sshd/port = $SSHPORT/' /etc/fail2ban/jail.conf
sed -i 's/maxretry = 5/maxretry = 3/' /etc/fail2ban/jail.conf

echo "##########################"
echo "## creating Diretcories ##"
echo "##########################"
sleep 1
mkdir /home/$username/.pid/
mkdir /home/$username/temp
mkdir /home/downloads
mkdir /home/downloads/completed
mkdir /home/downloads/completed/tv
mkdir /home/downloads/completed/films
mkdir /home/downloads/completed/books
mkdir /home/downloads/completed/music
mkdir /home/downloads/completed/games
mkdir /home/downloads/completed/comics
mkdir /home/downloads/ongoing
mkdir /home/media/
mkdir /home/media/films
mkdir /home/media/tv
mkdir /home/media/music
mkdir /home/media/books
mkdir /home/media/games
mkdir /home/media/comics
mkdir /home/backups/
mkdir /home/backups/sickbeard
mkdir /home/backups/couchpotato
mkdir /home/backups/headphones
mkdir /home/backups/lazylibrarian
mkdir /home/backups/sabnzbd
mkdir /home/backups/comics
mkdir /home/backups/games
chown $username /home/*/*/
chown $username /home/*/*/*
chmod 777  /home/*/*

echo review the line(s) below and press enter - end of script

echo sudo docker run –name downloader -v /home/$username/temp:/home/$username/temp -v /home/$username/.pid/:/home/$username/.pid/ -v /home/media/games:/home/media/games –net=host -d -t brownster/vps-docker
