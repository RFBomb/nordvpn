#!/usr/bin/with-contenv bash
echo "Logging out of NordVPN"
nordvpn logout

echo "Killing NordVPN services so that container can successfully restart"
pkill nordvpn
pkill nordvpnd
rm -f nordvpn.sock nordvpn-openvpn.sock