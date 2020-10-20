
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.23
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.1.7
#		2. Enable hardware capture on all port in Tester::start_capture
# Version 1.2.1.10
#		3. Enable software capture on all port in Tester::start_capture
#		4. Show all control plane packet on all port in Tester::stop_capture
# Version 1.3.2.2
#		5. Add arguments in start capture: portList
# Version 1.4.2.3
#		6. Remove all filter after stopping capture
# Version 1.5.2.5
#		7. Set Tester::cleanup -release_port default value to false
# Version 1.6.2.6
#		8. Change the cleanup way to newconfig and Connect port to hardware
# Version 1.7.2.10
#		9. Catch the stop traffic command in case the traffic stop by itself
# Version 1.8.2.12
#		10.Add -reboot_port argument in cleanup to reboot port
# Version 1.9.2.14
#		11. Change default value of release_port to false in Tester::cleanup
# Version 1.10.2.19
#		12. Add clear Capture buffer in start_capture
# Version 1.11.2.23
#		13. Add Traffic state condition
# Version 1.12.2.26
#		14. Add Tester.clear_traffic_stats
#		15. Add Tester.get_log
# Version 1.13.3.1
#		16. Add Tester.flap_router -times -duration -a2w -w2a -end_up_dn -router
# Version 1.14.4.19
#		17. Wait start traffic state ready
# Version 1.15.4.19-patch
# Version 1.16.4.22
#		18. Stop capture before apply traffic in Tester::start_traffic
# Version 1.17.4.27
#		19. reduce waiting time of Tester::start_traffic
# Version 1.18.4.44
#		20. add -apply in start_traffic
# Version 1.19.4.47
#		21. add save_config proc
# Version 1.20.4.49
#		22. add -new_config in cleanup
# Version 1.21.4.59
#		23. add remove_all_stream proc
# Version 1.22.7.28
#       24. add Tester::delete_pppoe
# Version 1.23.1.29
#       25. add Tester::tester_config_file


class Tester {

    proc constructor {} {}
    proc apply_traffic {} {}
    proc start_traffic { { restartCaptureJudgement 1 } } {}
    proc stop_traffic {} {}
    proc start_router { args } {}
    proc stop_router { args } {}
    proc start_capture { args } {}
    proc stop_capture { { wait 3000} args } {}
    proc save_capture { args } {}
    proc clear_capture {} {}
    proc cleanup { args } {}
    proc delete_pppoe {} {}
    proc synchronize {} {}
    proc save_config { args } {}
    proc reboot {} {}
    proc clear_traffic_stats {} {}
    proc get_log { { file default } } {}
    proc getAllTx {} {}
    proc isLossFrames { { streams "" } } {}
    proc saveResults { args } {}
    proc set_stats_mode { args } {}
    proc tester_config_file { filedir } {}
    proc run_testcomposer {} {}
    proc start_arp_nd {} {}
    proc port_map { args } { }
    proc assign_all { args } {}
    proc save_result { args } {}
    
}

proc Tester::getAllTx {} {
    set tag "proc Tester::getAllTx  [info script]"
	Deputs "----- TAG: $tag -----"
    
	set allObj [ find objects ]
	set allTx 0

	foreach obj $allObj {
		if { [ $obj isa Port ] } {
Deputs "port obj:$obj"
			set tx [ GetStatsFromReturn [ $obj get_stats ] tx_frame_count ]
Deputs "port tx:$tx"
			incr allTx $tx
		}
	}
	
	return $allTx
}

proc Tester::start_traffic { args } {
    set tag "proc Tester::start_traffic [info script]"
    Deputs "----- TAG: $tag -----"

    set restartCaptureJudgement 1
	set apply 0
    
	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -capture_check {
            	set restartCaptureJudgement $value
            }                     
            -apply {
            	set apply $value
            }
        }
    }
	
	if { $apply } {
		Tester::apply_traffic
	} else {
	
		set root [ixNet getRoot]
		
		set restartCapture 0
        set suspendList [list]
		if { $restartCaptureJudgement } {
            set version [ixNet getVersion]
	        Deputs "The ixNetwork version is: $version"
			set portList [ ixNet getL $root vport ]
			foreach hPort $portList {
                if {[string match 6.0* $version]} {
                    if { [ ixNet getA $hPort/capture    -hardwareEnabled  ] } {
							set restartCapture 1
							break
				    }
                } else {
                    if { [ ixNet getA $hPort/capture   -isCaptureRunning  ] } {
                        set restartCapture 1
                        break
                    }
                }
				# if { [ ixNet getA $hPort/capture   -isCaptureRunning  ] } {
					# set restartCapture 1
					# break
				# }
			}
		}
		
		if { $restartCapture } {
			catch {
				#Tester::stop_capture 1000
                ixNet exec stopCapture
				foreach item [ ixNet getL $root/traffic trafficItem ] {
					lappend suspendList [ ixNet getA $item -suspend ]
					if { [ixNet getA $item -enabled] == "true" } {
						catch {
							ixNet exec generate $item
							
					#Deputs "Wait for generate traffic"	
						}
				    }
				}
				ixNet exec apply $root/traffic
				#Tester::start_capture
                after 1000				
				ixNet exec closeAllTabs
                ixNet exec startCapture
			}
		} else {
			foreach item [ ixNet getL $root/traffic trafficItem ] {
				lappend suspendList [ ixNet getA $item -suspend ]
				if { [ixNet getA $item -enabled] == "true" } {
                    catch {
                        ixNet exec generate $item
                        
                #Deputs "Wait for generate traffic"	
                    }
                }
			}
			ixNet exec apply $root/traffic
		}
        if { [ llength $suspendList ] > 0 } {
            foreach suspend $suspendList item [ ixNet getL $root/traffic trafficItem ] {
                ixNet setA $item -suspend $suspend
            }
        }
		ixNet commit
		ixNet exec start $root/traffic
		set timeout 30
		set stopflag 0
		while { 1 } {
		if { !$timeout } {
			break
		}
		set state [ ixNet getA $root/traffic -state ] 
		if { $state != "started" } {
            Deputs "start state:$state"
			if { [string match startedWaiting* $state ] } {
				set stopflag 1
			} elseif {[string match stopped* $state ] && ($stopflag == 1)} {
				break	
			}	
			after 1000		
		} else {
	Deputs "start state:$state"
			break
		}
		incr timeout -1
	Deputs "start timeout:$timeout state:$state"
		}
	}
    return [ GetStandardReturnHeader ]
}

