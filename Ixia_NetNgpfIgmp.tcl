
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.3
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1
#		2. Add MulticastGroup class
# Version 1.2
#		3. Add join_group method
# Version 1.3 
#       4. Add MldOverPppoeHost
#       5. Modify IgmpOverPppoeHost

class IgmpHost {
    inherit EmulationNgpfObject
    public variable igmpTrigger
    public variable igmpTunnelObj
    	
    constructor { port { hIgmp NULL } {onStack NULL}} {}
	method reborn { {version ipv4} } {
        set tag "body IgmpHost::reborn [info script]"
        Deputs "----- TAG: $tag -----"
        set ip_version $version
        if { [ catch {
			set hPort   [ $portObj cget -handle ]
		} ] } {
			error "$errNumber(1) Port Object in DhcpHost ctor"
		}

		#-- enable igmp emulation
        Deputs "hPort: $hPort"
        if {[info exists igmpTrigger]} {
            set triggerHandle [$igmpTrigger cget -handle]
            # set result [regexp {dhcpv(\d+)} $triggerHandle dhcpHandle dhcpVersion]
            
            set result [regexp {dhcpv(\d+)} $triggerHandle dhcpHandle dhcpVersion]
            if {[info exists dhcpVersion]} {
                if {$dhcpVersion == 4} {
                    set handle [ixNet add $triggerHandle igmpHost]
                } else {
                    set handle [ixNet add $triggerHandle mldHost]
                }
            }
            set result [regexp {(pppoxclient)} $triggerHandle pppoxHandle pppoxClient]
            if {[info exists pppoxClient]} {
                ## ncpType can be configured using parameter ipcp_encap
                # set ncpType [ixNet getA [ixNet getA $triggerHandle -ncpType]/singleValue -value]
                # if {$ncpType == "ipv4"} {
                    set result [regexp {(igmp)} $igmpTunnelObj protocolType tunnelProtocol]
                    if {$tunnelProtocol == "igmp"} {
                        set handle [ixNet add $triggerHandle igmpHost]
                    } elseif {$tunnelProtocol == "mld"} {
                        set handle [ixNet add $triggerHandle MldHost]
                    }
                #     Deputs "Yet to work on dual stack !!!"
                # }
            }

            ixNet commit
            set handle [IxNet remapIds $handle]
            ixNet setA $handle -name $this
            # $this configure -version $ip_version
	        set protocol igmp
            return
        }

        set igmpObj ""
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        Deputs "topoObjList: $topoObjList"
        set vportList [ixNet getL [ixNet getRoot] vport]
        set vport [ lindex $vportList end ]
        if {[llength $topoObjList] != [llength $vportList]} {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj != $vport && $vport == $hPort} {
                    set ethernetObj [CreateProtoHandleFromRoot $hPort]
                #     set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                #     set deviceGroupObj [ixNet add $topoObj deviceGroup]
				#     set deviceGroupObj [ ixNet remapIds $deviceGroupObj ]
                #     set ethernetObj [ixNet add $deviceGroupObj ethernet]
                #     ixNet commit
                    if { $ip_version == "ipv4" } {
                        set ipv4Obj [ixNet add $ethernetObj ipv4]
                        set ipv4Obj [ ixNet remapIds $ipv4Obj ]
                        set ipHandle $ipv4Obj
					    ixNet commit
                    }
                }
                break
            }
        }

        array set routeBlock [ list ]
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        if { [ llength $topoObjList ] == 0 } {
            set handle [CreateProtoHandleFromRoot $hPort igmpHost ipv4]
            set ipHandle [GetDependentNgpfProtocolHandle $handle ip]
            ixNet setA $handle -name $this
            ixNet commit
        } elseif { [ llength $topoObjList ] != 0 } {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        foreach ethernetObj $ethernetList {
                            if { $ip_version == "ipv4" } {
                                set ipv4Obj [ixNet getL $ethernetObj ipv4]
                                if {[llength $ipv4Obj] != 0} {
                                    set ipv4Obj [ ixNet remapIds $ipv4Obj ]
                                    set ipHandle $ipv4Obj
                                }
                            } elseif {$ip_version == "ipv6"} {
                                set ipv6Obj [ixNet getL $ethernetObj ipv6]
                                if {[llength $ipv6Obj] != 0} {
                                    set ipv6Obj [ ixNet remapIds $ipv6Obj ]
                                    set ipHandle $ipv6Obj
                                }
                            } else {
                                error "unknown ip_version $ip_version"
                                return
                            }
                            Deputs "Adding igmpHost ipversion received is $ip_version"
                            set handle [ixNet add $ipHandle igmpHost]
                            ixNet commit
                            set handle [ixNet remapIds $handle]
                            ixNet setA $handle -name $this
                        }
                    }
                }
            }
        }
        # ixNet setA $handle -descriptiveName $this
        #Setting to 1 default number of device 
	    # ixNet setA $deviceGroupObj -multiplier "1"
	    ixNet commit
        # $this configure -version $ip_version
	    set protocol igmp
	}
    method config { args } {}
	method unconfig {} {
		set tag "body IgmpHost::unconfig [info script]"
        Deputs "----- TAG: $tag -----"
		set interface [ list ]
		set group_list	[ list ]
		array set group_handle [list]
		catch {
            Deputs Step10		
            foreach hIgmp $handle {
				ixNet remove $hIgmp
			}
		ixNet commit
		}
		set handle ""
	}
    
    method join_group { args } {}
    method leave_group { args } {}
    method get_group_stats { args } {}
    method get_host_stats { args } {}
    
	public variable count
    public variable ipaddr
    public variable ipaddr_step
    public variable vlan_id1_step
    public variable vlan_id2_step
	public variable interface
	public variable group_list
	public variable group_handle
	public variable view
    public variable ipHandle
}

body IgmpHost::constructor { port { hIgmp NULL } {onStack NULL}} {
    global errNumber
    
    set tag "body IgmpHost::ctor [info script]"
    Deputs "----- TAG: $tag -----"

    if {$hIgmp != "NULL"} {
        Deputs "check the value of hIgmp $hIgmp"
        set igmpTrigger $hIgmp
    }
    if {$onStack != "NULL"} {
        Deputs "check the value of hIgmp $hIgmp"
        set igmpTrigger $onStack
    }
    set igmpTunnelObj $hIgmp
    set portObj [ GetObject $port ]
    set hPort [ $portObj cget -handle ]
    set count 		1
    set ipaddr_step 	0.0.0.1
    set vlan_id1_step	1
    set vlan_id2_step	1
	set interface [ list ]
	set group_list	[ list ]
	array set group_handle [list]

	set handle ""
    set view {::ixNet::OBJ-/statistics/view:"IGMP Host Per Port"}
    Deputs "view:$view"
    if { $hIgmp == "NULL" } {
        set hIgmp [GetObjNameFromString $this "NULL"]
    }
    Deputs "----- hIgmp: $hIgmp, hPort: $hPort -----"
    if { $hIgmp != "NULL" } {
        set handle [GetValidNgpfHandleObj "igmp_host" $hIgmp $hPort]
        Deputs "----- handle: $handle -----"
        if { $handle != "" } {
            set protocol igmp
            set handleName [ ixNet getA $handle -name ] 
        } 
    }
    
    if { $handle == "" } {
        set handleName $this           
        reborn
    }
}

