
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.0
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1
#       2. add unconfig

class PppoeHost {
    inherit ProtocolNgpfStackObject 
	public variable hPppox   
    public variable sg_pppoxEndpoint
    
    constructor { port { onStack null } { hPppoe null } } { chain $port $onStack $hPppoe } {
        set tag "PppoeHost::constructor [info script]"
        Deputs "----- TAG: $tag -----"
        global LoadConfigMode
		        
        if { $hPppoe == "null" && $LoadConfigMode == 1  } {
            set hPppoe [GetObjNameFromString $this "null"]
        }
        
        if { $hPppoe != "null" } {
            set eth_hnd [GetValidNgpfHandleObj "pppoe_host" $hPppoe $hPort]
            if { [llength $eth_hnd] == 2 } {
                set handle [lindex $eth_hnd 1]
                set hPppox [lindex $eth_hnd 0]
                set handleName [ ixNet getA $handle -name ]
            }
        }
        
        if { $handle == "" } {
            set handleName $this           
            reborn $onStack
        }
    }
	method reborn { { onStack null } } {}
	method config { args } {}
	method connect { } { 
   
        set tag "body PppoeHost::connect [info script]"
        Deputs "----- TAG: $tag -----"
		start
		return [ GetStandardReturnHeader ]	
	}
	
	method disconnect { } { 
        set tag "body PppoeHost::disconnect [info script]"
        Deputs "----- TAG: $tag -----"
        stop 
        ixNet exec stop $stack 		
		return [ GetStandardReturnHeader ]	
	 }
    method abort { } { 
        set tag "body PppoeHost::abort [info script]"
        Deputs "----- TAG: $tag -----"
        ixNet exec restartDown $sg_pppoxEndpoint      
        return [GetStandardReturnHeader]
    }
	method get_summary_stats {} {}
    method unconfig {} {
        set tag "body PppoeHost::unconfig [info script]"
		Deputs "----- TAG: $tag -----"		
		catch {	
		    chain		
            ixNet remove $sg_pppoxEndpoint
			ixNet commit

		}
    }
    method igmp_over_pppoe {} {}
	method wait_connect_complete { args } {}
	method wait_disconnect_complete {} {}
    
	method CreatePPPoEPerSessionView {} {

        set tag "body PppoeHost::CreatePPPoEPerSessionView [info script]"
		Deputs "----- TAG: $tag -----"
		set type "Per Session"
        set protocol "PPPoX Client"
		set r_no [expr {int(rand()*100000)}]
		set root [ixNet getRoot]
		
		set customView [ixNet add $root/statistics view]
        ixNet setMultiAttribute $customView -pageTimeout 25  -type layer23NextGenProtocol -caption "PPPoXSessionPerSession_$r_no"  -visible true -autoUpdate true -viewCategory NextGenProtocol
        ixNet commit
        set customView [lindex [ixNet remapIds $customView] 0]

        set advCv [ixNet add $customView "advancedCVFilters"]
	
        ixNet setMultiAttribute $advCv -grouping \"$type\"  -protocol \{$protocol\} -availableFilterOptions \{$type\}    -sortingStats {}
        ixNet commit
        set advCv [lindex [ixNet remapIds $advCv] 0]

        set ngp [ixNet add $customView layer23NextGenProtocolFilter]
        ixNet setMultiAttribute $ngp -advancedFilterName \"No\ Filter\"   -advancedCVFilter $advCv -protocolFilterIds [list ] -portFilterIds [list ]
        ixNet commit
        set ngp [lindex [ixNet remapIds $ngp] 0]

        set stats [ixNet getList $customView statistic]
		
        foreach stat $stats {
            ixNet setA $stat -scaleFactor 1
            ixNet setA $stat -enabled true
            ixNet setA $stat -aggregationType first
            ixNet commit
        }
        ixNet setA $customView -enabled true
        ixNet commit
        ixNet execute refresh $customView
        ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
		return $customView
	}
}
body PppoeHost::igmp_over_pppoe {} {
    set tag "body PppoeHost::igmp_over_pppoe [info script]"
    Deputs "----- TAG: $tag -----"
    set igmp_name igmp_[clock seconds]

    IgmpOverPppoeHost $igmp_name $this
    return PppoeHost::$igmp_name
}
body PppoeHost::wait_disconnect_complete {} {
    set tag "body PppoeHost::wait_disconnect_complete [info script]"
    Deputs "----- TAG: $tag -----"
    set timeout 300
	return [GetStandardReturnHeader]
}