proc Tester::stop_traffic {} {
    set tag "proc Tester::stop_traffic [info script]"
    Deputs "----- TAG: $tag -----"
    
    set root [ixNet getRoot]
	if { [ catch {
		ixNet exec stop $root/traffic
	} err ] } {
		Deputs "Stop traffic error:$err"
	}
    set timeout 30
    while { 1 } {
	if { !$timeout } {
		break
	}
	set state [ ixNet getA $root/traffic -state ] 
	if { ( $state != "stopped" ) && ( $state != "unapplied" ) } {
		after 1000
	} else {
		break
	}
	incr timeout -1
Deputs "stop timeout:$timeout"
    }
    return [ GetStandardReturnHeader ]
}

proc Tester::start_router { args } {
    set tag "proc Tester::start_router [info script]"
    Deputs "----- TAG: $tag -----"
    set device_type ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -device_type {
                set device_type [string tolower $value]
            }

        }
    }
    
#	ixTclNet::StartProtocols
    if { $device_type == ""} {
        ixNet exec startAllProtocols
    } else {
        set device_list ""
        set root [ixNet getRoot]
        set vport_list [ixNet getL $root vport]
        foreach vport_handle $vport_list {
            set vport_protocols     [ixNet getL $vport_handle protocols]
            set vport_protocolStack [ixNet getL $vport_handle protocolStack]
            
            switch -exact -- $device_type {
                bgp {                    
                    set bgpH [ixNet getL $vport_protocols bgp]
                    if {[ixNet getA $bgpH  -enabled] == "true" } {
                        lappend device_list $bgpH
                    }
                }
                isis {
                    set isisH [ixNet getL $vport_protocols isis]
                    if {[ixNet getA $isisH  -enabled] == "true" } {
                        lappend device_list $isisH
                    }
                }
                ldp {
                    set ldpH [ixNet getL $vport_protocols ldp]
                    if {[ixNet getA $ldpH  -enabled] == "true" } {
                        lappend device_list $ldpH
                    }
                }
				igmp {
                    set igmpH [ixNet getL $vport_protocols igmp]
                    if {[ixNet getA $igmpH  -enabled] == "true" } {
                        lappend device_list $igmpH
                    }
                }
				mld {
                    set mldH [ixNet getL $vport_protocols mld]
                    if {[ixNet getA $mldH  -enabled] == "true" } {
                        lappend device_list $mldH
                    }
                }
				rip {
                    set ripH [ixNet getL $vport_protocols rip]
                    if {[ixNet getA $ripH  -enabled] == "true" } {
                        lappend device_list $ripH
                    }
                }
				ripng {
                    set ripngH [ixNet getL $vport_protocols ripng]
                    if {[ixNet getA $ripngH  -enabled] == "true" } {
                        lappend device_list $ripngH
                    }
                }
                ospf -
                ospfv2 {
                    set ospfH [ixNet getL $vport_protocols ospf]
                    if {[ixNet getA $ospfH  -enabled] == "true" } {
                        lappend device_list $ospfH
                    }
                }
                ospfv3 {
                    set ospfV3H [ixNet getL $vport_protocols ospfV3]
                    if {[ixNet getA $ospfV3H  -enabled] == "true" } {
                        lappend device_list $ospfV3H
                    }
                }
				bfd {
                    set bfdH [ixNet getL $vport_protocols bfd]
                    if {[ixNet getA $bfdH  -enabled] == "true" } {
                        lappend device_list $bfdH
                    }
                }
                rsvp {
                    set rsvpH [ixNet getL $vport_protocols rsvp]
                    if {[ixNet getA $rsvpH  -enabled] == "true" } {
                        lappend device_list $rsvpH
                    }
                }
                dhcp {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {	
							set dhcpH [ixNet getL $ethernetH dhcpEndpoint]
							if { $dhcpH != "" } {
								lappend device_list $ethernetH
							}                                               
						}
					}
                   
                }
                pppox {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {	
							set pppoxH [ixNet getL $ethernetH pppoxEndpoint]
							if { $pppoxH != "" } {
								lappend device_list $ethernetH
							}                                               
						}
					}
                }
                l2tp {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {	
							set ipH [ixNet getL $ethernetH ip]
							if { $ipH != "" } {
                                set l2tpH [ixNet getL $ipH l2tpEndpoint]
                                if { $l2tpH !="" } {
                                    lappend device_list $ethernetH
                                }
								
							}                                               
						}
					}
                }
				pim {
					set pimH [ixNet getL $vport_protocols pimsm]
					if { [ ixNet getA $pimH -enabled ] == "true" } {
						lappend device_list $pimH
					}
				}
            }
        }
        
		switch -exact -- $device_type {
		    dhcp -
		    l2tp -
		    pppox {
		        ixNet exec start $device_list
                   
            }
			default {
		        foreach deviceH $device_list {
                    ixNet exec start $deviceH
                }
			}
		}
        # foreach deviceH $device_list {
            # ixNet exec start $deviceH
        # }
	
    }
	
    return [ GetStandardReturnHeader ]
}

