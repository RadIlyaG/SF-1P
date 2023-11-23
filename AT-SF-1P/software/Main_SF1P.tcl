# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam   
  
  set lTestsAllTests [list]
  set lTestNames [list]
#   set lDownloadTests [list BrdEeprom]
#   eval lappend lTestsAllTests $lDownloadTests
  
  ## 14:15 28/12/2022
  lappend lTestNames PowerOffOn
  
  ##08:06 23/11/2023
  ## lappend lTestNames UsbTree
  
  if [string match *.HL.*  $gaSet(DutInitName)] {
    ## HL option doesn't have MicroSD
  } else {
    if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC"} {
      ## no CD card Contact
    } else {  
      lappend lTestNames MicroSD  
    }
    
  }
  lappend lTestNames SOC_Flash_Memory SOC_i2C 
  
  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC"} {
    ## 15:52 18/10/2023 lappend lTestNames BrdEeprom
  }
  ## no BrdEeprom in SFP
  
  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC"} {
    ## no DRY Contact
  } else {  
    lappend lTestNames  DryContactAlarm 
  }
  lappend lTestNames   ID
  
  if {[package vcompare $gaSet(SWver) "5.0.1.229.5"] == "0"} {
    ## if gaSet(SWver) = "5.0.1.229.5", then vcompare = 0 
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      if {[string index $gaSet(dutFam.cell) 2]=="4"} {
        lappend lTestNames CellularModemL4
      } else {
        lappend lTestNames CellularModem
      } 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
      if {[string index $gaSet(dutFam.cell) 2]=="4"} {
        lappend lTestNames CellularDualModemL4
      } else {
        lappend lTestNames CellularDualModem
      }
    }
  } else {
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      if {[string index $gaSet(dutFam.cell) 2]=="4"} {
        lappend lTestNames CellularModem_SIM1 CellularModem_SIM2 ; #CellularModemL4_RadOS
      } else {
        lappend lTestNames CellularModem_SIM1 CellularModem_SIM2
      } 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
      if {[string index $gaSet(dutFam.cell) 2]=="4"} {
        lappend lTestNames CellularDualModemL4_RadOS
      } else {
        lappend lTestNames CellularModem_SIM1 CellularModem_SIM2 ; #CellularDualModem_RadOS
      }
    }
  }
  
  lappend lTestNames DataTransmissionConf DataTransmission
  
  if {$gaSet(dutFam.serPort)!="0"} {
    if {$gaSet(dutFam.serPort)=="1RS"} {
      ## dont check SerialPorts if only one Serial Port exists 
    } else {
      lappend lTestNames SerialPorts
    }  
  }
  
  if {$gaSet(dutFam.gps)!="0" && $gaSet(dutFam.lora)=="0"} {}
    ## test GPS if no LORA
    
    ## 07:49 10/07/2022  meantime we don't check lora
  if {$gaSet(dutFam.gps)!="0"} {
    lappend lTestNames GPS
  }
  
  if {$gaSet(dutFam.wifi)!="0"} {
    lappend lTestNames WiFi_2G  ; ## 16:12 29/06/2023 WiFi_5G
  }
  
  if {$gaSet(dutFam.lora)!="0"} {
    lappend lTestNames LoRa
  }
  
  if {$gaSet(dutFam.poe)!="0"} {
    lappend lTestNames POE
  }
  if {$gaSet(dutFam.plc)!="0"} {
    lappend lTestNames PLC
  }
  
  if {[string index $gaSet(dutFam.cell) 0] !=0} {
    lappend lTestNames LteLeds
  }
  lappend lTestNames  FrontPanelLeds 
  lappend lTestNames  Factory_Settings SSH
  if !$gaSet(demo) {
    lappend lTestNames Mac_BarCode
  }

  eval lappend lTestsAllTests $lTestNames
  
  set glTests ""
  set gaSet(TestMode) AllTests
  set lTests [set lTests$gaSet(TestMode)]
  
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }

  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}


# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
  AddToPairLog $gaSet(pair) "********* DUT start *********"
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    MuxMngIO nc
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n[MyTime] **** Test $numberedTest finish;  ret of $numberedTest is: $ret, fail:<$gaSet(fail)>\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }
  
  if {$ret==0} {
    AddToPairLog $gaSet(pair) ""
    AddToPairLog $gaSet(pair) "All tests pass"
  } 

  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"
  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom) fail:<$gaSet(fail)>"   
  return $ret
}
# ***************************************************************************
# UbootVersion
# ***************************************************************************
proc UbootVersion {run} {
  set ::sendSlow 1
  set ret [UbootCheckVersionRam]
  return $ret
}
# ***************************************************************************
# UsbMicroSD
# ***************************************************************************
proc UsbMicroSD {run} {
  global gaSet buffer
  set ::sendSlow 1
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *PCPE* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret==0} {
    set ret [UsbMicroSDcheck]
  }
  return $ret
}

