sudo -u debian-tor tor-gencert -a $(hostname -I|xargs):7000 -i /var/lib/tor/keys/authority_identity_key -s /var/lib/tor/keys/authority_signing_key -c /var/lib/tor/keys/authority_certificate

cp -fr /var/lib/tor/* /hostlab/$(hostname)/var/lib/tor/



