
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.0
#===============================================================================
# Change made
# Version 1.0 
#       1. Create

class PimSession {
	inherit RouterNgpfEmulationObject
	public variable hInt
	
	constructor { port { hPim NULL }  } {
		global errNumber
		
		set tag "body PimSession::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set portObj [ GetObject $port ]
		if {[ catch {
			set hPort [ $portObj cget -handle ]
		} ] } {
			error "$errNumber(1) Port Object in rip ctor"
		}

        set topoObjList [ixNet getL [ixNet getRoot] topology]
        Deputs "topoObjList: $topoObjList"
        set vportList [ixNet getL [ixNet getRoot] vport]
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
        if { [ llength $topoObjList ] == 0 } {
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
            set handle [ixNet add $ipv4Obj pimV4Interface]
            ixNet commit
            set handle [ ixNet remapIds $handle ]
        } else {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        foreach ethernetObj $ethernetList {
                            set ipv4Obj [ixNet getL $ethernetObj ipv4]
                            set ipv6Obj [ixNet getL $ethernetObj ipv6]
                            if { [info exists ipv4Obj] && $ipv4Obj != "" } {
                                set handle [ixNet getL $ipv4Obj pimV4Interface]
                                if {[llength $handle] != 0} {
                                    set handle [ ixNet remapIds $handle ]
                                } else {
                                    set handle [ixNet add $ipv4Obj pimV4Interface]
                                    ixNet commit
                                    set handle [ ixNet remapIds $handle ]
                                }
                            }
                            if { [info exists ipv6Obj] && $ipv6Obj != "" } {
                                set handle [ixNet getL $ipv6Obj pimV6Interface]
                                if {[llength $handle] != 0} {
                                    set handle [ ixNet remapIds $handle ]
                                } else {
                                    set handle [ixNet add $ipv6Obj pimV6Interface]
                                    ixNet commit
                                    set handle [ ixNet remapIds $handle ]
                                }
                            }
                        }
                    }
                }
            }
        }
        if { $hPim == "NULL" } {
            set hPim [GetObjNameFromString $this "NULL"]
        }  
        if { $hPim != "NULL" } {
            set handle [GetValidNgpfHandleObj "pim_router" $hPim $hPort]
            Deputs "----- handle: $handle -----"
        }
        if { $handle != "" } {
            set handleName [ ixNet getA $handle -name ]
            if { [info exists ethernetObj] } {
                set rb_interface ethernetObj
            } else {
                set topoObjList [ixNet getL [ixNet getRoot] topology]
                foreach topoObj $topoObjList {
                    set vportObj [ixNet getA $topoObj -vports]
                    if {$vportObj == $hPort} {
                        set deviceGroupList [ixNet getL $topoObj deviceGroup]
                        foreach deviceGroupObj $deviceGroupList {
                            set ethernetObj [ixNet getL $deviceGroupObj ethernet]
                            break
                        }
                    }
                }
                set rb_interface ethernetObj
            }
            array set interface [ list ]
            #set hInt [lindex [ixNet getL $handle interface] 0 ]
            set hInt ethernetObj
            #unable to find "-interfaces" so not yet implemented
            #set int [ixNet getA $hInt -interfaces]
            #set interface($int) $hInt
        }
        if { $handle == ""} {
            if { [info exists ipv4Obj] } {
                if { $ipv4Obj != "" } {
                    set handle [ixNet add $ipv4Obj pimV4Interface]
                    ixNet commit
                    set handle [ ixNet remapIds $handle ]
                }
            }
            if { [info exists ipv6Obj] } {
                if { $ipv6Obj != "" } {
                    set handle [ixNet add $ipv6Obj pimV6Interface]
                    ixNet commit
                    set handle [ ixNet remapIds $handle ]
                }
            }
        }
        set deviceGroup [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
        set rb_interface [ ixNet getL $deviceGroup ethernet ]
        array set interface [ list ]

        generate_interface
        ixNet setA $handle -name $this
        ixNet commit
	}
	
	method config { args } {}
	method get_status {} {}
	method get_stats {} {}
	method send_bsm {} {}
	method generate_interface { args } {
		set tag "body RipSession::generate_interface [info script]"
        Deputs "----- TAG: $tag -----"
        Deputs "Not Required in NGPF"
	}	
}

