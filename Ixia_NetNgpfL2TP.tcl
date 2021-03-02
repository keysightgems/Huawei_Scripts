
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.0
#===============================================================================
# Change made
# Version 1.0 
#       1. Create


class L2tpHost {
    inherit ProtocolNgpfStackObject
    
    #public variable type
	public variable optionSet
	
	public variable rangeStats
	public variable hostCnt
	public variable hL2tp
    
    constructor { port { onStack null } { hl2tp null } } { chain $port $onStack $hl2tp } {
        set tag "L2tpHost::constructor [info script]"
        Deputs "----- TAG: $tag -----"
        global LoadConfigMode
        
		set portObj [ GetObject $port ]
        
		if { $hl2tp == "null" && $LoadConfigMode == 1  } {
            set hl2tp [GetObjNameFromString $this "null"]
        }
        
        if { $hl2tp != "null" } {
            set eth_hnd [GetValidNgpfHandleObj "l2tp" $hl2tp $hPort]
			if { [llength $eth_hnd] == 2 } {
                set handle [lindex $eth_hnd 1]
                set hL2tp [lindex $eth_hnd 0]
                set handleName [ ixNet getA $handle/l2tpRange -name ]
            } 
        } 
        if { $handle == "" } {
            set handleName $this           
            reborn $onStack
        }
    }
	method reborn { { onStack null } } {}
	method config { args } {}
	method connect { } { start }
	method disconnect { } { stop }
    method abort { } { 
        set tag "body L2tpHost::abort [info script]"
    Deputs "----- TAG: $tag -----"
        ixNet exec abort $hL2tp
      
        return [GetStandardReturnHeader]
    }
	method get_summary_stats {} {}
    method CreateL2tpPerSessionView {} {
        set tag "body L2tpHost::CreateL2tpPerSessionView [info script]"
		Deputs "----- TAG: $tag -----"
        set r_no [expr {int(rand()*100000)}]
		set root [ixNet getRoot]
        set customView          [ ixNet add $root/statistics view ]

        ixNet setMultiAttribute $customView -pageTimeout 25 \
                                                    -type layer23NextGenProtocol \
                                                    -caption "L2tpPerSessionView_$r_no" \
                                                    -visible true -autoUpdate true \
                                                    -viewCategory NextGenProtocol

        ixNet commit
        set view [lindex [ixNet remapIds $customView] 0]
		set advCv [ixNet add $view "advancedCVFilters"]
        set type "Per Port"
        set protocol "L2TP Access Concentrator"

		ixNet setMultiAttribute $advCv -grouping \"$type\" \
                                                             -protocol \{$protocol\} \
                                                             -availableFilterOptions \{$type\} \
                                                             -sortingStats {}
        ixNet commit

        set advCv [lindex [ixNet remapIds $advCv] 0]

        set ngp [ixNet add $view layer23NextGenProtocolFilter]
        ixNet setMultiAttribute $ngp -advancedFilterName \"No\ Filter\" -advancedCVFilter $advCv  -protocolFilterIds [list ] -portFilterIds [list ]
        ixNet commit
        set ngp [lindex [ixNet remapIds $ngp] 0]

        set stats [ixNet getList $view statistic]
        puts $stats
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
}
body L2tpHost::reborn { { onStack null } } {
    
	set tag "body L2tpHost::reborn [info script]"
	Deputs "----- TAG: $tag -----"
		
	chain 

	if { [ catch {
        set hPort   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in L2tpSession ctor"
    }
   
    Deputs "stack: $stack"
	set sg_ethernet $stack
	#-- add pppox endpoint stack
    set sg_l2tp ""
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
        set sg_l2tp [ixNet add $ipv4Obj lac]
        ixNet commit

        set sg_l2tp [ ixNet remapIds $sg_l2tp ]
        ixNet setA $sg_l2tp -name $this
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
                        if { [llength $ipv4Obj] != 0 } {
                            set sg_l2tp [ixNet getL $ipv4Obj lac]
                            if {[llength $sg_l2tp] != 0} {
                                set sg_l2tp [ ixNet remapIds $sg_l2tp ]
                            } else {
                                set sg_l2tp [ixNet add $ipv4Obj lac]
                                ixNet commit
                                set sg_l2tp [ ixNet remapIds $sg_l2tp ]
                            }

                        } else {
                            set ipv4Obj [ixNet add $ethernetObj ipv4]
                            ixNet commit
                            set sg_l2tp [ixNet add $ipv4Obj lac]
                            ixNet commit
                            set sg_l2tp [ ixNet remapIds $sg_l2tp ]
                        }
                   }
                }
            }
        }
        ixNet setA $sg_l2tp -name $this
        ixNet commit
    }

    Deputs "sg_l2tp: $sg_l2tp"
    #ixNet setA $sg_l2tp -name $this
    ixNet commit
    set sg_l2tp [lindex [ixNet remapIds $sg_l2tp] 0]
    set hL2tp $sg_l2tp

    #-- add range on the ethernet 

	set deviceGroupObj [GetDependentNgpfProtocolHandle $hL2tp "deviceGroup"]		
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
		ixNet setA [ixNet getA $macPoolsObj -enableVlans]/singleValue -value false
		ixNet commit  
        
        set ipPoolObj [ixNet add $networkGroupObj "ipv4PrefixPools"]
				ixNet commit
		   	    ixNet setM $ipPoolObj -addrStepSupported true -name "Basic\ IPv4\ Addresses\ 1"
				ixNet commit

		}

	ixNet setM $sg_l2tp -multiplier 1 -active true -name $this
    
    ixNet commit
    set sg_l2tp [ixNet remapIds $sg_l2tp]
    
    set handle $sg_l2tp
	
	ixNet commit
}

