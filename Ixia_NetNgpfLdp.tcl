
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
    inherit RouterNgpfEmulationObject
    public variable handle	
	public variable version
	public variable ldpInterface    

    constructor {  port } {
		global errNumber
		set tag "body LdpSession::ctor [info script]"
Deputs "----- TAG: $tag -----"
        set portObj [ GetObject $port ]
        set handle ""
        reborn		
	
	}

	method reborn {} {
	    global errNumber
		global rb_interface
	
		set tag "body LdpSession::reborn [info script]"
		set version "ipv4"
		set ip_version $version
		if { [ catch {
            set hPort   [ $portObj cget -handle ]
        } ] } {
            error "$errNumber(1) Port Object in LdpSession ctor"
        }

		#-- add interface and ldp protocol

		set topoObjList [ixNet getL [ixNet getRoot] topology]
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
							set handle [ixNet add $ipv4Obj ldpBasicRouter]
                            ixNet commit
                            set handle [ ixNet remapIds $handle ]
                        }
				    }
			    }
                break
            }
        }
		if { [ llength $topoObjList ] == 0 } {
		    set topoObjList [ixNet getL [ixNet getRoot] topology]
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
            set handle [ixNet add $ipv4Obj ldpBasicRouter]
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
							if { [info exists ipv4Obj] && $ipv4Obj != "" && $ip_version == "ipv4" } {                                
								set handle [ixNet getL $ipv4Obj ldpBasicRouter]
								if {[llength $handle] != 0} {
									set handle [ ixNet remapIds $handle ]
								} else {
									set handle [ixNet add $ipv4Obj ldpBasicRouter]
									ixNet commit
									set handle [ ixNet remapIds $handle ]
								}
							} else {
								if { [info exists ipv6Obj] && $ipv6Obj != "" } {
									set handle [ixNet getL $ipv6Obj ldpBasicRouterV6]
									if {[llength $handle] != 0} {
										set handle [ ixNet remapIds $handle ]
									} else {
										set handle [ixNet add $ipv6Obj ldpBasicRouterV6]
										ixNet commit
										set handle [ ixNet remapIds $handle ]
									}
								}
							}
						}
					}
				}
			}
		}
		#Enable protocol 	
		set ipPattern [ixNet getA [ixNet getA $handle -active] -pattern]
		SetMultiValues $handle "-active" $ipPattern True
		ixNet commit
        
		#Retrive the interface         
		set rb_interface [GetDependentNgpfProtocolHandle $handle "ethernet"]		
		Deputs "rb_interface is: $rb_interface"

		$this configure -handle $handle
		$this configure -version $ip_version
		set protocol ldp			
	
		array set interface [ list ]
		generate_interface		
    }
	
	method establish_lsp { args } {}
	method teardown_lsp { args } {}
	method flapping_lsp { args } {}
    method config { args } {}
	method get_status {} {}
	method get_stats {} {}

	method generate_interface { args } {
		set tag "body LdpSession::generate_interface [info script]"
        Deputs "----- TAG: $tag -----"		
		global rb_interface
		global hInt
		foreach int $rb_interface {
			if { [ ixNet getA $int -type ] == "routed" } {
				continue
			}
            set ipObj [GetDependentNgpfProtocolHandle $handle ip]
	    	if {[string first "ipv4" $ipObj] != -1} {
                set ip_version "ipv4"
                set hInt [ixNet getL $ipObj "ldpConnectedInterface"] 			
			}
            if {[string first "ipv6" $ipObj] != -1} {
               set ip_version "ipv6"
               set hInt [ixNet getL $ipObj "ldpv6ConnectedInterface"]
			}

		    if { [llength $ipObj] != 0 } {               
		        set ipPattern [ixNet getA [ixNet getA $hInt -active] -pattern]
	            SetMultiValues $hInt "-active" $ipPattern True			
	            ixNet commit
		        set hInt [ ixNet remapIds $hInt ]
		        set interface($int) $hInt	
            }
		}		
  	    $this configure -ldpInterface $hInt
        Deputs "interface: [array get interface]"
	}
}

