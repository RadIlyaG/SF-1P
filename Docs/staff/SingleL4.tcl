Configure
port 
cellular lte
mode sim 1
sim 1
apn-name "statreal"
pdp-type relayed-ppp
exit
no shutdown
exit all
configure router 1
interface 1
bind cellular lte
no shutdown
exit all

# sim 2
exit all
configure port cellular lte
config>port>cellular lte > shutdown  
sim 2
apn-name "statreal"
exit
mode sim 2
no shutdown
exit all
configure port cellular lte 
config>port>cellular(lte)# no shutdown