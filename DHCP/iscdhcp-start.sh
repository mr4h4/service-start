#!/bin/bash

# ===== General Information ===== # ===== Información general =====

# Script Name: isc-dhcp-start
# Description: Automatiza la instalación, configuración final y puesta en marcha de un servicio DHCP. (Linux Mint)
# Version: 0.1 
# Author:

# ===== Functions ===== # ===== Funciones =====
comprobar_isc_dhcp() { # Función para comprobar si el paquete isc-dhcp-server está instalado
    if dpkg -l | grep -q "isc-dhcp-server"; then
        echo "isc-dhcp-server está instalado."
        return 0  # Verdadero
    else
        echo "isc-dhcp-server no está instalado."
        return 1  # Falso
    fi
}

dhcpconf() { #Leer configuración (inputs)
    read -p "server-identifier >> " identifier #Leer identificador del servidor
    read -p "default-lease-time >> " leasetime #Indica el tiempo de asignación en segundos
    read -p "option subnet-mask >> " subnetmask #Indica la máscara de red
    read -p "option broadcast-addressnan >> " broadcast #Indica el broadcast
    read -p "option router >> " gateway #Indica el gateway

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

startservice(){ #Configurar el servicio DHCP (outpouts)
    echo "authoritative;" | sudo tee -a /etc/dhcp/dhcpd.conf #Definir al SV como principal para ese segmento de red. (default)
    echo "one-lease-per-client-on;" | sudo tee -a /etc/dhcp/dhcpd.conf #Define una IP por host.
    echo "server-identifier $identifier;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el nodo que alberga el servicio.
    echo "default-lease-time $leasetime;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el tiempo de asignación en segundos.
    echo "option subnet-mask $subnetmask;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica la máscara de red
    echo "option broadcast-address; $broadcast;" | sudo tee -a /etc/dhcp/dhcpd.conf #indica el broadcast
    echo "option routers $gateway;" | sudo tee -a /etc/dhcp/dhcpd.conf #Indica el gateway
    echo "" | sudo tee -a /etc/dhcp/dhcpd.conf 

    #echo "server-identifier $identifier;" | sudo tee -a /etc/dhcp/dhcpd.conf 
}
## ===== Start ===== ## ===== Inicio =====
sudo chmod +rwx tu_script.sh

echo "Comprobando instalación de isc-dhcp-server..."
sleep 2
# Llamar a la función
comprobar_isc_dhcp
# Verificar el resultado de la función
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


# ===== Global Variables ===== # ===== Variables globales =====

# Define colors for output # Definir colores para el output


# Function to display log messages # Función para mostrar mensajes de log

# Help function # Función de ayuda

# Error function # Función de error

# Main function # Función principal

# ===== Execution ===== # ===== Ejecución =====
# Check if the script is being run directly (not "sourced), and call the main function. # Verifica si el script ha sido ejecutado directamente (no "sourced), y llama a la función main.

#if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then #if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#    main "$@" #    main "$@"
#fi #fi


