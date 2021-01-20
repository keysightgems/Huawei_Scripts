
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
    public variable ldp_interface	
    public variable deviceHandle
    public variable ethHandle
    public variable version
    public variable ipv4Handle
    public variable ipv6Handle	
	public variable ldpObj
	
    constructor {  port { hLdpSession NULL } } {
		global errNumber
	    set handle ""
        set deviceHandle ""
        set ethHandle  ""  
	    set ldpRouter ""	

        #-- enable protocol
        set portObj [ GetObject $port ]
        Deputs "port:$portObj"
        if { [ catch {
	        set hPort   [ $portObj cget -handle ]
            Deputs "port handle: $hPort"
        } ] } {
	        error "$errNumber(1) Port Object in LdpSession ctor"
        }
        Deputs "initial port..."
	    if { $hLdpSession == "NULL" } {
            set hLdpSession [GetObjNameFromString $this "NULL"]
        }
        Deputs "----- hLdpSession: $hLdpSession, hPort: $hPort -----"
        if { $hLdpSession != "NULL" } {
            set handle [GetValidNgpfHandleObj "ldp" $hLdpSession $hPort]
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
						set ipv4Obj [ ixNet remapIds $ipv4Obj ]

					}
					if { $ip_version == "ipv6" } {
					    set ipv6Obj [ixNet add $ethernetObj ipv6]
						ixNet commit
						set ipv6Obj [ ixNet remapIds $ipv6Obj ]
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
			    ixNet commit
                set ipv4Obj [ ixNet remapIds $ipv4Obj ]

		        set ldpObj [ixNet getL $ipv4Obj ldpBasicRouter]
                if {[llength $ldpObj] == 0} {
                    set ldpObj [ixNet add $ipv4Obj ldpBasicRouter]
		        }
            }
			
            if { $ip_version == "ipv6" } {
                set ipv6Obj [ixNet add $ethernetObj ipv6]
			    ixNet commit
                set ipv6Obj [ ixNet remapIds $ipv6Obj ]

		        set ldpObj [ixNet getL $ipv6Obj ldpBasicRouterV6]

                if {[llength $ldpObj] == 0} {
			        set ldpObj [ixNet add $ipv6Obj ldpBasicRouterV6]
                }
            }

            set ldpObj [ ixNet remapIds $ldpObj ]
            ixNet setA $ldpObj -name $this
            ixNet commit
            array set routeBlock [ list ]
        } else {
             foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
				puts " $vportObj == $hPort"
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
	    set ldp_interface_list [GetLdpRouterHandle $ldpObj $ip_version]
        set ldp_interface [lindex $ldp_interface_list "0"]
        set ip_version [lindex $ldp_interface_list "1"]
	    if { $ip_version == "ipv4" } {
            $this configure -ipv4Handle $ipv4Obj
        } else {
            $this configure -ipv6Handle $ipv6Obj
        }
	
	#Setting to 1 default number of device 
	ixNet setA $deviceGroupObj -multiplier "1"
	ixNet commit
	
	
    $this configure -handle $ldpObj
    $this configure -deviceHandle $deviceGroupObj
    $this configure -ethHandle $ethernetObj
	$this configure -version $ip_version
	$this configure -ldp_interface $ldp_interface

	set protocol ldp
		
		
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
	foreach int $rb_interface {
    	if { [ ixNet getA $int -type ] == "routed" } {
			continue
		}
		
		set hInt [ ixNet add $handle interface ]
		ixNet setM $hInt -protocolInterface $int -enabled True
		ixNet commit
			set hInt [ ixNet remapIds $hInt ]

			set interface($int) $hInt	
		}
        Deputs "interface: [array get interface]"
	}	
}

