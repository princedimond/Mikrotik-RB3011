# 2026-02-04 22:36:26 by RouterOS 7.21.2
# software id = TJEN-60KP
#
# model = RB3011UiAS
# serial number = 8EEE0AD2EE45
/interface bridge
add admin-mac=74:4D:28:5F:33:D6 auto-mac=no comment=defconf name=bridge \
    vlan-filtering=yes
/interface vlan
add comment=mgmt-vlan-1 interface=bridge name=VLAN1 vlan-id=1
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/iot lora servers
add address=eu1.cloud.thethings.industries name="TTS Cloud (eu1)" protocol=\
    UDP
add address=nam1.cloud.thethings.industries name="TTS Cloud (nam1)" protocol=\
    UDP
add address=au1.cloud.thethings.industries name="TTS Cloud (au1)" protocol=\
    UDP
add address=eu1.cloud.thethings.network name="TTN V3 (eu1)" protocol=UDP
add address=nam1.cloud.thethings.network name="TTN V3 (nam1)" protocol=UDP
add address=au1.cloud.thethings.network name="TTN V3 (au1)" protocol=UDP
/disk settings
set auto-media-interface=bridge auto-media-sharing=yes auto-smb-sharing=yes
/interface bridge port
add bridge=bridge interface=ether2 pvid=10
add bridge=bridge interface=ether3 pvid=10
add bridge=bridge interface=ether4 pvid=20
add bridge=bridge interface=ether5 pvid=20
add bridge=bridge interface=ether6 pvid=30
add bridge=bridge interface=ether7 pvid=30
add bridge=bridge interface=ether8 pvid=40
add bridge=bridge interface=ether9 pvid=40
add bridge=bridge interface=ether10
add bridge=bridge interface=sfp1
add bridge=bridge interface=ether1
# vlan interface already configured on bridge
add bridge=bridge interface=VLAN1
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface bridge vlan
add bridge=bridge comment=c-vlan tagged=ether1,ether10 untagged=ether2,ether3 \
    vlan-ids=10
add bridge=bridge comment=user-vlan tagged=ether1,ether10 untagged=\
    ether4,ether5 vlan-ids=20
add bridge=bridge comment=guest-vlan tagged=ether1,ether10 untagged=\
    ether6,ether7 vlan-ids=30
add bridge=bridge comment=bt-vlan tagged=ether1,ether10 untagged=\
    ether8,ether9 vlan-ids=40
add bridge=bridge comment=mgmt-vlan tagged=bridge,ether1,ether10 vlan-ids=1
/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=LAN
add interface=ether3 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
add interface=ether6 list=LAN
add interface=ether7 list=LAN
add interface=ether8 list=LAN
add interface=ether9 list=LAN
add interface=ether10 list=LAN
add interface=sfp1 list=LAN
/ip address
add address=10.0.0.3/24 interface=VLAN1 network=10.0.0.0
add address=10.0.0.3/24 interface=ether2 network=10.0.0.0
/ip dhcp-client
# DHCP client can not run on slave or passthrough interface!
add comment=defconf interface=ether1
/ip dhcp-server network
add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=\
    192.168.88.1
/ip dns
set allow-remote-requests=yes servers=1.1.1.1,9.9.9.9,8.8.4.4
/ip dns static
add address=10.0.0.3 comment=defconf name=router.lan type=A
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set h323 disabled=yes
set sip disabled=yes
set pptp disabled=yes
/ip route
add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=10.0.0.2
add gateway=10.0.0.1
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" \
    dst-port=33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
/ipv6 nd
set [ find default=yes ] advertise-dns=yes
/system clock
set time-zone-name=America/Chicago
/system identity
set name=rb3011-switch
/system ntp client
set enabled=yes
/system ntp client servers
add address=0.us.pool.ntp.org
add address=1.us.pool.ntp.org
add address=2.us.pool.ntp.org
add address=3.us.pool.ntp.org
/system script
add dont-require-permissions=no name="FW Rule 1" owner=btadmin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip firewall filter\
    \nadd chain=input protocol=tcp dst-port=22 src-address-list=ssh_blacklist \
    action=drop \\\
    \ncomment=\"drop ssh brute forcers\" disabled=no\
    \nadd chain=input protocol=tcp dst-port=22 connection-state=new \\\
    \nsrc-address-list=ssh_stage3 action=add-src-to-address-list address-list=\
    ssh_blacklist \\\
    \naddress-list-timeout=10d comment=\"\" disabled=no\
    \nadd chain=input protocol=tcp dst-port=22 connection-state=new \\\
    \nsrc-address-list=ssh_stage2 action=add-src-to-address-list address-list=\
    ssh_stage3 \\\
    \naddress-list-timeout=1m comment=\"\" disabled=no\
    \nadd chain=input protocol=tcp dst-port=22 connection-state=new src-addres\
    s-list=ssh_stage1 \\\
    \naction=add-src-to-address-list address-list=ssh_stage2 address-list-time\
    out=1m comment=\"\" disabled=no\
    \nadd chain=input protocol=tcp dst-port=22 connection-state=new action=add\
    -src-to-address-list \\\
    \naddress-list=ssh_stage1 address-list-timeout=1m comment=\"\" disabled=no\
    "
add dont-require-permissions=no name="FW Rule 2" owner=btadmin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip firewall filter\
    \n\
    \nadd chain=input protocol=tcp dst-port=21 src-address-list=ftp_blacklist \
    action=drop \\\
    \ncomment=\"drop ftp attack\""
add dont-require-permissions=no name="FW Rule 3" owner=btadmin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip firewall filter\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"Port scanners to list \" disabled=\
    no \\\
    \nprotocol=tcp psd=21,3s,3,1\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"NMAP FIN Stealth scan\" disabled=n\
    o \\\
    \nprotocol=tcp tcp-flags=fin,!syn,!rst,!psh,!ack,!urg\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"SYN/FIN scan\" disabled=no protoco\
    l=tcp \\\
    \ntcp-flags=fin,syn\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"SYN/RST scan\" disabled=no protoco\
    l=tcp \\\
    \ntcp-flags=syn,rst\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"FIN/PSH/URG scan\" disabled=no pro\
    tocol=\\\
    \ntcp tcp-flags=fin,psh,urg,!syn,!rst,!ack\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"ALL/ALL scan\" disabled=no protoco\
    l=tcp \\\
    \ntcp-flags=fin,syn,rst,psh,ack,urg\
    \nadd action=add-src-to-address-list address-list=\"port scanners\" addres\
    s-list-timeout=2w chain=input comment=\"NMAP NULL scan\" disabled=no proto\
    col=\\\
    \ntcp tcp-flags=!fin,!syn,!rst,!psh,!ack,!urg\
    \nadd action=drop chain=input comment=\"dropping port scanners\" disabled=\
    no src-address-list=\"port scanners\""
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
