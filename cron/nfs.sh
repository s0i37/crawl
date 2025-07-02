#!/bin/bash

ROBOT='1'
CLUSTER='1'
CRAWL_TIME=300
MAX_FILESIZE='-100k'
MAX_DEPTH=10

cat nfs-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip
do
	showmount --directories "$ip" | grep / | while read share
	do
		echo "$ip" "$share"
	done
done > nfs-shares.txt

mkdir nfs 2> /dev/null; cd nfs
for depth in `seq 1 $MAX_DEPTH`
do
	IFS=$'\t'
	cat ../nfs-shares.txt | while read ip share
	do echo "$ip: $share"
		grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}' | head -n 1) || host="$ip"
		mkdir -p "nfs/$host/$share" 2> /dev/null
		sudo timeout 5 mount.nfs "$ip:$share" "nfs/$host/$share" -o nolock,ro
		timeout $CRAWL_TIME /opt/crawl/crawl.sh "nfs/$host/$share" -mindepth "$depth" -maxdepth "$depth" -size $MAX_FILESIZE
		sudo umount "nfs/$host/$share"
		timeout 1 rm -r "nfs/$host"
	done
done
cd -
