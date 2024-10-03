#!/bin/bash

# ===== General Information ===== # ===== Información general =====

# Script Name: isc-dhcp-start
# Description: Automatiza la instalación, configuración final y puesta en marcha de un servicio DHCP. (Linux Mint)
# Version: 0.1 
# Author:

# ===== Functions ===== # ===== Funciones =====
comprobar_isc_dhcp() { # Función para comprobar si el paquete isc-dhcp-server está instalado
    if dpkg -l | grep -q "isc-dhcp-server"; then
        return 0  # Verdadero
    else
        echo "isc-dhcp-server no está instalado."
        return 1  # Falso
    fi
}

dhcpconf() { #Leer configuración (inputs)    
    read -p "network-ip>> " dirRed 
    read -p "netmask >> " netmask
    read -p "broadcast >> " broadcast #Indica el broadcast
    read -p "gateway >> " gateway #Indica el gateway
    read -p "range (first) >> " rangoA 
    read -p "range (last) >> " rangoB
    read -p "default-lease-time >> " leasetime #Indica el tiempo de asignación en segundos
    read -p "max-lease-time >> " maxleasetime #Indica el tiempo de asignación en segundos

    startservice
}

confyesornot() {
    read -p "¿Quiere iniciar la configuración del servicio? (y/n) >> " confyesno
    if [[ $confyesno == "y" || $confyesno == "Y" ]]; then
        dhcpconf  # Llama a la función dhcpconf
    elif [[ $confyesno == "n" || $confyesno == "N" ]]; then
        return 0  # Salir sin hacer nada
    else
        echo "Parámetro inválido. Inserte (y/n)"
        confyesornot  # Llama a la función nuevamente
    fi
}

startyesornot() {
    read -p "¿Quiere iniciar directamente el servicio? (y/n) >> " startyesno
    if [[ $startyesno == "y" || $startyesno == "Y" ]]; then
        service isp-dhcp-server restart # Reiniciar servicio
        service isp-dhcp-server start # Iniciar servicio
        service isp-dhcp-server status # Ver estado actual
        sudo tail -f /var/log/syslog & # Ver logs en segundo plano

        # Comprobar que el servicio está funcionando
        if systemctl is-active --quiet isp-dhcp-server; then
            echo "Servicio iniciado correctamente y está en funcionamiento." # Mensaje de éxito
        else
            echo "El servicio no se ha iniciado correctamente." # Mensaje de error
        fi
    elif [[ $startyesno == "n" || $startyesno == "N" ]]; then
        return 0  # Salir sin hacer nada
    else
        echo "Parámetro inválido. Inserte (y/n)"
        startyesornot  # Llama a la función nuevamente
    fi
}


startservice(){ #Configurar el servicio DHCP (outpouts)
    echo "Creando backup de la configuración actual..."
    sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
    sleep 2

    echo "Restaurando /etc/dhcp/dhcpd.conf..."
    sudo rm /etc/dhcp/dhcpd.conf
    sleep 2

    echo "Configurando DHCP..."
    echo "authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf #Definir al SV como principal para ese segmento de red. (DEFAULT)
    echo "one-lease-per-client-on;" | sudo tee -a /etc/dhcp/dhcpd.conf #Define una IP por host. (DEFAULT)
    echo "subnet $dirRed netmask $netmask {" | sudo tee -a /etc/dhcp/dhcpd.conf
    echo "option broadcast-address $broadcast;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el broadcast
    echo "option routers $gateway;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el gateway
    echo "range $rangoA $rangoB;" | sudo tee -a /etc/dhcp/dhcpd.conf 
    echo "default-lease-time $leasetime;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el tiempo de asignación en segundos.
    echo "max-lease-time $maxleasetime;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el tiempo de asignación en segundos.
    echo "}" | sudo tee -a /etc/dhcp/dhcpd.conf
    echo "Servicio DHCP configurado correctamente"
    sleep 2
    startyesornot

    
}
## ===== Start ===== ## ===== Inicio =====
sudo chmod +rwx iscdhcp-start.sh

echo "Comprobando instalación de isc-dhcp-server..."
sleep 2
comprobar_isc_dhcp

# Verificar el resultado de $comprobar_isc_dhcp
if [ $? -eq 0 ]; then
    # Si el paquete está instalado
    echo "Iniciando configuración del servicio..."
    sleep 2
    dhcpconf
else
    # Si el paquete no está instalado
    echo "Instalando isc-dhcp-server..."
    sleep 2
    sudo apt-get install isc-dhcp-server #Instalar servicio isc-dhcp
    # sudo apt update && sudo apt install -y isc-dhcp-server
    sleep 2
    confyesornot
fi