body L2tpHost::config { args } {
    global errorInfo
    global errNumber

	set tag "body L2tpHost::config [info script]"
	Deputs "----- TAG: $tag -----"
		puts "arg: $args"
    eval { chain } $args
	puts "arg1: $args"
    set ENcp       [ list ipv4 ipv6 ipv4v6 ]
    set EAuth      [ list none auto chap_md5 pap ]

	#param collection
	Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {			
			-session_per_tunnel_count {
                set session_per_tunnel_count $value 
                
			}
			-session_num {
                set session_num  $value 
                
			}
			-tunnel_destination_ip {
                set tunnel_destination_ip $value
                
			}
			-tunnel_authentication {
				set tunnel_authentication $value
                
                #hostname|none
			}
			-tunnel_host {
				set tunnel_host $value
			}
			-tunnel_secret {
				set tunnel_secret $value
			}
			-ipcp_encap {
				set ipcp_encap [string tolower $value]
                #ipv4|ipv6|ipv4v6
			}
            -session_auth_type {
				set session_auth_type [string tolower $value]
			}
			-session_user {
				set session_user $value
			}
            -session_password {
				set session_password $value
			}
			-mru {
				set mru $value
			}
            -ip_type {
				set ip_type [string tolower $value]
                if { $ip_type == "ipv4" } {
                    set ip_type "IPv4"
                }
                if { $ip_type == "ipv6" } {
                    set ip_type "IPv6"
                }
			}
            -ip_address {
				set ip_address $value
			}
            -ip_gateway {
				set ip_gateway $value
			}
            -ip_mask {
				set ip_mask $value
			}
        }
    }

    if { [ info exists ip_type ] } {
		#set ipPattern [ixNet getA [ixNet getA $handle -ipType] -pattern]
		#SetMultiValues $handle "-ipType" $ipPattern $ip_type
	}
    set ipObj [GetDependentNgpfProtocolHandle $handle "ipv4"]
    if { [ info exists ip_address ] } {
		set ipPattern [ixNet getA [ixNet getA $ipObj -address] -pattern]
		SetMultiValues $ipObj "-address" $ipPattern $ip_address
	}
    
    if { [ info exists ip_gateway ] } {
		set ipPattern [ixNet getA [ixNet getA $ipObj -gatewayIp] -pattern]
		SetMultiValues $ipObj "-gatewayIp" $ipPattern $ip_gateway
	}
    
    if { [ info exists ip_mask ] } {
		set ipPattern [ixNet getA [ixNet getA $ipObj -prefix] -pattern]
		SetMultiValues $ipObj "-prefix" $ipPattern $ip_mask
	}
	
	if { [ info exists session_per_tunnel_count ] } {
		ixNet setA $handle -tunnelsPerInterfaceMultiplier $session_per_tunnel_count
	}
	
	if { [ info exists session_num ] } {
		#set ipPattern [ixNet getA [ixNet getA $handle -tunnelsPerInterfaceMultiplier ] -pattern]
		#SetMultiValues $handle "-tunnelsPerInterfaceMultiplier " $ipPattern $session_num
	}
    
    if { [ info exists tunnel_destination_ip ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -baseLnsIp] -pattern]
		SetMultiValues $handle "-baseLnsIp" $ipPattern $tunnel_destination_ip
	}
    
    if { [ info exists tunnel_authentication ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -tunnelAuthentication] -pattern]
		SetMultiValues $handle "-tunnelAuthentication" $ipPattern $tunnel_authentication
	}
    
    if { [ info exists tunnel_host ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -lacHostName] -pattern]
		SetMultiValues $handle "-lacHostName" $ipPattern $tunnel_host
	}
    
    if { [ info exists tunnel_secret ] } {
		set ipPattern [ixNet getA [ixNet getA $handle -lacSecret] -pattern]
		SetMultiValues $handle "-lacSecret" $ipPattern $tunnel_secret
	}
        
   	if { [ info exists mru ] } {
		#set ipPattern [ixNet getA [ixNet getA $handle -mtu] -pattern]
		#SetMultiValues $handle "-mtu" $ipPattern $mru
	}
	
	if { [ info exists ipcp_encap ] } {
		switch $ipcp_encap {
			ipv4 {
				set ipcp_encap IPv4
			}
			ipv6 {
				set ipcp_encap IPv6
			}
			ipv4v6 {
				set ipcp_encap DualStack
			}
		}

		#set ipPattern [ixNet getA [ixNet getA $handle -ncpType] -pattern]
		#SetMultiValues $handle "-ncpType" $ipPattern $ipcp_encap
		
	}
	
	if { [ info exists session_auth_type ] } {
		switch $session_auth_type {
			paporchap {
				set authentication papOrChap
				if { [ info exists session_user ] } {
					ixNet setMultiAttrs $handle/l2tpRange \
					    -papUser $session_user
                    ixNet setMultiAttrs $handle/l2tpRange \
					    -chapName $session_user
				}
				if { [ info exists session_password ] } {
					ixNet setMultiAttrs $handle/l2tpRange \
					   -papPassword $session_password
                    ixNet setMultiAttrs $handle/l2tpRange \
					   -chapSecret $session_password
				}
					
			}
            pap {
                set authentication pap
				if { [ info exists session_user ] } {
					set ipPattern [ixNet getA [ixNet getA $handle -authType] -pattern]
					SetMultiValues $handle "-authType" $ipPattern $authentication
	
				}
				if { [ info exists session_password ] } {
					set ipPattern [ixNet getA [ixNet getA $handle -papPassword] -pattern]
					SetMultiValues $handle "-papPassword" $ipPattern $authentication
	
				}	            }
			chap {
				set authentication chap
				if { [ info exists session_user ] } {
					set ipPattern [ixNet getA [ixNet getA $handle -chapName	] -pattern]
					SetMultiValues $handle "-chapName" $ipPattern $authentication
				}
				if { [ info exists session_password ] } {
					set ipPattern [ixNet getA [ixNet getA $handle -chapSecret] -pattern]
					SetMultiValues $handle "-chapSecret" $ipPattern $authentication
				}			
			}
		}
		#set ipPattern [ixNet getA [ixNet getA $handle -authType] -pattern]
		#SetMultiValues $handle "-authType" $ipPattern $authentication
		
	}

	ixNet commit
	return [GetStandardReturnHeader]
}

