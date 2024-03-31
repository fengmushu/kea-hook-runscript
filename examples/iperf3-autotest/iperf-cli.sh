#!/bin/bash

LEASES=`cat /var/lib/kea/kea-leases4.csv* | grep -P "[a-f0-9]+2:" | awk -F, '{print $1}' | sort | uniq`
# echo $LEASES

help()
{
    echo "./iperf-cli.sh <seconds:10> <pkgsize:256> <bitrate:3M> <udp/tcp:u>"
}
help

SEC_TO_RUN=10
[ -z "$1" ] || {
    SEC_TO_RUN=$1
}
echo "seconds to run: $SEC_TO_RUN"

iperf3_start()
{
    DIR_RUN=/tmp/iperf3/`date +%m%d-%H%M%S`

    mkdir -p $DIR_RUN
    for IP4ADDR in $LEASES
    do
        echo  $IP4ADDR
        iperf3 -c $IP4ADDR -u -b3M -l256 -t$SEC_TO_RUN -J -T "$IP4ADDR" --get-server-output --forceflush --logfile $DIR_RUN/report-$IP4ADDR.json &
    done
}

iperf3_start

