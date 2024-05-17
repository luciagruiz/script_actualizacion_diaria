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
echo -e ""$negrita"Uso:"$fin_formato" $0
"$negrita"Descripción:"$fin_formato" Este script actualiza el sistema diariamente. Se debe ejecutar con privilegios de root.
"$negrita"Parámetros aceptados:"$fin_formato"
	-h Muestra esta ayuda
	-v Muestra la versión 
"$negrita"Ejemplos de uso: "$fin_formato""
}

mostrar_version() {
echo "$0 Versión: 1.0"
exit 0
}

#Comprobar la conexión
validar_conexion () {
	if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
		return 0
	else
		echo -e "$rojo$negrita[ERROR]$fin_formato - No hay conexión a Internet."
		exit 1
	fi
}

#Comprobar si el script se está ejecutando con privilegios de root
validar_root() {
	if [ $(whoami) = 'root' ]; then
		return 0
	else
		echo -e "$rojo$negrita[ERROR]$fin_formato - Este script se debe ejecutar como root."
		exit 1
	fi
}

# Función para registrar mensajes en el archivo de log
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >> "/var/log/auto_update.log"
}

comprobar_distro() {
	distro=cat /etc/os-release | grep '^ID=' | cut -d'=' -f2
	return $distro
}

# Actualizar los repositorios e instalar actualizaciones
actualizar_repo() {
    if command -v apt-get &> /dev/null; then
        apt-get update -y >> "/var/log/auto_update.log" 2>&1
        apt-get upgrade -y >> "/var/log/auto_update.log" 2>&1
        apt-get autoclean -y >> "/var/log/auto_update.log" 2>&1
        apt-get autoremove -y >> "/var/log/auto_update.log" 2>&1
    elif command -v yum &> /dev/null; then
        yum update -y >> "/var/log/auto_update.log" 2>&1
    elif command -v dnf &> /dev/null; then
        dnf update -y >> "/var/log/auto_update.log" 2>&1
    elif command -v pacman &> /dev/null; then
        pacman -Syu --noconfirm >> "/var/log/auto_update.log" 2>&1
    else
        echo "No se ha podido determinar el gestor de paquetes del sistema"
        exit 1
    fi
}

# Preguntar sobre ejecución diaria
pregunta() {
    read -p "¿Desea que el sistema se actualice diariamente? (s/n): " respuesta
    if [ "$respuesta" = "s" ]; then
        read -p "Por favor, ingrese la hora de actualización (formato HH:MM, por ejemplo, 09:00): " hora
        programar_ejecucion
    else
        echo "No se realizará la actualización diaria."
    fi
}

# Programar la ejecución diaria a la hora especificada
programar_ejecucion() {
    # Comprobar si la línea ya está presente en el crontab
    if grep -q "$PWD/$0" /etc/crontab; then
        read -p "Ya hay una ejecución diaria del script programada, ¿deseas eliminarla? (s/n): " respuesta2
        if [ "$respuesta2" = "s" ]; then
            # Eliminar la línea del crontab
            sudo sed -i "\~^.*$PWD/$0.*\$~d" /etc/crontab
            echo "Se eliminó la ejecución diaria anteriormente programada."
            
            # Extraer la hora y el minuto de la variable $hora
            hora2=$(echo "$hora" | cut -d':' -f1)
            minuto=$(echo "$hora" | cut -d':' -f2)
        
            # Agregar la línea al crontab con la hora especificada por el usuario
            echo "$minuto $hora2 * * * root $PWD/$0" | sudo tee -a /etc/crontab >/dev/null
            echo "Se programará la actualización diaria a las $hora"
        
        else
            # Obtener la hora y el minuto de la ejecución diaria existente
            linea_existente=$(grep "$PWD/$0" /etc/crontab)
            hora_existente=$(echo "$linea_existente" | awk '{print $2}')
            minuto_existente=$(echo "$linea_existente" | awk '{print $1}')
            echo "Se mantendrá la actualización diaria a las $hora_existente:$minuto_existente."
            return
        fi
    
    elif ! grep -q "$PWD/$0" /etc/crontab; then
        # Extraer la hora y el minuto de la variable $hora
        hora2=$(echo "$hora" | cut -d':' -f1)
        minuto=$(echo "$hora" | cut -d':' -f2)
        
        # Agregar la línea al crontab con la hora especificada por el usuario
        echo "$minuto $hora2 * * * root $PWD/$0" | sudo tee -a /etc/crontab >/dev/null
        echo "Se programará la actualización diaria a las $hora"
    fi
}

#Zona del script

#Control de argumentos
while getopts "hv" opcion; do
	case $opcion in
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version ;;
		?) mostrar_ayuda; exit 1 ;;
	esac
done

validar_root
validar_conexion
actualizar_repo
log_message "Sistema actualizado correctamente."
pregunta

#Tareas pendientes
#Menú de opciones:
#Notificación por correo
##cat /etc/os-release
#Preguntar si se actualiza diariamente. Si sí: Elegir la hora; si no, actualizar sólo una vez.

