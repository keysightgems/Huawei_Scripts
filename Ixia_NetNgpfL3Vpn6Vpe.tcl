
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.0
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
class L3Vpn {
	constructor {} {}
	method config { args } {}	
}
body L3Vpn::config { args } {	
    global errorInfo
    global errNumber
    set tag "body L3Vpn::config [info script]"
Deputs "----- TAG: $tag -----"
	
# -- Default value initiation
	set ce_num				0
	set pe_num				0
	set ce 					[ list ] ;#ce port handle list
	set pe					[ list ] ;#pe port handle list
	set vpn_unique_per_pe	1
	set vpn_num				0
	
	# set ce_ipv4_addr		30.30.30.2
	set ce_ipv4_step		1
	set ce_ipv4_mod			24
	set ce_ipv4_pfx			24
	set ce_ipv4_port_step	1
	set ce_ipv4_port_mod	8
	set ce_vlan_enable		0
	set ce_vlan_id			1
	set ce_vlan_step		1
	
	# set ce_dut_addr			30.30.30.1
	set ce_dut_step			1
	set ce_dut_mod			24
	array set ce_e_bgp		[ list ] ;#ce external bgp handle list
	set ce_local_as			65001
	set ce_local_as_step	1
	
	set ce_route_num		50
	set ce_route_mask		24
	set ce_route_step		1
	set ce_route_addr		22.22.22.0
	set ce_route_ce_step	1
	set ce_route_ce_mod		8

	set p_router_num		0
	set pe_router_num		1
	set Ep_pe_igp			[ list "OSPF" "ISIS" ]
	set p_pe_igp			"OSPF"
	
	# set p_ipv4_addr			20.20.20.2
	set p_ipv4_pfx			24
	set p_ipv4_mod			24
	set p_ipv4_step			1
	set p_ipv4_port_mod		8
	set p_ipv4_port_step	1
	
	# set pe_ipv4_addr			20.20.20.2
	set pe_ipv4_pfx			24
	set pe_ipv4_mod			24
	set pe_ipv4_step		1
	set pe_ipv4_port_mod	8
	set pe_ipv4_port_step	1
	
	# set p_pe_dut_addr		20.20.20.1
	set p_pe_dut_mod		24
	set p_pe_dut_step		1
	set p_pe_dut_port_mod	8
	set p_pe_dut_port_step	1
	
	set p_pe_vlan_enable	0
	set p_pe_vlan_id		1
	set p_pe_vlan_step		1
	
	set pe_loopback_ipv4_addr			2.2.2.2
	set pe_loopback_ipv4_pfx			32
	set pe_loopback_ipv4_mod			32
	set pe_loopback_ipv4_step			1
	set pe_loopback_ipv4_port_mod		16
	set pe_loopback_ipv4_port_step		1
	
	set p_pe_dut_loopback_addr			1.1.1.1
	set p_pe_dut_loopback_mod			32
	set p_pe_dut_loopback_step			0
	set p_pe_dut_loopback_port_mod		32
	set p_pe_dut_loopback_port_step		0
	
	set p_loopback_ipv4_addr			100.2.1.1
	set ce_loopback_ipv4_addr			100.1.1.1
	array set p_pe_interface	[list]
	array set p_pe_ospf			[list]
	array set p_pe_ldp			[list]
	
	set ldp_start_label		16
	set pe_bgp_as			100
	array set pe_i_bgp		[list]
	array set pe_l3site		[list]
	set pe_bgp_rt			100:1
	set pe_bgp_rt_step		0:1
	set pe_bgp_rd			100:1
	set pe_bgp_rd_step		0:1
	
	set pe_vpn_route_num		50
	set pe_vpn_route_mask		24
	set pe_vpn_route_step		1
	set pe_vpn_route_addr		55.55.55.0
	set pe_vpn_route_vrf_step	1
	set pe_vpn_route_vrf_mod	16
	
	#param collection
	Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-vpn_num {
				set vpn_num_per_pe $value
			}
			-vpn_unique_per_pe {
				set vpn_unique_per_pe $value
			}
			-ce_port {
				set ce_port $value
			}
			-ce_vlan_enable {
				set ce_vlan_enable $value
			}
			-ce_vlan_id {
				set ce_vlan_id $value
			}
			-ce_vlan_step {
				set ce_vlan_step $value
			}
			-ce_ipv4_addr {
				set ce_ipv4_addr $value
			}
			-ce_ipv4_step {
				set ce_ipv4_step $value
			}
			-ce_ipv4_mod {
				set ce_ipv4_mod $value
			}
			-ce_ipv4_pfx {
				set ce_ipv4_pfx $value
			}
			-ce_dut_addr {
				set ce_dut_addr $value
			}
			-ce_dut_step {
				set ce_dut_step $value
			}
			-ce_dut_mod {
				set ce_dut_mod $value
			}
			-ce_ipv4_port_step {
				set ce_ipv4_port_step $value
			}		
			-ce_ipv4_port_mod {
				set ce_ipv4_port_mod $value
			}
			-ce_bgp_as {
				set ce_local_as $value
			}
			-ce_bgp_as_step {
				set ce_local_as_step $value
			}
			-ce_bgp_route_num {
				set ce_route_num $value
			}
			-ce_bgp_route_mod {
				set ce_route_mask $value
			}
			-ce_bgp_route_addr {
				set ce_route_addr $value
			}
			-ce_bgp_route_step {
				set ce_route_step $value
			}
			-ce_bgp_route_ce_step {
				set ce_route_ce_step $value
			}
			-ce_bgp_route_ce_mod {
				set ce_route_ce_mod $value
			}
			
			-pe_port -
			-p_port {
				set p_pe_port	$value
			}
			-p_vlan_enable -
			-pe_vlan_enable {
				set p_pe_vlan_enable $value
			}
			-p_vlan_id -
			-pe_vlan_id {
				set p_pe_vlan_id $value
			}
			-p_vlan_step -
			-pe_vlan_step {
				set p_pe_vlan_step $value
			}
			-p_pe_igp {
				set p_pe_igp $value
			}
			-p_pe_mpls {
				set p_pe_mpls $value
			}
			-p_router_num {
				set p_router_num $value
			}
			-p_ipv4_addr {
				set p_ipv4_addr $value
			}
			-p_ipv4_pfx {
				set p_ipv4_pfx $value
			}
			-p_ipv4_mod {
				set p_ipv4_mod $value
			}
			-p_ipv4_step {
				set p_ipv4_step $value
			}		
			-p_ipv4_port_mod {
				set p_ipv4_port_mod $value
			}
			-p_ipv4_port_step {
				set p_ipv4_port_step $value
			}
			-p_loopback_ipv4_addr {
				set p_loopback_ipv4_addr $value
			}
			-pe_router_num {
				set pe_router_num $value
			}
			-pe_ipv4_addr {
				set pe_ipv4_addr $value
			}
			-pe_ipv4_pfx {
				set pe_ipv4_pfx $value
			}
			-pe_ipv4_mod {
				set pe_ipv4_mod $value
			}
			-pe_ipv4_step {
				set pe_ipv4_step $value
			}		
			-pe_ipv4_port_mod {
				set pe_ipv4_port_mod $value
			}
			-pe_ipv4_port_step {
				set pe_ipv4_port_step $value
			}
			
			-p_dut_addr -
			-pe_dut_addr {
				set p_pe_dut_addr $value
			}
			-p_dut_mod -
			-pe_dut_mod {
				set p_pe_dut_mod $value
			}
			-p_dut_step -
			-pe_dut_step {
				set p_pe_dut_step $value
			}
			-p_dut_port_mod -
			-pe_dut_port_mod {
				set p_pe_dut_port_mod $value
			}
			-p_dut_port_step -
			-pe_dut_port_step {
				set p_pe_dut_port_step $value
			}
			-pe_loopback_ipv4_addr {
				set pe_loopback_ipv4_addr $value
			}
			-pe_loopback_ipv4_step {
				set pe_loopback_ipv4_step $value
			}
			-pe_loopback_ipv4_pfx {
				set pe_loopback_ipv4_pfx $value
			}
			-pe_loopback_ipv4_mod {
				set pe_loopback_ipv4_mod $value
			}
			-pe_loopback_ipv4_port_mod {
				set pe_loopback_ipv4_port_mod $value
			}
			-pe_loopback_ipv4_port_step {
				set pe_loopback_ipv4_port_step $value
			}
			-dut_loopback_ipv4_addr {
				set p_pe_dut_loopback_addr $value
			}
			-dut_loopback_ipv4_step {
				set p_pe_dut_loopback_step $value
			}
			-dut_loopback_ipv4_mod {
				set p_pe_dut_loopback_mod $value
			}
			-dut_loopback_ipv4_port_step {
				set p_pe_dut_loopback_port_step $value
			}
			-dut_loopback_ipv4_port_mod {
				set p_pe_dut_loopback_port_mod $value
			}
			-pe_bgp_as {
				set pe_bgp_as $value
			}
			-pe_bgp_rt {
				set pe_bgp_rt $value
			}
			-pe_bgp_rt_step {
				set pe_bgp_rt_step $value
			}
			-pe_bgp_rd {
				set pe_bgp_rd $value
			}
			-pe_bgp_rd_step {
				set pe_bgp_rd_step $value
			}
			-pe_vpn_route_num {
				set pe_vpn_route_num $value
			}
			-pe_vpn_route_addr {
				set pe_vpn_route_addr $value
			}
			-pe_vpn_route_step {
				set pe_vpn_route_step $value
			}
			-pe_vpn_route_mod {
				set pe_vpn_route_mask $value
			}
			-pe_vpn_route_vrf_step {
				set pe_vpn_route_vrf_step $value
			}
			-pe_vpn_route_vrf_mod {
				set pe_vpn_route_vrf_mod $value
			}
			-ospf_area_id {
				set ospf_area_id $value
			}
			-ospf_network_type {
				set ospf_network_type $value
			}
			-ldp_start_label {
				set ldp_start_label $value
			}
		}
	}
	puts "Not implemented below parameters "
	puts "-p_pe_igp -p_pe_mpls , ospf_network_type , ospf_area_id "

	Deputs Step10
	# -- Calculate vpn num
	if { [ info exists vpn_num_per_pe ] } {
		Deputs "vpn num per PE:$vpn_num_per_pe"
		if { $vpn_unique_per_pe } {
			if { $p_router_num } {
				set vpn_num	[ expr $p_router_num * $pe_router_num * $vpn_num_per_pe ]
			} else {
				set vpn_num	[ expr $pe_router_num * $vpn_num_per_pe ]
			}
		} else {
			set vpn_num	$vpn_num_per_pe
		}
		Deputs "vpn num:$vpn_num"
	} else {
		return [ GetErrorReturnHeader "Madatory parameters needed...ce_port" ]
	}
	Deputs Step20
	# =========================
	# CE configuration
	# =========================	
	Deputs "===============CE Configuration============="
	# -- Fetch Port CE handle
	if {[ info exists ce_port ]} {		
		set ce_num	[ llength $ce_port ]		
		foreach obj $ce_port {
			lappend ce [ $obj  cget -handle ]
		}

	} else {
		return [ GetErrorReturnHeader "Madatory parameters needed...PE_port" ]
	}
	# -- Configure every single CE
	foreach port $ce_port {
		set hPort [ $port cget -handle ]
		# -- Add interface/sub-interface
		# -- Num of CE interface equals which of VPN
		if { [ info exists ce_ipv4_addr ] && [ info exists ce_dut_addr ] } {
		    #-inner_vlan_enable $ce_vlan_enable
			if { $ce_vlan_enable } {
				$port config \
					-intf_ip $ce_ipv4_addr -intf_num $vpn_num  \
					-dut_ip $ce_dut_addr -dut_ip_num $vpn_num -inner_vlan_id $ce_vlan_id \
					-dut_ip_mod $ce_dut_mod -intf_ip_step $ce_ipv4_step \
					-intf_ip_mod $ce_ipv4_mod  \
					-inner_vlan_step $ce_vlan_step \
					-dut_ip_step $ce_dut_step -mask $ce_ipv4_mod
			} else {
				$port config \
					-intf_ip $ce_ipv4_addr  \
					-intf_num $vpn_num \
					-intf_ip_step $ce_ipv4_step \
					-intf_ip_mod $ce_ipv4_mod \
					-dut_ip $ce_dut_addr -dut_ip_mod $ce_dut_mod \
					-dut_ip_num $vpn_num -dut_ip_step $ce_dut_step -mask $ce_ipv4_mod
			}			
			set ce_vlan_id	[ expr $ce_vlan_id + $ce_vlan_step * $vpn_num ]
			set ce_ipv4_addr [ IncrementIPAddr 	$ce_ipv4_addr $ce_ipv4_port_mod $ce_ipv4_port_step ]
		}
		# increment per port
        # -- Add EBGP peer
        #-- add interface and bgp protocol

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
        set ipv4Obj [ixNet add $ethernetObj ipv4]
        ixNet commit
        set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
        ixNet commit
        set bgpObj [ ixNet remapIds $bgpObj ]
        ixNet commit
        lappend ceBgpObjList $bgpObj		
    } else {
        foreach topoObj $topoObjList {
            set vportObj [ixNet getA $topoObj -vports]
            if {$vportObj == $hPort} {
                set deviceGroupList [ixNet getL $topoObj deviceGroup]
				foreach deviceGroupObj $deviceGroupList {
                    set ethernetList [ixNet getL $deviceGroupObj ethernet]
                    foreach ethernetObj $ethernetList {
                        set ipv4ObjList [ixNet getL $ethernetObj ipv4] 
					    foreach ipv4Obj $ipv4ObjList {
							set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]
							if {[llength $bgpObj] != 0} {
								set bgpObj [ ixNet remapIds $bgpObj ]
							} else {
								set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
								ixNet commit	
								set bgpObj [ ixNet remapIds $bgpObj ]
								
							}
	                    	lappend ceBgpObjList $bgpObj						
						}
                    }
                }
            }
        }
    }
    
	foreach bgpObj $ceBgpObjList {

		#Enable protocol 
		set ipPattern [ixNet getA [ixNet getA $bgpObj -active] -pattern]
		SetMultiValues $bgpObj "-active" $ipPattern True
		ixNet commit	
		
		#Retrive the interface         
		lappend interface_list [GetDependentNgpfProtocolHandle $bgpObj "ethernet"]
		set deviceGroup [GetDependentNgpfProtocolHandle $bgpObj "deviceGroup"]
        set ipPattern [ixNet getA [ixNet getA $bgpObj -type] -pattern]
		SetMultiValues $bgpObj "-type" $ipPattern "external"

        set ipPattern [ixNet getA [ixNet getA $bgpObj -localAs2Bytes] -pattern]
		SetMultiValues $bgpObj "-localAs2Bytes" $ipPattern $ce_local_as
			
		set ipPattern [ixNet getA [ixNet getA $bgpObj -bgpId] -pattern]
		SetMultiValues $bgpObj "-bgpId" $ipPattern $ce_loopback_ipv4_addr
        			
		set ipv4Obj [GetDependentNgpfProtocolHandle $bgpObj "ip"]
		
		set ipPattern [ixNet getA [ixNet getA $ipv4Obj -gatewayIp] -pattern]
        set dut [GetMultiValues $ipv4Obj "-gatewayIp" $ipPattern]
			
		Deputs "dut:$dut"	

        set ipPattern [ixNet getA [ixNet getA $bgpObj -dutIp] -pattern]
		SetMultiValues $bgpObj "-dutIp" $ipPattern $dut

		set networkGroupObj [ixNet add $deviceGroup "networkGroup"]
		ixNet commit
		set networkGroupObj [ ixNet remapIds $networkGroupObj ]			
	    lappend networkGroupObjList $networkGroupObj
		
		set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
        ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
		            ixNet commit	
	
	    set connector [ixNet add $ipPoolObj connector]
		ixNet setA $connector -connectedTo $bgpObj
        ixNet commit
		set hBgp [ ixNet remapIds $bgpObj ]
			
		set ce_e_bgp(ROUTER,$port) $hBgp
	    incr ce_local_as $ce_local_as_step
# -- Add EBGP route range
        if {[string first "." $ce_route_mask] != -1} {
            set pLen [SubnetToPrefixlenV4 $ce_route_mask]
        } else {
			set pLen $ce_route_mask
        }
             
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
		SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen

        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -networkAddress] -pattern]
	    SetMultiValues $ipPoolObj "-networkAddress" $ipPattern $ce_route_addr
		        
		set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixAddrStep] -pattern]
	    SetMultiValues $ipPoolObj "-prefixAddrStep" $ipPattern $ce_route_step
				
	
		ixNet setA $ipPoolObj -numberOfAddresses $ce_route_num
		
		ixNet commit		
		set hRoute [ ixNet remapIds $ipPoolObj ]
			
		set ce_e_bgp(ROUTE,$hBgp) $hRoute
		set ce_route_addr [ IncrementIPAddr $ce_route_addr $ce_route_ce_mod $ce_route_ce_step ]
		set ce_loopback_ipv4_addr [ IncrementIPAddr $ce_loopback_ipv4_addr 32 1 ]
		}
	}	
	
	# =========================
	# PE configuration
	# =========================		
	Deputs "===============PE Configuration============="
	if { [ info exists p_pe_port ] } {		
		set pe_num	[ llength $p_pe_port ]
		Deputs "pe_num:$pe_num"		
		foreach obj $p_pe_port {
			lappend pe [ $obj  cget -handle ]
		}
	} else {
		return [ GetErrorReturnHeader "Madatory parameters needed...p_pe_port" ]
	}

	foreach port $p_pe_port {
		# -- Num of PE interface equals which of P or PE
		set hPort [ $port cget -handle ]
		# -- Enable ospf routers 
		#set bgpObjList ""
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
			set ipv4Obj [ixNet add $ethernetObj ipv4]
			ixNet commit
			set ospfObj [ixNet add $ipv4Obj ospfv2]
			ixNet commit
			set ospfObj [ ixNet remapIds $ospfObj ]
			ixNet commit
			lappend ospfObjList $ospfObj
			set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
			ixNet commit
			set ldpObj [ ixNet remapIds $ldpObj ]
			ixNet commit		
			lappend ldpObjList $ldpObj
			set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]	
			ixNet commit
			set bgpObj [ ixNet remapIds $bgpObj ]
			ixNet commit		
			lappend bgpObjList $bgpObj		
		} else {
			foreach topoObj $topoObjList {
				set vportObj [ixNet getA $topoObj -vports]
				if {$vportObj == $hPort} {
					set deviceGroupList [ixNet getL $topoObj deviceGroup]
					foreach deviceGroupObj $deviceGroupList {
						set ethernetList [ixNet getL $deviceGroupObj ethernet]
						foreach ethernetObj $ethernetList {
							set ipv4ObjList [ixNet getL $ethernetObj ipv4] 
							foreach ipv4Obj $ipv4ObjList {							
								set ospfObj [ixNet getL $ipv4Obj ospfv2]
								if {[llength $ospfObj] != 0} {
									set ospfObj [ ixNet remapIds $ospfObj ]
								} else {
									set ospfObj [ixNet add $ipv4Obj ospfv2]
									ixNet commit	
									set ospfObj [ ixNet remapIds $ospfObj ]
									
								}
								lappend ospfObjList $ospfObj	
								set ldpObj [ixNet getL $ipv4Obj ldpBasicRouter]
								if {[llength $ldpObj] != 0} {
									set ldpObj [ ixNet remapIds $ldpObj ]
								} else {
									set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
									ixNet commit	
									set ldpObj [ ixNet remapIds $ldpObj ]
								
								}
								lappend ldpObjList $ldpObj	
							
								set bgpObj [ixNet getL $ipv4Obj bgpIpv4Peer]	
								if {[llength $bgpObj] != 0} {
									set bgpObj [ ixNet remapIds $bgpObj ]
								} else {
									set bgpObj [ixNet add $ipv4Obj bgpIpv4Peer]
									ixNet commit	
									set bgpObj [ ixNet remapIds $bgpObj ]
								
								}		
								lappend bgpObjList $bgpObj								
							}
						}
					}
				}
			}
		}

		# -- Enable ospf routers 
		set ospfV2Hndle [ixNet getA [ixNet getRoot]/globals/topology/ospfv2Router -enableDrBdr]	
		set value2Obj [ixNet setA $ospfV2Hndle/singleValue -value True]
		ixNet commit

		foreach  ospfObj $ospfObjList {
			set ipPattern [ixNet getA [ixNet getA $ospfObj -active] -pattern]
			SetMultiValues $ospfObj "-active" $ipPattern True
			ixNet commit
		}
		# -- Enable ldp routers 	
		foreach  ldpObj $ldpObjList {
			#Enable protocol 
			set ipPattern [ixNet getA [ixNet getA $ldpObj -active] -pattern]
			SetMultiValues $ldpObj "-active" $ipPattern True
			ixNet commit
		}
		# -- Enable bgp routers 
		foreach  bgpObj $bgpObjList {
			set ipPattern [ixNet getA [ixNet getA $bgpObj -active] -pattern]
			SetMultiValues $bgpObj "-active" $ipPattern True
			ixNet commit
		}
		
		# -- translate rt
		set targetList		[ list ]
		set rtInfo			[ split $pe_bgp_rt ":" ]
		set asip			[ lindex $rtInfo 0 ]
		set assigned 		[ lindex $rtInfo 1 ]
		set rtstepInfo		[ split $pe_bgp_rt_step ":" ]
		set asipStep		[ lindex $rtstepInfo 0 ]
		set assignedStep	[ lindex $rtstepInfo 1 ]

		# -- translate rd
		set distinguisherList [ list ]
		set rdInfo			[ split $pe_bgp_rd ":" ]
		set d_asip			[ lindex $rdInfo 0 ]
		set d_assigned		[ lindex $rdInfo 1 ]
		set rdStepInfo		[ split $pe_bgp_rd_step ":" ]
		set d_asipStep		[ lindex $rdStepInfo 0 ]
		set d_assignedStep	[ lindex $rdStepInfo 1 ]

		if { $p_router_num } {
			# -- Config P interface
			Deputs "===============P interface============="
			if { [ info exists p_ipv4_addr ] && [ info exists p_pe_dut_addr ] } {

				if { $p_pe_vlan_enable } {
					$port config \
							-intf_ip $p_ipv4_addr  -inner_vlan_enable $p_pe_vlan_enable \
							-intf_num $p_router_num \
							-intf_ip_step $p_ipv4_step \
							-intf_ip_mod $p_ipv4_mod \
							-dut_ip $p_pe_dut_addr \
							-dut_ip_num $p_router_num \
							-dut_ip_mod $p_pe_dut_mod \
							-inner_vlan_id $p_pe_vlan_id \
							-inner_vlan_step $p_pe_vlan_step \
							-mask $p_ipv4_pfx -dut_ip_step $p_pe_dut_step 
				} else {
					$port config \
							-intf_ip $p_ipv4_addr \
							-intf_num $p_router_num \
							-intf_ip_step $p_ipv4_step \
							-intf_ip_mod $p_ipv4_mod \
							-dut_ip $p_pe_dut_addr \
							-dut_ip_num $p_router_num \
							-dut_ip_mod $p_pe_dut_mod \
							-mask $p_ipv4_pfx -dut_ip_step $p_pe_dut_step 
				}
						
				set p_pe_vlan_id	[ expr $p_pe_vlan_id + $p_pe_vlan_step * $p_router_num ]
				set p_ipv4_addr [ IncrementIPAddr $p_ipv4_addr $p_ipv4_port_mod $p_ipv4_port_step ]
				set p_pe_dut_addr [ IncrementIPAddr $p_pe_dut_addr $p_pe_dut_port_mod $p_pe_dut_port_step ]
			} 
			set p_int [GetDependentNgpfProtocolHandle $ldpObj "ethernet"]		
			Deputs "p_int is: $p_int"	
			set p_pe_interface(CONNECTED,$port) $p_int
			
			# -- Config PE loopback interface
			Deputs "===============PE interface============="
			if { [ info exists pe_loopback_ipv4_addr ] && [ info exists p_pe_dut_loopback_addr ] } {
				set pe_lpback_addr $pe_loopback_ipv4_addr
				set dut_lpback_addr $p_pe_dut_loopback_addr
				Deputs "loopback addr:$pe_lpback_addr"
				set pe_co_vpn_route_addr	$pe_vpn_route_addr
				Deputs "pe co-vpn route addr: $pe_co_vpn_route_addr"
				set p_lpback_addr $p_loopback_ipv4_addr
				foreach p $p_int {
					Deputs Step20
					set routeDataObj [ixNet getL $deviceGroupObj routerData]
					set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
						SetMultiValues $routeDataObj "-routerId" $ipPattern $p_loopback_ipv4_addr	
						ixNet commit
						# -- add ldp interface
						
						foreach ldpObj $ldpObjList {
						
							set p_pe_ldp(ROUTER,$port) $ldpObj
							set ipObj [GetDependentNgpfProtocolHandle $ldpObj ip]
							if {[string first "ipv4" $ipObj] != -1} {
								set ip_version "ipv4"
								set ldpInt [ixNet getL $ipObj "ldpConnectedInterface"] 			
							}
								
							ixNet setM $ldpInt -active True 
							ixNet commit
							# -- add unconnected interface via each p interface
							Deputs "pe num:$pe_router_num"
							for { set index 0 } { $index < $pe_router_num } { incr index } {
								Deputs Step30
								set deviceGroupObjLdp [GetDependentNgpfProtocolHandle $ldpInt "deviceGroup"]						
								set int [ixNet add $deviceGroupObjLdp "ethernet"]
								ixNet commit 
								set int [ ixNet remapIds $int ]       
																
								Deputs "unconnected interface: $int connected via: $p"
								ixNet setA $int/unconnected -connectedVia $p
								ixNet commit
								set ip [ixNet add $int "ipv4"]
								ixNet commit 
								set ip [ ixNet remapIds $ip ]   
								set ipPattern [ixNet getA [ixNet getA $ip -address] -pattern]
								SetMultiValues $ip "-address" $ipPattern $pe_loopback_ipv4_addr	


								set ipPattern [ixNet getA [ixNet getA $ip -gatewayIp] -pattern]
								SetMultiValues $ip "-gatewayIp" $ipPattern $p_pe_dut_loopback_addr	

								if {[string first "." $pe_loopback_ipv4_pfx] != -1} {
									set pLen [SubnetToPrefixlenV4 $pe_loopback_ipv4_pfx]
								} else {
									set pLen $pe_loopback_ipv4_pfx
								}
								set ipPattern [ixNet getA [ixNet getA $ip -prefix] -pattern]
								SetMultiValues $ip "-prefix" $ipPattern $pe_loopback_ipv4_pfx	
								
								ixNet commit
							
								lappend p_pe_interface(UNCONNECTED,$p) $int
								Deputs "unconnected interface saved: $p_pe_interface(UNCONNECTED,$p)"
								Deputs "saved elements: [ array names p_pe_interface ]"
									
								# -- set interface between P and PE
								if { [ info exists pe_ipv4_addr ] == 0 } {
									set pe_ipv4_addr 11.11.11.1
								} 

								# -- add ldp FEC range
								set deviceGroupObj [GetDependentNgpfProtocolHandle $ldpObj "deviceGroup"]
								set ethernetObj [GetDependentNgpfProtocolHandle $ldpObj "ethernet"]
								puts "******************************** deviceGroup obj is :: $deviceGroupObj"
								set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
								ixNet commit
								set networkGroupObj [ ixNet remapIds $networkGroupObj ]
			
								set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
								ixNet commit
								ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
								ixNet setA $ipPoolObj/connector -connectedTo $ldpObj
				
								set connector [ixNet add $ipPoolObj connector]
								ixNet setA $connector -connectedTo $ldpObj
								ixNet commit
								set range [ixNet getL $ipPoolObj ldpFECProperty]
	
								set ipPattern [ixNet getA [ixNet getA $range -active] -pattern]
								SetMultiValues $range "-active" $ipPattern true
								ixNet commit
								set handle [ ixNet remapIds $range ]
								set ipPattern [ixNet getA [ixNet getA $handle -labelValue] -pattern]
								SetMultiValues $handle "-labelValue" $ipPattern $ldp_start_label

								set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
								SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
								set ipPattern [ixNet getA [ixNet getA $ipPoolObj -networkAddress] -pattern]
								SetMultiValues $ipPoolObj "-networkAddress" $ipPattern $pe_loopback_ipv4_addr
								ixNet commit
							}
							# -- add ibgp via unconnected interface
							foreach  bgpObj $bgpObjList {
								#Retrive the interface         
								lappend interface_list [GetDependentNgpfProtocolHandle $bgpObj "ethernet"]
								set deviceGroup [GetDependentNgpfProtocolHandle $bgpObj "deviceGroup"]
								set ipPattern [ixNet getA [ixNet getA $bgpObj -type] -pattern]
								SetMultiValues $bgpObj "-type" $ipPattern "internal"

								set ipPattern [ixNet getA [ixNet getA $bgpObj -localAs2Bytes] -pattern]
								SetMultiValues $bgpObj "-localAs2Bytes" $ipPattern $pe_bgp_as
				
								set ipPattern [ixNet getA [ixNet getA $bgpObj -bgpId] -pattern]
								SetMultiValues $bgpObj "-bgpId" $ipPattern $pe_loopback_ipv4_addr

								set ipPattern [ixNet getA [ixNet getA $bgpObj -dutIp] -pattern]
								SetMultiValues $bgpObj "-dutIp" $ipPattern $p_pe_dut_loopback_addr
			
								set ibgp [ ixNet remapIds $bgpObj ]
				
								lappend pe_i_bgp(ROUTER,$port) $ibgp
								set networkGroupObj [ixNet add $deviceGroup "networkGroup"]
								ixNet commit
								set networkGroupObj [ ixNet remapIds $networkGroupObj ]			
								lappend networkGroupObjList $networkGroupObj
				
								set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
								ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
								ixNet commit	
	
								set connector [ixNet add $ipPoolObj connector]
								ixNet setA $connector -connectedTo $bgpObj
								ixNet commit
								set hBgp [ ixNet remapIds $bgpObj ]
			
								if { $vpn_unique_per_pe == 0 } {
									set pe_vpn_route_addr $pe_co_vpn_route_addr
								}
								for { set vpnIndex 0 } { $vpnIndex < $vpn_num_per_pe } { incr vpnIndex } {
									Deputs Step40
									set bgpVrfObj [ ixNet getL $hBgp bgpVrf ]
									if { [ llength $bgpVrfObj ] == 0 } {
										set bgpVrfObj [ ixNet add $hBgp bgpVrf]
										ixNet commit
										set bgpVrfObj [ ixNet remapIds $bgpVrfObj ]
									}				
									set bgpImportObjList [ ixNet getL $bgpVrfObj bgpExportRouteTargetList ]
									set bgpVrfObj [ixNet remapIds $bgpVrfObj]
									lappend pe_l3site(SITE,$hBgp) $bgpVrfObj

									ixNet setA $bgpVrfObj -count 1
									ixNet setA $bgpVrfObj -active true
									# -- set RT
									set targetList [ list ]
									if { [ string is integer $asip ] } {
										Deputs Step50								
										set asType as
										set asNumber $asip
										set ipAddr 0.0.0.0								
										incr asip 		$asipStep
										Deputs "asipStep:$asipStep"									
										Deputs "asip:$asip"									
									} else {
										Deputs Step60
										set asType ip
										set asNumber 100
										set ipAddr $asip									
										set pfxLen [ SubnetToPrefixlenV4 $asipStep ]
										set asip   [ IncrementIPAddr $pfxLen ]
									}
									set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetAsNumber] -pattern]
									SetMultiValues $bgpImportObjList "-targetAsNumber" $ipPattern $asNumber
					
									set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetAssignedNumber] -pattern]
									SetMultiValues $bgpImportObjList "-targetAssignedNumber" $ipPattern $assigned
				
									set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetType] -pattern]
									SetMultiValues $bgpImportObjList "-targetType" $ipPattern $asType		

									set ipPattern [ixNet getA [ixNet getA $bgpImportObjList -targetIpAddress] -pattern]
									SetMultiValues $bgpImportObjList "-targetIpAddress" $ipPattern $ipAddr
									incr assigned 	$assignedStep		
								
								# -- set vpn route
					
									ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -start $pe_vpn_route_addr -direction increment
									ixNet commit
	
									if {[string first "." $pe_vpn_route_mask] != -1} {
										set pLen [SubnetToPrefixlenV4 $pe_vpn_route_mask]
									} else {
										set pLen $pe_vpn_route_mask
									}
									set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
									SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen	

									set stepvalue [GetIpV46Step ipv4 [ expr 32 - $pe_vpn_route_vrf_mod ] $pe_vpn_route_vrf_step]

									#set ipPattern [ixNet getA [ixNet getA $ipPoolObj -networkAddress] -pattern]
									#SetMultiValues $ipPoolObj "-networkAddress" $ipPattern $stepvalue	
										
									ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
									ixNet commit
		
									set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixAddrStep] -pattern]
									SetMultiValues $ipPoolObj "-prefixAddrStep" $ipPattern $pe_vpn_route_step	
					              
								    ixNet setA $ipPoolObj -count $pe_vpn_route_num						
									ixNet commit
