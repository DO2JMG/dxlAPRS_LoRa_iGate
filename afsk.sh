#!/bin/bash

workingdir="$( cd "$(dirname "$0")" ; pwd -P )"
source ${workingdir}/options.conf
piddir=${workingdir}/pidfiles
bindir=${workingdir}/bin
fifopath=${workingdir}/fifo

beaconfile=${workingdir}/beacon.txt

AFSKMODEM=${bindir}/afskmodem
AFSKUDPGATE=${bindir}/udpgate4
AFSKSDRTST=${bindir}/sdrtst

command -v ${AFSKMODEM} >/dev/null 2>&1 || { echo "Ich vermisse " ${AFSKMODEM} >&2; exit 1; }
command -v ${AFSKUDPGATE} >/dev/null 2>&1 || { echo "Ich vermisse " ${AFSKUDPGATE} >&2; exit 1; }
command -v ${AFSKSDRTST} >/dev/null 2>&1 || { echo "Ich vermisse " ${AFSKSDRTST} >&2; exit 1; }

function startrtltcp {
  echo "Starte rtl_tcp"
  rtl_tcp -a 127.0.0.1 -d ${device} -g ${gain} -p ${rtltcp_port} 2>&1 > /dev/null &

  rtltcp_pid=$!
  echo $rtltcp_pid > $PIDFILE
  sleep 5
}

function startsdrtst {
  echo "Starte sdrtst"

  mknod ${fifopath}/aprspipe p 2> /dev/null

  ${AFSKSDRTST} -t 127.0.0.1:${rtltcp_port} -c ${workingdir}/qrg.txt -r 16000 -s ${fifopath}/aprspipe -v >&1 >> ${LOGFILE} &
  sdrtst_pid=$!
  echo $sdrtst_pid > $PIDFILE
}

function startAFSKrx {
  echo "Starte AFSK Modem"

  ${AFSKMODEM} -f 16000 -o ${fifopath}/aprspipe -c 1 -M 0 -c 0 -L 127.0.0.1:9702:0 2>&1 >> ${LOGFILE} &
  
  AFSKrx_pid=$!
  echo $AFSKrx_pid > $PIDFILE
}

function startudpgate {
  echo "Starte udpgate"

  ${AFSKUDPGATE} -s ${gatewaycall} -R 127.0.0.1:9071:9702 -n 10:${beaconfile} -g ${aprsserver}:${aprsport} -p ${aprspass} -v 2>&1 >> ${LOGFILE} &
  udpgate_pid=$!
  echo $udpgate_pid > $PIDFILE
}


function sanitycheck {
  shopt -s nullglob
  for f in ${piddir}/*.pid; do
  pid=`cat $f`
    if [ -f /proc/$pid/exe ]; then 
      echo "$(basename $f) ok pid: $pid"
    else 
      echo "$(basename $f) died"
      rm $f
    fi
  done
}


function checkproc {
  if [ -s $PIDFILE ];then 
    pid=`cat $PIDFILE`
    if [ -f /proc/$pid/exe ]; then 
      return 0
    else 
      return 1
    fi
  else 
    return 1
  fi
}


tnow=`date "+%x_%X"`
echo $tnow

### kill procs
if [ "x$1" == "xstop" ];then
  killall rtl_tcp
  killall afskmodem
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

# check for AFSKrx 
cd ${caldir}
LOGFILE=/tmp/AFSK_modem.log
PIDFILE=${piddir}/AFSK_modem.pid

checkproc
returnval=$?
if [ $returnval -eq 1 ];then
  : > ${LOGFILE}
   startAFSKrx
fi

sanitycheck

exit 0

