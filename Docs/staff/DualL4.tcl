configure
port
cellular lte-1
sim 1
apn-name "statreal"
exit
no shutdown
exit
cellular lte-2
sim 1
apn-name "statreal"
pdp-type relayed-ppp
exit
no shutdown
exit
exit
router 1
interface 1
bind cellular lte-1
dhcp
dhcp-client
client-id mac
exit
no shutdown
exit
interface 2
bind cellular lte-2
dhcp
dhcp-client
client-id mac
exit
no shutdown
exit
exit all

•	check the parameters the modem  sim 1
configure port cellular lte-1
config>port>cellular(lte)# show status