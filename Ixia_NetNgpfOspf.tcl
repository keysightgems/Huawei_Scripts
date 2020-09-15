# Copyright (c) Ixia technologies 2020-2021, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
#       2. Update
# Version 1.1.4.34
#		3. Add reborn in Ospfv2Session.config Ospfv3Session.config

class OspfSession {
    inherit RouterNgpfEmulationObject
    
	public variable hNetworkRange
	public variable hNetworkGroup
    public variable OspfVersion
	public variable deviceHandle
    set devicehandle ""
    global devicehandle
    constructor { port { hOspfSession NULL } } {
		global errNumber
		
		set tag "body OspfvSession::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set portObj [ GetObject $port ]
		
		set handle ""
		set ospfRtHandle ""
        
		
	}
	
	method reborn {} {
		set tag "body OspfSession::reborn [info script]"
Deputs "----- TAG: $tag -----"
		
		if { [ catch {
			Deputs "portObj is: $portObj"
			set hPort   [ $portObj cget -handle ]
			Deputs "hPort is: $hPort"
		} ] } {
			error "$errNumber(1) Port Object in DhcpHost ctor"
		}
		set ospfV2Hndle [ixNet getA [ixNet getRoot]/globals/topology/ospfv2Router -enableDrBdr]
		set ospfV3Hndle [ixNet getA [ixNet getRoot]/globals/topology/ospfv3Router -enableDrBdr]
        set value2Obj [ixNet setA $ospfV2Hndle/singleValue -value True]
		set value3Obj [ixNet setA $ospfV3Hndle/singleValue -value True]
		ixNet commit

		set rb_interface [ ixNet getL $hPort interface ]
	    Deputs "rb_interface is: $rb_interface"
		array set interface [ list ]

	}
	
