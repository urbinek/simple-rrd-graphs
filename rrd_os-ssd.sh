#!/bin/sh
set -e
# memory usage stats

# DEFine global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=os_ssd

#directory to store graphs - DO NOT REMOVE $ds_name
img=/zfs/ssd/www/rrd/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/zfs/ssd/pool/rrd/db/$ds_name.rrd

# heartbeat time(s) wihout data
hbeat=120
# minimum value to be stored in db
min_value=30
# maximum value to be stored in db
max_value=35
# amount of time(s) we expect data to be updated into the database
step=60
# how many "steps" we will store in the db,
# for 1 month with 60s step 60*24*31
steps=44640

# ssd_disks=`find /dev/disk/by-id/ -name "temp-*" -not -name "*part*" -exec basename {} \;`
# ssd_disks=`ls -1 /dev/disk/by-id/ata* | grep -v part`

# for disk in ${ssd_disks[@]} ; do
#  #echo "$(basename $disk): $(hddtemp -n $disk)"
#  printf "%s:\t\t%s\n" $(basename $disk) $(hddtemp -n $disk)
# done

# OS
SSDPR_S25A=$(hddtemp -n /dev/disk/by-id/ata-IR-SSDPR-S25A-120_GUL036145)
SSDPR_CX400=$(hddtemp -n /dev/disk/by-id/ata-SSDPR-CX400-128_GUX007579)

if [ ! -e $db ]; then
 rrdtool create $db \
  --step $step \
  DS:ssdpr-s25a:GAUGE:$hbeat:$min_value:$max_value \
  DS:ssdpr-cx400:GAUGE:$hbeat:$min_value:$max_value \
  RRA:AVERAGE:0.5:1:$steps
fi

echo "Updating RRD $ds_name with values: $SSDPR_S25A, $SSDPR_CX400"
$rrdtool update $db N:$SSDPR_S25A:$SSDPR_CX400

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
   --title "System SSD temps (°C)" \
   --watermark "`date`" \
   $x_axis \
   --upper-limit $max_value \
   --lower-limit "$min_value" \
   --rigid \
   --base=1000 \
   DEF:ssdpr-s25a=$db:ssdpr-s25a:AVERAGE \
   DEF:ssdpr-cx400=$db:ssdpr-cx400:AVERAGE \
   LINE1:ssdpr-s25a#F58231:"ssdpr-s25a": \
   LINE1:ssdpr-cx400#FFE119:"ssdpr-cx400": 
done

