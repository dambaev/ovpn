# Brief

This container provides simple way to establish vpn connection to SmartPlants
OpenVPN/tcp service and to setup 1:1 NAT to some device, that is local to
resin container

# how to use

start container, log in on it from resin's dashboard and type:

	ovpn.sh <username> <password> <host> <local_host>

where
username is openvpn username
password - password for that user
host - openvpn service host
`local_host` - local IP address to which nat translations should be defined

After work had been performed, you need to run

	ovpn-stop.sh

in order to disconnect ovpn. Or, simply, shutdown ovpn container

# Example

	ovpn.sh somevpnuser supersecret some.host.name 10.0.0.1
