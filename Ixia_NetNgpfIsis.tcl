
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.14.58
#		2. Add ipv4_addr ipv4_gw ipv4_prefix_len ipv6_addr ipv6_gw ipv6_prefix_len in config
#		3. Add SimulatedRoute class

class IsisSession {
    inherit RouterNgpfEmulationObject
    public variable handle		

	constructor { port { hIsisSession NULL } } {}
    method reborn {} {}
    method config { args } {}
    method get_stats {} {}
    method advertise_topo {} {}
	method withdraw_topo {} {}
    public variable isisObj
	public variable mac_addr
}

body IsisSession::get_stats {} {
    set tag "body IsisSession::get_stats [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]

    puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 30000

	set view {::ixNet::OBJ-/statistics/view:"ISIS-L3 RTR Per Port"}
    set captionList             [ ixNet getA $view/page -columnCaptions ]
    Deputs "caption list:$captionList"
	set port_name				[ lsearch -exact $captionList {Port} ]
    set session_conf            [ lsearch -exact $captionList {Sessions Total} ]
    set session_succ            [ lsearch -exact $captionList {Sessions Up} ]
    set flap         	        [ lsearch -exact $captionList {L2 Session Flap} ]
	
    set ret [ GetStandardReturnHeader ]
	
    set stats [ ixNet getA $view/page -rowValues ]
    Deputs "stats:$stats"

    set connectionInfo [ ixNet getA $hPort -connectionInfo ]
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
        Deputs "checking ${chassis}/Card${card}/Port${port} with [ lindex $row $port_name ]"

        ## Check disabled by Sreekanth as the user can't pass in the same naming convention
        ## So, failing when comparing 10.39.71.180/Card01/Port01 with ::port25
		# if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
		# 	continue
		# }

        set statsItem   "session_conf"
        set statsVal    [ lindex $row $session_conf ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "session_succ"
        set statsVal    [ lindex $row $session_succ ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "flap"
        set statsVal    [ lindex $row $flap ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        Deputs "ret:$ret"
    }
    return $ret
}

body IsisSession::reborn {} {
	global errNumber

	set tag "body IsisSession::reborn [info script]"
    Deputs "----- TAG: $tag -----"
    if { [ catch {
        set hPort   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in IsisSession ctor"
    }
	
	#-- add interface and isis protocol
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    Deputs "topoObjList: $topoObjList"
    set vportList [ixNet getL [ixNet getRoot] vport]
    #set vport [ lindex $vportList end ]
    if {[llength $topoObjList] != [llength $vportList]} {
        foreach topoObj $topoObjList {
            #set vportObj [ixNet getA $topoObj -vports]
            #foreach vport $vportList {
            #    if {$vportObj != $vport && $vport == $hPort} {
            #        set ethernetObj [CreateProtoHandleFromRoot $hPort]
            #    }
            #}
            #break
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
                    }
				}
			}
            break
        }
    }
    array set routeBlock [ list ]
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    if { [ llength $topoObjList ] == 0 } {
        set handle [CreateProtoHandleFromRoot $hPort isisL3]
        ixNet setA $handle -name $this
    } elseif { [ llength $topoObjList ] != 0 } {
        foreach topoObj $topoObjList {
  		    set vportObj [ixNet getA $topoObj -vports]
            if {$vportObj == $hPort} {
                set deviceGroupList [ixNet getL $topoObj deviceGroup]
                foreach deviceGroupObj $deviceGroupList {
	 				set ethernetList [ixNet getL $deviceGroupObj ethernet]
					foreach ethernetObj $ethernetList {
                        set handle [ixNet getL $ethernetObj isisL3]
						if {[ llength $handle ] == 0 } {
						    set handle [ixNet add $ethernetObj isisL3]
						    ixNet commit
                            set handle [ ixNet remapIds $handle ]
                            ixNet setA $handle -name $this
						}
                    }
                }
            }
        }
    }

	ixNet commit
    #Enable vlan 
    set ethernetObj [GetDependentNgpfProtocolHandle $handle "ethernet"]
	ixNet setA [ixNet getA  $ethernetObj -enableVlans]/singleValue -value "true"
	ixNet commit
}

body IsisSession::constructor { port { hIsisSession NULL } } {
    set tag "body IsisSession::constructor [info script]"
    Deputs "----- TAG: $tag -----"
	
    global errNumber
	set handle ""

    #-- enable protocol
    set portObj [ GetObject $port ]
    Deputs "port:$portObj"
    if { [ catch {
	    set hPort   [ $portObj cget -handle ]
        Deputs "port handle: $hPort"
    } ] } {
	    error "$errNumber(1) Port Object in IsisSession ctor"
    }
    Deputs "initial port..."
	if { $hIsisSession == "NULL" } {
        set hIsisSession [GetObjNameFromString $this "NULL"]
    }
    Deputs "----- hIsisSession: $hIsisSession, hPort: $hPort -----"
    if { $hIsisSession != "NULL" } {
        set handle [GetValidNgpfHandleObj "isis" $hIsisSession $hPort]
        Deputs "----- handle: $handle -----"
        if { $handle != "" } {
            set handleName [ ixNet getA $handle -name ] 
        }
    }
    if { ![info exists handle] || $handle == ""} {
     
        set handleName $this
        set handle ""
        reborn
    }
}

body IsisSession::config { args } {
    set tag "body IsisSession::config [info script]"
    global errNumber
	Deputs "----- TAG: $tag -----"
	
	set sys_id "64:01:00:01:00:00"
    # in case the handle was removed
    if { $handle == "" } {
	    reborn
    }
	set ip_version "ipv4"
	Deputs "Args:$args "
    foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-localSystemID -
			-sys_id - 
			-system_id {
				set sys_id $value
			}
			-network_type {
				set value [string tolower $value]
					switch $value {
					p2p {
						set value pointpoint
					}
					default {
						set value broadcast
					}
				}
				set network_type $value
			}
            -discard_lsp {
            	set discard_lsp $value
            }
			-enable_wide_metric {
				set enable_wide_metric $value
			}
            -interface_metric -
            -metric {
            	set metric $value
            }
            -hello_interval {
            	set hello_interval $value  	    	
            }
            -dead_interval {
            	set dead_interval $value  	    	
            }
            -vlan_id {
            	set vlan_id $value
            }
            -lsp_refreshtime {
            	set lsp_refreshtime $value
            }
            -lsp_lifetime {
            	set lsp_lifetime $value
            }
			-mac_addr {
                set value [ MacTrans $value ]
                if { [ IsMacAddress $value ] } {
                    set mac_addr $value
                } else {
                   Deputs "wrong mac addr: $value"
                    error "$errNumber(1) key:$key value:$value"
                }
				
			}
			-ipv6_addr {
				set ipv6_addr $value
			}
			-ipv6_gw {
				set ipv6_gw $value
			}
			-ipv6_prefix_len {
				set ipv6_prefix_len $value
			}
			-ip_version {
				set ip_version $value
			}
			-level {
				set level $value
			}
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_prefix_len {
				set ipv4_prefix_len $value
			}
			-ipv4_gw {
				set ipv4_gw $value
			}
		}
    }
    #set isisRouter [GetDependentNgpfProtocolHandle $handle "isisL3Router"]
	set deviceGroupObj [GetDependentNgpfProtocolHandle $handle deviceGroup]
	set isisRouter [ixNet getL $deviceGroupObj "isisL3Router"]
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObjList [ixNet getL $topoObj deviceGroup]
            foreach deviceGroupObj $deviceGroupObjList {
                set ethernetObj [ixNet getL $deviceGroupObj ethernet]
                set ipv4Obj [ixNet getL $ethernetObj ipv4]
                set ipv6Obj [ixNet getL $ethernetObj ipv6]

                if { [ info exists ip_version ] } {
                    if { [ string tolower $ip_version ] == "ipv6" } {

                        if {[llength $ipv6Obj] == "0"} {
                           set ipv6Obj [ixNet add $ethernetObj ipv6]
                           ixNet commit
                        }
                    } elseif {[ string tolower $ip_version ] == "ipv4" } {
                        if {[llength $ipv4Obj] == "0"} {
                            set ipv4Obj [ixNet add $ethernetObj ipv4]
                            ixNet commit
                        }

                    }
                }
				
				if { [ info exists ipv4_addr ] } {
                    if { $ip_version == "ipv4" } {
                        Deputs "ipv4: [ixNet getL $ethernetObj ipv4]"
                        set ipv4Obj [ixNet getL $ethernetObj ipv4]
						
                        ixNet setA [ixNet getA $ipv4Obj -address]/singleValue -value $ipv4_addr
                        ixNet commit
                    } 
                }
				
                if { [ info exists ipv6_addr ] } {
                    if { $ip_version == "ipv6" } {                   
                        Deputs "ipv6: [ixNet getL $ethernetObj ipv6]"
                        Deputs "interface:$ethernetObj"
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
                        ixNet commit
                    }
               	}		
				
                if { [ info exists ipv4_gw ] } {
                    if { $ip_version == "ipv4" } {
                        set ipv4Obj [ixNet getL $ethernetObj ipv4]
                        ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/singleValue  -value $ipv4_gw
                        ixNet commit
                    }
                }

                if { [ info exists ipv6_gw ] } {
                    if { $ip_version == "ipv6" } {
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/singleValue -value $ipv6_gw
                        ixNet commit
                    }
                }
				
				if { [ info exists ipv4_prefix_len ] } {
                    if {$ip_version == "ipv4"} {
                    if {$ipv4_prefix_len == "255.0.0.0"} {
                        set pLen 8						
                    } elseif  {$ipv4_prefix_len == "255.255.0.0"} {
                        set pLen 16
                    } elseif  {$ipv4_prefix_len == "255.255.255.0"} {
                        set pLen 24
                    } else {
                        set pLen 32
                    }
                
                    ixNet setA [ixNet getA $ipv4Obj -prefix]/singleValue -value $pLen
                    ixNet commit
				   }
                }
				
 				if { [ info exists ipv6_prefix_len ] } {
                    if { $ip_version == "ipv6" } {
			
					    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -prefix]/singleValue -value $ipv6_prefix_len
                        ixNet commit
					}
                }               
            
            
                if { [ info exists mac_addr ] } {
                    ixNet setA [ixNet getA $ethernetObj -mac]/singleValue -value $mac_addr
                    ixNet commit
                }
                if { [ info exists loopback_ipv4_addr ] } {
                    Deputs "not implemented parameter: loopback_ipv4_addr"
                }

				if { [ info exists vlan_id ] } {
				    set vlanObj [ixNet getL $ethernetObj vlan]
					if {$vlanObj == ""} {
					    set vlanObj [ixNet add $ethernetObj vlan]
					}
				    ixNet setA [ixNet getA $vlanObj -vlanId]/singleValue -value $vlan_id
                }	

	            if { [ info exists level ] } {
				
		            switch [ string tolower $level ] {
				        l1 {
				           set level level1
			            }
					    l2 {
				           set level level2
			            }
			            l12 {
				           set level l1l2
			            }
		            }
		             ixNet setA [ixNet getA $handle -levelType]/singleValue -value $level
	            }
	
                if { [ info exists sys_id ] } {
	               set bridgeDataObj [ixNet getL $deviceGroupObj bridgeData]
		           if {[ llength $bridgeDataObj ] == 0} {
				      set bridgeDataObj [ixNet add $deviceGroupObj bridgeData]
				   }
				   regsub -all {:} $sys_id { } {sys_id}
                   set sys_id \{$sys_id\}
				   
				   ixNet setA [ixNet getA  $bridgeDataObj -systemId]/singleValue -value $sys_id
                   ixNet commit 
                }
				
				if { [ info exists enable_wide_metric ] } {
				    ixNet setA [ixNet getA $isisRouter -enableWideMetric]/singleValue -value $enable_wide_metric
                }
				
				if { [ info exists network_type ] } {
	                ixNet setA [ixNet getA $handle -networkType]/singleValue -value $network_type
                }

                if { [ info exists hello_interval ] } {
	                ixNet setA [ixNet getA $handle -level1HelloInterval]/singleValue -value $hello_interval

                }	

                if { [ info exists discard_lsp ] } {
				    ixNet setA [ixNet getA $isisRouter -discardLSPs]/singleValue -value $discard_lsp

                }
                if { [ info exists metric ] } {
			         ixNet setA [ixNet getA $handle -interfaceMetric]/singleValue -value $metric

                }

                if { [ info exists dead_interval ] } {
		            ixNet setA [ixNet getA $handle -level1DeadInterval]/singleValue -value $dead_interval


                }
                if { [ info exists lsp_refreshtime ] } {
				     ixNet setA [ixNet getA $isisRouter -lSPRefreshRate]/singleValue -value $lsp_refreshtime

                }
                if { [ info exists lsp_lifetime ] } {
		            ixNet setA [ixNet getA $isisRouter -lSPLifetime]/singleValue -value $lsp_lifetime

                } 
                ixNet commit
	        }
	    }
	}

    ixNet commit
	return [GetStandardReturnHeader]

}