body IgmpHost::config { args } {
    global errorInfo
    global errNumber
    # set version version2
    set tag "body IgmpHost::config [info script]"
	Deputs "----- TAG: $tag -----"
	if { $handle == "" } {
		reborn
	}
	#param collection
	Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -force_leave {
                ## Unused option, even in classic
            	set force_leave $value
            }
            -force_robust_join {			
                ## Unused option, even in classic
            	set force_robust_join $value
            }
            -insert_checksum_errors {
                ## Unused option, even in classic
            	set insert_checksum_errors $value
            }
            -insert_length_errors {
                ## Unused option, even in classic
            	set insert_length_errors $value
            }
            -ipv4_dont_fragment  {
                ## Unused option, even in classic
            	set ipv4_dont_fragment  $value
            }
            -pack_reports {
                ## Unused option, even in classic
            	set pack_reports $value
            }
            -robustness_variable {
                ## Unused option, even in classic
            	set robustness_variable $value
            }
            -v1_router_present_timeout {
                ## Unused option, even in classic
            	set v1_router_present_timeout $value
            }
            -version {
            	set version $value
            }
            -ipaddr -
			-ipv6_addr -
			-ipv4_addr {
            	set ipaddr $value
            }
            -ipaddr_step -
			-ipv4_addr_step {
            	set ipaddr_step $value
            }
            -count {
                ## Unused option, even in classic
            	set count $value
            }
			-ipv6_gw {
                ## Unused option, even in classic
            	set ipgw $value
            }
			-outer_vlan_id -
            -vlan_id1 {
            	set vlan_id1 $value
            }
			-outer_vlan_step -
            -vlan_id1_step {
            	set vlan_id1_step $value
            }
			-inner_vlan_id -
            -vlan_id2 {
            	set vlan_id2 $value
            }
			-inner_vlan_step -
            -vlan_id2_step {
            	set vlan_id2_step $value
            }
			-group_specific {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
					set group_specific $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-general_query {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
				set general_query $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-router_alert {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
					set router_alert $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-unsolicited {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
					set unsolicited $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
            -unsolicited_report_interval {
            	set unsolicited_report_interval $value
            }
		}
    }

    # Deputs "check the value of igmpTrigger as $igmpTrigger"
    if {[info exists igmpTrigger]} {
        foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            ## Unused option, even in classic
            set groupList $value
            # set group $value
            }
        }
        foreach group $groupList {
        Deputs Step10
        if { [ $group isa MulticastGroup ] == 0 } {
            return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
        }
        set grpIndex [ lsearch $group_list $group ]
        if { $grpIndex >= 0 } {
            Deputs Step30
            foreach hIgmp $handle {
                set hGroup	$group_handle($group,$hIgmp)
                ixNet setA $hGroup -enabled True
                ixNet commit
            }
        } else {
            Deputs Step40
            set filter_mode [ $group cget -filter_mode ]
            set group_ip [ $group cget -group_ip ]
            set group_num [ $group cget -group_num ]
            set group_step [ $group cget -group_step ]
            set group_modbit [ $group cget -group_modbit ]
            set source_ip [ $group cget -source_ip ]
            set source_num [ $group cget -source_num ]
            set source_step [ $group cget -source_step ]
            set source_modbit [ $group cget -source_modbit ]
            Deputs "=group prop= filter_mode:$filter_mode group_ip:$group_ip group_num:$group_num group_step:$group_step group_modbit:$group_modbit source_ip:$source_ip source_num:$source_num source_step:$source_step source_modbit:$source_modbit"
            Deputs Step45
            Deputs "handle:$handle"
            foreach hIgmp $handle {

                if {[regexp {(igmpHost)} $hIgmp igmp igmpHandle] != 0} {
                    set hGroup [ ixNet getL $hIgmp igmpMcastIPv4GroupList]
                    set hSource [ixNet getL $hGroup igmpUcastIPv4SourceList]

                    if {[info exists source_step] && $source_step != ""} {
                        if { [ IsIPv6Address $source_step ] } {
                            set source_step "0.0.0.1"
                        }
                    }
                } elseif {[regexp {(mldHost)} $hIgmp mld mldHandle] != 0} {

                    set hGroup [ ixNet getL $hIgmp mldMcastIPv6GroupList]
                    set hSource [ixNet getL $hGroup mldUcastIPv6SourceList]

                    if {[info exists source_ip] && $source_ip == "0.0.0.0"} {
                        set source_ip "aaaa:0:0:0:0:0:0:0"
                    }
                    if {[info exists source_step] && $source_step != ""} {
                        if { [ IsIPv4Address $source_step ] } {
                            set source_step "0:0:0:0:0:0:0:1"
                        }
                    }

                } else {
                    Deputs "didn't match with Igmp or Mld for handle $handle"
                }

                Deputs "group handle retrieved from igmp handle is $hGroup"
                # ixNet setM $hSource \
                #     -sourceRangeCount $source_num \
                #     -sourceRangeStart $source_ip
                # ixNet setA [ixNet getA $hGroup -startMcastAddr]/singleValue -value $group_ip
                set pattern  [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
                SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip
                ixNet commit

                if {[info exists source_ip]} {
                    # ixNet setA [ixNet getA $hSource -startUcastAddr]/singleValue -value $source_ip
                    set pattern  [ixNet getA [ixNet getA $hSource -startUcastAddr] -pattern]
                    SetMultiValues $hSource "-startUcastAddr" $pattern $source_ip
                }
                if {[info exists source_step]} {
                    set pattern  [ixNet getA [ixNet getA $hSource -ucastAddrIncr] -pattern]
                    SetMultiValues $hSource "-ucastAddrIncr" $pattern $source_step
                }
                if {[info exists source_num]} {
                    # ixNet setA [ixNet getA $hSource -ucastSrcAddrCnt]/singleValue -value $source_num
                    set pattern  [ixNet getA [ixNet getA $hSource -ucastSrcAddrCnt] -pattern]
                    SetMultiValues $hSource "-ucastSrcAddrCnt" $pattern $source_num
                }
            ixNet commit
            }
        }
        }
        }
    return
    }
    set ip_addr [ixNet getA [ixNet getA $ipHandle -address]/singleValue -value]
            # set pattern  [ixNet getA [ixNet getA $ipHandle -address] -pattern]
            # SetMultiValues $ipHandle "-address" $pattern $value
    if {![info exists ipaddr]} {
        Deputs "no configurable Ip Address found of IgmpHost.. returning"
        return
    }
    if {$ip_addr == $ipaddr} {
        set matched_int ipHandle
    }
    if {[info exists matched_int]} {
        Deputs "found matched Ip interface"
        set int $matched_int
    } else {
        Deputs "no matching Ip interface found, calling host class"
        if { [ GetObject $this.host ] == "" } {
            Host $this.host $portObj
        }
        Deputs "args:$args"
        eval {$this.host} config $args
        set int [ $this.host cget -handle ]
    }

    ixNet commit

	foreach h $handle {
		if { [ info exists version ] } {
            if {$version == "v1" || $version == "version1"} {
                set ixversion version1
			}
            if {$version == "v2" || $version == "version2"} {
                set ixversion version2
			}
            if {$version == "v3" || $version == "version3"} {
                set ixversion version3
			}
			    # ixNet setA $h -version $ixversion
            # ixNet setA [ixNet getA $h -versionType]/singleValue -value $ixversion
            set pattern  [ixNet getA [ixNet getA $h -versionType] -pattern]
            SetMultiValues $h "-versionType" $pattern $ixversion
            # ixNet commit
		}
		if { [ info exists group_specific ] } {
			# ixNet setA $h -sqResponseMode $group_specific
            # ixNet setA [ixNet getA $h -gSResponseMode]/singleValue -value $group_specific
            set pattern  [ixNet getA [ixNet getA $h -gSResponseMode] -pattern]
            SetMultiValues $h "-gSResponseMode" $pattern $group_specific
		}
		if { [ info exists general_query ] } {
            # ixNet setA [ixNet getA $h -gQResponseMode]/singleValue -value $general_query
            set pattern  [ixNet getA [ixNet getA $h -gQResponseMode] -pattern]
            SetMultiValues $h "-gQResponseMode" $pattern $general_query
			# ixNet setA $h -gqResponseMode $general_query
		}
		if { [ info exists router_alert ] } {
			# ixNet setA $h -routerAlert $router_alert
            # ixNet setA [ixNet getA $h -routerAlert]/singleValue -value $router_alert
            set pattern  [ixNet getA [ixNet getA $h -routerAlert] -pattern]
            SetMultiValues $h "-routerAlert" $pattern $router_alert
		}
		if { [ info exists unsolicited ] } {
            # ixNet setA [ixNet getA $h -uSResponseMode]/singleValue -value $unsolicited
            set pattern  [ixNet getA [ixNet getA $h -uSResponseMode] -pattern]
            SetMultiValues $h "-reportFreq" $pattern $unsolicited
			# ixNet setA $h -upResponseMode $unsolicited
		}
		if { [ info exists unsolicited_report_interval ] } {
			# ixNet setA $h -reportFreq $unsolicited_report_interval
            # ixNet setA [ixNet getA $h -reportFreq]/singleValue -value $unsolicited_report_interval
            set pattern  [ixNet getA [ixNet getA $h -reportFreq] -pattern]
            SetMultiValues $h "-reportFreq" $pattern $unsolicited_report_interval
		}
		ixNet commit
	}
    	
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	return [ GetStandardReturnHeader ]	
}

