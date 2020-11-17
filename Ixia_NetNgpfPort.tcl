
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 2.20
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.1.1
#       1. Add get_status method to achieve status of port
#       2. Add sub-interface configuration in config method
# Version 1.2.1.2
#		3. Add ping method
# Version 1.3.1.8
#		4. Add reset method
# Version 1.4.1.16
#		5. Add multi-interface in Port::config
# Version 1.5.2.1
#		6. Clear ownership in GetRealPort
# Version 1.6.2.4
#		7. Add get_stats method
#		8. Add Host class to emulate a host
# Version 1.7.2.6
#		9. Add Connect method to connect to hardware port
# Version 1.8.2.7
#		10. Add check strange port in ctor
# Version 1.9.2.9
#		11. Enable Ping defaultly
# Version 1.10.2.10
#		12. Add port_mac_addr param in Port.get_status
# Version 1.11.2.11
#		13. Port reborn
# Version 1.12.2.12
#		14. Add default mac and ip in properties
# Version 1.13.2.17
#		15. Replace connectedTo to AssignPorts to fix no license problem
# Version 1.14.3.0
#		16. Replace autoInstrumentation to floating to adapt with 10GE
#		17. Add data integrity stats when rx equals 0
# Version 1.15.3.5
#		18. Add ipv6 int addr in config
# Version 1.16.3.10
#		19. Add Host.ping
# Version 1.17.4.18
#		20. Add set_port_stream_load to set load of all stream under certain port
# Version 1.18.4.19
#		21. configure "transmit ignore link" after assign port
#		22. use assign ports when ctor and usual connectedTo ports when reborn and cleanup reserve port
# Version 1.19.4.20
#		23. add oversize stat in rx_frame_count
# Version 1.20.4.23
#		24. add total_frame_count in Port::get_stats
#		25. add Port::break_link and Port::restore_link
# Version 1.20.4.26
#       26. Create Port obj by existing port handle in Port.ctor
#       26. modify Port::set_port_stream_load
# Version 1.21.4.27
#       27. modify Host::config  src_mac format
# Version 1.22.4.28
#       28. Add catch for Data Plane Port Statistics command
#       29. modify Port::set_port_stream_load , change stream_load into L1 speed
# Version 1.23.4.29
#       30. modify port.set_dhcpv4,add lease_time
# Version 1.24.4.30
#       31. modify port.set_dhcpv4,add max_request_rate,request_rate_step,
#                                  add max_release_rate,release_rate_step
#       32. add port.start_traffic,port.stop_traffic
# Version 1.25.4.31
#		33. add resume method to resume all streams under port
# Version 1.26.4.32
#       34. remove vlan configure in Port.config
#       35. add method set_dot1x
# Version 2.08.4.33
#       36. remove vlan configure in Port.config
# Version 2.10.4.34
#		37. add ipv4_gw_step/ipv6_gw_step in Host.config
# Version 2.11.4.44
#		38. use dynamic port type for flow-control in port.config
# Version 2.12.4.46
#		39. don't check link on port in ctor
#		40. set auto_instrumentation default to endOfFrame
# Version 2.13.4.49
#		41. modify port.start_traffic to fix bug of apply traffic
# Version 2.14.4.53
#		42. fix bug in Host.config
# Version 2.15.4.54
#		43. add Port.set_port_dynamic_rate
# Version 2.16.4.59
#		44. remove param validation in port.config
# Version 2.17.4.60
#		45. add port.Reconnect
# Version 2.17.4.60
#       46. modify Host.enable|disable, add hostInfo for 3918
# Version 2.18.4.70
#       47. modify for loadconfigmode
# Version 2.19.4.71
#       48. add start_router, stop_router
# Version 2.20 4.78
#       49. add reset_handle, when custom use Tester::cleanup -new_config 1 , connect port, handle should be empty
# Version 2.21 4.78
#       50. add modify_handle

class Port {
    inherit NetNgpfObject
    public variable topoHandle
    public variable dgHandle
    public variable ipv4Handle
    public variable ipv6Handle
    public variable ethHandle
    variable PortHandle
    public variable ipVersion
    set ipVersion ""
    constructor { { hw_id NULL } { medium NULL } { hPort NULL } {force 0} } {}
    method config { args } {}
    method get_status {} {}
    method get_stats {} {}
    method ping { args } {}
    method send_arp { } {}
    method reset {} {}
    method reset_handle {} {
        set tag "body Port::reset_handle [info script]"
    Deputs "----- TAG: $tag -----"
        set handle ""
    }
    method modify_handle { value } {
        set tag "body Port::modify_handle [info script]"
    Deputs "----- TAG: $tag -----"
        set handle $value
    }
	method start_traffic {} {}
	method stop_traffic {} {}
    method start_router { args } {}
	method stop_router { args } {}    
    method break_link {} {}
    method restore_link {} {}
	method set_port_stream_load { args } {}
    method set_port_dynamic_rate { args } {}
	method resovle_mac { args } {
		set tag "body Port::resovle_mac [info script]"
        Deputs "----- TAG: $tag -----"
		global errorInfo
		global errNumber
        Deputs "Args:$args "
		foreach { key value } $args {
			set key [string tolower $key]
			switch -exact -- $key {
				-neighbor_ip {
					if { $value != "" } {
						if { [ IsIPv4Address $value ] } {
							set neighbor_ip $value
						} else {
							error "$errNumber(1) key:$key value:$value"
						}
					}
				}
				default {
					error "$errNumber(3) key:$key value:$value"
				}
			}
		}
		if { [ info exists neighbor_ip ] } {
            Deputs "get neighbor"
			set neighbor [ ixNet getF $handle discoveredNeighbor -neighborIp $neighbor_ip ]
            if { $neighbor == "" } {
                return "00:00:00:00:00:00"
            }
            Deputs "neighbor:$neighbor"
            Deputs "get neighbor mac"
			set neighbor_mac [ ixNet getA $neighbor -neighborMac ]
            Deputs "neighbor mac:$neighbor_mac"
		}
		if { [ IsMacAddress $neighbor_mac ] } {
			return $neighbor_mac
		} else {
			return "00:00:00:00:00:00"
		}
	}
    
    method set_dhcpv4 { args } {}
    method set_dhcpv6 { args } {}
    method set_dot1x {args } {}
  	method resume {} {
		set tag "body Traffic::resume [info script]"
        Deputs "----- TAG: $tag -----"
		set info [ ixNet getA $handle -connectionInfo ]
		regexp {chassis="(\d+.\d+.\d+.\d+)"} $info chas chasAddr
		regexp {card="(\d+)"} $info card cardId
		regexp {port="(\d+)"} $info port portId
		if { [ ixConnectToChassis ] == 0 } {
			set tclServer [ lindex [ split $loginInfo "/" ] 0 ]
			ixConnectToTclServer $tclServer
			ixConnectToChassis $chasAddr
		}

		chassis get $chasAddr
		set chasId [ chassis cget -id ]
		port get $chasId $cardId $portId
		set owner [ port cget -owner ]
		ixLogin $owner
		set pl [ list [ list $chasId $cardId $portId ] ]
		ixTakeOwnership $pl
		
		set streamCount [ port getStreamCount $chasId $cardId $portId ]
		set sl [ list ]
		for { set id 1 } { $id <= $streamCount } { incr id } {
			lappend sl $id
		}
		
		return stream resume $chasId $cardId $portId $sl
	}
	
    
    method GetRealPort { chas card port force } {}
    method Connect { location { medium NULL } { checkLink 0 } {force 0}} {}
    method Reconnect { location { medium NULL } { checkLink 0 } {force 0} } {}
    method CheckStrangePort {} {}
    method GetProtocolsHandleList {} {
        set tag "body Port::GetProtocolsHandleList [info script]"
    Deputs "----- TAG: $tag -----"
        array set deviceList  ""
        array set bgpList     ""
        array set isisList    ""
        array set ldpList     ""
        array set ospfList    ""
        array set ospfv3List  ""
        array set dhcpList    ""
        array set pppoxList   ""
		array set igmpList    ""
		array set mldList     ""
		array set ripList     ""
		array set ripngList   ""
		array set l2tpList	  ""
      
        set vport_protocols     [ixNet getL $handle protocols]
        set vport_protocolStack [ixNet getL $handle protocolStack]
        
       
    #bgp                     
        set bgpH [ixNet getL $vport_protocols bgp]
        if {[ixNet getA $bgpH  -enabled] == "true" } {
            #only can start bgpH, can disable bgpNR
            set deviceList(bgp) $bgpH
            foreach bgpNR [ixNet getL $bgpH neighborRange] {
			    if { [catch {
			        set bgpNR_name [ixNet getA [ixNet getA $bgpNR -interfaces] -description]
                    set bgpList($bgpNR_name) $bgpNR 
			    } ] } {
				   Deputs " No interface bind to bgp"
				}
               
            }
        }
    
    #isis 
        set isisH [ixNet getL $vport_protocols isis]
        if {[ixNet getA $isisH  -enabled] == "true" } {
           #only can start isisH, can disable isisR
            set deviceList(isis) $isisH
            foreach isisR [ixNet getL $isisH router] {
                # set isisIntface [lindex [ixNet getL $isisR interface] 0]
                # set isisR_name [ixNet getA [ixNet getA $isisIntface -interfaceId] -description]
                # set isisList($isisR_name) $isisR
			    if { [catch {
					set isisIntface [lindex [ixNet getL $isisR interface] 0]
                    set isisR_name [ixNet getA [ixNet getA $isisIntface -interfaceId] -description]
                    set isisList($isisR_name) $isisR
				} ] } {
				   Deputs " No interface bind to isis"
				}
            }
        }
    
    #ldp 
        set ldpH [ixNet getL $vport_protocols ldp]
        if {[ixNet getA $ldpH  -enabled] == "true" } {
           
            set deviceList(ldp) $ldpH
			foreach ldpR [ixNet getL $ldpH router] {
                # set ldpIntface [lindex [ixNet getL $ldpR interface] 0]
                # set ldpR_name [ixNet getA [ixNet getA $ldpIntface -protocolInterface] -description]
                # set ldpList($ldpR_name) $ldpR
			    if { [catch {
					set ldpIntface [lindex [ixNet getL $ldpR interface] 0]
                    set ldpR_name [ixNet getA [ixNet getA $ldpIntface -protocolInterface] -description]
                    set ldpList($ldpR_name) $ldpR
				} ] } {
				   Deputs " No interface bind to ldp"
				}
            }
        }
    #igmp 
        set igmpH [ixNet getL $vport_protocols igmp]
        if {[ixNet getA $igmpH  -enabled] == "true" } {
           #only can start isisH, can disable isisR
            set deviceList(igmp) $igmpH
            foreach igmpR [ixNet getL $igmpH host] { 
                if { [catch {			
                   set igmpR_name  [ixNet getA [ixNet getA $igmpR -interfaces] -description]
                   set igmpList($igmpR_name) $igmpR
			    } ] } {
				   Deputs " No interface bind to igmp"
				}
            }
        }
		
	#mld 
        set mldH [ixNet getL $vport_protocols mld]
        if {[ixNet getA $mldH  -enabled] == "true" } {
           #only can start mldH, can disable mldR
            set deviceList(mld) $mldH
            foreach mldR [ixNet getL $mldH host] {               
               # set mldR_name  [ixNet getA [ixNet getA $mldR -interfaces] -description]
               # set mldList($mldR_name) $mldR
			    if { [catch {			
                   set mldR_name  [ixNet getA [ixNet getA $mldR -interfaces] -description]
                   set mldList($mldR_name) $mldR
			    } ] } {
				   Deputs " No interface bind to mld"
				}
            }
        }
	
	#rip 
        set ripH [ixNet getL $vport_protocols rip]
        if {[ixNet getA $ripH  -enabled] == "true" } {
           #only can start ripH, can disable ripR
            set deviceList(rip) $ripH
            foreach ripR [ixNet getL $ripH router] {
              
               # set ripR_name [ixNet getA [ixNet getA $ripR -interfaceId] -description]
               # set ripList($ripR_name) $ripR
			    if { [catch {			
                   set ripR_name [ixNet getA [ixNet getA $ripR -interfaceId] -description]
                   set ripList($ripR_name) $ripR
			    } ] } {
				   Deputs " No interface bind to rip"
				}
            }
        }
		
	#ripng 
        set ripngH [ixNet getL $vport_protocols ripng]
        if {[ixNet getA $ripngH  -enabled] == "true" } {
           #only can start ripngH, can disable ripngR
            set deviceList(ripng) $ripngH
            foreach ripngR [ixNet getL $ripngH router] {
               # set ripngIntface [lindex [ixNet getL $ripngR interface] 0]
               # set ripngR_name [ixNet getA [ixNet getA $ripngIntface -interfaceId] -description]
               # set ripngList($ripngR_name) $ripngR
			    if { [catch {			
                   set ripngIntface [lindex [ixNet getL $ripngR interface] 0]
                   set ripngR_name [ixNet getA [ixNet getA $ripngIntface -interfaceId] -description]
                   set ripngList($ripngR_name) $ripngR
			    } ] } {
				   Deputs " No interface bind to ripng"
				}
            }
        }
		
    #ospfv2 
        set ospfH [ixNet getL $vport_protocols ospf]
        if {[ixNet getA $ospfH  -enabled] == "true" } {
           
            set deviceList(ospf) $ospfH
            foreach ospfR [ixNet getL $ospfH router] {
               # set ospfIntface [lindex [ixNet getL $ospfR interface] 0]
               # set ospfR_name [ixNet getA [ixNet getA $ospfIntface -interfaces] -description]
               # set ospfList($ospfR_name) $ospfR
			    if { [catch {			
                    set ospfIntface [lindex [ixNet getL $ospfR interface] 0]
                    set ospfR_name [ixNet getA [ixNet getA $ospfIntface -interfaces] -description]
                    set ospfList($ospfR_name) $ospfR
			    } ] } {
				   Deputs " No interface bind to ospf"
				}
            }
        }
    
    #ospfv3 
        set ospfV3H [ixNet getL $vport_protocols ospfV3]
        if {[ixNet getA $ospfV3H  -enabled] == "true" } {
            set deviceList(ospfv3) $ospfV3H
            foreach ospfV3R [ixNet getL $ospfV3H router] {
               # set ospfV3Intface [lindex [ixNet getL $ospfV3R interface] 0]
               # set ospfV3R_name [ixNet getA [ixNet getA $ospfV3Intface -interfaces] -description]
               # set ospfv3List($ospfV3R_name) $ospfV3R
			    if { [catch {			
                   set ospfV3Intface [lindex [ixNet getL $ospfV3R interface] 0]
                   set ospfV3R_name [ixNet getA [ixNet getA $ospfV3Intface -interfaces] -description]
                   set ospfv3List($ospfV3R_name) $ospfV3R
			    } ] } {
				   Deputs " No interface bind to ospfv3"
				}
            }
        }
    #bfd    
        set bfdH [ixNet getL $vport_protocols bfd]
        if {[ixNet getA $bfdH  -enabled] == "true" } {
            set deviceList(bfd) $bfdH
           
        }
    #rsvp           
        set rsvpH [ixNet getL $vport_protocols rsvp]
        if {[ixNet getA $rsvpH  -enabled] == "true" } {
            set deviceList(rsvp) $rsvpH
           
        }
    
    #eth
	    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
	#dhcp/pppox/l2tp 
        if {$ethernetH_list != "" } {
            foreach ethernetH $ethernetH_list {
                set dhcpH [ixNet getL $ethernetH dhcpEndpoint]
                if { $dhcpH != "" } {
                    set deviceList(dhcp) $dhcpH
                    foreach dhcpR [ixNet getL $dhcpH range] {
                       set dhcpR_name [ixNet getA [ixNet getL $dhcpR dhcpRange] -name]
                       set dhcpList($dhcpR_name) $dhcpR
                    }
                } 
                set pppoxH [ixNet getL $ethernetH pppoxEndpoint]
                if { $pppoxH != "" } {
                    set deviceList(pppox) $pppoxH
                    foreach pppoxR [ixNet getL $pppoxH range] {
                       set pppoxR_name [ixNet getA [ixNet getL $pppoxR pppoxRange] -name]
                       set pppoxList($pppoxR_name) $pppoxR
                    }
                }
				set	ipH [ixNet getL $ethernetH ip]
				if { $ipH != "" } { 
					set l2tpH [ixNet getL $ipH l2tpEndpoint]
					if { $l2tpH != "" } {
						set deviceList(l2tp) $l2tpH
						foreach l2tpR [ixNet getL $l2tpH range] {
							set l2tpR_name [ ixNet getA $l2tpH/l2tpRange -name ]
							set l2tpList($l2tpR_name) $l2tpR
						}
					}
				}
           }                    
        }
    }
    
