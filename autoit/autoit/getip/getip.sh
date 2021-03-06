#!/bin/bash
rundir="/autoit/getip" # CHANGE IN POWERSHELL SCRIPT
datadir="/autoit.data/getip"
. ${rundir}/variables.cfg
com=${1}
reqs="${2}"
auto="${3}"
p=${auto}
pnetno="${4}"
#sw="$1"
#nuip="$2"

if [[ ! ${com} == "return" ]] && [[ ! ${com} == "get" ]]; then
  echo "[ERROR]-Not a valid entry. Get Or Return IP ?"
  exit 1
fi

if [[ ${com} == "get" ]] && [[ ! ${auto} == "p" ]] && [[ ! ${auto} == "v" ]]; then
  echo "[ERROR]-Not a valid entry. v or p plaform type not indicated ? (v-virtual / p-physical)"
  exit 1
fi

if [[ ${com} == "get" ]] && [[ ${pnetno} != [0-9] ]]; then
  echo "[ERROR]-Network selected but network group number not indicated."
  exit 1
fi

ts="$(( ( RANDOM % 800 ) + 100 ))-$(date +'%s')"

# PROCESS MANAGEMENT
   [[ -e ${datadir}/proc ]] || mkdir -p ${datadir}/proc &> /dev/null
   echo "$$" >> ${datadir}/proc/proc
   queue=0
   oIFS=${IFS}; IFS=$'\n'
   while :; do
     for ap in `cat ${datadir}/proc/proc`; do
       [[ ! -z ${ap} ]] && ps -ef |grep -v grep |awk '{print $2}' |grep -v "^$$$" |grep "^${ap}$" &> /dev/null && queue=1
       [[ ${queue} -eq 0 ]] && [[ "${ap}" == "$$" ]] && break
     done
     [[ ${queue} -eq 0 ]] && break
     [[ ${queue} -eq 1 ]] && queue=0 && sleep 1 && continue
   done
   IFS=${oIFS}

sed -ni "/$$/,\$p" ${datadir}/proc/proc
# PROCESS MANAGEMENT END

[[ -e ${datadir}/rangefiles ]] || mkdir -p ${datadir}/rangefiles &> /dev/null
[[ -e ${datadir}/preservedip ]] || mkdir -p ${datadir}/preservedip &> /dev/null
[[ -e ${datadir}/provisionedip ]] || mkdir -p ${datadir}/provisionedip &> /dev/null
[[ -e ${datadir}/tmp ]] || mkdir -p ${datadir}/tmp &> /dev/null

if [[ ${com} == "return" ]] && auto="ve" && [[ ! -z ${reqs} ]]; then
  unset getiplist; getiplist=`cat getip*.cfg |awk -F ";" '{print $1}'`
  oPWD=${PWD}; cd ${datadir}/preservedip/
  for returnip in `echo -e "${getiplist}"`; do [[ ! -z ${returnip} ]] && ls ${datadir}/preservedip/ |grep "^${returnip};" |xargs rm -rf; done
  cd ${oPWD}

  oPWD=${PWD}; cd ${datadir}/provisionedip/
  for returnip in `echo -e "${getiplist}"`; do [[ ! -z ${returnip} ]] && ls ${datadir}/provisionedip/ |grep "^${returnip};" |xargs rm -rf; done
  cd ${oPWD}
fi

# GET
if [[ ${com} == "get" ]]; then

# ENABLE
#if vcadmin="$vcadmin" vcpass="$vcpass" vcserver="$vcserver" iplistcsv="$datadir/tmp/iplist.csv" pwsh -Command 'Connect-VIServer -server $env:vcserver -Force -WarningAction 0 -Username $env:vcadmin -Password $env:vcpass; get-vm |get-annotation -customattribute *-ip-* |select Name,AnnotatedEntity,value |export-csv $env:iplistcsv' &> /dev/null; then
#  true
#else
#  echo "[ERROR]-Couldn't pull IP inventory from vcenter."
#  exit 1
#fi

IFS="${oIFS}"; IFS=$'\n'
for proip in `sdiff <(cat ${datadir}/tmp/iplist.csv |grep "\"ip" |awk -F "," '{print $3}' |grep -v "\"\"" |awk -F "\"" '{print $2}' |sed 's/;/;\n/g' |grep -v "^$" |awk '!a[$0]++' |grep -v "VLAN" |grep ";" |sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4) \
      <(ls -1 ${datadir}/provisionedip/ | awk -F ";" '{print $1";"}') |sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | awk -F ";" '{print $1";"}' |grep "^[0-9]"`; do
