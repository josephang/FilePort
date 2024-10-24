#!/bin/bash
# Call Compression Script With default_directories.json
# Specify Which Directories You Wish To Compress
#If you do not need compression, you can comment this out
/FilePort/Hangar/Scripts/FilePortATC.sh -c default_directories.json

# You Can Specify More Flight Plans Delimited By Commas
#/FilePort/Hangar/Scripts/FilePortATC.sh -c default_directories.json,default_directories2.json


# Configure Remote Server With default_clearance.json
# You can specify directories that do not need to be compressed, but still need to be synced here
# You must also make sure that the config includes the directory of your compressed files for them to by synced
/FilePort/Hangar/Scripts/FilePortTakeOff.sh default_clearance.json

#After Making Sure This Works, Set This FlightPlan To Be Run By Cron
