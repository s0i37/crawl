#!/bin/bash

USERAGENT="Mozilla"
IGNORE_EXT="gif,GIF,jpg,JPG,png,PNG,ico,ICO,svg,SVG,woff,ttf,eot"

[ $# -lt 1 ] && {
	echo "$0 url [/usr/bin/wget options]"
	echo "example: $0 --level 5 --wait 2 --domains www.site.com --quota=10000000 -A html,php -R pdf,jpg -X uploads --no-parent http://site.com/path/to"
	exit
}

function crawl(){
	wget --no-check-certificate --recursive --spider -e robots=off -U $USERAGENT -O "/dev/shm/spider_temp" --no-verbose $* 2>&1 | sed -rn 's|.*URL:[ ]*([^ ]+).*|\1|p'
}

function save(){
	wget --no-check-certificate --recursive -N -e robots=off -U $USERAGENT --no-verbose -R "$IGNORE_EXT" $* 2>&1 | sed -rn 's|.*URL:[ ]*([^ ]+).*|\1|p'
}

#crawl $*
save $*