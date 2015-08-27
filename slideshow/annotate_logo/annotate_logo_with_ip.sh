#!/bin/sh

ip_addr=$(host -t A $(hostname) | awk '{ print $NF }')

rm logo_with_ip.png

convert logo.png -fill '#00000080' -gravity Southwest \
  -annotate +0+0 "$ip_addr" logo_with_ip.png

cp logo_with_ip.png ~/logo.png
