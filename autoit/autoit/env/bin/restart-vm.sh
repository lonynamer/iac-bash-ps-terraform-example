#!/bin/bash
vm="${4}" vcadmin="${1}" vcpass="${2}" vcserver="${3}" pwsh -Command 'Connect-VIServer -server $env:vcserver -Force -WarningAction 0 -Username $env:vcadmin -Password $env:vcpass; restart-vm -VM $env:vm -runasync -confirm:$false'