    public variable location
    public variable intf_mac
    public variable intf_ipv4
    public variable inter_burst_gap
	public variable PortNo
	public variable port_name
    
    #loadconfig device list
    public variable deviceList
    public variable bgpList
    public variable isisList
    public variable ldpList
    public variable ospfList
    public variable ospfv3List
    public variable dhcpList
    public variable pppoxList
    public variable igmpList   
	public variable mldList     
	public variable ripList     
	public variable ripngList   
 
    
    
}

body Port::constructor { { hw_id NULL } { medium NULL } { hPort NULL } {force 0} } {
    
    set tag "body Port::ctor [info script]"
    Deputs "----- TAG: $tag -----"
    
    global LoadConfigMode   
    set topoHandle " "
    set dgHandle " "
    set ipv4Handle " "
    set ipv6Handle " "
    set ethHandle " "
    
	set port_name $this
    # -- Check for Multiuser Login
	set portObjList [ GetAllPortObj ]
	if { [ llength $portObjList ] == 0 } {
        Deputs "All port obj:[GetAllPortObj]"
		set strangePort [ CheckStrangePort ]
        Deputs "Strange port:$strangePort"		
		if { $strangePort == 0 } {
			global loginInfo
			Login $loginInfo
		}
	}
	set handle ""

    Deputs Step10
    if { $hw_id != "NULL" } {
        Deputs "hw_id:$hw_id"	
        # -- check hardware
		set locationInfo [ split $hw_id "/" ]
		set chassis     [ lindex $locationInfo 0 ]
		set ModuleNo    [ lindex $locationInfo 1 ]
		set PortNo      [ lindex $locationInfo 2 ]

        if { $LoadConfigMode } {
            set handle [GetValidHandleObj "port" $hw_id]
			if {$handle != ""} {
			    # ixNet setA $handle -name $this
				# ixNet commit
				set port_name [ixNet getA $handle -name]
			}
        }
        if {$handle == "" } {
		    if { [ GetRealPort $chassis $ModuleNo $PortNo 0 ] == [ ixNet getNull ] } {
				error "Port hardware not found: $hw_id"
			}
			Deputs Step20	
			catch {
				if { $medium != "NULL" } {
					set handle [ Connect $hw_id $medium 1  $force]
				} else {
					set handle [ Connect $hw_id NULL 0 $force]
				}
			}
		}
		set location $hw_id
        Deputs "location:$location" 
    } else {
        
        if { $hPort != "NULL" } {
			set chassis ""
			set card ""
			set port ""
            set handle $hPort
			set connectionInfo [ ixNet getA $handle -connectionInfo ]
            Deputs "connectionInfo :$connectionInfo"
			regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
            Deputs "chas:$chassis card:$card port$port"
			set location ${chassis}/${card}/${port}
			ixNet setA $handle -name $this
			ixNet commit
		} else {
            if { $LoadConfigMode } {
                set handle		[GetValidHandleObj "port" $this]
            } 
            if { $handle== "" } {
                Deputs "offline create"
                set root [ixNet getRoot]
                set handle [ixNet add $root vport]
                # ixNet setA $handle -name $this
                # ixNet commit
                # set handle [ixNet remapIds $handle]
            }
			ixNet setA $handle -name $this
			ixNet commit
			set handle [ixNet remapIds $handle]
           
        }  
    }
    set PortHandle $handle
    
    if { $LoadConfigMode } {
		GetProtocolsHandleList
    } 
    
	set intf_mac 	 ""
	set intf_ipv4	 ""
	set inter_burst_gap 12
}

body Port::CheckStrangePort {} {
    set tag "body Port::CheckStrangePort [info script]"
Deputs "----- TAG: $tag -----"
	set root [ ixNet getRoot]
	for { set index 0 } { $index < 6 } { incr index } {
		if { [ llength [ ixNet getL $root vport ] ] > 0 } {
			Deputs "The connecting optional port $port is ocuppied, try next port..."
			return 0
		} 
		after 500
	}
	return 1
}

body Port::Connect { location { medium NULL } { checkLink 0 } { force 0 } } {
    set tag "body Port::Connect [info script]"
    Deputs "----- TAG: $tag -----"
    # -- add vport
    set root    [ ixNet getRoot ]
    if { $handle == "" } {
        set vport   [ ixNet add $root vport ]
        ixNet setA $vport -name $this
		ixNet commit
        set vport [ixNet remapIds $vport]
        set handle $vport
    }
    
	if { $medium != "NULL" } {
        Deputs "connect medium:$medium"	
        # if {[ixNet getA $vport -type] == "ethernet" } {
            # ixNet setA $vport/l1Config/ethernet -media $medium
        # }
        ixNet setA $handle/l1Config/[ixNet getA $handle -type] -media $medium
       
		
	}

	# -- connect to hardware
	set locationInfo [ split $location "/" ]
	set chassis     [ lindex $locationInfo 0 ]
	set ModuleNo    [ lindex $locationInfo 1 ]
	set PortNo      [ lindex $locationInfo 2 ]

	if { [ string tolower [ ixNet getA $root/statistics -guardrailEnabled ] ] != "true" } {
        Deputs "guardrail: false"
		catch {
			ixNet setA $root/statistics -guardrailEnabled True
			ixNet commit
		}
        Deputs "guardrail:[ ixNet getA $root/statistics -guardrailEnabled  ]"
	}

	if { $checkLink } {
		#fix license issue
		ixTclNet::AssignPorts [ list [ list $chassis $ModuleNo $PortNo ] ] {} $handle true
	} else {
		ixNet setA $handle -connectedTo [ GetRealPort $chassis $ModuleNo $PortNo $force ] 
		ixNet commit
	}
	set handle [ixNet remapIds $handle]
    Deputs "handle:$handle"	
	ixNet setA $handle -transmitIgnoreLinkStatus True
    ixNet commit       
 
	return $handle
}

body Port::Reconnect { location { medium NULL } { checkLink 0 } { force 0 } } {
    set tag "body Port::Reconnect [info script]"
    Deputs "----- TAG: $tag -----"
    # -- add vport
    set root    [ ixNet getRoot ]   
    # -- connect to hardware
	set locationInfo [ split $location "/" ]
	set chassis     [ lindex $locationInfo 0 ]
	set ModuleNo    [ lindex $locationInfo 1 ]
	set PortNo      [ lindex $locationInfo 2 ]

	if { [ string tolower [ ixNet getA $root/statistics -guardrailEnabled ] ] != "true" } {
        Deputs "guardrail: false"
		catch {
			ixNet setA $root/statistics -guardrailEnabled True
			ixNet commit
		}
        Deputs "guardrail:[ ixNet getA $root/statistics -guardrailEnabled  ]"
	}

	if { $checkLink } {
		#fix license issue
		ixTclNet::AssignPorts [ list [ list $chassis $ModuleNo $PortNo ] ] {} $handle true
	} else {
		ixNet setA $handle -connectedTo [ GetRealPort $chassis $ModuleNo $PortNo $force ] 
		ixNet commit
	}
	set handle [ixNet remapIds $handle]
    Deputs "handle:$handle"	
	ixNet setA $handle -transmitIgnoreLinkStatus True
    ixNet commit
 
	return $handle
}