# -- set vpn route RD
									set devicehandle [GetDependentNgpfProtocolHandle $bgpVrfObj "deviceGroup"]
									set routeRangeList  [ixNet add $devicehandle networkGroup]
									ixNet commit
									set ipPoolObj [ixNet add $routeRangeList "ipv4PrefixPools"]
									ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
									ixNet commit
									set ipPoolObj [ ixNet remapIds $ipPoolObj ]								
									set connector [ixNet add $ipPoolObj connector]
									ixNet setA $connector -connectedTo $bgpVrfObj
									ixNet commit
				
									set bgpVpnRouteObj [ixNet add $ipPoolObj bgpL3VpnRouteProperty]
									ixNet commit
									set bgpVpnRouteObj [ ixNet remapIds $bgpVpnRouteObj ]


									if { [ string is integer $asip ] } {										
										incr d_asip $d_asipStep	
									} else {										
										set pfxLen [ SubnetToPrefixlenV4 $d_asipStep ]
										set d_asip [ IncrementIPAddr $pfxLen ]
									}
												
									set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherAsNumber] -pattern]
									SetMultiValues $bgpVpnRouteObj "-distinguisherAsNumber" $ipPattern $d_asip

									set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherType] -pattern]
									SetMultiValues $bgpVpnRouteObj "-distinguisherType" $ipPattern as
							
				
									set ipPattern [ixNet getA [ixNet getA $bgpVpnRouteObj -distinguisherAssignedNumber] -pattern]
									SetMultiValues $bgpVpnRouteObj "-distinguisherAssignedNumber" $ipPattern $d_assigned

									#-distinguisherAsNumberStepAcrossVrfs $d_asipStep \
									#-distinguisherAssignedNumberStepAcrossVrfs $d_assignedStep
									incr d_assigned $d_assignedStep
									Deputs "rt: ${asip}:${assigned} rd: ${d_asip}:${d_assigned}"								

									set pe_vpn_route_addr [ IncrementIPAddr \
										$pe_vpn_route_addr $pe_vpn_route_vrf_mod \
										$pe_vpn_route_vrf_step ]
								}	
                             
							}

							incr ldp_start_label
							set p_pe_interface(IP,$int) $pe_ipv4_addr
							set p_pe_interface(PFX,$int) $pe_ipv4_pfx
							set pe_ipv4_addr \
								[ IncrementIPAddr $pe_ipv4_addr \
								$pe_ipv4_mod $pe_ipv4_step ]
							set pe_loopback_ipv4_addr \
								[ IncrementIPAddr $pe_loopback_ipv4_addr \
								$pe_loopback_ipv4_mod $pe_loopback_ipv4_step ]
							set p_pe_dut_loopback_addr \
								[ IncrementIPAddr $p_pe_dut_loopback_addr \
								$p_pe_dut_loopback_mod $p_pe_dut_loopback_step ]
								
