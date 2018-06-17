#!/bin/sh
# rrd_cpu.sh
# cpu usage stats

# set db directory
rrdtool=/usr/bin/rrdtool
ds_name=cpu_temp


#directory to store graphs - DO NOT REMOVE $ds_name
img=/PATH/To/CHANGE/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/PATH/To/CHANGE/db/$ds_name.rrd


#data=`/usr/bin/sensors | /usr/bin/grep Physical | /usr/bin/grep -o  -e '[0-9]\{2,\}\.[0-9]\{1\}' | /usr/bin/head -1`
cpu_temp=$((`cat /sys/devices/platform/coretemp.0/hwmon/hwmon3/temp1_input` / 1000))
fan_rpm=$((`cat /sys/devices/platform/nct6775.2592/hwmon/hwmon[0-9]/fan2_input` ))

if [ ! -e $db ]
then
 rrdtool create $db \
  --step 60 \
  DS:cpu_temp:GAUGE:120:0:100 \
  DS:fan_rpm:GAUGE:120:0:2500 \
  RRA:MAX:0.5:1:44640
fi

echo "Updating RRD $ds_name with value $cpu_temp, $fan_rpm"
$rrdtool update $db N:$cpu_temp:$fan_rpm


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
   --right-axis-label 'CPU FAN Speed (RPM)
' \
  --lower-limit 30  \
  --rigid \
  --right-axis 1:0 \
  --units-exponent 0 \
  $x_axis \
   --disable-rrdtool-tag \
   DEF:cpu_temp="$db":cpu_temp:MAX \
   DEF:fan_rpm="$db":fan_rpm:MAX \
   AREA:cpu_temp#00FF00:"Temperature (°C)"\
  # LINE:fan_rpm#FF69B4:"CPU FAN Speed"
done



#   LINE:fan_rpm#FF69B4:"CPU FAN Speed"
#   DEF:fan_rpm="$db":fan_rpm:MAX \
#    --alt-y-grid --rigid \

