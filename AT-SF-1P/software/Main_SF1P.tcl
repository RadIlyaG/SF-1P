# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName) gaSet(testmode):$gaSet(testmode)\n"
  
  set ret [RetriveDutFam]
  if {$ret!=0} {
    set glTests [list] 
    set gaSet(startFrom) ""
    $gaGui(startFrom) configure -values $glTests
    return -1
  }
    
  set lTestsAllTests [list]
  set lTestNames [list]
  if {$gaSet(testmode) == "dataPwrOnOff"} {
    lappend lTestNames DataPwrOnOff  
  } else {
    if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
      lappend lTestNames FDbutton_on_start
    }
   
    if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
      # 16:01 22/12/2024 lappend lTestNames PowerOffOn
      ## no PowerOffOn for ETX-1p
    } else {
      if {$gaSet(it6900.1) == "" && $gaSet(it6900.2) == ""} {
        #11:08 22/09/2024
        #lappend lTestNames PowerOffOn
        set glTests [list] 
        set gaSet(startFrom) ""
        $gaGui(startFrom) configure -values $glTests
        set gaSet(fail) "No Programmable Power Supply connected"
        Status $gaSet(fail) red
        return -2
      } else {
        lappend lTestNames Voltage
      }
    }
     
    if $gaSet(showBoot) {
      if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
        ## no CD card Contact
      } else {  
        lappend lTestNames MicroSD  
      }
      lappend lTestNames SOC_Flash_Memory SOC_i2C 
    }
    
    if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
      ## 15:52 18/10/2023 lappend lTestNames BrdEeprom
    }
    ## no BrdEeprom in SFP
    
    if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
      ## no DRY Contact
    } else {  
      if {$gaSet(dutFam.dryCon)=="FULL"} {
        lappend lTestNames DryContactAlarm 
      } elseif {$gaSet(dutFam.dryCon)=="GO"} {
        lappend lTestNames DryContactAlarmGo 
      }
    }
    lappend lTestNames   ID
    
    if [llength $gaSet(unknownFieldsL)] {
      foreach tst $gaSet(unknownFieldsL) {
        lappend lTestNames $tst 
      }  
    }
    
    if [string match *.HL.*  $gaSet(DutInitName)] {
      lappend lTestNames HL_Security
    }
    if [string match *.WH.*  $gaSet(DutInitName)] {
      lappend lTestNames Halow_WiFi
    }
    
    if {[package vcompare $gaSet(SWver) "5.0.1.229.5"] == "0"} {
      ## if gaSet(SWver) = "5.0.1.229.5", then vcompare = 0 
      if {[string index $gaSet(dutFam.cell) 0]=="1"} {
        if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
          lappend lTestNames CellularModemL4
        } else {
          lappend lTestNames CellularModem
        } 
      } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
        if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
          lappend lTestNames CellularDualModemL4
        } else {
          lappend lTestNames CellularDualModem
        }
      }
    } else {
      if {[string index $gaSet(dutFam.cell) 0]!="0"} {
        lappend lTestNames CellularModem_SIM1 CellularModem_SIM2
      }
      
      ## 08:33 15/01/2024
      # if {[string index $gaSet(dutFam.cell) 0]=="1"} {
        # if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
          # # single L4
          # lappend lTestNames CellularModem_SIM1 CellularModem_SIM2 ; #CellularModemL4_RadOS
        # } else {
          # # single not L4
          # lappend lTestNames CellularModem_SIM1 CellularModem_SIM2
        # } 
      # } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
        # if {[string range $gaSet(dutFam.cell) 1 end]=="L4"} {
          # # double L4
          # # 08:55 14/01/2024 lappend lTestNames CellularDualModemL4_RadOS
          # lappend lTestNames CellularModem_SIM1 CellularModem_SIM2
        # } else {
          # # double not L4
          # lappend lTestNames CellularModem_SIM1 CellularModem_SIM2 ; #CellularDualModem_RadOS
        # }
      # }
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
    
    if {$gaSet(dutFam.wifi)!="0" &&  ![string match *.WH.*  $gaSet(DutInitName)]} {
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
    
    if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
      lappend lTestNames Certificate  
      ## lappend lTestNames DigitalSerialNumber  ; # done in Factory_Settings
    }
    if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R" && [package vcompare $gaSet(SWver) "6.3.0.81"] == "0"} {
      lappend lTestNames Install_SW_update  
    }
    
    if {[string index $gaSet(dutFam.cell) 0] !=0} {
      lappend lTestNames LteLeds
    }
    if $gaSet(showBoot) {
      lappend lTestNames FrontPanelLeds 
    } else {
      if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
        ## we did it at start
      } else {
        lappend lTestNames FDbutton
      }
    }
    lappend lTestNames Factory_Settings ; # 08:14 27/02/2025 SSH
    if !$gaSet(demo) {
      lappend lTestNames Mac_BarCode
    }
    if {$gaSet(DefaultCF)!="0"} {
      lappend lTestNames LoadUserDefaultFile CheckUserDefaultFile
    }
    # if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R" && [package vcompare $gaSet(SWver) "6.3.0.81"] == "0"} {
      # lappend lTestNames Install_SW_update  
    # }
    
    if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
      lappend lTestNames Check_Certificate_Linux
    }
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
  
  return 0
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
    if {[llength [info commands $testName]]==0} {
      set gaSet(fail) "No Test defined for $testName"
      set ret -1
    } else {
      set ret [$testName 1]
    }
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
  set ::sendSlow 1
  MuxMngIO nc
  set ret 0
  set ret [IDPerf ID]  
  if {$ret != 0} {return $ret}

  set ret [ReadWanLanStatus]
  if {$ret != 0} {return $ret}
  
  if $gaSet(showBoot) {
    set ret [ReadBootParams]
    if {$ret != 0} {return $ret}
  }
  
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
  
  if {$gaSet(testmode) == "dataPwrOnOff"} {
    set min $gaSet(PowerOnOff.dur)
  } else {
    set min 1
  }
  set ret [Wait "Data is running" [expr {60 * $min}] white]
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
  global gaSet
  set ::sendSlow 1
  
  if {$gaSet(dutFam.serPort)=="2RSM" || $gaSet(dutFam.serPort)=="2RMI"} {
    set comL [list]
    foreach val [registry values HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM ] {
      lappend comL [registry get HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM $val]    
    }
    if {[lsearch $comL COM$gaSet(comSer485)]=="-1"} {
       set gaSet(fail) "COM$gaSet(comSer485) doesn't exist on the PC"
       return -3
    }
  
    if [catch {open \\\\.\\com$gaSet(comSer485) RDWR} handle] {
      set gaSet(fail) "Can't open COM-$gaSet(comSer485)"
      return -3
    } else {
      after 1000
      catch {close $handle} 
    }
    set ret [RLCom::Open $gaSet(comSer485) 115200 8 NONE 1]
  } else {
    set ret 0
  }
  if {$ret==0} {
    set ret [SerialPortsPerf]
    catch {RLCom::Close $gaSet(comSer485)}
  }
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
  global gaSet
  set ::sendSlow 0
  set ret [Cert_checkLinux]
  if {$ret!=0} {return -1}
  
  set ret [ReadImei]
  if {$ret!=0} {
    after 10000
    set ret [ReadImei]
    if {$ret!=0} {return $ret}
  }
  if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
    AddToAttLog "ID Number: $gaSet(1.barcode1)"
    set ret [ReadIccid]
    if {$ret!=0} {return $ret}
    set ret [Cert_GetLoraGateway]
    if {$ret!=0} {return $ret}
    puts "Factory_Settings $gaSet(1.barcode1) ::iccId:$::iccId ::loraGatewayId:$::loraGatewayId"
    foreach {ret resTxt} [::RLWS::Update_SimID_LoraGW $gaSet(1.barcode1) $::iccId $::loraGatewayId] {}
    if {$ret!=0} {
      set gaSet(fail) $resTxt
      return $ret
    }
    set ret [DigitalSerialNumber $run]
    if {$ret!=0} {return $ret}
  }
  
  set ret [CheckSimOut]
  if [string match {*pulled out*} $gaSet(fail)] {
    RLSound::Play information
    if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
      set txt "Pull out SIM-2 and press OK"
    } else {
      set txt "Pull out SIM/s and press OK"
    }
    set res [DialogBox -title "SIM inside" -text $txt -type "Ok Stop" -icon /images/error]
    if {$res=="Stop"} {
      set ret -2
    } else {
      Power all off
      after 4000
      Power all on
      set ret [CheckSimOut]
    }    
  }
  if {$ret!=0} {return $ret}
  set ret [FactorySettingsPerf]
  if {$ret!=0} {return $ret}
  Wait "Wait for reset" 30
  set ret [Login]
  if {$ret!=0} {return $ret}
  set ret [Cert_checkLinux]
  if {$ret!=0} {return -1}
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
  
  set ret [FactorySettingsPerf]   
  if {$ret!=0} {return $ret}
  
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
  #Power all off
  #after 4000
  Power all on 
  
  # set rad_sftp = 1to use RAD's sftp site as place to put start... and wifiReport..
  # else, to use Syncthing, set it 0
  set ::rad_sftp 1
  
  if ![file exists c:/ate_wifi_folder] {
    file mkdir c:/ate_wifi_folder
    after 1000  
  }
  
  #Wait "Wait for up" 15
  
  # 14:33 05/01/2026
  if $::rad_sftp {
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet) wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
    if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
      set gaSet(fail) "Unable to connect to ftp.rad.co.il"
      return -1
    }
  } else {
    catch {file delete -force c:/ate_wifi_folder/startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).txt} res
    puts "ST DeleteFile <$res>"
	
	## delete sync-conflict- file
	foreach  rep [glob -nocomplain c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).sy*.txt ] {
		catch {file delete -force $rep} res
		puts "ST DeleteFile $rep <$res>"
	}
  }
  
  set locWifiReport LocWifiReport_$gaSet(wifiNet).txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  # 14:34 05/01/2026
  if $::rad_sftp {
    catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpUploadFile <$res>"
    if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
      set gaSet(fail) "Unable to connect to ftp.rad.co.il"
      return -1
    }
    regexp {result: (-?1) } $res ma ret
  } else {
    catch {file copy -force startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/} res
  }
  
  set ret [Login] ; #[Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 2.4 $locWifiReport]
  
  if {$ret==0} { 
    # 14:34 05/01/2026
    if $::rad_sftp {
      catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet) wifireport_$gaSet(wifiNet).txt} res
      puts "FtpDeleteFile <$res>"
      if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
        set gaSet(fail) "Unable to connect to ftp.rad.co.il"
        return -1
      }
    } else {
      catch {file delete -force c:/ate_wifi_folder/startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).txt} res
      puts "ST DeleteFile <$res>"
	  
	  ## delete sync-conflict- file
	  foreach  rep [glob -nocomplain c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).sy*.txt ] {
		catch {file delete -force $rep} res
		puts "ST DeleteFile $rep <$res>"
	  }
    }
  
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
  
  # 15:22 05/01/2026
  if $::rad_sftp {
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet) wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
  } else {  
    catch {file delete -force c:/ate_wifi_folder/startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).txt} res
    puts "ST DeleteFile <$res>"
  }
  
  set locWifiReport LocWifiReport_$gaSet(wifiNet).txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  # 15:22 05/01/2026
  if $::rad_sftp {
    catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpCopyFile <$res>"
    regexp {result: (-?1) } $res ma ret
  } else {
    catch {file copy -force startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/} res
    puts "ST CopyFile <$res>"
  }
  
  set ret [Login] ; #[Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 5 $locWifiReport]
  
  if {$ret==0} {
    # 15:22 05/01/2026
    if $::rad_sftp {
	    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet) wifireport_$gaSet(wifiNet).txt} res
      puts "FtpDeleteFile <$res>"
    } else {
      catch {file delete -force c:/ate_wifi_folder/startMeasurement_$gaSet(wifiNet) c:/ate_wifi_folder/wifiReport_$gaSet(wifiNet).txt} res
      puts "ST DeleteFile <$res>"
    }
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
    # 14:24 26/11/2024 ChirpStackDeleteGateway $gaSet(ChirpStackIPGW)
    # after 1000
    ChirpStackAddGateway $gaSet(ChirpStackIPGW)  
    ChirpStackv4_AddGateway  $gaSet(ChirpStackIPGW) 
    set ret [LoraServerPolling]
    if {$ret==0} { 
      set ret 0 ; #LoraGateWayMode "no shutdown"
      if {$ret==0} { 
        set ret [ConfigLoraDev]
        if {$ret==0} {
          set ret [LoraPing LoraServerIP $gaSet(LoraServerIP)]
          if {$ret==0} {
            set ret [LoraPing ChirpStackIP $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))]
            if {$ret==0} {
            set ret [JoinLoraDev]
              puts "ret 1 after JoinLoraDev: $ret"; update
              AddToPairLog $gaSet(pair) "ret 1 after JoinLoraDev: $ret"
              if {$ret!=0} {
                set ret [LoraModuleConf]
                if {$ret==0} {
                  # no need add GW sinse after first join the GW exists
                  # ChirpStackAddGateway $gaSet(ChirpStackIPGW)  
                  set ret [Wait "Wait before second Join" 15 white]
                  if {$ret==0} {
                    set ret [JoinLoraDev]
                    puts "ret 2 after JoinLoraDev: $ret"; update
                    AddToPairLog $gaSet(pair) "ret 2 after JoinLoraDev: $ret"
                    set rr [CheckDockerPS]
                    puts "ret of CheckDockerPS: $rr"
                  }
                }
              }  
              if {$ret==0} {
                Wait "Wait after join" 5 white
                set data [clock format [clock seconds] -format "%d%H%M%S"]
                
                ## to avoid problems woth leading 0 I change by 9
                ## 03121234 -> 93121234
                if {[string index $data 0]==0} {
                  set data 9[string range $data 1 end]
                }
                set ret [LoraPerf  $data]
                puts "ret after LoraPerf $data: $ret"; update
                AddToPairLog $gaSet(pair) "ret 1 after LoraPerf: $ret"
                if {$ret!=0} {
                  Wait "Wait after LoraPerf" 5 white
                  set ret [LoraPerf  $data]
                  puts "ret after LoraPerf $data: $ret"; update
                  AddToPairLog $gaSet(pair) "ret 2 after LoraPerf: $ret"
                } 
                if {$ret==0} {
                  #set ret [LoraPerf 11223344]
                  ChirpStackDeleteGateway $gaSet(ChirpStackIPGW)  
                  ChirpStackv4_DeleteGateway $gaSet(ChirpStackIPGW)
                }  
              }  
            } 
          } 
        }
      }
    }
    ChirpStackDeleteGateway $gaSet(ChirpStackIPGW) 
    ChirpStackv4_DeleteGateway $gaSet(ChirpStackIPGW)    
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
  global gaSet
  set ::sendSlow 0
  set ret [LinuxLedsPerf]
  if {$ret==0} {
    if {$gaSet(dutFam.box)=="ETX-1P"} {
      set txt "Connect Antenna to LTE AUX."
      Power all off
    }
    if {$gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
      append txt " Remove SIM-1 and SIM-2. Insert AT\&T SIM into slot-1"
    } else {
      append txt " Remove SIM-1 and SIM-2"
    }
    RLSound::Play information
    set res [DialogBox -title "LTE AUX and SIM" -type "Ok Cancel" \
          -message $txt -icon images/info]
    Power all on      
    if {$res=="Cancel"} {
      set gaSet(fail) "User stop" 
      set ret -2
    } elseif {$res=="Ok"}  {
      set ret 0
    }
  }
  return $ret
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
  set ret [FDbuttonPerf ""]
}
# ***************************************************************************
# FDbutton_on_start
# ***************************************************************************
proc FDbutton_on_start {run} {
  set ::sendSlow 0
  set ret [FDbuttonPerf "on_start"]
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
  if {[string match *.HL.*  $gaSet(DutInitName)] && $gaSet(mainHW)<"0.6"} {
    AddToPairLog $gaSet(pair) "HL: mainHW:$gaSet(mainHW), no MicroSD Test"
    return 0
  }  
  
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
    if $gaSet(showBoot) {
      set txt "Set J21 to 1-2 (BADAS) and verify the SSH cable is connected"
      RLSound::Play information
      set res [DialogBox -title "SSH Test" -type "OK Cancel" -message $txt -icon images/info]
    } else {
      set res OK
    }
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
    
    ## 08:21 26/02/2024
    # if [NoFti_Cellular] {
      # return -1
    # }
    
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      set ret [CellularLte_RadOS_Sim12]
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12 1 2] 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
      set ret [CellularLte_RadOS_Sim12_Dual] 
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12_Dual 1]
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
    
    ## 08:21 26/02/2024
    # if [NoFti_Cellular] {
      # return -1
    # }
    
    if {[string index $gaSet(dutFam.cell) 0]=="1"} {
      set ret [CellularLte_RadOS_Sim12]
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12 2 1] 
    } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
    
      ## 07:15 14/12/2023
      ## 08:51 14/01/2024 set gaSet(fail) "Bad FTI for this option" 
      ## 08:51 14/01/2024 return -1
      
      set ret [CellularLte_RadOS_Sim12_Dual] 
      if {$ret!=0} {return -1}
      set ret [CellularModemPerf_RadOS_Sim12_Dual 2] 
    }
  }
  return $ret
}
# ***************************************************************************
# PowerOffOn
# ***************************************************************************
proc PowerOffOn {run} {
  set ::sendSlow 0
  global gaSet
  if {$gaSet(PowerOffOnUntil)=="first_steps"} {
    return [PowerOffOnPerf]
  } elseif {$gaSet(PowerOffOnUntil)=="login"} {
    return [PowerOffOnPerf_login]
  }
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

# ***************************************************************************
# HL_Security
# ***************************************************************************
proc HL_Security {run} {
  global gaSet
  set ::sendSlow 0
  #set gaSet(fail) "No Test Instruction"
  #return -1
  set ret [HL_SecurityPerf]
  return $ret
}
# ***************************************************************************
# Halow_WiFi
# ***************************************************************************
proc Halow_WiFi {run} {
  global gaSet
  set ::sendSlow 0
  #set gaSet(fail) "No Test Instruction"
  #return -1
  set ret [Halow_WiFiPerf]
  return $ret
}
# ***************************************************************************
# Voltage
# ***************************************************************************
proc Voltage {run} {
  global gaSet
  set ::sendSlow 0
  set ret -1
  
  set ret [IT9600_current 1]
  
  if {$ret==0} {
    if {$gaSet(dutFam.ps)=="WDC" || $gaSet(dutFam.ps)=="12V" || $gaSet(dutFam.ps)=="D72V" || $gaSet(dutFam.ps)=="D60V"} {
      set ret [PowerProtection]
    } else {
      set ret 0
    }
  }
  
  if {$ret==0} {
    set ret [VoltagePerf]
    $gaSet(statBarShortTest) configure -text ""
  }
  
  # if {$ret==0} {
    # if {$gaSet(dutFam.ps)=="WDC" || $gaSet(dutFam.ps)=="12V"} {
      # set ret [PowerProtection]
    # } else {
      # set ret 0
    # }
  # }
  if {$ret==0} {
    global buffer gaSet
    set ret [IT9600_normalVoltage 1 1]
    if {$ret!="-1"} {
      set ret 0
    }
    # set volt [Retrive_normalVoltage]
    # set ret [IT6900_on_off script off]
    # if {$ret!="-1"} {
      # set ret [IT6900_set script $volt]
    # }  
    # if {$ret!="-1"} {
      # after 2000
      # set ret [IT6900_on_off script on]
      # after 2000
    # }
  }
  
  return $ret
}
# ***************************************************************************
# DryContactAlarmGo
# ***************************************************************************
proc DryContactAlarmGo {run} {
  global gaSet buffer
  set ::sendSlow 0
  MuxMngIO nc
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  set ret 0
  if {$ret==0} {
    set ret [DryContactAlarmcheckGo]
  }
  return $ret
}
# ***************************************************************************
# Certificate
# ***************************************************************************
proc Certificate {run} {
  global gaSet buffer
  set ::sendSlow 1
  MuxMngIO nc
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  set ret 0
  if {$ret==0} {
    #set ret [CellularLte_RadOS_Sim12]
  }
  if {$ret==0} {
    set ret [Dns_config]
  }
  if {$ret==0} {
    set ret [Cert_GetLoraGateway]
    puts "Ret after Cert_GetLoraGatewa ret:<$ret> "
    if {$ret=="-1"} {
      after 10000
      set ret [Cert_GetLoraGateway]
    }
  }
  if {$ret==0} {
    set ret [DateTime_set]
  }
  if {$ret==0} {
    set ret [Cert_createRSA]
  }
  if {$ret==0} {
    set ret [Cert_cryptoCa]
  }
  if {$ret==0} {
    set ret [Cert_AuthenticateCa]
  }
  
  if {$ret==0} {
    set ret [Cert_GetPassword]
  }
  if {$ret==0} {
    set ret [Cert_EnrollCerificate]
  }
  
  return $ret
}

# ***************************************************************************
# DigitalSerialNumber
# ***************************************************************************
proc DigitalSerialNumber {run} {
  global gaSet buffer
  set ::sendSlow 0
  MuxMngIO nc
  
  foreach {ret resTxt} [::RLWS::Get_DigitalSerialCode $gaSet(1.barcode1)] {}
  if {$ret==0} {
    AddToPairLog $gaSet(pair) "DigitalSerial: $resTxt" 
    AddToAttLog "DigitalSerial: $resTxt" 
  } else {
    set gaSet(fail) $resTxt
  }
  return $ret
}
# ***************************************************************************
# DataPwrOnOff
# ***************************************************************************
proc DataPwrOnOff {run} {
  global gaSet buffer
  set allPass 0
  set allFail 0
  set fail ""
  for {set i 1} {$i<=$gaSet(PowerOnOff.qty)} {incr i} {
    if {$gaSet(act)==0} {return -2}
    $gaSet(statBarShortTest) configure -text "${i}/$gaSet(PowerOnOff.qty) Pass=$allPass Fail=$allFail"
    
    puts "\n[MyTime] DataPwrOnOff $i"
    Power all off
    after 5000
    Power all on
  
    set ret [DataTransmissionConf $i]
    if {$ret!=0} {
      AddToPairLog $gaSet(pair) "Cycle $i. Ret of Conf:<$ret>"
    }
    if {$ret==0} {
      set ret [DataTransmission $i]
      AddToPairLog $gaSet(pair) "Cycle $i. Ret of Data Transmission:<$ret>"
      if {$ret==0} {
        incr allPass
      } else {
        incr allFail
        set fail $gaSet(fail)
        AddToPairLog $gaSet(pair) $fail
      }
    } else {
      incr allFail 
      set fail $gaSet(fail)
      AddToPairLog $gaSet(pair) $fail
    }    
  }
  set gaSet(fail) $fail
  $gaSet(statBarShortTest) configure -text "Pass=$allPass Fail=$allFail"
  AddToPairLog $gaSet(pair) "\nTotal cycles: $gaSet(PowerOnOff.qty). Passes: $allPass, Fails: $allFail" 
  
  if {$allFail==0} {
    set ret 0
  } else {
    set ret -1
  }
  return $ret
}
# ***************************************************************************
# LoadUserDefaultFile
# ***************************************************************************
proc LoadUserDefaultFile {run} {
  global gaSet  
  Power all on
  #set ret [FactorySettingsPerf]
  #if {$ret!=0} {return $ret}
  Wait "Wait for up" 30
  set ::sendSlow 1
  set ret [LoadDefConf]
  return $ret
}
# ***************************************************************************
# CheckUserDefaultFile
# ***************************************************************************
proc CheckUserDefaultFile {run} {
  global gaSet 
  set ::sendSlow 1
  Power all on
  set ret [CheckUserDefaultFilePerf]
  return $ret 
}

# ***************************************************************************
# Install_SW_update
# ***************************************************************************
proc Install_SW_update {run} {
  global gaSet 
  set ::sendSlow 1
  MuxMngIO 6ToPc
  Power all on
  set ret [Install_SW_update_Perf]
  if {$ret=="0" || $ret=="-2"} {
    return $ret
  } else {
    ## do not include SW_update fail in statistics
    return "-4"
  }
}
# ***************************************************************************
# Check_Certificate_Linux
# ***************************************************************************
proc Check_Certificate_Linux {run} {
  global gaSet 
  set ::sendSlow 1
  MuxMngIO nc
  Power all on
  set ret [Cert_checkLinux]
  return $ret
  
}