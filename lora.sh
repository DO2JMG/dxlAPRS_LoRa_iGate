#!/bin/bash

workingdir="$( cd "$(dirname "$0")" ; pwd -P )"
source ${workingdir}/lora-options.conf
piddir=${workingdir}/pidfiles
bindir=${workingdir}/bin
fifopath=${workingdir}/fifos

beaconfile=${workingdir}/beacon.txt

LORARX=${bindir}/lorarx
LORAUDPGATE=${bindir}/udpgate4
LORASDRTST=${bindir}/sdrtst

command -v ${LORARX} >/dev/null 2>&1 || { echo "Ich vermisse " ${LORARX} >&2; exit 1; }
command -v ${LORAUDPGATE} >/dev/null 2>&1 || { echo "Ich vermisse " ${LORAUDPGATE} >&2; exit 1; }
command -v ${LORASDRTST} >/dev/null 2>&1 || { echo "Ich vermisse " ${LORASDRTST} >&2; exit 1; }

function startrtltcp {
  echo "Starte rtl_tcp"
  rtl_tcp -a 127.0.0.1 -d ${device} -g ${gain} -p ${rtltcp_port} 2>&1 > /dev/null &

  rtltcp_pid=$!
  echo $rtltcp_pid > $PIDFILE
  sleep 5
}

function startsdrtst {
  echo "Starte sdrtst"

  mknod ${fifopath}/lorapipe p 2> /dev/null

  ${LORASDRTST} -t 127.0.0.1:${rtltcp_port} -i 1024000 -c ${workingdir}/qrg.txt -r 250000  -L 127.0.0.1:18051 -s ${fifopath}/lorapipe -v >&1 >> ${LOGFILE} &
  sdrtst_pid=$!
  echo $sdrtst_pid > $PIDFILE
}

function startlorarx {
  echo "Starte lorarx"

  ${LORARX} -i ${fifopath}/lorapipe -f i16 -b 7 -v -s 12 -L 127.0.0.1:9702 -s 10 -v 2>&1 >> ${LOGFILE} &
  #${LORARX} -i ${fifopath}/lorapipe -f i16 -b 7 -v -s 12 -L 127.0.0.1:9702 -c 5 2>&1 >> ${LOGFILE} &
  
  lorarx_pid=$!
  echo $lorarx_pid > $PIDFILE
}

function startudpgate {
  echo "Starte udpgate"

  ${LORAUDPGATE} -s ${gatewaycall} -R 127.0.0.1:9071:9702 -n 10:${beaconfile} -g ${aprsserver}:${aprsport} -p ${aprspass} -v 2>&1 >> ${LOGFILE} &
  udpgate_pid=$!
  echo $udpgate_pid > $PIDFILE
}


function sanitycheck {
# check pidfiles in piddir
  shopt -s nullglob # no error if no PIDFILE
  for f in ${piddir}/*.pid; do
  pid=`cat $f`
    if [ -f /proc/$pid/exe ]; then ## pid is running?
      echo "$(basename $f) ok pid: $pid"
    else ## pid not running
      echo "$(basename $f) died"
      rm $f
    fi
  done
}


function checkproc {
#checks if prog is running or not
  if [ -s $PIDFILE ];then ##have PIDFILE
    pid=`cat $PIDFILE`
    if [ -f /proc/$pid/exe ]; then ## pid is running?
      return 0
    else ## pid not running
      return 1
    fi
  else ## no PIDFILE
    return 1
  fi
}


tnow=`date "+%x_%X"`
echo $tnow

### kill procs
if [ "x$1" == "xstop" ];then
  killall rtl_tcp
  killall lorarx
  killall udpgate4
  killall sdrtst
  sanitycheck
  exit 0
fi

# check for rtl_tcp
LOGFILE=/tmp/rtl_tcp.log
PIDFILE=${piddir}/rtl_tcp.pid

 checkproc
 returnval=$?
 if [ $returnval -eq 1 ];then
   : > ${LOGFILE}
   startrtltcp
 fi

sleep 2

# check for sdrtst
LOGFILE=/tmp/sdrtst.log
PIDFILE=${piddir}/sdrtst.pid

checkproc
returnval=$?
if [ $returnval -eq 1 ];then
  : > ${LOGFILE}
  startsdrtst
fi

# check for udpgate 
cd ${caldir}
LOGFILE=/tmp/udpgate4.log
PIDFILE=${piddir}/udpgate4.pid

checkproc
returnval=$?
if [ $returnval -eq 1 ];then
  : > ${LOGFILE}
  startudpgate
fi

# check for lorarx 
cd ${caldir}
LOGFILE=/tmp/lorarx.log
PIDFILE=${piddir}/lorarx.pid

checkproc
returnval=$?
if [ $returnval -eq 1 ];then
  : > ${LOGFILE}
   startlorarx
fi

sanitycheck

exit 0

