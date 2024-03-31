#!/bin/bash

LEASES=`cat /var/lib/kea/kea-leases4.csv* | grep -P "[a-f0-9]+2:" | awk -F, '{print $1}' | sort | uniq`
# echo $LEASES
