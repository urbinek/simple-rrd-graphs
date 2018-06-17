#!/bin/sh
# cpu usage stats
#
#

# define global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=cpu_load

#directory to store graphs - DO NOT REMOVE $ds_name
img=/PATH/To/CHANGE/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/PATH/To/CHANGE/db/$ds_name.rrd
# heartbeat time(s) wihout data
hbeat=120
# minimum value to be stored in db
min_value=0
# maximum value to be stored in db
max_value=16
# amount of time(s) we expect data to be updated into the database
step=60
# how many "steps" we will store in the db,
# for 1 month with 60s step 60*24*31
steps=44640

# define data collection command
data=`awk '{print $2}' /proc/loadavg`


# create db
if [ ! -e $db ]
then
 rrdtool create $db \
  --step $step \
  DS:$ds_name:GAUGE:$hbeat:$min_value:$max_value \
  RRA:MAX:0.5:1:$steps
fi

# fill db with data
echo "Updating RRD $ds_name with value $data"
$rrdtool update $db --template $ds_name N:$data


# generate graph from db
for period in day week month ; do

case $period in
  "day")   x_axis="--x-grid MINUTE:10:HOUR:1:MINUTE:120:0:%R" ;;
  "week")  x_axis="--x-grid HOUR:12:DAY:1:DAY:1:0:%A" ;;
  "month") x_axis="--x-grid WEEK:1:WEEK:1:DAY:1:0:%d"  ;;
  *) x_axis=" "
esac

  $rrdtool graph "$img"-"$period".png \
   -w 785 -h 120 -a PNG \
   --slope-mode \
   --disable-rrdtool-tag \
   --start end-1"$period" --end now \
   --font DEFAULT:7: \
   --color CANVAS#35373C \
   --title "System CPU average load (8 cores)" \
   --watermark "`date`" \
   --vertical-label 'Average CPU load' \
   --right-axis-label 'Average CPU load
' \
  $x_axis \
   --lower-limit 0 \
   --rigid \
   --alt-autoscale \
   --right-axis 1:0 \
   --right-axis-format "%.1lf" \
   DEF:roundtrip="$db":"$ds_name":MAX \
   AREA:roundtrip#00FF00:"Average CPU load"

done

