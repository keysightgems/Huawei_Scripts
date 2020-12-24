
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.28
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1
#		1. Add create obj command in config method
#		2. Add implementation for set_igmp_over_dhcp in both DhcpHost class and his child class
# Version 1.2.1.4
#		3. Add method wait_request_complete wait_release_complete
#		4. Add exception branch in set_dhcp_msg_option for customizing default option in [ 53, 61, 51, 57, 55 ]
# Version 1.3.1.5
#		5. Read Err: "ixNet::ERROR-ErrorsOccured-6401-Error in Plugin- There is no license available for DHCP Client"
#			in DHCP::request method.
#		   Fixed by after 1000 and try again.
# Version 1.4.1.6
#		6. Add after 5000 in request to make sure the stats will be updated
#		7. Remove the view after get_detailed stats
# Version 1.5
#		8. Set DHCP option 51 to configuration -suggested_lease_time
#		9. Set DHCP option 55 to configuration of request list
# Version 1.6.1.9
#		10. Add catch retry in DHCP Client request and DHCP Server start for a license check issue
#		11. Add get_stats method in DHCP server 
# Version 1.7.1.10
#		12. Add 5seconds delay in DHCP server start
# Version 1.8.1.11
#		13. Add 
#				-ipv4_addr 
#				-ipv4_prefix_len 
#				-ipv4_gw 
#				-gw_step 
#				-mac_addr 
#				-mac_add_step 
#				-router_list
#				-domain_name_server_list
#			in DHCP Server config
# Version 1.9.2.1
#		14. Add method get_lease_address in DhcpServer
#		15. Add method get_stats in Dhcpv6Server
# Version 1.10.2.1-patch
#		16. Change dhcpPerSession naming issue
# Version 1.11
#		17. Add ia-type in Dhcpv6Server.config
# Version 1.12.2.4
#		18. Implement wait_request_complete to to get the result of ALL-OFFER or NOT
#		19. Implement wait_release_complete to to get the result of ALL-RELEASE or NOT
# Version 1.13.2.5
#		20. Add initilization method in Dhcp.config when invoked with empty object(object reborn)
# Version 1.14.2.8
#		21. Add abort method in DhcpHost
# Version 1.15.2.24
#		22. Add -ia_type in Dhcpv6.config
# Version 1.16.2.25
#		23. Add reborn to Dhcpv6.config
#		24. Add -count to DhcpServer.config
# Version 1.17.3.0
#		25. inherit from ProtocolNgpfStackObject
# Version 1.18.3.1L
#		26. add two or more dhcpServerEndpoints will prompt errors, but valid actully. Add catch to fix
# Version 1.19.3.7
#		27. add solicit msg type in set_dhcp_msg_option
# Version 1.20.3.10
#		28. add customized request msg type
# Version 1.21.4.2
#       29. add -preferred_life_time, -valid_life_time to DhcpServer.config and add -iaid to Dhcpv6Host.config
# Version 1.22.Unicom.cgn
# 		30. add dual stack host
# Version 1.22
# 		31. add option82 in DhcpHost::set_dhcp_msg_option
# Version 1.23.4.13
#		32. identify option payload type in DhcpHost::set_dhcp_msg_option
# Version 1.24.6.20
#		33. add Ipv6AutoConfigHost
# Version 1.25 11.4
#       34. DhcpHost.config add -relay_pool_ipv4_addr 
# Version 1.26 12.26
#       35. DhcpHost.set_dhcp_msg_option add -enable_hex_value
# Version 1.27 3.14
#       36. add Dot1xHost
# Version 1.28 7.27
#       37. add port_avg_setup_rate to get_port_summary_stats

class DhcpHost {
    inherit ProtocolNgpfStackObject
    
    #public variable type
    #public variable stack
    public variable hIgmp
    public variable optionSet
    
    public variable rangeStats
    public variable hostCnt
    public variable hDhcp
    public variable requestDuration
	public variable ipVersion
	public variable statsView
	public variable dhcpStackVersion
	
    constructor { port { onStack null } { hdhcp null }} { chain $port $onStack $hdhcp } {}
    method reborn { dhcpVersion { onStack null } } {
	    set tag "body DhcpHost::reborn [info script]"
	    Deputs "----- TAG: $tag -----"
		    
	    array set rangeStats [list]
	    if { $onStack == "null" } {
			Deputs "new dhcp endpoint"
			chain 
			set sg_ethernet $stack
			#-- add dhcp endpoint stack
			set ipVersion $dhcpVersion
			if {$dhcpVersion == "ipv4"} {
			    set ipv4Obj [ixNet getL $sg_ethernet ipv4]
			    if {[llength $ipv4Obj] == 0} {
				    set sg_dhcpEndpoint [ixNet add $sg_ethernet dhcpv4client]
				} else {
				    set topoObj [GetDependentNgpfProtocolHandle $sg_ethernet "topology"]
				    set deviceGroupObj [ixNet add $topoObj deviceGroup]
				    ixNet commit
				    set ethernetObj [ixNet add $deviceGroupObj ethernet]
				    ixNet commit
				    set sg_dhcpEndpoint [ixNet add $ethernetObj dhcpv4client]
				    ixNet setA $deviceGroupObj -multiplier 1
				}
			} else {
				#set dhcpVersion ipv6
				set sg_dhcpEndpoint [ixNet add $sg_ethernet dhcpv6client]
			}
			ixNet commit
			set sg_dhcpEndpoint [ixNet remapIds $sg_dhcpEndpoint]
			set hDhcp $sg_dhcpEndpoint
		} else {
			Deputs "based on existing stack:$onStack"
			set ethHandle [GetDependentNgpfProtocolHandle $onStack "ethernet"]
			set result [regexp {dhcpv(\d)} $onStack match match1]
			if {$match1 == 4} {
				set sg_dhcpEndpoint [ixNet add $ethHandle dhcpv6client]
				ixNet commit
				set sg_dhcpEndpoint [ixNet remapIds $sg_dhcpEndpoint]
			} else {
				Deputs "something went wrong !!!!!! onStack value $onStack and etheHandle found is $ethHandle"
			}
			set hDhcp $sg_dhcpEndpoint
		}
	
	    set handle $hDhcp
		# set dhcpStackVersion dhcpVersion
		$this configure -dhcpStackVersion $dhcpVersion
		
		set dhcpGlobal [ixNet add [ixNet getRoot]/globals/protocolStack dhcpGlobals]
		ixNet commit
		set dhcpGlobal [ixNet remapIds $dhcpGlobal]
		set optionSet [ixNet add $dhcpGlobal dhcpOptionSet ]
		ixNet commit
		set optionSet [ixNet remapIds $optionSet]
	    set igmpObj ""
    }
	
    method config { args } {}
    method request {} {}
    method release {} {}
    method renew {} {}
    method abort {} {}
    method retry {} {}
	## Support not found for resume() and pause() in NGPF
    method resume {} {}
    method pause {} {}
    method rebind {} {}
    method set_dhcp_msg_option { args } {}
    method get_summary_stats {} {}
    method get_detailed_stats {} {}
    method set_igmp_over_dhcp { args } {}
    method unset_igmp_over_dhcp {} {}
    method wait_request_complete { args } {}
    method wait_release_complete { args } {}
    method get_port_summary_stats { view } {}

	
    method CreateDhcpPerSessionView {} {
        set tag "body DhcpHost::CreateDhcpPerSessionView [info script]"
        Deputs "----- TAG: $tag -----"
        set root [ixNet getRoot]
        set customView [ixNet add $root/statistics view]
        ixNet setMultiAttribute $customView -pageTimeout 25 \
                                                    -type layer23NextGenProtocol \
                                                    -caption "dhcpPerSessionView" \
                                                    -visible true -autoUpdate true \
                                                    -viewCategory NextGenProtocol
        ixNet commit
        set view [lindex [ixNet remapIds $customView] 0]

        set advCv [ixNet add $view "advancedCVFilters"]
        set type "Per Session"
        set protocol "DHCPv4 Client"
        ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                             -protocol \{$protocol\} \
                                                             -availableFilterOptions \{$type\} \
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
             ixNet setA $stat -aggregationType first
             ixNet commit
        }
        ixNet setA $view -enabled true
        ixNet commit
        ixNet execute refresh $view
        return $view
    }
    
    
    method CreateDhcpPerRangeView {} {
        set tag "body DhcpHost::CreateDhcpPerRangeView [info script]"
        Deputs "----- TAG: $tag -----"
        set root [ixNet getRoot]
        set customView [ixNet add $root/statistics view]
        ixNet setMultiAttribute $customView -pageTimeout 25 \
                                                    -type layer23NextGenProtocol \
                                                    -caption "dhcpPerRangeView" \
                                                    -visible true -autoUpdate true \
                                                    -viewCategory NextGenProtocol
        ixNet commit
        set customView [lindex [ixNet remapIds $customView] 0]

        set advCv [ixNet add $customView "advancedCVFilters"]
        set type "Per Device Group"
        set protocol "DHCPv6 Client"
        ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                             -protocol \{$protocol\} \
                                                             -availableFilterOptions \{$type\} \
                                                             -sortingStats {}
        ixNet commit

        set advCv [lindex [ixNet remapIds $advCv] 0]

        set ngp [ixNet add $customView layer23NextGenProtocolFilter]
        ixNet setMultiAttribute $ngp -advancedFilterName \"No\ Filter\" \
                                                       -advancedCVFilter $advCv \
                                                       -protocolFilterIds [list ] -portFilterIds [list ]
        ixNet commit
        set ngp [lindex [ixNet remapIds $ngp] 0]

        set stats [ixNet getList $customView statistic]
        foreach stat $stats {
             ixNet setA $stat -scaleFactor 1
             ixNet setA $stat -enabled true
             ixNet setA $stat -aggregationType sum
             ixNet commit
        }
        ixNet setA $customView -enabled true
        ixNet commit
        ixNet execute refresh $customView
        return $customView
    }
}

body DhcpHost::config { args } {

    global errorInfo
    global errNumber
    set tag "body DhcpHost::config [info script]"
Deputs "----- TAG: $tag -----"
#disable the interface

    eval { chain } $args
	
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {            
            -count {
                if { [ string is integer $value ] && ( $value <= 65535 ) } {
                    set count $value
					set hostCnt $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -circuit_id {
                set circuit_id  $value
            }
            -enable_circuit_id {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_circuit_id $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -enable_relay_agent {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_relay_agent $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -enable_remote_id {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_remote_id $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -relay_pool_ipv4_addr -
            -relay_agent_ipv4_addr {
                if { [ IsIPv4Address $value ] } {
                    set relay_agent_ipv4_addr $value
                    set enable_relay_agent 1
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
            }
            -relay_pool_ipv4_addr_step -
            -relay_agent_ipv4_addr_step {
                if { [ IsIPv4Address $value ] } {
                    set relay_agent_ipv4_addr_step $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
            }
            -relay_server_ipv4_addr {
                if { [ IsIPv4Address $value ] } {
                    set relay_server_ipv4_addr $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
            }		   
		   -relay_client_mac_addr_start {
			  
		   }		   
		   -relay_client_mac_addr_step {
			   
		   }		   
            -remote_id {
                set remote_id $value
            }
            -enable_auto_retry {
                set trans [ BoolTrans $value ]
                if { $trans == "1" } {
                } elseif { $trans == "0" } {
                    set retry_attempts 0
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -retry_attempts {
                if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set retry_attempts $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }

            -suggest_lease {
                if { [ string is integer $value ] && ( $value > 0 ) } {
                    set suggest_lease $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }		   
		    -use_broadcast_flag {
			  set use_broadcast_flag $value
		    }		   
		    -relay_server_ipv4_addr_step {
			  set relay_server_ipv4_addr_step $value
		    }
            -request_rate {
                set request_rate $value
            }
			-request_timeout {
                set request_timeout $value
            }
            -release_rate {
                set release_rate $value
            }
            -retry_count {
                set retry_count $value
            }
            -outstanding_session {
                set outstanding_session $value
            }
            -override_global_setup {
                set override_global_setup $value
            }
        }
	}
	set range $handle
    if { [ info exists count ] } {
        #ixNet setA $handle -count $count
        set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
        ixNet setA $deviceGroupObj -multiplier $count
        ixNet commit
    }

	if {[$this cget -dhcpStackVersion] == "ipv4"} {
		set configProtocol "dhcpv4client"
	} elseif {[$this cget -dhcpStackVersion] == "ipv6"} {
		set configProtocol "dhcpv6client"
	}

    if { [ info exists enable_relay_agent ] } {
		Deputs "setting enable_relay_agent"
		## add and enable a TLV 82 from DHCPv4client
		set tlvToAdd [getTlvHandleFromDefaultTlvCode $configProtocol 82]
		if {$tlvToAdd != ""} {	
			set tlvEntry [findIfTlvExist $handle 82]
			if {$tlvEntry == ""} {
				set dhcpRelayAgentTlvHandle [addTlvHandle $handle $tlvToAdd]
				Deputs "dhcpRelayAgentTlvHandle value added is $dhcpRelayAgentTlvHandle"
				ixNet setA $dhcpRelayAgentTlvHandle -isEnabled True
				ixNet commit
			}
		}
    }
    if { [ info exists enable_circuit_id ] } {
		## add and enable a TLV 82 from DHCPv4client and search for relay circuit and select the checkbox
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set circuitIdTlv [getTlvHandleFromTlvProfileCode $handle 1]
			Deputs "circuitIdTlv value added is $circuitIdTlv"
			ixNet setA $circuitIdTlv -isEnabled $enable_circuit_id
		}
		ixNet commit
    }
    if { [ info exists circuit_id ] } {
       	ixNet setA $range/dhcpRange -relayCircuitId $circuit_id
		## add and enable a TLV 82 from DHCPv4client and search for relay circuit ID and update the value
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added"
		} else {
			set circuitIdTlv [getTlvHandleFromTlvProfileCode $handle 1]
			ixNet setA $circuitIdTlv/subTlv -isEnabled True
			set objList [ixNet getL $circuitIdTlv/subTlv/value object]
			Deputs "circuitIdTlv value added is $circuitIdTlv and objList is $objList"
			set ipPattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			set fieldObj $objList/field
            SetMultiValues $fieldObj "-value" $ipPattern $circuit_id
		}
    }

    if { [ info exists use_broadcast_flag ] } {
		## enable the broadcast flag
		if {$use_broadcast_flag == 1} {
		 	set ipPattern [ixNet getA [ixNet getA $handle -dhcp4Broadcast] -pattern]
			SetMultiValues $handle "-dhcp4Broadcast" $ipPattern true
		} else {
		 	set ipPattern [ixNet getA [ixNet getA $handle -dhcp4Broadcast] -pattern]
			SetMultiValues $handle "-dhcp4Broadcast" $ipPattern false
		}
    }
    if { [ info exists relay_server_ipv4_addr_step ] } {
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set serverIpTlv [getTlvHandleFromTlvProfileCode $handle 11]
			ixNet setA $serverIpTlv/subTlv -isEnabled true
			set objList [ixNet getL $serverIpTlv/subTlv/value object]
			ixNet setA $objList/field -isEnabled True
			Deputs "serverIpTlv value added is $serverIpTlv and objList is $objList"
			set pattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			if {$pattern == "counter"} {
			    ixNet setA [ixNet getA $objList/field -value]/counter -step $relay_server_ipv4_addr_step
                ixNet commit
            } else {
                ixNet add [ixNet getA $objList/field -value] counter
                ixNet commit
                ixNet setA [ixNet getA $objList/field -value]/counter -step $relay_server_ipv4_addr_step
                ixNet commit
            }
		}
    }
    if { [ info exists relay_agent_ipv4_addr ] } {
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set agentIpTlv [getTlvHandleFromTlvProfileCode $handle 5]
			ixNet setA $agentIpTlv/subTlv -isEnabled true
			set objList [ixNet getL $agentIpTlv/subTlv/value object]
			ixNet setA $objList/field -isEnabled True
			Deputs "agentIpTlv value added is $agentIpTlv and objList is $objList"
			set pattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			if {$pattern == "counter"} {
			    ixNet setA [ixNet getA $objList/field -value]/counter -start $relay_agent_ipv4_addr
                ixNet commit
            } else {
                ixNet add [ixNet getA $objList/field -value] counter
                ixNet commit
                ixNet setA [ixNet getA $objList/field -value]/counter -start $relay_agent_ipv4_addr
                ixNet commit
            }
		}
    }
    if { [ info exists relay_agent_ipv4_addr_step ] } {
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set agentIpTlv [getTlvHandleFromTlvProfileCode $handle 5]
			ixNet setA $agentIpTlv/subTlv -isEnabled true
			set objList [ixNet getL $agentIpTlv/subTlv/value object]
			ixNet setA $objList/field -isEnabled True
			Deputs "agentIpTlv value added is $agentIpTlv and objList is $objList"
			set pattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			if {$pattern == "counter"} {
			    ixNet setA [ixNet getA $objList/field -value]/counter -step $relay_agent_ipv4_addr_step
                ixNet commit
            } else {
                ixNet add [ixNet getA $objList/field -value] counter
                ixNet commit
                ixNet setA [ixNet getA $objList/field -value]/counter -step $relay_agent_ipv4_addr_step
                ixNet commit
            }
		}
    }
    if { [ info exists relay_server_ipv4_addr ] } {
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set serverIpTlv [getTlvHandleFromTlvProfileCode $handle 11]
			ixNet setA $serverIpTlv/subTlv -isEnabled true
			set objList [ixNet getL $serverIpTlv/subTlv/value object]
			ixNet setA $objList/field -isEnabled True
			Deputs "serverIpTlv value added is $serverIpTlv and objList is $objList"
			set pattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			if {$pattern == "counter"} {
			    ixNet setA [ixNet getA $objList/field -value]/counter -start $relay_server_ipv4_addr
                ixNet commit
            } else {
                ixNet add [ixNet getA $objList/field -value] counter
                ixNet commit
                ixNet setA [ixNet getA $objList/field -value]/counter -start $relay_server_ipv4_addr
                ixNet commit
            }
		}
    }
    if { [ info exists remote_id ] } {
       ixNet setA $range/dhcpRange -relayRemoteId $remote_id
		## TLV 2 under DHCP relay agent TLV
		set tlvList [ixNet getL $handle/tlvProfile tlv]
		if {$tlvList == ""} {
			Deputs "No Tlvs are added. Returning"
		} else {
			set remoteIdTlv [getTlvHandleFromTlvProfileCode $handle 2]
			ixNet setA $remoteIdTlv/subTlv -isEnabled true
			set objList [ixNet getL $remoteIdTlv/subTlv/value object]
			ixNet setA $objList/field -isEnabled True
			Deputs "remoteIdTlv value added is $remoteIdTlv and objList is $objList"
			set ipPattern [ixNet getA [ixNet getA $objList/field -value] -pattern]
			set fieldObj $objList/field
			SetMultiValues $fieldObj "-value" $ipPattern $remote_id
		}
    }

    set root [ixNet getRoot]
	set dhcpGlobals [ixNet getL /globals/topology dhcpv4client]
	if { [ info exists retry_attempts ] } {
		Deputs "updating retry_attempts"
       	set ipPattern [ixNet getA [ixNet getA $dhcpGlobals -dhcp4NumRetry] -pattern]
        SetMultiValues $dhcpGlobals "-dhcp4NumRetry" $ipPattern $retry_attempts
    }

    if { [info exists override_global_setup] && $override_global_setup } {
        if { [ info exists request_rate ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -interval] -pattern]
           set dhcpObj $dhcpGlobals/startRate
           SetMultiValues $dhcpObj "-interval" $ipPattern $request_rate
           ########################################################
		   set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -maxOutstanding] -pattern]
           SetMultiValues $dhcpObj "-interval" $ipPattern $request_rate
        }
        if { [ info exists outstanding_session ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -maxOutstanding] -pattern]
           set dhcpObj $dhcpGlobals/startRate
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $outstanding_session
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/stopRate -maxOutstanding] -pattern]
           set dhcpObj $dhcpGlobals/stopRate
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $outstanding_session
        }
        if { [ info exists release_rate ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/stopRate -rate] -pattern]
           set dhcpObj $dhcpGlobals/stopRate
           SetMultiValues $dhcpObj "-rate" $ipPattern $release_rate
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/stopRate -maxOutstanding] -pattern]
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $release_rate
        }
    } else {
        if { [ info exists request_rate ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -interval] -pattern]
           set dhcpObj $dhcpGlobals/startRate
           SetMultiValues $dhcpObj "-interval" $ipPattern $request_rate
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -maxOutstanding] -pattern]
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $request_rate
        }
        if { [ info exists outstanding_session ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/startRate -maxOutstanding] -pattern]
           set dhcpObj $dhcpGlobals/startRate
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $outstanding_session
        }
        if { [ info exists release_rate ] } {
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/stopRate -rate] -pattern]
           set dhcpObj $dhcpGlobals/stopRate
           SetMultiValues $dhcpObj "-rate" $ipPattern $release_rate
           set ipPattern [ixNet getA [ixNet getA $dhcpGlobals/stopRate -maxOutstanding] -pattern]
           SetMultiValues $dhcpObj "-maxOutstanding" $ipPattern $outstanding_session
        }
    }
	if { [ info exists request_timeout ] } {
		set ipPattern [ixNet getA [ixNet getA $dhcpGlobals -dhcp4ResponseTimeout] -pattern]
        SetMultiValues $dhcpGlobals "-dhcp4ResponseTimeout" $ipPattern $request_timeout
	}
   	ixNet commit
   	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]
}

