# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.7
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.2.3
#		2. Add RouteBlock class for those routing protocols with routes objects
#		3. Add RouterNgpfEmulationObject for those routing protocols with protocol interface properties object
# Version 1.2.2.7
#		4. set handle to null for object reborn
#		5. catch ixNet remove
# Version 1.3.3.1
#		6. add start/stop/enable/disable in EmulationNgpfObject
#		7. add ProtocolNgpfStackObject for those stacked protocols with stack and ethernet stack config
# Version 1.4.unicom.cgn
#		8. add existing stack based ProtocolNgpfStackObject.reborn 
# Version 1.5.11.4
#       9. modify vlan config of ProtocolNgpfStackObject.config
# Version 1.6.4.45
#		10. add multi-thread for flapping_route

class NetNgpfObject {
    public variable handle
    method unconfig {} {
    set tag "body NetNgpfObject::unconfig [info script]"
Deputs "----- TAG: $tag -----"
		catch {
			ixNet remove $handle
			ixNet commit
		}
		set handle ""
		return [ GetStandardReturnHeader ]
	}
}

class EmulationNgpfObject {
    
    inherit NetNgpfObject
    public variable portObj
    public variable hPort
    public variable trafficObj
	method start {} {
		set tag "body EmulationNgpfObject::start [info script]"
Deputs "----- TAG: $tag -----"
		catch {
			foreach h $handle {
				ixNet exec start $h
			}
		}
		return [ GetStandardReturnHeader ]
	}
	
	method stop {} {
		set tag "body EmulationNgpfObject::stop [info script]"
Deputs "----- TAG: $tag -----"
		catch {
			foreach h $handle {
				ixNet exec stop $h
			}
		}
		return [ GetStandardReturnHeader ]
	}
	
	method enable {} {
	    
		set tag "body EmulationNgpfObject::enable [info script]"
Deputs "----- TAG: $tag -----"
		catch {
			ixNet setA [ixNet getA $handle -enabled]/singleValue -value True
			ixNet commit
		}
		return [ GetStandardReturnHeader ]
	}
	
	method disable {} {
		set tag "body EmulationNgpfObject::disable [info script]"
Deputs "----- TAG: $tag -----"
		Deputs "+++ $handle"
		catch {
			ixNet setA [ixNet getA $handle -enabled]/singleValue -value False
			ixNet commit
		}
		return [ GetStandardReturnHeader ]
	}	
	method unconfig {} {
        set tag "body EmulationNgpfObject::unconfig [info script]"
Deputs "----- TAG: $tag -----"
        if { [catch { set hPort "" } err] } {
            Deputs "err: $err" 
        }
		chain 
		#catch { unset hPort }
	}
}

class ProtocolNgpfStackObject {
    inherit EmulationNgpfObject
    public variable stack
    #public variable hPort
    
