#!/bin/bash
rundir="/autoit/getip"
datadir="/autoit.data/getip"
. ${rundir}/variables.cfg

[[ -e ${datadir}/rangefiles ]] || mkdir ${datadir}/rangefiles &> /dev/null
[[ -e ${datadir}/preserverip ]] || mkdir ${datadir}/preservedip &> /dev/null
[[ -e ${datadir}/provisionedip ]] || mkdir ${datadir}/provisionedip &> /dev/null
[[ -e ${datadir}/tmp ]] || mkdir ${datadir}/tmp &> /dev/null

oIFS="$IFS"
for snet in `cat ${rundir}/ranges.cfg |grep -v "^#"`; do
  sw=`awk -F ";" '{print $1}' <<< "$snet"`
  [[ -e "${datadir}/rangefiles/${sw}" ]] || touch ${datadir}/rangefiles/${sw}
  echo "${snet}"
  for net in `awk -F ";" '{print $2}' <<< "$snet"`; do
    #echo "$net"
    oIFS=${IFS}; IFS="|"
    for r in `echo -e "${net}"`; do
      #echo "${r}"
      preip=`awk -F "." '{print $1"."$2"."$3"."}' <<< "$r"`
      ra=`echo "${r}" |awk -F "." '{print $4}' |awk -F "-" '{print $1}'`
      rb=`echo "${r}" |awk -F "." '{print $4}' <<< "$r" |awk -F "-" '{print $2}'`
      #echo "${preip}"
      #echo $ra
      #echo $rb
      oIFS=${IFS}; IFS=$'\n'
      for postip in `echo -e "$(seq $ra $rb)"`; do ! grep "${preip}${postip};" ${datadir}/rangefiles/${sw} &> /dev/null && echo -e "${preip}${postip};" >> ${datadir}/rangefiles/${sw} && echo -e "${preip}${postip};"; done
      IFS="${oIFS}"
    done
    IFS="${oIFS}"
  done
done
IFS="${oIFS}"


oIFS=${IFS};IFS=$'\n'
[[ -e ${datadir}/networks.tf ]] && rm -rf ${datadir}/networks.tf
for network in `ls ${datadir}/rangefiles`; do
  nettag=`echo -e "${network}" |awk -F "-" '{print $1"-"$2"-"$3}'`
  echo >> ${datadir}/networks.tf
  echo "data \"vsphere_network\" \"${nettag}\" {" >> ${datadir}/networks.tf
  echo "name = \"${network}\"" >> ${datadir}/networks.tf
  echo  "datacenter_id = \"\${data.vsphere_datacenter.dc.id}\"" >> ${datadir}/networks.tf
  echo "}" >> ${datadir}/networks.tf
done
echo -e "\nIF NEW NETWORKS ADDED. PLEASE COPY ${datadir}/networks.tf to /autoit/env/bin DIRECTORY !!!\n"
IFS=${oIFS}

# Preserve ip
# Provision ip
# Remove Ip
# Check sed conflict