# ***************************************************************************
# DryContactAlarm
# ***************************************************************************
proc DryContactAlarm {run} {
  global gaSet buffer
  set ::sendSlow 0
  MuxMngIO nc
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  set ret 0
  if {$ret==0} {
    set ret [DryContactAlarmcheck $gaSet(dutFam.dryCon)]
#     if {$gaSet(dutFam.dryCon)=="FULL"} {
#       set ret [DryContactAlarmcheckFull]
#     } elseif {$gaSet(dutFam.dryCon)=="GO"} {
#       set ret [DryContactAlarmcheckGo]
#     } 
  }
  return $ret
}

# ***************************************************************************
# BrdEeprom
# ***************************************************************************
proc BrdEeprom {run} {
  set ::sendSlow 0
  MuxMngIO nc
  set ret [BrdEepromPerf]   
  return $ret
}

# ***************************************************************************
# ID
# ***************************************************************************
proc ID {run} {
  global gaSet
  set ::sendSlow 0
  MuxMngIO nc
  set ret 0
  set ret [IDPerf ID]  
  if {$ret != 0} {return $ret}

  set ret [ReadWanLanStatus]
  if {$ret != 0} {return $ret}
  
  set ret [ReadBootParams]
  if {$ret != 0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DataTransmissionConf
# ***************************************************************************
proc DataTransmissionConf {run} {
  global gaSet
  set ::sendSlow 0
  Power all on
  MuxMngIO 6ToGen
     
  puts "[MyTime] RLEtxGen::PortsConfig -admStatus down"; update
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus down
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S" || $gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
    RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus down
  }
  after 2000
      
  set ret [DataTransmissionSetup]; ## linux 
  # 08:56 24/05/2022 set ret [DataTransmissionSetup_RadOS]
  if {$ret!=0} {return $ret}
  
  return $ret
} 
# ***************************************************************************
# DataTransmission
# ***************************************************************************
proc DataTransmission {run} {
  global gaSet
  set ::sendSlow 0
  MuxMngIO 6ToGen
  after 2000
  puts "[MyTime] RLEtxGen::PortsConfig -admStatus down"; update
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus down
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S" || $gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
    RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus down
  }
   
  InitEtxGen 1
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S" || $gaSet(dutFam.wanPorts) == "1SFP1UTP"} { 
    InitEtxGen 2
  }
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus up
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S" || $gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
    RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus up
  }
  
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  Etx204Start
  set ret [Wait "Data is running" 10 white]
  if {$ret!=0} {return $ret}
  set ret [Etx204Check]
  puts "\nAfter Etx204Check 10: ret:<$ret> fail:<$gaSet(fail)>"
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Data is running" 60 white]
  if {$ret!=0} {return $ret}  
  set ret [Etx204Check]
  puts "\nAfter Etx204Check 60: ret:<$ret> fail:<$gaSet(fail)>"
  if {$ret!=0} {return $ret}
  
  RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus down
  if {$gaSet(dutFam.wanPorts) == "4U2S" || $gaSet(dutFam.wanPorts) == "5U1S" || $gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
    RLEtxGen::PortsConfig $gaSet(idGen2) -updGen all -admStatus down
  }
 
  return $ret
} 


# ***************************************************************************
# SerialPorts
# ***************************************************************************
proc SerialPorts {run} {
  set ::sendSlow 1
  set ret [SerialPortsPerf]
  return $ret
}
# ***************************************************************************
# POE
# ***************************************************************************
proc POE {run} {
  set ::sendSlow 0
  set ret [PoePerf]
  MuxMngIO nc    
  return $ret
}
# ***************************************************************************
# GPS
# ***************************************************************************
proc GPS {run} {
  set ::sendSlow 0
  MuxMngIO nc
  set ret [GpsPerf]
  return $ret
}


