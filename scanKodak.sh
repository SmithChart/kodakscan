#!/bin/bash

# Scans from a hard-coded scanner to a pdf in the current directory

usage() {
  echo "scanKodak.sh [OPTIONS...]"
  echo
  echo "  -f FILE    Give output file name [default: \`date +%F %H%M%S\`]"
  echo "  -c         Scan in color [default: gray scale]"
  echo "  -q         Set output JPEG quality to 85% [default: 50%]"
  echo "  -r RES     Set resolution in dpi [default 150 dpi]"
}

gs='-type Grayscale'
qual='50%'
dpi='150'

# Get options
while getopts ":f:cqr:h" Option
do
  case $Option in
    f ) FILE=$OPTARG;;
    c ) gs='';;
    q ) qual='85%';;
    r ) dpi=$OPTARG;;
    h ) usage; exit;;
  esac
done

TMPFILE=$(mktemp)

# Check if file is set
if [[ ! "$FILE" ]]
then
	FILE="$(date +"%F %H%M%S").pdf"
fi

echo Will output to file "$FILE"

#Scan pages and store .tiffs
echo Starting scan...
scanimage --format tiff -p --batch=$TMPFILE%04d.tiff --source 'ADF Duplex' --resolution $dpi

#use imagemagick to compress all tiffs and glue them to a single pdf
echo Glueing pages...
convert $TMPFILE*.tiff $gs -quality $qual -density "$dpi"x"$dpi" -compress jpeg $TMPFILE.all.pdf

#Output to given file
if [[ ! -f $FILE ]]
then
	#File does not exist. This is easy
	echo Creating new PDF $FILE and fixing title.
	#creating tmpfile because pdftk's update_info apparently can't read inline
	echo -en "InfoKey: Title\nInfoValue: $FILE\n" > $TMPFILE.title
	#updating the title because "tmp.rvvk8ozNjn.pdf" just doesn't look good in the title bar, also moving the file away from tmp
	pdftk $TMPFILE.all.pdf update_info $TMPFILE.title output "$FILE"
else
	#File exists. cat'ing files together
	echo Appending to existing PDF $FILE
	mv "$FILE" "$FILE.tmp.pdf"
	pdftk "$FILE.tmp.pdf" $TMPFILE.all.pdf cat output "$FILE"
	rm "$FILE.tmp.pdf"
fi


rm $TMPFILE*