body IsisSession::advertise_topo {} {

	set tag "body IsisSession::advertise_topo [info script]"
    Deputs "----- TAG: $tag -----"

    set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
    set networkGroupList [ixNet getL $deviceGroupObj networkGroup]
    foreach networkGroupObj $networkGroupList {
        ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value true
    }
    ixNet commit
    return [GetStandardReturnHeader]
}
body IsisSession::withdraw_topo {} {

	set tag "body IsisSession::withdraw_topo [info script]"
    Deputs "----- TAG: $tag -----"

    set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
    set networkGroupList [ixNet getL $deviceGroupObj networkGroup]
    foreach networkGroupObj $networkGroupList {
        ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value false
    }
	ixNet commit
    return [GetStandardReturnHeader]
}

class SimulatedRoute {
    inherit EmulationNgpfObject
	public variable deviceGroupObj
    public variable isisObj
    public variable isisHandle
    public variable portObj
    public variable hPort
	
	constructor { router } {
        set isisObj [GetObject $router]
        set isisHandle [$isisObj cget -handle]
        set deviceGroupObj [GetDependentNgpfProtocolHandle $isisHandle "deviceGroup"]
        set portObj [ $router cget -portObj ]
		set hPort [ $router cget -hPort ]
    }
	method config { args } {}
}

body SimulatedRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimulatedRoute::config [info script]"
    Deputs "----- TAG: $tag -----"
        # eval chain $args
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
                -route_type {
                    set route_type $value
                }
            }
        }

            if { [ info exists route_type ] } {
                if { [ string tolower $route_type ] == "internal" } {
                    set route_origin false
                } else {
                    set route_origin true
                }
            
                set deviceGroupObj [GetDependentNgpfProtocolHandle $isisHandle "deviceGroup" ]
                set networkGroupObjList [ixNet getL $deviceGroupObj "networkGroup"]
                set networkGroupObj ""
                foreach networkObj $networkGroupObjList {
                    set ipv4PoolObj [ixNet getL $networkObj ipv4PrefixPools]
                    set ipv6PoolObj [ixNet getL $networkObj ipv6PrefixPools]
                    if {$ipv4PoolObj != ""} {
                        if {[ixNet getL $ipv4PoolObj isisL3RouteProperty] != ""} {
                            set networkGroupObj networkObj
                            break
                        }
                    }
                    if {$ipv6PoolObj != ""} {
                        if {[ixNet getL $ipv6PoolObj isisL3RouteProperty] != ""} {
                            set networkGroupObj networkObj
                            break
                        }
                    }
                }

                if {[llength $networkGroupObj] == 0} {
                    set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
                    ixNet commit
                    set networkGroupObj [ixNet remapIds $networkGroupObj]
                }

                set rb [ GetObject $route_block ]
                $route_block configure -protocol "isis"
                
                if { $rb == "" } {
                    return [GetErrorReturnHeader "No object found...-route_block"]
                }
                
                set num 		[ $rb cget -num ]
                set start 		[ $rb cget -start ]
                set step		[ $rb cget -step ]
                set prefix_len	[ $rb cget -prefix_len ]

                Deputs "num:$num start:$start step:$step prefix_len:$prefix_len"
                ixNet setA $networkGroupObj -multiplier $num
                ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value True
                ixNet commit

                set ipv6PoolObj ""
                set ipv4PoolObj ""
                if {[string first ":" $start] != -1} {
                    set ipv6PoolObj [ixNet getL $networkGroupObj ipv6PrefixPools]
                    if {[llength $ipv6PoolObj] == 0} {
                        set ipv6PoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
                        ixNet commit
                        set ipv6PoolObj [ ixNet remapIds $ipv6PoolObj ]
                    }
                    set ipPoolObj $ipv6PoolObj
                    set connector [ixNet add $ipv6PoolObj connector]
                    ixNet setA $connector -connectedTo $isisHandle
                    ixNet commit
                }
                if {[string first "." $start] != -1} {
                    set ipv4PoolObj [ixNet getL $networkGroupObj "ipv4PrefixPools"]
                    if {[llength $ipv4PoolObj] == 0} {
                        set ipv4PoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
                        ixNet commit
                        set ipv4PoolObj [ ixNet remapIds $ipv4PoolObj ]
                    }
                    set ipPoolObj $ipv4PoolObj
                    set connector [ixNet add $ipv4PoolObj connector]
                    ixNet setA $connector -connectedTo $isisHandle
                    ixNet commit
                }
                ixNet commit
                if {[info exists metric]} {
                    if {[info exists ipv4PoolObj] && $ipv4PoolObj != ""} {
                        set isisRoutePropObj [ixNet getL $ipv4PoolObj isisL3RouteProperty]
                        ixNet setA [ixNet getA $isisRoutePropObj -metric]/singleValue -value $metric
                    }
                    if {[info exists ipv6PoolObj] && $ipv6PoolObj != ""} {
                        set isisRoutePropObj [ixNet getL $ipv6PoolObj isisL3RouteProperty]
                        ixNet setA [ixNet getA $isisRoutePropObj -metric]/singleValue -value $metric
                    }
                }
                if {[string first ":" $start] != -1} {
                    ixNet setM [ixNet getA $ipv6PoolObj -networkAddress]/counter -start $start -direction increment
                    ixNet commit
                }
                if {[string first "." $start] != -1} {
                    ixNet setM [ixNet getA $ipv4PoolObj -networkAddress]/counter -start $start -direction increment
                    ixNet commit
                }
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
                set handle $networkGroupObj
                ixNet commit
                
                $rb configure -handle $handle
                $rb configure -portObj $portObj
                $rb configure -hPort $hPort
                $rb configure -protocol "isis"
                $rb enable
                
                set routeBlock($rb,handle) $handle
                lappend routeBlock(obj) $rb

            } else {
                return [GetErrorReturnHeader "Madatory parameter needed...-route_block"]
            }

        if {[info exists ipv4PoolObj] && [llength $ipv4PoolObj]} {
            set isisRoutePropObj [ixNet getL $ipv4PoolObj isisL3RouteProperty]
            ixNet setA $isisRoutePropObj -routeOrigin $route_origin
            set connector [ixNet add $ipv4PoolObj connector]
            ixNet setA $connector -connectedTo $isisHandle
            ixNet commit
        }

        if {[info exists ipv6PoolObj] && [llength $ipv6PoolObj]} {
            set isisRoutePropObj [ixNet getL $ipv6PoolObj isisL3RouteProperty]
            ixNet setA $isisRoutePropObj -routeOrigin $route_origin
            set connector [ixNet add $ipv6PoolObj connector]
            ixNet setA $connector -connectedTo $isisHandle
            ixNet commit
        }
        
    ixNet commit
}