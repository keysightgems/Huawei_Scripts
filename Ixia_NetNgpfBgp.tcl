
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.3
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.4.34
#		2. Add Vpn for BGP Vpn
# Version 1.2.4.53
#		3. Add capability in reborn
# Version 1.3.4.54
#		4. Add learned filter in reborn

class BgpSession {
    inherit RouterNgpfEmulationObject
    public variable ip_version
    public variable ipv4_addr
    public variable bgpHandle
	public variable version
    constructor { port  { hBgpSession NULL }  } {
		set tag "body BgpSession::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set portObj [ GetObject $port ]
		set handle ""
		set bgphandle ""
		set routeBlock(obj) [list]

        set portObj [ GetObject $port ]
        if { [ catch {
            set hPort   [ $portObj cget -handle ]
        } ] } {
            error "$errNumber(1) Port Object in BgpSession ctor"
        }
        if { $hBgpSession == "NULL" } {
            set hBgpSession [GetObjNameFromString $this "NULL"]
        }
        Deputs "----- hBgpSession: $hBgpSession, hPort: $hPort -----"
        if { $hBgpSession != "NULL" } {
            set handle [GetValidNgpfHandleObj "bgp" $hBgpSession $hPort]
            Deputs "----- handle: $handle -----"

            if { $handle != "" } {
                set handleName [ ixNet getA $handle -name ]
            }

        }
        if { $handle == "" } {
            set handleName $this
            reborn
        }

	}

	method reborn { {version ipv4}  } { }
    method config { args } {}
	method enable {} {}
	method disable {} {}
	method get_status {} {}
	method get_stats {} {}
	method set_route { args } {}
	method advertise_route { args } {}
	method withdraw_route { args } {}
	method wait_session_up { args } {}
}


class SimRoute {
    inherit RouterNgpfEmulationObject
    public variable  bgpObj
    public variable  hBgp
    public variable  ipv4_addr
	public variable  hRouteBlock
    public variable  networkGroupObj
    # public variable  bgpIpRouteObj
    public variable bgpSimRouteObj
    public variable bgpV6SimRouteObj

    constructor { bgpobj { hRouteBlock NULL } } {
		set tag "body SimRoute::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set bgpObj  [ GetObject $bgpobj    ]
        set hBgp    [ $bgpObj cget -bgpHandle ]
        set portObj [ $bgpObj cget -portObj]
        set hPort   [ $bgpObj cget -hPort  ]
		set handle ""
        set routeBlock(obj) [list]
          if { $hRouteBlock == "NULL" } {
            set hRouteBlock [GetObjNameFromString $this "NULL"]
        }
        Deputs "----- hRouteBlock: $hRouteBlock, $bgpobj: $hBgp -----"
        set deviceGroupObj [GetDependentNgpfProtocolHandle $hBgp "deviceGroup"]
        if { $hRouteBlock != "NULL" } {
            set handle [GetValidNgpfHandleObj "simroute" $hRouteBlock $deviceGroupObj]
            Deputs "----- handle: $handle -----"
            if { $handle != "" } {
                set handleName [ ixNet getA $handle -name ]
            }
        }
	}

    method config { args } {}
	method enable {} {}
	method advertise_route { } {
	    set tag "body SimRoute::advertise_route [info script]"
        Deputs "----- TAG: $tag -----"
        set ipPattern [ixNet getA [ixNet getA $networkGroupObj -enabled] -pattern]
		SetMultiValues $networkGroupObj "-enabled" $ipPattern True
        #ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value True
	    #ixNet commit
	}
	method withdraw_route { } {
	    set tag "body SimRoute::withdraw_route [info script]"
        Deputs "----- TAG: $tag -----"
        set ipPattern [ixNet getA [ixNet getA $networkGroupObj -enabled] -pattern]
		SetMultiValues $networkGroupObj "-enabled" $ipPattern False
        #ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value False
		#ixNet commit
	}
	method flapping_route { args } {
		set tag "body SimRoute::flapping_route [info script]"
        Deputs "----- TAG: $tag -----"
		set interval 5
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
        if {$bgpSimRouteObj != ""} {
            set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -enableFlapping] -pattern]
		    SetMultiValues $bgpSimRouteObj "-enableFlapping" $ipPattern True
            #ixNet setA [ixNet getA $bgpSimRouteObj -enableFlapping]/singleValue -value True
        }
        if {$bgpV6SimRouteObj != ""} {
            set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -enableFlapping] -pattern]
		    SetMultiValues $bgpV6SimRouteObj "-enableFlapping" $ipPattern True
            #ixNet setA [ixNet getA $bgpV6SimRouteObj -enableFlapping]/singleValue -value True
        }

        if {[info exists interval]} {
            if {$bgpSimRouteObj != ""} {
                set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -downtime] -pattern]
		        SetMultiValues $bgpSimRouteObj "-downtime" $ipPattern $interval
		        set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -uptime] -pattern]
		        SetMultiValues $bgpSimRouteObj "-uptime" $ipPattern $interval
                #ixNet setA [ixNet getA $bgpSimRouteObj -downtime]/singleValue -value $interval
                #ixNet setA [ixNet getA $bgpSimRouteObj -uptime]/singleValue -value $interval
            }
            if {$bgpV6SimRouteObj != ""} {
                set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -downtime] -pattern]
		        SetMultiValues $bgpV6SimRouteObj "-downtime" $ipPattern $interval
		        set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -uptime] -pattern]
		        SetMultiValues $bgpV6SimRouteObj "-uptime" $ipPattern $interval
                #ixNet setA [ixNet getA $bgpV6SimRouteObj -downtime]/singleValue -value $interval
                #ixNet setA [ixNet getA $bgpV6SimRouteObj -uptime]/singleValue -value $interval
            }
        }
	    ixNet commit
	}
}