    method reborn { { onStack null } } {
		set tag "body ProtocolNgpfStackObject::reborn [info script]"
Deputs "----- TAG: $tag -----"
		if { [ info exists hPort ] == 0 || $hPort == "" } {
			if { [ catch {
				set hPort   [ $portObj cget -handle ]
			} ] } {
				error "$errNumber(1) Port Object in DhcpHost ctor"
			}
		}
		
		if { $onStack == "null" } {
            Deputs "new ethernet stack"
			#-- add ethernet stack
			set topoObjList [ixNet getL [ixNet getRoot] topology]
            Deputs "topoObjList: $topoObjList"
            set vportList [ixNet getL [ixNet getRoot] vport]
            if {[llength $topoObjList] != [llength $vportList]} {
                foreach topoObj $topoObjList {
                    set vportObj [ixNet getA $topoObj -vports]
                    foreach vport $vportList {
                        if {$vportObj != $vport && $vport == $hPort} {
                            #if {[llength $topoObj] == 0 } {}
                            if {[llength $topoObjList] < [llength $vportList] && $hPort == [ lindex $vportList end ]} {
                                set sg_ethernet [CreateProtoHandleFromRoot $hPort]
                                set sg_ethernet [ixNet remapIds $sg_ethernet]
                                set stack $sg_ethernet
                            } else {
                                set deviceGroupObj [ixNet getL $topoObj deviceGroup]
                                set sg_ethernet [ixNet getL $deviceGroupObj ethernet]
                                set stack $sg_ethernet
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
                set topoObj [ixNet remapIds $topoObj]
                set deviceGroupObj [ixNet add $topoObj deviceGroup]
                ixNet commit
                ixNet setA $deviceGroupObj -multiplier 1
                ixNet commit
                set sg_ethernet [ixNet add $deviceGroupObj ethernet]
                ixNet commit
                set sg_ethernet [ixNet remapIds $sg_ethernet]
                set sg_ethernet [lindex [ixNet remapIds $sg_ethernet] 0]
                #-- ethernet stack will be used in unconfig to clear all the stack
                set stack $sg_ethernet
            } else {
                foreach topoObj $topoObjList {
                    set vportObj [ixNet getA $topoObj -vports]
                    if {$vportObj == $hPort} {
                        set deviceGroupList [ixNet getL $topoObj deviceGroup]
                        foreach deviceGroupObj $deviceGroupList {
                            set ethernetList [ixNet getL $deviceGroupObj ethernet]
                            set sg_ethernet [lindex [ixNet remapIds $ethernetList] 0]
                            set stack $sg_ethernet
                        }
                    }
                }
            }
		}		
    }
	
    method constructor { port { onStack null } { hProtocol null } } {
		global errorInfo
		global errNumber
        global LoadConfigMode
		set tag "body ProtocolNgpfStackObject::ctor [info script]"
Deputs "----- TAG: $tag -----"
        set portObj [ GetObject $port ]
        if { [ catch {
        	set hPort   [ $portObj cget -handle ]
        } ] } {
        	error "$errNumber(1) Port Object in ProtocolNgpfStackObject ctor"
        }
Deputs "onStack:$onStack" 
        set handle ""       
		# if { $onStack != "null" } {
			# reborn $onStack
		# } else {
			# reborn
		# }
     
        if {  $LoadConfigMode == 0 && $hProtocol == "null"} {
            reborn $onStack
		} 
    }
	
    method config { args } {}
}

body ProtocolNgpfStackObject::config { args } {
	
    global errorInfo
    global errNumber
    set tag "body ProtocolNgpfStackObject::config [info script]"
    Deputs "----- TAG: $tag -----"
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-mac_addr {
                set trans [ MacTrans $value ]
                if { [ IsMacAddress $trans ] } {
                    set mac_addr $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
			}
			-mac_addr_step {
                set trans [ MacTrans $value ]
                if { [ IsMacAddress $trans ] } {
                    set mac_addr_step $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
			}
			-inner_vlan_enable {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set inner_vlan_enable $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-vlan_id2 -
			-inner_vlan_id {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set inner_vlan_id $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set inner_vlan_enable 1
			}
			-vlan_id2_step -
			-inner_vlan_step {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set inner_vlan_step $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set inner_vlan_enable 1
			}
			-inner_vlan_repeat_count {
				if { [ string is integer $value ] && ( $value >= 0 ) } {
					set inner_vlan_repeat_count $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
			}
            -vlan2_per_port -
			-vlan_id2_num -
			-inner_vlan_num {
				if { [ string is integer $value ] && ( $value >= 0 ) } {
					set inner_vlan_num $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set inner_vlan_enable 1                
			}
			-inner_vlan_priority {
                if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 8 ) } {
                    set inner_vlan_priority $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-vlan_presnet -
			-outer_vlan_enable {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set outer_vlan_enable $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-vlan_id1 -
			-vlan_id -
			-outer_vlan_id {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set outer_vlan_id $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set outer_vlan_enable 1
			}
			-vlan_id_step -
			-vlan_id1_step -
			-outer_vlan_step {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 4096 ) } {
					set outer_vlan_step $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set outer_vlan_enable 1
			}
			-vlan_id1_num -
			-vlan_num -
            -vlan1_per_port -
			-outer_vlan_num {
				if { [ string is integer $value ] && ( $value >= 0 ) } {
					set outer_vlan_num $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
                set outer_vlan_enable 1
			}
			-outer_vlan_priority {
				if { [ string is integer $value ] && ( $value >= 0 ) && ( $value < 8 ) } {
					set outer_vlan_priority $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
			}    	
			-outer_vlan_repeat_count {
				if { [ string is integer $value ] && ( $value >= 0 ) } {
					set outer_vlan_repeat_count $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
			}
			-outer_vlan_cfi {			
			}
			-inner_vlan_cfi {
			}
		}
    }
	
    if { $handle == "" } {
	    reborn
        set handle $stack
    }
	
    set range $handle
    set ethernetObj [GetDependentNgpfProtocolHandle $handle "ethernet"]
    if { [ info exists mac_addr ] } {
        ixNet setM [ixNet getA $ethernetObj -mac]/counter -start $mac_addr -direction "increment"
    }
    if { [ info exists mac_addr_step ] } {
        ixNet setM [ixNet getA $ethernetObj -mac]/counter -step $mac_addr_step
    }
    ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value False
    ixNet commit

    if { [ info exists inner_vlan_id ] && [ info exists outer_vlan_id ] } {
	    set vlan_count 2
    } else {
        set vlan_count 1
    }
    ixNet setA $ethernetObj -vlanCount $vlan_count
    ixNet commit
	set version [ixNet getVersion]
	Deputs "The ixNetwork version is: $version"
    if { [ info exists outer_vlan_enable ] || [ info exists outer_vlan_id ] } {

	    if {[string match 6.0* $version]} {
		    #set outer_vlan [ixNet add $range vlanRange]
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
	    }
	}
    
    set vlanCount [ixNet getA $ethernetObj -vlanCount]
    set outerValnObj [lindex [ixNet getL $ethernetObj vlan] 0]
    if { [ info exists outer_vlan_id ] } {
        ixNet setM [ixNet getA $outerValnObj -vlanId]/counter -start $outer_vlan_id -direction increment
        ixNet commit
    }
    
    if { [ info exists outer_vlan_step ] } {
        Deputs "outer_vlan_step:$outer_vlan_step"
        ixNet setA [ixNet getA $outerValnObj -vlanId]/counter -step $outer_vlan_step
    }
    if { [ info exists outer_vlan_repeat_count ] || [ info exists outer_vlan_num ] } {
        ixNet setA [ixNet getA $outerValnObj -vlanId] -pattern custom
        ixNet commit
        set incrementObj [ixNet add [ixNet getA $outerValnObj -vlanId]/custom increment]
        ixNet commit
        if { [ info exists outer_vlan_step ] } {
            ixNet setA $incrementObj -value $outer_vlan_step
        } else {
            ixNet setA $incrementObj -value 1
        }
        set incObj [ixNet add $incrementObj increment]
        ixNet commit
    }
	if { [ info exists outer_vlan_repeat_count ] } {
		ixNet setA $incObj -count $outer_vlan_repeat_count
	}
    
    if { [ info exists outer_vlan_num ] } {
        ixNet setA $incrementObj -count $outer_vlan_num
    }
    
    if { [ info exists outer_vlan_priority ] } {
        ixNet setA [ixNet getA $outerValnObj -priority]/singleValue -value $outer_vlan_priority
    }

	ixNet commit
    set version [ixNet getVersion]
	Deputs "The ixNetwork version is: $version"
    set verval [string match 6.0* $version]
    if { [ info exists inner_vlan_enable ] } {
        Deputs "inner vlan enabled..."

	    if {$verval == 1} {
		    #ixNet setA $ethernetObj -innerEnable True
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setA [ixNet getA $ethernetObj -enableVlans]/singleValue -value True
	    }
    }
    set innerValnObj [lindex [ixNet getL $ethernetObj vlan] end]
    if { [ info exists inner_vlan_id ] } {
	    if {$verval == 1} {
		    #ixNet setA $inner_vlan -innerFirstId $inner_vlan_id
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setM [ixNet getA $innerValnObj -vlanId]/counter -start $inner_vlan_id -direction increment
            ixNet commit
	    }
    }
    
    if { [ info exists inner_vlan_step ] } {
	    if {$verval == 1} {
		    #ixNet setA $inner_vlan -innerIncrement $inner_vlan_step
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setA [ixNet getA $innerValnObj -vlanId]/counter -step $inner_vlan_step
	    }		
    }
    if { [ info exists inner_vlan_repeat_count ] || [ info exists inner_vlan_num ] } {
        ixNet setA [ixNet getA $innerValnObj -vlanId] -pattern custom
        ixNet commit
        set incrementObj [ixNet add [ixNet getA $innerValnObj -vlanId]/custom increment]
        ixNet commit
        if { [ info exists outer_vlan_step ] } {
            ixNet setA $incrementObj -value $inner_vlan_step
        } else {
            ixNet setA $incrementObj -value 1
        }
        set incObj [ixNet add $incrementObj increment]
        ixNet commit
    }
	if { [ info exists inner_vlan_repeat_count ] } {
		if {$verval == 1} {
			#ixNet setA $inner_vlan -innerIncrementStep $inner_vlan_repeat_count
			Deputs "Not implemented for IxNetwork version $version"
		} else {
			ixNet setA $incObj -count $inner_vlan_repeat_count
		}
		
	}
    if { [ info exists inner_vlan_num ] } {
	    if {$verval ==1} {
		    #ixNet setA $inner_vlan -innerUniqueCount $inner_vlan_num
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setA $incrementObj -count $inner_vlan_num
	    }
	
    }
    
    if { [ info exists inner_vlan_priority ] } {
	    if {$verval ==1} {
		    #ixNet setA $inner_vlan -innerPriority $inner_vlan_priority
		    Deputs "Not implemented for IxNetwork version $version"
	    } else {
		    ixNet setA [ixNet getA $innerValnObj -priority]/singleValue -value $inner_vlan_priority
	    }       
    }
    
    ixNet commit
}

class RouterNgpfEmulationObject {
	inherit EmulationNgpfObject
	#-- handle/interface
	public variable interface
	#-- port/interface
	public variable rb_interface
	
	public variable protocol
 	public variable routeBlock
	public variable routeBlock(obj)
	
	public variable flappingProcessId
	
	method start {} {
		set tag "body RouterNgpfEmulationObject::start [info script]"
        Deputs "----- TAG: $tag -----"
		#ixNet exec start $hPort/protocols/$protocol
		ixNet exec startAllProtocols
		return [ GetStandardReturnHeader ]
	}
	
	method stop {} {
		set tag "body BgpSession::start [info script]"
        Deputs "----- TAG: $tag -----"
		#ixNet exec stop $hPort/protocols/$protocol
		ixNet exec stopAllProtocols
		return [ GetStandardReturnHeader ]
	}
	
	method flapping_route { args } {
		set tag "body RouterNgpfEmulationObject::flapping_route [info script]"
        Deputs "----- TAG: $tag -----"
		global loginInfo
		#set a2w 10
		#set w2a 10
		
		Deputs "args: $args"
		foreach { key value } $args {
			set key [string tolower $key]
			switch -exact -- $key {
				-a2w {
					set a2w [ expr $value * 1000 ]
				}
				-w2a {
					set w2a [ expr $value * 1000 ]
				}
				-times {
					set times $value
				}
				-interval {
					set interval $value
				}
				-route_block {
					set rbList $value
					foreach rb $rbList {
						if { ![ $rb isa RouteBlock ] } {
							error "$errNumber(1) argument:-route_block value:$rb"
						}
					}
				}
			}
		}
		if { [ info exists interval ] && [ info exists a2w ] } {
			error "$errNumber(4) -interval -a2w only one key can be used at one time."
		}
		if { ![ info exists rbList ] } {
			set rbList $routeBlock(obj)
		}
		if { [ info exists interval ] } {
			set a2w [ expr $interval * 1000 ]
			set w2a [ expr $interval * 1000 ]
		} else {
			if { ![ info exists a2w ] } {
				set a2w 10000
			}
			if { ![ info exists w2a ] } {
				set w2a 10000
			}
		} 
		if { ![ info exists times ] } {
			package req Thread
			set hFlapList [ list ]
			foreach rb $rbList {
				set hFlap [ $rb cget -handle ]
				lappend hFlapList $hFlap
			}

            Deputs "hFlapList:$hFlapList"
			set id [ thread::create { 
				proc runFlap { hFlapList w2a a2w } {
					while { 1 } {
                        puts "withdraw..."
                        foreach handle $hFlapList {
							ixNet setA $handle -enabled False
						}
						ixNet commit
						after $w2a
                        puts "advertise..."
						foreach handle $hFlapList {
							ixNet setA $handle -enabled True
						}
						ixNet commit
						after $a2w
					}
				}
				proc init { tclServer tclPort version } {
					package req IxTclNetwork
					ixNet connect $tclServer \
						-port $tclPort \
						-version $version
				}
				thread::wait
			} ]		
            Deputs "[ thread::names ]"			
			lappend flappingProcessId $id
			
			global currDir
			global remote_server
			global remote_serverPort
			global ixN_tcl_v
			global ixN_lib
			
            Deputs "version: $ixN_tcl_v"			
            Deputs "server port:$remote_serverPort"			
            Deputs "server:$remote_server"			

			set tclLib $ixN_lib
            Deputs "tcl lib:$tclLib"

			set result \
			[ thread::send $id \
			[ list lappend auto_path $tclLib ] ]
            Deputs "result:$result"
			
			#set result \
			#[ thread::send $id \
			#[ list source "$currDir/ixianet.tcl" ] ]
            #Deputs "result:$result"
			
			set result \
			[ thread::send $id \
			[ list init $remote_server $remote_serverPort $ixN_tcl_v ] ]
            Deputs "init result:$result"

			set result \
			[ thread::send -async $id \
			[ list runFlap $hFlapList $w2a $a2w ] ]
            Deputs "runFlap result:$result"

		} else {
			flappingRouteForTimes $rbList $a2w $w2a $times
		}
		return [ GetStandardReturnHeader ]
		
	}
	method flappingRouteForTimes { routeBlockList a2w w2a times } {
		set tag "body RouterNgpfEmulationObject::flappingRouteAsync [info script]"
        Deputs "----- TAG: $tag -----"

		for { set index 0 } { $index < $times } { incr index } {
			foreach rb $routeBlockList {
				$rb disable
			}

			after $w2a

			foreach rb $routeBlockList {
				$rb enable
			}

			after $a2w

		}		
	}
	method stop_flapping_route {} {
		set tag "body RouterNgpfEmulationObject::flapping_route [info script]"
        Deputs "----- TAG: $tag -----"
    	foreach pid $flappingProcessId {
			thread::release $pid
		}
		return [ GetStandardReturnHeader ]
	}

}

class RouteBlock {
	
	inherit EmulationNgpfObject
	
	public variable num
	public variable start
	public variable step
	public variable prefix_len
	public variable type
	public variable protocol
    public variable origin
    public variable nexthop
    public variable med
    public variable local_pref
    public variable cluster_list
    public variable flag_atomic_agg
    public variable agg_as
    public variable agg_ip
    public variable originator_id
    public variable communities
    public variable flag_label
    public variable label_mode
    public variable user_label
	public variable as_path
    public variable enable_as_path
    public variable as_path_type
    
	
	constructor {} {
		# set num 1
		# set step 1
		# set prefix_len 24
		# set start 100.0.0.1
        set num ""
		set step ""
		set prefix_len ""
		set start ""
		set protocol ""
		set type ""
		set handle ""
        set origin ""
		set nexthop ""
		set med ""
		set local_pref ""
		set cluster_list ""
		set flag_atomic_agg ""
		set agg_as ""
		set agg_ip ""
		set originator_id ""
		set communities ""
		set flag_label ""
		set label_mode ""
		set user_label ""
		set as_path ""
        set enable_as_path ""
        set as_path_type ""
	}
	method config { args } {}
}

body RouteBlock::config { args } {
    global errorInfo
    global errNumber
    set tag "body RouteBlock::config [info script]"
    Deputs "----- TAG: $tag -----"
        
    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -num {
            	set num $value
            }            
            -start {
				if { [ IsIPv4Address $value ] } {
					set type ipv4
				} else {
					set type ipv6
				}
            	set start $value
            }
            -step {
            	set step $value
            }            
            -prefix_len {
            	set prefix_len $value
            }
            -origin {
                set origin $value
            }
            -nexthop {
                set nexthop $value
            }
            -med {
                set med $value
            }
            -local_pref {
                set local_pref $value
            }
            -cluster_list {
                set cluster_list $value
            }
            -flag_atomic_agg {
                set flag_atomic_agg $value
            }
            -agg_as {
                set agg_as $value
            }
            -agg_ip {
                set agg_ip $value
            }
            -originator_id {
                set originator_id $value
            }
            -communities {
                set communities $value
            }
            -flag_label {
                set flag_label $value
            }
            -label_mode {
                set label_mode $value
            }
            -user_label {
                set user_label $value
            }
			-as_path {
                set as_path $value
            }
            -enable_as_path {
                set enable_as_path $value
            }
            -as_path_type {
                set as_path_type $value
            }
        }
    }
	
    return [GetStandardReturnHeader]

}

class Tlv {
	inherit NetNgpfObject
	
	public variable tlv_type
	public variable len
	public variable val
	
	constructor { { t ignore } { v 0 } } { chain lldp } {
		set tlv_type $t
		set val $v
		set len 0
	}
	method config { args } {
		return [GetStandardReturnHeader]
				
	}
}

class Topology {
	
	inherit NetNgpfObject
	public variable type
	public variable router_id_start
	public variable sim_rtr_num
	public variable row_num
	public variable column_num
	public variable attach_column
	public variable attach_row
	
	constructor {} {
		set type grid
		set sim_rtr_num 4
		set row_num 3
		set column_num 3
		set attach_column 1
		set attach_row 1
	}
	method config { args } {}

}

body Topology::config { args } {
    global errorInfo
    global errNumber
    set tag "body Topology::config [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
	set key [string tolower $key]
	switch -exact -- $key {
	    -type {
		    set type [ string tolower $value ]
	    }
	    -router_id_start {
	        set router_id_start $value
	    }
	    -sim_rtr_num {
		    set sim_rtr_num $value
	    }
	    -row_num {
		    set row_num $value
	    }            
	    -column_num {
		    set column_num $value
	    }
	    -attach_column {
		    set attach_column $value
	    }            
	    -attach_row {
		    set attach_row $value
	    }
	}
    }
	
    return [GetStandardReturnHeader]

}

