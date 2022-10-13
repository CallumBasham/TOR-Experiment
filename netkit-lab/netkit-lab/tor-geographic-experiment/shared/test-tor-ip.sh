#!/bin/bash

# For 1000 times
for i in $(seq 200); do

	# Clean the Logs 
	rm -rf /var/log/tor/info.log;

	# Restart tor (forces to reacquire a circuit)
	systemctl restart tor;
	
	# Waits until the log file has been created
	until [ -f /var/log/tor/info.log ]; do
		sleep .01;
	done
	
	# Waits until the Tor circuit has finished building
	until grep -q "Bootstrapped 100%" /var/log/tor/info.log; do
		sleep .01;
	done
	
	# Outputs the IP address part of the CURL response
	curl -s -x socks5://127.0.0.1:9050/ http://124.4.4.253 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> /hostlab/ip-output.txt

done 