proc Tester::stop_router { args } {
    set tag "proc Tester::stop_router [info script]"
    Deputs "----- TAG: $tag -----"
    
	#ixTclNet::StopProtocols
    #ixNet exec stopAllProtocols
    set device_type ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -device_type {
                set device_type [string tolower $value]
            }

        }
    }
    
#	ixTclNet::StartProtocols
    if { $device_type == ""} {
        ixNet exec stopAllProtocols
    } else {
        set device_list ""
        set root [ixNet getRoot]
        set vport_list [ixNet getL $root vport]
        foreach vport_handle $vport_list {
            set vport_protocols     [ixNet getL $vport_handle protocols]
            set vport_protocolStack [ixNet getL $vport_handle protocolStack]
            
            switch -exact -- $device_type {
                bgp {                    
                    set bgpH [ixNet getL $vport_protocols bgp]
                    if {[ixNet getA $bgpH  -enabled] == "true" } {
                        lappend device_list $bgpH
                    }
                }
                isis {
                    set isisH [ixNet getL $vport_protocols isis]
                    if {[ixNet getA $isisH  -enabled] == "true" } {
                        lappend device_list $isisH
                    }
                }
                ldp {
                    set ldpH [ixNet getL $vport_protocols ldp]
                    if {[ixNet getA $ldpH  -enabled] == "true" } {
                        lappend device_list $ldpH
                    }
                }
				igmp {
                    set igmpH [ixNet getL $vport_protocols igmp]
                    if {[ixNet getA $igmpH  -enabled] == "true" } {
                        lappend device_list $igmpH
                    }
                }
				mld {
                    set mldH [ixNet getL $vport_protocols mld]
                    if {[ixNet getA $mldH  -enabled] == "true" } {
                        lappend device_list $mldH
                    }
                }
				rip {
                    set ripH [ixNet getL $vport_protocols rip]
                    if {[ixNet getA $ripH  -enabled] == "true" } {
                        lappend device_list $ripH
                    }
                }
				ripng {
                    set ripngH [ixNet getL $vport_protocols ripng]
                    if {[ixNet getA $ripngH  -enabled] == "true" } {
                        lappend device_list $ripngH
                    }
                }
                ospf -
                ospfv2 {
                    set ospfH [ixNet getL $vport_protocols ospf]
                    if {[ixNet getA $ospfH  -enabled] == "true" } {
                        lappend device_list $ospfH
                    }
                }
                ospfv3 {
                    set ospfV3H [ixNet getL $vport_protocols ospfV3]
                    if {[ixNet getA $ospfV3H  -enabled] == "true" } {
                        lappend device_list $ospfV3H
                    }
                }
                bfd {
                    set bfdH [ixNet getL $vport_protocols bfd]
                    if {[ixNet getA $bfdH  -enabled] == "true" } {
                        lappend device_list $bfdH
                    }
                }
                rsvp {
                    set rsvpH [ixNet getL $vport_protocols rsvp]
                    if {[ixNet getA $rsvpH  -enabled] == "true" } {
                        lappend device_list $rsvpH
                    }
                }
                dhcp {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {							
							set dhcpH [ixNet getL $ethernetH dhcpEndpoint]
							if { $dhcpH != "" } {
								lappend device_list $ethernetH
							}                                               							
						}
					}
                   
                }
                pppox {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {	
							set pppoxH [ixNet getL $ethernetH pppoxEndpoint]
							if { $pppoxH != "" } {
								lappend device_list $ethernetH
							} 
                        }						
                    }
                }

            }
        }
		
		switch -exact -- $device_type {
		    dhcp -
		    l2tp -
		    pppox {
		        ixNet exec stop $device_list
                   
            }
			default {
		        foreach deviceH $device_list {
                    ixNet exec stop $deviceH
                }
			}
		}
        
        # foreach deviceH $device_list {
            # ixNet exec stop $deviceH
        # }
	
    }
    return [ GetStandardReturnHeader ]
}

proc Tester::abort_router { args } {
    set tag "proc Tester::abort_router [info script]"
    Deputs "----- TAG: $tag -----"
    
	#ixTclNet::StopProtocols
    #ixNet exec stopAllProtocols
    set device_type ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -device_type {
                set device_type [string tolower $value]
            }

        }
    }
    
#	ixTclNet::StartProtocols
    if { $device_type == ""} {
        ixNet exec stopAllProtocols
    } else {
        set device_list ""
        set root [ixNet getRoot]
        set vport_list [ixNet getL $root vport]
        foreach vport_handle $vport_list {
            set vport_protocols     [ixNet getL $vport_handle protocols]
            set vport_protocolStack [ixNet getL $vport_handle protocolStack]
            
            switch -exact -- $device_type {
                bgp {                    
                    set bgpH [ixNet getL $vport_protocols bgp]
                    if {[ixNet getA $bgpH  -enabled] == "true" } {
                        lappend device_list $bgpH
                    }
                }
                isis {
                    set isisH [ixNet getL $vport_protocols isis]
                    if {[ixNet getA $bgpH  -enabled] == "true" } {
                        lappend device_list $isisH
                    }
                }
                ldp {
                    set ldpH [ixNet getL $vport_protocols ldp]
                    if {[ixNet getA $ldpH  -enabled] == "true" } {
                        lappend device_list $ldpH
                    }
                }
				igmp {
                    set igmpH [ixNet getL $vport_protocols igmp]
                    if {[ixNet getA $igmpH  -enabled] == "true" } {
                        lappend device_list $igmpH
                    }
                }
				mld {
                    set mldH [ixNet getL $vport_protocols mld]
                    if {[ixNet getA $mldH  -enabled] == "true" } {
                        lappend device_list $mldH
                    }
                }
				rip {
                    set ripH [ixNet getL $vport_protocols rip]
                    if {[ixNet getA $ripH  -enabled] == "true" } {
                        lappend device_list $ripH
                    }
                }
				ripng {
                    set ripngH [ixNet getL $vport_protocols ripng]
                    if {[ixNet getA $ripngH  -enabled] == "true" } {
                        lappend device_list $ripngH
                    }
                }
                ospf -
                ospfv2 {
                    set ospfH [ixNet getL $vport_protocols ospf]
                    if {[ixNet getA $ospfH  -enabled] == "true" } {
                        lappend device_list $ospfH
                    }
                }
                ospfv3 {
                    set ospfV3H [ixNet getL $vport_protocols ospfV3]
                    if {[ixNet getA $ospfV3H  -enabled] == "true" } {
                        lappend device_list $ospfV3H
                    }
                }
                dhcp {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {							
							set dhcpH [ixNet getL $ethernetH dhcpEndpoint]
							if { $dhcpH != "" } {
								lappend device_list $ethernetH
							}                                               							
						}
					}
                   
                }
                pppox {
                    set ethernetH_list [ixNet getL $vport_protocolStack ethernet ]
					if {$ethernetH_list != "" } {
						foreach ethernetH $ethernetH_list {	
							set pppoxH [ixNet getL $ethernetH pppoxEndpoint]
							if { $pppoxH != "" } {
								lappend device_list $ethernetH
							} 
                        }						
                    }
                }

            }
        }
        
        switch -exact -- $device_type {
		    dhcp -
		    l2tp -
		    pppox {
		        ixNet exec stop $device_list
                   
            }
			default {
		        foreach deviceH $device_list {
                    ixNet exec stop $deviceH
                }
			}
		}
        
        # foreach deviceH $device_list {
            # ixNet exec abort $deviceH
        # }
    }
    return [ GetStandardReturnHeader ]
}

