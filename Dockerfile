FROM ubuntu:latest

ARG OverlayVersion="1.22.1.0"
ARG HostArchitecture="armhf"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${OverlayVersion}/s6-overlay-${HostArchitecture}.tar.gz /tmp/

RUN \
	echo " " && echo " " && echo " " && \
	echo "****  Install S6 Overlay  ****" && \
	tar xzf /tmp/s6-overlay*.tar.gz -C / && \
	echo "  " && echo "**** Install Base Packages Required ****" && \
	apt-get -qq update && \
	apt-get -qq install -yqq \
		wget \
		dpkg \
		gnupg2 \
		bash \
		iputils-ping \
		curl \
		slurm
	
RUN \
	echo " " && echo " " && echo " " && \
	echo "**** Install NordVPN Application ****" && \
	cd /tmp && \
	wget -qnc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb && \
	dpkg -i nordvpn-release_1.0.0_all.deb && \
	apt-get -qq update && \
	apt-get install -yqq nordvpn || \
		sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.postinst && \
		apt-get install -yqq && \
	sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.postrm && \
	sed -i "s/init)/$(ps --no-headers -o comm 1))/" /var/lib/dpkg/info/nordvpn.prerm && \
	chmod ugo+w /var/lib/nordvpn/data/	&& \
	echo " " && echo " " && \
	echo "**** cleanup ****" && \
	apt-get clean && \ 
	apt-get autoremove --purge && \
	rm -rf \
		/tmp/* \		
		/var/tmp/*

##Declare Environment Variables for User
ENV \
	USER=""  \	
	PASS=""  \
	HostSubnet="192.168.0.0/24" \
	DockerSubnet="172.20.1.0/24" \
	AUTOCONNECT=off  \
	KILLSWITCH=on \
	CYBERSEC=off \
	OBFUSCATE=off \
	SERVER="" \
	WebTest="nordvpn.com" \
	Tech=OpenVPN \
	Protocol=UDP \
	RetryTime=5 \
	DebugLogin=false \
	DebugNordVPN=false 

##Declare Environment Variables for application services
ENV \
	App=/usr/bin/nordvpn \
	Service="/etc/init.d/nordvpn" \
	SystemService="/usr/lib/systemd/system/nordvpnd.service" \
	Socket="/usr/lib/systemd/system/nordvpnd.socket" \
	SBin="/usr/sbin/nordvpnd"
	
COPY root/ /

ENTRYPOINT ["/init"]