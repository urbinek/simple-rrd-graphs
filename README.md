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
