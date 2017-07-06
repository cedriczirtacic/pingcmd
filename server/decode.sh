#!/bin/bash

function help() {
    echo "$0 <cap_file>"
    exit 2
}

if [[ $# -lt 1 ]] ;then
    help
fi

pcap=$1
sudo tcpdump -r $pcap 2>/dev/null| perl -ne "if (/([0-9]+)$/) { \
    if (int(\$1) == 8) {print $/;} else {print chr(\$1-8);} \
}" -- && echo