body LdpSession::get_status {} {

	set tag "body LdpSession::get_status [info script]"
    Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
    Deputs "root $root"
 
	set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	if {[string first "LDP Per Port" $viewList] != -1 } {
        set view {::ixNet::OBJ-/statistics/view:"LDP Per Port"}
        getStatusView $view $hPort
	}
	if {[string first "LDPv6 Per Port" $viewList] != -1 } {
        set view {::ixNet::OBJ-/statistics/view:"LDPv6 Per Port"}
        getStatusView $view $hPort
	}
}
proc getStatusView {view {hPort}} {
    after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
    Deputs "captionList $captionList"
	set name_index        		        [ lsearch -exact $captionList {Port} ]
	set sessionUp_index 				[ lsearch -exact $captionList {Sessions Up} ]
    set sessionFlap_index      		    [ lsearch -exact $captionList {Session Flap} ]
	set lspEg_index 				    [ lsearch -exact $captionList {Established LSP Egress} ]
	set lspIn_index 			        [ lsearch -exact $captionList {Established LSP Ingress} ]
	set mappingTx_index			        [ lsearch -exact $captionList {Label Mapping Tx} ]
    set releaseTx_index      		    [ lsearch -exact $captionList {Label Release Tx} ]
	set releaseRx_index 				[ lsearch -exact $captionList {Label Release Rx} ]
	set withdrawTx_index 			    [ lsearch -exact $captionList {Label Withdraw Tx} ]
	set withdrawRx_index		 	    [ lsearch -exact $captionList {Label Withdraw Rx} ]
	set adjV4Count_index			    [ lsearch -exact $captionList {Established IPv4 Adjacency Count} ]
    set adjV6Count_index      	        [ lsearch -exact $captionList {Established IPv6 Adjacency Count} ]
	set sessionUpV4_index 				[ lsearch -exact $captionList {IPv4 Sessions Up} ]
	set sessionUpV6_index 			    [ lsearch -exact $captionList {IPv6 Sessions Up} ]


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
		set sessionUp    	[ lindex $row $sessionUp_index ]
		set sessionFlap    	[ lindex $row $sessionFlap_index ]
		set lspEg    	    [ lindex $row $lspEg_index ]
		set lspIn    	    [ lindex $row $lspIn_index ]
		set mappingTx       [ lindex $row $mappingTx_index ]
		set releaseTx    	[ lindex $row $releaseTx_index ]
		set releaseRx    	[ lindex $row $releaseRx_index ]
		set withdrawTx    	[ lindex $row $withdrawTx_index ]
		set withdrawRx    	[ lindex $row $withdrawRx_index ]
		set adjV4Count      [ lindex $row $adjV4Count_index ]
		set adjV6Count      [ lindex $row $adjV6Count_index ]		
		set sessionUpV4     [ lindex $row $sessionUpV4_index ]
		set sessionUpV6     [ lindex $row $sessionUpV6_index ]
		
		if { $sessionUp } {
			set status "sessionUp"
		}
		if { $sessionFlap } {
			set status "sessionFlap"
		}
		if { $lspEg } {
			set status "lspEg"
		}
		if { $mappingTx } {
			set status "mappingTx"
		}

		if { $releaseTx } {
			set status "releaseTx"
		}
		if { $releaseRx } {
			set status "releaseRx"
		}
		if { $withdrawTx } {
			set status "withdrawTx"
		}
		if { $withdrawRx } {
			set status "withdrawRx"
		}
		if { $adjV4Count } {
			set status "adjV4Count"
		}
		if { $adjV6Count } {
			set status "adjV6Count"
		}
		if { $sessionUpV4 } {
			set status "sessionUpV4"
		}

		if { $sessionUpV6 } {
			set status "sessionUpV6"
		}
	}	
    set ret [ GetStandardReturnHeader ]
    set ret $ret[ GetStandardReturnBody "status" $status ]
	return $ret

}

