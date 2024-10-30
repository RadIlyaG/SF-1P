##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  
  set ret2 [OpenEtxGen]
    
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2 " ; update
  if {$ret1!=0 || $ret2!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  ##set ret [RLSerial::Open $gaSet(comDut) 115200 n 8 1]
  set ret [RLCom::Open $gaSet(comDut) 115200 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comDut) fail"
  }
  if {$gaSet(comDut) != $gaSet(comSer1)} {
    set ret [RLCom::Open $gaSet(comSer1) 115200 8 NONE 1]
    if {$ret!=0} {
      set gaSet(fail) "Open COM $gaSet(comSer1) fail"
    }
  }
#   set ret [RLCom::Open $gaSet(comSer2) 9600 8 NONE 1]
#   if {$ret!=0} {
#     set gaSet(fail) "Open COM $gaSet(comSer2) fail"
#   }
  set ret [RLCom::Open $gaSet(comSer485) 115200 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comSer485) fail"
  }
  
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  ##catch {RLSerial::Close $gaSet(comDut)}
  catch {RLCom::Close $gaSet(comDut)}
  catch {RLCom::Close $gaSet(comSer1)}
#   catch {RLCom::Close $gaSet(comSer2)}
  catch {RLCom::Close $gaSet(comSer485)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
#   catch {RLEtxGen::CloseAll}
  catch {RLEtxGen::Close $gaSet(idGen1)}
  catch {RLEtxGen::Close $gaSet(idGen2)}
  #catch {RLScotty::SnmpCloseAllTrap}
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=14} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idPwr$rb) [RLUsbPio::Open $rb RBA $channel]
  }
  
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
#   set gaSet(idAI)       [RLUsbPio::Open 4 PORT $channel]
#   RLUsbPio::SetConfig $gaSet(idAI) 11111111 ; # all 8 pins are IN
  set gaSet(idPioDrContIn)  [RLUsbPio::Open 7 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idPioDrContIn) 11111111 ; # all 8 pins are IN
  set gaSet(idPioDrContOut) [RLUsbPio::Open 8 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idPioDrContOut) 00000000 ; # all 8 pins are OUT
  
  set gaSet(idPioSwBox1)  [RLUsbPio::Open 1 SPDT $channel]
  set gaSet(idPioSwBox2)  [RLUsbPio::Open 2 SPDT $channel]
  
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2" {
	  catch {RLUsbPio::Close $gaSet(idPwr$rb)}
  }
#   catch {RLUsbPio::Close $gaSet(idAI)}
  catch {RLUsbPio::Close $gaSet(idPioDrContOut)}
  catch {RLUsbPio::Close $gaSet(idPioDrContIn)}
  catch {RLUsbMmux::Close $gaSet(idMuxMngIO)}
  
  catch {RLUsbMmux::Close $gaSet(idPioSwBox1)}
  catch {RLUsbMmux::Close $gaSet(idPioSwBox2)}
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  puts "SaveUutInit $fil"
  set id [open $fil w]
  puts $id "set gaSet(dbrUbootSWnum)       \"$gaSet(dbrUbootSWnum)\""
  puts $id "set gaSet(dbrUbootSWver)       \"$gaSet(dbrUbootSWver)\""
  puts $id "set gaSet(UbootSWpath)         \"$gaSet(UbootSWpath)\""
  
  puts $id "set gaSet(uutSWfrom)           \"$gaSet(uutSWfrom)\""
  puts $id "set gaSet(dbrSWnum)            \"$gaSet(dbrSWnum)\""
  puts $id "set gaSet(SWver)               \"$gaSet(SWver)\""
  puts $id "set gaSet(UutSWpath)           \"$gaSet(UutSWpath)\""
    
  puts $id "set gaSet(mainHW)              \"$gaSet(mainHW)\""
  puts $id "set gaSet(mainPcbId)           \"$gaSet(mainPcbId)\""
    
  puts $id "set gaSet(sub1HW)              \"$gaSet(sub1HW)\""
  puts $id "set gaSet(sub1PcbId)           \"$gaSet(sub1PcbId)\""
  
  puts $id "set gaSet(LXDpath)             \"$gaSet(LXDpath)\""
  
  puts $id "set gaSet(csl)                 \"$gaSet(csl)\""
  
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  
  puts $id "set gaSet(dbrBootSwNum)         \"$gaSet(dbrBootSwNum)\""
  puts $id "set gaSet(dbrBootSwVer)         \"$gaSet(dbrBootSwVer)\""
  
  if ![info exists gaSet(hwAdd)] {
    set gaSet(hwAdd) A
  }
  puts $id "set gaSet(hwAdd)                 \"$gaSet(hwAdd)\""
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  gaGui
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  foreach ps {1 2} {
    if ![info exists gaSet(it6900.$ps)] {
      set gaSet(it6900.$ps) ""
    }
    puts $id "set gaSet(it6900.$ps) \"$gaSet(it6900.$ps)\""    
  }  
  
  puts $id "set gaSet(showBoot) \"$gaSet(showBoot)\""
  close $id   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent {expected stamm} {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  
  ## replace a few empties by one empty
  regsub -all {[ ]+} $sent " " sent
  
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  if {$expected=="stamm"} {
    ##set cmd [list RLSerial::Send $com $sent]
    set cmd [list RLCom::Send $com $sent]
    foreach car [split $sent ""] {
      set asc [scan $car %c]
      #puts "car:$car asc:$asc" ; update
      if {[scan $car %c]=="13"} {
        append sentNew "\\r"
      } elseif {[scan $car %c]=="10"} {
        append sentNew "\\n"
      } else {
        append sentNew $car
      }
    }
    set sent $sentNew
  
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent"
    puts "send: ----------------------------------------\n"
    update
    return $ret
    
  }
  #set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  #set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  if $::sendSlow {
    set cmd [list RLCom::SendSlow $com $sent 20 buffer $expected $timeOut]
  } else {
    set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  }
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  set ::buff $buffer
  
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } else {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    #puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "\n[MyTime] Send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=<$expected>, buffer=<$buffer>"
    #puts "send: ----------------------------------------\n"
    update
  }
  
  #RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