body BgpSession::reborn { {version ipv4}  } {
    global errNumber
    global bgpObj
    set tag "body BgpSession::reborn [info script]"
    Deputs "----- TAG: $tag -----"
    set ip_version $version

    if { [ catch {
        set hPort   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in BgpSession ctor"
    }

    #-- add interface and bgp protocol
    set bgpObj ""
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
                        if { $ip_version == "ipv4" } {
                            set ipv4Obj [ixNet add $ethernetObj ipv4]
                            ixNet commit
                        }
                        if { $ip_version == "ipv6" } {
                            set ipv6Obj [ixNet add $ethernetObj ipv6]
                            ixNet commit
                        }
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
        ixNet setA $deviceGroupObj -multiplier 1
        ixNet commit
        set ethernetObj [ixNet add $deviceGroupObj ethernet]
        ixNet commit
        if { $ip_version == "ipv4" } {
            set ipv4Obj [ixNet add $ethernetObj ipv4]
            ixNet commit
            set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
            ixNet commit
        }
        if { $ip_version == "ipv6" } {
            set ipv6Obj [ixNet add $ethernetObj ipv6]
            ixNet commit
            set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
            ixNet commit
            set ipPattern [ixNet getA [ixNet getA $bgpObj -dutIp] -pattern]
			SetMultiValues $bgpObj "-dutIp" $ipPattern "0:0:0:0:0:0:0:0"
            #ixNet setA [ixNet getA $bgpObj -dutIp]/singleValue -value "0:0:0:0:0:0:0:0"
            #ixNet commit
        }
        set bgpObj [ ixNet remapIds $bgpObj ]
        ixNet setA $bgpObj -name $this
        ixNet commit
        array set routeBlock [ list ]

    } else {
        foreach topoObj $topoObjList {
            set vportObj [ixNet getA $topoObj -vports]
            if {$vportObj == $hPort} {
                set deviceGroupList [ixNet getL $topoObj deviceGroup]
                foreach deviceGroupObj $deviceGroupList {
                    set ethernetList [ixNet getL $deviceGroupObj ethernet]
                    foreach ethernetObj $ethernetList {
                        set ipv4Obj [ixNet getL $ethernetObj ipv4]
                        if { $ip_version == "ipv4" } {
                            if {[ info exists ipv4_addr ]} {
                                set ipPattern [ixNet getA [ixNet getA $ipv4Obj -address] -pattern]
                                set ipaddr [GetMultiValues $ipv4Obj "-address" $ipPattern]
                                #set ipaddr [ixNet getA [ixNet getA $ipv4Obj -address]/singleValue -value]
                                if {$ipaddr == $ipv4_addr} {
                                    set ethernetObj $ethernetObj
                                    set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]
                                    if {[llength $bgpObj] != 0} {
                                        set bgpObj [ ixNet remapIds $bgpObj ]
                                    } else {
                                        set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
                                        ixNet commit
                                        set bgpObj [ ixNet remapIds $bgpObj ]
                                    }
                                    break
                                }
                            } else {
                                if { [llength $ipv4Obj] == 0 } {
                                    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                                    if { [llength $ipv6Obj] != 0 } {
                                        if { [llength $bgpObj] == 0 } {
                                            set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                                            ixNet commit
                                            set bgpObj [ ixNet remapIds $bgpObj ]
                                        }
                                    }
                                } else {
									set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]
                                    if { [llength $bgpObj] == 0 } {
                                        set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
                                        ixNet commit
                                        set bgpObj [ ixNet remapIds $bgpObj ]
                                    }
                                }
                            }
                        } elseif { $ip_version == "ipv6" } {
                            set ipv6Obj [ixNet getL $ethernetObj ipv6]
                            if { [llength $ipv6Obj] == 0 } {
                                set ipv6Obj [ixNet add $ethernetObj ipv6]
                                ixNet commit
                                set bgpObj [ixNet getL $ipv6Obj bgpIpv6Peer]
                                if {[llength $bgpObj] != 0} {
                                    set bgpObj [ ixNet remapIds $bgpObj ]
                                } else {
                                    set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                                    ixNet commit
                                    set bgpObj [ ixNet remapIds $bgpObj ]
                                }
                            } else {
								set bgpObj [ixNet getL $ipv6Obj bgpIpv6Peer]
                                if { [llength $bgpObj] == 0 } {
                                    set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                                    ixNet commit
                                    set bgpObj [ ixNet remapIds $bgpObj ]
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    #-- set capability
    foreach bgp $bgpObj {
        set filterList { -filterIpV4Mpls -filterIpV4MplsVpn -filterIpV4Multicast -filterIpV4Unicast -filterIpV6Mpls -filterIpV6MplsVpn -filterIpV6Multicast -filterIpV6Unicast \
                     -capabilityIpV4Mpls -capabilityIpV4MplsVpn -capabilityIpV4Multicast -capabilityIpV4Unicast -capabilityIpV6Mpls -capabilityIpV6MplsVpn -capabilityIpV6Multicast \
                     -capabilityIpV6Unicast }
        foreach filter $filterList {
            set ipPattern [ixNet getA [ixNet getA $bgp $filter] -pattern]
			SetMultiValues $bgp $filter $ipPattern True
            #ixNet setAttr [ixNet getAttr $bgp $filter]/singleValue -value True
        }
        ixNet commit
    }
    $this configure -bgpHandle $bgpObj
    $this configure -version $ip_version
    set protocol bgp
}

body BgpSession::config { args } {
    global errorInfo
    global errNumber
    if { [ catch {
        set handle   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in BgpSession ctor"
    }
    set tag "body BgpSession::config [info script]"
    Deputs "----- TAG: $tag -----"

	set loopback_ipv4_gw 1.1.1.1

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -afi {
            	set afi $value
            }
            -sub_afi {
            	set sub_afi $value
            }
            -as {
            	set as $value
            }
            -dut_ip {
            	set dut_ip $value
            }
            -dut_as {
            	set dut_as $value
            }
            -enable_pack_routes {
            	set enable_pack_routes $value
            }
            -max_routes_per_update {
            	set max_routes_per_update $value
            }
            -enable_refresh_routes {
            	set enable_refresh_routes $value
            }
            -hold_time_interval {
            	set hold_time_interval $value
            }
            -ip_version {
            	set ip_version $value
            }
            -ipv6_addr {
                set ipv6_addr $value
            }
            -address -
            -ip -
			-ipv4_addr {
				set ipv4_addr $value
                set ip $value
			}
            -gateway -
			-ipv4_gw {
				set ipv4_gw $value
                set gateway $value
			}
            -mac {
                set mac $value
            }
			-type {
				set type $value
			}
			-bgp_id -
			-router_id {
				set bgp_id $value
			}
			-loopback_ipv4_addr {
				set loopback_ipv4_addr $value
			}
			-loopback_ipv4_gw {
				set loopback_ipv4_gw $value
			}
            -enable_flap {
                set enable_flap $value
            }
            -flap_down_time {
                set flap_down_time $value
            }
            -flap_up_time {
                set flap_up_time $value
            }
		}
    }

	if { $handle == "" } {
		reborn $ip_version
	}

    set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObjList [ixNet getL $topoObj deviceGroup]
            foreach deviceGroupObj $deviceGroupObjList {
                set ethernetObj [ixNet getL $deviceGroupObj ethernet]
                if { [ info exists ipv4_addr ] } {
                    if { $ip_version == "ipv4" } {
                        Deputs "ipv4: [ixNet getL $ethernetObj ipv4]"
                        set ipv4Obj [ixNet getL $ethernetObj ipv4]
                        set ipPattern [ixNet getA [ixNet getA $ipv4Obj -address] -pattern]
			            SetMultiValues $ipv4Obj "-address" $ipPattern $ipv4_addr
                        #ixNet setA [ixNet getA $ipv4Obj -address]/singleValue -value $ipv4_addr
                        ixNet commit
                    }
                }
                if { [ info exists ipv6_addr ] } {
                    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                    if {$ipv6Obj == ""} {
                        set ipv6Obj [ixNet add $ethernetObj ipv6]
                        ixNet commit
                        set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                        ixNet commit
                        set bgpV6Obj [ ixNet remapIds $bgpObj ]
                    } else {
                        set bgpObj [ixNet getL $ipv6Obj bgpIpv6Peer]
                        if {$bgpObj == ""} {
                            set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                            ixNet commit
                            set bgpV6Obj [ ixNet remapIds $bgpObj ]
                        } else {
                            set bgpV6Obj $bgpObj
                        }
                    }

                    if { [llength $ipv6Obj] != 0 } {
                        set ipPattern [ixNet getA [ixNet getA $ipv6Obj -address] -pattern]
			            SetMultiValues $ipv6Obj "-address" $ipPattern $ipv6_addr
                        #ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
                        #ixNet commit
                    } else {
                        set ipv6Obj [ixNet add $ethernetObj ipv6]
                        ixNet commit
                        set ipPattern [ixNet getA [ixNet getA $ipv6Obj -address] -pattern]
			            SetMultiValues $ipv6Obj "-address" $ipPattern $ipv6_addr
                        #ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
                        #ixNet commit
                    }
                }
                if { [ info exists ipv4_gw ] } {
                    if { $ip_version == "ipv4" } {
                        set ipv4Obj [ixNet getL $ethernetObj ipv4]
                        set ipPattern [ixNet getA [ixNet getA $ipv4Obj -gatewayIp] -pattern]
			            SetMultiValues $ipv4Obj "-gatewayIp" $ipPattern $ipv4_gw
                        #ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/singleValue  -value $ipv4_gw
                        #ixNet commit
                    }
                }
                if { [ info exists gateway ] } {
                    if { $ip_version == "ipv6" } {
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        set ipPattern [ixNet getA [ixNet getA $ipv6Obj -gatewayIp] -pattern]
			            SetMultiValues $ipv6Obj "-gatewayIp" $ipPattern $gateway
                        #ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/singleValue -value $gateway
                        #ixNet commit
                    }
                }
                if { [ info exists mac ] } {
                    set ipPattern [ixNet getA [ixNet getA $ethernetObj -mac] -pattern]
			        SetMultiValues $ethernetObj "-mac" $ipPattern $mac
                    #ixNet setA [ixNet getA $ethernetObj -mac]/singleValue -value $mac
                    #ixNet commit
                }
                if { [ info exists loopback_ipv4_addr ] } {
                    Deputs "not implemented parameter: loopback_ipv4_addr"
                }

                if { $ip_version == "ipv4" } {
                    set ipv4Obj [ixNet getL $ethernetObj ipv4]
                    if {[llength $ipv4Obj] == 0} {
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        if {[llength $ipv6Obj] != 0} {
                            set bgpObj [ixNet getList $ipv6Obj bgpIpv6Peer]
                            if { [llength $bgpObj] == 0 } {
                                set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                                ixNet commit
                                set bgpV6Obj [ ixNet remapIds $bgpObj ]
                            } else {
                                set bgpV6Obj [ixNet getL $ipv6Obj bgpIpv6Peer]
                            }
                        }
                    } else {
                        set bgpObj [ixNet getList $ipv4Obj bgpIpv4Peer]
                        if { [llength $bgpObj] == 0 } {
                            set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
                            ixNet commit
                            set bgpObj [ ixNet remapIds $bgpObj ]
                        } else {
                            set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]
                        }
                    }
                }
                if { $ip_version == "ipv6" } {
                    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                    if { [llength $ipv6Obj] != 0 } {
                        set bgpObj [ixNet getList $ipv6Obj bgpIpv6Peer]
                        if { [llength $bgpObj] == 0 } {
                            set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                            ixNet commit
                            set bgpV6Obj [ ixNet remapIds $bgpObj ]
                        } else {
                            set bgpV6Obj [ixNet getL $ipv6Obj bgpIpv6Peer]
                        }
                    } else {
                        set ipv6Obj [ixNet add $ethernetObj ipv6]
                        ixNet commit
                        set bgpObj [ixNet getList $ipv6Obj bgpIpv6Peer]
                        if { [llength $bgpObj] == 0 } {
                            set bgpObj [ixNet add $ipv6Obj bgpIpv6Peer]
                            ixNet commit
                            set bgpV6Obj [ ixNet remapIds $bgpObj ]
                        }
                    }
                }

                if {[ info exists ipv4_addr ] } {
                    set bgpObj $bgpObj
                } else {
                    set bgpObj ""
                }
                if {[ info exists ipv6_addr ] } {
                    set bgpV6Obj $bgpV6Obj
                } else {
                    set bgpV6Obj ""
                }
                if { [ info exists type ] } {
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -type] -pattern]
			            SetMultiValues $bgpObj "-type" $ipPattern $type
                        #ixNet setA [ixNet getA $bgpObj -type]/singleValue -value $type
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -type] -pattern]
			            SetMultiValues $bgpV6Obj "-type" $ipPattern $type
                        #ixNet setA [ixNet getA $bgpV6Obj -type]/singleValue -value $type
                    }
                }
                if { [ info exists afi ] } {
                    Deputs "not implemented parameter: afi"
                }
                if { [ info exists sub_afi ] } {
                    Deputs "not implemented parameter: safi"
                }
                if { [ info exists as ] } {
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -localAs2Bytes] -pattern]
			            SetMultiValues $bgpObj "-localAs2Bytes" $ipPattern $as
                        #ixNet setA [ixNet getA $bgpObj -localAs2Bytes]/singleValue -value $as
                        #ixNet commit
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -localAs2Bytes] -pattern]
			            SetMultiValues $bgpV6Obj "-localAs2Bytes" $ipPattern $as
                        #ixNet setA [ixNet getA $bgpV6Obj -localAs2Bytes]/singleValue -value $as
                        #ixNet commit
                    }
                }
                if { [ info exists dut_ip ] } {
                    Deputs "dut_ip:$dut_ip"
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -dutIp] -pattern]
			            SetMultiValues $bgpObj "-dutIp" $ipPattern $dut_ip
                        #ixNet setA [ixNet getA $bgpObj -dutIp]/singleValue -value $dut_ip
                        #ixNet commit
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -dutIp] -pattern]
			            SetMultiValues $bgpV6Obj "-dutIp" $ipPattern $dut_ip
                        #ixNet setA [ixNet getA $bgpV6Obj -dutIp]/singleValue -value $dut_ip
                        #ixNet commit
                    }
                }
                if { [ info exists dut_as ] } {
                    Deputs "not implemented parameter: dut_as"
                }
                if { [ info exists enable_pack_routes ] } {
                    Deputs "not implemented parameter: enable_pack_routes"
                }
                if { [ info exists Max_routes_per_update ] } {
                    Deputs "not implemented parameter: Max_routes_per_update"
                }
                if { [ info exists enable_refresh_routes ] } {
                    Deputs "not implemented parameter: enable_refresh_routes"
                }
                if { [ info exists hold_time_interval ] } {
                    Deputs "not implemented parameter: hold_time_interval"
                }
                if { [ info exists bgp_id ] } {
                    set routeDataObj [ixNet getL $deviceGroupObj routerData]
                    set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
			        SetMultiValues $routeDataObj "-routerId" $ipPattern $bgp_id
                    #ixNet setA [ixNet getA $routeDataObj -routerId]/singleValue -value $bgp_id
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -bgpId] -pattern]
			            SetMultiValues $bgpObj "-bgpId" $ipPattern $bgp_id
                        #ixNet setA [ixNet getA $bgpObj -bgpId]/singleValue -value $bgp_id
                        #ixNet commit
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -bgpId] -pattern]
			            SetMultiValues $bgpV6Obj "-bgpId" $ipPattern $bgp_id
                        #ixNet setA [ixNet getA $bgpV6Obj -bgpId]/singleValue -value $bgp_id
                        #ixNet commit
                    }
                }
                if { [ info exists ipv6_addr ] } {
                    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                    set ipPattern [ixNet getA [ixNet getA $ipv6Obj -address] -pattern]
			        SetMultiValues $ipv6Obj "-address" $ipPattern $ipv6_addr
                    #ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
                    #ixNet commit
                }

                if { [ info exists enable_flap ] } {
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -flap] -pattern]
			            SetMultiValues $bgpObj "-flap" $ipPattern $enable_flap
                        #ixNet setA [ixNet getA $bgpObj -flap]/singleValue -value $enable_flap
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -flap] -pattern]
			            SetMultiValues $bgpV6Obj "-flap" $ipPattern $enable_flap
                        #ixNet setA [ixNet getA $bgpV6Obj -flap]/singleValue -value $enable_flap
                    }
                }

                if { [ info exists flap_down_time ] } {
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -downtimeInSec] -pattern]
			            SetMultiValues $bgpObj "-downtimeInSec" $ipPattern $flap_down_time
                        #ixNet setA [ixNet getA $bgpObj -downtimeInSec]/singleValue -value $flap_down_time
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -downtimeInSec] -pattern]
			            SetMultiValues $bgpV6Obj "-downtimeInSec" $ipPattern $flap_down_time
                        #ixNet setA [ixNet getA $bgpV6Obj -downtimeInSec]/singleValue -value $flap_down_time
                    }
                }

                if { [ info exists flap_up_time ] } {
                    if {$bgpObj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpObj -uptimeInSec] -pattern]
			            SetMultiValues $bgpObj "-uptimeInSec" $ipPattern $flap_up_time
                        #ixNet setA [ixNet getA $bgpObj -uptimeInSec]/singleValue -value $flap_up_time
                    }
                    if {$bgpV6Obj != ""} {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6Obj -uptimeInSec] -pattern]
			            SetMultiValues $bgpV6Obj "-uptimeInSec" $ipPattern $flap_up_time
                        #ixNet setA [ixNet getA $bgpV6Obj -uptimeInSec]/singleValue -value $flap_up_time
                    }
                }
                ixNet commit
            }
        }
    }
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]

}