body Port::GetRealPort { chassis card port force } {
    set tag "body Port::GetRealPort [info script]"
    Deputs "----- TAG: $tag -----"
    set root    [ixNet getRoot]
    Deputs "chassis:$chassis"        
	set root [ixNet getRoot]
	if { [ llength [ixNet getList $root/availableHardware chassis] ] == 0 } {
        Deputs Step20
		set chas [ixNet add $root/availableHardware chassis]
		ixNet setA $chas -hostname $chassis
		ixNet commit
		set chas [ixNet remapIds $chas]
	} else {
        Deputs Step30
		set chas_list [ixNet getList $root/availableHardware chassis]
        foreach chas $chas_list {
            set hostname [ixNet getA $chas -hostname]
            if { $hostname != $chassis } {
                #ixNet remove $chas
                #ixNet commit
                set chas [ixNet add $root/availableHardware chassis]
                ixNet setA $chas -hostname $chassis
                ixNet commit
                set chas [ixNet remapIds $chas]
                break
            } else {
                break
            }
        }
	}
	set chassis $chas
    set realCard $chassis/card:$card
    Deputs "card:$realCard"
    set cardList [ixNet getList $chassis card]
    Deputs "cardList:$cardList"
    set findCard 0
    foreach ca $cardList {
        eval set ca $ca
        eval set realCard $realCard
        Deputs "realCard:$realCard"
        Deputs "ca:$ca"
        if { $ca == $realCard } {
            set findCard 1
            break
        } 
    }
    Deputs Step10
    Deputs "findCard:$findCard"
    if { $findCard == 0} {
        return [ixNet getNull]
    }
    set realPort $chassis/card:$card/port:$port
    Deputs "port:$realPort"
    set portList [ ixNet getList $chassis/card:$card port ]
    Deputs "portList:$portList"
    set findPort 0
    foreach po $portList {
        eval set po $po
        eval set realPort $realPort
        if { $po == $realPort } {
            set findPort 1
            break
        }
    }
    Deputs "findPort:$findPort"
    if { $findPort } {
        Deputs "real port:	$chassis/card:$card/port:$port"
        if { $force } {
            ixNet exec clearOwnership $chassis/card:$card/port:$port
        }
		
        return $chassis/card:$card/port:$port
    } else {
        return [ixNet getNull]
    }
}

