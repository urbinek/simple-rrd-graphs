#!/bin/sh
set -e
# memory usage stats

# DEFine global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=zfs_hdd

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
max_value=70
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

# ZFS HDD
WDC_WD10JPVX_WX71AC7ARRV8=$(hddtemp -n //dev/disk/by-id/ata-WDC_WD10JPVX-00JC3T0_WD-WX71AC7ARRV8)
WDC_WD10JPVX_WXA1AB72FXA7=$(hddtemp -n //dev/disk/by-id/ata-WDC_WD10JPVX-00JC3T0_WD-WXA1AB72FXA7)
WDC_WD10JPVX_WXE1AA7KK82C=$(hddtemp -n //dev/disk/by-id/ata-WDC_WD10JPVX-00JC3T0_WD-WXE1AA7KK82C)
WDC_WD10JPVX_WXR1AB7PD9N5=$(hddtemp -n //dev/disk/by-id/ata-WDC_WD10JPVX-00JC3T0_WD-WXR1AB7PD9N5)
WDC_WD20EFRX=$(hddtemp -n /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M0856843)

if [ ! -e $db ]; then
 rrdtool create $db \
  --step $step \
  DS:wdc-wx71ac7arrv8:GAUGE:$hbeat:$min_value:$max_value \
  DS:wdc-wxa1ab72fxa7:GAUGE:$hbeat:$min_value:$max_value \
  DS:wdc-wxe1aa7kk82c:GAUGE:$hbeat:$min_value:$max_value \
  DS:wdc-wxr1ab7pd9n5:GAUGE:$hbeat:$min_value:$max_value \
  DS:wdc-wd20efrx:GAUGE:$hbeat:$min_value:$max_value \
  RRA:AVERAGE:0.5:1:$steps
fi

echo "Updating RRD $ds_name with values: $WDC_WD10JPVX_WX71AC7ARRV8, $WDC_WD10JPVX_WXA1AB72FXA7, $WDC_WD10JPVX_WXE1AA7KK82C, $WDC_WD10JPVX_WXR1AB7PD9N5, $WDC_WD20EFRX"
$rrdtool update $db N:$WDC_WD10JPVX_WX71AC7ARRV8:$WDC_WD10JPVX_WXA1AB72FXA7:$WDC_WD10JPVX_WXE1AA7KK82C:$WDC_WD10JPVX_WXR1AB7PD9N5:$WDC_WD20EFRX

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
   --title "hdd_pool HDD temps (°C)" \
   --watermark "`date`" \
   $x_axis \
   --lower-limit $((min_value + 5)) \
   --rigid \
   --base=1000 \
   DEF:wdc-wx71ac7arrv8=$db:wdc-wx71ac7arrv8:AVERAGE \
   DEF:wdc-wxa1ab72fxa7=$db:wdc-wxa1ab72fxa7:AVERAGE \
   DEF:wdc-wxe1aa7kk82c=$db:wdc-wxe1aa7kk82c:AVERAGE \
   DEF:wdc-wxr1ab7pd9n5=$db:wdc-wxr1ab7pd9n5:AVERAGE \
   DEF:wdc-wd20efrx=$db:wdc-wd20efrx:AVERAGE \
   LINE1:wdc-wx71ac7arrv8#FFE119:"wdc-wx71ac7arrv8": \
   LINE1:wdc-wxa1ab72fxa7#BFEF45:"wdc-wxa1ab72fxa7": \
   LINE1:wdc-wxe1aa7kk82c#3CB44B:"wdc-wxe1aa7kk82c": \
   LINE1:wdc-wxr1ab7pd9n5#42D4F4:"wdc-wxr1ab7pd9n5": \
   LINE1:wdc-wd20efrx#4363D8:"wdc-wd20efrx":
done

