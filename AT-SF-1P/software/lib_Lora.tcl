# ***************************************************************************
# ConfigLoraDev
# ***************************************************************************
proc ConfigLoraDev {} {
  Status "Config Lora Device"
  global gaSet buffer
  
  switch -exact -- $gaSet(dutFam.lora.region) {
    eu433 {set devRate "EU433"} 
    eu868 {set devRate "EU868"}
    au915 - us902 - us915 {set devRate "US915"}   
    as923 {set devRate "AS923"}  
    default {
      set gaSet(fail) "RATE is not defined"
      return -1
    }    
  }
  
  ClearChirpStackLogs
  
  set timeout 10000
  set url http://${gaSet(LoraServerIP)}:5000/sendToLora
  set query [::http::formatQuery ConfigLoraDev  $devRate]
  puts "[MyTime] ConfigLoraDev POST $query"
  catch {::http::geturl $url -query $query -timeout $timeout} tok
  upvar #0 $tok state
  #parray state
  http::cleanup $tok
  
  set ret [ReadChirpStackLogs]
  return $ret
}

# ***************************************************************************
# JoinLoraDev
# ***************************************************************************
proc JoinLoraDev {} {
  Status "Join Lora Device"
  global gaSet buffer
  
  ClearChirpStackLogs
  
  set timeout 10000
  set url http://${gaSet(LoraServerIP)}:5000/sendToLora
  set query [::http::formatQuery JoinLoraDev ""]
  puts "[MyTime] JoinLoraDev POST $query"
  catch {::http::geturl $url -query $query -timeout $timeout} tok
  upvar #0 $tok state
  #parray state
  http::cleanup $tok
  
  set ret [ReadChirpStackLogs 60]
  if {$ret!="0"} {
    set gaSet(fail) "Join LoRa Device fail"
  }
  return $ret
}

# ***************************************************************************
# SendDataToLoraDev
# ***************************************************************************
proc SendDataToLoraDev {{data aabbccdd}} {
  Status "Send Data $data to Lora Device"
  global gaSet buffer
  
  ClearChirpStackLogs
  
  set timeout 10000
  set url http://${gaSet(LoraServerIP)}:5000/sendToLora
  set query [::http::formatQuery SendDataToLoraDev  $data]
  puts "[MyTime] SendDataToLoraDev POST $query"
  catch {::http::geturl $url -query $query -timeout $timeout} tok
  upvar #0 $tok state
  #parray state
  http::cleanup $tok
  
  set ret [ReadChirpStackLogs]
  if {$ret!="0"} {
    set gaSet(fail) "Send_Receive to LoRa Device fail"
  }
  
  return $ret
}

# ***************************************************************************
# ClearChirpStackLogs
# ***************************************************************************
proc ClearChirpStackLogs {} {
  global gaSet
  set logs [glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]
  puts "[MyTime] ClearChirpStackLogs <$logs>"; update
  if {[llength $logs]>0} {
    foreach log $logs {
      file delete -force $log
    }
  }
  set logs [glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]
  puts "[MyTime] ClearChirpStackLogs <$logs>"; update
  
  return 0
}

# ***************************************************************************
# ReadChirpStackLogs
# ***************************************************************************
proc ReadChirpStackLogs {{maxWait 20}} {
  global gaSet
  puts "[MyTime] ReadChirpStackLogs"
  set startSec [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set waitSec [expr {$nowSec - $startSec}]
    if {$waitSec > $maxWait} {
      set ret -1
      set gaSet(fail) "No result from ChirpStack"
      return $ret
    }
    set logs [glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]
    puts "[MyTime] ReadChirpStackLogs $waitSec sec <$logs>"; update
    set ret na
    if {[llength $logs]>0} {
      foreach log $logs {
        set tail [file tail $log]
        if {$tail=="OK"} {
          set ret 0
          break
        } elseif {$tail=="FAIL"} {
          set ret -1
          break
        }
      }  
    }
    if {$ret!="na"} {
      set logs [glob -nocomplain -directory //$gaSet(LoraServerHost)/c$/LoraDirs/ChirpStackLogs *]
      if {[llength $logs]>0} {
        foreach log $logs {
          file delete -force $log
        }
      }
      break
    }
    after 2000
  }
  return $ret
}
