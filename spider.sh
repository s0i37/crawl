#!/bin/bash

USERAGENT="Mozilla"
IGNORE_EXT="woff,ttf,eot"

[ $# -lt 1 ] && {
	echo "$0 url [/usr/bin/wget options]"
	echo "example: $0 --level 5 --wait 2 --domains www.site.com --limit-size=10000000 -A html,php -R pdf,jpg -X uploads --no-parent http://site.com/path/to"
	echo "example: $0 --level 2 --wait 1 --limit-size=500k ftp://target.com/"
	exit
}

function crawl(){
	$(dirname "$0")/bin/wget --no-check-certificate --recursive --spider -e robots=off -U "$USERAGENT" -O "/tmp/spider" --no-verbose $* 2>&1 | sed -rn 's|.*URL:[ ]*([^ ]+).*|\1|p'
}

function save(){
	$(dirname "$0")/bin/wget --no-check-certificate --recursive -nc -e robots=off -U "$USERAGENT" --no-verbose -R "$IGNORE_EXT" $* 2>&1 | sed -rn 's|.*URL:[ ]*([^ ]+).*|\1|p'
}

#crawl $*
save $*

#https://yurichev.com/wget.html
