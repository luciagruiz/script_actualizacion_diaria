#! /usr/bin/env bash
#Autor: Lucía Garrote Ruiz, Francisco Javier Huete Mejías
#Descripción:
#Versión: 1.0
#Fecha:
#Zona de depuración
        #Inicio de la zona de depuración con set -x (descomentar para activar)
#set -x
        #Advertencia de falta de variable (descomentar para activar)
#set -u
#Zona de declaración de variables

#Color de texto
rojo="\e[1;31m"
verde="\e[1;32m"
amarillo="\e[1;33m"
azul="\e[1;34m"
morado="\e[1;35m"
cyan="\e[1;36m"

#Color de fondo
gris="\e[1;40m"
verde="\e[1;42m"
amarillo="\e[1;44m"
azul="\e[1;44m"
morado="\e[1;45m"
cyan="\e[1;46m"

#Formato
negrita="\e[1m"
subrayado="\e[4m"
parpadeo="\e[1;5m"
invertido="\e[1;7m"


fin_formato="\e[0m"

#Zona de declaración de funciones

mostrar_ayuda() {
echo "Uso: $0 [ARGUMENTOS]
Descripción: Este script actualiza el sistema diariamente.
Parámetros aceptados:
	-h Muestra esta ayuda
	-v Muestra la versión "
}

mostrar_version() {
echo "$0 Versión: 1.0"
exit 0
}

#Comprobar la conexión
validar_conexion () {
	if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
		return 0
	fi
	return 1
}

#Comprobar si el script se está ejecutando con privilegios de root
validar_root() {
	local uid="$(f_uid)"
	if [ "$uid" -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

#Zona del script

#Control de argumentos
while getopts "hv" opcion; do
	case $opcion in
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version ;;
		?) mostrar_ayuda; exit 1
	esac
done


validar_root
if [ $?=1 ]; then
	echo "[ERROR] - Este script se debe ejecutar como root."
else
	validar_conexion
	if [ $?=1 ]; then
	echo "[ERROR] - No hay conexión a Internet."
fi
