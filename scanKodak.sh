#!/bin/bash

# Scans from a hard-coded scanner to a pdf in the current directory

TMPFILE=$(tempfile)

gs='-type Grayscale'
qual='50%'

# Get options
while getopts ":f:cq" Option
do
  case $Option in
    f ) FILE=$OPTARG;;
		c ) gs='';;
		q ) qual='85%';;
  esac
done


# Check if file is set
if [[ ! "$FILE" ]]
then
	FILE="$(date +"%s").pdf"
fi

echo Will output to file "$FILE"

#Scan file and create pdf
scanimage  --format tiff -p --batch=$TMPFILE%04d.tiff --source 'ADF Duplex' --resolution 150

#for f in $(ls $TMPFILE*.tiff | sort); do echo $f; convert -type Grayscale  -quality 50% $f $f.jpg; convert $f.jpg $f.jpg.pdf; done
for f in $(ls $TMPFILE*.tiff | sort); do echo $f; convert $gs -quality $qual $f $f.jpg; convert -page A4 $f.jpg $f.jpg.pdf; done

pdftk $(ls $TMPFILE*.tiff.jpg.pdf | sort) cat output $TMPFILE.all.pdf

#Output to given file
if [[ ! -f $FILE ]]
then
	#File does not exist. This is easy
	echo Creating new PDF $FILE
	cp "$TMPFILE.all.pdf" "$FILE"
else
	#File exists. cat'ing files together
	echo Appending to existing PDF $FILE
	mv "$FILE" "$FILE.tmp.pdf"
	pdftk "$FILE.tmp.pdf" $TMPFILE.all.pdf cat output "$FILE"
	rm "$FILE.tmp.pdf"
fi


rm $TMPFILE*
