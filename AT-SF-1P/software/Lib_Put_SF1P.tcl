# ***************************************************************************
# PowerResetAndLogin2Uboot
# ***************************************************************************
proc PowerResetAndLogin2Uboot {} {
  puts "[MyTime] PowerResetAndLogin2Uboot"
  Power all off
  after 4000
  Power all on 
  
  set ret [Login2Uboot]
  return $ret 
}
# ***************************************************************************
# PowerResetAndLogin2App
# ***************************************************************************
proc PowerResetAndLogin2App {} {
  global gaSet buffer
  puts "[MyTime] PowerResetAndLogin2App"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match {*SF1v login:*} $buffer]} {
    set ret [Send $com su\r "assword"]
    set ret [Send $com 1234\r "SecFlow-1v#"] 
    if {$ret==0} {return $ret}   
  }
  

  Power all off
  after 4000
  Power all on 
  
  set ret [Login2App]
  return $ret 
}
# ***************************************************************************
# PowerResetAndLogin2Boot
# ***************************************************************************
proc PowerResetAndLogin2Boot {} {
  puts "[MyTime] PowerResetAndLogin2Boot"
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match {*PCPE*} $buffer]} {
    return 0   
  }
  
  
  Power all off
  after 4000
  Power all on   
  
  set ret [Login2Boot]
  return $ret 
}
# ***************************************************************************


# ***************************************************************************
# Login2Uboot
# ***************************************************************************
proc Login2Uboot {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into Uboot"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  
  if {[string match *PCPE* $buffer]} {
    set ret 0
  }
  
  set gaSet(fail) "Login to Uboot level fail" 
  if {$ret!=0} {
    for {set i 1} {$i<=60} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      puts "Login2Uboot i:$i [MyTime] buffer:<$buffer>" ; update
      #puts "Login2Uboot i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      if {[string match {*to stop autoboot:*} $gaSet(loginBuffer)]} {
        set ret [Send $com \r\r "PCPE"]
        if {$ret==0} {break}
      }
      if {[string match {*for safe-mode menu*} $gaSet(loginBuffer)]} {
        set ret [Send $com s "to continue"]
        if {$ret=="-1"} {
          set gaSet(fail) "Enter to safe-mode menu fail"
          break
        } elseif {$ret=="-2"} {
          break
        } elseif {$ret==0} {
          set gaSet(loginBuffer) ""
          set ret [OpenUboot]
          if {$ret!=0} {
            break
          }
        }  
      }
      if {[string match {*PCPE*} $gaSet(loginBuffer)]} {
        set ret 0
        break
      }
      if {[string match {*BootROM: Bad header at offset 00000000*} $gaSet(loginBuffer)]} {
        return -1
      }
      after 1000
    }
  }
  
  return $ret
}
# ***************************************************************************
# OpenUboot
# ***************************************************************************
proc OpenUboot {} {
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] Open Uboot"
  set ret [Send $com "andromeda\r" "with startup"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to basic safe-mode menu fail"
  } elseif {$ret==0} {
    Send $com "advanced\r" "stam" 1
    set ret [DescrPassword "tech" "with startup"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to advanced safe-mode menu fail"
    } elseif {$ret==0} {
      set ret [Send $com "12\r" "with startup"]
      if {$ret=="-1"} {
        set gaSet(fail) "Enable access to U-BOOT fail"
      } elseif {$ret==0} {
        set ret [Send $com "1\r" "Reset device"]
        if {$ret=="-1"} {
          set gaSet(fail) "Reset device fail"
        } 
      }
    }
  }
  return $ret
}
# ***************************************************************************
# Login
# ***************************************************************************
proc Login {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {[string match {*PCPE*} $gaSet(loginBuffer)]} {
    Send $com boot\r "partitions"
  }
  if {[string match {*root@localhost*} $gaSet(loginBuffer)]} {
    Send $com exit\r\r "-1p"
  }
  
  if {$ret!=0} {
    if {[string match *-1p* $buffer]} {
      after 2000
      Send $com "\r" stam 0.25
      append gaSet(loginBuffer) "$buffer"
      if {[string match *-1p* $buffer]} {
        set ret 0
      }
    }
  }
  if {$ret!=0} {
    if {[string match {*CLI session is closed*} $buffer]} {
      set ret -1
      RLCom::Send $com \r
    }
  }
  
  set gaSet(fail) "Login fail" 
  set startSec [clock seconds]
  if {$ret!=0} {
    for {set i 1} {$i<=90} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      #puts "Login i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      puts "Login i:$i [expr {[clock seconds] - $startSec}] [MyTime] buffer:<$buffer>" ; update
      
      if {[string match {*failed to achieve system info*} $gaSet(loginBuffer)] &&\
          [string match {*command execute error:*} $gaSet(loginBuffer)]} {
        return "PowerOffOn"  
      }    

      if {[string match {*user>*} $gaSet(loginBuffer)]} {
        set ret [Send $com su\r "assword"]
        set ret [Send $com 1234\r "-1p#" 3]
        if {$ret=="-1"} {
          if {[string match {*Login failed user*} $buffer]} {
            set ret [Send $com su\r4\r "again" 3]
          }
          set ret [Send $com 4\r "again" 3]
          set ret [Send $com 4\r "-1p#" 3]
        }
#         if {[string match {*LOGIN(uid=0)*} $gaSet(loginBuffer)]} {
#           set ret [Send $com "exit\r\r\r" "login:"] 
#           set ret [Send $com su\r "assword"]
#           set ret [Send $com 1234\r "ETX-1p#"]
#         }
        
        if {$ret==0} {break}
      }
      if {[string match {*-1p*} $buffer]} {
        return 0
      }
      if {[string match {*PCPE*} $buffer]} {
        Send $com boot\r "partitions"
      }
      after 5000
    }
  }
  
  return $ret
}

# ***************************************************************************
# Login2Linux
# ***************************************************************************
proc Login2Linux {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login to Linux"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 1
  if {[string match {*root@localhost*} $gaSet(loginBuffer)]} {
    return 0
  }
  
  set ret [LogonDebug $com]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "debug shell\r\r" localhost]
  if [string match *:/#* $buffer] {
    set gaSet(linuxPrompt) /#
  } elseif [string match */\]* $buffer] {
    set gaSet(linuxPrompt) /\]
  }
  set ret [Send $com "\r\r" $gaSet(linuxPrompt)]
  return $ret
}

# ***************************************************************************
# Login2App
# ***************************************************************************
proc Login2App {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into Application"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  
  if {[string match *-1p* $buffer]} {
    set ret 0
  }
  if {[string match *PCPE>* $buffer]} {
    Send $com "boot\r" stam 0.25
    after 10000
    set ret -1
  }
  if {[string match *root@localhost* $buffer]} {
    Send $com "exit\r\r" stam 2
    Send $com "logout\r\r" stam 2
    set ret -1
  } 
  
  set gaSet(fail) "Login to Application level fail" 
  if {$ret!=0} {
    for {set i 1} {$i<=90} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      #puts "Login2App i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      puts "Login2App i:$i [MyTime] buffer:<$buffer>" ; update
      if {[string match {*user>*} $gaSet(loginBuffer)]} {
        set ret [Send $com su\r "assword"]
        set ret [Send $com 1234\r "-1p#" 3]
        if {$ret=="-1"} {
          set ret [Send $com 4\r "again"]
          set ret [Send $com 4\r "-1p#"]
        }
#         if {[string match {*LOGIN(uid=0)*} $gaSet(loginBuffer)]} {
#           set ret [Send $com "exit\r\r\r" "login:"] 
#           set ret [Send $com su\r "assword"]
#           set ret [Send $com 1234\r "-1p#"]
#         }
        
        if {$ret==0} {break}
      }
#       if {[string match {*PCPE*} $gaSet(loginBuffer)]} {
#         return -1
#       }
      after 5000
    }
  }
  
  return $ret
}

# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {port} {
  global gaSet buffer bu glSFPs
#   Status "Read EthPort Status of $port"
  set ret [Login]
  if {$ret!=0} {
#     set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read EthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  set ret [Send $com "show status\r" more 8]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  set res [regexp {SFP\+?\sIn} $bu - ]
  if {$res==0} {
#     set gaSet(fail) "The status of port $port is not \'SFP In\'"
#     return -1
  }
  #21/04/2020 10:18:09
  set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Operational Status of port $port fail"
    return -1
  }
  set opStat [string trim $value]
  puts "opStat:<$opStat>"
  if {$opStat!="Up"} {
    set gaSet(fail) "The Operational Status of port $port is $opStat"
    return -1
  }
  
  set res [regexp {Administrative Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Administrative Status of port $port fail"
    return -1
  }
  set adStat [string trim $value]
  puts "adStat:<$adStat>"
  if {$adStat!="Up"} {
    set gaSet(fail) "The Administrative Status of port $port is $adStat"
    return -1
  }
  
  if {[package vcompare $gaSet(SWver) "5.0.1.229.5"] == "0"} {
    ## SWver "5.0.1.229.5" doesn't support SFP's details
  } else {  
    set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)Typical} $bu - val]
    if {$res==0} {
      set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)SFP Manufacture Date} $bu - val]
      if {$res==0} {
        set gaSet(fail) "Read Manufacturer Part Number of SFP in port $port fail"
        return -1
      } 
    }
    set val [string trim $val]
    puts "val:<$val>" ; update
    if {[lsearch {"SFP-9G"} $val]=="-1"} {
      set gaSet(fail) "The Manufacturer Part Number of SFP in port $port is \'$val\'"
      return -1  
    }
  }
  
  return 0
}

# ***************************************************************************
# ReadUtpPortStatus
# ***************************************************************************
proc ReadUtpPortStatus {port} {
  global gaSet buffer bu 
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read UtpEthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "\rexit all\r" stam 0.5
  Send $com "exit all\r" stam 0.5  
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  set ret [Send $com "show status\r" ($port)]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Operational Status of port $port fail"
    return -1
  }
  set opStat [string trim $value]
  puts "opStat:<$opStat>"
  if {$opStat!="Up"} {
    set gaSet(fail) "The Operational Status of port $port is $opStat"
    return -1
  }
  
    set res [regexp {Administrative Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Administrative Status of port $port fail"
    return -1
  }
  set adStat [string trim $value]
  puts "adStat:<$adStat>"
  if {$adStat!="Up"} {
    set gaSet(fail) "The Administrative Status of port $port is $adStat"
    return -1
  }
  
  set res [regexp {Connector Type[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Connector Type of port $port fail"
    return -1
  }
  set conType [string trim $value]
  puts "conType:<$conType>"
  if {$conType!="RJ45"} {
    set gaSet(fail) "The Connector Type of port $port is $conType"
    return -1
  }
 
  return 0
}

# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc SpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  set ret [Send $com "speed-duplex 100-full-duplex\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer
  set ret [GetPageFile $gaSet($::pair.barcode1)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# LogonDebug
# ***************************************************************************
proc LogonDebug {com} {
  global gaSet buffer
  Send $com "exit all\r" stam 0.25 
  Send $com "logon debug\r" stam 0.25 
  Status "logon debug"
   if {[string match {*command not recognized*} $buffer]==0} {
#     set ret [Send $com "logon debug\r" password]
#     if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" "-1p#" ]
    if {$ret!=0} {return $ret}
  } else {
    set ret 0
  }
  return $ret  
}
# ***************************************************************************
# DescrPassword
# ***************************************************************************
proc DescrPassword {mode prompt} {
  global buffer gaSet
  set com $gaSet(comDut)
  regexp {Challenge code:\s+(\d+)\s} $buffer - kc
  catch {exec $::RadAppsPath/atedecryptor.exe $kc $mode} password
  set ret [Send $com "$password\r" $prompt 1]
  return $ret
}


# ***************************************************************************
# DryContactAlarmcheck
# ***************************************************************************
proc DryContactAlarmcheck {mode} {
  global buffer gaSet
  puts "\n[MyTime] DryContactAlarmcheck $mode"; update
  set com $gaSet(comDut)
  
  set ret ret ; #[Send $com "\r\r" $gaSet(linuxPrompt) 1]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure system\r" "system"]
    if {$ret!=0} {
      set gaSet(fail) "Configure System fail"
      return -1
    }
    set ret [Send $com "show device-information\r" "Engine Time"]
    if {$ret!=0} {
      set gaSet(fail) "Show device-information fail"
      return -1
    }
    set res  [regexp {Hw:\s+([\w\/\.]+)\s?} $buffer ma uutHw]
    if {$res==0} {
      set gaSet(fail) "Read Hw fail"
      return -1
    } 
    set uutHw [string trim $uutHw]
    puts "uutHw:$uutHw"
    if {[package vcompare $gaSet(SWver) "5.0.1.229.5"] == "0"} {
      set gaSet(mainHW) "1.0/a"
    } else {
      set gaSet(mainHW) $uutHw
    }
    Send $com "exit all\r" "stam" 1
    set ret [Login2Linux]
    if {$ret!=0} {return $ret}    
  }
  
  set ret [DryContactConfig]
  if {$ret!=0} {return $ret}
  
#   RLUsbPio::Set $gaSet(idPioDrContOut) 00000010 
  after 500
  
  foreach gr2st {0 1 0 1} gr1st {0 0 1 1} sb {00 10 01 11} {
    MuxSwitchBox 1 $gr1st
    MuxSwitchBox 2 $gr2st
    after 250
    set ret [Send $com "cat \$DC_IN1_DIR/value \> \$DC_OUT1_DIR/value\r" stam 0.2]
    Send $com "cat \$DC_IN1_DIR/value\r" stam 0.2
    Send $com "cat \$DC_OUT1_DIR/value\r" stam 0.2
		set ret [Send $com "cat \$DC_IN2_DIR/value \> \$DC_OUT2_DIR/value\r" stam 0.2]
    Send $com "cat \$DC_IN2_DIR/value\r" stam 0.2
    Send $com "cat \$DC_OUT2_DIR/value\r" stam 0.2
    after 250
    RLUsbPio::Get $gaSet(idPioDrContIn) buffer
    puts "DryContactAlarmcheck buffer after gr2st:<$gr2st> gr1st:<$gr1st> buffer:<$buffer> sb:<$sb>"
    if [string match *$sb $buffer] {
      #puts "$buffer match *$sb"
      set res 0
    } else {
      set gaSet(fail) "I/O Alarm is [string range $buffer 6 7]. Should be $sb"
      puts "$gaSet(fail)"
      set res -1
      break
    }
  }
  set ret [Send $com "\r\r" $gaSet(linuxPrompt) 1]
  set ret $res
  return $ret
} 

# ***************************************************************************
# UbootCheckVersionRam
# ***************************************************************************
proc UbootCheckVersionRam {} {
  global gaSet buffer
  puts "\n[MyTime] UbootCheckVersionRam"; update
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *PCPE* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  
  set ret [Send $com "reset\r" "resetting"]
  if {$ret!=0} {return $ret}
  
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\sSF1V-([\w\.]+)\s} $gaSet(loginBuffer) ma val]
  if {$res==0} {
    set gaSet(fail) "Read Uboot parametes fail"
    return -1
  }
  puts "gaSet(dbrUbootSWver):<$gaSet(dbrUbootSWver)> val:<$val>"
  if {$gaSet(dbrUbootSWver) != $val} {
    set gaSet(fail) "Uboot version is \'$val\'. Should be \'$gaSet(dbrUbootSWver)\'"
    return -1
  }
  AddToPairLog $gaSet(pair) "Uboot SW ver: $val"
  
  regexp {DRAM[\:\s]+(\d)\sG} $gaSet(loginBuffer) ma val
  puts "gaSet(dutFam.mem):<$gaSet(dutFam.mem)> val:<$val>"
  if {"$gaSet(dutFam.mem)" != $val} {
    set gaSet(fail) "DRAM is \'$val\'. Should be \'$gaSet(dutFam.mem)\'"
    return -1
  }
  
  return $ret
}  
# ***************************************************************************
# BrdEepromPerf
# ***************************************************************************
proc BrdEepromPerf {} {
  global gaSet buffer
  puts "[MyTime] BrdEepromPerf"
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *-1p* $buffer]} {
    set ret 0
  } elseif {[string match *-1p* $buffer]} {
    set ret 0
  } else {
    set ret [Login]
  }
  if {$ret!=0} {return $ret}
  
  set ret [BuildEepromString newUut] 
  if {$ret!=0} {return $ret}  
  
