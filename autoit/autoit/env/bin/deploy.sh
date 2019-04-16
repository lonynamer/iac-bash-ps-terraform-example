#!/bin/bash
set +x
######
envfile="environment.cfg"
envfiletag=`echo -e "${envfile}" |awk -F "." '{print $1"-vc"}'`
base=`whereis deploy.sh |awk '{print $2}' |xargs dirname`
creation_date=`date +'%s-%F-%H:%M.%S'`
basedir="/$(basename $(pwd))/"
#set_ve=$(basename `pwd`)

# SUB RESOURCE NAME VALIDATION
# IF SUB RESOURCE DIRECTORY, SAME NAME AS MAIN RESOURCE DIRECTORY
# OR DOESN'T INCLUDE MAIN NAME WITH - FOLLOWING A NUMBER DON'T RUN
if [[ $(basename $(dirname `pwd`)) == "ADD" ]] || [[ $(basename $(pwd)) == "ADD" ]]; then
  maindir=`basename $(dirname $(dirname $(pwd)))`
  if [[ $(basename $(pwd)) == "ADD" ]] || ! echo -e "$(basename `pwd`)" |grep "^${maindir}-[0-9]*" &> /dev/null || ! echo -e "$(basename `pwd`)" | grep "[0-9]$" &> /dev/null; then
  echo -e "[ERROR] Subresource directory name should start by main resource name following by - and a number ! "
  exit 1
  fi
fi

### APPLY ALL
if [[ $1 == "applyall" ]]; then
  ! [[ -e "ADD" ]] && echo -e "[ERROR] Either sub resource not initialized or 'applyall' is used in sub resource directory." && exit 1
  oIFS=${IFS};IFS=$'\n';mPWD=`pwd`
  for adir in $(echo -e "./${IFS}$(ls -d ./ADD/* 2> /dev/null)"); do
    cd ${mPWD}
    cd ${adir}
    ! [[ -e "./deploy.sh" ]] && continue
    echo "${adir}"
    export TF_LOG_PATH=./tmp/terraform.log
    terraform init || exit $?
    terraform refresh || exit $?
    terraform apply -parallelism=4 -auto-approve || exit $?
  done
  IFS=${oIFS}
  cd ${mPWD}
  exit 0
fi

### APPLY
if [[ $1 == "apply" ]]; then
  export TF_LOG_PATH=./tmp/terraform.log
  terraform init || exit $?
  terraform refresh || exit $?
  terraform apply -parallelism=4 -auto-approve || exit $?
  exit 0
fi

### DESTROY ALL
if [[ $1 == "destroyall" ]]; then
  ! [[ -e "ADD" ]] && echo -e "[ERROR] Either sub resource not initialized or 'destroyall' is used in sub resource directory." && exit 1
  oIFS=${IFS};IFS=$'\n';mPWD=`pwd`
  for adir in $(echo -e "$(ls -d ./ADD/* 2> /dev/null)${IFS}./"); do
    cd ${mPWD}
    cd ${adir}
    ! [[ -e "./deploy.sh" ]] && continue
    echo "${adir}"
    export TF_LOG_PATH=./tmp/terraform.log
    terraform refresh || exit $?
    terraform destroy -auto-approve || exit $?
  done
  IFS=${oIFS}
  cd ${mPWD}
  exit 0
fi

### DESTROY
if [[ $1 == "destroy" ]]; then
  terraform refresh || exit $?
  terraform destroy -auto-approve || exit $?
  exit 0
fi

### CLEAN ALL
if [[ $1 == "cleanall" ]]; then
  ! [[ -e "ADD" ]] && echo -e "[ERROR] Either sub resource not initialized or 'destroyall' is used in sub resource directory." && exit 1
  oIFS=${IFS};IFS=$'\n';mPWD=`pwd`
  for adir in $(echo -e "$(ls -d ./ADD/* 2> /dev/null)${IFS}./"); do
    cd ${mPWD}
    echo "${adir}"
    cd ${adir}
    [[ `terraform show |wc -l` -gt 1 ]] && echo -e "[ERROR] Some resources are not destroyed to be cleaned. Please first destroy the resources." && exit 1
    echo "${adir}"
    terraform init
    terraform refresh
    for a in `ls -1`; do [[ $a != "variables"*".tf" ]] && [[ $a != "ADD" ]] && rm -rf $a; done
  done
  IFS=${oIFS}
  cd ${mPWD}
  exit 0
fi

# CLEAN
if [[ $1 == clean ]]; then
  [[ `terraform show |wc -l` -gt 1 ]] && echo -e "[ERROR] Resource is not destroyed to be cleaned. Please first destroy the resource." && exit 1
  terraform init
  terraform refresh
  for a in `ls -1`; do [[ $a != "variables"*".tf" ]] && [[ $a != "ADD" ]] && rm -rf $a; done
  exit 0
fi

# UNIDENTIFIED SELECTION
[[ ! -z $1  ]] && echo -e "[ERROR] Unidentified selection !" && exit 1

# DON'T RUN SECOND TIME
if [[ -e ./deploy.sh ]]; then
  echo -e "\n\n[ERROR] deploy.sh deployment initialization can run only one time. Please destroy orderly the sub infrastructures, main infrastructure, clean and start with only variables file. Use terraform apply and changing variables for additional changes."
  exit 1
fi


### PREPARATION
if ls *"variables.tf" &> /dev/null; then
  vars=`ls *"variables.tf" | head -1` && mv ${vars} variables.tf