class PimGroup {
	
	inherit NetNgpfObject
	public variable hJoinPrune
	public variable hSource
	public variable rb_interface
	
	constructor { router } {
		global errNumber
        global LoadConfigMode
	    
		set tag "body PimGroup::ctor [info script]"
Deputs "----- TAG: $tag -----"
		
		set routerObj [ GetObject $router ]
		if { [ catch {
			set hRouter   [ $routerObj cget -handle ]
		} ] } {
			error "$errNumber(1) Router Object in PimGroup ctor"
		}
		if {[string first "ipv4" $hRouter] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ipv6" $hRouter] != -1} {
            set ip_version "ipv6"
        }

		#set rb_interface [ ixNet getL $hRouter interface ]
        
        set hJoinPrune ""
        if { $LoadConfigMode } {
            set RPAddr [GetObjNameFromString $this "NULL"]
            if { $ip_version == "ipv4" } {
                set hJoinPruneList [ ixNet getL $hRouter pimV4JoinPruneList ]
            } else {
                set hJoinPruneList [ ixNet getL $hRouter pimV6JoinPruneList ]
            }
            if { $RPAddr != "NULL" && $hJoinPruneList != "" } {
                foreach hJ $hJoinPruneList {
                    if { $ip_version == "ipv4" } {
                        set ipPattern [ixNet getA [ixNet getA $hJ -rpV4Address] -pattern]
                        set rp_addr [GetMultiValues $hJ "-rpV4Address" $ipPattern]
                    } else {
                        set ipPattern [ixNet getA [ixNet getA $hJ -rpV6Address] -pattern]
                        set rp_addr [GetMultiValues $hJ "-rpV6Address" $ipPattern]
                    }
                    #set rp_addr [ixNet getA $hJ -rpAddress ]
                    if { $rp_addr == $RPAddr } {
                        set hJoinPrune $hJ
                        break
                    }
            
                }
            } 
        }
        
		if { $hJoinPrune == "" } {
            if { $ip_version == "ipv4" } {
                set hJoinPrune [ ixNet getL $hRouter pimV4JoinPruneList ]
                set hSource [ ixNet getL $hRouter pimV4SourcesList ]
            } else {
                set hJoinPrune [ ixNet getL $hRouter pimV6JoinPruneList ]
                set hSource [ ixNet getL $hRouter pimV6SourcesList ]
            }
        }
    }
	
	method config { args } {}
	method send_join {} {}
	method send_prune {} {}

}