#***************************************************************************
#** Wait
#***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    #set ret [Send $com \r stam $testEach]
    #set ret [RLSerial::Waitfor $com buffer stam $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      if [string match *$expd* $buffer] {
        set ret 0
      }
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:\"$expd\" ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
} 
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
#   return 0
  set ret 0
  switch -exact -- $ps {
    1   {set pioL 1}
    2   {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {set bit 1} 
	  off {set bit 0} 
  }
  foreach pio $pioL {      
    RLUsbPio::Set $gaSet(idPwr$pio) $bit
    if {$gaSet(it6900.$pio)!=""} {
      IT6900_on_off script $state "1 2"
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  puts "\nGuiPower $n $state"
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 - 5.1 - SE.1 {set portL [list 1]}
    1.2 - 2.2 - 3.2 - 4.2 - 5.2 - SE.2 {set portL [list 2]}      
    1 - 2 - 3 - 4 - 5 - SE - all       {set portL [list 1 2]}  
  }        
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $portL {
      set id [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$id>"
      RLUsbPio::Set $id $state
      RLUsbPio::Close $id
    }   
  }
  
  set ret [IT9600_normalVoltage 1 $state]
  # set volt [Retrive_normalVoltage]
  # if {$state=="0"} {
    # set ret [IT6900_on_off script off]
  # } elseif {$state=="1"} {
    # set ret [IT6900_set script $volt]
    # if {$ret!="-1"} {
      # after 2000
      # set ret [IT6900_on_off script on]
      # after 2000
    # }
  # }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  set logFileID [open $gaSet(log.$pair) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# AddToAttLog
# ***************************************************************************
proc AddToAttLog {line}  {
  global gaSet
  set log c:/logs/${gaSet(logTime)}-ID_ATT-$gaSet(1.barcode1).txt
  set logFileID [open $log a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# ShowLog 
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
#     exec notepad $gaSet(logFile.$gaSet(pair)) &
#   }
  if {[info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
    exec notepad $gaSet(log.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {} {
  global gaSet gaGui
  
  set gaSet(testmode) finalTests
  
  if ![info exists gaSet(logTime)] {
    set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
  }
  
  set gaSet(relDebMode) Release
  $gaGui(labRelDebMode) configure -text $gaSet(relDebMode) -bg SystemButtonFace
  
  Status "Please wait for retriving DBR's parameters"
  if {$gaSet(useExistBarcode) && [info exists gaSet(1.barcode1)]} {
    set barcode $gaSet(1.barcode1)
  } else {  
    set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  }
  # do it after GetSW set gaSet(useExistBarcode) 0
  
  if {$barcode==""} {
    set gaSet(fail) "Scan ID Barcode first"
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBoxRamzor -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  if {$gaSet(demo)==0} {
    set ret [MainEcoCheck $barcode]
    puts "ret of MainEcoCheck $barcode <$ret>"
    if {$ret!=0} {
      $gaGui(startFrom) configure -text "" -values [list]
      set gaSet(log.$gaSet(pair)) c:/logs/[clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"].txt
      AddToPairLog $gaSet(pair) $ret
      RLSound::Play information
      DialogBoxRamzor -type "OK" -icon /images/error -title "Unapproved changes" -message $ret
      Status ""
      return -2
    }
  }
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  #wm title . "$gaSet(pair) : "
  if $gaSet(demo) {
    wm title . "DEMO!!! $gaSet(pair)"
  } else {
    wm title . "$gaSet(pair) : "
  }
  after 500
  
  # if 1 {
  # if {![file exist $gaSet(javaLocation)]} {
    # set gaSet(fail) "Java application is missing"
    # return -1
  # }
  # catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  # set fileName MarkNam_$barcode.txt
  # after 1000
  # if ![file exists MarkNam_$barcode.txt] {
    # set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    # #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    # RLSound::Play fail
	  # Status "Test FAIL"  red
    # DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    # pack $gaGui(frFailStatus)  -anchor w
	  # $gaSet(runTime) configure -text ""
  	# return -1
  # }
  
  # set fileId [open "$fileName"]
    # seek $fileId 0
    # set dbrName [read $fileId]    
  # close $fileId
  # }
  
  set gaSet(1.traceId) ""
  set gaSet(1.useTraceId) 0
  set gaSet(1.barcode1) $barcode
  foreach {ret resTxt} [::RLWS::Get_OI4Barcode  $gaSet(1.barcode1)] {}
  if {$ret=="0"} {
    #  set dbrName [dict get $ret "item"]
    set dbrName $resTxt
  } else {
    set gaSet(fail) "Fail to get DBR Name for $gaSet(1.barcode1)"
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBoxRamzor -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set txt "[string trim $dbrName]"
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $dbrName .]
  
  puts "GetDbrName dbrName:<$dbrName>"
  puts "GetDbrName initName:<$initName>"
  set gaSet(DutFullName) $dbrName
  set gaSet(DutInitName) $initName.tcl
  
  #file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    #source uutInits/$gaSet(DutInitName)  
    #UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw} {
      puts "GetDbrName gaSet($v) does not exist"
      set gaSet($v) ??
    }
    foreach en {licEn} {
      set gaSet($v) 0
    } 
  } 
  if $gaSet(demo) {
    wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
  } else {
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  }
  pack forget $gaGui(frFailStatus)
  #Status ""
  update
  #BuildTests
  
  ## 08:38 20/05/2024
  set gaSet(1.barcode1) $barcode
  set gaSet(1.barcode1.IdMacLink) [IdMacLinkNoLink $barcode]
  
  set ret 0
  if 1 {
    set ret [GetDbrSW $barcode]
    set gaSet(useExistBarcode) 0
    puts "GetDbrName ret of GetDbrSW:$ret" ; update
    if {$ret!=0} {
      RLSound::Play fail
      Status "Test FAIL"  red
      DialogBoxRamzor -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
      pack $gaGui(frFailStatus)  -anchor w
      $gaSet(runTime) configure -text ""
      return $ret
    }  
  }
  puts ""
  
  #set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barcode.txt
  #AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
  #AddToPairLog $gaSet(pair) "UUT - $barcode"
  
  set ret [BuildTests]
  if {$ret==0} {
    set ret [IT9600_normalVoltage 1 1]
    if {$ret!="-1"} {
      set ret 0
    }
    puts "\nGetDbrName ret after IT9600_normalVoltage:<$ret>"
  }
  
  focus -force $gaGui(tbrun)
  if {$ret==0} {
    Status "Ready"
  }
  return $ret
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    if {[regsub -all {\.} $gaSet(DutFullName)  "/" a]!=0} {
      set gaSet(DutFullName) $a
    }
    
    #wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    if $gaSet(demo) {
      wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
    } else {
      wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    }
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}

# ***************************************************************************
# RetriveDutFam
## set gaSet(DutInitName) SF-1P.E1.DC.4U2S.2RSM.L1.G.LR2.2R.tcl
## set dutInitName  [regsub -all / SF-1V/E2/12V/4U1S/2RS/L1/G/L1 .].tcl
# RetriveDutFam $dutInitName
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  array unset gaSet dutFam.*
  #set gaSet(dutFam) NA 
  #set gaSet(dutBox) NA 
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "[MyTime] RetriveDutFam $dutInitName"
  set fieldsL [lrange [split $dutInitName .] 0 end-1] ; # remove tcl
  
  set idx [lsearch $fieldsL "HL"]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  regexp {([A-Z0-9\-\_]+)\.E?} $dutInitName ma gaSet(dutFam.sf)
  switch -exact -- $gaSet(dutFam.sf) {
    SF-1P - ETX-1P - SF-1P_ICE - ETX-1P_SFC - SF-1P_ANG {set gaSet(appPrompt) "-1p#"}
    VB-101V {set gaSet(appPrompt) "VB101V#"}
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.sf)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
    set gaSet(dutFam.box) "ETX-1P"
    if ![regexp {1P\.([A-Z0-9]+)\.} $dutInitName ma gaSet(dutFam.ps)] {
      if ![regexp {1P_SFC\.([A-Z0-9]+)\.} $dutInitName ma gaSet(dutFam.ps)] {
        regexp {1P_A\.([A-Z0-9]+)\.} $dutInitName ma gaSet(dutFam.ps)
      }
    }
  } else {
    regexp {P[_A-Z]*\.(E\d)\.} $dutInitName ma gaSet(dutFam.box)  
    regexp {E\d\.([A-Z0-9]+)\.} $dutInitName ma gaSet(dutFam.ps)
  }  
  set idx [lsearch $fieldsL $gaSet(dutFam.box)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  if {$gaSet(dutFam.ps) != "FDC"} {
    set idx [lsearch $fieldsL $gaSet(dutFam.ps)]
    set fieldsL [lreplace $fieldsL $idx $idx]
  }
  #set fieldsL [concat $fieldsL "D72V" "FDC"]

  if {$gaSet(dutFam.sf)=="ETX-1P" || $gaSet(dutFam.sf)=="ETX-1P_SFC" || $gaSet(dutFam.sf)=="ETX-1P_A"} {
    set gaSet(dutFam.wanPorts)  "1SFP1UTP"
    set gaSet(dutFam.lanPorts)  "4UTP"
  } else {
    if {[string match *\.2U\.* $dutInitName]} {
      set gaSet(dutFam.wanPorts)  "2U"
    } elseif {[string match *\.4U2S\.* $dutInitName]} {
      set gaSet(dutFam.wanPorts)  "4U2S"
    } elseif {[string match *\.5U1S\.* $dutInitName]} {
      set gaSet(dutFam.wanPorts)  "5U1S"
    }
    set gaSet(dutFam.lanPorts)  "NotExists"
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.wanPorts)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  set idx [lsearch $fieldsL $gaSet(dutFam.lanPorts)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.2RS\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RS
  } elseif {[string match *\.2RSM\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RSM
  } elseif {[string match *\.1RS\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 1RS
	} elseif {[string match *\.2RMI\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RMI
  } elseif {[string match *\.2RSI\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RSI
  } else {
    set gaSet(dutFam.serPort) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.serPort)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.CSP\.* $dutInitName]} {
    set gaSet(dutFam.serPortCsp) CSP
  } else {
    set gaSet(dutFam.serPortCsp) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.serPortCsp)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  ToggleComDut
  
  
  if {[string match *\.2PA\.* $dutInitName]} {
    set gaSet(dutFam.poe) 2PA
  } elseif {[string match *\.POE\.* $dutInitName]} {
    set gaSet(dutFam.poe) POE
  } else {
    set gaSet(dutFam.poe) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.poe)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set gaSet(dutFam.cell) 0
  ## 15:56 25/12/2023 foreach cell [list HSP L1 L2 L3 L4 L450A L450B 5G L4P] {}
  foreach cell [list HSP L1 L2 L3 L4 L450A 5G LTA] {
    set qty [llength [lsearch -all [split $dutInitName .] $cell]]
    if $qty {
      set gaSet(dutFam.cell) $qty$cell
      break
    }  
  }
  # twice, since 2 modems can be installed
  set idx [lsearch $fieldsL [string range $gaSet(dutFam.cell) 1 end]]
  set fieldsL [lreplace $fieldsL $idx $idx]
  set idx [lsearch $fieldsL [string range $gaSet(dutFam.cell) 1 end]]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.G\.* $dutInitName]} {
    set gaSet(dutFam.gps) G
  } else {
    set gaSet(dutFam.gps) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.gps)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.WF\.* $dutInitName]} {
    set gaSet(dutFam.wifi) WF
  } elseif {[string match *\.WFH\.* $dutInitName] || [string match *\.WH\.* $dutInitName]} {
    set gaSet(dutFam.wifi) WH
  } else {
    set gaSet(dutFam.wifi) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.wifi)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.GO\.* $dutInitName]} {
    set gaSet(dutFam.dryCon) GO
    set idx [lsearch $fieldsL $gaSet(dutFam.dryCon)]
    set fieldsL [lreplace $fieldsL $idx $idx]
  } else {
    set gaSet(dutFam.dryCon) FULL
  }
  
  if {[string match *\.RG\.* $dutInitName]} {
    set gaSet(dutFam.rg) RG
  } else {
    set gaSet(dutFam.rg) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.rg)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set qty [regexp -all {\.(LR[1-9AB])\.} $dutInitName ma lora]
  if $qty {
    set gaSet(dutFam.lora) $lora
    switch -exact -- $lora {
      LR1 {set gaSet(dutFam.lora.region) eu433; set gaSet(dutFam.lora.fam) 4XX; set gaSet(dutFam.lora.band) "EU 433"}
      LR2 {set gaSet(dutFam.lora.region) eu868; set gaSet(dutFam.lora.fam) 8XX; set gaSet(dutFam.lora.band) "EU 863-870"}
      LR3 {set gaSet(dutFam.lora.region) au915; set gaSet(dutFam.lora.fam) 9XX; set gaSet(dutFam.lora.band) "AU 915-928 Sub-band 2"}
      LR4 {set gaSet(dutFam.lora.region) us902; set gaSet(dutFam.lora.fam) 9XX; set gaSet(dutFam.lora.band) "US 902-928 Sub-band 2"}
      LR6 {set gaSet(dutFam.lora.region) as923; set gaSet(dutFam.lora.fam) 9XX; set gaSet(dutFam.lora.band) "AS 923-925"}
      LRA {set gaSet(dutFam.lora.region) us915; set gaSet(dutFam.lora.fam) 9XX; set gaSet(dutFam.lora.band) "US 902-928 Sub-band 2"}
      LRB {set gaSet(dutFam.lora.region) eu868; set gaSet(dutFam.lora.fam) 8XX; set gaSet(dutFam.lora.band) "EU 863-870"}
      LR9 {set gaSet(dutFam.lora.region) us915; set gaSet(dutFam.lora.fam) 9XX; set gaSet(dutFam.lora.band) "US 915-928 Sub-band 2"}
    }
    ## 15:57 25/12/2023  LRC {set gaSet(dutFam.lora.region) eu433; set gaSet(dutFam.lora.fam) 4XX; set gaSet(dutFam.lora.band) "EU 433"}
  } else {
    set gaSet(dutFam.lora) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.lora)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set qty [regexp -all {\.(PLC|PLCD|PLCGO)\.} $dutInitName ma plc]
  if $qty {
    set gaSet(dutFam.plc) $plc
  } else {
    set gaSet(dutFam.plc) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.plc)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.2R\.* $dutInitName]} {
    set gaSet(dutFam.mem) 2
    set idx [lsearch $fieldsL ${gaSet(dutFam.mem)}R]
    set fieldsL [lreplace $fieldsL $idx $idx]
  } else {
    set gaSet(dutFam.mem) 1
  }
  
  puts "fieldsL:<$fieldsL>"
  puts "[parray gaSet dut*]\n" ; update
  
