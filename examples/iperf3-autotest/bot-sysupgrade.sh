#!/bin/bash

. ./common.sh

help()
{
    echo "./bot-sysupgrade.sh <firmware:bot.bin>"
}
help

FW_BIN=bot.bin
[ -z "$1" ] || {
    FW_BIN=$1
}
OS_VERSION=`ls bot*.bin | awk -F- '{printf "%s-%s", $3,$4}'`
[ -z "$2" ] || {
    OS_VERSION=$2
}
echo "bin to upgrade: $FW_BIN, $OS_VERSION"

sysupgrade()
{
    DIR_RUN=/tmp/iperf3/`date +%m%d-%H%M%S`

    rm ~/.ssh/known_hosts > /dev/null 2>&1
    # 1. apt-get install sshpass
	#    auto input password
	#
	# 2. modify /etc/ssh/ssh_config, avoid warring:
	#    RSA key fingerprint is 96:a9:23:5c:cc:d1:0a:d4:70:22:93:e9:9e:1e:74:2f.
	#    Are you sure you want to continue connecting (yes/no)? yes
	# StrictHostKeyChecking accept-new

    mkdir -p $DIR_RUN
    for IP4ADDR in $LEASES
    do
        printf  "\n\n>>>>>>>: %s\n" $IP4ADDR
        CUR_OS_VER=`sshpass ssh root@$IP4ADDR "cat /etc/openwrt_version" 2>/dev/null`
        [ -z "$CUR_OS_VER" ] && {
            echo "Mybe not a bot, ignore..."
            continue
        }
        [ x"$CUR_OS_VER" = x"$OS_VERSION" ] && {
            echo "Already last version $CUR_OS_VER."
            continue
        }

        echo "Do sysupgrade to $CUR_OS_VER..."
        # iperf3 -c $IP4ADDR -u -b3M -l256 -t$FW_BIN -J -T "$IP4ADDR" --get-server-output --forceflush --logfile $DIR_RUN/report-$IP4ADDR.json &
        sshpass scp $FW_BIN root@$IP4ADDR:/tmp/ && {
            sshpass ssh root@$IP4ADDR "sysupgrade $PARAMS /tmp/$FW_BIN" 2>&1 &
        }
    done
}

sysupgrade

