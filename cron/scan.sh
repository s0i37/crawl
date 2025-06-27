#!/bin/bash

PORTS_WWW="80,443,8080"
PORTS_FTP='21'
PORTS_SMB='445'
PORTS_NFS='2049'
PORTS_RSYNC='873'
SCAN_RATE=50

rm www-hosts.txt 2> /dev/null
rm ftp-hosts.txt 2> /dev/null
rm smb-hosts.txt 2> /dev/null
rm nfs-hosts.txt 2> /dev/null
rm rsync-hosts.txt 2> /dev/null

for net in $(cat nets.txt)
do echo "$net"
	nmap -Pn -n --max-retries 0 --max-rate $SCAN_RATE "$net" -p "$PORTS_WWW" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2 " " $5}' >> www-hosts.txt
	nmap -Pn -n --max-retries 0 --max-rate $SCAN_RATE "$net" -p "$PORTS_FTP" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> ftp-hosts.txt
	nmap -Pn -n --max-retries 0 --max-rate $SCAN_RATE "$net" -p "$PORTS_SMB" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> smb-hosts.txt
	nmap -Pn -n --max-retries 0 --max-rate $SCAN_RATE "$net" -p "$PORTS_NFS" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> nfs-hosts.txt
	nmap -Pn -n --max-retries 0 --max-rate $SCAN_RATE "$net" -p "$PORTS_RSYNC" --open -oG - | grep '/open/' | tr '/' ' ' | awk '{print $2}' >> rsync-hosts.txt
done