#   foreach nam [array names gaSet dutFam.*] {
#     puts -nonewline "$gaSet($nam)."
#   }
#   puts "$dutInitName"

  set gaSet(unknownFieldsL) [list]
  if [llength $fieldsL] {
    set gaSet(unknownFieldsL) $fieldsL
    RLSound::Play fail
    set res [DialogBoxRamzor -title "Unknown option" -message "The following is unknown:\n$fieldsL\nThe test will fail" \
      -type {Continue Stop} -icon /images/error]
    if {$res=="Stop"} {  
      set ::gMessage $fieldsL
      return -1
    }  
  }
  return 0
}  

# ***************************************************************************
# BuildEepromString
## BuildEepromString newUut
# ***************************************************************************
proc BuildEepromString {mode} {
  global gaSet
  puts "[MyTime] BuildEepromString $mode"
  
  if {$gaSet(dutFam.cell)=="0" && $gaSet(dutFam.wifi)=="0"} {
    ## no modems, no wifi
    set gaSet(eeprom.mod1man) ""
    set gaSet(eeprom.mod1type) ""
    set gaSet(eeprom.mod2man) ""
    set gaSet(eeprom.mod2type) ""
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.wifi)=="0" && $gaSet(dutFam.lora)=="0"} {
    ## just modem 1, no modem 2 and no wifi
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man) ""
    set gaSet(eeprom.mod2type) ""        
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.wifi)=="WF"} {
    ## modem 1 and wifi instead of modem 2
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan  -wifi]
    set gaSet(eeprom.mod2type) [ModType -wifi]
  } elseif {$gaSet(dutFam.cell)=="0" && $gaSet(dutFam.wifi)=="WF"} {
    ## no modem 1, wifi instead of modem 2
    set gaSet(eeprom.mod1man)  ""
    set gaSet(eeprom.mod1type) ""
    set gaSet(eeprom.mod2man)  [ModMan  -wifi]
    set gaSet(eeprom.mod2type) [ModType -wifi]    
  } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
    ## two modems are installed
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2type) [ModType $gaSet(dutFam.cell)]
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.lora)!="0"} {
    ## modem 1 and LoRa instead of modem 2
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan  -lora]
    set gaSet(eeprom.mod2type) [ModType -lora]
  }
  
  if {$mode=="newUut"} {
    set ret [GetMac 10]
    if {$ret=="-1" || $ret=="-2"} {
      return $ret
    } 
    foreach {a b} [split $ret {}] {
      append mac ${a}${b}:
    }
    set mac [string trim $mac :]
  } else {
    set mac "NoMac"
  }
  set gaSet(eeprom.mac) $mac
  #set mac 00:20:D2:AB:76:92
  set partNum [regsub -all {\.} $gaSet(DutFullName) /]
  switch -exact -- $gaSet(dutFam.ps) {
    ACEX {set ps 12V}
    DC   {set ps 12V}
    WDC  {set ps WDC-I}
    12V  {set ps 12V-I}
  }
  set gaSet(eeprom.ps) $ps
  
  switch -exact -- $gaSet(dutFam.serPort) {
    0     {set ser1 "";       set ser2 "";      set 1rs485 "";   set 2rs485 ""; set 1cts ""   ; set 2cts ""   }
    2RS   {set ser1 "RS232";  set ser2 "RS232"; set 1rs485 "";   set 2rs485 ""; set 1cts "YES"; set 2cts "YES"}
    2RSM  {set ser1 "RS485";  set ser2 "RS232"; set 1rs485 "2W"; set 2rs485 ""; set 1cts "YES"; set 2cts "YES"}
    1RS   {set ser1 "RS232";  set ser2 "";      set 1rs485 "";   set 2rs485 ""; set 1cts "YES"; set 2cts ""   }
  }
  set gaSet(eeprom.ser1) $ser1
  set gaSet(eeprom.ser2) $ser2
  set gaSet(eeprom.1rs485) $1rs485
  set gaSet(eeprom.2rs485) $2rs485
  
  switch -exact -- $gaSet(dutFam.poe) {
    0   {set poe ""}
    2PA   {set poe "2PA"}
    POE   {set poe "POE"}
  }
  set gaSet(eeprom.poe) $poe
  
  if {$mode=="newUut"} {
    set txt "aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeaaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeee"
    append txt MODEM_1_MANUFACTURER=${gaSet(eeprom.mod1man)},
    append txt MODEM_2_MANUFACTURER=${gaSet(eeprom.mod2man)},
    append txt MODEM_1_TYPE=${gaSet(eeprom.mod1type)},
    append txt MODEM_2_TYPE=${gaSet(eeprom.mod2type)},
    append txt MAC_ADDRESS=${mac},
    append txt MAIN_CARD_HW_VERSION=${gaSet(mainHW)},
    if {$gaSet(mainHW)=="0.6"} {
      append txt SUB_CARD_1_HW_VERSION=${gaSet(sub1HW)},
    } else {
      append txt SUB_CARD_1_HW_VERSION=,
    }
    if {$gaSet(mainHW)=="0.6"} {
      append txt HARDWARE_ADDITION=${gaSet(hwAdd)},
    }
    append txt CSL=${gaSet(csl)},
    append txt PART_NUMBER=${partNum},
    append txt PCB_MAIN_ID=${gaSet(mainPcbId)},
    if {$gaSet(mainHW)=="0.6"} {
      append txt PCB_SUB_CARD_1_ID=${gaSet(sub1PcbId)},
    } else {
      append txt PCB_SUB_CARD_1_ID=,
    }
    append txt PS=${ps},
    if {[string match *.HL.*  $gaSet(DutInitName)] || $gaSet(dutFam.sf) == "ETX-1P"} {
      ## HL option and ETX-1P don't have MicroSD
      append txt SD_SLOT=,
    } else {
      append txt SD_SLOT=YES,
    }
    append txt SERIAL_1=${ser1},
    append txt SERIAL_2=${ser2},
    append txt SERIAL_1_CTS_DTR=${1cts},
    append txt SERIAL_2_CTS_DTR=${2cts},
    append txt RS485_1=${1rs485},
    append txt RS485_2=${2rs485},
    #append txt POE=${poe},
    if {$gaSet(dutFam.sf) == "ETX-1P"} {
      append txt DRY_CONTACT_IN_OUT=,
    } else {
      append txt DRY_CONTACT_IN_OUT=2_2,
    }
    if {$gaSet(dutFam.wanPorts) == "4U2S"} {
      append txt NNI_WAN_1=FIBER,
      append txt NNI_WAN_2=FIBER,
      append txt LAN_3_4=YES,
    } elseif {$gaSet(dutFam.wanPorts) == "2U"} {
      append txt NNI_WAN_1=,
      append txt NNI_WAN_2=,
      append txt LAN_3_4=,
    } elseif {$gaSet(dutFam.wanPorts) == "5U1S"} {
      append txt NNI_WAN_1=FIBER,
      append txt NNI_WAN_2=FIBER,
      append txt LAN_3_4=YES,
    } elseif {$gaSet(dutFam.wanPorts) == "1SFP1UTP"} {
      append txt NNI_WAN_1=FIBER,
      append txt NNI_WAN_2=COPPER,
      append txt LAN_3_4=YES,
    }
    #append txt USB-A=YES,
    #append txt M.2-2=,
    append txt LIST_REF=0.0,
    #append txt SER_NUM=,
    append txt END=
    
    AddToPairLog $gaSet(pair) "$txt"  
    
    set fil c:/download/etx1p/eeprom.[set gaSet(pair)].cnt
    if [file exists $fil] {
      file copy -force $fil c:/temp/[clock format  [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"].eeprom.[set gaSet(pair)].txt
      catch {file delete -force $fil}
    }
    after 500
    set id [open $fil w]
      puts $id $txt
    close $id
  }
  
  return 0
} 

# ***************************************************************************
# ModMan
# ***************************************************************************
proc ModMan {cell} {
  switch -exact -- [string range $cell 1 end] {
    HSP - L1 - L2 - L3 - L4 {return QUECTEL}
    wifi                    {return AZUREWAVE}
    lora                    {return RAK}
    L450A                   {return Unitac}
    L450B                   {return Unitac}
    5G                      {return "SIERRA WIRELESS"}
  }
}  
# ***************************************************************************
# ModType
# ***************************************************************************
proc ModType {cell} {
  global gaSet
  switch -exact -- [string range $cell 1 end] {
    HSP  {return UC20}
    L1   {return EC25-E}
    L2   {return EC25-A}
    L3   {return EC25-AU}
    L4   {return EC25-AFFD}
    wifi {return AW-CM276MA}
    lora {
      switch -exact -- $gaSet(dutFam.lora) {
         LR1 {return EU433}
         LR2 {return RAK-5146}
         LR3 {return US915}
         LR4 {return US915}
         LR6 {return AS923}
         LR7 {return EU868}
         LRA {return 9XX}
         LRB {return 8XX}
         LRC {return LRC}
      }  
    }
    L450A {return ML620EU}
    L450B {return ML660PC}
    5G    {return EM9191}
  }
}                            
# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save com} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf \"$cfTxt\" $save $com"
  #set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
          if {$gaSet(pair)==5} {
            set dutIp 10.10.10.1[set ::pair]
          } else {
            if {$gaSet(pair)=="SE"} {
              set dutIp 10.10.10.111
            } else {
              set dutIp 10.10.10.1[set gaSet(pair)]
            }  
          }
          #set dutIp 10.10.10.1[set gaSet(pair)]
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *EccXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt] || [string match *aAux* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        ##RLSerial::Send $com "$line\r" 
        RLCom::Send $com "$line\r" 
      } else {
        if {[string match *Aux* $cfTxt]} {
          set gaSet(prompt) 205A
        } else {
          set waitFor 2I
        }
        if {[string match {*conf system name*} $line]} {
          set gaSet(prompt) [lindex $line end]
        }
        if {[string match *CUST-LAB-ETX203PLA-1* $line]} {
          set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        }
        if {[string match *WallGarden_TYPE-5* $line]} {
          set gaSet(prompt) "WallGarden_TYPE-5"          
        }
        if {[string match *BOOTSTRAP-2I10G* $line]} {
          set gaSet(prompt) "BOOTSTRAP-2I10G"          
        }
        set ret [Send $com $line\r $gaSet(prompt) 60]
#         Send $com "$line\r"
#         set ret [MyWaitFor $com {205A 2I ztp} 0.25 60]
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "CLI Error"
          set ret -1
          break
        }
      }            
    }
  }
  close $id  
  if {$ret==0} {
    if {$com==$gaSet(comAux1) || $com==$gaSet(comAux2)} {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
    } else {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
#       Send $com "exit all\r" 
#       set ret [MyWaitFor $com {205A 2I ztp} 0.25 8]
    }
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 80]
      if {$ret=="-1"} {
        set ret [Send $com "admin save\r" "successfull" 80]
      }
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  puts "[MyTime] Pings to $dutIp" ; update
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac
# ***************************************************************************
proc GetMac {qty} {
  global gaSet buffer
  puts "[MyTime] GetMac" ; update
  
  set ret [Login2Linux]
  if {$ret!=0} {return $ret}
  set com $gaSet(comDut)
  set ret [Send $com "\r" $gaSet(linuxPrompt)]  
  set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
  if {$ret!=0} {return $ret}
  if {[string match {*command not found*} $buffer]} {
    set ret [Send $com "cat /USERFS/eeprom/MAC_ADDRESS\r" $gaSet(linuxPrompt)]  
    if {$ret!=0} {return $ret}
  }
  set res [regexp {ADDRESS\s+([0-9A-F\:]+) } $buffer ma macLink]
  if {$res} {
    set dutMac [string toupper [join [split $macLink :] ""]]
    set hexDutMac 0x$dutMac
    puts "GetMac macLink:<$macLink> dutMac:<$dutMac> hexDutMac:<$hexDutMac>"
    if {$dutMac eq "181818181818"} {
      puts "DefaultMAC: 181818181818"
      set dutMac "DefaultMAC"
    }
  } else {
    puts "GetMac No User_eeprom"
    set dutMac "EmptyEEPROM"
    #set gaSet(fail) "Read EEPROM fail"
    #return -1
  }  
  puts "[MyTime] GetMac dutMac:<$dutMac> xdigit $dutMac:[string is xdigit $dutMac]"    
  if {[string is xdigit $dutMac]} {
    return $dutMac
  } else {
    puts "[MyTime] GetMac MACServer.exe" 
    set macFile c:/temp/mac.txt
    # exec $::RadAppsPath/MACServer.exe 0 $qty $macFile 1
    # set ret [catch {open $macFile r} id]
    # if {$ret!=0} {
    #  set gaSet(fail) "Open Mac File fail"
    #  return -1
    # }
    # set buffer [read $id]
    # close $id
    # file delete $macFile
    # set ret [regexp -all {ERROR} $buffer]
    # if {$ret!=0} {
    #   set gaSet(fail) "MACServer ERROR"
    #   return -1
    # }
    # set mac [lindex $buffer 0]  ; # 1806F5F4763B
    foreach {ret resTxt} [::RLWS::Get_Mac $qty] {}
    if {$ret!=0} {
      set gaSet(fail) $resTxt
      return -1
    }
    return $resTxt
  }  
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# GetDbrSW
# DC1002307101 5.4.0.127.28 B1.0.4 SF-1P/E1/DC/4U2S/2RSM/L1/G/L1/2R
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui gaDBox
  set gaSet(dbrSW) ""
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  
  set sw 0
  set gaSet(manualMrktName) 0
  set gaSet(manualCSL) 0
  # catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
  foreach {res b} [::RLWS::Get_SwVersions $barcode] {}
  after 1000
  
  puts "GetDbrSW barcode:<$barcode> b:<$b>" ; update
  
  if $gaSet(demo) {
    if $gaSet(useExistBarcode) {
      set boot $gaSet(dbrBootSwVer)
      set sw $gaSet(SWver)
    } else {
      set ret [DialogBox -width 39 -title "Manual Definitions" -text "Please define details" -type "Ok Cancel" \
        -entQty 4  -DotEn 1 -DashEn 1 -NoNumEn 1\
        -entLab {"SW Version, like 5.4.0.127.28" "Boot Version, like B1.0.4" "Marketing Name, like SF-1P/E1/DC/4U2S/2RS/2R" "CSL, like A"}]  
      if {$ret=="Cancel"} {
        set gaSet(fail) "User stop"
        return -2
      }
      UnregIdBarcode $barcode
      set sw [string trim $gaDBox(entVal1)]
      set boot [string toupper [string trim $gaDBox(entVal2)]]
      if {[string index $boot 0]=="B"} {
        set boot [string range $boot 1 end]
      }
      set gaSet(manualMrktName) [string trim $gaDBox(entVal3)]
      set gaSet(manualCSL) [string toupper [string trim $gaDBox(entVal4)]]
    }
  } else {
    if {[lindex $b end] == $barcode || $b == ""} {
      set gaSet(fail) "No SW definition in IDbarcode"
      return -2
    }
    foreach pair [split $b \n] {
      foreach {aa bb} $pair {      
        if {[string range $aa 0 1]=="SW" && [string index $bb 0]!= "B"} {
          puts "aa=$aa bb=$bb"; update
          set sw $bb
          #break
        }
        if {[string range $aa 0 1]=="SW" && [string index $bb 0] == "B"} {
          puts "bo=$aa boo=$bb"; update
          set boot [string range $bb 1 end]
          #break
        }
      }
      #if {$sw} {break}
    }
  }  
  #set gaSet(dbrSWver) $bb
  
  if ![info exists boot] {
    set gaSet(fail) "No Boot Version defined in DBR for $barcode"
    return -1
  }
  puts "GetDbrSW $barcode sw:<$sw> boot:<$boot>"
  set gaSet(dbrBootSwVer) $boot
  set gaSet(SWver) $sw
  after 1000
  
  # set swTxt [glob SW*_$barcode.txt]
  # catch {file delete -force $swTxt}
  update
  
  pack forget $gaGui(frFailStatus)
  
  # set swTxt [glob SW*_$barcode.txt]
  # catch {file delete -force $swTxt}
  
  Status ""
  update
  BuildTests
  focus -force $gaGui(tbrun)
  return 0
}
# ***************************************************************************
# GuiMuxMngIO
# ***************************************************************************
proc GuiMuxMngIO {mngMode} {
  global gaSet descript
  set channel [RetriveUsbChannel]   
  RLEH::Open
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  MuxMngIO $mngMode
  RLUsbMmux::Close $gaSet(idMuxMngIO) 
  RLEH::Close
}
# ***************************************************************************
# MuxMngIO
##     MuxMngIO 2ToPc
# ***************************************************************************
proc MuxMngIO {mngMode} {
  global gaSet
  puts "MuxMngIO $mngMode"
  RLUsbMmux::AllNC $gaSet(idMuxMngIO)
  after 1000
  RLUsbMmux::BusState $gaSet(idMuxMngIO) "A,B C D"
  after 500
  switch -exact -- $mngMode {
    1ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 1,14
    }
    2ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 2,14
    }
    3ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 3,14
    }
    4ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 4,14
    }
    5ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 5,14
    }
    6ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,14
    }
    6ToGen {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,13
    }
    
    nc {
      ## do nothing, already disconected
    }
  } 
