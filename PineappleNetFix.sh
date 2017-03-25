#!/bin/bash

# tldr; Fixes problem where host looses network connection and gives
# the Pineapple an Internet connection though the host.
# 
# The Hak5 Wifi Pineapplle has a known issue where when it's connected
# to a host via the USB interface, it will kill the network connection 
# on the host it was connected to. This is becuase the Pineapple becomes
# the default gateway for the host. This script fixes this issue while
# also allowing the Pineapple to connect to the internet via the host
# it's attached to. 
#
# Author: Dylan Smyth


if [[ $EUID != 0 ]] ; then
  echo "This must be run as root!"
  exit 1
fi

if [[ $# < 3 ]] ; then
  echo "Usage:"
  echo "  ./PineappleNetFix.sh <INTERNAL_IFACE> <EXTERNAL_IFACE> <GATEWAY_IP>"
  echo ""
  echo "Where..."
  echo "  <INTERNAL_IFACE> is the ethernet interface created by the Pineapple."
  echo "  <EXTERNAL_IFACE> is the interface with an internet connection."
  echo "  <GATEWAY_IP> is the IP address of the network gateway for <EXTERNAL_IFACE>."
  echo ""
  echo "Example usage:"
  echo "  ./PineappleNetFix.sh eth2 wlan0 192.168.1.254"
  exit 0
fi

iface_in=$1
iface_ex=$2
gw=$3

echo "Bring up internal interface"
ifconfig $iface_in up
ifconfig $iface_in 172.16.42.42 netmask 255.255.255.0
echo "Internal iface IP is 172.16.42.42"

echo "Fixing route for default gateway"
route del default gw Pineapple.lan
route add default gw $gw netmask 0.0.0.0

echo "Turning on IP forwarding"
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Setting up iptables rules"
iptables -t nat -A POSTROUTING -o $iface_ex -j MASQUERADE
iptables -A FORWARD -i $iface_ex -o $iface_in -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $iface_in -o $iface_ex -j ACCEPT

echo "Done."