body Port::config { args } {
    # object reborn
	if { $handle == "" } {
		if { $location != "NULL" } {
			catch {
				set handle [ Connect $location ]
			}
			set inter_burst_gap 12
		} else {
			return [ GetErrorReturnHeader "No port information or wrong port information." ]
		}
	}

    global errorInfo
    global errNumber

    set EType [ list eth pos atm 10g_lan 10g_wan 40g_lan 100g_lan 40gpos ]
    set EMedia [ list copper fiber ]
    # set ESpeed [ list 10M 100M 1G 10G 40G 100G 155M 622M 2.5G 40GPOS ]
    set EDuplex [ list full half ]
    
    set flagInnerVlan   0
    set flagOuterVlan   0
    
    set inner_vlan_id   100
    set inner_vlan_step 1
    set inner_vlan_num  1
    set inner_vlan_priority 0
    set outer_vlan_id   100
    set outer_vlan_step 1
    set outer_vlan_num  1
    set outer_vlan_priority 0
    
    set enable_arp 1
    set intf_ip_num	1
    set intf_ip_mod	32
    set dut_ip_num	1
    set dut_ip_mod	32
    
    set mask 24
    set ipv6_mask 64
    # set ipv6_addr_step ::1
    set ipv6_addr_step 1
    set intf_num 1
    set ip_version "ipv4"
	
    set flow_control 0
	set sig_end 1
	
    set tag "body Port::config [info script]"
    Deputs "----- TAG: $tag -----"
    # param collection
    
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -location {
                set location $value
            }
            -intf_ip {
                if { $value != "" } {
                	if { [ IsIPv4Address $value ] } {
                		set intf_ip $value
                	} else {
                		error "$errNumber(1) key:$key value:$value"
                	}
                }
            }
            -intf_ip_num -
            -intf_num -
            -ipv6_addr_num -
            -dut_ip_num {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set intf_num $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-intf_ip_step {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set intf_ip_step $value
                    # set intf_ip_step "0.0.$intf_ip_step.0"
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-intf_ip_mod {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] && $trans <= 32 && $trans >= 1 } {
                    set intf_ip_mod $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                    
			}
            -dut_ip {
                if { [ IsIPv4Address $value ] } {
                    set dut_ip $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -dut_ip_step {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set dut_ip_step $value
                    # set dut_ip_step "0.0.$dut_ip_step.0"
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -dut_ip_mod {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] && $trans <= 32 && $trans >= 1 } {
                    set dut_ip_mod $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                    
            }
            -mask {
                if { [ string is integer $value ] && $value <= 30 } {
                    set mask $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -type {
                set value [ string tolower $value ]
                if { [ lsearch -exact $EType $value ] >= 0 } {
                    
                    set type $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -fec_enable {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set fec_enable $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -media {
                set value [ string tolower $value ]
                if { [ lsearch -exact $EMedia $value ] >= 0 } {
                    set media $value
                    Deputs "media:$media"                    
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -speed {
                switch $value {
                    10M {
                        set speed 10
                    }
                    100M {
                        Deputs "speed:$speed"					
                        set speed 100
                    }
                    1G {
                        set speed 1000
                    }
					10G {
                        set speed "speed10g"
                    }
					2.5G {
                        set speed "speed2.5g"
                    }
					5G {
                        set speed "speed5g"
                    }
					40G {
						set speed "speed40g"
					}
					100G {
						set speed "speed100g"
					}
                }
            }
            -auto_neg {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set auto_neg $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -duplex {
                set value [ string tolower $value ]
                if { [ lsearch -exact $EDuplex $value ] >= 0 } {
                    
                    set duplex $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -enable_arp -
            -enable_arp_reply {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_arp $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -inner_vlan_enable {
                set flagInnerVlan $value
            }
            -inner_vlan_id {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
                    set inner_vlan_id $value
                    set flagInnerVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -inner_vlan_step {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
                    set inner_vlan_step $value
                    set flagInnerVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -inner_vlan_num {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set inner_vlan_num $value
                    set flagInnerVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -inner_vlan_priority {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 8 ) } {
                    set inner_vlan_priority $value
                    set flagInnerVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -outer_vlan_enable {
                set flagOuterVlan $value
            }
            -outer_vlan_id {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
                    set outer_vlan_id $value
                    set flagOuterVlan 1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -outer_vlan_step {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
                    set outer_vlan_step $value
                    set flagOuterVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -outer_vlan_num {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set outer_vlan_num $value
                    set flagOuterVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -outer_vlan_priority {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 8 ) } {
                    set outer_vlan_priority $value
                    set flagOuterVlan   1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -ipv6_addr {
            	set ipv6_addr $value
            }
            -ipv6_addr_step {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set ipv6_addr_step $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -ipv6_addr_mod {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] && $trans <= 128 && $trans >= 1 } {
                    set ipv6_addr_mod $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                    
            }
		   -ipv6_prefix_len -
            -ipv6_mask {
                if { [ string is integer $value ] && $value <= 128 } {
                    set ipv6_mask $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
		   -ipv6_gw -
            -dut_ipv6 {
            	set dut_ipv6 $value
            }
            -flow_control {
		        set trans [ BoolTrans $value ]
		        if { $trans == "1" || $trans == "0" } {
			        set flow_control $trans
		        } else {
			        error "$errNumber(1) key:$key value:$value"
		        }
            }
            -inter_burst_gap {
				set inter_burst_gap $value
            }
			-ip_version {
				set ip_version $value
			}
			-sig_end {
				set sig_end $value
			}
            -mac_addr {
                set mac_addr $value
            }
            -transmit_mode {
                set transmit_mode $value
                #interleaved | sequential
            }
            -default {
                Deputs "Invalid key $key at port::config"
            }
        }
    }

    set foundTopoPort false
    Deputs "add interface on port..."
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set topoPortHandle [ixNet getA $topoObj -vports]
        if {$topoPortHandle == $handle} {
            set foundTopoPort true
            break
        }
    }
    if {$foundTopoPort == false } {
        set topoObj [ixNet add [ixNet getRoot] topology -vports $handle]
        ixNet commit
        set topoObj [ixNet remapIds $topoObj]
    } else {
        Deputs "found topoObj is $topoObj"
        set deviceGroupObj [ixNet getL $topoObj deviceGroup]
        set ethObj [ixNet getL $deviceGroupObj ethernet]
    }

    if { [info exists intf_ip_step] && $intf_ip_step != ""} {
        if {$mask != ""} {
           if {$mask == 8} {
                set ipv4AddrStepValue [string replace "0.0.0.0" 0 0 $intf_ip_step]
            } elseif  {$mask == 16} {
                set ipv4AddrStepValue [string replace "0.0.0.0" 2 2 $intf_ip_step]
            } elseif  {$mask == 24} {
                set ipv4AddrStepValue [string replace "0.0.0.0" 4 4 $intf_ip_step]
            } else {
                set ipv4AddrStepValue [string replace "0.0.0.0" 6 6 $intf_ip_step]
            }
        }
    }

    if {[info exists dut_ip_step] && $dut_ip_step != "" } {
        if {$mask != ""} {
           if {$mask == 8} {
                set ipv4DutStepValue [string replace "0.0.0.0" 0 0 $dut_ip_step]
            } elseif  {$mask == 16} {
                set ipv4DutStepValue [string replace "0.0.0.0" 2 2 $dut_ip_step]
            } elseif  {$mask == 24} {
                set ipv4DutStepValue [string replace "0.0.0.0" 4 4 $dut_ip_step]
            } else {
                set ipv4DutStepValue [string replace "0.0.0.0" 6 6 $dut_ip_step]
            }
        }
    }

    if {[info exists ipv6_addr_step] && $ipv6_addr_step != ""} {
        if {$ipv6_mask != ""} {
           if {$ipv6_mask == 16} {
               set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 0 0 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 32} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 2 2 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 48} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 4 4 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 64} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 6 6 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 80} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 8 8 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 96} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 10 10 $ipv6_addr_step]
            } elseif  {$ipv6_mask == 112} {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 12 12 $ipv6_addr_step]
            } else {
                set ipv6AddrStepValue [string replace "0:0:0:0:0:0:0:0" 14 14 $ipv6_addr_step]
            }
        }
    }

    if {[info exists dut_ip_step] && $dut_ip_step != ""} {
        if {$ipv6_mask != ""} {
           if {$ipv6_mask == 16} {
               set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 0 0 $dut_ip_step]
            } elseif  {$ipv6_mask == 32} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 2 2 $dut_ip_step]
            } elseif  {$ipv6_mask == 48} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 4 4 $dut_ip_step]
            } elseif  {$ipv6_mask == 64} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 6 6 $dut_ip_step]
            } elseif  {$ipv6_mask == 80} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 8 8 $dut_ip_step]
            } elseif  {$ipv6_mask == 96} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 10 10 $dut_ip_step]
            } elseif  {$ipv6_mask == 112} {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 12 12 $dut_ip_step]
            } else {
                set ipv6DutStepValue [string replace "0:0:0:0:0:0:0:0" 14 14 $dut_ip_step]
            }
        }
    }

	for { set index 0 } { $index < $intf_num } { incr index } {
	    if {$foundTopoPort == false} {
            set deviceGroupObj [ixNet add [lindex $topoObj end] deviceGroup]
            ixNet commit
            set deviceGroupObj [ixNet remapIds $deviceGroupObj]

            ixNet setAttr $deviceGroupObj -multiplier 1
            set ethObj [ixNet add $deviceGroupObj ethernet]
            ixNet commit
            set ethObj [ixNet remapIds $ethObj]
            ixNet setA [ixNet getA $ethObj -mac] -pattern singleValue
            lappend intf_mac [ ixNet getA [ixNet getA $ethObj -mac]/singleValue -value ]
        }
    }

    if {$flagOuterVlan != 0 && $flagInnerVlan != 0 } {
        set numOfVlans 2
    } elseif {$flagOuterVlan == 0 && $flagInnerVlan != 0 } {
        set numOfVlans 1
    } elseif {$flagOuterVlan != 0 && $flagInnerVlan == 0 } {
        set numOfVlans 1
    } else {
        set numOfVlans 0
    }

    if {[info exists numOfVlans] && $numOfVlans != 0} {
        ixNet setA $ethObj -useVlans True
        ixNet setA $ethObj -vlanCount $numOfVlans
        ixNet commit
    }

    if { [ info exists mac_addr ] } {
        foreach topo $topoObj {
            set vportObj [ixNet getA $topo -vports]
            if {$vportObj == $handle} {
                set deviceGroupObj [ixNet getL $topo deviceGroup]
                foreach deviceGroup $deviceGroupObj {
                    set ethObj [ixNet getL $deviceGroup ethernet]
                    ixNet setA [ixNet getA $ethObj -mac]/singleValue -value $mac_addr
                }
                ixNet commit
            }
        }
    }
    
    if { [ info exists transmit_mode ] } {
        ixNet setA $handle -txMode $transmit_mode
        ixNet commit
    }
    ixNet commit

    if { [ info exists ip_version ] == 0 || $ip_version != "ipv4" } {
		if { [ info exists ipv6_addr ] == 0 && [ info exists intf_ip ] } {
			set a [ lindex [ split $intf_ip "." ] 0 ]
			set b [ lindex [ split $intf_ip "." ] 1 ]
			set c [ lindex [ split $intf_ip "." ] 2 ]
			set d [ lindex [ split $intf_ip "." ] 3 ]
			set ipv6_addr "::${a}:${b}:${c}:${d}"
		}
	}
    Deputs "set ipv6 on interface..."
    set topoObj [ixNet getL [ixNet getRoot] topology]
    foreach topo $topoObj {
        set vportObj [ixNet getA $topo -vports]
        if {$vportObj == $handle} {
            set deviceGroupObj [ixNet getL $topo deviceGroup]
            foreach deviceGroup $deviceGroupObj {
                set ethObj [ixNet getL $deviceGroup ethernet]
                if { [ info exists ipv6_addr ] } {
                    if { [ llength [ ixNet getList $ethObj ipv6 ] ] == 0 } {
                        set ipv6Obj [ ixNet add $ethObj ipv6 ]
                        ixNet commit
                    } else {
                        set ipv6Obj [ lindex [ ixNet getList $ethObj ipv6 ] 0 ]
                    }
                    set ipv6Obj [ixNet remapIds $ipv6Obj]
                    ixNet setA [ixNet getA $ipv6Obj -address]/counter -start $ipv6_addr

                    if {[info exists ipv6_addr_step] && $ipv6_addr_step != ""} {
                        ixNet setA [ixNet getA $ipv6Obj -address]/counter -step $ipv6AddrStepValue
                    }
                    ixNet setA [ixNet getA $ipv6Obj -address]/counter -direction increment

                    ixNet setA [ixNet getA $ipv6Obj -prefix]/counter -start $ipv6_mask
                    ixNet commit
                }
                Deputs "set dut ipv6 address..."
                if { [ info exists dut_ipv6 ] } {
                    if { [ llength [ ixNet getList $ethObj ipv6 ] ] == 0 } {
                        set ipv6Obj [ ixNet add $ethObj ipv6 ]
                        ixNet commit
                    } else {
                        set ipv6Obj [ lindex [ ixNet getList $ethObj ipv6 ] 0 ]
                    }
                    ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/counter -start $dut_ipv6
                    ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/counter -direction increment

                    ixNet setA [ixNet getA $ipv6Obj -prefix]/counter -start $ipv6_mask
                    ixNet commit
                }

                Deputs "set ipv4 on interface..."
                if { [ info exists intf_ip ] } {
                    if { [ llength [ ixNet getList $ethObj ipv4 ] ] == 0 } {
                        set ipv4Obj [ ixNet add $ethObj ipv4 ]
                        ixNet commit
                    } else {
                        set ipv4Obj [ lindex [ ixNet getList $ethObj ipv4 ] 0 ]
                    }
                    set ipv4Obj [ixNet remapIds $ipv4Obj]
                    ixNet setA [ixNet getA $ipv4Obj -address]/counter -start $intf_ip
                    if [info exists intf_ip_step] {
                        ixNet setA [ixNet getA $ipv4Obj -address]/counter -step $ipv4AddrStepValue
                    }
                    ixNet setA [ixNet getA $ipv4Obj -address]/counter -direction increment

                    ixNet setA [ixNet getA $ipv4Obj -prefix]/counter -start $mask
                    ixNet commit
                    lappend intf_ipv4 $intf_ip
                    Deputs "int_ip: $intf_ip"
                }
                Deputs "set dut ipv4 address..."
                if { [ info exists dut_ip ] } {
                    if { [ llength [ ixNet getList $ethObj ipv4 ] ] == 0 } {
                        set ipv4Obj [ ixNet add $ethObj ipv4 ]
                        ixNet commit
                    } else {
                        set ipv4Obj [ lindex [ ixNet getList $ethObj ipv4 ] 0 ]
                    }
                    ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/counter -start $dut_ip
                    if {[info exists dut_ip_step]} {
                        ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/counter -step $dut_ip_step
                    }
                    ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/counter -direction increment

                    ixNet setA [ixNet getA $ipv4Obj -prefix]/counter -start $mask
                    ixNet commit
                    Deputs "dut_ip: $dut_ip"
                }
            }
        }
    }
    ixNet commit

    if { $flagInnerVlan } {
        Deputs "Setting innver vlan for port::config"
        set innerVlanHandle [lindex [ixNet getL $ethObj vlan] end]
        if {[info exists inner_vlan_id]} {
            ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -start $inner_vlan_id -direction increment
            ixNet commit
        }
        if {[info exists inner_vlan_step]} {
            ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -step $inner_vlan_step
            ixNet commit
        }
        if {[info exists inner_vlan_priority]} {
            ixNet setA [ixNet getA $innerVlanHandle -priority]/singleValue -value $inner_vlan_priority
            ixNet commit
        }
        ixNet commit
        if {[info exists inner_vlan_num]} {
            ixNet setA [ixNet getA $innerVlanHandle -vlanId] -pattern custom
            ixNet commit
            set incrementObj [ixNet add [ixNet getA $innerVlanHandle -vlanId]/custom increment]
            ixNet commit
            if { [ info exists inner_vlan_step] } {
                ixNet setA $incrementObj -value $inner_vlan_step
            } else {
                ixNet setA $incrementObj -value 1
            }
            set incObj [ixNet add $incrementObj increment]
            ixNet commit
            ixNet setA $incObj -count $inner_vlan_num
            # ixNet setA incrementObj -count $inner_vlan_num
        }
        ixNet commit
    }

    if { $flagOuterVlan } {
        Deputs "setting outer vlan for port::config"
        set outerVlanHandle [lindex [ixNet getL $ethObj vlan] 0]
        if {[info exists outer_vlan_id]} {
            ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -start $outer_vlan_id -direction increment
        }
        if {[info exists outer_vlan_step]} {
            ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -step $outer_vlan_step
        }
        if {[info exists outer_vlan_priority]} {
            ixNet setA [ixNet getA $outerVlanHandle -priority]/singleValue -value $outer_vlan_priority
        }
        ixNet commit
        if {[info exists outer_vlan_num]} {
            ixNet setA [ixNet getA $outerVlanHandle -vlanId] -pattern custom
            ixNet commit
            set incrementObj [ixNet add [ixNet getA $outerVlanHandle -vlanId]/custom increment]
            ixNet commit

            if { [ info exists outer_vlan_step ] } {
                ixNet setA $incrementObj -value $outer_vlan_step
            } else {
                ixNet setA $incrementObj -value 1
            }
            set incObj [ixNet add $incrementObj increment]
            ixNet commit
            ixNet setA $incObj -count $outer_vlan_num
        }
    }
    ixNet commit    
    
    if { [ info exists type ] } {
        switch $type  {
            eth {
                set ix_type ethernet
            }
            ethernetFcoe {
                set ix_type ethernetFcoe
            }
            pos -
            atm {
                set ix_type $type
            }
            10g_lan {
                set ix_type tenGigLan
            }
            10g_wan {
                set ix_type tenGigWan
            }
            100g_lan {
               set ix_type tenFortyHundredGigLan 
            }
        }
        ixNet setA $handle -type $ix_type
		if { $ix_type == "tenGigWan" } {
			ixNet setA $handle/l1Config/tenGigWan -interfaceType wanSdh
		}
        ixNet commit
    }
    
    if { [ info exists fec_enable ] } {
        catch {
            ixNet setA $handle/l1Config/tenFortyHundredGigLan -enableRsFec $fec_enable
            ixNet setA $handle/l1Config/tenFortyHundredGigLan -ieeeL1Defaults $fec_enable
            ixNet commit
        }
    }
    
    if { [ info exists speed ] } {
	    if {[ixNet getA $handle -type] == "ethernet" } {
			set ori_speed [ ixNet getA $handle/l1Config/ethernet -speed ]
			Deputs "ori speed:$ori_speed"
			if { $ori_speed == "null" } {
				set ori_speed auto
			}
			if { $speed == 1000 } {
				ixNet setA $handle/l1Config/ethernet -speed speed1000
				ixNet commit
			} else {
				if { ($ori_speed == "auto") || ($ori_speed == "speed1000") } {
					set duplex fd
				} else {
					regexp {\d+([fh]d)} $ori_speed match duplex
				}
				ixNet setA $handle/l1Config/ethernet -speed speed$speed$duplex
				ixNet commit
			}
		}
		if {[ixNet getA $handle -type] == "hundredGigLan"} {
			if { $speed == "speed40g" || $speed == "speed100g" } {
				ixNet setA $handle/l1Config/hundredGigLan -speed $speed
				ixNet commit
			}
		}
    }
    
    if { [ info exists duplex ] } {
        switch $duplex {
            full { set duplex fd }
            half { set duplex hd }
        }
        set speed [ ixNet getA $handle/l1Config/ethernet -speed ]
        if { ( $speed == "speed1000" ) || ( $speed == "auto" ) } {
            Deputs "wrong configuration for duplex with speed1000 or auto speed"
        } else {
            if { [ regexp {(\d+)} $speed match speed ] } {
                ixNet setA $handle/l1Config/ethernet -speed speed$speed$duplex
                ixNet commit
            }
        }
    }

    Deputs "enable arp with value $enable_arp"
    if { [ info exists enable_arp ] } {
        set root [ixNet getRoot]
        if {$enable_arp == 1} {
            ixNet setA [ixNet getA ::ixNet::OBJ-/globals/topology/ipv4 -reSendArpOnLinkUp]/singleValue -value true
            ixNet setA [ixNet getA ::ixNet::OBJ-/globals/topology/ipv6 -reSendNsOnLinkUp]/singleValue -value true
        } else {
            ixNet setA [ixNet getA ::ixNet::OBJ-/globals/topology/ipv4 -reSendArpOnLinkUp]/singleValue -value false
            ixNet setA [ixNet getA ::ixNet::OBJ-/globals/topology/ipv6 -reSendNsOnLinkUp]/singleValue -value false
        }
        ixNet commit
    }
    
    if { [ info exists media ] } {
        if {[ixNet getA $handle -type] == "ethernet" } {
            ixNet setA $handle/l1Config/[ixNet getA $handle -type] -media $media
            Deputs "media type changed to $media"
            ixNet commit
        }
        
    }
    
    if { [ info exists auto_neg ] } {
        if { $auto_neg } {
            set auto_neg True
        } else {
            set auto_neg False
        }
		catch {
			ixNet setA $handle/l1Config/[ixNet getA $handle -type]  -autoNegotiate $auto_neg 
            Deputs "autoneg option changed to $auto_neg"
			ixNet commit
		}
    } 
    
    if { [ info exists flow_control ] } {
        Deputs "flow_control:$flow_control"
		ixNet setA $handle/l1Config/[ixNet getA $handle -type] -enabledFlowControl $flow_control
        Deputs "flowcontrol option changed to $flow_control"
		ixNet commit
    }
	if { [ info exists sig_end ] } {
		if { $sig_end } {
			ixNet setA $handle/l1Config/[ixNet getA $handle -type] -autoInstrumentation endOfFrame
		} else {
			ixNet setA $handle/l1Config/[ixNet getA $handle -type] -autoInstrumentation floating			
		}
		#ixNet commit
	}
	
    if { [ catch { ixNet  commit } err ] } {
		Deputs "commit err:$err"
	}
	#$this configure -ipVersion $ip_version
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]
}

