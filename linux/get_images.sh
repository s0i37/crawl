#!/bin/bash

[[ $# -lt 1 ]] && {
	echo "$0 index_local_path [out_directory]"
	echo "example: $0 /mnt/share/"
	echo "example: $0 ./www.site.com/ images/"
	exit
}

[[ $# -ge 2 ]] && out_dir="$2"
for filepath in $(find "$1" -type f)
do
	mime=$(xdg-mime query filetype "$filepath")
	[[ $mime = *image* ]] && {
		echo $filepath
		[[ $out_dir ]] && cp "$filepath" "$out_dir/${filepath//\//-}"
	}
done