# ***************************************************************************
# Factory_Settings
# ***************************************************************************
proc Factory_Settings {run} {
  set ::sendSlow 0
  set ret [ReadImei]
  if {$ret!=0} {return $ret}
  set ret [FactorySettingsPerf]
  Wait "Wait for reset" 30
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  set ::sendSlow 0
  global gaSet  
  puts "Mac_BarCode"
  set pair 1
  mparray gaSet *mac*
  mparray gaSet *barcode*
  mparray gaSet *imei*
  if {$gaSet(dutFam.cell)!=0} {   
    if {[llength [array get gaSet *imei*]]==0} {
      set gaSet(fail) "No IMEI was read" 
      #return -1
      set ret [ReadImei]
      if {$ret!=0} {return $ret}
    }
  }
    
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [IDPerf readMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  
  set ret [RegBC]   
  if {$ret!=0} {return $ret}
  
   
  set ret [ImeiSQliteAddLine]
  return $ret
}

# ***************************************************************************
# WiFi2.4G   WiFi5G
# ***************************************************************************
proc WiFi_2G {run} {
  global gaSet
  set ::sendSlow 0
  Power all off
  after 4000
  Power all on 
  
  Wait "Wait for up" 15
  
  catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
  puts "FtpDeleteFile <$res>"
  
  set locWifiReport LocWifiReport_$gaSet(wifiNet).txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpUploadFile <$res>"
  regexp {result: (-?1) } $res ma ret
  
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 2.4 $locWifiReport]
  
  if {$ret==0} { 
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
  }

  return $ret
}
# ***************************************************************************
# WiFi5G  
# ***************************************************************************
proc WiFi_5G {run} {
  global gaSet
  set ::sendSlow 0
  Power all off
  after 4000
  Power all on   
  
  Wait "Wait for up" 15
  
  RLSound::Play information
  set txt "Connect Antenna to WiFi AUX. Verify no Antenna on WiFi MAIN"
  set ret [DialogBox -title "WiFi 5G Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "WiFi $baud fail"
    return -1 
  }
  
  #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
  #FtpDeleteFile [string tolower wifireport_$gaSet(wifiNet).txt]
  catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
  puts "FtpDeleteFile <$res>"
  set locWifiReport LocWifiReport_$gaSet(wifiNet).txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  #set ret [FtpUploadFile startMeasurement_$gaSet(wifiNet)]
  catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  regexp {result: (-?1) } $res ma ret
  
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 5 $locWifiReport]
  
  if {$ret==0} {
    #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
    #FtpDeleteFile [string tolower wifireport_$gaSet(wifiNet).txt]
	catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
  }
  
  return $ret
}
# ***************************************************************************
# PLC
# ***************************************************************************
proc PLC {run} {
  set ::sendSlow 0
  set ret [PlcPerf]
}
# ***************************************************************************
# LoRa
# ***************************************************************************
proc LoRa {run} {
  global gaSet
  set ::sendSlow 0
  MuxMngIO nc
  set ret [LoraModuleConf]
  if {$ret=="-1"} { 
    #set ret [LoraModuleConf]
  }
  if {$ret==0} { 
    set ret [LoraServerPolling]
    if {$ret==0} { 
      set ret [LoraGateWayMode "no shutdown"]
      if {$ret==0} { 
        set ret [ConfigLoraDev]
        if {$ret==0} {
          set ret [LoraPing LoraServerIP $gaSet(LoraServerIP)]
          if {$ret==0} {
            set ret [LoraPing ChirpStackIP $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))]
            if {$ret==0} {
            set ret [JoinLoraDev]
              puts "ret 1 after JoinLoraDev: $ret"; update
              if {$ret!=0} {
                #set ret [JoinLoraDev]
                #puts "ret 2 after JoinLoraDev: $ret"; update
              }  
              if {$ret==0} {
                set data [clock format [clock seconds] -format "%d%H%M%S"]
                set ret [LoraPerf  $data ] ;  # aabbccdd
                puts "ret after LoraPerf $data: $ret"; update
                if {$ret==0} {
                  #set ret [LoraPerf 11223344]
                }  
              }  
            } 
          } 
        }
      }
    }
  }
  set fail $gaSet(fail)
  if {$ret!=0 && $gaSet(LoraStayConnectedOnFail)==1} {
    ## do nothing
  } else {
    MuxMngIO nc
    #LoraGateWayMode "shutdown"
    LoraServerRelease
  }
  set gaSet(fail) $fail
  
  return $ret  
}
# ***************************************************************************
# LinuxLeds
# ***************************************************************************
proc LteLeds {run} {
  set ::sendSlow 0
  set ret [LinuxLedsPerf]
}
# ***************************************************************************
# BootLeds
# ***************************************************************************
proc FrontPanelLeds {run} {
  set ::sendSlow 0
  set ret [BootLedsPerf]
}
# ***************************************************************************
# FDbutton
# ***************************************************************************
proc FDbutton {run} {
  set ::sendSlow 0
  set ret [FDbuttonPerf]
}
# ***************************************************************************
# UsbTree
# ***************************************************************************
proc UsbTree {run} {
  global gaSet buffer
  set ::sendSlow 1
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *PCPE* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Boot]
  }
  if {$ret==0} {
    set ret [UsbStartTreePerform]
  }
  return $ret
}
# ***************************************************************************
# SOC_Flash_Memory
# ***************************************************************************
proc SOC_Flash_Memory {run} {
  global gaSet buffer
  set ::sendSlow 1
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *PCPE* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Boot]
  }
  if {$ret==0} {
    set ret [SocFlashMemPerform]
  }
  return $ret
}
# ***************************************************************************
# SOC_i2C
# ***************************************************************************
proc SOC_i2C {run} {
  global gaSet buffer
  set ::sendSlow 1
  set com $gaSet(comDut)
#   Send $com "\r" stam 0.25
#   Send $com "\r" stam 0.25
#   if {[string match *PCPE* $buffer]} {
#     set ret 0
#   } else {
#     set ret [PowerResetAndLogin2Boot]
#   }
  set ret [PowerResetAndLogin2Boot]
  if {$ret==0} {
    set ret [SocI2cPerform]
  }
  return $ret
}

