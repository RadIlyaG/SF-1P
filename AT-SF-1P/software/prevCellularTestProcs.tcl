# ***************************************************************************
# neCellularModem
# ***************************************************************************
proc neCellularModem {run} {
  MuxMngIO nc
  set ret [CellularLte] 
  if {$ret!=0} {
     return -1
  }
  set ret [CellularModemPerf 1 notL4] 
  #CellularModemCloseGpio  
  if {$ret!=0} {
     return -1
  }
  set ret [CellularModemPerf 2 notL4]   
  #CellularModemCloseGpio
  if {$ret!=0} {
    return -1
  }  
#   set ret [CellularFirmware]   
#   if {$ret!=0} {return -1}
  return $ret
} 

# ***************************************************************************
# neCellularDualModem
# ***************************************************************************
proc neCellularDualModem {run} {
  set ret [CellularModemPerfDual notL4]   
  if {$ret!=0} {return -1}
  set ret [CellularFirmwareDual]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# neCellularModemL4
# ***************************************************************************
proc neCellularModemL4 {run} {
  set ret [CellularModemPerf 1 L4]   
  if {$ret!=0} {return -1}
  set ret [CellularModemPerf 2 L4]   
  if {$ret!=0} {return -1}  
  set ret [CellularFirmware]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# neCellularDualModemL4
# ***************************************************************************
proc neCellularDualModemL4 {run} {
  set ret [CellularModemPerfDual L4]   
  if {$ret!=0} {return -1}
  set ret [CellularFirmwareDual]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# neCellularLte
# ***************************************************************************
proc neCellularLte {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Cellular Lte"
  
  set ret [Send $com "exit all\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Exit All fail"
    return $ret
  }
  set ret [Send $com "configure port cellular lte\r" "(lte)"]
  if {$ret!=0} {
    set gaSet(fail) "Configure LTE fail"
    return $ret
  }
  set ret [Send $com "shutdown\r" "(lte)"]
  if {$ret!=0} {
    set gaSet(fail) "Shutdown LTE fail"
    return $ret
  }
  set ret [Send $com "no shutdown\r" "(lte)"]
  if {$ret!=0} {
    set gaSet(fail) "No Shutdown LTE fail"
    return $ret
  }
  set ret [Send $com "exit all\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Exit All fail"
    return $ret
  }
  set ret [Send $com "configure router 1 interface 1\r" "(1)"]
  if {$ret!=0} {
    set gaSet(fail) "Configure Router fail"
    return $ret
  }
  set ret [Send $com "shutdown\r" "(1)"]
  if {$ret!=0} {
    set gaSet(fail) "Shutdown Router fail"
    return $ret
  }
  set ret [Send $com "dhcp\r" "(1)"]
  if {$ret!=0} {
    set gaSet(fail) "Configure DHCP fail"
    return $ret
  }
  set ret [Send $com "bind cellular lte\r" "(1)"]
  if {$ret!=0} {
    set gaSet(fail) "Bind Cellular LTE fail"
    return $ret
  }
  set ret [Send $com "no shutdown\r" "(1)"]
  if {$ret!=0} {
    set gaSet(fail) "No Shutdown Router fail"
    return $ret
  }
  return $ret
}
# ***************************************************************************
# neCellularModemPerf
# ***************************************************************************
proc neCellularModemPerf {slot l4} {
  global gaSet buffer
  puts "[MyTime] CellularModemPerf $slot $l4"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem of SIM-$slot fail" 
  set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio500/value\r" "\]#"]
  if {$ret!=0} {return -1}
  after 2000
#   set ret [Send $com "echo \"487\" > /sys/class/gpio/export\r" "\]#"]
#   if {$ret!=0} {return -1}
  set ret [Send $com "echo \"out\" > /sys/class/gpio/gpio487/direction\r" "\]#"]
  if {$ret!=0} {return -1}
#   set ret [Send $com "echo \"500\" > /sys/class/gpio/export\r" "\]#"]
#   if {$ret!=0} {return -1}
  set ret [Send $com "echo \"out\" > /sys/class/gpio/gpio500/direction\r" "\]#"]
  if {$ret!=0} {return -1}
  
  set w 5; Wait "Wait $w seconds for GPIO init" $w
  
  set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio500/value\r" "\]#"]
  if {$ret!=0} {return -1}
  
  set w 10; Wait "Wait $w seconds for modem OFF" $w
  
  set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio500/value\r" "\]#"]
  if {$ret!=0} {return -1}
  
  if {$slot==1} {
    set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio487/value\r" "\]#"]
  } elseif {$slot==2} {
    set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio487/value\r" "\]#"]
  }
  if {$ret!=0} {return -1}
  set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio500/value\r" "\]#"]
  if {$ret!=0} {return -1}
  
  set w 10; Wait "Wait $w seconds for modem ON" $w
  
  set res1 [set res2 [set res3 [set res4 0]]]
  for {set i 1} {$i<=7} {incr i} {
    Status "Connecting to Cellular Network ($i)"
    after 2000
    puts "Slot:$slot i:$i res1:$res1 res2:$res2 res3:$res3 res4:$res4"
    set ret [Send $com "/usr/sbin/quectel-CM -s internetg \&\r" "add wwan0" ]
    set ::buff $buffer
#     if {$ret==0} {}
    if 1 {
      set res [regexp {SIMStatus:\s+([\w\_\-]+)\s} $buffer ma simSta]
      puts "res of SIMStatus = $res"
      if {$res==0} {
        set gaSet(fail) "Read SIMStatus of SIM-$slot fail"
        set ret -1
        continue
      }
      AddToPairLog $gaSet(pair) "SIMStatus of SIM-$slot is \'$simSta\'"
      if {$simSta!="SIM_READY"} {
        set gaSet(fail) "SIMStatus of SIM-$slot is \'$simSta\'. Should be \'SIM_READY\'"
        set ret -1
        if {$simSta=="SIM_ABSENT"} {
          break
        } else {
          continue
        }
      } else {
        set res1 1
      }
      
      set res [regexp {requestBaseBandVersion\s+([\w\_\-]+)\s} $buffer ma bandVer]
      puts "res of BaseBandVersion = $res"
      if {$res==0} {
        set gaSet(fail) "Read BaseBandVersion of SIM-$slot fail"
        set ret -1
        continue
      }
      AddToPairLog $gaSet(pair) "BaseBandVersion of SIM-$slot is \'$bandVer\'"
      set cell [string range $gaSet(dutFam.cell) 1 end]
      set fw $gaSet([set cell].fwL) 
      if {$bandVer!=$fw} {
        set gaSet(fail) "BaseBandVersion of SIM-$slot is \'$bandVer\'. Should be \'$fw\'"
        set ret -1
        continue
      } else {
        set res2 1
      }
      
      set res [regexp -all {DataCap:\s+([\w]+)\s} $buffer ma dataCap]
      puts "res of DataCap = $res"
      if {$res==0} {
        set gaSet(fail) "Read DataCap of SIM-$slot fail"
        set ret -1
        continue
      }
      AddToPairLog $gaSet(pair) "DataCap of SIM-$slot is \'$dataCap\'"
      if {$dataCap!="LTE"} {
        set gaSet(fail) "DataCap of SIM-$slot is \'$dataCap\'. Should be \'LTE\'"
        set ret -1
        continue
      } else {   
        set res3 1
      }
        
      set res [regexp -all {IPv4ConnectionStatus:\s+([\w\s]+)\s} $buffer ma ipv4ConSta]
      puts "res of IPv4ConnectionStatus = $res"
      if {$res==0} {
        set gaSet(fail) "Read IPv4ConnectionStatus of SIM-$slot fail"
        set ret -1
        continue
      }
      AddToPairLog $gaSet(pair) "IPv4ConnectionStatus of SIM-$slot is \'$ipv4ConSta\'"
      if {$ipv4ConSta!="CONNECTED"} {
        set gaSet(fail) "IPv4ConnectionStatus of SIM-$slot is \'$ipv4ConSta\'. Should be \'CONNECTED\'"
        set ret -1
        continue
      } else {
        set res4 1
      }
      
      if {$res1 && $res2 && $res3 && $res4} {
        set ret 0
        break
      } 
    }
  }
  
  if {$ret!=0} {
#     set gaSet(fail) "Cellular Test of SIM-$slot fail"
    return -1
  }
  
  if {$ret==0} {
    set w 5; Wait "Wait $w seconds for Network" $w
    for {set i 1} {$i<=5} {incr i} {
      puts "Ping $i"  
      set gaSet(fail) "Send ping to 8.8.8.8 from SIM-$slot fail"     
      set ret [Send $com "ping 8.8.8.8 -c 5\r" "\]#" 15]
      if {$ret!=0} {return -1}
      set ret -1  
      if {[string match {*5 packets transmitted, 5 received, 0% packet loss*} $buffer]} {
        set ret 0
        break
      } else {
        set gaSet(fail) "Ping to 8.8.8.8 from SIM-$slot fail" 
      }
    }
  }
  
  return $ret
}  
# ***************************************************************************
# neCellularModemPerfDual
# ***************************************************************************
proc neCellularModemPerfDual {l4} {
  global gaSet buffer
  puts "[MyTime] CellularModemPerfDual $l4"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration dual modem fail" 
  Status "Modem 1 power-down"
  set ret [Send $com "cellular modem 1 power-down\r" "SecFlow-1v#"]
  if {$ret!=0} {
    after 2000
    set ret [Send $com "cellular modem 1 power-down\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
  }
  Status "Modem 2 power-down"
  set ret [Send $com "cellular modem 2 power-down\r" "SecFlow-1v#"]
  if {$ret!=0} {
    after 2000
    set ret [Send $com "cellular modem 2 power-down\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
  }
  
  foreach mdm {1 2} {
    for {set i 1} {$i<=20} {incr i} {
      Status "Waif for powering down"    
      set ret [Send $com "cellular disable modem-id $mdm\r" "SecFlow-1v#"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular disabled*} $buffer] || [string match {*already disabled*} $buffer] } {
        break
      }
    }  
  }
  
  
  set ret [Send $com "router static\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "enable\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "configure terminal\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "ip route 8.8.8.0/24 ppp0\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "ip route 151.101.2.0/24 ppp1\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "exit\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "exit\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  
  if {$l4=="notL4"} {
    set ret [Send $com "cellular wan update sim-slot 1 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest radio-access-technology auto connection-method direct-IP\r" "SecFlow-1v#"]
  } elseif {$l4=="L4"} {
    set ret [Send $com "cellular wan update sim-slot 1 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest connection-method ppp\r" "SecFlow-1v#"]
  }  
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  if {$l4=="notL4"} {
    set ret [Send $com "cellular wan update sim-slot 2 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest radio-access-technology auto connection-method direct-IP\r" "SecFlow-1v#"]
  } elseif {$l4=="L4"} {
    set ret [Send $com "cellular wan update sim-slot 2 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest connection-method ppp\r" "SecFlow-1v#"]
  }
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  set ret [Send $com "cellular settings update modem-id 1 default-route no\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  set ret [Send $com "cellular settings update modem-id 2 default-route no\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  foreach mdm {1 2} {
    for {set i 1} {$i<=20} {incr i} {
      Status "Waif for powering down and up" 
      set ret [Send $com "cellular enable modem-id $mdm\r" "SecFlow-1v#"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular enabled*} $buffer] || [string match {*cellular already enabled*} $buffer]} {
        break
      }
    }  
  }
  
  set sec1 [clock seconds]
  set st1 [set st2 NA]
  for {set i 1} {$i<=22} {incr i} {
    # puts "[MyTime] CellularModemPerf.1 i:$i"
    set sec2 [clock seconds]
    set aft [expr {$sec2-$sec1}]
    set ret [Wait "SIM-1&2 Wait for cellular (after $aft sec: $st1 $st2)" 10]
    if {$ret!=0} {return -1}
    
    set ret [Send $com "cellular network show\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
    
    set st1 "NA" 
    set rssi1 "NA"
    set st2 "NA" 
    set rssi2 "NA"
    set res [regexp { 1[\s\|]+([A-Z\.]+?)\!?\s} $buffer ma st1]
    puts "CellularDualModemPerf 1 i:$i res1:<$res> st1:<$st1>"
    set res [regexp { 2[\s\|]+([A-Z\.]+?)\!?\s} $buffer ma st2]
    puts "CellularDualModemPerf 2 i:$i res2:<$res> st2:<$st2>"
    
    if {$st1=="CONNECTED" && $st2=="CONNECTED"} {
      set ret 0
      set res [regexp {1.+?No[\s\|]+(-\d{2})} $buffer ma rssi1]
      set res [regexp {2.+?No[\s\|]+(-\d{2})} $buffer ma rssi2]
      break
    } else {
#       set ret [Wait "SIM-1&2 Wait for cellular ($i. $st1 $st2)" 8]
#       if {$ret!=0} {return -1}
    }
  }  
  puts "[MyTime] CellularDualModemPerf i:$i st1:<$st1> rssi1:<$rssi1> st2:<$st2> rssi2:<$rssi2>"
   set sec2 [clock seconds]
  set aft [expr {$sec2-$sec1}]
  if {$st1!="CONNECTED"} {
    set gaSet(fail) "After $aft sec Oper Status of SIM-1 is \'$st1\'. Should be \'CONNECTED\'" 
    return -1
  }
  if {$st2!="CONNECTED"} {
    set gaSet(fail) "After $aft sec Oper Status of SIM-2 is \'$st2\'. Should be \'CONNECTED\'" 
    return -1
  }
  
  AddToPairLog $gaSet(pair) "RSSI of SIM-1 is \'$rssi1\'"
  AddToPairLog $gaSet(pair) "RSSI of SIM-2 is \'$rssi2\'"
  
  if {$rssi1>"-51" || $rssi1<"-90"} {
    set gaSet(fail) "RSSI of SIM-1 is \'$rssi1\'. Should be between -51 and -90" 
    return -1
  }
  if {$rssi2>"-51" || $rssi2<"-90"} {
    set gaSet(fail) "RSSI of SIM-2 is \'$rssi2\'. Should be between -51 and -90" 
    return -1
  }
  
  set ret [Ping2Cellular 1 "8.8.8.8"]
  if {$ret!=0} {return $ret}
  set ret [Ping2Cellular 2 "151.101.2.1"]
  if {$ret!=0} {return $ret}
    
  return $ret
}  
# ***************************************************************************
# neCellularFirmware
# ***************************************************************************
proc neCellularFirmware {} {
  global gaSet buffer
  puts "[MyTime] CellularFirmware"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem fail" 
  set ret [Send $com "cellular disable\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  
  if {[string match {*cellular already disabled*} $buffer]} {
    ## skip waiting
  } else {
    set ret [Wait "Wait for cellular disable" 20]
    if {$ret!=0} {return -1}
  }
  
  set gaSet(fail) "Read modem version fail" 
  set ret [Send $com "cellular modem power-up\r" "SecFlow-1v#" 30]
  if {$ret!=0} {return -1}
  set ret [Send $com "cellular modem get version\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem version fail"
    return -1 
  }
  set fw [string trim $val]
  set mdm [string range $gaSet(dutFam.cell) 1 end] 
  set cellFwL $gaSet($mdm.fwL)
  puts "CellularFirmware fw:<$fw> mdm:<$mdm> cellFwL:<$cellFwL>"
  if {[lsearch $cellFwL $fw]!="-1"} {
    set ret 0
  } else {
    set gaSet(fail) "The FW is \'$fw\'. Should be one of $cellFwL"
    set ret -1 
  }
  
  set ret [Send $com "cellular modem get imei\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  Send $com "cellular modem power-down\r" "SecFlow-1v#" 
  
  return $ret
}
# ***************************************************************************
# neCellularFirmwareDual
# ***************************************************************************
proc neCellularFirmwareDual {} {
  global gaSet buffer
  puts "[MyTime] CellularFirmwareDual"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem fail" 
 
  foreach mdm {1 2} {
    for {set i 1} {$i<=20} {incr i} {
      Status "Waif for modem $mdm powering down" 
      set ret [Send $com "cellular disable modem-id $mdm\r" "SecFlow-1v#"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular disabled*} $buffer] || [string match {*already disabled*} $buffer] } {
        break
      }
    }  
  }
  
  set gaSet(fail) "Read modem version fail" 
  Status "Modem 1 power-up"
  set ret [Send $com "cellular modem 1 power-up\r" "SecFlow-1v#" 30]
  if {$ret!=0} {return -1}
  Status "Modem 2 power-up"
  set ret [Send $com "cellular modem 2 power-up\r" "SecFlow-1v#" 30]
  if {$ret!=0} {return -1}
  
  
  Status "Modem 1 get version"
  set gaSet(fail) "Read modem 1 version fail" 
  set ret [Send $com "cellular modem 1 get version\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  if {[string match {*failed to communicate with modem*} $buffer]} {
    set ret [Send $com "cellular modem 1 power-down\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 1 power-up\r" "SecFlow-1v#" 30]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 1 get version\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
  }
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val1]
  if {$res==0} {
    set gaSet(fail) "Read modem 1 version fail"
    return -1 
  }
  set fw1 [string trim $val1]
  
  set ret [Send $com "cellular modem 1 get imei\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem 1 IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  Status "Modem 2 get version"
  set gaSet(fail) "Read modem 2 version fail" 
  set ret [Send $com "cellular modem 2 get version\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  if {[string match {*failed to communicate with modem*} $buffer]} {
    set ret [Send $com "cellular modem 2 power-down\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 2 power-up\r" "SecFlow-1v#" 30]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 2 get version\r" "SecFlow-1v#"]
    if {$ret!=0} {return -1}
  }
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val2]
  if {$res==0} {
    set gaSet(fail) "Read modem 2 version fail"
    return -1 
  }
  set fw2 [string trim $val2]
  
  set ret [Send $com "cellular modem 2 get imei\r" "SecFlow-1v#"]
  if {$ret!=0} {return -1}
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem 2 IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  set mdm [string range $gaSet(dutFam.cell) 1 end] 
  set cellFwL $gaSet($mdm.fwL)
  puts "CellularFirmware fw1:<$fw1>  fw2:<$fw2>  mdm:<$mdm> cellFwL:<$cellFwL>"

  if {[lsearch $cellFwL $fw1]!="-1" && [lsearch $cellFwL $fw2]!="-1"} {
    set ret 0
  } elseif {[lsearch $cellFwL $fw1]=="-1"} {
    set gaSet(fail) "The FW of modem-1 is \'$fw1\'. Should be one of $cellFwL"
    set ret -1 
  } elseif {[lsearch $cellFwL $fw2]=="-1"} {
    set gaSet(fail) "The FW of modem-2 is \'$fw2\'. Should be one of $cellFwL"
    set ret -1 
  }
  Send $com "cellular modem 1 power-down\r" "SecFlow-1v#" 
  Send $com "cellular modem 2 power-down\r" "SecFlow-1v#" 
  
  return $ret
}
