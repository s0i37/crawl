#!/bin/bash

[ $# -lt 1 ] && {
	echo "$0 out_dir/"
	echo "example: ./crawl.sh /mnt/share/ | $0 images/"
	echo "example: ./crawl.sh ./www.site.com/ | $0 images/"
	exit
}
out_dir="$1"

mkdir "$out_dir" 2> /dev/null
while read line
do echo -n "$line"
	read filetype filepath <<< $(echo "$line" | sed -e 's/\x1b\[[0-9;]*m//g' | rev)
	filepath=$(echo "$filepath" | rev)
	filetype=$(echo "$filetype" | rev)
	if [ "$filetype" = '[image]' ]; then
		convert -resize '640x480' "$filepath" "$out_dir/${filepath//\//-}" 2> /dev/null || cp "$filepath" "$out_dir/${filepath//\//-}"
		echo -n "$out_dir/${filepath//\//-}"
	fi
	echo ''
done