body DhcpHost::request {} {
# IxDebugOn
    set tag "body DhcpHost::request [info script]"
Deputs "----- TAG: $tag -----"
Deputs "handle :$handle"
	# after 3000
	set requestTimestamp [ clock seconds ]
    if { [ catch {
    	ixNet exec start $handle
    } err ] } {
Deputs "err:$err"
		after 3000
		set requestTimestamp [ clock seconds ]
		ixNet exec start $handle
    }
# IxDebugOff	
	set completeTimestamp [ clock seconds ]
	set requestDuration [ expr $completeTimestamp - $requestTimestamp ]
#-- make sure the stats will be updated
    return [GetStandardReturnHeader]
}
body DhcpHost::release {} {
    set tag "body DhcpHost::release [info script]"
Deputs "----- TAG: $tag -----"
   	ixNet exec stop $handle
	ixNet commit
    return [GetStandardReturnHeader]
}
body DhcpHost::abort {} {
    set tag "body DhcpHost::abort [info script]"
Deputs "----- TAG: $tag -----"
	ixNet exec abort $hDhcp
	ixNet commit
    return [GetStandardReturnHeader]
}
body DhcpHost::renew {} {
    set tag "body DhcpHost::renew [info script]"
    Deputs "----- TAG: $tag -----"
	if { [ catch {
		# ixNet exec dhcpClientRenew $handle
		ixNet exec renew $handle
	} ] } {
		return [GetErrorReturnHeader "Supported only onixNetwork 6.30 or above."]		
	}
    return [GetErrorReturnHeader "Unsupported functionality."]
}
body DhcpHost::retry {} {
    set tag "body DhcpHost::retry [info script]"
Deputs "----- TAG: $tag -----"
	if { [ catch {
		ixNet exec dhcpClientRetry $handle
	} ] } {
		return [GetErrorReturnHeader "Supported only onixNetwork 6.30 or above."]		
	}
    return [GetErrorReturnHeader "Unsupported functionality."]
}

## Below procs resume and pause are not supported in NGPF
body DhcpHost::resume {} {
    set tag "body DhcpHost::resume [info script]"
Deputs "----- TAG: $tag -----"
	if { [ catch {
		ixNet exec dhcpClientResume $handle
	} ] } {
		return [GetErrorReturnHeader "Supported only onixNetwork 6.30 or above."]		
	}
    return [GetErrorReturnHeader "Unsupported functionality."]
}
body DhcpHost::pause {} {
    set tag "body DhcpHost::pause [info script]"
Deputs "----- TAG: $tag -----"
	if { [ catch {
		ixNet exec dhcpClientPause $handle
	} ] } {
		return [GetErrorReturnHeader "Supported only onixNetwork 6.30 or above."]		
	}
    return [GetErrorReturnHeader "Unsupported functionality."]
}
body DhcpHost::rebind {} {
    set tag "body DhcpHost::rebind [info script]"
Deputs "----- TAG: $tag -----"
	if { [ catch {
		ixNet exec rebind $handle
	} ] } {
		return [GetErrorReturnHeader "Supported only onixNetwork 6.30 or above."]		
	}
    return [GetErrorReturnHeader "Unsupported functionality."]
}
body DhcpHost::wait_request_complete { args } {
    set tag "body DhcpHost::wait_request_complete [info script]"
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
		
		set view {::ixNet::OBJ-/statistics/view:"DHCPv4 Client Per Port"}
		Deputs "view:$view"
		set captionList             [ixNet getA $view/page -columnCaptions ]
		Deputs "caption list:$captionList"
		set port_name				[ lsearch -exact $captionList {Port} ]
		set initStatsIndex          [ lsearch -exact $captionList {Sessions Total} ]
		set succStatsIndex          [ lsearch -exact $captionList {Sessions Up} ]
		set ackRcvIndex          	[ lsearch -exact $captionList {ACKs Rx} ]
		
		set stats [ixNet getA $view/page -rowValues ]
		Deputs "stats:$stats"

		set connectionInfo [ixNet getA $hPort -connectionInfo ]
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

			set initStats    [ lindex $row $initStatsIndex ]
			set succStats    [ lindex $row $succStatsIndex ]
			set ackRcvStats  [ lindex $row $ackRcvIndex ]
			
			break
		}
		Deputs "initStats:$initStats == succStats:$succStats == ackRcvStats:$ackRcvStats "		
		if { $succStats != "" && $succStats >= $initStats && $initStats > 0 && $ackRcvStats >= $succStats } {
			break	
		}
		after 1000
	}
	return [GetStandardReturnHeader]
}

body DhcpHost::wait_release_complete { args } {
    set tag "body DhcpHost::wait_release_complete [info script]"
	Deputs "----- TAG: $tag -----"

	set timeout 10

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-timeout {
				set timeout $value
			}
		}
    }

	set timerStart [ clock second ]

    set root [ixNet getRoot]
    set view [ lindex [ixNet getF $root/statistics view -caption "dhcpPerSessionView" ] 0 ]
    if { $view == "" } {
		if { [ catch {
			set view [ CreateDhcpPerSessionView ]
		} ] } {
			return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
		}
    }
    after 15000
    ixNet execute refresh $view

    set captionList         [ixNet getA $view/page -columnCaptions ]
    set ipIndex             [ lsearch -exact $captionList {Address} ]

	set pageCount [ixNet getA $view/page -totalPages ]

	while { [ expr [ clock second ] - $timerStart ] > $timeout } {
		for { set index 1 } { $index <= $pageCount } { incr index } {

			ixNet setA $view/page -currentPage $index
			ixNet commit

			set stats [ixNet getA $view/page -rowValues ]
			Deputs "stats:$stats"

			foreach row $stats {

				eval {set row} $row

				set statsItem   "ipv4_addr"
				set statsVal    [ lindex $row $ipIndex ]
				Deputs "stats val:$statsVal"
				if { $statsVal != "0.0.0.0" } {
					ixNet remove $view
					ixNet commit
					return [ GetErrorReturnHeader "" ]
				}
			}
		}

		after 1000
		ixNet exec refresh $view
	}

	ixNet remove $view
	ixNet commit
    return  [ GetStandardReturnHeader ]
}