body PimSession::config { args } {
	global errorInfo
	global errNumber
	
	set bi_dir_option_set NO
	set Bootstrap_message_interval 60
	set bsr_priority 1
	set dr_priority 1
	set enable_bsr NO
	set gen_id_mode FIXED
	set hello_hold_time 105
	set hello_interval 30
	set join_prune_hold_time 60
	set join_prune_interval 60
	set ip_version Ipv4
	
	set tag "body PimSession::config [info script]"
Deputs "----- TAG: $tag -----"
	
	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-ip_version {
				set value [string tolower $value]
				set ip_version $value
			}
			-router_id {
				set router_id $value
			}
			-bi_dir_option_set {
				set value [string toupper $value]
				set bi_dir_option_set $value
			}
			-bootstrap_message_interval {			
				set bootstrap_message_interval $value
			}
			-bsr_priority {
				set bsr_priority $value
			}
			-dr_priority {
				set dr_priority $value
			}
			-enable_bsr {
				set value [string toupper $value]
				set enable_bsr $value
			}
			-gen_id_mode {
				set value [string toupper $value]
				set gen_id_mode $value
			}
			-hello_hold_time {
				set hello_hold_time $value
			}
			-hello_interval {
				set hello_interval $value
			}
			-join_prune_hold_time {
				set join_prune_hold_time $value
			}
			-join_prune_interval {
				set join_prune_interval $value
			}
			
			# Can not find in ixNetwork
			-pim_mode {
				set pim_mode $value
			}
			-upstream_neighbor {
				set upstream_neighbor $value
			}
			
		}
	}
	
	set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
	if { [ info exists ip_version ] } {
		switch $ip_version {
			ipv4 {
				set ip_version ipv4
			}
			ipv6 {
				set ip_version ipv6
			}
		}
		if { $ip_version == "ipv6" } {
		    set ethernetObj [GetDependentNgpfProtocolHandle $handle "ethernet"]
		    set ipv4Obj [ixNet getL $ethernetObj "ipv4"]
		    set ipv6Obj [ixNet getL $ethernetObj "ipv6"]
		    if { $ipv4Obj == "" && $ipv6Obj != ""} {
		        set handle [ixNet getL $ipv6Obj pimV6Interface]
		    } else {
                ixNet remove $ipv4Obj
                ixNet commit
                set ipv6Obj [ixNet add $ethernetObj "ipv6"]
                ixNet commit
                set handle [ixNet add $ipv6Obj pimV6Interface]
                ixNet commit
                set handle [ ixNet remapIds $handle ]
                ixNet setA $handle -name $this
                ixNet commit
		    }
		}
	}
	if { [ info exists router_id ] } {
		set routeDataObj [ixNet getL $deviceGroupObj routerData]
        set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
        SetMultiValues $routeDataObj "-routerId" $ipPattern $router_id
	}
	if { [ info exists bi_dir_option_set ] } {
		switch $bi_dir_option_set {
			NO {
				set bi_dir_option_set False
			}
			YES {
				set bi_dir_option_set True
			}
		}
		set ipPattern [ixNet getA [ixNet getA $handle -sendBidirectional] -pattern]
        SetMultiValues $handle "-sendBidirectional" $ipPattern $bi_dir_option_set
	}	
	if { [ info exists bootstrap_message_interval ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -enableBootstrap] -pattern]
        SetMultiValues $handle "-enableBootstrap" $ipPattern True
		set ipPattern [ixNet getA [ixNet getA $handle -bootstrapInterval] -pattern]
        SetMultiValues $handle "-bootstrapInterval" $ipPattern $bootstrap_message_interval
	}
	if { [ info exists bsr_priority ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -enableBootstrap] -pattern]
        SetMultiValues $handle "-enableBootstrap" $ipPattern True
		set ipPattern [ixNet getA [ixNet getA $handle -bootstrapPriority] -pattern]
        SetMultiValues $handle "-bootstrapPriority" $ipPattern $bsr_priority
	}
	if { [ info exists dr_priority ] } {
		set pimRouterObj [ixNet getL $deviceGroupObj pimRouter]
		set ipPattern [ixNet getA [ixNet getA $pimRouterObj -drPriority] -pattern]
        SetMultiValues $pimRouterObj "-drPriority" $ipPattern $dr_priority
	}
	if { [ info exists enable_bsr ] } {
		switch $enable_bsr {						
			NO {
				set enable_bsr False
			}
			YES {
				set enable_bsr True				
			}			
		}
		set ipPattern [ixNet getA [ixNet getA $handle -enableBootstrap] -pattern]
        SetMultiValues $handle "-enableBootstrap" $ipPattern $enable_bsr
	}
	if { [ info exists gen_id_mode ] } {
		switch $gen_id_mode {						
			FIXED {
				set gen_id_mode constant				
			}
			INCREMENT {
				set gen_id_mode incremental			
			}
			RANDOM {
				set gen_id_mode random				
			}			
		}
		set ipPattern [ixNet getA [ixNet getA $handle -sendGenerationMode] -pattern]
        SetMultiValues $handle "-sendGenerationMode" $ipPattern $gen_id_mode
	}
	
	if { [ info exists hello_hold_time ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -helloHoldTime] -pattern]
        SetMultiValues $handle "-helloHoldTime" $ipPattern $hello_hold_time
	}
	
	if { [ info exists hello_interval ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -helloInterval] -pattern]
        SetMultiValues $handle "-helloInterval" $ipPattern $hello_interval
	}
	if { [ info exists join_prune_hold_time ] } {
		set pimRouterObj [ixNet getL $deviceGroupObj pimRouter]
		set ipPattern [ixNet getA [ixNet getA $pimRouterObj -joinPruneHoldTime] -pattern]
        SetMultiValues $pimRouterObj "-joinPruneHoldTime" $ipPattern $join_prune_hold_time
	}
	if { [ info exists join_prune_interval ] } {
		set pimRouterObj [ixNet getL $deviceGroupObj pimRouter]
		set ipPattern [ixNet getA [ixNet getA $pimRouterObj -joinPruneInterval] -pattern]
        SetMultiValues $pimRouterObj "-joinPruneInterval" $ipPattern $join_prune_interval
	}

	if { [ info exists upstream_neighbor ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -autoPickNeighbor] -pattern]
        SetMultiValues $handle "-autoPickNeighbor" $ipPattern False
        if { $ip_version == "ipv6" } {
            set ipPattern [ixNet getA [ixNet getA $handle -neighborV6Address] -pattern]
            SetMultiValues $handle "-neighborV6Address" $ipPattern $upstream_neighbor
        } else {
            set ipPattern [ixNet getA [ixNet getA $handle -v4Neighbor] -pattern]
            SetMultiValues $handle "-v4Neighbor" $ipPattern $upstream_neighbor
        }
	}
	
	# Workaround for hello_hold_time setting
	if { [ info exists hello_hold_time ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -helloHoldTime] -pattern]
        SetMultiValues $handle "-helloHoldTime" $ipPattern $hello_hold_time
	}
	# Workaround for join_prune_hold_time
	if { [ info exists join_prune_hold_time ] } {
		set pimRouterObj [ixNet getL $deviceGroupObj pimRouter]
		set ipPattern [ixNet getA [ixNet getA $pimRouterObj -joinPruneHoldTime] -pattern]
        SetMultiValues $pimRouterObj "-joinPruneHoldTime" $ipPattern $join_prune_hold_time
	}
	return [GetStandardReturnHeader]
}

