#!/bin/bash -ex
USER="$1"
PWD="$2"
GW_IP="$3"
FWD_IP="$4"

function usage(){
	echo "$0 <GW_IP> <FORWARD_IP>"
}

if [ "$USER" == "" ] || [ "$PWD" == "" ] || [ "$GW_IP" == "" ] || [ "$FWD_IP" == "" ]; then
       usage
       exit 1
fi

# stop already running client
ovpn-stop.sh

#run new one
echo "$USER" > ~/secret
echo "$PWD" >> ~/secret
nohup openvpn --dev tun --remote "$GW_IP" --port 8443 --proto tcp-client --tls-client --ca /etc/openvpn/ca.crt --auth-user-pass ~/secret --pull &
# wait while ppp0 will be availabe
TIMEOUT_CNT=60 # timeout seconds
IFACE=""

while [ "$IFACE" == "" ]; do
	ip addr show dev tun0 2>/dev/null >/dev/null && {
		IFACE=tun0
		rm ~/secret
	} || {
		TIMEOUT_CNT=$(( $TIMEOUT_CNT - 1))
		if [ "$TIMEOUT_CNT" == "0" ]; then
			exit 1
		fi
		sleep 1s
	}
done

LOCALIP=$(ip addr show dev tun0 | grep inet | awk '{print $2}' | awk 'BEGIN{FS="/"}{print $1}')
# here we are replacing the end of IP address with ".1" to get gateway's IP address
GATEWAY=${LOCALIP%.*}.1

# setup forwardings
iptables -t nat -N VPNFWDDNAT || true
iptables -t nat -A VPNFWDDNAT -i tun0 -p tcp -m tcp -j DNAT --to-destination $FWD_IP
iptables -t nat -A VPNFWDDNAT -i tun0 -p udp -m udp -j DNAT --to-destination $FWD_IP
iptables -t nat -A VPNFWDDNAT -i tun0 -p icmp --icmp-type any -m icmp -j DNAT --to-destination $FWD_IP


iptables -t nat -N VPNFWDSNAT || true
iptables -t nat -A VPNFWDSNAT -s $GATEWAY/24 -j MASQUERADE
iptables -t nat -A VPNFWDSNAT -o tun0 -j MASQUERADE

# now setup jumps to our chains
iptables -t nat -A POSTROUTING -j VPNFWDSNAT
iptables -t nat -A PREROUTING  -j VPNFWDDNAT

#now tell gateway which device had been connected, so we can track it
wget http://$GATEWAY/sstp-vpn/?uuid="$RESIN_DEVICE_UUID" || true

ip addr show dev tun0 && echo "vpn tunnel looks working" || echo "vpn tunnel looks not working..."