body LdpSession::get_stats {} {

    set tag "body LdpSession::get_stats [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
    set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	if {[string first "LDP Drill Down" $viewList] != -1 } {
		set protocol "LDP"
        set view [CreateNgpfProtocolView $protocol]
        getStatsView $view $hPort
	}
	if {[string first "LDPv6 Drill Down" $viewList] != -1 } {
	    set protocol "LDPv6"
        set view [CreateNgpfProtocolView $protocol]
        getStatsView $view $hPort
	}

}
proc getStatsView {view {hPort}} {
	after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
Deputs "captionList $captionList"	 

    set port_name [ lsearch -exact $captionList {Port} ]
    set session_succ [ lsearch -exact $captionList {Sessions Up} ]
    set flap [ lsearch -exact $captionList {Session Flap} ]

    set ret [ GetStandardReturnHeader ]

    set stats [ ixNet getA $view/page -rowValues ]
    Deputs "stats:$stats"

	set portFound 0
	foreach row $stats {
		eval {set row} $row
Deputs "row:$row"
Deputs "port index:$port_name"
		set rowPortName [ lindex $row $port_name ]
Deputs "row port name:$port_name"
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
    set statsItem   "session_succ"
    set statsVal    [ lindex $row $session_succ ]
    Deputs "stats val:$statsVal"
    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]

    set statsItem   "flap"
    set statsVal    [ lindex $row $flap ]
    Deputs "stats val:$statsVal"
    set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
    Deputs "ret:$ret" 
    return $ret
}

body LdpSession::config { args } {

    global errorInfo
    global errNumber
    global rb_interface
	
    if { [ catch {
        set hport   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in LdpSession ctor"
    }
    set tag "body LdpSession::config [info script]"
    Deputs "----- TAG: $tag -----"
	
    #param collection
    Deputs "Args:$args "
	set version "ipv4"
	set ip_version $version
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
   	   reborn 
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
				if {[ llength $ipv4Obj ] != 0} {
					if { [ info exists ipv4_addr ] } {
						foreach int $rb_interface {
							set ipv4_hdl [ixNet getL $int ipv4]
							set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -address] -pattern]
							set ip_addr [GetMultiValues $ipv4_hdl "-address" $ipPattern]						
							if {[info exists ipv4_gw]} {
								set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -gatewayIp] -pattern]
								set ip_gw [GetMultiValues $ipv4_hdl "-gatewayIp" $ipPattern]
								if {$ip_addr == $ipv4_addr && $ipv4_gw == $ip_gw} {
									set matched_int $int
									break
								}
							} elseif {$ip_addr == $ipv4_addr} {
								set matched_int $int
								break
							}
			
						}
					    if {[info exists matched_int]} {
							foreach int $rb_interface {
								if {$matched_int == $int} {
									continue
								}
								if { [info exists interface($int)] } {
									set ipPattern [ixNet getA [ixNet getA $interface($int) -active] -pattern]
									SetMultiValues $interface($int) "-active" $ipPattern False	
								}
							}
							set rb_interface $matched_int
							ixNet commit
			
						}
						foreach int $rb_interface {
							catch {
								if { [info exists interface($int)] } {
									set ipPattern [ixNet getA [ixNet getA $interface($int) -address] -pattern]
									SetMultiValues $interface($int) "-address" $ipPattern $ipv4_addr					
									ixNet commit
								}
							}
						}
					}
				
					if { [ info exists ipv4_prefix_len ] } {
						foreach int $rb_interface {
							catch {
								if { [info exists interface($int)] } {
									set pLen 24
									if {$ipv4_prefix_len == "255.0.0.0"} {
										set pLen 8
									} elseif {$ipv4_prefix_len == "255.255.0.0"} {
										set pLen 16
									} elseif  {$ipv4_prefix_len == "255.255.255.0"} {
										set pLen 24
									} else {
										set pLen 32
									}
									set ipPattern [ixNet getA [ixNet getA $interface($int) -prefix] -pattern]
									SetMultiValues $interface($int) "-prefix" $ipPattern $pLen
									ixNet commit
								} 
							}
						}
					}
					if { [ info exists ipv4_gw ] } {
						foreach int $rb_interface {
							catch {
								if { [info exists interface($int)] } {
									set ipPattern [ixNet getA [ixNet getA $interface($int) -gateway] -pattern]
									SetMultiValues $interface($int) "-gateway" $ipPattern $ipv4_gw				    
									ixNet commit
								}
							}
						}
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
		            set ipPattern [ixNet getA [ixNet getA $handle -keepAliveInterval] -pattern]
			        SetMultiValues $handle "-keepAliveInterval" $ipPattern $keep_alive_interval

	            }
		
		        if { [ info exists lsp_type ] } {
	                puts "Not implemented"
	            }
			    if { [ info exists router_id ] } {
	                set routeDataObj [ixNet getL $deviceGroupObj routerData]
                    set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
			        SetMultiValues $routeDataObj "-routerId" $ipPattern $router_id					   
	            }
				if { [ info exists enable_graceful_restart ] } {
                         set ipPattern [ixNet getA [ixNet getA $handle -enableGracefulRestart] -pattern]
			             SetMultiValues $handle "-enableGracefulRestart" $ipPattern $enable_graceful_restart		
	            }
			    if { [ info exists reconnect_time ] } {
                         set ipPattern [ixNet getA [ixNet getA $handle -reconnectTime] -pattern]
			             SetMultiValues $handle "-reconnectTime" $ipPattern $reconnect_time			               
	            }					
	            if { [ info exists recovery_time ] } {
                         set ipPattern [ixNet getA [ixNet getA $handle -recoveryTime] -pattern]
			             SetMultiValues $handle "-recoveryTime" $ipPattern $recovery_time		

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
                    set ipPattern [ixNet getA [ixNet getA $ldpInterface -operationMode] -pattern]
			        SetMultiValues $ldpInterface "-operationMode" $ipPattern $label_advertise_mode		
						
	
	            }
			    if { [ info exists hello_interval ] } {
                    set ipPattern [ixNet getA [ixNet getA $ldpInterface -basicHelloInterval] -pattern]
			        SetMultiValues $ldpInterface "-basicHelloInterval" $ipPattern $hello_interval		

	            }					
			    if { [ info exists transport_tlv_mode ] } {
		            set transport_tlv_mode [ string toupper $transport_tlv_mode ]
				    switch $transport_tlv_mode {
 						TRANSPORT_TLV_MODE_NONE {
                            set ipPattern [ixNet getA [ixNet getA $handle -sessionPreference] -pattern]
			                SetMultiValues $handle "-sessionPreference" $ipPattern any
					    }
			            TRANSPORT_TLV_MODE_TESTER_IP {
                            set ipPattern [ixNet getA [ixNet getA $handle -sessionPreference] -pattern]
			                SetMultiValues $handle "-sessionPreference" $ipPattern ipv4
							set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
                            set routerId [GetMultiValues $routeDataObj "-routerId" $ipPattern]
                            if {[ llength $ipv4Obj ] != 0} {
								set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -address] -pattern]
			                    SetMultiValues $ipv4_hdl "-address" $ipPattern $routerId	
							
			                }
						}
			            TRANSPORT_TLV_MODE_ROUTER_ID {
                            set ipPattern [ixNet getA [ixNet getA $handle -sessionPreference] -pattern]
			                SetMultiValues $handle "-sessionPreference" $ipPattern ipv6
			            }
		            }
			    }
			    ixNet commit
	        }
	    }
	}
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology	
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
		eval $lsp establish_lsp 
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
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	
	return [GetStandardReturnHeader]	

}

