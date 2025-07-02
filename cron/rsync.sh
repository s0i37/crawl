#!/bin/bash

ROBOT='1'
CLUSTER='1'
CRAWL_TIME=300

mkdir rsync 2> /dev/null; cd rsync
cat ../rsync-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip
do echo "$ip"
	grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}' | head -n 1) || host="$ip"
	rsync --list-only "rsync://$host" | awk '{print $1}' | while read share
	do
		mkdir -p "rsync/$host/$share" 2> /dev/null
		timeout $CRAWL_TIME rsync -av "rsync://$ip/$share" "rsync/$host/$share"
		/opt/crawl/crawl.sh "rsync/$host/$share"
		#rm -r "rsync/$host"
		#rm ".rsync_$host.sess"
	done
done
cd -