class MulticastGroup {

	inherit EmulationNgpfObject

	public variable filter_mode
	public variable source_ip
	public variable source_num
	public variable source_step
	public variable source_modbit
	public variable group_ip
	public variable group_num
	public variable group_step
	public variable group_modbit
    public variable source_ipv6

	public variable protocol
	method config { args } {}
	
	constructor { } {
		set filter_mode 		exclude
		set source_ip			0.0.0.0
		set source_num			1
		set source_step			1
		set source_modbit		32
		set group_ip			224.0.0.0
		set group_num			1
		set group_step			1
		set group_modbit		32
	}
}

body IgmpHost::join_group { args } {
    global errNumber
    global LoadConfigMode
    
    set tag "body IgmpHost::join_group [info script]"
Deputs "----- TAG: $tag -----"

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set groupList $value
            }
            -rate {
            	set rate $value
            }
        }
    }

	if { [ info exists rate ] } {
        set pattern  [ixNet getA [ixNet getA /globals/topology/igmpHost -ratePerInterval] -pattern]
        SetMultiValues /globals/topology/igmpHost "-ratePerInterval" $pattern $rate
	}
	
	if { [ info exists groupList ] } {
		foreach group $groupList {
			if { [ $group isa MulticastGroup ] == 0 } {
				return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
			}
			set grpIndex [ lsearch $group_list $group ]
			if { $grpIndex >= 0 } {
				foreach hIgmp $handle {
					set hGroup	$group_handle($group,$hIgmp)
					ixNet commit
				}
			} elseif { $LoadConfigMode } {
                
                foreach hIgmp $handle {
                    set findflag 0
					# set hGroupList [ixNet getL $hIgmp group]
					set hGroupList [ixNet getL $hIgmp igmpMcastIPv4GroupList]
                    foreach hGroup $hGroupList {
                        set group_ip [ixNet getA $hGroup -groupFrom]
                        if { [GetObjNameFromString $group "NULL"] == $group_ip } {
                           set findflag 1
                           break
                        }
                    }
                    if { $findflag } {
                        set group_handle($group,$hIgmp) $hGroup
                        # ixNet setA $hGroup -enabled True
					    # ixNet commit
                    }
                                        
				}
            
            } else {
				set filter_mode [ $group cget -filter_mode ]
				set group_ip [ $group cget -group_ip ]
				set group_num [ $group cget -group_num ]
				set group_step [ $group cget -group_step ]
				set group_modbit [ $group cget -group_modbit ]
				set source_ip [ $group cget -source_ip ]
				set source_num [ $group cget -source_num ]
				set source_step [ $group cget -source_step ]
				set source_modbit [ $group cget -source_modbit ]
	Deputs "=group prop= filter_mode:$filter_mode group_ip:$group_ip group_num:$group_num group_step:$group_step group_modbit:$group_modbit source_ip:$source_ip source_num:$source_num source_step:$source_step source_modbit:$source_modbit"
				foreach hIgmp $handle {
					set hGroup [ ixNet getL $hIgmp igmpMcastIPv4GroupList]

					set pattern  [ixNet getA [ixNet getA $hGroup -active] -pattern]
                    SetMultiValues $hGroup "-active" $pattern true
                    if { [info exists group_ip] && [info exists group_step] } {
                        set pattern  "counter"
                        SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip $group_step
                    } elseif  { [info exists group_ip] && ![info exists group_step] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
                        SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip
                    }
                    if { [info exists group_step] } {
                        set ipPattern [ixNet getA [ixNet getA $hGroup -mcastAddrIncr] -pattern]
                        SetMultiValues $hGroup "-mcastAddrIncr" $ipPattern $group_step
                    }
                    if { [info exists group_num] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -mcastAddrCnt] -pattern]
                        SetMultiValues $hGroup "-mcastAddrCnt" $pattern $group_num
                    }
                    if { [info exists filter_mode] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -sourceMode] -pattern]
                        SetMultiValues $hGroup "-sourceMode" $pattern $filter_mode
                    }
					if { [ IsIPv4Address $source_ip ] } {
                        set hSource [ ixNet add $hGroup igmpUcastIPv4SourceList]
                        if { [info exists source_ip] && [info exists source_step] } {
                            set pattern  "counter"
                            SetMultiValues $hSource "-startUcastAddr" $pattern $source_ip $source_step
                        } elseif  { [info exists source_ip] && ![info exists source_step] } {
                            set pattern  [ixNet getA [ixNet getA $hSource -startUcastAddr] -pattern]
                            SetMultiValues $hSource "-startUcastAddr" $pattern $source_ip
                        }
                        if {[info exists source_step]} {
                            set pattern  [ixNet getA [ixNet getA $hSource -ucastAddrIncr] -pattern]
                            SetMultiValues $hSource "-ucastAddrIncr" $pattern $source_step
                        }
                        if {[info exists source_num]} {
                            set pattern  [ixNet getA [ixNet getA $hSource -ucastSrcAddrCnt] -pattern]
                            SetMultiValues $hSource "-ucastSrcAddrCnt" $pattern $source_num
                        }
                    ixNet commit
                    } else {
                        error "$errNumber(1) Invalid Ipv4 address"
                    }
                    
					set group_handle($group,$hIgmp) $hGroup
					lappend group_list $group
					$group configure -handle $hGroup
					$group configure -portObj $portObj
					$group configure -hPort $hPort
					$group configure -protocol "igmp"
				}			
			}
		}
	}

	start
	return [ GetStandardReturnHeader ]
}
body IgmpHost::leave_group { args } {
    global errNumber
    global LoadConfigMode
    
    set tag "body IgmpHost::leave_group [info script]"
    Deputs "----- TAG: $tag -----"

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set group $value
            }
            -rate {
            	set rate $value
            }
        }
    }

	if { [ info exists rate ] } {
        # ixNet setA [ixNet getA /globals/topology/igmpHost -ratePerInterval]/singleValue -value $rate
        set pattern  [ixNet getA [ixNet getA /globals/topology/igmpHost -ratePerInterval] -pattern]
        SetMultiValues  /globals/topology/igmpHost "-ratePerInterval" $pattern $rate
		ixNet commit
		# ixNet setMultiAttrs $hPort/protocols/igmp \
		# 	-numberOfGroups $rate \
		# 	-timePeriod 1000
		# ixNet commit
	}
	
	if { [ info exists group ] } {
		if { [ $group isa MulticastGroup ] == 0 } {
			return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
		}
		set grpIndex [ lsearch $group_list $group ]
		if { $grpIndex >= 0 } {
			foreach hIgmp $handle {

				set hGroup	$group_handle($group,$hIgmp)
                # ixNet setA [ixNet getA $hGroup -active]/singleValue -value false
        set pattern  [ixNet getA [ixNet getA $hGroup -active] -pattern]
        SetMultiValues $hGroup "-active" $pattern false
				ixNet commit

                ## Save changes on the fly, incase if leave_group is called when IGMP host is running
                if {[catch {ixNet exec applyOnTheFly /globals/topology}] == 1} {
                    puts "error in applying on the fly change"
                    puts "$::errorInfo"
                }
			}
        }
	} elseif { $LoadConfigMode } {
        foreach hIgmp $handle {
            set findflag 0
            set hGroupList [ixNet getL $hIgmp group]
            foreach hGroup $hGroupList {
                set group_ip [ixNet getA $hGroup -groupFrom]
                if { [GetObjNameFromString $group "NULL"] == $group_ip } {
                    set findflag 1
                    break
                }
            }
            if { $findflag } {
                set group_handle($group,$hIgmp) $hGroup
                ixNet setA $hGroup -enabled False
                ixNet commit                
            }                                   
        }
    } else {
        return [ GetErrorReturnHeader "No such group:$group" ]
	}
	return [ GetStandardReturnHeader ]
}