proc Tester::start_routers { router } {
    set tag "proc Tester::start_routers [info script]"
Deputs "----- TAG: $tag -----"
    
	foreach rt $router {
		if { [ $rt isa EmulationNgpfObject ] == 0 } {
			return [ GetErrorReturnHeader "$rt is not a valid object." ]
		}
	}
	
	foreach rt $router {
		$rt start
	}
	return [ GetStandardReturnHeader ]
}

proc Tester::stop_routers { router } {
    set tag "proc Tester::stop_routers [info script]"
    Deputs "----- TAG: $tag -----"
    
		foreach rt $router {
			if { [ $rt isa EmulationNgpfObject ] == 0 } {
				return [ GetErrorReturnHeader "$rt is not a valid object." ]
			}
		}
		
		foreach rt $router { 
			$rt stop
		}
		return [ GetStandardReturnHeader ]
}

proc Tester::start_capture { args } {
    set tag "proc Tester::start_capture [info script]"
    Deputs "----- TAG: $tag -----"

    set close_captures ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -ports {
                set portList $value
            }
            -close_captures {
                set close_captures $value
            }
        }
    }

	if { [ info exists portList ] == 0 } {
		set root [ixNet getRoot]
		set portList [ ixNet getL $root vport ]
	} else {
		
		set hPortList [ list ]
		foreach port $portList {
			set hPort [ $port cget -handle ]
			lappend hPortList $hPort
		}
		set portList $hPortList
	}
    Deputs "capture port handle list:$portList"

	foreach hPort $portList {
		set hardwareEnb [ixNet getA $hPort/capture -hardwareEnabled]
		set softwareEnb [ixNet getA $hPort/capture -softwareEnabled]
		if {$hardwareEnb == "False" && $softwareEnb == "False"} {
			ixNet setA $hPort/capture  -hardwareEnabled True
		}
		ixNet commit
		
        Deputs "Port rx mode on $hPort : [ ixNet getA $hPort -rxMode ]"	
		if { [ ixNet getA $hPort -rxMode ] == "captureAndMeasure" } {
			continue
		}
		ixNet setA $hPort -rxMode capture
		ixNet commit
        Deputs "Port rx mode on $hPort : [ ixNet getA $hPort -rxMode ]"	

		while { [ixNet getA $hPort -state] != "up" } {
			after 1000
		}

	}


	# clear all the captuer content
	foreach obj [ find objects ]  {
		set isCaptureObj [ $obj isa Capture ]
		if { $isCaptureObj } {
			$obj configure -content [list]
		}
	}
    
    if { $close_captures == "" } {
        ixNet exec closeAllTabs
    } else {
        ixNet exec closeAllTabs $close_captures
    }

    Deputs "start capture..."
	ixNet exec startCapture
	after 3000
	
    return [ GetStandardReturnHeader ]
}

proc Tester::stop_capture { { wait 3000 } args } {
    set tag "proc Tester::stop_capture [info script]"
    Deputs "----- TAG: $tag -----"
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -ports {
                set portList $value
            }
        }
    }
    if { [ info exists portList ] != 0 } {
        set savelist ""
        foreach obj [  find objects ] {
            if { [$obj isa Capture] } {
                if { [lsearch  $portList [$obj cget -portObj]] != -1 } {
                    ixNet exec stop [$obj cget -handle]
                    if { [$obj cget -capfile] != "" } {
                        lappend savelist $obj

                    }                    
                }
            }
        }
        after $wait
        foreach cap $savelist {
            $cap save_file
        }

       
    } else {

        ixNet exec stopCapture
        # set root [ixNet getRoot]
        # set portList [ ixNet getL $root vport ]
        # foreach hPort $portList {
            # Deputs "hPort:$hPort"
            # # ixNet setA $hPort/capture/filter	-captureFilterDA anyAddr
            # # ixNet setA $hPort/capture/filter	-captureFilterSA anyAddr
            # # ixNet setA $hPort/capture/filter	-captureFilterPattern anyPattern
            # # ixNet setA $hPort/capture/filter	-captureFilterFrameSizeEnable False
            # ixNet setA $hPort/capture    		-hardwareEnabled False
            # # ixNet setA $hPort/capture    -softwareEnabled False
            # ixNet commit
            # # after 1000
        # }
        after $wait
        set caplist ""
        foreach obj [  find objects ] {
            if { [$obj isa Capture] } {
                if { [$obj cget -capfile] != "" } {
                    lappend caplist $obj

                }
            }
        }
        Deputs "caplist: $caplist"
        if { $caplist != "" } {
            foreach cap $caplist {
                $cap save_file
            }
        }
        # catch { show_control_capture }
    }
    
    return [ GetStandardReturnHeader ]
}


