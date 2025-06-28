#!/bin/bash

./files.sh
for files in smb-files-*.txt
do
	IFS='-' read host share <<< $(echo "${files:10:-4}")
	echo "smb://$host/$share"
	./cover.py "../smb-all/.smb_${host}_${share//\//_}.sess" "$files" "coverage-$host-$share.html"
done
