#!/bin/bash

[[ $# -ne 1 ]] && {
	echo $0 words.csv
	exit
}

db=$(basename "$1")
db="${db%.*}".db
[[ -e "$db" ]] || {
	echo "CREATE VIRTUAL TABLE words USING fts3(date DATETIME, uri TEXT, ext TEXT, type TEXT, text TEXT);" | sqlite3 "$db"
}

sqlite3 "$db" <<E
.separator ","
.import "$1" words
E

# https://www.sqlite.org/fts3.html