#!/bin/bash

GREEN=$'\x1b[32m'
YELLOW=$'\x1b[33m'
RESET=$'\x1b[39m'

MATCH=30
LIMIT=10
OFFSET=0
URI='%'
TYPE='%'
EXT='%'

while getopts "u:t:e:m:c:o:" opt
do
	case $opt in
		u) URI=$OPTARG;;
		t) TYPE=$OPTARG;;
		e) EXT=$OPTARG;;
		m) MATCH=$OPTARG;;
		c) LIMIT=$OPTARG;;
		o) OFFSET=$OPTARG;;
esac
done

[[ $(($#-$OPTIND)) -lt 1 ]] && [[ "$URI" = '%' && "$TYPE" = '%' && "$EXT" = '%' ]] && {
	echo "$0 [opts] words.db QUERY"
	echo "opts:"
	echo "  -u url"
	echo "  -t type"
	echo "  -e ext"
	echo "  -m match"
	echo "  -c count"
	echo "  -o offset"
	exit
}

DB="${@:$OPTIND:1}"
shift $OPTIND
echo "SELECT uri,type,text FROM words WHERE uri LIKE '$URI' and type LIKE '$TYPE' and ext LIKE '$EXT' and text LIKE '%$*%' limit $LIMIT offset $OFFSET;" | sqlite3 -separator '%' "$DB" | while IFS='%' read uri type text
do
	echo "${GREEN}$uri ${YELLOW}[$type]${RESET}"
	echo "$text" | grep -i -o -P ".{0,$MATCH}$*..{0,$MATCH}" | grep -i --color=auto "$*"
	echo ""
done
