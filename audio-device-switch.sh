#!/bin/bash
# Switch between audio outputs
#
# Copyright 2022 Marcel Grolms
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


all_sinks=()
all_sink_ids=()
available_sink_ids=()
ignore_sink_ids=()
ignore_sinks=()

notify=0

declare -i sinks_count
declare -i active_sink_index

# check for available sinks
sinks_count=$(pacmd list-sinks | grep -c "index:[[:space:]][[:digit:]]")
if [ "$sinks_count" -eq 0 ] ; then
    echo "No sink detected."
    exit
fi
# set active sink index
active_sink_index=$(pacmd list-sinks | sed -n -e 's/[[:space:]][[:space:]]\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p')

#### FUNCTION BEGIN
# Set all and available sinks
# GLOBALS: 
#   all_sinks all_sink_ids available_sink_ids ignore_sink_ids ignore_sinks
### FUNCTION END
function get_available_sinks {
    while read -r row ; 
    do
        IFS=' ' read -r -a current_sink <<< "$row"
        #echo "Index: ${current_sink[0]} Vendor: ${current_sink[1]} Product: ${current_sink[2]}"
        all_sink_ids+=("${current_sink[0]}")
        all_sinks+=("${current_sink[1]}:${current_sink[2]}")

        for sink in "${ignore_sink_ids[@]}"; do
            if [ "${current_sink[1]}:${current_sink[2]}" == "$sink" ] ; then
                #echo "Exclude sink with index $sink from switching"
                ignore_sinks+=("${current_sink[0]}")
            fi
        done
    done <<<$(pacmd list-sinks | sed -n -e "s/[\ \*]*index:\ \([[:digit:]]\)\|[\  \t]*device\.product\.id\ \=\ \"\([0-9a-f]\{4\}\)\"\|[\ \t]*device\.vendor\.id\ =\ \"\(....\)\"\|[\ \t]*\(ports:\)/\1\2\3\4/p" | awk -v RS='ports:\n' -v FS='\n' -v ORS='\n' -v OFS=' ' '{ $1=$1 };1')

    for index in "${all_sink_ids[@]}"; do
        if [ "${#ignore_sinks[@]}" -ne 0 ] ; then
            for ignoreSinkIndex in "${ignore_sinks[@]}"; do
                if [ "$index" -ne "$ignoreSinkIndex" ] ; then
                    available_sink_ids["${#available_sink_ids[@]}"]="$index"
                fi
            done
        else
            available_sink_ids[${#available_sink_ids[@]}]=$index
        fi
    done
}

while getopts i:nh flag
do
    case "${flag}" in
        i) 
            ignore=${OPTARG}
            IFS=' ' read -r -a ignore_sink_ids <<< "$ignore"
            ;;
        n) 
            notify=1
            ;;
        *) 
            echo "Usage: audio-device-switch [-i \"vendor:productId vendor:productId ...\"]" >&2
            get_available_sinks
            echo "  Available sinks: " >&2
            for sink in "${all_sinks[@]}"; do
                echo "      $sink"
            done
            exit
            ;;
    esac
done

get_available_sinks

active_index_position_found=0
(( next_sink_index=-1 ))

for index in "${available_sink_ids[@]}"; do
    if [ $next_sink_index -lt 0 ] ; then
        export next_sink_index=$index
    fi
    # if active sink is found this will be the next
    if [ $active_index_position_found -eq 1 ] ; then
        export next_sink_index=$index
        break;
    fi
    # find active sink
    if [ "$active_sink_index" -eq "$index" ] ; then
        export active_index_position_found=1
    fi  
done

# change the default sink
pacmd "set-default-sink ${next_sink_index}"

# move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p');
do
    pacmd "move-sink-input $app $next_sink_index"
done

# display notification
if [ $notify -ne 0 ] ; then
    ndx=0
    pacmd list-sinks | sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' | while read -r line;
    do
        if [ "$next_sink_index" -eq "${available_sink_ids[$ndx]}" ] ; then
            notify-send -i preferences-desktop-multimedia "Sound output switched to:" "$line"
            exit
        fi
        ((ndx++))
    done;
fi