else
  exit
fi

oIFS=$'\n'
for credfile in `ls -1 /cred-autoit/`; do
  ln -s /cred-autoit/${credfile} ./${credfile} &> /dev/null
done
for depfile in `ls -1 /autoit/env/bin/`; do
    [[ ${deplfile} != "images.tf" ]] && cp /autoit/env/bin/${depfile} ./${depfile} &> /dev/null
    ln -s /autoit/env/bin/${depfile} ./${depfile} &> /dev/null
done
IFS=${oIFS}

cp -rf /autoit/getip/ranges.cfg ./
rm -rf ./networks.tf
[[ ! -d ./tmp ]] && mkdir ./tmp
### PREPARATION END

for network in `cat ranges.cfg |grep -v "^#" |awk '/./' |awk -F ";" '{print $1}'`; do
unset nw; nw=`echo -e "${network}" |awk -F "-" '{print $1"-"$2"-"$3}'`
######
cat <<ENDOFFILE >> ./networks.tf

data "vsphere_network" "${nw}" {
  name = "${network}"
  datacenter_id = "\${data.vsphere_datacenter.dc.id}"
}
ENDOFFILE
######
done

### GET ENVIRONMENT SET
if [[ $(basename $(dirname `pwd`)) == "ADD" ]]; then
  set_ve=$(basename $(dirname $(dirname $(pwd))))
  oIFS=${IFS};IFS=$'\n'
  for sets in `cat variables.tf |grep "^set_team\|^set_owner\|^set_physical\|^set_netno\|^set_net2no" |awk -F "=" '{print $1}'`; do
    unset set; set=`cat ../../variables.tf |grep "^${sets}"`
    sed -i "s/^${sets}.*/${set}/g" ./variables.tf
  done
  IFS=${oIFS}
else
  set_ve=$(basename `pwd`)
  [[ ! -d ./ADD ]] && mkdir ./ADD
