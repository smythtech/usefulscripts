#!/bin/bash

# This script acts as a wrapper for the iptables commands used to 
# enable Network Address Translation (NAT). Makes it a bit easier
# to switch NAT on and off for given interfaces.
#
# Author: Dylan Smyth


if [[ $EUID != 0 ]] ; then
  echo "This must be run as root!"
  exit 1
fi

if [[ $# < 3 ]] ; then
  echo "Usage:"
  echo "  easynat.sh <enable | disable> <INTERNAL_IFACE> <EXTERNAL_IFACE>"
  echo ""
  echo "Example usage:"
  echo "  easynat.sh enable eth2 wlan0"
  exit 1
fi

iface_in=$2
iface_ex=$3

if [ $1 = "enable" ] ; then
  echo "Enabling Nat"
  action="-A"
  forward=1
elif [ $1 = "disable" ] ; then
  echo "Disabling Nat"
  action="-D"
  forward=0
else
  echo "Invalid option. Use enable or disable."
  exit 1
fi
echo $forward > /proc/sys/net/ipv4/ip_forward
iptables -t nat $action POSTROUTING -o $iface_ex -j MASQUERADE
iptables $action FORWARD -i $iface_ex -o $iface_in -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables $action FORWARD -i $iface_in -o $iface_ex -j ACCEPT