class LdpLsp {
	inherit RouterNgpfEmulationObject
	public variable hInt
	method config { args } {}
	method establish_lsp {} {}
	method teardown_lsp {} {}
	method flapping_lsp { args } {}

}

body LdpLsp::establish_lsp {} {
    global hInt
	set tag "body LdpLsp::establish_lsp [info script]"
    Deputs "----- TAG: $tag -----"
	foreach eachInterface $hInt {
	    ixNet setA [ixNet getA $eachInterface -active]/singleValue -value True

	}
	ixNet commit
}

body LdpLsp::teardown_lsp {} {
	set tag "body LdpLsp::teardown_lsp [info script]"
	global hInt
	Deputs "----- TAG: $tag -----"

	foreach eachInterface $hInt {
	    ixNet setA [ixNet getA $eachInterface -active]/singleValue -value False

	}
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
			-lsp {
			
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
	#public variable version
	public variable ipPoolObj

	constructor { ldp } {
		global errNumber
		set tag "body Ipv4PrefixLsp::ctor [info script]"
        Deputs "----- TAG: $tag -----"
		set ldpObj $ldp
		Deputs "value received at constructor is $ldp"
		reborn
	}
	method reborn {} {
	
	    global errNumber
		set tag "body Ipv4PrefixLsp::reborn [info script]"
        Deputs "----- TAG: $tag -----"
		if { [ catch {
			set hLdp   [ $ldpObj cget -handle ]
			set deviceGroupObj [GetDependentNgpfProtocolHandle $hLdp "deviceGroup"]
			set ethernetObj [GetDependentNgpfProtocolHandle $hLdp "ethernet"]
			set ipObj [GetDependentNgpfProtocolHandle $hLdp "ip"]
			puts "******************************** deviceGroup obj is :: $deviceGroupObj"
			set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
            ixNet commit
            set networkGroupObj [ ixNet remapIds $networkGroupObj ]

			if {[string first "ipv4" $ipObj] != -1} {
				set ip_version "ipv4"
								
			} else {
               set ip_version "ipv6"
			} 			
			
		    if { $ip_version == "ipv4" } {
                set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
				ixNet commit
		   	    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
				ixNet setA $ipPoolObj/connector -connectedTo $hLdp
				
				set connector [ixNet add $ipPoolObj connector]
                ixNet setA $connector -connectedTo $hLdp
                ixNet commit
                set range [ixNet getL $ipPoolObj ldpFECProperty]
	
		        set ipPattern [ixNet getA [ixNet getA $range -active] -pattern]
	            SetMultiValues $range "-active" $ipPattern true
				#ixNet setA [ixNet getA $range -active]/singleValue -value true
				ixNet commit
				set handle [ ixNet remapIds $range ]

		    } else {
                set ipPoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
				ixNet commit
				ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"
				#ixNet setA $ipPoolObj/connector -connectedTo $hLdp
				ixNet commit
				set connector [ixNet add $ipPoolObj connector]
                ixNet setA $connector -connectedTo $hLdp
                ixNet commit
			    set range [ixNet getL $ipPoolObj ldpIpv6FECProperty]
				ixNet setA [ixNet getA $range -active]/singleValue -value true
				ixNet commit
				set handle [ ixNet remapIds $range ]				
		    }			
			
		} ] } {
			error "$errNumber(1) LDP Object in Ipv4PrefixLsp ctorn"
		}
		
	}
	method config { args } {}
}

body Ipv4PrefixLsp::config { args } {

    global errorInfo
    global errNumber
    #set pLen 24
	set assinged_label 3
	set fec_type LDP_FEC_TYPE_PREFIX 

    set tag "body Ipv4PrefixLsp::config [info script]"
    Deputs "----- TAG: $tag -----"

	
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
			set type [ $route_block cget -type ]
		} else {
			return [ GetErrorReturnHeader "Bad RouteBlock obj... $route_block" ]			
		}
	} else {
		return [ GetErrorReturnHeader "Missing madatory parameter... -route_block" ]
	}

	if { [ info exists num ] } {
		set ipPattern [ixNet getA [ixNet getA $ipPoolObj -numberOfAddressesAsy] -pattern]
	    SetMultiValues $ipPoolObj "-numberOfAddressesAsy" $ipPattern $num
    }
    if { [ info exists start ] } {
        set ipPattern [ixNet getA [ixNet getA $ipPoolObj -networkAddress] -pattern]
	    SetMultiValues $ipPoolObj "-networkAddress" $ipPattern $start
    }
	if { [ info exists step ] } {
	    puts "not implemented "
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

    }

 
	if { [ info exists assinged_label ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -labelValue] -pattern]
        SetMultiValues $handle "-labelValue" $ipPattern $assinged_label
	}
	
	if { [ info exists fec_type ] } {
  	    set fec_type [ string toupper $fec_type ] 
	    switch $fec_type {
			LDP_FEC_TYPE_PREFIX {
				 set pLen $prefix_len
			}
		    LDP_FEC_TYPE_HOST_ADDR {
				set pLen 32
		    }

		}
		set ipPattern [ixNet getA [ixNet getA $ipPoolObj -prefixLength] -pattern]
        SetMultiValues $ipPoolObj "-prefixLength" $ipPattern $pLen
	}
	ixNet commit
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	
	return [GetStandardReturnHeader]	

}