body Port::get_status { } {
    global errorInfo
    global errNumber

    set tag "body Port::get_status [info script]"
Deputs "----- TAG: $tag -----"
#param collection
Deputs "handle:$handle"
    set phy_status [ ixNet getA $handle -state ]
Deputs Step10
    set neighbor [ lindex [ ixNet getL $handle discoveredNeighbor ] 0 ]
    set actaul_speed [ ixNet getA $handle -actualSpeed ]
Deputs Step20
Deputs "neighbor:$neighbor"
    if { [ catch {
    	set dutMac	[ MacTrans [ ixNet getA $neighbor -neighborMac ] 1 ]
    } ] } {
		set dutMac 00-00-00-00-00-00
    }
Deputs Step30
    if { [ catch {
		set dutIp	 [ ixNet getA $neighbor -neighborIp ]
    } ] } {
		set dutIp 0.0.0.0
    }
Deputs Step40    
    if { [ catch {
Deputs Step50   
    	set interface [ lindex [ ixNet getL $handle interface ] 0 ]
Deputs Step60
    	set ipv4Int   [ lindex [ ixNet getL $interface ipv4 ] 0 ]
Deputs Step70
    	set ipv4Addr [ ixNet getA $ipv4Int -ip ]
Deputs Step80
    } log ] } {
Deputs Step90
    	set ipv4Addr 0.0.0.0
    }
Deputs Step100  
	if { [ catch {
    	set interface [ lindex [ ixNet getL $handle interface ] 0 ]
		set port_mac	[ MacTrans [ ixNet getA $interface/ethernet -macAddress ] 1 ]
Deputs "port_mac:$port_mac"
		} ] } {
		set port_mac	00-00-00-00-00-00
	}
    set ret [ GetStandardReturnHeader ]
    set ret $ret[ GetStandardReturnBody "phy_state" $phy_status ]
    set ret $ret[ GetStandardReturnBody "dut_mac" $dutMac ]
    set ret $ret[ GetStandardReturnBody "port_ipv4_addr" $ipv4Addr ]
	set ret $ret[ GetStandardReturnBody "port_mac_addr" $port_mac ]
    set ret $ret[ GetStandardReturnBody "actual_speed" $actaul_speed ]
   
	return $ret
}

body Port::ping { args } {
    set tag "body Port::ping [info script]"
Deputs "----- TAG: $tag -----"

	set count 		1
	set interval 	1000
	set flag 		1

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -src {
                if { [ IsIPv4Address $value ] } {
                    set intf_ip $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -dst {
                if { [ IsIPv6Address $value ] || [ IsIPv4Address $value ] } {
                    set dut_ip $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -count {
                if { [ string is integer $value ] } {
                    set count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -interval {
                if { [ string is integer $value ] } {
                    set interval    $value

                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -flag {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_arp $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            default {
                error "$errNumber(3) key:$key value:$value"
            }
        }
    }
    
	set pingTrue	0
	set pingFalse	0

Deputs "add pint interface..."	
	if { [ info exists intf_ip ] } {
		set int [ixNet add $handle interface]
		ixNet setA $int/ipv4 -ip $intf_ip
		ixNet commit
		
	} else {
		set int [ ixNet getL $handle interface ]
		if { [ llength $int ] == 0 } {
			return [ GetErrorReturnHeader "No ping source identified or no interface created under current port." ]
		}
		
	}

Deputs Step10
	set pingResult [ list ]
	for { set index 0 } { $index < $count } { incr index } {
		
		lappend pingResult [ ixNet exec sendPing $int $dut_ip ]
		after $interval
	}
Deputs Step20
	set pingPass	0
	foreach result $pingResult {
		if { [ regexp {failed} $result ] } {
			incr pingFalse
			set pingPass 0
		} else {
			incr pingTrue
			set pingPass 1
		}
	}

Deputs Step30
	if { [ info exists intf_ip ] } {
		ixNet remove $int
		ixNet commit		
	}
	
Deputs Step40
	set loss [ expr $pingFalse / $count.00 * 100 ]
	
Deputs Step50
	if { $pingPass == $flag } {
		set ret  [ GetStandardReturnHeader ]
	} else {
		set ret  [ GetErrorReturnHeader "Unexpected result $pingPass" ]
	}
	
Deputs Step60
	lappend ret [ GetStandardReturnBody "loss" $loss ]
	
	return $ret
}

body Port::send_arp { } {
    set tag "body Port::send_arp [info script]"
Deputs "----- TAG: $tag -----"

	
	set intList [ ixNet getL $handle interface ]
    if { $intList != "" } {
        foreach int $intList {
            ixNet execs sendArpAndNS $int
        }
        after 1000
    }
	
    return [GetStandardReturnHeader]    
	
}

body Port::set_dhcpv4 { args } {
    set tag "body Port::set_dhcpv4 [info script]"
Deputs "----- TAG: $tag -----"

	global errNumber
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-request_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set request_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-max_request_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set max_request_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-request_rate_step {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set request_rate_step $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
            -lease_time {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set lease_time $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-release_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set release_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-max_release_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set max_release_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-release_rate_step {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set release_rate_step $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
            -outstanding_session -
			-max_outstanding_session {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set max_outstanding_session $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
            -override_global_setup {
                set override_global_setup $value
            }
		}
	}
	
	set root [ixNet getRoot]
	set dhcpGlobals [ ixNet getL $root/globals/protocolStack dhcpGlobals ]
    if { $dhcpGlobals == ""} {
	    set dhcpGlobals [ ixNet add $root/globals/protocolStack dhcpGlobals ]
	}
    set dhcpOptions [ ixNet getL $handle/protocolStack dhcpOptions ]
    if { [info exists override_global_setup] && $override_global_setup } {
        if { [ info exists request_rate ] } {
            ixNet setA $dhcpOptions -overrideGlobalSetupRate true
            ixNet setA $dhcpOptions -setupRateInitial $request_rate
            ixNet setA $dhcpOptions -setupRateMax $request_rate
        }
        if { [ info exists max_outstanding_session ] } {
            ixNet setA $dhcpOptions -overrideGlobalSetupRate true
            ixNet setA $dhcpOptions -overrideGlobalTeardownRate true
            ixNet setA $dhcpOptions -maxOutstandingRequests $max_outstanding_session
            ixNet setA $dhcpOptions -maxOutstandingReleases $max_outstanding_session
        }
        if { [ info exists release_rate ] } {
            ixNet setA $dhcpOptions -overrideGlobalTeardownRate true
            ixNet setA $dhcpOptions -teardownRateInitial $release_rate
            ixNet setA $dhcpOptions -teardownRateMax $release_rate
        }
    } else {
        if { [ info exists request_rate ] } {
            ixNet setA $dhcpOptions -overrideGlobalSetupRate false
            ixNet setA $dhcpGlobals -setupRateInitial $request_rate
            ixNet setA $dhcpGlobals -setupRateMax $request_rate
        }
        if { [ info exists max_outstanding_session ] } {
            ixNet setA $dhcpOptions -overrideGlobalSetupRate false
            ixNet setA $dhcpOptions -overrideGlobalTeardownRate false
            ixNet setA $dhcpGlobals -maxOutstandingRequests $max_outstanding_session
            ixNet setA $dhcpGlobals -maxOutstandingReleases $max_outstanding_session
        }
        if { [ info exists release_rate ] } {
            ixNet setA $dhcpOptions -overrideGlobalTeardownRate false
            ixNet setA $dhcpGlobals -teardownRateInitial $release_rate
            ixNet setA $dhcpGlobals -teardownRateMax $release_rate
        }
    }
	
	if { [ info exists max_request_rate ] } {
		ixNet setA $dhcpGlobals -setupRateMax $max_request_rate
	}
	if { [ info exists request_rate_step ] } {
		ixNet setA $dhcpGlobals -setupRateIncrement $request_rate_step
	}
	
    if { [ info exists lease_time ] } {
		ixNet setA $dhcpGlobals  -dhcp4AddrLeaseTime  $lease_time
	}
	
	if { [ info exists max_release_rate ] } {
		ixNet setA $dhcpGlobals -teardownRateMax $max_release_rate
	}
	if { [ info exists release_rate_step ] } {
		ixNet setA $dhcpGlobals -teardownRateIncrement $release_rate_step
	}
	
	
	ixNet commit
	return [ GetStandardReturnHeader ]
}

body Port::set_dhcpv6 { args } {
    set tag "body Port::set_dhcpv6 [info script]"
Deputs "----- TAG: $tag -----"
	set result  [ eval set_dhcpv4 $args ]
	return $result
}

body Port::set_dot1x { args } {
    set tag "body Port::set_dot1x [info script]"
Deputs "----- TAG: $tag -----"

	global errNumber
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-auth_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 100000 ) } {
                    set auth_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-logoff_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 1000 ) } {
                    set logoff_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-outstanding_rate {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 1000 ) } {
                    set outstanding_rate $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
            -retry_count {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value <= 1000 ) } {
                    set max_start [expr $value +1]
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}	
		}
	}
    
    set root [ixNet getRoot]
	set globalSetting [ ixNet getL $root/globals/protocolStack dot1xGlobals ]
    if { $globalSetting == ""} {
	    set globalSetting [ ixNet add $root/globals/protocolStack dot1xGlobals ]
	}
	if { [ info exists auth_rate ] } {
		ixNet setA $globalSetting -maxClientsPerSecond $auth_rate
	}
	if { [ info exists logoff_rate ] } {
		ixNet setA $globalSetting -logoffMaxClientsPerSecond $logoff_rate
	}
	if { [ info exists outstanding_rate ] } {
		ixNet setA $globalSetting -maxOutstandingRequests $outstanding_rate
	}
	
    if { [ info exists max_start ] } {
		ixNet setA $globalSetting  -maxStart  $max_start
	}
	
	
	ixNet commit
	return [ GetStandardReturnHeader ]
}

body Port::reset {} {
    set tag "body Port::reset [info script]"
    Deputs "----- TAG: $tag -----"
    ixNet exec setFactoryDefaults $handle
    ixNet commit
	return [ GetStandardReturnHeader ]
}

body Port::start_traffic {} {
    set tag "body Port::start_traffic [info script]"
Deputs "----- TAG: $tag -----"

Deputs "handle:$handle"
		set root [ ixNet getRoot]
        set applyflag 0
        if { [ ixNet getA ::ixNet::OBJ-/traffic -state ] == "unapplied" || [ ixNet getA ::ixNet::OBJ-/traffic -state ] == "stopped" } {
            set applyflag 1
        }
		set trafficList [ ixNet getL $root/traffic trafficItem ]
		foreach traffic $trafficList {
			
			lappend flowList [ ixNet getL $traffic highLevelStream]
		}
        if { $applyflag } {
            catch {
                Tester::generate_traffic
                after 1000
                Tester::apply_traffic
            }
        }
		
Deputs "flowList: $flowList"
		set flagApply 0
		foreach flow $flowList {
			foreach deepFlow $flow {
				set txPort [ ixNet getA $deepFlow -txPortId ]
				set state [ ixNet getA $deepFlow -state]
				
				if { $state != "started"} {
					if { $txPort == $handle } {
						lappend txList $deepFlow
					}
				}
			}
		}
		
Deputs "TxList: $txList"
				
		# foreach  startTx $txList {
		    # ixNet exec startStatelessTraffic $startTx
		    # # after 3000
		# }
		ixNet exec startStatelessTraffic $txList
        after 2000
Deputs "All streams are transtmitting!"
		return [ GetStandardReturnHeader ]
}

body Port::stop_traffic {} {
    set tag "body Port::stop_traffic [info script]"
Deputs "----- TAG: $tag -----"

Deputs "handle:$handle"
		set root [ ixNet getRoot]
		set trafficList [ ixNet getL $root/traffic trafficItem ]
		foreach traffic $trafficList {
			lappend flowList [ ixNet getL $traffic highLevelStream]
		}
Deputs "flowList: $flowList"
		set flagApply 0
		foreach flow $flowList {
			foreach deepFlow $flow {
				set txPort [ ixNet getA $deepFlow -txPortId ]
				if { $txPort == $handle } {
					set state [ ixNet getA $deepFlow -state]
					if { $state != "stopped"} {
						lappend txList $deepFlow
					}
				}
				
			}
		}
			
		# foreach  stopTx $txList {
		    # ixNet exec stopStatelessTraffic $stopTx
		    # after 3000
		# }
        ixNet exec stopStatelessTraffic $txList
        after 2000
Deputs "All streams are stopped!"

		return [ GetStandardReturnHeader ]
}

body Port::start_router { args } {
    set tag "body Port::start_router [info script]"
Deputs "----- TAG: $tag -----"
    global LoadConfigMode
    set device_type_list ""
    set device_id_list ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -device_type {
                set device_type_list $value
            }
            -device_id {
                set device_id_list  $value
            }

        }
    }
    
   
    set root [ixNet getRoot]
   
  
    if { !$LoadConfigMode   } {
        GetProtocolsHandleList
    }
    
	if { $device_type_list !=  "" } {
	    foreach device_type $device_type_list {
		    set device_type [string tolower $device_type]
			switch -exact -- $device_type {
				bgp {                    
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(bgp) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size bgpList] != 1 } {
							foreach {dName dHandle} [array get bgpList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(bgp)
						}
					}
					
				}
				isis {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(isis) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size isisList] != 1 } {
							foreach {dName dHandle} [array get isisList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(isis)
						}
					}
				}
				ldp {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(ldp) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size ldpList] != 1 } {
							foreach {dName dHandle} [array get ldpList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(ldp)
						}
					}
				}
				igmp {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(igmp) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size igmpList] != 1 } {
							foreach {dName dHandle} [array get igmpList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(igmp)
						}
					}
				}
				mld {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(mld) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size mldList] != 1 } {
							foreach {dName dHandle} [array get mldList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(mld)
						}
					}
				}
				rip {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(rip) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size ripList] != 1 } {
							foreach {dName dHandle} [array get ripList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(rip)
						}
					}
				}
				ripng {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle deviceList(ripng) 
						   Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size ripngList] != 1 } {
							foreach {dName dHandle} [array get ripngList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(ripng)
						}
					}
				}
                ospf -
				ospfv2 {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(ospf)
		 Deputs "deviceHandle:$deviceHandle"                   
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size ospfList] != 1 } {
							foreach {dName dHandle} [array get ospfList ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(ospf)
						}
					}
				}
				ospfv3 {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(ospfv3) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					} else {
						if { [array size ospfv3List] != 1 } {
							foreach {dName dHandle} [array get ospfv3List ] {
								if { [lsearch -exact $device_id_list $dName] } {
									ixNet setA $dHandle -enabled true
									ixNet commit
								} else {
									ixNet setA $dHandle -enabled false
									ixNet commit
								}
							}
							ixNet exec start  $deviceList(ospfv3)
						}
					}
				}
                bfd {
                    if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(bfd) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					}
                    
                }
                rsvp {
                    if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(rsvp) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle
						}
					}
                    
                }
				dhcp {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(dhcp) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle async
						}
					} else {
						if { [array size dhcpList] != 1 } {
							foreach {dName dHandle} [array get dhcpList ] {
								ixNet exec start  $dHandle   async
							}
							
						}
					}
				   
				}
				pppox {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(pppox) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle async
						}
					} else {
						if { [array size pppoxList] != 1 } {
							foreach {dName dHandle} [array get pppoxList ] {
								ixNet exec start  $dHandle   async
							}
							
						}
					}
				}
				l2tp {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(l2tp) 
							Deputs "deviceHandle:$deviceHandle"
						   ixNet exec start $deviceHandle async
						}
					} else {
						if { [array size l2tpList] != 1 } {
							foreach {dName dHandle} [array get l2tpList ] {
								ixNet exec start  $dHandle   async
							}
							
						}
					}
				}
			}
		}
	} else {
	    if { [array size deviceList] != 1 } {
			foreach {dName dHandle} [array get deviceList ] {
				ixNet exec start  $dHandle   
			}
			
		}
	}

    
    
	return [ GetStandardReturnHeader ]
}

