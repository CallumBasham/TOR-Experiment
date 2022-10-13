service --status-all

systemctl stop tor
service tor stop

machine_name=$(echo $(uname -n))

mkdir /var/lib/tor/keys

echo "1---------------------------------------------------------------------!"

sudo -u debian-tor tor-gencert --create-identity-key -m 12 -a 127.0.0.1:7000 \
	-i /var/lib/tor/keys/authority_identity_key \
	-s /var/lib/tor/keys/authority_signing_key \
	-c /var/lib/tor/keys/authority_certificate

