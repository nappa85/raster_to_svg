#!/bin/bash
GIF=${1/.png/.gif};
SVG=${1/.png/.svg};
echo "$1 -> $SVG";
W=`identify -format "%[fx:w]" $1`;
H=`identify -format "%[fx:h]" $1`;
# convert to gif with 64 indexed colors, trying to eliminate dust spots
convert $1 -colors 64 -morphology open disk:1 $GIF;
# list colors
COLORS=`convert $GIF -unique-colors txt: | egrep -o "\#([A-F0-9]{6})FF"`;
# start global svg
echo '<?xml version="1.0" standalone="no"?>' > $SVG;
echo '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">' >> $SVG;
echo "<svg version=\"1.0\" xmlns=\"http://www.w3.org/2000/svg\" width=\"${W}pt\" height=\"${H}pt\" viewBox=\"0 0 $W $H\" preserveAspectRatio=\"xMidYMid meet\">" >> $SVG;
for i in $COLORS; do
  COLOR=${i:1:-2};
  COLOR_GIF=${1/.png/_$COLOR.gif};
  COLOR_BMP=${1/.png/_$COLOR.bmp};
  COLOR_SVG=${1/.png/_$COLOR.svg};
  # extract a single color
  convert $GIF +transparent \#$COLOR $COLOR_GIF
  # replace the color with white and expand the area to avoid void spaces between areas
  convert $COLOR_GIF -fill \#FFFFFF -opaque \#$COLOR -morphology dilate disk:1 $COLOR_BMP
  # convert to svg
  potrace -s --group -i -k 0 -C \#$COLOR $COLOR_BMP -o $COLOR_SVG;
  # merge with global svg
  LINES=`cat $COLOR_SVG | wc -l`;
  tail -n $((LINES-9)) $COLOR_SVG | head -n $((LINES-10)) >> $SVG;
  # cleanup
  rm $COLOR_GIF;
  rm $COLOR_BMP;
  rm $COLOR_SVG;
done
# close global svg
echo '</svg>'  >> ${1/.png/.svg};
# cleanup
rm $GIF;