#   for {set i 1} {$i<=10} {incr i} {
#     puts "ping $i"
#     set ret [Send $com "ping 10.10.10.10\r" "10.10.10.10 is alive"]
#     if {$ret==0} {break}
#   }
#   if {$ret!=0} {
#     set gaSet(fail) "10.10.10.10 is not alive" 
#   }

  Status "Read EEPROM"
  puts "\n[MyTime]eeprom before erase"
  set ret [Send $com "cat /sys/class/i2c-adapter/i2c-0/0-0052/eeprom\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret} 
  puts "\n[MyTime]"

  Status "Remove current_platform.json"
  set ret [Send $com "rm -f /opt/info/current_platform.json\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {
    set gaSet(fail) "Remove current_platform.json fail"
    return $ret
  }
  
  Status "Remove USERFS/eeprom"
  set ret [Send $com "sudo rm -r /USERFS/eeprom/*\r" $gaSet(linuxPrompt)] 
  if {$ret!=0} {
    set gaSet(fail) "Remove USERFS_eeprom fail"
    return $ret
  }
  
  
  Status "Programming EEPROM"
  set gaSet(fail) "Programming eEprom fail"

  set id [open c:/download/etx1p/eeprom.[set gaSet(pair)].cnt r]
    gets $id line
    if {$gaSet(act)==0} {close $id ; return -2}
  close $id
  
  set eepromString "echo \""
  append eepromString $line
  append eepromString "\"  > /sys/class/i2c-adapter/i2c-0/0-0052/eeprom"
  set ret [Send $com "$eepromString\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "systemctl restart eeprom-parser\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret} 
  
  Status "Read EEPROM"
  set ret [Send $com "cat /sys/class/i2c-adapter/i2c-0/0-0052/eeprom\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret} 
  
  set res [regexp {MAC_ADDRESS=([0-9A-F\:]+),} $buffer ma sysMac]
  if {$res==0} {
    set gaSet(fail) "Read MAC from sys/eeprom fail"
    return -1
  }
  puts "gaSet(eeprom.mac):$gaSet(eeprom.mac) sysMac:$sysMac"
  if {$gaSet(eeprom.mac) != $sysMac} {
    set gaSet(fail) "$gaSet(eeprom.mac) was programmed, but in sys the UUT has $sysMac"  
    return -1
  }
  
  set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret} 
  
  set res [regexp {MAC_ADDRESS\s+([0-9A-F\:]+)} $buffer ma userMac]
  if {$res==0} {
    set gaSet(fail) "Read MAC from /USERFS/eeprom fail"
    return -1
  }
  puts "gaSet(eeprom.mac):$gaSet(eeprom.mac) userMac:$userMac"
  
  set ret [Send $com "cat /USERFS/eeprom/PART_NUMBER\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret} 

  set res [regexp {_NUMBER\s+([0-9A-Z\/\-]+) } $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read PART_NUMBER fail"
    return -1
  }
  puts "gaSet(DutFullName):$gaSet(DutFullName) val:$val"

  if {$gaSet(eeprom.mac) != $userMac || \
      $gaSet(DutFullName) != $val} {
    puts "\n[MyTime] SYSTEMCTL RESTART EEPROM-PARSER AGAIN! gaSet(eeprom.mac):<$gaSet(eeprom.mac)> userMac:<$userMac> gaSet(DutFullName):$gaSet(DutFullName) val:$val"
    set restartEepromParser 1
    set ret [Send $com "sudo rm -r /USERFS/eeprom/*\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret} 
    set ret [Send $com "systemctl restart eeprom-parser\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret} 
    set ret [Send $com "\r" $gaSet(linuxPrompt)]  
    set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret} 
  
    set res [regexp {MAC_ADDRESS\s+([0-9A-F\:]+)} $buffer ma userMac]
    if {$res==0} {
      set gaSet(fail) "Read MAC from /USERFS/eeprom fail"
      return -1
    }
    if {$gaSet(eeprom.mac) != $userMac} {
      set gaSet(fail) "$gaSet(eeprom.mac) was programmed, but in USEFS the UUT has $userMac"  
      return -1
    } else {
      set gaSet(1.mac1) $userMac
      set ret 0
    }
    
    set ret [Send $com "cat /USERFS/eeprom/PART_NUMBER\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret} 
  
    set res [regexp {_NUMBER\s+([0-9A-Z\/\-]+) } $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read PART_NUMBER fail"
      return -1
    }
    puts "gaSet(DutFullName):$gaSet(DutFullName) val:$val"
    if {$gaSet(DutFullName) != $val} {
      set gaSet(fail) "PART_NUMBER is \'$val\'. Should be $gaSet(DutFullName)"
      return -1
    }
  } else {
    set restartEepromParser 0
    set gaSet(1.mac1) $userMac
    set ret 0
  }
               
  if {$ret==0} {
    if {[ParseSW] eq "Safari"} {
      ## in Safari dont remove the file
    } else {
      if {$restartEepromParser ==1} {
        set ret [Send $com "rm -f /opt/info/current_platform.json\r" $gaSet(linuxPrompt)]  
        if {$ret!=0} {
          set gaSet(fail) "Remove current_platform.json fail"
          return $ret
        }
      }  
    }
    set ret [Send $com "sync\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {
      set gaSet(fail) "Sync after Eeprom Set fail"
      return $ret
    } 
    
    Status "Reboot with new EEPROM"
    
#     25/01/2022 08:50:42
#     set ret [Send $com "reboot\r" "topped"]  
#     if {$ret!=0} {
#       set gaSet(fail) "Reboot after Eeprom Set fail"
#       return $ret
#     }
    
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2  
    set ret [Send $com "exit all\r" "-1p"]
    if {$ret!=0} {
      set gaSet(fail) "\'exit all\' fail"
      return $ret
    }  
    
    set ret [Send $com "admin factory-default\r" "yes/no" 20]
    if {$ret!=0} {
      set gaSet(fail) "\'admin factory-default\' fail"
      return $ret
    } 
    
    set ret [Send $com "y\r" "Device reboot" 45]
    if {$ret!=0} {
      set gaSet(fail) "Device reboot fail"
      return $ret
    } 
    Wait "Wait for rebooting" 30
  }
  
  
  return $ret
}

# ***************************************************************************
# IDPerf
# ***************************************************************************
proc IDPerf {mode} {
  global gaSet buffer
  puts "[MyTime] IDPerf $mode"
  
#   set ret [BuildEepromString fromIDPerf] 
#   if {$ret!=0} {return $ret}
  
  set com $gaSet(comDut)
  set ret [Login]
#   Send $com "\r" stam 0.25
#   Send $com "exit all\r" stam 0.25
#   if {[string match *1p* $buffer]} {
#     set ret 0
#   } else {
#     set ret [Login]
#   }
  if {$ret=="PowerOffOn"} {
    Power all off
    after 4000
    Power all on
    set ret [Login]
  }
  if {$ret!=0} {return $ret}

  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  set ret [Send $com "\r" "/\]\#"] 
  
  set ret [TpmCheck]
  if {$ret!=0} {
    #Send $com "exit\r\r" "#"
    return $ret
  }
  
  set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret}
  if {[string match {*command not found*} $buffer]} {
    set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret}
  }
  set macLink ""  
  #set res [regexp {ADDRESS\s+([0-9A-F\:]+) } $buffer ma macLink]
  set res [regexp {\s+([0-9A-F\:]+) } $buffer ma macLink]
  if {$res} {
    set dutMac [string toupper [join [split $macLink :] ""]]
    set hexDutMac 0x$dutMac
    set gaSet(1.mac1) $dutMac
    puts "GetMac macLink:<$macLink> dutMac:<$dutMac> hexDutMac:<$hexDutMac>"
  } else {
    puts "GetMac No User_eeprom"
    set dutMac "EmptyEEPROM"
    #set gaSet(fail) "Read EEPROM fail"
    #return -1
  } 
  set ret [Send $com "exit\r" "#"]  
  if {$ret!=0} {return $ret} 
  
  # if {$mode=="readMac"} {
    # return 0
  # }
#   set ret [Login]
#   if {$ret!=0} {return $ret}

  if {[string range $dutMac 0 5]!="1806F5"} {
    if {$macLink==""} {
      set gaSet(fail) "MAC Address is empty."
    } else {
      set gaSet(fail) "MAC Address is \'$macLink\'. It's out of RAD range"
    }
    return -1
  }
  
  if {$mode=="readMac"} {
    return 0
  }
  
  set ret [Send $com "configure system\r" "system"]
  if {$ret!=0} {
    set gaSet(fail) "Configure System fail"
    return -1
  }
  set ret [Send $com "show device-information\r" "Engine Time"]
  if {$ret!=0} {
    set gaSet(fail) "Show device-information fail"
    return -1
  }
  
  AddToPairLog $gaSet(pair) "$buffer"
  
  
  set res  [regexp {Sw:\s+([\d\.a-z]+)\s} $buffer ma uutSw]
  if {$res==0} {
    set gaSet(fail) "Read Sw fail"
    return -1
  } 
  set uutSw [string trim $uutSw]
  puts "gaSet(SWver):$gaSet(SWver) uutSw:$uutSw"
  if {$uutSw!=$gaSet(SWver)} {
    set gaSet(fail) "The SW is \'$uutSw\'. Should be \'$gaSet(SWver)\'" 
    return -1
  }
  
  # 09:52 15/05/2024  HW's check will be performed in Download Station
  # set res  [regexp {Hw:\s+([\w\/\.]+)\s?} $buffer ma uutHw]
  # if {$res==0} {
    # set gaSet(fail) "Read Hw fail"
    # return -1
  # } 
  # set uutHw [string trim $uutHw]
  # puts "gaSet(mainHW):$gaSet(mainHW) uutHw:$uutHw"
  # if {[package vcompare $gaSet(SWver) "5.0.1.229.5"] == "0"} {
    # set gaSetMainHw "1.0/a"
  # } else {
    # set gaSetMainHw $gaSet(mainHW)
  # }
  # if {$uutHw!=$gaSetMainHw} {
    # set gaSet(fail) "The HW is \'$uutHw\'. Should be \'$gaSetMainHw\'" 
    # return -1
  # }
  
  set res  [regexp {Name\s+:\s+([a-zA-Z\d\-]+)\s} $buffer ma uutName]
  if {$res==0} {
    set gaSet(fail) "Read Name fail"
    return -1
  } 
  set uutName [string trim $uutName]
  puts "uutName:$uutName"
  if {$gaSet(dutFam.box) == "ETX-1P"} {
    set nam "ETX-1p"
  } else {
    set nam "SF-1p"
  }
  if {$uutName!=$nam} {
    set gaSet(fail) "The Name is \'$uutName\'. Should be \'$nam\'" 
    return -1
  }
  
  
  # 09:05 15/05/2024 Model's check will be performed in Download Station
  # set res  [regexp {Model\s:\s+([a-zA-Z\d\-\/\_\s]+)\s+[FL]} $buffer ma uutModel]
  # if {$res==0} {
    # set gaSet(fail) "Read Model fail"
    # return -1
  # } 
  # set uutModel [string trim $uutModel]
  # puts "uutModel:<$uutModel>"
  
  # if {($gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S") && \
	      # $gaSet(mainHW) < 0.6 &&  $uutModel != "SF-1P superset"} {
	  # set gaSet(fail) "The Model is \'$uutModel\'. Should be \'SF-1P superset\'" 
    # return -1
  # } elseif {$gaSet(dutFam.wanPorts) == "2U" && $uutModel != "SF-1P"} {
	  # set gaSet(fail) "The Model is \'$uutModel\'. Should be \'SF-1P\'" 
    # return -1
  # } elseif {$gaSet(dutFam.wanPorts) == "1SFP1UTP" && $uutModel != "ETX-1P"} {
	  # set gaSet(fail) "The Model is \'$uutModel\'. Should be \'ETX-1P\'" 
    # return -1
  # } elseif {($gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S") && \
	      # $gaSet(mainHW) >= 0.6 && $uutModel != "SF-1P superset CP_2"} {
      # set gaSet(fail) "The Model is \'$uutModel\'. Should be \'SF-1P superset CP_2\'" 
    # return -1
  # }
  
  set res  [regexp {Address\s+:\s+([A-F\d\-]+)\s} $buffer ma uutMac]
  if {$res==0} {
    set gaSet(fail) "Read MAC Address fail"
    return -1
  }
  set uutMac [string trim $uutMac]
  puts "uutMac:$uutMac"
  set u0Mac [join [split $uutMac -] ":"]
  puts "uutMac:$uutMac u0Mac:$u0Mac macLink:$macLink"
  if {$u0Mac!=$macLink} {
    set uMac [join [split $uutMac -] ""]
    set 1Mac [string range $uMac 0 5]
    set 2Mac 0x[string range $uMac 6 end]
    set 2MacDec [format %X [expr $2Mac - 0x1] ]
    set u12MacDec ${1Mac}${2MacDec}
    foreach {a b} [split $u12MacDec ""] {
      append uuMac $a$b:
    }
    set uutMac [string trimright $uuMac :]
    #set uutMac [join [split $uutMac -] :]
    puts "uutMac:$uutMac macLink:$macLink"
    if {$uutMac!=$macLink} {
      set gaSet(fail) "The MAC is \'$uutMac\'. Should be \'$macLink\'" 
      return -1
    }
  }
  
  set ret [Send $com "show summary-inventory\r" ">system"]
  if {$ret!=0} {
    set gaSet(fail) "Show summary-inventory fail"
    return -1
  }
  AddToPairLog $gaSet(pair) "$buffer"
  set res [regexp {\.\d+\s+([\w\-\/]+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read FW Ver fail"
    return -1
  }
  
  # 11:56 22/06/2023
  # if {$gaSet(DutFullName) != $val} {
    # set gaSet(fail) "The FW Ver is \'$val\'. Should be \'$gaSet(DutFullName)\'"
    # return -1 
  # }
  
  if {$gaSet(manualMrktName)=="0"} {
    # set ret [RetriveIdTraceData $gaSet(1.barcode1) MKTItem4Barcode]
    foreach {ret resTxt} [::RLWS::Get_MrktName  $gaSet(1.barcode1)] {}
    if {$ret=="0"} {
      # set market_name [dict get $ret "MKT Item"]
      set market_name $resTxt
    } else {
      # set gaSet(fail) "Fail to get market_name for $gaSet(1.barcode1)"
      set gaSet(fail) $resTxt
      return -1 
    }
  } else {
    set market_name $gaSet(manualMrktName)
  }
  
  puts "IDperf val:<$val>  market_name:<$market_name>"
  if {$market_name != $val} {
    set gaSet(fail) "The FW Ver is \'$val\'. Should be \'$market_name\'"
    return -1 
  }
  
  return 0
  
}  
# ***************************************************************************
# CellularModemCloseGpio
# ***************************************************************************
proc CellularModemCloseGpio {} {
  global gaSet buffer
  puts "[MyTime] CellularModemCloseGpio"
  
  set com $gaSet(comDut)
#   set ret [Login]
#   if {$ret!=0} {return $ret}
#   set ret [Login2Linux]
#   if {$ret!=0} {return $ret}
  set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio500/value\r" $gaSet(linuxPrompt)]
  return $ret
}

# ***************************************************************************
# Ping2Cellular
# ***************************************************************************
proc Ping2Cellular {slot ip} {
  global gaSet buffer
  puts "[MyTime] Ping2Cellular $slot $ip"
  
  set com $gaSet(comDut)
  set ret [Send $com "ping $ip\r" "-1p" 20]
  if {$ret!=0} {
    set gaSet(fail) "Sending pings from SIM-$slot to $ip fail"
    return $ret
  } 
  if {[string match {*Network is unreachable*} $buffer]} {
    after 5000
    set ret [Send $com "ping $ip\r"  "-1p" 20]
    if {$ret!=0} {
      set gaSet(fail) "Sending pings from SIM-$slot to $ip fail"
      return $ret
    }
  }
  set res1 [regexp {(\d) packets received} $buffer ma val1]  
  set res2 [regexp {(\d+)% packet loss} $buffer ma val2]
  if {$res1==0 || $res2==0} {
    set gaSet(fail) "Read pings from SIM-$slot to $ip fail"
    return -1 
  }
  if {$val1!=5} {
    set gaSet(fail) "Ping fail - received $val1 packets. Should be 5" 
    return -1 
  }
  if {$val2!=0} {
    set gaSet(fail) "Ping fail - ${val2}% packet loss" 
    return -1 
  }
  return 0
}
  
  
# ***************************************************************************
# SerialPortsPerf
# ***************************************************************************
proc SerialPortsPerf {} {
  global gaSet buffer
  puts "[MyTime] SerialPortsPerf"
  
  set com $gaSet(comDut)
  if {$gaSet(dutFam.serPort)=="2RSM" || $gaSet(dutFam.serPort)=="2RMI"} {
    set comSer1 $gaSet(comSer485)  
  } else {
    set comSer1 $gaSet(comSer1)
  }
  
  set ret ret ; #[Send $com "\r\r" $gaSet(linuxPrompt) 1]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Login2Linux]
    if {$ret!=0} {return $ret}    
  }
  
  set gaSet(fail) "Configuration Serial fail" 
  set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio484/value\r" "#"]
  if {$ret!=0} {return -1}
  set ret [Send $com "stty -F /dev/ttyMV1 115200\r" "#"]
  if {$ret!=0} {return -1}
  set ret [Send $com "cat /dev/ttyMV1 &\r" "#"]
  if {$ret!=0} {return -1}
  
  
  set txt1 "ABCD_1234 7890"
  Status "Send \'$txt1\' from Serial-2 to Serial-1"
  for {set i 1} {$i<=2} {incr i} {
    # set ret [Send $gaSet(comSer2) "echo \"1\r2\r\" > /dev/ttyMV1\r" "#"]
    # set ret [RLCom::Read $gaSet(comSer1) buffer]
    # puts "buffer:<$buffer>"
  
    set ret [Send $gaSet(comSer2) "echo \"$txt1\" > /dev/ttyMV1\r" "#"]
    if {$ret!=0} {return -1}
  	set ret [ReadCom $comSer1 "$txt1" 3]
    puts "ret after i:$i comSer1:<$ret>" ; update
    if {$ret==0} {break}
  }
  if {$ret!=0} {
    set gaSet(fail) "Read \'$txt1\' on Serial-1 fail" 
    return $ret
  }
  
  
  set txt2 "10987_abcd6543"
  Status "Send \'$txt2\' from Serial-1 to Serial-2"
  for {set i 1} {$i<=2} {incr i} {
    # Send $comSer1 "1\r2\r" "stam" 1
    # set ret [RLCom::Read $gaSet(comSer2) buffer]
    # puts "buffer:<$buffer>"
    
    Send $comSer1 "$txt2\r\r" "stam" 1
    after 1000
    set ret [ReadCom $gaSet(comSer2) "$txt2" 3]
    puts "ret after i:$i comSer2:<$ret>" ; update
    if {$ret==0} {break}
  }
  if {$ret!=0} {
    set gaSet(fail) "Read \'$txt2\' on Serial-2 fail" 
    return $ret
  }
  
  return $ret
  
}
# ***************************************************************************
# SerialCloseBackGrPr
# ***************************************************************************
proc SerialCloseBackGrPr {ser mode} {
  global gaSet buffer
  if {$ser==2 && ($gaSet(dutFam.serPort)=="2RS" ||  $gaSet(dutFam.serPort)=="2RSI")} {
    set ser 2
  } elseif {$ser==2 && $gaSet(dutFam.serPort)=="2RSM"} {
    set ser 485
  }
  Send $gaSet(comSer$ser) "kill \$bgPid\r" \#
  if {$mode=="Exit"} {
    Send $gaSet(comSer$ser) "exit\r\r\r" login
  }
  return 0
}
 
# ***************************************************************************
# RouterCreate
# ***************************************************************************
proc RouterCreate {port} {
  global gaSet buffer
  puts "[MyTime] RouterCreate $port"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match " \# " $buffer]} {
    Send $com "exit\r" "login:"
    set ret [Login2App]
  } elseif {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "router interface create address-prefix 10.10.10.30/24 physical-interface eth$port interface-id 1\r" "SecFlow-1v#"]
  if {$ret!=0} {
    set gaSet(fail) "Router Create on Eth-$port fail" 
    return -1
  }
  
  Status "Check Eth-$port link status"
  set ret [Send $com "port show status\r" SecFlow-1v#]
  if {$ret!=0} {
    set gaSet(fail) "Read port show status fail" 
    return -1
  }
  set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read port show status fail" 
    return -1
  }
  puts "RouterCreate $port ma:<$ma> val:<$val>"
  if {$val!="UP"} {
    after 10000
    set ret [Send $com "port show status\r" SecFlow-1v#]
    if {$ret!=0} {
      set gaSet(fail) "Read port show status fail" 
      return -1
    }
    set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read port show status fail" 
      return -1
    }
    puts "RouterCreate $port ma:<$ma> val:<$val>"
    if {$val!="UP"} {
      after 10000
      set ret [Send $com "port show status\r" SecFlow-1v#]
      if {$ret!=0} {
        set gaSet(fail) "Read port show status fail" 
        return -1
      }
      set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read port show status fail" 
        return -1
      }
      puts "RouterCreate $port ma:<$ma> val:<$val>"
      if {$val!="UP"} {
        set gaSet(fail) "Link of Eth-$port isn't UP" 
        set ret "-1"
      } else {
        set ret "0"
      }  
    } else {
      set ret "0"
    }
  } else {
    set ret "0"
  }
  
  return $ret
}
# ***************************************************************************
# RouterRemove
# ***************************************************************************
proc RouterRemove {} {
  global gaSet buffer
  puts "[MyTime] RouterRemove"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match " \# " $buffer]} {
    Send $com "exit\r" "login:"
    set ret [Login2App]
  } elseif {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "router interface remove interface-id 1\r" "SecFlow-1v#"]
  if {$ret!=0} {
    set gaSet(fail) "Router Remove fail"
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# PoePerf
# ***************************************************************************
proc PoePerf {} {
  global gaSet buffer
  set poe $gaSet(dutFam.poe)
  puts "[MyTime] PoePerf $poe"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SecFlow-1v#* $buffer]} {
    set ret 0
  } else {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2 
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 4000
      Power all on
      set ret [ReadCom $com "login:" 120]
      puts "ret after readComLogin:<$ret>" ; update       
    }
  }
  if {$ret!=0} {return $ret}
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  Status "POE configuration"
  
  foreach port [list 2 3 4 5] {
    Status "Eth-$port. POE show"
    set ret [Send $com "poe disable\r" "SecFlow-1v#"]
    if {$ret!=0} {set gaSet(fail) "Set poe disable fail" ;  return -1}
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      MuxMngIO ${port}ToAirMux
    } else {  
      MuxMngIO ${port}ToPhone
    }
    after 2000
    set ret [Send $com "poe enable\r" "SecFlow-1v#"]
    if {$ret!=0} {set gaSet(fail) "Set poe enable fail" ;  return -1}
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set mP 30
    } else {
      set mP 15
    }
    set ret [Send $com "poe ports update admin-status enable max-power $mP port-id $port\r" "SecFlow-1v#"]
    after 2000
    if {$ret!=0} {set gaSet(fail) "Set poe admin-status of port-$port fail" ;  return -1}
    set ret [Send $com "poe show\r" "SecFlow-1v#"]
    if {$ret!=0} {set gaSet(fail) "Poe show fail" ;  return -1}
    
    set res [regexp {tion:\s+(\w+)\s} $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read POE HW Configuration fail" 
      return -1
    }
    if {$val!="$poe"} {
      set gaSet(fail) "POE HW Configuration is \'$val\'. Should be \$poe\'" 
      return -1
    }
    
    foreach dd [list ma maxPwr admSt pwr  vlt cur typ opSt] {
      set $dd 0
    }
    set re "\\s$port\[\\s\\|\]\+\(\\d\+\)\[\\s\\|\]\+\(\\w\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\w\\-\]\+\)\[\\s\\|\]\+\(\\w\*\)"
    set res [regexp $re $buffer ma maxPwr admSt pwr  vlt cur typ opSt]
    #regexp {\s5[\s\|]+(\d+)[\s\|]+(\w+)[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)[\s\|]+([\w\-]+)[\s\|]+(\w+)} $buffer ma maxPwr admSt pwr  vlt cur typ opSt
    foreach dd [list ma maxPwr admSt pwr vlt cur typ opSt] {
      puts "$dd:<[set $dd]>"
    }
    if {$res==0} {
      set gaSet(fail) "Read POE values of port-$port fail" 
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set val 30
    } else {
      set val 15
    }
    if {$maxPwr!=$val} {
      set gaSet(fail) "The Max. Power of port-$port is $maxPwr. Should be $val"
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set min "3.3" ; set max "4.0"
    } else {
      set min "2.0" ; set max "2.5"
    }
    if {$pwr<=$min || $pwr>$max} {
      set gaSet(fail) "The Power of port-$port is $pwr. Should be between $min and $max"
      return -1
    }
    
    set min "47.0" ; set max "51.0"
    if {$vlt<=$min || $vlt>=$max} {
      set gaSet(fail) "The Voltage of port-$port is $vlt. Should be between $min and $max"
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set min "0.070" ; set max "0.090"
    } else {
      set min "0.040" ; set max "0.055"
    }
    if {$cur<=$min || $cur>=$max} {
      set gaSet(fail) "The Current of port-$port is $cur. Should be between $min and $max"
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set val "Alt-B"
    } else {
      set val "Alt-A"
    }
    if {$typ!=$val} {
      set gaSet(fail) "The Type of port-$port is $typ. Should be $val"
      return -1
    }
    set val "OK"
    if {$opSt!=$val} {
      set gaSet(fail) "The Type of port-$port is $opSt. Should be $val"
      return -1
    }
    
    AddToPairLog $gaSet(pair) "Port-$port. Max. Power: $maxPwr, Admin Status: $admSt, Power: $pwr, Voltage: $vlt, Current: $cur, Type: $typ, Oper Status: $opSt"  
  
    
    set ret [Send $com "poe ports update admin-status disable port-id $port\r" "SecFlow-1v#"]
    after 2000
    if {$ret!=0} {set gaSet(fail) "Disable admin-status of port-$port fail" ;  return -1}
  }
  
  return $ret
}  

