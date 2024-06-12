#!/usr/bin/env bash

. ./common.sh

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] -p proto arg1 [arg2...]

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-V, --iperf     <2|3> version of iperf2/iperf3, default 3
-t, --timer     <5-~> seconds to wait for finish, default 10
-d, --dir       <UL|DL|BI> uplink, downlink or both, default DL
-s, --size      <64-1480> packet size, default 1024
-r, --rate      <1M-1G> rate limits per node, default 3M
-p, --proto     <udp|tcp> protocol, default tcp
EOF
  exit
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  iperf_version=3
  timer=10
  dir=""
  size="-l1024"
  rate="-b3M"
  proto=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -V | --iperf) iperf_version=${2-}; shift ;; # example iperf_version
    -t | --timer) timer=${2-}; shift ;;
    -d | --dir) {
        case "${2-}" in
        DL) dir='' ;;
        UL) dir='-R' ;;
        BI) dir='' ;;
        *) dir='' ;;
        esac
        shift
    } ;;
    -s | --size) size="-l${2-}"; shift ;;
    -r | --rate) rate="-b${2-}"; shift ;;
    -p | --proto) {
        case "${2-}" in
        udp) proto='-u' ;;
        *) proto='' ;;
        esac
        shift;
    } ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"
setup_colors

# script logic here
msg "${RED}Read parameters:${NOFORMAT}"

[ ${iperf_version} -eq 3 ] && {
    CMD=iperf3
} || {
    CMD=iperf
}
let timer_traffic=${timer}+10
let timer_watchdog=${timer}+10

msg "run: ${timer}'s, use ${CMD}, ${rate}, ${size}, ${proto}, ${dir}"

DIR_RUN=iperf${iperf_version}/`date +%m%d-%H%M%S`

iperf3_start()
{
    for IP4ADDR in $LEASES
    do
        timeout -s SIGKILL $timer_watchdog $CMD -c $IP4ADDR ${proto} ${rate} ${size} -t${timer} ${dir} -J -T $IP4ADDR --get-server-output --forceflush --logfile $DIR_RUN/report-$IP4ADDR.json &
    done
}

iperf2_start()
{
    for IP4ADDR in $LEASES
    do
        timeout -s SIGKILL $timer_watchdog $CMD -c $IP4ADDR ${proto} ${rate} ${size} -i1 -t${timer} ${dir} -y > $DIR_RUN/iperf2-$IP4ADDR.csv 2>/dev/null &
    done
}

sys_monitor()
{
    #timeout $timer_traffic gnome-system-monitor -r 2>&1 &
    gnome-system-monitor -r 2>&1 &
}

mkdir -p $DIR_RUN
[ ${iperf_version} -eq 2 ] && {
    killall iperf > /dev/null 2>&1
    iperf2_start
} || {
    killall iperf3 > /dev/null 2>&1
    iperf3_start
}
sys_monitor

msg "waitting iperf${iperf_version} ..."
while pidof $CMD > /dev/null 2>&1
do
    echo -n "-";
    sleep 1
done
msg "ok"
