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
	public variable view
    set devicehandle ""
    global devicehandle
	
    constructor { port { hOspfSession NULL } } {
		global errNumber
		
		set tag "body OspfvSession::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set portObj [ GetObject $port ]
		
		set handle ""
		set ospfRtHandle ""
		set view ""
        
		
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
        # The below code not required for NGPF so commented
        if {0} {
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
        set deviceGroup [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
        set routeObj [ixNet getL $deviceGroup routerData]
        set ipPattern [ixNet getA [ixNet getA $routeObj -routerId] -pattern]
        SetMultiValues $routeObj "-routerId" $ipPattern $router_id
		Deputs "router_idpost:$router_id"
	}	
	if { [ info exists area_id ] } {
	    
	    set id_hex [IP2Hex $area_id]
		set area_id [format %i 0x$id_hex]

		set ipPattern [ixNet getA [ixNet getA $handle -areaId] -pattern]
        SetMultiValues $handle "-areaId" $ipPattern $area_id
		#set valueObj [ ixNet getA $handle -areaId]
		#set value [ixNet setA $valueObj/singleValue -value $area_id]
		#ixNet commit
		
	}
	if { [ info exists hello_interval ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -helloInterval] -pattern]
        SetMultiValues $handle "-helloInterval" $ipPattern $hello_interval
		#set valueObj [ ixNet getA $handle -helloInterval]
		#set value [ixNet setA $valueObj/singleValue -value $hello_interval]
		#ixNet commit
	}
	if { [ info exists if_cost ] } {
		set version [GetOspfNgpfRouterHandle $handle 1]
		if {$version == 2} {
		    set ipPattern [ixNet getA [ixNet getA $handle -metric] -pattern]
            SetMultiValues $handle "-metric" $ipPattern $if_cost
		  #ixNet setA [ixNet getA $handle -metric]/singleValue -value $if_cost
		  #ixNet commit
		} elseif {$version == 3} {
            set ipPattern [ixNet getA [ixNet getA $handle -linkMetric] -pattern]
            SetMultiValues $handle "-linkMetric" $ipPattern $if_cost
          #ixNet setA [ixNet getA $handle -linkMetric]/singleValue -value $if_cost
		}
	}
	
	# v3 -interfaceType pointToPoint, -interfaceType broadcast
	# v2 -networkType pointToPoint, -networkType broadcast, -networkType pointToMultipoint
	if { [ info exists network_type ] } {
	    set network_type [string toupper $network_type]
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
		set ipPattern [ixNet getA [ixNet getA $handle -networkType] -pattern]
        SetMultiValues $handle "-networkType" $ipPattern $network_type
        #ixNet setA [ixNet getA $handle -networkType]/singleValue -value $network_type
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
		set ipPattern [ixNet getA [ixNet getA $handle -deadInterval] -pattern]
        SetMultiValues $handle "-deadInterval" $ipPattern $dead_interval
		#ixNet setA [ixNet getA $handle -deadInterval]/singleValue -value $dead_interval
		#ixNet commit
	}
	
	# v3 
	# v2 -lsaRetransmitTime
	if { [ info exists retransmit_interval ] } {
		set ospfRtHandle [GetOspfNgpfRouterHandle $handle]
		Deputs "ospfRtHandle:$ospfRtHandle"
		set ipPattern [ixNet getA [ixNet getA $ospfRtHandle -lsaRetransmitTime] -pattern]
        SetMultiValues $ospfRtHandle "-lsaRetransmitTime" $ipPattern $retransmit_interval
		#ixNet setA [ixNet getA $ospfRtHandle -lsaRetransmitTime]/singleValue -value $retransmit_interval
		#ixNet commit
	}
	if { [ info exists priority ] } {
	    set ipPattern [ixNet getA [ixNet getA $handle -priority] -pattern]
        SetMultiValues $handle "-priority" $ipPattern $priority
	    #ixNet setA [ixNet getA $handle -priority]/singleValue -value $priority
		#ixNet commit
	}
    return [GetStandardReturnHeader]
	
}
body OspfSession::advertise_topo {} {

	set tag "body OspfSession::advertise_topo [info script]"
Deputs "----- TAG: $tag -----"
    set deviceGroupObj [$this cget -deviceHandle]
	foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
	    set ipPattern [ixNet getA [ixNet getA $route -enabled] -pattern]
        SetMultiValues $route "-enabled" $ipPattern True
	    #ixNet setA [ixNet getA $route -enabled]/singleValue -value True
	}

    ixNet commit
    return [GetStandardReturnHeader]
}
body OspfSession::withdraw_topo {} {

	set tag "body OspfSession::withdraw_topo [info script]"
Deputs "----- TAG: $tag -----"
    set deviceGroupObj [$this cget -deviceHandle]
    foreach route [ ixNet getL $deviceGroupObj networkGroup ] {
	    set ipPattern [ixNet getA [ixNet getA $route -enabled] -pattern]
        SetMultiValues $route "-enabled" $ipPattern False
		#ixNet setA [ixNet getA $route -enabled]/singleValue -value False
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
		set typeList {netTopologyCustom netTopologyFatTree netTopologyGrid netTopologyHubNSpoke netTopologyLinear netTopologyMesh netTopologyRing netTopologyTree}
		set type [$topo cget -type]
		foreach netType $typeList {
            if {[string first $type [string tolower $netType]] != -1 } {
                set type $netType
                set netTopology [ixNet add $hNetworkRange $netType]
                ixNet commit
                break
            }
        }
		set sim_rtr_num [$topo cget -sim_rtr_num]
		set row_num [$topo cget -row_num]
		set column_num [$topo cget -column_num]
		set attach_row [$topo cget -attach_row]
		set attach_column [$topo cget -attach_column]
		if { [info exists netTopology] } {
		    ixNet setM $netTopology -rows $row_num -columns $column_num
		    ixNet commit
		}
		set routerId [$topo cget -router_id_start]
		if { [info exists routerId] } {
		    set simRouteObj [ixNet getL $hNetworkRange simRouter]
		    set ipPattern [ixNet getA [ixNet getA $simRouteObj -routerId] -pattern]
            SetMultiValues $simRouteObj "-routerId" $ipPattern $routerId
		}
		# The below arguments not present in NGPF
        #-entryRow $attach_row \
        #-entryColumn $attach_column

	} else {
		return [GetErrorReturnHeader "Madatory parameter needed...-topo"]
	}
	ixNet commit
	
	return [GetStandardReturnHeader]
}
body OspfSession::unset_topo {} {
	
	set tag "body OspfSession::unset_topo [info script]"
Deputs "----- TAG: $tag -----"
	puts "Stopping  All Protocols"
    ixNet exec stopAllProtocols
	after 30000
    ixNet remove $hNetworkGroup networkGroup
	ixNet commit
}

