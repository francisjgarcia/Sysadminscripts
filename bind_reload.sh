#!/bin/bash

#########################################
#       Francis J. Garcia               #
#       https://francisjgarcia.es       #
#########################################################
#       Este script entra en el fichero de zonas        #
#       de bind9 y tras guardarlo, incrementa el        #
#       serial siguiendo una nomenclatura con la        #
#       fecha en la que se modifico y lo recarga.       #
#########################################################
# Instrucciones: Escribir la zona como primera variable #
# y si el directorio es diferente de /etc/bind escribir #
# la ruta completa al fichero de zonas.                 #
# En el caso de utilizar vistas y querer ejecutar el    #
# el script sin preguntas, añadir como segunda          #
# variable el nombre de la vista de tu fichero de zona. #
#########################################################
## Ejemplo: ./reload_bind.sh /etc/bind/dbexample vista  #
#########################################################

## Variables de directorio
ZonaDNS=$1
VistaDNS=$2
FicheroDNS=$(echo $ZonaDNS | awk -F"/" '{print $NF}')
DirectorioDNS=$(echo $ZonaDNS | awk -F"/" '{$NF=""; print}' | tr " " "/")

if [[ "$DirectorioDNS" == "" ]]
then
	DirectorioDNS="/etc/bind/"
fi

if [[ -z $ZonaDNS ]]
then
	echo "Debes introducir el nombre del fichero de tu zona como variable."
	echo "Ejemplo: $(echo $0 | awk -F"/" '{print $NF}') dbejemplo.com"
	exit
else
	if [[ ! -f $DirectorioDNS$FicheroDNS ]]
	then
		echo "Este fichero de zona no existe en tu directorio $DirectorioDNS"
		echo "Si utilizas un directorio de zonas diferente al predeterminado, debes indicar la ruta completa."
		echo "Ejemplo:" $(echo $0 | awk -F"/" '{print $NF}') "/path/to/bind/$FicheroDNS"
		exit
	fi
fi

## Comprobar vistas
if [[ -z $VistaDNS ]]
then
	read -p "¿Utilizas vistas en tu zona? (s/N) " -n 1 -r
	echo ""
	if [[ $REPLY =~ ^[Ss]$ ]]
	then
        echo "Introduce el nombre de tu vista:"
        read Vista
	fi
else
	Vista=$VistaDNS
fi

## Variables de la zona
Dominio=$(echo $ZonaDNS | awk -F"\." '{print $2"."$3}')
SerialActual=$(cat $DirectorioDNS$FicheroDNS | head -3 | tail -1 | awk '{print $1}')
NuevoSerial=$(date +%y%m%d)
ComprobarFecha=$(echo $SerialActual | cut -c1-6)

if [[ $ComprobarFecha == $NuevoSerial ]]
then
	Contador=$(cat $DirectorioDNS$FicheroDNS | head -3 | tail -1 | awk '{print substr($1,7)}')
else
	Contador="000"
fi

PrimeraComprobacion=$(echo $Contador | cut -c1)
SegundaComprobacion=$(echo $Contador | cut -c2)

## Comprobaciones
if [[ $PrimeraComprobacion == "0" ]]
then
	if [[ $SegundaComprobacion == "0" ]]
	then
		Contador=$(echo $Contador | cut -c3)
		let Contador=Contador+1
		if (( $Contador >= 1 && $Contador <= 9 ))
		then
			NuevoContador="00$Contador"
		else
			NuevoContador="0$Contador"
		fi
	else
		Contador=$(echo $Contador | cut -c2,3)
		let Contador=Contador+1
                if (( $Contador >= 10 && $Contador <= 99 ))
                then
                        NuevoContador="0$Contador"
                else
                        NuevoContador=$Contador
                fi
	fi
else
	let Contador=Contador+1
	NuevoContador=$Contador
fi

## Ejecución del script
if [[ -z $2 ]]
then
	nano $DirectorioDNS$FicheroDNS
fi
sed -i "s/$SerialActual/$NuevoSerial$NuevoContador/g" $DirectorioDNS$FicheroDNS

echo "Serial Actual: $SerialActual"
echo "Nuevo Serial: $NuevoSerial$NuevoContador"

if [[ -z $Vista ]]
then
        named-checkzone zonename $DirectorioDNS$FicheroDNS && rndc reload $Dominio || exit
else
        named-checkzone zonename $DirectorioDNS$FicheroDNS && rndc reload $Dominio IN $Vista || exit
fi
