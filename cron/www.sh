#!/bin/bash

DOMAIN='company.org'
USER='username'
PASS='password'

ROBOT='1'
CLUSTER='1'
CRAWL_TIME=300
MAX_FILESIZE='500k'

mkdir www 2> /dev/null; cd www
cat ../www-hosts.txt | awk "(NR-$ROBOT)%$CLUSTER==0" | while read ip port
do echo "$ip $port"
	grep -e " $ip$" ../hosts-ip.txt > /dev/null && host=$(grep -e " $ip$" ../hosts-ip.txt | awk '{print $1}' | head -n 1) || host="$ip"
	if curl -s --max-time 1 "http://$ip:$port" >/dev/null; then
		schema='http'
	elif curl -s --insecure --max-time 1 "https://$ip:$port" >/dev/null; then
		schema='https'
	else
		continue
	fi
	timeout $CRAWL_TIME /opt/crawl/spider.sh "$schema://$host:$port/" --domains "$host" -P "$schema" --limit-size=$MAX_FILESIZE --level 2 #--user "$USER@$DOMAIN:$PASS"
	if [ "$port" = 80 -o "$port" = 443 ]; then
		/opt/crawl/crawl.sh "$schema/$host"
	else
		/opt/crawl/crawl.sh "$schema/$host:$port"
	fi
	#rm -r "$schema/$host:$port" || rm -r "$schema/$host"
	#rm ".${schema}_$host:$port.sess" || rm ".${schema}_$host.sess"
done
cd -
