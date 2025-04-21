############################################################################### 

# Topic: Using RouterOS to VLAN your network 

# Example: Router-Switch-AP all in one device 

# Web: https://forum.mikrotik.com/viewtopic.php?t=143620 

# RouterOS: 7.18.2 

# Date: Mar 28, 20 

# Notes: Start with a reset (/system reset-configuration) 

# Thanks: mkx, sindy 

############################################################################### 

 

 

####################################### 

# Naming 

####################################### 

 

 

# name the device being configured 

/system identity set name="RB3011UiAs" 

 

 

####################################### 

# VLAN Overview 

####################################### 

 

 

# 01 = MGMT Vlan 

# 10 = chris 

# 20 = users 

# 30 = guest 

# 40 = bt 

 

 

####################################### 

# Bridge 

####################################### 

 

 

# create one bridge, set VLAN mode off while we configure 

/interface bridge add name=bridge1 protocol-mode=none vlan-filtering=no 

 

 

####################################### 

# 

# -- Access Ports -- 

# 

####################################### 

 

 

# ingress behavior 

/interface bridge port 

 

 

# Purple Trunk to AP. PVID is only needed when combining tagged + untagged 

# trunk (vs fully tagged), but does not hurt so enable. 

add bridge=bridge1 interface=ether1 pvid=99 

add bridge=bridge1 interface=ether2 pvid=99 

 

 

# Guest VLAN (10) 

add bridge=bridge1 interface=ether3 pvid=30 

add bridge=bridge1 interface=ether4 pvid=30 

 

 

# IoT VLAN (20) 

 

 

# BASE_VLAN / Full access (99) 

add bridge=bridge1 interface=ether5 pvid=99 

add bridge=bridge1 interface=ether6 pvid=99 

add bridge=bridge1 interface=ether7 pvid=99 

add bridge=bridge1 interface=ether8 pvid=99 

add bridge=bridge1 interface=ether9 pvid=99 

add bridge=bridge1 interface=ether10 pvid=99 

 

 

# NB: WAN VLAN tagging is not set here because it's not part of bridge 

 

 

# 

# egress behavior 

# 

/interface bridge vlan 

 

 

# Guest, IoT, & BASE VLAN + Purple uplink trunk (ether1) 

# L3 switching so Bridge must be a tagged member 

# In case of fully tagged trunk, set ether1 to tagged for vlan 99 as well (instead of untagged) 

add bridge=bridge1 vlan-ids=10 tagged=bridge1,ether1, ether2 untagged=ether3,ether4 

add bridge=bridge1 vlan-ids=20 tagged=bridge1,ether1, ether2 

add bridge=bridge1 vlan-ids=99 tagged=bridge1                untagged=ether1,ether2,ether5,ether6,ether7,ether8,ether9,ether10 

 

 

####################################### 

# IP Addressing & Routing 

####################################### 

 

 

# LAN facing router's IP address on the BASE_VLAN 

/interface vlan add interface=bridge1 name=BASE_VLAN vlan-id=99 

/ip address add address=10.0.0.3/24 interface=BASE_VLAN 

 

 

# DNS server, set to cache for LAN 

/ip dns set allow-remote-requests=yes servers="10.0.0.3" 

 

 

# From https://forum.mikrotik.com/viewtopic.php?t=90052#p452139 

/interface vlan add interface=sfp1 name=WAN_VLAN vlan-id=34 

 

 

# Set DHCP WAN client on ether6 AND WAN_VLAN 

/ip dhcp-client 

add disabled=no interface=WAN_VLAN 

 

 

####################################### 

# IP Services 

####################################### 

 

 

# Guest VLAN interface creation, IP assignment, and DHCP service 

/interface vlan add interface=bridge1 name=GUEST_VLAN vlan-id=10 

/ip address add interface=GUEST_VLAN address=172.16.10.1/24 

/ip pool add name=GUEST_POOL ranges=172.16.10.100-172.16.10.254 

/ip dhcp-server add address-pool=GUEST_POOL interface=GUEST_VLAN name=GUEST_DHCP disabled=no 