# ***************************************************************************
# MicroSD
# ***************************************************************************
proc MicroSD {run} {
  set ::sendSlow 1
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *PCPE* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Boot]
  }
  if {$ret==0} {
    set ret [MicroSDPerform]
  }
  return $ret
}

# ***************************************************************************
# SSH
# ***************************************************************************
proc SSH {run} {
  global gaSet buffer
  set ::sendSlow 0
  MuxMngIO 6ToPc
  set pair 1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [IDPerf readMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  set ret [SshPerform]
  if {$ret=="-1"} {
    set txt "Set J21 to 1-2 (BADAS) and verify the SSH cable is connected"
    RLSound::Play information
    set res [DialogBox -title "SSH Test" -type "OK Cancel" -message $txt -icon images/info]
    if {$res=="Cancel"} {
      set ret -2
    } else {
      set ret [SshPerform]
    }
  }  
  if {$gaSet(dutFam.sf)=="ETX-1P_SFC" && $ret==0} {
    RLSound::Play information
    set txt "Remove the J21 JUMPER"
    DialogBox -title "SSH Test for Safaricom" -type "OK" -message $txt -icon images/info
  }
  return $ret
}
# ***************************************************************************
# CellularModem_SIM1
# ***************************************************************************
proc CellularModem_SIM1 {run} {
  global gaSet
  set ::sendSlow 0
  if {[package vcompare $gaSet(SWver) "5.0.3.33"] != "1"} {
    ## if gaSet(SWver) = "5.0.3.33", then vcompare = 0 
    ## if gaSet(SWver) < "5.0.3.33", then vcompare = -1 
    set ret [CellularLte_RadOS] 
    if {$ret!=0} {return -1}
    set ret [CellularModemPerf_RadOS lte lte-2 notL4] 
  } else {
    ## if gaSet(SWver) > "5.0.3.33", then vcompare = 1
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      set ret [CellularLte_RadOS_Sim12]
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12 1 2 notL4] 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
      set ret [CellularLte_RadOS_Sim12_Dual] 
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12_Dual 1 notL4]
    }   
  }  
  return $ret
} 
# ***************************************************************************
# CellularModem_SIM2
# ***************************************************************************
proc CellularModem_SIM2 {run} {
  global gaSet
  set ::sendSlow 0
  if {[package vcompare $gaSet(SWver) "5.0.3.33"] != "1"} {
    ## if gaSet(SWver) = "5.0.3.33", then vcompare = 0 
    ## if gaSet(SWver) < "5.0.3.33", then vcompare = -1 
    set ret [CellularLte_RadOS] 
    if {$ret!=0} {return -1}
    set ret [CellularModemPerf_RadOS lte-2 lte notL4] 
  } else {
    ## if gaSet(SWver) > "5.0.3.33", then vcompare = 1
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      set ret [CellularLte_RadOS_Sim12]
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12 2 1 notL4] 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
      set ret [CellularLte_RadOS_Sim12_Dual] 
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12_Dual 2 notL4] 
    }
  }
  return $ret
}
# ***************************************************************************
# PowerOffOn
# ***************************************************************************
proc PowerOffOn {run} {
  set ::sendSlow 0
  return [PowerOffOnPerf]
}  

# ***************************************************************************
# CellularModem
# ***************************************************************************
proc CellularModem {run} {
  MuxMngIO nc
  set ::sendSlow 0
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
