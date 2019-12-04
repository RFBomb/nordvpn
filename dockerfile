FROM ubuntu:latest

ARG OverlayVersion="1.22.1.0"
ARG HostArchitecture="armhf"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${OverlayVersion}/s6-overlay-${HostArchitecture}.tar.gz /tmp/
RUN \
	echo "****  Install S6 Overlay  ****" && \
	tar xzf /tmp/s6-overlay*.tar.gz -C / && \
	echo "  " && echo "**** Install Base Packages Required ****" && \
	apt-get -qq update && \
	apt-get -qq install -yqq \
		wget \
		dpkg \
		curl \
		gnupg2 \
		nano \
	
RUN \
	echo " " && echo "**** Install NordVPN Application ****" && \
	cd /tmp && wget -qnc https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb && \
	dpkg -i nordvpn-release_1.0.0_all.deb && \
	apt-get -qq update && \
	apt-get -qq download nordvpn && \
	dpkg --unpack nordvpn*.deb && \
	rm /var/lib/dpkg/info/nordvpn*.postinst -f && \
	apt-get install -yf && \
	chmod ugo+w /var/lib/nordvpn/data/		

ENV \
	USER=""  \	
	PASS=""  \
	HostSubnet="192.168.0.0/24" \
	DockerSubnet="172.0.0.0/24" \
	AUTOCONNECT=on  \
	KILLSWITCH=on \
	CYBERSEC=off \
	OBFUSCATE=off \
	SERVER="P2P" \
	App=/usr/bin/nordvpn \
	Service="/etc/init.d/nordvpn start" \
	SystemService="/usr/lib/systemd/system/nordvpnd.service" \
	Socket="/usr/lib/systemd/system/nordvpnd.socket" \
	SBin="/usr/sbin/nordvpnd"
	
COPY root/ /

RUN \
	echo "**** cleanup ****" && \
	apt-get clean && \ 
	apt-get autoremove --purge && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists* \
		/var/tmp/*

	
ENTRYPOINT ["/init"]
CMD  ["/LoginScript.sh"]
