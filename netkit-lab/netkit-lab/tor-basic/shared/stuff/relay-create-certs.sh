echo "Hex: Gen-certs -------------------------------------------"
sudo -u debian-tor tor --list-fingerprints --orport 1 --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" --datadirectory /var/lib/tor

sleep 5

echo "Hex: Move Certs -------------------------------------------"
sudo -u debian-tor mv /var/lib/tor/* /hostlab/$(hostname)/var/lib/tor
mv /var/lib/tor/* /hostlab/$(hostname)/var/lib/tor