#--
# Save Capture
#--
# Parameters: |key, value|
#       - capture_dir: Directory which we'll put the capture files
#       - suffix: Suffix name appended to capture file name
# Return:
#        0 if got success
#        raise error if failed 
#-- 
proc Tester::save_capture { args } {
    set tag "proc Tester::stop_capture [info script]"
    Deputs "----- TAG: $tag -----"
    
    set capture_dir [ pwd ]
    set suffix ""
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -capture_dir {
                set capture_dir $value
            }
            -suffix {
                set suffix $value
            }
        }
    }
    
    if { ![ file exists $capture_dir ] } {
        file mkdir $capture_dir
    }
    
    if { $suffix == "" } {
        ixNet exec saveCapture $capture_dir
    } else {
        ixNet exec saveCapture $capture_dir $suffix
    }
    
    return [ GetStandardReturnHeader ]
}

proc Tester::clear_capture {} {
    set tag "proc Tester::clear_capture [info script]"
    Deputs "----- TAG: $tag -----"
	ixNet exec closeAllTabs
    return [ GetStandardReturnHeader ]
}

proc Tester::show_control_capture {} {
    set tag "proc Tester::show_control_capture [info script]"
Deputs "----- TAG: $tag -----"

	set root [ixNet getRoot]
	set portList [ ixNet getL $root vport ]
Deputs "==SHOW CONTROL CAPTURE CONTENT=="
	foreach hPort $portList {
		set pktCount [ ixNet getA $hPort/capture -controlPacketCounter ]
		if { [ string is integer $pktCount ] == 0 } {
			continue
		}
		if { $pktCount } {
			Deputs "PORT = [ixNet getA $hPort -connectionInfo], Packet Count = $pktCount"
		} else {
			continue
		}
		#-- round robin the frame
		for { set index 0 } { $index < $pktCount } { incr index } {
			Deputs "PACKET INDEX = # $index"
			ixNet exec getPacketFromControlCapture $hPort/capture/currentPacket $index
			#-- round robin the stack
			foreach hStack [ ixNet getL $hPort/capture/currentPacket stack ] {
				Deputs "Protocol = [ixNet getA $hStack -displayName]"
				#-- round robin the field
				foreach hField [ixNet getL $hStack field] {
					Deputs "\tField = [ixNet getA $hField -displayName], Value = [ixNet getA $hField -fieldValue]"
				}
			}
		}
	}

	
}

proc Tester::cleanup { args } {
# IxDebugOn

    set tag "proc Tester::cleanup [info script]"
Deputs "----- TAG: $tag -----"

    set release_port 0
	set reboot_port 0
	set new_config 1
	
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -release_port {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set release_port $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
			-reboot_port {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set reboot_port $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
				
			}
			-new_config {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set new_config $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
				
			}
            default {
                error "$errNumber(3) key:$key value:$value"
            }
        }
    }
    #############################
    ixNet exec stopAllProtocols
    after 3000
    ##############################
	if { $new_config } {
		ixNet exec newConfig
	}
	set objects [ find objects ]
Deputs "objects:$objects"
	foreach obj $objects {
Deputs "obj:$obj"
		if { [ catch {
			if { [ $obj isa NetNgpfObject ] } {
Deputs Step10
				if { [ $obj isa Port ] } {
Deputs Step20
					set location [ $obj cget -location ]
Deputs "location:$location"
					if { $reboot_port } {
						set portInfo [ split $location "/" ]
						set chas [ lindex $portInfo 0 ] 
						set card [ lindex $portInfo 1 ] 
						set port [ lindex $portInfo 2 ] 
						ixConnectToChassis $chas
						chassis get $chas
						set chas [ chassis cget -id ]
						SmbPortReboot $chas $card $port
					}
					if { $new_config } {
						if { $release_port == 0 } {
	Deputs "obj: $obj location:$location"
                            if { $new_config } {
                                $obj reset_handle
                            }
							$obj Connect $location
						}
					}
				} else {
Deputs Step30
					$obj unconfig
					#delete object $obj
				}
			} else {
				continue
			}
		} err ] } { 
Deputs $err
		continue 
		}
	}
	ixNet commit

    return [ GetStandardReturnHeader ]
}

proc Tester::delete_pppoe { args } {
# IxDebugOn

    set tag "proc Tester::delete_pppoe [info script]"
Deputs "----- TAG: $tag -----"

    #############################
    ixNet exec stopAllProtocols
    ##############################
    
    set objects [ find objects ]
Deputs "objects:$objects"
	foreach obj $objects {
Deputs "obj:$obj"
		if { [ catch {
			if { [ $obj isa PppoeHost ] } {
					$obj unconfig
					#delete object $obj
				
			} else {
				continue
			}
		} err ] } { 
Deputs $err
		continue 
		}
	}
	ixNet commit
}

