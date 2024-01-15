configure
port
cellular lte
sim 1
apn-name "statreal"
exit
mode sim 1
no shutdown
exit
exit
router 1
interface 1
bind cellular lte
dhcp
dhcp-client
client-id mac
exit
no shutdown
exit all

## sim2
exit all
configure port cellular lte
config>port>cellular(lte)# shutdown  
sim 2
apn-name "statreal"
exit
mode sim 2
no shutdown
exit all
configure port cellular lte 
config>port>cellular(lte)# no shutdown