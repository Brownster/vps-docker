#!/bin/bash

## PROMPT TO SET VARIABLES

echo           You are about to set the variables for the docker build 
echo                  there are a few deatils to enter.... 

echo Enter your newsgroup server:
read NEWSSERVER

echo Enter your newsgroup Port:
read NEWSPORT

echo Enter your newsgroup Username:
read NEWSUSER

echo Enter your newsgroup server Password:
read NEWSPASS

echo Enter how many concuurent connections you newsgroup derver allows
red NEWSCON

echo Does your nesgroup server use ssl? (answer yes or no):
read NEWSENC

echo Enter Your docker repo username
read DOCKERREPO

echo Enter Your Docker repo password
read DOCKERPASS

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

HOSTIP=`ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'
echo the ip address i will be using is $HOSTIP

echo "we will add a user so we can stop using root, please provide username and password when prompted"
sleep2
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
	fi


echo thats all i need for now
sleep 2
echo installing Docker.......
sleep 1
apt-get upadate && apt-get install -y apt-transport-https
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
apt-get upadte && apt-get install -y lxc-docker

HOSTIP=`ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'`

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
mkdir /home/downloads/ongoing
mkdir /home/downloads/nzb
mkdir /home/downloads/queue
mkdir /home/downloads/tmp
mkdir /home/media/
mkdir /home/media/films
mkdir /home/media/tv
mkdir /home/media/music
mkdir /home/backups/
mkdir /home/backups/sickbeard
mkdir /home/backups/couchpotato
mkdir /home/backups/headphones
mkdir /home/backups/nzbget
mkdir /home/backups/nzbget/scripts
mkdir /home/install
chown $username /home/*/*/
chown $username /home/*/*/*
chmod 777  /home/*/*

#Pull dockerfiles
cd /home/install
git clone git@github.com:brownster/vps-nzbget.git
git clone git@github.com:brownster/vps-sonarr.git
git clone git@github.com:brownster/vps-couchpotato.git
git clone git@github.com:brownster/vps-headphones.git

# Push variables to dockerfiles
#couchpotato
sed -i 's/ENV DYNDNS someplace.dydns-remote.com/ENV DYNDNS $DYNDNS' /home/install/vps-couchpotato/Dockerfile

#Nzbget
sed -i 's/"MainDir=~/downloads"/"MainDir=/home/downloads"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/"DestDir=${MainDir}/dst"/"DestDir=/home/downloads/completed"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/"InterDir=${MainDir}/inter"/"InterDir=/home/downloads/ongoing"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/"NzbDir=${MainDir}/nzb"/"NzbDir=/home/downloads/nzb"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/"ScriptDir=${MainDir}/scripts"/"ScriptDir=/home/backups/nzbget/scripts"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/"QueueDir=${MainDir}/queue"/"QueueDir=/home/downloads/queue"' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Host=my.newsserver.com/Server1.Host=$NEWSSERVER' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Port=119/Server1.Port=$NEWSPORT' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Username=user/Server1.Username=$NEWSUSER' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Password=pass/Server1.Password=$NEWSPASS' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Encryption=no/Server1.Encryption=$NEWSENC' /home/install/vps-nzbget/nzbget.conf
sed -i 's/Server1.Connections=4/Server1.Connections=$NEWSCON' /home/install/vps-nzbget/nzbget.conf
sed -i 's/ControlIP=0.0.0.0/ControlIP=$HOSTIP' /home/install/vps-nzbget/nzbget.conf
sed -i 's/ControlPort=6789/ControlPort=$SABPORT' /home/install/vps-nzbget/nzbget.conf

#Sonarr




#Headphones
sed -i 's/ENV username user/ENV username $username' /home/install/vps-headphones/Dockerfile



#Build dockerfiles
#Build nzbget
cd /home/install/vps-nzbget
sudo docker build -t $DOCKERREPO/nzbget .

#Build couchpotato
cd /home/install/couchpotato
sudo docker build -t $DOCKERREPO/couchpotato .

#Build Sonarr
cd /home/install/sonarr
sudo docker build -t $DOCKERREPO/sonarr .

#Build headphones
cd /home/install/headphones
sudo docker build -t $DOCKERREPO/headphones .


#Run couchpotato Container
sudo docker run -p $COUCHPORT:$COUCHPORT –name couchpotato --restart=always -v /home/media/films:/home/media/films -v /home/backups/couchpotato/:/home/backups/couchpotato/ -v /etc/localtime:/etc/localtime:ro
# Run Sonarr Container
sudo docker run -p $SICKPORT:$SICKPORT  --restart=always –name sonarr -v /home/media/tv:/home/media/tv -v /home/backups/sonarr/:/home/backups/sonar/ -v /etc/localtime:/etc/localtime:ro
# Run NZBGET Container
sudo docker run -d -p $SABPORT:$SABPORT --restart=always -name nzbget  -v /home/media:/media -v /home/data:/data -v /home/config:/config -v /etc/localtime:/etc/localtime:ro
#Run Headphones
sudo docker run -d -p $HEADPORT:$HEADPORT --restart=always -name headphones  -v /home/media:/media -v /home/data:/data -v /home/config:/config -v /etc/localtime:/etc/localtime:ro
