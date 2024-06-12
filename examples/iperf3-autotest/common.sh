#!/bin/bash

kea_config() {
    KEA_CONF4=/etc/kea/kea-dhcp4.conf
    diff ${KEA_CONF4} kea-dhcp4.conf >/dev/null 2>&1 || {
        sudo cp kea-dhcp4.conf ${KEA_CONF4} || {
            echo 'kea-dhcp4.conf tmpl not found'
            exit -2
        }
        sudo rm /var/lib/kea/kea-*
        timeout 5 sudo systemctl restart kea-dhcp4-server.service &
    }
}

kea_prepare() {
    kea_config

    HOOK_DIR=/opt/kea/kea-hook-runscript
    SCRIPTS_DIR=/opt/kea/kea-hook-runscript/examples/iperf3-autotest
    sudo mkdir -p $HOOK_DIR
    sudo chmod a+rw $HOOK_DIR
    mkdir -p $SCRIPTS_DIR

    cp script.sh $SCRIPTS_DIR
    cp ../../*.so $HOOK_DIR/ || {
        cd ../../ && make || {
            echo "kea-hook-runscript.so not found"
            exit -2
        }
    }
}
kea_prepare

LEASES=`sudo cat /var/lib/kea/kea-leases4.csv* | grep -P "[a-f0-9]+2:" | awk -F, '{print $1}' | sort | uniq`
[ -n "${LEASES}" ] || {
    echo "empty leases, quit & waiting for sta online..."
    exit 0
}