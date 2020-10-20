package require Itcl
package require registry
namespace import itcl::*

proc GetEnxNgpfInfo { args } {
   Deputs "GetEnxInfo:$args "
   global enx_portNameList
   global enx_portLocationList
   foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-portnamelist {
				set enx_portNameList $value
			}
            -portlocationlist {
				set enx_portLocationList $value
			}           
        }
    }

}
proc GetOspfNgpfRouterHandle {handle {option 0}} {
    set result [regexp {(.*)(topology:[0-9]+)/(deviceGroup:[0-9]+).*([0-9]):(.*)$} $handle match match1 match2 match3 match4]
	set devHandle [join $match1/$match2/$match3]
	Deputs "devHandle:$devHandle"
	if {$match4 == 2} {
        set returnHandle [ixNet getL $devHandle ospfv2Router]
		set version 2
    } elseif {$match4 == 3}  {
		set returnHandle [ixNet getL $devHandle ospfv3Router]
		set version 3
	}
	if {$option != 0} {
		return $version
	}
		return $returnHandle
}

proc CreateNgpfProtocolView {protocol {type "Per Port"}} {
    set r_no [expr {int(rand()*100000)}]
    set view [ixNet add /statistics view]
    ixNet setMultiAttribute $view -pageTimeout 25 \
                                                    -type layer23NextGenProtocol \
                                                    -caption view_$r_no \
                                                    -visible true -autoUpdate true \
                                                    -viewCategory NextGenProtocol
    ixNet commit
    set view [lindex [ixNet remapIds $view] 0]

    set advCv [ixNet add $view "advancedCVFilters"]
    ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                     -protocol \{$protocol\} \
                                                     -sortingStats {}
    ixNet commit
    set advCv [lindex [ixNet remapIds $advCv] 0]

    set ngp [ixNet add $view layer23NextGenProtocolFilter]
    ixNet setMultiAttribute $ngp -advancedFilterName \"No\ Filter\" \
                                                   -advancedCVFilter $advCv \
                                                   -protocolFilterIds [list ] -portFilterIds [list ]
    ixNet commit
    set ngp [lindex [ixNet remapIds $ngp] 0]

    set stats [ixNet getList $view statistic]
    foreach stat $stats {
         ixNet setA $stat -scaleFactor 1
		 ixNet setA $stat -enabled true
		 ixNet setA $stat -aggregationType sum
		 ixNet commit
    }
	ixNet setA $view -enabled true
	ixNet commit
    ixNet execute refresh $view
	return $view
	}

proc GetDependentNgpfProtocolHandle {handle option} {
    #set result [regexp {(.*)(topology:[0-9]+)\/(deviceGroup:[0-9]+)\/(ethernet:[0-9]+)\/([a-z|A-Z]+[0-9]?:[0-9]+)(.*)$} $handle match match1 match2 match3 match4 match5 match6]
    set result [regexp {(.*)(topology:[0-9]+)\/(deviceGroup:[0-9]+)\/(ethernet:[0-9]+)\/(.*)} $handle match match1 match2 match3 match4 match5 match6]
    Deputs "match $match match1 $match1 match2 $match2 match3 $match3 match4 $match4 match5 $match5 match6 $match6"
    set devHandle [join $match1/$match2/$match3]
    if {$option == "deviceGroup"} {
        return $devHandle
    } elseif {$option == "ethernet"} {
        set ethHandle [join $match1/$match2/$match3/$match4]
        return $ethHandle
    } elseif {$option == "ip"} {
        set ipHandle [join $match1/$match2/$match3/$match4/$match5]
        Deputs "returning ipHandle $ipHandle"
        return $ipHandle
    } elseif {$option == "networkGroup"} {
        set networkGroupHandles [ixNet getL $devHandle "networkGroup"]
        return $networkGroupHandles
    } elseif {$option == "isisL3Router"} {
        set isisRouterHandle [ixNet getL $devHandle isisL3Router]
        return $isisRouterHandle
    } elseif {$option == "isisL3"} {
        set ethHandle [join $match1/$match2/$match3/$match4]
        set isisHandle [ixNet getL $ethHandle isisL3]
        return $isisHandle
    } elseif {$option == "ipv4PrefixPools"} {
        set networkGroupHandles [ixNet getL $devHandle "networkGroup"]
        if {$networkGroupHandles == ""} {
            return ""
        }
        set ipv4PoolObj [ixNet getL $networkGroupHandles "ipv4PrefixPools"]
        return $ipv4PoolObj
    } elseif {$option == "ipv6PrefixPool"} {
        set networkGroupHandles [ixNet getL $devHandle "networkGroup"]
        if {$networkGroupHandles == ""} {
            return ""
        }
        set ipv6PoolObj [ixNet getL $networkGroupHandles "ipv6PrefixPools"]
        return $ipv6PoolObj
    }
}