body BgpSession::set_route { args } {
    global errorInfo
    global errNumber
    set tag "body BgpSession::set_route [info script]"
    Deputs "----- TAG: $tag -----"

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }

    set deviceGroup [GetDependentNgpfProtocolHandle $bgpHandle "deviceGroup"]

    if { [ info exists route_block ] } {
		foreach rb $route_block {
			set num 		[ $rb cget -num ]
			set step 		[ $rb cget -step ]
			set prefix_len 	[ $rb cget -prefix_len ]
			set start 		[ $rb cget -start ]
			set type 		[ $rb cget -type ]

            set origin 		[ $rb cget -origin ]
            set nexthop 	[ $rb cget -nexthop ]
            set med 		[ $rb cget -med ]
            set local_pref 	      [ $rb cget -local_pref ]
            set cluster_list      [ $rb cget -cluster_list ]
            set flag_atomic_agg   [ $rb cget -flag_atomic_agg ]
            set agg_as 		      [ $rb cget -agg_as ]
            set agg_ip 		      [ $rb cget -agg_ip ]
            set originator_id 	  [ $rb cget -originator_id ]
            set communities 	  [ $rb cget -communities ]
            set flag_label 		  [ $rb cget -flag_label ]
            set label_mode 		  [ $rb cget -label_mode ]
            set user_label 		  [ $rb cget -user_label ]
            set enable_as_path    [ $rb cget -enable_as_path ]
            set as_path_type      [ $rb cget -as_path_type ]
			set as_path           [ $rb cget -as_path ]
			Deputs "num:$num, step:$step, prefix_len:$prefix_len, start:$start, type:$type"

			Deputs "deviceGroup:$deviceGroup"
			set networkGroupObj [ixNet add $deviceGroup "networkGroup"]
			ixNet commit
			set networkGroupObj [ ixNet remapIds $networkGroupObj ]
            Deputs "networkGroupObj:$networkGroupObj"
			set routeBlock($rb) $networkGroupObj
			lappend routeBlock(obj) $rb
			Deputs "routeBlock(obj):$routeBlock(obj)"

            if { $num != "" } {
                ixNet setA $networkGroupObj -multiplier $num
                ixNet commit
            }
            if { $start != "" } {
                if {$type == "ipv4"} {
                    set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
                    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
		            ixNet commit
                }
                if {$type == "ipv6"} {
                    set ipPoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
                    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
		            ixNet commit
		        }
		        set connector [ixNet add $ipPoolObj connector]
                ixNet setA $connector -connectedTo $bgpHandle
                ixNet commit
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -start $start -direction increment
                ixNet commit
            }
            if { $prefix_len != "" } {
                if {$type == "ipv4"} {
                    if {[string first "." $prefix_len] != -1} {
                        set pLen [SubnetToPrefixlenV4 $prefix_len]
                    } else {
                        set pLen $prefix_len
                    }
                } else {
                    set pLen $prefix_len
                }
                set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
			    SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
                #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
                #ixNet commit
            }
            if { $step != "" } {
                set stepvalue [GetIpV46Step $type $pLen $step]
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
                ixNet commit
            }
            set bgpIpRouteObj ""
            set bgpV6IpRouteObj ""
            if {[llength [ixNet getL $ipPoolObj bgpV6IPRouteProperty]] != 0} {
                set bgpV6IpRouteObj [ixNet getL $ipPoolObj bgpV6IPRouteProperty]
            }
            if {[llength [ixNet getL $ipPoolObj bgpIPRouteProperty]] != 0} {
                set bgpIpRouteObj [ixNet getL $ipPoolObj bgpIPRouteProperty]
            }
            if { $origin != "" } {
                #origin are igp/egp/incomplete
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableOrigin] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableOrigin" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableOrigin]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -origin] -pattern]
			        SetMultiValues $bgpIpRouteObj "-origin" $ipPattern $origin
                    #ixNet setA [ixNet getA $bgpIpRouteObj -origin]/singleValue -value $origin
                }
                if { $bgpV6IpRouteObj != ""} {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableOrigin] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableOrigin" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableOrigin]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -origin] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-origin" $ipPattern $origin
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -origin]/singleValue -value $origin
                }
                ixNet commit
            }

            if { $nexthop != "" } {
                #nexthop is ipv4/ipv6 ip
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableNextHop] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableNextHop" $ipPattern True
			        #ixNet setA [ixNet getA $bgpIpRouteObj -enableNextHop]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -nextHopType] -pattern]
			        SetMultiValues $bgpIpRouteObj "-nextHopType" $ipPattern manual
                    #ixNet setA [ixNet getA $bgpIpRouteObj -nextHopType]/singleValue -value manual
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -nextHopIPType] -pattern]
			        SetMultiValues $bgpIpRouteObj "-nextHopIPType" $ipPattern $type
                    #ixNet setA [ixNet getA $bgpIpRouteObj -nextHopIPType]/singleValue -value $type
                    if { $type == "ipv4" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -ipv4NextHop] -pattern]
			            SetMultiValues $bgpIpRouteObj "-ipv4NextHop" $ipPattern $nexthop
                        #ixNet setA [ixNet getA $bgpIpRouteObj -ipv4NextHop]/singleValue -value $nexthop
                    } else {
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -ipv6NextHop] -pattern]
			            SetMultiValues $bgpIpRouteObj "-ipv6NextHop" $ipPattern $nexthop
                        #ixNet setA [ixNet getA $bgpIpRouteObj -ipv6NextHop]/singleValue -value $nexthop
                    }
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableNextHop] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableNextHop" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableNextHop]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -nextHopType] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-nextHopType" $ipPattern manual
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -nextHopType]/singleValue -value manual
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -nextHopIPType] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-nextHopIPType" $ipPattern $type
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -nextHopIPType]/singleValue -value $type
                    if { $type == "ipv4" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -ipv4NextHop] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-ipv4NextHop" $ipPattern $nexthop
                        #ixNet setA [ixNet getA $bgpV6IpRouteObj -ipv4NextHop]/singleValue -value $nexthop
                    } else {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -ipv6NextHop] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-ipv6NextHop" $ipPattern $nexthop
                        #ixNet setA [ixNet getA $bgpV6IpRouteObj -ipv6NextHop]/singleValue -value $nexthop
                    }
                }
                ixNet commit
            }

            if { $med != "" } {
                #med is integer value 10
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableMultiExitDiscriminator] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableMultiExitDiscriminator" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableMultiExitDiscriminator]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -multiExitDiscriminator] -pattern]
			        SetMultiValues $bgpIpRouteObj "-multiExitDiscriminator" $ipPattern $med
                    #ixNet setA [ixNet getA $bgpIpRouteObj -multiExitDiscriminator]/singleValue -value $med
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableMultiExitDiscriminator] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableMultiExitDiscriminator" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableMultiExitDiscriminator]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -multiExitDiscriminator] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-multiExitDiscriminator" $ipPattern $med
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -multiExitDiscriminator]/singleValue -value $med
                }
                ixNet commit
            }
            if {[info exists enable_as_path ]} {
                #Valid enum values are 0=dontincludelocalas 1=includelocalasasasseq 2=includelocalasasasset 3=includelocalasasasseqconfederation 4=includelocalasasassetconfederation 5=prependlocalastofirstsegment
                if {$bgpIpRouteObj != ""} {
                    if { $enable_as_path == "true" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableAsPathSegments] -pattern]
			            SetMultiValues $bgpIpRouteObj "-enableAsPathSegments" $ipPattern True
                        #ixNet setA [ixNet getA  $bgpIpRouteObj -enableAsPathSegments]/singleValue -value true
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -asSetMode] -pattern]
			            SetMultiValues $bgpIpRouteObj "-asSetMode" $ipPattern "dontincludelocalas"
                        #ixNet setA [ixNet getA  $bgpIpRouteObj -asSetMode]/singleValue -value "dontincludelocalas"
                    }
                }
                if {$bgpV6IpRouteObj != ""} {
                    if { $enable_as_path == "true" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableAsPathSegments] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-enableAsPathSegments" $ipPattern True
                        #ixNet setA [ixNet getA  $bgpV6IpRouteObj -enableAsPathSegments]/singleValue -value true
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -asSetMode] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-asSetMode" $ipPattern "dontincludelocalas"
                        #ixNet setA [ixNet getA  $bgpV6IpRouteObj -asSetMode]/singleValue -value "dontincludelocalas"
                    }
                }
                ixNet commit
            }

            if { $as_path != "" } {
                #values 1=asset 2=asseq 4=assetconfederation 3=asseqconfederation
                if { $bgpIpRouteObj != "" } {
                    set bgpAsPathObj [ixNet getL $bgpIpRouteObj bgpAsPathSegmentList]
                    set ipPattern [ixNet getA [ixNet getA $bgpAsPathObj -segmentType] -pattern]
			        SetMultiValues $bgpAsPathObj "-segmentType" $ipPattern $as_path
                    #ixNet setA [ixNet getA $bgpAsPathObj -segmentType]/singleValue -value $as_path
                }
                if { $bgpV6IpRouteObj != "" } {
                    set bgpAsPathObj [ixNet getL $bgpV6IpRouteObj bgpAsPathSegmentList]
                    set ipPattern [ixNet getA [ixNet getA $bgpAsPathObj -segmentType] -pattern]
			        SetMultiValues $bgpAsPathObj "-segmentType" $ipPattern $as_path
                    #ixNet setA [ixNet getA $bgpAsPathObj -segmentType]/singleValue -value $as_path
                }
            }

            if { $local_pref != "" } {
                #local_pref int value
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableLocalPreference] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableLocalPreference" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableLocalPreference]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -localPreference] -pattern]
			        SetMultiValues $bgpIpRouteObj "-localPreference" $ipPattern $local_pref
                    #ixNet setA [ixNet getA $bgpIpRouteObj -localPreference]/singleValue -value $local_pref
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableLocalPreference] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableLocalPreference" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableLocalPreference]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -localPreference] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-localPreference" $ipPattern $local_pref
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -localPreference]/singleValue -value $local_pref
                }
                ixNet commit
            }

            if { $cluster_list != "" } {
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableCluster] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableCluster" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableCluster]/singleValue -value True
                    set clusterNum 1
                    foreach clusterElement  $cluster_list {
                        if { [IsIPv4Address $clusterElement] } {
                            set clusterNum [llength $cluster_list]
                            break
                        }
                    }
                    ixNet setA $bgpIpRouteObj -noOfClusters $clusterNum
                    ixNet commit
                    set clusterObjList [ixNet getL $bgpIpRouteObj bgpClusterIdList]
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableCluster] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableCluster" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableCluster]/singleValue -value True
                    set clusterNum 1
                    foreach clusterElement  $cluster_list {
                        if { [IsIPv4Address $clusterElement] } {
                            set clusterNum [llength $cluster_list]
                            break
                        }
                    }
                    ixNet setA $bgpV6IpRouteObj -noOfClusters $clusterNum
                    ixNet commit
                    set clusterObjList [ixNet getL $bgpV6IpRouteObj bgpClusterIdList]
                }
                foreach cluster $cluster_list clusterObj $clusterObjList {
                    set ipPattern [ixNet getA [ixNet getA $clusterObj -clusterId] -pattern]
			        SetMultiValues $clusterObj "-clusterId" $ipPattern $cluster
                    #ixNet setA [ixNet getA $clusterObj -clusterId]/singleValue -value $cluster
                }
            }

            if { $flag_atomic_agg != "" } {
                # agg_as int value/agg_ip ipv4 ip
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableAggregatorId] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableAggregatorId" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableAggregatorId]/singleValue -value True
                    if { $agg_as != "" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -aggregatorAs] -pattern]
			            SetMultiValues $bgpIpRouteObj "-aggregatorAs" $ipPattern $agg_as
                        #ixNet setA [ixNet getA $bgpIpRouteObj -aggregatorAs]/singleValue -value $agg_as
                    }
                    if { $agg_ip != "" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -aggregatorId] -pattern]
			            SetMultiValues $bgpIpRouteObj "-aggregatorId" $ipPattern $agg_ip
                        #ixNet setA [ixNet getA $bgpIpRouteObj -aggregatorId]/singleValue -value $agg_ip
                    }
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableAggregatorId] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableAggregatorId" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableAggregatorId]/singleValue -value True
                    if { $agg_as != "" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -aggregatorAs] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-aggregatorAs" $ipPattern $agg_as
                        #ixNet setA [ixNet getA $bgpV6IpRouteObj -aggregatorAs]/singleValue -value $agg_as
                    }
                    if { $agg_ip != "" } {
                        set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -aggregatorId] -pattern]
			            SetMultiValues $bgpV6IpRouteObj "-aggregatorId" $ipPattern $agg_ip
                        #ixNet setA [ixNet getA $bgpV6IpRouteObj -aggregatorId]/singleValue -value $agg_ip
                    }
                }

            }

            if { $originator_id != "" } {
                #$originator_id ipv4 ip
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableOriginatorId] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableOriginatorId" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableOriginatorId]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -originatorId] -pattern]
			        SetMultiValues $bgpIpRouteObj "-originatorId" $ipPattern $originator_id
                    #ixNet setA [ixNet getA $bgpIpRouteObj -originatorId]/singleValue -value $originator_id
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableOriginatorId] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableOriginatorId" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableOriginatorId]/singleValue -value True
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -originatorId] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-originatorId" $ipPattern $originator_id
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -originatorId]/singleValue -value $originator_id
                }
                ixNet commit
            }

            if { $communities != "" } {
                #$communities hex value
                if { $bgpIpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpIpRouteObj -enableCommunity] -pattern]
			        SetMultiValues $bgpIpRouteObj "-enableCommunity" $ipPattern True
                    #ixNet setA [ixNet getA $bgpIpRouteObj -enableCommunity]/singleValue -value True
                    set hexcommunity ""
                    foreach element [split $communities : ] {
                        set hexcommunity $hexcommunity[Int2Hex $element 4]
                    }
                    #set communities [Hex2Int $hexcommunity]
                    ixNet setA $bgpIpRouteObj -noOfCommunities $communities
                }
                if { $bgpV6IpRouteObj != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6IpRouteObj -enableCommunity] -pattern]
			        SetMultiValues $bgpV6IpRouteObj "-enableCommunity" $ipPattern True
                    #ixNet setA [ixNet getA $bgpV6IpRouteObj -enableCommunity]/singleValue -value True
                    set hexcommunity ""
                    foreach element [split $communities : ] {
                        set hexcommunity $hexcommunity[Int2Hex $element 4]
                    }
                    #set communities [Hex2Int $hexcommunity]
                    ixNet setA $bgpV6IpRouteObj -noOfCommunities $communities
                }

            }

            ixNet commit
            ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
			$rb configure -handle $networkGroupObj
			$rb configure -portObj $portObj
			$rb configure -hPort $hPort
			$rb configure -protocol "bgp"
			$rb enable
		}
	}

    return [GetStandardReturnHeader]
}

