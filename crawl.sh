#!/bin/bash

RED=$'\x1b[31m'
GREEN=$'\x1b[32m'
GREY=$'\x1b[90m'
RESET=$'\x1b[39m'

[[ $# -lt 1 ]] && {
	echo "$0 where/ [/usr/bin/find options]"
	echo "example: $0 folder/ -size -10M -not -iname '*.wav' -not -iname '*.mp3'"
	echo "example: $0 smb/10.10.10.10/pub/ -not -ipath '*/Program Files*/*' -not -ipath '*/Windows/*'"
	echo "example: $0 http/10.10.10.10/ -newermt '2012-12-21 00:00'"
	exit
}

function session_file_done(){
	path="$1"
	echo "[$path]" >> "$session_file"
}

function session_is_file_done(){
	path="$1"
	fgrep "[$path]" "$session_file" 1> /dev/null 2> /dev/null && echo 1 || echo 0
}

function session_create(){
	session_file="$1"
	stat "$session_file" 1> /dev/null 2> /dev/null && echo 1 || {
		touch "$session_file"
		echo 0
	}
}

function session_close(){
	rm "$session_file"
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
	( cd "$tempdir"; "./$(basename $0)" "$where" "${opts[@]}"; )
}

where="${1//../}"
shift
opts=("$@")

if [[ ${where:0:1} = '.' || ${where:0:1} = '/' ]]; then
	echo "only relative direct path: $0 path/to/folder"
	exit
fi

index=${where//\//_}.csv
session_file=".${where//\//_}.sess"
is_resume=$(session_create "$session_file")

find "$where" "${opts[@]}" -type f -print 2> /dev/null |
while read path
do
	[[ $is_resume = 1 && $(session_is_file_done "$path") = 1 ]] && {
		echo $GREY"$path"$RESET
		continue
	}
	[[ -s "$index" ]] && printf "\n" >> "$index"
	echo -n "$(date +%s)," >> "$index"
	echo -n "$path"
	echo -n "$path" | escape >> "$index"
	echo -n "," >> "$index"
	filename=$(basename "$path")
	filename=${filename%\?*}
	ext=${filename##*.}
	[[ "$filename" = "$ext" ]] && ext=''
	echo -n "$ext" | escape >> "$index"
	echo -n "," >> "$index"
	mime=$(file -b --mime-type "$path")
	#mime=$(xdg-mime query filetype "$path")
	case "$mime" in
		*/*html*|application/javascript)
			echo -n "html," >> "$index"
			codepage=$(uchardet "$path")
			cat "$path" | iconv -f "$codepage" 2> /dev/null | lynx -nolist -dump -stdin | escape >> "$index"
			echo $GREEN " [html]" $RESET
			;;
		text/*|*/*script|*/xml|*/json|*-ini)
			echo -n "text," >> "$index"
			codepage=$(uchardet "$path")
			cat "$path" | iconv -f "$codepage" 2> /dev/null | escape >> "$index"
			echo $GREEN " [text]" $RESET
			;;
		application/msword)
			echo -n "doc," >> "$index"
			catdoc "$path" | escape >> "$index"
			echo $GREEN " [doc]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.wordprocessingml.document)
			echo -n "doc," >> "$index"
			unzip -p "$path" 2> /dev/null | grep -a '<w:r' | sed 's/<w:p[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | grep -a -v '^[[:space:]]*$' | sed G | escape >> "$index"
			echo $GREEN " [docx]" $RESET
			if unzip -l "$path" | grep -q 'word/media/'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'word/media/*' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/vnd.ms-excel)
			echo -n "xls," >> "$index"
			xls2csv -x "$path" | escape >> "$index"
			echo $GREEN " [xls]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
			echo -n "xls," >> "$index"
			#libreoffice --convert-to csv "$path" out.csv
			unzip -p "$path" 2> /dev/null | grep -a -e '<si><t' -e '<vt:lpstr>' | sed 's/<[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | escape >> "$index"
			echo $GREEN " [xlsx]" $RESET
			;;
		application/pdf)
			echo -n "pdf," >> "$index"
			pdf2txt -t text "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [pdf]" $RESET
			;;
		application/x-executable|application/*microsoft*-executable|application/x*dos*)
			echo -n "executable," >> "$index"
			rabin2 -qq -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [exe]" $RESET
			;;
		application/x-object|application/x-sharedlib|application/x-executable)
			echo -n "executable," >> "$index"
			rabin2 -qq -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [elf]" $RESET
			;;
		image/*)
			echo -n "image," >> "$index"
			#identify -verbose "$path" 2> /dev/null | escape >> "$index"
			tesseract "$path" stdout -l eng 2> /dev/null | escape >> "$index"
			tesseract "$path" stdout -l rus 2> /dev/null | escape >> "$index"
			#curl -s http://10.250.153.11/string_api -F "file=@$path" | escape >> "$index"
			echo $GREEN " [image]" $RESET
			;;
		audio/*)
			echo -n "audio," >> "$index"
			vosk-transcriber --lang en-us --input "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [audio]" $RESET
			;;
		application/*compressed*|application/*zip*|application/*rar*|application/*tar*|application/*gzip*|application/*-msi|*/java-archive)
			echo -n "archive," >> "$index"
			7z l -p '' "$path" 2> /dev/null | tail -n +13 | escape >> "$index"
			echo $GREEN " [archive]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			7z x -p '' "$path" -o"$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/vnd.ms-outlook)
			echo -n "message," >> "$index"
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			msgconvert --outfile "$temp/$path/out.eml" "$path" 2> /dev/null
			mu view "$temp/$path/out.eml" 2> /dev/null | escape >> "$index"
			echo $GREEN " [message]" $RESET
			munpack -t -f -C "$(realpath $temp/$path)" 'out.eml' > /dev/null
			rm "$temp/$path/out.eml"
			fork "$temp"
			rm -r "$temp"
			;;
		message/*)
			echo -n "message," >> "$index"
			mu view "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [message]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			cp "$path" "$temp/$path/"
			munpack -t -f -C "$(realpath $temp/$path)" "$(basename $path)" > /dev/null
			rm "$temp/$path/$(basename $path)"
			fork "$temp"
			rm -r "$temp"
			;;
		*.tcpdump.pcap)
			echo -n "pcap," >> "$index"
			tcpdump -r "$path" -nn -A | escape >> "$index"
			echo $GREEN " [pcap]" $RESET
			;;
		application/x-raw-disk-image)
			echo -n "disk," >> "$index"
			binwalk "$path" | escape >> "$index"
			echo $GREEN " [disk]" $RESET
			;;
		application/octet-stream)
			echo -n "raw," >> "$index"
			#strings "$path" | escape >> "$index"
			echo -n "" >> "$index"
			echo $GREEN " [raw]" $RESET
			;;
		*)
			file "$path" | grep text > /dev/null &&
			{
				echo -n "text," >> "$index"
				cat "$path" | escape >> "$index"
				echo $GREEN " [text]" $RESET
			} || {
				echo -n "unknown," >> "$index"
				#strings "$path" >> "$index"
				echo -n "" >> "$index"
				echo $RED " [unknown]" $RESET
				echo "$path $mime" >> unknown_mime.log
			}
			;;
	esac
	session_file_done "$path"
done

#session_close