#!/bin/bash

DOMAIN='company.org'
USER='iivanov'
PASS='password'

#crackmapexec -t 1 smb --shares smb-hosts.txt | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | grep ' READ ' | sed -rn 's/SMB\s+([0-9\.]+)\s+445\s+([^" "]+)\s+([^" "]+)\s+READ.*/\1\t\2\t\3/p' > shares-anon.txt
crackmapexec -t 1 smb -d "$DOMAIN" -u "$USER" -p "$PASS" --shares smb-hosts.txt | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | grep ' READ ' | sed -rn 's/SMB\s+([0-9\.]+)\s+445\s+([^" "]+)\s+([^" "]+)\s+READ.*/\1\t\2\t\3/p' > shares-user.txt

IFS=$'\t'
for depth in {1..10}
do
	cat shares-user.txt | fgrep -v 'IPC$' | while read ip name share
	do echo "$ip" "$share"
		fgrep -q "+ $depth //$ip/$share" crawl.log 2> /dev/null && continue
		mkdir "/mnt/$ip-$share"
		sudo timeout 5 mount.cifs "//$ip/$share" "/mnt/$ip-$share" -o ro,dom="$DOMAIN",user="$USER",pass="$PASS" || { echo "- $depth //$ip/$share" >> crawl.log; continue; }
		timeout 300 /opt/crawl/crawl.sh "/mnt/$ip-$share" -mindepth "$depth" -maxdepth "$depth" -size -100k
		sudo umount "/mnt/$ip-$share"
		rm -r "/mnt/$ip-$share"
		echo "+ $DEPTH //$ip/$share" >> crawl.log
	done
done
