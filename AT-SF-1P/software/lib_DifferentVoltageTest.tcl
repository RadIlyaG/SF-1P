# ***************************************************************************
# Gui_DifferentVoltageTest
# ***************************************************************************
proc Gui_DifferentVoltageTest {} {
  return 0
  global gaSet gaGui
  set base .topDVT
  
  if [winfo exists $base] {
    wm deiconify $base
    return {}
  }
  
  
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1
  
  wm title $base "Different Voltage Test"
  
  set frCond [TitleFrame $base.frCond -text "Conditions" -bd 2 -relief groove]
    set fr [$frCond getframe]
    set l1 [ttk::label  $fr.lab1 -text "Set of voltages (example: 10, 24, 30)"]
    set gaGui(entDiffV) [ttk::entry $fr.ent1  -textvariable gaSet(entDiffV)]
    grid $l1 $gaGui(entDiffV) -padx 2 -pady 2
    set gaSet(entDiffV) "10, 24, 30"
    
    set l2 [ttk::label  $fr.lab2 -text "Qty of each voltage performance"]
    set gaGui(entQtyEachV) [ttk::entry $fr.ent2  -textvariable gaSet(entQtyEachV)]
    grid $l2 $gaGui(entQtyEachV) -padx 2 -pady 2
    set gaSet(entQtyEachV) "1"
    
    set l3 [ttk::label  $fr.lab3 -text "Qty of Voltage Sets"]
    set gaGui(entQtyVoSets) [ttk::entry $fr.ent3  -textvariable gaSet(entQtyVoSets)]
    grid $l3 $gaGui(entQtyVoSets) -padx 2 -pady 2
    set gaSet(entQtyVoSets) "1"
    
    set gaGui(chbSOF) [ttk::checkbutton  $fr.chbSOF  -text "Stop On Failure"  -variable gaSet(chbSOF)]
    grid $gaGui(chbSOF) -padx 2 -pady 2
    set gaSet(chbSOF) 1
    
    
  set frButt [ttk::frame $base.frButt -relief flat]  
    set gaGui(butRunDiffV) [ttk::button $frButt.b1 -text "RUN" -command butRunDiffV]
    set gaGui(butStopDiffV) [ttk::button $frButt.b2 -text "STOP" -command butStopDiffV\
        -state disabled]
    grid $gaGui(butRunDiffV) $gaGui(butStopDiffV) -sticky e -padx 2 -pady 2
    
  pack $frCond -padx 2 -pady 2
  pack $frButt -padx 2 -pady 2
  
  
  focus -force $base
  #grab $base
  return {} 
 
}

proc butStopDiffV {} {
  global gaSet gaGui
  set gaSet(act)  0
  $gaGui(butRunDiffV) configure -state normal
  $gaGui(butStopDiffV) configure -state disabled
  update
}

# ***************************************************************************
# butRunDiffV
# ***************************************************************************
proc butRunDiffV {} {
  global gaSet gaGui
  
  $gaGui(butRunDiffV) configure  -state disabled
  $gaGui(butStopDiffV) configure  -state normal
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
  update
  set ::sendSlow 0
  set gaSet(act)  1
  set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
  set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-DiffVoltTest.txt
  catch {RLEH::Close}
  RLEH::Open
  catch {RLCom::Close $gaSet(comDut)}
  after 1000
  set ret 0 ;# [OpenPio]
  set ret1 [RLCom::Open $gaSet(comDut) 115200 8 NONE 1]
  if {$ret!=0 || $ret1!=0} {
    DialogBox -title "Open RL fail" -message "Open RL Fail" -icon /images/error.gif -type "Ok"
    return -1
  }
   
  puts "gaSet(entDiffV):$gaSet(entDiffV)"
  AddToPairLog $gaSet(pair) "Start $gaSet(entQtyVoSets) set/s of \($gaSet(entDiffV)\)VDC, $gaSet(entQtyEachV) time/s each Voltage\n"
  set ps 1
  set fails 0
  set passes 0
  for {set k 1} {$k<=$gaSet(entQtyVoSets)} {incr k} {
    
    foreach volt [split $gaSet(entDiffV) ","] {
      set volt [string tolower [string trim $volt]]
      set volt [string trimright $volt "v"]
      puts "volt:<$volt>"
      for {set i 1} {$i <= $gaSet(entQtyEachV)} {incr i} {
      
        set ret [IT6900_on_off script off "1 2"]
        $gaSet(statBarShortTest) configure -text "Set $k, ${volt}V, cycle $i"
        
        Status "Set $k, ${volt}V, cycle $i"
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
          
          if {$ret==0} {
            set res "PASS"
            incr passes
          } else {
            if {$ret=="-2"} {
              set res "User Stop"
            } else {
              set res "FAIL"
              incr fails
            }
          }
          puts "[MyTime] Set $k, Voltage=${volt}VDC, cycle $i, $res Ret after Login: $ret"
          AddToPairLog $gaSet(pair) "Set $k, Voltage=${volt}VDC, cycle $i, $res"
        }
        if {$ret!=0 && $gaSet(chbSOF)==1} {break}
        if {$ret=="-2"} {break}
      }
      if {$ret!=0 && $gaSet(chbSOF)==1} {break}
      if {$ret=="-2"} {break}
    } 
    if {$ret!=0 && $gaSet(chbSOF)==1} {break}    
    if {$ret=="-2"} {break}
  }
  
  puts "After all. ret:<$ret>, gaSet(fail):$gaSet(fail)"
  if {$ret==0 && $fails==0} {
    Status $res green
  } elseif {$ret=="-1" || $fails>0} {
    Status $res red
  } elseif {$ret=="-2"} {
    Status $res red
  } else {
    Status $ret "yellow"
  }
  butStopDiffV
  AddToPairLog $gaSet(pair) "\nFails: $fails, Passes: $passes"
  
  # ClosePio
  catch {RLCom::Close $gaSet(comDut)}
  catch {RLEH::Close}   
}

