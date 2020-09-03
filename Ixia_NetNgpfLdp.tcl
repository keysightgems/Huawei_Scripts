
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.3
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.2.3
#		2. Add LSP class
# Version 1.2.4.34
#		3. Add reborn in Ldp.config
# Version 1.3.4.42
#		4. change inherit structure from emulation


class LdpSession {
    inherit RouterEmulationObject
    public variable ldpHandle		
    public variable deviceHandle
    public variable ethHandle
    public variable version
    public variable ipv4Handle
    public variable ipv6Handle	
    constructor { port } {
		global errNumber
		
		set tag "body LdpSession::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set portObj [ GetObject $port ]
		set handle ""
		reborn
	}
	
	method reborn {{version ipv4}} {
	    global ldpObj
	    global errNumber
		set tag "body LdpSession::reborn [info script]"
		set ip_version $version
	    if { [ catch {
            set hPort   [ $portObj cget -handle ]
        } ] } {
            error "$errNumber(1) Port Object in LdpSession ctor"
        }


    #-- add interface and ldp protocol
    set ldpObj ""
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    Deputs "topoObjList: $topoObjList"
    set vportList [ixNet getL [ixNet getRoot] vport]
    set vport [ lindex $vportList end ]
    if {[llength $topoObjList] != [llength $vportList]} {

        foreach topoObj $topoObjList {
            set vportObj [ixNet getA $topoObj -vports]
            if {$vportObj != $vport && $vport == $hPort} {
                set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                set deviceGroupObj [ixNet add $topoObj deviceGroup]
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
            break
        }
    }
	set topoObjList [ixNet getL [ixNet getRoot] topology]

    if { [ llength $topoObjList ] == 0 } {
        set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
        set deviceGroupObj [ixNet add $topoObj deviceGroup]
        set ethernetObj [ixNet add $deviceGroupObj ethernet]

        if { $ip_version == "ipv4" } {
		    set ipv4Obj [ixNet add $ethernetObj ipv4]
		    set ldpObj [ixNet getL $ipv4Obj ldpBasicRouter]
            if {[llength $ldpObj] == 0} {
                set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
                ixNet commit
		    }
        }
        if { $ip_version == "ipv6" } {
            set ipv6Obj [ixNet add $ethernetObj ipv6]
		    set ldpObj [ixNet getL $ipv6Obj ldpBasicRouterV6]

            if {[llength $ldpObj] == 0} {
			    set ldpObj [ixNet add $ipv6Obj ldpBasicRouterV6]
                ixNet commit
            }
        }

        set ldpObj [ ixNet remapIds $ldpObj ]
        ixNet setA $ldpObj -name $this
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
                                set ipaddr [ixNet getA [ixNet getA $ipv4Obj -address]/singleValue -value]
                                if {$ipaddr == $ipv4_addr} {
                                    set ethernetObj $ethernetObj
                                    set ldpObj [ixNet getL $ipv4Obj ldpBasicRouter]
                                    if {[llength $ldpObj] != 0} {
                                        set ldpObj [ ixNet remapIds $ldpObj ]
                                    } else {
                                        set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
                                        ixNet commit
                                        set ldpObj [ ixNet remapIds $ldpObj ]
                                    }
                                    break
                                }
                            } else {
                                if { [llength $ipv4Obj] == 0 } {
                                    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                                    if { [llength $ipv6Obj] != 0 } {
                                        if { [llength $ldpObj] == 0 } {
                                            set ldpObj [ixNet add $ipv6Obj ldpBasicRouterV6]
                                            ixNet commit
                                            set ldpObj [ ixNet remapIds $ldpObj ]
                                        }
                                    }
                                } else {
                                    if { [llength $ldpObj] == 0 } {
                                        set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
                                        ixNet commit
                                        set ldpObj [ ixNet remapIds $ldpObj ]
                                    }
                                }
                            }
                        } elseif { $ip_version == "ipv6" } {
                            set ipv6Obj [ixNet getL $ethernetObj ipv6]
                            if { [llength $ipv6Obj] == 0 } {
                                set ipv6Obj [ixNet add $ethernetObj ipv6]
                                ixNet commit
                                set ldpObj [ixNet getL $ipv6Obj ldpBasicRouterV6]
                                if {[llength $ldpObj] != 0} {
                                    set ldpObj [ ixNet remapIds $ldpObj ]
                                } else {
                                    set ldpObj [ixNet add $ipv6Obj ldpBasicRouterV6]
                                    ixNet commit
                                    set ldpObj [ ixNet remapIds $ldpObj ]
                                }
                            } else {
                                if { [llength $ldpObj] == 0 } {
                                    set ldpObj [ixNet add $ipv6Obj ldpBasicRouterV6]
                                    ixNet commit
                                    set ldpObj [ ixNet remapIds $ldpObj ]
                                }
                            }
                        }
                    }
                }
            }
        }
    }	
	#Setting to 1 default number of device 
	ixNet setA $deviceGroupObj -multiplier "1"
	ixNet commit
    $this configure -ldpHandle $ldpObj
    $this configure -deviceHandle $deviceGroupObj
    $this configure -ethHandle $ethernetObj
	$this configure -version $ip_version
    if { $ip_version == "ipv4" } {
        $this configure -ipv4Handle $ipv4Obj
    } else {
        $this configure -ipv6Handle $ipv6Obj
    }

	set protocol ldp
		
		
	}
	method establish_lsp { args } {}
	method teardown_lsp { args } {}
	method flapping_lsp { args } {}
    method config { args } {}
	method get_status {} {}
	method get_stats {} {}

}