body LdpSession::get_status {} {

	set tag "body LdpSession::get_status [info script]"
    Deputs "----- TAG: $tag -----"


    set root [ixNet getRoot]
    Deputs "root $root"
	set protocol "ldp"
	#set view [CreateProtocolView $protocol]
	puts "Starting All Protocols"
    ixNet exec startAllProtocols
    puts "Sleep 30sec for protocols to start"
    after 30000
	 

	#set view [CreateProtocolView $protocol]
	set view {::ixNet::OBJ-/statistics/view:"LDP Per Port"}
    Deputs "view $view"	
    set captionList         [ ixNet getA $view/page -columnCaptions ]
	Deputs "caption:$captionList"
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
	set p2pmEg_index 				    [ lsearch -exact $captionList {Established P2MP LSP Egress} ]
	set p2pmIg_index 		   	        [ lsearch -exact $captionList {Established P2MP LSP Ingress} ]
	set adjV4Count_index			    [ lsearch -exact $captionList {Established IPv4 Adjacency Count} ]
    set adjV6Count_index      	        [ lsearch -exact $captionList {Established IPv6 Adjacency Count} ]
	set sessionUpV4_index 				[ lsearch -exact $captionList {IPv4 Sessions Up} ]
	set sessionUpV6_index 			    [ lsearch -exact $captionList {IPv6 Sessions Up} ]
	
	set stats [ ixNet getA $view/page -rowValues ]
	Deputs "stats : $stats"
    set portFound 0
    foreach row $stats {
        eval {set row} $row
        set rowPortName [ lindex $row $name_index ]
		set portName [ ixNet getA $hPort -name ]
			if { [ regexp $portName $rowPortName ] } {
				set portFound 1
				break
        }
    }


    Deputs "name_index: $name_index  "      		        
	Deputs "sessionUp_index : $sessionUp_index"				
    Deputs " sessionFlap_index : $sessionFlap_index"      		
	Deputs " lspEg_index 	   : $lspEg_index"		    
	Deputs " LspIn_index 	   : $lspIn_index"	        
	Deputs " mappingTx_index   : $mappingTx_index  "		      
    Deputs " releaseTx_index   : $releaseTx_index" 		    
	Deputs " releaseRx_index   : $releaseRx_index"		
	Deputs " withdrawTx_index  : $withdrawTx_index	"	   
	Deputs " withdrawRx_index  : $withdrawRx_index	 "	   
	Deputs " p2pmEg_index 	   : $p2pmEg_index		"   
	Deputs " p2pmIg_index 	   : $p2pmIg_index   	"        
	Deputs " adjV4Count_index  : $adjV4Count_index	"	    
    Deputs " adjV6Count_index  : $adjV6Count_index   	 "       
	Deputs " sessionUpV4_index : $sessionUpV4_index	"		
	Deputs " sessionUpV6_index : $sessionUpV6_index	"	    

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
		set p2pmEg          [ lindex $row $p2pmEg_index ]
		set p2pmIg          [ lindex $row $p2pmIg_index ]
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
		if { $p2pmEg } {
			set status "p2pmEg"
		}
		if { $p2pmIg } {
			set status "p2pmIg"
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

body LdpSession::config { args } {

    global errorInfo
    global errNumber

    if { [ catch {
        set hport   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in LdpSession ctor"
    }
    set tag "body LdpSession::config [info script]"
    Deputs "----- TAG: $tag -----"
	
	
    #param collection
    Deputs "Args:$args "
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
					    ixNet setA [ixNet getA $handle -keepAliveInterval]/singleValue -value $keep_alive_interval            

	                }

					
					if { [ info exists lsp_type ] } {
	                   puts "Not implemented"
	                }
										
					if { [ info exists router_id ] } {
	                   set routeDataObj [ixNet getL $deviceGroupObj routerData]
					   ixNet setA [ixNet getA $routeDataObj -routerId]/singleValue -value $router_id
	                }
				    if { [ info exists enable_graceful_restart ] } {
		               ixNet setA [ixNet getA $handle -enableGracefulRestart]/singleValue -value $enable_graceful_restart            
	                }
					if { [ info exists reconnect_time ] } {
	               
                       ixNet setA [ixNet getA $handle -reconnectTime]/singleValue -value $reconnect_time 
	                }					
	                if { [ info exists recovery_time ] } {
	                   ixNet setA [ixNet getA $handle -recoveryTime]/singleValue -value $recovery_time            

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
					    ixNet setA [ixNet getA $ldp_interface -operationMode]/singleValue -value $label_advertise_mode            
						
	
	                }
					if { [ info exists hello_interval ] } {
						ixNet setA [ixNet getA $ldp_interface -basicHelloInterval]/singleValue -value $hello_interval          

	                }					
					if { [ info exists transport_tlv_mode ] } {
		                set transport_tlv_mode [ string toupper $transport_tlv_mode ]
						#-prefixAdvertisementType
						switch $transport_tlv_mode {
 						    TRANSPORT_TLV_MODE_NONE {
							    ixNet setA [ixNet getA $handle -sessionPreference]/singleValue -value "any"   
							}
			                TRANSPORT_TLV_MODE_TESTER_IP {
				                ixNet setA [ixNet getA $handle -sessionPreference]/singleValue -value "ipv4"   
			                }
			                TRANSPORT_TLV_MODE_ROUTER_ID {
			                	ixNet setA [ixNet getA $handle -sessionPreference]/singleValue -value "ipv6"   
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
	
	return [GetStandardReturnHeader]	

}

class LdpLsp {
	inherit RouterNgpfEmulationObject
	public variable type
	public variable handle
	
	method config { args } {}
	method establish_lsp {} {}
	method teardown_lsp {} {}
	method flapping_lsp { args } {}
	
	constructor { ldp } {       
		
		set tag "body Vpn::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set ldpObj $ldp
		Deputs "value received at constructor is $ldp"
		set handle  [ $ldpObj cget -handle ]
	}
	

}

body LdpLsp::establish_lsp {} {
	set tag "body LdpLsp::establish_lsp [info script]"
    Deputs "----- TAG: $tag -----"
	ixNet setA [ixNet getA $handle -active]/singleValue -value True
	ixNet commit
}

body LdpLsp::teardown_lsp {} {
	set tag "body LdpLsp::teardown_lsp [info script]"
    Deputs "----- TAG: $tag -----"
	ixNet setA [ixNet getA $handle -active]/singleValue -value False
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

	#inherit LdpLsp
	public variable ldpObj
	public variable handle
	public variable portObj
	public variable ip_version
    public variable ldpImpryObjList
	public variable networkGroupObj
	public variable hLdp
	public variable ipPoolObj
	public variable ldpFecObj
	
	constructor { ldp } {
		global errNumber

		set tag "body Ipv4PrefixLsp::ctor [info script]"
        Deputs "----- TAG: $tag -----"

		set ldpObj $ldp
		Deputs "value received at constructor is $ldp"
		set hLdp [ $ldp cget -handle ]
		set portObj [ $ldp cget -portObj ]
		set hPort	[ $ldp cget -hPort ]
		set ip_version [$ldp cget -version]
		Deputs "ldpObj : $ldpObj..hLdp: $hLdp..portObj: $portObj..hPort: $hPort"
		set handle ""
		reborn
	}
	method reborn {} {
	
	    global errNumber
        set ldpFecObj ""
        set ldpv6FecObj ""
		
		set tag "body Ipv4PrefixLsp::reborn [info script]"
        Deputs "----- TAG: $tag -----"

		if { [ catch {
			set hLdp   [ $ldpObj cget -handle ]
            set deviceGroupObj [$ldpObj cget -deviceHandle]
            puts "******************************** deviceGroup obj is :: $deviceGroupObj"
            set networkGroupObj [ixNet getL $deviceGroupObj "networkGroup"]
		    if { [ llength $networkGroupObj ] == 0 } {
 	           set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
               ixNet commit
               set networkGroupObj [ ixNet remapIds $networkGroupObj ]
	           puts "networkGroupObj:$networkGroupObj"	
		
		    }
	       
		    set ethernetObj [ixNet getL $deviceGroupObj ethernet]
		    set ldp_interface_list [GetLdpRouterHandle $hLdp $ip_version]
			set ldp_interface [lindex $ldp_interface_list "0"]
			set ip_version [lindex $ldp_interface_list "1"]
		    if { $ip_version == "ipv4" } {
                set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
				ixNet commit
		   	    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
				ixNet setA $ipPoolObj/connector -connectedTo $hLdp
				ixNet commit
                set range [ixNet getL $ipPoolObj ldpFECProperty]
				ixNet setA [ixNet getA $range -active]/singleValue -value true
				ixNet commit
				set handle [ ixNet remapIds $range ]
       
		    } else {
                set ipPoolObj [ixNet add $networkGroupObj "ipv6PrefixPools"]
				ixNet commit
				ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv6\ Addresses\ 1"

				ixNet setA $ipPoolObj/connector -connectedTo $hLdp
				ixNet commit
			    set range [ixNet getL $ipPoolObj ldpIpv6FECProperty]
				ixNet setA [ixNet getA $range -active]/singleValue -value true
				ixNet commit
				set handle [ ixNet remapIds $range ]				
		    }			
			
		} ] } {
			error "$errNumber(1) LDP Object in Ipv4PrefixLsp ctor"
		}
		
	}
	method config { args } {}
}

body Ipv4PrefixLsp::config { args } {

    global errorInfo
    global errNumber
    set pLen 24
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
		} else {
			return [ GetErrorReturnHeader "Bad RouteBlock obj... $route_block" ]			
		}
	} else {
		return [ GetErrorReturnHeader "Missing madatory parameter... -route_block" ]
	}	
	
	if { $num != "" } {
  	    ixNet setA $ipPoolObj -numberOfAddresses $num
        ixNet commit
    }
			
	if { [ info exists assinged_label ] } {
		ixNet setA [ixNet getA $handle -labelValue]/singleValue -value $assinged_label
		ixNet commit
	}

    if { $start != "" } {
        ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -start $start -direction increment
        ixNet commit
    }	

    if { $step != "" } {
        if {$ip_version == "ipv4"} {
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
            ixNet setM [ixNet getA $ipPoolObj -networkAddress]/counter -step $stepvalue
		    ixNet commit
        }
	
	    if { [ info exists fec_type ] } {
  			set fec_type [ string toupper $fec_type ] 
		    switch $fec_type {
			    LDP_FEC_TYPE_PREFIX {
				    set pLen $prefix_len
			    }
				LDP_FEC_TYPE_HOST_ADDR {
				    set pLen 24
                    if {$prefix_len == "255.0.0.0"} {
                            set pLen 8
                    } elseif  {$prefix_len == "255.255.0.0"} {
                            set pLen 16
                    } elseif  {$prefix_len == "255.255.255.0"} {
                            set pLen 24
                    } else {
                            set pLen 32
                    }
			    }

		    }
			ixNet setA [ixNet getA $ipPoolObj -prefixLength]/singleValue -value $pLen		        
		    ixNet commit
	    }
	
	return [GetStandardReturnHeader]	

}

class VcLsp {

	#inherit LdpLsp
	public variable ldpObj
	public variable vcRange
	public variable hInterface
    public variable networkGroupObj
	public variable handle
	public variable macPoolsObj
	public variable ip_version
	public variable hLdp
	public variable deviceGroupObj
	public variable ipv4Handle
	public variable ipv6Handle	
	
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
		set deviceGroupObj [$ldpObj cget -deviceHandle]
		set ip_version [$ldpObj cget -version]
        set ipv4Handle [$ldpObj cget -ipv4Handle]
        set ipv6Handle [$ldpObj cget -ipv6Handle]

        set networkGroupObj [ixNet getL $deviceGroupObj "networkGroup"]
		if { [ llength $networkGroupObj ] == 0 } {
 	        set networkGroupObj [ixNet add $deviceGroupObj "networkGroup"]
            ixNet commit
            set networkGroupObj [ ixNet remapIds $networkGroupObj ]
	        puts "networkGroupObj:$networkGroupObj"		
		
		
		}
	    set macPoolsObj [ixNet getL $networkGroupObj "macPools"]
		if { [ llength $macPoolsObj ] == 0 } {
		set macPoolsObj [ixNet add $networkGroupObj "macPools"]
		ixNet commit
	    set macPoolsObj [ ixNet remapIds $macPoolsObj ]
        }
		ixNet setA [ixNet getA $macPoolsObj -enableVlans]/singleValue -value True			
		ixNet commit  

	
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
		ixNet commit
    }
		
	
	if { [ info exists group_id ] } {
	    ixNet setA [ixNet getA $handle -groupId]/singleValue -value $group_id
		ixNet commit
	}
	if { [ info exists if_mtu ] } {
	    ixNet setA [ixNet getA $handle -mtu]/singleValue -value $if_mtu	
		ixNet commit
	}

	if { [ info exists vc_id_start ] } {
   	    if { [ info exists vc_id_step ] } {		
            ixNet setM [ixNet getA $handle -vCIDStart]/counter -step $vc_id_step -start $vc_id_start -direction increment
            ixNet commit
	    } else {
		    ixNet setA [ixNet getA $handle -vCIDStart]/singleValue -value $vc_id_start	
		    ixNet commit
	    }
	}

	if { [ info exists assinged_label ] } {
	    ixNet setA [ixNet getA $handle -label]/singleValue -value $assinged_label	
		ixNet commit
	}
	
	if { [ info exists peer_address ] } {
		if {$ip_version == "ipv4"} {
		    if {[ info ex vc_ip_address ]} {
                ixNet setM [ixNet getA $handle -peerId]/counter -step $peer_address -start $vc_ip_address -direction increment				
				
				} else { 
			        ixNet setA [ixNet getA $handle -peerId]/singleValue -value $peer_address					
				}
	
	    } else {
		    if {[ info ex vc_ip_address ]} {
                ixNet setM [ixNet getA $handle -ipv6PeerId]/counter -step $peer_address -start $vc_ip_address -direction increment				
				
		    } else { 
			    ixNet setA [ixNet getA $handle -ipv6PeerId]/singleValue -value $peer_address					
			}
				
			   
	    }  
			
		
		ixNet commit
	}

	
	if { [ info exists mac_start ] } {
	    if { [ info exists mac_step ] } {		
	       ixNet setM [ixNet getA $macPoolsObj -mac]/counter -step $mac_step -start $mac_start -direction increment
		
		} else {
	       ixNet setA [ixNet getA $macPoolsObj -mac]/singleValue -value  $mac_start 
        }

		ixNet commit
	}
    if { [ info exists vc_id_count ] } {
	    ixNet setA $macPoolsObj -vlanCount $vc_id_count
		ixNet commit
	
	}

    if { [ info exists requested_vlan_id_start ] } {
	    for {set i 1} {$i <= $vc_id_count} {incr i } {
		    ixNet setA [ixNet getA $macPoolsObj/vlan:$i -vlanId]/singleValue -value $requested_vlan_id_start
		
		} 

	}

    if { [ info exists requested_vlan_id_count ] } {
	    for {set i 1} {$i <= $vc_id_count} {incr i } {
		    ixNet setM [ixNet getA $macPoolsObj/vlan:$i -vlanId]/counter -step $requested_vlan_id_count -start $requested_vlan_id_start -direction increment
		
		} 

	}


	if { [ info exists incr_vc_vlan ] } {
		#Option not available in the NGPF >>>>>>
		#ixNet setM $handle/l2MacVlanRange \
			-incrementVlanMode parallelIncrement
		#ixNet commit
		
	}
	
	return [GetStandardReturnHeader]	
}