;   
}


# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}
# ***************************************************************************
# LoadBootErrorsFile
# ***************************************************************************
proc LoadBootErrorsFile {} {
  global gaSet
  set gaSet(bootErrorsL) [list] 
  if ![file exists bootErrors.txt]  {
    return {}
  }
  
  set id [open  bootErrors.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(bootErrorsL) $line
      }
    }

  close $id
  
#   foreach ber $bootErrorsL {
#     if [string length $ber] {
#      lappend gaSet(bootErrorsL) $ber
#    }
#   }
  return {}
}
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  # if {[string match *Dut* $comName] || [string match *Gen* $comName] || [string match *Ser* $comName]} {
    # set baud 115200
  # } else {
    # set baud 9600
  # }
  set baud 115200
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val]  
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
}  
# *********

# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list at-sf1p-1-10 at-sf1p-2-w10 at-sf1p-3-w10  at-sf1p-4-w10]
  set initsPath AT-SF-1P/software/uutInits            
  #set usDefPath AT-SF-1V/ConfFiles/DEFAULT
  
  set s1 c:/$initsPath
  #set s2 c:/$usDefPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      #set dest //$host/c$/$usDefPath
      #if [file exists $dest] {
      #  lappend sdl $s2 $dest
      #} else {
      #  lappend unUpdatedHostsL $host        
      #}
    }
  }
  
  set msg ""
  set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
  if {$unUpdatedHostsL!=""} {
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL "file://R:\\IlyaG\\SF1P"
          if ![file exists R:/IlyaG/SF1P] {
            file mkdir R:/IlyaG/SF1P
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/SF1P } res
            puts $res
#             catch {file copy -force $s2/$fi R:/IlyaG/Etx1P } res
#             puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}

# ***************************************************************************
# ReadCom
# ***************************************************************************
proc ReadCom {com inStr {timeout 10}} {
  global buffer buff gaSet
  set buffer ""
  $gaSet(runTime) configure -text ""
  set secStart [clock seconds]
  set secNow [clock seconds]
  set secRun [expr {$secNow-$secStart}]
  while {1} {
    
    set ret [RLCom::Read $com buff]
    append buffer $buff
    puts "Read from Com-$com $secRun buff:<$buff>" ; update
    if {$ret!=0} {break}
    if {[string match "*$inStr*" $buffer]} {
      set ret 0
      break
    }
    
    after 1000
    set secNow [clock seconds]
    set secRun [expr {$secNow-$secStart}]
    $gaSet(runTime) configure -text "$secRun" ; update
    if {$secRun > $timeout} {
      set ret -1
      break
    }
  }
  return $ret
}

# ***************************************************************************
# SameContent
# ***************************************************************************
proc SameContent {file1 file2} {
  puts "SameContent $file1 $file2" ; update
  set f1 [open $file1]
  fconfigure $f1 -translation binary
  set f2 [open $file2]
  fconfigure $f2 -translation binary
  while {![info exist same]} {
      if {[read $f1 4096] ne [read $f2 4096]} {
          set same 0
      } elseif {[eof $f1]} {
          # The same if we got to EOF at the same time
          set same [eof $f2]
      } elseif {[eof $f2]} {
          set same 0
      }
  }
  close $f1
  close $f2
  return $same
}

# ***************************************************************************
# LoadModem
# ***************************************************************************
proc LoadModem {mdm} {
  global gaSet
  set mdm [string toupper $mdm]
  puts "[MyTime] LoadModem $mdm [file exists $mdm.txt]"
  if ![file exists $mdm.txt]  {
    set gaSet(fail) "$mdm.txt file doesn't exist"
    return -1
  }
  
  set gaSet($mdm.fwL) [list]
  set id [open $mdm.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet($mdm.fwL) $line
      }
    }
  close $id
  
  return 0
}

