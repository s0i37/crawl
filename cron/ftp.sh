#!/bin/bash

cat ftp-hosts.txt | while read ip
do echo "$ip"
	timeout 300 /opt/crawl/spider.sh "ftp://$ip/"
	timeout 300 /opt/crawl/crawl.sh "$ip"
done
