console show

# package require http
# source Lib_Put_SF1P.tcl
# source Lib_Gen_SF1P.tcl

# ***************************************************************************
# ConfigLoraDev
# ***************************************************************************
proc ConfigLoraDev {} {
  global gaSet buffer
  Status "Config Lora Device"
  set com $gaSet(comLoraDev)
  RLEH::Open
  set ret [RLCom::Open $com 115200 8 NONE 1]
  after 2000
  #puts "ret_openCom: <$ret>"
  set gaSet(fail) "Config Lora Device fail"
  set ret [Send $com "at+set_config=lora:join_mode:0\r\n" "OK"] 
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    
    set ret [Send $com "at+set_config=lora:class:0\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:region:EU868\r\n" "OK"] ; # AS923
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:confirm:1\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:dev_eui:60C5A8FFFE7841A6\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:app_eui:60C5A8FFF8680833\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:app_key:60C5A8FFF868083360C5A8FFF8680833\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret [Send $com "at+set_config=lora:work_mode:0\r\n" "OK"]
  }
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret 0
  } else {
    set ret -1
  }
  
  RLCom::Close $com
  RLEH::Close
  return $ret
}
# ***************************************************************************
# JoinLoraDev
# ***************************************************************************
proc JoinLoraDev {} {
  Status "Join Lora Device"
  global gaSet buffer
  set com $gaSet(comLoraDev)
  #RLEH::Open
  set ret [RLCom::Open $com 115200 8 NONE 1]
  after 500
  #puts "ret_openCom: <$ret>"
  set gaSet(fail) "Join Lora Device fail"
  set ret [Send $com "at+join\r\n" "OK" 60]
  
  if {$ret==0 && [string match {*Join Success OK*} $buffer]} {
    set ret 0
  } else {
    set ret -1
  }
  
  RLCom::Close $com
  #RLEH::Close
  return $ret
}

# ***************************************************************************
# StatusLoraDev
# ***************************************************************************
proc StatusLoraDev {} {
  global gaSet buffer
  set com $gaSet(comLoraDev)
  RLEH::Open
  set ret [RLCom::Open $com 115200 8 NONE 1]
  after 500
  #puts "ret_openCom: <$ret>"
  set gaSet(fail) "Status Lora Device fail"
  set ret [Send $com "at+get_config=device:status\r\n" "OK"]
  
  # if {$ret==0 && [string match {*success OK*} $buffer]} {
    # set ret 0
  # } else {
    # set ret -1
  # }
  
  RLCom::Close $com
  RLEH::Close
  return $ret
}
# ***************************************************************************
# SendDataToLoraDev
#  at+send=lora:1:11223344
# ***************************************************************************
proc SendDataToLoraDev {{data aabbccdd}} {
  global gaSet buffer
  Status "Send Data $data to Lora Device"
  set com $gaSet(comLoraDev)
  #RLEH::Open
  set ret [RLCom::Open $com 115200 8 NONE 1]
  after 200
  #puts "ret_openCom: <$ret>"
  set gaSet(fail) "Send Data to Lora Device fail"
  set ret [Send $com "at+send=lora:1:$data\r\n" "OK"]
  
  if {$ret==0 && [string match {*success OK*} $buffer]} {
    set ret 0
  } else {
    set ret -1
  }
  
  RLCom::Close $com
  #RLEH::Close
  return $ret
}

