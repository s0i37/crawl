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

function save_image(){
	path="$1"
	SIZE='640x480'
	convert -resize $SIZE "$path" "$IMAGES/${path//\//-}" 2> /dev/null || cp "$path" "$IMAGES/${path//\//-}"
}

function fork(){
	tempdir="$1"
	ln -s "$(realpath $0)" "$tempdir/$(basename $0)"
	ln -s "$(realpath $index)" "$tempdir/$index"
	( cd "$tempdir"; "./$(basename $0)" "$where"; )
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
			echo -n "word," >> "$index"
			catdoc "$path" | escape >> "$index"
			echo $GREEN " [word]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.wordprocessingml.document)
			echo -n "word," >> "$index"
			unzip -p "$path" 2> /dev/null | grep -a '<w:r' | sed 's/<w:p[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | grep -a -v '^[[:space:]]*$' | sed G | escape >> "$index"
			echo $GREEN " [word]" $RESET
			if unzip -l "$path" | grep -q 'word/media/'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'word/media/*' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/vnd.ms-excel)
			echo -n "excel," >> "$index"
			xls2csv -x "$path" | escape >> "$index"
			echo $GREEN " [excel]" $RESET
			;;
		application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
			echo -n "excel," >> "$index"
			unzip -p "$path" 2> /dev/null | grep -a -e '<si><t' -e '<vt:lpstr>' | sed 's/<[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | escape >> "$index"
			echo $GREEN " [excel]" $RESET
			if unzip -l "$path" | grep -q 'xl/media/'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'xl/media/*' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/vnd.openxmlformats-officedocument.presentationml.presentation)
			echo -n "powerpoint," >> "$index"
			unzip -qc "$path" 'ppt/slides/slide*.xml' 2> /dev/null | grep -oP '(?<=\<a:t\>).*?(?=\</a:t\>)' | escape >> "$index"
			echo $GREEN " [powerpoint]" $RESET
			if unzip -l "$path" | grep -q 'ppt/media/'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'ppt/media/*' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/vnd.oasis.opendocument.graphics|application/vnd.ms-visio.drawing.main*)
			echo -n "visio," >> "$index"
			#LibreOffice
			unzip -qc "$path" 'content.xml' 2> /dev/null | grep -oP '(?<=\<text:p\>).*?(?=\</text:p\>)' | escape >> "$index"
			#Microsoft
			for page in $(unzip -qq -l "$path" 'visio/pages/*.xml' | awk '{print $NF}'); do
				unzip -qc "$path" "$page" | xq | grep -e '"#text":' -e '"@Name":' | cut -d : -f 2- | tr -d '"'
			done | escape >> "$index"
			echo $GREEN " [visio]" $RESET
			#LibreOffice
			if unzip -l "$path" | grep 'Pictures/' | grep -q -v 'TablePreview1.svm'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'Pictures/*.jpg' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			#Microsoft
			if unzip -l "$path" | grep -q 'visio/media/'; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				unzip "$path" 'visio/media/*' -d "$temp/$path" > /dev/null
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/pdf)
			echo -n "pdf," >> "$index"
			pdf2txt -t text "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [pdf]" $RESET
			if [ $(pdfimages -list "$path" | tail -n +3 | wc -l) -ge 1 ]; then
				temp=$(tempfile 2>/dev/null)
				rm "$temp" && mkdir -p "$temp/$path"
				pdfimages -all "$path" "$temp/$path/img"
				fork "$temp"
				rm -r "$temp"
			fi
			;;
		application/x-ms-shortcut)
			echo -n "lnk," >> "$index"
			lnkinfo "$path" 2> /dev/null | grep -e 'String' | cut -d ' ' -f 2- | escape >> "$index"
			echo $GREEN " [lnk]" $RESET
			;;
		application/x-executable|application/*microsoft*-executable|application/x*dos*)
			echo -n "executable," >> "$index"
			rabin2 -qq -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [exe]" $RESET
			;;
		application/x-object|application/x-sharedlib|application/x-executable|application/x-pie-executable)
			echo -n "executable," >> "$index"
			rabin2 -qq -z "$path" 2> /dev/null | escape >> "$index"
			echo $GREEN " [elf]" $RESET
			;;
		image/*)
			LANGS=(eng rus)
			echo -n "image," >> "$index"
			identify -verbose "$path" 2> /dev/null | grep -e 'Geometry:' -e 'User Comment:' | escape >> "$index"
			for lang in ${LANGS[*]}; do
				tesseract "$path" stdout -l $lang 2> /dev/null | escape >> "$index"
			done
			[ -n "$IMAGES" ] && save_image "$path"
			#curl -s http://10.250.153.11/string_api -F "file=@$path" | escape >> "$index"
			echo $GREEN " [image]" $RESET
			;;
		audio/*)
			LANGS=(en-us ru)
			echo -n "audio," >> "$index"
			ffmpeg -i "$path" 2>&1 | grep -e 'Duration:' | escape >> "$index"
			for lang in ${LANGS[*]}; do
				vosk-transcriber --lang $lang --input "$path" 2> /dev/null | escape >> "$index"
			done
			echo $GREEN " [audio]" $RESET
			;;
		video/*)
			FPS=1
			echo -n "video," >> "$index"
			ffmpeg -i "$path" 2>&1 | grep -e 'Duration:' -e 'Stream' | escape >> "$index"
			echo $GREEN " [video]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			ffmpeg -i "$path" -acodec copy "$temp/$path/audio.aac" 1> /dev/null 2> /dev/null
			ffmpeg -i "$path" -vf fps=$FPS "$temp/$path/frame%d.png" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/x-ole-storage)
			echo -n "thumbsdb," >> "$index"
			echo $GREEN " [thumbsdb]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			vinetto "$path" -o "$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/*compressed*|application/*zip*|application/*rar*|application/*tar*|application/*gzip*|application/*-msi|*/java-archive|application/x-archive)
			echo -n "archive," >> "$index"
			7z l -p '' "$path" 2> /dev/null | tail -n +13 | escape >> "$index"
			echo $GREEN " [archive]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			7z x -p '' "$path" -o"$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/x-installshield)
			echo -n "archive," >> "$index"
			echo $GREEN " [cab]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			cabextract -d "$temp/$path" "$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/x-rpm)
			echo -n "package," >> "$index"
			echo $GREEN " [rpm]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			rpm2cpio "$path" | cpio -idmuv --no-absolute-filenames -p "$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/vnd.debian.binary-package)
			echo -n "package," >> "$index"
			echo $GREEN " [deb]" $RESET
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			dpkg --extract "$path" "$temp/$path" 1> /dev/null 2> /dev/null
			fork "$temp"
			rm -r "$temp"
			;;
		application/x-bytecode.python)
			echo -n "bytecode," >> "$index"
			pycdc "$path" 2> /dev/null | tail -n +5 | escape >> "$index"
			echo $GREEN " [bytecode]" $RESET
			;;
		application/x-ms-evtx)
			echo -n "winevent," >> "$index"
			evtx "$path" -o jsonl | escape >> "$index"
			echo $GREEN " [evtx]" $RESET
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
		application/*sqlite3)
			echo -n "sqlite," >> "$index"
			sqlite3 "$path" '.dump' 2> /dev/null | escape >> "$index"
			echo $GREEN " [sqlite]" $RESET
			;;
		*.tcpdump.pcap)
			echo -n "pcap," >> "$index"
			tcpdump -r "$path" -nn -A | escape >> "$index"
			echo $GREEN " [pcap]" $RESET
			;;
		application/x-raw-disk-image|application/x-qemu-disk|application/x-virtualbox-vdi|application/x-virtualbox-vmdk)
			echo -n "disk," >> "$index"
			qemu-system-x86_64 -hda disk.img -m 256M -net nic -net user -display none -snapshot -hdb "$path"
			nc -nv -lp 5555 << EE | escape >> $index
for part in /dev/sdb*
do echo $part
  if mount $part /mnt/ -o ro; then
    cd /mnt/
    cat etc/shadow
    cat root/.bash_history
    cat home/*/.bash_history
    cd -
    umount /mnt
  elif mount -t ntfs $part /mnt/ -o ro; then
    cd /mnt/
    find Users/*/Desktop
    find Users/*/Documents
    for history in Users/*/AppData/Local/Google/Chrome/User\ Data/Default/History
    do echo 'select * from urls;' | sqlite3 "$history"
    done
    if [ -f Windows/System32/config/SAM ]; then
      secretsdump.py -sam Windows/System32/config/SAM -security Windows/System32/config/SECURITY -system Windows/System32/config/SYSTEM LOCAL
    fi
    cd -
    umount /mnt
  fi
done 2>/dev/null
EE
			echo $GREEN " [disk]" $RESET
			;;
		application/octet-stream)
			echo -n "raw," >> "$index"
			temp=$(tempfile 2>/dev/null)
			rm "$temp" && mkdir -p "$temp/$path"
			binwalk -e "$path" -C "$temp/$path" | tail -n +4 | escape >> "$index"
			echo $GREEN " [raw]" $RESET
			fork "$temp"
			rm -r "$temp"
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