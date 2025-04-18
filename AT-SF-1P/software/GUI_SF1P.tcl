#***************************************************************************
#** GUI
#***************************************************************************
proc GUI {} {
  global gaSet gaGui glTests  
  
  #  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  # wm title . "$gaSet(pair) : "
  
  # 09:37 19/05/2024 From today - no Boot
  # if {![info exist gaSet(showBoot)]} {
    # set gaSet(showBoot) 1
  # }
  set gaSet(showBoot) 0
  
  if $gaSet(demo) {
    wm deiconify .
  wm geometry . $gaGui(xy)
  update
    RLSound::Play information
    set txt "You are working with ATE's DEMO version\n
Please confirm you know products should not be released to the customer with this version"
    set res [DialogBoxRamzor -icon images/info -type "OK Abort" -text $txt -default 1 -aspect 2000 -title "DEMO version"]
    if {$res=="Abort"} {
      exit
    } 
    wm title . "DEMO!!! $gaSet(pair)"
  } else {
    wm title . "$gaSet(pair) : "
  }
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  set gaSet(eraseTitleGui) $gaSet(eraseTitle)
  if {$gaSet(eraseTitle)==1} {
    if $gaSet(demo) {
      wm title . "DEMO!!! $gaSet(pair)"
    } else {
      wm title . "$gaSet(pair) : "
    }
  }
  
  wm protocol . WM_DELETE_WINDOW {Quit}
  wm geometry . 640x183$gaGui(xy)
  wm resizable . 0 0
  set descmenu {
    "&File" all file 0 {	 
      {command "Log File"  {} {} {} -command ShowLog}
	    {separator}     
      {cascad "&Console" {} console 0 {
        {checkbutton "console show" {} "Console Show" {} -command "console show" -variable gConsole}
        {command "Capture Console" cc "Capture Console" {} -command CaptureConsole}
      }
      }
      {separator}
      {cascad "Edit Modems Files" {} {} 0 {
        {command "Edit L1 file" init "" {} -command {exec notepad L1.txt &}}
        {command "Edit L2 file" init "" {} -command {exec notepad L2.txt &}}
        {command "Edit L3 file" init "" {} -command {exec notepad L3.txt &}}
        {command "Edit L4 file" init "" {} -command {exec notepad L4.txt &}}
        {command "Edit HSP file" init "" {} -command {exec notepad HSP.txt &}}
        {command "Edit L4P file" init "" {} -command {exec notepad L4P.txt &}}
        {command "Edit L450A file" init "" {} -command {exec notepad L450A.txt &}}
        {command "Edit L450B file" init "" {} -command {exec notepad L450B.txt &}}
        {command "Edit 5G file" init "" {} -command {exec notepad 5G.txt &}}
      }
      }
      {separator}
      {command "Load Modem files" init "" {} -command {LoadModemFiles}}
      {separator}
      {separator}
      {command "History" History "" {} \
         -command {
           set cmd [list {*}[auto_execok start] {}]
           exec {*}$cmd [pwd]\\history.html &
#            set cmd [list exec "C:\\Program\ Files\\Internet\ Explorer\\iexplore.exe" [pwd]\\history.html &]
#            eval $cmd
         }
      }
      {separator}
      {command "E&xit" exit "Exit" {Alt x} -command {Quit}}
    }
    "&Tools" tools tools 0 {	  

      {command "IT6900" {} "" {} -command {Gui_IT6900}} 
      
      {separator}   
      {cascad "Power" {} pwr 0 {
        {command "PS-1 & PS-2 ON" {} "" {} -command {GuiPower $gaSet(pair) 1}} 
        {command "PS-1 & PS-2 OFF" {} "" {} -command {GuiPower $gaSet(pair) 0}}  
        {command "PS-1 & PS-2 OFF and ON" {} "" {} \
            -command {
              GuiPower $gaSet(pair) 0
              after 1000
              GuiPower $gaSet(pair) 1
            }  
        }             
      }
      } 
      {separator}       
      {cascad "Mux " {} "" 0 {
        {command "ETH6 - Generator" {} "" {} -command {GuiMuxMngIO 6ToGen}} 
        {command "ETH6 - LAN" {} "" {} -command {GuiMuxMngIO 6ToPc}}    
        {command "ETH6 - NC" {} "" {} -command {GuiMuxMngIO nc}}         
      }
      }      
      {separator}    
      {radiobutton "Don't use exist Barcodes" init {} {} -command {} -variable gaSet(useExistBarcode) -value 0}
      {radiobutton "Use exist Barcodes" init {} {} -command {} -variable gaSet(useExistBarcode) -value 1}      
      {separator}
      {radiobutton "One test ON"  init {} {} -value 1 -variable gaSet(oneTest)}
      {radiobutton "One test OFF" init {} {} -value 0 -variable gaSet(oneTest)}
      {separator}    
      {command "Release / Debug mode" {} "" {} -command {GuiReleaseDebugMode}}                 
      {separator}   
      {cascad "Email" {} fs 0 {
        {command "E-mail Setting" gaGui(ToolAdd) {} {} -command {GuiEmail .mail}} 
  		  {command "E-mail Test" gaGui(ToolAdd) {} {} -command {TestEmail}}       
      }
      }  
      {separator}    
      {radiobutton "PowerOffOn until first steps" init {} {} -command {} -variable gaSet(PowerOffOnUntil) -value first_steps}
      {radiobutton "PowerOffOn until Login" init {} {} -command {} -variable gaSet(PowerOffOnUntil) -value login}      
      {separator}  
      {command "Different Voltage Test" {} "" {} -command {Gui_DifferentVoltageTest}}
    }                
    "&Terminal" terminal tterminal 0  {
      {command "UUT" "" "" {} -command {OpenTeraTerm gaSet(comDut)}}  
      {command "Gen-1" "" "" {} -command {OpenTeraTerm gaSet(comGen1)}} 
      {command "Gen-2" "" "" {} -command {OpenTeraTerm gaSet(comGen2)}} 
      {command "Serial-1" "" "" {} -command {OpenTeraTerm gaSet(comSer1)}}  
      {command "Serial-2" "" "" {} -command {OpenTeraTerm gaSet(comSer2)}} 
      {command "485-2" "" "" {} -command {OpenTeraTerm gaSet(comSer485)}}                     
    }
    "Test &mode" testmode testmode 0  {
      {radiobutton "Final Tests" init {} {} -command {BuildTests} -variable gaSet(testmode) -value finalTests}
      {radiobutton "Data + Power OFF-ON" init {} {} -command {ConfigPowerOnOff} -variable gaSet(testmode) -value dataPwrOnOff}      
                          
    }
    "&About" all about 0 {
      {command "&About" about "" {} -command {About} 
      }
    }
  }
  # {command "Update INIT and UserDefault files on all the Testers" {} "Exit" {} -command {UpdateInitsToTesters}}
      # {separator}
  #    {command "Inventory" init {} {} -command {GuiInventory}}    
  #    {command "Load Init File" init {} {} -command {GetInitFile; GuiInventory}}
  #    {separator}  
  #    {command "Options" init {} {} -command {GuiOpts}}
  #    {separator} 
  
  # {separator}
      # {radiobutton "J21 1-2 (Show Boot)"  init {} {} -value 1 -variable gaSet(showBoot) -command ToggleShowBoot}
      # {radiobutton "J21 2-3 (Hide Boot)"  init {} {} -value 0 -variable gaSet(showBoot) -command ToggleShowBoot}
      
  # {radiobutton "Use exist Barcodes" init {} {} -command {GetDbrName} -variable gaSet(useExistBarcode) -value 1}
      

  set mainframe [MainFrame .mainframe -menu $descmenu]
  
  set gaSet(sstatus) [$mainframe addindicator]  
  $gaSet(sstatus) configure -width 60 
  
  set gaSet(statBarShortTest) [$mainframe addindicator]
  
  
  set gaSet(startTime) [$mainframe addindicator]
  
  set gaSet(runTime) [$mainframe addindicator]
  $gaSet(runTime) configure -width 5
  
  set tb0 [$mainframe addtoolbar]
  pack $tb0 -fill x
  
  set gaGui(labDemoNotDemo1) [Label $tb0.labDemoNotDemo1 -width 5]
  if $gaSet(demo) {
    pack $gaGui(labDemoNotDemo1) -padx 5 -side left
  }
  
  set labstartFrom [Label $tb0.labSoft -text "Start From   "]
  set gaGui(startFrom) [ComboBox $tb0.cbstartFrom  -height 18 -width 35 -textvariable gaSet(startFrom) -justify center  -editable 0]
  $gaGui(startFrom) bind <Button-1> {SaveInit}
  pack $labstartFrom $gaGui(startFrom) -padx 2 -side left
  set sepIntf [Separator $tb0.sepIntf -orient vertical]
  pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0
	 
  set bb [ButtonBox $tb0.bbox0 -spacing 1 -padx 5 -pady 5]
    set gaGui(tbrun) [$bb add -image [Bitmap::get images/run1] \
        -takefocus 1 -command ButRun \
        -bd 1 -padx 5 -pady 5 -helptext "Run the Tester"]		 		 
    set gaGui(tbstop) [$bb add -image [Bitmap::get images/stop1] \
        -takefocus 0 -command ButStop \
        -bd 1 -padx 5 -pady 5 -helptext "Stop the Tester"]
    set gaGui(tbpaus) [$bb add -image [Bitmap::get images/pause] \
        -takefocus 0 -command ButPause \
        -bd 1 -padx 5 -pady 1 -helptext "Pause/Continue the Tester"]	    
  pack $bb -side left  -anchor w -padx 7 ;#-pady 3
  set bb [ButtonBox $tb0.bbox1 -spacing 1 -padx 5 -pady 5]
    set gaGui(noSet) [$bb add -image [Bitmap::get images/Set] \
        -takefocus 0 -command {PerfSet swap} \
        -bd 1 -padx 5 -pady 5 -helptext "Run with the UUTs Setup"]    
  pack $bb -side left  -anchor w -padx 7
  set bb [ButtonBox $tb0.bbox12 -spacing 1 -padx 5 -pady 5]
    set gaGui(email) [$bb add -image [image create photo -file  images/email16.ico] \
        -takefocus 0 -command {GuiEmail .mail} \
        -bd 1 -padx 5 -pady 5 -helptext "Email Setup"] 
    set gaGui(ramzor) [$bb add -image [image create photo -file  images/TRFFC09_1.ico] \
        -takefocus 0 -command {GuiIPRelay} \
        -bd 1 -padx 5 -pady 5 -helptext "IP-Relay Setup"]        
  pack $bb -side left  -anchor w -padx 7
  
  set sepIntf [Separator $tb0.sepFL -orient vertical]
  #pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0 
  
  set bb [ButtonBox $tb0.bbox2]
    set gaGui(butShowLog) [$bb add -image [image create photo -file images/find1.1.ico] \
        -takefocus 0 -command {ShowLog} -bd 1 -helptext "View Log file"]     
  pack $bb -side left  -anchor w -padx 7
  
  set gaGui(labDemoNotDemo2) [Label $tb0.labDemoNotDemo2 -width 5]
  pack $gaGui(labDemoNotDemo2) -padx 5 -side right
  
      
#     set frCommon [frame $mainframe.frCommon  -bd 2 -relief groove]
#     pack $frCommon -fill both -expand 1 -padx 2 -pady 0 -side left 
	 
    set frDUT [frame $mainframe.frDUT -bd 2 -relief groove] 
      set labDUT [Label $frDUT.labDUT -text "UUT's barcode" -width 15]
      set gaGui(entDUT) [Entry $frDUT.entDUT -bd 1 -justify center -width 50\
            -editable 1 -relief groove -textvariable gaSet(entDUT) -command {GetDbrName}\
            -helptext "Scan a barcode here"]
      set gaGui(clrDut) [Button $frDUT.clrDut -image [image create photo -file  images/clear1.ico] \
            -takefocus 1 \
            -command {
                global gaSet gaGui
                set gaSet(entDUT) ""
                focus -force $gaGui(entDUT)
            }]         
      pack $labDUT $gaGui(entDUT) $gaGui(clrDut) -side left -padx 2 
#     set frTestPerf [TitleFrame $mainframe.frTestPerf -bd 2 -relief groove \
#         -text "Test Performance"] 
#       set f [$frTestPerf getframe]      17/09/2014 16:26:46

    set fr6900 [frame $mainframe.fr6900 -bd 2 -relief groove] 
      set lab1 [Label $fr6900.lab1 -text "IT6900 PS:"]
      if ![info exists gaSet(it6900.1)] {
        set gaSet(it6900.1) ""
      }
      set lab2 [Label $fr6900.lab2 -text ${gaSet(it6900.1)}-${gaSet(it6900.2)} -width 40 -relief sunken -bd 2 ]
      set gaGui(fr6900.lab2) $lab2
      pack $lab1 $lab2 -padx 2 -side left

    set frTestPerf [frame $mainframe.frTestPerf -bd 2 -relief groove]     
      set f $frTestPerf
      set frCur [frame $f.frCur]  
        set labCur [Label $frCur.labCur -text "Current Test  " -width 13]
        set gaGui(curTest) [Entry $frCur.curTest -bd 1 \
            -editable 0 -relief groove -textvariable gaSet(curTest) \
	       -justify center -width 50]
        set gaGui(labRelDebMode) [Label $frCur.labRelDebMode -text $gaSet(relDebMode) -width 13] 
        set gaGui(labDemoNotDemo) [Label $frCur.labDemoNotDemo -width 5] 
        pack $labCur $gaGui(curTest) -padx 7 -pady 1 -side left -fill x;# -expand 1 
        pack $gaGui(labRelDebMode) $gaGui(labDemoNotDemo) -side right -anchor e
      pack $frCur  -anchor w
      #set frStatus [frame $f.frStatus]
      #  set labStatus [Label $frStatus.labStatus -text "Status  " -width 12]
      #  set gaGui(labStatus) [Entry $frStatus.entStatus \
            -bd 1 -editable 0 -relief groove \
	   -textvariable gaSet(status) -justify center -width 58]
      #  pack $labStatus $gaGui(labStatus) -fill x -padx 7 -pady 3 -side left;# -expand 1 	 
      #pack $frStatus -anchor w
      set frFail [frame $f.frFail]
      set gaGui(frFailStatus) $frFail
        set labFail [Label $frFail.labFail -text "Fail Reason  " -width 12]
        set labFailStatus [Entry $frFail.labFailStatus \
            -bd 1 -editable 1 -relief groove \
            -textvariable gaSet(fail) -justify center -width 80]
      pack $labFail $labFailStatus -fill x -padx 7 -pady 3 -side left; # -expand 1	
      #pack $gaGui(frFailStatus) -anchor w
  
    pack $frDUT $fr6900 $frTestPerf -fill both -expand yes -padx 2 -pady 2 -anchor nw	 
  pack $mainframe -fill both -expand yes

  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  

  console eval {.console config -height 35 -width 92}
  console eval {set ::tk::console::maxLines 10000}
  console eval {.console config -font {Verdana 10}}
  focus -force .
  bind . <F1> {console show}
  bind . <Alt-i> {GuiInventory}
  bind . <Alt-r> {ButRun}
  bind . <Alt-s> {ButStop}
  bind . <Alt-b> {set gaSet(useExistBarcode) 1} ; #; GetDbrName
  bind . <Control-p> {ToolsPower on}
  bind . <Alt-o> {set gaSet(oneTest) 1}
  

  .menubar.tterminal entryconfigure 0 -label "UUT: COM $gaSet(comDut)"
  .menubar.tterminal entryconfigure 1 -label "Gen-1: COM $gaSet(comGen1)"
  .menubar.tterminal entryconfigure 2 -label "Gen-2: COM $gaSet(comGen2)"
  .menubar.tterminal entryconfigure 3 -label "Ser-1: COM $gaSet(comSer1)"
  .menubar.tterminal entryconfigure 4 -label "Ser-2: COM $gaSet(comSer2)"
  .menubar.tterminal entryconfigure 5 -label "485-2: COM $gaSet(comSer485)"
  
  set ::NoATP 0
  if $::NoATP {
    RLStatus::Show -msg atp
  }
  set ::NoFTI 0
  if $::NoFTI {
    RLStatus::Show -msg fti
  }
  
  if $gaSet(demo) {
    #$gaGui(labDemoNotDemo) configure -text "DEMO!!!" -bg yellow -fg red
    $gaGui(labDemoNotDemo1) configure -text "DEMO!!!" -bg yellow -fg red
    $gaGui(labDemoNotDemo2) configure -text "DEMO!!!" -bg yellow -fg red
  }
  set gaSet(entDUT) ""
  focus -force $gaGui(entDUT)
  
  if ![info exists ::RadAppsPath] {
    set ::RadAppsPath c:/RLFiles/Tools/RadApps
  }
  set gaSet(GuiUpTime) [clock seconds]
}
# ***************************************************************************
# About
# ***************************************************************************
proc About {} {
  if [file exists history.html] {
    set id [open history.html r]
    set hist [read $id]
    close $id
#     regsub -all -- {[<>]} $hist " " a
#     regexp {div ([\d\.]+) \/div} $a m date
    regsub -all -- {<[\w\=\#\d\s\"\/]+>} $hist "" a
    regexp {<!---->\s(.+)\s<!---->} $a m date
  } else {
    set date 14.11.2016 
  }
  DialogBox -title "About the Tester" -icon info -type ok  -font {{Lucida Console} 9} -message "ATE software upgrade\n$date"
  #DialogBox -title "About the Tester" -icon info -type ok\
          -message "The software upgrated at 14.11.2016"
}

# ***************************************************************************
# GuiInventory
# ***************************************************************************
proc GuiInventory {} {
  global gaSet gaTmpSet gaGui
  array unset gaTmpSet
  
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1
  
  wm title $base "Inventory of $gaSet(DutFullName)"
  
  foreach par {dbrUbootSWnum dbrUbootSWver uutSWfrom dbrSWnum SWver mainHW mainPcbId sub1HW sub1PcbId \
      csl dbrBootSwNum dbrBootSwVer hwAdd} {
    if ![info exists gaSet($par)] {
      set gaSet($par) ??
    }
    set gaTmpSet($par) $gaSet($par)
  }
  foreach par {UbootSWpath UutSWpath LXDpath} {
    if ![info exists gaSet($par)] {
      set gaSet($par) C:\\Temp
    }
    set gaTmpSet($par) $gaSet($par)
  }
    
  set pathWith 60
  set fr [TitleFrame $base.fr1 -text "Uboot" -bd 2 -relief groove]
    set fr0 [$fr getframe]
  #set fr [frame $base.fr1 -bd 2 -relief groove]
    set fr1 [frame $fr0.fr1]
      set lab1 [ttk::label $fr1.lab1 -text "Software (SWxxxx)"]
      set en1 [ttk::entry $fr1.en1 -justify center -width 8  -textvariable gaTmpSet(dbrUbootSWnum)]  ; # -editable 1
      grid $lab1 $en1 -sticky w -padx 2 -pady 2
      set lab2 [ttk::label $fr1.lab2 -text "Version"]
      set en2 [ttk::entry $fr1.en2 -justify center -width 12 -state disabled -textvariable gaTmpSet(dbrUbootSWver)] ; # -editable 0
      grid $lab2 $en2 -sticky w -padx 2 -pady 2
      
    set fr2 [frame $fr0.fr2]
      set txt "UBoot Software"
      set f UbootSWpath
      set b1 [ttk::button $fr2.brw -text "Browse..." -command [list BrowseCF $txt $f] ]
      set b2 [ttk::button $fr2.cl  -image [image create photo -file images/clear1.ico] -command [list ClearInvLabel $f] ]
      set lab2 [ttk::label $fr2.lab2 -relief sunken -textvariable gaTmpSet($f) -width $pathWith] 
      grid $b1 $lab2 $b2  -sticky w -padx 2 -pady 2      
    
    grid $fr1  -padx 2 -pady 2 -sticky ew
    grid $fr2  -padx 2 -pady 2  -sticky ew  
#   pack $fr  -anchor w -pady 2 -padx 2 -fill both -expand 1
  
  set fr [TitleFrame $base.frBoo -text "UUT Boot" -bd 2 -relief groove]
  set fr0 [$fr getframe]
    set fr1 [frame $fr0.fr1]
      set lab1 [ttk::label $fr1.lab1 -text "Boot (SWxxxx)"]
      set en1 [ttk::entry $fr1.en1 -justify center -width 8 -textvariable gaTmpSet(dbrBootSwNum)]  ; # -editable 1
      set en2 [ttk::entry $fr1.en2 -justify center -width 12 -textvariable gaTmpSet(dbrBootSwVer)]    ; # -editable 1
      grid $lab1 $en1 $en2 -sticky w -padx 2 -pady 2
    grid $fr1  -padx 2 -pady 2 -sticky ew
  pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1
  
  set fr [TitleFrame $base.fr2 -text "UUT Software" -bd 2 -relief groove]
    set fr0 [$fr getframe]
  
  #set fr [frame $base.fr2 -bd 2 -relief groove]
    set fr1 [frame $fr0.fr1]
      set lab1 [ttk::label $fr1.lab1 -text "UUT Software"]
      set rb1 [ttk::radiobutton $fr1.rb1 -text "From DBR" -value "fromDbr" -variable  gaTmpSet(uutSWfrom)]
      set en1 [ttk::entry $fr1.en1 -justify center -width 8 -textvariable gaTmpSet(dbrSWnum)]  ; # -editable 1
      set en2 [ttk::entry $fr1.en2 -justify center -width 12 -textvariable gaTmpSet(SWver)]    ; # -editable 1
      set rb2 [ttk::radiobutton $fr1.rb2 -text "Manual" -value "manual" -variable  gaTmpSet(uutSWfrom)]
      grid $rb1 $en1 $en2 -sticky w -padx 2 -pady 2
      #22/02/2021 11:30:49 grid $rb2 -sticky w -padx 2 -pady 2
    
    set fr2 [frame $fr0.fr2]
      set txt "UUT Software"
      set f UutSWpath
      set b1 [ttk::button $fr2.brw -text "Browse..." -command [list BrowseCF $txt $f] ]
      set b2 [ttk::button $fr2.cl  -image [image create photo -file images/clear1.ico] -command [list ClearInvLabel $f] ]
      set lab2 [ttk::label $fr2.lab2  -relief sunken -textvariable gaTmpSet($f) -width $pathWith] 
      grid $b1 $lab2 $b2  -sticky w -padx 2 -pady 2
      
    
    grid $fr1  -padx 2 -pady 2 -sticky ew
    #22/02/2021 11:30:45 grid $fr2  -padx 2 -pady 2  -sticky ew
  pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1
  
  set fr [TitleFrame $base.fr3 -text "Main Card" -bd 2 -relief groove]
    set fr1 [$fr getframe]
    set lab1 [ttk::label $fr1.lab1 -text "HW version"]
    set cmb1 [ttk::entry $fr1.cmb1 -textvariable gaTmpSet(mainHW) -state normal  -width 5 ]
#     set cmb1 [ttk::combobox $fr1.cmb1 -textvariable gaTmpSet(mainHW) -values [list 0.0 0.1 0.2 0.3] -width 5 ]
    set lab2 [ttk::label $fr1.lab2 -text "PCB ID"]
    set en1 [ttk::entry $fr1.en1 -textvariable gaTmpSet(mainPcbId) -width 33]
    set lab3 [ttk::label $fr1.lab3 -text "HW Addition"]
    set en2 [ttk::entry $fr1.en2 -textvariable gaTmpSet(hwAdd) -width 33]
    
    grid $lab1 $cmb1 -sticky w -padx 2 -pady 2
    grid $lab2 $en1 -sticky w -padx 2 -pady 2
    grid $lab3 $en2 -sticky w -padx 2 -pady 2
  pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1
  
  set fr [TitleFrame $base.fr4 -text "Sub-1 Card" -bd 2 -relief groove]
    set fr1 [$fr getframe]
    set lab1 [ttk::label $fr1.lab1 -text "HW version"]
    set cmb1 [ttk::entry $fr1.cmb1 -textvariable gaTmpSet(sub1HW) -state normal -width 5 ]
    set lab2 [ttk::label $fr1.lab2 -text "PCB ID"]
    set en1 [ttk::entry $fr1.en1 -textvariable gaTmpSet(sub1PcbId) -width 33]
    
    grid $lab1 $cmb1 -sticky w -padx 2 -pady 2
    grid $lab2 $en1 -sticky w -padx 2 -pady 2
  pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1

  set fr [TitleFrame $base.fr5 -text "LXD" -bd 2 -relief groove]
    set fr0 [$fr getframe]
  #set fr [frame $base.fr2 -bd 2 -relief groove]
    set fr2 [ttk::frame $fr0.fr2]
      set txt "LXD"
      set f LXDpath
      set b1 [ttk::button $fr2.brw -text "Browse..." -command [list BrowseCF $txt $f] ]
      set b2 [ttk::button $fr2.cl  -image [image create photo -file images/clear1.ico] -command [list ClearInvLabel $f] ]
      set lab2 [ttk::label $fr2.lab2 -relief sunken -textvariable gaTmpSet($f) -width $pathWith] 
      grid $b1 $lab2 $b2  -sticky w -padx 2 -pady 2
      
    grid $fr2  -padx 2 -pady 2  -sticky ew
#   pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1
  
  set fr [ttk::frame $base.fr6  -relief groove]
    set lab1 [ttk::label $fr.lab1 -text "CSL"  -width 9]
    set en1 [ttk::entry $fr.en1 -textvariable gaTmpSet(csl) -width 3]
    grid $lab1 $en1 -sticky w -padx 2 -pady 2
  pack $fr  -anchor w  -pady 2 -padx 2  -fill both -expand 1
  
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [ttk::button $base.frBut.butImp -text Import -command ButImportInventory -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butCanc -text Cancel -command ButCancInventory -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butOk -text Ok -command ButOkInventory -width 7]  -side right -padx 6
  
  focus -force $base
  #grab $base
  return {}  
}

# ***************************************************************************
# BrowseCF
# ***************************************************************************
proc BrowseCF {txt f} {
  global gaTmpSet gaSet
  puts "BrowseCF <$txt> <$f>"
  set dir [file join c:/download]/etx1p
#   switch -exact -- $f {
#     BootCF - SWCF {
#       set dir [file join c:/download]
#     } 
#     default {
#       set dir [file join [file dirname [pwd]] ConfFiles]
#     } 
#   }
  
  set fil [tk_getOpenFile -title $txt -initialdir $dir]
  if {$fil!=""} {
    set gaTmpSet($f) $fil
  }
  focus -force .topHwInit
}
# ***************************************************************************
# ClearInvLabel
# ***************************************************************************
proc ClearInvLabel {f} {
  global gaSet gaGui  gaTmpSet
  set gaTmpSet($f) ""
}

# ***************************************************************************
# ButImportInventory
# ***************************************************************************
proc ButImportInventory {} {
  global gaSet gaTmpSet
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
  if {$fil!=""} {  
    set gaTmpSet(DutFullName) $gaSet(DutFullName)
    set gaTmpSet(DutInitName) $gaSet(DutInitName)
    set DutInitName $gaSet(DutInitName)
    
    source $fil
    set parL [list sw]
    foreach par $parL {
      set gaTmpSet($par) $gaSet($par)
    }
    
    set gaSet(DutFullName) $gaTmpSet(DutFullName)
    set gaSet(DutInitName) $DutInitName ; #xcxc ; #gaTmpSet(DutInitName)    
  }    
  focus -force .topHwInit
}
#***************************************************************************
#** ButOk
#***************************************************************************
proc ButOkInventory {} {
  global gaSet gaTmpSet
  
  if ![file exists uutInits] {
    file mkdir uutInits
  }
    
  set saveInitFile 0
  foreach nam [array names gaTmpSet] {
#     ## new unit
#     if ![info exists gaSet($nam)] {
#       set gaSet($nam) $gaTmpSet($nam)
#     }
    if {$gaTmpSet($nam)!=$gaSet($nam)} {
      puts "ButOkInventory1 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
      #set gaSet($nam) $gaTmpSet($nam)      
      set saveInitFile 1 
      break
    }  
  }
  
  if {![file exists uutInits/$gaSet(DutInitName)]} {
    set saveInitFile 1
  }
  
  if {$saveInitFile=="0"} {
    puts "ButOkInventory no difference"
  } elseif {$saveInitFile=="1"} {
    set res Save
    if {[file exists uutInits/$gaSet(DutInitName)]} {
      set txt "Init file for \'$gaSet(DutFullName)\' exists.\n\nAre you sure you want overwright the file?"
      set res [DialogBox -title "Save init file" -message  $txt -icon images/question \
          -type [list Save "Save As" Cancel] -default 2]
      if {$res=="Cancel"} {return -1}
    }
    if {$res=="Save"} {
      #SaveUutInit uutInits/$gaSet(DutInitName)
      set fil "uutInits/$gaSet(DutInitName)"
    } elseif {$res=="Save As"} {
      set fil [tk_getSaveFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
      if {$fil!=""} {        
        set fil1 [file tail [file rootname $fil]]
        puts fil1:$fil1
        set gaSet(DutInitName) $fil1.tcl
        set gaSet(DutFullName) $fil1
        #set gaSet(entDUT) $fil1
        #wm title . "$gaSet(pair) : $gaSet(DutFullName)"
        if $gaSet(demo) {
          wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
        } else {
          wm title . "$gaSet(pair) : $gaSet(DutFullName)"
        }
        #SaveUutInit $fil
        update
      }
    } 
    puts "ButOkInventory fil:<$fil>"
    if {$fil!=""} {
      foreach nam [array names gaTmpSet] {
        if {$gaTmpSet($nam)!=$gaSet($nam)} {
          puts "ButOkInventory2 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
          set gaSet($nam) $gaTmpSet($nam)      
        }  
      }
      #mparray gaTmpSet
      #mparray gaSet
      SaveUutInit $fil
    } 
    
  }
  
  array unset gaTmpSet
  SaveInit
  #BuildTests
  ButCancInventory
}


#***************************************************************************
#** ButCancInventory
#***************************************************************************
proc ButCancInventory {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}


#***************************************************************************
#** Quit
#***************************************************************************
proc Quit {} {
  global gaSet
  SaveInit
  RLSound::Play information
  set ret [DialogBox -title "Confirm exit"\
      -type "yes no" -icon images/question -aspect 2000\
      -text "Are you sure you want to close the application?"]
  if {$ret=="yes"} {exit}
  if {$ret=="yes"} {SQliteClose; CloseRL; IPRelay-Green; exit}
}

#***************************************************************************
#** CaptureConsole
#***************************************************************************
proc CaptureConsole {} {
  console eval { 
    set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"]
    if ![file exists c:/temp] {
      file mkdir c:/temp
      after 1000
    }
    set fi c:\\temp\\ConsoleCapt_[set ti].txt
    if [file exists $fi] {
      set res [tk_messageBox -title "Save Console Content" \
        -icon info -type yesno \
        -message "File $fi already exist.\n\
               Do you want overwrite it?"]      
      if {$res=="no"} {
         set types { {{Text Files} {.txt}} }
         set new [tk_getSaveFile -defaultextension txt \
                 -initialdir c:\\ -initialfile [file rootname $fi]  \
                 -filetypes $types]
         if {$new==""} {return {}}
      }
    }
    set aa [.console get 1.0 end]
    set id [open $fi w]
    puts $id $aa
    close $id
  }
}

#***************************************************************************
#** ButRun
#***************************************************************************
proc ButRun {} {
  global gaSet gaGui glTests gRelayState
  
  if {[wm title .]=="$gaSet(pair) : " || [wm title .]=="DEMO!!! $gaSet(pair)" || \
      ![info exists glTests]  || ![llength $glTests]} {
    Ramzor red on
    RLSound::Play fail
    set txt "Scan ID Barcode first"
    DialogBoxRamzor -icon /images/error -text $txt -title "Wrong Tests definition"
    set gaSet(fail) $txt
    Status $txt red
    return -2
  }
  set ret 0
  
  Ramzor green on
  
  pack forget $gaGui(frFailStatus)
  set gaSet(ButRunTime) [clock seconds]
  Status ""
  focus $gaGui(tbrun) 
  set gaSet(runStatus) ""
  #set gaSet(prompt) "-1p"
  set ::wastedSecs 0
  
  set gaSet(1.barcode1.IdMacLink) ""
  
  set gaSet(act) 1
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
    
  set clkSeconds [clock seconds]
  set ti [clock format $clkSeconds -format  "%Y.%m.%d-%H.%M"]
  # if ![info exists gaSet(logTime)] {
    # set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
  # }
  set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
   
  

  if ![file exists c:/logs] {
    file mkdir c:/logs
  }
  
  if {$ret==0} {
    set ret [LoadModemFiles]
    puts "ButRun ret after LoadModemFiles ret:<$ret>"
    LoadNoTraceFile
  }
  
  set gRelayState red
  IPRelay-LoopRed
  if {$ret==0} {
    Ramzor red on
    if {$gaSet(testmode) == "dataPwrOnOff"} {
      set gaSet(operator) operator
      set gaSet(operatorID) operatorID
    } else {
      set ret [GuiReadOperator]
    }
    Ramzor green on
    parray gaSet *arco*
    parray gaSet *rato*
  }
  if {$ret!=0} {
    set ret -3
  } elseif {$ret==0} {
    set ret [ReadBarcode] ; #0 ; # in GetDbrName [ReadBarcode]
    parray gaSet *arco*
    parray gaSet *rato*
#   if {$ret=="-1"} {
#     #return $ret
# #     ## SKIP is pressed, we can continue
# #     set ret 0
# #     set gaSet(1.barcode1) "skipped" 
#   }
  }
    
  # 08:59 11/10/2023  
  # if {$ret==0} {
    # if {![file exists uutInits/$gaSet(DutInitName)]} {
      # set txt "Init file for \'$gaSet(DutFullName)\' is absent"
      # Status  $txt
      # set gaSet(fail) $txt
      # set gaSet(curTest) $gaSet(startFrom)
      # set ret -1
      # AddToPairLog $gaSet(pair) $gaSet(fail)
    # }
  # }
  
  
  if {$ret==0} {
    if {$gaSet(relDebMode)=="Debug"} {
      #RLSound::Play beep
      RLSound::Play information
      set txt "Be aware!\r\rYou are about to perform tests in Debug mode.\r\r\
      If you are not sure, in the GUI's \'Tools\'->\'Release / Debug mode\' choose \"Release Mode\""
      set res [DialogBoxRamzor -icon images/info -type "Continue Abort" -text $txt -default 0 -aspect 2000 -title "Release / Debug mode"]
      if {$res=="Abort"} {
        set ret -1
        set gaSet(fail) "Debug mode abort"
        Status "Debug mode abort"
  #       AddToLog $gaSet(fail)
        AddToPairLog $gaSet(pair) $gaSet(fail)
      } else {
        AddToPairLog $gaSet(pair) "\n!!! DEBUG MODE !!!\n"
        set ret 0
      }
    }
    foreach v {SWver} {
      if {$gaSet($v)=="??"} {
        puts "ButRun v:$v gaSet($v):$gaSet($v)"
        set txt "Init file for \'$gaSet(DutFullName)\' is wrong"
        Status  $txt
        set gaSet(fail) $txt
        set gaSet(curTest) $gaSet(startFrom)
        set ret -1
        AddToPairLog $gaSet(pair) $gaSet(fail)
        break
      }
    }
  }
  if {$ret==0} {
    if {$gaSet(testmode) == "finalTests"} {
      RLSound::Play information
      
      set txt "Connect all cables, SIM cards and antennas according to the ordered option" ; #, SD card
      set txt2 "\n\nSet J18 to 2-3, J19 to 1-2, J20 to 1-2, J21 to 1-2"
      if $gaSet(showBoot) {
        append txt $txt2
      }
      set res [DialogBoxRamzor -icon images/info -type "Continue Abort" -text $txt -default 0 -aspect 2000 -title "SF-1p"]
      if {$res=="Abort"} {
        set ret -2
        set gaSet(fail) "User stop"
        AddToPairLog $gaSet(pair) $gaSet(fail)
      } else {
        set ret 0
      }
    }
  }
  
  if {$ret==0} {
    AddToPairLog $gaSet(pair) "$gaSet(operatorID) $gaSet(operator)"
  
    ToggleComDut 
   
    set IdBarcode $gaSet(1.barcode1)
    set traceId $gaSet(1.traceId)
    puts "\nButRun IdBarcode:<$IdBarcode> traceId:<$traceId>"
    if {$gaSet(manualCSL)=="0"} {
      #  set ret [RetriveIdTraceData  $IdBarcode CSLByBarcode]
      foreach {ret resTxt} [::RLWS::Get_CSL $IdBarcode] {}
      if {$ret!="0"} {
        after 2000
        foreach {ret resTxt} [::RLWS::Get_CSL $IdBarcode] {}
      }
    } else {
      set ret 0
      set resTxt $gaSet(manualCSL)
      # set ret [dict set di CSL $gaSet(manualCSL)]
    }
    puts "ButRun CSL ret:<$ret>"
    if {$ret=="0"} {
      # set gaSet(csl) [dict get $ret CSL]
      set gaSet(csl) $resTxt
      AddToPairLog $gaSet(pair) "CSL: $gaSet(csl)"
    } else {
      # set gaSet(fail) "Fail to get CSL for $IdBarcode"
      set gaSet(fail) $resTxt
    }
    if {$ret==0} {
      # 09:20 15/05/2024 No TraceID
      # set ret [RetriveIdTraceData $traceId PCBTraceabilityIDData]
      # puts "ButRun PCBret:<$ret>"
      # if {$ret!="-1"} {
        # set gaSet(mainPcbId)  [dict get $ret pcb]
        # AddToPairLog $gaSet(pair) "MainPcb: $gaSet(mainPcbId)"
        # set  res [regexp {REV([\d\.]+)[A-Z]} $gaSet(mainPcbId)  ma gaSet(mainHW)]
        # if {$res==1} {
          # set ret 0
        # } else {
          # set ret -1
          # set gaSet(fail) "Fail to retrive mainHW from mainPcbId"
        # }  
      # } else {
        # set gaSet(fail) "Fail to get PCB_Data for $traceId"
      # }  
    }
  }
  if {$ret==0} {
    IPRelay-Green
    Status ""
    set gaSet(curTest) [$gaGui(startFrom) cget -text]
    console eval {.console delete 1.0 "end-1001 lines"}
    pack forget $gaGui(frFailStatus)
    $gaSet(startTime) configure -text " Start: [MyTime] "
    $gaGui(tbrun) configure -relief sunken -state disabled
    $gaGui(tbstop) configure -relief raised -state normal
    $gaGui(tbpaus) configure -relief raised -state normal
    set gaSet(fail) ""
    foreach wid {startFrom} {
      $gaGui($wid) configure -state disabled
    }
    #.mainframe setmenustate tools disabled
    update

    RLTime::Delay 1
    catch {unset gaSet(1.mac1)}
    catch {unset gaSet(1.imei1)}
    catch {unset gaSet(1.imei2)}
    
    set ret 0
    GuiPower all 1 ; ## power ON before OpenRL
    set gaSet(plEn) 0
    if {$ret==0} {
       if {$ret==0} {
        IPRelay-Green
        set ret [OpenRL]
        if {$ret==0} {
          set gaSet(runStatus) ""
          set ret [Testing]
        }
      }
    }
    puts "ret of Testing: $ret"  ; update
    foreach wid {startFrom } {
      $gaGui($wid) configure -state normal
    }
    .mainframe setmenustate tools normal
    puts "end of normal widgets"  ; update
    update
    set retC [CloseRL]
    puts "ret of CloseRL: $retC"  ; update
    
    set gaSet(oneTest) 0
    set gaSet(rerunTesterMulti) conf
    set gaSet(nextPair) begin    
    
    set gRelayState red
    IPRelay-LoopRed
  }
  
  Ramzor red on
  if {$ret==0} {
    RLSound::Play pass
    Status "Done"  green
    file rename -force $gaSet(log.$gaSet(pair)) [file rootname $gaSet(log.$gaSet(pair))]-Pass.txt
    set log [file rootname $gaSet(log.$gaSet(pair))]-Pass.txt
    set gaSet(runStatus) Pass
	  
	  set gaSet(curTest) ""
	  set gaSet(startFrom) [lindex $glTests 0]
  } elseif {$ret==1} {
    RLSound::Play information
    Status "The test has been perform"  yellow
    set log ""
  } else {
    set gaSet(runStatus) Fail  
    if {$ret=="-2"} {
	    set gaSet(fail) "User stop"
      ## do not include UserStop in statistics
      set gaSet(runStatus) ""  
	  }
    if {$ret=="-3"} {
	    ## do not include No Operator fail in statistics
      set gaSet(runStatus) ""  
	  }
    if {$ret=="-4"} {
	    ## do not include SW_update fail in statistics
      set gaSet(runStatus) ""  
	  }
    if {$gaSet(runStatus)!=""} {
      UnregIdBarcode $gaSet(1.barcode1)
    }
	  pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
	  RLSound::Play fail
	  Status "Test FAIL"  red
    if [info exists gaSet(log.$gaSet(pair))] {
	    file rename -force $gaSet(log.$gaSet(pair)) [file rootname $gaSet(log.$gaSet(pair))]-Fail.txt   
      set log [file rootname $gaSet(log.$gaSet(pair))]-Fail.txt 
    }  

    set gaSet(startFrom) $gaSet(curTest)
    update
  }
  if {[info exists log] && $gaSet(dutFam.dryCon)=="GO"} {
    if ![file exists c:/logs/GO] {
      file mkdir c:/logs/GO
    }
    if {$log!=""} {
      file copy -force $log c:/logs/GO
    }
  }
  if {$gaSet(runStatus)!=""} {
    SQliteAddLine
  }
  SendEmail "SF-1P" [$gaSet(sstatus) cget -text]
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  
  if {$ret==0 || $ret==1} {
    set txt ""
    set bg yellow
    set fg blue
    set fnt {TkDefaultFont 11}
  } else {
    set txt ""
    set bg SystemButtonFace
    set fg SystemWindowText
    set fnt {TkDefaultFont 9}
  }
  
  if {$ret==0 && $gaSet(DutFullName) == "ETX-1P_A/ACEX/1SFP1UTP/4UTP/LR9/G/LTA/2R"} {
    set txt2 "\n\nVerify Lora GatewayID and ICCID at DBR"
  } else {
    set txt2 ""
  }
  set res [DialogBoxRamzor -type "OK" -icon /images/info -title "Finish" -message "The test is done ${txt}${txt2}" \
    -bg $bg -font $fnt -fg $fg]
  update
  Ramzor all off
  
  if $gaSet(demo) {
    wm title . "DEMO!!! $gaSet(pair)"
  } else {
    # 16:13 23/09/2024 wm title . "$gaSet(pair) : "
  }
  
  # if {$gaSet(eraseTitle)==1} {
    # #wm title . "$gaSet(pair) : "
    # if $gaSet(demo) {
      # wm title . "DEMO!!! $gaSet(pair)"
    # } else {
      # wm title . "$gaSet(pair) : "
    # }
  # }
  focus -force $gaGui(entDUT)
  update
}


#***************************************************************************
#** ButStop
#***************************************************************************
proc ButStop {} {
  global gaGui gaSet
  set gaSet(act) 0
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  foreach wid {startFrom } {
    $gaGui($wid) configure -state normal
  }
  .mainframe setmenustate tools normal
  CloseRL
  update
}
# ***************************************************************************
# ButPause
# ***************************************************************************
proc ButPause {} {
  global gaGui gaSet
  if { [$gaGui(tbpaus) cget -relief] == "raised" } {
    $gaGui(tbpaus) configure -relief "sunken"     
    #CloseRL
  } else {
    $gaGui(tbpaus) configure -relief "raised" 
    #OpenRL   
  }
        
  while { [$gaGui(tbpaus) cget -relief] != "raised" } {
    RLTime::Delay 1
  }  
}
# ***************************************************************************
# GuiReleaseDebugMode
# ***************************************************************************
proc GuiReleaseDebugMode {} {
  global gaSet gaGui gaTmpSet glTests 
  
  set base .topReleaseDebugMode
  if [winfo exists $base] {
    wm deiconify $base
    return {}
  }
    
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Release/Debug Mode"
  
   array unset gaTmpSet
   
  if ![info exists gaSet(relDebMode)] {
    set gaSet(relDebMode) Release  
  }
  foreach par {relDebMode} {
    set gaTmpSet($par) $gaSet($par) 
  }
    
  set fr1 [ttk::frame $base.fr1 -relief groove]
    set fr11 [ttk::frame $fr1.fr11]
      set gaGui(rbRelMode) [ttk::radiobutton $fr11.rbRelMode -text "Release Mode" -variable gaTmpSet(relDebMode) -value Release -command ToggleRelDeb]
      set gaGui(rbDebMode) [ttk::radiobutton $fr11.rbDebMode -text "Debug Mode" -variable gaTmpSet(relDebMode) -value Debug -command ToggleRelDeb]
      set gaGui(butBuildTest) [ttk::button $fr11.butBuildTest -text "Refresh Tests" \
           -command {
               BuildTests
               after 200
               ButCancReleaseDebugMode
               after 100
               update
               GuiReleaseDebugMode
           }]      
      pack $gaGui(rbRelMode) $gaGui(rbDebMode) $gaGui(butBuildTest) -anchor nw
      
    set fr12 [ttk::frame $fr1.fr12]
      set fr121 [ttk::frame $fr12.fr121]
        set l2 [ttk::label $fr121.l2 -text "Available Tests"]
        pack $l2 -anchor w
        scrollbar $fr121.yscroll -command {$gaGui(lbAllTests) yview} -orient vertical
        pack $fr121.yscroll -side right -fill y
        set gaGui(lbAllTests) [ListBox $fr121.lb1  -selectmode multiple \
            -yscrollcommand "$fr121.yscroll set" -height 25 -width 33 \
            -dragenabled 1 -dragevent 1 -dropenabled 1 -dropcmd DropRemTest]
        pack $gaGui(lbAllTests) -side left -fill both -expand 1
        
      set fr122 [frame $fr12.fr122 -bd 0 -relief groove]
        grid [button $fr122.b0 -text ""   -command {} -state disabled -relief flat] -sticky ew
        $fr122.b0 configure -background [ttk::style lookup . -background disabled]
        grid [set gaGui(addOne) [ttk::button $fr122.b3 -text ">"  -command {AddTest sel}]] -sticky ew
        grid [set gaGui(addAll) [ttk::button $fr122.b4 -text ">>" -command {AddTest all}]] -sticky ew
        grid [set gaGui(remOne) [ttk::button $fr122.b5 -text "<"  -command {RemTest sel}]] -sticky ew
        grid [set gaGui(remAll) [ttk::button $fr122.b6 -text "<<" -command {RemTest all}]] -sticky ew
            
      set fr123 [frame $fr12.fr123 -bd 0 -relief groove]  
        set l3 [Label $fr123.l3 -text "Tests to run"]
        pack $l3 -anchor w  
        scrollbar $fr123.yscroll -command {$gaGui(lbTests) yview} -orient vertical  
        pack $fr123.yscroll -side right -fill y
        set gaGui(lbTests) [ListBox $fr123.lb2  -selectmode multiple \
            -yscrollcommand "$fr123.yscroll set" -height 25 -width 33 \
            -dragenabled 1 -dragevent 1 -dropenabled 1 -dropcmd DropAddTest] 
        pack $gaGui(lbTests) -side left -fill both -expand 1  
      
      grid $fr121 $fr122 $fr123 -sticky news  
          
    pack $fr11 -side left -padx 14 -anchor n -pady 2
    pack $fr12 -side left -padx 2 -anchor n -pady 2
  pack $fr1  -padx 2 -pady 2
  pack [ttk::frame $base.frBut] -pady 4 -anchor e    -padx 2 
    #pack [Button $base.frBut.butImp -text Import -command ButImportInventory -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butCanc -text Cancel -command ButCancReleaseDebugMode -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butOk -text Ok -command ButOkReleaseDebugMode -width 7]  -side right -padx 6
  
  #BuildTests
  ##ToggleTestMode  ; just in ASMi54
  foreach te $glTests {
    $gaGui(lbAllTests) insert end $te -text $te
  }
  
  ToggleRelDeb
  
  focus -force $base
  grab $base
  return {}  
}
# ***************************************************************************
# ButCancReleaseDebugMode
# ***************************************************************************
proc ButCancReleaseDebugMode {} {
  grab release .topReleaseDebugMode
  focus .
  destroy .topReleaseDebugMode
}
# ***************************************************************************
# ButOkReleaseDebugMode
# ***************************************************************************
proc ButOkReleaseDebugMode {} {
  global gaGui gaSet gaTmpSet glTests
  
  if {[llength [$gaGui(lbTests) items]]==0} {
    return 0
  }
  
  set gaSet(relDebMode) $gaTmpSet(relDebMode) 
  
  set glTests [$gaGui(lbTests) items]
  set gaSet(startFrom) [lindex $glTests 0]
  
  $gaGui(startFrom) configure -values $glTests
  if {$gaSet(relDebMode)=="Debug"} {
    set gaSet(debugTests) $glTests
  }
  
  if {[llength [$gaGui(lbAllTests) items]] != [llength [$gaGui(lbTests) items]]} {
    Status "Debug Mode" red
  }
  array unset gaTmpSet
  #SaveInit
  #BuildTests
  if {$gaSet(relDebMode)=="Debug"} {
    set bg yellow
  } else {
    set bg SystemButtonFace
  }
  $gaGui(labRelDebMode) configure -text $gaSet(relDebMode) -bg $bg
  ButCancReleaseDebugMode
}  
# ***************************************************************************
# AddTest
# ***************************************************************************
proc AddTest {mode} {
   global gaSet gaGui
   if {$mode=="sel"} {
     set ftL [$gaGui(lbAllTests) selection get]
   } elseif {$mode=="all"} {
     set ftL [$gaGui(lbAllTests) items]
   }
   foreach ft $ftL {
     if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
       $gaGui(lbTests) insert end $ft -text $ft
     }
   }
   $gaGui(lbAllTests) selection clear
   $gaGui(lbTests) reorder [lsort -dict [$gaGui(lbTests) items]]
}
# ***************************************************************************
# RemTest
# ***************************************************************************
proc RemTest {mode} {
   global gaSet gaGui
   if {$mode=="sel"} {
     set ftL [$gaGui(lbTests) selection get]
   } elseif {$mode=="all"} {
     set ftL [$gaGui(lbTests) items]
     eval $gaGui(lbTests) selection set $ftL
#      RLSound::Play beep
#      set res [DialogBox -title "Remove all tests" -type [list Cancel Yes] \
#        -text "Are you sure you want to remove ALL the tests?" -icon images/info]
#      if {$res=="Cancel"} {
#        $gaGui(lbTests) selection clear
#        return {}
#      }
   }
   foreach ft $ftL {
     $gaGui(lbTests) delete $ftL
   }
}
# ***************************************************************************
# DropAddTest
# ***************************************************************************
proc DropAddTest {listbox dragsource itemList operation datatype data} {
  puts [list $listbox $dragsource $itemList $operation $datatype $data]
  global gaSet gaGui
  if {$dragsource=="$gaGui(lbAllTests).c"} {
    set ft $data
    if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
      $gaGui(lbTests) insert end $ft -text $ft
    }
    $gaGui(lbTests) reorder [lsort -dict [$gaGui(lbTests) items]]
  } elseif {$dragsource=="$gaGui(lbTests).c"} {
    set destIndx [$gaGui(lbTests) index [lindex $itemList 1]]
    $gaGui(lbTests) move $data $destIndx
    $gaGui(lbTests) selection clear
    
  }
}
# ***************************************************************************
# DropRemTest
# ***************************************************************************
proc DropRemTest {listbox dragsource itemList operation datatype data} {
  puts [list $listbox $dragsource $itemList $operation $datatype $data]
  global gaSet gaGui gaTmpSet
  if {$gaTmpSet(relDebMode)=="Debug"} {
    if {$dragsource=="$gaGui(lbTests).c"} {
      set ft $data
      $gaGui(lbTests) delete $ft
    }
  }
}
# ***************************************************************************
# ToggleRelDeb
# ***************************************************************************
proc ToggleRelDeb {} {
  global gaGui gaTmpSet
  if {$gaTmpSet(relDebMode)=="Release"} {
    puts "ToggleRelDeb Release"
    #BuildTests
    after 100
    AddTest all
    set state disabled
  } elseif {$gaTmpSet(relDebMode)=="Debug"} {
    puts "ToggleRelDeb Debug"
    RemTest all
    after 100 ; update
    set state normal
    if {[info exists gaSet(debugTests)] && [llength $gaSet(debugTests)]>0} {
      foreach ft $gaSet(debugTests) {
        if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
          $gaGui(lbTests) insert end $ft -text $ft
        }
      }
    }
  }
  foreach b [list $gaGui(addOne) $gaGui(addAll) $gaGui(remOne) $gaGui(remAll)] {
    $b configure -state $state
  }
}
# ***************************************************************************
# GuiReadOperator
# ***************************************************************************
proc GuiReadOperator {} {
  global gaSet gaGui gaDBox gaGetOpDBox
  catch {array unset gaDBox} 
  catch {array unset gaGetOpDBox} 
  if $::NoATP {
    puts "[MyTime] NoAtp-Operator"
    return 0
  }
  #set ret [GetOperator -i pause.gif -ti "title Get Operator" -te "text Operator's Name "]
  set sn [clock seconds]
  set ret [GetOperator -i images/oper32.ico -gn $::RadAppsPath]
  incr ::wastedSecs [expr {[clock seconds]-$sn}]
  if {$ret=="-1"} {
    set gaSet(fail) "No Operator Name"
    return $ret
  } else {
    set gaSet(operator) $ret
    return 0
  }
}   

