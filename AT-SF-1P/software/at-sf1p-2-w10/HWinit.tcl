#set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_201\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      #set gaSet(comDut)     7; #1
      set gaSet(comGen1)    5
      set gaSet(comGen2)    6
      set gaSet(comDut) [set gaSet(comSer2) 4]
      set gaSet(comSer1)    2
      set gaSet(comSer485)  13; #2
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT31CS0F 
      set gaSet(ip4lora) 172.18.94.182
  }
  2 {
      #set gaSet(comDut)     1; #6
      set gaSet(comGen1)    10
      set gaSet(comGen2)    9
      set gaSet(comDut) [set gaSet(comSer2) 8]
      set gaSet(comSer1)    7
      set gaSet(comSer485)  14; #9  
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT31CTG9   
      set gaSet(ip4lora) 172.18.94.183
  }
  
}  
source lib_PackSour.tcl
