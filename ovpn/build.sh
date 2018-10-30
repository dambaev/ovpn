#!/bin/bash -ex


cd /usr/src/app

apt update -y && apt dist-upgrade -y

apt install -y openvpn psmisc

cp ca.crt /etc/openvpn


apt install -y tcpdump nmap telnet vim iptables

ln -s /usr/src/app/ovpn.sh /usr/local/bin
ln -s /usr/src/app/ovpn-stop.sh /usr/local/bin
