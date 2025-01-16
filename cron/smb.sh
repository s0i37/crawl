#!/bin/bash

DOMAIN='company.org'
USER='username'
PASS='password'

ROBOT='1'
CLUSTER='1'

cat smb-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip
do
	smbclient -U "$DOMAIN"/"$USER"%"$PASS" -L "$ip" | grep 'Disk' | sed -rn 's/^\s+(.+)\s+Disk.*/\1/p' | fgrep -v -e 'IPC$' -e 'print$' | while read share
	do
		smbclient -U "$DOMAIN"/"$USER"%"$PASS" "//$ip/$share" -c 'q' >/dev/null 2>&1 && echo "$ip"$'\t'"$share"
	done
done > smb-shares.txt

mkdir smb-all 2> /dev/null; cd smb-all
for depth in {1..10}
do
	IFS=$'\t'
	cat ../smb-shares.txt | while read ip share
	do echo "$ip: $share"
		grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}') || host="$ip"
		mkdir -p "smb/$host/$share" 2> /dev/null
		sudo timeout 5 mount.cifs "//$host/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=2.0 || sudo timeout 5 mount.cifs "//$host/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=1.0
		timeout 300 /opt/crawl/crawl.sh "smb/$host/$share" -mindepth "$depth" -maxdepth "$depth" -size -100k -not -ipath '*/Program Files*/*' -not -ipath '*/Windows/*' | /opt/crawl/save_images.sh /opt/crawl/www/static/images
		sudo umount "smb/$host/$share"
		timeout 1 rm -r "smb/$host"
	done
done
cd -

mkdir smb-new 2> /dev/null; cd smb-new
for depth in {1..10}
do
	IFS=$'\t'
	cat ../smb-shares.txt | while read ip share
	do echo "$ip: $share"
		grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}') || host="$ip"
		mkdir -p "smb/$host/$share" 2> /dev/null
		sudo timeout 5 mount.cifs "//$host/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=2.0 || sudo timeout 5 mount.cifs "//$host/$share" "smb/$host/$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS",vers=1.0
		timeout 300 /opt/crawl/crawl.sh "smb/$host/$share" -newermt "$(date +'%Y-%m-%d 00:00:00' -d '-24 hours')" -mindepth "$depth" -maxdepth "$depth" -size -100k -not -ipath '*/Program Files*/*' -not -ipath '*/Windows/*' | /opt/crawl/save_images.sh /opt/crawl/www/static/images
		sudo umount "smb/$host/$share"
		timeout 1 rm -r "smb/$host"
		rm ".smb_${host}_${share}.sess"
	done
done
cd -
