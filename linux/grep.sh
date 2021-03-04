#!/bin/bash

RED=$'\x1b[31m'
GREEN=$'\x1b[32m'
GREY=$'\x1b[90m'
RESET=$'\x1b[39m'

[[ $# -lt 1 ]] && {
	echo "$0 'needle' where/ [/usr/bin/find options]"
	echo "example: $0 /mnt/share/ -type f -size -10M ! -iname '*.wav' ! -iname '*.mp3'"
	exit
}

function fork(){
	needle="$1"
	tempdir="$2"
	ln -s "$(realpath $0)" "$tempdir/$(basename $0)"
	( cd "$tempdir"; "./$(basename $0)" "$needle" "${index%.*}" "${opts[@]}"; )
}

needle="$1"
shift
where="$1"
shift
opts=("$@")

find "$where" "${opts[@]}" -print |
while read path
do
	printf "\n"
	#echo -n "$path"
	#echo -n ","
	filename=$(basename "$path")
	filename=${filename%\?*}
	ext=${filename##*.}
	[[ $filename = $ext ]] && ext=''
	#echo -n "$ext"
	#echo -n ","
	mime=$(file -bi "$path")
	mime=${mime%' '*}
	case $mime in
		*/xml\;)
			content=$(cat "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[xml] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		*/*html*)
			codepage=$(uchardet "$path")
			content=$(cat "$path" | iconv -f $codepage | lynx -nolist -dump -stdin)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[html] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		text/*|*/*script\;)
			content=$(cat "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[text] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/msword\;)
			content=$(catdoc "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[doc] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/vnd.openxmlformats-officedocument.wordprocessingml.document\;)
			content=$(unzip -p "$path" | grep -a '<w:r' | sed 's/<w:p[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | grep -a -v '^[[:space:]]*$' | sed G)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[docx] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/vnd.ms-excel\;|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\;)
			content=$(xls2csv -x "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[xls] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/pdf\;)
			content=$(pdf2txt -t text "$path" 2> /dev/null)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[pdf] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/x-executable\;|application/x-ms-dos-executable\;)
			content=$(/opt/radare2/bin/rabin2 -z "$path" 2> /dev/null)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[exe] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/x-object\;|application/x-sharedlib|application/x-executable\;)
			content=$(/opt/radare2/bin/rabin2 -z "$path" 2> /dev/null)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[elf] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		application/*compressed*|application/*zip*|application/*rar*|application/*tar*|application/*gzip*)
			content=$(7z l "$path" | tail -n +13)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[archive] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			7z x "$path" -o"$temp/$path" 1> /dev/null 2> /dev/null
			fork "$needle" "$temp"
			rm -r "$temp"
			#break
			;;
		image/*)
			content=$(identify -verbose "$path" 2> /dev/null)
			#content=$(tesseract "$path" stdout -l eng; tesseract "$path" stdout -l rus)
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[img] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		message/*)
			content=$(mu view "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[message] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			cp "$path" "$temp/$path/"
			munpack -t -f -C "$(realpath $temp/$path)" "$(basename $path)" > /dev/null
			rm "$temp/$path/$(basename $path)"
			fork "$needle" "$temp"
			rm -r "$temp"
			#break
			;;
		application/octet-stream\;)
			#content=$(strings "$path")
			#if echo "$content"|grep -q -ai "$needle"; then
			#	echo $GREEN "[raw] $path" $RESET
			#	echo "$content"|grep -ai "$needle"
			#fi
			false
			;;
		application/x-raw-disk-image\;)
			content=$(binwalk "$path")
			if echo "$content"|grep -q -ai "$needle"; then
				echo $GREEN "[disk] $path" $RESET
				echo "$content"|grep -ai "$needle"
			fi
			;;
		*)
			echo -n "unknown,"
			file "$path" | grep -q text &&
			{
				content=$(cat "$path")
				if echo "$content"|grep -q -ai "$needle"; then
					echo $GREEN "[unknown] $path" $RESET
					echo "$content"|grep -ai "$needle"
				fi
			} || {
				content=$(strings "$path")
				if echo "$content"|grep -q -ai "$needle"; then
					echo $GREEN "[unknown] $path" $RESET
					echo "$content"|grep -ai "$needle"
				fi
			}
			;;
	esac
done