# ***************************************************************************
# ToggleShowBoot
# ***************************************************************************
proc ToggleShowBoot {} {
   global gaSet gaGui
   if {[info exists gaSet(DutFullName)] && $gaSet(DutFullName)!=""} {
    BuildTests
  }
  SaveInit
}
# ***************************************************************************
# ConfigPowerOnOff
# ***************************************************************************
proc ConfigPowerOnOff {} {
  global gaSet gaDBox
  set entLab [list]
  
  after 500 {
    if [info exists gaSet(PowerOnOff.qty)] {
      .tmpldlg.frame.fr.f1.ent1 insert 0 $gaSet(PowerOnOff.qty)
    } else {
      .tmpldlg.frame.fr.f1.ent1 insert 0  100
    }
    if [info exists gaSet(PowerOnOff.dur)] {
      .tmpldlg.frame.fr.f2.ent2 insert 0 $gaSet(PowerOnOff.dur)
    } else {
      .tmpldlg.frame.fr.f2.ent2 insert 0 1
    }
    .tmpldlg.frame.fr.f1.ent1 configure -justify center
    .tmpldlg.frame.fr.f2.ent2 configure -justify center
  }
  lappend entLab "Quantity of the ON-OFF cycles"
  lappend entLab "Data transmission duration, in minutes"
  set ret [DialogBox -title "Data + Power OFF-ON" -entQty 2 -type "Accept Cancel" -entLab $entLab]
  if {$ret=="Cancel"} {
    return -2
  }
  set gaSet(PowerOnOff.qty)  [string trim $gaDBox(entVal1)]
  set gaSet(PowerOnOff.dur)  [string trim $gaDBox(entVal2)]
  
  BuildTests
}

