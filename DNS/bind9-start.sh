#!/bin/bash

# ===== General Information =====
# Script Name: bind9-start
# Description: Automatiza la instalación, configuración final y puesta en marcha de un servicio DNS. (Linux Mint)
# Version: 0.1 
# Author:

# ===== Functions =====
comprobar_bind9() { 
    # Función para comprobar si el paquete bind9 está instalado
    if dpkg -l | grep -q "bind9"; then
        return 0  # Verdadero
    else
        echo "bind9 no está instalado."
        return 1  # Falso
    fi
}

bindconf() { 
    # Leer configuración (inputs)
    read -p "Dominio (ej: ejemplo.com): " dominio
    read -p "Dirección IP del servidor (ej: 192.168.1.2): " ipServidor
    read -p "Dirección IP de la red (ej: 192.168.1.0): " ipRed
    read -p "Máscara de subred (ej: 255.255.255.0): " netmask

    # Configuración inversa
    IFS='.' read -r a b c d <<< "$ipServidor" 
    zonaInversa="$c.$b.$a.in-addr.arpa"

    startservice
}

startservice() {
    echo "Creando backup de la configuración actual..."
    sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
    sleep 2

    echo "Restaurando /etc/bind/named.conf.local..."
    sudo rm /etc/bind/named.conf.local
    sleep 2

    echo "Creando directorio para zonas en /etc/bind/zones..."
    sudo mkdir -p /etc/bind/zones
    sleep 2

    echo "Configurando BIND9..."

    # Configurando named.conf.local
    echo "zone \"$dominio\" {" | sudo tee -a /etc/bind/named.conf.local
    echo "    type master;" | sudo tee -a /etc/bind/named.conf.local
    echo "    file \"/etc/bind/zones/db.$dominio\";" | sudo tee -a /etc/bind/named.conf.local
    echo "};" | sudo tee -a /etc/bind/named.conf.local

    echo "zone \"$zonaInversa\" {" | sudo tee -a /etc/bind/named.conf.local
    echo "    type master;" | sudo tee -a /etc/bind/named.conf.local
    echo "    file \"/etc/bind/zones/db.$zonaInversa\";" | sudo tee -a /etc/bind/named.conf.local
    echo "};" | sudo tee -a /etc/bind/named.conf.local
    
    # Crear archivo de zona directa
    echo "Creando archivo de zona directa para $dominio..."
    sudo tee /etc/bind/zones/db.$dominio > /dev/null <<EOL
\$TTL 604800
@   IN  SOA ns1.$dominio. root.$dominio. (
            $(date +"%Y%m%d%H") ; Serial
            604800  ; Refresh
            86400   ; Retry
            2419200 ; Expire
            604800) ; Negative Cache TTL

@   IN  NS  ns1.$dominio.
ns1 IN  A   $ipServidor
www IN  A   $ipServidor
EOL

    # Crear archivo de zona inversa
    echo "Creando archivo de zona inversa para $zonaInversa..."
    sudo tee /etc/bind/zones/db.$zonaInversa > /dev/null <<EOL
\$TTL 604800
@   IN  SOA ns1.$dominio. root.$dominio. (
            $(date +"%Y%m%d%H") ; Serial
            604800  ; Refresh
            86400   ; Retry
            2419200 ; Expire
            604800) ; Negative Cache TTL

@   IN  NS  ns1.$dominio.
$d   IN  PTR ns1.$dominio.
EOL

    echo "Servicio BIND9 configurado correctamente."
    sleep 2
    startyesornot
}

confyesornot() {
    read -p "¿Quiere iniciar la configuración del servicio? (y/n) >> " confyesno
    if [[ $confyesno == "y" || $confyesno == "Y" ]]; then
        bindconf  # Llama a la función bindconf
    elif [[ $confyesno == "n" || $confyesno == "N" ]]; then
        return 0  # Salir sin hacer nada
    else
        echo "Parámetro inválido. Inserte (y/n)"
        confyesornot  # Llama a la función nuevamente
    fi
}

startyesornot() {
    read -p "¿Quiere iniciar directamente el servicio BIND9? (y/n) >> " startyesno
    if [[ $startyesno == "y" || $startyesno == "Y" ]]; then
        sudo systemctl restart bind9  # Reiniciar servicio
        sudo systemctl start bind9    # Iniciar servicio
        sudo systemctl status bind9   # Ver estado actual
        sudo tail -f /var/log/syslog &  # Ver logs en segundo plano

        # Comprobar si el servicio está activo
        if systemctl is-active --quiet bind9; then
            echo "BIND9 iniciado correctamente y está en funcionamiento."
        else
            echo "El servicio no se ha iniciado correctamente."
        fi
    elif [[ $startyesno == "n" || $startyesno == "N" ]]; then
        return 0  # Salir sin hacer nada
    else
        echo "Parámetro inválido. Inserte (y/n)"
        startyesornot  # Llama a la función nuevamente
    fi
}

## ===== Start =====
sudo chmod +rwx bind9-start.sh

echo "Comprobando instalación de BIND9..."
sleep 2
comprobar_bind9

# Verificar el resultado de $comprobar_bind9
if [ $? -eq 0 ]; then
    # Si el paquete está instalado
    echo "Iniciando configuración del servicio..."
    sleep 2
    bindconf  # Cambiado de dhcpconf a bindconf
else
    # Si el paquete no está instalado
    echo "Instalando bind9..."
    sleep 2
    sudo apt-get install -y bind9 #Instalar servicio bind9
    sleep 2
    confyesornot
fi
