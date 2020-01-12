#!/usr/bin/with-contenv bash

## Check Internet Connection and exit if failed
if ! ping -c1 $WebTest &>/dev/null; 
then 
	# Test Fail - Assume No Internet Access
	echo "1"
else
	# Test OK - Internet Access Available
	echo "0"
fi