## This proc creates required stack NGPF from root.
proc CreateProtoHandleFromRoot {port {stack ""} {ipVersion ""}} {

    set topoObj [ixNet add [ixNet getRoot] topology -vports $port]
    ixNet commit
    set deviceGroupObj [ixNet add $topoObj deviceGroup]
    ixNet commit
    ixNet setA $deviceGroupObj -multiplier "1"
    ixNet commit
    set ethObj [ixNet add $deviceGroupObj ethernet]
    ixNet commit
    if {$stack == ""} {
        set handle $ethObj
    } elseif {$ipVersion == "ipv4"} {
        set ipv4Obj [ixNet add $ethObj ipv4]
        ixNet commit
        set handle [ixNet add $ipv4Obj $stack]
        ixNet commit
    } elseif {$ipVersion == "ipv6"} {
        set ipv6Obj [ixNet add $ethObj ipv6]
        ixNet commit
        set handle [ixNet add $ipv6Obj $stack]
        ixNet commit
    } elseif {$ipVersion == ""} {
        set handle [ixNet add $ethObj $stack]
        ixNet commit
    }
    set handle [ixNet remapIds $handle]
    return $handle
}

proc GenerateProtocolsNgpfObjects { portObj } {
    set tag "body Port::gen_pro_objs [info script]"
    Deputs "----- TAG: $tag -----"
    
    set portObj [GetObject $portObj]
    set handle [$portObj cget -handle]
    set handleName [$portObj cget -handleName]
    set protocols [ixNet getL $handle protocols]
    set protocolList [list bfd bgp igmp isis ldp mld ospf ospfV3 static]
    foreach pro $protocolList {
        set protocol [ixNet getL $protocols $pro]
        # Special to handle static
        set enabled [ ixNet getA $protocol -enabled ]
        if { $pro == "static" && $enabled == "::ixNet::OK" } {
            set enabled true
        }
        if { $enabled } {
            switch -exact $pro {
                bfd {
                    set bfdR [ixNet getL $protocol router]
                    BfdSession ${handleName}/bfd $handleName $bfdR
                }
                bgp {
                    set bgpNR [ixNet getL $protocol neighborRange]
                    BgpSession ${handleName}/bgp $handleName $bgpNR
                }
                igmp {
                    set igmpH [ixNet getL $protocol host]
                    IgmpHost ${handleName}/igmp $handleName $igmpH
                }
                mld {
                    set mldH [ixNet getL $protocol host]
                    MldHost ${handleName}/mld $handleName $mldH
                }
                isis {
                    set isisR [ixNet getL $protocol router]
                    IsisSession ${handleName}/isis $handleName $isisR
                }
                ldp {
                    set ldpR [ixNet getL $protocol router]
                    LdpSession ${handleName}/ldp $handleName $ldpR
                }
                ospf {
                    set ospfR [ixNet getL $protocol router]
                    Ospfv2Session ${handleName}/ospf $handleName $ospfR
                }
                ospfV3 {
                    set ospfV3R [ixNet getL $protocol router]
                    Ospfv3Session ${handleName}/ospfV3 $handleName $ospfV3R
                }
                static {
                    set staticLan [ixNet getL $protocol lan]
                    Host ${handleName}/static $handleName $staticLan
                }
            }
        }
    }

    set protocolStack [ixNet getL $handle protocolStack]
    set protocolStackList [list ipEndpoint dhcpEndpoint dhcpServerEndpoint pppoxEndpoint]
    foreach proStack $protocolStackList {
        set ethernet [ixNet getL $protocolStack ethernet]
        if { [llength $ethernet] == 0 } {
            continue
        }
		
		foreach ethernet $ethernet {
			set stack [ixNet getL $ethernet $proStack]
			if { $stack != "" } {
				switch -exact $proStack {
					dhcpEndpoint {
						set ranges [ixNet getL $stack range]
						foreach range $ranges {
							set ipType [ixNet getA $range/dhcpRange -ipType]
							set objName [ixNet getA $range/dhcpRange -name]
							if { $ipType == "IPv4" } {
								Dhcpv4Host $objName $handleName $stack $range
							} elseif { $ipType == "IPv6" } {
								Dhcpv6Host $objName $handleName $stack $range
							}
						}
					}
					dhcpServerEndpoint {
						set ranges [ixNet getL $stack range]
						foreach range $ranges {
							set ipType [ixNet getA $range/dhcpServerRange -ipType]
							set objName [ixNet getA $range/dhcpServerRange -name]
							if { $ipType == "IPv4" } {
								Dhcpv4Server $objName $handleName $stack $range
							} elseif { $ipType == "IPv6" } {
								Dhcpv6Server $objName $handleName $stack $range
							}
						}
					}
					pppoxEndpoint {
						set ranges [ixNet getL $stack range]
						foreach range $ranges {
							set objName [ixNet getA $range/pppoxRange -name]
							PppoeHost $objName $handleName $stack $range
						}
					}
					ipEndpoint {
						set ranges [ixNet getL $stack range]
						foreach range $ranges {
							set objName [ixNet getA $range/ipRange -name]
							set ipRangeOptions [ixNet getL $protocolStack ipRangeOptions]
							if { [llength $ipRangeOptions] != 0 } {
								if { [ixNet getA $ipRangeOptions -ipv6AddressMode] == "autoconf" } {
									Ipv6AutoConfigHost $objName $handleName $stack $range
								} else {
									IPoEHost $objName $handleName $stack $range
								}
							}
						}
					}
				}
			}
		}
    }
}

