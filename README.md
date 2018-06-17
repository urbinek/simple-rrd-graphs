## Installation
To install simply copy scripts somewhere on disk and add cron entries as below:

```
* * * * * /ssd/scripts/rrd_cpu-load.sh > /dev/null 2>&1
* * * * * /ssd/scripts/rrd_cpu-temp.sh > /dev/null 2>&1
* * * * * /ssd/scripts/rrd_memory.sh > /dev/null 2>&1
```
## Configuration
Cach script can be configured to some deggree, but overall it is copy'n'go solution. 

Whats NEED to be changed are paths where script will collect rendered images and rrd database.
```
#directory to store graphs - DO NOT REMOVE $ds_name
img=/PATH/To/CHANGE/$ds_name

# set db parameters
# db directory - DO NOT REMOVE $ds_name
db=/PATH/To/CHANGE/db/$ds_name.rrd
```
Also indes.html needs to be placed on some http server, and paths to images changed accordingly

## Demo 
Live graphs can be found at https://nginx.urbinek.eu/rrd/haruko or slightly mofidied for ZFS stats at https://nginx.urbinek.eu/rrd/

[![CPU temp grapg](https://nginx.urbinek.eu/rrd/cpu_temp-day.png "CPU temp grapg")](https://nginx.urbinek.eu/rrd/cpu_temp-day.png "CPU temp grapg")

[![CPU Load Graph](https://nginx.urbinek.eu/rrd/cpu_load-day.png "CPU Load Graph")](https://nginx.urbinek.eu/rrd/cpu_load-day.png "CPU Load Graph")

[![Memory compsumption graph](https://nginx.urbinek.eu/rrd/memory-day.png "Memory compsumption graph")](https://nginx.urbinek.eu/rrd/memory-day.png "Memory compsumption graph")
