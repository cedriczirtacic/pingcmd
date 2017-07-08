#!/bin/bash

if [[ $(id -un) != "root" ]];then
    echo "You must execute this as root.";
    exit 1;
fi

function help() {
    echo "$0 <4/6> <interface> <output>"
    exit 2
}

if [[ $# -lt 2 ]] ;then
    help
fi

TCPDUMP=$(which tcpdump)
version=$1;
interface=$2;
output=$3;

if [[ $version == 4 ]];then
    ${TCPDUMP} -nni ${interface} -e 'icmp[icmptype] == 8' -w ${output}
else
    ${TCPDUMP} -nni ${interface} -e 'icmp6 and dst localhost' -w ${output}
fi
