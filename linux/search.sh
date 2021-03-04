#!/bin/bash

GREEN=$'\x1b[32m'
RESET=$'\x1b[39m'

LIMIT=10
OFFSET=1

while getopts "c:o:" opt
do
	case $opt in
		c) LIMIT=$OPTARG;;
		o) OFFSET=$OPTARG;;
esac
done

[[ $(($#-$OPTIND)) -lt 1 ]] && {
	echo $0 [opts] words.db SQL_QUERY
	echo "opts:"
	echo "  -c count"
	echo "  -o offset"
	exit
}

DB="${@:$OPTIND:1}"
shift $OPTIND
echo $GREEN
#echo "SELECT uri FROM words WHERE text MATCH '$*' limit $LIMIT offset $OFFSET;" | sqlite3 "$DB"
echo "SELECT uri FROM words WHERE text LIKE '%$*%' limit $LIMIT offset $OFFSET;" | sqlite3 "$DB"
echo $RESET
#echo "SELECT text FROM words WHERE text MATCH '$*' limit $LIMIT offset $OFFSET;" | sqlite3 "$DB" | grep -o -P ".{0,100}$*..{0,100}" | grep --color=auto "$*"
echo "SELECT text FROM words WHERE text LIKE '%$*%' limit $LIMIT offset $OFFSET;" | sqlite3 "$DB" | grep -o -P ".{0,100}$*..{0,100}" | grep --color=auto "$*"