    method config { args } {}
	method set_topo { args } {}
	method unset_topo { args } {}
	method advertise_topo {} {}
	method withdraw_topo {} {}
	method flapping_topo { args } {}
	method enable {} {
        set tag "body OspfSession::enable [info script]"
Deputs "----- TAG: $tag -----"
        ixNet setA [ixNet getA $handle -active]/singleValue -value True
        ixNet commit
    }
	method disable {} {
        set tag "body OspfSession::disable [info script]"
Deputs "----- TAG: $tag -----"
        ixNet setA [ixNet getA $handle -active]/singleValue -value False
        ixNet commit
    }
	method get_status {} {}
	method get_stats {} {}
	method generate_interface { args } {
		set tag "body OspfSession::generate_interface [info script]"
Deputs "----- TAG: $tag -----"
Deputs "handle:$handle"		
		foreach int $rb_interface {
			if { [ ixNet getA $int -type ] == "routed" } {
				continue
				Deputs "inside:$int"	
			}
			set hInt [ ixNet add $handle interface ]
			ixNet setM $hInt -interfaces $int -enabled True -connectedToDut True
			
			ixNet commit
			set hInt [ ixNet remapIds $hInt ]
			set interface($int) $hInt	
			Deputs "hInt:$hInt"
			Deputs "interface($int):$interface($int)"
		}
	}	
}
body OspfSession::config { args } {
	
    global errorInfo
    global errNumber
	
	set area_id "0.0.0.0"
	set hello_interval 10
	set if_cost 1
	set network_type "native"
	set options "v6bit | rbit | ebit"
	set router_dead_interval 40
	
	set intf_num 1
	
    set tag "body OspfSession::config [info script]"

	
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -router_id {
				set router_id $value
			}
			-area_id {			
				set area_id $value
			}
			-hello_interval {
				set hello_interval $value
			}
			-if_cost {
				set if_cost $value
			}
			-network_type {
				set value [string toupper $value]
				set network_type $value
			}
			-options {
				set options $value
			}
		   
		    -router_dead_interval -
			-dead_interval {
				set dead_interval $value
			}
			-retransmit_interval {
				set retransmit_interval $value
			}
			-priority {
				set priority $value
			}
        }
    }
	
	if { $handle == "" } {
		reborn
	}
	ixNet setM $handle -enabled True
	
	if { [ info exists router_id ] } {
Deputs "router_id:$router_id"	
		ixNet setA $handle -localRouterID $router_id
		ixNet commit
		Deputs "router_idpost:$router_id"
	}	
	if { [ info exists area_id ] } {
	    
	    set id_hex [IP2Hex $area_id]
		set area_id [format %i 0x$id_hex]
		
		set valueObj [ ixNet getA $handle -areaId]
		set value [ixNet setA $valueObj/singleValue -value $area_id]
		ixNet commit
		
	}
	if { [ info exists hello_interval ] } {
		set valueObj [ ixNet getA $handle -helloInterval]
		set value [ixNet setA $valueObj/singleValue -value $hello_interval]
		ixNet commit
	}
	if { [ info exists if_cost ] } {
		set version [GetOspfNgpfRouterHandle $handle 1]
		if {$version == 2} {
		  ixNet setA [ixNet getA $handle -metric]/singleValue -value $if_cost
		ixNet commit
		} elseif {$version == 3} {
          ixNet setA [ixNet getA $handle -linkMetric]/singleValue -value $if_cost
		}
	}
	
	# v3 -interfaceType pointToPoint, -interfaceType broadcast
	# v2 -networkType pointToPoint, -networkType broadcast, -networkType pointToMultipoint
	if { [ info exists network_type ] } {
	
		switch $network_type {
		
			NATIVE {
				set network_type pointtomultipoint
			}
			BROADCAST {
				set network_type broadcast
			}
			P2P {
				set network_type pointtopoint
			}
		}

		ixNet setA [ixNet getA $handle -networkType]/singleValue -value $network_type
		ixNet commit
		
	}
	
	# v3 -routerOptions
	# v2 -options
	if { [ info exists options ] } {
		 foreach int $rb_interface {
			 
			 set options [split $options |]
			 
			 if {[string match *dcbit* $options]} {
				 set dcbit 1
			 } else {
				 set dcbit 0
			 }
			 if {[string match *rbit* $options]} {
				 set rbit 1
			 } else {
				 set rbit 0
			 }
			 if {[string match *nbit* $options]} {
				 set nbit 1
			 } else {
				 set nbit 0
			 }
			 if {[string match *mcbit* $options]} {
				 set mcbit 1
			 } else {
				 set mcbit 0
			 }
			 if {[string match *ebit* $options]} {
				 set ebit 1
			 } else {
				 set ebit 0
			 }
			 if {[string match *v6bit* $options]} {
				 set v6bit 1
			 } else {
				 set v6bit 0
			 }
			 set opt_val "00$dcbit$rbit$nbit$mcbit$ebit$v6bit"
			 set opt_val [BinToDec $opt_val]
#			 set opt_val [Int2Hex $opt_val]		
			 ixNet setA $interface($int) -routerOptions $opt_val
			 ixNet commit
		 }
	}
	
	if { [ info exists dead_interval ] } {
		ixNet setA [ixNet getA $handle -deadInterval]/singleValue -value $dead_interval
		ixNet commit
	}
	
	# v3 
	# v2 -lsaRetransmitTime
	if { [ info exists retransmit_interval ] } {
		set ospfRtHandle [GetOspfNgpfRouterHandle $handle]
		Deputs "ospfRtHandle:$ospfRtHandle"
		ixNet setA [ixNet getA $ospfRtHandle -lsaRetransmitTime]/singleValue -value $retransmit_interval
		ixNet commit
	}
	if { [ info exists priority ] } {
	    ixNet setA [ixNet getA $handle -priority]/singleValue -value $priority
		ixNet commit
	}
    return [GetStandardReturnHeader]
	
}
body OspfSession::advertise_topo {} {

	set tag "body OspfSession::advertise_topo [info script]"
Deputs "----- TAG: $tag -----"
    set deviceGroupObj [$this cget -deviceHandle]
	foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
	    ixNet setA [ixNet getA $route -enabled]/singleValue -value True
	}

    ixNet commit
    return [GetStandardReturnHeader]
}
body OspfSession::withdraw_topo {} {

	set tag "body OspfSession::withdraw_topo [info script]"
Deputs "----- TAG: $tag -----"
    set deviceGroupObj [$this cget -deviceHandle]
    foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
	
		ixNet setA [ixNet getA $route -enabled]/singleValue -value False
	}

	ixNet commit
    return [GetStandardReturnHeader]
}
body OspfSession::flapping_topo { args } {

	set tag "body OspfSession::flapping_topo [info script]"
Deputs "----- TAG: $tag -----"


    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
		
			-times {
				set times $value
			}
			-interval {
				set interval $value
			}
		}
	}
	set deviceGroupObj [$this cget -deviceHandle]
	for { set index 0 } { $index < $times } { incr index } {
		foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
		    ixNet setA [ixNet getA $route -enabled]/singleValue -value True
		}
		ixNet commit
		
		after [ expr $interval * 1000 ]
		
		foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
			ixNet setA [ixNet getA $route -enabled]/singleValue -value False
		}
		ixNet commit
		
	}
	
	ixNet commit
    return [GetStandardReturnHeader]
}
body OspfSession::set_topo {args} {
	
	set tag "body OspfSession::set_topo [info script]"
Deputs "----- TAG: $tag -----"
    set deviceGroupObj [$this cget -deviceHandle]
	set hRouter $handle
	set hNetworkGroup [ixNet add $deviceGroupObj networkGroup]
	ixNet commit
    set hNetworkRange [ixNet add $hNetworkGroup networkTopology]
    ixNet commit
    set hNetworkRange [ ixNet remapIds $hNetworkRange ]
    set hNetworkGroup [ ixNet remapIds $hNetworkGroup ]
    #Available options are netTopologyCustom netTopologyFatTree netTopologyGrid netTopologyHubNSpoke netTopologyLinear netTopologyMesh netTopologyRing netTopologyTree
    set linearTopology [ixNet add $hNetworkRange netTopologyLinear]
    ixNet commit

	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-topo {
				set topo $value
			}
		}
	}
	# Need clarification on topo argument value
	if { [ info exists topo ] } {
		
		if { $topo == "" || [ $topo isa Topology ] == 0 } {
			return [GetErrorReturnHeader "No valid object found...-topo $topo"]
		}
		
		set type [$topo cget -type]
		set sim_rtr_num [$topo cget -sim_rtr_num]
		set row_num [$topo cget -row_num]
		set column_num [$topo cget -column_num]
		set attach_row [$topo cget -attach_row]
		set attach_column [$topo cget -attach_column]
		
		ixNet setM $hNetworkRange \
			-numRows $row_num \
			-numCols $column_num \
			-entryRow $attach_row \
			-entryColumn $attach_column
		
	} else {
		return [GetErrorReturnHeader "Madatory parameter needed...-topo"]
	}
	ixNet commit
	
	return [GetStandardReturnHeader]
}
body OspfSession::unset_topo {} {
	
	set tag "body OspfSession::unset_topo [info script]"
Deputs "----- TAG: $tag -----"
    ixNet remove $hNetworkGroup networkGroup
	ixNet commit
}

class Ospfv2Session {
	inherit OspfSession
    constructor { port { hOspfSession NULL } } { chain $port $hOspfSession } {
		set tag "body Ospfv2Session::ctor [info script]"
        Deputs "----- TAG: $tag -----"

        if { [ catch {
            set hPort   [ $portObj cget -handle ]
        } ] } {
            error "$errNumber(1) Port Object in OspfSession ctor"
        }

        if { $hOspfSession == "NULL" } {
            set hOspfSession [GetObjNameFromString $this "NULL"]
        }
        Deputs "----- hOspfSession: $hOspfSession, hPort: $hPort, portObj is: $portObj, port is: $port -----"
        if { $hOspfSession != "NULL" } {
			
            set handle [GetValidHandleObj "ospfv2" $hOspfSession $hPort]
            Deputs "----- ospfhandle: $handle -----"
            if { $handle != "" } {
                set handleName [ ixNet getA $handle -name ] 
				Deputs "----- ospfhandle2: $handleName -----"
            }
            
            
        } else {
            set handleName $this
            set handle ""
            reborn
        }
        
    }
	