body PimSession::get_status {} {
	set tag "body PimSession::get_status [info script]"
    Deputs "----- TAG: $tag -----"
	
	set root [ixNet getRoot]
    Deputs "root $root"

	set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	if {[string first "PIMv4 IF Per Port" $viewList] != -1 } {
        set view {::ixNet::OBJ-/statistics/view:"PIMv4 IF Per Port"}
        getStatusView $view $hPort
	}
	if {[string first "PIMv6 IF Per Port" $viewList] != -1 } {
        set view {::ixNet::OBJ-/statistics/view:"PIMv6 IF Per Port"}
        getStatusView $view $hPort
	}
}
proc getStatusView {view {hPort}} {
    after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
    Deputs "captionList $captionList"
	set name_index [ lsearch -exact $captionList {Port} ]
	#set rtrsconf_index [ lsearch -exact $captionList {Rtrs. Configured} ]
	#set rtrsrun_index [ lsearch -exact $captionList {Rtrs. Running} ]
	set rtrsconf_index [ lsearch -exact $captionList {Sessions Down} ]
	set rtrsrun_index [ lsearch -exact $captionList {Sessions Up} ]
	set nbrslear_index [ lsearch -exact $captionList {Number of Neighbors Learnt} ]
	set hellotx_index [ lsearch -exact $captionList {Hellos Tx} ]

	set stats [ ixNet getA $view/page -rowValues ]
    Deputs "stats:$stats"
	
	set portFound 0
	foreach row $stats {
		eval {set row} $row
    Deputs "row:$row"
		
    Deputs "port index:$name_index"
		set rowPortName [ lindex $row $name_index ]
    Deputs "row port name:$name_index"
		
		set connectionInfo [ ixNet getA $hPort -connectionInfo ]
    Deputs "connectionInfo :$connectionInfo"
        set connectionStatus [ixNet getA $hPort -connectionStatus]

		regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
    Deputs "chas:$chassis card:$card port:$port"
		
		set portName ${chassis}/Card${card}/Port${port}
    Deputs "filter name: $portName"
		
		# 192.168.0.110/Card1/Port7
		# 192.168.0.110/Card01/Port07
		#regexp -nocase {([0-9\.]+)/Card([0-9\.]+)/Port([0-9\.]+)} $rowPortName match rchassis rcard rport
		regexp -nocase {([0-9\.]+);([0-9\.]+);([0-9\.]+)} $connectionStatus match rchassis rcard rport
    Deputs "rchass:$rchassis rcard:$rcard rport:$rport"
		if { $card < 10 } {
		    set card 0$card
		}
		if { $port < 10 } {
		    set port 0$port
		}
		if {$chassis == $rchassis && $card == $rcard && $port == $rport} {
			set portFound 1
			break
		}
	}	
	
	set status "down"	
	
	if { $portFound } {
		set rtrsconf [ lindex $row $rtrsconf_index ]
		set rtrsrun [ lindex $row $rtrsrun_index ]
		set nbrslear [ lindex $row $nbrslear_index ]
		set hellotx [ lindex $row $hellotx_index ]

		if { $rtrsconf != "" && $rtrsconf == 0 } {
			set status "NO_STATE"
		}
		if { $rtrsrun != "" && $rtrsrun == 0 } {
			set status "STOPPED"
		} else {
			set status "STARTED"
		}
		if { $nbrslear != "" && $nbrslear != 0 } {
			set status "NEIGHBOR"
		}
		if { $hellotx != "" && $hellotx != 0} {
			set status "HELLO"
		}
#		if {} {
#			set status "DR"
#		}
	}	
	
	set ret [ GetStandardReturnHeader ]
	set ret $ret[ GetStandardReturnBody "status" $status ]
	return $ret
}