/ip dhcp-server network add address=172.16.10.0/24 dns-server=172.16.99.1 gateway=172.16.10.1 

 

 

# IoT VLAN interface creation, IP assignment, and DHCP service 

/interface vlan add interface=bridge1 name=IoT_VLAN vlan-id=20 

/ip address add interface=IoT_VLAN address=172.16.20.1/24 

/ip pool add name=IoT_POOL ranges=172.16.20.100-172.16.20.254 

/ip dhcp-server add address-pool=IoT_POOL interface=IoT_VLAN name=IoT_DHCP disabled=no 

/ip dhcp-server network add address=172.16.20.0/24 dns-server=172.16.99.1 gateway=172.16.20.1 

 

 

# Optional: Create a DHCP instance for BASE_VLAN. Convenience feature for an admin. 

/ip pool add name=BASE_POOL ranges=172.16.99.100-172.16.99.254 

/ip dhcp-server add address-pool=BASE_POOL interface=BASE_VLAN name=BASE_DHCP disabled=no 

/ip dhcp-server network add address=172.16.99.0/24 dns-server=172.16.99.1 gateway=172.16.99.1 

 

 

####################################### 

# Firewalling & NAT 

# A good firewall for WAN. Up to you 

# about how you want LAN to behave. 

####################################### 

 

 

# Use MikroTik's "list" feature for easy rule matchmaking. 

 

 

/interface list add name=WAN 

/interface list add name=VLAN2WAN 

/interface list add name=VLAN 

/interface list add name=BASE 

 

 

/interface list member 

add interface=sfp1       list=WAN 

add interface=WAN_VLAN   list=WAN 

add interface=BASE_VLAN  list=VLAN2WAN 

add interface=GUEST_VLAN list=VLAN2WAN 

# add interface=IoT_VLAN   list=VLAN2BASE 

add interface=BASE_VLAN  list=BASE 

 

 

add interface=BASE_VLAN  list=VLAN 

add interface=GUEST_VLAN list=VLAN 

add interface=IoT_VLAN   list=VLAN 

 

 

# VLAN aware firewall. Order is important. 

 

 

################## 

# INPUT CHAIN 

################## 

/ip firewall filter 

add chain=input action=accept connection-state=established,related comment="Allow Estab & Related" 

 

 

# Allow BASE_VLAN full access to the device for Winbox, etc. 

add chain=input action=accept in-interface-list=BASE comment="Allow BASE VLAN router access" 

 

 

# Allow IKEv2 VPN server on router 

add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 protocol=udp 

add action=accept chain=input comment="defconf: accept ipsec AH" protocol=ipsec-ah 

add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=ipsec-esp 

 

 

# Allow clients to do DNS, for both TCP and UDP 

add chain=input action=accept dst-port=53 src-address=172.16.0.0/16 proto=tcp comment="Allow all LAN and VPN clients to access DNS" 

add chain=input action=accept dst-port=53 src-address=172.16.0.0/16 proto=udp comment="Allow all LAN and VPN clients to access DNS" 

 

 

add chain=input action=drop comment="Drop" 

 

 

################## 

# FORWARD CHAIN 

################## 

/ip firewall filter 

add chain=forward action=accept connection-state=established,related comment="Allow Estab & Related" 

 

 

# Allow selected VLANs to access the Internet 

add chain=forward action=accept connection-state=new in-interface-list=VLAN2WAN out-interface-list=WAN comment="VLAN Internet Access only" 

 

 

# Allow IoT IoT_VLAN to access server in BASE_VLAN, but no WAN. 

add chain=forward action=accept connection-state=new in-interface=IoT_VLAN  out-interface=BASE_VLAN dst-address=172.16.99.2 comment="Allow IoT_VLAN -> server in BASE_VLAN" 

add chain=forward action=accept connection-state=new in-interface=BASE_VLAN out-interface=IoT_VLAN  comment="Allow all of BASE_VLAN -> IoT_VLAN" 

 

 

# Allow IPSec traffic from 172.16.30.0/24 

