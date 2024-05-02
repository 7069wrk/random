key=csi

#disable unneeded services known to be available in one or more linux OS
disable_services() {
    # Define a list of services to disable
    local disableservices=(
        "systemd-networkd-wait-online.service"
        "NetworkManager-wait-online.service"
        "apache-htcacheclean.service"
        "apache-htcacheclean@.service"
        "apache2.service"
        "apache2@.service"
        "bettercap.service"
        "clamav-daemon.service"
        "clamav-freshclam.service"
        "clamav-milter.service"
        "cups-browsed.service"
        "cups.service"
        "dnsmasq.service"
        "dnsmasq@.service"
        "i2p"
        "i2pd"
        "kismet.service"
        "lokinet"
        "lokinet-testnet.service"
        "openfortivpn@.service"
        "openvpn-client@.service"
        "openvpn-server@.service"
        "openvpn.service"
        "openvpn@.service"
        "privoxy.service"
        "rsync.service"
        "systemd-networkd-wait-online.service"
        "NetworkManager-wait-online.service"
        "xl2tpd.service"
    )

    # Iterate through the list and disable each service
    for service in "${disableservices[@]}"; do
        echo "Disabling $service..."
        sudo systemctl disable "$service" > /dev/null 2>&1
        sudo systemctl stop "$service" > /dev/null 2>&1
        echo "$service disabled successfully."
    done
}

disable_services

echo $key | sudo -S apt update
echo $key | sudo -S apt upgrade -y
echo $key | sudo -S apt dist-upgrade -y
echo $key | sudo -S apt full-upgrade -y
echo $key | sudo -s apt autoremove -y
echo $key | sudo -s apt clean

