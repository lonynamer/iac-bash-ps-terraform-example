#!/bin/bash
sshpass -p $1 ssh -o StrictHostKeyChecking=no $2 "powershell (Get-DhcpServerv4Reservation -IPAddress $3 -and (Remove-DhcpServerv4Reservation -IPAddress $3" || exit 1
sshpass -p $1 ssh -o StrictHostKeyChecking=no $2 "powershell (Get-DhcpServerv4Lease -IPAddress $3 -and (Remove-DhcpServerv4Lease -IPAddress $3" || exit1