body BgpSession::advertise_route { args } {
    global errorInfo
    global errNumber
    global LoadConfigMode
    set tag "body BgpSession::advertise_route [info script]"
    Deputs "----- TAG: $tag -----"

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
    #Deputs "advertise_route values of route_block is ::$route_block"
	if { [ info exists route_block ] } {
	    set networkGroupObj $routeBlock($route_block)
	    set ipPattern [ixNet getA [ixNet getA $networkGroupObj -enabled] -pattern]
	    SetMultiValues $networkGroupObj "-enabled" $ipPattern True
	    #ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value True
        #ixNet commit
	} else {
        if { $LoadConfigMode } {
            set devicehandle [GetDependentNgpfProtocolHandle $bgpHandle "deviceGroup"]
            set routeRangeList  [ixNet getL $devicehandle networkGroup]
            if { $routeRangeList != "" } {
                foreach rRangeObj $routeRangeList {
                    set ipPattern [ixNet getA [ixNet getA $rRangeObj -enabled] -pattern]
			        SetMultiValues $rRangeObj "-enabled" $ipPattern True
                    #ixNet setA [ixNet getA $rRangeObj -enabled]/singleValue -value True
                }
                ixNet commit
            }
            ## Checking for Ipv4 pool
            set vpnRouteRangeList ""
            if {$routeRangeList != "" } {
                foreach routeRangeObj $routeRangeList {
                    set ipv4PoolList [ixNet getL $routeRangeObj "ipv4PrefixPools"]
                    foreach ipv4PoolObj $ipv4PoolList {
                        set bgpL3VpnObj [ixNet getL $ipv4PoolObj "bgpL3VpnRouteProperty"]
                        set bgpV6L3VpnObj [ixNet getL $ipv4PoolObj "bgpV6L3VpnRouteProperty"]
                        if {$bgpL3VpnObj != "" || $bgpV6L3VpnObj != ""} {
                            lappend vpnRouteRangeList $routeRangeObj
                        }
                    }
                    set ipv6PoolList [ixNet getL $routeRangeObj "ipv6PrefixPools"]
                    foreach ipv6PoolObj $ipv6PoolList {
                        set bgpV6L3VpnObj [ixNet getL $ipv6PoolObj "bgpV6L3VpnRouteProperty"]
                        set bgpL3VpnObj [ixNet getL $ipv6PoolObj "bgpL3VpnRouteProperty"]
                        if {$bgpV6L3VpnObj != "" || $bgpL3VpnObj != ""} {
                            lappend vpnRouteRangeList $routeRangeObj
                        }
                    }
                }
            }
            if { $vpnRouteRangeList != "" } {
                foreach vpnRRange $vpnRouteRangeList {
                    ixNet setA $vpnRRange -enabled True
                }
            }
            ixNet commit
        } else {
                set devicehandle [GetDependentNgpfProtocolHandle $bgpHandle "deviceGroup"]
                set routeRangeList  [ixNet getL $devicehandle networkGroup]
                foreach hRouteBlock $routeRangeList {
                    Deputs "hRouteBlock : $hRouteBlock"
                    set ipPattern [ixNet getA [ixNet getA $hRouteBlock -enabled] -pattern]
			        SetMultiValues $hRouteBlock "-enabled" $ipPattern True
                    #ixNet setA [ixNet getA $hRouteBlock -enabled]/singleValue -value True
                }
        }
	}
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	return [GetStandardReturnHeader]

}