body PppoeHost::reborn { { onStack null } } {
    
	set tag "body PppoeHost::reborn [info script]"
	Deputs "----- TAG: $tag -----"	
    set flag 1
	
    if { [ info exists hPort ] == 0 || $hPort == "" } {
        set flag 1
    } else {
		set pppoxObj ""
        set topoObjList [ixNet getL [ixNet getRoot] topology]
        set vportList [ixNet getL [ixNet getRoot] vport]
        if {[llength $topoObjList] != [llength $vportList]} {
            foreach topoObj $topoObjList {
                set vportObj [ixNet getA $topoObj -vports]
				foreach vport $vportList {
					if {$vportObj != $vport && $vport == $hPort} {	
                        # set topoObj [ixNet add [ixNet getRoot] topology -vports $hPort]
						# set deviceGroupObj [ixNet add $topoObj deviceGroup]
						# set deviceGroupObj [ ixNet remapIds $deviceGroupObj ]
						# set sg_ethernet [ixNet add $deviceGroupObj ethernet]
						# ixNet commit
						# set sg_ethernet [lindex [ixNet remapIds $sg_ethernet] 0]
                        set sg_ethernet [CreateProtoHandleFromRoot $hPort]
						set stack $sg_ethernet	
						set flag 0
                    } 
				break  
                }
		    }
		}
		set topoObjList [ixNet getL [ixNet getRoot] topology]

		if { [ llength $topoObjList ] == 0 } {
		    set sg_pppoxEndpoint [CreateProtoHandleFromRoot $hPort pppoxclient]
            set stack [GetDependentNgpfProtocolHandle $sg_pppoxEndpoint ethernet]
			set handle $sg_pppoxEndpoint 
            set flag 0
        } elseif { [ llength $topoObjList ] != 0 } {
            foreach topoObj $topoObjList {		    
                set vportObj [ixNet getA $topoObj -vports]
                Deputs "Checking vport value $vportObj and hPort value $hPort"
			    if {$vportObj == $hPort } {
                    set deviceGroupList [ixNet getL $topoObj deviceGroup]
                    foreach deviceGroupObj $deviceGroupList {
                        set ethernetList [ixNet getL $deviceGroupObj ethernet]
                        foreach sg_ethernet $ethernetList {
							set sg_pppoxEndpoint [ixNet add $sg_ethernet pppoxclient]
							ixNet commit
	                        set sg_pppoxEndpoint [lindex [ixNet remapIds $sg_pppoxEndpoint] 0]
	                        set handle $sg_pppoxEndpoint								
							set stack $sg_ethernet
							set flag 0
	                    }
					}
                } 
            }
        }
    }

	if { $flag } {
    	chain
		set handle $stack
	
	    #-- add pppox endpoint stack
	    if { [llength [ixNet getL $stack pppoxclient]] > 0 } {
            set sg_pppoxEndpoint [lindex [ixNet getL $stack pppoxclient] 0]
        } else {
            set sg_pppoxEndpoint [ixNet add $stack pppoxclient]
			ixNet commit
		    set sg_pppoxEndpoint [ixNet remapIds $sg_pppoxEndpoint]	
        }
		set handle $sg_pppoxEndpoint
	}
	
    #ixNet setA $sg_pppoxEndpoint -name $this
    ixNet commit
}
	

