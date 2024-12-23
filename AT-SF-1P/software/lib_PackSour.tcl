wm iconify . ; update

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
set jav [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment" CurrentVersion]
set gaSet(javaLocation) [file normalize [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment\\$jav" JavaHome]/bin]


## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER
}
after 1000
set ::RadAppsPath c:/RLFiles/Tools/RadApps

 set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
if 1 {
 
  if {$gaSet(radNet)} {
    if 0 {
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
      set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
      puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
      if {$mTimeTds>$mTimeRL} {
        puts "$mTimeTds>$mTimeRL"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
        after 2000
      }
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
      set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
      puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
      if {$mTimeTds>$mTimeRL} {
        puts "$mTimeTds>$mTimeRL"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
        after 2000
      }
    }
    if 1 {
      set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/LibUrl_WS/LibUrl.tcl]
      set mTimePwd  [file mtime [pwd]/LibUrl.tcl]
      puts "mTimeTds:$mTimeTds mTimePwd:$mTimePwd"
      if {$mTimeTds>$mTimePwd} {
        puts "$mTimeTds>$mTimePwd"
        file copy -force //prod-svm1/tds/install/ateinstall/jate_team/LibUrl_WS/LibUrl.tcl ./
        after 2000
      }
    }
    update
  }
  
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/SF-1P/AT-SF-1P]
  set d1 [file normalize  C:/AT-SF-1P]
#   set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX1P/download]
#   set d2 [file normalize  C:/download]
  
  if {$gaSet(radNet)} {
    if {[string match *ilya-g* [info host]]} {
        set emailL [list]
      } else {
        set emailL {meir_ka@rad.com}
      }  
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1" \
      -noCheckFiles {init*.tcl skipped.txt eeprom*.cnt EthTest* *ifiReport.txt  LocWifiReport* startMea*  *.db} \
      -noCheckDirs {temp tmpFiles OLD old uutInits} -jarLocation  $::RadAppsPath \
      -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      #SQliteClose
      exit
    }
  }
  
  if {$gaSet(radNet)} {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Get28* Macreg.2* Macreg-i* DP* *.prd}]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    if {$ret=="-1"} {
      set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
      -message "The AutoSync process did not perform successfully.\n\n\
      Do you want to continue? "]
      if {$res=="no"} {
        #SQliteClose
        exit
      }
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RLUsbPio
package require RLUsbMmux
package require RLSound  
package require RLCom
package require RLEtxGen
RLSound::Open ; # [list failbeep fail.wav passbeep pass.wav beep warning.wav]
package require ezsmtp
package require http
package require RLAutoUpdate
package require sqlite3
package require ftp
package require http
package require tls
package require base64
package require twapi
::http::register https 8445 ::tls::socket
::http::register https 8443 ::tls::socket
package require json
source Lib_Ramzor.tcl
source lib_EcoCheck.tcl
  

source Gui_SF1P.tcl
source Main_SF1P.tcl
source Lib_Put_SF1P.tcl
source Lib_Gen_SF1P.tcl
source Lib_Etx204.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source lib_SQlite.tcl
source lib_Ftp_SF1P.tcl
# 11:46 09/10/2023
# if [file exists uutInits/$gaSet(DutInitName)] {
  # source uutInits/$gaSet(DutInitName)
# } else {
  # source [lindex [glob uutInits/SF-1P*.tcl] 0]
# }
update
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl
source Lib_Lora.tcl
source Lib_Ramzor.tcl
source lib_EcoCheck.tcl
source lib_IT6900.tcl
source lib_DifferentVoltageTest.tcl

set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0

set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0

set gaSet(gpibMode) com
set gaSet(relDebMode) Release

set gaSet(WifiNet) 70.70

set gaSet(ChirpStackIP.9XX) 172.18.94.105; #91
set gaSet(ChirpStackIP.8XX) 172.18.94.26; #91
set gaSet(LoraServerHost) Jer-LoraSrv1-10; #"at-sf1p-1-10"
set gaSet(LoraServerIP) 172.18.94.79
set gaSet(ChirpStackData) "aabbccdd"
set gaSet(LoraStayConnectedOnFail) 0

set gaSet(wifiNet) [info host]_$gaSet(pair)
if ![file exist startMeasurement_$gaSet(wifiNet)] {
  set id [open startMeasurement_$gaSet(wifiNet) w+]
  after 100
  close $id
}
if ![info exists gaSet(hwAdd)] {
  set gaSet(hwAdd) A
}

if ![info exists gaSet(demo)] {
  set gaSet(demo) 0
}

if ![info exists gaSet(PowerOffOnUntil)] {
  set gaSet(PowerOffOnUntil) login ; #first_steps
}
set gaSet(testmode) finalTests
#puts "$gaSet(DutFullName)"
# 11:48 09/10/2023  ToggleComDut

LoadNoTraceFile

GUI
# 11:51 09/10/2023 BuildTests
update

wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"
