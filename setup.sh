#!/bin/bash

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
    read -p "dns-server-ip (default 8.8.8.8) >> " dns_server_ip
    read -p "domain () >> " domain
    read -p "authoritative (y/n) >> " authoritative
    read -p "interface (ej. eth0, wlan0, etc.) >> " interface

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
        sudo systemctl restart isc-dhcp-server
        tail -f /var/log/syslog & 

        if systemctl is-active --quiet isc-dhcp-server; then
            echo "Servicio insed -i '/^INTERFACESv4=/d' /etc/default/isc-dhcp-servericiado correctamente."
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
    
    # Agregar el parámetro 'authoritative' si el usuario lo elige
    if [[ $authoritative == "y" || $authoritative == "Y" ]]; then
        echo "authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf > /dev/null
    elif [[ $authoritative == "n" || $authoritative == "N" ]]; then
        echo "#authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf > /dev/null
    else
        echo "Parametro invalido. Se interpretará como 'no'."
    fi

    # Si no se proporciona un DNS, se asigna 8.8.8.8 como valor predeterminado
    if [ -z "$dns_server_ip" ]; then
        dns_server_ip="8.8.8.8"
    fi

    # Si no se proporciona un dominio, no escribir nada en el archivo
    if [ -z "$domain" ]; then
        domain_line=""
    else
        domain_line="option domain-name \"$domain\";"
    fi

    # Configurar la interfaz de red para que el servicio escuche en ella
    if [ -z "$interface" ]; then
        echo "No se ha especificado ninguna interfaz, utilizando la predeterminada."
        interface="eth0"  # Default interface in case user leaves it blank
    fi

    # Escribir la interfaz en el archivo /etc/default/isc-dhcp-server
    sed -i '/^INTERFACESv4=/d' /etc/default/isc-dhcp-server
    echo "INTERFACESv4=\"$interface\"" | sudo tee -a /etc/default/isc-dhcp-server > /dev/null

    # Agregar la configuración al archivo dhcpd.conf sin sobrescribir lo anterior
    sudo tee -a /etc/dhcp/dhcpd.conf > /dev/null <<EOL
default-lease-time $leasetime;
max-lease-time $maxleasetime;

subnet $dirRed netmask $netmask {
    range $rangoA $rangoB;
    option domain-name-servers $dns_server_ip;
    $domain_line
    option subnet-mask $netmask;
    option routers $gateway;
    option broadcast-address $broadcast;
}
EOL

    startyesornot
}

## ===== Start =====
if [[ $(whoami) == "root" ]]; then
    echo "Comprobando instalación de isc-dhcp-server..."
    sleep 2
    comprobar_isc_dhcp
else
    echo "Por favor, inicia el script como root"
    exit 1
fi


if [ $? -eq 0 ]; then
    echo "Iniciando configuración del servicio..."
    sleep 2
    dhcpconf
else
    echo "Instalando isc-dhcp-server..."
    sleep 2
    sudo apt-get install isc-dhcp-server -y
    sleep 2
    confyesornot
fi
