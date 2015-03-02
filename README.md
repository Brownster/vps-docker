# vps-docker
All in one easy VPS setup DOCKERFILE WORK IN PROGRESS NOT WORKING

This bash script attempts to harden your vps and install docker instances of NZBGET, Transmision, Headphones, Sonarr, Couchpotato,and on your vps Fail2ban setup for ssh curlftps for mount points back to your local media squidproxy for anonymous web browsing proxy server useful in the uk and other steps to secure your vps like changing ssh port

The aim of this dockerfile is to install all necessary components and set them up from the information given in the start of the install.sh.

Before you start you will need at least one dyndns/no-ip name(s) for your home you will also need to install an ftp server on your file server with port forwarding on your router. With that in place you will be able to run all your nzb downloads on your vps then once the download is complete post processing will move the files to your media collection on your local storage with the help of curlftps and some mount points this script will create.

To install get a kvm vps from ramnode https://clientarea.ramnode.com/aff.php?aff=838 reinstall the os with ubuntu 12.04 LTS minimal

log on as root you should change the root password now with "passwd" and then copy paste the following:

cd /home

apt-get update -y && apt-get install git -y

git clone https://github.com/Brownster/vps-docker.git installsh

cd installsh

chmod 777 install.sh

sudo ./install.sh

# and follow prompts