# ***************************************************************************
# LoadModemFiles
# ***************************************************************************
proc LoadModemFiles {} {
  foreach mdm [list HSP L1 L2 L3 L4 L450A L450B 5G L4P LTA] {
    set ret [LoadModem $mdm]
    if {$ret!=0} {return $ret}
  } 
 return $ret  
}

# ***************************************************************************
# FtpVerifyNoReport
# ***************************************************************************
proc FtpVerifyNoReport {} {
  global gaSet
  Status "Waiting for report file delete"
  set startSec [clock seconds]
  while 1 {
    #set res [FtpFileExist [string tolower  wifireport_$gaSet(wifiNet).txt]]
    catch {exec python.exe lib_sftp.py FtpFileExist wifireport_$gaSet(wifiNet).txt} res
    regexp {result: (-?1) } $res ma res
    #puts "FtpFileExist res <$res>"
    set runDur [expr {[clock seconds] - $startSec}]
    $gaSet(runTime) configure -text "$runDur" ; update
    puts "FtpVerifyNoReport runDur:<$runDur> res:<$res>"
    if {$runDur > 220} {
      set gaSet(fail) "wifireport_$gaSet(wifiNet).txt still exists on the ftp"
      return -1 
    }
    if {$res=="-1"} {
      break
    }
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt ""} res
    puts "FtpDeleteFile <$res>"
    if {[string match {*Unable to connect to ftp.rad.co.il*} $res]} {
      set gaSet(fail) "Unable to connect to ftp.rad.co.il"
      return -1
    }
    after 10000
  }
  return 0
}
# ***************************************************************************
# FtpVerifyReportExists
# ***************************************************************************
proc FtpVerifyReportExists {} {
  global gaSet
  Status "Waiting for report file create"
  set startSec [clock seconds]
  while 1 {
    #set res [FtpFileExist  [string tolower wifireport_$gaSet(wifiNet).txt]]
    catch {exec python.exe lib_sftp.py FtpFileExist wifireport_$gaSet(wifiNet).txt} res
    regexp {result: (-?1) } $res ma res
    #puts "FtpFileExist res <$res>"  
    set runDur [expr {[clock seconds] - $startSec}]
    $gaSet(runTime) configure -text "$runDur" ; update
    puts "FtpVerifyReportExists runDur:<$runDur> res:<$res>"
    if {$runDur > 220} {
      set gaSet(fail) "wifireport_$gaSet(wifiNet).txt still doesn't exist on the ftp"
      return -1 
    }
    if {$res=="1"} {
      break
    }
    after 10000
  }
  return 0  
}