	method reborn {} {
		set tag "body Ospfv2Session::reborn [info script]"
Deputs "----- TAG: $tag -----"

		chain
        set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
		ixNet commit
        set deviceGroupObj [ixNet add $topoObj deviceGroup]
		ixNet commit
		set deviceGroupObj [ ixNet remapIds $deviceGroupObj ]
		ixNet setA $deviceGroupObj -multiplier 1
        ixNet commit
        set ethObj [ixNet add $deviceGroupObj ethernet]
		ixNet commit
        set ipv4Obj [ixNet add $ethObj ipv4]
		ixNet commit
        set ospfObj [ixNet add $ipv4Obj ospfv2]
        ixNet commit
		set ospfRtHandle [ ixNet getL $deviceGroupObj ospfv2Router ]
		ixNet setA [ ixNet getA $ospfRtHandle -active]/singleValue -value True
		ixNet commit
		set handle [ ixNet remapIds $ospfObj ]
		ixNet setA $handle -name $this
        Deputs "handleospf:$handle"
		set protocol ospf
		$this configure -deviceHandle $deviceGroupObj
	}

	method config { args } {}
	method get_status {} {}
	method get_stats {} {}
}

body Ospfv2Session::get_status {} {

	set tag "body OspfSession::get_status [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
    Deputs "root $root"
	set protocol "OSPFv2-RTR"
	#set view [CreateProtocolView $protocol]
	puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	set view [CreateProtocolView $protocol]
	ixNet execute refresh $view
    set captionList             [ ixNet getA $view/page -columnCaptions ]
	#set captionList1             [ ixNet exec getColumnValues $view/page -enabledStatsSelectorColumns ]
	Deputs "captions:$captionList"
	#Deputs "captions1:$captionList1"
    set name_index        		[ lsearch -exact $captionList {Port} ]
	set down_index 				[ lsearch -exact $captionList {Down State Count} ]
    set attempt_index      		[ lsearch -exact $captionList {Attempted State Count} ]
	set init_index 				[ lsearch -exact $captionList {Init State Count} ]
	set twoway_index 			[ lsearch -exact $captionList {Twoway State Count} ]
	set exstart_index			[ lsearch -exact $captionList {ExStart State Count} ]
	set exchange_index			[ lsearch -exact $captionList {Exchange State Count} ]
	set loading_index			[ lsearch -exact $captionList {Loading State Count} ]
	set full_index				[ lsearch -exact $captionList {Full State Count} ]

	set stats [ ixNet getA $view/page -rowValues ]
    set portFound 0
    foreach row $stats {
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		set portName [ ixNet getA $hPort -name ]
			if { [ regexp $portName $rowPortName ] } {
				set portFound 1
				break
        }
    }


	set status "down"

	# down��attempt��init��two_ways��exstart��exchange��loading��full
    if { $portFound } {
	    Deputs "inside"
		set down    	[ lindex $row $down_index ]
		set attempt    	[ lindex $row $attempt_index ]
		set init    	[ lindex $row $init_index ]
		set twoways    	[ lindex $row $twoway_index ]
		set exstart     [ lindex $row $exstart_index ]
		set exchange    [ lindex $row $exchange_index ]
		set loading     [ lindex $row $loading_index ]
		set full    	[ lindex $row $full_index ]
		if { $down } {
			Deputs "insided"
			set status "down"
		}
		if { $attempt } {
			Deputs "insidea"
			set status "attempt"
		}
		if { $init } {
			Deputs "insidei"
			set status "init"
		}
		if { $twoways } {
			Deputs "insidet"
			set status "two_ways"
		}
		if { $exstart } {
			Deputs "insideee"
			set status "exstart"
		}
		if { $exchange } {
			Deputs "insideeee"
			set status "exchange"
		}
		if { $loading } {
			Deputs "insidel"
			set status "loading"
		}
		if { $full } {
			Deputs "insidef"
			set status "full"
		}

	}
	Deputs "status:$status"

    set ret [ GetStandardReturnHeader ]
	Deputs "ret :$ret"
    set ret $ret[ GetStandardReturnBody "status" $status ]
	Deputs "ret1 :$ret"
	return $ret

}

