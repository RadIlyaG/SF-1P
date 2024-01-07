#set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_201\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      #set gaSet(comDut)     7
      set gaSet(comGen1)    9; #4
      set gaSet(comGen2)    7; #8
      set gaSet(comDut) [set gaSet(comSer2) 8]
      set gaSet(comSer1)    6; #7
      set gaSet(comSer485)  10; #2
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FTEBG66 
      set gaSet(ip4lora) 172.18.94.186
  }
  2 {
      #set gaSet(comDut)     1; #6
      set gaSet(comGen1)    4; #6
      set gaSet(comGen2)    2; #2
      set gaSet(comDut) [set gaSet(comSer2) 5]
      set gaSet(comSer1)    1; #1
      set gaSet(comSer485)  14; #13; #9  
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT1MSB37  
      set gaSet(ip4lora) 172.18.94.187      
  }
  
}  
source lib_PackSour.tcl
