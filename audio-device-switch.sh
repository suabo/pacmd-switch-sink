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


notify=0
while getopts d:nh flag
do
    case "${flag}" in
        d) disable=${OPTARG};;
        n) notify=1;;
        *) echo "Usage: audio-device-switch -d \"vendor:productId vendor:productId\""; exit;;
    esac
done

declare -i sinks_count=`pacmd list-sinks | grep -c index:[[:space:]][[:digit:]]`
if [ $sinks_count -eq 0 ] ; then
    echo "No audio output detected."
    exit
fi

IFS=' ' read -r -a disableSink <<< "$disable"

arrSinkIndex=()
arrDisabledSinkIndex=()

while read row ; 
do
    IFS=' ' read -r -a arrSink <<< "$row"
    #echo "Index: ${arrSink[0]} Vendor: ${arrSink[1]} Product: ${arrSink[2]}"
    loopSink="${arrSink[1]}:${arrSink[2]}"

    for sink in ${disableSink[@]}; do
        if [ $loopSink == $sink ] ; then
            #echo "Exclude sink with index $sink from switching"
            arrDisabledSinkIndex+=(${arrSink[0]})
        fi
    done
done <<<$(pacmd list-sinks | sed -n -e "s/[\ \*]*index:\ \([[:digit:]]\)\|[\  \t]*device\.product\.id\ \=\ \"\([0-9a-f]\{4\}\)\"\|[\ \t]*device\.vendor\.id\ =\ \"\(....\)\"\|[\ \t]*\(ports:\)/\1\2\3\4/p" | awk -v RS='ports:\n' -v FS='\n' -v ORS='\n' -v OFS=' ' '{ $1=$1 };1')

declare -i active_sink_index=`pacmd list-sinks | sed -n -e 's/[[:space:]][[:space:]]\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`

while read index ;
do
    if [ ${#a[@]} -ne 0 ] ; then
        for disableSinkIndex in ${arrDisabledSinkIndex[@]}; do
            if [ $index -ne $disableSinkIndex ] ; then
                arrSinkIndex[${#arrSinkIndex[@]}]=$index
            fi
        done
    else
        arrSinkIndex[${#arrSinkIndex[@]}]=$index
    fi
done < <(pacmd list-sinks | sed -n -e 's/[\*\ ]*index:[[:space:]]\([[:digit:]]\)/\1/p')

active_index_position_found=0
let next_sink_index=-1

for index in ${arrSinkIndex[@]}; do
  if [ $next_sink_index -lt 0 ] ; then
        export next_sink_index=$index
    fi
    if [ $active_index_position_found -eq 1 ] ; then
        if [[ ! "${arrDisabledSinkIndex[*]}" =~ "${index}" ]]; then
            export next_sink_index=$index
            break;
        fi
    fi
    if [ $active_sink_index -eq $index ] ; then
        export active_index_position_found=1
    fi  
done

#change the default sink
pacmd "set-default-sink ${next_sink_index}"

#move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p');
do
    pacmd "move-sink-input $app $next_sink_index"
done

#display notification
if [ $notify -ne 0 ] ; then
    ndx=0
    pacmd list-sinks | sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' | while read line;
    do
        if [ $next_sink_index -eq ${arrSinkIndex[$ndx]} ] ; then
            notify-send -i preferences-desktop-multimedia "Sound output switched to:" "$line"
            exit
        fi
        ((ndx++))
    done;
fi