body PimSession::get_stats {} {
	set tag "body PimSession::get_stats [info script]"
Deputs "----- TAG: $tag -----"
	
	set root [ixNet getRoot]
Deputs "root $root"
	set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	if {[string first "PIMv4 IF Per Port" $viewList] != -1 } {
        set protocol "PIMv4 IF"
        set view [CreateNgpfProtocolView $protocol]
        #set view {::ixNet::OBJ-/statistics/view:"PIMv4 IF Per Port"}
        getStatsView $view $hPort
	}
	if {[string first "PIMv6 IF Per Port" $viewList] != -1 } {
        set protocol "PIMv6 IF"
        set view [CreateNgpfProtocolView $protocol]
        #set view {::ixNet::OBJ-/statistics/view:"PIMv6 IF Per Port"}
        getStatsView $view $hPort
	}
}
proc getStatsView {view {hPort}} {
	after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
Deputs "captionList $captionList"	 
	
	set name_index [ lsearch -exact $captionList {Port} ]
	set nbrslear_index [ lsearch -exact $captionList {Number of Neighbors Learnt} ]
	set bspmsgrx_index [ lsearch -exact $captionList {Bootstrap Msg Rx} ]
	set hellorx_index [ lsearch -exact $captionList {Hellos Rx} ]
	set regrx_index [ lsearch -exact $captionList {Register Rx} ]
	set regstoprx_index [ lsearch -exact $captionList {RegisterStop Rx} ]
	set bspmsgtx_index [ lsearch -exact $captionList {Bootstrap Msg Tx} ]
	set hellotx_index [ lsearch -exact $captionList {Hellos Tx} ]
	set regtx_index [ lsearch -exact $captionList {Register Tx} ]
	set regstoptx_index [ lsearch -exact $captionList {RegisterStop Tx} ]
	
	set stats [ ixNet getA $view/page -rowValues ]
	Deputs "stats:$stats"
	
	set portFound 0
	foreach row $stats {
		eval {set row} $row
Deputs "row:$row"
Deputs "port index:$name_index"
		set rowPortName [ lindex $row $name_index ]
Deputs "row port name:$name_index"
		set connectionInfo [ ixNet getA $hPort -connectionInfo ]
Deputs "connectionInfo :$connectionInfo"
        set connectionStatus [ixNet getA $hPort -connectionStatus]
		regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
Deputs "chas:$chassis card:$card port:$port"
		set portName ${chassis}/Card${card}/Port${port}
Deputs "filter name: $portName"
		# 192.168.0.110/Card1/Port7
		# 192.168.0.110/Card01/Port07
		#regexp -nocase {([0-9\.]+)/Card([0-9\.]+)/Port([0-9\.]+)} $rowPortName match rchassis rcard rport
		regexp -nocase {([0-9\.]+);([0-9\.]+);([0-9\.]+)} $connectionStatus match rchassis rcard rport
Deputs "rchass:$rchassis rcard:$rcard rport:$rport"
		if { $card < 10 } {
		    set card 0$card
		}
		if { $port < 10 } {
		    set port 0$port
		}
		if {$chassis == $rchassis && $card == $rcard && $port == $rport} {
			set portFound 1
			break
		}
	}	
	
	set ret "Status : true\nLog : \n"
	if { $portFound } {
		set statsItem   "neighbor_count"
		set statsVal    [ lindex $row $nbrslear_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_bootstrap_count"
		set statsVal    [ lindex $row $bspmsgrx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_hello_count"
		set statsVal    [ lindex $row $hellorx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_register_count"
	     set statsVal    [ lindex $row $regrx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_register_stop_count"
		set statsVal    [ lindex $row $regstoprx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_bootstrap_count"
	     set statsVal    [ lindex $row $bspmsgtx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_hello_count"
	     set statsVal    [ lindex $row $hellotx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_register_count"
	     set statsVal    [ lindex $row $regtx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	    
	     set statsItem   "tx_register_stop_count"
	     set statsVal    [ lindex $row $regstoptx_index ]
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
# Can not find in ixNet,so set N/A		
		set statsItem   "rx_assert_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_cand_rp_advert_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_group_rp_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_group_sg_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_group_sgrpt_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_group_starg_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "rx_join_prune_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_assert_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_cand_rp_advert_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_group_rp_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_group_sg_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_group_sgrpt_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_group_starg_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
		set statsItem   "tx_join_prune_count"
		set statsVal    "N/A"
Deputs "stats val:$statsVal"
		set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	}

Deputs "ret:$ret"
	
	return $ret
	
}

body PimSession::send_bsm {} {
	global errorInfo
	global errNumber
	
	set tag "body PimSession::send_bsm [info script]"
Deputs "----- TAG: $tag -----"
    set ipPattern [ixNet getA [ixNet getA $handle -supportUnicastBsm] -pattern]
    SetMultiValues $handle "-supportUnicastBsm" $ipPattern True

	return [GetStandardReturnHeader]
}

body PimGroup::config { args } {
	global errorInfo
	global errNumber
	
	set enabling_pruning NO
	set group_type STARG
	set tag "body PimGroup::config [info script]"
Deputs "----- TAG: $tag -----"

	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-enabling_pruning {
				set value [string toupper $value]
				set enabling_pruning $value
			}
			-group_type {
				set value [string toupper $value]
				set group_type $value
			}
			-rp_ip_addr {			
				set rp_ip_addr $value
			}
			-group {
				set group $value
			}
		}
	}
	if {[string first "ipv4" $hJoinPrune] != -1} {
        set ip_version "ipv4"
    }
    if {[string first "ipv6" $hJoinPrune] != -1} {
        set ip_version "ipv6"
    }

	if { [ info exists enabling_pruning ] } {
		switch $enabling_pruning {						
			NO {
				set enabling_pruning False
			}
			YES {
				set enabling_pruning True				
			}			
		}
		set ipPattern [ixNet getA [ixNet getA $hJoinPrune -active] -pattern]
	    SetMultiValues $hJoinPrune "-active" $ipPattern $enabling_pruning
	}
	
	if { [ info exists group_type ] } {
		#Valid enum values are 1=startorp 2=startogroup 3=sourcetogroup 4=stargtosourcegroup 5=registeredtriggered
		switch $group_type {
			STARG {
				set group_type startogroup
			}
			SG {
				set group_type sourcetogroup
			}	
			STARSTARRP {
				set group_type startorp
			}
		}
		set ipPattern [ixNet getA [ixNet getA $hJoinPrune -rangeType] -pattern]
	    SetMultiValues $hJoinPrune "-rangeType" $ipPattern $group_type
	}

	if { [ info exists rp_ip_addr ] } {
		if { $ip_version == "ipv4" } {
            set ipPattern [ixNet getA [ixNet getA $hJoinPrune -rpV4Address] -pattern]
            SetMultiValues $hJoinPrune "-rpV4Address" $ipPattern $rp_ip_addr
        } else {
            set ipPattern [ixNet getA [ixNet getA $hJoinPrune -rpV6Address] -pattern]
            SetMultiValues $hJoinPrune "-rpV6Address" $ipPattern $rp_ip_addr
        }
	}
	
	if { [ info exists group ] } {
		set group [ GetObject $group ]
		$group configure -handle $hSource
		if { $group == ""} {
			return [GetErrorReturnHeader "No valid object found...-group $group"]
		}
		set source_ip 		[ $group cget -source_ip ]
		set source_num 		[ $group cget -source_num ]
		set group_ip	    [ $group cget -group_ip ]
		set group_num   [ $group cget -group_num ]
		set group_modbit    [ $group cget -group_modbit ]
		if { [info exists source_ip] } {
		    set ipPattern [ixNet getA [ixNet getA $hSource -sourceAddress] -pattern]
            SetMultiValues $hSource "-sourceAddress" $ipPattern $source_ip
		}
		if { [info exists source_num] } {
		    set ipPattern [ixNet getA [ixNet getA $hSource -sourceCount] -pattern]
            SetMultiValues $hSource "-sourceCount" $ipPattern $source_num
		}
		if { [info exists group_ip] } {
		    set ipPattern [ixNet getA [ixNet getA $hSource -groupAddress] -pattern]
            SetMultiValues $hSource "-groupAddress" $ipPattern $group_ip
		}
		if { [info exists group_num] } {
		    set ipPattern [ixNet getA [ixNet getA $hSource -groupCount] -pattern]
            SetMultiValues $hSource "-groupCount" $ipPattern $group_num
		}
		if { [info exists group_modbit] } {
		    if { $ip_version == "ipv4" } {
                set ipPattern [ixNet getA [ixNet getA $hJoinPrune -groupV4MaskWidth] -pattern]
                SetMultiValues $hJoinPrune "-groupV4MaskWidth" $ipPattern $group_modbit
            } else {
                set ipPattern [ixNet getA [ixNet getA $hJoinPrune -groupV6MaskWidth] -pattern]
                SetMultiValues $hJoinPrune "-groupV6MaskWidth" $ipPattern $group_modbit
            }
		}

	} else {
		return [GetErrorReturnHeader "Madatory parameter needed...-group"]
	}
	
	return [GetStandardReturnHeader]
}

body PimGroup::send_join {} {
	global errorInfo
	global errNumber
	
	set tag "body PimGroup::send_join [info script]"
Deputs "----- TAG: $tag -----"
	set ipPattern [ixNet getA [ixNet getA $hJoinPrune -active] -pattern]
	SetMultiValues $hJoinPrune "-active" $ipPattern True

	return [GetStandardReturnHeader]
}

body PimGroup::send_prune {} {
	global errorInfo
	global errNumber
	
	set tag "body PimGroup::send_prune [info script]"
Deputs "----- TAG: $tag -----"
    set ipPattern [ixNet getA [ixNet getA $hJoinPrune -active] -pattern]
	SetMultiValues $hJoinPrune "-active" $ipPattern False

	ixNet commit
	return [GetStandardReturnHeader]
}