add action=accept chain=forward comment="DEFAULT: Accept In IPsec policy." ipsec-policy=in,ipsec src-address=172.16.30.0/24 

add action=accept chain=forward comment="DEFAULT: Accept Out IPsec policy." disabled=yes ipsec-policy=out,ipsec 

 

 

add chain=forward action=drop comment="Drop" 

 

 

################## 

# NAT 

################## 

/ip firewall nat 

add chain=srcnat action=masquerade out-interface-list=WAN comment="Default masquerade" 

add action=masquerade chain=srcnat comment="Hairpin NAT https://www.steveocee.co.uk/mikrotik/hairpin-nat/" dst-address=172.16.99.2 out-interface=BASE_VLAN src-address=172.16.0.0/16 

 

 

################## 

# Disable unused service ports, whatever this is 

################## 

/ip firewall service-port 

set ftp disabled=yes 

set tftp disabled=yes 

set irc disabled=yes 

set h323 disabled=yes 

set sip disabled=yes 

set pptp disabled=yes 

set udplite disabled=yes 

set sctp disabled=yes 

 

 

####################################### 

# VLAN Security 

####################################### 

 

 

# Only allow ingress packets without tags on Access Ports 

/interface bridge port 

# Only  

# set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether2] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether3] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether4] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether5] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether6] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether7] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether8] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether9] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether10] 

 

 

 

 

/interface bridge port 

# For fully tagged trunk (management VLAN also tagged) 

#set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged [find interface=ether1] 

 

 

# For tagged + untagged trunk (management VLAN being untagged), we allow both type of frames 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-all [find interface=ether1] 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-all [find interface=ether2] 

# Only allow tagged packets on WAN port 

set bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged [find interface=sfp1] 

 

 

####################################### 

# MAC Server settings 

####################################### 

 

 

# Ensure only visibility and availability from BASE_VLAN, the MGMT network 

/ip neighbor discovery-settings set discover-interface-list=BASE 

/tool mac-server mac-winbox set allowed-interface-list=BASE 

/tool mac-server set allowed-interface-list=BASE 

 

 

####################################### 

# Turn on VLAN mode 

####################################### 

/interface bridge set bridge1 vlan-filtering=yes 

 

 

############################################################################### 

# Topic: Set static DHCP leases, DNS & firewall forward rules 

# Web: https://www.techonia.com/5759/fixed-static-address-mikrotik-dhcp http://www.icafemenu.com/how-to-port-forward-in-mikrotik-router.htm 

############################################################################### 

 

 

/ip dns static 

add address="10.0.0.3" name="rb3011" place-before=0 ttl="01:00:00" 

add address="10.0.0.3" name="rb3011.lan" place-before=0 ttl="01:00:00" 

 

 

# Trusted VLAN / BASE_DHCP 

 

 

## Network infra (1-20) 

# /ip dhcp-server lease add address=172.16.99.1 server=BASE_DHCP mac-address=E4:8D:8C:2A:70:19 comment="rb2011" 

/ip dns static add address=172.16.99.1 name="rb2011.lan" place-before=0 ttl="01:00:00" comment="infrastructure" 

/ip dns static add address=172.16.99.1 name="rb2011" place-before=0 ttl="01:00:00" comment="infrastructure" 

 

 

 

 

# Set forward rules 

/ip firewall nat 

add chain=dstnat action=dst-nat disabled=no dst-port=80    in-interface-list=WAN protocol=tcp to-addresses=172.16.99.2 to-ports=80 comment="Forward HTTP from WAN to server" 

add chain=dstnat action=dst-nat disabled=no dst-port=443   in-interface-list=WAN protocol=tcp to-addresses=172.16.99.2 to-ports=443  comment="Forward HTTPS from WAN to server" 

 

 

add chain=dstnat action=dst-nat disabled=no dst-port=500 in-interface-list=WAN protocol=udp to-addresses=172.16.99.2 to-ports=500   comment="Forward IKEv2 ESP from WAN to server" 