# ***************************************************************************
# GpsPerf
# ***************************************************************************
proc GpsPerf {} {
  global gaSet buffer  buf
  puts "[MyTime] GpsPerf"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" "1p"]
  if {$ret!=0} {
    set gaSet(fail) "Config gnss fail" 
    return -1
  }
  set ret [Send $com "configure system clock gnss 1\r" "gnss(1)#"]
  if {$ret!=0} {
    set gaSet(fail) "Clock gnss 1 fail" 
    return -1
  }
  after 5000
  set ret [Send $com "secondary-system glonass galileo beidou\r" "gnss(1)#"]
  if {$ret!=0} {
    set gaSet(fail) "Secondary-system glonass fail" 
    return -1
  }
  set ret [Send $com "no shutdown\r" "gnss(1)#"]
  if {$ret!=0} {
    set gaSet(fail) "Enable gnss fail" 
    return -1
  }
#   set ret [Send $com "show status\r" "more"]
#   if {$ret!=0} {
#     set gaSet(fail) "Gnss show fail" 
#     return -1
#   }
#   set buf $buffer
#   set ret [Send $com "\r" "gnss(1)#"]
#   if {$ret!=0} {
#     set gaSet(fail) "Gnss show fail" 
#     return -1
#   }
#   append buf $buffer
#   set buffer $buf
    
  set maxWait 6
  set sec1 [clock seconds]
  set lat [set vis -1]
  
  for {set i 1} {$i<[expr {60 * $maxWait}]} {incr i 10} {
    set sec2 [clock seconds]
    set aft [expr {$sec2-$sec1}]
    set ret [Wait "Wait for GPS sync ($aft sec)" 10]
    if {$ret!=0} {return -1}
    #Status "Wait for GPS sync ($i)"
    set ret [Send $com "show status\r" "more" 2]
#     if {$ret!=0} {
#       set gaSet(fail) "Gnss show fail" 
#       return -1
#     }  
    set buf $buffer
    set ret [Send $com "\r" "gnss(1)#"]
    if {$ret!=0} {
      set gaSet(fail) "Gnss show fail" 
      return -1
    }
    append buf $buffer
    set buffer $buf
    
    puts "GpsPerf i:$i After $aft sec buffer:<$buffer>"
    set ret 0
    set res [regexp {Operational Status[\s\:]+([\w]+)\s} $buffer - value]
    if {$res==0} {
      set gaSet(fail) "Read Operational Status fail"
      return -1
    }
    set opStat [string trim $value]
    puts "opStat:<$opStat>"
    if {$opStat!="Up"} {
      set gaSet(fail) "The Operational Status is $opStat"
      set ret -1
    }
    
    set res [regexp {Administrative Status[\s\:]+([\w]+)\s} $buffer - value]
    if {$res==0} {
      set gaSet(fail) "Read Administrative Status fail"
      return -1
    }
    set adStat [string trim $value]
    puts "adStat:<$adStat>"
    if {$adStat!="Up"} {
      set gaSet(fail) "The Administrative Status is $adStat"
      set ret -1
    }
    
    if {$opStat=="Up"} {
      set res [regexp {Tracking Status[\s\:]+([\w\s]+)\s+Latitude} $buffer - value]
      if {$res==1} {
        set tracStat [string trim $value]
        puts "tracStat:<$tracStat>"
        if {$tracStat!="GNSS Locked"} {
          set gaSet(fail) "The Tracking Status is $tracStat"
          set ret -1
        }
      } else {
        set ret -1
      }  
    }
      
    if {$ret==0} {
      break
    }
    
    
    after 5000
    set ret -1
    set gaSet(fail) "GPS did not synchronized after $maxWait minutes"
    
  }
#   if {$ret==0} {
#     AddToPairLog $gaSet(pair) "Latitude: $lat, Visible: $vis"  
#   }

  return $ret
}  

# ***************************************************************************
# FrontLedsPerf
# ***************************************************************************
proc FrontLedsPerf {} {
  global gaSet buffer
  puts "[MyTime] FrontLedsPerf"
  
  set com $gaSet(comDut)
  Power all off
  after 4000
  Power all on
  
  set ret [ReadCom $com  "safe-mode menu" 60]
  puts "[MyTime] ret after readComWithStartup:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Reach safe-mode fail"
    return $ret
  }
  
  set ret [Send $com "s\r" "assword"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to basic safe-mode menu fail"
  } elseif {$ret==0} {
    Send $com "andromeda\r" "stam" 1
    Send $com "advanced\r" "stam" 1
    set ret [DescrPassword "tech" "with startup"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to advanced safe-mode menu fail"
    } elseif {$ret==0} {
      set ret [Send $com "11\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Lock U-BOOT fail"
         return -1 
      }
    
      set ret [Send $com "14\r" "Sequence"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set ret [Send $com "1\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set txt "Verify Port 2-5 LINK/ACT are green, POE are green\n\
      S1 and S2 Tx-RX are green\n\
      Port 1 Link/Act is green\n\
      Sim 1 and 2 are green (if exist)\n\
      PWR is green"
      RLSound::Play information
      set ret [DialogBox -title "Front leds Test" -type "OK Cancel" -icon images/info -text $txt] 
      if {$ret=="Cancel"} {
        set gaSet(fail) "Front leds Test fail"
        return -1 
      }
      
      set ret [Send $com "14\r" "Sequence"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set ret [Send $com "2\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set txt "Verify Port 2-5 LINK/ACT, POE are OFF\n\
      S1 and S2 Tx-RX are OFF\n\
      Port 1 Link/Act is OFF\n\
      Sim 1 and 2 are OFF (if exist)\n\
      PWR is green"
      RLSound::Play information
      set ret [DialogBox -title "Front leds Test" -type "OK Cancel" -icon images/info -text $txt] 
      if {$ret=="Cancel"} {
        set gaSet(fail) "Front leds Test fail"
        return -1 
      }
      set ret 0
    }  
  }    
  if {$ret==0} {
    set ret [Send $com "c\r" "Loading software"]
    set ret [Login2App]
    if {$ret!=0} {return $ret}
  
    
  }
  return $ret
}

# ***************************************************************************
# ReadImei
# ***************************************************************************
proc ReadImei {} {
  global gaSet buffer
  puts "[MyTime] ReadImei"
  set com $gaSet(comDut)
   
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  Send $com "exit all\r" "#"
  set cellQty [string index $gaSet(dutFam.cell) 0]
  if {$cellQty==1} {
    if [info exists gaSet(1.imei1)] {return 0}
    Status "Read IMEI"
    set ret [Send $com "configure port cellular lte\r" "(lte)#"]
    if {$ret!=0} {
      set gaSet(fail) "Read IMEI fail"
      return $ret 
    }
    set ret [Send $com "no shutdown\r" "(lte)#"]
    if {$ret!=0} {
      set gaSet(fail) "Read LTE No Shutdown fail"
      return $ret 
    }
    
    for {set i 1} {$i<=15} {incr i} {
      if {$gaSet(act)==0} {set ret -2; break}
      Status "Read LTE status ($i)"
      set b ""
      set ret [Send $com "show status\r" "more"]
      append b $buffer
      set ret [Send $com "\r" "(lte)#" 1]
      append b $buffer
      
      if [string match *more* $buffer] {
        set ret [Send $com "\r" "(lte)#"]
        append b $buffer
      }
      
      if [string match *more* $buffer] {
        set ret [Send $com "\r" "(lte)#"]
        append b $buffer
      }
      
      if {$ret!=0} {
        set gaSet(fail) "LTE Show Status fail"
        return $ret 
      }
      set buffer $b
      set ret -1; set val ""
      set gaSet(fail) "Read IMEI fail"
      set res [regexp {IMEI\s+:\s+(\d+)} $buffer ma val]
      if {$res==1} {
        set ret 0
        break
      } else {
        after 3000
      }
    }
    if {$ret!=0} {
      return $ret
    } 
    if {[string is double $val] && [string length $val]=="15"} {
      set gaSet(1.imei1) $val
    } else {
      set gaSet(fail) "The IMEI \'$val\' is wrong"
      set ret -1
    }
   
  } elseif {$cellQty==2} {
    if {[info exists gaSet(1.imei1)] && [info exists gaSet(1.imei2)]} {return 0}
    foreach mdm {1 2} {
      Status "Read Cellular parameters of modem-$mdm"
#         set ret [Send $com "cellular modem $mdm power-down\r" "SecFlow-1v#"]
#         if {$ret!=0} {
#           set gaSet(fail) "Set modem $mdm power-down fail"
#           return $ret 
#         }
       
      Send $com "exit all\r" "-1p"
      set ret [Send $com "configure port cellular lte-$mdm\r" "lte-$mdm"]
      if {$ret!=0} {
        set gaSet(fail) "Set modem $mdm power-up fail"
        return $ret 
      }
      set ret [Send $com "no shutdown\r" "lte-$mdm"]
      if {$ret!=0} {
        set gaSet(fail) "Read LTE-$mdm No Shutdown fail"
        return $ret 
      }
      for {set i 1} {$i<=10} {incr i} {
        if {$gaSet(act)==0} {set ret -2; break}
        Status "Read LTE-$mdm status ($i)"
        set b ""
        set ret [Send $com "show status\r" "more"]
        append b $buffer
        set ret [Send $com "\r" "(lte-$mdm)" 1]
        append b $buffer
        
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if {$ret!=0} {
          set gaSet(fail) "LTE-$mdm Show Status fail"
          return $ret 
        }
        set buffer $b
        set ret -1; set val ""
        set gaSet(fail) "Read IMEI fail"
        set res [regexp {IMEI\s+:\s+(\d+)} $buffer ma val]
        if {$res==1} {
          set ret 0
          break
        } else {
          after 3000
        }
      }   
      if {$ret!=0} {
        return $ret
      } 
      if {[string is double $val] && [string length $val]=="15"} {
        set gaSet(1.imei$mdm) $val
      } else {
        set gaSet(fail) "The IMEI \'$val\' is wrong"
        set ret -1
      }      
    } 
  }
  Send $com "exit all\r" "-1p"
  puts ""
  parray gaSet *imei*
  puts ""
  return $ret
}
  
# ***************************************************************************
# FactorySettingsPerf
# ***************************************************************************
proc FactorySettingsPerf {} {
  global gaSet buffer
  set poe $gaSet(dutFam.poe)
  puts "[MyTime] FactorySettingsPerf"  
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" "#"]
  set ret [Send $com "admin factory-default\r" "yes/no"]
  if {$ret!=0} {
    set gaSet(fail) "Perform factory-default fail"
    return $ret 
  }
  set ret [Send $com "yes\r" "startup-config successfully" 20]
  if {$ret!=0} {
    set gaSet(fail) "Restarting system fail"
    return $ret 
  }
  
#   set ret [Login]
#   if {$ret!=0} {return $ret}
    
  return $ret
}  
# ***************************************************************************
# WifiPerf
# ***************************************************************************
proc WifiPerf {baud locWifiReport} {
  global gaSet buffer
  MuxMngIO nc
  puts "[MyTime] WifiPerf $baud $locWifiReport"  
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
#   if {[string match *SecFlow-1v#* $buffer]} {
#     set ret 0
#   } else {
#     set ret [PowerResetAndLogin2App]
#   }
#   set ret [PowerResetAndLogin2App]
#   if {$ret!=0} {return $ret}

  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {
    set gaSet(fail) "exit all fail"
    return $ret 
  }
  set gaSet(fail) "Config WiFi fail"
  
  Send $com "config router 1\r" "(1)"
  Send $com "no interface 1\r" "(1)"
  Send $com "exit all\r" "-1p"
  Send $com "config port\r" ">port"
  if {$baud=="2.4"} {
    Send $com "wlan 2.4g\r" "(2.4g)"
  } elseif {$baud=="5"} {
    set ret [Send $com "wlan 2\r" "(2)"]
  }
  Send $com "access-point 1\r" "ap(1)"
  Send $com "shutdown\r" "ap(1)"
  Send $com "exit all\r" "-1p"
  
  set ret [Send $com "config system\r" "system"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "dhcp-server 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "clear binding all\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "pool \"1\"\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "network [set gaSet(WifiNet)].5[PcNum].0/24\r" "(1)"]
  if {$ret!=0} {return $ret}
  set maxAddr 5
  set ret [Send $com "address-range [set gaSet(WifiNet)].5[PcNum].[UutNum]1 [set gaSet(WifiNet)].5[PcNum].[UutNum][set maxAddr]\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "system"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "config"]
  if {$ret!=0} {return $ret}
  
#   set ret [Send $com "port ethernet lan4\r" "(lan4)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "no shutdown\r" "(lan4)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "exit\r" "port"]
#   if {$ret!=0} {return $ret}
  
  set ret [Send $com "port\r" "port"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "wifi-country-code israel\r" "port"]
  if {$ret!=0} {return $ret}
  if {$baud=="2.4"} {
    set ret [Send $com "wlan 2.4g\r" "(2.4g)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "radio-mode 802.11g\r" "(2.4g)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "channel auto\r" "(2.4g)"] ; #4
  } elseif {$baud=="5"} {
    set ret [Send $com "wlan 2\r" "(2)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "radio-mode 802.11na\r" "(2)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "channel 36\r" "(2)"]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "access-point 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ssid RAD_TST1_$gaSet(wifiNet)\r" "(1)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "password \"RAD_TST1\" hash\r" "(1)"]
  set ret [Send $com "password \"RAD_TST1\"\r" "(1)"]
  if {$ret!=0} {return $ret}
  if [string match {*Illegal encrypted password *} $buffer] {
    set ret [Send $com "password \"RAD_TST1\"\r" "(1)"]
    if {$ret!=0} {return $ret}  
  }
  set ret [Send $com "max-clients 8\r" "(1)"]
  if {$ret!=0} {return $ret}
   set ret [Send $com "no shutdown\r" "(1)" 30]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "config\r" "config"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "router 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "interface 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "address [set gaSet(WifiNet)].5[PcNum].[UutNum]/24\r" "(1)"]
  if {$ret!=0} {return $ret}
  if {$baud=="2.4"} {
    set ret [Send $com "bind wlan 2.4g access-point 1\r" "(1)"]
  } elseif {$baud=="5"} {
    set ret [Send $com "bind wlan 2 access-point 1\r" "(1)"]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "dhcp-client\r" "client"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "client-id mac\r" "client"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "(1)"]
  if {$ret!=0} {
    after 5000
    set ret [Send $com "no shutdown\r" "(1)"]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  set ret [WiFiReport $locWifiReport $baud on]
  if {$ret!=0} {return $ret}
  
  for {set try 1} {$try <= 3} {incr try} {
    for {set adrr $maxAddr} {$adrr > 0} {incr adrr -1} {
	    Status "Ping to [set gaSet(WifiNet)].5[PcNum].[UutNum][set adrr]"
	    set ret [Ping2Cellular WiFi [set gaSet(WifiNet)].5[PcNum].[UutNum][set adrr]]   
	    puts "[MyTime] ping res: $ret at try $try" 
	    if {$ret==0} {break}
	  }
    if {$ret==0} {break}
    after 10000
  }
  
  # catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
  # puts "FtpDeleteFile <$res>"
  # if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
    # set gaSet(fail) "Unable to connect to ftp.rad.co.il"
    # return -1
  # }
  # catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
  # puts "FtpDeleteFile <$res>"
  # if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
    # set gaSet(fail) "Unable to connect to ftp.rad.co.il"
    # return -1
  # }
  if {$ret!=0} {
    # catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    # puts "FtpDeleteFile <$res>"
    # if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
    #   set gaSet(fail) "Unable to connect to ftp.rad.co.il"
    #   return -1
    # }
  }
  return $ret
  
  
  ## 08:04 23/11/2023
  if 0 {
  if {$baud=="2.4"} {
  
    ## we stop the measurement and wait upto 2 minutes to verify that wifireport will be deleted
    #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
    #FtpDeleteFile  [string tolower wifireport_$gaSet(wifiNet).txt]
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)  wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
    # catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    # puts "FtpDeleteFile <$res>"
    
    set ret [FtpVerifyNoReport]
    if {$ret!=0} {return $ret}

    #FtpUploadFile startMeasurement_$gaSet(wifiNet)
    catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpUploadFile <$res>"
    regexp {result: (-?1) } $res ma ret
    
    RLSound::Play information
    # 16:13 29/06/2023 set txt "Disconnect Antenna from WiFi MAIN"
    set txt "Disconnect WiFi Antennas"
    set ret [DialogBox -title "WiFi $baud Test" -type "OK Cancel" -icon images/info -text $txt] 
    if {$ret=="Cancel"} {
      set gaSet(fail) "WiFi $baud fail"
      return -1 
    }
    
    for {set i 1} {$i<=3} {incr i} {
      puts "[MyTime] Check for signal down when antenna off ($i)"; update
      
      catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
      puts "FtpUploadFile <$res>"
      
      set ret [Wait "Wait for WiFi signal down" 40]
      if {$ret!=0} {return -1}
       
      ## we start the measurement and wait upto 2 minutes to verify that wifireport will be created
      set ret [FtpVerifyReportExists]
      if {$ret!=0} {return $ret}
    
      set ret [WiFiReport $locWifiReport $baud off]
      set wifiRet $ret
      puts "wifiRet:<$wifiRet>"; update
      if {$ret!=0} {
        catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)  wifireport_$gaSet(wifiNet).txt} res
        puts "FtpDeleteFile <$res>"
        #FtpDeleteFile  [string tolower wifireport_$gaSet(wifiNet).txt]
        # catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
        # puts "FtpDeleteFile <$res>"
      
        set wifiRet $ret
        set ret [FtpVerifyNoReport]
        if {$ret!=0} {return $ret}
      } else {
        break
      } 
#       set ret [Wait "Wait for WiFi signal down" 30]
#       if {$ret!=0} {return -1}
#       set ret [FtpVerifyReportExists]
#       if {$ret!=0} {return $ret}
#     
#       set ret [WiFiReport $locWifiReport $baud off]
#       if {$ret!=0} {return $ret}
    } 
    if {$wifiRet != 0} {
      set ret $wifiRet
    }          
  }
  } 
 
  return $ret
}
# ***************************************************************************
# WiFiReport
# ***************************************************************************
proc WiFiReport {locWifiReport baud ant} {
  global gaSet
  puts "[MyTime]  WiFiReport $locWifiReport $baud $ant"
  catch {file delete -force $locWifiReport} res
  puts "WiFiReport catch res:<$res>"
  AddToPairLog $gaSet(pair) "Antenna: $ant"
  
  Status "Looking for RAD_TST1"
  set ret -1
  set ::signalWithAntenna 0
  for {set i 1} {$i <= 70} {incr i} {
    if {$gaSet(act)==0} {return -2}
    puts "i:<$i>"
    $gaSet(runTime) configure -text "$i" ; update
    #if {[FtpGetFile wifiReport_$gaSet(wifiNet).txt $locWifiReport]=="1"} {}
    catch {exec python.exe lib_sftp.py FtpGetFile [string tolower wifiReport_$gaSet(wifiNet).txt] $locWifiReport} res
    regexp {result: (-?1) } $res ma res
    puts "FtpGetFile res <$res>"
    if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
      set gaSet(fail) "Unable to connect to ftp.rad.co.il"
      return -1
    }
    
    if {$res=="1" } {
      after 500
      if {[file exists $locWifiReport]} { 
        set ret  [WiFiReadReport $locWifiReport $baud $ant $i]
        puts "WiFiReport i:$i ret after WiFiReadReport <$ret> fail:<$gaSet(fail)>" 
        if {$ret=="TryAgain"} {
          ## wait a little and then try again
          after 2000
        } else {
          break
        }
      } else {
        set gaSet(fail) "$locWifiReport does not exist"
        puts "$locWifiReport does not exist"
        after 2000
      }
    } else {
      set gaSet(fail) "FtpGetFile wifiReport_$gaSet(wifiNet).txt fail"
      puts "FtpGetFile wifiReport_$gaSet(wifiNet).txt fail"
      after 2000
    }
  }
  if {$ret=="TryAgain"} {set ret -1}
  puts "WiFiReport ret before return <$ret> gaSet(fail):<$gaSet(fail)>" 
  return $ret
}
# ***************************************************************************
# WiFiReadReport
#  set locWifiReport LocWifiReport.txt
# ***************************************************************************
proc WiFiReadReport {locWifiReport baud ant tr} {
  global gaSet
  puts "\n[MyTime]  WiFiReadReport $locWifiReport $baud $ant $tr"
  set ret 0
  set id [open $locWifiReport r]
    set wlanIntfR [read $id]
  close $id
  puts "WiFiReadReport wlanIntfR:<$wlanIntfR>"
  
  set ::wlanIntfR $wlanIntfR
  #set res [regexp "SSID\\s+\(\\d+\)\\s+:\\s+RAD_TST1_$gaSet(wifiNet)" $wlanIntfR ma val]
  set res [regexp "SSID\\s+:\\s+RAD_TST1_$gaSet(wifiNet)" $wlanIntfR ma]
  
  if {$res==0} {
    if {$ant=="off"} {
      AddToPairLog $gaSet(pair) "No RAD_TST1_$gaSet(wifiNet)"
      return 0
    }
    set gaSet(fail) "Read SSID RAD_TST1_$gaSet(wifiNet) fail"
    return "TryAgain"
  }
#   set res [regexp "SSID ${val}.+54" $wlanIntfR wlanIntf]
#   if {$res==0} {
#     set gaSet(fail) "Read SSID fail"
#     return "TryAgain"
#   }
  puts "WiFiReadReport ma:<$ma>"
  set res [regexp "SSID\\s+:\\s+RAD_TST1_$gaSet(wifiNet).+?%" $wlanIntfR wlanIntf]
  if {$res==0} {
    set gaSet(fail) "Read SSID fail"
    return "TryAgain"
  }
  
  puts "WiFiReadReport wlanIntf:<$wlanIntf>"
  set ::wlanIntf $wlanIntf
  
  set res [regexp {SSID[\s\d\:]+([\w\_\-]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read SSID or data of RAD_TST1_$gaSet(wifiNet) fail"
    return "TryAgain" 
  }
  if {$val!="RAD_TST1_$gaSet(wifiNet)"} {
    set gaSet(fail) "SSID is $val. Should be RAD_TST1_$gaSet(wifiNet)"
    return "-1"
  }
  
  set res [regexp {Radio type[\s\:]+([\w\.]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Radio type fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Baud: $baud, Radio type: $val"  
  if {$baud=="2.4" && $val!="802.11g" && $val!="802.11n"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11g or 802.11n"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$baud=="5" && $val!="802.11a" && $val!="802.11ac"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11a or 802.11ac"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  }
  
  set res [regexp {Signal[\s\:]+(\d+)\%\s?} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Signal fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Signal: $val"  
  puts "WiFiReadReport Antena:<$ant> val:<$val> ::signalWithAntenna:<$::signalWithAntenna>"
  
  set minSignal 30
  if {$ant=="on" && $val<="$minSignal"} {
    set gaSet(fail) "Signal is ${val}%. Should be more then ${minSignal}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$ant=="off" && $val>=$::signalWithAntenna} {
    set gaSet(fail) "Signal is ${val}%. Should be less then ${::signalWithAntenna}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } else {
    if {$ant=="on"} {
      set ::signalWithAntenna $val
    }
    set gaSet(fail) ""
    return 0
  }
  if {$ret eq "0"} {
    set gaSet(fail) ""
  }
  return $ret
}

# ***************************************************************************
# PlcPerf
# ***************************************************************************
proc PlcPerf {} {
  global gaSet buffer
  puts "[MyTime] PlcPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 4000
      Power all on
      set ret [ReadCom $com "login:" 120]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    puts "PLC open relay of DigitalOutput ch:<$ch>"
    set ret [Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"]
  }  
  RLSound::Play information
  set txt "Verify 6 DIGITAL IN and 6 DIGITAL OUT are OFF"
  set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "Digital On/OUT led test fail"
    return -1 
  }
  
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    ## read DI
    puts "PLC read DigitalInput ch:<$ch>"
    set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r $ch -c 1 /dev/ttyS1\r" "#"]
    set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val]
    puts "ma:<$ma> val:<$val>"
    if {$val!=1} {
       set gaSet(fail) "The Digital Input of ch-$ch is $val. Should be 1" 
       set ret -1
       break
    }
  } 
  
  if {$ret==0} {
    for {set ch 1} {$ch <= 6} {incr ch} {
      puts "PLC close relay of DigitalOutput ch:<$ch>"
      set ret [Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"]
    }
  } 
  RLSound::Play information
  set txt "Verify 6 Green DIGITAL IN and 6 Red DIGITAL OUT are ON"
  set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "Digital On/OUT led test fail"
    set ret -1
  }

  after 250 
  if {$ret==0} {
    for {set ch 1} {$ch <= 6} {incr ch} {
      set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r $ch -c 1 /dev/ttyS1\r" "#"]
      set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val]
      puts "ma:<$ma> val:<$val>"
      if {$val!=0} {
        set gaSet(fail) "The Digital Input of ch-$ch is $val. Should be 0" 
        set ret -1
        break
      }
    }
  }  
  
  #     after 250
#     ## stop the polling
#     set ret [Send $com \3]
    
    
  for {set ch 1} {$ch <= 6} {incr ch} {
    puts "PLC open relay of DigitalOutput ch:<$ch>"
    Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"
  } 
 
  set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 3 -r 1 -c 6 /dev/ttyS1\r" "#"]
  for {set ch 1} {$ch <= 6} {incr ch} {  
    set res [regexp "\\\[$ch\\\]\\:\\s+\(\-?\\d+\)\\s" $buffer ma val]
    puts "PLC Read Analog Input $ch val:<$val>"
    AddToPairLog $gaSet(pair) "Analog Input $ch: $val"  
    if {$val<"-32000" || $val>"-28000"} {
      set gaSet(fail) "Analog Input $ch is $val. Should be between -28000 and -32000" 
      set ret -1
      break  
    } else {
      set ret 0
    }
  }

  return $ret
}
# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {} {
  global gaSet buffer
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuratin for DATA fail"
  
  for {set i 1} {$i <= 5} {incr i} {
    set ret [Send $com "\r" $gaSet(linuxPrompt) 2]
    if {$ret==0} {break}
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addbr br0\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br0 wan1\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br0 wan2\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig wan1 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig wan2 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig br0 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  


  set ret [Send $com "brctl addbr br1\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br1 lan0\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br1 lan1\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig lan0 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig lan1 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig br1 up\r" $gaSet(linuxPrompt)]

  set ret [Send $com "brctl addbr br2\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br2 lan3\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "brctl addif br2 lan2\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig lan2 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig lan3 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig br2 up\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}

  return $ret
}  

# ***************************************************************************
# DataTransmissionSetup_RadOS
# ***************************************************************************
proc DataTransmissionSetup_RadOS {} {
  global gaSet buffer
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration for DATA fail"
  
  Send $com "exit all\r" "-1p"
  if {$ret!=0} {return $ret}
  Send $com "config router 1 interface 32\r" "(32)"
  if {$ret!=0} {return $ret}
  Send $com "shutdown\r" "(32)"
  if {$ret!=0} {return $ret}
  Send $com "no bind\r" "(32)"
  if {$ret!=0} {return $ret}
  Send $com "exit all\r" "-1p"
  if {$ret!=0} {return $ret}
  
  Send $com "config\r" "config"
  if {$ret!=0} {return $ret}
  
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S"} {
    Send $com "bridge 1 port 1\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "bind ethernet 1\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "no shutdown\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "exit\r" "(1)"
    if {$ret!=0} {return $ret}
    
    Send $com "port 2\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "bind ethernet 2\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "no shutdown\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "exit\r" "(1)"
    if {$ret!=0} {return $ret}
    
    Send $com "exit\r" "config"
    if {$ret!=0} {return $ret}
    
    Send $com "port ethernet 1 no shutdown\r" "config"
    if {$ret!=0} {return $ret}
    Send $com "port ethernet 2 no shutdown\r" "config"
    if {$ret!=0} {return $ret}
  }
  
  Send $com "bridge 2 port 1\r" "(1)"
  if {$ret!=0} {return $ret}
  Send $com "bind ethernet 3\r" "(1)"
  if {$ret!=0} {return $ret}
  Send $com "no shutdown\r" "(1)"
  if {$ret!=0} {return $ret}
  Send $com "exit\r" "(2)"
  if {$ret!=0} {return $ret}
  
  Send $com "port 2\r" "(2)"
  if {$ret!=0} {return $ret}
  Send $com "bind ethernet 4\r" "(2)"
  if {$ret!=0} {return $ret}
  Send $com "no shutdown\r" "(2)"
  if {$ret!=0} {return $ret}
  Send $com "exit\r" "(2)"
  if {$ret!=0} {return $ret}
  
  Send $com "exit\r" "config"
  if {$ret!=0} {return $ret}
  
  Send $com "port ethernet 3 no shutdown\r" "config"
  if {$ret!=0} {return $ret}
  Send $com "port ethernet 4 no shutdown\r" "config"
  if {$ret!=0} {return $ret}
  
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S"} {
    Send $com "bridge 3 port 1\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "bind ethernet 5\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "no shutdown\r" "(1)"
    if {$ret!=0} {return $ret}
    Send $com "exit\r" "(3)"
    if {$ret!=0} {return $ret}
    
    Send $com "port 2\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "bind ethernet 6\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "no shutdown\r" "(2)"
    if {$ret!=0} {return $ret}
    Send $com "exit\r" "(3)"
    if {$ret!=0} {return $ret}
    
    Send $com "exit\r" "config"
    if {$ret!=0} {return $ret}
    
    Send $com "port ethernet 5 no shutdown\r" "config"
    if {$ret!=0} {return $ret}
    Send $com "port ethernet 6 no shutdown\r" "config"
    if {$ret!=0} {return $ret}
  }
      
  return $ret
}
# ***************************************************************************
# LinuxLedsPerf
# ***************************************************************************
proc LinuxLedsPerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  set ret ret ; # [Send $com "\r\r" $gaSet(linuxPrompt) 1]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Login2Linux]
    if {$ret!=0} {return $ret}    
  }
  
  set ret [Config4CellBar]
  if {$ret!=0} {return $ret}
  
