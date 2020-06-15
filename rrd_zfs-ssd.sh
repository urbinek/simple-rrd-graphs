#!/bin/sh
set -e
# memory usage stats

# DEFine global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=zfs_ssd

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

# ZFS SSD
SPCC_30010555175=$(hddtemp -n /dev/disk/by-id/ata-SPCC_Solid_State_Disk_30010555175)
SPCC_30010554596=$(hddtemp -n /dev/disk/by-id/ata-SPCC_Solid_State_Disk_30010554596)
QVO_S4CZNF0MA70255L=$(hddtemp -n /dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4CZNF0MA70255L)
QVO_S4CZNF0MA70526E=$(hddtemp -n /dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4CZNF0MA70526E)
QVO_S4CZNF0N320241K=$(hddtemp -n /dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4CZNF0N320241K)
QVO_S4CZNF0N320220N=$(hddtemp -n /dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4CZNF0N320220N)

if [ ! -e $db ]; then
 rrdtool create $db \
  --step $step \
  DS:sppc-30010555175:GAUGE:$hbeat:$min_value:$max_value \
  DS:sppc-30010554596:GAUGE:$hbeat:$min_value:$max_value \
  DS:qvo-s4cznf0ma70255l:GAUGE:$hbeat:$min_value:$max_value \
  DS:qvo-s4cznf0ma70526e:GAUGE:$hbeat:$min_value:$max_value \
  DS:qvo-s4cznf0n320241k:GAUGE:$hbeat:$min_value:$max_value \
  DS:qvo-s4cznf0n320220n:GAUGE:$hbeat:$min_value:$max_value \
  RRA:AVERAGE:0.5:1:$steps
fi

echo "Updating RRD $ds_name with values: $SPCC_30010555175, $SPCC_30010554596, $QVO_S4CZNF0MA70255L, $QVO_S4CZNF0MA70526E, $QVO_S4CZNF0N320241K, $QVO_S4CZNF0N320220N"
$rrdtool update $db N:$SPCC_30010555175:$SPCC_30010554596:$QVO_S4CZNF0MA70255L:$QVO_S4CZNF0MA70526E:$QVO_S4CZNF0N320241K:$QVO_S4CZNF0N320220N

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
   --title "ssd_pool SSD temps (°C)" \
   --watermark "`date`" \
   $x_axis \
   --lower-limit $((min_value + 5)) \
   --rigid \
   --base=1000 \
   DEF:sppc-30010555175=$db:sppc-30010555175:AVERAGE \
   DEF:sppc-30010554596=$db:sppc-30010554596:AVERAGE \
   DEF:qvo-s4cznf0ma70255l=$db:qvo-s4cznf0ma70255l:AVERAGE \
   DEF:qvo-s4cznf0ma70526e=$db:qvo-s4cznf0ma70526e:AVERAGE \
   DEF:qvo-s4cznf0n320241k=$db:qvo-s4cznf0n320241k:AVERAGE \
   DEF:qvo-s4cznf0n320220n=$db:qvo-s4cznf0n320220n:AVERAGE \
   LINE1:sppc-30010555175#FFE119:"sppc-30010555175": \
   LINE1:sppc-30010554596#BFEF45:"sppc-30010554596": \
   LINE1:qvo-s4cznf0ma70255l#3CB44B:"qvo-s4cznf0ma70255l": \
   LINE1:qvo-s4cznf0ma70526e#42D4F4:"qvo-s4cznf0ma70526e": \
   LINE1:qvo-s4cznf0n320241k#4363D8:"qvo-s4cznf0n320241k": \
   LINE1:qvo-s4cznf0n320220n#911EB4:"qvo-s4cznf0n320220n":
done

