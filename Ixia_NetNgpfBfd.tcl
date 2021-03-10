
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.1
#===============================================================================
# Change made
# Version 1.0 
#       1. Create

class BfdSession {
    inherit RouterNgpfEmulationObject    
	public variable bfdSession
    constructor { port } {
		global errNumber
		set tag "body BfdSession::ctor [info script]"
        Deputs "----- TAG: $tag -----"
        set portObj [ GetObject $port ]
        set handle ""
        reborn	
	}
	
    method get_stats {} {}
	method reborn {} {
		set tag "body BfdSession::reborn [info script]"
        Deputs "----- TAG: $tag -----"
		set version "ipv4"		
        set ip_version $version
		if { [ catch {
           set hPort   [ $portObj cget -handle ]
        } ] } {
           error "$errNumber(1) Port Object in BfdSession ctor"
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
							set handle [ixNet add $ipv4Obj bfdv4Interface]
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
            set handle [ixNet add $ipv4Obj bfdv4Interface]
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
								set handle [ixNet getL $ipv4Obj bfdv4Interface]
								if {[llength $handle] != 0} {
									set handle [ ixNet remapIds $handle ]
								} else {
									set handle [ixNet add $ipv4Obj bfdv4Interface]
									ixNet commit
									set handle [ ixNet remapIds $handle ]
								}
							} else {
								if { [info exists ipv6Obj] && $ipv6Obj != "" } {
									set handle [ixNet getL $ipv6Obj bfdv6Interface]
									if {[llength $handle] != 0} {
										set handle [ ixNet remapIds $handle ]
									} else {
										set handle [ixNet add $ipv6Obj bfdv6Interface]
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
		
		if { $handle != "" } {
            set rb_interface [GetDependentNgpfProtocolHandle $handle "ethernet"]	
            array set interface [ list ]
        }
		
	    #Enable protocol 		
        set ipPattern [ixNet getA [ixNet getA $handle -active] -pattern]
	    SetMultiValues $handle "-active" $ipPattern True
        ixNet commit
        ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
        ixNet setA $handle -name $this
        Deputs "handle:$handle"
		set protocol bfd
		$this configure -handle $handle
        ixNet commit
	}
	
    method config { args } {}
	method generate_interface { args } {
		set tag "body BfdSession::generate_interface [info script]"
        Deputs "----- TAG: $tag -----"
		foreach int $rb_interface {

			set ipObj [GetDependentNgpfProtocolHandle $handle ip]
	    	if {[string first "ipv4" $ipObj] != -1} {
                set ip_version "ipv4"
                set hInt [ixNet getL $ipObj "bfdv4Interface"] 			
			}
            if {[string first "ipv6" $ipObj] != -1} {
               set ip_version "ipv6"
               set hInt [ixNet getL $ipObj "bfdv6Interface"]
			}

		    if { [llength $ipObj] != 0 } {               
		        set ipPattern [ixNet getA [ixNet getA $hInt -active] -pattern]
	            SetMultiValues $hInt "-active" $ipPattern True			
	            ixNet commit
		        set hInt [ ixNet remapIds $hInt ]
		        set interface($int) $hInt	
            }
		}		
        Deputs "interface: [array get interface]"
	}
}
body BfdSession::get_stats {} {
    set tag "body BfdSession::get_stats [info script]"
    Deputs "----- TAG: $tag -----"

    set root [ixNet getRoot]
    Deputs "root $root"
	
    set viewList [ixNet getL ::ixNet::OBJ-/statistics view]
	if {[string first "BFDv4 IF Per Port" $viewList] != -1 } {
        set protocol "BFDv4 IF"
        set view [CreateNgpfProtocolView $protocol]
        getStatsView $view $hPort
	}
	if {[string first "BFDv6 IF Per Port" $viewList] != -1 } {
        set protocol "BFDv6 IF"
        set view [CreateNgpfProtocolView $protocol]
        getStatsView $view $hPort
	}

}
proc getStatsView {view {hPort}} {
	after 5000
	set captionList [ ixNet getA $view/page -columnCaptions ]
Deputs "captionList $captionList"	
	
	set port_name				[ lsearch -exact $captionList {Stat Name} ]
    set session_conf            [ lsearch -exact $captionList {Sessions Configured} ]
    set session_succ            [ lsearch -exact $captionList {Configured UP-Sessions} ]
    set flap         	        [ lsearch -exact $captionList {Session Flap Count} ]
	
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
    return $ret
}
body BfdSession::config { args } {
	set tag "body BfdSession::config [info script]"
Deputs "----- TAG: $tag -----"
	
	set ip_version ipv4
	set enable_echo 0
	#we can not update count if the protocol is running 
	#set count 1
	set local_disc_step 1	
	
	if { [ catch {
        set hport   [ $portObj cget -handle ]
    } ] } {
        error "$errNumber(1) Port Object in LdpSession ctor"
    }
    set tag "body LdpSession::config [info script]"
    Deputs "----- TAG: $tag -----"
	
Deputs "Args:$args "
	foreach { key value } $args {
		set key [string tolower $key]
		switch -exact -- $key {
			-count {
				set count $value
			}
			-enable_echo {
				set trans [ BoolTrans $value ]
				if { $trans == "1" || $trans == "0" } {
					set enable_echo $value
				} else {
					error "$errNumber(1) key:$key value:$value"
				}
			}
			-echo_rx_interval {
				set echo_rx_interval $value
			}
			-echo_tx_interval {
				set echo_tx_interval $value
			}
			-rx_interval {
				set rx_interval $value
			}
			-tx_interval {
				set tx_interval $value			
			}
			-detect_multiplier {
				set detect_multiplier $value
			}
			-source_ip {
				set source_ip $value
			}
			-peer_ip {
				set peer_ip $value			
			}
			-ip_version {
				set ip_version $value			
			}
			-priority {
				set priority $value			
			}
			-router_id {
				set router_id $value
			}
			-local_disc {
				set local_disc $value				
			}
			-local_disc_step {
				set local_disc_step $value				
			}
			-remote_disc {
				set remote_disc $value
			}
			-authentication {
				set authentication $value
			}
			-password {
				set password $value
			}
			-md5_key {
				set md5_key $value
			}
		}
	}
	if { $handle == "" } {
		reborn
	}
    Deputs "Step10"
    set topoObjList [ixNet getL [ixNet getRoot] topology]
    foreach topoObj $topoObjList {
        set vportObj [ixNet getA $topoObj -vports]
        if {$vportObj == $hPort} {
            set deviceGroupObjList [ixNet getL $topoObj deviceGroup]
            foreach deviceGroupObj $deviceGroupObjList {
                set ethernetObj [ixNet getL $deviceGroupObj ethernet]
                if { [ info exists source_ip ] } {
	                #check if there is interface whose ip is the same as source_ip
		            foreach rb $rb_interface {
			            set ipv4_hdl [ixNet getL $rb ipv4]
						set ipv6_hdl [ixNet getL $rb ipv6]
						#Shankita - Does not have support type argument in NGPF >>>
						#set int_type [GetMultiValues $rb "-type" $ipPattern]
						set int_type "ethernet"		
			            if {$ipv4_hdl != ""} {
							set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -address] -pattern]
							set ip_addr [GetMultiValues $ipv4_hdl "-address" $ipPattern]
							if {$int_type != "ethernet" && $ip_addr == $source_ip} {
								set matched_int $rb
								break
							}						
						
						} else {
							set ipPattern [ixNet getA [ixNet getA $ipv6_hdl -address] -pattern]
							set ip_addr [GetMultiValues $ipv6_hdl "-address" $ipPattern]

							if {$int_type != "ethernet" && $ip_addr == $source_ip} {
								set matched_int $rb
								break
							}						
						}
					}
		            if {![info exists matched_int]} {
		               	set used_int [ lindex $rb_interface 0 ]
		            	foreach rb $rb_interface {

                            set ipv4_hdl [ixNet getL $rb ipv4]
							set ipv6_hdl [ixNet getL $rb ipv6]
							if {$ipv4_hdl != ""} { 
								set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -address] -pattern]
								SetMultiValues $ipv4_hdl "-address" $ipPattern $source_ip	
                
								if { [ info exists peer_ip ] } {
									set ipPattern [ixNet getA [ixNet getA $ipv4_hdl -gatewayIp] -pattern]
									SetMultiValues $ipv4_hdl "-gatewayIp" $ipPattern $peer_ip
								}							
							} else {
								set ipPattern [ixNet getA [ixNet getA $ipv6_hdl -address] -pattern]
								SetMultiValues $ipv6_hdl "-address" $ipPattern $source_ip	
                
								if { [ info exists peer_ip ] } {
									set ipPattern [ixNet getA [ixNet getA $ipv6_hdl -gatewayIp] -pattern]
									SetMultiValues $ipv6_hdl "-gatewayIp" $ipPattern $peer_ip
								}							
							}							
				            ixNet commit
			            }
		            } else {
		             	set used_int $matched_int
		            }

					generate_interface
					
	            	if { $enable_echo } {
                       set ipPattern [ixNet getA [ixNet getA $interface($used_int) -configureEchoSourceIp] -pattern]
			   
			           SetMultiValues $interface($used_int) "-configureEchoSourceIp" $ipPattern True

			           if { $ipv4_hdl != "" } {
                           set ipPattern [ixNet getA [ixNet getA $interface($used_int) -sourceIp4] -pattern]
			               SetMultiValues $interface($used_int) "-sourceIp4" $ipPattern $source_ip	
			           } else {
                           set ipPattern [ixNet getA [ixNet getA $interface($used_int) -sourceIp6] -pattern]
			               SetMultiValues $interface($used_int) "-sourceIp6" $ipPattern $source_ip	
			           }
		            }
		
	            }
                Deputs "Step70"
	            if { [ info exists router_id ] } {
					set routeDataObj [ixNet getL $deviceGroupObj routerData]
					set ipPattern [ixNet getA [ixNet getA $routeDataObj -routerId] -pattern]
					SetMultiValues $routeDataObj "-routerId" $ipPattern $router_id

	            }
                Deputs "Step100"
                if { [ info exists count ] } {
					set bfdSession [ list ]
					for { set index 0 } { $index < $count } { incr index } {			
						ixNet setA $interface($used_int) -noOfSessions $count
						ixNet commit 
						if { $ipv4_hdl != "" } {
							set hSession [ ixNet add $interface($used_int) bfdv4Session ]	
							set ipPattern [ixNet getA [ixNet getA $hSession -active] -pattern]
							SetMultiValues $hSession "-active" $ipPattern True
							if { [ info exists peer_ip ] } {
								set ipPattern [ixNet getA [ixNet getA $hSession -remoteIp4] -pattern]
								SetMultiValues $hSession "-remoteIp4" $ipPattern $peer_ip		
							}
						
						} else {
							set hSession [ ixNet add $interface($used_int) bfdv6Session ]	
							set ipPattern [ixNet getA [ixNet getA $hSession -active] -pattern]
							SetMultiValues $hSession "-active" $ipPattern True
							if { [ info exists peer_ip ] } {
								set ipPattern [ixNet getA [ixNet getA $hSession -remoteIp6] -pattern]
								SetMultiValues $hSession "-remoteIp6" $ipPattern $peer_ip		
							}
						}
						ixNet commit
						lappend bfdSession $hSession
				    }
                    Deputs "Step170"
                    if { [ info exists local_disc ] } {
                        foreach session $bfdSession {
                            set ipPattern [ixNet getA [ixNet getA $session -myDiscriminator] -pattern]
                            SetMultiValues $session "-myDiscriminator" $ipPattern $local_disc
                            incr local_disc $local_disc_step
                        }
                    }
                    Deputs "Step180"
                    if { [ info exists remote_disc ] } {
                        foreach session $bfdSession {
                            set ipPattern [ixNet getA [ixNet getA $session -enableRemoteDiscriminatorLearned] -pattern]
                            SetMultiValues $session "-enableRemoteDiscriminatorLearned" $ipPattern False
                            set ipPattern [ixNet getA [ixNet getA $session -remoteDiscriminator] -pattern]
                            SetMultiValues $session "-remoteDiscriminator" $ipPattern $remote_disc
                        }
                    } else {
                        foreach session $bfdSession {
                            set ipPattern [ixNet getA [ixNet getA $session -enableRemoteDiscriminatorLearned] -pattern]
                            SetMultiValues $session "-enableRemoteDiscriminatorLearned" $ipPattern True
                        }
                    }
			    }
				
                Deputs "Step110"
                if { [ info exists echo_rx_interval ] } {
                    set ipPattern [ixNet getA [ixNet getA $interface($used_int) -echoRxInterval] -pattern]
                    SetMultiValues $interface($used_int) "-echoRxInterval" $ipPattern $echo_rx_interval
                }
                Deputs "Step120"
                if { [ info exists echo_tx_interval ] } {
                    set ipPattern [ixNet getA [ixNet getA $interface($used_int) -echoTxInterval] -pattern]
                    SetMultiValues $interface($used_int) "-echoTxInterval" $ipPattern $echo_tx_interval
                }
                Deputs "Step130"
                if { [ info exists rx_interval ] } {
                    #shankita - min Range 10 - 10000 , clasic support 1- 10000
                    set ipPattern [ixNet getA [ixNet getA $interface($used_int) -minRxInterval] -pattern]
                    SetMultiValues $interface($used_int) "-minRxInterval" $ipPattern $rx_interval
                }
                Deputs "Step140"
                if { [ info exists tx_interval ] } {
                    set ipPattern [ixNet getA [ixNet getA $interface($used_int) -txInterval] -pattern]
                    SetMultiValues $interface($used_int) "-txInterval" $ipPattern $tx_interval
                }
                Deputs "Step150"
                if { [ info exists priority ] } {
                    set ipPattern [ixNet getA [ixNet getA $interface($used_int) -ipDiffServ] -pattern]
                    SetMultiValues $interface($used_int) "-ipDiffServ" $ipPattern $priority
                }
                Deputs "Step160"
                if { [ info exists detect_multiplier ] } {
                    #shankita -::ixNet::ERROR-10000-,BFDv4 IF 1: The multiplier for this layer can only be 1
                    #set ipPattern [ixNet getA [ixNet getA $interface($used_int) -multiplier] -pattern]
                    #SetMultiValues $interface($used_int) "-multiplier" $ipPattern $detect_multiplier
                }

                if { [ info exists authentication ] } {
                    puts "Not implemented "
                }
                if { [ info exists password ] } {
                    puts "Not implemented "
                }
                if { [ info exists md5_key ] } {
                    puts "Not implemented "
                }

			}
		}
	}
    ixNet commit 
    ixNet exec applyOnTheFly  ::ixNet::OBJ-/globals/topology
    return [GetStandardReturnHeader]

}

