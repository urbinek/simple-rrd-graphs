#!/bin/sh
# rrd_cpu.sh
# cpu usage stats

# set db directory
rrdtool=/usr/bin/rrdtool
ds_name=cpu_temp

#directory to store graphs - DO NOT REMOVE $ds_name
img=/zfs/ssd/www/rrd/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/zfs/ssd/pool/rrd/db/$ds_name.rrd

#data=`/usr/bin/sensors | /usr/bin/grep Physical | /usr/bin/grep -o  -e '[0-9]\{2,\}\.[0-9]\{1\}' | /usr/bin/head -1`
data=$((`cat /sys/devices/platform/coretemp.0/hwmon/hwmon1/temp1_input` / 1000))

if [ ! -e $db ]
then
 rrdtool create $db \
  --step 60 \
  DS:$ds_name:GAUGE:120:0:100 \
  RRA:AVERAGE:0.5:1:44640
fi

echo "Updating RRD $ds_name with value $data"
$rrdtool update $db --template $ds_name N:$data


for period in day week month ; do

case $period in
  "day")   x_axis="--x-grid MINUTE:10:HOUR:1:MINUTE:120:0:%R" ;;
  "week")  x_axis="--x-grid HOUR:12:DAY:1:DAY:1:0:%A" ;;
  "month") x_axis="--x-grid WEEK:1:WEEK:1:DAY:1:0:%d"  ;;
  *) x_axis=" "
esac

  $rrdtool graph "$img"-"$period".png \
   -w 900 -h 150 -a PNG \
   --slope-mode \
   --start end-1"$period" --end now \
   --font DEFAULT:7: \
   --title "CPU 0 $period Package temp" \
   --watermark "`date`" \
   --color CANVAS#35373C \
   --vertical-label 'Temperature (°C)' \
   --right-axis-label 'Temperature (°C)
' \
  $x_axis \
   --lower-limit 35 \
   --right-axis 1:0 \
   --alt-y-grid --rigid \
   --disable-rrdtool-tag \
   DEF:roundtrip="$db":"$ds_name":AVERAGE \
   AREA:roundtrip#00FF00:"Temperature (°C)"

done



#    --x-grid MINUTE:10:HOUR:1:MINUTE:120:0:%R \