proc StripHtmlTags { htmlText } {
  regsub -all {<[^>]+>} $htmlText "_" newText
  return $newText
}

# ***************************************************************************
# ReadCookies
# ***************************************************************************
proc ReadCookies {} {
  global cookies state
  set cookies [list]
  foreach {name value} $state(meta) {
    if { $name eq "Set-Cookie" } {
      lappend cookies [lindex [split $value {;}] 0]
    }
  }
} 



proc fff {} {
  router interface create address-prefix 10.10.10.20/24 physical-interface eth2  purpose application-host
  
  gnss update admin-status enable
  
  router nat static create protocol tcp  original-port 4443  modified-ip 10.0.3.70  modified-port 8443
  
  lxd update admin-status enable
  
}
proc inex {} {
  package require tcom
  set ie [tcom::ref createobject InternetExplorer.Application]
  $ie Visible True
  ##$ie GoHome
  $ie Navigate "https://10.10.10.20:4443/login"
  while {[$ie Busy]} {
   puts -nonewline .
   update
   after 100
 }
 
  set loc [$ie LocationURL]
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [$doc body]
  set inn [$body innerHTML]
  #join [[::tcom::info interface $ie] methods] \n
  #join [[::tcom::info interface $body] methods] \n
  
  set inputs [ $body getElementsByTagName "*" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "overridelink" ] == 0 } {
        $input focus
        after 250
        $input click
        break
      }
    }
    incr index    
  }
  
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [$doc body]
  
  set inputs [ $body getElementsByTagName "input" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "username" ] == 0 } {
        $input focus
        $input value "admin"
        while { [ $doc readyState ] != "complete" } {
          after 250
        }
      }
      if { [ string compare $name "password" ] == 0 } {
        $input focus
        $input value "admin"
        while { [ $doc readyState ] != "complete" } {
          after 250
        }
      }
    }
    incr index    
  }
  
}