body PppoeHost::config { args } {
    global errorInfo
    global errNumber

	set tag "body PppoeHost::config [info script]"
	Deputs "----- TAG: $tag -----"
		
    eval { chain } $args
	
    set ENcp       [ list ipv4 ipv6 ipv4v6 ]
    set EAuth      [ list none auto chap_md5 pap ]
	#param collection
	Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-mru_size {
				set mru_size $value
			}
            -session_num -
            -count {
                if { [ string is integer $value ] } {
                    set count $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }
			-ipcp_encap {
                set value [ string tolower $value ]
                if { [ lsearch -exact $ENcp $value ] >= 0 } {
                    
                    set ipcp_encap $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-authentication {
                set value [ string tolower $value ]
                if { [ lsearch -exact $EAuth $value ] >= 0 } {
                    
                    set authentication $value
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-enable_domain {
                set trans [ BoolTrans $value ]
                if { $trans == "1" || $trans == "0" } {
                    set enable_domain $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
			}
			-domain {
				set domain $value
			}
			-user_name {
				set user_name $value
			}
			-password {
				set password $value
			}
        }
    }
	if { [ info exists mru_size ] } {
		# ixNet setA [ixNet getA $handle -mtu]/singleValue -value $mru_size
        set pattern  [ixNet getA [ixNet getA $handle -mtu] -pattern]
        SetMultiValues $handle "-mtu" $pattern $mru_size
	}
	
	if { [ info exists ipcp_encap ] } {
		    switch $ipcp_encap {
			ipv4 {
				set ipcp_encap ipv4
			}
			ipv6 {
				set ipcp_encap ipv6
			}
			ipv4v6 {
				set ipcp_encap dual_stack
			}
		}
		# ixNet setA [ixNet getA $handle -ncpType]/singleValue -value $ipcp_encap
        set pattern  [ixNet getA [ixNet getA $handle -ncpType] -pattern]
        SetMultiValues $handle "-ncpType" $pattern $ipcp_encap
		
	    }
	

	if { [ info exists count ] } {
		ixNet setMultiAttrs $handle  -multiplier $count
	}
	
	if { [ info exists authentication ] } {
		switch $authentication {
			auto {
				set authentication pap_or_chap
                if { [ info exists user_name ] } {
				    # ixNet setA [ixNet getA $handle -chapName]/singleValue -value $user_name
        set pattern  [ixNet getA [ixNet getA $handle -chapName] -pattern]
        SetMultiValues $handle "-chapName" $pattern $user_name
					# ixNet setA [ixNet getA $handle -papUser]/singleValue -value $user_name
        set pattern  [ixNet getA [ixNet getA $handle -papUser] -pattern]
        SetMultiValues $handle "-papUser" $pattern $user_name
				}
				if { [ info exists password ] } {
				    # ixNet setA [ixNet getA $handle -chapSecret]/singleValue -value $password
        set pattern  [ixNet getA [ixNet getA $handle -chapSecret] -pattern]
        SetMultiValues $handle "-chapSecret" $pattern $password
					# ixNet setA [ixNet getA $handle -papPassword]/singleValue -value $password
        set pattern  [ixNet getA [ixNet getA $handle -papPassword] -pattern]
        SetMultiValues $handle "-papPassword" $pattern $password
				}
			}
			chap_md5 {
				set authentication chap
				if { [ info exists user_name ] } {
				    # ixNet setA [ixNet getA $handle -chapName]/singleValue -value $user_name
        set pattern  [ixNet getA [ixNet getA $handle -chapName] -pattern]
        SetMultiValues $handle "-chapName" $pattern $user_name
				}
				if { [ info exists password ] } {
				    # ixNet setA [ixNet getA $handle -chapSecret]/singleValue -value $password
        set pattern  [ixNet getA [ixNet getA $handle -chapSecret] -pattern]
        SetMultiValues $handle "-chapSecret" $pattern $password
				}			
			}
            pap {
				set authentication pap
				if { [ info exists user_name ] } {
					# ixNet setA [ixNet getA $handle -papUser]/singleValue -value $user_name
        set pattern  [ixNet getA [ixNet getA $handle -papUser] -pattern]
        SetMultiValues $handle "-papUser" $pattern $user_name

				}
				if { [ info exists password ] } {
					# ixNet setA [ixNet getA $handle -papPassword]/singleValue -value $password
        set pattern  [ixNet getA [ixNet getA $handle -papPassword] -pattern]
        SetMultiValues $handle "-papPassword" $pattern $password

				}
            }				

            none {
				set authentication none
				
			}
			
		}
		# ixNet setA [ixNet getA $handle -authType]/singleValue -value $authentication
        set pattern  [ixNet getA [ixNet getA $handle -authType] -pattern]
        SetMultiValues $handle "-authType" $pattern $authentication
	}
	
	if { [ info exists enable_domain ] } {
		# ixNet setA [ixNet getA $handle -enableDomainGroups]/singleValue -value $enable_domain
        set pattern  [ixNet getA [ixNet getA $handle -enableDomainGroups] -pattern]
        SetMultiValues $handle "-enableDomainGroups" $pattern $enable_domain
	}
	
	if { [ info exists domain ] } {
	    # ixNet setA [ixNet getA $handle -domainList]/string -pattern $domain		
        set pattern  [ixNet getA [ixNet getA $handle -domainList] -pattern]
        SetMultiValues $handle "-domainList" $pattern $domain
	}
    #set sg_pppoxEndpoint $handle
	ixNet commit
	ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
	return [GetStandardReturnHeader]
	
}

body PppoeHost::get_summary_stats {} {
    set tag "body PppoeHost::get_summary_stats [info script]"
    Deputs "----- TAG: $tag -----"
 	
	puts "Sleep 30sec for protocols to start"
    after 30000
	
    set root [ixNet getRoot]
	set view {::ixNet::OBJ-/statistics/view:"PPPoX Client Per Port"}
    Deputs "view:$view"
    set captionList             [ ixNet getA $view/page -columnCaptions ]
    Deputs "caption list:$captionList"
	set port_name				[ lsearch -exact $captionList {Port} ]
    set attempted_count_up          [ lsearch -exact $captionList {Sessions Up} ]
	set connected_down_count          [ lsearch -exact $captionList {Sessions Down} ]
    set ret [ GetStandardReturnHeader ]
	
    set stats [ ixNet getA $view/page -rowValues ]
    Deputs "stats:$stats"
	#set connectionInfo [ ixNet getA $hPort -connectionInfo ]
	
    #Deputs "connectionInfo :$connectionInfo"
    #regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
    #Deputs "chas:$chassis card:$card port$port"

    foreach row $stats {  
        eval {set row} $row
        set rowPortName [ lindex $row $port_name ]
		set portName [ ixNet getA $hPort -name ]
			if { [ regexp $portName $rowPortName ] } {
				set statsItem   "attempted_count_up"
				set statsVal    [ lindex $row $attempted_count_up ]
				Deputs "stats val:$statsVal"
                set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]                
                set statsItem   "connected_down_count"
				set statsVal    [ lindex $row $connected_down_count ]
				Deputs "stats val:$statsVal"
				set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
                Deputs "ret:$ret"
		}

    }
        
    return $ret
}

body PppoeHost::wait_connect_complete { args } {
    set tag "body PppoeHost::wait_connect_complete [info script]"
    Deputs "----- TAG: $tag -----"

	set timeout 300

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -wait_time -
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
		set stats [ get_summary_stats ]
		set initStats [ GetStatsFromReturn $stats attempted_count_up ]
		set succStats [ GetStatsFromReturn $stats connected_down_count ]
        Deputs "initStats:$initStats == succStats:$succStats ?"		
		if { $succStats != "" && $initStats >= $succStats && $initStats > 0 } {
			break	
		}
		
		after 1000
	}
	
	return [GetStandardReturnHeader]
}