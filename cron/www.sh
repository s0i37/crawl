#!/bin/bash

cat www-hosts.txt | while read ip port
do echo "$ip $port"
	timeout 300 /opt/crawl/spider.sh "http://$ip:$port/"
	timeout 300 /opt/crawl/crawl.sh "$ip:$port"
done