# ***************************************************************************
# GetJwtToken
# ***************************************************************************
proc GetJwtToken {} {
  global gaSet
  set url http://172.18.93.38:8080/api/internal/login
  set json "{\"email\": \"admin\", \"password\": \"admin\"}"
  
  set ret [catch {exec curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcyIsImV4cCI6MTY3MzUzMjE0NCwiaWQiOjEsImlzcyI6ImFzIiwibmJmIjoxNjczNDQ1NzQ0LCJzdWIiOiJ1c2VyIiwidXNlcm5hbWUiOiJhZG1pbiJ9.t13pZDY8vJdTB1UObWIr9n4Ijtirj21XdIiCfy7VsCA" -d $json $url} res]
  set jwt [string trim [lindex [split [lindex $res 0] :] 1] \"]
  puts "\nGetJwToken ret:<$ret>  res:<$res>  jwt:<$jwt>" 
  set gaSet(LoraSrvr.jwt) $jwt
 
 # curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'Grpc-Metadata-Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcyIsImV4cCI6MTY3MzUzMjE0NCwiaWQiOjEsImlzcyI6ImFzIiwibmJmIjoxNjczNDQ1NzQ0LCJzdWIiOiJ1c2VyIiwidXNlcm5hbWUiOiJhZG1pbiJ9.t13pZDY8vJdTB1UObWIr9n4Ijtirj21XdIiCfy7VsCA' -d '{ \ 
   # "email": "admin", \ 
   # "password": "admin" \ 
 # }' 'http://172.18.93.38:8080/api/internal/login'
}

# ***************************************************************************
# GWsSumm
# ***************************************************************************
proc GWsSumm {} {
  global gaSet
  set url http://172.18.93.38:8080/api/internal/gateways/summary
  
  set ret [catch {exec curl -X GET --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt)" $url} res]
  puts "\GWsSumm ret:<$ret>  res:<$res> " 
}

# ***************************************************************************
# GetDevice
# ***************************************************************************
proc GetDevice {} {
  global gaSet
  set url http://172.18.93.38:8080/api/devices/60C5A8FFFE7841A6
  set ret [catch {exec curl -X GET --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt)" $url} res]
  
  puts "\GetDevice ret:<$ret>  res:<$res> " 
}
# ***************************************************************************
# GetDevActivation
# ***************************************************************************
proc GetDevActivation {} {
  global gaSet
  set url http://172.18.93.38:8080/api/devices/60C5A8FFFE7841A6/activation
  set ret [catch {exec curl -X GET --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt)" $url} res]
  
  puts "\GetDevActivation ret:<$ret>  res:<$res> " 
}
# ***************************************************************************
# GetDevFrames
# ***************************************************************************
proc GetDevFrames {} {
  global gaSet
  set url http://172.18.93.38:8080/api/devices/60C5A8FFFE7841A6/frames
  set ret [catch {exec curl -X GET --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt)" $url &} res]
  
  puts "\GetDevFrames ret:<$ret>  res:<$res> " 
}

# ***************************************************************************
# GetDeviceQueueItem
# ***************************************************************************
proc GetDeviceQueueItem {} {
  global gaSet
  set url http://172.18.93.38:8080/api/devices/60C5A8FFFE7841A6/queue
  set json "{\"deviceQueueItem\": {\"confirmed\": true, \"data\": \"qrvM3Q==\", \"fPort\": 1 }}"
  set ret [catch {exec curl -X POST --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer $gaSet(LoraSrvr.jwt) " -d $json $url} res]
  
  puts "\GetDeviceQueueItem ret:<$ret>  res:<$res> " 
}


if 0 {

1806f5fffeb8272c

JWT TOKEN
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhcyIsImV4cCI6MTY3MzAwMjA1OCwiaWQiOjEsImlzcyI6ImFzIiwibmJmIjoxNjcyOTE1NjU4LCJzdWIiOiJ1c2VyIiwidXNlcm5hbWUiOiJhZG1pbiJ9.FEBZw6i3-eFDaMoRglUB5PLkLC5hrg17Ib3avVD6kOo

API key ID
7ad2e10b-0297-4d74-b2e1-acee0cfaf200

API key name
loraRak811 api_key

Token
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X2lkIjoiN2FkMmUxMGItMDI5Ny00ZDc0LWIyZTEtYWNlZTBjZmFmMjAwIiwiYXVkIjoiYXMiLCJpc3MiOiJhcyIsIm5iZiI6MTY3MjkxMTY4MSwic3ViIjoiYXBpX2tleSJ9.32hIrR-SFlf5Tsi5Ne7_i_MlUJ7Sq1FJq6d5UTli-XQ

set api_token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X2lkIjoiN2FkMmUxMGItMDI5Ny00ZDc0LWIyZTEtYWNlZTBjZmFmMjAwIiwiYXVkIjoiYXMiLCJpc3MiOiJhcyIsIm5iZiI6MTY3MjkxMTY4MSwic3ViIjoiYXBpX2tleSJ9.32hIrR-SFlf5Tsi5Ne7_i_MlUJ7Sq1FJq6d5UTli-XQ"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X2lkIjoiYjViMjIyODUtOWUxMy00MzAxLWFjMGItOTMwNDI2YmY4YmZjIiwiYXVkIjoiYXMiLCJpc3MiOiJhcyIsIm5iZiI6MTY3MzkzOTMxMywic3ViIjoiYXBpX2tleSJ9.osSyTzH3iwzqVck7gEozPtvZZFKZETwfBaP5o7fnT7o

set res ""
catch {exec curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Grpc-Metadata-Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlfa2V5X2lkIjoiN2FkMmUxMGItMDI5Ny00ZDc0LWIyZTEtYWNlZTBjZmFmMjAwIiwiYXVkIjoiYXMiLCJpc3MiOiJhcyIsIm5iZiI6MTY3MjkxMTY4MSwic3ViIjoiYXBpX2tleSJ9.32hIrR-SFlf5Tsi5Ne7_i_MlUJ7Sq1FJq6d5UTli-XQ" -d "{ \ 
   \"deviceQueueItem\": { \ 
     \"confirmed\": true, \ 
     \"data\": \"AQID\", \ 
     \"fPort\": 10 \ 
   } \ 
 }" "http://172.18.93.38:8080/api/devices/60C5A8FFFE7841A6/queue"} res
 puts $res
 
 
 
  #::http::register https 8080 ::tls::socket
  set gaSet(curl) C:/curl-7.73.0-win64-mingw/bin/curl.exe
  catch {exec $gaSet(curl) -k  -c cook$gaSet(pair) "http://172.18.93.56:8080/"} resBody
    set csrf - ;  regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)\"} $resBody ma csrf
    if {$csrf=="-"} {
      regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    }  
    puts $resBody
    puts csrf1<$csrf>
    
    package require http
    set timeout 10000
    set url http://172.18.93.56:5000/sendToLora
    dict set deviceQueueItem confirmed true
    dict set deviceQueueItem data qrvM3Q==
    
    set query [::http::formatQuery SendDataToLoraDev p1 par2 ar2  ]
    catch {::http::geturl $url -query $query -timeout $timeout} tok
    upvar #0 $tok state
    #parray state
    http::cleanup $tok
    
    set json "{\"tp_perform = "{\"email\": \"admin\", \"password\": \"admin\"}""
    catch {::http::geturl $url -query $json -timeout $timeout} tok
    upvar #0 $tok state
    parray state
    http::cleanup $tok
    
    set query [::http::formatQuery $deviceQueueItem]
    catch {::http::geturl $url -query $json -timeout $timeout} tok
    upvar #0 $tok state
    parray state
    http::cleanup $tok
    
  set gaSet(curl) C:/curl-7.73.0-win64-mingw/bin/curl.exe
  set d "{ \ 
   \"deviceQueueItem\": { \ 
     \"confirmed\": true, \ 
     \"data\": \"AQID\", \ 
     \"fPort\": 10 \ 
   } \ 
 }"
  set d "{\"deviceQueueItem\": {\"confirmed\": true, \"data\": \"qrvM3Q==\", \"fPort\": 1 }}"
  dict set deviceQueueItem confirmed true
  dict set deviceQueueItem data qrvM3Q==
  
  catch {exec $gaSet(curl) -X POST  --header "Content-Type: application/json" --header "Accept: application/json" \
    -d $deviceQueueItem http://172.18.93.56:5000/sendToLora} resBody
   
} 

   
    
