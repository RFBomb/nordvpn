#!/usr/bin/with-contenv bash

echo "   " ; \
echo "   " ; \
echo "   " ; \
echo "   " ; \
echo "**** Attempting to Log Into NordVPN  ********" ; \
nordvpn login --username $USER --password $PASS ;

if ( ${nordvpn account} == "You are not logged in." )
then
	echo "Login Failure!"
	exit 1 
fi


echo "   " ; \
echo "   " ; \
echo "**** Log In Success! -- Setting up User-Defined Settings **** " ; \
nordvpn set autoconnect ${AUTOCONNECT} ; \
nordvpn set cybersec ${CYBERSEC} ; \
nordvpn set obfuscate ${OBFUSCATE} ; \
nordvpn whitelist add subnet ${HostSubnet} ; \
nordvpn whitelist add subnet ${DockerSubnet} ; \
nordvpn c ${SERVER} ; \
nordvpn status ; \
bash