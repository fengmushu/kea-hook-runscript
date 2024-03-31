#!/bin/bash

. ./common.sh

help()
{
    echo "./iperf-cli.sh <ver:3/2> <seconds:10> <dir:DL/UL/BI> [pkgsize:256] [bitrate:3M] [udp/tcp:u]"
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
FLOW_DIR=""
[ -z "$3" ] || {
    [ x$3 = x"DL" ] && {
        FLOW_DIR=""
    } || {
        FLOW_DIR="-R"
    }
}
[ $VERSION -eq 3 ] && {
    CMD=iperf3
} || {
    CMD=iperf
}
let SYS_MONITOR=$SEC_TO_RUN+10
let SYS_WATCHDOG=$SEC_TO_RUN+10

echo "seconds to run: $SEC_TO_RUN, use version-$VERSION"

DIR_RUN=/tmp/iperf${VERSION}/`date +%m%d-%H%M%S`
mkdir -p $DIR_RUN

iperf3_start()
{
    for IP4ADDR in $LEASES
    do
        echo  $IP4ADDR
        timeout -s SIGKILL $SYS_WATCHDOG $CMD -c $IP4ADDR -u -b3M -l256 -t$SEC_TO_RUN $FLOW_DIR -J -T "$IP4ADDR" --get-server-output --forceflush --logfile $DIR_RUN/report-$IP4ADDR.json &
    done
}

iperf2_start()
{
    for IP4ADDR in $LEASES
    do
        echo $IP4ADDR
        timeout -s SIGKILL $SYS_WATCHDOG $CMD -c $IP4ADDR -u -b3M -l256 -i1 -t$SEC_TO_RUN $FLOW_DIR -yC > $DIR_RUN/iperf2-$IP4ADDR.csv 2>/dev/null &
    done
}

sys_monitor()
{
    timeout $SYS_MONITOR gnome-system-monitor -r 2>&1 &
}

iperf_stop_all()
{
    killall iperf > /dev/null 2>&1
    killall iperf3 > /dev/null 2>&1
}

iperf_stop_all
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