body BgpSession::withdraw_route { args } {
    global errorInfo
    global errNumber
    global LoadConfigMode
    set tag "body BgpSession::config [info script]"
    Deputs "----- TAG: $tag -----"

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }

	if { [ info exists route_block ] } {
	    set networkGroupObj $routeBlock($route_block)
	    set ipPattern [ixNet getA [ixNet getA $networkGroupObj -enabled] -pattern]
	    SetMultiValues $networkGroupObj "-enabled" $ipPattern False
	    #ixNet setA [ixNet getA $networkGroupObj -enabled]/singleValue -value False
        #ixNet commit
	} else {
         if { $LoadConfigMode } {
            #set devicehandle [$this cget -deviceHandle]
            set devicehandle [GetDependentNgpfProtocolHandle $bgpHandle "deviceGroup"]
            Deputs "devicehandle: $devicehandle"
            set routeRangeList  [ixNet getL $devicehandle networkGroup]
            if { $routeRangeList != "" } {
                foreach rRangeObj $routeRangeList {
                    set ipPattern [ixNet getA [ixNet getA $rRangeObj -enabled] -pattern]
			        SetMultiValues $rRangeObj "-enabled" $ipPattern False
                    #ixNet setA [ixNet getA $rRangeObj -enabled]/singleValue -value False
                }
                ixNet commit
            }
            ## Checking for Ipv4 pool
            set vpnRouteRangeList ""
            if {$routeRangeList != "" } {
                foreach routeRangeObj $routeRangeList {
                    set ipv4PoolList [ixNet getL $routeRangeObj "ipv4PrefixPools"]
                    foreach ipv4PoolObj $ipv4PoolList {
                        set bgpL3VpnObj [ixNet getL $ipv4PoolObj "bgpL3VpnRouteProperty"]
                        set bgpV6L3VpnObj [ixNet getL $ipv4PoolObj "bgpV6L3VpnRouteProperty"]
                        if {$bgpL3VpnObj != "" || $bgpV6L3VpnObj != ""} {
                            lappend vpnRouteRangeList $routeRangeObj
                        }
                    }
                    set ipv6PoolList [ixNet getL $routeRangeObj "ipv6PrefixPools"]
                    foreach ipv6PoolObj $ipv6PoolList {
                        set bgpV6L3VpnObj [ixNet getL $ipv6PoolObj "bgpV6L3VpnRouteProperty"]
                        set bgpL3VpnObj [ixNet getL $ipv6PoolObj "bgpL3VpnRouteProperty"]
                        if {$bgpV6L3VpnObj != "" || $bgpL3VpnObj != ""} {
                            lappend vpnRouteRangeList $routeRangeObj
                        }
                    }
                }
            }

            if { $vpnRouteRangeList != "" } {
                foreach vpnRRange $vpnRouteRangeList {
                    ixNet setA $vpnRRange -enabled False
                }
            }
            ixNet commit
        } else {
            set devicehandle [GetDependentNgpfProtocolHandle $bgpHandle "deviceGroup"]
            set routeRangeList  [ixNet getL $devicehandle networkGroup]
            foreach hRouteBlock $routeRangeList {
                set ipPattern [ixNet getA [ixNet getA $hRouteBlock -enabled] -pattern]
			    SetMultiValues $hRouteBlock "-enabled" $ipPattern False
                #ixNet setA [ixNet getA $hRouteBlock -enabled]/singleValue -value False
            }
        }
	}
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	return [GetStandardReturnHeader]

}

body BgpSession::get_stats {} {

    set tag "body BgpSession::get_stats [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
    puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 30000
    set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
    foreach viewObj $viewList {
        if {"::ixNet::OBJ-/statistics/view:\"BGP Peer Per Port\"" == $viewObj} {
            set view $viewObj
        }
        if {"::ixNet::OBJ-/statistics/view:\"BGP+ Peer Per Port\"" == $viewObj} {
            set view $viewObj
        }
    }
    Deputs "view:$view"
    set captionList             [ ixNet getA $view/page -columnCaptions ]
    Deputs "caption list:$captionList"
    set port_name [ lsearch -exact $captionList {Port} ]
    set session_conf [ lsearch -exact $captionList {Sessions Configured} ]
    set session_succ [ lsearch -exact $captionList {Sessions Up} ]
    set flap [ lsearch -exact $captionList {Session Flap Count} ]

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

body BgpSession::wait_session_up { args } {
    set tag "body BgpSession::wait_session_up [info script]"
Deputs "----- TAG: $tag -----"

	set timeout 300

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -timeout {
				set trans [ TimeTrans $value ]
                if { [ string is integer $trans ] } {
                    set timeout $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }

        }
    }

	set startClick [ clock seconds ]

	while { 1 } {
		set click [ clock seconds ]
		if { [ expr $click - $startClick ] >= $timeout } {
			return [ GetErrorReturnHeader "timeout" ]
		}

		set stats [ get_stats ]
		set initStats [ GetStatsFromReturn $stats session_conf ]
		set succStats [ GetStatsFromReturn $stats session_succ ]

		if { $succStats == $initStats && $initStats > 0 } {
			break
		}

		after 3000
	}

	return [GetStandardReturnHeader]

}