body Ospfv2Session::get_stats {} {
	set tag "body OspfSession::get_status [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
    Deputs "root $root"
    puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	set protocol "OSPFv2-RTR"
	set view [CreateProtocolView $protocol]
	set captionList             [ ixNet getA $view/page -columnCaptions ]
	#set captionList1             [ ixNet exec getColumnValues $view/page -enabledStatsSelectorColumns ]
	Deputs "captions:$captionList"

    set name_index        		[ lsearch -exact $captionList {Port} ]
    set rx_ack_index          	[ lsearch -exact $captionList {LS Ack Rx} ]
    set tx_ack_index          	[ lsearch -exact $captionList {LS Ack Tx} ]
	set rx_dd_index				[ lsearch -exact $captionList {DBD Rx} ]
	set tx_dd_index				[ lsearch -exact $captionList {DBD Tx} ]
	set rx_hello_index			[ lsearch -exact $captionList {Hellos Rx} ]
	set tx_hello_index			[ lsearch -exact $captionList {Hellos Tx} ]
	set rx_network_lsa_index	[ lsearch -exact $captionList {Network LSA Rx} ]
	set tx_network_lsa_index	[ lsearch -exact $captionList {Network LSA Tx} ]
	set rx_nssa_lsa_index		[ lsearch -exact $captionList {NSSA LSA Rx} ]
	set tx_nssa_lsa_index		[ lsearch -exact $captionList {NSSA LSA Tx	} ]
	set rx_request_index		[ lsearch -exact $captionList {LS Request Rx} ]
	set tx_request_index		[ lsearch -exact $captionList {LS Request Tx} ]
	set rx_router_lsa_index		[ lsearch -exact $captionList {Router LSA Rx} ]
	set tx_router_lsa_index		[ lsearch -exact $captionList {Router LSA Tx} ]
	set rx_summary_lsa_index	[ lsearch -exact $captionList {Summary IP LSA Rx} ]
	set tx_summary_lsa_index	[ lsearch -exact $captionList {Summary IP LSA Tx} ]
	set rx_as_external_lsa_index 	[ lsearch -exact $captionList {External LSA Rx} ]
	set tx_as_external_lsa_index 	[ lsearch -exact $captionList {External LSA Tx} ]
    set rx_asbr_summary_lsa_index 	[ lsearch -exact $captionList  {Link State Advertisement Rx}  ]
    set tx_asbr_summary_lsa_index 	[ lsearch -exact $captionList  {LinkState Advertisement Tx}  ]
    set rx_update_index	 		[ lsearch -exact $captionList  {LS Update Rx}  ]
    set tx_update_index	 		[ lsearch -exact $captionList  {LS Update Tx}  ]

	set stats [ ixNet getA $view/page -rowValues ]
    set portFound 0
    foreach row $stats {
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		set portName [ ixNet getA $hPort -name ]
        if { [ regexp $portName $rowPortName ] } {
            set portFound 1
            break
        }
    }
    set ret "Status : true\nLog : \n"

    if { $portFound } {
        set statsItem   "rx_ack"
		set statsVal    [ lindex $row $rx_ack_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_ack"
		set statsVal    [ lindex $row $tx_ack_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_dd"
		set statsVal    [ lindex $row $rx_dd_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_dd"
		set statsVal    [ lindex $row $tx_dd_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_hello"
		set statsVal    [ lindex $row $rx_hello_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_hello"
		set statsVal    [ lindex $row $tx_hello_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_network_lsa"
		set statsVal    [ lindex $row $rx_network_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_network_lsa"
		set statsVal    [ lindex $row $tx_network_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_nssa_lsa"
		set statsVal    [ lindex $row $rx_nssa_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_nssa_lsa"
		set statsVal    [ lindex $row $tx_nssa_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_request"
		set statsVal    [ lindex $row $rx_request_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_request"
		set statsVal    [ lindex $row $tx_request_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_router_lsa"
		set statsVal    [ lindex $row $rx_router_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_router_lsa"
		set statsVal    [ lindex $row $tx_router_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_summary_lsa"
		set statsVal    [ lindex $row $rx_summary_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_summary_lsa"
		set statsVal    [ lindex $row $tx_summary_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_as_external_lsa"
		set statsVal    [ lindex $row $rx_as_external_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_as_external_lsa"
		set statsVal    [ lindex $row $tx_as_external_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_asbr_summary_lsa"
		set statsVal    [ lindex $row $rx_asbr_summary_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_asbr_summary_lsa"
		set statsVal    [ lindex $row $tx_asbr_summary_lsa_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_update"
		set statsVal    [ lindex $row $rx_update_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_update"
		set statsVal    [ lindex $row $tx_update_index ]
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_te_lsa"
		set statsVal    "NA"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_te_lsa"
		set statsVal    "NA"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]


    }

Deputs "ret:$ret"

    return $ret
}

body Ospfv2Session::config { args } {
	global errorInfo
	global errNumber
	
	set ipv4_prefix_len 24
	set ipv4_gw 1.1.1.1
	set loopback_ipv4_gw 1.1.1.1
	set ipv4_addr_step	0.0.0.1
	set outer_vlan_step	1
	set inner_vlan_step	1
	set outer_vlan_num 1
	set inner_vlan_num 1
	set outer_vlan_priority 0
	set inner_vlan_priority 0

	set count 		1
	set enabled 		True
	
	set tag "body Ospfv2Session::config [info script]"
Deputs "----- TAG: $tag -----"
		
Deputs "Args:$args "
	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_prefix_len {
				if { [ string is integer $value ] && $value <= 32 } {
					set ipv4_prefix_len $value					
				} else {
					error "$errNumber(1) key:$key value:$value"					
				}				
			}
			-ipv4_gw {
				set ipv4_gw $value
			}
			-outer_vlan_id {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set outer_vlan_id $value
					set flagOuterVlan   1					
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
			-outer_vlan_cfi {
				set outer_vlan_cfi $value				
			}
			-inner_vlan_cfi {
				set inner_vlan_cfi $value				
			}
			-loopback_ipv4_addr {
				set loopback_ipv4_addr $value
			}
			-loopback_ipv4_gw {
				set loopback_ipv4_gw $value
			}
		}
	}
	if { $handle == "" } {
		Deputs "beforereborn:$handle"
		reborn
		Deputs "afterreborn:$handle"
	}
	set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObj [ixNet getL $topoObj deviceGroup]
			foreach devObj $deviceGroupObj {
            set ethernetObj [ixNet getL $devObj ethernet]
			if { [ info exists ipv4_addr ] } {
                Deputs "ipv4: [ixNet getL $ethernetObj ipv4]"
                set ipv4Obj [ixNet getL $ethernetObj ipv4]
                ixNet setA [ixNet getA $ipv4Obj -address]/singleValue -value $ipv4_addr
				ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/singleValue -value $ipv4_gw
				ixNet setA [ixNet getA $ipv4Obj -prefix]/singleValue -value $ipv4_prefix_len
				ixNet commit
				
				generate_interface	
			}
			
			
			if {[ info exists outer_vlan_id ]} {
					for { set index 0 } { $index < $count } { incr index } {

						if { [ info exists outer_vlan_id ] } {
							set vlanId $outer_vlan_id
							ixNet setA $ethernetObj -vlanCount 1
							ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
                            set oVlanObj [lindex [ixNet getL $ethernetObj vlan] 0]
							ixNet setA [ixNet getA $oVlanObj -vlanId]/singleValue -value $vlanId
							ixNet setA [ixNet getA $oVlanObj -priority]/singleValue -value $outer_vlan_priority
						ixNet commit
						incr outer_vlan_id $outer_vlan_step

						}
						if { [ info exists inner_vlan_id ] } {
							set vlanId $inner_vlan_id
							set innerPri $inner_vlan_priority
							ixNet setA $ethernetObj -vlanCount 2
							ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
							ixNet commit
                            set iVlanObj [lindex [ixNet getL $ethernetObj vlan] 1]
							Deputs "iVlanObj: $iVlanObj"
							ixNet setA [ixNet getA $iVlanObj -vlanId]/singleValue -value $vlanId
							ixNet setA [ixNet getA $iVlanObj -priority]/singleValue -value $innerPri
						ixNet commit

							incr inner_vlan_id $inner_vlan_step

						}

						if { [ info exists enabled ] } {
							ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
							ixNet commit

						}

					}
			}

	        if { [ info exists loopback_ipv4_addr ] } {
                Deputs "loopback_ipv4_addr is not implemented "
                catch { Host $this.loopback $portObj }
                $this.loopback config \
                    -ipv4_addr $loopback_ipv4_addr \
                    -unconnected 1 \
                    -ipv4_prefix_len 32 \
                    -ipv4_gw $loopback_ipv4_gw
                set loopbackInt [ $this.loopback cget -handle ]
                Deputs "loopback int:$loopbackInt"
                set viaInt [ lindex $rb_interface end ]
                Deputs "via interface:$viaInt"
                ixNet setA $loopbackInt/unconnected \
                    -connectedVia $viaInt
                ixNet commit
                set hInt [ ixNet add $handle interface ]
                ixNet setM $hInt \
                    -interfaceIpAddress $loopback_ipv4_addr \
                    -interfaceIpMaskAddress 255.255.255.255 \
                    -enabled True \
                    -connectedToDut False \
                    -linkTypes stub

                ixNet commit
                set interface($loopbackInt) $hInt
            }
	}
	}
	}
	ixNet commit
	eval chain $args
	return [GetStandardReturnHeader]
	
}

class Ospfv3Session {
	inherit OspfSession
	
    constructor { port { hOspfSession NULL } } { chain $port $hOspfSession } {
		set tag "body Ospfv3Session::ctor [info script]"
Deputs "----- TAG: $tag -----"
       if { [ catch {
            set hPort   [ $portObj cget -handle ]
        } ] } {
            error "$errNumber(1) Port Object in OspfSession ctor"
        }
        if { $hOspfSession == "NULL" } {
            set hOspfSession [GetObjNameFromString $this "NULL"]
        }
        Deputs "----- hOspfSession: $hOspfSession, hPort: $hPort -----"
        if { $hOspfSession != "NULL" } {
            set handle [GetValidHandleObj "ospfv3" $hOspfSession $hPort]
            Deputs "----- handle: $handle -----"
            if { $handle != "" } {
                set handleName [ ixNet getA $handle -name ] 
            } 
			# else {
               # error "$errNumber(5) handle:$hOspfSession"
            # }
            
            
        } else {
            set handleName $this
            set handle ""
            reborn
        }
	    

    }
	
	method reborn {} {
		set tag "body Ospfv3Session::reborn [info script]"
Deputs "----- TAG: $tag -----"
		chain
		#set topoObjList [ixNet getL [ixNet getRoot] topology]

        set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
        set deviceGroupObj [ixNet add $topoObj deviceGroup]
        set deviceGroupObj [ ixNet remapIds $deviceGroupObj ]
		ixNet setA $deviceGroupObj -multiplier 1
        ixNet commit
        set ethObj [ixNet add $deviceGroupObj ethernet]
		ixNet commit
        set ipv6Obj [ixNet add $ethObj ipv6]
		ixNet commit
        set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
        ixNet commit

        set ospfRtHandle [ ixNet getL $deviceGroupObj ospfv3Router ]
        ixNet setA [ ixNet getA $ospfRtHandle -active]/singleValue -value True
		ixNet commit
		set handle [ ixNet remapIds $ospfv3Obj ]
		ixNet setA $handle -name $this
		$this configure -deviceHandle $deviceGroupObj
        Deputs "handlev3ospf:$handle"
		set protocol ospfV3
 		generate_interface	
	}
	
	method config { agrs } {}
	method get_status {} {}
	method get_stats {} {}
}

body Ospfv3Session::get_status {} {

	set tag "body Ospfv3Session::get_status [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
Deputs "root $root"
	set protocol "OSPFv3-RTR"
	#set view [CreateProtocolView $protocol]
	puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	set view [CreateProtocolView $protocol]
    set captionList         [ ixNet getA $view/page -columnCaptions ]
	Deputs "caption:$captionList"
    set name_index        		[ lsearch -exact $captionList {Port} ]
	set down_index 				[ lsearch -exact $captionList {Neighbors Down Count} ]
    set attempt_index      		[ lsearch -exact $captionList {Neighbors Attempt Count} ]
	set init_index 				[ lsearch -exact $captionList {Init Count} ]
	set twoway_index 			[ lsearch -exact $captionList {Neighbors Two Way Count} ]
	set exstart_index			[ lsearch -exact $captionList {Neighbors ExStart Count} ]
	set exchange_index			[ lsearch -exact $captionList {Neighbors Exchange Count} ]
	set loading_index			[ lsearch -exact $captionList {Neighbors Loading Count} ]
	set full_index				[ lsearch -exact $captionList {Neighbors Full Count} ]

	set stats [ ixNet getA $view/page -rowValues ]
	 Deputs "stats : $stats"
    set portFound 0
    foreach row $stats {
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		set portName [ ixNet getA $hPort -name ]
			if { [ regexp $portName $rowPortName ] } {
				set portFound 1
				break
        }
    }

   Deputs "down_index:$down_index"
   Deputs "attempt_index:$attempt_index"
   Deputs "init_index:$init_index"
   Deputs "twoway_index:$twoway_index"
   Deputs "exstart_index:$exstart_index"
   Deputs "loading_index:$loading_index"
	set status "down"

	# down��attempt��init��two_ways��exstart��exchange��loading��full
    if { $portFound } {
		set down    	[ lindex $row $down_index ]
		set attempt    	[ lindex $row $attempt_index ]
		set init    	[ lindex $row $init_index ]
		set twoway    	[ lindex $row $twoway_index ]
		set exstart     [ lindex $row $exstart_index ]
		set exchange    [ lindex $row $exchange_index ]
		set loading     [ lindex $row $loading_index ]
		set full    	[ lindex $row $full_index ]
		if { $down } {
			set status "down"
		}
		if { $attempt } {
			set status "attempt"
		}
		if { $init } {
			set status "init"
		}
		if { $twoway } {
			set status "two_ways"
		}
		if { $exstart } {
			set status "exstart"
		}
		if { $exchange } {
			set status "exchange"
		}
		if { $loading } {
			set status "loading"
		}
		if { $full } {
			set status "full"
		}

	}

    set ret [ GetStandardReturnHeader ]
    set ret $ret[ GetStandardReturnBody "status" $status ]
	return $ret

}

body Ospfv3Session::get_stats {} {
	set tag "body Ospfv3Session::get_status [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
Deputs "root $root"
    puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	set protocol "OSPFv3-RTR"
	set view [CreateProtocolView $protocol]
    set captionList         [ ixNet getA $view/page -columnCaptions ]

    set name_index        		[ lsearch -exact $captionList {Stat Name} ]
    set rx_ack_index          	[ lsearch -exact $captionList {LS Ack Rx} ]
    set tx_ack_index          	[ lsearch -exact $captionList {LS Ack Tx} ]
	set rx_dd_index				[ lsearch -exact $captionList {DBD Rx} ]
	set tx_dd_index				[ lsearch -exact $captionList {DBD Tx} ]
	set rx_hello_index			[ lsearch -exact $captionList {Hellos Rx} ]
	set tx_hello_index			[ lsearch -exact $captionList {Hellos Tx} ]
	set rx_network_lsa_index	[ lsearch -exact $captionList {NetworkLSA Rx} ]
	set tx_network_lsa_index	[ lsearch -exact $captionList {NetworkLSA Tx} ]
	set rx_nssa_lsa_index		[ lsearch -exact $captionList {NSSALSA Rx} ]
	set tx_nssa_lsa_index		[ lsearch -exact $captionList {NSSALSA Tx} ]
	set rx_request_index		[ lsearch -exact $captionList {LS Request Rx} ]
	set tx_request_index		[ lsearch -exact $captionList {LS Request Tx} ]
	set rx_router_lsa_index		[ lsearch -exact $captionList {RouterLSA Rx} ]
	set tx_router_lsa_index		[ lsearch -exact $captionList {RouterLSA Tx} ]
	set rx_as_external_lsa_index 	[ lsearch -exact $captionList {ExternalLSA Rx} ]
	set tx_as_external_lsa_index 	[ lsearch -exact $captionList {ExternalLSA Tx} ]
	set rx_update_index	 		[ lsearch -exact $captionList  {LS Update Rx}  ]
	set tx_update_index	 		[ lsearch -exact $captionList  {LS Update Tx}  ]

    set rx_inter_area_prefix_lsa_index 	[ lsearch -exact $captionList  {InterareaPrefixLSA Rx}  ]
    set tx_inter_area_prefix_lsa_index 	[ lsearch -exact $captionList  {InterareaPrefixLSA Tx}  ]
	set rx_inter_area_router_lsa_index	[ lsearch -exact $captionList {InterareaRouterLSA Rx} ]
	set tx_inter_area_router_lsa_index	[ lsearch -exact $captionList {InterareaRouterLSA Tx} ]
	set rx_intra_area_prefix_lsa_index	[ lsearch -exact $captionList {IntraareaPrefixLSA Rx} ]
	set tx_intra_area_prefix_lsa_index	[ lsearch -exact $captionList {InterareaPrefixLSA Tx} ]
	set rx_link_lsa_index	[ lsearch -exact $captionList {LinkLSA Rx} ]
	set tx_link_lsa_index	[ lsearch -exact $captionList {LinkLSA Tx} ]


	set stats [ ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"
    set portFound 0
    foreach row $stats {
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		set portName [ ixNet getA $hPort -name ]
        if { [ regexp $portName $rowPortName ] } {
            set portFound 1
            break
        }
    }
    set ret "Status : true\nLog : \n"

    if { $portFound } {
	    set statsItem   "rx_ack"
		set statsVal    [ lindex $row $rx_ack_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_ack"
		set statsVal    [ lindex $row $tx_ack_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_dd"
		set statsVal    [ lindex $row $rx_dd_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_dd"
		set statsVal    [ lindex $row $tx_dd_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_hello"
		set statsVal    [ lindex $row $rx_hello_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_hello"
		set statsVal    [ lindex $row $tx_hello_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_network_lsa"
		set statsVal    [ lindex $row $rx_network_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_network_lsa"
		set statsVal    [ lindex $row $tx_network_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_nssa_lsa"
		set statsVal    [ lindex $row $rx_nssa_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_nssa_lsa"
		set statsVal    [ lindex $row $tx_nssa_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_request"
		set statsVal    [ lindex $row $rx_request_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_request"
		set statsVal    [ lindex $row $tx_request_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_router_lsa"
		set statsVal    [ lindex $row $rx_router_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_router_lsa"
		set statsVal    [ lindex $row $tx_router_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_as_external_lsa"
		set statsVal    [ lindex $row $rx_as_external_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_as_external_lsa"
		set statsVal    [ lindex $row $tx_as_external_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_update"
		set statsVal    [ lindex $row $rx_update_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_update"
		set statsVal    [ lindex $row $tx_update_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_inter_area_prefix_lsa"
	    set statsVal    [ lindex $row $rx_inter_area_prefix_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_inter_area_prefix_lsa"
	    set statsVal    [ lindex $row $tx_inter_area_prefix_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_inter_area_router_lsa"
	    set statsVal    [ lindex $row $rx_inter_area_router_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_inter_area_router_lsa"
	    set statsVal    [ lindex $row $tx_inter_area_router_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_intra_area_prefix_lsa"
	    set statsVal    [ lindex $row $rx_intra_area_prefix_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_intra_area_prefix_lsa"
	    set statsVal    [ lindex $row $tx_intra_area_prefix_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "rx_link_lsa"
	    set statsVal    [ lindex $row $rx_link_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	    set statsItem   "tx_link_lsa"
	    set statsVal    [ lindex $row $tx_link_lsa_index ]
        Deputs "stats val:$statsVal"
	    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
    }
    Deputs "ret:$ret"
    return $ret
}

body Ospfv3Session::config { args } {
	global errorInfo
	global errNumber
	
	set ipv6_addr 3ffe:3210::2
	set ipv6_prefix_len 64
	set ipv6_gw 3ffe:3210::1
	
	set ipv6_addr_step	::1
	set outer_vlan_step	1
	set inner_vlan_step	1
	set outer_vlan_num 1
	set inner_vlan_num 1
	set outer_vlan_priority 0
	set inner_vlan_priority 0

	set count 		1
	set enabled 		True
	
	set tag "body Ospfv3Session::config [info script]"
Deputs "----- TAG: $tag -----"
	
Deputs "Args:$args "
	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-ipv6_addr {
				set ipv6_addr $value
			}
			-ipv6_prefix_len {
				if { [ string is integer $value ] && $value <= 128 } {
					set ipv6_prefix_len $value					
				} else {
					error "$errNumber(1) key:$key value:$value"					
				}				
			}
			-ipv6_gw {
				set ipv6_gw $value
			}
			-outer_vlan_id {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set outer_vlan_id $value
					set flagOuterVlan   1					
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
			-outer_vlan_cfi {
				set outer_vlan_cfi $value				
			}
			-inner_vlan_cfi {
				set inner_vlan_cfi $value				
			}
		}
	}

	set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObj [ixNet getL $topoObj deviceGroup]
            set ethernetObj [ixNet getL $deviceGroupObj ethernet]
            set ipv6Obj [ixNet getL $ethernetObj ipv6]
            if { [llength $ipv6Obj] == 0 } {
                set ipv6Obj [ixNet add $ethernetObj ipv6]
                ixNet commit
                set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
                ixNet commit

                set ospfRtHandle [ ixNet getL $deviceGroupObj ospfv3Router ]
                ixNet setA [ ixNet getA $ospfRtHandle -active]/singleValue -value True
                ixNet commit
                set handle [ ixNet remapIds $ospfv3Obj ]
                ixNet setA $handle -name $this
                Deputs "handlev3ospf:$handle"
                set protocol ospfV3
            }

			if { [ info exists ipv6_addr ] } {
                Deputs "ipv6: [ixNet getL $ethernetObj ipv6]"
                #set ipv6Obj [ixNet getL $ethernetObj ipv6]
                ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
				ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/singleValue -value $ipv6_gw
				ixNet setA [ixNet getA $ipv6Obj -prefix]/singleValue -value $ipv6_prefix_len
				ixNet commit
				
				generate_interface	
			}
			if {[ info exists outer_vlan_id ]} {
                for { set index 0 } { $index < $count } { incr index } {

                    if { [ info exists outer_vlan_id ] } {
                        set vlanId $outer_vlan_id
                        ixNet setA $ethernetObj -vlanCount 1
                        ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
                        set oVlanObj [lindex [ixNet getL $ethernetObj vlan] 0]
                        ixNet setA [ixNet getA $oVlanObj -vlanId]/singleValue -value $vlanId
                        ixNet setA [ixNet getA $oVlanObj -priority]/singleValue -value $outer_vlan_priority
                    ixNet commit
                    incr outer_vlan_id $outer_vlan_step

                    }
                    if { [ info exists inner_vlan_id ] } {
                        set vlanId $inner_vlan_id
                        set innerPri $inner_vlan_priority

                        ixNet setA $ethernetObj -vlanCount 2
                        ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
                        ixNet commit
                        set iVlanObj [lindex [ixNet getL $ethernetObj vlan] 1]
                        Deputs "iVlanObj: $iVlanObj"
                        ixNet setA [ixNet getA $iVlanObj -vlanId]/singleValue -value $vlanId
                        ixNet setA [ixNet getA $iVlanObj -priority]/singleValue -value $innerPri
                        ixNet commit
                        incr inner_vlan_id $inner_vlan_step
                    }

                    if { [ info exists enabled ] } {
                        ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
                        ixNet commit

                    }

                }
			}
	        if { [ info exists loopback_ipv6_addr ] } {
                Deputs "loopback_ipv6_addr is not implemented "
                catch { Host $this.loopback $portObj }
                $this.loopback config \
                    -ipv4_addr $loopback_ipv4_addr \
                    -unconnected 1 \
                    -ipv4_prefix_len 32 \
                    -ipv4_gw $loopback_ipv4_gw
                set loopbackInt [ $this.loopback cget -handle ]
                Deputs "loopback int:$loopbackInt"
                set viaInt [ lindex $rb_interface end ]
                Deputs "via interface:$viaInt"
                ixNet setA $loopbackInt/unconnected \
                    -connectedVia $viaInt
                ixNet commit
                set hInt [ ixNet add $handle interface ]
                ixNet setM $hInt \
                    -interfaceIpAddress $loopback_ipv4_addr \
                    -interfaceIpMaskAddress 255.255.255.255 \
                    -enabled True \
                    -connectedToDut False \
                    -linkTypes stub

                ixNet commit
                set interface($loopbackInt) $hInt
	        }
	}
	}
	ixNet commit
	eval chain $args
	return [GetStandardReturnHeader]
	
}

class SimulatedSummaryRoute {
	inherit EmulationNgpfObject
	
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj
    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		set handle ""
		reborn
		# set trafficObj $handle
	}
	
	method reborn {} {
		set tag "body SimulatedSummaryRoute::reborn [info script]"
Deputs "----- TAG: $tag -----"
        #set deviceGroupObj [$this cget -deviceHandle]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }
		set portObj [ $routerObj cget -portObj ]
		set hPort [ $routerObj cget -hPort ]
Deputs "portObj:$portObj"
Deputs "hPort:$hPort"
	}
	method config { args } {}
	
}
body SimulatedSummaryRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedSummaryRoute::config [info script]"
Deputs "----- TAG: $tag -----"

	if { $handle == "" } {
		reborn
	}
#param collection
   
Deputs "Args:$args "

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {            
            -age {
				set age $value
            }            
			-checksum {
				set checksum $value
            }
            -metric {
				set metric $value
            }            
			-route_block {
				set route_block $value
            }
            -enabled {
                set enabled [BoolTrans $value]
            }

        }
    }

    if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}
	
	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		$route_block configure -protocol "ospf"
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]

Deputs "num:$num start:$start step:$step prefix_len:$prefix_len"
        ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
		
		$rb configure -handle $handle
		$rb configure -portObj $portObj
		$rb configure -hPort $hPort
		$rb configure -protocol "ospf"
		$rb enable
		
		set routeBlock($rb,handle) $handle
		lappend routeBlock(obj) $rb

	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}
    
    if { [ info exists enabled ] } {
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value $enabled
        ixNet commit
	}
	
    return [GetStandardReturnHeader]
	
}

class SimulatedInterAreaRoute {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj
    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
		#set hRouteRange [ixNet add $hRouter routeRange]
		#ixNet commit
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
		ixNet commit
		if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }
		set trafficObj $handle
	}
	
	
	method config { args } {}
	
}

class SimulatedLink {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj
    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
		ixNet commit
		if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }

		set trafficObj $handle
	}
	method config { args } {}
}
body SimulatedLink::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedLink::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	   set key [string tolower $key]
	   switch -exact -- $key {
		  
		  -age {
				set age $value
		  }            
			-checksum {
				set checksum $value
		  }
		  -metric {
				set metric $value
		  }            
			-route_block {
				set route_block $value
		  }

	   }
    }
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}

	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]
		
		ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
		
	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}

    return [GetStandardReturnHeader]
	
}

class SimulatedRouter {
	inherit NetNgpfObject

	public variable hUserlsagroup
	public variable hUserlsa
    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
Deputs "hRouter is: $hRouter"
		set hUserlsagroup [ixNet add $hRouter userLsaGroup]
		ixNet commit
		
		set hUserlsagroup [ ixNet remapIds $hUserlsagroup ]
		ixNet setA $hUserlsagroup -enalbed True
		ixNet commit
	    
	    set hUserlsa [ixNet add $hUserlsagroup userLsa]
	    ixNet commit
	    
	    set hUserlsa [ ixNet remapIds $hUserlsa ]
	    ixNet setA $hUserlsa -enalbed True
	    ixNet commit
		
		set trafficObj $hUserlsa
	}
	method config { args } {}
}
body SimulatedRouter::config { args } {
	global errorInfo
     global errNumber
	
	set type normal
     set tag "body SimulatedRouter::config [info script]"
Deputs "----- TAG: $tag -----"

Deputs "Args:$args "
	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-id {
				set id $value
			}            
			-type {
				set type $value
			}
		}
	}
	
	if { [ info exists id ] } {
		ixNet setA $hUserlsa -advertisingRouterId $id
	}
	
	if { [ info exists type ] } {
		switch $type {						
			abr {
				ixNet setM $hUserlsa/router -bBit True
			}
			asbr {
				ixNet setM $hUserlsa/router -eBit True								
			}	
			vl {
				ixNet setM $hUserlsa/router -vBit True
			}
			normal {
				ixNet setM $hUserlsa/router \
				-bBit False \
				-eBit False \
				-vBit False \
				-wBit False
			}
		}
	}
	
	ixNet commit
	return [GetStandardReturnHeader]
	
}

class SimulatedNssaRoute {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj

    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }

		set trafficObj $handle
	}
	method config { args } {}
}
body SimulatedNssaRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedNssaRoute::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	   set key [string tolower $key]
	   switch -exact -- $key {
		  
		  -age {
				set age $value
		  }            
			-checksum {
				set checksum $value
		  }
		  -metric {
				set metric $value
		  }            
			-route_block {
				set route_block $value
		  }

	   }
    }
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}

	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]
		
		ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
        ixNet setA [ixNet getA $ospfRouteObj -routeOrigin]/singleValue -value nssa
        ixNet commit
		
	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}
	
	ixNet commit
	
    return [GetStandardReturnHeader]
	
}

class SimulatedExternalRoute {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj

    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}

		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }
		
		set trafficObj $handle
	}
	method config { args } {}
}
body SimulatedExternalRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedExternalRoute::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	   set key [string tolower $key]
	   switch -exact -- $key {		  
		  -age {
				set age $value
		  }            
			-checksum {
				set checksum $value
		  }
		  -metric {
				set metric $value
		  }            
		-route_block {
				set route_block $value
		  }
          -enabled {
                set enabled [BoolTrans $value]
            }

	   }
    }
	
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}
	
	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]

		ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
        ixNet setA [ixNet getA $ospfRouteObj -routeOrigin]/singleValue -value externaltype1
        ixNet commit
		
	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}
	
	
    if { [ info exists enabled ] } {
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
	}
	
    return [GetStandardReturnHeader]
	
}

class SimulatedLinkRoute {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj

    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }
		
		set trafficObj $handle
	}
	method config { args } {}
}
body SimulatedLinkRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedLinkRoute::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	   set key [string tolower $key]
	   switch -exact -- $key {
		  
		  -age {
				set age $value
		  }            
			-checksum {
				set checksum $value
		  }
		  -metric {
				set metric $value
		  }            
			-route_block {
				set route_block $value
		  }

	   }
    }
	
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}
	
	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]
		ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
		
	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}
	
	ixNet commit
	
    return [GetStandardReturnHeader]
	
}

