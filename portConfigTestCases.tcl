lappend auto_path "C:/Keysight/Huawei_Project/Huawei NGPF project/GitRepo/Huawei_Scripts"

package req IxiaNgpfNet
Login 10.23.72.159 1

# Port port51 10.39.70.2/5/1
# Port port50 10.39.64.137/1/4

Port port51 10.39.70.2/5/1
Port port50 10.39.70.2/5/2

Port port52 10.39.70.2/5/3
Port port53 10.39.70.2/5/4

## Port related configurations
port51 config -intf_ip_step 7 -dut_ip "15.13.14.2" -mask 24 -intf_ip "15.13.14.1" -mac_addr "00:00:00:00:00:10" -ipv6_addr "2001::1" -ipv6_addr_step 7 -ipv6_mask 64 -transmit_mode "sequential" -outer_vlan_enable -inner_vlan_enable -outer_vlan_id 250 -inner_vlan_id 200 -inner_vlan_step 2 -inner_vlan_priority 4 -outer_vlan_priority 5 -outer_vlan_step 5 -inner_vlan_num 2 -outer_vlan_num 3 -enable_arp 1 -speed speed1000 -media fiber -auto_neg true -flow_control true -sig_end 1 -duplex half

## Port related configurations
port50 config -intf_ip_step 3 -dut_ip "15.13.14.2" -mask 16 -intf_ip "15.13.14.1" -mac_addr "00:00:00:00:00:10" -ipv6_addr "2001::10" -ipv6_addr_step 7 -ipv6_mask 128 -transmit_mode "interleaved" -outer_vlan_enable -inner_vlan_enable -outer_vlan_id 550 -inner_vlan_id 500 -inner_vlan_step 1 -inner_vlan_priority 4 -outer_vlan_priority 5 -outer_vlan_step 2 -inner_vlan_num 2 -outer_vlan_num 3 -enable_arp 0 -speed speed100 -media fiber -auto_neg true -flow_control true -sig_end 1 -duplex full

port52 config -intf_ip_step 3 -dut_ip "16.13.14.2" -mask 8 -intf_ip "16.13.14.1" -mac_addr "00:00:00:00:00:20" -ipv6_addr "3001::10" -ipv6_addr_step 6 -ipv6_mask 80 -outer_vlan_enable -inner_vlan_enable -inner_vlan_num 1 -outer_vlan_num 2 -media copper -auto_neg true -flow_control false -sig_end 0 -duplex full

port53 config -ipv6_addr "2000::1" -ipv6_gw "2000::2" -ipv6_mask 64 -dut_ipv6 "1000::1"