add chain=dstnat action=dst-nat disabled=no dst-port=4500 in-interface-list=WAN protocol=udp to-addresses=172.16.99.2 to-ports=4500   comment="Forward IKEv2 AH from WAN to server" 

 

 

 

 

/ip firewall filter 

add chain=forward action=accept connection-nat-state=dstnat connection-state=new in-interface-list=WAN src-address=!172.16.0.0/16 comment="Allow port forwarding from outside to network"  

 

 

############################################################################### 

# Topic: setting up QoS 

# Web: https://www.reddit.com/r/mikrotik/comments/7pl4f6/managing_bufferbloat_with_mikrotik/ 

# Notes: Start with a reset (/system reset-configuration) 

############################################################################### 

 

 

/ip firewall filter 

set [find where action=fasttrack-connection] disabled=yes 

/queue type 

add kind=sfq name=sfq-default sfq-perturb=10 

# Limit all VLANs and VPN clients, so target all /16 subnets 

# TODO: ignore VPN clients here because they are already limited by WAN? 

/queue simple 

add max-limit=48M/48M name=sfq-default queue=sfq-default/sfq-default target=172.16.0.0/16 

# set [find where name=sfq-default] max-limit=48M/48M 

 

 

# Prioritize some traffic 

# https://docs.microsoft.com/en-us/microsoftteams/prepare-network 

# https://forum.mikrotik.com/viewtopic.php?t=73214 

# https://itimagination.com/mikrotik-voip-qos-simple-queues/ 

 

 

############################################################################### 

# Topic: setting up QoS while maintaining fast track 

# Web: https://wiki.mikrotik.com/wiki/Manual:Queue#Queue_Tree 

# Notes: Start with a reset (/system reset-configuration) 

############################################################################### 

 

 

/ip firewall filter 

set [find where action=fasttrack-connection] disabled=yes 

/queue type 

add kind=sfq name=sfq-default sfq-perturb=10 

# Limit all VLANs and VPN clients, so target all /16 subnets 

# TODO: ignore VPN clients here because they are already limited by WAN? 

/queue simple 

add max-limit=48M/48M name=sfq-default queue=sfq-default/sfq-default target=172.16.0.0/16 

# set [find where name=sfq-default] max-limit=48M/48M 

 

 

 

 

############################################################################### 

# Topic: Various settings / tweaks 

############################################################################### 

 

 

/lcd set backlight-timeout=1m 

 

 

# set enabled=yes primary-ntp="94.198.159.10" secondary-ntp="185.255.55.20" #0.nl.pool.ntp.org 

/system ntp client 

set enabled=yes primary-ntp=149.210.142.45 secondary-ntp=95.46.198.21 

# /system ntp client 

# set enabled=yes server-dns-names="0.nl.pool.ntp.org,1.nl.pool.ntp.org,2.nl.pool.ntp.org" 

 

 

/system clock 

set time-zone-name=America/New_York 

 

 

/user ssh-keys import user=admin public-key-file="id_rsa.pub" 

 

 

 

 

############################################################################### 

# Topic: Enable IPv6 with stateless autoconfig 

# Web: https://wiki.mikrotik.com/wiki/Manual:System/Packages # https://wiki.mikrotik.com/wiki/Manual:IPv6/ND#Stateless_autoconfiguration_example https://www.netdaily.org/tag/mikrotik-ipv6-home-example/ https://wiki.mikrotik.com/wiki/Manual:Securing_Your_Router#IPv6 

# Notes: Start with a reset (/system reset-configuration) 

############################################################################### 

 

 

# One-time only 

# /system package enable ipv6 

# /system reboot 

 

 

# https://wiki.mikrotik.com/wiki/Manual:IPv6/ND#Stateless_autoconfiguration_example 

 

 

# FIXME: Get DNS from router? https://forum.mikrotik.com/viewtopic.php?p=651811 

# /ip dns set server=2001:db8::2 

# /ipv6 nd set [f] advertise-dns=yes 

 

 

# needed for IPv6 DNS discovery? 

#/ip neighbor discovery-settings 

#set discover-interface-list=LAN 

 

 