class SimulatedIntraAreaRoute {
	inherit NetNgpfObject
	public variable routerObj
	public variable ipv4PoolObj
	public variable ipv6PoolObj

    constructor { router } {
		global errNumber
	    
		set tag "body SimulatedSummaryRoute::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in SimulatedSummaryRoute ctor"
		}
		
		if {[string first "ospfv2" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ospfv3" $hRouter] != -1} {
            set ip_version "ipv6"
        }
		set deviceGroupObj [GetDeviceNgpfHandle $hRouter]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
        }
		
		set trafficObj $handle
	}
	method config { args } {}
}
body SimulatedIntraAreaRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedIntraAreaRoute::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	   set key [string tolower $key]
	   switch -exact -- $key {		  
		  -age {
				set age $value
		  }            
			-checksum {
				set checksum $value
		  }
		  -metric {
				set metric $value
		  }            
			-route_block {
				set route_block $value
		  }
          -route_block {
				set route_block $value
		  }

	   }
    }
	
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}
	
	if { [ info exists route_block ] } {
	
		set rb [ GetObject $route_block ]
		$route_block configure -handle $handle
		
		if { $rb == "" } {
		
			return [GetErrorReturnHeader "No object found...-route_block"]
			
		}
		
		set num 		[ $rb cget -num ]
		set start 		[ $rb cget -start ]
		set step		[ $rb cget -step ]
		set prefix_len	[ $rb cget -prefix_len ]

		ixNet setA $handle -multiplier $num
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        set pLen $prefix_len
        if {$step !=""} {
            set step $step
        } else {
            set step 1
        }
        if {[IsIPv6Address $start]} {
			ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv6PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 16} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 0 0 $step]
            } elseif  {$pLen == 32} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 2 2 $step]
            } elseif  {$pLen == 48} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 4 4 $step]
            } elseif  {$pLen == 64} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 6 6 $step]
            } elseif  {$pLen == 80} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 8 8 $step]
            } elseif  {$pLen == 96} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 10 10 $step]
            } elseif  {$pLen == 112} {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 12 12 $step]
            } else {
                set stepvalue [string replace "0:0:0:0:0:0:0:0" 14 14 $step]
            }
            ixNet setA [ixNet getA $ipv6PoolObj -networkAddress]/counter -step $stepvalue
		} else {
			ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
			ixNet setA [ixNet getA $ipv4PoolObj -prefixLength]/singleValue -value $pLen
            if {$pLen == 8} {
                set stepvalue [string replace "0.0.0.0" 0 0 $step]
            } elseif  {$pLen == 16} {
                set stepvalue [string replace "0.0.0.0" 2 2 $step]
            } elseif  {$pLen == 24} {
                set stepvalue [string replace "0.0.0.0" 4 4 $step]
            } else {
                set stepvalue [string replace "0.0.0.0" 6 6 $step]
            }
            ixNet setA [ixNet getA $ipv4PoolObj -networkAddress]/counter -step $stepvalue
		}
		ixNet commit
        ixNet setA [ixNet getA $ospfRouteObj -routeOrigin]/singleValue -value samearea
        ixNet commit
		
	} else {
	
		return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
	}
    
    if { [ info exists enabled ] } {
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
	}
	
    return [GetStandardReturnHeader]
	
}




