#!/bin/sh
# memory usage stats

# define global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=memory

#directory to store graphs - DO NOT REMOVE $ds_name
img=/zfs/ssd/www/rrd/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/zfs/ssd/pool/rrd/db/$ds_name.rrd

# heartbeat time(s) wihout data
hbeat=120
# minimum value to be stored in db
min_value=0
# maximum value to be stored in db
max_value=$memtotal
# amount of time(s) we expect data to be updated into the database
step=60
# how many "steps" we will store in the db,
# for 1 month with 60s step 60*24*31
steps=44640



# get memory stats
# htop stype memry stats
# green + blue + orange
# Green: Used memory pages (calculated as total - free - buffers - cache)
# Blue: Buffer pages
# Orange: Cache pages
MemTotal=$(grep -w MemTotal: /proc/meminfo | awk '{print $2}')
MemFree=$(grep -w MemFree: /proc/meminfo | awk '{print $2}')
MemBuffers=$(grep -w Buffers: /proc/meminfo | awk '{print $2}')
MemCached=$(grep -w Cached: /proc/meminfo | awk '{print $2}')
MemUsed=$(($MemTotal - $MemFree - $MemBuffers - $MemCached))
MemZFS=$(grep -w size /proc/spl/kstat/zfs/arcstats | awk '{print $3}')

#memtotal=$MemTotal
#memfree=$MemFree
#membuff=$MemBuffers
#memcached=$MemCached
#memused=$MemUsed

memtotal=$(($MemTotal * 1024))
memfree=$(($MemFree * 1024))
membuff=$(($MemBuffers * 1024))
memcached=$(($MemCached * 1024))
memused=$(($MemUsed * 1024))
memzfs=$(($MemZFS))


if [ ! -e $db ]
then
 rrdtool create $db \
  --step $step \
  DS:memtotal:GAUGE:$hbeat:$min_value:$memtotal \
  DS:memfree:GAUGE:$hbeat:$min_value:$memtotal \
  DS:membuff:GAUGE:$hbeat:$min_value:$memtotal \
  DS:memcached:GAUGE:$hbeat:$min_value:$memtotal \
  DS:memused:GAUGE:$hbeat:$min_value:$memtotal \
  DS:memzfs:GAUGE:$hbeat:$min_value:$memtotal \
  RRA:AVERAGE:0.5:1:$steps
fi


echo "Updating RRD $ds_name with values: $memtotal:$memfree:$membuff:$memcached:$memused:$memzfs"
$rrdtool update $db  N:$memtotal:$memfree:$membuff:$memcached:$memused:$memzfs

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
   --title "System memory consumption" \
   --watermark "`date`" \
   --vertical-label='bytes' \
   $x_axis \
   --upper-limit $memtotal \
   --lower-limit '0' \
   --rigid \
   --base=1024 \
   DEF:total=$db:memtotal:AVERAGE \
   DEF:used=$db:memused:AVERAGE \
   DEF:free=$db:memfree:AVERAGE \
   DEF:buff=$db:membuff:AVERAGE \
   DEF:cached=$db:memcached:AVERAGE \
   DEF:zfs=$db:memzfs:AVERAGE \
   AREA:used#00FF00:"In use":STACK:skipscale \
   AREA:cached#FFa500:"Cached":STACK:skipscale \
   AREA:buff#0000FF:"Buffered":STACK:skipscale  \
   AREA:zfs#FF69B4cc:"ZFS ARC stats" \

done