body IgmpHost::get_group_stats { args } {
	return [ GetErrorReturnHeader "Method not supported..." ]
}

body IgmpHost::get_host_stats { args } {
    set tag "body IgmpHost::get_host_stats [info script]"
    Deputs "----- TAG: $tag -----"
    
    set root [ixNet getRoot]
    set captionList [ixNet getA $view/page -columnCaptions]
# Deputs "caption list:$captionList"
# tx_v1_reports
# tx_v2_reports
# tx_v2_leave_reports
# tx_v3_reports
# rx_v1_general_queries
# rx_v2_general_queries
# rx_v3_general_queries
# rx_v1_specific_queries
# rx_v2_specific_queries
# rx_v3_group_specific_queries
# rx_v3_group_source_specific_queries
# send_includes
# send_excludes

# {Stat Name} 
# {Host v1 Membership Rpts. Rx} 
# {Host v2 Membership Rpts. Rx} 
# {v1 Membership Rpts. Tx} 
# {v2 Membership Rpts. Tx} 
# {v3 Membership Rpts. Tx} 
# {v2 Leave Tx} 
# {Host Total Frames Tx} 
# {Host Total Frames Rx} 
# {Host Invalid Packets Rx} 
# {General Queries Rx} 
# {Grp. Specific Queries Rx} 
# {v3 Grp. & Src. Specific Queries Rx}
	set tx_v1_reports			[ lsearch -exact $captionList {v1 Membership Reports Tx} ]
    set tx_v2_reports          [ lsearch -exact $captionList {v2 Membership Reports Tx}  ]
    set tx_v2_leave_reports          [ lsearch -exact $captionList  {v2 Leave Tx} ]
    set tx_v3_reports         	[ lsearch -exact $captionList {v3 Membership Reports Tx} ]
    set rx_v1_general_queries         	[ lsearch -exact $captionList {General Queries Rx} ]
    set rx_v2_general_queries         	[ lsearch -exact $captionList {General Queries Rx} ]
    set rx_v3_general_queries       		[ lsearch -exact $captionList {General Queries Rx} ]
    ## rx_v1_specific_queries is not part of stats
    set rx_v1_specific_queries        	[ lsearch -exact $captionList {Grp. Specific Queries Rx} ]
    set rx_v2_specific_queries	[ lsearch -exact $captionList {v2 Group-Specific Queries Rx}]
    set rx_v3_group_specific_queries       		[ lsearch -exact $captionList {Grp. Specific Queries Rx} ]
    set rx_v3_group_source_specific_queries        	[ lsearch -exact $captionList {v3 Group and Source Specific Queries Rx}]
    # set send_includes	[ lsearch -exact $captionList {Data Integrity Frames Rx.} ]
    # set send_excludes	[ lsearch -exact $captionList {Data Integrity Frames Rx.} ]

    set ret [ GetStandardReturnHeader ]
	
    while (1)  {
        after 10000
    set stats [ ixNet getA $view/page -rowValues ]

    foreach row $stats {
        
        eval {set row} $row
        Deputs "row:$row"

        set statsItem   "tx_v1_reports"
        set statsVal    [ lindex $row $tx_v1_reports ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "tx_v2_reports"
        set statsVal    [ lindex $row $tx_v2_reports ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
              
        set statsItem   "tx_v2_leave_reports"
        set statsVal    [ lindex $row $tx_v2_leave_reports ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "tx_v3_reports"
        set statsVal    [ lindex $row $tx_v3_reports ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "rx_v1_general_queries"
        set statsVal    [ lindex $row $rx_v1_general_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "rx_v2_general_queries"
        set statsVal    [ lindex $row $rx_v2_general_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
              
        set statsItem   "rx_v3_general_queries"
        set statsVal    [ lindex $row $rx_v3_general_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_v1_specific_queries"
        set statsVal    [ lindex $row $rx_v1_specific_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "rx_v2_specific_queries"
        set statsVal    [ lindex $row $rx_v2_specific_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
              
        set statsItem   "rx_v3_group_specific_queries"
        set statsVal    [ lindex $row $rx_v3_group_specific_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_v3_group_source_specific_queries"
        set statsVal    [ lindex $row $rx_v3_group_source_specific_queries ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        # set statsItem   "send_includes"
        # set statsVal    "NA"
# Deputs "stats val:$statsVal"
        # set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        # set statsItem   "send_excludes"
        # set statsVal    "NA"
# Deputs "stats val:$statsVal"
        # set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

Deputs "ret:$ret"

    }
    }
    return $ret	
}

body MulticastGroup::config { args } {

    global errNumber
    
    set tag "body MulticastGroup::config [info script]"
Deputs "----- TAG: $tag -----"

	set EFilterMode		[ list include exclude ]
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -filter_mode {
				set value [ string tolower $value ]
                if { [ lsearch -exact $EFilterMode $value ] >= 0 } {
                    
                    set filter_mode $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -source_ip {
                Deputs "set ip address...$value"
                if { [ IsIPv4Address $value ] } {
                   set source_ip $value
                } elseif { [ IsIPv6Address $value ] } {
                   set source_ip $value
                } else {
                   error "$errNumber(1) key:$key value:$value"
                }
            }
            -source_num {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] } {
                    set source_num $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -source_step {
                set source_step $value
            }
            -source_modbit {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] && $trans <= 32 && $trans >= 1 } {
                    set source_modbit $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                    
            }
            -group_ip {
			    if { [ IsIPv4Address $value ] } {
                   set group_ip $value
                } elseif { [ IsIPv6Address $value ] } {
                   set group_ip $value
                } else {
                   error "$errNumber(1) key:$key value:$value"
                }
            }
            -group_num {
                set trans [ UnitTrans $value ]
                if { [ string is integer $trans ] } {
                    set group_num $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -group_step {
				Deputs "inside group step"
                set group_step $value
            }
            -group_modbit {
                set trans [ UnitTrans $value ]
			    set group_modbit $trans
#                if { [ string is integer $trans ] && $trans <= 32 && $trans >= 1 } {
#                    set group_modbit $trans
#                } else {
#                    error "$errNumber(1) key:$key value:$value"
#                }                    
            }

        }
    }	
    if { [info exists group_ip]} {
        if { [ IsIPv4Address $group_ip ] } {
              set group_step "0.0.0.$group_step"
        } elseif { [ IsIPv6Address $group_ip ] } {
            set group_step "0:0:0:0:0:0:0:$group_step"
        }
    }
    if { [info exists source_ip]} {
        if { [ IsIPv4Address $source_ip ] } {
              set source_step "0.0.0.$source_step"
        } elseif { [ IsIPv6Address $source_ip ] } {
            set source_step "0:0:0:0:0:0:0:$source_step"
        }
    }
	return [ GetStandardReturnHeader ]
}

class MldHost {
    inherit IgmpHost
    public variable version	
    public variable mldTrigger
    public variable mldTunnelObj
    constructor { port {pppoe NULL} } { chain $port $pppoe} {
		set view ""
	}
	method join_group { args } {}
	method reborn { {version ipv6} {mldTunnelObj ""} } {
    set tag "body MldHost::reborn [info script]"
        Deputs "----- TAG: $tag -----"
		if { [ catch {
			set hPort   [ $portObj cget -handle ]
		} ] } {
			error "$errNumber(1) Port Object in DhcpHost ctor"
		}
		set ip_version $version

        Deputs "hPort: $hPort"

        if {$mldTunnelObj != ""} {
            Deputs "creating over DHCP"
            set handle [ixNet add $mldTunnelObj mldHost]
            ixNet commit
            set handle [ixNet remapIds $handle]
            return
        }
        set mldObj ""
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
                        if { $ip_version == "ipv6" } {
                            set ipv6Obj [ixNet add $ethernetObj ipv6]
                            ixNet commit
                            set ipv6Obj [ ixNet remapIds $ipv6Obj ]
                            set ipHandle $ipv6Obj
                        }
                    }
				}
			}
            break
        }
    }

        array set routeBlock [ list ]
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        if { [ llength $topoObjList ] == 0 } {
            set handle [CreateProtoHandleFromRoot $hPort mldHost ipv6]
            set ipHandle [GetDependentNgpfProtocolHandle $handle ip]
            ixNet setA $handle -name $this
            ixNet commit
        } elseif { [ llength $topoObjList ] != 0 } {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        foreach ethernetObj $ethernetList {
                            if { $ip_version == "ipv6" } {
                                set ipv6Obj [ixNet getL $ethernetObj ipv6]
                                if {[llength $ipv6Obj] != 0} {
                                    set ipv6Obj [ ixNet remapIds $ipv6Obj ]
                                    set ipHandle $ipv6Obj
                                }
                            }
                            # set handle [ixNet getL $ipHandle mldHost]
                            # if {[ llength $handle ] == 0 } {
                            set handle [ixNet add $ipHandle mldHost]
                            # }
                            ixNet commit
                            set handle [ixNet remapIds $handle]
                            ixNet setA $handle -name $this
                        }
                    }
                }
            }
        }
	    ixNet commit
		Deputs "handle:$handle"
        #$this configure -version $ip_version
	    set protocol mld
	}
	method config { args } {
        Deputs "In side MldHost::config calling chain"
		eval chain $args -ip_version ipv6 
	}
}
body MldHost::join_group { args } {
    global errNumber
    
    set tag "body MldHost::join_group [info script]"
Deputs "----- TAG: $tag -----"

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set groupList $value
            }
            -rate {
            	set rate $value
            }
        }
    }

		if { [ info exists rate ] } {
        # ixNet setA [ixNet getA /globals/topology/mldHost -ratePerInterval]/singleValue -value $rate
        set pattern  [ixNet getA [ixNet getA /globals/topology/mldHost -ratePerInterval] -pattern]
        SetMultiValues /globals/topology/mldHost "-ratePerInterval" $pattern $rate
		ixNet commit
	}
	
	if { [ info exists groupList ] } {
		foreach group $groupList {
	Deputs Step10
			if { [ $group isa MulticastGroup ] == 0 } {
				return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
			}
	Deputs Step20
			set grpIndex [ lsearch $group_list $group ]
			if { $grpIndex >= 0 } {
	Deputs Step30
				foreach hMld $handle {
					Deputs "inside group config"
					set hGroup	$group_handle($group,$hMld)
					ixNet setA $hGroup -enabled True
					ixNet commit
				}
			} else {
	Deputs Step40
				Deputs "inside else"
				set filter_mode [ $group cget -filter_mode ]
				set group_ip [ $group cget -group_ip ]
				set group_num [ $group cget -group_num ]
				set group_step [ $group cget -group_step ]
				set group_modbit [ $group cget -group_modbit ]
				set source_ip [ $group cget -source_ip ]
				set source_num [ $group cget -source_num ]
				set source_step [ $group cget -source_step ]
				set source_modbit [ $group cget -source_modbit ]
				if { [ IsIPv4Address $source_ip ] && $source_ip == "0.0.0.0"} {
				    set source_ip "aaaa:0:0:0:0:0:0:0"
				}
				if { [ IsIPv4Address $source_step ] } {
				    set source_step "0:0:0:0:0:0:0:$source_num"
				}
	Deputs "=group prop= filter_mode:$filter_mode group_ip:$group_ip group_num:$group_num group_step:$group_step group_modbit:$group_modbit source_ip:$source_ip source_num:$source_num source_step:$source_step source_modbit:$source_modbit"
	Deputs Step45

				foreach hMld $handle {

					set hGroup [ ixNet getL $hMld mldMcastIPv6GroupList]

                    set pattern  [ixNet getA [ixNet getA $hGroup -active] -pattern]
                    SetMultiValues $hGroup "-active" $pattern true
                    if { [info exists group_num] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -mcastAddrCnt] -pattern]
                        SetMultiValues $hGroup "-mcastAddrCnt" $pattern $group_num
                    }
                    if { [info exists group_ip] && [info exists group_step] } {
                        set pattern  "counter"
                        SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip $group_step
                    } elseif  { [info exists group_ip] && ![info exists group_step] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
                        SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip
                    }
                    if { [info exists group_step] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -mcastAddrIncr] -pattern]
                        SetMultiValues $hGroup "-mcastAddrIncr" $pattern $group_step
                    }
                    if { [info exists filter_mode] } {
                        set pattern  [ixNet getA [ixNet getA $hGroup -sourceMode] -pattern]
                        SetMultiValues $hGroup "-sourceMode" $pattern $filter_mode
                    }
					Deputs "sourceip: $source_ip"
                    if { [ IsIPv6Address $source_ip ] } {
                        Deputs Step48
                        set hSource [ ixNet add $hGroup mldUcastIPv6SourceList ]
                        Deputs $hSource
                        if { [info exists source_num] } {
                            set pattern  [ixNet getA [ixNet getA $hSource -ucastSrcAddrCnt] -pattern]
                            SetMultiValues $hSource "-ucastSrcAddrCnt" $pattern $source_num
                        }
                        if { [info exists source_ip] && [info exists source_step] } {
                            set pattern  "counter"
                            SetMultiValues $hSource "-startUcastAddr" $pattern $source_ip $source_step
                        } elseif  { [info exists source_ip] && ![info exists source_step] } {
                            set pattern  [ixNet getA [ixNet getA $hSource -startUcastAddr] -pattern]
                            SetMultiValues $hSource "-startUcastAddr" $pattern $source_ip
                        }
                        if { [info exists source_step] } {
                            set pattern  [ixNet getA [ixNet getA $hSource -ucastAddrIncr] -pattern]
                            SetMultiValues $hSource "-ucastAddrIncr" $pattern $source_step
                        }
                    } else {
                        error "$errNumber(1) Invalid Ipv6 address"
                    }
		Deputs Step50			
		Deputs "group handle:$hGroup"
		Deputs "group handle array names: [ array names group_handle ]"
					set group_handle($group,$hMld) $hGroup
		Deputs Step60
					lappend group_list $group
		Deputs "group handle names:[ array names group_handle ]"
		Deputs "group list:$group_list"
		
					$group configure -handle $hGroup
					$group configure -portObj $portObj
					$group configure -hPort $hPort
					$group configure -protocol "mld"
				}			
			}
		}
	}

	start
	return [ GetStandardReturnHeader ]
}
class IgmpOverDhcpHost {
	inherit IgmpHost
	public variable Dhcp
	