body DhcpHost::get_summary_stats {} {
    set tag "body DhcpHost::get_summary_stats [info script]"
	Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
	Deputs "root $root"
    set view [ lindex [ixNet getF $root/statistics view -caption "dhcpPerRangeView" ] 0 ]
    if { $view == "" } {
		if { [ catch {
			set view [ CreateDhcpPerRangeView ]
		} ] } {
			return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
		}
    }
    after 15000
    ixNet execute refresh $view

    set captionList         [ixNet getA $view/page -columnCaptions ]
    set rangeIndex          [ lsearch -exact $captionList {Device Group} ]
	Deputs "index:$rangeIndex"
    set discoverSentIndex   [ lsearch -exact $captionList {Discovers Tx} ]
	Deputs "index:$discoverSentIndex"
	if { $discoverSentIndex < 0 } {
	    set discoverSentIndex   [ lsearch -exact $captionList {Solicits Tx} ]
	    Deputs "index:$discoverSentIndex"
	}
    set offerRecIndex       [ lsearch -exact $captionList {Offers Rx} ]
	Deputs "index:$offerRecIndex"
	if { $offerRecIndex < 0 } {
	    set offerRecIndex       [ lsearch -exact $captionList {Replies Rx} ]
	    Deputs "index:$offerRecIndex"
	}
    set reqSentIndex        [ lsearch -exact $captionList {Requests Tx} ]
	Deputs "index:$reqSentIndex"
    set ackRecIndex         [ lsearch -exact $captionList {ACKs Rx} ]
    Deputs "index:$ackRecIndex"
	if { $ackRecIndex < 0 } {
	    set ackRecIndex       [ lsearch -exact $captionList {Advertisements Rx} ]
	    Deputs "index:$ackRecIndex"
	}
    set nackRecIndex        [ lsearch -exact $captionList {NACKs Rx} ]
	Deputs "index:$nackRecIndex"
	if { $nackRecIndex < 0 } {
	    set nackRecIndex       [ lsearch -exact $captionList {Advertisements Ignored} ]
	    Deputs "index:$nackRecIndex"
	}
    set releaseSentIndex    [ lsearch -exact $captionList {Releases Tx} ]
	Deputs "index:$releaseSentIndex"
    set declineSentIndex    [ lsearch -exact $captionList {Declines Tx} ]
	Deputs "index:$declineSentIndex"
    set renewSentIndex    [ lsearch -exact $captionList {Renews Tx} ]
	Deputs "index:$renewSentIndex"
    set retriedSentIndex    [ lsearch -exact $captionList {Rebinds Tx} ]
	Deputs "index:$retriedSentIndex"

	Deputs "handle:$handle"
	set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
    set rangeName [ixNet getA $deviceGroupObj -name ]
	Deputs "range name:$rangeName"

    set stats [ixNet getA $view/page -rowValues ]
	Deputs "stats:$stats"
    set rangeFound 0
    foreach row $stats {
        eval {set row} $row
		Deputs "row:$row"
		Deputs "range index:$rangeIndex"
        set rowRangeName [ lindex $row $rangeIndex ]
		Deputs "row range name:$rowRangeName"
        if { [ regexp $rowRangeName $rangeName ] } {
            set rangeFound 1
            break
        }
    }

    set ret "Status : true\nLog : \n"

    if { $rangeFound } {
        set statsItem   "attempt_rate"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "bind_rate"
		if { [ info exists requestDuration ] == 0 || $requestDuration < 1 } {
			set statsVal NA
		} else {
			set statsVal    [ expr [ lindex $row $offerRecIndex ] / $requestDuration ]
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "current_attempt_count"
		if { $discoverSentIndex >= 0 } {
			set statsVal    [ lindex $row $discoverSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "current_bound_count"
		if { $offerRecIndex >= 0 } {
			set statsVal    [ lindex $row $offerRecIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "current_idle_count"
        if {  $releaseSentIndex >= 0  && [lindex $row $releaseSentIndex] >0} {
			set statsVal    [ lindex $row $releaseSentIndex ]
		} else {
            set statsVal    [ expr [ lindex $row $discoverSentIndex ] - [ lindex $row $offerRecIndex ] ]
	    }
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_ack_count"
		if { $ackRecIndex >= 0 } {
			set statsVal    [ lindex $row $ackRecIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_nak_count"
		if { $nackRecIndex >= 0 } {
			set statsVal    [ lindex $row $nackRecIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_offer_count"
		if { $offerRecIndex >= 0 } {
			set statsVal    [ lindex $row $offerRecIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "total_attempt_count"
		if { $discoverSentIndex >= 0 } {
			set statsVal    [ lindex $row $discoverSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "total_bound_count"
		if { $offerRecIndex >= 0 } {
			set statsVal    [ lindex $row $offerRecIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(offerReceived) $statsVal

        set statsItem   "total_failed_count"
        set statsVal    [ expr [ lindex $row $discoverSentIndex ] - [ lindex $row $offerRecIndex ] ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "total_renewed_count"
		if { $renewSentIndex >= 0 } {
			set statsVal    [ lindex $row $renewSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "total_retried_count"
		if { $retriedSentIndex >= 0 } {
			set statsVal    [ lindex $row $retriedSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_discover_count"
		if { $discoverSentIndex >= 0 } {
			set statsVal    [ lindex $row $discoverSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(discoverSent) $statsVal

        set statsItem   "tx_release_count"
		if { $releaseSentIndex >= 0 } {
			set statsVal    [ lindex $row $releaseSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(releaseSent) $statsVal

        set statsItem   "tx_request_count"
		if { $reqSentIndex >= 0 } {
			set statsVal    [ lindex $row $reqSentIndex ]
		} else {
			set statsVal    "NA"
		}
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(requestSent) $statsVal

    }
    Deputs "ret:$ret"
	ixNet remove $view
	ixNet commit

    #add avg_setup_success_rate
    set dhcpv4view {::ixNet::OBJ-/statistics/view:"DHCPv4 Client Per Port"}

    set captionList         	[ixNet getA $dhcpv4view/page -columnCaptions ]
    set nameIndex          		[ lsearch -exact $captionList {Port} ]
	Deputs "index:$nameIndex"
    set avgSuccRateIndex        [ lsearch -exact $captionList {Average Setup Rate} ]
	Deputs "index:$avgSuccRateIndex"

	
    set stats [ixNet getA $dhcpv4view/page -rowValues ]
	Deputs "stats:$stats"

	set connectionInfo [ixNet getA [$portObj cget -handle] -connectionInfo ]
	Deputs "connectionInfo :$connectionInfo"
	regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
	Deputs "chas:$chassis card:$card port$port"
	if { [ string length $card ] == 1 } { set card "0$card" }
	if { [ string length $port ] == 1 } { set port "0$port" }
	set statsName "${chassis}/Card${card}/Port${port}"
	Deputs "statsName:$statsName"

    foreach row $stats {      
        eval {set row} $row
		Deputs "row:$row"

        set statsVal    [ lindex $row $nameIndex ]
		if { $statsVal != $statsName } {
			Deputs "stats skipped: $statsVal != $statsName"
			continue
		}
        
        set statsItem   "avg_setup_success_rate"
        set statsVal    [ lindex $row $avgSuccRateIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

    }
    Deputs "ret:$ret"
    return $ret
    
}
body DhcpHost::get_detailed_stats {} {
    set tag "body DhcpHost::get_detailed_stats [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
    set view [ lindex [ ixNet getF $root/statistics view -caption "dhcpPerSessionView" ] 0 ]

    if { $view == "" } {
		if { [ catch {
			set view [ CreateDhcpPerSessionView ]
		} ] } {
			return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
		}
    }

    after 15000
    ixNet execute refresh $view
    set captionList         [ixNet getA $view/page -columnCaptions ]
    set rangeIndex          [ lsearch -exact $captionList {Port} ]
    set discoverSentIndex   [ lsearch -exact $captionList {Discovers Tx} ]
    set offerRecIndex       [ lsearch -exact $captionList {Offers Rx} ]
    set reqSentIndex        [ lsearch -exact $captionList {Requests Tx} ]
    set ackRecIndex         [ lsearch -exact $captionList {ACKs Rx} ]
    set nackRecIndex        [ lsearch -exact $captionList {NACKs Rx} ]
    set releaseSentIndex    [ lsearch -exact $captionList {Releases Tx} ]
    set declineSentIndex    [ lsearch -exact $captionList {Declines Tx} ]
    set ipIndex             [ lsearch -exact $captionList {Address} ]
    set gwIndex             [ lsearch -exact $captionList {Gateway} ]
    set leaseIndex          [ lsearch -exact $captionList {Lease Time (sec)} ]

    set ret "Status : true\nLog : \n"

	set pageCount [ixNet getA $view/page -totalPages ]

	for { set index 1 } { $index <= $pageCount } { incr index } {

		ixNet setA $view/page -currentPage $index
		ixNet commit

		set stats [ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"

		foreach row $stats {

			set ret "$ret\{\n"

			eval {set row} $row
Deputs "row:$row"

			set statsItem   "disc_resp_time"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "error_status"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "inner_vlan_id"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "ipv4_addr"
			set statsVal    [ lindex $row $ipIndex ]
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "lease_left"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "lease_rx"
			set statsVal    [ lindex $row $leaseIndex ]
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "mac_addr"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "request_resp_time"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "host_state"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "vlan_id"
			set statsVal    "NA"
Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set ret "$ret\}\n"

		}

Deputs "ret:$ret"
	}

	ixNet remove $view
	ixNet commit
    return $ret
}

body DhcpHost::set_dhcp_msg_option { args } {
    global errorInfo
    global errNumber
    set tag "body DhcpHost::set_dhcp_msg_option [info script]"
Deputs "----- TAG: $tag -----"

	set EMsgType [ list discover request solicit decline release offer nak ack forcereview]
    set root [ixNet getRoot]

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -msg_type {
				set value [ string tolower $value ]
                if { [ lsearch -exact $EMsgType $value ] >= 0 } {

                    set msg_type $value
					Deputs "msg_type value received as $msg_type"
					if {$msg_type == "request" } {
						set msg_type "kRequest"
					} elseif {$msg_type == "release"} {
						set msg_type "kRelease"
					} elseif {$msg_type == "decline"} {
						set msg_type "KDecline"
					} elseif {$msg_type == "discover"} {
						set msg_type "KDiscover"
					} else {
						Deputs "no case matched with switch for $msg_type"
					}
                } else {
                	return [GetErrorReturnHeader "Unsupported functionality."]
                }
            }
            -option_type {
                if { [ string is integer $value ] && ( $value >= 1 ) && ( $value <= 65535 ) } {
                    set option_type $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -enable_hex_value {
                if { $value == "true" } {
            	    set optionType hexadecimal
                }
            }
            -payload {
            	set payload $value
            }
        }
    }

	if {[$this -cget dhcpStackVersion] == "ipv4"} {
		set configProtocol "dhcpv4client"
	} elseif {[$this -cget dhcpStackVersion] == "ipv6"} {
		set configProtocol "dhcpv6client"
	}

	set flagTypeDefined 0
	foreach tlv	[ixNet getL $optionSet dhcpOptionTlv ] {
		if { [ixNet getA $tlv -code ] == $option_type } {
			set flagTypeDefined 1
		}
	}
	Deputs "type defined value is $flagTypeDefined and option_type received is $option_type"

	if { ( $option_type == "53" ) || ( $option_type == "61" ) || ( $option_type == "57" ) } {
		Deputs "Not customized option:$option_type, IXIA has already added this option on defaultly."
		return [ GetErrorReturnHeader "Not customized option:$option_type, IXIA has already added this option on defaultly."]
	}

	if { $option_type == "51" } {
		set tlvHandle [getTlvHandleFromDefaultTlvCode $configProtocol 51]
		Deputs "option type 51"
		set tlvEntry [findIfTlvExist $handle 51]
		if {$tlvEntry == ""} {
			set tlvEntry [addTlvHandle $handle $tlvHandle]
		} else {
			ixNet setA $tlvEntry -isEnabled True
			set flagTypeDefined 1
		}
	}

	if { $option_type == "55" } {
Deputs "option type 55"
		set tlvEntry [getTlvHandleFromDefaultTlvCode $configProtocol 55]
		ixNet setA $tlvEntry -isEnabled True
		ixNet commit
		set flagTypeDefined 1
	}

	if { $option_type == "82" } {
		Deputs "line 1389"
		set tlvHandle [getTlvHandleFromDefaultTlvCode $configProtocol 82]
		set tlvEntry [findIfTlvExist $handle 82]
		if {$tlvEntry == ""} {
			set tlvEntry [addTlvHandle $handle $tlvHandle]
		} else {
			ixNet setA $tlvEntry -isEnabled True
			ixNet commit
		}
		set flagTypeDefined 1
	}

	## get the list of TLVs added in handle
	Deputs "value of tlvEntry $tlvEntry"
	if {[info exists msg_type]} {
		ixNet setA $tlvEntry -includeInMessages $msg_type
		ixNet commit
	}
	return [ GetStandardReturnHeader ]
}
body DhcpHost::set_igmp_over_dhcp { args } {

    global errorInfo
    global errNumber
	
    set tag "body DhcpHost::set_igmp_over_dhcp [info script]"
    Deputs "----- TAG: $tag -----"

	if { [ info exists hIgmp ] } {
		if { [ixNet exists $hIgmp ] } {
			return
		}
	}

	if { [ catch {
		set hPort   [ $portObj cget -handle ]
	} ] } {
		error "$errNumber(1) Port Object in DhcpHost ctor"
	}
	
	#-- add igmp host
	set result [regexp {dhcpv(\d)} $handle handleName dhcpVersion]
	if {$dhcpVersion == 4} {
		set host [ixNet add $handle igmpHost]
	} else {
		set host [ixNet add $handle mldHost]
	}

	ixNet commit
	set host [ixNet remapIds $host]	

	set hIgmp $host
}
body DhcpHost::unset_igmp_over_dhcp {} {

	if { [ info exists hIgmp ] } {
		if { [ixNet exists $hIgmp ] } {
			ixNet remove $hIgmp
			ixNet commit
		}
	}
}
body DhcpHost::get_port_summary_stats { view } {
    set tag "body DhcpHost::get_port_summary_stats [info script]"
	Deputs "----- TAG: $tag -----"
    set captionList         	[ixNet getA $view/page -columnCaptions ]
    set nameIndex          		[ lsearch -exact $captionList {Port} ]
	Deputs "index:$nameIndex"
    set ackRcvIndex          	[ lsearch -exact $captionList {ACKs Rx} ]
	Deputs "index:$ackRcvIndex"
    set addDiscIndex          	[ lsearch -exact $captionList {Addresses Discovered} ]
	Deputs "index:$addDiscIndex"
    set declineSntIndex          	[ lsearch -exact $captionList {Declines Tx} ]
	Deputs "index:$declineSntIndex"
    set discSntIndex          	[ lsearch -exact $captionList {Discovers Tx} ]
	Deputs "index:$discSntIndex"
    set nakRcvIndex          	[ lsearch -exact $captionList {NACKs Rx} ]
	Deputs "index:$nakRcvIndex"
    set offerRcvIndex          	[ lsearch -exact $captionList {Offers Rx} ]
	Deputs "index:$offerRcvIndex"
    set releaseSntIndex          	[ lsearch -exact $captionList {Releases Tx} ]
	Deputs "index:$releaseSntIndex"
    set reqSntIndex          	[ lsearch -exact $captionList {Requests Txt} ]
	Deputs "index:$reqSntIndex"
    set sessFailIndex          	[ lsearch -exact $captionList {Sessions Failed} ]
	Deputs "index:$sessFailIndex"
    set sessInitIndex          	[ lsearch -exact $captionList {Sessions Initiated} ]
	Deputs "index:$sessInitIndex"
    set sessSuccIndex          	[ lsearch -exact $captionList {Sessions Succeeded} ]
	Deputs "index:$sessSuccIndex"
    set succRateIndex          	[ lsearch -exact $captionList {Max Setup Rate} ]
	Deputs "index:$succRateIndex"
    set avgSuccRateIndex        [ lsearch -exact $captionList {Average Setup Rate} ]
	Deputs "index:$avgSuccRateIndex"

    set ret [ GetStandardReturnHeader ]
	
    set stats [ixNet getA $view/page -rowValues ]
	Deputs "stats:$stats"

	set connectionInfo [ixNet getA [$portObj cget -handle] -connectionInfo ]
	Deputs "connectionInfo :$connectionInfo"
	regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
	Deputs "chas:$chassis card:$card port$port"
	if { [ string length $card ] == 1 } { set card "0$card" }
	if { [ string length $port ] == 1 } { set port "0$port" }
	set statsName "${chassis}/Card${card}/Port${port}"
	Deputs "statsName:$statsName"

    foreach row $stats {      
        eval {set row} $row
		Deputs "row:$row"

        set statsVal    [ lindex $row $nameIndex ]
		if { $statsVal != $statsName } {
			Deputs "stats skipped: $statsVal != $statsName"
			continue
		}

        set statsItem   "tx_discover_count"
        set statsVal    [ lindex $row $discSntIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
        set statsItem   "rx_discover_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
              
        set statsItem   "tx_offer_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  
        set statsItem   "rx_offer_count"
        set statsVal    [ lindex $row $offerRcvIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "tx_request_count"
        set statsVal    [ lindex $row $reqSntIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
        set statsItem   "rx_request_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
        set statsItem   "tx_decline_count"
        set statsVal    [ lindex $row $declineSntIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
        set statsItem   "rx_decline_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "tx_ack_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		
        set statsItem   "rx_ack_count"
        set statsVal    [ lindex $row $ackRcvIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "tx_nak_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "rx_nak_count"
        set statsVal    [ lindex $row $nakRcvIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "tx_release_count"
        set statsVal    [ lindex $row $releaseSntIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "rx_release_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "tx_all_packet_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "rx_all_packet_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "port_session_count"
        set statsVal    [ lindex $row $sessInitIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "port_session_up_count"
        set statsVal    [ lindex $row $sessSuccIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "port_min_setup_time"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "port_max_setup_time"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "port_avg_setup_time"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "port_setup_rate"
        set statsVal    [ lindex $row $succRateIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
        
        set statsItem   "port_avg_setup_rate"
        set statsVal    [ lindex $row $avgSuccRateIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

		Deputs "ret:$ret"
    }
    return $ret		
}

class Dhcpv4Host {
	inherit DhcpHost
	public variable ipType "ipv4"
	constructor { port { onStack null } { hdhcp null }} { chain $port $onStack $hdhcp } {
        global LoadConfigMode
        set tag "body Dhcpv4Host::ctr [info script]"
        Deputs "----- TAG: $tag -----"
        
        if { $hdhcp == "null" && $LoadConfigMode == 1  } {
            set hdhcp [GetObjNameFromString $this "null"]
        }
        
        if { $hdhcp != "null" } {
            set eth_hnd [GetValidNgpfHandleObj "dhcpv4" $hdhcp $hPort]
            if { [llength $eth_hnd] == 2 } {
                set handle [lindex $eth_hnd 1]
                set hDhcp [lindex $eth_hnd 0]
                set handleName [ixNet getA $handle/dhcpRange -name ]
            } 
        }
        
        if { $handle == "" } {
            set handleName $this           
            reborn
        }
    }
    method igmp_over_dhcp {} {}
	method set_igmp_over_dhcp { args } {}
	method get_port_summary_stats {} {}
	method reborn { { onStack null } } {
		set tag "body Dhcpv4Host::reborn [info script]"
		Deputs "----- TAG: $tag -----"

		chain "ipv4" $onStack
		set statsView {::ixNet::OBJ-/statistics/view:"DHCPv4 Client Per Port"}
	}
}
body Dhcpv4Host::igmp_over_dhcp {} {
    set tag "body Dhcpv4Host::igmp_over_dhcp [info script]"
    Deputs "----- TAG: $tag -----"
    set igmp_name igmp_[clock seconds]
    IgmpOverDhcpHost $igmp_name $this
    
    return Dhcpv4Host::$igmp_name
}
body Dhcpv4Host::set_igmp_over_dhcp { args } {

    set tag "body Dhcpv4Host::set_igmp_over_dhcp [info script]"
Deputs "----- TAG: $tag -----"	

	eval { chain } $args

	ixNet setA $hIgmp -version igmpv2
	
	set EAction [ list join leave ]
	set action join

#param collection
Deputs "Args:$args "
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -group {
                    foreach grp $value {
                    	if { [ $grp isa MulticastGroup ] == 0 } {
                    		error "$errNumber(1) key:$key value:$value"
                    		}
            		}
            		set group $value
        	}
        	-action {
        		set value [ string tolower $value ]
                        if { [ lsearch -exact $EAction $value ] >= 0 } {
                            
                            set action $value
                        } else {
                        	return [GetErrorReturnHeader "Unsupported functionality."]
                        }
                }
            }
        }
	
	if {[info exists group]} {
	foreach grp $group {

		set group_ip 	[ $grp cget -group_ip ]
		set group_num [ $grp cget -group_num ]
		set group_step [ $grp cget -group_step ]
		set group_modbit [ $grp cget -group_modbit ]
		
		set hGroup [ixNet getL $hIgmp igmpMcastIPv4GroupList]
        set ipPattern [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
        SetMultiValues $hGroup "-startMcastAddr" $ipPattern $group_ip
        set ipPattern [ixNet getA [ixNet getA $hGroup -mcastAddrCnt] -pattern]
        SetMultiValues $hGroup "-mcastAddrCnt" $ipPattern $group_num
	}
	}
	ixNet commit
	return [ GetStandardReturnHeader ]

}
body Dhcpv4Host::get_port_summary_stats {} {
    set tag "body Dhcpv4Host::get_port_summary_stats [info script]"
	Deputs "----- TAG: $tag -----"
	set view {::ixNet::OBJ-/statistics/view:"DHCPv4 Client Per Port"}
	#set view ::ixNet::OBJ-/statistics/view:\"DHCPv4\"
	Deputs "view:$view"
	return [ chain $view ]
}

class Dhcpv6Host {

	inherit DhcpHost
	public variable ipType "ipv6"

	constructor { port { onStack null } { hdhcp null }} { chain $port $onStack $hdhcp } {
        global LoadConfigMode
        set tag "body Dhcpv6Host::ctr [info script]"
        Deputs "----- TAG: $tag -----"
        if { $hdhcp == "null" && $LoadConfigMode == 1  } {
            set hdhcp [GetObjNameFromString $this "null"]
        }
        
        if { $hdhcp != "null" } {
            set eth_hnd [GetValidNgpfHandleObj "dhcpv6" $hdhcp $hPort]
            if { [llength $eth_hnd] == 2 } {
                set handle [lindex $eth_hnd 1]
                set hDhcp [lindex $eth_hnd 0]
                set handleName [ixNet getA $handle/dhcpRange -name ]
            }
        }
        if { $handle == "" } {
            set handleName $this           
            reborn
        }
		$this configure -hDhcp $handle
    }
	
	method config { args } {}
	method set_igmp_over_dhcp { args } {}
	method get_port_summary_stats {} {}
	method get_summary_stats {} {}
	method get_detailed_stats {} {}
	method reborn { { onStack null } } {
		set tag "body Dhcpv6Host::reborn [info script]"
        Deputs "----- TAG: $tag -----"
		chain "ipv6" $onStack
		set statsView {::ixNet::OBJ-/statistics/view:"DHCPv6 Client Per Port"}
	}
}
body Dhcpv6Host::set_igmp_over_dhcp { args } {

    set tag "body Dhcpv6Host::set_igmp_over_dhcp [info script]"
Deputs "----- TAG: $tag -----"	

	eval { chain } $args

	ixNet setA $hIgmp -version igmpv3
	
	set EAction [ list join leave ]
	set action join

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -group {
				foreach grp $value {
					if { [ $grp isa MulticastGroup ] == 0 } {
						error "$errNumber(1) key:$key value:$value"
					}
				}
				set group $value
			}
			-action {
				set value [ string tolower $value ]
                if { [ lsearch -exact $EAction $value ] >= 0 } {
                    
                    set action $value
                } else {
					return [GetErrorReturnHeader "Unsupported functionality."]
                }
			}
        }
    }

	if {[info exists group]} {

	foreach grp $group {

		set group_ip 	[ $grp cget -group_ip ]
		set group_num [ $grp cget -group_num ]
		set group_step [ $grp cget -group_step ]
		set group_modbit [ $grp cget -group_modbit ]
		set source_ip 	[ $grp cget -source_ip ]
		set source_num [ $grp cget -source_num ]
		set source_step [ $grp cget -source_step ]
		set source_modbit	[ $grp cget -source_modbit ]
		
		set hGroup [ixNet getL $hIgmp igmpMcastIPv4GroupList]

		set ipPattern [ixNet getA [ixNet getA $hGroup -startMcastAddr] -pattern]
        SetMultiValues $hGroup "-startMcastAddr" $ipPattern $group_ip
        set ipPattern [ixNet getA [ixNet getA $hGroup -mcastAddrCnt] -pattern]
        SetMultiValues $hGroup "-mcastAddrCnt" $ipPattern $group_num
	}
	}
	ixNet commit
	return [ GetStandardReturnHeader ]

}
body Dhcpv6Host::config { args } {
    set tag "body Dhcpv6Host::config [info script]"
Deputs "----- TAG: $tag -----"
	
    eval { chain } $args 
    global errorInfo
    global errNumber

    set EDuidType [ list llt ll en ]
    set ESession  [ list iana iata iapd iana_iapd ]
    
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -duid_enterprise {
                if { [ string is integer $value ] } {
                    set duid_enterprise $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -duid_start {
                if { [ string is integer $value ] } {
                    set duid_start $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -duid_step {
                if { [ string is integer $value ] } {
                    set duid_step $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -duid_type {
                set value [ string tolower $value ]
                set duid_type $value
            }
            -t1_timer {
                if { [ string is integer $value ] } {
                    set t1_timer $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -t2_timer {
                if { [ string is integer $value ] } {
                    set t2_timer $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
		   
		   -iaid {
			   if { [ string is integer $value ] } {
				   set iaid $value
			   } else {
				   error "$errNumber(1) key:$key value:$value"
			   }
		   }
		   
			-session_type -
			-client_mode -
			-ia_type {
                set value [ string tolower $value ]
                if { [ lsearch -exact $ESession $value ] >= 0 } {
                    
                    set session_type $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }                
			}
		}
    }
    set range $handle
    
    if { [ info exists duid_type ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6DuidType] -pattern]
       SetMultiValues $handle "-dhcp6DuidType" $ipPattern $duid_type
    }

    if { [ info exists duid_enterprise ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6DuidEnterpriseId] -pattern]
       SetMultiValues $handle "-dhcp6DuidEnterpriseId" $ipPattern $duid_enterprise
    }

    if { [ info exists duid_start ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6DuidVendorId] -pattern]
       SetMultiValues $handle "-dhcp6DuidVendorId" $ipPattern $duid_start
    }
    
    if { [ info exists duid_step ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6DuidVendorId] -pattern]
       SetMultiValues $handle "-dhcp6DuidVendorId" $ipPattern " " $duid_step
    }
    
    if { [ info exists t1_timer ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6IaT1] -pattern]
       SetMultiValues $handle "-dhcp6IaT1" $ipPattern $t1_timer
    }
    
    if { [ info exists t2_timer ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6IaT2] -pattern]
       SetMultiValues $handle "-dhcp6IaT2" $ipPattern $t2_timer
    }

	if { [ info exists iaid ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -dhcp6IaId] -pattern]
        SetMultiValues $handle "-dhcp6IaId" $ipPattern $iaid
	}
	
	if { [ info exists session_type ] } {
       set ipPattern [ixNet getA [ixNet getA $handle -dhcp6IaType] -pattern]
       SetMultiValues $handle "-dhcp6IaType" $ipPattern $session_type
	}
    ixNet  commit
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]    
}
body Dhcpv6Host::get_port_summary_stats {} {
    set tag "body Dhcpv6Host::get_port_summary_stats [info script]"
	Deputs "----- TAG: $tag -----"
    set view {::ixNet::OBJ-/statistics/view:"DHCPv6 Client Per Port"}
	#set view ::ixNet::OBJ-/statistics/view:\"DHCPv6\"

	return [ chain $view ]
}
body Dhcpv6Host::get_summary_stats {} {
    set tag "body DhcpHost::get_summary_stats [info script]"
	Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
	Deputs "root $root"
    set view [ lindex [ixNet getF $root/statistics view -caption "dhcpPerRangeView" ] 0 ]
    if { $view == "" } {
		if { [ catch {
			set view [ CreateDhcpPerRangeView ]
		} ] } {
			return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
		}
    }
    after 15000
    ixNet execute refresh $view

    set captionList         [ixNet getA $view/page -columnCaptions ]
    set rangeIndex          [ lsearch -exact $captionList {Device Group} ]
	Deputs "index:$rangeIndex"
	set solicitsSentIndex   [ lsearch -exact $captionList {Solicits Tx} ]
	Deputs "index:$solicitsSentIndex"
	set repliesRecIndex       [ lsearch -exact $captionList {Replies Rx} ]
	Deputs "index:$repliesRecIndex"
    set reqSentIndex        [ lsearch -exact $captionList {Requests Tx} ]
	Deputs "index:$reqSentIndex"
	set advRecIndex       [ lsearch -exact $captionList {Advertisements Rx} ]
	Deputs "index:$advRecIndex"
	set advIgnoreIndex       [ lsearch -exact $captionList {Advertisements Ignored} ]
	Deputs "index:$advIgnoreIndex"
    set releaseSentIndex    [ lsearch -exact $captionList {Releases Tx} ]
	Deputs "index:$releaseSentIndex"
    set renewSentIndex    [ lsearch -exact $captionList {Renews Tx} ]
	Deputs "index:$renewSentIndex"
    set retriedSentIndex    [ lsearch -exact $captionList {Rebinds Tx} ]
	Deputs "index:$retriedSentIndex"

	Deputs "handle:$handle"
	set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
    set rangeName [ixNet getA $deviceGroupObj -name ]
	Deputs "range name:$rangeName"

    set stats [ixNet getA $view/page -rowValues ]
	Deputs "stats:$stats"
    set rangeFound 0
    foreach row $stats {
        eval {set row} $row
		Deputs "row:$row"
		Deputs "range index:$rangeIndex"
        set rowRangeName [ lindex $row $rangeIndex ]
		Deputs "row range name:$rowRangeName"
        if { [ regexp $rowRangeName $rangeName ] } {
            set rangeFound 1
            break
        }
    }

    set ret "Status : true\nLog : \n"

    if { $rangeFound } {
        set statsItem   "tx_solicit_count "
        set statsVal    [ lindex $row $solicitsSentIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_request_count"
		set statsVal    [ lindex $row $reqSentIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(requestSent) $statsVal

        set statsItem   "tx_confirm_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_info_request_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_rebind_count "
        set statsVal    [ lindex $row $retriedSentIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "tx_release_count"
		set statsVal    [ lindex $row $releaseSentIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(releaseSent) $statsVal

        set statsItem   "tx_renew_count"
		set statsVal    [ lindex $row $renewSentIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(releaseSent) $statsVal

        set statsItem   "rx_advertise_count "
		set statsVal    [ lindex $row $advRecIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(releaseSent) $statsVal

        set statsItem   "rx_reconfigure_count"
        set statsVal    "NA"
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

        set statsItem   "rx_reply_count"
		set statsVal    [ lindex $row $repliesRecIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
		#--temp variable to save current stats
		set rangeStats(releaseSent) $statsVal
    }

    #add avg_setup_success_rate
    set dhcpv6view {::ixNet::OBJ-/statistics/view:"DHCPv6 Client Per Port"}

    set captionList         	[ixNet getA $dhcpv6view/page -columnCaptions ]
    set nameIndex          		[ lsearch -exact $captionList {Port} ]
	Deputs "index:$nameIndex"
    set avgSuccRateIndex        [ lsearch -exact $captionList {Average Setup Rate} ]
	Deputs "index:$avgSuccRateIndex"

	
    set stats [ixNet getA $dhcpv6view/page -rowValues ]
	Deputs "stats:$stats"

	set connectionInfo [ixNet getA [$portObj cget -handle] -connectionInfo ]
	Deputs "connectionInfo :$connectionInfo"
	regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
	Deputs "chas:$chassis card:$card port$port"
	if { [ string length $card ] == 1 } { set card "0$card" }
	if { [ string length $port ] == 1 } { set port "0$port" }
	set statsName "${chassis}/Card${card}/Port${port}"
	Deputs "statsName:$statsName"

    foreach row $stats {      
        eval {set row} $row
		Deputs "row:$row"

        set statsVal    [ lindex $row $nameIndex ]
		if { $statsVal != $statsName } {
			Deputs "stats skipped: $statsVal != $statsName"
			continue
		}
        
        set statsItem   "avg_setup_success_rate"
        set statsVal    [ lindex $row $avgSuccRateIndex ]
		Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
    }
	Deputs "ret:$ret"

    return $ret
}
body Dhcpv6Host::get_detailed_stats {} {
    set tag "body Dhcpv6Host::get_detailed_stats [info script]"
	Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
    set view [ lindex [ixNet getF $root/statistics view -caption "dhcpPerSessionView" ] 0 ]
	Deputs "view:$view"
    if { $view == "" } {
		if { [ catch {
			#set view [ CreateDhcpPerSessionView ]
			set customView [ixNet add $root/statistics view]
            ixNet setMultiAttribute $customView -pageTimeout 25 \
                                                        -type layer23NextGenProtocol \
                                                        -caption "dhcpPerSessionView" \
                                                        -visible true -autoUpdate true \
                                                        -viewCategory NextGenProtocol
            ixNet commit
            set view [lindex [ixNet remapIds $customView] 0]

            set advCv [ixNet add $view "advancedCVFilters"]
            set type "Per Session"
            set protocol "DHCPv6 Client"
            ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                                 -protocol \{$protocol\} \
                                                                 -availableFilterOptions \{$type\} \
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
                 ixNet setA $stat -aggregationType first
                 ixNet commit
            }
            ixNet setA $view -enabled true
            ixNet commit
            ixNet execute refresh $view

		} ] } {
			return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
		}
    }

    after 15000
    ixNet execute refresh $view

    set captionList         [ixNet getA $view/page -columnCaptions ]
    set rangeIndex          [ lsearch -exact $captionList {Port} ]
    set discoverSentIndex   [ lsearch -exact $captionList {Discovers Tx} ]
    set offerRecIndex       [ lsearch -exact $captionList {Offers Rx} ]
    set reqSentIndex        [ lsearch -exact $captionList {Requests Tx} ]
    set ackRecIndex         [ lsearch -exact $captionList {ACKs Rx} ]
    set nackRecIndex        [ lsearch -exact $captionList {NACKs Rx} ]
    set releaseSentIndex    [ lsearch -exact $captionList {Releases Tx} ]
    set declineSentIndex    [ lsearch -exact $captionList {Declines Tx} ]
    set ipIndex             [ lsearch -exact $captionList {Address} ]
    set gwIndex             [ lsearch -exact $captionList {Gateway} ]
    set leaseIndex          [ lsearch -exact $captionList {Lease Time (sec)} ]

    set ret "Status : true\nLog : \n"
    
	set pageCount [ixNet getA $view/page -totalPages ]
	
	for { set index 1 } { $index <= $pageCount } { incr index } {

		ixNet setA $view/page -currentPage $index
		ixNet commit 
		
		set stats [ixNet getA $view/page -rowValues ]
		Deputs "stats:$stats"
		
		foreach row $stats {

			set ret "$ret\{\n"
			
			eval {set row} $row
			Deputs "row:$row"

			set statsItem   "disc_resp_time"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

			set statsItem   "status_code"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			
			set statsItem   "host_state"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
						
			set statsItem   "ipv6_addr"
			set statsVal    [ lindex $row $ipIndex ]
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			
			set statsItem   "lease_left"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			
			set statsItem   "lease_rx"
			set statsVal    [ lindex $row $leaseIndex ]
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			
			set statsItem   "mac_addr"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]   
			
			set statsItem   "request_resp_time"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]   
			
			set statsItem   "prefix_len"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]   
			
			set statsItem   "vlan_id"
			set statsVal    "NA"
			Deputs "stats val:$statsVal"
			set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]   
			
			set ret "$ret\}\n"
		}
			
		Deputs "ret:$ret"
	}

	ixNet remove $view
	ixNet commit
    return $ret
}

class DhcpServer {
    inherit ProtocolNgpfStackObject
    
    public variable type
    # public variable handle ""
    
    constructor { port } { chain $port} {}
	method reborn { ipType {args null} } {}
    method config { args } {}
    method start {} {}
    method stop {} {}
    method set_dhcp_msg_option { args } {
    	return [ GetErrorReturnHeader "Unsupported functionality." ]
    }
    method get_lease_address {} {}

}
body DhcpServer::reborn {ipType {args null}} {
    global errNumber
    
    set tag "body DhcpServer::reborn [info script]"
Deputs "----- TAG: $tag -----"

	if { [ info exists hPort ] == 0 } {
		if { [ catch {
			set hPort   [ $portObj cget -handle ]
		} ] } {
			error "$errNumber(1) Port Object in DhcpHost ctor"
		}
	}
	
	if {$handle != ""} {
		set stack [GetDependentNgpfProtocolHandle $handle "ethernet"]
	} else {
		set topoObjList [ixNet getL [ixNet getRoot] topology]
        Deputs "topoObjList: $topoObjList"
        set vportList [ixNet getL [ixNet getRoot] vport]
        if {[llength $topoObjList] != [llength $vportList]} {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                foreach vport $vportList {
                    if {$vportObj != $vport && $vport == $hPort} {
                        set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                        ixNet commit
                        set deviceGroupObj [ixNet add $topoObj deviceGroup]
                        ixNet commit
                        ixNet setA $deviceGroupObj -multiplier 1
                        ixNet commit
                        set ethernetObj [ixNet add $deviceGroupObj ethernet]
                        ixNet commit
                        set ethernetObj [ixNet remapIds $ethernetObj]
                        set stack $ethernetObj
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
            set ethernetObj [ixNet remapIds $ethernetObj]
            set stack $ethernetObj
        } else {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
                if {$vportObj == $hPort} {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set stack [ixNet getL $deviceGroupObj ethernet]
                    }
                }
            }
        }
	}
	if { $stack != " " } {
		if {$ipType == "ipv4"} {
		    set ipv4Obj [ixNet getL $stack ipv4]
		    if {$ipv4Obj != ""} {
		        set handle [ixNet getL $ipv4Obj dhcpv4server]
		        if {$handle != ""} {
		            set handle $handle
		        } else {
		           set handle [ixNet add $ipv4Obj dhcpv4server]
                    ixNet commit
                    set handle [ixNet remapIds $handle]
		        }
		    } else {
                set ipv4Obj [ixNet add $stack ipv4]
                ixNet commit
                set ipv4Obj [ixNet remapIds $ipv4Obj]

                set handle [ixNet add $ipv4Obj dhcpv4server]
                ixNet commit
                set handle [ixNet remapIds $handle]
            }

		} else {
		    set ipv6Obj [ixNet getL $stack ipv6]
		    if {$ipv6Obj != ""} {
		        set handle [ixNet getL $ipv6Obj dhcpv6server]
		        if {$handle != ""} {
		            set handle $handle
		        } else {
		           set handle [ixNet add $ipv6Obj dhcpv6server]
                    ixNet commit
                    set handle [ixNet remapIds $handle]
		        }
		    } else {
                set ipv6Obj [ixNet add $stack ipv6]
                ixNet commit
                set ipv6Obj [ixNet remapIds $ipv6Obj]

                set handle [ixNet add $ipv6Obj dhcpv6server]
                ixNet commit
                set handle [ixNet remapIds $handle]
            }
		}
	} else {
		chain
		set sg_ethernet $stack
		if {$ipType == "ipv4"} {
		    set ipv4Obj [ixNet getL $sg_ethernet ipv4]
		    if {$ipv4Obj != ""} {
		        set handle [ixNet getL $ipv4Obj dhcpv4server]
		        if {$handle != ""} {
		            set handle $handle
		        } else {
		           set handle [ixNet add $ipv4Obj dhcpv4server]
                    ixNet commit
                    set handle [ixNet remapIds $handle]
		        }
		    } else {
                set ipv4Obj [ixNet add $sg_ethernet ipv4]
                ixNet commit
                set ipv4Obj [ixNet remapIds $ipv4Obj]

                set handle [ixNet add $ipv4Obj dhcpv4server]
                ixNet commit
                set handle [ixNet remapIds $handle]
            }

		} else {
		    set ipv6Obj [ixNet getL $sg_ethernet ipv6]
		    if {$ipv6Obj != ""} {
		        set handle [ixNet getL $ipv6Obj dhcpv6server]
		        if {$handle != ""} {
		            set handle $handle
		        } else {
		           set handle [ixNet add $ipv6Obj dhcpv6server]
                    ixNet commit
                    set handle [ixNet remapIds $handle]
		        }
		    } else {
                set ipv6Obj [ixNet add $sg_ethernet ipv6]
                ixNet commit
                set ipv6Obj [ixNet remapIds $ipv6Obj]

                set handle [ixNet add $ipv6Obj dhcpv6server]
                ixNet commit
                set handle [ixNet remapIds $handle]
            }
            Deputs "endpoint:$sg_dhcpEndpoint"
		}
	}
	
    set trafficObj $handle

}
body DhcpServer::config { args } {
    set tag "body DhcpServer::config [info script]"
Deputs "----- TAG: $tag -----"
    
    global errorInfo
    global errNumber
Deputs "handle:$handle"

	eval chain $args

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -count {
            	set count $value
            }
            -pool_ip_start {
                set pool_ip_start $value
                if { [ IsIPv4Address $value ] } {
                    set ipType "ipv4"
                }
                if { [ IsIPv6Address $value ] } {
                    set ipType "ipv6"
                }
            }
            -pool_ip_pfx {
                set pool_ip_pfx $value
            }
            -pool_ip_count {
                if { [ string is integer $value ] } {
                    set pool_ip_count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -lease_time -
		  -preferred_life_time {
                if { [ string is integer $value ] } {
                    set lease_time $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -max_lease_time -
			-max_allowed_lease_time -
		     -valid_life_time {
                if { [ string is integer $value ] } {
                    set max_lease_time $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
			-ipv4_addr -
			-ipv6_addr {
                set ipv4_addr $value
                if { [ IsIPv4Address $value ] } {
                    set ipType "ipv4"
                }
                if { [ IsIPv6Address $value ] } {
                    set ipType "ipv6"
                }

			}
			-ipv4_prefix_len -
			-ipv6_prefix_len {
                set ipv4_prefix_len $value
			}
			-ipv4_gw -
			-ipv6_gw {
                set ipv4_gw $value
                if { [ IsIPv4Address $value ] } {
                    set ipType "ipv4"
                }
                if { [ IsIPv6Address $value ] } {
                    set ipType "ipv6"
                }
			}
			-gw_step {
                set gw_step $value
                if { [ IsIPv4Address $value ] } {
                    set ipType "ipv4"
                }
                if { [ IsIPv6Address $value ] } {
                    set ipType "ipv6"
                }
			}
			-domain_name_server_list {
				set domain_name_server_list $value
			}
			-router_list {
				set router_list $value
			}
		}
    }

Deputs Step10
    set range $handle
Deputs Step20

    set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
    set ipObj [GetDependentNgpfProtocolHandle $handle "ip"]

    if { [ info exists count ] } {
    	ixNet setA $handle -poolCount $count
    }
Deputs Step25
    if { [ info exists pool_ip_start ] } {
       if {$ipType == "ipv4"} {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp4ServerSessions -ipAddress] -pattern]
           set dhcpObj $handle/dhcp4ServerSessions
           SetMultiValues $dhcpObj "-ipAddress" $ipPattern $pool_ip_start
       } else {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp6ServerSessions -ipAddress] -pattern]
           set dhcpObj $handle/dhcp6ServerSessions
           SetMultiValues $dhcpObj "-ipAddress" $ipPattern $pool_ip_start
       }
    }
Deputs Step30
    if { [ info exists domain_name_server_list ] } {
		set index 1
		foreach dns $domain_name_server_list {
			if { $index > 2 } {
				break
			}
			if {$ipType == "ipv4"} {
			    Deputs "Not able to find domain_name_server_list equivalent for Ipv4 in NGPF"
			}
			if {$ipType == "ipv6"} {
			    set ipPattern [ixNet getA [ixNet getA $handle -dnsDomain] -pattern]
                SetMultiValues $handle "-dnsDomain" $ipPattern $dns
			}
			incr index
		}
    }
    if { [ info exists ipv4_addr ] } {
       if {$ipType == "ipv4"} {
            set ipPattern [ixNet getA [ixNet getA $ipObj -address] -pattern]
            SetMultiValues $ipObj "-address" $ipPattern $ipv4_addr
       } else {
            set ipPattern [ixNet getA [ixNet getA $ipObj -address] -pattern]
            SetMultiValues $ipObj "-address" $ipPattern $ipv4_addr
       }
    }
    if { [ info exists ipv4_gw ] } {
       if {$ipType == "ipv4"} {
            set ipPattern [ixNet getA [ixNet getA $ipObj -gatewayIp] -pattern]
            SetMultiValues $ipObj "-gatewayIp" $ipPattern $ipv4_gw
       } else {
            set ipPattern [ixNet getA [ixNet getA $ipObj -gatewayIp] -pattern]
            SetMultiValues $ipObj "-gatewayIp" $ipPattern $ipv4_gw
       }
    }
    if { [ info exists router_list ] } {
       if {$ipType == "ipv4"} {
            set ipPattern [ixNet getA [ixNet getA $handle/dhcp4ServerSessions -ipGateway] -pattern]
            set dhcpObj $handle/dhcp4ServerSessions
            SetMultiValues $dhcpObj "-ipGateway" $ipPattern [ lindex $router_list 0 ]
       } else {
            Deputs "Router parameter not available in Ipv6 for NGPF"
       }
    }
    if { [ info exists gw_step ] } {
       if {$ipType == "ipv4"} {
            set ipPattern [ixNet getA [ixNet getA $ipObj -address] -pattern]
            SetMultiValues $ipObj "-address" $ipPattern " " $gw_step
            set ipPattern [ixNet getA [ixNet getA $ipObj -gatewayIp] -pattern]
            SetMultiValues $ipObj "-gatewayIp" $ipPattern " " $gw_step
       } else {
            set ipPattern [ixNet getA [ixNet getA $ipObj -address] -pattern]
            SetMultiValues $ipObj "-address" $ipPattern " " $gw_step
            set ipPattern [ixNet getA [ixNet getA $ipObj -gatewayIp] -pattern]
            SetMultiValues $ipObj "-gatewayIp" $ipPattern " " $gw_step
       }
    }
    if { [ info exists ipv4_prefix_len ] } {
       set ipPrefix [ixNet getA [ixNet getA $ipObj -prefix] -pattern]
       SetMultiValues $ipObj "-prefix" $ipPrefix $ipv4_prefix_len
    }
    if { [ info exists pool_ip_pfx ] } {
       if {$ipType == "ipv4"} {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp4ServerSessions -ipPrefix] -pattern]
           set dhcpObj $handle/dhcp4ServerSessions
           SetMultiValues $dhcpObj "-ipPrefix" $ipPattern $pool_ip_pfx
       } else {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp6ServerSessions -ipPrefix] -pattern]
           set dhcpObj $handle/dhcp6ServerSessions
           SetMultiValues $dhcpObj "-ipPrefix" $ipPattern $pool_ip_pfx
       }
    }
    if { [ info exists pool_ip_count ] } {
       if {$ipType == "ipv4"} {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp4ServerSessions -poolSize] -pattern]
           set dhcpObj $handle/dhcp4ServerSessions
           SetMultiValues $dhcpObj "-poolSize" $ipPattern $pool_ip_count
       } else {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp6ServerSessions -poolSize] -pattern]
           set dhcpObj $handle/dhcp6ServerSessions
           SetMultiValues $dhcpObj "-poolSize" $ipPattern $pool_ip_count
       }
    }
    
    if { [ info exists lease_time ] } {
       if {$ipType == "ipv4"} {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp4ServerSessions -defaultLeaseTime] -pattern]
           set dhcpObj $handle/dhcp4ServerSessions
           SetMultiValues $dhcpObj "-defaultLeaseTime" $ipPattern $lease_time
       } else {
           set ipPattern [ixNet getA [ixNet getA $handle/dhcp6ServerSessions -defaultLeaseTime] -pattern]
           set dhcpObj $handle/dhcp6ServerSessions
           SetMultiValues $dhcpObj "-defaultLeaseTime" $ipPattern $lease_time
       }
    }
    if { [ info exists max_lease_time ] } {
       set root [ixNet getRoot]
       #ixNet setA [ixNet getList $root/globals/protocolStack dhcpServerGlobals ] -maxLeaseTime $max_lease_time
       Deputs "Not able to find max_lease_time equivalent in NGPF"
	}
	ixNet  commit
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]    
    
}
body DhcpServer::start {} {
    set tag "body DhcpServer::start [info script]"
Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
		ixNet exec start $handle
	} ] } {
		after 3000
		ixNet exec start $handle
	}
    return [GetStandardReturnHeader]
}
body DhcpServer::stop {} {
    set tag "body DhcpHost::stop [info script]"
Deputs "----- TAG: $tag -----"
   ixNet exec stop $handle
    return [GetStandardReturnHeader]
}
body DhcpServer::get_lease_address {} {
    set tag "body DhcpServer::get_lease_address [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
    set view [ lindex [ixNet getF $root/statistics view -caption "dhcpPerSessionView" ] 0 ]
Deputs "view:$view"
    if { $view == "" } {
        #set view [ CreateDhcpPerSessionView ]
        set customView [ixNet add $root/statistics view]
        ixNet setMultiAttribute $customView -pageTimeout 25 \
                                                    -type layer23NextGenProtocol \
                                                    -caption "dhcpPerSessionView" \
                                                    -visible true -autoUpdate true \
                                                    -viewCategory NextGenProtocol
        ixNet commit
        set view [lindex [ixNet remapIds $customView] 0]

        set advCv [ixNet add $view "advancedCVFilters"]
        set type "Per Lease"
        set protocol "DHCPv6 Server"
        ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                             -protocol \{$protocol\} \
                                                             -availableFilterOptions \{$type\} \
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
             ixNet setA $stat -aggregationType first
             ixNet commit
        }
        ixNet setA $view -enabled true
        ixNet commit
        ixNet execute refresh $view
    }
    set captionList         [ixNet getA $view/page -columnCaptions ]
    set stateIndex          [ lsearch -exact $captionList {Lease State} ]
    set addressIndex   		[ lsearch -exact $captionList {Lease Address} ]

    set ret "Status : true\nLog : \n"

	set pageCount [ixNet getA $view/page -totalPages ]

	set addrList [list]
	for { set index 1 } { $index <= $pageCount } { incr index } {

		ixNet setA $view/page -currentPage $index
		ixNet commit

		set stats [ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"

		foreach row $stats {

			eval {set row} $row
Deputs "row:$row"

			set state [ lindex $row $stateIndex ]
			if { $state == "Up" } {
				lappend addrList  [ lindex $row $addressIndex ]
			}
		}
			
Deputs "page:$addrList"
	}

	ixNet remove $view
	ixNet commit
	return [GetStandardReturnHeader][ GetStandardReturnBody count [ llength $addrList ] ][ GetStandardReturnBody address "$addrList" ]

}

class Dhcpv4Server {
    inherit DhcpServer

	public variable ipType "ipv4"
    constructor { port } { chain $port} {}
	method get_stats {} {}
	method reborn { {onStack null} } {
		chain "ipv4" $onStack
	}
}
body Dhcpv4Server::get_stats {} {
    set tag "body Dhcpv4Server::get_stats [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
Deputs "root $root"
Deputs [ixNet getL $root/statistics view]
    set view [ lindex [ixNet getF $root/statistics view -caption "DHCPv4 Server Per Port" ] 0 ]
Deputs "view:$view"
    if { $view == "" } {
		return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
    }

    set captionList         [ixNet getA $view/page -columnCaptions ]
    set rxDiscoverIndex          [ lsearch -exact $captionList {Discovers Rx} ]
Deputs "index:$rxDiscoverIndex"
    set txOfferIndex          	 [ lsearch -exact $captionList {Offers Tx} ]
Deputs "index:$txOfferIndex"
    set rxRequestIndex        	 [ lsearch -exact $captionList {Requests Rx} ]
Deputs "index:$rxRequestIndex"
    set txACKIndex          	 [ lsearch -exact $captionList {ACKs Tx} ]
Deputs "index:$txACKIndex"
    set txNACKIndex          	 [ lsearch -exact $captionList {NACKs Tx} ]
Deputs "index:$txNACKIndex"
    set rxDeclineIndex        	 [ lsearch -exact $captionList {Declines Rx} ]
Deputs "index:$rxDeclineIndex"
    set rxReleaseIndex        	 [ lsearch -exact $captionList {Releases Rx} ]
Deputs "index:$rxReleaseIndex"
    set rxInfoReqIndex        	 [ lsearch -exact $captionList {Information-Requests Rx} ]
    #set rxInfoReqIndex        	 [ lsearch -exact $captionList {Informs Received} ]
Deputs "index:$rxInfoReqIndex"
    set totLeaseIndex        	 [ lsearch -exact $captionList {Total Leases Allocated} ]
Deputs "index:$totLeaseIndex"
    set totRenewIndex        	 [ lsearch -exact $captionList {Total Leases Renewed} ]
Deputs "index:$totRenewIndex"
    set curLeaseIndex        	 [ lsearch -exact $captionList {Current Leases Allocated} ]
Deputs "index:$curLeaseIndex"

	set refresh [ixNet exec refresh $view ]
Deputs "refresh:$refresh"
Deputs "after 5 seconds..."
after 5000
    set stats [ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"
    foreach row $stats {
        eval {set row} $row
Deputs "row:$row"
	}
	
    set ret "Status : true\nLog : \n"
    
	set statsItem   "current_bound_count"
	set statsVal    [ lindex $row $curLeaseIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	
	set statsItem   "rx_decline_count"
	set statsVal    [ lindex $row $rxDeclineIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	
	set statsItem   "rx_discover_count"
	set statsVal    [ lindex $row $rxDiscoverIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "rx_inform_count"
	set statsVal    [ lindex $row $rxInfoReqIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "rx_release_count"
	set statsVal    [ lindex $row $rxReleaseIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "rx_request_count"
	set statsVal    [ lindex $row $rxRequestIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_bound_count"
	set statsVal    [ lindex $row $totLeaseIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_expired_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_released_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_renewed_count"
	set statsVal    [ lindex $row $totRenewIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_ack_count"
	set statsVal    [ lindex $row $txACKIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_force_renew_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_nak_count"
	set statsVal    [ lindex $row $txNACKIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_offer_count"
	set statsVal    [ lindex $row $txOfferIndex ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]


Deputs "ret:$ret"
    return $ret
	
}

class Dhcpv6Server {
    inherit DhcpServer
	public variable ipType "ipv6"

    constructor { port } { chain $port } {}
	method get_stats {} {}
	method config { args } {}
	method reborn {"ipv6" {onStack null}} {
		chain "ipv6" $onStack
       	ixNet setA $handle/dhcpServerRange -ipType IPv6
       	ixNet commit
	}
	

}
body Dhcpv6Server::get_stats {} {
    set tag "body Dhcpv6Server::get_stats [info script]"
Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
Deputs "root $root"
Deputs [ixNet getL $root/statistics view]
    set view [ lindex [ixNet getF $root/statistics view -caption "DHCPv6 Server Per Port" ] 0 ]
Deputs "view:$view"

    if { $view == "" } {
		return [ GetErrorReturnHeader "Can't fetch stats view, please make sure the session starting correctly." ]
    }


    set captionList         [ixNet getA $view/page -columnCaptions ]
    set current_bound_count_index          [ lsearch -exact $captionList {Current Addresses Allocated} ]
    set rx_rebind_count_index          	 [ lsearch -exact $captionList {Rebinds Rx} ]
    set rx_release_count_index        	 [ lsearch -exact $captionList {Releases Rx} ]
    set rx_renew_count_index          	 [ lsearch -exact $captionList {Renewals Rx} ]
    set rx_request_count_index          	 [ lsearch -exact $captionList {Requests Rx} ]
    set rx_solicit_count_index        	 [ lsearch -exact $captionList {Solicits Rx} ]
    set total_bound_count_index        	 [ lsearch -exact $captionList {Total Addresses Allocated} ]
    set tx_advertise_count_index        	 [ lsearch -exact $captionList {Advertisements Tx} ]
    set tx_reply_count_index        	 [ lsearch -exact $captionList {Replies Tx}  ]
    set rx_info_req_count_index        	 [ lsearch -exact $captionList {Replies Tx}  ]

	set refresh [ixNet exec refresh $view ]
Deputs "refresh:$refresh"
Deputs "after 5 seconds..."
after 5000
    set stats [ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"
    foreach row $stats {
        eval {set row} $row
Deputs "row:$row"
	}
	
    set ret "Status : true\nLog : \n"
    
	set statsItem   "current_bound_count"
	set statsVal    [ lindex $row $current_bound_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	
	set statsItem   "rx_rebind_count"
	set statsVal    [ lindex $row $rx_rebind_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	
	set statsItem   "rx_release_count"
	set statsVal    [ lindex $row $rx_release_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	set statsItem   "total_released_count"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	

	set statsItem   "rx_renew_count"
	set statsVal    [ lindex $row $rx_renew_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	set statsItem   "total_renewed_count"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "rx_request_count"
	set statsVal    [ lindex $row $rx_request_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "rx_solicit_count"
	set statsVal    [ lindex $row $rx_solicit_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_bound_count"
	set statsVal    [ lindex $row $total_bound_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_advertise_count"
	set statsVal    [ lindex $row $tx_advertise_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_reply_count"
	set statsVal    [ lindex $row $tx_reply_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_reply_count"
	set statsVal    [ lindex $row $tx_reply_count_index ]
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "total_expired_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_reconfigure_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_reconfigure_rebind_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

	set statsItem   "tx_reconfigure_renew_count"
	set statsVal    NA
Deputs "stats val:$statsVal"
	set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]


Deputs "ret:$ret"
    return $ret
	
}
body Dhcpv6Server::config { args } {
    set tag "body Dhcpv6Server::config [info script]"
Deputs "----- TAG: $tag -----"
    if { $handle == "" } {
    	set flagReborn 1
    } else {
    	set flagReborn 0
    }
    eval { chain } $args 
    if { $flagReborn } {
       ixNet setA $handle/dhcpServerRange -ipType IPv6
       ixNet commit    	
    }
    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-ia_type {
				# set ia_type [ string toupper $value ]
				set ia_type [ string tolower $value ]
				if {$ia_type == "iana+iapd"} {
					set ia_type "iana_iapd"
				}
			}
		}
	}
    if {[info exists ia_type]} {
	    set ipPattern [ixNet getA [ixNet getA $handle/dhcp6ServerSessions -iaType] -pattern]
	    set dhcpObj $handle/dhcp6ServerSessions
        SetMultiValues $dhcpObj "-iaType" $ipPattern $ia_type
	}
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]    
}

class DhcpDualStackHost {
    
	inherit NetNgpfObject

	public variable dhcpv4
	public variable dhcpv6
	
	constructor { port } {
		set dhcpv4 $this/dhcpv4
		set dhcpv6 $this/dhcpv6
		Dhcpv4Host $dhcpv4 $port
Deputs "created dhcpv4 host handle $dhcpv4"		
		set hDhcp [ $dhcpv4 cget -hDhcp ]
Deputs "dhcp handle: $hDhcp"
		Dhcpv6Host $dhcpv6 $port $hDhcp
Deputs "created dhcpv6 host $dhcpv6"	
	}

	method config { args } {
		set tag "body DhcpDualStackHost::config [info script]"
Deputs "----- TAG: $tag -----"

		eval $dhcpv4 config $args
		eval $dhcpv6 config $args
	}	

	method start { args } {
		set tag "body DhcpDualStackHost::start [info script]"
	Deputs "----- TAG: $tag -----"
	
		catch {
			$dhcpv4 start
		}
		catch {
			$dhcpv6 start
		}
	}

	method stop { args } {
		set tag "body DhcpDualStackHost::start [info script]"
	Deputs "----- TAG: $tag -----"
	
		catch {
			$dhcpv4 stop
		}
		catch {
			$dhcpv6 stop
		}
	}

	method unconfig { args } {
		set tag "body DhcpDualStackHost::unconfig [info script]"
	Deputs "----- TAG: $tag -----"
	
		catch {
			$dhcpv4 unconfig
		}
		catch {
			$dhcpv6 unconfig
		}
	}
	method wait_request_complete { args } {
		set tag "body DhcpDualStackHost::wait_request_complete [info script]"
	Deputs "----- TAG: $tag -----"

		set timeout 60

		foreach { key value } $args {
			set key [string tolower $key]
			switch -exact -- $key {
				-timeout {
					set timeout $value
				}
			}
		}
		
		if { ![ GetResultFromReturn \
			[ $dhcpv4 wait_request_complete $timeout ] ] } {
			return [ GetErrorReturnHeader "dhcpv4 host timeout" ]
		}
		return [ $dhcpv6 wait_request_complete $timeout ]
	}
}

class IPoEHost {

    inherit ProtocolNgpfStackObject
	public variable hIp
	constructor { port } { chain $port } {}
    method reborn {{OnStack null}} {
	    set tag "body IPoEHost::reborn [info script]"
	    Deputs "----- TAG: $tag -----"

	    chain

	    set sg_ethernet $stack
	    #-- add ipoe endpoint stack
	    set ipObj [ixNet getL $sg_ethernet ipv4]
	    if {[llength $ipObj] != 0 } {
	        set sg_ipEndpoint [lindex $ipObj 0]
	    } else {
	        set sg_ipEndpoint [ixNet add $sg_ethernet ipv4]
	        ixNet setA $sg_ipEndpoint -name $this
	        ixNet commit
	    }
	    set sg_ipEndpoint [lindex [ixNet remapIds $sg_ipEndpoint] 0]
	    set hIp $sg_ipEndpoint
	    set handle $sg_ipEndpoint

	    #-- add range
	    ixNet setA $sg_ethernet -useVlans False
	    ixNet commit
	
    }
	
	method config { args } {}
	method start {} {}
	method stop {} {}
	method abort {} {}
}
body IPoEHost::config { args } {
    global errorInfo
    global errNumber
    set tag "body IPoEHost::config [info script]"
Deputs "----- TAG: $tag -----"
#disable the interface

    eval { chain } $args
	
	set count 			1
	set ipv4_addr		1.1.1.2
	set ipv4_addr_step	0.0.0.1
	set ipv4_prefix_len	24
	set ipv4_gw			1.1.1.1
	set ipv6_addr		"3ffe:3210::2"
	set ipv6_addr_step	::1
	set ipv6_prefix_len	64
	set ipv6_gw			3ffe:3210::1
	set ip_version		ipv4
	set EgwIncrMode [list perSubnet perInterface]

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -count {
                if { [ string is integer $value ] } {
                    set count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -ip_version {
				set ip_version $value
			}
			-ip_mask -
			-ip_prefix_len {
				set ip_prefix_len $value
			}
            -ip_addr {
				set ip_addr $value
            }
            -ip_addr_step {
                set ip_addr_step $value
            }
			-ip_gw_addr {
				set ip_gw_addr $value
			}
			-ip_gw_addr_step {
			    set ip_gw_addr_step $value
			}
			-ip_gw_incr_mode {
			    if {$value == "perSubnet" || $value == "perInterface"} {
				    set ip_gw_incr_mode $value
				}
			}
			-mss {
			    set mss $value
			}
			-addr_mode {
			    set ipv6auto $value
			}
			-auto_mac_generation {
			    set auto_mac_generation $value
			}
			-enable_ipv6_config_rate {
			    set enable_ipv6_config_rate $value
			}
			-ipv6_config_rate {
			    set ipv6_config_rate $value
			}

        }
    }

    if { [ info exists ip_addr_step ] } {
        if { [ info exists ip_prefix_len ] } {
            set pLen $ip_prefix_len
        } else {
            if {$ip_version == "ipv4"} {
                set pLen 24
            } else {
                set pLen 64
            }
        }
        set ip_addr_step [GetIpV46Step $ip_version $pLen $ip_addr_step]
    }
    if { [ info exists ip_gw_addr_step ] } {
       if { [ info exists ip_prefix_len ] } {
            set pLen $ip_prefix_len
        } else {
            if {$ip_version == "ipv4"} {
                set pLen 24
            } else {
                set pLen 64
            }
        }
        set ip_gw_addr_step [GetIpV46Step $ip_version $pLen $ip_gw_addr_step]
    }
	if { [ info exists count ] } {
		# ixNet setA $handle/ipRange -count $count
		ixNet setA $handle -count $count
	}
	
	if { [ info exists ip_version ] } {
		set ip_version [string tolower $ip_version]
		if {[string first "ipv4" $handle] != -1} {
            set ethernetObj [GetDependentNgpfProtocolHandle $handle "ethernet"]
            set handle $ethernetObj
        } else {
            set handle $handle
        }
		if {$ip_version == "ipv4"} {
			set ipHandle [ixNet add $handle ipv4]
		}
		if {$ip_version == "ipv6"} {
			set ipHandle [ixNet add $handle ipv6]
		}
		ixNet commit
		set handle [ixNet remapIds $ipHandle]
	}
	
	if { [ info exists ip_addr ] } {
		Deputs "Adding ip address"
		set ipPattern [ixNet getA [ixNet getA $handle -address] -pattern]
	    SetMultiValues $handle "-address" $ipPattern $ip_addr
	}
	
	if { [ info exists ip_addr_step ] } {
		Deputs "Adding ip address step"
		set ipPattern [ixNet getA [ixNet getA $handle -address] -pattern]
		SetMultiValues $handle "-address" $ipPattern " " $ip_addr_step
	}
	
	if { [ info exists ip_prefix_len ] } {
		Deputs "Adding prefix len"
		set ipPattern [ixNet getA [ixNet getA $handle -prefix] -pattern]
	    SetMultiValues $handle "-prefix" $ipPattern $ip_prefix_len
	}

	if { [ info exists ip_gw_addr ] } {
		Deputs "Adding Gw address"
		set ipPattern [ixNet getA [ixNet getA $handle -gatewayIp] -pattern]
	    SetMultiValues $handle "-gatewayIp" $ipPattern $ip_gw_addr
	}
	
	if { [ info exists ip_gw_addr_step ] } {
		Deputs "Adding Gw address step as $ip_gw_addr_step"
		set ipPattern [ixNet getA [ixNet getA $handle -gatewayIp] -pattern]
	    SetMultiValues $handle "-gatewayIp" $ipPattern " " $ip_gw_addr_step
	}
	
	if { [ info exists ip_gw_incr_mode ] } {
		## TODO
		Deputs "ip_gw_incr_mode not required in NGPF"
		#ixNet setA $handle/ipRange -gatewayIncrementMode $ip_gw_incr_mode
	}
	 
	if { [ info exists mss ] } {
		## Marked as one of the traffic options in NGPF. 
		## Need to check the feasibility to pass this value from IP object to traffic.
		# ixNet setA $handle/ipRange -mss $mss
		Deputs "mss not required in NGPF"
	}
	
	if { [ info exists auto_mac_generation ] } {
		# Not supported in NGPF
		# ixNet setA $handle/ipRange -autoMacGeneration $auto_mac_generation
		Deputs "auto_mac_generation not required in NGPF"
	}
	ixNet commit
	
	set ipv6Globals "::ixNet::OBJ-/globals/topology/ipv6"
	if { [ info exists enable_ipv6_config_rate ] } {	
		## TODO
		set ipPattern [ixNet getA [ixNet getA $ipv6Globals/startRate -enabled] -pattern]
		set ipv6Obj $ipv6Globals/startRate
	    SetMultiValues $ipv6Obj "-enabled" $ipPattern $enable_ipv6_config_rate
    }
	if { [ info exists ipv6_config_rate ] } {	
		## TODO
		set ipPattern [ixNet getA [ixNet getA $ipv6Globals/startRate -rate] -pattern]
		set ipv6Obj $ipv6Globals/startRate
	    SetMultiValues $ipv6Obj "-rate" $ipPattern $ipv6_config_rate
    }
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
}

body IPoEHost::start {} {
    set tag "body IPoEHost::start [info script]"
Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
		ixNet exec start $hIp
	} ] } {
		after 3000
		ixNet exec start $hIp
	}
    return [GetStandardReturnHeader]
}

body IPoEHost::stop {} {
    set tag "body IPoEHost::stop [info script]"
Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
		ixNet exec stop $hIp
	} ] } {
		after 3000
		ixNet exec stop $hIp
	}
    return [GetStandardReturnHeader]
}

body IPoEHost::abort {} {
    set tag "body IPoEHost::abort [info script]"
Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
		ixNet exec abort $hIp
	} ] } {
		after 3000
		ixNet exec abort $hIp
	}
    return [GetStandardReturnHeader]
}


class Ipv6AutoConfigHost {

    inherit ProtocolNgpfStackObject
	public variable hIp
    constructor { port } { chain $port } {}
    method reborn {{onStack null}} {
	    set tag "body Ipv6AutoConfigHost::reborn [info script]"
	    Deputs "----- TAG: $tag -----"
		    
	    chain
	    	    	
	    set sg_ethernet $stack
	    set ipObj [ixNet getL $sg_ethernet ipv6Autoconfiguration]
	    set ipv6Obj [ixNet getL $sg_ethernet ipv6]
	    if {[llength $ipObj] != 0 && [llength $ipv6Obj] == 0} {
	        set sg_ipEndpoint [lindex $ipObj 0]
	    } elseif {[llength $ipObj] == 0 && [llength $ipv6Obj] == 0} {
	        set sg_ipEndpoint [ixNet add $sg_ethernet ipv6Autoconfiguration]
	        ixNet setA $sg_ipEndpoint -name $this
	        ixNet commit
	    } else {

	         error "Failed to add ipv6Autoconfiguration"
	    }
	    set sg_ipEndpoint [ixNet remapIds $sg_ipEndpoint]

	    set sg_ipEndpoint [lindex [ixNet remapIds $sg_ipEndpoint] 0]
	    set hIp $sg_ipEndpoint
	    set handle $sg_ipEndpoint
	
	 	set sg_Options [ixNet add $hPort/protocolStack options]
	 	ixNet setMultiAttrs $sg_Options\
             -routerSolicitationDelay 1 \
             -routerSolicitationInterval 3 \
             -routerSolicitations 2 \
             -retransTime 1000 \
             -dadTransmits 1 \
             -dadEnabled True \
             -ipv4RetransTime 3000 \
             -ipv4McastSolicit 4
			
		ixNet commit
    }
	
	method config { args } {}
	method start {} {}
    method stop {} {}
	method abort {} {}
}


body Ipv6AutoConfigHost::config { args } {
	Deputs "No configuration changes allowed for Ipv6AutoConfigHost in Ngpf"
}

body Ipv6AutoConfigHost::start {} {
    set tag "body Ipv6AutoConfigHost::start [info script]"
	global LoadConfigMode
Deputs "----- TAG: $tag -----"
Deputs "handle : $handle"
	after 3000
	if {![info exists hIp] && $LoadConfigMode == 1} {
		set protocolStack [ixNet getL $hPort protocolStack]
        set ethernet [lindex [ixNet getL $protocolStack ethernet] 0]
		set sg_ipEndpoint [ixNet getL $ethernet ipEndpoint]
		set hIp [lindex $sg_ipEndpoint 0]
	}
	if { [ catch {
	 	ixNet exec start $hIp
	} ] } {
	 	after 3000
	 	ixNet exec start $hIp
	}
	return [GetStandardReturnHeader]
}

body Ipv6AutoConfigHost::stop {} {
    set tag "body Ipv6AutoConfigHost::stop [info script]"
Deputs "----- TAG: $tag -----"
Deputs "handle : $handle"
   ixNet exec stop $hIp
    return [GetStandardReturnHeader]
}

body Ipv6AutoConfigHost::abort {} {
    set tag "body Ipv6AutoConfigHost::abort [info script]"
Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
	 	ixNet exec abort $hIp
	} ] } {
	 	after 3000
	 	ixNet exec abort $hIp
	}
	return [GetStandardReturnHeader]
}
class IpHost {
    inherit ProtocolNgpfStackObject
	public variable hIp
    
    constructor { port } { chain $port } {}
    method reborn { {OnStack null}} {
	    set tag "body IpHost::reborn [info script]"
	    Deputs "----- TAG: $tag -----"
		    
	    chain 
	    	    	
	    set sg_ethernet $stack
	    #-- add ipoe endpoint stack
	    set ipObj [ixNet getL $sg_ethernet ipv4]
	    if {[llength $ipObj] != 0 } {
	        set sg_ipEndpoint [lindex $ipObj 0]
	    } else {
	        set sg_ipEndpoint [ixNet add $sg_ethernet ipv4]
	        ixNet setA $sg_ipEndpoint -name $this
	        ixNet commit
	    }
	    set sg_ipEndpoint [lindex [ixNet remapIds $sg_ipEndpoint] 0]
	    set hIp $sg_ipEndpoint
	    set handle $sg_ipEndpoint

	    #-- add range
	    ixNet setA $sg_ethernet -useVlans False
	    ixNet commit

		set sg_Options [ixNet add $hPort/protocolStack options]
		ixNet setMultiAttrs $sg_Options\
            -routerSolicitationDelay 1 \
            -routerSolicitationInterval 3 \
            -routerSolicitations 2 \
            -retransTime 1000 \
            -dadTransmits 1 \
            -dadEnabled True \
            -ipv4RetransTime 3000 \
            -ipv4McastSolicit 4

		ixNet commit
    }
	
	method config { args } {}
	method start {} {}
    method stop {} {}
	method abort {} {}
}
body IpHost::config { args } {
    global errorInfo
    global errNumber
    set tag "body IpHost::config [info script]"
    Deputs "----- TAG: $tag -----"
    eval { chain } $args
	set EgwIncrMode [list perSubnet perInterface]
	#param collection
    Deputs "Args:$args "
	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -count {
                if { [ string is integer $value ] } {
                   #ixNet setA $handle/ipRange -count $value
                   ixNet setA $handle -count $value
                   ixNet commit
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -dup_addr_detection {
				##TODO
			    if {$value == "yes"} {
                   ixNet setA $hPort/protocolStack/options \
                        -dadEnabled "True"
                   ixNet commit 
				} else {
                   ixNet setA $hPort/protocolStack/options \
                        -dadEnabled "False"
                   ixNet commit 
				}
            }
            -dup_addr_detect_transmits {
				## TODO
				ixNet setA $hPort/protocolStack/options \
                    -dadTransmits $value
               ixNet commit
            }
            -retrans_timer {
			    ## TODO
				ixNet setA $hPort/protocolStack/options \
                    -retransTime $value
               ixNet commit
			}
			-router_solicitation_retrans_timer {
				## TODO
				ixNet setA $hPort/protocolStack/options \
                        -routerSolicitationInterval $value
                ixNet commit
			}
			-router_solicitation_retries {
				## TODO
				ixNet setA $hPort/protocolStack/options \
                    -routerSolicitations $value
               ixNet commit
			}
			-ipv4_addr {
			    set ipPattern [ixNet getA [ixNet getA $handle -address] -pattern]
                SetMultiValues $handle "-address" $ipPattern $value
            }
            -ipv4_addr_step {
				set ipPattern [ixNet getA [ixNet getA $handle -address] -pattern]
                SetMultiValues $handle "-address" $ipPattern " " $value
            }
			-ipv4_mask -
			-ipv4_prefix_len {
				set ipPattern [ixNet getA [ixNet getA $handle -prefix] -pattern]
                SetMultiValues $handle "-prefix" $ipPattern $value
			}
			-ipv4_gw_addr {
				set ipPattern [ixNet getA [ixNet getA $handle -gatewayIp] -pattern]
                SetMultiValues $handle "-gatewayIp" $ipPattern $value
			}
			-ipv4_gw_addr_step {
				set ipPattern [ixNet getA [ixNet getA $handle -gatewayIp] -pattern]
                SetMultiValues $handle "-gatewayIp" $ipPattern " " $value
			}
			-ipv4_gw_incr_mode {
				## TODO need to check with engineering team for mapping
			    if {$value == "perSubnet" || $value == "perInterface"} {
				   #ixNet setA $handle/ipRange -gatewayIncrementMode $value
                   ixNet commit
				} else {
				     error "$errNumber(1) key:$key value:$value"
				}
			}
			-mss {
				## TODO -- Not found equivalent in NGPF
			   #ixNet setA $handle/ipRange -mss $value
               ixNet commit
			}
			-auto_mac_generation {
			    Deputs "Auto Mac generation not required in NGPF"
			}
            -mac {
               set ipPattern [ixNet getA [ixNet getA $stack -mac] -pattern]
               SetMultiValues $stack "-mac" $ipPattern $value
            }
            -mac_step {
			   set ipPattern [ixNet getA [ixNet getA $stack -mac] -pattern]
               SetMultiValues $stack "-mac" $ipPattern " " $value
            }
            -vlan_id {

				ixNet setA $stack -useVlans True
				set vlanList [ixNet getL $stack vlan]
				foreach vlanEntry $vlanList {
					#ixNet setA [ixNet getA $vlanEntry -vlanId]/counter -start $value
					set ipPattern [ixNet getA [ixNet getA $vlanEntry -vlanId] -pattern]
                    SetMultiValues $vlanEntry "-vlanId" $ipPattern $value
				}
                ixNet commit
            }
            -vlan_id_step {

				set vlanList [ixNet getL $stack vlan]
				foreach vlanEntry $vlanList {
					set ipPattern [ixNet getA [ixNet getA $vlanEntry -vlanId] -pattern]
                    SetMultiValues $vlanEntry "-vlanId" $ipPattern " " $value
				}
               ixNet commit
            }
            -vlan_priority {

				set vlanList [ixNet getL $stack vlan]
				foreach vlanEntry $vlanList {
					set ipPattern [ixNet getA [ixNet getA $vlanEntry -priority] -pattern]
                    SetMultiValues $vlanEntry "-priority" $ipPattern $value
				}
                ixNet commit
            }
            -vlan_unique_count {

				ixNet setA $stack -vlanCount $value
                ixNet commit
            }
        }
    }
	
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
}

body IpHost::start {} {
    set tag "body IpHost::start [info script]"
    Deputs "----- TAG: $tag -----"
    Deputs "handle : $handle"
	after 3000
	if { [ catch {
		ixNet exec start $hIp
	} ] } {
		after 3000
		ixNet exec start $hIp
	}
    return [GetStandardReturnHeader]
}
body IpHost::stop {} {
    set tag "body IpHost::stop [info script]"
    Deputs "----- TAG: $tag -----"
    Deputs "handle : $handle"
   ixNet exec stop $hIp
    return [GetStandardReturnHeader]
}

body IpHost::abort {} {
    set tag "body IpHost::abort [info script]"
    Deputs "----- TAG: $tag -----"
	after 3000
	if { [ catch {
		ixNet exec abort $hIp
	} ] } {
		after 3000
		ixNet exec abort $hIp
	}
    return [GetStandardReturnHeader]
}
# Child Lists:
	# ancpRange (kOptional : getList)
	# dhcpRange (kRequired : getList)
	# dot1xRange (kOptional : getList)
	# eapoUdpRange (kOptional : getList)
	# esmcRange (kOptional : getList)
	# igmpMldRange (kOptional : getList)
	# iptvRange (kOptional : getList)
	# macRange (kRequired : getList)
	# ptpRangeOverMac (kOptional : getList)
	# vicClientRange (kOptional : getList)
	# vlanRange (kRequired : getList)
	# webAuthRange (kOptional : getList)
# Execs:
	# customProtocolStack((kArray)[(kObjref)=/vport/protocolStack/...],(kArray)[(kString)],(kEnumValue)=kAppend,kMerge,kOverwrite)
	# dhcpClientPause((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientRebind((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientRenew((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientResume((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientRetry((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientStart((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientStart((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range],(kEnumValue)=async,sync)
	# dhcpClientStop((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range])
	# dhcpClientStop((kArray)[(kObjref)=/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range],(kEnumValue)=async,sync)
	# disableProtocolStack((kObjref)=/vport/protocolStack/...,(kString))
	# enableProtocolStack((kObjref)=/vport/protocolStack/...,(kString))
#	start((kArray)[(kObjref)=/vport/protocolStack/atm,/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/ancp,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/dhcpServerEndpoint,/vport/protocolStack/atm/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip,/vport/protocolStack/atm/emulatedRouter/ip/ancp,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/twampClient,/vport/protocolStack/atm/emulatedRouter/ip/twampServer,/vport/protocolStack/atm/emulatedRouter/ipEndpoint,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/atm/emulatedRouterEndpoint,/vport/protocolStack/atm/ip,/vport/protocolStack/atm/ip/ancp,/vport/protocolStack/atm/ip/egtpEnbEndpoint,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpUeEndpoint,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tpEndpoint,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/smDnsEndpoint,/vport/protocolStack/atm/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/twampClient,/vport/protocolStack/atm/ip/twampServer,/vport/protocolStack/atm/ipEndpoint,/vport/protocolStack/atm/ipEndpoint/ancp,/vport/protocolStack/atm/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/ipEndpoint/twampClient,/vport/protocolStack/atm/ipEndpoint/twampServer,/vport/protocolStack/atm/pppox,/vport/protocolStack/atm/pppox/ancp,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppoxEndpoint,/vport/protocolStack/atm/pppoxEndpoint/ancp,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range/ancpRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet,/vport/protocolStack/ethernet/dcbxEndpoint,/vport/protocolStack/ethernet/dcbxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/dhcpServerEndpoint,/vport/protocolStack/ethernet/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip,/vport/protocolStack/ethernet/emulatedRouter/ip/ancp,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ip/twampServer,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/ethernet/emulatedRouterEndpoint,/vport/protocolStack/ethernet/esmc,/vport/protocolStack/ethernet/fcoeClientEndpoint,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFdiscRange,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFlogiRange,/vport/protocolStack/ethernet/fcoeFwdEndpoint,/vport/protocolStack/ethernet/fcoeFwdEndpoint/range,/vport/protocolStack/ethernet/fcoeFwdEndpoint/secondaryRange,/vport/protocolStack/ethernet/ip,/vport/protocolStack/ethernet/ip/ancp,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/twampClient,/vport/protocolStack/ethernet/ip/twampServer,/vport/protocolStack/ethernet/ipEndpoint,/vport/protocolStack/ethernet/ipEndpoint/ancp,/vport/protocolStack/ethernet/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ipEndpoint/twampClient,/vport/protocolStack/ethernet/ipEndpoint/twampServer,/vport/protocolStack/ethernet/pppox,/vport/protocolStack/ethernet/pppox/ancp,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppoxEndpoint,/vport/protocolStack/ethernet/pppoxEndpoint/ancp,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/vepaEndpoint,/vport/protocolStack/ethernet/vepaEndpoint/range,/vport/protocolStack/ethernetEndpoint,/vport/protocolStack/ethernetEndpoint/esmc,/vport/protocolStack/fcClientEndpoint,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range/fcClientFdiscRange,/vport/protocolStack/fcClientEndpoint/range/fcClientFlogiRange,/vport/protocolStack/fcFportFwdEndpoint])
#	start((kArray)[(kObjref)=/vport/protocolStack/atm,/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/ancp,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/dhcpServerEndpoint,/vport/protocolStack/atm/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip,/vport/protocolStack/atm/emulatedRouter/ip/ancp,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/twampClient,/vport/protocolStack/atm/emulatedRouter/ip/twampServer,/vport/protocolStack/atm/emulatedRouter/ipEndpoint,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/atm/emulatedRouterEndpoint,/vport/protocolStack/atm/ip,/vport/protocolStack/atm/ip/ancp,/vport/protocolStack/atm/ip/egtpEnbEndpoint,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpUeEndpoint,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tpEndpoint,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/smDnsEndpoint,/vport/protocolStack/atm/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/twampClient,/vport/protocolStack/atm/ip/twampServer,/vport/protocolStack/atm/ipEndpoint,/vport/protocolStack/atm/ipEndpoint/ancp,/vport/protocolStack/atm/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/ipEndpoint/twampClient,/vport/protocolStack/atm/ipEndpoint/twampServer,/vport/protocolStack/atm/pppox,/vport/protocolStack/atm/pppox/ancp,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppoxEndpoint,/vport/protocolStack/atm/pppoxEndpoint/ancp,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range/ancpRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet,/vport/protocolStack/ethernet/dcbxEndpoint,/vport/protocolStack/ethernet/dcbxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/dhcpServerEndpoint,/vport/protocolStack/ethernet/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip,/vport/protocolStack/ethernet/emulatedRouter/ip/ancp,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ip/twampServer,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/ethernet/emulatedRouterEndpoint,/vport/protocolStack/ethernet/esmc,/vport/protocolStack/ethernet/fcoeClientEndpoint,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFdiscRange,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFlogiRange,/vport/protocolStack/ethernet/fcoeFwdEndpoint,/vport/protocolStack/ethernet/fcoeFwdEndpoint/range,/vport/protocolStack/ethernet/fcoeFwdEndpoint/secondaryRange,/vport/protocolStack/ethernet/ip,/vport/protocolStack/ethernet/ip/ancp,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/twampClient,/vport/protocolStack/ethernet/ip/twampServer,/vport/protocolStack/ethernet/ipEndpoint,/vport/protocolStack/ethernet/ipEndpoint/ancp,/vport/protocolStack/ethernet/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ipEndpoint/twampClient,/vport/protocolStack/ethernet/ipEndpoint/twampServer,/vport/protocolStack/ethernet/pppox,/vport/protocolStack/ethernet/pppox/ancp,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppoxEndpoint,/vport/protocolStack/ethernet/pppoxEndpoint/ancp,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/vepaEndpoint,/vport/protocolStack/ethernet/vepaEndpoint/range,/vport/protocolStack/ethernetEndpoint,/vport/protocolStack/ethernetEndpoint/esmc,/vport/protocolStack/fcClientEndpoint,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range/fcClientFdiscRange,/vport/protocolStack/fcClientEndpoint/range/fcClientFlogiRange,/vport/protocolStack/fcFportFwdEndpoint],(kEnumValue)=async,sync)
#	stop((kArray)[(kObjref)=/vport/protocolStack/atm,/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/ancp,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/dhcpServerEndpoint,/vport/protocolStack/atm/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip,/vport/protocolStack/atm/emulatedRouter/ip/ancp,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/twampClient,/vport/protocolStack/atm/emulatedRouter/ip/twampServer,/vport/protocolStack/atm/emulatedRouter/ipEndpoint,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/atm/emulatedRouterEndpoint,/vport/protocolStack/atm/ip,/vport/protocolStack/atm/ip/ancp,/vport/protocolStack/atm/ip/egtpEnbEndpoint,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpUeEndpoint,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tpEndpoint,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/smDnsEndpoint,/vport/protocolStack/atm/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/twampClient,/vport/protocolStack/atm/ip/twampServer,/vport/protocolStack/atm/ipEndpoint,/vport/protocolStack/atm/ipEndpoint/ancp,/vport/protocolStack/atm/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/ipEndpoint/twampClient,/vport/protocolStack/atm/ipEndpoint/twampServer,/vport/protocolStack/atm/pppox,/vport/protocolStack/atm/pppox/ancp,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppoxEndpoint,/vport/protocolStack/atm/pppoxEndpoint/ancp,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range/ancpRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet,/vport/protocolStack/ethernet/dcbxEndpoint,/vport/protocolStack/ethernet/dcbxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/dhcpServerEndpoint,/vport/protocolStack/ethernet/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip,/vport/protocolStack/ethernet/emulatedRouter/ip/ancp,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ip/twampServer,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/ethernet/emulatedRouterEndpoint,/vport/protocolStack/ethernet/esmc,/vport/protocolStack/ethernet/fcoeClientEndpoint,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFdiscRange,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFlogiRange,/vport/protocolStack/ethernet/fcoeFwdEndpoint,/vport/protocolStack/ethernet/fcoeFwdEndpoint/range,/vport/protocolStack/ethernet/fcoeFwdEndpoint/secondaryRange,/vport/protocolStack/ethernet/ip,/vport/protocolStack/ethernet/ip/ancp,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/twampClient,/vport/protocolStack/ethernet/ip/twampServer,/vport/protocolStack/ethernet/ipEndpoint,/vport/protocolStack/ethernet/ipEndpoint/ancp,/vport/protocolStack/ethernet/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ipEndpoint/twampClient,/vport/protocolStack/ethernet/ipEndpoint/twampServer,/vport/protocolStack/ethernet/pppox,/vport/protocolStack/ethernet/pppox/ancp,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppoxEndpoint,/vport/protocolStack/ethernet/pppoxEndpoint/ancp,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/vepaEndpoint,/vport/protocolStack/ethernet/vepaEndpoint/range,/vport/protocolStack/ethernetEndpoint,/vport/protocolStack/ethernetEndpoint/esmc,/vport/protocolStack/fcClientEndpoint,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range/fcClientFdiscRange,/vport/protocolStack/fcClientEndpoint/range/fcClientFlogiRange,/vport/protocolStack/fcFportFwdEndpoint])
#	stop((kArray)[(kObjref)=/vport/protocolStack/atm,/vport/protocolStack/atm/dhcpEndpoint,/vport/protocolStack/atm/dhcpEndpoint/ancp,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/dhcpServerEndpoint,/vport/protocolStack/atm/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/atm/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip,/vport/protocolStack/atm/emulatedRouter/ip/ancp,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ip/twampClient,/vport/protocolStack/atm/emulatedRouter/ip/twampServer,/vport/protocolStack/atm/emulatedRouter/ipEndpoint,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/atm/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/atm/emulatedRouterEndpoint,/vport/protocolStack/atm/ip,/vport/protocolStack/atm/ip/ancp,/vport/protocolStack/atm/ip/egtpEnbEndpoint,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/egtpUeEndpoint,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/l2tpEndpoint,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/smDnsEndpoint,/vport/protocolStack/atm/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/atm/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/atm/ip/twampClient,/vport/protocolStack/atm/ip/twampServer,/vport/protocolStack/atm/ipEndpoint,/vport/protocolStack/atm/ipEndpoint/ancp,/vport/protocolStack/atm/ipEndpoint/range/ancpRange,/vport/protocolStack/atm/ipEndpoint/range/twampControlRange,/vport/protocolStack/atm/ipEndpoint/twampClient,/vport/protocolStack/atm/ipEndpoint/twampServer,/vport/protocolStack/atm/pppox,/vport/protocolStack/atm/pppox/ancp,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/atm/pppoxEndpoint,/vport/protocolStack/atm/pppoxEndpoint/ancp,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range/ancpRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/atm/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet,/vport/protocolStack/ethernet/dcbxEndpoint,/vport/protocolStack/ethernet/dcbxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint,/vport/protocolStack/ethernet/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/dhcpServerEndpoint,/vport/protocolStack/ethernet/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/dhcpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint,/vport/protocolStack/ethernet/emulatedRouter/dhcpServerEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip,/vport/protocolStack/ethernet/emulatedRouter/ip/ancp,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/emulatedRouter/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ip/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ip/twampServer,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/ancp,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampClient,/vport/protocolStack/ethernet/emulatedRouter/ipEndpoint/twampServer,/vport/protocolStack/ethernet/emulatedRouterEndpoint,/vport/protocolStack/ethernet/esmc,/vport/protocolStack/ethernet/fcoeClientEndpoint,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFdiscRange,/vport/protocolStack/ethernet/fcoeClientEndpoint/range/fcoeClientFlogiRange,/vport/protocolStack/ethernet/fcoeFwdEndpoint,/vport/protocolStack/ethernet/fcoeFwdEndpoint/range,/vport/protocolStack/ethernet/fcoeFwdEndpoint/secondaryRange,/vport/protocolStack/ethernet/ip,/vport/protocolStack/ethernet/ip/ancp,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpEnbEndpoint/ueSecondaryRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpMmeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpPcrfEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpSgwEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/egtpUeEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLacEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tp/dhcpoLnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ip/smDnsEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ip/twampClient,/vport/protocolStack/ethernet/ip/twampServer,/vport/protocolStack/ethernet/ipEndpoint,/vport/protocolStack/ethernet/ipEndpoint/ancp,/vport/protocolStack/ethernet/ipEndpoint/range/ancpRange,/vport/protocolStack/ethernet/ipEndpoint/range/twampControlRange,/vport/protocolStack/ethernet/ipEndpoint/twampClient,/vport/protocolStack/ethernet/ipEndpoint/twampServer,/vport/protocolStack/ethernet/pppox,/vport/protocolStack/ethernet/pppox/ancp,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppClientEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppox/dhcpoPppServerEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/pppoxEndpoint,/vport/protocolStack/ethernet/pppoxEndpoint/ancp,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range/ancpRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6PdClientRange,/vport/protocolStack/ethernet/pppoxEndpoint/range/dhcpv6ServerRange,/vport/protocolStack/ethernet/vepaEndpoint,/vport/protocolStack/ethernet/vepaEndpoint/range,/vport/protocolStack/ethernetEndpoint,/vport/protocolStack/ethernetEndpoint/esmc,/vport/protocolStack/fcClientEndpoint,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range,/vport/protocolStack/fcClientEndpoint/range/fcClientFdiscRange,/vport/protocolStack/fcClientEndpoint/range/fcClientFlogiRange,/vport/protocolStack/fcFportFwdEndpoint],(kEnumValue)=async,sync)

class Dot1xHost {
    inherit ProtocolNgpfStackObject
    
    public variable type
    
    constructor { port } { chain $port } {}
	method reborn { { onStack null } } {
	    set tag "body Dot1xHost::reborn [info script]"
	    Deputs "----- TAG: $tag -----"
		    
	    array set rangeStats [list]
	    if { $onStack == "null" } {
            Deputs "new dot1x endpoint"
            chain
            set topoObjList [ixNet getL [ixNet getRoot] topology]
			if { [ llength $topoObjList ] > 0 } {
                foreach topoObj $topoObjList {
                    set vportObj [ixNet getA $topoObj -vports]
                    if {$vportObj == $hPort} {
                        set deviceGroupObj [ lindex [ixNet getL $topoObj deviceGroup] 0 ]
				        set sg_ethernet [ixNet getL $deviceGroupObj ethernet]
				    }
				}
			} else {
			    set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
                set deviceGroupObj [ixNet add $topoObj deviceGroup]
               ixNet commit
               ixNet setA $deviceGroupObj -multiplier 1
               ixNet commit
                set sg_ethernet [ixNet add $deviceGroupObj ethernet]
				ixNet commit
				set sg_ethernet [ixNet remapIds $sg_ethernet]
			} 
			
			#-- add dhcp endpoint stack
			set sg_dot1xEndpoint [ixNet add $sg_ethernet dotOneX]
			ixNet commit
			set sg_dot1xEndpoint [lindex [ixNet remapIds $sg_dot1xEndpoint] 0]
			set hDot1x $sg_dot1xEndpoint
		} else {
            Deputs "based on existing stack:$onStack"
			set hDot1x $onStack
		}

	    set handle $sg_dot1xEndpoint
		
		ixNet commit
    }
    method config { args } {}
    method start {} {
        set tag "body dot1xHost::start [info script]"
        Deputs "----- TAG: $tag -----"
       ixNet exec start $handle
	
	   ixNet commit
        return [GetStandardReturnHeader]
    }
    method stop {} {
        set tag "body dot1xHost::stop [info script]"
        Deputs "----- TAG: $tag -----"
       ixNet exec stop $handle
	
	   ixNet commit
        return [GetStandardReturnHeader]
    }
    

}

body Dot1xHost::config { args } {
    global errorInfo
    global errNumber
    set tag "body Dot1xHost::config [info script]"
    Deputs "----- TAG: $tag -----"
    #disable the interface
    eval { chain } $args
	
	set count 			1
    #param collection
    Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -count {
                if { [ string is integer $value ] } {
                    set count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
            -auth_type {
				set authtype $value
            }
            -user_name {
				set username $value
            }
			-password {
				set password $value
			}
        }
    }

	set deviceGroupObj [GetDependentNgpfProtocolHandle $handle "deviceGroup"]
	if { [ info exists count ] } {
		ixNet setA $deviceGroupObj -multiplier $count
       ixNet commit
	}

	if { [ info exists authtype] } {
	    # authtype in NGPF: eaptls,eapmd5,eappeapv0,eappeapv1,eapttls,eapfast
		set ipPattern [ixNet getA [ixNet getA $handle -protocol] -pattern]
        SetMultiValues $handle "-protocol" $ipPattern $authtype
	} else {
        set ipPattern [ixNet getA [ixNet getA $handle -protocol] -pattern]
        SetMultiValues $handle "-protocol" $ipPattern "eapmd5"

    }
	
	if { [ info exists username ] } {
		ixNet setA [ixNet getA $handle -userName]/string -pattern $username{Inc:1,1}
       ixNet commit
	}
	
	if { [ info exists password ] } {
		ixNet setA [ixNet getA $handle -userPwd]/string -pattern $password{Inc:1,1}
       ixNet commit
	}
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
}
