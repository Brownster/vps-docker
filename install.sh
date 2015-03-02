#!/bin/bash

## PROMPT TO SET VARIABLES

echo           You are about to set the variables for the docker build 
echo                  there are a few deatils to enter.... 

echo Please enter DYNDNS / noip host name that resolves into your vps ip address:
read DYNDNS

echo Please enter a user name for accessing sickbeard, couchpotato etc:
read WEBUSER


echo Please enter a password for accessing all the web apps sickbeard, couchpotato ect:
read WEBPASS

echo Please enter a Username for Squid Proxy Server:
read SQUIDUSER

echo Please enter a password for Squid Proxy Server:
read SQUIDPASS

echo squid Proxy please enter the port for web access
read SQUIDPORT

echo SSH please enter the port for access
read SSHPORT

echo FTP server address either ip address if you have static address or 
echo dyn dns / no ip account resolving to your home ip if you are dynamic
read FTPHOST

echo enter the ftp account user name:
read FTPUSER

echo enter the ftp account password:
read FTPPASS

echo enter film ftp location - (relative to ftp home directory for ftp user)
read FILMFTPDIR

echo TV ftp location:
read TVFTPDIR

echo Music ftp location:
read MUSICFTPDIR

echo Books ftp location:
read BOOKSFTPDIR


echo enter dir to mount films ftp location
read FILMMNTDIR

echo tv series mount location
read TVMNTDIR

echo music mount location
read MUSICMNTDIR

echo books mount location
read BOOKSMNTDIR


## OPTIONAL TO CHANGE BELOW BUT RECOMMENDED ##

echo Nzbget Please enter the port for web access
read SABPORT

echo SICKBEARD now sonarr Please enter the port for web access
read SICKPORT

echo COUCHPOTATO Please enter the port for web access
read COUCHPORT

echo Headphones Please enter the port for web access
read HEADPORT

echo Lazy Librarian Please enter the port for web access
read BOOKPORT

echo Transmission RPC Port (web ui)
read TRANPORT

echo Transmission peer port
read TRANPPORT

echo Maraschino Web UI port
read MARAPORT=7979

echo thats all i need for now
sleep 2
echo installing Docker.......
sleep 1
apt-get upadate && apt-get install -y apt-transport-https
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
apt-get upadte && apt-get install -y lxc-docker


echo "####################"
echo "## installing ufw ##"
echo "####################"
sleep 2
apt-get install ufw -y
#changes to make docker work with UFW
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
mkdir /home/downloads/nzbblackhole
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
mkdir /home/install
chown $username /home/*/*/
chown $username /home/*/*/*
chmod 777  /home/*/*

#Pull dockerfiles
cd /home/install
git clone git@github.com:brownster/nzbget.git
git clone git@github.com:brownster/sonarr.git
git clone git@github.com:brownster/vps-couchpotato.git couchpotato
git clone git@github.com:brownster/headphones.git

# Push variables to dockerfiles
sed -i 's/ENV DYNDNS someplace.dydns-remote.com/ENV DYNDNS $DYNDNS' /home/install/couchpotato/Dockerfile



#Build dockerfiles
#Build nzbget
cd /home/install/nzbget
sudo docker build -t nzbget .

#Build couchpotato
cd /home/install/couchpotato
sudo docker build -t couchpotato .

#Build Sonarr
cd /home/install/sonarr
sudo docker build -t sonarr .

#Build headphones
cd /home/install/headphones
sudo docker build -t headphones .


#Run couchpotato Container
sudo docker run –name couchpotato --restart=always -v /home/media/films:/home/media/films -v /home/backups/couchpotato/:/home/backups/couchpotato/ –net=host -d -t couchpotator
# Run Sonarr Container
sudo docker run –name sonarr --restart=always -v /home/media/tv:/home/media/tv -v /home/backups/sonarr/:/home/backups/sonar/ –net=host -d -t sonar