# (bin) 53 % set bfd [ ixNet getL $port/protocols/bfd router ]
# ::ixNet::OBJ-/vport:1/protocols/bfd/router:1
# (bin) 54 % ixNet help $bfd
# Child Lists:
	# interface (kList : add, remove, getList)
	# learnedInfo (kManaged : getList)
# Attributes:
	# -enabled (readOnly=False, type=kBool)
	# -isLearnedInfoRefreshed (readOnly=True, type=kBool)
	# -routerId (readOnly=False, type=kIPv4)
	# -trafficGroupId (readOnly=False, type=kObjref=null,/traffic/trafficGroup)
# Execs:
	# refreshLearnedInfo (kObjref=/vport/protocols/bfd/router)

# (bin) 55 % ixNet getL $bfd interface
# ::ixNet::OBJ-/vport:1/protocols/bfd/router:1/interface:1
# (bin) 56 % set pi [ixNet getL $bfd interface]
# ::ixNet::OBJ-/vport:1/protocols/bfd/router:1/interface:1
# (bin) 57 % ixNet help $pi
# Child Lists:
	# session (kList : add, remove, getList)
# Attributes:
	# -echoConfigureSrcIp (readOnly=False, type=kBool)
	# -echoInterval (readOnly=False, type=kInteger)
	# -echoSrcIpv4Address (readOnly=False, type=kIPv4)
	# -echoSrcIpv6Address (readOnly=False, type=kIPv6)
	# -echoTimeout (readOnly=False, type=kInteger)
	# -echoTxInterval (readOnly=False, type=kInteger)
	# -enableCtrlPlaneIndependent (readOnly=False, type=kBool)
	# -enabled (readOnly=False, type=kBool)
	# -enableDemandMode (readOnly=False, type=kBool)
	# -flapTxInterval (readOnly=False, type=kInteger)
	# -interfaceId (readOnly=False, type=kObjref=null,/vport/interface, deprecated)
	# -interfaceIndex (readOnly=False, type=kInteger)
	# -interfaces (readOnly=False, type=kObjref=null,/vport/interface,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ipEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ipEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernetEndpoint/range)
	# -interfaceType (readOnly=False, type=kString)
	# -ipDifferentiatedServiceField (readOnly=False, type=kInteger)
	# -minRxInterval (readOnly=False, type=kInteger)
	# -multiplier (readOnly=False, type=kInteger)
	# -pollInterval (readOnly=False, type=kInteger)
	# -txInterval (readOnly=False, type=kInteger)
# Execs:
	# getInterfaceAccessorIfaceList (kObjref=/vport/protocols/bfd/router/interface)

# (bin) 58 % ixNet getL $pi session
# ::ixNet::OBJ-/vport:1/protocols/bfd/router:1/interface:1/session:1
# (bin) 59 % set session [ixNet getL $pi session]
# ::ixNet::OBJ-/vport:1/protocols/bfd/router:1/interface:1/session:1
# (bin) 60 % ixNet help $session
# Attributes:
	# -bfdSessionType (readOnly=False, type=kEnumValue=singleHop,multipleHops)
	# -enabled (readOnly=False, type=kBool)
	# -enabledAutoChooseSource (readOnly=False, type=kBool)
	# -ipType (readOnly=False, type=kEnumValue=ipv4,ipv6)
	# -localBfdAddress (readOnly=False, type=kIP)
	# -myDisc (readOnly=False, type=kInteger)
	# -remoteBfdAddress (readOnly=False, type=kIP)
	# -remoteDisc (readOnly=False, type=kInteger)
	# -remoteDiscLearned (readOnly=False, type=kBool)
