#!/bin/bash

RED=$'\x1b[31m'
GREEN=$'\x1b[32m'
GREY=$'\x1b[90m'
RESET=$'\x1b[39m'

[[ $# -lt 1 ]] && {
	echo "$0 where/ [/usr/bin/find options]"
	echo "example: $0 /mnt/share/ -size -10M ! -iname '*.wav' ! -iname '*.mp3'"
	exit
}

function session_file_done(){
	path="$1"
	echo "$path" >> "$session_file"
}

function session_is_file_done(){
	path="$1"
	grep "$path" "$session_file" 1> /dev/null 2> /dev/null && echo 1 || echo 0
}

function session_create(){
	session_file="$1"
	stat "$session_file" 1> /dev/null 2> /dev/null && echo 1 || {
		touch "/tmp/$session_file"
		ln -s "/tmp/$session_file" "$session_file"
		echo 0
	}
}

function session_close(){
	rm "$session_file"
	rm "/tmp/$session_file"
}

function escape(){
	echo -n '"'
	while read line
	do
		echo -n "$line" | tr -d ',"\r\n'
	done
	echo -n "$line" | tr -d ',"\r\n'
	echo -n '"'
}

function fork(){
	tempdir="$1"
	ln -s "$(realpath $0)" "$tempdir/$(basename $0)"
	ln -s "$(realpath $index)" "$tempdir/$index"
	( cd "$tempdir"; "./$(basename $0)" "${index%.*}" "${opts[@]}"; )
}

index=$(basename "$1").csv
session_file=".$(basename "$1").sess"
is_resume=$(session_create "$session_file")

where="$1"
shift
opts=("$@")

find "$where" "${opts[@]}" -type f -print 2> /dev/null |
while read path
do
	[[ $is_resume = 1 && $(session_is_file_done $path) = 1 ]] && {
		echo "(skip $path)"
		continue
	}
	printf "\n" >> "$index"
	echo -n "$(date +%s)," >> "$index"
	echo -n "$path"
	echo -n "$path" | escape >> "$index"
	echo -n "," >> "$index"
	filename=$(basename "$path")
	filename=${filename%\?*}
	ext=${filename##*.}
	[[ $filename = $ext ]] && ext=''
	echo -n "$ext" | escape >> "$index"
	echo -n "," >> "$index"
	mime=$(file -bi "$path")
	mime=${mime%' '*}
	case $mime in
		*/xml\;)
			echo -n "xml," >> "$index"
			cat "$path" | escape >> "$index"
			echo $GREEN " [xml]" $RESET
			;;
		*/*html*)
			echo -n "html," >> "$index"
			codepage=$(uchardet "$path")
			cat "$path" | iconv -f $codepage | lynx -nolist -dump -stdin | escape >> "$index"
			echo $GREEN " [html]" $RESET
			;;
		text/*|*/*script\;)
			echo -n "text," >> "$index"
			cat "$path" | escape >> "$index"
			echo $GREEN " [text]" $RESET
			;;
		application/msword\;)
			echo -n "doc," >> "$index"
			catdoc "$path" | escape >> "$index"
			echo $GREEN " [doc]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.wordprocessingml.document\;)
			echo -n "doc," >> "$index"
			unzip -p "$path" | grep -a '<w:r' | sed 's/<w:p[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | grep -a -v '^[[:space:]]*$' | sed G | escape >> "$index"
			echo $GREEN " [docx]" $RESET
			;;
		application/vnd.ms-excel\;)
			echo -n "xls," >> "$index"
			xls2csv -x "$path" | escape >> "$index"
			echo $GREEN " [xls]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\;)
			echo -n "xlsx," >> "$index"
			unzip -p "$path" | grep -a -e '<si><t>' -e '<vt:lpstr>' | sed 's/<[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | escape >> "$index"
			echo $GREEN " [xlsx]" $RESET
			;;
		application/pdf\;)
			echo -n "pdf," >> "$index"
			pdf2txt -t text "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [pdf]" $RESET
			;;
		application/x-executable\;|application/x*dos*)
			echo -n "exe," >> "$index"
			rabin2 -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [exe]" $RESET
			;;
		application/x-object\;|application/x-sharedlib|application/x-executable\;)
			echo -n "elf," >> "$index"
			rabin2 -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [elf]" $RESET
			;;
		application/*compressed*|application/*zip*|application/*rar*|application/*tar*|application/*gzip*)
			echo -n "zip," >> "$index"
			7z l "$path" | tail -n +13 | escape >> "$index"
			echo $GREEN " [archive]" $RESET
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			7z x "$path" -o"$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			session_file_done $path
			#break
			;;
		image/*)
			echo -n "image," >> "$index"
			identify -verbose "$path" 2> /dev/null | escape >> "$index"
			#tesseract "$path" stdout -l eng >> "$index"
			#tesseract "$path" stdout -l rus >> "$index"
			echo $GREEN " [img]" $RESET
			;;
		message/*)
			echo -n "message," >> "$index"
			mu view "$path" | escape >> "$index"
			echo $GREEN " [message]" $RESET
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			cp "$path" "$temp/$path/"
			munpack -t -f -C "$(realpath $temp/$path)" "$(basename $path)" > /dev/null
			rm "$temp/$path/$(basename $path)"
			fork "$temp"
			rm -r "$temp"
			session_file_done $path
			#break
			;;
		application/octet-stream\;)
			echo -n "raw," >> "$index"
			#strings "$path" | escape >> "$index"
			echo -n "," >> "$index"
			echo $GREEN " [raw]" $RESET
			;;
		application/x-raw-disk-image\;)
			echo -n "disk," >> "$index"
			binwalk "$path" | escape >> "$index"
			echo $GREEN " [disk]" $RESET
			;;
		*)
			echo -n "unknown," >> "$index"
			file "$path" | grep text > /dev/null &&
			{
				cat "$path" | escape >> "$index"
				echo $GREY " [unknown]" $RESET
			} || {
				#strings "$path" >> "$index"
				echo -n "," >> "$index"
				echo "$path $mime" >> unknown_mime.log
				echo $RED " [error]" $RESET
			}
			;;
	esac
	session_file_done $path
done

session_close