class Ospfv2Session {
	inherit OspfSession
    constructor { port { hOspfSession NULL } } { chain $port $hOspfSession } {
		set tag "body Ospfv2Session::ctor [info script]"
        Deputs "----- TAG: $tag -----"
		set view ""
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
            } else {
                set handleName $this
                set handle ""
                reborn
            }
            
        } else {
            set handleName $this
            set handle ""
			set view ""
			
            reborn
        }
        
    }
	
	method reborn {} {
		set tag "body Ospfv2Session::reborn [info script]"
Deputs "----- TAG: $tag -----"

		chain
		set topoObjList [ixNet getL [ixNet getRoot] topology]
        Deputs "topoObjList: $topoObjList"
        set vportList [ixNet getL [ixNet getRoot] vport]
        #set vport [ lindex $vportList end ]

        if {[llength $topoObjList] != [llength $vportList]} {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                foreach vport $vportList {
                    if {$vportObj != $vport && $vport == $hPort} {
                        set vportTopoList ""
                        foreach topoObj $topoObjList {
                            set vportObj [ixNet getA $topoObj -vports]
                            lappend vportTopoList $vportObj
                        }
                        if {[string first $hPort $vportTopoList] == -1} {
                            set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                            ixNet commit
                            set deviceGroupObj [ixNet add $topoObj deviceGroup]
                            ixNet commit
                            ixNet setA $deviceGroupObj -multiplier 1
                            ixNet commit
                            set ethernetObj [ixNet add $deviceGroupObj ethernet]
                            ixNet commit
                            set ipv4Obj [ixNet add $ethernetObj ipv4]
                            ixNet commit
                        }
                    }
                }
                break
            }
        }
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        if { [ llength $topoObjList ] == 0 } {
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
        } else {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        if {$ethernetList != ""} {
                            foreach ethernetObj $ethernetList {
                                set ipv4Obj [ixNet getL $ethernetObj ipv4]
                                if {$ipv4Obj != ""} {
                                    set ospfObj [ixNet getL $ipv4Obj ospfv2]
                                    if {$ospfObj == ""} {
                                        set ospfObj [ixNet add $ipv4Obj ospfv2]
                                        ixNet commit
                                    }
                                } else {
                                   set ipv4Obj [ixNet add $ethernetObj ipv4]
                                   set ospfObj [ixNet add $ipv4Obj ospfv2]
                                   ixNet commit
                                }
                            }
                        } else {
                            set ethObj [ixNet add $deviceGroupObj ethernet]
                            ixNet commit
                            set ipv4Obj [ixNet getL $ethObj ipv4]
                            if {$ipv4Obj != ""} {
                                set ospfObj [ixNet getL $ipv4Obj ospfv2]
                                if {$ospfObj == ""} {
                                    set ospfObj [ixNet add $ipv4Obj ospfv2]
                                    ixNet commit
                                }
                            } else {
                               set ipv4Obj [ixNet add $ethObj ipv4]
                               set ospfObj [ixNet add $ipv4Obj ospfv2]
                               ixNet commit
                            }
                        }
                    }
                }
            }
        }
		set ospfRtHandle [ ixNet getL $deviceGroupObj ospfv2Router ]
		ixNet setA [ ixNet getA $ospfRtHandle -active]/singleValue -value True
		ixNet commit
		set handle [ ixNet remapIds $ospfObj ]
		ixNet setA $handle -name $this
		ixNet commit
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
	puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	if {$view == ""} {
		set view [CreateNgpfProtocolView $protocol]
		}
	ixNet execute refresh $view
    set captionList             [ ixNet getA $view/page -columnCaptions ]
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
		Deputs "row:$row"
		Deputs "port index:$name_index"
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		Deputs "row port name:$rowPortName"
		set portName [ ixNet getA $hPort -name ]
		Deputs "portName:$portName"
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
	if {$view == ""} {
		set view [CreateNgpfProtocolView $protocol]
		}
	set captionList             [ ixNet getA $view/page -columnCaptions ]


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
		Deputs "row:$row"
		Deputs "port index:$name_index"
        set rowPortName [ lindex $row $name_index ]
		Deputs "row port name:$rowPortName"
		set portName [ ixNet getA $hPort -name ]
		Deputs "portName:$portName"
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
                #set hInt [ ixNet add $handle interface ]
                #ixNet setM $hInt \
                #    -interfaceIpAddress $loopback_ipv4_addr \
                #    -interfaceIpMaskAddress 255.255.255.255 \
                #    -enabled True \
                #    -connectedToDut False \
                #    -linkTypes stub

                #ixNet commit
                #set interface($loopbackInt) $hInt
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
            } else {
                set handleName $this
                set handle ""
                reborn
            }
			# else {
               # error "$errNumber(5) handle:$hOspfSession"
            # }
            
        } else {
            set handleName $this
            set handle ""
			set view ""
            reborn
        }
	    

    }
	
	method reborn {} {
		set tag "body Ospfv3Session::reborn [info script]"
Deputs "----- TAG: $tag -----"
		chain
		set topoObjList [ixNet getL [ixNet getRoot] topology]
        Deputs "topoObjList: $topoObjList"
        set vportList [ixNet getL [ixNet getRoot] vport]
        #set vport [ lindex $vportList end ]

        if {[llength $topoObjList] != [llength $vportList]} {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                foreach vport $vportList {
                    if {$vportObj != $vport && $vport == $hPort} {
                        set vportTopoList ""
                        foreach topoObj $topoObjList {
                            set vportObj [ixNet getA $topoObj -vports]
                            lappend vportTopoList $vportObj
                        }
                        if {[string first $hPort $vportTopoList] == -1} {
                            set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                            ixNet commit
                            set deviceGroupObj [ixNet add $topoObj deviceGroup]
                            ixNet commit
                            ixNet setA $deviceGroupObj -multiplier 1
                            ixNet commit
                            set ethernetObj [ixNet add $deviceGroupObj ethernet]
                            ixNet commit
                            set ipv6Obj [ixNet add $ethernetObj ipv6]
                            ixNet commit
                        }
                    }
                }
                break
            }
        }
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        if { [ llength $topoObjList ] == 0 } {
            set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
            ixNet commit
            set deviceGroupObj [ixNet add $topoObj deviceGroup]
            ixNet commit
            set deviceGroupObj [ ixNet remapIds $deviceGroupObj ]
            ixNet setA $deviceGroupObj -multiplier 1
            ixNet commit
            set ethObj [ixNet add $deviceGroupObj ethernet]
            ixNet commit
            set ipv6Obj [ixNet add $ethObj ipv6]
            ixNet commit
            set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
            ixNet commit
        } else {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        if {$ethernetList != ""} {
                            foreach ethernetObj $ethernetList {
                                set ipv6Obj [ixNet getL $ethernetObj ipv6]
                                if {$ipv6Obj != ""} {
                                    set ospfv3Obj [ixNet getL $ipv6Obj ospfv3]
                                    if {$ospfv3Obj == ""} {
                                        set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
                                        ixNet commit
                                    }
                                } else {
                                   set ipv6Obj [ixNet add $ethernetObj ipv6]
                                   ixNet commit
                                   set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
                                   ixNet commit
                                }
                            }
                        } else {
                            set ethObj [ixNet add $deviceGroupObj ethernet]
                            ixNet commit
                            set ipv6Obj [ixNet getL $ethObj ipv6]
                            if {$ipv6Obj != ""} {
                                set ospfv3Obj [ixNet getL $ipv6Obj ospfv3]
                                if {$ospfv3Obj == ""} {
                                    set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
                                    ixNet commit
                                }
                            } else {
                               set ipv6Obj [ixNet add $ethObj ipv6]
                               set ospfv3Obj [ixNet add $ipv6Obj ospfv3]
                               ixNet commit
                            }
                        }
                    }
                }
            }
        }
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
	puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	if {$view == ""} {
		set view [CreateNgpfProtocolView $protocol]
		}
    set captionList         [ ixNet getA $view/page -columnCaptions ]
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
	Deputs "stats:$stats"
    set portFound 0
    foreach row $stats {
        eval {set row} $row
		Deputs "row:$row"
		Deputs "port index:$name_index"
        set rowPortName [ lindex $row $name_index ]
		Deputs "row port name:$rowPortName"
		set portName [ ixNet getA $hPort -name ]
		Deputs "portName:$portName"
			if { [ regexp $portName $rowPortName ] } {
				set portFound 1
				break
        }
    }

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
	set tag "body Ospfv3Session::get_stats [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
