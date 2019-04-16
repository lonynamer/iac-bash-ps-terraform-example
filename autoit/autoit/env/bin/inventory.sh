#!/bin/bash
IFS=$'\n'
envpath="/autoit.data/env/ve"

rm -rf /autoit.data/inv/html_new &> /dev/null
mkdir -p /autoit.data/inv/html_new
echo -e "<pre>" >> /autoit.data/inv/html_new/index.html
echo -e "     AXXANA NEW INVENTORY\n\n" >> /autoit.data/inv/html_new/index.html
for env in `ls -d /autoit.data/env/ve/*`; do 

  # ENV
  cd ${envpath}
  cd $(basename ${env})
  if [[ ! -z $(basename ${env}) ]] && [[ `terraform show |wc -l` -gt 1 ]]; then
    # LINKS
    links+="<a href="http://inv.axxana.local/$(basename ${env})">$(basename ${env})</a>     "
    # LINKS END
    mkdir /autoit.data/inv/html_new/$(basename ${env})
    echo -e "$(terraform show |grep "^vsphere_virtual_machine\|^  custom")@3@@@@@@@@@" |grep -v "^  custom_attributes.%" |awk "/^vsphere_virtual_machine/,/$'\n'[a-z]/" |sed "s/^vsphere_virtual_machine./@2@@@@@@@@@/g" |sed '0,/@2@@@@@@@@@/s//<table bordercolor=black><tr><td><pre>/' |sed '0,/@3@@@@@@@@@/s//<\/td><\/tr><\/table>/' |sed 's/^@2@@@@@@@@@/<\/tr><\/table><br \/><table bordercolor=black><tr><td><pre>/g' |sed "s/;  V/;\n                V/g" >> /autoit.data/inv/html_new/$(basename ${env})/index.html
  else
    continue
  fi
  echo ${env}

#SUBENV
  subenvpath="/autoit.data/env/ve/$(basename ${env})/ADD"
  ls -d /autoit.data/env/ve/$(basename ${env})/ADD/* &> /dev/null && for env2 in `ls -d /autoit.data/env/ve/$(basename ${env})/ADD/*`; do
    cd ${subenvpath}
    cd $(basename ${env2})
    if [[ ! -z $(basename ${env2}) ]] && [[ `terraform show |wc -l` -gt 1 ]]; then
      echo -e "$(terraform show |grep "^vsphere_virtual_machine\|^  custom")@3@@@@@@@@@" |grep -v "^  custom_attributes.%" |awk "/^vsphere_virtual_machine/,/$'\n'[a-z]/" |sed "s/^vsphere_virtual_machine./@2@@@@@@@@@/g" |sed '0,/@2@@@@@@@@@/s//<table bordercolor=black><tr><td><pre>/' |sed '0,/@3@@@@@@@@@/s//<\/td><\/tr><\/table>/' |sed 's/^@2@@@@@@@@@/<\/tr><\/table><br \/><table bordercolor=black><tr><td><pre>/g' |sed "s/;  V/;\n                V/g" >> /autoit.data/inv/html_new/$(basename ${env})/index.html
    else
      continue
    fi
    echo ${env2}
  done
  for attr in `terraform show |awk "/^data.vsphere_custom_attribute/,/  name/" |grep "  id\|  name" |sed 's/  id = /  custom_attributes./g' |sed 'N;s/\n  name = /\/  /'`; do
    #echo -e "${attr}"
    sed -i "s/${attr}/g" /autoit.data/inv/html_new/$(basename ${env})/index.html
  done
  sed -i "1s/^/<a href=\"http:\/\/inv.axxana.local\">BACK TO MAIN<\/a><br \/><br \/>$(basename ${env})<br \/><br \/>/" /autoit.data/inv/html_new/$(basename ${env})/index.html
done

# MAIN PAGE
echo ${links} >> /autoit.data/inv/html_new/index.html
mv /autoit.data/inv/html /autoit.data/inv/html_old
mv /autoit.data/inv/html_new /autoit.data/inv/html
rm -rf /autoit.data/inv/html_old
exit
