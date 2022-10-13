#!/bin/bash

printf "\n\nThis script works on [Netkit version 1.1.4], untested on others!\n\n";
sleep 1;

# Asks then User Questions about how they'd like the Lab Setup
user_selection() {
	# How many Directory Autrhority Nodes
	while :; do
		read -ep 'Enter # of Directory Authority Nodes (0 - 50): ' param_DirAuthCount
		[[ $param_DirAuthCount =~ ^[[:digit:]]+$ ]] || continue
		(( ( (param_DirAuthCount=(10#$param_DirAuthCount)) <= 50 ) && param_DirAuthCount >= 0 )) || continue
		break
	done
	printf "You've selected: $param_DirAuthCount Directory Authority Nodes to be created, next...\n\n";

	# How many Standard Relay Nodes
	while :; do
		read -ep 'Enter # of Standard Relay Nodes (0 - 50): ' param_RelayNodeCount
		[[ $param_RelayNodeCount =~ ^[[:digit:]]+$ ]] || continue
		(( ( (param_RelayNodeCount=(10#$param_RelayNodeCount)) <= 50 ) && param_RelayNodeCount >= 0 )) || continue
		break
	done
	printf "You've selected: $param_RelayNodeCount Relay Nodes to be created, next...\n\n";

	# How many Tor Exit Nodes (of the relay nodes)
	while :; do
		read -ep 'Enter # of Relay Nodes that should also be Exit Nodes (0 - 50): ' param_ExitNodeCount
		[[ $param_ExitNodeCount =~ ^[[:digit:]]+$ ]] || continue
		(( ( (param_ExitNodeCount=(10#$param_ExitNodeCount)) <= $param_RelayNodeCount ) && param_ExitNodeCount >= 0 )) || { printf "\n > Must be less or equal to relay count ($param_RelayNodeCount relays) - this CONVERTS the # of relays you selected into EXIT NODES!\n\n"; continue; }
		break
	done
	printf "You've selected: $param_ExitNodeCount Exit Nodes to be created, next...\n\n";

	read -p "Summary: DirAuth's: $param_DirAuthCount, Relay: $param_RelayNodeCount, Exit: $param_ExitNodeCount,  continue? [Y/n]" prompt
	if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
	then
		echo "Processing..."; 
	else
		echo "Exiting...";
	  	exit 0
	fi

	# If the user is running Netkit on a host that is particiularly slow, this is important to improve stability of the code
	printf "\n\n";
	sleepPadding=0;
	read -p "Is your netkit slow? This is important as sleep's are added for padding, these need to be increased if your UML's are slow [Y/n]" prompt
	if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
	then
		echo "Adding additional 5 second padding time..."; 
		((sleepPadding=sleepPadding+5));
	else
		echo "Continuing with no changes...";
	fi

	sleep 1;
}

# Set's up the Host System to prepare for the Tor Lab, e.g. installing packages on the Host Ubuntu, and Installing Packages on the Netkit Filesystem
add_tor_to_netkit_fs() {
	#This is important, it does make permenant changes to the system (easy to undo however)
	printf "\n\n PLASE be aware of the choices you make in this part! (You may be prompted for your password depending on selections) \n\n";
	sleep 3;
	if ! vpackage --help; then
		read -p "vpackage does not have permissions to run, would you like to add them (chmod 777 path/vpackage) [Y/n]" prompt
		if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
		then
			echo "Processing..."; 
			sudo chmod 777 $(whereis vpackage | cut -d ':' -f2 | xargs);
		fi
	else
		echo "vpackage seems to be working, continuing..."; 
	fi
	
	# Checks if Tor is on the Netkit filesystem, if not, asks the user if they wish to install. 
	printf "\n\n";
	sleep 1;
	if vpackage list | grep -q "ii  tor "; then
		echo "Tor already exists on this file system, continuing without install..."
	else
		read -p "tor is not installed on this systems default netkit filesystem, would you like to install? (BE CAREFUL- this is a permanent change to your netkit, and can only be removed manually!) [Y/n]" prompt
		if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
		then
			echo "Processing..."; 
			vpackage update
			vpackage install tor -y
			vpackage install tor-arm -y
			
			touch temp.startup
			echo "systemctl stop tor" >> temp.startup
			echo "systemctl disable tor" >> temp.startup
			
			vstart temp --no-cow --mem 256 -q -e $(pwd)/temp.startup --hostlab=$(pwd) --hostwd=$(pwd) 
			
			until [ -f $(pwd)/temp.ready ]
			do
				sleep 5;
				echo "Awaiting UML boot completion (awaiting lock)";
			done
			
			sleep 10;
		
			echo "Lock ready"
			rm temp.ready
			echo "Lock collected"
			
			vcrash temp
			rm temp.startup
		else
			echo "Exiting as this lab will not work without Tor installed, you are welcome to do so manually. (Please note that you must configure it so that tor is disabled by default on boot.) ";
			exit 1;
		fi
	fi
	
	# Adds PHP for testing purposes
	printf "\n\n";
	sleep 1;
	if vpackage list | grep -q "ii  php "; then
		echo "PHP already exists on this file system, continuing without install..."
	else
		read -p "PHP is not installed on this netkit, would you like to install? (This lab uses PHP for testing client IP addresses for curl requests, however is most certainly NOT REQUIRED. [Y/n]" prompt
		if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
		then
			echo "Processing..."; 
			vpackage update
			vpackage install php -y
		else
			echo "Continuing without php (all good!)...";
		fi
	fi
	
	# IMPORTANT! Installs telnetd on the HOST OPERATING SYSTEM as it is required to access UML ssl port functionality. 
	printf "\n\n";
	sleep 1;
	printf "\n\n Please note: TelnetD is a telnet server and has many known vulnerativites, ensure you are disconnected from the internet or have sufficient firewalls, or take the risk if you are aware of the cirtumstances\n\n";
	read -p "Telnetd is required on the host operating system, would you like to install? [Y/n]" prompt
	if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
	then
		echo "Processing..."; 
		sudo apt install telnetd;
	else
		echo "Continuing without telnetd on host, if not installed this simply will NOT CONFIGURE ANY TOR COMPONENTS and the script may be unstable!...";
		sleep 3;
	fi
	
	printf "\n\n";
	sleep 1;
}

# Responsibile for creating the lab directory 'tor-lab' with a default lab.conf file
build_base_lab() {

	# Create Directory 
	mkdir tor-lab
	cd tor-lab
	touch lab.conf

# Write default lab.conf contents
cat>lab.conf<<EOL
# -[[ Lab Information ]]- #
LAB_VERSION="1"
LAB_AUTHOR="Callum Basham"
LAB_EMAIL="Callum.Basham@warwick.ac.uk"
LAB_WEB="https://github.com/CallumBasham"
LAB_DESCRIPTION="A Netkit Lab built to perform Tor Experiments [Automatically Generated by script]"

# -[[ Memory Allocation ]]- #
websrv[mem]=128
client[mem]=128
router1[mem]=128
router2[mem]=128
router3[mem]=128

# -[[ Collision Domain Allocation ]]- #
# WAN
router1[0]=wan
router2[0]=wan
router3[0]=wan

# WAN > ClientNet
router2[1]=clinet
client[0]=clinet

# WAN > WebNet
router3[1]=webnet
websrv[0]=webnet

# WAN > TorNet
router1[1]=tornet
EOL

	# Add entries for each directory authority 
	for dirnode in $(seq 1 $param_DirAuthCount); do
		echo "dirauth$dirnode[0]=tornet" >> lab.conf
		echo "dirauth$dirnode[mem]=300" >> lab.conf
	done
	
	# Add entries for each relay node 
	for relrnode in $(seq 1 $param_RelayNodeCount); do
		echo "relay$relrnode[0]=tornet" >> lab.conf
		echo "relay$relrnode[mem]=300" >> lab.conf
	done
}


# Create Directory Authority files
# (Will Launch a UML instances to perform tor-commands)
create_dirauth_files () {

	# For each Directory Authority 
	for node in $(seq 1 $param_DirAuthCount); do
		
		# Create & Write its .startup file
		# (IP mismatch may occur if more than 9 nodes are created)
		touch dirauth$node.startup
cat>dirauth$node.startup<<EOL
ifconfig eth0 hw ether 02:60:ac:9a:bc:0$node
ifconfig eth0 120.2.2.$(($node+1))/24
	
route add default gw 120.2.2.1 dev eth0

# Make Tor Directories if they do not exist
mkdir -p /var/lib/tor
mkdir -p /var/log/tor

# Ensure the tor user owns these directories
chown -R debian-tor:debian-tor /var/lib/tor
chown -R debian-tor:debian-tor /var/log/tor
EOL
	
		# Create the Directory Authority file system
		mkdir dirauth$node
		mkdir -p dirauth$node/var/lib/tor
		mkdir -p dirauth$node/etc/tor
	
		# Start the UML instance
		# Run's the .startup created above
		# Sets the hostlab and hostwd to current directory (will ensure the .ready file is placed here)
		# Adds an additional connection, e.g. opening port 41410+#DirectoryAuthority [ENABLES TELNETD FUNCTIONALITY]
		# Default memory and collision dommain is applied
		vstart dirauth$node -e dirauth$node.startup --hostlab=$(pwd) --hostwd=$(pwd) --con1=port:$((41410+$node)) --eth0=tornet --mem=512
		
		# Wait until the UML has booted
		until [ -f dirauth$node.ready ]
		do
			sleep 2
			echo "Awaiting UML boot completion (awaiting lock)"
		done
		
		# Cleanup 
		echo "Lock ready"
		rm dirauth$node.ready
		echo "Lock collected"
	
		# Padding time for safety
		sleep $((5 + $sleepPadding));
		
		# Create Tor's Keys and Certificates, replicates to the Host's filesystem for persistence
		# tor-gencert to create Directory Authoirty Keys [uses the pass phrase: password, change if you require]
		# tor --list-fingerprint to create all the ed25509 certificates and fingerprints for normal relay operations
		# Writes the torrc file
		# Copies file to host directory
		{ 
			sleep 3;
			echo "sudo -u debian-tor mkdir -p /var/lib/tor/keys"; 
			sleep 1;
			echo "ls /var/lib/tor/keys"; 
			sleep 1;
			echo "sudo -u debian-tor tor-gencert --create-identity-key -m 12 -a 120.2.2.$(($node+1)):7000 -i /var/lib/tor/keys/authority_identity_key -s /var/lib/tor/keys/authority_signing_key -c /var/lib/tor/keys/authority_certificate";
			sleep 3;
			echo "password";
			sleep 1;
			echo "password";
			sleep 1;
			echo "ls /var/lib/tor/keys"; 
			sleep 1;
			echo "sudo -u debian-tor tor --list-fingerprint --orport 1 --dirserver 'x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff' --datadirectory /var/lib/tor/";
			sleep 3;
echo "cat >/etc/tor/torrc <<EOL
TestingTorNetwork 1
DataDirectory /var/lib/tor
RunAsDaemon 1
ConnLimit 60
Nickname dirauth$node
ShutdownWaitLength 0
PidFile /var/lib/tor/pid
Log notice file /var/log/tor/notice.log
Log info file /var/log/tor/info.log
Log debug file /var/log/tor/debug.log
ProtocolWarnings 1
SafeLogging 0
DisableDebuggerAttachment 0
SocksPort 0
OrPort 5000
ExitRelay 0
#BridgeRelay 0
#Relay 0
#Authority 1
#BridgeAuthority 0
ControlPort 9051
Address 120.2.2.$(($node+1))
DirPort 7000
#ExitPolicy accept 0.0.0.0/0:*
#ExitPolicy accept [::1]:*
#IPv6Exit 1
ExitPolicy reject *:* # Do not want authorities as relays themselves
AuthoritativeDirectory 1
V3AuthoritativeDirectory 1
ContactInfo dirauth$node@cyber.test
TestingV3AuthInitialVotingInterval 150
TestingV3AuthInitialVoteDelay 20
TestingV3AuthInitialDistDelay 20
CookieAuthentication 0
DirAllowPrivateAddresses 1
EOL";
			sleep 1;
			echo "mv /etc/tor/torrc /hostlab/dirauth$node/etc/tor/";
			sleep .5;
			echo "mv /var/lib/tor/* /hostlab/dirauth$node/var/lib/tor/";
			sleep 2;
		} | telnet localhost $((41410+$node)) # telnet's to the Host's "localhost", on the port that we vstart'ed the UML node with earlier
		
		# Padding time
		sleep 2;
		
		# Double tap to be safe, when adding --con, the UML does not always shut down first attempt, two is to be safe
		vcrash dirauth$node
		vcrash dirauth$node
		lclean
	done
}

# Read the Directory Authority's Fingerprints into an Array, then Insert them into the Directory Authorities Torrc files respectively
insert_dirauth_torrc () {

	# Foreach Directory Authority (read fingerprints into pipe| separated array)
	declare -A dirarray
	for node in $(seq 1 $param_DirAuthCount); do
		finger1=$(echo $(cat dirauth$node/var/lib/tor/keys/authority_certificate | grep fingerprint | cut -d ' ' -f2))
		finger2=$(echo $(cat dirauth$node/var/lib/tor/fingerprint | cut -d ' ' -f2))
		
		dirarray[dirauth$node]=$(echo "$node|$finger1|$finger2") #c1
	done
	
	# Foreach dirauth, foreach | separated array, insert into the torrc's
	for node in $(seq 1 $param_DirAuthCount); do
		
		# How many Fingerprints need to be inserted? 
		echo "Adding all DirAuth's keys to DirAuth$node's torrc now..."
		arrlen=${#dirarray[@]};
		echo "# of keys to insert=$arrlen";
		
		# Foreach Fingerprint in the array, convert to variables and echo them into the torrc of the current directory authority in the loop
		for i in "${dirarray[@]}"; do
			# Convert to variables from Pipe separated string
			echo "current fingerprint-pair: $i";
			dirauthNode=$(echo $i | cut -d '|' -f1) #c6
			sub_fingera=$(echo $i | cut -d '|' -f2) #c4
			sub_fingerb=$(echo $i | cut -d '|' -f3) #c5
			
			# Insert into torrc
			echo "DirAuthority dirauth$dirauthNode orport=5000 no-v2 v3ident=$sub_fingera 120.2.2.$(($dirauthNode+1)):7000 $sub_fingerb" >> dirauth$node/etc/tor/torrc 
		done
	
		# Finish the .startup file by adding the tor start command
		echo "systemctl start tor" >> dirauth$node.startup
		echo """echo 'Checking for tor's death!""" >> dirauth$node.startup
		echo "sleep 5" >> dirauth$node.startup
		echo "cat /var/log/tor/debug.log | grep Dying" >> dirauth$node.startup
	done
}


# Create Relay & Exit Relay Node files
# (Will Launch a UML instances to perform tor-commands)
create_relay_files () {

	# For each Relay
	for node in $(seq 1 $param_RelayNodeCount); do
	
		# Create & Write its .startup file
		touch relay$node.startup
cat>relay$node.startup<<EOL
ifconfig eth0 hw ether 02:60:ac:7a:bc:0$node
ifconfig eth0 120.2.2.$(($node+11))/24
	
route add default gw 120.2.2.1 dev eth0

# Make Tor Directories if they do not exist
mkdir -p /var/lib/tor
mkdir -p /var/log/tor

# Ensure the tor user owns these directories
chown -R debian-tor:debian-tor /var/lib/tor
chown -R debian-tor:debian-tor /var/log/tor
EOL
		# Create the Directory Authority file system
		mkdir relay$node
		mkdir -p relay$node/var/lib/tor
		mkdir -p relay$node/etc/tor
	
		# Start the UML instance
		# Run's the .startup created above
		# Sets the hostlab and hostwd to current directory (will ensure the .ready file is placed here)
		# Adds an additional connection, e.g. opening port 42410+#DirectoryAuthority [ENABLES TELNETD FUNCTIONALITY]
		# Default memory and collision dommain is applied
		vstart relay$node -e relay$node.startup --hostlab=$(pwd) --hostwd=$(pwd) --con1=port:$((42410+$node)) --eth0=tornet --mem=512
		
		# Wait until the UML has booted
		until [ -f relay$node.ready ]
		do
			sleep 2
			echo "Awaiting UML boot completion (awaiting lock)"
		done
		
		# Cleanup 
		echo "Lock ready"
		rm relay$node.ready
		echo "Lock collected"
	
		# Padding time for safety 
		sleep $((5 + $sleepPadding));
		
		# Create Tor's Keys and Certificates, replicates to the Host's filesystem for persistence
		# tor-gencert to create Directory Authoirty Keys [uses the pass phrase: password, change if you require]
		# tor --list-fingerprint to create all the ed25509 certificates and fingerprints for normal relay operations
		# Writes the torrc file
		# Copies file to host directory
		if [ $node -le $param_ExitNodeCount ]; then
			{ 
				sleep 3;
				echo "sudo -u debian-tor mkdir -p /var/lib/tor/keys"; 
				sleep 1;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
				echo "sudo -u debian-tor tor --list-fingerprint --orport 1 --dirserver 'x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff' --datadirectory /var/lib/tor/";
				sleep 3;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
echo "cat >/etc/tor/torrc <<EOL
TestingTorNetwork 1
DataDirectory /var/lib/tor
RunAsDaemon 1
ConnLimit 60
Nickname relay$node
ShutdownWaitLength 0
PidFile /var/lib/tor/pid
Log notice file /var/log/tor/notice.log
Log info file /var/log/tor/info.log
Log debug file /var/log/tor/debug.log
ProtocolWarnings 1
SafeLogging 0
DisableDebuggerAttachment 0
SocksPort 0
OrPort 5000
ControlPort 9051
Address 120.2.2.$(($node+11))


ExitPolicy accept *:*
ExitPolicy accept [::1]:*
IPv6Exit 1
ExitRelay 1 

ContactInfo relay$node@cyber.test
CookieAuthentication 0

AssumeReachable 1
EOL"
				sleep .5;
				echo "mv /etc/tor/torrc /hostlab/relay$node/etc/tor/";
				sleep .5;
				echo "mv /var/lib/tor/* /hostlab/relay$node/var/lib/tor/";
				sleep 2;
			} | telnet localhost $((42410+$node))
		else
			{ 
				sleep 3;
				echo "sudo -u debian-tor mkdir -p /var/lib/tor/keys"; 
				sleep 1;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
				echo "sudo -u debian-tor tor --list-fingerprint --orport 1 --dirserver 'x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff' --datadirectory /var/lib/tor/";
				sleep 3;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
echo "cat >/etc/tor/torrc <<EOL
TestingTorNetwork 1
DataDirectory /var/lib/tor
RunAsDaemon 1
ConnLimit 60
Nickname relay$node
ShutdownWaitLength 0
PidFile /var/lib/tor/pid
Log notice file /var/log/tor/notice.log
Log info file /var/log/tor/info.log
Log debug file /var/log/tor/debug.log
ProtocolWarnings 1
SafeLogging 0
DisableDebuggerAttachment 0
SocksPort 0
OrPort 5000
ControlPort 9051
Address 120.2.2.$(($node+11))
#DirPort 7000
#ExitPolicy accept 0.0.0.0/0:*
#ExitPolicy accept [::1]:*
#IPv6Exit 1
#ExitRelay 1 #allows as exit relay
#AuthoritativeDirectory 1
#V3AuthoritativeDirectory 1
ContactInfo relay$node@cyber.test
#TestingV3AuthInitialVotingInterval 300
#TestingV3AuthInitialVoteDelay 20
#TestingV3AuthInitialDistDelay 20
CookieAuthentication 0

AssumeReachable 1
EOL"
				sleep .5;
				echo "mv /etc/tor/torrc /hostlab/relay$node/etc/tor/";
				sleep .5;
				echo "mv /var/lib/tor/* /hostlab/relay$node/var/lib/tor/";
				sleep 2;
			} | telnet localhost $((42410+$node)) # telnet's to the Host's "localhost", on the port that we vstart'ed the UML node with earlier
		fi
		
		# Padding time
		sleep 2;
		
		# Double tap to be safe, when adding --con, the UML does not always shut down first attempt, two is to be safe
		vcrash relay$node
		vcrash relay$node
		lclean
	done
}

# Read the Directory Authority's Fingerprints into an Array, then Insert them into the Relay Nodes Torrc files respectively
insert_relay_torrc () {

	# Foreach Directory Authority (read fingerprints into pipe| separated array)
	declare -A dirarray
	for node in $(seq 1 $param_DirAuthCount); do
		finger1=$(echo $(cat dirauth$node/var/lib/tor/keys/authority_certificate | grep fingerprint | cut -d ' ' -f2))
		finger2=$(echo $(cat dirauth$node/var/lib/tor/fingerprint | cut -d ' ' -f2))
		
		dirarray[dirauth$node]=$(echo "$node|$finger1|$finger2")
	done
	
	# Foreach Relay, foreach | separated array, insert into the torrc's
	for node in $(seq 1 $param_RelayNodeCount); do
		
		# Foreach Fingerprint in the array, convert to variables and echo them into the torrc of the current relay node in the loop
		for i in "${dirarray[@]}"; do
			# Convert to variables from Pipe separated string
			echo "current fingerprint-pair: $i";
			dirauthNode=$(echo $i | cut -d '|' -f1) 
			sub_fingera=$(echo $i | cut -d '|' -f2) 
			sub_fingerb=$(echo $i | cut -d '|' -f3) 
			
			# Insert into torrc
			echo "DirAuthority dirauth$dirauthNode orport=5000 no-v2 v3ident=$sub_fingera 120.2.2.$(($dirauthNode+1)):7000 $sub_fingerb" >> relay$node/etc/tor/torrc
		done
	
		# Finish the .startup file by adding the tor start command
		echo "systemctl start tor" >> relay$node.startup
		echo """echo 'Checking for tor's death!""" >> relay$node.startup
		echo "sleep 5" >> relay$node.startup
		echo "cat /var/log/tor/debug.log | grep Dying" >> relay$node.startup
	done
}

# Create Client files
# (Will Launch a UML instances to perform tor-commands)
create_client_files () {

# Create & Write its .startup file
# (IP mismatch may occur if more than 9 nodes are created)
touch client.startup
cat>client.startup<<EOL
ifconfig eth0 192.168.0.2/24

route add default gw 192.168.0.1 dev eth0

mkdir -p /var/lib/tor
mkdir -p /var/log/tor

chown -R debian-tor:debian-tor /var/lib/tor
chown -R debian-tor:debian-tor /var/log/tor
EOL
		# Create the Client's file system
		mkdir client
		mkdir -p client/var/lib/tor
		mkdir -p client/etc/tor
	
		# Start the UML instance
		# Run's the .startup created above
		# Sets the hostlab and hostwd to current directory (will ensure the .ready file is placed here)
		# Adds an additional connection, e.g. opening port 42410+#DirectoryAuthority [ENABLES TELNETD FUNCTIONALITY]
		# Default memory and collision dommain is applied
		vstart client -e client.startup --hostlab=$(pwd) --hostwd=$(pwd) --con1=port:$((42410)) --eth0=tornet --mem=512
		
		# Wait until the UML has booted
		until [ -f client.ready ]
		do
			sleep 2
			echo "Awaiting UML boot completion (awaiting lock)"
		done
		
		# Cleanup 
		echo "Lock ready"
		rm client.ready
		echo "Lock collected"
	
		# Padding time for safety 
		sleep $((5 + $sleepPadding));
		
		# Create Tor's Keys and Certificates, replicates to the Host's filesystem for persistence
		# tor-gencert to create Directory Authoirty Keys [uses the pass phrase: password, change if you require]
		# tor --list-fingerprint to create all the ed25509 certificates and fingerprints for normal relay operations
		# Writes the torrc file
		# Copies file to host directory
			{ 
				sleep 3;
				echo "sudo -u debian-tor mkdir -p /var/lib/tor/keys"; 
				sleep 1;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
				echo "sudo -u debian-tor tor --list-fingerprint --orport 1 --dirserver 'x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff' --datadirectory /var/lib/tor/";
				sleep 3;
				echo "ls /var/lib/tor/keys"; 
				sleep 1;
echo "cat >/etc/tor/torrc <<EOL
TestingTorNetwork 1
DataDirectory /var/lib/tor
RunAsDaemon 1
ConnLimit 60
Nickname client
ShutdownWaitLength 0
PidFile /var/lib/tor/pid
Log notice file /var/log/tor/notice.log
Log info file /var/log/tor/info.log
Log debug file /var/log/tor/debug.log
ProtocolWarnings 1
SafeLogging 0
DisableDebuggerAttachment 0
SocksPort 9050
ControlPort 9051
Address 192.168.0.2
EOL"
				sleep .5;
				echo "mv /etc/tor/torrc /hostlab/client/etc/tor/";
				sleep .5;
				echo "mv /var/lib/tor/* /hostlab/client/var/lib/tor/";
				sleep 2;
			} | telnet localhost $((42410)) # telnet's to the Host's "localhost", on the port that we vstart'ed the UML node with earlier
		
		# Padding time
		sleep 2;
		
		# Double tap to be safe, when adding --con, the UML does not always shut down first attempt, two is to be safe
		vcrash client
		vcrash client
		lclean
}

# Read the Directory Authority's Fingerprints into an Array, then Insert them into the Client's Torrc files respectively
insert_client_torrc () {

	# Foreach Directory Authority (read fingerprints into pipe| separated array)
	declare -A dirarray
	#for node in 1 2 3; do
	for node in $(seq 1 $param_DirAuthCount); do
		finger1=$(echo $(cat dirauth$node/var/lib/tor/keys/authority_certificate | grep fingerprint | cut -d ' ' -f2))
		finger2=$(echo $(cat dirauth$node/var/lib/tor/fingerprint | cut -d ' ' -f2))
		
		dirarray[dirauth$node]=$(echo "$node|$finger1|$finger2")
	done
	
	# Foreach Fingerprint in the array, convert to variables and echo them into the torrc of client
	for i in "${dirarray[@]}"; do
		# Convert to variables from Pipe separated string
		echo "current fingerprint-pair: $i";
		dirauthNode=$(echo $i | cut -d '|' -f1) 
		sub_fingera=$(echo $i | cut -d '|' -f2) 
		sub_fingerb=$(echo $i | cut -d '|' -f3) 
			
		# Insert into torrc
		echo "DirAuthority dirauth$dirauthNode orport=5000 no-v2 v3ident=$sub_fingera 120.2.2.$(($dirauthNode+1)):7000 $sub_fingerb" >> client/etc/tor/torrc
			
	done
	
	# Finish the .startup file by adding the tor start command
	echo "systemctl start tor" >> client.startup
	echo """echo 'Checking for tor's death!""" >> client.startup
	echo "sleep 5" >> client.startup
	echo "cat /var/log/tor/debug.log | grep Dying" >> client.startup
}

# Create a default Web Server that simply returns the remote IP address from a curl
setup_websrv() {
	touch websrv.startup
	mkdir websrv
cat>websrv.startup<<EOL
ifconfig eth0 10.10.10.2/28
route add default gw 10.10.10.1

# Start apache
service apache2 start

# Build WebSrv contents
rm -rf /var/www/html/*
touch var/www/html/index.php

echo "<?php" >> /var/www/html/index.php
echo "echo 'php version: ' . phpversion(); " >> /var/www/html/index.php
echo "?>"  >> /var/www/html/index.php

echo "<html>" >> /var/www/html/index.php
echo "<body>" >> /var/www/html/index.php
echo "<h1>Welcome: <?php echo \\\$_SERVER['REMOTE_ADDR']; ?></h1>" >> /var/www/html/index.php
echo "</body>" >> /var/www/html/index.php
echo "</html>" >> /var/www/html/index.php
EOL
}

# Build Routers to finalize the network design
setup_routers() {
echo "<<<<  setup_routers !";

	# -[ Router 1 - tornet ]- #
	touch router1.startup
	mkdir router1
cat>router1.startup<<EOL
ifconfig eth0 69.69.69.1/28
ifconfig eth1 120.2.2.1/24
EOL

	# -[ Router 2 - clientnet ] - #
	# Contains NAT to act as a real "home network"
	touch router2.startup
	mkdir router2
cat>router2.startup<<EOL
ifconfig eth0 69.69.69.2/28
ifconfig eth1 192.168.0.1/24

#  NAT as a normal router would
# Enables IP Forwarding (for Nat later)
echo "1" > /proc/sys/net/ipv4/ip_forward

# Mask LAN to WAN traffic as itself, e.g. all traffic from LAN = this eth0 device's IP.
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

route add -net 120.2.2.0/24 gw 69.69.69.1 dev eth0
EOL

	# -[ Router 3 - websrv net ]- #
	# Port forward web traffic
	touch router3.startup
	mkdir router3
cat>router3.startup<<EOL
ifconfig eth0 69.69.69.3/28
ifconfig eth1 10.10.10.1/28

# Nat with port forwards for the web server
# Enables IP Forwarding (for Nat later)
echo "1" > /proc/sys/net/ipv4/ip_forward

# Mask LAN to WAN traffic as itself, e.g. all traffic from LAN = this eth0 device's IP.
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

# Port forward WAN traffic destined for LAN's WebSrv
iptables -A FORWARD -m state -p tcp --state NEW,ESTABLISHED,RELATED -j ACCEPT # create stateful connections, allows the return trips
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-dest 10.10.10.2:80 # route to LAN's port 80 HTTP
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-dest 10.10.10.2:443 # route to LAN's port 443 HTTPS

route add -net 120.2.2.0/24 gw 69.69.69.1 dev eth0
EOL
}

# A selection of terminal prompts to build the lab requirements
user_selection;
# Ensures the host system & netkit system are both prepared to handle the lab's requirements
add_tor_to_netkit_fs;
# Builds the basic lab structure: directiries, lab.conf
build_base_lab;
# Creates directory authority nodes, starts the UML and performs configuration, then saves and closes
create_dirauth_files;
# Writes dirauth entries to directory authority torrc's
insert_dirauth_torrc;
# Creates relay (&exit) nodes, starts the UML and performs configuration, then saves and closes
create_relay_files;
# Writes dirauth entries to relays torrc's
insert_relay_torrc;
# Creates client nodes, starts the UML and performs configuration, then saves and closes
create_client_files;
# Writes dirauth entries to clients torrc's
insert_client_torrc;
# Builds a generic apache2 web server with php to return a client's IP address upon curl
setup_websrv;
# Finishes the netkit node setup by adding routers with static routes/nat to create a "real-world" implementation
setup_routers;
sleep 1;

# start the lab
lstart -f

# Check if user is done with their work
read -p "Finished? shall we clean up? [Y = closes terminals and deletes ALL files / n = takes no action, ends script]" prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
	# Purge the lab
	lcrash
	lclean

	# Uncomment the below to NOT-DELETE the lab after working
	cd ..
	rm -rf tor-lab
else
	echo "Ok! You can do whatever you want with the lab, it can be recreated at any point by re-running this script. Its yours now, away with you!"
fi