proc Tester::apply_traffic {} {
	set tag "proc Tester::apply_traffic [info script]"
  Deputs "----- TAG: $tag -----"
	
    set flag 0
	set root [ixNet getRoot]
	set portList [ ixNet getL $root vport ]
    set version [ixNet getVersion]
	Deputs "The ixNetwork version is: $version"
			
    foreach hPort $portList {
        if {[string match 6.0* $version]} {
            if { [ ixNet getA $hPort/capture    -hardwareEnabled  ] } {
                ixNet exec stopCapture
                set flag 1
                after 1000
                break
            }
        } else {
            if { [ ixNet getA $hPort/capture   -isCaptureRunning  ] } {
                ixNet exec stopCapture
                set flag 1
                after 1000
                break
            }
        }
      
    }
  
	
	ixNet setAttribute ::ixNet::OBJ-//traffic -refreshLearnedInfoBeforeApply true
	ixNet commit
    ixNet exec apply ::ixNet::OBJ-//traffic
   
    after 1000
    
    if { $flag } {
        ixNet exec startCapture
        after 1000
    }
    
    return [ GetStandardReturnHeader ]
}

proc Tester::generate_traffic {} {
	set tag "proc Tester::generate_traffic [info script]"
Deputs "----- TAG: $tag -----"

	set root [ixNet getRoot]
	set it_handles [ ixNet getL $root/traffic trafficItem ]
		#-- generate traffic
	foreach handle $it_handles {
        if { [ixNet getA $handle -enabled] == "true" } {
		   catch {
			ixNet exec generate $handle
			
	Deputs "Wait for generate traffic"	
		   }
	    }
	}
	
    return [ GetStandardReturnHeader ]

}

proc Tester::synchronize {} {
    set tag "proc Tester::synchronize [info script]"
Deputs "----- TAG: $tag -----"

#	set root [ixNet getRoot]
#	set it_handles [ ixNet getL $root/traffic trafficItem ]
#		#-- generate traffic
#	foreach handle $it_handles {
#		ixNet exec generate $handle
#Deputs "Wait for generate traffic"	
#	}

#	ixTclNet::ApplyTraffic

    return [ GetStandardReturnHeader ]
}

proc Tester::clear_traffic_stats {} {
  set tag "proc Tester::clear_traffic_stats [info script]"
	Deputs "----- TAG: $tag -----"
	catch { ixNet exec clearStats }
	return [ GetStandardReturnHeader ]
}

proc Tester::get_log { { file default } } {
	set tag "proc Tester::get_log [info script]"
Deputs "----- TAG: $tag -----"
	if { $file == "default" } {
Deputs Step10
		set currDir [file dirname [info script]]
		set file "$currDir/[clock seconds].zip"
	}
Deputs "file path:$file"
	ixNet exec collectLogs [ ixNet writeTo $file -ixNetRelative ]	
	return [ GetStandardReturnHeader ]
}

proc Tester::flap_router { args } {
	
	set tag "proc Tester::get_log [info script]"
Deputs "----- TAG: $tag -----"

	set times 1
	set a2w 10
	set w2a 10
	set end_up_dn 1
	
	Deputs "Args:$args "
	foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-a2w {
				set trans [ TimeTrans $value ]
				set a2w $trans
			}
			-w2a {
				set trans [ TimeTrans $value ]
				set w2a $trans
			}
			-duration {
				set trans [ TimeTrans $value ]
				set duration $trans
			}
			-times {
				set times $value  	    	
			}
			-end_up_dn {
				set end_up_dn $value
			}
			-router {
				set router $value
			}
	    }
	}	
	
	if { [ info exists router ] } {
		start_routers $router
		if { [ info exists duration ] } {
			set now [ clock seconds ]
			while { [ expr [ clock seconds ] - $now ] < $duration } {
Deputs "stop R..."
				stop_routers $router
Deputs "W2A..."
				after [ expr 1000*$w2a ]
Deputs "start R..."
				start_routers $router
eputs "A2W..."
				after [ expr 1000*$a2w ]
			}
		} else {
			for { set index 0 } { $index < $times } { incr index } {
Deputs "stop R..."
				stop_routers $router
Deputs "W2A..."
				after [ expr 1000*$w2a ]
Deputs "start R..."
				start_routers $router
Deputs "A2W..."
				after [ expr 1000*$a2w ]
			}
		}
		
		if { $end_up_dn } {
			start_routers $router
		} else {
			stop_routers $router
		}
	} else {
		start_router
		if { [ info exists duration ] } {
			set now [ clock seconds ]
			while { [ expr [ clock seconds ] - $now ] < $duration } {
Deputs "stop R..."
				stop_router
Deputs "W2A..."
				after [ expr 1000*$w2a ]
Deputs "start R..."
				start_router
Deputs "A2W..."
				after [ expr 1000*$a2w ]
			}
		} else {
			for { set index 0 } { $index < $times } { incr index } {
Deputs "stop R..."
				stop_router
Deputs "W2A..."
				after [ expr 1000*$w2a ]
Deputs "start R..."
				start_router
Deputs "A2W..."
				after [ expr 1000*$a2w ]
			}
		}
		
		if { $end_up_dn } {
			start_router
		} else {
			stop_router
		}
	}
	return [ GetStandardReturnHeader ]
	
}

proc Tester::save_config { { config_file "d:/configfile.ixncfg" } } {
   set tag "proc Tester::save_config [info script]"
    Deputs "----- TAG: $tag -----"

	# set config_file "d:/configfile.ixncfg" 

    # foreach { key value } $args {
        # set key [string tolower $key]
        # switch -exact -- $key {
            # -config_file {
                # set config_file $value
            # }
        # }
    # }
	
    set  result [ixNet exec  saveConfig [ixNet writeTo $config_file  -overwrite]]
	return [ GetStandardReturnHeader ]

}


proc Tester::remove_all_stream {} {
   set tag "proc Tester::remove_all_stream [info script]"
    Deputs "----- TAG: $tag -----"
	foreach obj [ find objects ] {
		if { [ $obj isa Traffic ] } {
			$obj unconfig
		}
	}
	return [ GetStandardReturnHeader ]
}

