#***************************************************************************
#** DialogBoxEnt
#** 
#** For icon option in [pwd] must be gif file with name like icon.  
#**   error.gif for icon 'error'
#**   stop.gif  for icon 'stop'
#**
#** Input parameters:
#**   -title   Specifies a string to display as the title of the message box. 
#**            The default value is an empty string. 
#**   -text    Specifies the message to display in this message box.  
#**            The default value is an empty string. 
#**   -icon    Specifies an icon to display.
#**            If this option is not specified, then no icon will be displayed. 
#**   -type    Arranges for a predefined set of buttons to be displayed.
#**            The default value is 'ok' button.
#**   -parent  Makes window the logical parent of the message box. 
#**            The message box is displayed on top of its parent window.
#**            The default value is window '.'
#**   -aspect  Specifies a non-negative integer value indicating desired 
#**            aspect ratio for the text.
#**            The aspect ratio is specified as 100*width/height.
#**            100 means the text should be as wide as it is tall, 
#**            200 means the text should be twice as wide as it is tall, 
#**            50 means the text should be twice as tall as it is wide, and so on.
#**            Used to choose line length for text if width option isn't specified. 
#**            Defaults to 150. 
#**   -default Name gives the symbolic name of the default button 
#**            for this message window ('ok', 'cancel', and so on). 
#**            If the message box has just one button it will automatically 
#**            be made the default, otherwise if this option is not specified,
#**            there won't be any default button. 
#**
#** Return value: name of the pressed button
#** Example:
#**   DialogBox
#**   DialogBox -icon error -type "ok yes TCL" -text "Move the Cables"
#***************************************************************************
proc DialogBoxEnt {args} {

  # each option & default value
  foreach {opt def} {title "DialogBoxE" text "" icon "" type ok \
                     parent . aspect 2000 default 0 entVar ""} {
    set var$opt [Opte $args "-$opt" $def]
  }
  wm deiconify $varparent
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1]

  if {[catch {Bitmap::get [pwd]\\$varicon.gif} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }

  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
  }

  #create message
  set msg [message [$dlg getframe].msg -text $vartext -justify center \
     -anchor c -aspect $varaspect]  
  pack $msg -fill both -expand 1 -padx 10 -pady 3

  if {$varentVar!=""} {
    set ent [Entry [$dlg getframe].ent -justify center]
    pack  $ent
	 focus $ent
  }

  set ret [$dlg draw]
  if {$varentVar!=""} {
    set entryString  [$ent cget -text]
	  set ::$varentVar $entryString
  }
  destroy $dlg
  return $ret
}



#***************************************************************************
#** Opte
#***************************************************************************
proc Opte {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
} 