class VcLsp {

	inherit LdpLsp
	public variable ldpObj
	public variable hInterface
	public variable vcRange
	public variable hLdp
	
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
	    
		set deviceGroupObj [GetDependentNgpfProtocolHandle $hLdp "deviceGroup"]		
        set networkGroupList [ixNet getL $deviceGroupObj "networkGroup"]
        if { [ llength $networkGroupList ] == 0 } {
            set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
            ixNet commit
            set networkGroupObj [ ixNet remapIds $networkGroupObj ]
            set networkGroupList [ixNet getL $deviceGroupObj "networkGroup"]
        }
        foreach networkGroupObj  $networkGroupList {
	        set macPoolsObj [ixNet getL $networkGroupObj "macPools"]
		    if { [ llength $macPoolsObj ] == 0 } {
		       set macPoolsObj [ixNet add $networkGroupObj "macPools"]
		       ixNet commit
	           set macPoolsObj [ ixNet remapIds $macPoolsObj ]
           }

		set ipPattern [ixNet getA [ixNet getA $macPoolsObj -enableVlans] -pattern]
        SetMultiValues $macPoolsObj "-enableVlans" $ipPattern True

		ixNet commit  
        }
	
        Deputs "rb_interface:[ $ldpObj cget -ldpInterface ]"
        foreach int [ $ldpObj cget -ldpInterface ] {
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
	
	set encap "LDP_LSP_ENCAP_ETHERNET_VLAN"
	set peer_address 160.160.160.160
	set vc_ip_address 1.1.1.1
	set vc_id_count 1

	if { $hLdp == "" } {
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
			    if { [ string is integer $value ] && ( $value >= 0 ) } {
                    set mac_step $value
                    set mac_step "00:00:00:00:00:0$mac_step"
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }		
               
			}
			-mac_num  {			
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
	#set handleList ""
	if { [ info exists encap ] } {
		set encap [ string toupper $encap ]
		switch $encap {
			LDP_LSP_ENCAP_FRAME_RELAY_DLCI {
				set ixencap framerelay
			}
			LDP_LSP_ENCAP_ATM_AAL5_VCC {
				set ixencap atmaal5
			}
			LDP_LSP_ENCAP_ATM_TRANSPARENT_CELL {
				set ixencap atmxcell 
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
				set ixencap ethernetvpls
			}
		}
  
	    set deviceGroupObj [GetDependentNgpfProtocolHandle $hLdp "deviceGroup"]
		set networkGroupList [ixNet getL $deviceGroupObj "networkGroup"]
		if { [ llength $networkGroupList ] == 0 } {
            set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
            ixNet commit
            set networkGroupObj [ ixNet remapIds $networkGroupObj ]
            set networkGroupList [ixNet getL $deviceGroupObj "networkGroup"]
        }
        foreach networkGroupObj $networkGroupList {
	        set macPoolsObj [ixNet getL $networkGroupObj "macPools"]
		    if {$ixencap == "ethernet" || $ixencap == "vlan" } {
			    set range [ixNet add $hLdp "ldppwvpls"]
			    ixNet commit
		        set handle [ ixNet remapIds $range ]
		        ixNet setA $macPoolsObj/connector -connectedTo $range
		        ixNet setA [ixNet getA $handle -interfaceType]/singleValue -value $ixencap			

		    } else {
			    set range [ixNet add $hLdp "ldpotherpws"]
			    ixNet commit
			    set handle [ ixNet remapIds $range ]
			    ixNet setA [ixNet getA $handle -ifaceType]/singleValue -value $ixencap
            }
            lappend handleList $handle
		}
		ixNet commit
	}
	foreach handle $handleList {
	    if { [ info exists group_id ] } {
	       set ipPattern [ixNet getA [ixNet getA $handle -groupId] -pattern]
		   SetMultiValues $handle "-groupId" $ipPattern $group_id
	    }
	    if { [ info exists if_mtu ] } {
	       set ipPattern [ixNet getA [ixNet getA $handle -mtu] -pattern]
		   SetMultiValues $handle "-mtu" $ipPattern $if_mtu
	    }

	    if { [ info exists requested_vlan_id_start ] } {
			if { [ info exists requested_vlan_id_step ] } {
               set ipPattern [ixNet getA [ixNet getA $handle -vCIDStart] -pattern]
               SetMultiValues $handle "-vCIDStart" $ipPattern $requested_vlan_id_start $requested_vlan_id_step
			   #ixNet setM [ixNet getA $handle -vCIDStart]/counter -step $vc_id_step -start $vc_id_start -direction increment
			} else {
				set ipPattern [ixNet getA [ixNet getA $handle -vCIDStart] -pattern]
		        SetMultiValues $handle "-vCIDStart" $ipPattern $requested_vlan_id_start
			}
			ixNet commit 
		}
		
		if { [ info exists requested_vlan_id_count ] } {
		    #how to configure >>>>
		    #set ipPattern [ixNet getA [ixNet getA $handle -count] -pattern]
		    #SetMultiValues $handle "-count" $ipPattern $requested_vlan_id_count
		    #ixNet commit
	
	    }
		
		
		if { [ info exists assinged_label ] } {
			set ipPattern [ixNet getA [ixNet getA $handle -label] -pattern]
		    SetMultiValues $handle "-label" $ipPattern $assinged_label
			#ixNet setA [ixNet getA $handle -label]/singleValue -value $assinged_label
		}
		
		if { [ info exists peer_address ] } {
			if {[IsIPv4Address $peer_address] } {
				if {[ info exists vc_ip_address ]} {
					set ipPattern [ixNet getA [ixNet getA $handle -peerId] -pattern]
                    SetMultiValues $handle "-peerId" $ipPattern $peer_address $vc_ip_address
					#ixNet setM [ixNet getA $handle -peerId]/counter -step $vc_ip_address -start $peer_address -direction increment
			
				} else { 
					set ipPattern [ixNet getA [ixNet getA $handle -peerId] -pattern]
		            SetMultiValues $handle "-peerId" $ipPattern $peer_address
					#ixNet setA [ixNet getA $handle -peerId]/singleValue -value $peer_address
				}
				
			} else {
				if {[ info exists vc_ip_address ]} {
					set ipPattern [ixNet getA [ixNet getA $handle -ipv6PeerId] -pattern]
                    SetMultiValues $handle "-ipv6PeerId" $ipPattern $peer_address $vc_ip_address
					#ixNet setM [ixNet getA $handle -ipv6PeerId]/counter -step $vc_ip_address -start $peer_address -direction increment
			
				} else { 
					set ipPattern [ixNet getA [ixNet getA $handle -ipv6PeerId] -pattern]
		            SetMultiValues $handle "-ipv6PeerId" $ipPattern $peer_address
					#ixNet setA [ixNet getA $handle -ipv6PeerId]/singleValue -value $peer_address
				}
			  
			}
			
	    }
		ixNet commit
	}

    foreach networkGroupObj $networkGroupList {
	    set macPoolsObj [ixNet getL $networkGroupObj "macPools"]
	    if { [ info exists mac_start ] } {
	        if { [ info exists mac_step ] } {
				set ipPattern [ixNet getA [ixNet getA $macPoolsObj -mac] -pattern]               
				SetMultiValues $macPoolsObj "-mac" $ipPattern $mac_start $mac_step 
		
		    } else {
	          set ipPattern [ixNet getA [ixNet getA $macPoolsObj -mac] -pattern]
              SetMultiValues $macPoolsObj "-mac" $ipPattern $mac_start
	          #ixNet setA [ixNet getA $macPoolsObj -mac]/singleValue -value  $mac_start
            }
		    ixNet commit
	    }

        if { [ info exists mac_num ] } {
	        puts "mac_num Not implemented"
	
	    }
		if { [ info exists vc_id_count ] } {
			ixNet setA  $macPoolsObj -vlanCount $vc_id_count
			#set ipPattern [ixNet getA [ixNet getA $macPoolsObj -vlanCount] -pattern]
            #SetMultiValues $macPoolsObj "-vlanCount" $ipPattern $vc_id_count 
			
			ixNet commit 
			
	    }		
		if { [ info exists vc_id_start ] } {
		    if { [ info exists vc_id_step ] } {
                for {set i 1} {$i <= $vc_id_count} {incr i } {
                    set ipPattern [ixNet getA [ixNet getA $macPoolsObj/vlan:$i -vlanId] -pattern]
                    SetMultiValues $macPoolsObj/vlan:$i "-vlanId" $ipPattern $vc_id_start $vc_id_step
                }
            } else {
                for {set i 1} {$i <= $vc_id_count} {incr i } {
                    set ipPattern [ixNet getA [ixNet getA $macPoolsObj/vlan:$i -vlanId] -pattern]
                    SetMultiValues $macPoolsObj/vlan:$i "-vlanId" $ipPattern $vc_id_start
                }
            }
			ixNet commit
	    }




	if { [ info exists incr_vc_vlan ] && $incr_vc_vlan } {
	
		#option not available in ngpf >>>>
	    # -incrementVlanMode parallelIncrement
		#ixNet commit
		
	}
		
	}
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology	
	return [GetStandardReturnHeader]	
}



