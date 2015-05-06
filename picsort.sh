#!/bin/bash
rm ./error.txt
source="."
target="."
FILETYPES=("*.jpg" "*.jpeg" "*.png" "*.tif" "*.tiff" "*.gif" "*.xcf" "*.avi" "*.mov")
for x in "${FILETYPES[@]}"; do
    echo "Scanning for $x…"
    find "$source" -type f -iname "$x" | while read file ; do
	echo -n "$file"
	date=$(exiv2 "$file" 2> /dev/null | awk '/Image timestamp/ { print $4 }')
	if [ -z "$date" ]; then
	    date=$(stat -c %y "$file")
	    date=${date%% *}
	    date=${date//[-]/:}
	fi
	if [ -z "$date" ]; then
	    echo "$file" >> ./error.txt 
	    continue
	fi
	echo ""
	echo $date
	echo ""
	year=${date%%:*}
	month=${date%:*}
	month=${month#*:}
	day=${date##*:}
	mkdir -p "${target}/${year}"
	mkdir -p "${target}/${year}/${month}/${day}"
	mv -i "$file" "${target}/${year}/${month}/${day}"
    done
    echo ""
done;