proc Tester::isLossFrames { { streams "" } { acceptloss 0} } {
    set tag "proc Tester::isLossFrames  [info script]"
	Deputs "----- TAG: $tag -----"
    
	set lossFrames 0
    if { $streams == "" } {
        if { [llength $streams] == 0 } {
            set objects [find objects]
            foreach obj $objects {
                if { [$obj isa Traffic] } {
                    lappend streams $obj
                }
            }
        }
    }
	foreach obj $streams {
        set traffic_name [ ixNet getA [ $obj cget -handle ] -name ]
        #set traffic_name [ ixNet getA $obj -name ]
        Deputs "Traffic obj: $traffic_name"
        set results [ $obj get_stats ]
        set tx [ GetStatsFromReturn $results tx_frame_count ]
        set rx [ GetStatsFromReturn $results rx_frame_count ]
        set frames [expr $tx - $rx]
        set tmpFrames $lossFrames
        set lossFrames [expr $lossFrames*1.0 + $frames*1.0]
        if { $frames >= 0 && $tmpFrames >= 0 && $lossFrames < 0 } {
            Deputs "Oops!!! Overflow happens during test!! tx:$tx, rx:$rx, tmpFrames:$tmpFrames, lossFrames:$lossFrames"
            return true
        }
        Deputs "Port: [ixNet getA [$obj cget -handle] -name], Tx Frame Count: $tx, Rx Frame Count: $rx, Balance Frames: $lossFrames"
	}
    Deputs "Total Loss Frames: $lossFrames"
    if { $lossFrames > $acceptloss } {
        return true
    }
	return false
}

proc Tester::saveResults { args } {
    set tag "proc Tester::saveResults [info script]"
    Deputs "----- TAG: $tag -----"
    
	Deputs "Args:$args "
    set appended false
    set streams [list]
	foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-resultfile {
				set resultfile $value
			}
			-frame_size {
				set frame_size $value
			}
            -streams {
                set streams $value
            }
            -append {
                set appended $value
            }
        }
    }
    
    if { !$appended } {
        if { [ file exists $resultfile ] } {
            file delete $resultfile
        }
    }
    
    if { [llength $streams] == 0 } {
        set objects [find objects]
        foreach obj $objects {
            if { [$obj isa Traffic] } {
                lappend streams $obj
            }
        }
    }
    set lossFrames 0
    foreach obj $streams {
        set traffic_name [ ixNet getA [ $obj cget -handle ] -name ]
        #set traffic_name [ ixNet getA $obj -name ]
        Deputs "Traffic obj: $traffic_name"
        catch {
            set highLevelStream [ $obj cget -highLevelStream ]
			set highLevelStream [lindex $highLevelStream 0]
            set frameSize [ ixNet getL $highLevelStream frameSize ]
            set frame_size [ ixNet getA $frameSize -fixedSize ]
            Deputs "Traffic frame size: $frame_size"
        }
        set retResults [ $obj get_stats ]
        set captions "Traffic Item, Frame Size, Tx Frames, Rx Frames, Store-Forward Avg Latency (ns), Store-Forward Min Latency (ns), Store-Forward Max Latency (ns), First TimeStamp, Last TimeStamp"
        set values "$traffic_name,$frame_size,[GetStatsFromReturn $retResults tx_frame_count],[GetStatsFromReturn $retResults rx_frame_count],[GetStatsFromReturn $retResults avg_latency],[GetStatsFromReturn $retResults min_latency],[GetStatsFromReturn $retResults max_latency],[GetStatsFromReturn $retResults first_arrival_time],[GetStatsFromReturn $retResults last_arrival_time]"
        
        set lossFrames [expr $lossFrames*1.0 + ([GetStatsFromReturn $retResults tx_frame_count] - [GetStatsFromReturn $retResults rx_frame_count])]
        if { [ file exists $resultfile ] } { 
            set fid [open $resultfile a]
        } else {
            set fid [open $resultfile w]
            puts $fid $captions
        }
        puts $fid $values
        close $fid
    }
	
    if { [ file exists $resultfile ] } { 
        set fid [open $resultfile a]
        puts $fid "Total Frame Loss"
        puts $fid $lossFrames
        close $fid
    }
    return [ GetStandardReturnHeader ]
}


proc Tester::set_stats_mode { args } {
	set tag "proc Tester::set_stats_mode [info script]"
Deputs "----- TAG: $tag -----"
    Deputs "Args:$args "
  
	foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-mode {
				set mode [string tolower $value]
			}
        }
    }
    
    set root [ixNet getRoot]
    
    if { [ info exists mode ] } {
		switch $mode {
			latency_jitter {
				ixNet setMultiAttribute $root/traffic/statistics/latency -enabled false
                ixNet commit
                ixNet setMultiAttribute $root/traffic/statistics/delayVariation \
                    -enabled true \
                    -statisticsMode rxDelayVariationAverage \
                    -latencyMode storeForward
                ixNet commit
			}
			jitter {
				ixNet setMultiAttribute $root/traffic/statistics/latency -enabled false
                ixNet commit
                ixNet setMultiAttribute $root/traffic/statistics/delayVariation \
                    -enabled true \
                    -statisticsMode rxDelayVariationErrorsAndRate \
                    -latencyMode storeForward
                ixNet commit
			}
			basic {
				ixNet setA $root/traffic/statistics/delayVariation \
                   -enabled false 
                ixNet commit
            
                ixNet setA $root/traffic/statistics/latency -enabled true
                ixNet commit
			}
		}
		
	}
	
	return [ GetStandardReturnHeader ]
}

proc Tester::tester_config_file { filedir } {
    set tag "proc Tester::tester_config_file [info script]"
Deputs "----- TAG: $tag -----"
    
    global testerConfigFile
    set testerConfigFile $filedir
 }
 
proc Tester::run_testcomposer { } {
    set tag "proc Tester::run_testcomposer [info script]"
Deputs "----- TAG: $tag -----"
    
    ixNet exec start ::ixNet::OBJ-/eventScheduler/program:"Main_Procedure"
    return [ GetStandardReturnHeader ]
 }
 
