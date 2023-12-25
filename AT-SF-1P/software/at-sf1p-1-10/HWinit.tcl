switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      #set gaSet(comDut)     7; #1
      set gaSet(comGen1)    2; #5
      set gaSet(comGen2)    4; #6
      set gaSet(comDut) [set gaSet(comSer2) 5]
      set gaSet(comSer1)    6; #2
      set gaSet(comSer485)  13; #2
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT567XOH 
      set gaSet(ip4lora) 172.18.94.180
  }
  2 {
      #set gaSet(comDut)     1; #6
      set gaSet(comGen1)    9; #10
      set gaSet(comGen2)    7; #9
      set gaSet(comDut) [set gaSet(comSer2) 8]
      set gaSet(comSer1)    10; #7
      set gaSet(comSer485)  15; #9  
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT5PHZ3S  
      set gaSet(ip4lora) 172.18.94.181
  }  
}  
source lib_PackSour.tcl
