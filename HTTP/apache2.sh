#!/bin/bash

# Variables
DOMAIN="mi-sitio.com"
DOC_ROOT="/var/www/$DOMAIN"
CONFIG_FILE="/etc/apache2/sites-available/$DOMAIN.conf"
SSL_CONFIG_FILE="/etc/apache2/sites-available/$DOMAIN-ssl.conf"
APACHE_SSL_DIR="/etc/ssl/$DOMAIN"

# Función para verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Función para agregar entrada en /etc/hosts
agregar_a_hosts() {
    echo "Agregando $DOMAIN a /etc/hosts..."
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "127.0.0.1    $DOMAIN" >> /etc/hosts
        echo "$DOMAIN ha sido añadido a /etc/hosts"
    else
        echo "$DOMAIN ya existe en /etc/hosts"
    fi
}

# Función para eliminar un sitio web y sus configuraciones
eliminar_sitio() {
    echo "Eliminando el sitio $DOMAIN..."

 # Deshabilitar el sitio
    a2dissite "$DOMAIN.conf"
    a2dissite "$DOMAIN-ssl.conf"
    systemctl reload apache2

# Eliminar los archivos de configuración
    rm -f "$CONFIG_FILE" "$SSL_CONFIG_FILE"

# Eliminar el directorio de documentos
    rm -rf "$DOC_ROOT"

# Eliminar el dominio de /etc/hosts
    sed -i "/$DOMAIN/d" /etc/hosts

    echo "Sitio $DOMAIN eliminado correctamente."
}

# Preguntar si quiere eliminar el sitio
read -p "¿Quieres eliminar el sitio $DOMAIN existente? (y/n): " eliminar
if [[ "$eliminar" == "y" ]]; then
    eliminar_sitio
    exit 0
fi

# Actualizar repositorios e instalar Apache2 si no está instalado
echo "Instalando Apache2..."
apt update
apt install -y apache2

# Verificar si la instalación fue exitosa
if ! which apache2 > /dev/null; then
    echo "Error: Apache2 no se instaló correctamente."
    exit 1
fi

# Crear el directorio raíz del documento para el sitio
echo "Creando el directorio raíz del documento..."
mkdir -p $DOC_ROOT

# Crear un archivo HTML de prueba
echo "<html>
  <head>
    <title>Bienvenido a $DOMAIN</title>
  </head>
  <body>
    <h1>¡Éxito! Apache está configurado para $DOMAIN</h1>
  </body>
</html>" > $DOC_ROOT/index.html

# Crear un archivo de configuración para el sitio HTTP
echo "Creando el archivo de configuración de Apache para $DOMAIN..."

echo "<VirtualHost *:80>
    ServerAdmin admin@$DOMAIN
    ServerName $DOMAIN
    DocumentRoot $DOC_ROOT
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > $CONFIG_FILE

# Habilitar el sitio y deshabilitar el predeterminado
echo "Habilitando el sitio en Apache..."
a2dissite 000-default.conf
a2ensite $DOMAIN.conf

# Habilitar el módulo rewrite si es necesario
a2enmod rewrite

# Agregar el dominio a /etc/hosts
agregar_a_hosts

# Preguntar si desea configurar SSL
read -p "¿Quieres habilitar SSL (https) para este sitio? (y/n): " ssl_choice

if [[ "$ssl_choice" == "y" ]]; then
    echo "Configurando SSL..."

# Crear directorio para almacenar certificados SSL autogenerados
    mkdir -p "$APACHE_SSL_DIR"

# Generar un certificado SSL autofirmado
    openssl req -new -x509 -days 365 -nodes -out "$APACHE_SSL_DIR/$DOMAIN.crt" -keyout "$APACHE_SSL_DIR/$DOMAIN.key" -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Crear archivo de configuración SSL
    echo "<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerAdmin admin@$DOMAIN
        ServerName $DOMAIN
        DocumentRoot $DOC_ROOT

        SSLEngine on
        SSLCertificateFile $APACHE_SSL_DIR/$DOMAIN.crt
        SSLCertificateKeyFile $APACHE_SSL_DIR/$DOMAIN.key

        ErrorLog \${APACHE_LOG_DIR}/error_ssl.log
        CustomLog \${APACHE_LOG_DIR}/access_ssl.log combined
    </VirtualHost>
</IfModule>" > $SSL_CONFIG_FILE

# Habilitar el módulo SSL y la configuración del sitio SSL
    a2enmod ssl
    a2ensite "$DOMAIN-ssl.conf"
fi

# Reiniciar Apache para aplicar los cambios
echo "Reiniciando Apache..."
systemctl restart apache2

# Habilitar Apache para que se inicie al arrancar el sistema
systemctl enable apache2

echo "El servidor HTTP está configurado en Apache y funcionando."
if [[ "$ssl_choice" == "y" ]]; then
    echo "Accede a tu sitio en https://$DOMAIN"
else
    echo "Accede a tu sitio en http://$DOMAIN"
fi