proc Tester::start_arp_nd { } {
    set tag "proc Tester::start_arp_nd [info script]"
Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
    set vportList [ixNet getL $root vport]
    set intList ""
    foreach hVport $vportList {
        set temp [ixNet getL $hVport interface ]
        if { $temp !="" } {
            set intList [ concat $intList $temp]
        }
    }
    if { $intList != "" } {
        foreach int $intList {
            ixNet execs sendArpAndNS $int
        }
        after 1000
    }
    return [ GetStandardReturnHeader ]
}
 
proc Tester::port_map { args } {
    set tag "proc Tester::port_map[info script]"
Deputs "----- TAG: $tag -----"
    global loadconfig_src_ip
    global loadconfig_src_pid
    global loadconfig_dst_ip
    global loadconfig_dst_pid
    global ChangePortMap
    
    set ChangePortMap 1
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -src_ip {
                set loadconfig_src_ip  $value
            }
            -src_pid {
                set loadconfig_src_pid $value
            }
            -dst_ip {
                set loadconfig_dst_ip $value
            }
            -dst_pid {
                set loadconfig_dst_pid $value
            }

        }
    }
    
    #modify port map 
    set root [ixNet getRoot]
    set portlist [ixNet getL $root vport]
    
    set removeChas 0
    set chasList [ixNet getList $root/availableHardware chassis]
    set hostnameList [list]
    foreach chas $chasList {
        set hostname [ixNet getA $chas -hostname]
        lappend hostnameList $hostname
    }
    if { [lsearch $hostname $loadconfig_dst_ip] == -1} {
        set chas [ixNet add $root/availableHardware chassis]
        ixNet setA $chas -hostname $loadconfig_dst_ip
        ixNet commit
        set chas [ixNet remapIds $chas]
        set removeChas 1
    }
    set chasH [ixNet getF ::ixNet::OBJ-/availableHardware chassis -hostname $loadconfig_dst_ip]
    foreach hport $portlist {
                               
        set assignInfo [ixNet getA  $hport -assignedTo]
        set locationInfo [ split $assignInfo ":" ]
        set chassis     [ lindex $locationInfo 0 ]
        set ModuleNo    [ lindex $locationInfo 1 ]
        set PortNo      [ lindex $locationInfo 2 ]
        
        set index [lsearch $loadconfig_src_pid   ${ModuleNo}/${PortNo} ]
        if { $index != -1 } {
            set dst [lindex $loadconfig_dst_pid $index]
            set dst [ split $dst "/" ]
            set ModuleNo    [ lindex $dst 0 ]
            set PortNo      [ lindex $dst 1 ]
            set realPort $chasH/card:$ModuleNo/port:$PortNo
       
            ixNet exec releasePort $hport
            after 1000  
           
            ixNet setA $hport -connectedTo $realPort
            ixNet commit
        } else {
            error "no match port find for pid ${ModuleNo}/${PortNo} "
        }
       
    }
    if { $removeChas } {
        set chasH [ixNet getF ::ixNet::OBJ-/availableHardware chassis -hostname $loadconfig_src_ip]
        ixNet remove $chasH
        ixNet commit
    }
    
    
    return [ GetStandardReturnHeader ]
}


proc Tester::assign_all { args } {
    set tag "proc Tester::assign_all[info script]"
Deputs "----- TAG: $tag -----"
   

   
    Deputs "Args:$args "
    global assign_portNameList 
    global assign_portLocationList 
    global assign_vportList
    global assign_enable_flow_control
    global assign_realportList
    set assign_enable_flow_control "false"
  
	foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-portnamelist {
				set assign_portNameList $value
			}
            -portlocationlist {
				set assign_portLocationList $value
			}
            -enable_flow_control {
				set assign_enable_flow_control  $value
			}
            
        }
    }
    uplevel {
        foreach portName $assign_portNameList {
            Port $portName NULL NULL NULL 
            lappend assign_vportList [$portName cget -handle]
        }
        
        foreach  portLocation $assign_portLocationList {
            lappend assign_realportList [split $portLocation "/" ]
        }
        #ixTclNet::AssignPorts $assign_realportList {} $assign_vportList force
        ixNet -strip exec assignPorts $assign_realportList {} $assign_vportList "true"
        
        # foreach portName $assign_portNameList {
            # $portName config -flow_control $assign_enable_flow_control
            
        # }
    }
    
    return [ GetStandardReturnHeader ]

}

proc Tester::save_result { args } {
    set tag "proc Tester::save_result[info script]"
Deputs "----- TAG: $tag -----"
     
    Deputs "args:$args "
    set type "trafficitem"
    foreach { key value } $args {
	    set key [string tolower $key]
	    switch -exact -- $key {
			-pathname {
				set pathname $value
			}
            -type {
				set type [string tolower $value]
			}           
        }
    }
    set desfile [open $pathname w+]
    close $desfile
    set desfile [open $pathname a]
    if { $type == "trafficitem"} {
        set view {::ixNet::OBJ-/statistics/view:"Traffic Item Statistics"}
    } else {
        set view {::ixNet::OBJ-/statistics/view:"Flow Statistics"}
    }
    set captionList    [ ixNet getA $view/page -columnCaptions ]
    set rpattern ""
    foreach element $captionList {
        if {$rpattern != ""} {
           set rpattern "$rpattern,$element"
        } else {
            set rpattern $element
        }
    }
    puts $desfile $rpattern
    #close $desfile
    
    set stats [ ixNet getA $view/page -rowValues ]
    Deputs "stats: $stats"
    foreach row $stats {
        eval {set row} $row
        set rpattern ""
        foreach element $row {
            if {$rpattern != ""} {
               set rpattern "$rpattern, $element"
            } else {
                set rpattern " $element"
            }
        }
        puts $desfile $rpattern
    }
    close $desfile
}