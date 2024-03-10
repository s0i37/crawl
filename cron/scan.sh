#!/bin/bash

#PORTS_WWW="80,443,8080,8443,8000,8088,8880,8808,8888,6443,7443,9443,10443,8081"
PORTS_WWW="80,8080"
PORTS_FTP='21'
PORTS_SMB='445'

for net in $(cat nets.txt)
do echo "$net"
	#nmap -Pn -n --max-retries 0 --max-rate 5 "$net" -p "$PORTS_WWW" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2 " " $5}' >> www-hosts.txt
	#nmap -Pn -n --max-retries 0 --max-rate 5 "$net" -p "$PORTS_FTP" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> ftp-hosts.txt
	nmap -Pn -n --max-retries 0 --max-rate 5 "$net" -p "$PORTS_SMB" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> smb-hosts.txt
done
