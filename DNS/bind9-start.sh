#!/bin/bash

# ===== General Information =====
# Script Name: bind9-start
# Description: Automatiza la instalación, configuración final y puesta en marcha de un servicio DNS. (Linux Mint)
# Version: 2.0
# Author: mr4h4 - h3rhex

# ===== Functions =====
comprobar_bind9() { 
    if dpkg -l | grep -q "bind9"; then
        return 0  # Verdadero
    else
        echo "BIND9 no está instalado."
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
    sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak || { echo "Error al crear backup"; exit 1; }
    sleep 2

    echo "Restaurando /etc/bind/named.conf.local..."
    echo "" | sudo tee /etc/bind/named.conf.local  # Limpiar el archivo antes de escribir
    sleep 2

    echo "Creando directorio para zonas en /etc/bind/zones..."
    sudo mkdir -p /etc/bind/zones || { echo "Error al crear directorio"; exit 1; }
    sleep 2

    echo "Configurando BIND9..."

    # Configurando named.conf.local
    {
        echo "zone \"$dominio\" {"
        echo "    type master;"
        echo "    file \"/etc/bind/zones/db.$dominio\";"
        echo "};"

        echo "zone \"$zonaInversa\" {"
        echo "    type master;"
        echo "    file \"/etc/bind/zones/db.$zonaInversa\";"
        echo "};"
    } | sudo tee -a /etc/bind/named.conf.local

    # Crear archivo de zona directa
    echo "Creando archivo de zona directa para $dominio..."
    sudo tee /etc/bind/zones/db.$dominio > /dev/null <<EOL
;
; Archivo de configuracion para la zona directa de $dominio
;
\$TTL 86400
@   IN  SOA ns.$dominio. admin.$dominio. (
            $(date +"%Y%m%d%H") ; Serial
            3600         ; Refresh
            1800         ; Retry
            1209600      ; Expire
            86400 )      ; Negative Cache TTL

; Servidores de nombres
@       IN  NS  ns.$dominio.

; Registros A (dirección IP)
ns      IN  A   $ipServidor
www     IN  A   $ipServidor
EOL

    # Crear archivo de zona inversa
    echo "Creando archivo de zona inversa para $zonaInversa..."
    sudo tee /etc/bind/zones/db.$zonaInversa > /dev/null <<EOL
;
; Archivo de zona inversa para $zonaInversa.x
;
\$TTL 86400
@   IN  SOA ns.$dominio. admin.$dominio. (
            $(date +"%Y%m%d%H") ; Serial
            3600         ; Refresh
            1800         ; Retry
            1209600      ; Expire
            86400 )      ; Negative Cache TTL

; Servidores de nombres
@       IN  NS  ns.$dominio.

; Registros PTR (IP a nombre de dominio)
$d   IN  PTR  $dominio.
EOL

    echo "Servicio BIND9 configurado correctamente."
    sleep 2
    startyesornot
}

confyesornot() {
    read -p "¿Quiere iniciar la configuración del servicio? (y/n) >> " confyesno
    if [[ $confyesno == "y" || $confyesno == "Y" ]]; then
        bindconf
    elif [[ $confyesno == "n" || $confyesno == "N" ]]; then
        return 0
    else
        echo "Parámetro inválido. Inserte (y/n)"
        confyesornot
    fi
}

startyesornot() {
    read -p "¿Quiere iniciar directamente el servicio BIND9? (y/n) >> " startyesno
    if [[ $startyesno == "y" || $startyesno == "Y" ]]; then
        sudo systemctl start bind9 || { echo "Error al iniciar BIND9"; exit 1; }
        sudo systemctl status bind9

        if systemctl is-active --quiet bind9; then
            echo "BIND9 iniciado correctamente y está en funcionamiento."
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

## ===== Start =====
# Asegúrate de que el script tenga permisos de ejecución antes de ejecutarlo

echo "Comprobando instalación de BIND9..."
sleep 2
comprobar_bind9

if [ $? -eq 0 ]; then
    echo "Iniciando configuración del servicio..."
    sleep 2
    bindconf
else
    echo "Instalando bind9..."
    sleep 2
    if sudo apt-get install -y bind9; then
        confyesornot
    else
        echo "Error al instalar bind9. Asegúrate de tener acceso a Internet y permisos adecuados."
        exit 1
    fi
fi