	constructor { dhcp } { chain [ $dhcp  cget -portObj ] $dhcp} {
		set tag "body IgmpOverDhcpHost::ctor [info script]"
        Deputs "----- TAG: $tag -----"
		set Dhcp $dhcp
        Deputs "Dhcp: $Dhcp"
        born
	}
		
	method born {} {}
	method config { args } {}
	method start {} {}
	method stop {} {}
}
body IgmpOverDhcpHost::born {} {
    set tag "body IgmpOverDhcpHost::born [info script]"
    Deputs "----- TAG: $tag -----"
			
	set interface [ list ]
	set hDhcp [ $Dhcp cget -handle ]

    Deputs "hDhcp:$hDhcp"
	# set count [ ixNet getA $hDhcp/dhcpRange -count ]
    ## TODO, currently hardcoded to 1. Need to evaluate how to get the count
	# set count 1
    # Deputs "count:$count"
	# for { set index 1 } { $index <= $count } { incr index } {
    #     Deputs "hPort:$hPort"
    #     set host [lindex $handle [expr $index - 1]]
    #     # if { $host == "" } {
    #     #     set host [ ixNet add $hPort/protocols/igmp host ]
    #     # }
    #     Deputs "IgmpOverDhcpHost host: $host index:$index"		
	# 	ixNet setM $host \
	# 		-interfaceType DHCP \
	# 		-interfaceIndex $index \
	# 		-enabled True 
	# 	ixNet commit
    #     set host [ixNet remapIds $host]
    #     if { [lsearch $handle $host] == -1} {
    #         lappend handle $host
    #     }
	# 	ixNet setA $host -interfaces $hDhcp
	# 	ixNet commit
	# }
    Deputs "handle:$handle"	
}
body IgmpOverDhcpHost::config { args } {
    set tag "body IgmpOverDhcpHost::config [info script]"
    Deputs "----- TAG: $tag -----"
    
    # Deputs "handle:$handle"	
	if { [ llength $handle ] == 0 } {
		born
	}
	
	eval chain $args
	
	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set groupList $value
            }
            -rate {
            	set rate $value
            }
        }
    }

	if { [ info exists rate ] } {
        set pattern  [ixNet getA [ixNet getA /globals/topology/igmpHost -ratePerInterval] -pattern]
        SetMultiValues /globals/topology/igmpHost "-ratePerInterval" $pattern $rate
	}

	return [ GetStandardReturnHeader ]
}
body IgmpOverDhcpHost::start {} {
    set tag "body IgmpOverDhcpHost::start [info script]"
    Deputs "----- TAG: $tag -----"
    ixNet exec startIGMP $handle
	# ixNet exec start $hPort/protocols/igmp
	return [ GetStandardReturnHeader ]
}
body IgmpOverDhcpHost::stop {} {
    set tag "body IgmpOverDhcpHost::stop [info script]"
    Deputs "----- TAG: $tag -----"
    ixNet exec stopIGMP $handle
	# ixNet exec stop $hPort/protocols/igmp
	return [ GetStandardReturnHeader ]
}


