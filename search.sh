#!/bin/bash

GREEN=$'\x1b[32m'
RESET=$'\x1b[39m'

MATCH=50
LIMIT=10
OFFSET=0
URI='%'

while getopts "m:c:o:u:" opt
do
	case $opt in
		m) MATCH=$OPTARG;;
		c) LIMIT=$OPTARG;;
		o) OFFSET=$OPTARG;;
		u) URI=$OPTARG;;
esac
done

[[ $(($#-$OPTIND)) -lt 1 ]] && [[ $URI = '%' ]] && {
	echo $0 [opts] words.db QUERY
	echo "opts:"
	echo "  -m match"
	echo "  -c count"
	echo "  -o offset"
	echo "  -u fragment"
	exit
}

DB="${@:$OPTIND:1}"
shift $OPTIND
IFS='=%='
echo "SELECT uri,text FROM words WHERE uri LIKE '$URI' and text LIKE '%$*%' limit $LIMIT offset $OFFSET;" | sqlite3 -separator '=%=' "$DB" | while read uri text
do
	echo $GREEN"$uri"$RESET
	echo "$text" | grep -i -o -P ".{0,$MATCH}$*..{0,$MATCH}" | grep -i --color=auto "$*"
done