# ***************************************************************************
# RegBC
# ***************************************************************************
proc RegBC {} {
  global gaSet gaDBox
  Status "BarCode Registration"
   set ret  -1
  set res1 -1
  set res2 -1
  
  foreach pair 1 {
    #incr pairIndx
    #set pair [lindex $lPassPair $pairIndx]
    foreach la {1} {
      set mac [regsub -all {\:}  $gaSet($pair.mac$la) ""]
      set barcode $gaSet($pair.barcode$la)
      set barcode$la $barcode
      #puts "pairIndx:$pairIndx pair:$pair"
      Status "Registration the  MAC."
      
      set str "$::RadAppsPath/MACReg_2Mac_2IMEI.exe /$mac / /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
      set cellQty [string index $gaSet(dutFam.cell) 0]
      if {$cellQty=="1"} {
        append str " /$gaSet(1.imei1)"
      } elseif {$cellQty=="2"} {
        append str " /$gaSet(1.imei1) /$gaSet(1.imei2)"
      }
      
      set res$la [string trim [catch {eval exec $str} retVal$la]]
      
      puts "mac:$mac barcode:$barcode res$la:<[set res$la]> retVal$la:<[set retVal$la]>"
      update
      AddToPairLog $gaSet(pair) "MAC:$mac IDbarcode:$barcode"
      if {$cellQty=="1"} {
        AddToPairLog $gaSet(pair) "IMEI: $gaSet(1.imei1)"
      } elseif {$cellQty=="2"} {
        AddToPairLog $gaSet(pair) "IMEI1: $gaSet(1.imei1) IMEI2: $gaSet(1.imei2)"
      }
      #after 1000
      if {[set res$la]!="0"} {
        puts "ret:[set res$la]"
        set ret -1
        break
      } else {
        set ret 0
      }
    } 
    if {$ret!="0"} {
      break
    }
#     AddToLog "mac:$mac Barcode-1 - $barcode1" 
    
    if ![file exists c://logs//macHistory.txt] {
      set id [open c://logs//macHistory.txt w]
      after 100
      close $id
    }
    set id [open c://logs//macHistory.txt a]
    foreach la {1} {
      puts $id "[MyTime] Tester:$gaSet(pair) MAC:$gaSet($pair.mac$la) BarCode:[set barcode$la] res:[set res$la]"
    }      
    close $id
  
    if {$ret!=0} {
      break
    } 
  }  
  Status ""	  

  if {$res1 != 0} {
	  set gaSet(fail)  "Fail to update Data-Base"
	  return -1 
	} else {
 		return 0 
  }
} 

# ***************************************************************************
# CheckBcOk
# ***************************************************************************
proc CheckBcOk {readTrace} {
	global  gaDBox  gaSet
  puts "[MyTime] CheckBcOk $readTrace" ;  update
  set pair 1
  if {$gaSet(useExistBarcode)==0} {
    RLSound::Play information
    SendEmail "SF-1P" "Read barcodes"
    
    if {$readTrace==0} {
      set entQty 1
      set entLab {"ID"}
      set radButQty 0
    } else {
      # 13:37 09/05/2024
      # if {$gaSet(dutFam.ps)=="WDC" || $gaSet(dutFam.ps)=="12V"} {
        # set entQty 3
        # set entLab {"ID" "Main Card's Traceability" "PS Card's Traceability"}
        # set radButQty 3        
      # } else {
        # set entQty 2
        # set entLab {"ID" "Main Card's Traceability"}
        # set radButQty 2 
      # }
      set entQty 2
      set entLab {"ID" "Main Card's Traceability"}
      set radButQty 2
    }
    set ret [DialogBox -title "Read Barcodes" -text "Enter the SF-1P's barcode" -ent1focus 1\
        -type "Ok Cancel" -entQty $entQty -entPerRow 1 -entLab $entLab -icon /images/info] 
    #-type "Ok Cancel Skip" 12/10/2020 09:33:23    
  	if {$ret == "Cancel" } {
  	  return -2 
  	} elseif {$ret=="Ok"} {
      foreach {ent1 ent2 ent3} [lsort -dict [array names gaDBox entVal*]] {
        set barcode1 [string toupper $gaDBox($ent1)]  
        if {$readTrace==0} {        
          set traceId1 "" 
          set traceId2 ""
          set useTraceId 0
        } else {
          set traceId1 [string toupper $gaDBox($ent2)]  
          if {$entQty==3} {
            set traceId2 [string toupper $gaDBox($ent3)] 
          } else {
            set traceId2 ""
          }
          set useTraceId 1; #$gaDBox(useTraceId)
        }
        puts "barcode1:<$barcode1> traceId1:<$traceId1>  traceId2:<$traceId2> useTraceId:<$useTraceId>"
  	    if ![string is xdigit [string range $barcode1 2 end]] {
          set gaSet(fail) "Wrong barcode: $barcode1"
          return -1
        }
        if {[string length $barcode1]!=11 && [string length $barcode1]!=12} {
          set gaSet(fail) "The barcode should be 11 or 12 HEX digits"
          return -1
        }
        if {$useTraceId && ![string is digit $traceId1]} {
          set gaSet(fail) "Wrong TraceID1: $traceId1"
          return -1
        }
        if {$useTraceId && $entQty==3 && (![string is digit $traceId2] || $traceId2=="")} {
          set gaSet(fail) "Wrong TraceID2: $traceId2"
          return -1
        }
      }
      return 0  	
  	} elseif {$ret=="Skip"} {
      set gaSet(fail) "No barcode. The reading was skipped"
      return 0
    }
  } elseif {$gaSet(useExistBarcode)==1} {
    if ![info exists gaSet(1.barcode1)] {
      set gaSet(useExistBarcode) 0
      return -1
    }
    if ![info exists gaSet(1.traceId)] {
      set gaSet(useExistBarcode) 0
      return -1
    }
    
    
    set barcode $gaSet(1.barcode1)
    if ![info exists gaSet(logTime)] {
      set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
    }
    set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barcode.txt
    AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
    AddToPairLog $gaSet(pair) "UUT - $barcode"
    AddToPairLog $gaSet(pair) "MainBoard TraceID - $gaSet(1.traceId)"
    
    set gaSet(useExistBarcode) 0
    return 0
  }
}
# ***************************************************************************
# ReadBarcode
# ***************************************************************************
proc ReadBarcode {} {
  global gaSet gaDBox glTests
  puts "[MyTime] ReadBarcode" ;  update
  set ret -1
  catch {array unset gaDBox}
  
  # if {[lsearch $gaSet(noTraceL) $gaSet(DutFullName)]!="-1"} {
    # set readTrace 0
  # } else {
    # # if {[lsearch $glTests *BrdEeprom*]!="-1"} {
      # # set readTrace 1
    # # } else {
      # # set readTrace 0
    # # } 
    # set readTrace 1    
  # }
  # #set readTrace 1
  
  # 09:18 15/05/2024 No TraceID
  set readTrace 0
  
  while {$ret != "0" } {
    set ret [CheckBcOk $readTrace]
    Status $gaSet(fail)
    puts "CheckBcOk res:$ret "
    #if { $ret == "-2" ||  $ret == "-1" } {}
    if { $ret == "-2"} {
      set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}.txt
      AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
      return $ret
    }
	}	
  Status ""
  foreach {ent1 ent2 ent3} [lsort -dict [array names gaDBox entVal*]] {
    foreach la {1} {
      set barcode [string toupper $gaDBox([set ent$la])]  
      set gaSet(1.barcode$la) $barcode
      set res [IdMacLinkNoLink $barcode]
      set gaSet(1.barcode$la.IdMacLink) $res
    }
    if {$readTrace==0} {      
      set traceId ""  
      set gaSet(1.traceId) $traceId
      set gaSet(2.traceId) $traceId
      set useTraceId 0
      set gaSet(1.useTraceId) $useTraceId
      set gaSet(2.useTraceId) $useTraceId
    } else {      
      set traceId [string toupper $gaDBox($ent2)]  
      set gaSet(1.traceId) $traceId
      set useTraceId 1; #$gaDBox(useTraceId)
      set gaSet(1.useTraceId) $useTraceId
      
      set traceId2 "" 
      set gaSet(2.traceId) $traceId2
      set gaSet(2.useTraceId) 0
      if {$ent3!=""} {
        set traceId2 [string toupper $gaDBox($ent3)]  
        set gaSet(2.traceId) $traceId2
        set gaSet(2.useTraceId) 1
      }
    }
    
    if ![info exists gaSet(logTime)] {
      set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
    }
    set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barcode.txt
    AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
    AddToPairLog $gaSet(pair) "UUT - $barcode"
    if $useTraceId {
      set txt "Main Card's TraceID: $traceId"
      if {$ent3!=""} {
        append txt ", PS Card's TraceID: $traceId2"
      }
      AddToPairLog $gaSet(pair) $txt
    } else {
      AddToPairLog $gaSet(pair) "No use TraceId"
    }
  }    
  return $ret
}

# ***************************************************************************
# UnregIdBarcode
# UnregIdBarcode $gaSet(1.barcode1)
# UnregIdBarcode EA100463652
# ***************************************************************************
proc UnregIdBarcode {barcode {mac {}}} {
  global gaSet
  Status "Unreg ID Barcode $barcode"
  set res [UnregIdMac $barcode $mac]
    
  puts "\nUnreg ID Barcode $barcode res:<$res>\n"
  if {$res=="OK" || [string match "*No records to Delete by ID-Number*" $res]} {
    set ret 0
  } else {
    set ret $res
  }
  if [info exists gaSet(logFile.$gaSet(pair))] {
    AddToPairLog $gaSet(pair) "Unreg ID Barcode $barcode mac:<$mac> res:<$res> ret:<$ret>"
  }
  return $ret
}

# ***************************************************************************
# UnregIdMac
# ***************************************************************************
proc UnregIdMac {barcode {mac {}}} {
  set ret 0
  set res ""
  set url "http://ws-proxy01.rad.com:10211/ATE_WS/ws/rest/"
  #set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param "DisconnectBarcode\?mac=[set mac]\&idNumber=[set barcode]"
  append url $param
  puts "url:<$url>"
  if [catch {set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]} res] {
    return $res
  } 
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set res "http::status: <$st> http::ncode: <$nc>"
    set ret -1
  }
  upvar #0 $tok state
  #parray state
  #puts "body:<$state(body)>"
  set ret $state(body)
  ::http::cleanup $tok
  
  return $ret
}

# ***************************************************************************
# IdMacLinkNoLink
# ***************************************************************************
proc IdMacLinkNoLink {barcode} {
  global gaSet
  puts "\nIdMacLinkNoLink $barcode"
  
  foreach {res resTxt} [::RLWS::CheckMac $barcode AABBCCFFEEDD] {}
  if {$res<0} {
    set ret "error"
    set gaSet(fail) $resTxt
  } elseif {$res==0} {
    set ret $resTxt
  } elseif {$res==1} {
    set ret [lindex [split $resTxt " "] end]
  }
  return $ret
  
  # set res [catch {exec $gaSet(javaLocation)/java.exe -jar $::RadAppsPath/checkmac.jar $barcode AABBCCFFEEDD} retChk]
  # puts "IdMacLinkNoLink barcode:<$barcode > res:<$res> retChk:<$retChk>" ; update
  # if {$res=="1" && $retChk=="0"} {
    # puts "No Id-MAC link"
    # set ret "noLink"
  # } else {
    # puts "Id-Mac link or error"
    # if [regexp {is already connected to :(\w+)} $retChk ma val] {
      # set ret $val
    # } else {
      # set ret "error"
    # }
  # } 
  # return $ret
}