class IgmpOverPppoeHost {
	inherit IgmpHost
	public variable Pppoe
	
	constructor { pppoe } { 
		set tag "body IgmpOverPppoeHost::ctor [info script]"      
        Deputs "----- TAG: $tag -----"   
        set Pppoe $pppoe
        chain [ $pppoe  cget -portObj ] $this $Pppoe} {
	}
		
	method reborn {} {}
	method config { args } {}
	method start {} {}
	method stop {} {}
}
body IgmpOverPppoeHost::reborn {} {
    set tag "body IgmpOverPppoeHost::reborn [info script]"
    Deputs "----- TAG: $tag -----"
	
    chain    
	set interface [ list ]
	set hPppoe [ $Pppoe cget -handle ]
    # ixNet setM $handle \
	# 		-interfaceType PPP \
	# 		-interfaces $hPppoe  \
	# 		-enabled True 
    ixNet commit
    Deputs "handle:$handle"	
}
body IgmpOverPppoeHost::config { args } {
    set tag "body IgmpOverPppoeHost::config [info script]"
    Deputs "----- TAG: $tag -----"
    
    # Deputs "handle:$handle"	
	if { $handle == "" } {
		reborn
       
	}
	
	eval chain $args
	
	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set groupList $value
            }
            -rate {
            	set rate $value
            }
        }
    }

	# if { [ info exists rate ] } {
	# 	ixNet setMultiAttrs $hPort/protocols/igmp \
	# 		-numberOfGroups $rate \
	# 		-timePeriod 1000
	# 	ixNet commit
	# }
	
	if { [ info exists groupList ] } {
		foreach group $groupList {
            Deputs Step10
			if { [ $group isa MulticastGroup ] == 0 } {
				return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
			}
            Deputs Step20
			set grpIndex [ lsearch $group_list $group ]
			if { $grpIndex >= 0 } {
                Deputs Step30
				foreach hIgmp $handle {
					set hGroup	$group_handle($group,$hIgmp)
					ixNet setA $hGroup -enabled True
					ixNet commit
				}
			} else {
                Deputs Step40
				set filter_mode [ $group cget -filter_mode ]
				set group_ip [ $group cget -group_ip ]
				set group_num [ $group cget -group_num ]
				set group_step [ $group cget -group_step ]
				set group_modbit [ $group cget -group_modbit ]
				set source_ip [ $group cget -source_ip ]
				set source_num [ $group cget -source_num ]
				set source_step [ $group cget -source_step ]
				set source_modbit [ $group cget -source_modbit ]
                Deputs "=group prop= filter_mode:$filter_mode group_ip:$group_ip group_num:$group_num group_step:$group_step group_modbit:$group_modbit source_ip:$source_ip source_num:$source_num source_step:$source_step source_modbit:$source_modbit"
                Deputs Step45
                Deputs "handle:$handle"	
				foreach hIgmp $handle {
					set hGroup [ ixNet add $hIgmp group ]
                    Deputs "hGroup:$hGroup"					
					set incrStep [ GetPrefixV4Step $group_modbit $group_step ]
                    Deputs "incrStep:$incrStep"					
					ixNet setM $hGroup \
						-enabled 		True \
						-groupCount 	$group_num \
						-groupFrom 		$group_ip \
						-incrementStep 	$incrStep \
						-sourceMode 	$filter_mode
						
					ixNet commit
                    set hGroup [ ixNet remapIds $hGroup ]
                    Deputs "sourceip: $source_ip"
                    if { $source_ip != "0.0.0.0" } {
        Deputs Step48
                        set hSource [ ixNet add $hGroup source ]
        Deputs $hSource
                        ixNet setM $hSource \
                            -sourceRangeCount $source_num \
			                -sourceRangeStart $source_ip
                        ixNet commit
                        set hSource [ixNet remapIds $hSource]
                    }
                    Deputs Step50			
                    Deputs "group handle:$hGroup"
                    Deputs "group handle array names: [ array names group_handle ]"
					set group_handle($group,$hIgmp) $hGroup
                    Deputs Step60
					lappend group_list $group
                    Deputs "group handle names:[ array names group_handle ]"
                    Deputs "group list:$group_list"
				}			
			}
		}
	}

	return [ GetStandardReturnHeader ]
	
}
body IgmpOverPppoeHost::start {} {
    set tag "body IgmpOverPppoeHost::start [info script]"
    Deputs "----- TAG: $tag -----"
	ixNet exec start $hPort/protocols/igmp
	return [ GetStandardReturnHeader ]
}
body IgmpOverPppoeHost::stop {} {
    set tag "body IgmpOverPppoeHost::stop [info script]"
    Deputs "----- TAG: $tag -----"
	ixNet exec stop $hPort/protocols/igmp
	return [ GetStandardReturnHeader ]
}