# -- same VPN per PE
							if { $vpn_unique_per_pe == 0 } {
								# -- translate rt
									set rtInfo			[ split $pe_bgp_rt ":" ]
									set asip			[ lindex $rtInfo 0 ]
									set assigned 		[ lindex $rtInfo 1 ]
									set rtstepInfo		[ split $pe_bgp_rt_step ":" ]
									set asipStep		[ lindex $rtstepInfo 0 ]
									set assignedStep	[ lindex $rtstepInfo 1 ]
								# -- translate rd
									set rdInfo			[ split $pe_bgp_rd ":" ]
									set d_asip			[ lindex $rdInfo 0 ]
									set d_assigned		[ lindex $rdInfo 1 ]
									set rdStepInfo		[ split $pe_bgp_rd_step ":" ]
									set d_asipStep		[ lindex $rdStepInfo 0 ]
									set d_assignedStep	[ lindex $rdStepInfo 1 ]
								Deputs Step100
								Deputs "rt: ${asip}:${assigned} rd: ${d_asip}:${d_assigned}"								
								set pe_co_vpn_route_addr [ IncrementIPAddr \
									$pe_co_vpn_route_addr $pe_vpn_route_mask \
									$pe_vpn_route_num ]
							}
						}

						set p_loopback_ipv4_addr [ IncrementIPAddr $p_loopback_ipv4_addr 16 1 ]
					}
					set p_loopback_ipv4_addr $p_lpback_addr
					set pe_loopback_ipv4_addr [ IncrementIPAddr \
						$pe_lpback_addr $pe_loopback_ipv4_port_mod $pe_loopback_ipv4_port_step ]
					set p_pe_dut_loopback_addr [ IncrementIPAddr \
						$dut_lpback_addr $p_pe_dut_loopback_port_mod $p_pe_dut_loopback_port_step ]
                }
			} else {
				# -- No P router
				# -- Config PE interface		
				if { [ info exists pe_ipv4_addr ] && [ info exists p_pe_dut_addr ] } {						
					if { $p_pe_vlan_enable } {
						$port config \
							-intf_ip $pe_ipv4_addr  -inner_vlan_enable $p_pe_vlan_enable \
							-intf_num $pe_router_num \
							-intf_ip_step $pe_ipv4_step \
							-intf_ip_mod $pe_ipv4_mod \
							-mask $pe_ipv4_pfx \
							-dut_ip $p_pe_dut_addr \
							-dut_ip_num $pe_router_num \
							-dut_ip_step $p_pe_dut_step \
							-dut_ip_mod $p_pe_dut_mod \
							-inner_vlan_id $p_pe_vlan_id \
							-inner_vlan_step $p_pe_vlan_step
					} else {
						$port config \
							-intf_ip $pe_ipv4_addr \
							-intf_num $pe_router_num \
							-intf_ip_step $pe_ipv4_step \
							-intf_ip_mod $pe_ipv4_mod \
							-mask $pe_ipv4_pfx \
							-dut_ip $p_pe_dut_addr \
							-dut_ip_num $pe_router_num \
							-dut_ip_step $p_pe_dut_step \
							-dut_ip_mod $p_pe_dut_mod 
					}
					
					set p_pe_vlan_id	[ expr $p_pe_vlan_id + $p_pe_vlan_step * $pe_router_num ]
					set pe_ipv4_addr [ IncrementIPAddr $pe_ipv4_addr $pe_ipv4_port_mod $pe_ipv4_port_step ]
					set p_pe_dut_addr [ IncrementIPAddr $p_pe_dut_addr $p_pe_dut_port_mod $p_pe_dut_port_step ]
				} 	

				# -- Config PE loopback interface
				if { [ info exists pe_loopback_ipv4_addr ] && [ info exists p_pe_dut_loopback_addr ] } {
					set pe_lpback_addr $pe_loopback_ipv4_addr
					set dut_lpback_addr $p_pe_dut_loopback_addr
					puts "loopback addr:$pe_lpback_addr"
					
					foreach ospfObj $ospfObjList {
					
						set pe_int [GetDependentNgpfProtocolHandle $ospfObj ethernet]
						set p_pe_interface(CONNECTED,$port) $pe_int
					
						# -- add unconnected interface via each p interface
						foreach pe $pe_int {	
							set devicehandle [GetDependentNgpfProtocolHandle $ospfObj "deviceGroup"]
							set int [ ixNet add $devicehandle ethernet ]
							ixNet commit 
							set int [ ixNet remapIds $int ]
							ixNet setA $int -enabled True
							ixNet setA $int/unconnected -connectedVia $pe
							ixNet commit
							set ip [ixNet add $int "ipv4"]
							ixNet commit 
							set ip [ ixNet remapIds $ip ]   
							set ipPattern [ixNet getA [ixNet getA $ip -address] -pattern]
							SetMultiValues $ip "-address" $ipPattern $pe_loopback_ipv4_addr	

							set ipPattern [ixNet getA [ixNet getA $ip -gatewayIp] -pattern]
							SetMultiValues $ip "-gatewayIp" $ipPattern $p_pe_dut_loopback_addr	

							if {[string first "." $pe_loopback_ipv4_pfx] != -1} {
								set pLen [SubnetToPrefixlenV4 $pe_loopback_ipv4_pfx]
							} else {
								set pLen $pe_loopback_ipv4_pfx
							}
							set ipPattern [ixNet getA [ixNet getA $ip -prefix] -pattern]
							SetMultiValues $ip "-prefix" $ipPattern $pe_loopback_ipv4_pfx								
							ixNet commit						

							set routeRangeList  [ixNet add $devicehandle networkGroup]
							ixNet commit

							lappend p_pe_interface(UNCONNECTED,$pe) $int
							set p_pe_interface(IP,$int) $pe_loopback_ipv4_addr
							set p_pe_interface(PFX,$int) $pe_loopback_ipv4_pfx

							set pe_loopback_ipv4_addr \
								[ IncrementIPAddr $pe_loopback_ipv4_addr \
								$pe_loopback_ipv4_mod $pe_loopback_ipv4_step ]
							set p_pe_dut_loopback_addr \
								[ IncrementIPAddr $p_pe_dut_loopback_addr \
								$p_pe_dut_loopback_mod $p_pe_dut_loopback_step ]
						}
					}
					set pe_loopback_ipv4_addr [ IncrementIPAddr \
					$pe_lpback_addr $pe_loopback_ipv4_port_mod $pe_loopback_ipv4_port_step ]
					set p_pe_dut_loopback_addr [ IncrementIPAddr \
					$dut_lpback_addr $p_pe_dut_loopback_port_mod $p_pe_dut_loopback_port_step ]
					
				}

			
# -- Add ospf routers 
				foreach p $p_pe_interface(CONNECTED,$port) {
					Deputs "unconnected interface via $p : $p_pe_interface(UNCONNECTED,$p)"
				
					set p_pe_ospf(ROUTER,$port) $ospfObj
					ixNet setM $ospfObj -connectedToDut True -interfaces $p -enabled True
					ixNet commit
			
					foreach pe $p_pe_interface(UNCONNECTED,$p) {
						# -- Add ospf interface
						set pe_int_ip $p_pe_interface(IP,$pe)
						set pe_int_pfx $p_pe_interface(PFX,$pe)
						Deputs "connected ip via $pe : $pe_int_ip / $pe_int_pfx"

						set ipPattern [ixNet getA [ixNet getA $ospfObj -networkType] -pattern]
						SetMultiValues $ospfObj "-networkType" $ipPattern pointtopoint

						ixNet commit
						
						#	-connectedToDut False \
							-interfaceIpAddress $pe_int_ip \
							-advertiseNetworkRange True \
							-networkRangeIp $pe_loopback_ipv4_addr \
							-networkRangeIpMask $pe_loopback_ipv4_pfx \
							-networkRangeIpByMask True \
							-networkRangeRouterId $pe_loopback_ipv4_addr \
							-interfaceIpMaskAddress [ PrefixlenToSubnetV4 $pe_int_pfx ]
						if { $p_router_num } {
							ixNet setA $ospfObj -localRouterID $p_loopback_ipv4_addr
						} else {
							ixNet setA $ospfObj -localRouterID $pe_int_ip
						}
						ixNet commit
						set pe_loopback_ipv4_addr [ IncrementIPAddr \
						$pe_loopback_ipv4_addr $pe_loopback_ipv4_mod $pe_loopback_ipv4_step ]

					}
					set p_loopback_ipv4_addr [ IncrementIPAddr $p_loopback_ipv4_addr 16 1 ]
					Deputs "P router id:$p_loopback_ipv4_addr"
				}
			}
		}

    return [GetStandardReturnHeader]
	
}
