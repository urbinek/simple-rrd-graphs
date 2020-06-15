#!/bin/sh
set -e
# memory usage stats

# DEFine global parms
# rrd path
rrdtool=/usr/bin/rrdtool

# name of dataset, will be uset to generate db and graphs
ds_name=ZaCapioryMali

#directory to store graphs - DO NOT REMOVE $ds_name
img=/zfs/ssd/www/ZaCapiory/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/zfs/ssd/pool/rrd/db/$ds_name.rrd

# heartbeat time(s) wihout data
hbeat=1200
# amount of time(s) we expect data to be updated into the database
step=600
# how many "steps" we will store in the db,
# for 1 month with 60s step 60*24*31
steps=4464

stats=$(curl --silent  https://stats.foldingathome.org/api/team/250683 | jq -r '.donors[] | "\(.name)_\(.credit)"')

MichalR=$(echo "$stats" | grep "MichalR" | cut -d'_' -f 2)
lksilesian=$(echo "$stats" | grep "lksilesian" | cut -d'_' -f 2)
Bartek=$(echo "$stats" | grep "Bartek" | cut -d'_' -f 2)
MateuszL=$(echo "$stats" | grep "MateuszL" | cut -d'_' -f 2)
xmesaj2=$(echo "$stats" | grep "xmesaj2" | cut -d'_' -f 2)
nataliad2412=$(echo "$stats" | grep "nataliad2412" | cut -d'_' -f 2)
blazejpoland=$(echo "$stats" | grep "blazejpoland" | cut -d'_' -f 2)
Blazejej=$(echo "$stats" | grep "Blazejej" | cut -d'_' -f 2)
Kamps=$(echo "$stats" | grep "Kamps" | cut -d'_' -f 2)
NATKA=$(echo "$stats" | grep "NATKA" | cut -d'_' -f 2)

grand_score=$(($MichalR + $lksilesian + $MateuszL + $Bartek + $xmesaj2 + $nataliad2412 + $blazejpoland + $Blazejej + $Kamps + $NATKA))
divide=2

if [ ! -e $db ]; then
 rrdtool create $db \
  --step $step \
  DS:MichalR:GAUGE:$hbeat:0:U \
  DS:lksilesian:GAUGE:$hbeat:0:U \
  DS:Bartek:GAUGE:$hbeat:0:U \
  DS:MateuszL:GAUGE:$hbeat:0:U \
  DS:xmesaj2:GAUGE:$hbeat:0:U \
  DS:nataliad2412:GAUGE:$hbeat:0:U \
  DS:blazejpoland:GAUGE:$hbeat:0:U \
  DS:Blazejej:GAUGE:$hbeat:0:U \
  DS:Kamps:GAUGE:$hbeat:0:U \
  DS:NATKA:GAUGE:$hbeat:0:U \
  RRA:AVERAGE:0.5:1:$steps
fi

echo "Updating RRD $ds_name with values: $MichalR, $lksilesian, $MateuszL, $Bartek, $xmesaj2, $nataliad2412, $blazejpoland, $Blazejej, $Kamps, $NATKA"
$rrdtool update $db N:$MichalR:$lksilesian:$MateuszL:$Bartek:$xmesaj2:$nataliad2412:$blazejpoland:$Blazejej:$Kamps:$NATKA

# generate graph from db
for period in day week month ; do

case $period in
  "day")   x_axis="--x-grid MINUTE:10:HOUR:1:MINUTE:120:0:%R" ;;
  "week")  x_axis="--x-grid HOUR:12:DAY:1:DAY:1:0:%A" ;;
  "month") x_axis="--x-grid WEEK:1:WEEK:1:DAY:1:0:%d"  ;;
  *) x_axis=" "
esac

  $rrdtool graph "$img"-"$period".png \
    -w 1200 -h 183 -a PNG \
    --slope-mode \
    --disable-rrdtool-tag \
    --start end-1"$period" --end now \
    --font DEFAULT:7: \
    --color CANVAS#35373C \
    --title "Stats for foldingathome wihout urbinek" \
    --watermark "`date`" \
    $x_axis \
    --rigid \
    --base=1000 \
    --upper-limit $((grand_score / divide))\
    --lower-limit 0 \
    DEF:MichalR=$db:MichalR:AVERAGE \
    DEF:lksilesian=$db:lksilesian:AVERAGE \
    DEF:MateuszL=$db:MateuszL:AVERAGE \
    DEF:Bartek=$db:Bartek:AVERAGE \
    DEF:xmesaj2=$db:xmesaj2:AVERAGE \
    DEF:nataliad2412=$db:nataliad2412:AVERAGE \
    DEF:blazejpoland=$db:blazejpoland:AVERAGE \
    DEF:Blazejej=$db:Blazejej:AVERAGE \
    DEF:Kamps=$db:Kamps:AVERAGE \
    DEF:NATKA=$db:NATKA:AVERAGE \
    LINE1:MichalR#ADA759:"MichalR": \
    LINE1:lksilesian#C08863:"lksilesian": \
    LINE1:MateuszL#96B1D0:"MateuszL": \
    LINE1:Bartek#D0C7AB:"Bartekh": \
    LINE1:xmesaj2#FFE119:"xmesaj2_63569": \
    LINE1:nataliad2412#E28FAD:"nataliad2412": \
    LINE1:blazejpoland#E48E58:"blazejpoland": \
    LINE1:Blazejej#5AA08D:"Blazejej": \
    LINE1:Kamps#4C92B1:"Kamps": \
    LINE1:NATKA#AC99C1:"NATKA": 
done

