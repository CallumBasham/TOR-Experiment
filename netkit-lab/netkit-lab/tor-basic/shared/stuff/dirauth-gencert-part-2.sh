machine_name=$(echo $(uname -n))

echo "2---------------------------------------------------------------------!"

sudo -u debian-tor tor --list-fingerprint --orport 1 \
		--dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" \
		--datadirectory /var/lib/tor/

echo "3---------------------------------------------------------------------!"


#cd /hostlab/$machine_name
#mkdir var
#cd var
#mkdir lib
#cd lib
#mkdir tor
#cd tor
#mkdir keys
mkdir -p /hostlab/$machine_name/var/lib/tor/keys/
cp -R /var/lib/tor/keys /hostlab/$machine_name/var/lib/tor/
cp /var/lib/tor/fingerprint /hostlab/$machine_name/var/lib/tor/
cp /etc/tor/torrc /hostlab/$machine_name/etc/tor/

echo "4---------------------------------------------------------------------!"

echo "Machine name: $machine_name" >> /hostlab/dirauth_fingerprints.txt
fingerprint1=$(echo $(cat /var/lib/tor/keys/authority_certificate | grep fingerprint | cut -d ' ' -f2))

echo "5---------------------------------------------------------------------!"

echo "Certificate fingerprint is: $fingerprint1" >> /hostlab/dirauth_fingerprints.txt

echo "6---------------------------------------------------------------------!"

fingerprint2=$(echo $(cat /var/lib/tor/fingerprint | cut -d ' ' -f2))
echo "Onion Fingerprint is: $fingerprint2" >> /hostlab/dirauth_fingerprints.txt
echo "---------------------------------------------------------------------" >> /hostlab/dirauth_fingerprints.txt

echo "7---------------------------------------------------------------------!"

systemctl start tor
service tor start