proc vvv {} {
  package require twapi
  set ie [ twapi::comobj InternetExplorer.Application ]
  $ie Visible 0
  set szUrl "https://10.10.10.20:4443/login"
  $ie Navigate $szUrl
  $ie Visible 1
  set w [ $ie HWND ]
  set wIE [ list $w HWND ]
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [ $doc body ]
  
  
  set inputs [ $body getElementsByTagName "*" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
      puts "$index"
    } else {
      puts "input:<$input> name:<$name>"
    }
    incr index
  }
  
  set index 0    
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "overridelink" ] == 0 } {
        $input focus
        after 250
        $input click
        break
      }
    }
    incr index    
  }
  
  $ie Navigate $szUrl
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [ $doc body ]
  
  set inputs [ $body getElementsByTagName "input" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "username" ] == 0 } {
        $input value "admin"
        $input focus
      }
      if { [ string compare $name "password" ] == 0 } {
        $input value "admin"
        $input focus
      }
      
    }
    incr index    
  }
  
  set inputs [ $body getElementsByClassName "login-form" ]

}
## https://wiki.tcl-lang.org/page/IE+Automation+With+TWAPI

# ***************************************************************************
# ParseSW
# ***************************************************************************
proc ParseSW {} {
  global gaSet
  if {[string match *SFC* $gaSet(DutInitName)]} {
    return Safari
  }
  return General
  # foreach {a b c d e} [split $gaSet(SWver) .] {}
  # if {($a eq "5") && ($b eq "0") && ($c eq "0" || $c eq "1") &&($d <= "999")} {
    # return Safari
  # }
  # return General
}
# ***************************************************************************
# PcNum
# ***************************************************************************
proc PcNum {} {
  global gaSet
  return [expr {[string range $gaSet(hostDescription) end-1 end]}]
} 
# ***************************************************************************
# procUutNum
# ***************************************************************************
proc UutNum {} {
  global gaSet
  return $gaSet(pair)
} 
# ***************************************************************************
# MuxSwitchBox
# ***************************************************************************
proc MuxSwitchBox {gr state} {
  global gaSet
  RLUsbPio::Set  $gaSet(idPioSwBox$gr) $state
}
# ***************************************************************************
# ToggleComDut
# ***************************************************************************
proc ToggleComDut {} {
  global gaSet
  puts "[MyTime] ToggleComDut $gaSet(DutFullName)"
  if {[string match *ETX-1P* $gaSet(DutFullName)]} {
    set gaSet(comDut) $gaSet(comSer1)
  } else {
    if {[string match *\/1RS* $gaSet(DutFullName)]} {
      set gaSet(comDut) $gaSet(comSer1)
    } else {
      set gaSet(comDut) $gaSet(comSer2)
    } 
  }
  if [winfo exists .menubar.tterminal]  {
    .menubar.tterminal entryconfigure 0 -label "UUT: COM $gaSet(comDut)"
  }
}

proc GuiAlarm {leg state} {
  OpenPio
  if {$leg==4} {
    set io 1
  } elseif {$leg==6} {
    set io 2
  }
  MuxSwitchBox $io $state
  ClosePio
}