Deputs "root $root"
    puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 50000
	set protocol "OSPFv3-RTR"
	set view [CreateNgpfProtocolView $protocol]
    set captionList         [ ixNet getA $view/page -columnCaptions ]
	Deputs "captionList:$captionList"
	

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
	set tx_nssa_lsa_index		[ lsearch -exact $captionList {NSSA LSA Tx} ]
	set rx_request_index		[ lsearch -exact $captionList {LS Request Rx} ]
	set tx_request_index		[ lsearch -exact $captionList {LS Request Tx} ]
	set rx_router_lsa_index		[ lsearch -exact $captionList {Router LSA Rx} ]
	set tx_router_lsa_index		[ lsearch -exact $captionList {Router LSA Tx} ]
	set rx_as_external_lsa_index 	[ lsearch -exact $captionList {External LSA Rx} ]
	set tx_as_external_lsa_index 	[ lsearch -exact $captionList {External LSA Tx} ]
	set rx_update_index	 		[ lsearch -exact $captionList  {LS Update Rx}  ]
	set tx_update_index	 		[ lsearch -exact $captionList  {LS Update Tx}  ]

    set rx_inter_area_prefix_lsa_index 	[ lsearch -exact $captionList  {InterArea Prefix LSA Rx}  ]
    set tx_inter_area_prefix_lsa_index 	[ lsearch -exact $captionList  {InterArea Prefix LSA Tx}  ]
	set rx_inter_area_router_lsa_index	[ lsearch -exact $captionList {InterArea Router LSA Rx} ]
	set tx_inter_area_router_lsa_index	[ lsearch -exact $captionList {InterArea Router LSA Tx} ]
	set rx_intra_area_prefix_lsa_index	[ lsearch -exact $captionList {IntraArea Prefix LSA Rx} ]
	set tx_intra_area_prefix_lsa_index	[ lsearch -exact $captionList {IntraArea Prefix LSA Tx} ]
	set rx_link_lsa_index	[ lsearch -exact $captionList {Link LSA Rx} ]
	set tx_link_lsa_index	[ lsearch -exact $captionList {Link LSA Tx} ]


	set stats [ ixNet getA $view/page -rowValues ]
	Deputs "stats:$stats"
    set portFound 0
    foreach row $stats {
		Deputs "row:$row"
		Deputs "port index:$name_index"
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		Deputs "row port name:$rowPortName"
		set portName [ ixNet getA $hPort -name ]
		Deputs "portName:$portName"
        if { [ regexp $portName $rowPortName ] } {
            set portFound 1
            break
        }
    }
    set ret "Status : true\nLog : \n"
    if { $portFound } {
		Deputs "stats"
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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipPoolObj $ipv6PoolObj
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
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
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
		ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
		ixNet commit
		if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
            -from {
                set from $value
            }
            -to {
                set to $value
            }
	   }
    }
	if { [ info exists ipv4PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv4PoolObj ospfRouteProperty]
        set ipv4PoolObj [ ixNet remapIds $ipv4PoolObj ]
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipv6PoolObj [ ixNet remapIds $ipv6PoolObj ]
        set ipPoolObj $ipv6PoolObj
    }
	if { [ info exists metric ] } {
		ixNet setA [ixNet getA $ospfRouteObj -metric]/singleValue -value $metric
	    ixNet commit
	}
	if { [info exists from ] } {
        #Need clarification for this argument
	}
	if { [info exists to ] } {
        #Need clarification for this argument
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        }
		
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

        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
        set hNetworkGroup [ixNet add $deviceGroupObj networkGroup]
        ixNet commit
        set hNetworkRange [ixNet add $hNetworkGroup networkTopology]
        ixNet commit
        set hUserlsa [ ixNet remapIds $hNetworkRange ]
        set hNetworkGroup [ ixNet remapIds $hNetworkGroup ]
        #Available options are netTopologyCustom netTopologyFatTree netTopologyGrid netTopologyHubNSpoke netTopologyLinear netTopologyMesh netTopologyRing netTopologyTree
        set linearTopology [ixNet add $hNetworkRange netTopologyFatTree]
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
	set simRouterObj [ixNet getL $hUserlsa simRouter]
	if { [ info exists id ] } {
	    ixNet setA [ixNet getA $simRouterObj -routerId]/counter -start $id -direction increment -step "0.0.0.1"
	}
	set ospfRouterObj [ixNet getL $simRouterObj ospfPseudoRouter]
	set ospfV3RouterObj [ixNet getL $simRouterObj ospfv3PseudoRouter]
	if { [ info exists type ] } {
		switch $type {
			abr {
				if {$ospfRouterObj != ""} {
				    ixNet setA [ixNet getA $ospfRouterObj -bBit]/singleValue -value True
				}
				if {$ospfV3RouterObj != ""} {
				    ixNet setA [ixNet getA $ospfV3RouterObj -bBit]/singleValue -value True
				}
			}
			asbr {
				if {$ospfRouterObj != ""} {
				    ixNet setA [ixNet getA $ospfRouterObj -eBit]/singleValue -value True
				}
				if {$ospfV3RouterObj != ""} {
				    ixNet setA [ixNet getA $ospfV3RouterObj -eBit]/singleValue -value True
				}
			}
			vl {
				#ixNet setM $hUserlsa/router -vBit True
				Deputs "vBit not available in NGPF"
			}
			normal {
				if {$ospfRouterObj != ""} {
				    ixNet setA [ixNet getA $ospfRouterObj -bBit]/singleValue -value False
				    ixNet setA [ixNet getA $ospfRouterObj -eBit]/singleValue -value False
				}
				if {$ospfV3RouterObj != ""} {
				    ixNet setA [ixNet getA $ospfV3RouterObj -bBit]/singleValue -value False
				    ixNet setA [ixNet getA $ospfV3RouterObj -eBit]/singleValue -value False
				}
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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipPoolObj $ipv6PoolObj
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        }

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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipPoolObj $ipv6PoolObj
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        }

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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipPoolObj $ipv6PoolObj
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
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
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hRouter "deviceGroup"]
		set hRouteRange [ixNet add $deviceGroupObj "networkGroup"]
        ixNet commit
        set handle [ ixNet remapIds $hRouteRange ]
        ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
        ixNet commit
        if {$ip_version == "ipv4"} {
            set ipv4PoolObj [ixNet add $handle "ipv4PrefixPools"]
            ixNet setM $ipv4PoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
            ixNet commit
        }
        if {$ip_version == "ipv6"} {
            set ipv6PoolObj [ixNet add $handle "ipv6PrefixPools"]
            ixNet setM $ipv6PoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
            ixNet commit
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $hRouter
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
        set ipPoolObj $ipv4PoolObj
    }
    if { [ info exists ipv6PoolObj ] } {
        set ospfRouteObj [ixNet getL $ipv6PoolObj ospfv3RouteProperty]
        set ipPoolObj $ipv6PoolObj
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
        if { $prefix_len != "" } {
            if {[string first "." $prefix_len] != -1} {
                set pLen [SubnetToPrefixlenV4 $prefix_len]
            } else {
                set pLen $prefix_len
            }
            if {[string first "." $start] != -1} {
                set type "ipv4"
            } else {
                set type "ipv6"
            }
        } else {
            if {[string first "." $start] != -1} {
                set pLen 24
                set type "ipv4"
            } else {
                set pLen 64
                set type "ipv6"
            }
        }
        #not accepting 255.255.255.0 for prefix_len, but taking integer value
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
        #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
        ixNet commit

        if { $step != "" } {
            set stepvalue [GetIpV46Step $type $pLen $step]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        } else {
            set stepvalue [GetIpV46Step $type $pLen 1]
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
            ixNet commit
        }
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