proc GetIpV46Step { type pLen step} {
    if {$type == "ipv4"} {
        if {$pLen == 8} {
            set stepvalue [string replace "0.0.0.0" 0 0 $step]
        } elseif  {$pLen == 16} {
            set stepvalue [string replace "0.0.0.0" 2 2 $step]
        } elseif  {$pLen == 24} {
            set stepvalue [string replace "0.0.0.0" 4 4 $step]
        } else {
            set stepvalue [string replace "0.0.0.0" 6 6 $step]
        }
    } else {
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
    }
    return $stepvalue
}

proc GetAllPortNgpfObj {} {
    set portObj [list]
    set objList [ find objects ]
    foreach obj $objList {
        if { [ $obj isa Port ] } {
            lappend portObj [ $obj cget -handle ]
        }
    }
    
    return $portObj
}

proc GetValidNgpfHandleObj { objType handle { parentHnd "" } } {
    global ngpfMode
    set tag "GetValidNgpfHandleObj [info script]"
    Deputs "----- TAG: $tag -----"
	set index 0
	if { [ catch {
		set index [expr $index + $handle] 
	} err ] } {
		set index 0
	}
	
	switch -exact $objType {
		port {
        Deputs "check port: checkname $handle"
			foreach port [ixNet getL [ixNet getRoot] vport] {
                set portname [ixNet getA $port -name]
				if { $port == $handle } {
					return $handle
				} elseif { $portname == $handle || $portname == [lindex [split $handle "::"] end] } {
                Deputs "portname:$portname; checkname $handle"
					return $port 
				} elseif { [llength [ split $handle "/" ]] == 3 } {
					set realLocationInfo [ split $handle "/" ]
					set assignedTo [ixNet getA $port -assignedTo]
					set ModuleNo    [lindex [split $assignedTo ":"] 1]
					set PortNo      [lindex [split $assignedTo ":"] 2]
					if { $ModuleNo == [lindex $realLocationInfo 1] && $PortNo == [lindex $realLocationInfo 2]} {
						return $port
					}
				}
			}
			return ""
		}
		traffic {
			set trafficObjs [ixNet getL [ixNet getL [ixNet getRoot] traffic] trafficItem]
			foreach trafficItemobj $trafficObjs {
				set itemlist [ixNet getL $trafficItemobj highLevelStream]
                set itemName [ixNet getA $trafficItemobj -name]
				foreach trafficobj $itemlist {
                    set highName [ixNet getA $trafficobj -name]
					if { $highName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $highName } {
						return $trafficItemobj
					} elseif { $itemName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $itemName || $itemName == [lindex [split $handle "::"] end] } {
						return $trafficItemobj
					}
                    # if { [ixNet getA $trafficobj -txPortName] == [ixNet getA $parentHnd -name] } {
                        # if { $highName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $highName } {
                            # return $trafficItemobj
                        # } elseif { $itemName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $itemName || $itemName == [lindex [split $handle "::"] end] } {
                            # return $trafficItemobj
                        # }
                    # }
				}
			}
            
            # set index [expr $index - 1]
            # if { $index >= 0 && [llength $trafficObjs] != 0 && [llength $trafficObjs] > $index } {
                # return [lindex $trafficObjs $index]
            # }
            
            return ""
		}
		bfd {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols bfd]
			if { [ ixNet getA $protocol -enabled ] } {
				set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $routers] > $index} {
					# return [lindex $routers $index]
				# }
			}
			return ""
		}
		bgp {
		    set topoObjList [ixNet getL [ixNet getRoot] topology]
            if { [ llength $topoObjList ] != 0 } {
                foreach topoObj $topoObjList {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceObj $deviceGroupList {
                        set ethernetObjList [ixNet getL $deviceObj ethernet]
                        foreach ethernetObj $ethernetObjList {
                            set ipv4ObjList [ixNet getL $ethernetObj ipv4]
                            set ipv6ObjList [ixNet getL $ethernetObj ipv6]
                            if { [ llength $ipv4ObjList ] != 0 } {
                                foreach ipv4Obj $ipv4ObjList {
                                    set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]
                                    if { $bgpObj == $handle } {
                                        return $handle
                                    }
                                    #if {[ixNet getA [ixNet getA $router -interfaces] -description] == $handle} {
                                    #    return $router
                                    #}
                                }
                            }
                            if { [ llength $ipv6ObjList ] != 0 } {
                                foreach ipv6Obj $ipv6ObjList {
                                    set bgpObj [ixNet getL $ipv6Obj bgpIpv6Peer]
                                    if { $bgpObj == $handle } {
                                        return $handle
                                    }
                                    #if {[ixNet getA [ixNet getA $router -interfaces] -description] == $handle} {
                                    #    return $router
                                    #}
                                }
                            }
                        }
                    }
                }
            }
            return ""
		}
        simroute {
            set routers [ixNet getL $parentHnd networkGroup]
			foreach router $routers {
                if { $router == $handle } {
                    return $handle
                } 				
            }
			return ""
		}
		igmp_host {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols igmp]
			if { [ ixNet getA $protocol -enabled ] } {
				set hosts [ixNet getL $protocol host]
				foreach host $hosts {
					if { $host == $handle } {
						return $handle
					} 
                    if {[ixNet getA [ixNet getA $host -interfaceId] -description] == $handle} {
                        return $host
                    }
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $hosts] != 0 && [llength $hosts] > $index } {
					# return [lindex $hosts $index]
				# }
			}			
			return ""
		}
        pim_router {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols pimsm]
			if { [ ixNet getA $protocol -enabled ] } {
				set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
                    if {[ixNet getA [ixNet getA [lindex [ixNet getL $router interface] 0] -interfaces] -description] == $handle} {
                        return $router
                    }
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $hosts] != 0 && [llength $hosts] > $index } {
					# return [lindex $hosts $index]
				# }
			}			
			return ""
		}
		mld_host {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols mld]
			if { [ ixNet getA $protocol -enabled ] } {
				set hosts [ixNet getL $protocol host]
				foreach host $hosts {
					if { $host == $handle } {
						return $handle
					} 
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $hosts] != 0 && [llength $hosts] > $index } {
					# return [lindex $hosts $index]
				# }
			}			
			return ""		
		}
		isis {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols isis]
			if { [ ixNet getA $protocol -enabled ] } {
				
                set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
                    if {[ixNet getA [ixNet getA [lindex [ixNet getL $router interface] 0] -interfaceId] -description] == $handle} {
                        return $router
                    }
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $routers] > $index} {
					# return [lindex $routers $index]
				# }
			}			
			return ""		
		}
		ldp {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols ldp]
			if { [ ixNet getA $protocol -enabled ] } {
				set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $routers] > $index} {
					# return [lindex $routers $index]
				# }
			}			
			return ""		
		}
		ospfv2 {
			
            set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols ospf]
			if { [ ixNet getA $protocol -enabled ] } {
				set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
                    if {[ixNet getA [ixNet getA [lindex [ixNet getL $router interface] 0] -interfaces] -description] == $handle} {
                        return $router
                    }
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $routers] != 0 && [llength $routers] > $index } {         
					# return [lindex $routers $index]
				# }
			}			
			return ""            
		}
		ospfv3 {			
            set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols ospfV3]
			if { [ ixNet getA $protocol -enabled ] } {
				set routers [ixNet getL $protocol router]
				foreach router $routers {
					if { $router == $handle } {
						return $handle
					} 
                    if {[ixNet getA [ixNet getA [lindex [ixNet getL $router interface] 0] -interfaces] -description] == $handle} {
                        return $router
                    }
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $routers] != 0 && [llength $routers] > $index } {         
					# return [lindex $routers $index]
				# }
			}			
			return ""            
		}
		host {
			set protocols [ixNet getL $parentHnd protocols]
			set protocol [ixNet getL $protocols static]
			if { [ ixNet getA $protocol -enabled ] == "::ixNet::OK" } {
				set lans [ixNet getL $protocol lan]
				foreach lan $lans {
					if { $lan == $handle } {
						return $handle
					} 
				}
				
				# set index [expr $index - 1]
				# if { $index >= 0 && [llength $lans] > $index} {
					# return [lindex $lans $index]
				# }
			}
			return ""			
		}
		dhcp {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet dhcpEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
                set ipv4Ranges [list ]
				foreach range $ranges {
				    if { [ixNet getA $range/dhcpRange -ipType] != "IPv4" } {
						continue
					}
                    lappend ipv4Ranges $range
                    set rangeName [ixNet getA $range/dhcpRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ipv4Ranges] > $index} {
                    # return [list $stack [lindex $ipv4Ranges $index]]
                # }
			}
			return ""
		}
		dhcp_server {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet dhcpServerEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
                set ipv4Ranges [list ]
				foreach range $ranges {
				    if { [ixNet getA $range/dhcpServerRange -ipType] != "IPv4" } {
						continue
					}
                    lappend ipv4Ranges $range
                    set rangeName [ixNet getA $range/dhcpRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}	
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ipv4Ranges] > $index} {
                    # return [list $stack [lindex $ipv4Ranges $index]]
                # }
			}
			return ""
		}
		dhcpv6 {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet dhcpEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
                set ipv6Ranges [list ]
				foreach range $ranges {
				    if { [ixNet getA $range/dhcpRange -ipType] != "IPv6" } {
						continue
					}
                    lappend ipv6Ranges $range
                    set rangeName [ixNet getA $range/dhcpRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ipv6Ranges] > $index} {
                    # return [list $stack [lindex $ipv6Ranges $index]]
                # }	
			}
			return ""
		}
		dhcpv6_server {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet dhcpServerEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
                set ipv6Ranges [list ]
				foreach range $ranges {
				    if { [ixNet getA $range/dhcpServerRange -ipType] != "IPv6" } {
						continue
					}
                    lappend ipv6Ranges $range
                    set rangeName [ixNet getA $range/dhcpRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ipv6Ranges] > $index} {
                    # return [list $stack [lindex $ipv6Ranges $index]]
                # }
			}
			return ""
		}		
		pppoe_host {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet pppoxEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
				foreach range $ranges {
                    set rangeName [ixNet getA $range/pppoxRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ranges] > $index} {
                    # return [list $stack [lindex $ranges $index]]
                # }
			}
			return ""
		}
        l2tp {
			set protocolStack [ixNet getL $parentHnd protocolStack]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set ethstack [ixNet getL $ethernet ip]
				if { $ethstack == "" } {
					continue
				}
                set stack [ixNet getL $ethstack l2tpEndpoint]
                if { $stack == "" } {
					continue
				}
                
				set ranges [ixNet getL $stack range]
				foreach range $ranges {
                    set rangeName [ixNet getA $range/l2tpRange -name]
					if { $range == $handle } {
						return [list $stack $range]
					} elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
						return [list $stack $range]
					}
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ranges] > $index} {
                    # return [list $stack [lindex $ranges $index]]
                # }
			}
			return ""
		}
        ipoe_host {
			set protocolStack [ixNet getL $parentHnd protocolStack]
            set ipRangeOptions [ixNet getL $protocolStack ipRangeOptions]
			set ethernets [ixNet getL $protocolStack ethernet]
			foreach ethernet $ethernets {
				set stack [ixNet getL $ethernet ipEndpoint]
				if { $stack == "" } {
					continue
				}
				set ranges [ixNet getL $stack range]
                set ipoeRanges [list ]
				foreach range $ranges {
                    if { [llength $ipRangeOptions] != 0 } {
                        if { [ixNet getA $ipRangeOptions -ipv6AddressMode] == "autoconf" } {
                            continue
                        }
                    }
                    lappend ipoeRanges $range
                    set rangeName [ixNet getA $range/ipRange -name]
                    if { $range == $handle } {
                        return [list $stack $range]
                    } elseif { $rangeName == $handle || [string range $handle 1 [expr [string length $handle] - 2]] == $rangeName } {
                        return [list $stack $range]
                    }
				}
                # set index [expr $index - 1]
                # if { $index >= 0 && [llength $ipoeRanges] > $index} {
                    # return [list $stack [lindex $ipoeRanges $index]]
                # }
			}
			return ""
        }
        default {
            return ""
        }
	}
    return ""
}
#We will add leftover packages once implemented for NGPF
puts "load package Ixia_Util..."
if { [ catch {
	source [file join $currDir Ixia_Util.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_Util.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
} 
puts "load package Ixia_NetNgpfObj..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfObj.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfObj.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
} 	
puts "load package Ixia_NetNgpfPort..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfPort.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfPort.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
} 	
puts "load package Ixia_NetNgpfBgp..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfBgp.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfBgp.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

puts "load package Ixia_NetNgpfOspf..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfOspf.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfOspf.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}
puts "load package Ixia_NetNgpfIsis..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfIsis.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfIsis.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

puts "load package Ixia_NetNgpfDhcp..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfDhcp.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfDhcp.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

puts "load package Ixia_NetNgpfDot1xRate..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfDot1xRate.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfDot1xRate.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

puts "load package Ixia_NetNgpfTraffic..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfTraffic.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfTraffic.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

puts "load package Ixia_NetNgpfTester..."
if { [ catch {
	source [file join $currDir Ixia_NetNgpfTester.tcl]
} err ] } {
	if { [ catch {
			source [file join $currDir Ixia_NetNgpfTester.tbc]
	} tbcErr ] } {
		puts "load package fail...$err $tbcErr"
	}
}

#IxDebugOn
#IxDebugCmdOn