body LdpSession::config { args } {

    global errorInfo
    global errNumber

    if { [ catch {
        set handle   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in BgpSession ctor"
    }
    set tag "body BgpSession::config [info script]"
    Deputs "----- TAG: $tag -----"
	
    set tag "body LdpSession::config [info script]"
    Deputs "----- TAG: $tag -----"
	
    #param collection
    Deputs "Args:$args "
	set ip_version "ipv4"
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -router_id {
				set router_id $value
			}
			-egress_label {	
				set egress_label $value
			}
			-hello_interval {
				set hello_interval $value
			}
			-bfd {
				set bfd $value
			}
			-enable_graceful_restart {
				set enable_graceful_restart $value
			}
			-hello_type  {
				set hello_type  $value
			}
			-label_min {
				set label_min $value
			}
			-keep_alive_interval  {
				set keep_alive_interval  $value
			}
			-reconnect_time {
				set reconnect_time  $value
			}
			-recovery_time {
				set recovery_time  $value
			}
			-transport_tlv_mode {
				set transport_tlv_mode  $value
			}
			-lsp_type {
				set lsp_type  $value
			}
			-label_advertise_mode {
				set label_advertise_mode  $value
			}
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_prefix_len {
				set ipv4_prefix_len $value
			}
			-ipv4_gw -
			-dut_ip {
				set ipv4_gw $value
			}

            default {
                error "$errNumber(3) key:$key value:$value"
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
					set ipv4Obj [ixNet getL $ethernetObj ipv4]
				    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                		
					if { [ info exists ip_version ] } {
		                if { [ string tolower $ip_version ] == "ipv6" } {
							if {[llength $ipv6Obj] == "0"} {
							   set ipv6Obj [ixNet add $ethernetObj ipv6]							   
				               ixNet commit
                            }
							set ldpv6Interface [ixNet getL $ipv6Obj ldpv6ConnectedInterface]
							if {$ldpv6Interface == ""} {
							    set ldpv6Interface [ixNet add $ipv6Handle ldpv6ConnectedInterface]
								ixNet commit
								set ldpv6Interface [ ixNet remapIds $ldpv6Interface ]


	                        }
							
		                } elseif {[ string tolower $ip_version ] == "ipv4" } {
 						    if {[llength $ipv4Obj] == "0"} {
				                set ipv4Obj [ixNet add $ethernetObj ipv4]							   
				                ixNet commit
			                }
						    set ldpv4Interface [ixNet getL $ipv4Obj ldpConnectedInterface ]
	                        if {$ldpv4Interface == ""} {
	                             set ldpv4Interface [ixNet add $ipv4Obj ldpConnectedInterface ]
							     ixNet commit
								set ldpv4Interface [ ixNet remapIds $ldpv4Interface ]

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
					
                    if { [ info exists ipv4_gw ] } {
                        if { $ip_version == "ipv4" } {
                            set ipv4Obj [ixNet getL $ethernetObj ipv4]
                            ixNet setA [ixNet getA $ipv4Obj -gatewayIp]/singleValue  -value $ipv4_gw
                            ixNet commit
                        }
                    }					
				    if { [ info exists ipv4_prefix_len ] } {
                        if {$ip_version == "ipv4"} {
                            set pLen 24
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

				    if { [ info exists egress_label ] } {
	                   puts "Not implemented"
	                }
				    if { [ info exists bfd ] } {
	                   puts "Not implemented"
	                }
				    if { [ info exists hello_type ] } {
	                   puts "Not implemented"
	                }
					
				    if { [ info exists label_min ] } {
	                   puts "Not implemented"
	                }
									
					if { [ info exists keep_alive_interval ] } {
					    ixNet setA [ixNet getA $ldpHandle -keepAliveInterval]/singleValue -value $keep_alive_interval            

	                }
					if { [ info exists lsp_type ] } {
	                   puts "Not implemented"
	                }
										
					if { [ info exists router_id ] } {
	                   set routeDataObj [ixNet getL $deviceGroupObj routerData]
					   ixNet setA [ixNet getA $routeDataObj -routerId]/singleValue -value $router_id
	                }
				    if { [ info exists enable_graceful_restart ] } {
		               ixNet setA [ixNet getA $ldpHandle -enableGracefulRestart]/singleValue -value $enable_graceful_restart            
	                }
					if { [ info exists reconnect_time ] } {
	               
                       ixNet setA [ixNet getA $ldpHandle -reconnectTime]/singleValue -value $reconnect_time 
	                }					
	                if { [ info exists recovery_time ] } {
	                   ixNet setA [ixNet getA $ldpHandle -recoveryTime]/singleValue -value $recovery_time            

	                }		
	                if { [ info exists label_advertise_mode ] } {
		                set label_advertise_mode [ string tolower $label_advertise_mode ]
		                switch $label_advertise_mode {
					        du {
				               set label_advertise_mode unsolicited
			                }
						    dod {
				               set label_advertise_mode ondemand
			                }
		                }
						if { $ip_version == "ipv4" } {
	                        ixNet setA [ixNet getA $ldpv4Interface -operationMode]/singleValue -value $label_advertise_mode            
					
					    } else {
	                        ixNet setA [ixNet getA $ldpv6Interface -operationMode]/singleValue -value $label_advertise_mode            
					
					    }
	
	                }
					if { [ info exists hello_interval ] } {
					    if { $ip_version == "ipv4" } {
					        ixNet setA [ixNet getA $ldpv4Interface -basicHelloInterval]/singleValue -value $hello_interval            
					
					
					    } else {
					        ixNet setA [ixNet getA $ldpv6Interface -basicHelloInterval]/singleValue -value $hello_interval            
					
					    }
	                }					
					if { [ info exists transport_tlv_mode ] } {
		                set transport_tlv_mode [ string toupper $transport_tlv_mode ]
						#-prefixAdvertisementType
						switch $transport_tlv_mode {
 						    TRANSPORT_TLV_MODE_NONE {
							    ixNet setA [ixNet getA $ldpHandle -sessionPreference]/singleValue -value "any"   
							}
			                TRANSPORT_TLV_MODE_TESTER_IP {
				                ixNet setA [ixNet getA $ldpHandle -sessionPreference]/singleValue -value "ipv4"   
			                }
			                TRANSPORT_TLV_MODE_ROUTER_ID {
			                	ixNet setA [ixNet getA $ldpHandle -sessionPreference]/singleValue -value "ipv6"   
			                }
		                }
					}
					

					ixNet commit

	            }
				   
			}
		}
	
    return [GetStandardReturnHeader]	
	
}

body LdpSession::establish_lsp { args } {
    global errorInfo
    global errNumber
    set tag "body LdpSession::establish_lsp [info script]"
Deputs "----- TAG: $tag -----"
	
#param collection
Deputs "Args:$args "
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-lsp {
				set lsp $value
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	if { [ $lsp isa LdpLsp ] } {
		$lsp establish_lsp
	} else {
		return [ GetErrorReturnHeader "Bad LSP object... $lsp" ]
	}
	
	return [GetStandardReturnHeader]	

}

body LdpSession::teardown_lsp { args } {
    global errorInfo
    global errNumber
    set tag "body LdpSession::teardown_lsp [info script]"
Deputs "----- TAG: $tag -----"
	
#param collection
Deputs "Args:$args "
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-lsp {
				set lsp $value
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	if { [ $lsp isa LdpLsp ] } {
		$lsp teardown_lsp
	} else {
		return [ GetErrorReturnHeader "Bad LSP object... $lsp" ]
	}
	
	return [GetStandardReturnHeader]	

}

body LdpSession::flapping_lsp { args } {
    global errorInfo
    global errNumber
    set tag "body LdpSession::flapping_lsp [info script]"
Deputs "----- TAG: $tag -----"
	
#param collection
Deputs "Args:$args "
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-lsp {
				set lsp $value
			}
			-flap_times -
			-flap_interval {
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	if { [ $lsp isa LdpLsp ] } {
		eval $lsp flapping_lsp $args
	} else {
		return [ GetErrorReturnHeader "Bad LSP object... $lsp" ]
	}
	
	return [GetStandardReturnHeader]	

}

class LdpLsp {
	inherit EmulationObject
	
	public variable type
	public variable hLdp

	method config { args } {}
	method establish_lsp {} {}
	method teardown_lsp {} {}
	method flapping_lsp { args } {}
	
}

body LdpLsp::establish_lsp {} {
	set tag "body LdpLsp::establish_lsp [info script]"
Deputs "----- TAG: $tag -----"
	ixNet setA $handle -enabled True
	ixNet commit
}

body LdpLsp::teardown_lsp {} {
	set tag "body LdpLsp::teardown_lsp [info script]"
Deputs "----- TAG: $tag -----"
	ixNet setA $handle -enabled False
	ixNet commit
}

body LdpLsp::flapping_lsp { args } {
    global errorInfo
    global errNumber
    set tag "body LdpLsp::flapping_lsp [info script]"
Deputs "----- TAG: $tag -----"
	
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-flap_times {
				set flap_times $value
			}
			-flap_interval {
				set flap_interval $value
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	for { set index 0 } { $index < $flap_times } { incr index } {
		teardown_lsp
		after [ expr $flap_interval * 1000 ]
		establish_lsp
		after [ expr $flap_interval * 1000 ]
	}
	return [GetStandardReturnHeader]	
}

class Ipv4PrefixLsp {

	inherit LdpLsp
	public variable ldpObj
	
	constructor { ldp } {
		global errNumber
		
		set tag "body Ipv4PrefixLsp::ctor [info script]"
Deputs "----- TAG: $tag -----"
		set ldpObj $ldp
		reborn
	}
	method reborn {} {
		set tag "body Ipv4PrefixLsp::reborn [info script]"
Deputs "----- TAG: $tag -----"
		set hLdp [ $ldpObj cget -handle ]
		set range [ ixNet add $hLdp advFecRange ]
		ixNet setA $range -enabled True
		ixNet commit
		set handle [ ixNet remapIds $range ]
		
	}
	method config { args } {}
}

body Ipv4PrefixLsp::config { args } {

    global errorInfo
    global errNumber
    set tag "body Ipv4PrefixLsp::config [info script]"
Deputs "----- TAG: $tag -----"
	set assinged_label 3
	set fec_type LDP_FEC_TYPE_PREFIX
	
#param collection
Deputs "Args:$args "
	if { $handle == "" } {
		reborn
	}
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-route_block {
				set route_block $value
			}
			-fec_type {
				set fec_type $value
			}
			-assinged_label {
				set assinged_label $value
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	if { [ info exists route_block ] } {
		if { [ $route_block isa RouteBlock ] } {
			set num [ $route_block cget -num ]
			set start [ $route_block cget -start ]
			set step [ $route_block cget -step ]
			set prefix_len [ $route_block cget -prefix_len ]
		} else {
			return [ GetErrorReturnHeader "Bad RouteBlock obj... $route_block" ]			
		}
	} else {
		return [ GetErrorReturnHeader "Missing madatory parameter... -route_block" ]
	}
	
	if { [ info exists fec_type ] } {
		set fec_type [ string toupper $fec_type ] 
		switch $fec_type {
			LDP_FEC_TYPE_PREFIX {
				ixNet setA $handle -maskWidth $prefix_len
			}
			LDP_FEC_TYPE_HOST_ADDR {
				ixNet setA $handle -maskWidth 32
			}
		}
		ixNet commit
	}
	
	if { [ info exists num ]  } {
		ixNet setA $handle -numberOfNetworks $num
		ixNet commit
	}
	
	if { [ info exists start ] } {
		ixNet setA $handle -firstNetwork $start
		ixNet commit
	}
	
	if { [ info exists assinged_label ] } {
		ixNet setA $handle -labelValueStart $assinged_label
		ixNet commit
	}

	return [GetStandardReturnHeader]	

}

class VcLsp {

	inherit LdpLsp
	public variable ldpObj
	public variable vcRange
	public variable hInterface
	
	constructor { ldp } {
		global errNumber
		
		set tag "body VcLsp::ctor [info script]"
        Deputs "----- TAG: $tag -----"
		set ldpObj $ldp
		reborn
	}
	method reborn {} {
		set tag "body VcLsp::reborn [info script]"
        Deputs "----- TAG: $tag -----"
		set hLdp [ $ldpObj cget -handle ]
		set hPort [$ldpObj cget -hPort]
		set range [ ixNet add $hLdp l2Interface ]
        Deputs "range:$range"
		ixNet setA $range -enabled True
		ixNet commit
		set handle [ ixNet remapIds $range ]
        Deputs "handle:$handle"		
		set range [ ixNet add $handle l2VcRange ]
		ixNet setM $range -enabled True \
			-fecType pwIdFec \
			-doNotExpandIntoVcs True
		ixNet commit
		set vcRange [ ixNet remapIds $range ]

        Deputs "rb_interface:[ $ldpObj cget -rb_interface ]"		
		foreach int [ $ldpObj cget -rb_interface ] {
			if { [ ixNet getA $int -type ] == "routed" } {
				set hInterface [ ixNet add $hLdp interface ]
				ixNet setM $hInterface \
					-protocolInterface $int \
					-enabled True \
					-discoveryMode extendedMartini
				ixNet commit
				
				# use transport address
				ixNet setM [ $ldpObj cget -handle ] \
					-useTransportAddress True \
					-transportAddress $int
				ixNet commit
			}
		}
	}
	method config { args } {}
}

body VcLsp::config { args } {
    global errorInfo
    global errNumber
    set tag "body VcLsp::config [info script]"
    Deputs "----- TAG: $tag -----"
        
    #param collection
    Deputs "Args:$args "
	set encap LDP_LSP_ENCAP_ETHERNET_VLAN
	set peer_address 160.160.160.160
	set vc_ip_address 1.1.1.1
	
	if { $handle == "" } {
		reborn
	}
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-encap {
				set encap $value
			}
			-group_id {
				set group_id $value
			}
			-if_mtu {
				set if_mtu $value
			}
			-mac_start {
				set mac_start $value
			}
			-mac_step  {
                # -- unsupported yet
                set mac_step  $value
			}
			-mac_num  {
                # -- unsupported yet
				set mac_num  $value
			}
			-vc_id_start {
				set vc_id_start $value
			}
			-vc_id_step   {
				set vc_id_step   $value
			}
			-vc_id_count   {
				set vc_id_count   $value
			}
			-requested_vlan_id_start  {
				set requested_vlan_id_start  $value
			}
			-requested_vlan_id_step    {
				set requested_vlan_id_step    $value
			}
			-requested_vlan_id_count    {
				set requested_vlan_id_count   $value
			}
			-assinged_label     {
				set assinged_label   $value
			}
            -peer_address {
				set peer_address $value
			}
			-vc_ip_address {
				set vc_ip_address $value
			}
			-incr_vc_vlan {
				set incr_vc_vlan $value
			}
			default {
                error "$errNumber(3) key:$key value:$value"
            }
		}
    }
	
	if { [ info exists encap ] } {
		set encap [ string toupper $encap ]
		switch $encap {
			LDP_LSP_ENCAP_FRAME_RELAY_DLCI {
				set ixencap frameRelay
			}
			LDP_LSP_ENCAP_ATM_AAL5_VCC {
				set ixencap atmaal5
			}
			LDP_LSP_ENCAP_ATM_TRANSPARENT_CELL {
				set ixencap atmxCell
			}
			LDP_LSP_ENCAP_ETHERNET_VLAN {
				set ixencap vlan
			}
			LDP_LSP_ENCAP_ETHERNET {
				set ixencap ethernet
			}
			LDP_LSP_ENCAP_HDLC {
				set ixencap hdlc
			}
			LDP_LSP_ENCAP_PPPoE {
				set ixencap ppp
			}
			LDP_LSP_ENCAP_CEM {
				set ixencap cem
			}
			LDP_LSP_ENCAP_ATM_VCC {
				set ixencap atmvcc
			}
			LDP_LSP_ENCAP_ATM_VPC {
				set ixencap atmvpc
			}
			LDP_LSP_ENCAP_ETHERNET_VPLS {
				set ixencap vlan
			}
		}
		ixNet setA $handle -type $ixencap
		ixNet commit
		# if { $encap == "LDP_LSP_ENCAP_ETHERNET_VPLS" } {
			# ixNet setA $vcRange -fecType generalizedIdFecVpls
			# ixNet commit
		# }
	}
	if { [ info exists group_id ] } {
		ixNet setA $handle -groupId $group_id
		ixNet commit
	}
	
	if { [ info exists if_mtu ] } {
		ixNet setA $vcRange -mtu $if_mtu
		ixNet commit
	}
	
	if { [ info exists vc_id_start ] } {
		ixNet setA $vcRange -vcId $vc_id_start
		ixNet commit
	}
	
	if { [ info exists vc_id_step ] } {
		ixNet setA $vcRange -vcIdStep $vc_id_step
		ixNet commit
	}
	
	if { [ info exists vc_id_count ] } {
		ixNet setA $vcRange -count $vc_id_count
		ixNet commit
	}
	
	if { [ info exists mac_start ] } {
		ixNet setM $vcRange/l2MacVlanRange \
			-startMac $mac_start \
			-enabled True
		ixNet commit
	}
	
	if { [ info exists requested_vlan_id_start ] } {
		ixNet setM $vcRange/l2MacVlanRange \
			-firstVlanId $requested_vlan_id_start \
			-enableVlan True
		ixNet commit
	}
	
	if { [ info exists requested_vlan_id_count ] } {
		ixNet setA $vcRange/l2MacVlanRange \
			-vlanCount $requested_vlan_id_count \
			-enableVlan True

		ixNet commit
	}
	
	if { [ info exists assinged_label ] } {
		ixNet setA $vcRange -labelStart $assinged_label
		ixNet commit
	}
	
	if { [ info exists peer_address ] } {
		ixNet setA $vcRange -peerAddress $peer_address
		set hTarget [ ixNet add $hInterface targetPeer ]
		ixNet setM $hTarget \
			-ipAddress $peer_address \
			-enabled True
		ixNet commit
		ixNet setM $vcRange/l2VcIpRange \
			-peerAddress $peer_address \
			-enabled True \
			-startAddress $vc_ip_address
		ixNet commit
	}
	if { [ info exists incr_vc_vlan ] && $incr_vc_vlan } {
		ixNet setM $vcRange/l2MacVlanRange \
			-incrementVlanMode parallelIncrement
		ixNet commit
		
	}
	return [GetStandardReturnHeader]	
}