#      <(ls -1 ${datadir}/provisionedip/ | awk -F ";" '{print $1";"}') |sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | grep "<" | awk -F ";" '{print $1";"}'`; do
  swwno=`cat ranges.cfg | grep $(echo -e "${proip}" |awk -F "." '{print $1"."$2"."$3"."}') |awk -F "-" '{print $1"-"$2"-"$3}'`
  #echo "${proip}"
  #echo "$swwno"
  if [[ ! -z "${proip}"  ]]; then
    isipv4="^[0-9]+.[0-9]+.[0-9]+.[0-9]+;$"
    [[ ! $proip =~ $isipv4 ]] && continue
    if ls ${datadir}/preservedip/ | grep "^${proip}" &> /dev/null; then
      cp -rf "${datadir}/preservedip/${proip}"* "${datadir}/provisionedip/"
    else
      touch "${datadir}/provisionedip/${proip}${swwno};ip;${ts};"
      touch "${datadir}/preservedip/${proip}${swwno};ip;${ts};"
    fi
  fi
done
IFS="${oIFS}"

# SUM OF IPS PER NETS
oIFS="${IFS}"; IFS=$'\n'
nets=`echo -e "${reqs}" | tr ';' '\n' |sort |awk -F "|" '{print $1}' |awk '!a[$0]++'`
for net in `echo -e "${nets}"`; do
totalip=`echo "${reqs}" | tr ';' '\n' |sort | tr ';' '\n' |sort |grep "^${net}" |awk -F'|' '{sum+=$2}END{print sum;}'`
resultip+="${net}|${totalip};"
done
IFS="${oIFS}"
resultip=${resultip::-1}

#PRESERVERIP
IFS="${oIFS}"; IFS=";"
for req in `echo -e "${resultip}"`; do
sw=`echo -e "${req}" | awk -F "|" '{print $1}'`"-${pnetno}"
nuip=`echo -e "${req}" | awk -F "|" '{print $2}'`
#CONTINUE
if ls -1 ${datadir}/rangefiles |grep "^${sw}-" &> /dev/null && [[ ! -z "${sw}" ]] && \
[[ ! -z "${nuip}" ]]; then

  oIFS="$IFS"; IFS=$'\n'
  noip=1
  for snet in `ls -1 ${datadir}/rangefiles |grep "^${sw}-"`; do
    #DISABLE
    #echo "${snet}"
    unset snetno; snetno=`echo -e "${snet}" |awk -F "-" '{print $3}'`
    #DISABLE
    #echo "${snetno}"
    unset avip; avip=`sdiff <(sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 "${datadir}/rangefiles/${snet}") <(ls -1 ${datadir}/preservedip/ |grep ";${sw};" | awk -F ";" '{print $1";"}' |sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4) |grep "<" | wc -l`
    [[ "$nuip" -gt "$avip" ]] && continue
    noip=0
    unset ips; ips=`sdiff <(sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 "${datadir}/rangefiles/${snet}") <(ls -1 ${datadir}/preservedip/ |grep ";${sw};" | awk -F ";" '{print $1";"}' |sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4) |grep "<" | awk -F ";" '{print $1";"}' | head -${nuip}`
    oIFS="${IFS}"; IFS=$'\n'
    for ip in `echo -e "${ips}"`; do
      topreservedip+="${ip}${sw};ip;${ts};\n"
    done
    IFS="${oIFS}"
    break
  done
  IFS="$oIFS"
#  echo $noip
  [[ ${noip} -eq 1 ]] && echo "[ERROR]-There are not enough IP addresses on ${sw}, please provide more subnets/vswitches." && exit 1

else
  #DELETE
  echo "${sw}"
  echo "REQ${req}"
  echo "${nuip}"
  #DELETE
  echo "[ERROR]-vswitch/subnet or no of IPs not selected correctly."
  exit 1
fi
#
done
IFS=${oIFS}

topreservedip=`echo -e "${topreservedip}" |grep -v "^$"`
for topres in `echo -e "${topreservedip}"`; do
  touch "${datadir}/preservedip/${topres}"
  touch "${datadir}/provisionedip/${topres}"
done 

#PRESERVATION
echo -e "${topreservedip}"
fi

exit

# Inform if there are not valids.
# Terraform will move the preserved ips to reserved ips. Maybe will be reserve but not provision.
# If non valid Ips in inventory, don't run. Inform which ones.