fi
oIFS="${IFS}"; unset IFS; `cat variables.tf |grep "^set_" |grep -v "{\|}\|^#" |tr -d ' ' |tr -d '"' |sed 's/^/export /'`;IFS="${oIFS}";
set_owner=${set_owner//_/ }
set_team=${set_team//_/ }
porv=$([[ ${set_physical} == true ]] && echo "p"; [[ ${set_physical} == false ]] && echo "v")
p=$([[ ${set_physical} == true ]] && echo "p")

### COUNT NUMBER OF IPS TO PROVISION
echo -e "variable \"amounts\" {\ntype=\"map\"\ndefault={" > amounts.tf
oIFS="${IFS}"; IFS=$'\n'
for vm in `cat variables.tf |grep "^vm"`; do
  ### GET VM VARIABLES
  oIFS="${IFS}"; unset IFS; `cat variables.tf |awk "/^${vm}/,/}/" |grep -v "{\|}\|^#" |tr -d ' ' |tr -d '"' |sed 's/^/export /'`; IFS="${oIFS}"
  for locs in `echo -e "${set_locations}" |tr -d " \"[]" |sed 's/,/\n/g'`; do
    ### CONDITIONS
    [[ "$((amount*nodes))" -eq 0 ]] && continue
    [[ "${locs}" != "${location}" ]] && [[ ${standby} == false ]] && continue
    [[ "${locs}" != "${location}" ]] && [[ ${set_standby} == false ]] && continue
    echo -e "${vm}" |grep "ora\|rac" &> /dev/null && [[ ${set_createdb} == false ]] && continue
    [[ ${set_physical} == false ]] && [[ ${set_physical} == true ]] && continue
    #echo ${amount}
    #echo A${locs}
    #echo ${vm}
    #echo $location
    ###

    ### VARIABLES TO TERRAFORM
    res=`echo -e "${vm}" |tr -d ' ' |awk -F "=" '{print $1}'`
    resources+=("${res}")
    sites+=("${locs}")
    rescount+=("${amount}")
    nofnodes+=("${nodes}")
    ###
    echo "${locs}_${res}=${amount}," >> amounts.tf

    #echo $res
    #echo $amount
    #echo $nodes
    if [[ $((amount*nodes)) -gt 0 ]]; then
        for aamount in $(seq 1 ${amount}); do  
          for anode in $(seq 1 ${nodes}); do
          [[ ${anode} -eq 1 ]] && for snetreq in `cat variables.tf |awk "/${vm}/,/}/" |grep -v "{\|}\|\^#" |tr -d ' '|grep "^saddip_" |sort |grep "^saddip_" |sort |grep -v "=0"`; do
            if [[ ${secondnetamountno} == "all" ]] || echo -e "${secondnetamountno}" |grep "^${aamount},\|,${aamount},\|,${aamount}$\|^${aamount}$" &> /dev/null; then
              snets2="${snets2}`echo -e ";${snetreq}" |sed "s/saddip_/${p}/g" |sed "s/=/-${locs}|/g"`"
            else
              snets="${snets}`echo -e ";${snetreq}" |sed "s/saddip_/${p}/g" |sed "s/=/-${locs}|/g"`"
            fi
          done
          for netreq in `cat variables.tf |awk "/${vm}/,/}/" |grep -v "{\|}\|\^#" |tr -d ' '|grep "^addip_" |sort |grep "^addip_" |sort |grep -v "=0"`; do
            if [[ ${secondnetamountno} == "all" ]] || echo -e "${secondnetamountno}" |grep "^${aamount},\|,${aamount},\|,${aamount}$\|^${aamount}$" &> /dev/null; then
              nets2="${nets2}`echo -e ";${netreq}" |sed "s/addip_/${p}/g" |sed "s/=/-${locs}|/g"`"
            else
              nets="${nets}`echo -e ";${netreq}" |sed "s/addip_/${p}/g" |sed "s/=/-${locs}|/g"`"
            fi
          done
        done
      done
    fi
    nets+=("${net}")
    snets+=("${snet}")
    nets2+=("${net2}")
    snets2+=("${snet2}")
  done
  IFS="${oIFS}"
done
echo -e "}\n}" >> amounts.tf
IFS="${oIFS}"
nets=`echo -e "${nets}" |sed 's/^.//'`
nets="${nets}${snets}"
nets2=`echo -e "${nets2}" |sed 's/^.//'`
nets2="${nets2}${snets2}"
#echo "TOTALNETS${nets}"
#echo "TOTALNETS2${nets2}"
#echo "STOTALNETS${snets}"
#echo "STOTALNETS2${snets2}"
#echo ${resources[*]}
#echo ${sites[*]}
#echo ${rescount[*]}
#echo ${nofnodes[*]}

### GENERATE 
#ENDOFFILE
oIFS=${IFS};IFS=$'\n'
for inv in `cat custom-attributes.conf`; do

######
cat <<ENDOFFILE >> ./data-custom-attr-vm.tf
data "vsphere_custom_attribute" "attr-${inv}" {
  name          = "${inv}"
}

ENDOFFILE
######
done
IFS=${oIFS}

### GENERATE getip.tf FILE
######
cat <<ENDOFFILE >> ./getip.tf

### PROVISION IPS
# GET IPS
resource "null_resource" "preserveip" {
  provisioner "local-exec" {
    command = "\${local.set_giprundir}/getip.sh get '${nets}' '${porv}' '${set_netno}'> getip.cfg"
  }
  provisioner "local-exec" {
    command = "if [[ ! -z '${nets2}' ]]; then \${local.set_giprundir}/getip.sh get '${nets2}' '${porv}' '${set_net2no}' > getip2.cfg ; else exit 0; fi"
  }
  provisioner "local-exec" {
    command = "\${local.set_giprundir}/getip.sh return auto ve"
    when = "destroy"
  }

}

ENDOFFILE
#####

# APPLY GETIP
export TF_LOG_PATH=./tmp/terraform-init.log
terraform init
terraform apply -auto-approve
cp -rf ${set_giprundir}/ranges.cfg ./

# CHECK GETIP
if ! ls getip*.cfg &> /dev/null || ([[ -e ./getip.cfg ]] && ! cat ./getip.cfg |grep ";ip;" |grep "^[0-9]" &> /dev/null) || ([[ -e ./getip2.cfg ]] && ! cat ./getip2.cfg |grep ";ip;" |grep "^[0-9]" &> /dev/null); then
  echo -e "[ERROR] Could not get even 1 ip address, there should be a misconfiguration."
  exit 1
fi

### PREPARE INVENTORY, DNS, DHCP INFORMATION
#echo ${resources[*]}
#echo ${sites[*]}
#echo ${rescount[*]}
#echo ${nofnodes[*]}

### GENERATE envfile FILE
######
cat <<ENDOFFILE >> ./${envfile}
# CREATE VE ENV FOLDER
variable "set_ve" {
  default = "${set_ve}"
}

######
ENDOFFILE
######
! [[ $(basename $(dirname `pwd`)) == "ADD" ]] && cat <<ENDOFFILE >> ./${envfile}

resource "vsphere_folder" "ve" {
  path = "ENVS/\${local.set_team}/\${var.set_ve}"
  type = "vm"
  datacenter_id = "\${data.vsphere_datacenter.dc.id}"
}

resource "null_resource" "reserved-dhcp-backup" {
  provisioner "local-exec" {
    command = "mv reserved-dhcp.cfg reserved-\$(date +'%s-%F-%H:%M.%S')-dhcp.cfg"
    when = "destroy"
  }
}

# CREATE VMS
######
ENDOFFILE

#! [[ $(basename $(dirname `pwd`)) == "ADD" ]]

#==============
# CREATE VMS
#echo -e "$(seq 0 ${#resources[@]})"
oIFS=${IFS}; IFS=$'\n'
for resno in $(seq 0 $((${#resources[@]}-1))); do
  unset res; res=${resources[resno]}
  unset site; site=${sites[resno]}
  #echo "${res}"
  oIFS="${IFS}"; unset IFS; `cat variables.tf |awk "/^${res}/,/}/" |grep -v "{\|}\|^#" |tr -d ' ' |tr -d '"' |sed 's/^/export /'`; IFS="${oIFS}"
    for countloop in $(seq 1 ${rescount[resno]}); do
      #echo "COUNT${countloop}"
      if [[ ${secondnetamountno} == "all" ]] || echo -e "${secondnetamountno}" |grep "^${countloop},\|,${countloop},\|,${countloop}$\|^${countloop}$" &> /dev/null; then
        getip_cfg="./getip2.cfg"
      else
        getip_cfg="./getip.cfg"
      fi
      #echo "GETIP${getip_cfg}"
      for nodeloop in $(seq 1 ${nofnodes[resno]}); do
       #echo "${nodeloop}"

# CUSTOM ATTRIBUTES
unset env; env="${set_ve^^}"
unset owner; owner="${set_owner^^}"
unset team; team="${set_team^^}"
unset data_type
#data_type
if [[ ${set_dataonmgmt} == true ]]; then
  unset data_type; data_type+="1GonM;"
elif [[ ${set_enable10g} == true ]] && [[ ${gig10} == true ]] && [[ ${set_1giginstead} == false ]]; then
  data_type+="10G;"
  card_type="vmxnet3"
else 
  data_type+="1G;"
  card_type="e1000e"
fi
[[ ${set_enablefc} == true ]] && data_type+=";FC" && fc=true
#data_type

# TAG
unset sepsubnet; sepsubnet=`echo -e "${res}" | awk -F "_" '{print $2}'`
unset resname; resname=`echo -e "${res}" | awk -F "_" '{print $3}'`
cadd=0 && [[ $(basename $(dirname `pwd`)) == "ADD" ]] && ls ../*/amounts.tf ../../amounts.tf &> /dev/null && cadd=`cat $(ls -1 ../*/amounts.tf ../../amounts.tf |grep -v "${basedir}") |grep ",$" |grep "^${site}_vm_${sepsubnet}_${resname}=" |awk -F "=|," '{sum+=$2;} END{print sum;}'`
unset tag; tag="${set_ve}-${site}-${sepsubnet}-${resname}-$((${cadd}+${countloop}))-${nodeloop}"; tag=${tag^^}
unset tagprimary; tagprimary="${set_ve}-${site}-${sepsubnet}-${resname}-$((${cadd}+${countloop}))-1"; tagprimary=${tagprimary^^}
unset attachdisktarget; attachdisktarget="${set_ve}-${site}-${attachdiskshared//_/-}-$((${cadd}+${countloop}))-1"; attachdisktarget="${attachdisktarget^^}"
# TAG END

# IP ATTRIBUTES
unset platform
unset image
unset credentials
unset ip_data_local
unset ip_data_remote
unset ip_floating
unset ip_kvm
unset ip_kvm_data
unset ip_management_local
unset ip_management_remote
unset ip_oracle_pri_local
unset ip_oracle_pri_remote
# NOT IN THE TABLES
unset nip_d_l
unset nip_d_r
unset nip_m_l
unset nip_m_r
unset nip_o_l
unset nip_o_r
# NOT IN THE TABLES
unset dns_entries
unset dhcp
unset ip_scan
unset ip_virtual
unset ip_management_gw
unset ip_data_gw
unset platform; platform="VC"
unset location_site; location_site="${site^^}"
unset role; role="${resname^^}"

# IMAGE/IMAGE CREDENTIALS
image="\${var.images[${imageno}]}"
credentials="\${var.images-credentials[${imageno}]}"
#

IFS="${IFS}";IFS=$'\n'
for attrip in `cat variables.tf |awk "/^vm_${sepsubnet}_${resname}/,/}/" |grep -v "{\|}\|^#" |tr -d ' ' |tr -d '"' |grep "^addip\|^saddip"`; do
unset attrname; attrname=`echo -e "${attrip}" |awk -F "=" '{print $1}'`
unset ipport; ipport="${p}`echo -e "${attrip}" |awk -F "_" '{print $2}' |awk -F "=" '{print $1}'`-${site}"
unset ipno; ipno=`echo -e "${attrip}" |awk -F "=" '{print $2}'`

for proip in $(seq 1 ${ipno}); do

# IP ATTRIBUTES
# PROVISION IP FUNCTION
preserve_ip () {
  unset findip; unset ipnet; unset ipvlan
  findip=`cat ${getip_cfg} |grep ";${ipport}-" |grep -v "grep" |grep -v ";PROVISIONED;" |head -1 |awk -F ";" '{print $1";"}'`
  [[ ! -z ${findip} ]] && ipnet=`cat ${getip_cfg} |grep "^${findip}" |awk -F ";" '{print $2}'` && ipvlan=`cat ranges.cfg |grep "^${ipnet}" |awk -F "-" '{print $4}'`
  [[ ! -z ${findip} ]] &&  sed -i "/^${findip}/ s/$/PROVISIONED;/" ${getip_cfg} && echo -e "`cat ${getip_cfg} |grep "^${findip}"`${tag};" >> provisionedip.cfg
}

# SPECIAL FOR SCAN IP
if [[ ${nodeloop} -eq 1 ]] && [[ ${set_dataonmgmt} == false ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "saddip_d" ]] && [[ ${addnet_d} -gt 0 ]] && [[ ${site} == "l" ]]; then
  preserve_ip
  ip_data_local+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_d_l; nip_d_l="${ipnet}" && unset nip_d_l_v; nip_d_l_v="${ipvlan}" && d_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${nodeloop} -eq 1 ]] && [[ ${set_dataonmgmt} == false ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "saddip_d" ]] && [[ ${addnet_d} -gt 0 ]] && [[ ${site} == "r" ]]; then
  preserve_ip
  ip_data_remote+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_d_r; nip_d_r="${ipnet}" && unset nip_d_r_v; nip_d_r_v="${ipvlan}" && d_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${nodeloop} -eq 1 ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "saddip_m" ]] && [[ ${addnet_m} -gt 0 ]] && [[ ${site} == "l" ]]; then
  preserve_ip
  ip_management_local+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_m_l; nip_m_l="${ipnet}" && unset nip_m_l_v; nip_m_l_v="${ipvlan}" && m_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${nodeloop} -eq 1 ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "saddip_m" ]] && [[ ${addnet_m} -gt 0 ]] && [[ ${site} == "r" ]]; then
  preserve_ip
  ip_management_remote+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_m_r; nip_m_r="${ipnet}" && unset nip_m_r_v; nip_m_r_v="${ipvlan}" && m_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
# SPECIAL FOR SCAN IP
if [[ ${set_dataonmgmt} == false ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_d" ]] && [[ ${addnet_d} -gt 0 ]] && [[ ${site} == "l" ]]; then
  preserve_ip
  ip_data_local+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_d_l; nip_d_l="${ipnet}" && unset nip_d_l_v; nip_d_l_v="${ipvlan}" && d_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${set_dataonmgmt} == false ]] && [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_d" ]] && [[ ${addnet_d} -gt 0 ]] && [[ ${site} == "r" ]]; then
  preserve_ip
  ip_data_remote+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_d_r; nip_d_r="${ipnet}" && unset nip_d_r_v; nip_d_r_v="${ipvlan}" && d_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_m" ]] && [[ ${addnet_m} -gt 0 ]] && [[ ${site} == "l" ]]; then
  preserve_ip
  ip_management_local+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_m_l; nip_m_l="${ipnet}" && unset nip_m_l_v; nip_m_l_v="${ipvlan}" && m_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_m" ]] && [[ ${addnet_m} -gt 0 ]] && [[ ${site} == "r" ]]; then
  preserve_ip
  ip_management_remote+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_m_r; nip_m_r="${ipnet}" && unset nip_m_r_v; nip_m_r_v="${ipvlan}" && m_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_o" ]] && [[ ${addnet_o} -gt 0 ]] && [[ ${site} == "l" ]]; then
  preserve_ip
  ip_oracle_pri_local+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_o_l; nip_o_l="${ipnet}" && unset nip_o_l_v; nip_o_l_v="${ipvlan}" && o_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
if [[ ${ipno} -ne 0 ]] && [[ ${attrname} == "addip_o" ]] && [[ ${addnet_o} -gt 0 ]] && [[ ${site} == "r" ]]; then
  preserve_ip
  ip_oracle_pri_remote+="${findip}"
  [[ ! -z ${findip} ]] && unset nip_o_r;nip_o_r="${ipnet}" && unset nip_o_r_v; nip_o_r_v="${ipvlan}" && o_net=`grep "^${ipnet}\-" ranges.cfg |awk -F "-" '{print $1"-"$2"-"$3}'`
fi
# IP ATTRIBUTES END
  done
done
IFS="${oIFS}"

#IP ATTRIBUTES LAST ARRANGE
unset m_l; m_l="${ip_management_local}"
unset m_r; m_r="${ip_management_remote}"
unset d_l; d_l="${ip_data_local}"
unset d_r; d_r="${ip_data_remote}"
unset o_l; o_l="${ip_oracle_pri_local}"
unset o_r; o_r="${ip_oracle_pri_remote}"
[[ ! -z ${ip_data_local} ]] && ip_data_local="VLAN${nip_d_l_v}-${nip_d_l};${ip_data_local}" && ip_data_gw=`cat ranges.cfg |grep "^${nip_d_l}-" |awk -F "data-local-" '{print $2}' |awk -F ";" '{print $1";"}'`
[[ ! -z ${ip_data_remote} ]] && ip_data_remote="VLAN${nip_d_r_v}-${nip_d_r};${ip_data_remote}" && ip_data_gw=`cat ranges.cfg |grep "^${nip_d_r}-" |awk -F "data-remote-" '{print $2}' |awk -F ";" '{print $1";"}'`
[[ ! -z ${ip_management_local} ]] && ip_management_local="VLAN${nip_m_l_v}-${nip_m_l};${ip_management_local}" && ip_management_gw=`cat ranges.cfg |grep "^${nip_m_l}-" |awk -F "management-local-" '{print $2}' |awk -F ";" '{print $1";"}'`
[[ ! -z ${ip_management_remote} ]] && ip_management_remote="VLAN${nip_m_r_v}-${nip_m_r};${ip_management_remote}" && ip_management_gw=`cat ranges.cfg |grep "^${nip_m_r}-" |awk -F "management-remote-" '{print $2}' |awk -F ";" '{print $1";"}'`
[[ ! -z ${ip_oracle_pri_local} ]] && ip_oracle_pri_local="VLAN${nip_o_l_v}-${nip_o_l};${ip_oracle_pri_local}"
[[ ! -z ${ip_oracle_pri_remote} ]] && ip_oracle_pri_remote="VLAN${nip_o_r_v}-${nip_o_r};${ip_oracle_pri_remote}"
ip_management_gw=`echo -e "${ip_management_gw}" |sed -r 's/(.*)-24;/\1 \/ 255.255.255.0/' |sed -r 's/(.*)-23;/\1 \/ 255.255.254.0/' |sed -r 's/(.*)-22;/\1 \/ 255.255.252.0/' |sed -r 's/(.*)-21;/\1 \/ 255.255.248.0/'`
ip_data_gw=`echo -e "${ip_data_gw}" |sed -r 's/(.*)-24;/\1 \/ 255.255.255.0/' |sed -r 's/(.*)-23;/\1 \/ 255.255.254.0/' |sed -r 's/(.*)-22;/\1 \/ 255.255.252.0/' |sed -r 's/(.*)-21;/\1 \/ 255.255.248.0/'`

######
# CUSTOM ATTRIBUTES END

# DNS RECORDS - DHCP IP
# DNS
oIFS="${IFS}"
unset dnsnameloop; IFS=',' read -r -a dnsnameloop <<< `echo -e "${dnsname}" |tr -d '[]'`
unset dnsnetloop; IFS=',' read -r -a dnsnetloop <<< `echo -e "${dnsnet}" |tr -d '[]'`
unset dnsipnoloop; IFS=',' read -r -a dnsipnoloop <<< `echo -e "${dnsipno}" |tr -d '[]'`
IFS="${oIFS}"
touch dns.cfg
unset dhcp
unset scoper
unset scope
for recno in $(seq 0 $((${#dnsnameloop[@]}-1))); do
  unset setdnsips
  for noip in $(seq 1 ${dnsipnoloop[${recno}]}); do
    unset lanname; lanname="${dnsnetloop[${recno}]}_${site}"
    unset dnsnameloop2; IFS='|' read -r -a dnsnameloop2 <<< `echo -e "${dnsnameloop[${recno}]}"`
    for dnsnameloopadd in ${dnsnameloop2[@]}; do
      [[ ${dnsnameloopadd} == "SCAN" ]] && [[ ! ${nodeloop} -eq 1 ]] && continue
      unset dnsext; dnsext="${tag}-${dnsnameloopadd}"; dnsext=`echo -e "${dnsext}" |sed -e 's/[-]*$//g'`
      echo "${dnsext}" |grep "\-SCAN$" &> /dev/null && dnsext=${dnsext%-*} && dnsext=${dnsext%-*}
      unset setdnsip; setdnsip=`echo ${!lanname} |awk -F ";" '{print $1";"}'`
      
      # DHCP
      if [[ -z ${dhcp} ]] && [[ ${lanname} == "m_${site}" ]] && dhcp=`echo ${!lanname} |awk -F ";" '{print $1";"}'`; then
        scoper=`echo -e "${dhcp}" |awk -F "." '{print $1"."$2"."$3"."}'`
        scope=`cat ranges.cfg |grep ";${scoper}\||${scoper}" |awk -F ";" '{print $2}' |awk -F "." '{print $1"."$2"."$3".0"}'`
      fi
      echo "${tag}|${dnsext}|${setdnsip}" >> dns.cfg
      # SPECIAL IPS
      [[ ${dnsnameloopadd} == "SCAN" ]] && ip_scan+="${setdnsip}"
      [[ ${dnsnameloopadd} == "VIP" ]] && ip_virtual+="${setdnsip}"
      [[ ${dnsnameloopadd} == "FLOATING" ]] && ip_floating+="${setdnsip}"
      [[ ${dnsnameloopadd} == "KVM" ]] && ip_kvm+="${setdnsip}"
      [[ ${dnsnameloopadd} == "KVMDATA" ]] && ip_kvm_data+="${setdnsip}"
      # SPECIAL IPS END
    done
    setdnsips+=${setdnsip}
    eval ${lanname}='${!lanname/${setdnsip}/}'
  done
  for dnsnameloopadd2 in ${dnsnameloop[${recno}]}; do
    oIFS=${IFS};IFS="|"
    for dnsnameloopadd in `echo -e "${dnsnameloopadd2}"`; do
         unset dnsext; dnsext="${tag}-${dnsnameloopadd}"; dnsext=`echo -e "${dnsext}" |sed -e 's/[-]*$//g'`
         echo "${dnsext}" |grep "\-SCAN$" &> /dev/null && dnsext=${dnsext%-*} && dnsext=${dnsext%-*}
         dns_entries+="${dnsext}|${setdnsips}  "
    done
    IFS=${oIFS}
  done
done
# DNS RECORDS - DHCP IP END

vmlist+="\"${tag},\""
######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

resource "vsphere_virtual_machine" "${tag}" {
  count = 1
  wait_for_guest_net_timeout = 0
  migrate_wait_timeout = "90"
  name = "${tag}"
  num_cores_per_socket = "${cpucores}"
  memory = "$((${memory}*1024))"
  hv_mode = "hvOn"
  nested_hv_enabled = true
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory_hot_add_enabled = true
  scsi_bus_sharing = "\${data.vsphere_virtual_machine.images.*.scsi_bus_sharing[${imageno}]}"
  #scsi_controller_count = "\${data.vsphere_virtual_machine.images.*.scsi_controller_count[${imageno}]}"
  scsi_type = "\${data.vsphere_virtual_machine.images.*.scsi_type[${imageno}]}"
  resource_pool_id = "\${data.vsphere_resource_pool.pl.id}"
  guest_id = "\${data.vsphere_virtual_machine.images.*.guest_id[${imageno}]}"
  folder = "$(if ! [[ $(basename $(dirname `pwd`)) == "ADD" ]]; then echo '${vsphere_folder.ve.path}'; else echo 'ENVS/${local.set_team}/${var.set_ve}'; fi)"

  cdrom {
      client_device = true
  }
ENDOFFILE
######

if [[ ${attachdiskshared} == "" ]] || ([[ ${tag} == ${tagprimary} ]] && [[ ${attachdiskshared} == "${sepsubnet}_${resname}" ]]) || ! cat ./variables.tf |grep "_${attachdiskshared}" |grep "^vm_" &> /dev/null; then

#####
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg
  datastore_cluster_id  = "\${data.vsphere_datastore_cluster.ds.id}"
ENDOFFILE
#####
fi 

#MANAGEMENT NETWORK
[[ ! -z ${addnet_m} ]] && [[ ${addip_m} -gt 0 ]] && for pci in $(seq 1 ${addnet_m}); do
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  network_interface {
      network_id = "\${data.vsphere_network.${m_net}.id}"
      adapter_type = "e1000e"
      }

ENDOFFILE
done
######

#DATA NETWORK
[[ ! -z ${addnet_d} ]] && [[ ! -z ${d_net} ]] && [[ ${set_dataonmgmt}=="false" ]] && [[ ${addip_d} -gt 0 ]] && for pci in $(seq 1 ${addnet_d}); do
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  network_interface {
      network_id = "\${data.vsphere_network.${d_net}.id}"
      adapter_type = "${card_type}"
      }

ENDOFFILE
done
######

#ORACLE PRIVATE NETWORK
[[ ! -z ${addnet_o} ]] && [[ ${addip_o} -gt 0 ]] && for pci in $(seq 1 ${addnet_o}); do
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  network_interface {
      network_id = "\${data.vsphere_network.${o_net}.id}"
      adapter_type = "e1000e"
      }

ENDOFFILE
done

######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  disk {
    label = "disk0"
    unit_number = 0
    size  = "\${data.vsphere_virtual_machine.images.*.disks.0.size[${imageno}]}"
    thin_provisioned = "\${data.vsphere_virtual_machine.images.*.disks.0.thin_provisioned[${imageno}]}"
    eagerly_scrub = "\${data.vsphere_virtual_machine.images.*.disks.0.eagerly_scrub[${imageno}]}"
  }

ENDOFFILE
######


unset attachunitno; attachunitno=0
oIFS=${IFS}
unset adddiskloop; IFS=',' read -r -a adddiskloop <<< `echo -e "${adddisk}" |tr -d '[]'`
IFS=${oIFS}
for recno in $(seq 0 $((${#adddiskloop[@]}-1))); do
[[ ! "${adddiskloop[${recno}]}" =~ ^[0-9]+$ ]] && continue
attachunitno=$((attachunitno+1))
if [[ ${attachdiskshared} == "" ]] || ([[ ${tag} == ${tagprimary} ]] && [[ ${attachdiskshared} == "${sepsubnet}_${resname}" ]]) || ! cat ./variables.tf |grep "_${attachdiskshared}" |grep "^vm_" &> /dev/null; then
######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  disk {
ENDOFFILE
######
   else
    cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg
  disk {
    datastore_id = "\${vsphere_virtual_machine.${attachdisktarget}.disk.0.datastore_id}"
ENDOFFILE
fi
######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg
    label = "adddisk$((${recno}+1))"
    unit_number = $((${recno}+1))
    size  = ${adddiskloop[${recno}]}
    thin_provisioned = false
    eagerly_scrub = "true"
  }

ENDOFFILE
######
done

### CREATE SHARED DISKS
if [[ "${tag}" == "${tagprimary}" ]]; then
oIFS=${IFS}
unset addshareddiskloop; IFS=',' read -r -a addshareddiskloop <<< `echo -e "${addshareddisk}" |tr -d '[]'`
IFS=${oIFS}
for recno in $(seq 0 $((${#addshareddiskloop[@]}-1))); do
[[ ! "${addshareddiskloop[${recno}]}" =~ ^[0-9]+$ ]] && continue
attachunitno=$((attachunitno+1))
######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

    disk {
    label = "${tag}-addshareddisk$((${#adddiskloop[@]}+1+${recno}))"
    unit_number = $((${#adddiskloop[@]}+1+${recno}))
    size  = ${addshareddiskloop[${recno}]}
    thin_provisioned = false
    eagerly_scrub = "true"
    #disk_sharing = "sharingMultiWriter"
    #disk_mode = "persistent"
    #path = ""
  }

ENDOFFILE
######
done
fi 
### CREATE SHARED DISKS END

### ATTACH SHARED DISKS
if [[ ! ${attachdiskshared} == "" ]] && cat ./variables.tf |grep "_${attachdiskshared}" |grep "^vm_" &> /dev/null && [[ ! ${tag} == ${attachdisktarget} ]]; then
unset attachdisksharedloop; unset adddisklist;
adddisklist+="0"; diskunitno=0
for adddisks in `cat variables.tf |awk "/${attachdiskshared}/,/}/" |grep -v "{\|}\|^#" |grep "^adddisk\|^addshareddisk" |tr -d '[]'`; do
  unset addtype; addtype=`echo -e "${adddisks}" | awk -F "=" '{print $1}' |tr -d '[] '`
  IFS=',' read -r -a attachdisksharedloop <<< `echo -e "${adddisks}" | awk -F "=" '{print $2}' |tr -d '[]" '`
  for adddisk in $(seq 0 $((${#attachdisksharedloop[@]}))); do
  [[ ! ${attachdisksharedloop[${adddisk}]} =~ ^[0-9]+$ ]] && continue
  diskunitno=$((diskunitno+1))
  adddisklist+=(${attachdisksharedloop[${adddisk}]})
  [[ ${addtype} == "addshareddisk" ]] && attachunitno=$((attachunitno+1)) && cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

   disk {
     datastore_id = "\${vsphere_virtual_machine.${attachdisktarget}.disk.${diskunitno}.datastore_id}"
     attach = true
     unit_number=${attachunitno}
     path = "${attachdisktarget}/${attachdisktarget}_${diskunitno}.vmdk"
     label = "${tag}-attacheddisk-${attachunitno}"
     #disk_sharing = "sharingMultiWriter"
     #disk_mode = "persistent"
  }

ENDOFFILE
  done
 # IFS=${oIFS}
done

fi
#### ATTACH SHARED DISKS END

#####
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg

  clone {
    template_uuid = "\${data.vsphere_virtual_machine.images.*.id[${imageno}]}"
  }

  custom_attributes = "\${map(
ENDOFFILE
######

oIFS="${IFS}";IFS=$'\n'
for attr in `cat custom-attributes.conf`; do
                        [[ "$(eval echo \$${attr//-/_})" == "" ]] && continue
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg
                        data.vsphere_custom_attribute.attr-${attr}.id, "$(eval echo \$${attr//-/_})",
ENDOFFILE
######
done
IFS="${oIFS}"
######
cat <<ENDOFFILE >> ./${envfiletag}-${tag}.cfg
  )}"

}
ENDOFFILE
######

######
cat <<ENDOFFILE >> ./dhcp-${tag}.cfg

resource "null_resource" "dhcp-${tag}" {
  provisioner "local-exec" {
    command="add-dhcp.sh '\${var.dhcp-creds["set_dhcp_password"]}' '\${var.dhcp-creds["set_dhcp_user"]}' '${scope}' '${dhcp//;/}' '\${replace(vsphere_virtual_machine.${tag}.network_interface.0.mac_address,":","")}' '${tag}.${set_dnszone}' '${tag}.${set_dnszone}'"
  }
  provisioner "local-exec" {
    command="echo '${tag};${scope};${dhcp//;/};\${replace(vsphere_virtual_machine.${tag}.network_interface.0.mac_address,":","")};${tag}.${set_dnszone};${tag}.${set_dnszone};' >> reserved-dhcp.cfg"
  } 
  provisioner "local-exec" {
    command="delete-dhcp.sh '\${var.dhcp-creds["set_dhcp_password"]}' '\${var.dhcp-creds["set_dhcp_user"]}' '${dhcp//;/})'"
    when = "destroy"
  }
}

resource "null_resource" "restart-${tag}" {
  depends_on = ["null_resource.dhcp-${tag}"]
  provisioner "local-exec" {
    command="restart-vm.sh \"\${var.provider-vsphere["user"]}\" \"\${var.provider-vsphere["password"]}\" \"\${var.provider-vsphere["vsphere_server"]}\" \"${tag}\""
  }
}
# DHCP PROVISIONER FOR EACH

ENDOFFILE
######
done
  done
    done
      IFS=${oIFS}

# FOR REGENERATING SAME IPS
sed -i 's/PROVISIONED;//g' ${getip_cfg}

######
#cat <<ENDOFFILE >> ./outputs.tf
#On destroy delete ips.
#KVM
#Floating IP
#ENDOFFILE

# CREATE DNS TF FILE
unset dnsaddcom; unset dnsdelcom
oIFS="${IFS}"; IFS=$'\n'
for dnsadd in `cat ./dns.cfg`; do
#echo "A${dnsadd}"
unset dnshost; dnshost=`echo -e "${dnsadd}" |awk -F "|" '{print $2}'`
unset dnshostip; dnshostip=`echo -e "${dnsadd}" |awk -F "|" '{print $3}'`
#echo $dnszone
#echo $dnszoneip
dnsaddcom+='dnscmd ${var.dns-creds["set_dns_server"]} /recordadd ${local.set_dnszone}'" ${dnshost} A ${dnshostip//;/}\n"
dnsdelcom+='dnscmd ${var.dns-creds["set_dns_server"]} /recorddelete ${local.set_dnszone}'" ${dnshost} A ${dnshostip//;/} /f\n"
done
IFS="${oIFS}"
#echo -e "${dnsaddcom}"
#echo -e "${dnsdelcom}"

cat <<ENDOFFILE >> ./dns.tf

resource "null_resource" "dns" {

  provisioner "local-exec" {
    command=<<-HEREDOC
      sshpass -p '\${var.dns-creds["set_dns_password"]}' ssh -o StrictHostKeyChecking=no \${var.dns-creds["set_dns_user"]} <<EOT
$(echo -e "${dnsaddcom}" |grep -v "^$")
EOT
    HEREDOC
  }

  provisioner "local-exec" {
    command=<<-HEREDOC
      sshpass -p '\${var.dns-creds["set_dns_password"]}' ssh -o StrictHostKeyChecking=no \${var.dns-creds["set_dns_user"]} <<EOT
$(echo -e "${dnsdelcom}" |grep -v "^$")
EOT
    HEREDOC
    when = "destroy"
  }

}
ENDOFFILE
# CREATE DNS TF FILE END

for cfg in `ls ${envfile} ${envfiletag}* dhcp-* |grep ".cfg$"`; do 
  mv ${cfg} ${cfg//.cfg/.tf}
done

# IMPORTANT BUGS
# image selection control et

### LINK, OR COPY DUSUN

### DREAM
### TASK MANAGER
### VE NUMBER GET AUTO

### IMAGING
### CREATE IMAGES
### https://www.virtuallyghetto.com/2014/09/how-to-run-qemu-kvm-on-esxi.html
### https://www.techrepublic.com/blog/the-enterprise-cloud/scripting-out-dhcp-reservations-in-windows-server-2008-with-netsh/

#LATER
# SCANIPNO
### FC ON EKLE