body SimRoute::config { args } {
    global errorInfo
    global errNumber
    set tag "body SimRoute::config [info script]"
    Deputs "----- TAG: $tag -----"

    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
                set route_block $value
            }
            -as_path {
                set as_path $value
            }
            -enable_as_path {
                set enable_as_path $value
            }
            -as_path_type {
                set as_path_type $value
                #"asSet"|"asSequence"|"asConfedSequence"|"asConfedSet"
            }
            -as_path_option {
                set as_path_option $value
                #noInclude|includeAsSeq|includeAsSet|includeAsSeqConf|includeAsSetConf|prependAs
            }
            -origin {
                set origin $value
            }
        }
    }

    set topoObj [ixNet getL [ixNet getRoot] topology]
    set deviceGroupObj [GetDependentNgpfProtocolHandle $hBgp "deviceGroup"]

    if { [ info exists route_block ] } {
        foreach rb $route_block {
            set num         [ $rb cget -num ]
            set step        [ $rb cget -step ]
            set prefix_len  [ $rb cget -prefix_len ]
            set start       [ $rb cget -start ]
            set type        [ $rb cget -type ]

            if { $handle == "" } {
                set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
                ixNet commit
                set networkGroupObj [ ixNet remapIds $networkGroupObj ]
                Deputs "networkGroupObj:$networkGroupObj"
            }

            set routeBlock($rb,handle) $networkGroupObj
            lappend routeBlock(obj) $rb
            Deputs "routeBlock(obj):$routeBlock(obj)"

            if { $num != "" } {
                ixNet setA $networkGroupObj -multiplier $num
                ixNet commit
            }
            if { $start != "" } {
                if {$type == "ipv4"} {
                    set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
                    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
                    ixNet commit
                    set ipPoolObj [ ixNet remapIds $ipPoolObj ]
                }
                if {$type == "ipv6"} {
                    set ipPoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
                    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
                    ixNet commit
                    set ipPoolObj [ ixNet remapIds $ipPoolObj ]
                }

                set connector [ixNet add $ipPoolObj connector]
                ixNet setA $connector -connectedTo $hBgp
                ixNet commit
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -start $start -direction increment
                ixNet commit
            }
            if { $prefix_len != "" } {
                if {$type == "ipv4"} {
                    if {[string first "." $prefix_len] != -1} {
                        set pLen [SubnetToPrefixlenV4 $prefix_len]
                    } else {
                        set pLen $prefix_len
                    }
                } else {
                    set pLen $prefix_len
                }
                #not accepting 255.255.255.0 for prefix_len, but taking integer value
                set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
			    SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
                #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
                ixNet commit
            }
            if { $step != "" } {
                set stepvalue [GetIpV46Step $type $pLen $step]
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
                ixNet commit
            }
            ixNet commit

            $rb configure -handle $handle
            $rb configure -portObj $portObj
            $rb configure -hPort $hPort
            $rb configure -protocol "bgp"
            $rb enable
        }
    }
    ## Below are the configurable options ##
    ## as_path -->  <segment_type>
    ## enable_as_path --> enableAsPathSegments
    ## as_path_type -->  <segment_type>
    ## as_path_option --> asSetMode
    ## origin --> origin
    set bgpSimRouteObj ""
    set bgpV6SimRouteObj ""

    if {[string first "ipv4" $hBgp] != -1} {
        set ip_version "ipv4"
    }
    if {[string first "ipv6" $hBgp] != -1} {
        set ip_version "ipv6"
    }
    set networkGrpList [ixNet getL $deviceGroupObj "networkGroup"]
    if {$networkGrpList != "" } {
        foreach networkGrpObj $networkGrpList {
            if {$ip_version == "ipv4"} {
                set ipPoolObj [ixNet getL $networkGrpObj "ipv4PrefixPools"]
                if { $ipPoolObj == "" } {
                    set ipPoolObj [ixNet getL $networkGrpObj "ipv6PrefixPools"]
                }
                if {[llength [ixNet getL $ipPoolObj bgpIPRouteProperty]] != 0} {
                    set bgpSimRouteObj [ixNet getL $ipPoolObj bgpIPRouteProperty]
                }
            }
            if {$ip_version == "ipv6"} {
                set ipPoolObj [ixNet getL $networkGrpObj "ipv6PrefixPools"]
                if { $ipPoolObj == "" } {
                    set ipPoolObj [ixNet getL $networkGrpObj "ipv4PrefixPools"]
                }
                if {[llength [ixNet getL $ipPoolObj bgpV6IPRouteProperty]] != 0} {
                    set bgpV6SimRouteObj [ixNet getL $ipPoolObj bgpV6IPRouteProperty]
                }
            }
        }
    }

    if { [info exists origin ]} {
        if {$bgpSimRouteObj != ""} {
            set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -enableOrigin] -pattern]
			SetMultiValues $bgpSimRouteObj "-enableOrigin" $ipPattern True
            #ixNet setA [ixNet getA $bgpSimRouteObj -enableOrigin]/singleValue -value True
            set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -origin] -pattern]
			SetMultiValues $bgpSimRouteObj "-origin" $ipPattern $origin
            #ixNet setA [ixNet getA $bgpSimRouteObj -origin]/singleValue -value $origin
        }

        if {$bgpV6SimRouteObj != ""} {
            set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -enableOrigin] -pattern]
			SetMultiValues $bgpV6SimRouteObj "-enableOrigin" $ipPattern True
            #ixNet setA [ixNet getA $bgpV6SimRouteObj -enableOrigin]/singleValue -value True
            set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -origin] -pattern]
			SetMultiValues $bgpV6SimRouteObj "-origin" $ipPattern $origin
            #ixNet setA [ixNet getA $bgpV6SimRouteObj -origin]/singleValue -value $origin
        }
        #origin are igp/egp/incomplete
    }

    if {[info exists enable_as_path ]} {
        if {$bgpSimRouteObj != ""} {
            if { $enable_as_path == "true" } {
                set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -enableAsPathSegments] -pattern]
			    SetMultiValues $bgpSimRouteObj "-enableAsPathSegments" $ipPattern True
                #ixNet setA [ixNet getA  $bgpSimRouteObj -enableAsPathSegments]/singleValue -value true
            } elseif {$enable_as_path == "false" } {
                set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -enableAsPathSegments] -pattern]
			    SetMultiValues $bgpSimRouteObj "-enableAsPathSegments" $ipPattern False
                #ixNet setA [ixNet getA  $bgpSimRouteObj -enableAsPathSegments]/singleValue -value false
            }
        }
        if {$bgpV6SimRouteObj != ""} {
            if { $enable_as_path == "true" } {
                set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -enableAsPathSegments] -pattern]
			    SetMultiValues $bgpV6SimRouteObj "-enableAsPathSegments" $ipPattern True
                #ixNet setA [ixNet getA  $bgpV6SimRouteObj -enableAsPathSegments]/singleValue -value true
            } elseif {$enable_as_path == "false" } {
                set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -enableAsPathSegments] -pattern]
			    SetMultiValues $bgpV6SimRouteObj "-enableAsPathSegments" $ipPattern False
                #ixNet setA [ixNet getA  $bgpV6SimRouteObj -enableAsPathSegments]/singleValue -value false
            }
        }
    }

    if { [info exists as_path_type ] } {
        if { $as_path_type != "" } {
            set as_path_type [string tolower $as_path_type]
            if {$bgpSimRouteObj != ""} {
                set bgpAsPathObj [ixNet getL $bgpSimRouteObj bgpAsPathSegmentList]
                set ipPattern [ixNet getA [ixNet getA $bgpAsPathObj -segmentType] -pattern]
			    SetMultiValues $bgpAsPathObj "-segmentType" $ipPattern $as_path_type
                #ixNet setA [ixNet getA $bgpAsPathObj -segmentType]/singleValue -value $as_path_type
            }
            if {$bgpV6SimRouteObj != ""} {
                set bgpAsPathObj [ixNet getL $bgpV6SimRouteObj bgpAsPathSegmentList]
                set ipPattern [ixNet getA [ixNet getA $bgpAsPathObj -segmentType] -pattern]
			    SetMultiValues $bgpAsPathObj "-segmentType" $ipPattern $as_path_type
                #ixNet setA [ixNet getA $bgpAsPathObj -segmentType]/singleValue -value $as_path_type
            }
        }
    }

    if {[info exist as_path_option]} {
        if {$as_path_option != ""} {
            if {$bgpSimRouteObj != ""} {
                set ipPattern [ixNet getA [ixNet getA $bgpSimRouteObj -asSetMode] -pattern]
			    SetMultiValues $bgpSimRouteObj "-asSetMode" $ipPattern $as_path_option
                #ixNet setA [ixNet getA  $bgpSimRouteObj -asSetMode]/singleValue -value $as_path_option
            }
            if {$bgpV6SimRouteObj != ""} {
                set ipPattern [ixNet getA [ixNet getA $bgpV6SimRouteObj -asSetMode] -pattern]
			    SetMultiValues $bgpV6SimRouteObj "-asSetMode" $ipPattern $as_path_option
                #ixNet setA [ixNet getA  $bgpV6SimRouteObj -asSetMode]/singleValue -value $as_path_option
            }
        }
    }
    ixNet commit

    return [GetStandardReturnHeader]
}

class Vpn {
    inherit RouterNgpfEmulationObject

	public variable bgpObj
	public variable hBgp
    public variable bgpVrfObj
	public variable portObj
	public variable ip_version
    public variable bgpImportObjList
	
    constructor { bgp } {       
		
		set tag "body Vpn::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set bgpObj $bgp
		Deputs "value received at constructor is $bgp"
		set hBgp [ $bgp cget -bgpHandle ]

		set portObj [ $bgp cget -portObj ]
		set hPort	[ $bgp cget -hPort ]
		set ip_version [$bgp cget -version]
		Deputs "bgpObj : $bgpObj..hBgp: $hBgp..portObj: $portObj..hPort: $hPort"
		set handle ""
		reborn
	}

	method reborn {} {
		global errNumber

		set tag "body Vpn::reborn [info script]"
        Deputs "----- TAG: $tag -----"

		if { [ catch {
			set hBgp   [ $bgpObj cget -bgpHandle ]
		} ] } {
			error "$errNumber(1) BGP Object in Vpn ctor"
		}		
	     #-- add bgpVrf protocol
        if {[string first "ipv4" $hBgp] != -1} {
            set ip_version "ipv4"
        }
        if {[string first "ipv6" $hBgp] != -1} {
            set ip_version "ipv6"
        }
		if { $ip_version == "ipv4" } {
            set bgpVrfObj [ ixNet getL $hBgp bgpVrf ]
		    if { [ llength $bgpVrfObj ] == 0 } {
                set bgpVrfObj [ ixNet add $hBgp bgpVrf]
                ixNet commit
                set bgpVrfObj [ ixNet remapIds $bgpVrfObj ]
            }
		} else {
		    set bgpVrfObj [ ixNet getL $hBgp bgpV6Vrf ]
		    if { [ llength $bgpVrfObj ] == 0 } {
                set bgpVrfObj [ ixNet add $hBgp bgpV6Vrf]
                ixNet commit
                set bgpVrfObj [ ixNet remapIds $bgpVrfObj ]
			} 
		}		
		
        set bgpImportObjList [ ixNet getL $bgpVrfObj bgpExportRouteTargetList ]
		array set routeBlock [ list ]				
		set protocol vpn
	}
    method config { args } {}
	method set_route { args } {}
}

body Vpn::config { args } {
    global errorInfo
    global errNumber
    set tag "body Vpn::config [info script]"
    Deputs "----- TAG: $tag -----"

	if { $handle == "" } {
		reborn
	}

    #param collection
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -rt {
            	set rt $value
            }
			-rd {
				set rd $value
			}
			-rd_as {
				set rd_as $value
			}
			-rd_ip {
				set rd_ip $value
			}
			-rt_type {
				set rt_type $value
			}
			-rt_ip {
				set rt_ip $value
			}
			-as_path {
				set as_path $value
			}
			-as_path_type {
				set as_path_type $value
			}
			-local_pref {
				set local_pref $value
			}
			-next_hop {
				set next_hop $value
			}
			-route_block {
				set route_block $value
			}
		}
    }

    if { [ info exists rt ] } {
        set rtSplit [ split $rt ":" ]
        set asNumber [ lindex $rtSplit 0 ]
        set assignedNumber [ lindex $rtSplit 1 ]
        if { [ IsIPv4Address $asNumber ] } {
            set rtList "\{ ip 0 $asNumber $assignedNumber \}"
            set asType "ip"
            set ipAddr $asNumber
            set asNumber "0" 
        } else {
            set rtList "\{ as $asNumber 0.0.0.0 $assignedNumber \}"
            set asType "as"
            set ipAddr "0.0.0.0"
        }

        if { $asNumber != "" } {
            set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetAsNumber] -pattern]
			SetMultiValues $bgpImportObjList "-targetAsNumber" $ipPattern $asNumber
            #ixNet setA [ixNet getA $bgpImportObjList -targetAsNumber]/singleValue -value $asNumber
        }

        if { $assignedNumber != "" } {
	        set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetAssignedNumber] -pattern]
			SetMultiValues $bgpImportObjList "-targetAssignedNumber" $ipPattern $assignedNumber
	        #ixNet setA [ixNet getA $bgpImportObjList -targetAssignedNumber]/singleValue -value $assignedNumber
        }	
		
		if { $asType != "" } {
	        set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetType] -pattern]
			SetMultiValues $bgpImportObjList "-targetType" $ipPattern $asType
	        #ixNet setA [ixNet getA $bgpImportObjList -targetType]/singleValue -value $asType
        }
		if { $ipAddr != "" } {
	        set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetIpAddress] -pattern]
			SetMultiValues $bgpImportObjList "-targetIpAddress" $ipPattern $ipAddr
	        #ixNet setA [ixNet getA $bgpImportObjList -targetIpAddress]/singleValue -value $ipAddr
        }		
		
	}
    set_route -route_block $route_block -rd $rd	
	
	ixNet commit
    return [GetStandardReturnHeader]

}

