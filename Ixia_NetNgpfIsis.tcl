
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.14.58
#		2. Add ipv4_addr ipv4_gw ipv4_prefix_len ipv6_addr ipv6_gw ipv6_prefix_len in config
#		3. Add SimulatedRoute class

class IsisSession {
    inherit RouterEmulationObject
    public variable isisHandle		
    public variable deviceHandle
    public variable ethHandle
    public variable version

    
	constructor { port { hIsisSession NULL } } {}
    method reborn {} {}
    method config { args } {}
    method get_stats {} {}
    method advertise_topo {} {}
	method withdraw_topo {} {}
    set isisObj ""
	public variable mac_addr
}


body IsisSession::get_stats {} {
    set tag "body IsisSession::get_stats [info script]"
    Deputs "----- TAG: $tag -----"
    set root [ixNet getRoot]
	set view {::ixNet::OBJ-/statistics/view:"BGP Aggregated Statistics"}
    # set view  [ ixNet getF $root/statistics view -caption "Port Statistics" ]
    Deputs "view:$view"
    set captionList             [ ixNet getA $view/page -columnCaptions ]
    Deputs "caption list:$captionList"
	set port_name				[ lsearch -exact $captionList {Stat Name} ]
    set session_conf            [ lsearch -exact $captionList {Sess. Configured} ]
    set session_succ            [ lsearch -exact $captionList {Sess. Up} ]
    set flap         	        [ lsearch -exact $captionList {Session Flap Count} ]
	
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
		if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
			continue
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
body IsisSession::reborn {} {
    global isisObj
	global errNumber
    

	set tag "body IsisSession::reborn [info script]"
    Deputs "----- TAG: $tag -----"
    set ip_version [ $portObj cget -ipVersion ]
    set version "ipv4"
	
	if { $ip_version != "<undefined>" } {
        set ip_version $ip_version
    } else {
        set ip_version $version
    }	

	if { [ catch {
        set hPort   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in BgpSession ctor"
    }
	
	#-- add isis protocol
    array set routeBlock [ list ]
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    if { [ llength $topoObjList ] == 0 } {

        set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
        
		set deviceGroupObj [ixNet add $topoObj deviceGroup]
		debug 1 

        set ethernetObj [ixNet add $deviceGroupObj ethernet]
		
        set isisObj [ixNet add $ethernetObj isisL3]

        set isisObj [ ixNet remapIds $isisObj ]
      
		
    } elseif { [ llength $topoObjList ] != 0 } {
        foreach topoObj $topoObjList {
  		    set vportObj [ixNet getA $topoObj -vports]
            if {$vportObj == $hPort} {
                set deviceGroupList [ixNet getL $topoObj deviceGroup]
				puts "deviceGroupList :: $deviceGroupList >>>"
                foreach deviceGroupObj $deviceGroupList {
                    set ethernetList [ixNet getL $deviceGroupObj ethernet]
					foreach ethernetObj $ethernetList {
                        set isisObj [ixNet getL $ethernetObj isisL3]
						if {[ llength $isisObj ] == 0 } {
						    set isisObj [ixNet add $ethernetObj isisL3]
						}
                    }

                }
            }
        }


    }

	ixNet commit
    $this configure -isisHandle $isisObj
    $this configure -deviceHandle $deviceGroupObj
    $this configure -ethHandle $ethernetObj
	$this configure -version $ip_version
    set protocol isis	
	
}


body IsisSession::constructor { port { hIsisSession NULL } } {
    set tag "body IsisSession::constructor [info script]"
    Deputs "----- TAG: $tag -----"
	
    global errNumber
	set isishandle ""
    set deviceHandle ""
    set ethHandle  ""  
    #-- enable protocol
    set portObj [ GetObject $port ]
    Deputs "port:$portObj"
    if { [ catch {
	    set hPort   [ $portObj cget -handle ]
        Deputs "port handle: $hPort"
    } ] } {
	    error "$errNumber(1) Port Object in IsisSession ctor"
    }
    Deputs "initial port..."
	if { $hIsisSession == "NULL" } {
        set hIsisSession [GetObjNameFromString $this "NULL"]
    }
    Deputs "----- hIsisSession: $hIsisSession, hPort: $hPort -----"
    if { $hIsisSession != "NULL" } {
        set handle [GetValidHandleObj "isis" $hIsisSession $hPort]
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

body IsisSession::config { args } {
    set tag "body IsisSession::config [info script]"
    global errNumber
	Deputs "----- TAG: $tag -----"
	
	set sys_id "64:01:00:01:00:00"
    if { $handle == "" } {
	    reborn
    }
	set ip_version "ipv4"
	Deputs "Args:$args "
    foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-localSystemID -
			-sys_id - 
			-system_id {
				set sys_id $value
			}
			-network_type {
				set value [string tolower $value]
					switch $value {
					p2p {
						set value pointpoint
					}
					p2mp {
						set value pointToMultipoint
					}
					default {
						set value broadcast
					}
				}
				set network_type $value
			}
            -discard_lsp {
            	set discard_lsp $value
            }
			-enable_wide_metric {
				set enable_wide_metric $value
			}
            -interface_metric -
            -metric {
            	set metric $value
            }
            -hello_interval {
            	set hello_interval $value  	    	
            }
            -dead_interval {
            	set dead_interval $value  	    	
            }

            -vlan_id {
            	set vlan_id $value
            }
			-lSP_RefreshRate -
            -lsp_refreshtime {
            	set lsp_refreshtime $value
            }
            -lsp_lifetime {
            	set lsp_lifetime $value
            }
			-mac_addr {
                set value [ MacTrans $value ]
                if { [ IsMacAddress $value ] } {
                    set mac_addr $value
                } else {
                   Deputs "wrong mac addr: $value"
                    error "$errNumber(1) key:$key value:$value"
                }
				
			}
			-ipv6_addr {
				set ipv6_addr $value
			}
			-ipv6_gw {
				set ipv6_gw $value
			}
			-ipv6_prefix_len {
				set ipv6_prefix_len $value
			}
			-ip_version {
				set ip_version $value
			}
			-level {
				set level $value
			}
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_prefix_len {
				set ipv4_prefix_len $value
			}
			-ipv4_gw {
				set ipv4_gw $value
			}
			
		}
    }
	
	
    set devicehandle [$this cget -deviceHandle]
	set isisRouter [ixNet getL $devicehandle isisL3Router]
	if {$isisRouter == ""} {
	    set isisRouter [ixNet add $devicehandle isisL3Router]
	}
	
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObjList [ixNet getL $topoObj deviceGroup]
            foreach deviceGroupObj $deviceGroupObjList {
                set ethernetObj [ixNet getL $deviceGroupObj ethernet]
                	if { [ info exists ip_version ] } {
		                if { [ string tolower $ip_version ] == "ipv6" } {
							if { [ llength [ ixNet getL $ethernetObj ipv4 ] ] } {
				               ixNet remove [ ixNet getL $ethernetObj ipv4 ]
				               ixNet commit
			                }
							if { ![ llength [ ixNet getL $ethernetObj ipv6 ] ] } {
							   set ipv6Obj [ixNet add $ethernetObj ipv6]							   
				               ixNet commit
                           } else {
                               set ipv6Obj [ixNet getL $ethernetObj ipv6]
						   }						   
		                } else {
 						    if { ![ llength [ ixNet getL $ethernetObj ipv4 ] ] } {
				                set ipv4Obj [ixNet add $ethernetObj ipv4]							   
				                ixNet commit
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
				
                if { [ info exists ipv6_addr ] } {
                    if { $ip_version == "ipv6" } {                   
                        Deputs "ipv6: [ixNet getL $ethernetObj ipv6]"
                        Deputs "interface:$ethernetObj"
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -address]/singleValue -value $ipv6_addr
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

                if { [ info exists ipv6_gw ] } {
                    if { $ip_version == "ipv6" } {
                        set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -gatewayIp]/singleValue -value $ipv6_gw
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
				
 				if { [ info exists ipv6_prefix_len ] } {
                    if { $ip_version == "ipv6" } {
					    set ipv6Obj [ixNet getL $ethernetObj ipv6]
                        ixNet setA [ixNet getA $ipv6Obj -prefix]/singleValue -value $ipv6_prefix_len
                        ixNet commit
					}
                }               
            
            
                if { [ info exists mac_addr ] } {
                    ixNet setA [ixNet getA $ethernetObj -mac]/singleValue -value $mac_addr
                    ixNet commit
                }
                if { [ info exists loopback_ipv4_addr ] } {
                    Deputs "not implemented parameter: loopback_ipv4_addr"
                }

				if { [ info exists vlan_id ] } {
				    set vlanObj [ixNet getL $ethernetObj vlan]
					if {$vlanObj == ""} {
					    set vlanObj [ixNet add $ethernetObj vlan]
					}
				    ixNet setA [ixNet getA $vlanObj -vlanId]/singleValue -value $vlan_id
                }	

	            if { [ info exists level ] } {
				
		            switch [ string tolower $level ] {
				        l1 {
				           set level level1
			            }
					    l2 {
				           set level level2
			            }
			            l12 {
				           set level l1l2
			            }
		            }
		             ixNet setA [ixNet getA $isisHandle -levelType]/singleValue -value $level
	            }
	
                if { [ info exists sys_id ] } {		
	               set bridgeDataObj [ixNet getL $deviceGroupObj bridgeData]
		           if {[ llength $bridgeDataObj ] == 0} {
				      set bridgeDataObj [ixNet add $deviceGroupObj bridgeData]
				   }
				   regsub -all {:} $sys_id { } {sys_id}
                   set sys_id \{$sys_id\}
				   
				   ixNet setA [ixNet getA  $bridgeDataObj -systemId]/singleValue -value $sys_id
                   ixNet commit 
				   
                }
				
				if { [ info exists enable_wide_metric ] } {
			       ixNet setA [ixNet getA $isisRouter -enableWideMetric]/singleValue -value $enable_wide_metric

                }
				
				if { [ info exists network_type ] } {
	                ixNet setA [ixNet getA $isisHandle -networkType]/singleValue -value $network_type
                }

                if { [ info exists hello_interval ] } {
	                ixNet setA [ixNet getA $isisHandle -level1HelloInterval]/singleValue -value $hello_interval

                }	

                if { [ info exists discard_lsp ] } {
				    ixNet setA [ixNet getA $isisRouter -discardLSPs]/singleValue -value $discard_lsp

                }
                if { [ info exists metric ] } {
			         ixNet setA [ixNet getA $isisHandle -interfaceMetric]/singleValue -value $metric

                }

                if { [ info exists dead_interval ] } {
		            ixNet setA [ixNet getA $isisHandle -level1DeadInterval]/singleValue -value $dead_interval


                }
                if { [ info exists lsp_refreshtime ] } {
				     ixNet setA [ixNet getA $isisRouter -lSPRefreshRate]/singleValue -value $lsp_refreshtime

                }
                if { [ info exists lsp_lifetime ] } {
		            ixNet setA [ixNet getA $isisRouter -lSPLifetime]/singleValue -value $lsp_lifetime

                } 

                ixNet commit
	
	        }
	    }
	}
	return [GetStandardReturnHeader]

}


body IsisSession::advertise_topo {} {

	set tag "body IsisSession::advertise_topo [info script]"
Deputs "----- TAG: $tag -----"

	foreach route [ ixNet getL $handle routeRange ] {
	
		ixNet setA $route -enabled True
	}
    if {[info exists hNetworkRange ]} {
    
        ixNet setA $hNetworkRange -enabled True
       
    }
    ixNet commit
    return [GetStandardReturnHeader]
}
body IsisSession::withdraw_topo {} {

	set tag "body IsisSession::withdraw_topo [info script]"
Deputs "----- TAG: $tag -----"

	foreach route [ ixNet getL $handle routeRange ] {
	
		ixNet setA $route -enabled False
	}
	if {[info exists hNetworkRange ]} {
	    ixNet setA $hNetworkRange -enabled False
    }
	ixNet commit
    return [GetStandardReturnHeader]
}


class SimulatedRoute {
	inherit SimulatedSummaryRoute
	
	constructor { router } { chain $router } {}
	method config { args } {}

}

body SimulatedRoute::config { args } {
	global errorInfo
    global errNumber
    set tag "body SimulatedRoute::config [info script]"
    Deputs "----- TAG: $tag -----"

	eval chain $args

	foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-route_type {
				set route_type $value
			}
        }
    }
	
	if { [ info exists route_type ] } {
		if { [ string tolower $route_type ] == "internal" } {
			set route_origin false
		} else {
			set route_origin true
		}
		ixNet setA $handle -routeOrigin $route_origin
	}
	
	ixNet commit
}