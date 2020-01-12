#!/usr/bin/with-contenv bash

# Force download the repo lists using Curl
get() { 
	rm $1
	curl -s -o $1 --url $2 ; 
	}

AttemptLogin() {
	echo "********* Attempting to Log Into NordVPN  *********" ; 
	LoginResult=$(nordvpn login --username $(eval echo $USER) --password $(eval echo $PASS) ;) ;

	## Check if Log-In was Successfull -- If not then exit
	CharCount=$( nordvpn account | grep Expires | wc -c ; );
	CharCount2=$( echo '$LoginResult' | grep Username | wc -c ; );
	CharCount3=$( echo '$LoginResult' | grep 'having trouble reaching our servers' | wc -c ; );
	CharCount4=$( echo '$LoginResult' | grep Daemon | wc -c ; );

	if (( $CharCount > 0 ))
	then
		LoginState=Success
	else
		echo "$LoginResult"
		if (( $CharCount2 > 0 ))
		then
			#Bad Username / Password
			LoginState=UserPass
			if ( $DebugLogin ); then 
				echo "Username: $(eval echo $USER)"
				echo "Password: $(eval echo $PASS)"
			fi
		elif (( $CharCount3 > 0 ))
		then
			#Cannot Reach Server
			LoginState=Server
		elif (( $CharCount4 > 0 ))
		then
			#Cannot Reach Server
			LoginState=Daemon
			echo "Attempting to kill stuck processes"
			pkill -f "nordvpn"
			pkill -f "nordvpnd"
			rm -f /run/nordvpnd.sock nordvpn-openvpn.sock
			sleep 1
			echo "Restarting NordVPNd Service"
			exec /usr/sbin/nordvpnd &
		fi
	fi
}

####################################################################################
#	 Update Check
####################################################################################
echo "   " ; \
echo "***************************************************" ; \
echo "******** Checking for internet connection *********" ; \
## Check Internet Connection and exit if failed
if ! ping -c 1 $WebTest &>/dev/null; 
then 
	# Test Fail - Assume No Internet Access
	echo "No Internet Access -- Exiting Container"
	exit 1
else
	# Test OK - Internet Access Available
	echo "Internet Access OK!"
fi

####################################################################################
echo "***************************************************" ;
echo "Checking for updates to NordVPN";
	
	cd /var/lib/apt/lists	
	#get ports.ubuntu.com_ubuntu-ports_dists_bionic-backports_InRelease 'http://ports.ubuntu.com/ubuntu-ports/dists/bionic/InRelease'
	#get ports.ubuntu.com_ubuntu-ports_dists_bionic-security_InRelease 'http://ports.ubuntu.com/ubuntu-ports/dists/bionic-updates/InRelease'
	#get ports.ubuntu.com_ubuntu-ports_dists_bionic-updates_InRelease 'http://ports.ubuntu.com/ubuntu-ports/dists/bionic-backports/InRelease'
	#get ports.ubuntu.com_ubuntu-ports_dists_bionic_InRelease 'http://ports.ubuntu.com/ubuntu-ports/dists/bionic-security/InRelease'
	get repo.nordvpn.com_deb_nordvpn_debian_dists_stable_InRelease 'https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/InRelease'
	
	CharCount=$(apt-get --just-print upgrade | grep nordvpn | wc -c ;)
	if (( $CharCount > 0 )) ; then
		echo "NordVPN Update Required -- Updating"
		#echo "Verify NordVPN scripts won't fault out"
		#sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.postrm
		#sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.prerm		
		#echo "Updating any of the required packages"
		#apt-get -qq install -yqq \
		#		dpkg \
		#		gnupg2
		apt-get install -yqq nordvpn || sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.postinst
		apt-get install -yqq
		apt-get clean 
		rm -rf \
			/tmp/* \
			/var/tmp/*
	else
		echo "NordVPN is up to date"
	fi
echo "***************************************************"


####################################################################################
#	 Start Services and Log In
####################################################################################

echo "********    Starting NordVPNd Service    *********" ; \
exec /usr/sbin/nordvpnd &
sleep 5

echo "***************************************************" ; \
LoginState="Unknown"
AttemptLogin ;

while [ ! "$LoginState" == "Success" ]; do
	if [ "$LoginState" == "UserPass" ]; then exit 1; fi;
	echo "Sleeping ${RetryTime}s before trying again"
	sleep ${RetryTime}
	AttemptLogin ;
done;

echo "***************************************************" ; \
echo "**** Log In Success! -- Setting up User-Defined Settings **** " ; 
if (( $DebugNordVPN ));
then
	nordvpn set protocol ${Protocol} ;
	nordvpn set technology ${Tech} ;
	nordvpn set autoconnect ${AUTOCONNECT} ; 
	nordvpn set cybersec ${CYBERSEC} ; 
	nordvpn set obfuscate ${OBFUSCATE} ; 
	nordvpn whitelist add subnet ${HostSubnet} ; 
	nordvpn whitelist add subnet ${DockerSubnet} ;
	nordvpn set killswitch ${KILLSWITCH} ; 
	nordvpn c ${SERVER} ;
else
	nordvpn set protocol ${Protocol} &>/dev/null;
	nordvpn set technology ${Tech} &>/dev/null;
	nordvpn set autoconnect ${AUTOCONNECT} &>/dev/null;
	nordvpn set cybersec ${CYBERSEC} &>/dev/null;
	nordvpn set obfuscate ${OBFUSCATE} &>/dev/null;
	nordvpn whitelist add subnet ${HostSubnet} &>/dev/null;
	nordvpn whitelist add subnet ${DockerSubnet} &>/dev/null;
	nordvpn set killswitch ${KILLSWITCH} &>/dev/null;
	nordvpn c ${SERVER} &>/dev/null;
fi
echo "***************************************************"
echo "*********     Status       *********" ;
echo " "
nordvpn status ; 
echo " "
echo "********* Current Settings *********" ;
echo " "
nordvpn settings ;
echo " "
echo "*********   Account Notes  *********" ;
echo " "
if (( $DebugNordVPN ));
then
	nordvpn account;
else
	nordvpn account | grep Expires
fi
echo " "
echo "****   Login Script Complete  ****" ;
echo "*********************************************************************************************"
echo "** To connect to a different server:"
echo "       - Attach to the container"
echo "       - Use the command 'nordvpn c [server]' where [server] is the server/group you would like to connect to."
echo "** Additional Whitelist Entries:"
echo "       - Attach to the container"
echo "       - Use the command 'nordvpn whitelist add [options]' to add things to the whitelist."
echo "       - Use the command 'nordvpn whitelist remove [options]' to remove things to the whitelist."
echo "       - Options are:"
echo "		* 'subnet [IP]' where [IP] is the ip adress or subnet you wish to add/remove from the whitelist."
echo "		* 'port [port]' where [port] is single port you wish to add/remove from the whitelist."
echo "		* 'ports [port-range]' where [port-range] is range of ports you wish to add/remove from the whitelist.";
echo "*********************************************************************************************";
