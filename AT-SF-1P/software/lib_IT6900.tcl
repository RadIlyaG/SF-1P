# ***************************************************************************
# IT9600_normalVoltage
# ***************************************************************************
proc IT9600_normalVoltage {off on} {
  global buffer gaSet
  puts "\n[MyTime] IT9600_normalVoltage"; update
  set volt [Retrive_normalVoltage]
  puts "off:<$off> on:<$on> volt:<$volt>"; update
  if $off {
    set ret [IT6900_on_off script off "1 2"]
  } else {
    set ret 0
  }

  if {$ret!="-1"} {
    set ret [IT6900_set script $volt "1"]
    if {$ret!="-1"} {
      set ret [IT6900_set script $volt "2"]
    }
  }  
  if {$ret!="-1"} {
    if $on {
      after 2000
      set ret [IT6900_on_off script on "1 2"]
    } else {
      set ret 0
    }
    # after 2000
  }
  return $ret
}  
# ***************************************************************************
# Retrive_normalVoltage
# ***************************************************************************
proc Retrive_normalVoltage {} {
  global gaSet
  if {$gaSet(dutFam.ps)=="WDC"} {
    set volt 48
  } elseif {$gaSet(dutFam.ps)=="12V" || $gaSet(dutFam.ps)=="ACEX"} {
    set volt 24
  } elseif {$gaSet(dutFam.ps)=="DC"} {
    set volt 24
  } elseif {$gaSet(dutFam.ps)=="D72V"} {
    set volt 48
  } elseif {$gaSet(dutFam.ps)=="FDC"} {
    set volt 48
  }
  return $volt
}

# ***************************************************************************
# Gui_IT6900
# ***************************************************************************
proc Gui_IT6900 {} {
  global gaSet gaGui
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1
  wm protocol $base WM_DELETE_WINDOW {IT6900_quit}
  set addrL []
  set res_list [exec python.exe lib_IT6900.py get_list stam stam]
  foreach res $res_list {
    if [regexp {0x6900::(\d+)::INSTR} $res ma addr] {
      lappend addrL $addr     
    }
  }
  puts "addrL: $addrL"
  
  wm title $base "IT6900"
  set frA [TitleFrame $base.frA -text "PS's ID" -bd 2 -relief groove]
    set fr [$frA getframe]
      foreach p {1 2} {
        set lab [Label $fr.lab$p -text "PS-$p Serial Number"]
        set ent [ComboBox $fr.ent$p -values $addrL -width 20 -textvariable gaSet(it6900.$p) ]
        set but [Button $fr.but$p -command [list IT6900_clr $p] -text "Clear"]
        grid $lab $ent $but
        set gaGui(it6900.$p) $ent
      }
    pack $fr  
    
  set frB [TitleFrame $base.frB -text "Manual mode" -bd 2 -relief groove]
    set fr [$frB getframe]
    set butOn  [Button $fr.butOn  -text "ON"  -command {IT6900_on_off gui on}]
    set butOff [Button $fr.butOff -text "OFF" -command {IT6900_on_off gui off}]
    set entVolt [Entry $fr.entVolt -textvariable gaSet(it6900.volt)]
    set butSet  [Button $fr.butSet  -text "SET"  -command {IT6900_set gui ""}]
    bind $entVolt <Return> {IT6900_set}
    pack $butOn $butOff -padx 5 -side left
    pack $entVolt $butSet -padx 5 -side left
  
  pack $frA
  pack $frB
  
}

# ***************************************************************************
# IT6900_on_off
# ***************************************************************************
proc IT6900_on_off {gui_script mode ps_l} {
  puts "\n[MyTime] IT6900_on_off $gui_script $mode"
  global gaSet gaGui
  set ret -1
  if {$gui_script=="gui"} {
    set addr [$gaGui(it6900.$ps) get]
    if {$addr!=""} {
      set ret [exec python.exe lib_IT6900.py $addr write "outp $mode"]
    } 
  }
  foreach ps $ps_l {
    set addr $gaSet(it6900.$ps)
    if {$addr!=""} {
      set ret [exec python.exe lib_IT6900.py $addr write "outp $mode"]
    } else {
      set ret 0
    }
  } 
  if {$ret=="-1"} {
    set gaSet(fail) "No communication with IT6900"
  }
  return $ret
}
# ***************************************************************************
# IT6900_set
# ***************************************************************************
proc IT6900_set {gui_script volt ps} {
  global gaSet gaGui
  puts "\n[MyTime] IT6900_set $gui_script $volt $ps"
  set ret -1
    
  if {$gui_script=="gui"} {
    foreach ps {1 2} {
      set addr [$gaGui(it6900.$ps) get]
      set volt $gaSet(it6900.volt)
      if {$addr!=""} {
        set ret [exec python.exe lib_IT6900.py $addr write "volt $volt"]
      }
    }
  } else {
    set addr $gaSet(it6900.$ps)  
    if {$addr!=""} {
      set ret [exec python.exe lib_IT6900.py $addr write "volt $volt"]
    } else {
      set ret 0
    }
  }  
   
  if {$ret=="-1"} {
    set gaSet(fail) "No communication with IT6900"
  }
  return $ret
}

# ***************************************************************************
# IT6900_clr
# ***************************************************************************
proc IT6900_clr {ps} {
  global gaGui
  $gaGui(it6900.$ps) clearvalue
}
# ***************************************************************************
# IT6900_quit
# ***************************************************************************
proc IT6900_quit {} {
  global gaSet gaGui
  foreach ps {1 2} {
    set gaSet(it6900.$ps) [$gaGui(it6900.$ps) get]
  }
  $gaGui(fr6900.lab2) configure -text ${gaSet(it6900.1)}-${gaSet(it6900.2)}
  if {[info exists gaSet(DutFullName)] && $gaSet(DutFullName)!=""} {
    BuildTests
  }  
  SaveInit
  destroy .topHwInit
}

# ***************************************************************************
# IT9600_current
# ***************************************************************************
proc IT9600_current {{set_normal 1}} {
  global buffer gaSet
  puts "\n[MyTime] IT9600_current $set_normal"; update
  if $set_normal {
    set ret [IT9600_normalVoltage 1 1]
  } else {
    set ret 0
  }
  # set ret [IT6900_on_off script off]
  # if {$ret!="-1"} {
    # set ret [IT6900_set script $volt]
  # }  
  # if {$ret!="-1"} {
    # after 2000
    # set ret [IT6900_on_off script on]
    # after 2000
  # }
  set ret1 -1
  set ret2 -1
  after 2000
  foreach ps {1 2} {
    puts "Measure Current on PS-$ps"
    set addr $gaSet(it6900.$ps)
    set curr [exec python.exe lib_IT6900.py $addr query meas:curr?]
    puts "PS-$ps curr_ret:<$curr>"
    set curr$ps [lindex [split $curr \n] end]
    puts "PS-$ps curr_ret:<[set curr$ps]>"
    if {[set curr$ps]>0.05} {
      set ret$ps 0
    } else {
      set ret$ps -1
    }
  }  
  puts "ret1:$ret1 ret2:$ret2"
  if {$ret1=="-1" && $ret2=="-1"} {
    set gaSet(fail) "UUT doesn't connected to IT6900"
    set ret -1
  } else {
    set ret 0
  }
  puts "ret:${ret}. ret==-1 if in both PSs current< 0.05, otherwise ret==0"
  return $ret
}