#!/bin/bash

if [[ $(id -un) != "root" ]];then
    echo "You must execute this as root.";
    exit 1;
fi

function help() {
    echo "$0 <interface> <output>"
    exit 2
}

if [[ $# -lt 2 ]] ;then
    help
fi

TCPDUMP=$(which tcpdump)
interface=$1;
output=$2;

${TCPDUMP} -nni ${interface} -e 'icmp[icmptype] == 8' -w ${output}