# ***************************************************************************
# LoraServerPolling
# ***************************************************************************
proc LoraServerPolling {} {
  global gaSet
  Status "Polling Lora Server"
  #set fld [file join r:/ LoraServerPoll]
  set fld //$gaSet(LoraServerHost)/c$/LoraDirs/LoraServerPoll
  # if {[file exists  $fld] == 0} {
    # file mkdir $fld
  # }
  
  set startWaitSec [clock seconds]
  set maxWaitSec 30; #300; # 5 minutes
  while 1 {
    if {$gaSet(act)==0} {return -2}
    
    ## Read the folder. Just 0 or 1 file should be here
    ## therefor, if more then one file is here, I delete all of them
    set flags [glob -nocomplain -directory $fld *]
    if {[llength $flags]>1} { 
      foreach flag $flags {
        if [catch {file delete -force $flag} res] {
          puts "\n Deleting File [file tail $flag]:$res"; update
        }
      }   
      after 200      
    }
    
    
    ## read the folder again
    set flags [glob -nocomplain -directory $fld *]
    set flagsLen [llength $flags]    
    set flag [file tail [lindex $flags 0]]
    set waitSec [expr {[clock seconds] - $startWaitSec}]
    puts "LoraServerPolling flag:<$flag> flagsLen:$flagsLen wifiNet:<$gaSet(wifiNet)> waitSec:$waitSec sec" ; update
    if {$waitSec>$maxWaitSec} {
      set gaSet(fail) "Can't get Enqueue to ChirpStack"
      set ret -1
      break
    }
    if {$flagsLen==0} {
      set id [open $fld/$gaSet(wifiNet) w+]
      after 1000
      close $id
      set ret 0
      break
    } else {
      puts 1; update
      if {$flag==$gaSet(wifiNet)} {
        puts 2; update
        ##gaSet(wifiNet) == [info host]_$gaSet(pair)
        ## it's my flag, continue
        set ret 0
        break
      } else {
        puts 3; update
      }
    }
    after 5000
  }
  
  return $ret  
}
# ***************************************************************************
# LoraServerRelease
# ***************************************************************************
proc LoraServerRelease {} {
  global gaSet
  Status "Release Lora Server"
  #set fld [file join r:/ LoraServerPoll]
  set fld //$gaSet(LoraServerHost)/c$/LoraDirs/LoraServerPoll
  if [catch {file delete -force $fld/$gaSet(wifiNet)} res] {
    set gaSet(fail) $res
    set ret -1
  } else {
    set ret 0
  }
  return $ret  
}
# ***************************************************************************
# LoraPingToChirpStack
# ***************************************************************************
proc LoraPingToChirpStack {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ip $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))
  set w 5; Wait "Wait $w seconds for Network" $w
  for {set i 1} {$i<=5} {incr i} {
    puts "Ping $i"  
    set gaSet(fail) "Send ping to ChirpStack $ip fail"     
    set ret [Send $com "ping $ip\r" "-1p" 15]
    if {$ret!=0} {return -1}
    set ret -1  
    if {[string match {*5 packets transmitted. 5 packets received, 0% packet loss*} $buffer]} {
      set ret 0
      break
    } else {
      set gaSet(fail) "Ping to ChirpStack $ip fail" 
    }
  }
  return $ret
}

# ***************************************************************************
# LoraPing
# ***************************************************************************
proc LoraPing {to ip} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "LoraPing to $to $ip"
  set w 5; Wait "Wait $w seconds for Network" $w
  for {set i 1} {$i<=5} {incr i} {
    puts "Ping $i"  
    set gaSet(fail) "Send ping to $to $ip fail"     
    set ret [Send $com "ping $ip\r" "-1p" 15]
    if {$ret!=0} {return -1}
    set ret -1  
    if {[string match {*5 packets transmitted. 5 packets received, 0% packet loss*} $buffer]} {
      set ret 0
      break
    } else {
      set gaSet(fail) "Ping to $to $ip fail" 
      after  1000
    }
  }
  return $ret
}
# ***************************************************************************
# LoadNoTraceFile
# ***************************************************************************
proc LoadNoTraceFile {} {
  global gaSet
  set gaSet(noTraceL) [list] 
  if ![file exists NoTrace.txt]  {
    return {}
  }
  
  set id [open NoTrace.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(noTraceL) $line
      }
    }

  close $id
}
# ***************************************************************************
# RetrivePcbId
# RetrivePcbId 21034056
# RetrivePcbId 21154229
# RetrivePcbId 20423011
# RetrivePcbId 21035187
# RetrivePcbId 21181408  
# ***************************************************************************
proc RetrivePcbId {traceID} {
  global gaSet
  puts "RetrivePcbId $traceID"
  set res "NA"
  set catch_ret [catch {exec java -jar GetPcbId.jar $traceID} res]
  puts "RetrivePcbId $traceID catch_ret:<$catch_ret> res:<$res>"
  if {$catch_ret==0} {
    set ret 0
    foreach pcbId {SF-1P.REV0.5I SF-1P.REV0.4I SF-1V/MAIN.REV0.1I SF-1V/PS.REV0.1I SF-1V/PS.REV0.3I} {
      set regexp_res [regexp {REV([\d\.]+)I?} $pcbId ma hwVer]
      puts "RetrivePcbId $traceID  pcbId:<$pcbId> regexp_res:<$regexp_res> hwVer:<$hwVer>"
    }
    set ret [list $pcbId $hwVer]
  } else {
    set ret -1
    set gaSet(fail) "Retrive Pcb Id ($traceID) fail"
  }
  return $ret
}

## RetriveIdTraceData DF100148093 CSLByBarcode
## RetriveIdTraceData DF100148093 MKTItem4Barcode
## RetriveIdTraceData 21181408    PCBTraceabilityIDData
## RetriveIdTraceData TO300315253 OperationItem4Barcode
# ***************************************************************************
# RetriveIdTaceData
# ***************************************************************************
proc RetriveIdTraceData {args} {
  global gaSet
  #set gaSet(fail) ""
  puts "RetriveIdTraceData $args"
  set barc [format %.11s [lindex $args 0]]
  
  set command [lindex $args 1]
  switch -exact -- $command {
    CSLByBarcode          {set barcode $barc  ; set traceabilityID null  ; set retPar "CSL"}
    PCBTraceabilityIDData {set barcode null   ; set traceabilityID $barc ; set retPar "pcb"}
    MKTItem4Barcode       {set barcode $barc  ; set traceabilityID null  ; set retPar "MKT Item"}
    OperationItem4Barcode {set barcode $barc  ; set traceabilityID null  ; set retPar "item"}
    default {set gaSet(fail) "Wrong command: \'$command\'"; return -1}
  }
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param [set command]\?barcode=[set barcode]\&traceabilityID=[set traceabilityID]
  append url $param
  puts "url:<$url>"
  if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
    after 2000
    if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
       set gaSet(fail) "Fail to get $command for $barc"
       return -1
    }
  }
  
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set gaSet(fail) "http::status: <$st> http::ncode: <$nc>"; return -1
  }
  upvar #0 $tok state
  #parray state
  #puts "$state(body)"
  set body $state(body)
  ::http::cleanup $tok
  
  set asadict [::json::json2dict $body]
  foreach {name whatis} $asadict {
    foreach {par val} [lindex $whatis 0] {
      puts "<$par> <$val>"
      if {$val!="null"} {
        dict set di $par $val
      }  
    }
  }
  if [info exist di] {
    return $di ; #[dict get $di $retPar]
  } else {
    return -1
  }
  
  # set re {[{}\[\]\,\t\:\"]}
  # set tt [regsub -all $re $body " "]
  # set ret [regsub -all {\s+}  $tt " "]
  
  # return [lindex $ret end]
}

# ***************************************************************************
# NoFti_Cellular
# ***************************************************************************
proc NoFti_Cellular {} {
  global gaSet
  set celOpt [string range $gaSet(dutFam.cell) 1 end]
  if {$celOpt=="L4P" || $celOpt=="L450B"} {
    set gaSet(fail) "No Test defined for $celOpt"
    return -1
  } else {
    return 0
  }
}
# ***************************************************************************
# DialogBoxRamzor
# ***************************************************************************
proc DialogBoxRamzor {args}  {
  Ramzor red on
  set ret [eval DialogBox $args]
  puts "DialogBoxRamzor ret after DialogBox:<$ret>"
  Ramzor green on
  return $ret
}