/ipv6 settings set accept-router-advertisements=yes 

 

 

/ipv6 pool add name=BASE_POOL6 prefix-length=56 prefix=fded:99::/48 

/ipv6 address add address=::1 eui-64=yes from-pool=BASE_POOL6 interface=BASE_VLAN 

/ipv6 nd set [ find default=yes ] interface=BASE_VLAN ra-interval=20s-1m other-configuration=yes 

 

 

/ipv6 pool add name=GUEST_POOL6 prefix-length=56 prefix=fded:10::/48 

/ipv6 address add address=::1 eui-64=yes from-pool=GUEST_POOL6 interface=GUEST_VLAN 

/ipv6 nd add interface=GUEST_VLAN ra-interval=20s-1m 

 

 

/ipv6 pool add name=IoT_POOL6 prefix-length=56 prefix=fded:20::/48 

/ipv6 address add address=::1 eui-64=yes from-pool=IoT_POOL6 interface=IoT_VLAN 

/ipv6 nd add interface=IoT_VLAN ra-interval=20s-1m 

 

 

# IPv6 basic firewall https://wiki.mikrotik.com/wiki/Manual:Securing_Your_Router#IPv6 

/ipv6 firewall filter 

add chain=input action=accept connection-state=established,related comment="allow established and related"  

add chain=input action=drop   connection-state=invalid comment="defconf: drop invalid"  

add chain=input action=accept protocol=icmpv6 comment="accept ICMPv6" 

add chain=input action=accept protocol=udp port=33434-33534 comment="defconf: accept UDP traceroute" 

add chain=input action=accept protocol=udp dst-port=546 src-address=fe80::/16 comment="accept DHCPv6-Client prefix delegation." 

# add chain=input action=drop in-interface=sit1 log=yes log-prefix=dropLL_from_public src-address=fe80::/16 # not needed, we do not allow any link local 

# add chain=input action=accept comment="allow allowed addresses" src-address-list=allowed 

add chain=input action=accept in-interface-list=BASE comment="Allow BASE VLAN router access" 

add chain=input action=drop 

 

 

add chain=forward action=accept comment="defconf: accept established,related,untracked" connection-state=established,related,untracked  

add chain=forward action=drop comment="defconf: drop invalid" connection-state=invalid 

add chain=forward action=drop comment="defconf: rfc4890 drop hop-limit=1" hop-limit=equal:1 protocol=icmpv6 

add chain=forward action=accept comment="defconf: accept ICMPv6" protocol=icmpv6 

add chain=forward action=drop comment="defconf: drop everything else not coming from LAN" in-interface-list=!VLAN 

# add action=accept chain=input comment="defconf: accept established,related,untracked" connection-state=established,related,untracked 

# add action=accept chain=input comment="defconf: accept ICMPv6" protocol=icmpv6 

# add action=accept chain=input comment="defconf: accept UDP traceroute" port=33434-33534 protocol=udp 

# add action=accept chain=input comment="defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=udp src-address=fe80::/10 

# add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 protocol=udp 

# add action=accept chain=input comment="defconf: accept ipsec AH" protocol=ipsec-ah 

# add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=ipsec-esp 

# add action=accept chain=input comment="defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec 

# add action=drop chain=input comment="defconf: drop everything else not coming from LAN" in-interface-list=!LAN 

# add chain=forward action=drop comment="defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6 

# add chain=forward action=drop comment="defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6 

# add chain=forward action=accept comment="defconf: accept HIP" protocol=139 

# add chain=forward action=accept comment="defconf: accept IKE" dst-port=500,4500 protocol=udp 

# add chain=forward action=accept comment="defconf: accept ipsec AH" protocol=ipsec-ah 

# add chain=forward action=accept comment="defconf: accept ipsec ESP" protocol=ipsec-esp 

# add chain=forward action=accept comment="defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec 

 

 

# /ipv6 firewall address-list 

# add address=fe80::/16 list=allowed 

# add address=xxxx::/48  list=allowed 

# add address=ff02::/16 comment=multicast list=allowed 

 
