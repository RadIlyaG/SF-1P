# ***************************************************************************
# ConfigLoraDev
# ***************************************************************************
proc ConfigLoraDev {} {
  Status "Config Lora Sensor"
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
  if [array  exists state] {
    parray state
  } else {
    set gaSet(fail) "No connection to ChirpStack"
    http::cleanup $tok
    return -1
  }  
  http::cleanup $tok
  
  set ret [ReadChirpStackLogs]
  return $ret
}

# ***************************************************************************
# JoinLoraDev
# ***************************************************************************
proc JoinLoraDev {} {
  Status "Join Lora Sensor"
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
    set gaSet(fail) "Join LoRa Sensor fail"
  }
  return $ret
}

# ***************************************************************************
# SendDataToLoraDev
# ***************************************************************************
proc SendDataToLoraDev {{data aabbccdd}} {
  Status "Send Data $data to Lora Sensor"
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
    set gaSet(fail) "Send_Receive to LoRa Sensor fail"
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
    puts "\n[MyTime] ReadChirpStackLogs $waitSec sec <$logs>"; update
    set ret na
    if {[llength $logs]>0} {
      foreach log $logs {
        set tail [file tail $log]
        puts "ReadChirpStackLogs log:<$log> tail:<$tail>"
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
          puts "ReadChirpStackLogs delete log:<$log>"
          file delete -force $log
        }
      }
      break
    }
    after 2000
  }
  return $ret
}

# ***************************************************************************
# ChirpStackGetJwtToken
# ***************************************************************************
proc ChirpStackGetJwtToken {} {
  global gaSet
  set ip $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))
  set url http://$ip:8080/api/internal/login
  set json "{\"email\": \"admin\", \"password\": \"admin\"}"
  
  set ret [catch {exec curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcyIsImV4cCI6MTY3MzUzMjE0NCwiaWQiOjEsImlzcyI6ImFzIiwibmJmIjoxNjczNDQ1NzQ0LCJzdWIiOiJ1c2VyIiwidXNlcm5hbWUiOiJhZG1pbiJ9.t13pZDY8vJdTB1UObWIr9n4Ijtirj21XdIiCfy7VsCA" -d $json $url} res]
  set jwt [string trim [lindex [split [lindex $res 0] :] 1] \"]
  puts "\nGetJwToken ret:<$ret>  res:<$res>  jwt:<$jwt>" 
  set gaSet(LoraSrvr.jwt) $jwt
  return $jwt
}
# ***************************************************************************
# ChirpStackDeleteGateway
# ChirpStackDeleteGateway 1806f5fffeb80abc
# ChirpStackDeleteGateway $gaSet(ChirpStackIPGW)  
# ***************************************************************************
proc ChirpStackDeleteGateway {gwid} {
  global gaSet
  set ip $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))
  set url http://$ip:8080/api/gateways/$gwid
  ChirpStackGetJwtToken
  set ret [catch {exec curl -X DELETE --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt) " $url} res]
  puts "ChirpStackDeleteGateway ret:<$ret>  res:<$res> "
  #curl -X DELETE --header 'Accept: application/json' --header 'Grpc-Metadata-Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcyIsImV4cCI6MTcyODk5NjA2NiwiaWQiOjEsImlzcyI6ImFzIiwibmJmIjoxNzI4OTA5NjY2LCJzdWIiOiJ1c2VyIiwidXNlcm5hbWUiOiJhZG1pbiJ9.sCj5YyHo9hXjPUqtgALnwvpUkuAzQWj65Z3MxTZK6X8' 'http://172.18.94.105:8080/api/gateways/1806f5fffeb80abc'

}
# ***************************************************************************
# ChirpStackAddGateway
  # ChirpStackAddGateway 1806f5fffeb80abc
  # serviceProfileID == \"7f865cfb-4ef6-4cb5-a416-a123cd6c0a22\" for GW_915MHz
  # serviceProfileID == \"2edad469-d273-46e4-acd2-a4e4a46902f6\" for GW-PORFILE
  # ChirpStackAddGateway 1806f5fffeb80abc 
# ***************************************************************************
proc ChirpStackAddGateway {gwid} {
  global gaSet
  set ip $gaSet(ChirpStackIP.$gaSet(dutFam.lora.fam))
  
  set loraFam $gaSet(dutFam.lora.fam)
  set pcNumb [lindex [split [info host] -] end-1]; # at-sf1p-1-10 -> 1
  set desc AuGW_${loraFam}_${pcNumb}_$gaSet(pair)
  
  if {$loraFam=="8XX"} {
    set gatewayProfileID 2edad469-d273-46e4-acd2-a4e4a46902f6
  } elseif {$loraFam=="9XX"} {
    set gatewayProfileID 50fffc41-1b08-417b-83a8-8594c73475be
  }
  set serviceProfileId 7f865cfb-4ef6-4cb5-a416-a123cd6c0a22
  
  ChirpStackGetJwtToken
  
  set url http://$ip:8080/api/gateways
  set json "{\"gateway\": {\"description\": \"$desc\", \ 
     \"discoveryEnabled\": false, \ 
     \"gatewayProfileID\": \"$gatewayProfileID\", \ 
     \"id\": \"$gwid\", \ 
     \"location\": { \ 
       \"accuracy\": 0, \ 
       \"altitude\": 0, \ 
       \"latitude\": 0, \ 
       \"longitude\": 0, \ 
       \"source\": \"UNKNOWN\" \ 
     }, \
     \"metadata\": {}, \ 
     \"name\": \"$desc\", \ 
     \"networkServerID\": \"1\", \ 
     \"organizationID\": \"1\", \ 
     \"serviceProfileID\": \"$serviceProfileId\", \ 
     \"tags\": {} \ 
  
     }}"
     
  puts "\n Add GW url:<$url>"
  puts "\n Add GW json:<$json>"
  
  
  set ret [catch {exec curl -X POST --header "Accept: application/json" \
      --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt) " -d $json $url} res]
  puts "ChirpStackAddGateway ret:<$ret>  res:<$res> "
  return 0
} 


