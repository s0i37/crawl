#!/bin/bash

DOMAIN='company.org'
USER='username'
PASS='password'

CRAWL_TIME=300

cat ../smb-shares.txt | while IFS=$'\t' read ip share
do echo "$ip: $share"
	grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}' | head -n 1) || host="$ip"
	mkdir -p "smb/$host/$share" 2> /dev/null
	sudo timeout 5 mount.cifs "//$ip/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=2.0 || sudo timeout 5 mount.cifs "//$ip/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=1.0
	timeout $CRAWL_TIME find "smb/$host/$share" -type f -printf '%p | %k KB | %t\n' > "smb-files-$host-$share.txt"
	sudo umount "smb/$host/$share"
	timeout 1 rm -r "smb/$host"
done
