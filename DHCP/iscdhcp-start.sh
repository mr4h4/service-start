#!/bin/bash

# ===== General Information =====
# Script Name: isc-dhcp-start
# Description: Automatiza la instalación, configuración final y puesta en marcha de un servicio DHCP. (Linux Mint)
# Version: 0.1 
# Author:

# ===== Functions =====
comprobar_isc_dhcp() { 
    if dpkg -l | grep -q "isc-dhcp-server"; then
        return 0  # Verdadero
    else
        echo "isc-dhcp-server no está instalado."
        return 1  # Falso
    fi
}

dhcpconf() { 
    read -p "network-ip >> " dirRed 
    read -p "netmask >> " netmask
    read -p "broadcast >> " broadcast
    read -p "gateway >> " gateway
    read -p "range (first) >> " rangoA 
    read -p "range (last) >> " rangoB
    read -p "default-lease-time >> " leasetime
    read -p "max-lease-time >> " maxleasetime
    read -p "dns-server-ip >> " dns_server_ip
    read -p "domain >> " domain
    read -p "authoritative (y/n) >> " authoritative

    startservice
}

confyesornot() {
    read -p "¿Quiere iniciar la configuración del servicio? (y/n) >> " confyesno
    if [[ $confyesno == "y" || $confyesno == "Y" ]]; then
        dhcpconf
    elif [[ $confyesno == "n" || $confyesno == "N" ]]; then
        return 0
    else
        echo "Parámetro inválido. Inserte (y/n)"
        confyesornot
    fi
}

startyesornot() {
    read -p "¿Quiere iniciar directamente el servicio? (y/n) >> " startyesno
    if [[ $startyesno == "y" || $startyesno == "Y" ]]; then
        service isc-dhcp-server restart
        sudo tail -f /var/log/syslog & 

        if systemctl is-active --quiet isc-dhcp-server; then
            echo "Servicio iniciado correctamente."
        else
            echo "El servicio no se ha iniciado correctamente."
        fi
    elif [[ $startyesno == "n" || $startyesno == "N" ]]; then
        return 0
    else
        echo "Parámetro inválido. Inserte (y/n)"
        startyesornot
    fi
}

startservice(){ 
    echo "Creando backup de la configuración actual..."
    sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
    sleep 2

    echo "Restaurando /etc/dhcp/dhcpd.conf..."
    sudo rm /etc/dhcp/dhcpd.conf
    sleep 2
    
    if [[ $authoritative == "y" || $authoritative == "Y" ]]; then
        echo "authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf
    elif [[ $authoritative == "n" || $authoritative == "N" ]]; then
        echo "#authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf
    else
        echo "Parametro invalido. Se interpretará como 'no'."
    fi

    sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOL
    default-lease-time $leasetime;
    max-lease-time $maxleasetime;

    subnet $dirRed netmask $netmask {
        range $rangoA $rangoB;
        option domain-name-servers $dns_server_ip, 8.8.8.8;
        option domain-name "$domain";
        option subnet-mask $netmask;
        option routers $gateway;
        option broadcast-address $broadcast;
    }
EOL

    startyesornot
}

## ===== Start =====
echo "Comprobando instalación de isc-dhcp-server..."
sleep 2
comprobar_isc_dhcp

if [ $? -eq 0 ]; then
    echo "Iniciando configuración del servicio..."
    sleep 2
    dhcpconf
else
    echo "Instalando isc-dhcp-server..."
    sleep 2
    sudo apt-get install isc-dhcp-server
    sleep 2
    confyesornot
fi
