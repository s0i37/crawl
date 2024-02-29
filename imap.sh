#!/bin/bash

[[ $# -lt 1 ]] && {
	echo "$0 imap://server.com [user:pass]"
	echo "example: $0 imaps://imap.gmail.com someuser:somepass"
	exit
}

SERVER=$1
[[ $# -lt 2 ]] && { echo "enter user:pass"; read CREDS; } || CREDS=$2
EMAIL="${CREDS%%:*}"

function get_folders(){
	curl -s --insecure --user "$CREDS" "$SERVER" |
	sed -rn 's/.* ([^\s]+)/\1/p'
}

function get_messages_count(){
	folder=$1
	curl -s --insecure --user "$CREDS" "$SERVER" -X "EXAMINE $folder" |
	grep EXISTS |
	sed -rn 's/\* ([0-9]+) .*/\1/p'
}

function get_messages(){
	folder=$1
	messages_count=$2
	curl -s --insecure --user "$CREDS" "$SERVER/$folder;UID=[1-$messages_count]" > "messages.eml"
	csplit "messages.eml" '/^Return-Path:/' '{*}' > /dev/null
	rm messages.eml xx00
}

mkdir "$EMAIL" && pushd "$EMAIL" > /dev/null
for folder in $(get_folders)
do
	folder=$(echo $folder | tr -d '\r')
	mkdir "$folder" && pushd "$folder" > /dev/null
	max=$(get_messages_count "$folder")
	echo "[+] $folder $max messages"
	get_messages $folder $max
	popd > /dev/null
done
popd > /dev/null