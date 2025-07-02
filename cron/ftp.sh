#!/bin/bash

ROBOT='1'
CLUSTER='1'
CRAWL_TIME=300
MAX_FILESIZE='500k'

mkdir ftp 2> /dev/null; cd ftp
cat ../ftp-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip
do echo "$ip"
	grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}' | head -n 1) || host="$ip"
	timeout $CRAWL_TIME /opt/crawl/spider.sh "ftp://$ip/" -P ftp --limit-size=$MAX_FILESIZE
	/opt/crawl/crawl.sh "ftp/$host"
	#rm -r "ftp/$host"
	#rm ".ftp_$host.sess"
done
cd -