body Port::stop_router { args } {
    set tag "body Port::stop_router [info script]"
Deputs "----- TAG: $tag -----"
    set device_type_list ""
    set device_id_list ""
    global LoadConfigMode
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -device_type {
                set device_type_list $value
            }
            -device_id {
                set device_id_list  $value
            }

        }
    }
          
    
    if { !$LoadConfigMode   } {
       GetProtocolsHandleList
    }
    if { $device_type_list !=  "" } {
	    foreach device_type $device_type_list {
		    set device_type [string tolower $device_type]
			switch -exact -- $device_type {
				bgp { 
					catch {
					   set deviceHandle $deviceList(bgp) 
					   ixNet exec stop $deviceHandle
					}        
				   
					
				}
				isis {
					catch {
					   set deviceHandle $deviceList(isis) 
					   ixNet exec stop $deviceHandle
					}
				}
				ldp {
					catch {
					   set deviceHandle $deviceList(ldp) 
					   ixNet exec stop $deviceHandle
					}
				}
				igmp {
					catch {
					   set deviceHandle $deviceList(igmp) 
					   ixNet exec stop $deviceHandle
					}
				}
				mld {
					catch {
					   set deviceHandle $deviceList(mld) 
					   ixNet exec stop $deviceHandle
					}
				}
				rip {
					catch {
					   set deviceHandle $deviceList(rip) 
					   ixNet exec stop $deviceHandle
					}
				}
				ripng {
					catch {
					   set deviceHandle $deviceList(ripng) 
					   ixNet exec stop $deviceHandle
					}
				}
                ospf -
				ospfv2 {
					catch {
					   set deviceHandle $deviceList(ospf) 
					   ixNet exec stop $deviceHandle
					}
				}
				ospfv3 {
					catch {
					   set deviceHandle $deviceList(ospfv3) 
					   ixNet exec stop $deviceHandle
					}
				}
                bfd {
                    catch {
					   set deviceHandle $deviceList(bfd) 
					   ixNet exec stop $deviceHandle
					}
                    
                }
                rsvp {
                    catch {
					   set deviceHandle $deviceList(rsvp) 
					   ixNet exec stop $deviceHandle
					}
                    
                }
				dhcp {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(dhcp) 
						   ixNet exec stop $deviceHandle
						}
					} else {
						if { [array size dhcpList] != 1 } {
							foreach {dName dHandle} [array get dhcpList ] {
								ixNet exec stop  $dHandle   async
							}
							
						}
					}
				   
				}
				pppox {
					if { $device_id_list == "" } {
						catch {
						   set deviceHandle $deviceList(pppox) 
						   ixNet exec stop $deviceHandle
						}
					} else {
						if { [array size pppoxList] != 1 } {
							foreach {dName dHandle} [array get pppoxList ] {
								ixNet exec stop $dHandle   async
							}
							
						}
					}
				}
            }
		}
	} else {
	    if { [array size deviceList] != 1 } {
			foreach {dName dHandle} [array get deviceList ] {
				ixNet exec stop  $dHandle   
			}
			
		}
	}
    
    
	return [ GetStandardReturnHeader ]
}

body Port::break_link {} {
    set tag "body Port::break_link [info script]"
Deputs "----- TAG: $tag -----"
    ixNet exec linkUpDn $handle down
    ixNet commit
	return [ GetStandardReturnHeader ]
}

body Port::restore_link {} {
    set tag "body Port::restore_link [info script]"
Deputs "----- TAG: $tag -----"
    ixNet exec linkUpDn $handle up
    ixNet commit
	return [ GetStandardReturnHeader ]
}

