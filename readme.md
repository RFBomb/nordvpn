## NordVPN 

* This container uses linux app provided by NordVPN
* It is running inside a Ubuntu container that has the S6 Overlay installed. 
* I have written an init-script that runs when the container starts up that will attempt to log into the service, then set up the parameters passed using the environment variables, and finally connect to a server. 

## IMAGE HAS BEEN COMPILED FOR ARM DEVICES
* I am using this on a Raspberry Pi 4. and (I'll be honest) am not very interested in building the images for other architectures at the moment.
* I have provided all required files on the github page for this container. Running the dockerfile should be able to compile it for other architectures on your computer. 
   * NOTE: You will just have to modify the ARG at the top of the dockerfile for `HostArchitecture`, and it should work ( I think.)

## Networking

To access the ports of any containers that run behind the vpn, you will likely need a reverse-proxy setup. This requires any ports used by connected containers to be exposed by the NordVPN container. Then, you will have to run a reverse-proxy to provide access to those. (I have also written an easily usable nginx_proxy container you can view here:  LinkToNginxContainer )

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
* `HostSubnet`     - NordVPN normally blocks all traffic that isnt through the VPN. Whitelist your host's domain to allow local traffic.
* `DockerSubnet`     - Whitelist the docker subnet to allow container-container communication.
    * This may not be required to function, but I included it in the script just in case.
* `AUTOCONNECT`     - ON/OFF. Since there is an auto-login script that runs on container start, this is sort of unnecessary to specify.
* `KILLSWITCH`     - ON/OFF. The container can cannot to the internet even if nordvpn becomes disconnected. Setting this to 'ON' kills this internet connection if the connection becomes disconnected for some reason.
* `CYBERSEC`     - Turn on the CyberSecurity features nordvpn provides on their servers. See NordVPN website for details.
* `OBFUSCATE`     - Turn server obfuscate on or off. See NordVPN website for details.
* `SERVER`     - Decide which server / server group you want to connect to. For NordVPN to decide, just don't specify the argument. ( leave as '' ) (See NordVPN website for details) 

## Docker Run

* NordVPN Container
```
    docker run -ti --cap-add=NET_ADMIN --device /dev/net/tun --name vpn \
    -e USER=user@email.com \
    -e PASS='pas$word' \
    -e HostSubnet=192.168.1.0/24 \
    -e SERVER=P2P \
    -p 8080:80 \
    -d perfectlylegal/nordvpn
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
  image: perfectlylegal/nordvpn
  container_name: NordVPN
  stdin_open: true
  tty: true
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun
  networks:
      - TS_Bridge
  #Expose all ports required by other services behind the VPN
  expose:
     - 80
     - 9090
  environment:
     - USER=user@email.com
     - PASS='pas$word'
     - HostSubnet=192.168.0.0/24
     - DockerSubnet=172.16.1.0/24
     - AUTOCONNECT=on
     - KILLSWITCH=on
     - CYBERSEC=off
     - OBFUSCATE=off
     - SERVER=P2P
  #restart: unless-stopped

#--------------   Services Behind VPN  ---------------------------
 service1:
  image: service1
  network_mode: service:vpn

#--------------   Reverse Proxy  ---------------------------
proxy:
   image: perfectlylegal/nginx_proxy
   container_name: ReverseProxy
   stdin_open: true
   tty: true
   networks:
      - TS_Bridge
   #Map all ports that are exposed in the VPN service
   ports:
     - "80:80" 
     - "9090:9090"
   volumes:
      - /etc/localtime:/etc/localtime:ro
      - /disks/USB/DockerConfigs/nginx_proxy:/etc/nginx/
   #restart: unless-stopped

#--------------  Network Definition (if desired) ---------------------------
networks:
  TS_Bridge:
    driver: bridge
    ipam:
     driver: default
     config:
      - subnet: 172.16.1.0/24

```
