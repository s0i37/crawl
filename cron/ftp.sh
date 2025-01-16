#!/bin/bash

ROBOT='1'
CLUSTER='1'

mkdir ftp 2> /dev/null; cd ftp
cat ../ftp-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip
do echo "$ip"
	grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}') || host="$ip"
	timeout 300 /opt/crawl/spider.sh "ftp://$host/" -P ftp --limit-size=500k
	/opt/crawl/crawl.sh "ftp/$host" | /opt/crawl/save_images.sh /opt/crawl/www/static/images
	#rm -r "ftp/$host"
	#rm ".ftp_$host.sess"
done
cd -