#   set gaSet(fail) "Confugure AUX Led fail"
#   Send $com "cd / \r" stam 0.1
#   set ret [Send $com "cd /sys/class/gpio\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo 441 > export\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo out > gpio441/direction\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo 442 > export\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo out > gpio442/direction\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo 443 > export\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "echo out > gpio443/direction\r" "\]#"]
#   Send $com "echo 0 > gpio441/value\r" "\]#"
#   Send $com "echo 0 > gpio442/value\r" "\]#"  
#   set ret [Send $com "echo 0 > gpio443/value\r" "\]#"] 
#   if {$ret!=0} {return $ret}
#   RLSound::Play information
#   set res [DialogBox -title "AUX and LTE Leds Test" -type "Yes No" \
#       -message "Verify the AUX and the LTE (if exists) Leds are OFF" -icon images/info]
#   if {$res=="No"} {
#     set gaSet(fail) "AUX and LTE Led are not OFF" 
#     return -1
#   }
#   
#   set ret [Send $com "\r\r" "\]#" 1]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#     set ret [Login2Linux]
#     if {$ret!=0} {return $ret}  
#     Send $com "cd / \r" stam 0.1
#     set ret [Send $com "cd /sys/class/gpio\r" "\]#"]
#     if {$ret!=0} {return $ret}  
#   }
#   set ret [Send $com "echo 1 > gpio442/value\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   RLSound::Play information
#   set res [DialogBox -title "AUX Green Led Test" -type "Yes No" \
#       -message "Verify the AUX Green Led is ON" -icon images/info]
#   if {$res=="No"} {
#     set gaSet(fail) "AUX Green Led is not ON" 
#     return -1
#   }
#   Send $com "echo 0 > gpio442/value\r" "\]#"   
#   
#   set ret [Send $com "echo 1 > gpio443/value\r" "\]#"]
#   if {$ret!=0} {return $ret}
#   RLSound::Play information
#   set res [DialogBox -title "AUX Red Led Test" -type "Yes No" \
#       -message "Verify the AUX Red Led is ON" -icon images/info]
#   if {$res=="No"} {
#     set gaSet(fail) "AUX Red Led is not ON" 
#     return -1
#   }
#   Send $com "echo 0 > gpio443/value\r" "\]#"  
#   
#   if {$gaSet(dutFam.cell)!=0} {}  
#     set ret [Send $com "echo 1 > gpio441/value\r" "\]#"]
#     if {$ret!=0} {return $ret}
#     RLSound::Play information
#     set res [DialogBox -title "LTE Green Led Test" -type "Yes No" \
#         -message "Verify the LTE Green Led is ON" -icon images/info]
#     if {$res=="No"} {
#       set gaSet(fail) "LTE Green Led is not ON" 
#       return -1
#     }
#     Send $com "echo 0 > gpio441/value\r" "\]#" 
#     
  #   set ret [Config4CellBar]
  #   if {$ret!=0} {return $ret}
    
    Send $com "cd / \r" stam 0.1
    set txt "Press \'OK\' and verify LTE Bar Leds is changing in the following order:\n\n\
    all OFF -> 1 and 3 -> 2 and 4 -> all ON -> all OFF"
    while 1 {
    
      set ret [Send $com "\r\r" $gaSet(linuxPrompt) 1]
      if {$ret!=0} {
        set ret [Login]
        if {$ret!=0} {return $ret}
        set ret [Login2Linux]
        if {$ret!=0} {return $ret}    
      }
      RLSound::Play information
      set res [DialogBox -title "CellBar Test" -type "OK" -message $txt -icon images/info]
      
      Send $com "./lte_ledtest.sh 0\r" $gaSet(linuxPrompt) 
      after 250
      Send $com "./lte_ledtest.sh 5\r" $gaSet(linuxPrompt) 
      after 250
      Send $com "./lte_ledtest.sh 10\r" $gaSet(linuxPrompt) 
      after 250
      Send $com "./lte_ledtest.sh 15\r" $gaSet(linuxPrompt)
      after 250
      Send $com "./lte_ledtest.sh 0\r" $gaSet(linuxPrompt)
      
      RLSound::Play information
      set res [DialogBox -title "LTE Led Bar Test" -type "Yes No Repeat" \
          -message "Does the LTE Led Bar work well?" -icon images/info]
      if {$res=="No"} {
        set gaSet(fail) "CellBar Test Fail" 
        set ret -1
        break
      } elseif {$res=="Yes"}  {
        set ret 0
        break
      }
    } 
 
  return $ret
}
# ***************************************************************************
# Config4CellBar
# ***************************************************************************
proc Config4CellBar {} {
  global gaSet buffer
  Status "Config Cell Bar"
  set com $gaSet(comDut)
  Send $com "cd / \r" stam 0.1
  Send $com "stty icrnl \r" stam 0.1
  
  Send $com "cat > lte_ledtest.sh\r" stam 0.1
  set id [open lte_ledtest.sh r]
    while {[gets $id line]>=0} {
      if {[string length $line]>0} {
        Send $com "$line\r" stam 0.1
      }
    }
  close $id
  set ret [Send $com "\4\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
  
  

  Send $com "cat > lte_ledbar_test.sh \r" stam 0.1
  set id [open lte_ledbar_test.sh r]
    while {[gets $id line]>=0} {
      if {[string length $line]>0} {
        Send $com "$line\r" stam 0.1
      }
    }
  close $id
  set ret [Send $com "\4\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return $ret}
   
  Send $com "chmod 777 lte_ledtest.sh\r" $gaSet(linuxPrompt)  
  Send $com "chmod 777 lte_ledbar_test.sh\r" $gaSet(linuxPrompt)
  
  #Send $com "./lte_ledbar_test.sh\r" "\]#" 
  return $ret
}
# ***************************************************************************
# Login2Boot
# ***************************************************************************
proc Login2Boot {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into Boot"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  
  if {[string match *#* $buffer]} {
    set ret 0
  }
  
  set gaSet(fail) "Login to Boot level fail" 
  if {$ret!=0} {
    for {set i 1} {$i<=300} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      puts "Login2Boot i:$i [MyTime] buffer:<$buffer>" ; update
      #puts "Login2Uboot i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      if {[string match {*to stop autoboot:*} $gaSet(loginBuffer)]} {
        set ret [Send $com \r\r "PCPE"]
        if {$ret==0} {break}
      }
      
      if {[string match {*PCPE*} $gaSet(loginBuffer)]} {
        set ret 0
        break
      }
      
      after 1000
    }
  }
  
  return $ret
}
# ***************************************************************************
# BootLedsPerf_loop
# ***************************************************************************
proc BootLedsPerf_loop {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  RLSound::Play information
  set txt "Please disconnect all ETH cables\n\
  Remove the SD-card and the SIMs (if exists)"
  if {$gaSet(dutFam.cell)!=0} {
    append txt "\nDisconnect the antenna from \'LTE MAIN\' and mount it on the \'LTE AUX\'"
  }  
  set res [DialogBox -title "Boot Leds Test" -type "Ok Cancel" -message $txt  -icon images/info]
  if {$res=="Cancel"} {
    set gaSet(fail) "\'LTE AUX\' Test fail" 
    return -1
  }
  
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  set ret [Login]  ; # Login2App
  if {$ret!=0} {
    return $ret
  }
  RLSound::Play information
  RLCom::Read $com buffer
  set res [DialogBox -title "FD button Test" -type "Yes No" \
      -message "Press the FD button for 10-15 sec and verify the UUT is reboting (Front side's LEDs are blinking one time).\n\n\
      Reset has been performed??" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "FD button Test fail" 
    return -1
  }
  
  RLCom::Read $com buffer
  puts "BootLedsPerf buffer <$buffer>" ; update
  if {[string match {*actory-default-config*} $buffer]==0} {
    set gaSet(fail) "No \'factory-default-config\' message (FD button)" 
    return -1
  }
   
  set ret [Login2Boot]
  if {$ret!=0} {return $ret}  
  
#   RLSound::Play information
#   set res [DialogBox -title "FD button Test" -type "Yes No" \
#       -message "Press the FD button and verify the UUT is reboting.\n\n\
#       Reset has been performed??" -icon images/info]
#   if {$res=="No"} {
#     set gaSet(fail) "FD button Test fail" 
#     return -1
#   }
#   set ret [Login2Boot]
#   if {$ret!=0} {return $ret}  
  
  set ret [Send $com "\r\r" "PCPE" 1]
  if {$ret!=0} {
    Power all off
    after 4000
    Power all on
    set ret [Login2Boot]
    if {$ret!=0} {return $ret}    
  }
  
  set ret [Send $com "mmc dev 0:1\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc dev 0:1\' fail"
    return -1
  }
  if ![string match {*ot found*} $buffer] {   
    set gaSet(fail) "SD card is not pulled out" 
    return -1
  }
  
  RLSound::Play information
  set res [DialogBox -title "ALM and RUN Led Test" -type "Yes No" \
      -message "Verify the ALM and RUN Leds are OFF" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "ALM and RUN Leds are not OFF" 
    return -1
  }
  
  set ret [Send $com "gpio toogle GPIO112\r" "PCPE"]
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set res [DialogBox -title "RUN and PWR Green Led Test" -type "Yes No" \
      -message "Verify the RUN and PWR Green Leds are ON" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "RUN and/or PWR Green Led are not ON" 
    return -1
  }
  Send $com "gpio toogle GPIO112\r" "PCPE"
  
  set ret [Send $com "gpio toogle GPIO113\r" "PCPE"]
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set res [DialogBox -title "ALM Red Led Test" -type "Yes No" \
      -message "Verify the ALM Red Led is ON" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "ALM Red Led is not ON" 
    return -1
  }
  Send $com "gpio toogle GPIO113\r" "PCPE"
  
#   set ledName   [list WAN1   WAN2   WiFi   SIM1   SIM2   UTP1   UTP2   UTP3   UTP4   Ser1_TX Ser2_TX]
#   set par1      [list 2      2      2      1      1      1      1      1      1      1       1]
#   set onReg1    [list 0x80ef 0x80fe 0x80fe 0x90fe 0x90fe 0x80ef 0x80ef 0x80ef 0x80ef 0x90ef  0x90ef]
#   set onReg2    [list 0x9696 0x9696 0x9676 0x9656 0x9636 0x9636 0x9656 0x9676 0x9696 0x9636  0x9676]
#   set offReg1   [list 0x80ee 0x80ee 0x80ee 0x90ee 0x90ee 0x80ee 0x80ee 0x80ee 0x80ee 0x90ee  0x90ee]
#   set offReg2   [list 0x9696 0x9696 0x9676 0x9656 0x9636 0x9636 0x9656 0x9676 0x9696 0x9636  0x9676]
  
#   set txt "Press OK and verify LEDs turn ON and OFF in the following order:\n\n\
#   WAN1 -> WAN2 -> WiFi (if exists) -> SIM1 (if exists) -> SIM2 (if exists) ->  SFP ->  WAN2 ->  UTP1 ->  UTP2 ->  UTP3 ->  UTP4 ->  Ser1_TX -> Ser1_RX"
  set txt "Press OK and verify LEDs turn ON and OFF in the following order:\n\n\
  \"Green AUX\" -> \"Red AUX\" -> WiFi (if exists) -> SIM1 (if exists) -> SIM2 (if exists) -> SFP-1 (if exists) -> SFP-2 (if exists) -> UTP-3 (if exists) ->  UTP-4 (if exists) ->  UTP-5  -> UTP-6 -> Ser1_TX -> Ser1_RX -> Ser2_TX -> Ser2_RX" 
  set ::LedsInLoopStop 0
  RLSound::Play information
  set res [DialogBox -title "Boot Leds Test" -type "Yes Stop" \
      -message "$txt" -icon images/info]
  if {$res=="Stop"} {
    set gaSet(fail) "Boot Leds Test fail" 
    return -1
  }
  after 300 LedsInLoop
  RLSound::Play information
#   set txt "Verify LEDs turn ON and OFF in the following order:\n\n\
#   WAN1 -> WAN2 -> WiFi (if exists) -> SIM1 (if exists) -> SIM2 (if exists) ->  SFP ->  WAN2 -> UTP1 ->  UTP2 ->  UTP3 ->  UTP4 ->  Ser1_TX -> Ser1_RX\n\n\n\
#   Do the Leds work well?"
  set txt "Verify LEDs turn ON and OFF in the following order:\n\n\
    \"Green AUX\" -> \"Red AUX\" -> WiFi (if exists) -> SIM1 (if exists) -> SIM2 (if exists) -> SFP-1 (if exists) -> SFP-2 (if exists) -> UTP-3 ->  UTP-4  ->  UTP-5  (if exists) -> UTP-6 (if exists) -> Ser1_TX -> Ser1_RX -> Ser2_TX -> Ser2_RX\n\n\n\
  Do the Leds work well?"
  set res [DialogBox -title "Boot Leds Test" -type "Yes No" -message $txt -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "Boot Leds Test fail" 
    return -1
  } elseif {$res=="Yes"} {
    set ret 0
    set ::LedsInLoopStop 1
  }
  
  return $ret
}
# ***************************************************************************
# LedsInLoop
# ***************************************************************************
proc LedsInLoop {} {
  global gaSet
  if $::LedsInLoopStop {return 0}
#   set ledName   [list WAN1   WAN2   WiFi   SIM1   SIM2   SFP    WAN2   UTP1   UTP2   UTP3   UTP4   Ser1_TX Ser1_RX]
#   set par1      [list 2      2      2      1      1      2      2      1      1      1      1      1       1]
#   set onReg1    [list 0x80ef 0x80fe 0x80fe 0x90fe 0x90fe 0x80ef 0x80ef 0x80ef 0x80ef 0x80ef 0x80ef 0x90ef  0x90ef]
#   set onReg2    [list 0x9696 0x9696 0x9676 0x9656 0x9636 0x96b6 0x9676 0x9636 0x9656 0x9676 0x9696 0x9636  0x9676]
#   set offReg1   [list 0x80ee 0x80ee 0x80ee 0x90ee 0x90ee 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x90ee  0x90ee]
#   set offReg2   [list 0x9696 0x9696 0x9676 0x9656 0x9636 0x96b6 0x9676 0x9636 0x9656 0x9676 0x9696 0x9636  0x9676]
  
#   set ledName   [list "Green AUX" "Red AUX" WiFi    SIM1   SIM2   SFP-1   SFP-2 UTP-3  UTP-4  UTP-5  UTP-6  Ser1_TX  Ser1_RX  Ser2_TX  Ser2_RX ]
#   set par1      [list 1           1         1       1      1      2      2      1      1      1      1      1        1        1        1       ]
#   set onReg1    [list 0x80fe      0x80fe    0x80fe  0x90fe 0x90fe 0x80ef 0x80fe 0x80ef 0x80ef 0x80ef 0x80ef 0x90ef   0x90ef   0x90ef   0x90ef  ]
#   set onReg2    [list 0x9656      0x9636    0x9676  0x9656 0x9636 0x96b6 0x96b6 0x9636 0x9656 0x9676 0x9696 0x9636   0x9676   0x9656   0x9696  ]
#   set offReg1   [list 0x80ee      0x80ee    0x80ee  0x90ee 0x90ee 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x90ee   0x90ee   0x90ee   0x90ee  ]
#   set offReg2   [list 0x9656      0x9636    0x9676  0x9656 0x9636 0x96b6 0x96b6 0x9636 0x9656 0x9676 0x9696 0x9636   0x9676   0x9656   0x9696  ]

  set ledName   [list SFP-1   SFP-2 UTP-3  UTP-4  UTP-5  UTP-6  Ser1_TX  Ser1_RX  Ser2_TX  Ser2_RX   SIM1   SIM2   WiFi   "Green AUX" "Red AUX"]
  set par1      [list 2      2      1      1      1      1      1        1        1        1         1      1      1      1           1        ]
  set onReg1    [list 0x80ef 0x80fe 0x80ef 0x80ef 0x80ef 0x80ef 0x90ef   0x90ef   0x90ef   0x90ef    0x90fe 0x90fe 0x80fe 0x80fe      0x80fe   ]
  set onReg2    [list 0x96b6 0x96b6 0x9636 0x9656 0x9676 0x9696 0x9636   0x9676   0x9656   0x9696    0x9656 0x9636 0x9676 0x9656      0x9636   ]
  set offReg1   [list 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x80ee 0x90ee   0x90ee   0x90ee   0x90ee    0x90ee 0x90ee 0x80ee 0x80ee      0x80ee   ]
  set offReg2   [list 0x96b6 0x96b6 0x9636 0x9656 0x9676 0x9696 0x9636   0x9676   0x9656   0x9696    0x9656 0x9636 0x9676 0x9656      0x9636   ]
  
  set com $gaSet(comDut)
  foreach name $ledName p1 $par1 on1 $onReg1 on2 $onReg2 off1 $offReg1 off2 $offReg2 {
    if {$gaSet(dutFam.wanPorts) eq "2U" && \
        ($name eq "SFP-1" || $name eq "SFP-2" || $name eq "UTP-5" || $name eq "UTP-6" ||\
         $name eq "Ser2_TX" || $name eq "Ser2_RX")} {continue}
    if $::LedsInLoopStop {return 0}
    if {$name=="WiFi" && $gaSet(dutFam.wifi)=="0"} {continue}
    catch {Send $com "mii write $p1 1 $off1\r" "PCPE"}
    catch {Send $com "mii write $p1 0 $off2\r" "PCPE"}
    after 10
  }
  foreach name $ledName p1 $par1 on1 $onReg1 on2 $onReg2 off1 $offReg1 off2 $offReg2 {
    if $::LedsInLoopStop {return 0}
    if {$name=="WiFi" && $gaSet(dutFam.wifi)=="0"} {continue}
    catch {Send $com "mii write $p1 1 $on1\r" "PCPE"}
    catch {Send $com "mii write $p1 0 $on2\r" "PCPE"}
    after 500
    catch {Send $com "mii write $p1 1 $off1\r" "PCPE"}
    catch {Send $com "mii write $p1 0 $off2\r" "PCPE"}
    after 100
  }
  after 500 LedsInLoop 
}
# ***************************************************************************
# FDbuttonPerf
# ***************************************************************************
proc FDbuttonPerf {mode} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]  ; # Login2App
  if {$ret!=0} {
    return $ret
  }
  
  if {$mode!="on_start"} {
    RLSound::Play information
    set txt "Please disconnect all ETH cables\n\
    Remove the SD-card and the SIMs (if exists)"
    if {$gaSet(dutFam.cell)!=0} {
      append txt "\nDisconnect the antenna from \'LTE MAIN\' and mount it on the \'LTE AUX\'"
    }  
    set res [DialogBox -title "Boot Leds Test" -type "Ok Cancel" -message $txt  -icon images/info]
    if {$res=="Cancel"} {
      set gaSet(fail) "\'LTE AUX\' Test fail" 
      return -1
    }
  }
  
  Send $com "logout\r\r" "stam" 3 
  RLSound::Play information
  RLCom::Read $com buffer
  Send $com "\r" "stam" 1 
  set ::bb $buffer
  puts "Buffer before FD: <$::bb>"; update 
  set res [DialogBox -title "FD button Test" -type "Yes No" \
      -message "Press the FD button for 10-15 sec and verify the UUT is reboting (Front side's LEDs are blinking one time).\n\n\
      Reset has been performed??" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "FD button Test fail" 
    return -1
  }
  
  Send $com "\r" "stam" 1 
  set ::ba $buffer
  puts "Buffer after FD: <$::ba>"; update 
  
  RLCom::Read $com buffer
  puts "BootLedsPerf buffer <$buffer>" ; update
  if {[string match {*actory-default-config*} $buffer]==0} {
    set gaSet(fail) "No \'factory-default-config\' message (FD button)" 
    #return -1
  }
  if {$::bb == $::ba} {
    set gaSet(fail) "Reset was not performed (FD button)" 
    return -1
  }
  return 0
}