body Port::get_stats {} {

    set tag "body Port::get_stats [info script]"
    Deputs "----- TAG: $tag -----"
    
	#{::ixNet::OBJ-/statistics/view:"Port Statistics"}
    set root [ixNet getRoot]
	set view {::ixNet::OBJ-/statistics/view:"Port Statistics"}
    set rxview {::ixNet::OBJ-/statistics/view:"Data Plane Port Statistics"}
	set proview {::ixNet::OBJ-/statistics/view:"Global Protocol Statistics"}
    # set view  [ ixNet getF $root/statistics view -caption "Port Statistics" ]
    Deputs "view:$view"
    Deputs "rxview:$rxview"
    Deputs "proview:$proview"
    set captionList             [ ixNet getA $view/page -columnCaptions ]
	#set rxcaptionList [ ixNet getA $rxview/page -columnCaptions ]
    if { [catch { set rxcaptionList [ ixNet getA $rxview/page -columnCaptions ] } ]  } {
	    set rxcaptionList [list Port {Rx Frames}]
	} 
	set proCaptionList [ ixNet getA $proview/page -columnCaptions ]
    Deputs "caption list:$captionList"
    Deputs "rxcaptionList:$rxcaptionList"
    Deputs "pro caption list:$proCaptionList"
	set port_name				[ lsearch -exact $captionList {Stat Name} ]
    set tx_frame_count          [ lsearch -exact $captionList {Frames Tx.} ]
    set total_frame_count       [ lsearch -exact $captionList {Valid Frames Rx.} ]
    set tx_frame_rate         	[ lsearch -exact $captionList {Frames Tx. Rate} ]
    set rx_frame_rate         	[ lsearch -exact $captionList {Valid Frames Rx. Rate} ]
    set tx_bit_rate         	[ lsearch -exact $captionList {Tx. Rate (bps)} ]
    set rx_bit_rate       		[ lsearch -exact $captionList {Rx. Rate (bps)} ]
    set fcs_error_frame        	[ lsearch -exact $captionList {CRC Errors} ]
    set rx_data_integrity	    [ lsearch -exact $captionList {Data Integrity Frames Rx.} ]
    
	set rx_frame_count          [ lsearch -exact $rxcaptionList {Rx Frames}]
    set rx_port                 [ lsearch -exact $rxcaptionList Port]

	set control_pkt_tx			[ lsearch -exact $proCaptionList {Control Packet Tx.} ]
	set control_pkt_rx			[ lsearch -exact $proCaptionList {Control Packet Rx.} ]
	set ping_reply_tx			[ lsearch -exact $proCaptionList {Ping Reply Tx.} ]
	set ping_request_tx			[ lsearch -exact $proCaptionList {Ping Request Tx.} ]
	set ping_reply_rx			[ lsearch -exact $proCaptionList {Ping Reply Rx.} ]
	set ping_request_rx			[ lsearch -exact $proCaptionList {Ping Request Rx.} ]
	set arp_reply_tx			[ lsearch -exact $proCaptionList {Arp Reply Tx.} ]
	set arp_reply_rx			[ lsearch -exact $proCaptionList {Arp Reply Rx.} ]
	set arp_request_tx			[ lsearch -exact $proCaptionList {Arp Request Tx.} ]
	set arp_request_rx			[ lsearch -exact $proCaptionList {Arp Request Rx.} ]
	
    set ret [ GetStandardReturnHeader ]
	
    set stats    [ ixNet getA $view/page -rowValues ]
    #set rxstats  [ ixNet getA $rxview/page -rowValues ]
	if { [catch { set rxstats  [ ixNet getA $rxview/page -rowValues ] } ]} {
	    set rxstats [list $this  "0"]
	}
	set proStats [ ixNet getA $proview/page -rowValues ]
	
    Deputs "stats:$stats"
    Deputs "pro stats:$proStats"

    set connectionInfo [ ixNet getA $handle -connectionInfo ]
    Deputs "connectionInfo :$connectionInfo"
    regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
    Deputs "chas:$chassis card:$card port$port"

    foreach row $stats {
        eval {set row} $row
        Deputs "row:$row"
        Deputs "portname:[ lindex $row $port_name ]"
		if { [ string length $card ] == 1 } {
			set card "0$card"
		}
		if { [ string length $port ] == 1 } {
			set port "0$port"
		}
		if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
			continue
		}

        set statsItem   "tx_frame_count"
        set statsVal    [ lindex $row $tx_frame_count ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "total_frame_count"
        set statsVal    [ lindex $row $total_frame_count ]
Deputs "stats val:$statsVal"
    	if { $statsVal < 1 } {
		    set statsVal [ lindex $row $rx_data_integrity ]
Deputs "stats val:$statsVal"
    	}
		if { $statsVal < 1 } {
		    ixConnectToTclServer $chassis
			ixConnectToChassis $chassis
			set chas [chassis cget -id]
		    
		    stat get statAllStats $chas $card $port
            set statsVal [ stat cget -oversize ]
		    
Deputs "stats val:$statsVal"
    	}
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
              
        set statsItem   "tx_frame_rate"
        set statsVal    [ lindex $row $tx_frame_rate ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "rx_frame_rate"
        set statsVal    [ lindex $row $rx_frame_rate ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "tx_bit_rate"
        set statsVal    [ lindex $row $tx_bit_rate ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "rx_bit_rate"
        set statsVal    [ lindex $row $rx_bit_rate ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]          

    }
    
    foreach rxrow $rxstats {
        
        eval {set rxrow} $rxrow
Deputs "rxrow:$rxrow"

	
		if { $this != [ lindex $rxrow $rx_port ] } {
			continue
		}

        set statsItem   "rx_frame_count"
        set statsVal    [ lindex $rxrow $rx_frame_count ]
Deputs "stats val:$statsVal"
        if { $statsVal =="" } {
		    set statsVal "0"
Deputs "stats val:$statsVal"
    	}
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
    }
    
    foreach row $stats {
        
        eval {set row} $row
Deputs "row:$row"
Deputs "portname:[ lindex $row $port_name ]"
		if { [ string length $card ] == 1 } {
			set card "0$card"
		}
		if { [ string length $port ] == 1 } {
			set port "0$port"
		}
		if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
			continue
		}
              
        set statsItem   "fcs_error_frame"
        set statsVal    [ lindex $row $fcs_error_frame ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "ipv4_rrame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "ipv6_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "jumbo_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "mpls_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "oversize_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "prbs_bit_error_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "tcp_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "udp_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "vlan_frame_count"
        set statsVal    "NA"
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

Deputs "ret:$ret"

    }
        
    foreach row $proStats {
        
        eval {set row} $row
Deputs "row:$row"
Deputs "portname:[ lindex $row $port_name ]"
		if { [ string length $card ] == 1 } {
			set card "0$card"
		}
		if { [ string length $port ] == 1 } {
			set port "0$port"
		}
		if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
			continue
		}
              
        set statsItem   "control_pkt_tx"
        set statsVal    [ lindex $row $control_pkt_tx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "control_pkt_rx"
        set statsVal    [ lindex $row $control_pkt_rx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "ping_reply_tx"
        set statsVal    [ lindex $row $ping_reply_tx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "ping_reply_rx"
        set statsVal    [ lindex $row $ping_reply_rx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "ping_request_tx"
        set statsVal    [ lindex $row $ping_request_tx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "ping_request_rx"
        set statsVal    [ lindex $row $ping_request_rx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
	    set statsItem   "arp_reply_tx"
        set statsVal    [ lindex $row $arp_reply_tx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "arp_reply_rx"
        set statsVal    [ lindex $row $arp_reply_rx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "arp_request_tx"
        set statsVal    [ lindex $row $arp_request_tx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "arp_request_rx"
        set statsVal    [ lindex $row $arp_request_rx ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
Deputs "ret:$ret"

    }
        
    return $ret

}

body Port::set_port_stream_load { args } {
    set tag "body Port::set_port_stream_load [info script]"
Deputs "----- TAG: $tag -----"

Deputs "hport:$handle"

	global errNumber
	
    set ELoadUnit	[ list KBPS MBPS BPS FPS PERCENT ]
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-stream_load {
				if { [ string is integer $value ] || [ string is double $value ] } {
					set stream_load $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}				
			}
			-load_unit {
				set value [ string toupper $value ]
				if { [ lsearch -exact $ELoadUnit $value ] >= 0 } {

					set load_unit $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}			
			}
		}
	}
	
	set root [ixNet getRoot]
	set allObj [ find objects ]
	set trafficObj [ list ]
	foreach obj $allObj {
		if { [ $obj isa Traffic ] } {
			if { [ $obj cget -hPort ] == $handle } {
                Deputs "trafficObj: $obj; hport :$handle"
			    set objhandle [ $obj cget -handle]
                Deputs "$obj:$objhandle"
                if {$objhandle != ""} {
		
				    lappend trafficObj $obj
				}
			}
		}
	}
	if { [ llength $trafficObj ] == 0 } {
	   return [ GetErrorReturnHeader "No Traffic found under current port." ]
	}
	if { $load_unit == "MBPS" } {
	    set portspeed [ixNet getA $handle -actualSpeed]
		set stream_load [expr $stream_load *100/ $portspeed.0]
		set load_unit "PERCENT"
	}
	set unitLoad [ expr $stream_load / [ llength $trafficObj ].0 ]
    Deputs "unitLoad : $unitLoad"
	foreach obj $trafficObj {
	
		$obj config -stream_load $unitLoad -load_unit $load_unit 
	}
	
	return [GetStandardReturnHeader]

}

body Port::set_port_dynamic_rate { args } {
    set tag "body Port::set_port_dynamic_rate [info script]"
Deputs "----- TAG: $tag -----"

Deputs "hport:$handle"

	global errNumber
	
    set ELoadUnit	[ list KBPS MBPS BPS FPS PERCENT ]
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-stream_load {
				if { [ string is integer $value ] || [ string is double $value ] } {
					set stream_load $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}				
			}
			-load_unit {
				set value [ string toupper $value ]
				if { [ lsearch -exact $ELoadUnit $value ] >= 0 } {

					set load_unit $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}			
			}
		}
	}
	
	set root [ixNet getRoot]
	set allObj [ find objects ]
	set trafficObj [ list ]
	foreach obj $allObj {
		if { [ $obj isa Traffic ] } {
			if { [ $obj cget -hPort ] == $handle } {
                Deputs "trafficObj: $obj; hport :$handle"
			    set objhandle [ $obj cget -handle]
                Deputs "$obj:$objhandle"
                if {$objhandle != ""} {
				    lappend trafficObj $obj
				}
			}
		}
	}
    
	if { [ llength $trafficObj ] == 0 } {
	   return [ GetErrorReturnHeader "No Traffic found under current port." ]
	}
    
	if { $load_unit == "MBPS" } {
	    set portspeed [ixNet getA $handle -actualSpeed]
		set stream_load [expr $stream_load *100/ $portspeed.0]
		set load_unit "PERCENT"
	}
	set unitLoad [ expr $stream_load / [ llength $trafficObj ].0 ]
Deputs "unitLoad : $unitLoad"

    set dynamiclist [ixNet getL ::ixNet::OBJ-/traffic dynamicRate]
	foreach obj $trafficObj {
        foreach flowobj $dynamiclist {
           if { [string match *$obj* $flowobj] } {
               lappend dynamichandle $flowobj
           }
        }
	
		#$obj config -stream_load $unitLoad -load_unit $load_unit 
	}
    switch $load_unit {
        KBPS {
            set loadunit bitsPerSecond 
        }
        MBPS {
            set loadunit bitsPerSecond 			
        }
        BPS {
            set loadunit bitsPerSecond 			
        }
        FPS {
            set loadunit framesPerSecond 			
        }
        PERCENT {
            set loadunit percentLineRate 			
        }
    }
    foreach objhandle $dynamichandle {
        ixNet setA $objhandle -rateType $loadunit
    
        ixNet setA $objhandle -rate $unitLoad 
                             
    }
  
    ixNet commit
	
	return [GetStandardReturnHeader]

}

class Host {
	inherit NetNgpfObject
	constructor { port } {}
	method config { args } {}
	method unconfig {} {
        set tag "body Host::unconfig [info script]"
        Deputs "----- TAG: $tag -----"
		set hPort ""
		chain
	}
	method enable {} {
        set tag "body Host::enable [info script]"
    Deputs "----- TAG: $tag -----"
        foreach int $handle {
            ixNet setA $int -enabled true
            ixNet commit
        }
    }
	method disable {} {
        set tag "body Host::disable [info script]"
    Deputs "----- TAG: $tag -----"
        foreach int $handle {
            ixNet setA $int -enabled false
            ixNet commit
        }
    }
	method ping { args } {}
	method reborn {} {
		if { [ catch {
			set hPort [ $portObj cget -handle ]
		} ] } {
			set port [ GetObject $portObj ]
			set hPort [ $port cget -handle ]
		}
	}
	method start_arp_nd {} {
        set tag "body Host::start_arp_nd [info script]"
    Deputs "----- TAG: $tag -----"
        ixNet execs sendArpAndNS $handle
        
    }
    method stop_arp_nd { } {
        set tag "body Host::stop_arp_nd [info script]"
    Deputs "----- TAG: $tag -----"
    }
	public variable hPort
	public variable portObj
	public variable static
	# public variable ip_version
    public variable hostInfo
    public variable ipVersion
}

body Host::constructor { port } {
    set portObj $port
	
	reborn
	set handle ""
    set hostInfo ""
}

body Host::config { args } {
    global errNumber
    
    set tag "body Host::config [info script]"
    Deputs "----- TAG: $tag -----"
	
	if { $hPort == "" } {
		reborn
	}
	
	set count 			1
	# set src_mac			"00:10:94:00:00:02"
	set src_mac_step	"00:00:00:00:00:01"
	set vlan_id1_step	1
	set vlan_id2_step	1
	set ipv4_addr_step	0.0.0.1
	set ipv4_prefix_len	24
	set ipv4_gw			1.1.1.1
	set ipv6_addr_step	::1
	set ipv6_prefix_len	64
	set ipv6_gw			3ffe:3210::1
	set ip_version		ipv4
	set enabled 		True
    set unconnected		0
	set static 0
    set enable_vlan true
	
    set hostInfo $args
    
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-enabled {
				set  enabled $value
			}
            -enable_vlan {
                set enable_vlan $value
            }
            -count {
				set count $value
            }
            -src_mac {
			    if {[IsMacAddress $value]} {
				    set src_mac $value
				} else {
				    set src_mac [MacTrans $value]
				}
            }
            -src_mac_step {
				set src_mac_step $value
            }
            -vlan_id1 -
			-outer_vlan_id {
				set vlan_id1 $value
            }
            -vlan_id1_step -
			-outer_vlan_step {
				set vlan_id1_step $value
            }
            -vlan_pri1 {
                set vlan_pri1 $value
            }
            -vlan_id2 -
			-inner_vlan_id {
				set vlan_id2 $value
            }
            -vlan_id2_step -
			-inner_vlan_step {
				set vlan_id2_step $value
            }
            -vlan_pri2 {
                set vlan_pri2 $value
            }
            -ipaddr {
                if { [IsIPv4Address $value] } {
                    set ipv4_addr $value
                } else {
                    set ipv6_addr $value
                }
            }
            -ipaddr_step {
                if { [IsIPv4Address $value] } {
                    set ipv4_addr_step $value
                } else {
                    set ipv6_addr_step $value
                }
            }
            -ipv4_addr {
				set ipv4_addr $value
            }
            -ipv4_addr_step {
				set ipv4_addr_step $value
            }
			-ipv4_prefix_len -
			-ipv4_prefix_length	{
				set ipv4_prefix_len $value
			}
			-ipv4_gw {
				set ipv4_gw $value
			}
			-ipv4_gw_step {
				set ipv4_gw_step $value
			}
			-ipv6_addr {
				set ipv6_addr $value
			}
			-ipv6_addr_step {
				set ipv6_addr_step $value
			}
			-ipv6_prefix_len -
			-ipv6_prefix_length {
				set ipv6_prefix_len $value
			}
			-ipv6_gw {
				set ipv6_gw $value
			}
			-ipv6_gw_step {
				set ipv6_gw_step $value
			}
			-ip_version {
				set ip_version $value
			}
			-static {
				set static $value
			}
			-unconnected {
				set unconnected $value
			}
		}
    }	
	
	set pfxIncr 	[ GetStepPrefixlen $ipv4_addr_step ]
	if { [ info exists ipv4_gw_step ] } {
		set gwPfxIncr	[ GetStepPrefixlen $ipv4_gw_step ]
	}
    Deputs "pfxIncr:$pfxIncr"	
	if { [ info exists static] == 0 } {
		if { [ info exists ipv4_addr ] } {
			set static 0
		}
		if { [ info exists ipv6_addr ] } {
			set static 0
		}
	}

    set int ""
	if { $static } {
        set topoList [ixNet getL / topology]
        ## check topologies are already created
        if {[llength $topoList] != 0} {
            foreach topoObj $topoList {
                ## Checking for any topology same port is attached
                if {[ixNet getA $topoObj -vports] == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    if {[llength $deviceGroupList]== 0} {
                        set deviceGroupObj [ixNet add $topoObj deviceGroup]
                        ixNet commit
                        set deviceGroupObj [ixNet remapIds $deviceGroupObj]
                    } else {
                        set int [ixNet getL $deviceGroupList ethernet]
                        if {[llength $int] == 0} {
                            set int [ixNet add $deviceGroupList ethernet]
                            ixNet commit
                            set int [ixNet remapIds $int]
                        }
                    }
                }
            }
        }

        if {$int == ""} {
            set int [CreateProtoHandleFromRoot $hPort ethernet]
        }

        if {[info exists vlan_id1] && [info exists vlan_id2]} {
            set vlan_count 2
        } elseif {[info exists vlan_id1] || [info exists vlan_id2]} {
            set vlan_count 1
        } else {
            set vlan_count 0
        }
                
        if {[info exists vlan_count] && $vlan_count != 0} {
            ixNet setA $int -useVlans True
            ixNet setA $int -vlanCount $vlan_count
            ixNet commit
        }

		ixNet setA $int -description $this
        ixNet commit
        set int [ixNet remapIds $int]
            
        if { [lsearch $handle $int ] == -1 } {
            lappend handle $int
        }

        if {[info exists src_mac]} {
            ixNet setA [ixNet getA $int -mac]/singleValue -value $src_mac
            # ixNet setA $int -mac $src_mac
	 	    lappend intf_mac [ ixNet getA [ixNet getA $int -mac]/singleValue -value ]
            ixNet commit
        }

        if { [info exists vlan_id1 ] } {
            Deputs "Setting outer vlan for Host::config with vlan_id $vlan_id1"
            set outerVlanHandle [lindex [ixNet getL $int vlan] 0]
            ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -start $vlan_id1 -direction increment
            ixNet commit
            if {[info exists vlan_id1_step]} {
                ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -step $vlan_id1_step
                ixNet commit
            }
            if {[info exists vlan_pri1]} {
                ixNet setA [ixNet getA $outerVlanHandle -priority]/singleValue -value $vlan_pri1
            }
            ixNet commit
        }

        if { [info exists vlan_id2] } {
            Deputs "Setting inner vlan for Host::config with vlan_id $vlan_id2"
            set innerVlanHandle [lindex [ixNet getL $int vlan] end]
            ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -start $vlan_id2 -direction increment
            if {[info exists inner_vlan_step]} {
                ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -step $vlan_id2_step
            }
            if {[info exists vlan_pri2]} {
                ixNet setA [ixNet getA $innerVlanHandle -priority]/singleValue -value $vlan_pri2
            }
            ixNet commit
        }
	} else {
            for { set index 0 } { $index < $count } { incr index } {
                # set int ""
                set topoList [ixNet getL / topology]
                ## check topologies are already created
                if {[llength $topoList] != 0} {
                    foreach topoObj $topoList {
                        ## Checking for any topology same port is attached
                        if {[ixNet getA $topoObj -vports] == $hPort} {
                            set deviceGroupList [ixNet getL $topoObj deviceGroup]
                            if {[llength $deviceGroupList]== 0} {
                                set deviceGroupObj [ixNet add $topoObj deviceGroup]
                                ixNet commit
                                set deviceGroupObj [ixNet remapIds $deviceGroupObj]
                            } else {
                                set int [ixNet getL $deviceGroupList ethernet]
                                if {[llength $int] == 0} {
                                    set int [ixNet add $deviceGroupList ethernet]
                                    ixNet commit
                                    set int [ixNet remapIds $int]
                                }
                            }
                        }
                    }
                }
                if {$int == ""} {
                    set int [CreateProtoHandleFromRoot $hPort ethernet]
                }

                if {[info exists vlan_id1] && [info exists vlan_id2]} {
                    set vlan_count 2
                } elseif {[info exists vlan_id1] || [info exists vlan_id2]} {
                    set vlan_count 1
                } else {
                    set vlan_count 0
                }
                
                if {[info exists vlan_count] && $vlan_count != 0} {
                    ixNet setA $int -useVlans True
                    ixNet setA $int -vlanCount $vlan_count
                    ixNet commit
                }

                if { $unconnected } {
                    Deputs "unconncted:$unconnected"
                    Deputs "int:$int"		
                    ixNet setA $int -type routed
                }

			    ixNet setA $int -description $this
                ixNet commit
                set int [ixNet remapIds $int]
            
                if { [lsearch $handle $int ] == -1 } {
                    lappend handle $int
                }

                if {[info exists src_mac]} {
                    ixNet setA [ixNet getA $int -mac]/singleValue -value $src_mac
                    # ixNet setA $int -mac $src_mac
	 	            lappend intf_mac [ ixNet getA [ixNet getA $int -mac]/singleValue -value ]
                    ixNet commit
                }

			    if { [ info exists ipv4_addr ] } {
                    if { [ llength [ ixNet getList $int ipv4 ] ] == 0 } {
                        set ipv4Obj [ ixNet add $int ipv4 ]
                        ixNet commit
                    } else {
                        set ipv4Obj [ lindex [ ixNet getList $int ipv4 ] 0 ]
                    }
                    set ipv4Obj [ixNet remapIds $ipv4Obj]
                    ixNet setA [ixNet getA $ipv4Obj -address]/singleValue -value $ipv4_addr
                    if {[info exists ipv4_gw]} {
                        ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/singleValue -value $ipv4_gw
                    }
                    if {[info exists ipv4_prefix_len]} {
                        ixNet setA [ixNet getA $ipv4Obj -prefix]/singleValue -value $ipv4_prefix_len
                    }
                    ixNet commit
			    }

			    if { [ string tolower $ip_version ] != "ipv4" } {
				    if { [ llength [ ixNet getL $int ipv6 ] ] == 0 } {
					    set ipv6Obj [ixNet add $int ipv6]
					    ixNet commit
                        set ipv6Obj [ixNet remapIds $ipv6Obj]
				    } else {
                        set ipv6Obj [ixNet getL $int ipv6]
                    }

                    ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
                    if {[info exists ipv6_prefix_len]} {
                        ixNet setA [ixNet getA $ipv6Obj -prefix]/singleValue -value $ipv6_prefix_len
                    }
                    if {[info exists ipv6_gw]} {
                        ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/singleValue -value $ipv6_gw
                    }
                    ixNet commit
			    }
                Deputs "config mac"
			    if { [ info exists src_mac ] } {
				    ixNet setA [ixNet getA $int -mac]/singleValue -value $src_mac
				    ixNet commit
				    set src_mac [ IncrMacAddr $src_mac $src_mac_step ]
			    }

                if { [info exists vlan_id1 ] } {
                    Deputs "Setting outer vlan for Host::config with vlan_id $vlan_id1"
                    set outerVlanHandle [lindex [ixNet getL $int vlan] 0]
                    ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -start $vlan_id1 -direction increment
                    ixNet commit
                    if {[info exists vlan_id1_step]} {
                        ixNet setA [ixNet getA $outerVlanHandle -vlanId]/counter -step $vlan_id1_step
                        ixNet commit
                    }
                    if {[info exists vlan_pri1]} {
                        ixNet setA [ixNet getA $outerVlanHandle -priority]/singleValue -value $vlan_pri1
                    }
                    ixNet commit
                }

                if { [info exists vlan_id2] } {
                    Deputs "Setting inner vlan for Host::config with vlan_id $vlan_id2"
                    set innerVlanHandle [lindex [ixNet getL $int vlan] end]
                    ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -start $vlan_id2 -direction increment
                    if {[info exists inner_vlan_step]} {
                        ixNet setA [ixNet getA $innerVlanHandle -vlanId]/counter -step $vlan_id2_step
                    }
                    if {[info exists vlan_pri2]} {
                        ixNet setA [ixNet getA $innerVlanHandle -priority]/singleValue -value $vlan_pri2
                    }
                    ixNet commit
                }
			
                Deputs "enable interface"
	            if { [ info exists enabled ] } {
		            ixNet setA $int -enabled $enabled
		            ixNet commit			
	            }
	        }            	
	    }
	
        # $this configure -ipVersion $ip_version
	    Deputs "static $static"
	    return [ GetStandardReturnHeader ]
}


body Host::ping { args } {
    set tag "body Host::ping [info script]"
    Deputs "----- TAG: $tag -----"

	global errNumber

	set count 		1
	set interval 	1000
	set flag 		1

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -dst {
                if { [ IsIPv4Address $value ] } {
                    set dut_ip $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -count {
                if { [ string is integer $value ] } {
                    set count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -interval {
                if { [ string is integer $value ] } {
                    set interval    $value

                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -flag {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_arp $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            default {
                error "$errNumber(3) key:$key value:$value"
            }
        }
    }
    
	set pingTrue	0
	set pingFalse	0


Deputs Step10
	set pingResult [ list ]
	for { set index 0 } { $index < $count } { incr index } {
		
		foreach int $handle {
			lappend pingResult [ ixNet exec sendPing $int $dut_ip ]
		}
	
		after $interval
	}
	Deputs "The ping result is: $pingResult"
Deputs Step20
	set pingPass	0
	foreach result $pingResult {
		if { [ regexp {failed} $result ] } {
			incr pingFalse
			set pingPass 0
		} else {
			incr pingTrue
			set pingPass 1
		}
	}
	
# Deputs Step40
	# set loss [ expr $pingFalse / $count.00 * 100 ]
	
# Deputs Step50
	# if { $pingPass == $flag } {
		# set ret  [ GetStandardReturnHeader ]
	# } else {
		# set ret  [ GetErrorReturnHeader "Unexpected result $pingPass" ]
	# }
	
# Deputs Step60
	# lappend ret [ GetStandardReturnBody "loss" $loss ]
	
	return $pingPass

}




