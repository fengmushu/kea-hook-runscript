#!/bin/bash

. ./common.sh

help()
{
    echo "./iperf-cli.sh <ver:3/2> <seconds:10> [pkgsize:256] [bitrate:3M] [udp/tcp:u]"
}
help

VERSION=3
[ -z "$1" ] || {
    VERSION=$1
}
SEC_TO_RUN=10
[ -z "$2" ] || {
    SEC_TO_RUN=$2
}
echo "seconds to run: $SEC_TO_RUN, use version-$VERSION"

DIR_RUN=/tmp/iperf${VERSION}/`date +%m%d-%H%M%S`
mkdir -p $DIR_RUN

iperf3_start()
{
    for IP4ADDR in $LEASES
    do
        echo  $IP4ADDR
        iperf3 -c $IP4ADDR -u -b3M -l256 -t$SEC_TO_RUN -J -T "$IP4ADDR" --get-server-output --forceflush --logfile $DIR_RUN/report-$IP4ADDR.json &
    done
}

iperf2_start()
{
    for IP4ADDR in $LEASES
    do
        echo $IP4ADDR
        iperf -c $IP4ADDR -u -b3M -l256 -i1 -t$SEC_TO_RUN -yC > $DIR_RUN/iperf2-$IP4ADDR.csv &
    done
}

[ $VERSION -eq 2 ] && {
    iperf2_start
} || {
    iperf3_start
}
sys_monitor

echo "waitting iperf$VERSION ..."
while pidof $CMD > /dev/null 2>&1
do
    echo -n "-";
    sleep 1
done
echo "finished"