class MldOverPppoeHost {
	inherit MldHost
	public variable Pppoe
	
	constructor { pppoe } { 
        Deputs "at MldOverPppoeHost::constructor"
        set Pppoe $pppoe
        chain [ $pppoe  cget -portObj ] $pppoe } {
      
		set tag "body MldIgmpOverPppoeHost::ctor [info script]"      
        Deputs "----- TAG: $tag -----"
	}
		
	method reborn {} {}
	method config { args } {}
	method start {} {}
	method stop {} {}
}
body MldOverPppoeHost::reborn {} {
    set tag "body MldOverPppoeHost::reborn [info script]"
    Deputs "----- TAG: $tag -----"

    # chain
    chain "ipv6" [ $Pppoe cget -handle ]
}
body MldOverPppoeHost::config { args } {
    set tag "body MldOverPppoeHost::config [info script]"
    Deputs "----- TAG: $tag -----"

    # Deputs "handle:$handle"	
	if { $handle == "" } {
        Deputs "Calling reborn as handle is null"
		reborn
        
	}
	
	eval chain $args
	
	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
            	set groupList $value
            }
            -rate {
            	set rate $value
            }
        }
    }

	# if { [ info exists rate ] } {
	# 	ixNet setMultiAttrs $hPort/protocols/mld \
	# 		-numberOfGroups $rate \
	# 		-timePeriod 1000
	# 	ixNet commit
	# }
	
	if { [ info exists groupList ] } {
		foreach group $groupList {
            Deputs Step10
			if { [ $group isa MulticastGroup ] == 0 } {
				return [ GetErrorReturnHeader "Invalid MultcastGroup object... $group" ]
			}
            Deputs Step20
			set grpIndex [ lsearch $group_list $group ]
			if { $grpIndex >= 0 } {
                Deputs Step30
				foreach hIgmp $handle {
					set hGroup	$group_handle($group,$hIgmp)
					ixNet setA $hGroup -enabled True
					ixNet commit
				}
			} else {
                Deputs Step40
				set filter_mode [ $group cget -filter_mode ]
				set group_ip [ $group cget -group_ip ]
				set group_num [ $group cget -group_num ]
				set group_step [ $group cget -group_step ]
				set group_modbit [ $group cget -group_modbit ]
				set source_ip [ $group cget -source_ip ]
				set source_num [ $group cget -source_num ]
				set source_step [ $group cget -source_step ]
				set source_modbit [ $group cget -source_modbit ]
                Deputs "=group prop= filter_mode:$filter_mode group_ip:$group_ip group_num:$group_num group_step:$group_step group_modbit:$group_modbit source_ip:$source_ip source_num:$source_num source_step:$source_step source_modbit:$source_modbit"
                Deputs Step45
                Deputs "handle:$handle"	
				foreach hMld $handle {
					# set hGroup [ ixNet add $hMld groupRange ]
					set hGroup [ixNet getL $hMld mldMcastIPv6GroupList]
                    Deputs "hGroup:$hGroup"					
					# set incrStep [ GetPrefixV4Step $group_modbit $group_step ]
                    # Deputs "incrStep:$incrStep"					
					# ixNet setM $hGroup \
					# 	-enabled 		True \
					# 	-groupCount 	$group_num \
					# 	-groupFrom 		$group_ip \
					# 	-incrementStep 	$incrStep \
					# 	-sourceMode 	$filter_mode

                    set hGroup [ ixNet remapIds $hGroup ]
                    set pattern  [ixNet getA [ixNet getA $hGroup -active] -pattern]
                    SetMultiValues $hGroup "-active" $pattern true
                    set pattern  [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
                    SetMultiValues $hGroup "-startMcastAddr" $pattern $group_ip
                    set pattern  [ixNet getA [ixNet getA $hGroup -mcastAddrCnt] -pattern]
                    SetMultiValues $hGroup "-mcastAddrCnt" $pattern $group_num
                    ixNet setA $hGroup -count $group_num
                    set pattern  [ixNet getA [ixNet getA $hGroup -sourceMode] -pattern]
                    SetMultiValues $hGroup "-sourceMode" $pattern $filter_mode
						
					# ixNet commit
                    Deputs "sourceip: $source_ip"

                    if { $source_ip != "0.0.0.0" } {
        Deputs Step48
                        # set hSource [ ixNet add $hGroup sourceRange ]
                        set hSource [ixNet getL $hGroup mldUcastIPv6SourceList]
        Deputs $hSource
                        # ixNet setM $hSource \
                        #     -count $source_num \
			            #     -ipFrom $source_ip
                        ixNet setA $hSource -count $source_num
                        ixNet setA $hSource -startUcastAddr $source_ip
                        ixNet commit
                    }
                    Deputs Step50			
                    Deputs "group handle:$hGroup"
                    Deputs "group handle array names: [ array names group_handle ]"
					set group_handle($group,$hMld) $hGroup
                    Deputs Step60
					lappend group_list $group
                    Deputs "group handle names:[ array names group_handle ]"
                    Deputs "group list:$group_list"
                    # $group configure -handle $hGroup
					# $group configure -portObj $portObj
					# $group configure -hPort $hPort
					# $group configure -protocol "mld"
				}			
			}
		}
	}

	return [ GetStandardReturnHeader ]
	
}
body MldOverPppoeHost::start {} {
    set tag "body MldOverPppoeHost::start [info script]"
    Deputs "----- TAG: $tag -----"
	# ixNet exec start $hPort/protocols/mld
	ixNet exec start $handle
	return [ GetStandardReturnHeader ]
}
body MldOverPppoeHost::stop {} {
    set tag "body MldOverPppoeHost::stop [info script]"
    Deputs "----- TAG: $tag -----"
	# ixNet exec stop $hPort/protocols/mld
	ixNet exec stop $handle
	return [ GetStandardReturnHeader ]
}