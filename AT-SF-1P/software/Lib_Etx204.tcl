# ***************************************************************************
# OpenEtxGen
# ***************************************************************************
proc OpenEtxGen {} {
  global gaSet gaEtx204Conf
  foreach gen {1 2} {    
    set gaSet(idGen$gen) [RLEtxGen::Open $gaSet(comGen$gen) -package RLCom] 
    if {[string is integer $gaSet(idGen$gen)] && $gaSet(idGen$gen)>0 } {   
      set ret 0
    } else {
      set gaSet(fail) "Open Generator-$gen fail"
      set ret -1
      break
    }  
  }
  return $ret 
}

# ***************************************************************************
# ToolsEtxGen
# ***************************************************************************
proc ToolsEtxGen {} {
  global gaSet
  
  foreach gen {1 2} {
    Status "Opening EtxGen-$gen..."
    set gaSet(idGen$gen) [RLEtxGen::Open $gaSet(comGen$gen) -package RLCom]
    InitEtxGen $gen
  }
  Status Done
  catch {RLEtxGen::CloseAll}
  return 0
} 
# ***************************************************************************
# InitEtxGen
# ***************************************************************************
proc InitEtxGen {gen}  {
  global gaSet gaEtx204Conf
  set id $gaSet(idGen$gen)
  
  ::RLEtxGen::GetConfig $gaSet(idGen$gen) gaEtx204Conf
  Status "EtxGen-$gen Ports Configuration"
  RLEtxGen::PortsConfig $id -updGen all -autoneg enbl -maxAdvertize 1000-f \
      -admStatus down ; #-save yes 
  if {$gaEtx204Conf(id$gen,DA,Gen1)!="000000000005"} {
#     return 0
  }
  
  Status "EtxGen-$gen Gen Configuration"
  RLEtxGen::GenConfig $id -updGen all -factory yes -genMode GE -chain 1 -packRate 115000 
  #-packType VLAN -minLen 512 -maxLen 1000 
   
  Status "EtxGen-$gen Packet Configuration"
#   set sa 000000000001
#   set da 000000000002
#   puts "EtxGen-$gen Packet Configuration  sa:$sa da:$da" 
#   RLEtxGen::PacketConfig $id MAC -updGen all -SA $sa -DA $da
  
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA 0000000000[set gen]1 -DA 0000000000[set gen]2
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA 0000000000[set gen]2 -DA 0000000000[set gen]1
  if {$gen==1} {
    RLEtxGen::PacketConfig $id MAC -updGen 3 -SA 0000000000[set gen]3 -DA 0000000000[set gen]4
    RLEtxGen::PacketConfig $id MAC -updGen 4 -SA 0000000000[set gen]4 -DA 0000000000[set gen]3
  }
  return 0
}

# ***************************************************************************
# Etx204Start
# ***************************************************************************
proc Etx204Start {} {
  global gaSet buffer
  Status "Etx204 Start"
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    set id $gaSet(idGen$gen)
    puts "Etx204 Gen-$gen Start .. [MyTime]" ; update
    RLEtxGen::Start $id 
  }  
  after 500
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    set id $gaSet(idGen$gen)
    puts "Etx204 Gen-$gen Clear .. [MyTime]" ; update
    RLEtxGen::Clear $id
  }  
  after 500
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    set id $gaSet(idGen$gen)
    puts "Etx204 Gen-$gen Start .. [MyTime]" ; update
    RLEtxGen::Start $id 
  }  
  after 500
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    set id $gaSet(idGen$gen)
    puts "Etx204 Gen-$gen Clear .. [MyTime]" ; update
    RLEtxGen::Clear $id
  }
  return 0
}  

# ***************************************************************************
# Etx204Check
# ***************************************************************************
proc Etx204Check {} {
  global gaSet aRes
  
  set ret 0
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    puts "Etx204 Gen-$gen Check .. [MyTime]" ; update
    set id $gaSet(idGen$gen)    

    RLEtxGen::GetStatistics $id aRes
    if ![info exist aRes] {
      after 2000
      RLEtxGen::GetStatistics $id aRes
      if ![info exist aRes] {
        set gaSet(fail) "Read statistics of ETX204 Gen-$gen fail"
        return -1
      }
    }
    set res1 0
    set res2 0
    set res3 0
    set res4 0
  
    foreach port {1 2 3 4} {
      if {$gen==2 && $port==3} {break}
      if {$gaSet(dutFam.wanPorts) eq "2U" && ($port eq "3" || $port eq "4")} {break}
      puts "Generator Port-$port stats:"
      mparray aRes *Gen$port
      #foreach stat {ERR_CNT FRAME_ERR PRBS_ERR SEQ_ERR FRAME_NOT_RECOGN} {}
      foreach stat {ERR_CNT FRAME_ERR PRBS_ERR SEQ_ERR } {
        ## 
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res!=0} {
          set gaSet(fail) "The $stat in Generator-$gen Port-$port is $res. Should be 0"
          set res$port -1
          break
        }
      }
      if {[set res$port]!=0} {
        puts "stat:$stat res:$res res$port :<[set res$port]>"
        break
      }
      #puts "1" ; update
      foreach stat {PRBS_OK RCV_BPS RCV_PPS} {
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res==0} {
          set gaSet(fail) "The $stat in Generator-$gen Port-$port is 0. Should be more"
          set res$port -1
          break
        }
      }
      if {[set res$port]!=0} {
        puts "stat:$stat res:$res res$port :<[set res$port]>"
        break
      }
      #puts "2" ; update
    }
    #puts "3 gaSet(fail):$gaSet(fail)" ; update
    if {$res1!=0 || $res2!=0 || $res3!=0 || $res4!=0} {
      set ret -1
      break
    }
  }  
  
  puts "ret of Etx204Check Gen-$gen:<$ret>" 
  return $ret
}

# ***************************************************************************
# Etx204Stop
# ***************************************************************************
proc Etx204Stop {} {
  global gaSet
  Status "Etx204 Stop"
  foreach gen {1 2} {
    if {$gaSet(dutFam.wanPorts) eq "2U" && $gen eq 2} {break}
    puts "Etx204 Gen-$gen Stop .. [MyTime]" ; update
    set id $gaSet(idGen$gen)
    RLEtxGen::Stop $id
  }
  return 0
}