body Vpn::set_route { args } {

    global errorInfo
    global errNumber
    set tag "body Vpn::config [info script]"
    Deputs "----- TAG: $tag -----"

	set rdType as
	set asNumber 100
	set assignedNumber 1
	set ipNumber 0.0.0.0

    set deviceGroupObj [GetDependentNgpfProtocolHandle $bgpVrfObj "deviceGroup"]
    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-rd {
				set rd $value
			}
            -route_block {
            	set route_block $value
            }
        }
    }

	if { [ info exists route_block ] } {

		if { [ info exists rd ] } {
			set rdSplit [ split $rd ":" ]
			set asIpNumber		[ lindex $rdSplit 0 ]
			set assignedNumber	[ lindex $rdSplit 1 ]
			
			if { [ IsIPv4Address $asIpNumber ]} {
				set rdType ip
				set ipNumber $asIpNumber
			} else {
				set rdType as
				set asNumber $asIpNumber
			}
		}

		foreach rb $route_block {
			set num 		[ $rb cget -num ]
			set step 		[ $rb cget -step ]
			set prefix_len 	[ $rb cget -prefix_len ]
			set start 		[ $rb cget -start ]
			set type 		[ $rb cget -type ]

			puts "num:$num, step:$step, prefix_len:$prefix_len, start:$start, type:$type"

            if { $handle == "" } {
                set networkGroupObjList [ ixNet getL $deviceGroupObj "networkGroup" ]
                if { [ llength $networkGroupObjList ] != 0 } {
                    foreach networkGroupObj $networkGroupObjList {
                        if {$type == "ipv4"} {
                            set ipPoolObj [ixNet getL $networkGroupObj "ipv4PrefixPools"]
                            if { [ llength $ipPoolObj ] != 0 } {
                                if {[llength [ixNet getL $ipPoolObj bgpL3VpnRouteProperty]] != 0} {
                                    set networkGroupObj $networkGroupObj
                                    break
                                } else {
                                    set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
                                    ixNet commit
                                    set networkGroupObj [ ixNet remapIds $networkGroupObj ]
                                }
                            }
                        } else {
                            set ipPoolObj [ixNet getL $networkGroupObj "ipv6PrefixPools"]
                            if { [ llength $ipPoolObj ] != 0 } {
                                if {[llength [ixNet getL $ipPoolObj bgpV6L3VpnRouteProperty]] != 0} {
                                    set networkGroupObj $networkGroupObj
                                    break
                                } else {
                                    set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
                                    ixNet commit
                                    set networkGroupObj [ ixNet remapIds $networkGroupObj ]
                                }
                            }
                        }
                    }
                } else {
                    set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
                    ixNet commit
                    set networkGroupObj [ ixNet remapIds $networkGroupObj ]
                }
			}

            set routeBlock($rb,handle) $networkGroupObj
			lappend routeBlock(obj) $rb			

           if { $num != "" } {
                ixNet setA $networkGroupObj -multiplier $num
                ixNet commit
            }
			
			if { $start != "" } {
                if {$type == "ipv4"} {
                    set ipPoolObj [ixNet getL $networkGroupObj "ipv4PrefixPools"]
                    if { [ llength $ipPoolObj ] == 0 } {
                        set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
                        ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
                        ixNet commit
                    } else {
                        ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
                        ixNet commit
                    }
                }
                if {$type == "ipv6"} {
                    set ipPoolObj [ixNet getL $networkGroupObj "ipv6PrefixPools"]
                    if { [ llength $ipPoolObj ] == 0 } {
                        set ipPoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
                        ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
                        ixNet commit
                    } else {
                        ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
                        ixNet commit
                    }
		        }
		        set connector [ixNet add $ipPoolObj connector]
                ixNet setA $connector -connectedTo $bgpVrfObj
                ixNet commit
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -start $start -direction increment
                ixNet commit
            }
			set pLen 24
            if { $prefix_len != "" } {
                if {$type == "ipv4"} {
                    if {[string first "." $prefix_len] != -1} {
                        set pLen [SubnetToPrefixlenV4 $prefix_len]
                    } else {
                        set pLen $prefix_len
                    }
                } else {
                    set pLen $prefix_len
                }
                set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
			    SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
                #ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen
                ixNet commit
            }
            if { $step != "" } {
                set stepvalue [GetIpV46Step $type $pLen $step]
                ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
                ixNet commit
            }
 	   
	        set bgpVpnRouteObj ""
            set bgpV6VpnRouteObj ""
            if {[llength [ixNet getL $ipPoolObj bgpV6L3VpnRouteProperty]] != 0} {
                set bgpV6VpnRouteObj [ixNet getL $ipPoolObj bgpV6L3VpnRouteProperty]
            }
            if {[llength [ixNet getL $ipPoolObj bgpL3VpnRouteProperty]] != 0} {
                set bgpVpnRouteObj [ixNet getL $ipPoolObj bgpL3VpnRouteProperty]
            }
			
            if { $bgpVpnRouteObj != "" } {
                if { $asNumber != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherAsNumber] -pattern]
			        SetMultiValues $bgpVpnRouteObj "-distinguisherAsNumber" $ipPattern $asNumber
                    #ixNet setA [ ixNet getA $bgpVpnRouteObj -distinguisherAsNumber]/singleValue -value $asNumber
                }

                if { $rdType != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherType] -pattern]
			        SetMultiValues $bgpVpnRouteObj "-distinguisherType" $ipPattern $rdType
                    #ixNet setA [ ixNet getA $bgpVpnRouteObj -distinguisherType]/singleValue -value $rdType
                }	
		
  		        if { $ipNumber != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherIpAddress] -pattern]
			        SetMultiValues $bgpVpnRouteObj "-distinguisherIpAddress" $ipPattern $ipNumber
                    #ixNet setA [ ixNet getA $bgpVpnRouteObj -distinguisherIpAddress]/singleValue -value $ipNumber
                }	
		        if { $assignedNumber != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherAssignedNumber] -pattern]
			        SetMultiValues $bgpVpnRouteObj "-distinguisherAssignedNumber" $ipPattern $assignedNumber
                    #ixNet setA [ ixNet getA $bgpVpnRouteObj -distinguisherAssignedNumber]/singleValue -value $assignedNumber
                }
		    ixNet commit

            }
            if { $bgpV6VpnRouteObj != ""} {
                if { $asNumber != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6VpnRouteObj -distinguisherAsNumber] -pattern]
			        SetMultiValues $bgpV6VpnRouteObj "-distinguisherAsNumber" $ipPattern $asNumber
                    #ixNet setA [ ixNet getA $bgpV6VpnRouteObj -distinguisherAsNumber]/singleValue -value $asNumber
                }

                if { $rdType != "" } {
                   set ipPattern [ixNet getA [ixNet getA $bgpV6VpnRouteObj -distinguisherType] -pattern]
			       SetMultiValues $bgpV6VpnRouteObj "-distinguisherType" $ipPattern $rdType
                   #ixNet setA [ ixNet getA $bgpV6VpnRouteObj -distinguisherType]/singleValue -value $rdType
                }	
		
	   	        if { $ipNumber != "" } {
                   set ipPattern [ixNet getA [ixNet getA $bgpV6VpnRouteObj -distinguisherIpAddress] -pattern]
			       SetMultiValues $bgpV6VpnRouteObj "-distinguisherIpAddress" $ipPattern $ipNumber
                   #ixNet setA [ ixNet getA $bgpV6VpnRouteObj -distinguisherIpAddress]/singleValue -value $ipNumber
                }	
		        if { $assignedNumber != "" } {
                    set ipPattern [ixNet getA [ixNet getA $bgpV6VpnRouteObj -distinguisherAssignedNumber] -pattern]
			        SetMultiValues $bgpV6VpnRouteObj "-distinguisherAssignedNumber" $ipPattern $assignedNumber
                    #ixNet setA [ ixNet getA $bgpV6VpnRouteObj -distinguisherAssignedNumber]/singleValue -value $assignedNumber
                }
			
			ixNet commit

            }
			#$rb configure -handle $hRouteBlock
			$rb configure -portObj $portObj
			$rb configure -hPort $hPort
			$rb configure -protocol "bgp"
			$rb enable
		}	
	
    }	
    return [GetStandardReturnHeader]
}

# =======================
# Neighbor Range
# =======================
# Child Lists:
	# bgp4VpnBgpAdVplsRange (kLegacyUnknown : getList)
	# interfaceLearnedInfo (kLegacyUnknown : getList)
	# l2Site (kLegacyUnknown : getList)
	# l3Site (kLegacyUnknown : getList)
	# learnedFilter (kLegacyUnknown : getList)
	# learnedInformation (kLegacyUnknown : getList)
	# mplsRouteRange (kLegacyUnknown : getList)
	# opaqueRouteRange (kLegacyUnknown : getList)
	# routeImportOptions (kLegacyUnknown : getList)
	# routeRange (kLegacyUnknown : getList)
	# userDefinedAfiSafi (kLegacyUnknown : getList)