body L2tpHost::get_summary_stats {} {
    set tag "body L2tpHost::get_summary_stats [info script]"
    Deputs "----- TAG: $tag -----"
	set root [ixNet getRoot]
	Deputs "root $root"
	set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	#::ixNet::OBJ-/statistics/view:"Global Protocol Statistics"
	#Global Protocol Statistics
	if {[string first "L2TP Access Concentrator Per Port" $viewList] != -1 } {
        set protocol "L2TP Access Concentrator"
		#set view [CreateNgpfProtocolView $protocol]
		set view {::ixNet::OBJ-/statistics/view:"L2TP Access Concentrator Per Port"}
		getStatsView $view $hPort
	}
}

proc getStatsView {view {hPort}} {
	after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
	puts "captionList $captionList"	 
	set port_name				[ lsearch -exact $captionList {Port} ]
    set attempted_count          [ lsearch -exact $captionList {Sessions Total} ]
    set connected_success_count  [ lsearch -exact $captionList {Sessions Up} ]
	
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
	
	set ret "Status : true\nLog : \n"
	if { $portFound } {
		
        set statsItem   "attempted_count"
        set statsVal    [ lindex $row $attempted_count ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]          
              
        set statsItem   "connected_success_count"
        set statsVal    [ lindex $row $connected_success_count ]
        Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
	}

Deputs "ret:$ret"
	
	return $ret
	
}

