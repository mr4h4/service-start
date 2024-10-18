#FUNCIONES
disclaimer(){
read -p "¿Desea continuar? (y/n) >>" startyesno
    if [[ $startyesno == "y" || $startyesno == "Y" ]]; then
        domainconf
    elif [[ $startyesno == "n" || $startyesno == "N" ]]; then
        return 0
    else
        echo "Parámetro inválido. Inserte (y/n)"
        disclaimer
    fi
}

domainconf(){
read -p "¿Que tipo de resolución desea añadir? directa=(1) / inversa=(2) >>" conftype
    if [[ $conftype == "1"]]; then
        directaconf
    elif [[ $conftype == "2"]]; then
        inversaconf
    else
        echo "Parámetro inválido. Inserte (y/n)"
        disclaimer
    fi
}

directaconf(){
    read
}

#INICIO
echo "Antes de añadir un nuevo dominio, asegurate de tener instalado bind9 (Puedes utilizar 'bind9-start.sh')"
sleep 2

disclaimer
