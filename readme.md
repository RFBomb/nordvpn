## NordVPN 

* This container uses linux app provided by NordVPN
* It is running inside a Ubuntu container that has the S6 Overlay installed. 
* I have written an init-script that runs when the container starts up that will attempt to log into the service, then set up the parameters passed using the environment variables, and finally connect to a server. 

## Running on platforms other than ARM
* I am using this on a Raspberry Pi running Raspian. I have compiled the :arm tag on that device.
* Uploading to github lets DockerHub automatically build it for X86, but I am not testing that version.
	- As such, If it does not  work I would recommend downloading the github repository and building it yourself.
	- The one item that most likely has to be changed within the dockerfile is:
			ARG HostArchitecture="armhf"
	- Change that to whichever architecture you need, specified here: https://github.com/just-containers/s6-overlay#releases
			

## Networking

To access the ports of any containers that run behind the vpn, you will likely need a reverse-proxy setup. This requires any ports used by connected containers to be exposed by the NordVPN container. Then, you will have to run a reverse-proxy to provide access to those. (I have also written an easily usable nginx_proxy container you can view here:  rfbomb/easyproxy )

I would recommend using a Docker-Compose file (or Portainer) to run this container, the nginx container, and anything behind it. See below for an example docker-compose setup that also uses the reverse-proxy.

## Attaching to the container
* You can attach to the container like any other. Once you attach, you will have all the commands that NordVPN app provides at your disposal. 
* This includes the following base ones (as well as any other they provide - See their documentation for full details)
  * `nordvpn help` - get list of details about the app
  * `nordvpn c [option]` - Connect to a server. If already connected to a server, change to a different server.
       * [option] should be a server group to connect to. If undefined, nordvpn chooses for you.
  * `nordvpn d` - Disconnect from the server
  * `nordvpn settings` - View all settings for this container
  * `nordvpn set [options] - Modify a setting (see NordVPN website for details)
		
## Environment Variables

* `USER`     - User for NordVPN account.
* `PASS`     - Password for NordVPN account, surrounding the password in single quotes will prevent issues with special characters such as `$`.
* `HostSubnet`     	- NordVPN normally blocks all traffic that isnt through the VPN. Whitelist your host's domain to allow local traffic.
* `DockerSubnet`	- Whitelist the docker subnet to allow container-container communication. Required for any reverse proxies.
* `AUTOCONNECT`     - ON/OFF. Since there is an auto-login script that runs on container start, this is sort of unnecessary to specify. Note: This may reconnect if the connection drops. I haven't tested that much.
* `KILLSWITCH`     	- ON/OFF. Setting this to 'ON' kills this internet connection if the vpn becomes disconnected for any reason. Default is ON.
* `CYBERSEC`     	- Turn on the CyberSecurity features nordvpn provides on their servers. See NordVPN website for details.
* `OBFUSCATE`     	- Turn server obfuscate on or off. See NordVPN website for details.
* `SERVER`     		- Optional -- Decide which server / server group you want to connect to. For NordVPN to decide, just don't specify the argument. ( leave as '' ) (See NordVPN website for details) 
* `Protocol`		- Optional -- Set to TCP / UDP depending on preference. Default is UDP.
* `Tech`			- Optional - OpenVPN / NordLynx -- Set the connection type for NordVPN. Default is OpenVPN
* `WebTest`	   		- Optional -- Container checks for internet connection on startup by pinging specified address. Shuts down container if ping fails. Default address is 'nordvpn.com'.
* `RetryTime`       - optional -- Set delay time between failed login attempts (time in seconds)
* `DebugLogin` 		- Optional -- Set to 'False' by default. If set 'true' then it will show the login information in the log on the event of an incorrect username/password.
* `DebugNordVPN` 	- Optional -- Set to 'False' by default. If set 'true' then it will enable a verbose log during the LoginScript.


## Docker Run

* NordVPN Container
```
    docker run -ti --cap-add=NET_ADMIN --device /dev/net/tun --name vpn \
    -e USER='user@email.com' \
    -e PASS='pas$word' \
    -e HostSubnet=192.168.1.0/24 \
    -e SERVER=P2P \
    -d rfbomb/nordvpn