# Attributes:
	# -asNumMode (readOnly=False, type=(kEnumValue)=fixed,increment, deprecated)
	# -authentication (readOnly=False, type=(kEnumValue)=md5,null)
	# -bfdModeOfOperation (readOnly=False, type=(kEnumValue)=multiHop,singleHop)
	# -bgpId (readOnly=False, type=(kIP))
	# -dutIpAddress (readOnly=False, type=(kIP))
	# -enable4ByteAsNum (readOnly=False, type=(kBool))
	# -enableActAsRestarted (readOnly=False, type=(kBool))
	# -enableBfdRegistration (readOnly=False, type=(kBool))
	# -enableBgpId (readOnly=False, type=(kBool))
	# -enabled (readOnly=False, type=(kBool))
	# -enableDiscardIxiaGeneratedRoutes (readOnly=False, type=(kBool))
	# -enableGracefulRestart (readOnly=False, type=(kBool))
	# -enableLinkFlap (readOnly=False, type=(kBool))
	# -enableNextHop (readOnly=False, type=(kBool))
	# -enableOptionalParameters (readOnly=False, type=(kBool))
	# -enableSendIxiaSignatureWithRoutes (readOnly=False, type=(kBool))
	# -enableStaggeredStart (readOnly=False, type=(kBool))
	# -holdTimer (readOnly=False, type=(kInteger))
	# -interfaces (readOnly=False, type=(kObjref)=null,/vport/interface,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ipEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ipEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernetEndpoint/range)
	# -interfaceStartIndex (readOnly=False, type=(kInteger))
	# -interfaceType (readOnly=False, type=(kString))
	# -ipV4Mdt (readOnly=False, type=(kBool))
	# -ipV4Mpls (readOnly=False, type=(kBool))
	# -ipV4MplsVpn (readOnly=False, type=(kBool))
	# -ipV4Multicast (readOnly=False, type=(kBool))
	# -ipV4MulticastVpn (readOnly=False, type=(kBool))
	# -ipV4Unicast (readOnly=False, type=(kBool))
	# -ipV6Mpls (readOnly=False, type=(kBool))
	# -ipV6MplsVpn (readOnly=False, type=(kBool))
	# -ipV6Multicast (readOnly=False, type=(kBool))
	# -ipV6MulticastVpn (readOnly=False, type=(kBool))
	# -ipV6Unicast (readOnly=False, type=(kBool))
	# -isAsbr (readOnly=False, type=(kBool))
	# -isInterfaceLearnedInfoAvailable (readOnly=True, type=(kBool))
	# -isLearnedInfoRefreshed (readOnly=True, type=(kBool))
	# -linkFlapDownTime (readOnly=False, type=(kInteger))
	# -linkFlapUpTime (readOnly=False, type=(kInteger))
	# -localAsNumber (readOnly=False, type=(kString))
	# -localIpAddress (readOnly=False, type=(kIP))
	# -md5Key (readOnly=False, type=(kString))
	# -nextHop (readOnly=False, type=(kIPv4))
	# -numUpdatesPerIteration (readOnly=False, type=(kInteger))
	# -rangeCount (readOnly=False, type=(kInteger))
	# -remoteAsNumber (readOnly=False, type=(kInteger64), deprecated)
	# -restartTime (readOnly=False, type=(kInteger))
	# -staggeredStartPeriod (readOnly=False, type=(kInteger))
	# -staleTime (readOnly=False, type=(kInteger))
	# -tcpWindowSize (readOnly=False, type=(kInteger))
	# -trafficGroupId (readOnly=False, type=(kObjref)=null,/traffic/trafficGroup)
	# -ttlValue (readOnly=False, type=(kInteger))
	# -type (readOnly=False, type=(kEnumValue)=external,internal)
	# -updateInterval (readOnly=False, type=(kInteger))
	# -vpls (readOnly=False, type=(kBool))
# Execs:
	# getInterfaceAccessorIfaceList((kObjref)=/vport/protocols/bgp/neighborRange)
	# getInterfaceLearnedInfo((kObjref)=/vport/protocols/bgp/neighborRange)
	# refreshLearnedInfo((kObjref)=/vport/protocols/bgp/neighborRange)

# ====================
# Route Range
# ====================
# Child Lists:
	# asSegment (kLegacyUnknown : getList)
	# cluster (kLegacyUnknown : getList)
	# community (kLegacyUnknown : getList)
	# extendedCommunity (kLegacyUnknown : getList)
	# flapping (kLegacyUnknown : getList)
# Attributes:
	# -aggregatorAsNum (readOnly=False, type=(kInteger64))
	# -aggregatorIpAddress (readOnly=False, type=(kIP))
	# -asPathSetMode (readOnly=False, type=(kEnumValue)=includeAsSeq,includeAsSeqConf,includeAsSet,includeAsSetConf,noInclude,prependAs)
	# -enableAggregator (readOnly=False, type=(kBool))
	# -enableAggregatorIdIncrementMode (readOnly=False, type=(kBool))
	# -enableAsPath (readOnly=False, type=(kBool))
	# -enableAtomicAttribute (readOnly=False, type=(kBool))
	# -enableCluster (readOnly=False, type=(kBool))
	# -enableCommunity (readOnly=False, type=(kBool))
	# -enabled (readOnly=False, type=(kBool))
	# -enableGenerateUniqueRoutes (readOnly=False, type=(kBool))
	# -enableIncludeLoopback (readOnly=False, type=(kBool))
	# -enableIncludeMulticast (readOnly=False, type=(kBool))
	# -enableLocalPref (readOnly=False, type=(kBool))
	# -enableMed (readOnly=False, type=(kBool))
	# -enableNextHop (readOnly=False, type=(kBool))
	# -enableOrigin (readOnly=False, type=(kBool))
	# -enableOriginatorId (readOnly=False, type=(kBool))
	# -enableProperSafi (readOnly=False, type=(kBool))
	# -enableTraditionalNlriUpdate (readOnly=False, type=(kBool))
	# -endOfRib (readOnly=False, type=(kBool))
	# -fromPacking (readOnly=False, type=(kInteger))
	# -fromPrefix (readOnly=False, type=(kInteger))
	# -ipType (readOnly=False, type=(kEnumValue)=ipAny,ipv4,ipv6)
	# -iterationStep (readOnly=False, type=(kInteger))
	# -localPref (readOnly=False, type=(kInteger))
	# -med (readOnly=False, type=(kInteger64))
	# -networkAddress (readOnly=False, type=(kIP))
	# -nextHopIpAddress (readOnly=False, type=(kIP))
	# -nextHopIpType (readOnly=False, type=(kEnumValue)=ipAny,ipv4,ipv6)
	# -nextHopMode (readOnly=False, type=(kEnumValue)=fixed,incrementPerPrefix,nextHopIncrement)
	# -nextHopSetMode (readOnly=False, type=(kEnumValue)=sameAsLocalIp,setManually)
	# -numRoutes (readOnly=False, type=(kInteger))
	# -originatorId (readOnly=False, type=(kIP))
	# -originProtocol (readOnly=False, type=(kEnumValue)=egp,igp,incomplete)
	# -thruPacking (readOnly=False, type=(kInteger))
	# -thruPrefix (readOnly=False, type=(kInteger))
# Execs:
	# reAdvertiseRoutes((kObjref)=/vport/protocols/bgp/neighborRange/routeRange)

# ====================
# L3 VPN
# ====================
# (bin) 12 % ixNet help $port/protocols/bgp/neighborRange/l3Site
# Child Lists:
	# importTarget (kRequired : getList)
	# learnedRoute (kManaged : getList)
	# multicast (kRequired : getList)
	# multicastReceiverSite (kList : add, remove, getList)
	# multicastSenderSite (kList : add, remove, getList)
	# opaqueValueElement (kList : add, remove, getList)
	# target (kRequired : getList)
	# umhImportTarget (kRequired : getList)
	# umhSelectionRouteRange (kList : add, remove, getList)
	# umhTarget (kRequired : getList)
	# vpnRouteRange (kList : add, remove, getList)
# Attributes:
	# -enabled (readOnly=False, type=kBool)
	# -exposeEachVrfAsTrafficEndpoint (readOnly=False, type=kBool)
	# -includePmsiTunnelAttribute (readOnly=False, type=kBool)
	# -isLearnedInfoRefreshed (readOnly=True, type=kBool)
	# -mplsAssignedUpstreamLabel (readOnly=False, type=kInteger)
	# -multicastGroupAddressStep (readOnly=False, type=kIP)
	# -rsvpP2mpId (readOnly=False, type=kIP)
	# -rsvpTunnelId (readOnly=False, type=kInteger)
	# -sameRtAsL3SiteRt (readOnly=False, type=kBool)
	# -sameTargetListAsL3SiteTargetList (readOnly=False, type=kBool)
	# -trafficGroupId (readOnly=False, type=kObjref=null,/traffic/trafficGroup)
	# -tunnelType (readOnly=False, type=kEnumValue=tunnelTypePimGreRosenDraft,tunnelTypeRsvpP2mp,tunnelTypeMldpP2mp)
	# -useUpstreamAssignedLabel (readOnly=False, type=kBool)
	# -vrfCount (readOnly=False, type=kInteger64)
# Execs:
	# refreshLearnedInfo (kObjref=/vport/protocols/bgp/neighborRan
	
	# ixNet help $bgp/learnedFilter/capabilities
# Attributes:
	# -adVpls (readOnly=False, type=kBool)
	# -evpn (readOnly=False, type=kBool)
	# -fetchDetailedIpV4UnicastInfo (readOnly=False, type=kBool)
	# -fetchDetailedIpV6UnicastInfo (readOnly=False, type=kBool)
	# -ipV4Mpls (readOnly=False, type=kBool)
	# -ipV4MplsVpn (readOnly=False, type=kBool)
	# -ipV4Multicast (readOnly=False, type=kBool)
	# -ipV4MulticastMplsVpn (readOnly=False, type=kBool)
	# -ipV4MulticastVpn (readOnly=False, type=kBool)
	# -ipV4Unicast (readOnly=False, type=kBool)
	# -ipV6Mpls (readOnly=False, type=kBool)
	# -ipV6MplsVpn (readOnly=False, type=kBool)
	# -ipV6Multicast (readOnly=False, type=kBool)
	# -ipV6MulticastMplsVpn (readOnly=False, type=kBool)
	# -ipV6MulticastVpn (readOnly=False, type=kBool)
	# -ipV6Unicast (readOnly=False, type=kBool)
	# -vpls (readOnly=False, type=kBool)