# ***************************************************************************
# UsbStartTreePerform
# ***************************************************************************
proc UsbStartTreePerform {} {
  global gaSet buffer
  puts "\n[MyTime] UsbStartTreePerform"; update
  set com $gaSet(comDut)
  
  if {$gaSet(dutFam.cell) != 0 && $gaSet(dutFam.wifi) == 0} {
    ## LTE only
    if [string match *L450* $gaSet(dutFam.cell)] {
      ## L450A or L450B
      set bus0devs 1
      set 2vendorSpec NA
    } else {
      set bus0devs 2
      set 2vendorSpec 12
    }
  } elseif {($gaSet(dutFam.cell) != 0 && $gaSet(dutFam.wifi) != 0)} {
    ## LTE and WiFi
    set bus0devs 2
    set 2vendorSpec 480
  } elseif {$gaSet(dutFam.cell) == 0 && $gaSet(dutFam.wifi) == 0} {
    ## no LTE, no WiFi
    set bus0devs 1
    set 2vendorSpec NA
  } elseif {$gaSet(dutFam.cell) == 0 && $gaSet(dutFam.wifi) != 0} {
    ## WiFi only
    set bus0devs 1
    set 2vendorSpec NA
  }
  
  set ret [Send $com "usb start\r" "stam" 3]
  if [string match "*PCPE*" $buffer] {
    set ret 0
  }
  set ret [Send $com "usb stop\r" "stam" 1]
  after 3000
  
  for {set ii 1} {$ii <=3} {incr ii} {
    set ret [Send $com "usb start\r" "stam" 3]
    if [string match "*PCPE*" $buffer] {
      set ret 0
    }
    if {$ret!=0} {
      set gaSet(fail) "\'usb start\' fail"
      return $ret
    }
  
    set res [regexp {scanning bus 0 for devices[\.\s]+(\d) USB Device\(s\) found} $buffer ma val]
    if {$res == 0} {
      set ret [Send $com "usb stop\r" "stam" 1]
      after 3000
      set ret [Send $com "usb start\r" "stam" 3]
      if [string match "*PCPE*" $buffer] {
        set ret 0
      }
      if {$ret!=0} {
        set gaSet(fail) "\'usb start\' fail"
        return $ret
      }
      set res [regexp {scanning bus 0 for devices[\.\s]+(\d) USB Device\(s\) found} $buffer ma val]
      if {$res == 0} {
        set gaSet(fail) "Retrive from \'scanning bus 0 for devices\' fail"
        return -1
      }
    }
    puts "UsbStartTreePerform ii:{$ii} val:{$val} bus0devs:{$bus0devs}"
    if {$val != $bus0devs} {
      set ret -1
      after 2000
      # set gaSet(fail) "Found $val devices on bus 0. Should be $bus0devs"
      # return -1
    } else {
      set ret 0
      break
    }
    
  }
  if {$ret != 0} {
    set gaSet(fail) "Found $val devices on bus 0. Should be $bus0devs"
    return -1
  }
  
  
  set ret [Send $com "usb tree\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'usb tree\' fail"
    return -1
  }
  if {$2vendorSpec == "NA"} {
    if [string match {*2 Vendor specific*} $buffer] {
      set gaSet(fail) "\'2 Vendor specific\' is existing"
      return -1
    } else {
      set ret 0
    }
  } else {
#     03/08/2021 12:32:59 set res [regexp {2 Vendor specific \((\d+) Mb/s\, 500mA\) Android Android} $buffer ma val]
    set res [string match {*2 Vendor specific*} $buffer]
    if {$res == 0} {
      set gaSet(fail) "No \'2 Vendor specific\'"
      return -1
    } else {
      set ret 0
    }
#     03/08/2021 12:32:19
#     puts "UsbStartTreePerform val:{$val} 2vendorSpec:{$2vendorSpec}"
#     if {$val != $2vendorSpec} {
#       set gaSet(fail) "2 Vendor specific is $val Mb/s. Should be $2vendorSpec"
#       return -1
#     }
  }
  
  if {$gaSet(dutFam.wifi) != 0} {
    set ret [Send $com "pci\r" "PCPE"]
    if {$ret!=0} {
      set gaSet(fail) "\'pci\' fail"
      return -1
    }
    if ![string match {*Network controller*} $buffer] {
      set gaSet(fail) "\'Network controller\' does not exist"
      return -1
    }
  } 
  
  return $ret
}
# ***************************************************************************
# SocFlashMemPerform
# ***************************************************************************
proc SocFlashMemPerform {} {
  global gaSet buffer
  puts "\n[MyTime] SocFlashMemPerform"; update
  set com $gaSet(comDut)
  
  set ret [Send $com "mmc dev 1:0\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc dev 1:0\' fail"
    return -1
  }
  if ![string match {*switch to partitions \#0, OK*} $buffer] {
    set gaSet(fail) "\'switch to partitions 0\' does not exist"
    return -1
  }
  if ![string match {*mmc1(part 0) is current device*} $buffer] {
    set gaSet(fail) "\'mmc1(part 0) is current device\' does not exist"
    return -1
  }
  
  Send $com "mmc info\r" "PCPE" 1
  after 500
  set ret [Send $com "mmc info\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc info\' fail"
    return -1
  }
  if ![string match {*HC WP Group Size: 8 MiB*} $buffer] {
    set gaSet(fail) "\'HC WP Group Size: 8 MiB\' does not exist"
    return -1
  }
  if ![string match {*Bus Width: 8-bit*} $buffer] {
    set gaSet(fail) "\'Bus Width: 8-bit\' does not exist"
    return -1
  }
  
  set ret [Send $com "mmc list\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc list\' fail"
    return -1
  }
  if ![string match {*sdhci\@d0000: 0*} $buffer] {
    set gaSet(fail) "\'sdhci@d0000: 0\' does not exist"
    return -1
  }
  if ![string match {*sdhci@d8000: 1 (eMMC)*} $buffer] {
    set gaSet(fail) "\'sdhci@d8000: 1 (eMMD)\' does not exist"
    return -1
  }
  
  return $ret
}  

# ***************************************************************************
# SocI2cPerform
# ***************************************************************************
proc SocI2cPerform {} {
  global gaSet buffer
  puts "\n[MyTime] SocI2cPerform"; update
  set com $gaSet(comDut)
  
  set ret [Send $com "i2c bus\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'i2c bus\' fail"
    return -1
  }
  if ![string match {*Bus 0: i2c@11000*} $buffer] {
    set gaSet(fail) "\'Bus 0: i2c@11000\' does not exist"
    return -1
  }
  
  set ret [Send $com "i2c dev 0\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'i2c dev 0\' fail"
    return -1
  }
  
  set ret [Send $com "i2c probe\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'i2c probe\' fail"
    return -1
  }
  if ![string match {*20 21*} $buffer] {
    set gaSet(fail) "\'20 21\' does not exist"
    return -1
  }
  if ![string match {*7E 7F*} $buffer] {
    set gaSet(fail) "\'7E 7F\' does not exist"
    return -1
  }
  
  set ret [Send $com "i2c mw 0x52 0.2 0xaa 0x1\r" "PCPE"]
  set ret [Send $com "i2c md 0x52 0.2 0x20\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'i2c md\' fail"
    return -1
  }
  if ![string match {*0000: aa*} $buffer] {
    set gaSet(fail) "\'0000: aa\' does not exist"
    return -1
  }
  
  set ret [Send $com "i2c mw 0x52 0.2 0xbb 0x1\r" "PCPE"]
  set ret [Send $com "i2c md 0x52 0.2 0x20\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'i2c md\' fail"
    return -1
  }
  if ![string match {*0000: bb*} $buffer] {
    set gaSet(fail) "\'0000: bb\' does not exist"
    return -1
  }
  
#   set ret [Send $com "i2c md 0x50 0.1 0x40\r" "PCPE"]
#   if {$ret!=0} {
#     set gaSet(fail) "\'i2c md\' fail"
#     return -1
#   }
#   if ![string match {*SFP-9G*} $buffer] {
#     set gaSet(fail) "\'SFP-9G\' does not exist"
#     return -1
#   }
  
  return $ret
} 
  
# ***************************************************************************
# ReadBootParams
# ***************************************************************************
proc ReadBootParams {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Power all off
  after 4000
  Power all on
  
  set ret [Login2Boot]
  if {$ret!=0} {return $ret}
  
  set dbrBootSwVer $gaSet(dbrBootSwVer)
  if {[string index $dbrBootSwVer 0]=="B"} {
    set dbrBootSwVer [string range $dbrBootSwVer 1 end]
  }
  puts "gaSet(dbrBootSwVer):<$gaSet(dbrBootSwVer)> dbrBootSwVer:<$dbrBootSwVer>"
  # set res [string match {*U-Boot 2017.03.VER1.0.2-armada-17.10.2*} $gaSet(loginBuffer)]
  set res [string match *VER$dbrBootSwVer* $gaSet(loginBuffer)]
  if {$res == 0} {
    Power all off
    after 4000
    Power all on
  
    set ret [Login2Boot]
    if {$ret!=0} {return $ret}
  
    # set res [string match {*U-Boot 2017.03.VER1.0.2-armada-17.10.2*} $gaSet(loginBuffer)]
    set res [string match *VER$dbrBootSwVer* $gaSet(loginBuffer)]
    if {$res == 0} {
      # set gaSet(fail) "No \'U-Boot 2017.03-armada-17.10.2\' in Boot"
      set gaSet(fail) "No \'$gaSet(dbrBootSwVer)\' in Boot"
      return -1
    }
  }
  
  # set res [string match {*Nov 22 2021*} $gaSet(loginBuffer)]
  # if {$res == 0} {
    # set gaSet(fail) "No \'Nov 22 2021\' in Boot"
    # return -1
  # }
  
  set res [string match "*DRAM:  $gaSet(dutFam.mem) GiB*" $gaSet(loginBuffer)]
  if {$res == 0} {
    set gaSet(fail) "No \'DRAM:  $gaSet(dutFam.mem) GiB\' in Boot"
    return -1
  }
  
  set ret [Send $com "printenv NFS_VARIANT\r" PCPE]
  if {$ret!=0} {return $ret}
  set res [string match {*NFS_VARIANT=general*} $buffer]
  if {$res == 0} {
    set gaSet(fail) "No \'NFS_VARIANT=general\' in Boot"
    return -1
  }
  
  if {[string match *.HL.* $gaSet(DutInitName)]} {
    set ret [Send $com "printenv fdt_name\r" PCPE]
    if {$ret!=0} {return $ret}
    set res [string match {*armada-3720-SF1p_superSet_hl.dtb*} $buffer]
    if {$res == 0} {
      set gaSet(fail) "No \'fdt_name=armada-3720-SF1p_superSet_hl.dtb\' in Boot"
      return -1
    }
  }
  
  
  return 0
}  
# ***************************************************************************
# ReadWanLanStatus
# ***************************************************************************
proc ReadWanLanStatus {} {
  global gaSet buffer
  MuxMngIO 6ToGen
  switch -exact -- $gaSet(dutFam.wanPorts) {
    "2U" {
      set sfpPorts {}
      set utpPorts {3 4}
    }
    "4U2S" {
      set sfpPorts {1 2}
      set utpPorts {3 4 5 6}
    } 
    "5U1S" {
      set sfpPorts {1}
      set utpPorts {2 3 4 5 6}
    }  
    "1SFP1UTP" {
      set sfpPorts {wan1}
      set utpPorts {wan2 lan1 lan2 lan3 lan4}
    }    
  }
  foreach port $sfpPorts {
    set ret [ShutDown $port "no shutdown"]
    if {$ret != 0} {return $ret}
  }
  foreach port $utpPorts {
    set ret [ShutDown $port "no shutdown"]
    if {$ret != 0} {return $ret}
  }
  
  Status "Stop Generators"
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus down
  RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus down
  after 2000
  Status "Start Generators"
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus up
  RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus up
  
  
  foreach port $sfpPorts {
    set ret [ReadEthPortStatus $port]
    if {$ret != 0} {return $ret}
  } 
  foreach port $utpPorts {
    set ret [ReadUtpPortStatus $port]
    if {$ret != 0} {return $ret}
  }
  return 0
}
# ***************************************************************************
# MicroSDPerform
# ***************************************************************************
proc MicroSDPerform {} {
  global gaSet buffer
  puts "\n[MyTime] MicroSDPerform"; update
  set com $gaSet(comDut)
  
  Send $com "mmc dev 0:1\r" "PCPE" 1
  after 500
  set ret [Send $com "mmc dev 0:1\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc dev 0:1\' fail"
    return -1
  }
  if ![string match {*switch to partitions \#0, OK*} $buffer] { 
    after 500
    set ret [Send $com "mmc dev 0:1\r" "PCPE"]
    if ![string match {*switch to partitions \#0, OK*} $buffer] { 
      set gaSet(fail) "\'dev 0:1 switch to partitions 0\' does not exist"
      return -1
    }
  }
  if ![string match {*mmc0 is current device*} $buffer] {
    after 500
    set ret [Send $com "mmc dev 0:1\r" "PCPE"]
    if ![string match {*mmc0 is current device*} $buffer] {
      set gaSet(fail) "\'mmc0 is current device\' does not exist"
      return -1
    }
  }
  
  Send $com "mmc info\r" "PCPE" 1
  after 500
  set ret [Send $com "mmc info\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc info\' fail"
    return -1
  }
  # 14:15 15/05/2023
  # if ![string match {*Bus Width: 4-bit*} $buffer] {
    # set gaSet(fail) "\'Bus Width: 4-bit\' does not exist"
    # return -1
  # }
  if ![string match {*Capacity: 29.7 GiB*} $buffer] {
    set gaSet(fail) "\'Capacity: 29.7 GiB\' does not exist"
    return -1
  }
  
  return $ret
}  
# ***************************************************************************
# DryContactConfig
# ***************************************************************************
proc DryContactConfig {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "cd / \r" stam 0.1
  #Send $com "stty icrnl \r" stam 0.1
  
  #Send $com "cat > dry2in2out.sh\r" stam 0.25
  
  # if {[package vcompare $gaSet(SWver) "5.4.0.0"]=="-1"} {
    # ## if gaSet(SWver) < "5.4.0.0", then vcompare = -1
    # set scr dry2in2out.2021.sh
  # } elseif {[package vcompare $gaSet(SWver) "5.4.0.0"]=="1"} {
    # ## if gaSet(SWver) > "5.4.0.0", then vcompare = 1
    # set scr dry2in2out.sh
  # }  
 
  if {$gaSet(mainHW)<0.6} {
    set scr dry2in2out.2021.sh
  } else {
    set scr dry2in2out.sh
  }
  #set scr dry2in2out.sh
  puts "\n[MyTime]DryContactConfig $scr"
  set ret 0
  set id [open $scr r]
    while {[gets $id line]>=0} {
      if {[string length $line]>0} {
        Send $com "$line\r" stam 0.1
        if {[string match {*write error*} $buffer]} {
          set gaSet(fail) "\'write error\' during Config DryContact"
          set ret -1
          break
        }
      }
    }
  close $id
  if {$ret!=0} {
    return $ret
  }
  # 11:53 01/08/2023 Send $com "$line\r" stam 0.25
  Send $com "\r" stam 0.25
  # 11:53 01/08/2023 set ret 0; # [Send $com "\4\r" "\]#"]
  return $ret
  
  
}
# ***************************************************************************
# SshPerform
# ***************************************************************************
proc SshPerform {} {
  global gaSet buffer     
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(sshPcIp)  "169.254.1.10"
  set gaSet(sshUutIp) "169.254.1.1"
  catch {exec arp -d $gaSet(sshUutIp)} res
  puts "SshPerform res of arp -d: <$res>"; update
  RLSound::Play information
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S"} {
    set sshPort 6
  } elseif {$gaSet(dutFam.wanPorts) == "2U"} {
    set sshPort 4
  } elseif {$gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
    set sshPort 4
  }
 
  
  set txt "Please connect the SSH cable to port $sshPort"
  if $gaSet(showBoot) {
    append txt "\nRemove the J21 jumper to 2-3 position"  
  }  
  set res [DialogBox -title "SSH Test" -type "Ok Cancel" -message $txt  -icon images/info]
  if {$res=="Cancel"} {
    return -2
  } 

  
#   package require RLPlink
#    # plink.exe -ssh -P 22 su@169.254.1.1
#   set id [RLPlink::Open $gaSet(sshUutIp) -protocol ssh -password 1234 -user su@$gaSet(sshUutIp) -port 22]
  set ret -1
  set gaSet(fail) "No SSH session"
  for {set i 1} {$i <= 10} {incr i} {
    if {$gaSet(act)==0} {return -2}
    Status "SSH login ($i)"
    catch {exec plink -ssh -P 22 su@169.254.1.1 -pw 1234} res
    puts "i:$i psw1234 res<$res>" ; update
    if {[string match {*SF-1p#*} $res] || [string match {*ETX-1p#*} $res]} {
      set ret 0
      break
    }
    after 2000
    catch {exec plink -ssh -P 22 su@169.254.1.1 -pw 4} res
    puts "i:$i psw4 res<$res>" ; update
    if {[string match {*SF-1p#*} $res] || [string match {*ETX-1p#*} $res]} {
      set ret 0
      break
    }
    after 2000
  }
  
  if {$ret==0} {
    ## 08:04 25/05/2022 Control works always, no need check it disabled
    # Send $com \r\r stam 1
    # if {[string length $buffer]>0} {
      # set gaSet(fail) "Serial Port is still active. Check J21" 
      # set ret -1
    # }
  }
  
  return $ret
}    
# ***************************************************************************
# ReadRssi
# ***************************************************************************
proc ReadRssi {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return -1}
  Send $com "exit all\r" "1p#"
  Status "Read RSSI"
  set gaSet(fail) "Read RSSI fail"
  set ret [Send $com "configure port cellular lte\r" "(lte)#"]
  if {$ret!=0} {return -1}
  set ret [Send $com "show status\r" "(lte)#"]
  append buf $buffer
  if {$ret!=0} {
    if {[string match *more* $buffer]} {
      set ret [Send $com "\r" "(lte)#"]
      append buf $buffer
      set buffer $buf
      if {$ret!=0} {return $ret}
    } else {
      return $ret
    } 
  }
  set res [regexp {RSSI \(dBm\)\s+:\s+([\-\d]+)} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read RSSI fail"
    return -1
  }
  puts "Read RSSI ma:<$ma> val:<val>"; update
  AddToPairLog $gaSet(pair) "RSSI: $val dBm"
  if {$val>"-51" || $val < "-75"} {
    set gaSet(fail) "RSSI is \'$val\'. Should be between -75 and -51"
    return -1
  }
  return 0
}
# ***************************************************************************
# CellularLte_RadOS
# ***************************************************************************
proc CellularLte_RadOS {} {
  global gaSet buffer
  puts "[MyTime] CellularLte_RadOS"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration Cellular Lte fail"
  
  Status "Configuration Cellular"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "cellular lte\r" "(lte)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(lte)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "no shutdown\r" "(lte)"]
  #if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "cellular lte-2\r" "(lte-2)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(lte-2)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "no shutdown\r" "(lte-2)"]
  #if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "cellular-group 1\r" "(1)"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "bind cellular lte lte-2\r" "(1)"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "time-to-revert 2\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "connect-timeout 30\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "router 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "interface 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bind cellular lte\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "dhcp\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "dhcp-client\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "client-id mac\r" "(1)"]
  if {$ret!=0} {return $ret}
#   set ret [Send $com "no shutdown\r" "-1p"]
#   if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  set ret [Send $com "no shutdown\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" "-1p"]
  return $ret
}
# ***************************************************************************
# CellularModemPerf_RadOS
# ***************************************************************************
proc CellularModemPerf_RadOS {actSim disSim l4} {
  global gaSet buffer
  puts "\n[MyTime] CellularModemPerf_RadOS $actSim $disSim $l4"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "cellular $disSim\r" "($disSim)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "($disSim)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "cellular $actSim\r" "($actSim)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "($actSim)"]
  if {$ret!=0} {return $ret}
  
  for {set i 1} {$i<=24} {incr i} {
    if {$gaSet(act)==0} {set ret -2; break}
    Status "Read [string toupper $actSim] status ($i)"
    set ret [Send $com "show status\r" "($actSim)#" 8]
    set buf $buffer
    if {$ret!=0} {
      if [string match *more* $buffer] {
        set ret [Send $com "\r" "($actSim)#" 3]
        append buf $buffer
        if {$ret!=0} {
          set gaSet(fail) "LTE Show Status of SIM-${actSim} fail"
          return $ret 
        }
      } else {
        set gaSet(fail) "LTE Show Status of SIM-${actSim} fail"
        return $ret 
      }
    }
    
    set buffer $buf
    set gaSet(fail) "Read Operation Status of SIM-${actSim} fail"
    set res [regexp {Operation Status\s+:\s+(\w+)} $buffer ma val1]
    if {$res==0} {return -1}
    puts "CellularModemPerf_RadOS Operation Status of SIM-${actSim} i:<$i> val1:<$val1>"; update
    if {$val1=="Up"} {
      set gaSet(fail) "Read Operational Status of SIM-${actSim} fail"
      set res [regexp {Operational Status\s+:\s+(\w+)} $buffer ma val2]
      if {$res==0} {return -1}
      puts "CellularModemPerf_RadOS Operational Status of SIM-${actSim} i:<$i> val2:<$val2>"; update
    }
    
    set gaSet(fail) "Read Cellular network connection of SIM-${actSim} fail"
    set val3 ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val3]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val3:<$val3>"; update 
    
#     13/02/2022 15:30:16
#     set gaSet(fail) "Read Band of SIM-${actSim} fail"
#     set val4 ""
#     set res [regexp {Band\s+:\s+([\w\s]+)\s+Channel} $buffer ma val4]  
#     #if {$res==0} {return -1}  
#     puts "Band ma:<$ma> val4:<$val4>"; update 

##   ($val4=="LTE BAND 7" || $val4=="LTE BAND 3" || $val4=="LTE BAND 2")
    
    
    if {$val1=="Up" && $val2=="Up" && $val3=="Connected"} {
      set ret 0
      break
    } else {
      after 3000
    }
  }  
  
  if {$val1!="Up"} {
    set gaSet(fail) "Operation Status of SIM-${actSim} is \'$val1\'. Should be \'Up\'"
    return -1
  }
  if {$val2!="Up"} {
    set gaSet(fail) "Operational Status of SIM-${actSim} is \'$val2\'. Should be \'Up\'"
    return -1
  }
  
  if {$ret==0} {  
    set gaSet(fail) "Read RSSI of SIM-${actSim} fail"
    set res [regexp {RSSI \(dBm\)\s+:\s+([\-\d]+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "ReadRSSI ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "RSSI of SIM-${actSim}: $val dBm"  
    if {$val<"-75" || $val>"-51"} {
      set gaSet(fail) "RSSI of SIM-${actSim} is \'$val\'. Should be between -75 to -51"  
      return -1
    }
    
    set gaSet(fail) "Read Cellular network connection of SIM-${actSim} fail"
    set val ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "Cellular network connection of SIM-${actSim}: $val"  
    if {$val!="Connected"} {
      set gaSet(fail) "Cellular network connection of SIM-${actSim} is not \'Connected\'"  
      return -1
    }
    
#     13/02/2022 15:31:14
#     set gaSet(fail) "Read Band of SIM-${actSim} fail"
#     set val ""
#     set res [regexp {Band\s+:\s+([\w\s]+)\s+Channel} $buffer ma val]  
#     if {$res==0} {return -1}  
#     puts "Band ma:<$ma> val:<$val>"; update  
#     AddToPairLog $gaSet(pair) "Band of SIM-${actSim}: $val"  
#     if {$val!="LTE BAND 7" && $val!="LTE BAND 3" && $val!="LTE BAND 2"} {
#       set gaSet(fail) "Band of SIM-${actSim} is not \'LTE BAND 2\' or  \'LTE BAND 3\' or \'LTE BAND 7\'"  
#       return -1
#     }
    
  }
  
  if {$ret!=0} {return $ret} 

  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  
  set slot $actSim
  set res1 [set res2 [set res3 [set res4 0]]]
  for {set i 1} {$i<=7} {incr i} {
    Status "Connecting to Cellular Network ($i)"
    after 2000
    puts "Slot:$slot i:$i res1:$res1 res2:$res2 res3:$res3 res4:$res4"
    set ret [Send $com "/usr/sbin/quectel-CM -s internetg \&\r" "add wwan0" ]
    set ::buff $buffer
#     if {$ret==0} {}
    if 1 {
      set res1 1
      
      
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
      
      set res3 1
      
        
      set res4 1
      
      
      if {$res1 && $res2 && $res3 && $res4} {
        set ret 0
        break
      } 
    }
  }
  
  if {$ret!=0} {
    #set gaSet(fail) "Cellular Test of SIM-$slot fail"
    return $ret
  }
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2 
  
  if {$ret==0} {
    set w 5; Wait "Wait $w seconds for Network" $w
    for {set i 1} {$i<=5} {incr i} {
      puts "Ping $i"  
      set gaSet(fail) "Send ping to 8.8.8.8 from SIM-$slot fail"     
      set ret [Send $com "ping 8.8.8.8\r" "-1p" 25]
      if {$ret!=0} {return -1}
      set ret -1  
      if {[string match {*5 packets transmitted. 5 packets received, 0% packet loss*} $buffer]} {
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
# CellularLte_RadOS_Sim12
# ***************************************************************************
proc CellularLte_RadOS_Sim12 {} {
  global gaSet buffer
  puts "[MyTime] CellularLte_RadOS_Sim12"
  if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
    set L4 1
  } else {
    set L4 0
  }
  puts "CellularLte_RadOS_Sim12 L4:<$L4>"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration Cellular Lte fail"
  
  Status "Configuration Cellular"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  # if {[package vcompare $gaSet(SWver) "5.2.0.0"]==1} {
    # ## if gaSet(SWver) > "5.2.0.0", then vcompare = 1
    # set prmpt "(lte-1)"
    # set ret [Send $com "cellular lte-1\r" $prmpt]
  # } else {
    # set prmpt "(lte)"
    # set ret [Send $com "cellular lte\r" $prmpt]
  # }
  
  set prmpt "(lte)"
  set ret [Send $com "cellular lte\r" $prmpt]
  if {$ret!=0} {return $ret}
  set ret [Send $com "sim 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(1)"]
  if {$ret!=0} {return $ret}
  if {$gaSet(dutFam.box) == "ETX-1P"} {
    ## don't config pdp in ETX, L4
  } else {
    if $L4 {
      set ret [Send $com "pdp-type relayed-ppp\r" "(1)"]
      if {$ret!=0} {return $ret}
    }
  }
  #set ret [Send $com "no shutdown\r" "(lte)"]
  #if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" $prmpt]
  if {$ret!=0} {return $ret}
  set ret [Send $com "sim 2\r" "(2)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(2)"]
  if {$ret!=0} {return $ret}
  if {$gaSet(dutFam.box) == "ETX-1P"} {
    ## don't config pdp in ETX, L4
  } else {
    if $L4 {
      set ret [Send $com "pdp-type relayed-ppp\r" "(2)"]
      if {$ret!=0} {return $ret}
    }
  }
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "config"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "router 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "interface 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bind cellular lte\r" "(1)"]
  if {$ret!=0} {return $ret}
  if $L4 {
    set ret [Send $com "no shutdown\r" "(1)"]
  } elseif !$L4 {
    set ret [Send $com "dhcp\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "dhcp-client\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "client-id mac\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "-1p"]
    set ret [Send $com "no shutdown\r" "-1p"]
  }
  
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" "-1p"]
  return $ret
}
# ***************************************************************************
# CellularModemPerf_RadOS_Sim12
# ***************************************************************************
proc CellularModemPerf_RadOS_Sim12 {actSim disSim} {
  global gaSet buffer
  puts "\n[MyTime] CellularModemPerf_RadOS_Sim12 $actSim $disSim"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config Mode to SIM-$actSim fail"
  Status "Config Mode to SIM-$actSim"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  # if {[package vcompare $gaSet(SWver) "5.2.0.0"]==1} {
    # ## if gaSet(SWver) > "5.2.0.0", then vcompare = 1
    # set prmpt "(lte-1)"
    # set ret [Send $com "cellular lte-1\r" $prmpt]
  # } else {
    # set prmpt "(lte)"
    # set ret [Send $com "cellular lte\r" $prmpt]
  # }
  
  set prmpt "(lte)"
  set ret [Send $com "cellular lte\r" $prmpt]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" $prmpt]
  if {$ret!=0} {return $ret}
  Wait "Wait for LTE shutdown" 30
  set ret [Send $com "mode sim $actSim\r" $prmpt]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" $prmpt]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Read SIM-$actSim status fail"
  for {set i 1} {$i<=35} {incr i} {
    if {$gaSet(act)==0} {set ret -2; break}
    Status "Read SIM-$actSim status ($i)"
    set ret [Send $com "show status\r" "stam" 2]
    set buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" $prmpt]
    append buf $buffer
    if {$ret!=0} {return $ret}
    
    set buffer $buf
    
    set gaSet(fail) "Read Operational Status of SIM-${actSim} fail"
    set res [regexp {Operationa?l? Status\s+:\s+(\w+)} $buffer ma val1]
    if {$res==0} {return -1}
    puts "Operational Status of SIM-${actSim} i:<$i> val1:<$val1>"; update
    
    set gaSet(fail) "Read Mode fail"
    set val2 ""
    set res [regexp {Mode\s+:\s+(sim-\d)} $buffer ma val2]  
    if {$res==0} {return -1} 
    puts "Mode ma:<$ma> val2:<$val2>"; update 
  
    
    set gaSet(fail) "Read Cellular network connection of SIM-${actSim} fail"
    set val3 ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val3]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val3:<$val3>"; update 
    
    if {$val1=="Up" && $val2=="sim-$actSim" && $val3=="Connected"} {
      set ret 0
      break
    } else {
      after 3000
    }
  }  
  
  if {$val1!="Up"} {
    set gaSet(fail) "Operational Status of SIM-${actSim} is \'$val1\'. Should be \'Up\'"
    return -1
  }
  if {$val2!="sim-$actSim"} {
    set gaSet(fail) "Mode is \'$val2\'. Should be \'sim-$actSim\'"
    return -1
  }
  if {$val3!="Connected"} {
    set gaSet(fail) "Cellular network connection of SIM-${actSim} is \'$val3\'. Should be \'Connected\'"
    return -1
  }
  
  set gaSet(fail) "Read Administrative Status of SIM-${actSim} fail"
  set res [regexp {Administrative Status\s+:\s+(\w+)} $buffer ma val1]
  if {$res==0} {return -1}
  puts "Administrative Status of SIM-${actSim} i:<$i> val1:<$val1>"; update
  set ret 0
  
  if {$ret==0} {  
    set gaSet(fail) "Read RSSI of SIM-${actSim} fail"
    set res [regexp {RSSI \(dBm\)\s+:\s+([\-\d]+)} $buffer ma val]  
    if {$res==0} {
      set res [regexp {RSSI \(decibel-milliwatts\)\s+:\s+([\-\d]+)} $buffer ma val]  
      if {$res==0} {return -1}  
    }  
    puts "ReadRSSI ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "RSSI of SIM-${actSim}: $val dBm"  
    if {$val<"-75" || $val>"-20"} {
      set gaSet(fail) "RSSI of SIM-${actSim} is \'$val\'. Should be between -75 to -20"  
      return -1
    }
    
    set gaSet(fail) "Read Cellular network connection of SIM-${actSim} fail"
    set val ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "Cellular network connection of SIM-${actSim}: $val"  
    if {$val!="Connected"} {
      set gaSet(fail) "Cellular network connection of SIM-${actSim} is not \'Connected\'"  
      return -1
    }
    
    set gaSet(fail) "Read SIM Status fail"
    set val ""
    set res [regexp {SIM Status\s+:\s+(\w+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "SIM Status ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "SIM Status of SIM-${actSim}: $val"  
    if {$val!="ready"} {
      set gaSet(fail) "SIM Status of SIM-${actSim} is not \'ready\'"  
      return -1
    }
    
    set gaSet(fail) "Read Firmware fail"
    set val ""
    set res [regexp {Firmware : Revision:\s+([\w\._/]+)} $buffer ma val]  
    if {$res==0} {
      set res [set res [regexp {Firmware :\s+([\w\._/]+)} $buffer ma val]]  
      if {$res==0} {return -1}  
    }  
    puts "Firmware ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "Firmware of SIM-${actSim}: $val"  
    set cell [string range $gaSet(dutFam.cell) 1 end]
    set fw $gaSet([set cell].fwL) 
    puts "Firmware cell:<$cell> fw:<$fw>"; update  
    # if {$cell=="L450B"} {
      # set gaSet(fail) "Bad FTI for this option"
      # return -1      
    # }
    
    # 10:29 02/04/2024 if {$val!=$fw} {} 
    if {[lsearch $fw $val]=="-1"} {
      set gaSet(fail) "Firmware of SIM-${actSim} is \'$val\'. Should be \'$fw\'"  
      return -1
    }
  }
  
  if {$ret!=0} {return $ret} 

  
  if {$ret==0} {
    set w 5; Wait "Wait $w seconds for Network" $w
    for {set i 1} {$i<=5} {incr i} {
      puts "Ping $i"  
      set gaSet(fail) "Send ping to 8.8.8.8 from SIM-$actSim fail"     
      set ret [Send $com "ping 8.8.8.8\r" "-1p" 25]
      if {$ret!=0} {return -1}
      set ret -1  
      if {[string match {*5 packets transmitted. 5 packets received, 0% packet loss*} $buffer]} {
        set ret 0
        break
      } else {
        set gaSet(fail) "Ping to 8.8.8.8 from SIM-$actSim fail" 
        after 10000
      }
    }
  }
  return $ret
}  

# ***************************************************************************
# CellularLte_RadOS_Sim12_Dual
# ***************************************************************************
proc CellularLte_RadOS_Sim12_Dual {} {
  global gaSet buffer
  puts "[MyTime] CellularLte_RadOS_Sim12_Dual"
  if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
    set L4 1
  } else {
    set L4 0
  }
  puts "CellularLte_RadOS_Sim12_Dual L4:<$L4>"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration Cellular Lte fail"
  
  Status "Configuration Cellular"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  set prmpt "(lte)"
  set ret [Send $com "cellular lte-1\r" "lte-1"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "sim 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(1)"]
  if {$ret!=0} {return $ret}
  # if $L4 {
    # set ret [Send $com "pdp-type relayed-ppp\r" "(1)"]
    # if {$ret!=0} {return $ret}
  # }
  set ret [Send $com "exit\r" "lte-1"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "lte-1"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "-1"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "cellular lte-2\r" "lte-2"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "sim 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "apn-name \"statreal\"\r" "(1)"]
  if {$ret!=0} {return $ret}
  if $L4 {
    set ret [Send $com "pdp-type relayed-ppp\r" "(1)"]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "exit\r" "lte-2"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "lte-2"]
  
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "config"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "router 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "interface 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bind cellular lte-1\r" "(1)"]
  if {$ret!=0} {return $ret}
  # if $L4 {
    # set ret [Send $com "no shutdown\r" "(1)"]
  # } elseif !$L4 {
    # set ret [Send $com "dhcp\r" "(1)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "dhcp-client\r" "(1)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "client-id mac\r" "(1)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "exit\r" "-1p"]
    # set ret [Send $com "no shutdown\r" "-1p"]
  # }
    set ret [Send $com "dhcp\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "dhcp-client\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "client-id mac\r" "(1)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "-1p"]
    set ret [Send $com "no shutdown\r" "-1p"]
  set ret [Send $com "exit\r" "(1)"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "interface 2\r" "(2)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "(2)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bind cellular lte-2\r" "(2)"]
  if {$ret!=0} {return $ret}
  # if $L4 {
    # set ret [Send $com "no shutdown\r" "(1)"]
  # } elseif !$L4 {
    # set ret [Send $com "dhcp\r" "(2)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "dhcp-client\r" "(2)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "client-id mac\r" "(2)"]
    # if {$ret!=0} {return $ret}
    # set ret [Send $com "exit\r" "-1p"]
    # set ret [Send $com "no shutdown\r" "-1p"]
  # }
    set ret [Send $com "dhcp\r" "(2)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "dhcp-client\r" "(2)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "client-id mac\r" "(2)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "-1p"]
    set ret [Send $com "no shutdown\r" "-1p"]
  
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" "-1p"]
  return $ret
}

# ***************************************************************************
# CellularModemPerf_RadOS_Sim12_Dual
# ***************************************************************************
proc CellularModemPerf_RadOS_Sim12_Dual {actLte} {
  global gaSet buffer
  puts "\n[MyTime] CellularModemPerf_RadOS_Sim12_Dual $actLte"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config Mode to LTE-$actLte fail"
  Status "Config Mode to LTE-$actLte"
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port\r" "-1p"]
  if {$ret!=0} {return $ret}
 
  
  set prmpt "-$actLte"
  set ret [Send $com "cellular lte-$actLte\r" $prmpt]
  if {$ret!=0} {return $ret}
  # set ret [Send $com "shutdown\r" $prmpt]
  # if {$ret!=0} {return $ret}
  # Wait "Wait for LTE shutdown" 10
  # set ret [Send $com "mode sim $actSim\r" $prmpt]
  # if {$ret!=0} {return $ret}
  # set ret [Send $com "no shutdown\r" $prmpt]
  # if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Read LTE-$actLte status fail"
  for {set i 1} {$i<=35} {incr i} {
    if {$gaSet(act)==0} {set ret -2; break}
    Status "Read LTE-$actLte status ($i)"
    set ret [Send $com "show status\r" "stam" 2]
    set buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" "stam" 2]
    append buf $buffer
    set ret [Send $com "\r" $prmpt]
    append buf $buffer
    if {$ret!=0} {return $ret}
    
    set buffer $buf
    
    set gaSet(fail) "Read Operational Status of LTE-$actLte fail"
    set res [regexp {Operationa?l? Status\s+:\s+(\w+)} $buffer ma val1]
    if {$res==0} {return -1}
    puts "Operational Status of LTE-$actLte i:<$i> val1:<$val1>"; update
    
    set gaSet(fail) "Read Mode fail"
    set val2 ""
    set res [regexp {Mode\s+:\s+(sim-1)} $buffer ma val2]  
    if {$res==0} {return -1} 
    puts "Mode ma:<$ma> val2:<$val2>"; update 
  
    
    set gaSet(fail) "Read Cellular network connection of LTE-$actLte fail"
    set val3 ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val3]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val3:<$val3>"; update 
    
    if {$val1=="Up" && $val2=="sim-1" && $val3=="Connected"} {
      set ret 0
      break
    } else {
      after 3000
    }
  }  
  
  if {$val1!="Up"} {
    set gaSet(fail) "Operational Status of LTE-$actLte is \'$val1\'. Should be \'Up\'"
    return -1
  }
  if {$val2!="sim-1"} {
    set gaSet(fail) "Mode is \'$val2\'. Should be \'sim-1\'"
    return -1
  }
  if {$val3!="Connected"} {
    set gaSet(fail) "Cellular network connection of LTE-$actLte is \'$val3\'. Should be \'Connected\'"
    return -1
  }
  
  set gaSet(fail) "Read Administrative Status of LTE-$actLte fail"
  set res [regexp {Administrative Status\s+:\s+(\w+)} $buffer ma val1]
  if {$res==0} {return -1}
  puts "Administrative Status of LTE-$actLte i:<$i> val1:<$val1>"; update
  set ret 0
  
  if {$ret==0} {  
    set gaSet(fail) "Read RSSI of LTE-$actLte fail"
    set res [regexp {RSSI \(dBm\)\s+:\s+([\-\d]+)} $buffer ma val]  
    if {$res==0} {
      set res [regexp {RSSI \(decibel-milliwatts\)\s+:\s+([\-\d]+)} $buffer ma val]  
      if {$res==0} {return -1}  
    }  
    puts "ReadRSSI ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "RSSI of LTE-$actLte: $val dBm"  
    if {$val<"-75" || $val>"-20"} {
      set gaSet(fail) "RSSI of LTE-$actLte is \'$val\'. Should be between -75 to -20"  
      return -1
    }
    
    set gaSet(fail) "Read Cellular network connection of LTE-$actLte fail"
    set val ""
    set res [regexp {Cellular network connection\s+:\s+(\w+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "Cellular network connection ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "Cellular network connection of LTE-$actLte: $val"  
    if {$val!="Connected"} {
      set gaSet(fail) "Cellular network connection of LTE-$actLte is not \'Connected\'"  
      return -1
    }
    
    set gaSet(fail) "Read SIM Status fail"
    set val ""
    set res [regexp {SIM Status\s+:\s+(\w+)} $buffer ma val]  
    if {$res==0} {return -1}  
    puts "SIM Status ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "SIM Status of LTE-$actLte: $val"  
    if {$val!="ready"} {
      set gaSet(fail) "SIM Status of LTE-$actLte is not \'ready\'"  
      return -1
    }
    
    set gaSet(fail) "Read Firmware fail"
    set val ""
    set res [regexp {Firmware : Revision:\s+(\w+)} $buffer ma val]  
    if {$res==0} {
      set res [set res [regexp {Firmware :\s+([\w\._/]+)} $buffer ma val]]  
      if {$res==0} {return -1}  
    }  
    puts "Firmware ma:<$ma> val:<$val>"; update  
    AddToPairLog $gaSet(pair) "Firmware of LTE-$actLte: $val"  
    set cell [string range $gaSet(dutFam.cell) 1 end]
    set fw $gaSet([set cell].fwL) 
    puts "Firmware cell:<$cell> fw:<$fw>"; update  
    # if {$cell=="L450B"} {
      # set gaSet(fail) "Bad FTI for this option"
      # return -1      
    # }
    
    # 10:33 02/04/2024 if {$val!=$fw} {} 
    if {[lsearch $fw $val]=="-1"} {
      set gaSet(fail) "Firmware of LTE-$actLte is \'$val\'. Should be \'$fw\'"  
      return -1
    }
    
  }
  
  if {$ret!=0} {return $ret} 

  
  if {$ret==0} {
    set w 5; Wait "Wait $w seconds for Network" $w
    for {set i 1} {$i<=5} {incr i} {
      puts "Ping $i"  
      set gaSet(fail) "Send ping to 8.8.8.8 from LTE-$actLte fail"     
      set ret [Send $com "ping 8.8.8.8\r" "-1p" 25]
      if {$ret!=0} {return -1}
      set ret -1  
      if {[string match {*5 packets transmitted. 5 packets received, 0% packet loss*} $buffer]} {
        set ret 0
        break
      } else {
        set gaSet(fail) "Ping to 8.8.8.8 from LTE-$actLte fail" 
        after 10000
      }
    }
  }
  
  if {$ret==0 && $actLte==2} {
    set ret [Login2Linux]
    if {$ret!=0} {return $ret}
    set w 5; Wait "Wait $w seconds for Network" $w
    foreach wwan {wwan0 wwan1} {
      for {set i 1} {$i<=5} {incr i} {
        puts "Ping $i"  
        set gaSet(fail) "Send ping to 8.8.8.8 from $wwan fail"     
        set ret [Send $com "ping 8.8.8.8 -I $wwan -c 5\r" $gaSet(linuxPrompt) 25]
        if {$ret!=0} {return -1}
        set ret -1  
        if {[string match {*5 packets transmitted, 5 received, 0% packet loss*} $buffer]} {
          set ret 0
          break
        } else {
          set gaSet(fail) "Ping to 8.8.8.8 from $wwan fail"
          return -1          
        }
      }
    }
  }
  return $ret
}  


# ***************************************************************************
# BootLedsPerf
# ***************************************************************************
proc BootLedsPerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  if {$gaSet(dutFam.sf)=="ETX-1P_SFC"} {
    Power all off
    Status "Power OFF"
    after 4000
    Power all on
    Status "Power ON"
    after 1000
  }
  
  RLSound::Play information
  set txt "Please disconnect all ETH cables\n\
  Remove the SD-card and the SIMs (if exists)"
  if {$gaSet(dutFam.cell)!=0} {
    append txt "\nDisconnect the antenna from \'LTE MAIN\' and mount it on the \'LTE AUX\'"
  }  
  set res [DialogBox -title "Boot Leds Test" -type "Ok Cancel" -message $txt  -icon images/info]
  if {$res=="Cancel"} {
    set gaSet(fail) "\'LTE AUX\' Test fail" 
    return -1
  }
  
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  set ret [Login]  ; # Login2App
  if {$ret!=0} {
    return $ret
  }
  Send $com "logout\r\r" "stam" 3 
  RLSound::Play information
  RLCom::Read $com buffer
  Send $com "\r" "stam" 1 
  set ::bb $buffer
  puts "Buffer before FD: <$::bb>"; update 
  set res [DialogBox -title "FD button Test" -type "Yes No" \
      -message "Press the FD button for 10-15 sec and verify the UUT is reboting (Front side's LEDs are blinking one time).\n\n\
      Reset has been performed??" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "FD button Test fail" 
    return -1
  }
  
  Send $com "\r" "stam" 1 
  set ::ba $buffer
  puts "Buffer after FD: <$::ba>"; update 
  
  RLCom::Read $com buffer
  puts "BootLedsPerf buffer <$buffer>" ; update
  if {[string match {*actory-default-config*} $buffer]==0} {
    set gaSet(fail) "No \'factory-default-config\' message (FD button)" 
    #return -1
  }
  if {$::bb == $::ba} {
    set gaSet(fail) "Reset was not performed (FD button)" 
    return -1
  }
   
  set ret [Login2Boot]
  if {$ret!=0} {return $ret}  
  
#   RLSound::Play information
#   set res [DialogBox -title "FD button Test" -type "Yes No" \
#       -message "Press the FD button and verify the UUT is reboting.\n\n\
#       Reset has been performed??" -icon images/info]
#   if {$res=="No"} {
#     set gaSet(fail) "FD button Test fail" 
#     return -1
#   }
#   set ret [Login2Boot]
#   if {$ret!=0} {return $ret}  
  
  set ret [Send $com "\r\r" "PCPE" 1]
  if {$ret!=0} {
    Power all off
    after 4000
    Power all on
    set ret [Login2Boot]
    if {$ret!=0} {return $ret}    
  }
  
  set ret [Send $com "mmc dev 0:1\r" "PCPE"]
  if {$ret!=0} {
    set gaSet(fail) "\'mmc dev 0:1\' fail"
    return -1
  }
  if ![string match {*ot found*} $buffer] {   
    set gaSet(fail) "SD card is not pulled out" 
    return -1
  }
  
  RLSound::Play information
  set res [DialogBox -title "ALM and RUN Led Test" -type "Yes No" \
      -message "Verify the ALM and RUN Leds are OFF" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "ALM and RUN Leds are not OFF" 
    return -1
  }
  
  set ret [Send $com "gpio toogle GPIO112\r" "PCPE"]
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set res [DialogBox -title "RUN and PWR Green Led Test" -type "Yes No" \
      -message "Verify the RUN and PWR Green Leds are ON" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "RUN and/or PWR Green Led are not ON" 
    return -1
  }
  Send $com "gpio toogle GPIO112\r" "PCPE"
  
  set ret [Send $com "gpio toogle GPIO113\r" "PCPE"]
  if {$ret!=0} {return $ret}
  RLSound::Play information
  set res [DialogBox -title "ALM Red Led Test" -type "Yes No" \
      -message "Verify the ALM Red Led is ON" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "ALM Red Led is not ON" 
    return -1
  }
  Send $com "gpio toogle GPIO113\r" "PCPE"
  
  catch {Send $com "mii write 1 1 0x80fe\r" "PCPE"}
  catch {Send $com "mii write 1 0 0x9656\r" "PCPE"}
  RLSound::Play information
  set res [DialogBox -title "AUX Green Led Test" -type "Yes No" \
      -message "Verify the AUX Green Led is ON, if exists" -icon images/info]
  if {$res=="No"} {
    set gaSet(fail) "AUX Green Led is not ON" 
    return -1
  }
  catch {Send $com "mii write 1 1 0x80ee\r" "PCPE"}
  catch {Send $com "mii write 1 0 0x9656\r" "PCPE"}
  
  # all ON
  catch {Send $com "mii write 2 1 0x80ff\r" "PCPE"}
  catch {Send $com "mii write 2 0 0x96b6\r" "PCPE"}  
  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC"} {
    # WAN2 led
    catch {Send $com "mii write 2 0 0x9676\r" "PCPE"}  
  } 
  foreach {reg1} {0x80ff 0x90ff} {
    foreach reg2 {0x9636 0x9656 0x9676 0x9696} {
      catch {Send $com "mii write 1 1 $reg1\r" "PCPE"}
      catch {Send $com "mii write 1 0 $reg2\r" "PCPE"}
    }
  }
  
  set txt "Verify Green Leds are ON on the following ports:\n\
  ETH 1-6, S1 TX and RX, S2 TX and RX, SIM 1 and 2\n\n\
  Verify Red Led is ON on the AUX port\n\n\
  Do the Leds work well?"
  RLSound::Play information
  set res [DialogBox -title "Boot Leds Test" -type "Yes Stop" -message "$txt" -icon images/info]
  if {$res=="Stop"} {
    set gaSet(fail) "Boot Leds Test fail" 
    return -1
  }
  
  # all OFF
  catch {Send $com "mii write 2 1 0x80ee\r" "PCPE"}
  catch {Send $com "mii write 2 0 0x96b6\r" "PCPE"}
  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC"} {
    # WAN2 led
    catch {Send $com "mii write 2 0 0x9676\r" "PCPE"}  
  }
  foreach {reg1} {0x80ee 0x90ee} {
    foreach reg2 {0x9636 0x9656 0x9676 0x9696} {
      catch {Send $com "mii write 1 1 $reg1\r" "PCPE"}
      catch {Send $com "mii write 1 0 $reg2\r" "PCPE"}
    }
  }

  set txt "Verify all the leds, except PWR, are OFF"
  RLSound::Play information
  set res [DialogBox -title "Boot Leds Test" -type "Yes Stop" -message "$txt" -icon images/info]
  if {$res=="Stop"} {
    set gaSet(fail) "Boot Leds Test fail" 
    return -1
  }
  return 0
  
}
proc __LedsInLoop {} {
  global gaSet
  set com $gaSet(comDut)
  
  ## all OFF
  catch {Send $com "mii write 2 1 0x80ee\r" "PCPE"}
  catch {Send $com "mii write 2 0 0x96b6\r" "PCPE"}
  
  foreach {reg1} {0x80ee 0x90ee} {
    foreach reg2 {0x9636 0x9656 0x9676 0x9696} {
      catch {Send $com "mii write 1 1 $reg1\r" "PCPE"}
      catch {Send $com "mii write 1 0 $reg2\r" "PCPE"}
    }
  }
  
  # all ON
  catch {Send $com "mii write 2 1 0x80ff\r" "PCPE"}
  catch {Send $com "mii write 2 0 0x96b6\r" "PCPE"}
  foreach {reg1} {0x80ff 0x90ff} {
    foreach reg2 {0x9636 0x9656 0x9676 0x9696} {
      catch {Send $com "mii write 1 1 $reg1\r" "PCPE"}
      catch {Send $com "mii write 1 0 $reg2\r" "PCPE"}
    }
  }
  
  return 0
  
  
}
# ***************************************************************************
# PowerOffOnPerf
# ***************************************************************************
proc PowerOffOnPerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  for {set i 1} {$i <=  5} {incr i} {
    Power all off
    Status "Power OFF $i"
    after 4000
    Power all on
    Status "Power ON $i"
    after 1000
    # if $gaSet(showBoot) {
      # set timeou 2
    # } else {
      # set timeou 30
      # if {$gaSet(dutFam.box)=="ETX-1P"} {
        # set timeou 70
      # }
    # }
    set ret [ReadCom $com "rad os pre service" 130]
    puts "PowerOffOnPerf ret:<$ret>" ; update       
    #Send $com \r stam $timeou
    set buffLen [string length $buffer]
    puts "PowerOffOnPerf $i buffLen:<$buffLen>"; update
    if {$buffLen>100} {
      set ret 0
    } else {
      set ret -1
      set gaSet(fail) "UUT doesn't respond after $i OFF-ON"
      break
    }
    
  }
  return $ret
}


# ***************************************************************************
# LoraModuleConf
# ***************************************************************************
proc LoraModuleConf {} {
  global gaSet buffer
  Status "LoRa Module Configuration"
  
  set gaSet(fail) "Logon fail"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  Status "Configuration LoRa Module"
  
  set gaSet(fail) "Configuration LoRa Module fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "config\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "router 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "interface 32\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "-1p" 44]
  if {$ret!=0} {
    set ret [Send $com \r "-1p" 44]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "no address 169.254.1.1/16\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "address $gaSet(ip4lora)/24\r" "-1p"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "dhcp\r" "-1p"]
  #if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "-1p" 44]
  if {$ret!=0} {
    set ret [Send $com "\r" "-1p" 44]
    if {$ret!=0} {return $ret}
  }
  Status "Waiting for Lease"
  set obt 0
  set maxWait 300
  MuxMngIO 6ToPc
  set startSec [clock seconds]
  for {set i 1} {$i<=100} {incr i} {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set waitSec [expr {$nowSec - $startSec}]
    if {$waitSec>$maxWait} {
      set gaSet(fail) "DHCP IP not Obtained after $maxWait seconds"
      return -1
    }
    puts "Wait for DHCP: <$waitSec>, i:<$i> "; update
    set ret [Send $com "show status\r" "-1p" 44]
    if {[string match {*Lease Obtained*} $buffer]} {
      set obt 1
      set ret [Send $com \r "-1p"]
      break
    }
    if {[string match {*Admin:Up*} $buffer] && [string match {*Oper: Up*} $buffer]} {
      set obt 1
      set ret [Send $com \r "-1p"]
      break
    }
    switch -exact -- $i {
      20 -  40 -  60 - 80 {
        MuxMngIO nc
        after 3000
        MuxMngIO 6ToPc
      }
    }
    if {$ret!=0} {return $ret}
    after 3000
  }
  if {$obt==0} {
    set gaSet(fail) "DHCP IP not Obtained"
    return -1
  }
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "dns-name-server 8.8.8.8\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  
  set ret [Send $com "exit\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "system\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "date-and-time ntp\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "server 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  
  regexp {172.18.9.+} [exec ipconfig] ma
  regexp {Gateway[\.\:\s]+([\d\.]+)}  $ma val dg
  set dg [string trim $dg]
  set ret [Send $com "address $dg\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" "(1)"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "-1p"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port lora 1\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "frequency plan $gaSet(dutFam.lora.region)\r" "(1)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gateway\r" "lora-gateway"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "lora-gateway" 20]
  if {$ret!=0} {return $ret}
  set ret [Send $com "server ip-address $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam)) port 1700\r" "lora-gateway"]
  if {$ret!=0} {return $ret}
  set gw "1806f5fffeb80" ; # 1806f5fffeb80a11
  set loraType [string tolower [string index $gaSet(dutFam.lora) end]]
  append gw $loraType
  set pcNumb [lindex [split [info host] -] end-1]; # at-sf1p-1-10 -> 1
  append gw $pcNumb
  append gw $gaSet(pair)
  puts "LoraModuleConf gateway-id:<$gw>"
  set gaSet(ChirpStackIPGW) $gw
  set ret [Send $com "gateway-id string $gw\r" "lora-gateway"]; #gaSet(ChirpStackIPGW)
  if {$ret!=0} {return $ret}
  # set ret [Send $com "no shutdown\r" "lora-gateway"]
  # if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" "-1p"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# LoraGateWayMode
# ***************************************************************************
proc LoraGateWayMode {mode} {
  global gaSet buffer
  Status "Set Lora GateWay Mode to $mode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Set Lora GateWay Mode to $mode"
  
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure\r" "-1p"]
  if {$ret==0} {
    set ret [Send $com "port lora 1\r" "(1)"]
    if {$ret==0} {
      set ret [Send $com "gateway\r" "lora-gateway"]
      if {$ret==0} {
        set ret [Send $com "$mode\r" "lora-gateway"]
        if {$ret==0} {
          set ret [Send $com "exit all\r" "-1p"]
        }
      }
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Fail to open Lora's Gateway"
  }
  return $ret
}

# ***************************************************************************
# LoraPerf
# ***************************************************************************
proc LoraPerf {data} {
  global gaSet buffer
  puts "\n[MyTime] LoraPerf $data"; update
  #set data $gaSet(ChirpStackData)
  set logFile //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs/${gaSet(ChirpStackIPGW)}.$data.txt
  if [catch {file delete -force $logFile} res] {
    puts "LoraPerf res1: <$res>"; update
    set gaSet(fail) "Delete $logFile fail"
    return -1
  }
  # set ret [JoinLoraDev]
  # if {$ret!=0} {
    # set ret [JoinLoraDev]
    # if {$ret!=0} {return $ret}
  # }
  #puts "\n[MyTime] LoraPerf before Send <[glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]>"; update
  set ret [SendDataToLoraDev $data]
  if {$ret!=0} {return $ret}
  puts "[MyTime] LoraPerf after Send <[glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]>"; update
  
 if {[file exists $logFile]} {
    set ret 0 
    AddToPairLog $gaSet(pair) "LogFile: [file tail $logFile]"
    catch {file delete -force $logFile} res
    puts "LoraPerf res after delete logFile: <$res>"; update
  } else {
    set gaSet(fail) "Log File for $gaSet(ChirpStackIPGW) doesn't exist"
    return $ret
  }
  return $ret
}
# ***************************************************************************
# CellularLte
# ***************************************************************************
proc CellularLte {} {
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
# CellularModemPerf
# ***************************************************************************
proc CellularModemPerf {slot l4} {
  global gaSet buffer
  puts "[MyTime] CellularModemPerf $slot $l4"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem of SIM-$slot fail" 
  set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio500/value\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return -1}
  after 2000
#   set ret [Send $com "echo \"487\" > /sys/class/gpio/export\r" "\]#"]
#   if {$ret!=0} {return -1}
  set ret [Send $com "echo \"out\" > /sys/class/gpio/gpio487/direction\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return -1}
#   set ret [Send $com "echo \"500\" > /sys/class/gpio/export\r" "\]#"]
#   if {$ret!=0} {return -1}
  set ret [Send $com "echo \"out\" > /sys/class/gpio/gpio500/direction\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return -1}
  
  set w 5; Wait "Wait $w seconds for GPIO init" $w
  
  set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio500/value\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return -1}
  
  set w 10; Wait "Wait $w seconds for modem OFF" $w
  
  set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio500/value\r" $gaSet(linuxPrompt)]
  if {$ret!=0} {return -1}
  
  if {$slot==1} {
    set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio487/value\r" $gaSet(linuxPrompt)]
  } elseif {$slot==2} {
    set ret [Send $com "echo \"0\" > /sys/class/gpio/gpio487/value\r" $gaSet(linuxPrompt)]
  }
  if {$ret!=0} {return -1}
  set ret [Send $com "echo \"1\" > /sys/class/gpio/gpio500/value\r" $gaSet(linuxPrompt)]
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
      set ret [Send $com "ping 8.8.8.8 -c 5\r" $gaSet(linuxPrompt) 15]
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
# CheckSimOut
# ***************************************************************************
proc CheckSimOut {} {
 global gaSet buffer
  puts "[MyTime] CheckSimOut"
  
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  Send $com "exit all\r" "#"
  set cellQty [string index $gaSet(dutFam.cell) 0]
  if {$cellQty==1} {
    set ret [CellularLte_RadOS_Sim12]
    if {$ret!=0} {return $ret}
    Status "Read SIM status"
    set ret [Send $com "configure port cellular lte\r" "(lte)#"]
    if {$ret!=0} {
      set gaSet(fail) "Configure cellular lte fail"
      return $ret 
    }
    foreach sim {1 2} {
    
      set ret [Send $com "shutdown\r" "(lte)#"]
      set ret [Send $com "mode sim $sim\r" "(lte)#"]
      if {$ret!=0} {
        set gaSet(fail) "Configure mode sim-$sim fail"
        return $ret 
      }
      set ret [Send $com "no shutdown\r" "(lte)#"]
      if {$sim=="2"} {
        Wait "Wait for SIM-2 activation" 60 white
      }  
    
      for {set i 1} {$i<=40} {incr i} {
        if {$gaSet(act)==0} {set ret -2; break}
        after 2000
        Status "Read LTE status of SIM-$sim ($i)"
        set b ""
        set ret [Send $com "show status\r" "more"]
        append b $buffer
        set ret [Send $com "\r" "(lte)#" 1]
        append b $buffer
        
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte)#" 1]
          append b $buffer
        }
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte)#" 1]
          append b $buffer
        }
        if {$ret!=0} {
          set gaSet(fail) "LTE Show Status fail"
          return $ret 
        }
        set buffer $b
        puts "\nbuffer:<$buffer>\n"
        
        set gaSet(fail) "Read SIM Status fail"
        set res [regexp {SIM Information[\s\-]+SIM([\w\s\d\:]+)Status} $buffer ma val]
        puts "simInfo res<$res>  ma<$ma> val<$val> sim:<$sim>"
        if {$sim=="1" && [string match {*SIM 2*} $val]} {
          continue
        }
        if {$sim=="2" && [string match {*SIM 1*} $val]} {
          continue
        }
        
        set gaSet(fail) "Read SIM Status fail"
        set res [regexp {SIM Status\s+:\s+([\w\-]+)} $buffer ma val]
        if {$res==1} {
          set ret 0
          break
        } else {
          after 2000
        }
      }
      if {$ret!=0} {
        return $ret
      } 
      puts "val:<$val>" 
      if {$val=="ready"} {
        set gaSet(fail) "The SIM-$sim is not pulled out"
        set ret -1
        return $ret
      }
    }  
   
  } elseif {$cellQty==2} {
    set ret [CellularLte_RadOS_Sim12_Dual]
    if {$ret!=0} {return $ret}
    foreach mdm {1 2} {
      Status "Read Cellular parameters of modem-$mdm"
       
      Send $com "exit all\r" "-1p"
      set ret [Send $com "configure port cellular lte-$mdm\r" "lte-$mdm"]
      if {$ret!=0} {
        set gaSet(fail) "Set modem $mdm power-up fail"
        return $ret 
      }
      for {set i 1} {$i<=10} {incr i} {
        if {$gaSet(act)==0} {set ret -2; break}
        Status "Read LTE-$mdm status ($i)"
        set b ""
        set ret [Send $com "show status\r" "more"]
        append b $buffer
        set ret [Send $com "\r" "(lte-$mdm)" 1]
        append b $buffer
        
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if [string match *more* $buffer] {
          set ret [Send $com "\r" "(lte-$mdm)" 2]
          append b $buffer
        }
        if {$ret!=0} {
          set gaSet(fail) "LTE-$mdm Show Status fail"
          return $ret 
        }
        set buffer $b
        set ret -1; set val ""
        puts "\nbuffer:<$buffer>\n"
        set gaSet(fail) "Read SIM of lte-$mdm fail"
        set res [regexp {SIM Status\s+:\s+([\w\-]+)} $buffer ma val]
        if {$res==1} {
          set ret 0
          break
        } else {
          after 2000
        }
      }   
      if {$ret!=0} {
        return $ret
      } 
      puts "val:<$val>" 
      if {$val=="ready"} {
        set gaSet(fail) "The SIM of lte-$mdm is not pulled out"
        set ret -1
        break
      }   
    } 
  }
  Send $com "exit all\r" "-1p"
  puts ""
  return $ret 
}

# ***************************************************************************
# HL_SecurityPerf
# ***************************************************************************
proc HL_SecurityPerf {} {
  global buffer gaSet
  puts "\n[MyTime] HL_SecurityPerf "; update
  set com $gaSet(comDut)
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}    
  
  set ret -1
  set gaSet(fail) "Load Docker fail"
  Send $com "cd /USERFS/docker/internal\r" stam 1
  #Send $com "commend\r" stam 1
  Send $com "docker load -i gateway-mfr-rs.tar\r" "Loaded image"
  
  Send $com "docker run --rm -it --privileged gateway-mfr-rs:latest /gateway_mfr --device ecc://i2c-5:0xc0?slot=0 provision\r" stam 3
  if [string match *Error* $buffer] {
    set gaSet(fail) "Provision returns Error"
    AddToPairLog $gaSet(pair) "Provision:<Error>"
    #return -1
  }
  
  Send $com "docker run --rm -it --privileged gateway-mfr-rs:latest /gateway_mfr --device ecc://i2c-5:0xc0?slot=0 info\r" internal
  if [string match *Error* $buffer] {
    set gaSet(fail) "Check INFO returns Error"
    return -1
  }
  #set infSer [lindex $buffer [lsearch $buffer info]+1]
  #set infSerLst [regsub -all \[:,\"\] $infSer ""]
  #foreach {aa info bb serial} $infSerLst {}
  #puts "info:<$info> serial:<$serial>"
  #AddToPairLog $gaSet(pair) "info:<$info> serial:<$serial>"
  
  set body [lrange $buffer [lsearch $buffer info]+1 end-2]
  set asadict [::json::json2dict $body]
  foreach {par val} $asadict {
    dict set di $par $val
  }
  set info [dict get $di info]
  set serial [dict get $di serial]
  puts "info:<$info> serial:<$serial>"
  AddToPairLog $gaSet(pair) "info:<$info> serial:<$serial>"
  
  Send $com "docker run --rm -it --privileged gateway-mfr-rs:latest /gateway_mfr --device ecc://i2c-5:0xc0?slot=0 test\r" internal
  if [string match *Error* $buffer] {
    set gaSet(fail) "Check TEST returns Error"
    return -1
  }
  set body [lrange $buffer [lsearch $buffer test]+1 end]
  set asadict [::json::json2dict $body]
  set resQty 0
  set passQty 0
  foreach i [lindex $asadict end] {
    puts $i
    if [string match *result* $i] {incr resQty}
    if [string match *pass* $i] {incr passQty}
  }
  puts "resQty:<$resQty> passQty:<$passQty>"
  if {$resQty != $passQty} {
    set gaSet(fail) "Not all $resQty results are \'pass\'"
    return -1
  } else {
    set ret 0
    set gaSet(fail) ""
  }
  
  return $ret
}
# ***************************************************************************
# Halow_WiFiPerf
# ***************************************************************************
proc Halow_WiFiPerf {} {
  global buffer gaSet
  puts "\n[MyTime] Halow_WiFiPerf "; update
  set com $gaSet(comDut)
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  Status "Config Halow_WiFi Client"
  set gaSet(fail) "Config Halow_WiFi Client fail"
  Send $com "exit all\r" "-1p#"
  set ret [Send $com "configure router 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "interface 10\r"  (10)]
  if {$ret!=0} {return $ret}
   set ret [Send $com "shutdown\r"  (10)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bind wifi-client 1\r" (10)]
  if {$ret!=0} {return $ret}
  
  set addr "192.168.172."
  set pcNumb [lindex [split [info host] -] end-1]; # at-sf1p-1-10 -> 1
  append addr $pcNumb
  append addr $gaSet(pair)
  set ret [Send $com "address $addr/24\r" (10)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r"  (10)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r"  (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "static-route 0.0.0.0/ address 192.168.172.250\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" config]
  if {$ret!=0} {return $ret}
  set ret [Send $com "port wifi-client\r" client]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" client]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ssid \"HalowAP\"\r" HalowAP]
  if {$ret!=0} {return $ret}
  set ret [Send $com "security none\r" HalowAP]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" HalowAP]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" client]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" client]
  if {$ret!=0} {return $ret}
  
  set ret [Halow_WiFi_ShowStatus]
  puts "\n ret of Halow_WiFi_ShowStatus: <$ret>"
  if {$ret!=0} {return $ret}
  
  for {set i 1} {$i <=3} {incr i} {
    Status "Ping to 192.168.172.250 ($i)"
    set ret [Send $com "ping 192.168.172.250\r" "client" 20]
    if {$ret!=0} {
      set gaSet(fail) "Send ping to 192.168.172.250 fail"
      return $ret
    }
    set res [regexp {(\d) packets transmitted. (\d) packets received, (\d+)% packet loss} $buffer ma tp rp pl]
    if {$res==0} {
      set gaSet(fail) "Retrive ping results fail"
      return -1
    }
    puts "\nPing results ($i): tp:<$tp> rp:<$rp> pl:<$pl>"
    if {$tp!=5 || $rp!=5 || $pl!=0} {
      set gaSet(fail) "Ping results: $rp packets received, $pl% packet loss"
      set ret -1 
      after 3000      
    } else {
      set ret 0
      break
    }
  }
  
  ## shutdown to wifi-client for release the REF unit's MAC table
  Send $com "shutdown\r" client
  
  return $ret
}  
# ***************************************************************************
# Halow_WiFi_ShowStatus
# ***************************************************************************
proc Halow_WiFi_ShowStatus {} {
   global buffer gaSet
  puts "\n[MyTime] Halow_WiFi_ShowStatus "; update
  set com $gaSet(comDut)
  
  #set ret [Login]
  #if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Show wifi-client status fail"
  for {set i 1} {$i<=10} {incr i} {
    if {$gaSet(act)==0} {return -2}
    #Login
    Status "Show wifi-client status ($i)"
    set ret [Send $com "exit all\r" -1p]
    if {$ret!=0} {return $ret}
    set ret [Send $com "config port wifi-client\r" client]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show status\r" client]
    if {$ret!=0} {return $ret}
    set res [regexp {Admin Status[\s\:]+(\w+)\s} $buffer ma as]
    if {$res==0} {
      set gaSet(fail) "Read Admin Status fail"
      return -1
    }
    set ret -1
    set res [regexp {Operational Status[\s\:]+(\w+)\s} $buffer ma os]
    if {$res==0} {
      set gaSet(fail) "Read Operational Status fail"
      return -1
    }
    puts "Admin Status: <$as> Operational Status: <$os>"
    
    # set ret [Login2Linux]
    # if {$ret==0} {
      # Send $com "\r\r" "localhost"
      # Send $com "iw dev wlan0 scan\r" "stam"
      # Send $com "exit\r\r" "stam" 1
    # }
    
    if {$as=="Enabled" && $os=="Connected"} {
      set ret 0
      break
    }
    
    after 5000
  }  
  if {$ret=="-1"} {
    set gaSet(fail) "Admin: $as, Operational: $os"
  }
  
  return $ret
}
# ***************************************************************************
# TpmCheck
# ***************************************************************************
proc TpmCheck {} {
  global buffer gaSet
  puts "\n[MyTime] Tpm Check"; update
  set com $gaSet(comDut)
  
  if {$gaSet(manualCSL)=="0"} {
    # set ret [RetriveIdTraceData  $gaSet(1.barcode1) CSLByBarcode]
    foreach {ret resTxt} [::RLWS::Get_CSL $gaSet(1.barcode1)] {}
  } else {
    # set ret [dict set di CSL $gaSet(manualCSL)]
    set resTxt $gaSet(manualCSL)
  }
    
  # set ret [RetriveIdTraceData $gaSet(1.barcode1) CSLByBarcode]
  puts "TpmCheck CSL ret:<$ret> resTxt:<$resTxt>"
  if {$ret=="0"} {
    # set csl [dict get $ret CSL]
    set csl $resTxt
    #AddToPairLog $gaSet(pair) "CSL: $csl"
  } else {
    # set gaSet(fail) "Fail to get CSL for $gaSet(1.barcode1)"
    set gaSet(fail) $resTxt
    return -1
  }
  
  set ret [Send $com "\r" $gaSet(linuxPrompt) 1]
  set ret [Send $com "ls /dev/tpm0\r" $gaSet(linuxPrompt) 1]
  if {[string match {*\'/dev/tpm0\': No such file or directory*} $buffer] || \
      [string match {*/dev/tpm0: No such file or directory*} $buffer]} {
    set tmpExists 0
  } else {
    set tmpExists 1
  }
  AddToPairLog $gaSet(pair) "CSL: $csl, tpm0: $buffer"
  if {$csl < "F" && $tmpExists==1} {
    set gaSet(fail) "tpm0 exists when CSL=$csl"  
    set ret -1    
  } elseif {$csl >= "F" && $tmpExists==0} {
    set gaSet(fail) "tpm0 not exists when CSL=$csl"  
    set ret -1    
  } else {
    set ret 0
  }
  
  return $ret  
}  
# ***************************************************************************
# PowerProtection
# ***************************************************************************
proc PowerProtection {} {
  global buffer gaSet
  puts "\n[MyTime] PowerProtection"; update
  set com $gaSet(comDut)
  if {$gaSet(dutFam.ps)=="WDC"} {
    set volts [list 70 72 73]
  } elseif {$gaSet(dutFam.ps)=="12V"} {
    set volts [list 34 36 37]
  } elseif {$gaSet(dutFam.ps)=="D72V"} {
    set volts [list 72.5 73.5 75.0]; # 09:52 31/07/202475
  }
    
  foreach currShBe {notZero zero zero} volt $volts {
    set ret [IT6900_on_off script off "1 2"]
    if {$ret!="-1"} {
      ##set ret [IT6900_set script 30 2]
      set ret [IT6900_set script $volt 1]
    }  
    if {$ret!="-1"} {
      after 4000
      ##set ret [IT6900_on_off script on 2]
      set ret [IT6900_on_off script on 1]
    }  
    
    if {$ret!="-1"} {
      after 2000
      set ret [IT9600_current 0]
      puts "IT9600_current ret: $ret currShBe:<$currShBe>"
      if {$currShBe=="notZero"} {
        if {$ret==0} {
          set gaSet(fail) ""
          AddToPairLog $gaSet(pair) "Turn OFF Voltage Protection ${volt}VDC, PASS"
          set ret 0
        } else {
          set ret -1
          set gaSet(fail)  "UUT's Supply's current is 0"
          AddToPairLog $gaSet(pair) "Turn OFF Voltage Protection ${volt}VDC, FAIL"
          break
        }
      } elseif {$currShBe=="zero"} {
        if {$ret==0} {
          set gaSet(fail) "UUT's Supply's current isn't 0"
          set ret -1
          AddToPairLog $gaSet(pair) "Turn ON Voltage Protection ${volt}VDC, FAIL"
        } else {
          set ret 0
          set gaSet(fail)  ""
          AddToPairLog $gaSet(pair) "Turn ON Voltage Protection ${volt}VDC, PASS"
        }
      }
    } 
  }  
  return $ret
}


# ***************************************************************************
# VoltagePerf
# ***************************************************************************
proc VoltagePerf {} {
  global buffer gaSet
  puts "\n[MyTime] VoltagePerf"; update
  set com $gaSet(comDut)
  if {$gaSet(dutFam.ps)=="WDC"} {
    set voltL [list 20 48 60]
    set ps_l 1
  } elseif {$gaSet(dutFam.ps)=="12V" || $gaSet(dutFam.ps)=="ACEX"} {
    set voltL [list 24 30] ; # 14:35 24/07/2024 10 24 30
    set ps_l 1
  } elseif {$gaSet(dutFam.ps)=="DC"} {
    set voltL [list 48 60] ; # 14:35 24/07/2024 10 48 60
    set ps_l 1
  } elseif {$gaSet(dutFam.ps)=="D72V"} {
    set voltL [list 20 48 60 72]
    set ps_l "1 2"
  } elseif {$gaSet(dutFam.ps)=="FDC"} {
    set voltL [list 48 60] ; # 14:35 24/07/2024 10 48 60
    set ps_l 1
  }
  
  foreach volt $voltL {
    foreach ps $ps_l {
      if {$gaSet(dutFam.ps)=="D72V" && $ps==2 && ($volt==48 || $volt==60)} {
        set ret 0
        continue  
      }
      foreach i {1 2} {
        set ret [IT6900_on_off script off "1 2"]
        $gaSet(statBarShortTest) configure -text "PS=$ps ${volt}V i=$i"
        
        Status "PS=$ps, Voltage=${volt}VDC, attempt $i"
        set ret [IT6900_on_off script off $ps]
        puts "ret after IT6900_on_off script off $ps : $ret"
        if {$ret!="-1"} {
          set ret [IT6900_set script $volt $ps]
          puts "ret after IT6900_set script $volt $ps : $ret"
        }  
        if {$ret!="-1"} {
          after 4000
          set ret [IT6900_on_off script on $ps]
          puts "ret after IT6900_on_off script on $ps : $ret"
        }
        if {$ret!="-1"} {
          set ret [Login]
          puts "ret after Login: $ret"
          if {$ret==0} {
            AddToPairLog $gaSet(pair) "PS=$ps, Voltage=${volt}VDC, attempt $i PASS"
          }
        }
        if {$ret!=0} {return $ret}
      }
      if {$ret!=0} {return $ret}
    }
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# DryContactAlarmcheckGo
# ***************************************************************************
proc DryContactAlarmcheckGo {} {
  global buffer gaSet
  puts "\n[MyTime] DryContactAlarmcheckGo"; update
  set com $gaSet(comDut)
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}    
  
  set ret [DryContactGoConfig]
  if {$ret!=0} {return $ret}
  
  after 500
  
  foreach gr2st {0 1 0 1} gr1st {0 0 1 1} sb {11 01 10 00} {
    puts ""
    MuxSwitchBox 1 $gr1st
    MuxSwitchBox 2 $gr2st
    after 250
    Send $com "echo in > \$DC_IN1_DIR/direction\r" stam 0.2
    Send $com "echo in > \$DC_IN2_DIR/direction\r" stam 0.2
    Send $com "value1=\$(cat /sys/class/gpio/gpio\$DC_IN1/value)\r" stam 0.2
    Send $com "value2=\$(cat /sys/class/gpio/gpio\$DC_IN2/value)\r" stam 0.2
    Send $com "echo \"DC_IN_1:\$value1\"\r" stam 0.2
    set res [regexp {DC_IN_\d\:(\d) } $buffer ma val1]
    if !$res {
      set gaSet(fail) "Get value of DC_IN_1 fail"
      return -1
    }
    Send $com "echo \"DC_IN_2:\$value2\"\r" stam 0.2
    set res [regexp {DC_IN_\d\:(\d) } $buffer ma val2]
    if !$res {
      set gaSet(fail) "Get value of DC_IN_1 fail"
      return -1
    }
    set ibuf ${val2}${val1}
    
    puts "DryContactAlarmcheckGo buffer after gr2st:<$gr2st> gr1st:<$gr1st> ibuf:<$ibuf> sb:<$sb>"
    if [string match *$sb $ibuf] {
      #puts "$buffer match *$sb"
      set res 0
    } else {
      set gaSet(fail) "I/O Alarm is [string range $buffer 6 7]. Should be $sb"
      puts "$gaSet(fail)"
      set res -1
      break
    }
  }
  set ret [Send $com "\r\r" $gaSet(linuxPrompt) 1]
  set ret $res
  return $ret
} 

# ***************************************************************************
# DryContactGoConfig
# ***************************************************************************
proc DryContactGoConfig {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "cd / \r" stam 0.1
  set scr dry2inGo.sh
  puts "\n[MyTime]DryContactGoConfig $scr"
  
  set ret 0
  set id [open $scr r]
    while {[gets $id line]>=0} {
      if {[string length $line]>0} {
        Send $com "$line\r" stam 0.1
        if {[string match {*write error*} $buffer]} {
          set gaSet(fail) "\'write error\' during Config DryContact"
          set ret -1
          break
        }
      }
    }
  close $id
  if {$ret!=0} {
    return $ret
  }
  Send $com "\r" stam 0.25
  return $ret
}
# ***************************************************************************
# PowerOffOnPerf_login
# ***************************************************************************
proc PowerOffOnPerf_login {} {
  global gaSet buffer
  set com $gaSet(comDut)
  for {set i 1} {$i <=  5} {incr i} {
    Power all off
    Status "Power OFF $i"
    after 4000
    Power all on
    Status "Power ON $i"
    after 1000
    set ret [Login]
    puts "PowerOffOnPerf ret:<$ret>" ; update       
    if {$ret==0} {
      AddToPairLog $gaSet(pair) "OFF-ON attempt $i PASS"
    } else {
      set ret -1
      set gaSet(fail) "UUT doesn't respond after $i OFF-ON"
      break
    }
    
  }
  return $ret
}
