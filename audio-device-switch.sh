#!/bin/bash

# disabled sink id
disabledSinkId=0

# disable sink
disableSink=("1002:aaf0")

declare -i sinks_count=`pacmd list-sinks | grep -c index:[[:space:]][[:digit:]]`

if [ $sinks_count -eq 0 ] ; then
    exit
fi

while read row ; 
do
    IFS=' ' read -r -a arrSink <<< "$row"
    #echo "Index: ${arrSink[0]} Vendor: ${arrSink[1]} Product: ${arrSink[2]}"
    loopSink="${arrSink[1]}:${arrSink[2]}"

    for sink in ${disableSink[@]}; do
        if [ $loopSink == $sink ] ; then
            #echo "Exclude sink with index $sink from switching"
            disabledSinkId=${arrSink[0]}
        fi
    done

done <<<$(pacmd list-sinks | sed -n -e "s/[\ \*]*index:\ \([[:digit:]]\)\|[\  \t]*device\.product\.id\ \=\ \"\([0-9a-f]\{4\}\)\"\|[\ \t]*device\.vendor\.id\ =\ \"\(....\)\"\|[\ \t]*\(ports:\)/\1\2\3\4/p" | awk -v RS='ports:\n' -v FS='\n' -v ORS='\n' -v OFS=' ' '{ $1=$1 };1')

echo "Disable sink ${arrSink[0]}"

declare -i active_sink_index=`pacmd list-sinks | sed -n -e 's/[[:space:]][[:space:]]\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`

arrSinkIndex=()

while read index ;
do
    if [ $index -ne $disabledSinkId ] ; then
        arrSinkIndex[${#arrSinkIndex[@]}]=$index
    fi
done < <(pacmd list-sinks | sed -n -e 's/[\*\ ]*index:[[:space:]]\([[:digit:]]\)/\1/p')

active_index_position_found=0
let next_sink_index=-1
while read index ;
do
    if [ $next_sink_index -lt 0 ] ; then
        export next_sink_index=$index
    fi
    if [ $active_index_position_found -eq 1 ] ; then
        if [ $index -ne $disabledSinkId ] ; then
            export next_sink_index=$index
            break;
        fi
    fi
    if [ $active_sink_index -eq $index ] ; then
        export active_index_position_found=1
    fi
done < <(pacmd list-sinks | sed -n -e 's/[\*\ ]*index:[[:space:]]\([[:digit:]]\)/\1/p')


#change the default sink
pacmd "set-default-sink ${next_sink_index}"

#move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p');
do
    pacmd "move-sink-input $app $next_sink_index"
done

#display notification
ndx=0
pacmd list-sinks | sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' | while read line;
do
    if [ $next_sink_index -eq ${arrSinkIndex[$ndx]} ] ; then
        notify-send -i preferences-desktop-multimedia "Sound output switched to:" "$line"
        exit
    fi
    ((ndx++))
done;