```
* Secondary Service
```
    docker run -ti --rm --net=container:vpn -d image/yourchoice
```

## Docker Compose

```
version: '2'
services:   
#--------------   VPN  ---------------------------
 vpn:
  image: rfbomb/nordvpn
  container_name: NordVPN
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun
  networks:
      - Bridge
  #Expose all ports required by other services behind the VPN so reverse proxy can access them
  expose:
     - 4040
  environment:
     - USER='user@email.com'
     - PASS='pas$word'
     - HostSubnet=192.168.1.0/24
     - DockerSubnet=172.16.1.0/24
     - AUTOCONNECT=on   # on / off
     - KILLSWITCH=on    # on / off
     - CYBERSEC=off     # on / off
     - OBFUSCATE=off    # on / off
     - SERVER=P2P       # See NordVPN website for details
	 - Protocol=UDP     #optional -- Set to TCP / UDP depending on preference. Default is UDP.
	 - Tech=OpenVPN     #optional - OpenVPN / NordLynx -- Set the connection type for NordVPN. Default is OpenVPN
	 - WebTest=8.8.8.8  #optional -- server to ping to check for internet access
	 - RetryTime=5      #optional -- Set delay time between failed login attempts (time in seconds)
	 - DebugLogin=false #optional -- Show username and password in log on login failure
	 - DebugNordVPN=false #optional -- Show output of nordvpn commands during container startup
  #restart: unless-stopped

#--------------   Services Behind VPN  ---------------------------
 service1:
  image: service1
  network_mode: service:vpn

#--------------   Reverse Proxy  ---------------------------
proxy:
   image: rfbomb/easyproxy
   container_name: ReverseProxy
   stdin_open: true
   tty: true
   networks:
      - Bridge
   #Map all ports that are exposed in the VPN service
   ports:
     - "80:80" 
   volumes:
      - /etc/localtime:/etc/localtime:ro
      - /disks/USB/DockerConfigs/nginx_proxy:/etc/nginx/
   #restart: unless-stopped

#--------------  Network Definition (if desired) ---------------------------
networks:
  Bridge:
    driver: bridge
    ipam:
     driver: default
     config:
      - subnet: 172.16.1.0/24

```

## ChangeLog

1/11/2020
* Updated to latest version of NordVPN (again)
* Updated method of installing NordVPN inside DockerFile to take less steps after a pretty informative conversation via Reddit.
* Heavily changed the LoginScript.sh 
	- Will now notify if an update to the app is available.
		- Assuming that the container's apt-get is broken (from my testing it is) then this will require a rebuild of the app. 
	- Now properly adjusted for single and double quotes in the USER/PASS environment variables.
	- Will now attempt to log into the service every 5 seconds if the server could not be reached ("Its not you its us" error)
	- Added a bugfix to actually be able to restart the container, now that I finally found the problem.
		(It was the socket not releasing inside the container)
	- the NordVPNd service is now started inside the LoginScript. This is so the loginscript can be run with S6 as part of initialization, instead of as a CMD.
		- This also allows the startup process error checking to work properly, instead of possibly fighting S6 overlay.
* Added 'PING' to the container to verify internet access prior to attempting to start everything up.
* Added 'SLURM' to the container - use 'slurm -i eth0' to see usage statistics when attached
* Added a proper FinishScript for when the container exits.
	- These changes allow for restarting the container successfully.
	- The FinishScript will: 
		- log out of NordVPN
		- Kill NordVPN // NordVPNd processes
		- Remove the sockets in use by the services within the container 
	

#12/26/2019
* Updated repo to latest version of NordVPN. 
* Added a PingTest to check for internet Connection on startup
* Modified Login Script to work better / correctly.
* Added WebTest and DebugLogin ENV variables
* Slight changes to dockerfile


# 12/1/2019
* Intial Release
