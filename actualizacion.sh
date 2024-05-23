#! /usr/bin/env bash
#Autor: Lucía Garrote Ruiz, Francisco Javier Huete Mejías
#Descripción: Este script actualiza el sistema diariamente. Se debe ejecutar con privilegios de root.
#Versión: 1.28
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

#Formato
negrita="\e[1m"
fin_formato="\e[0m"

#Zona de declaración de funciones

mostrar_ayuda() {
	echo -e ""$negrita"Uso:"$fin_formato" $0 [OPCIÓN]
"$negrita"Descripción:"$fin_formato" Este script actualiza el sistema diariamente. Se debe ejecutar con privilegios de root.
"$negrita"Parámetros aceptados:"$fin_formato"
	-a Muestra la hora a la que se ha programado la ejecución diaria de este script
	-c Configura el script de forma interactiva
        -d Elimina la ejecución programada
	-p HORA Programa la ejecución diaria del script a una hora determinada. El formato aceptado para la hora es HH:MM con una hora entre 00 y 24.
	-h Muestra esta ayuda
	-v Muestra la versión 
"$negrita"Ejemplos de uso: "$fin_formato"
Para actualizar el sistema:
	$0
		
Para comprobar la hora a la que hay programada una actualización diaria del sistema:
	$0 -a
		
Para configurar una actualización diaria del sistema de forma interactiva:
	$0 -c
		
Para configurar una actualización diaria del sistema a las 9 de la mañana:
	$0 -p 09:00"
}

mostrar_version() {
echo "$0 Versión: 1.28"
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

#Función para comprobar la Distribución de la máquina
comprobar_distro() {
	distro=$(sudo cat /etc/os-release | grep '^ID=' | cut -d'=' -f2)
}

# Actualizar los repositorios e instalar actualizaciones
actualizar_repo() {
		comprobar_distro
    if [[ $distro = "debian" ]] || [[ $distro = "ubuntu" ]] || 
    [[ $distro = "kali" ]] || [[ $distro = "tails" ]] || 
    [[ $distro = "pureOS" ]] || command -v apt-get &> /dev/null; then
        apt-get update -y >> "/var/log/auto_update.log" 2>&1
        apt-get upgrade -y >> "/var/log/auto_update.log" 2>&1
        apt-get autoclean -y >> "/var/log/auto_update.log" 2>&1
        apt-get autoremove -y >> "/var/log/auto_update.log" 2>&1
    elif [[ $distro = "redhat" ]] || [[ $distro = "centOS" ]] || 
    [[ $distro = "rocky" ]] || [[ $distro = "alma" ]] || 
    [[ $distro = "fedora" ]] || command -v yum &> /dev/null; then
        yum update -y >> "/var/log/auto_update.log" 2>&1
    elif [[ $distro = "redhat" ]] || [[ $distro = "centOS" ]] || 
    [[ $distro = "rocky" ]] || [[ $distro = "alma" ]] || 
    [[ $distro = "fedora" ]] || command -v dnf &> /dev/null; then
        dnf update -y >> "/var/log/auto_update.log" 2>&1
    elif [[ $distro = "arch" ]] || [[ $distro = "crystal" ]] || 
    [[ $distro = "steam" ]] || [[ $distro = "garuda" ]] || 
    [[ $distro = "tearch" ]] || command -v pacman &> /dev/null; then
        pacman -Syu --noconfirm >> "/var/log/auto_update.log" 2>&1
    else
        echo -e "$rojo$negrita[ERROR]$fin_formato -  No se ha podido determinar el gestor de paquetes del sistema"
        exit 1
    fi
}

# Comprobación del formato de la hora proporcionada
comprobar_formato_hora() {
    if ! [[ $hora =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        echo -e "${rojo}${negrita}[ERROR]${fin_formato} - El formato de la hora proporcionada no es válido. Debe ser HH:MM."
        exit 1
    fi
}

comprobar_rango_hora() {
    # Asignar valor a variables si no están asignados ya
    hora2=$(echo "$hora" | sed 's/^0*//' | cut -d':' -f1)
    minuto=$(echo "$hora" | cut -d':' -f2)
    
    # Convertir horas y minutos a números enteros
    hora2=$((10#$hora2))
    minuto=$((10#$minuto))
    
    # Verificar si la hora y los minutos están en el rango correcto
    if (( hora2 < 0 || hora2 > 23 || minuto < 0 || minuto > 59 )); then
        echo -e "${rojo}${negrita}[ERROR]${fin_formato} - La hora especificada no es válida. Debe estar en formato HH:MM con una hora entre 00 y 23 y minutos entre 00 y 59."
        exit 1
    fi
}

# Eliminar la línea programada en el crontab
eliminar_linea_crontab(){
    if grep -q "$(realpath $0)" /etc/crontab; then
        sudo sed -i "\~^.*$(realpath $0).*\$~d" /etc/crontab
        echo -e "$verde$negrita[OK]$fin_formato - Se eliminó la ejecución diaria anteriormente programada."
    elif ! grep -q "$(realpath $0)" /etc/crontab; then
        echo -e "$rojo$negrita[ERROR]$fin_formato - No se encontró ninguna ejecución diaria anteriormente programada."
    fi
}

# Preguntar sobre ejecución diaria
pregunta() {
    read -p "¿Desea que el sistema se actualice diariamente? (s/n): " respuesta
    if [ "$respuesta" = "s" ]; then
        read -p "Por favor, ingrese la hora de actualización (formato HH:MM, por ejemplo, 09:00): " hora
        comprobar_formato_hora
        programar_ejecucion
    else
        echo -e "$verde$negrita[OK]$fin_formato - No se realizará la actualización diaria."
    fi
}

# Obtener hora de la ejecución diaria ya programada
comprobar_ejecucion_diaria() {
    # Comprobar si la línea ya está presente en el crontab
    if grep -q "$(realpath $0)" /etc/crontab; then
        linea_existente=$(grep "$(realpath $0)" /etc/crontab)
        hora_existente=$(echo "$linea_existente" | awk '{print $2}')
        minuto_existente=$(echo "$linea_existente" | awk '{print $1}')
        echo -e "$verde$negrita[OK]$fin_formato - La actualización diaria está programada para las $hora_existente:$minuto_existente"
    else
        echo "No hay ninguna ejecución diaria programada."
    fi
}

# Programar la ejecución diaria a la hora especificada de forma no interactiva ej: actualizacion.sh -p 08:15 (lo programa a las 08:15)
programar_ejecucion_basica() {
    # Verificar si se proporciona un argumento
    if [ -z "$1" ]; then
        echo -e "${rojo}${negrita}[ERROR]${fin_formato} - No se proporcionó ninguna hora para programar la ejecución diaria."
        exit 1
    fi

    hora="$1"
    comprobar_formato_hora
    comprobar_rango_hora
    
    eliminar_linea_crontab

    # Programar la nueva ejecución diaria
    echo "$minuto $hora2 * * * root $(realpath $0)" | sudo tee -a /etc/crontab >/dev/null
    echo -e "${verde}${negrita}[OK]${fin_formato} - Se programará la actualización diaria a las $hora."
}


# Programar la ejecución diaria a la hora especificada de forma interactiva
programar_ejecucion() {
    comprobar_rango_hora
    
    # Comprobar si la línea ya está presente en el crontab
    if grep -q "$(realpath $0)" /etc/crontab; then
        read -p "Ya hay una ejecución diaria del script programada, ¿deseas eliminarla? (s/n): " respuesta2
        if [ "$respuesta2" = "s" ]; then
            
            eliminar_linea_crontab
            
            # Agregar la línea al crontab con la hora especificada por el usuario
            echo "$minuto $hora2 * * * root $(realpath $0)" | sudo tee -a /etc/crontab >/dev/null
            echo -e "$verde$negrita[OK]$fin_formato - Se programará la actualización diaria a las $hora"
        
        else
            comprobar_ejecucion_diaria
        fi
    
    elif ! grep -q "$(realpath $0)" /etc/crontab; then
        # Agregar la línea al crontab con la hora especificada por el usuario
        echo "$minuto $hora2 * * * root $(realpath $0)" | sudo tee -a /etc/crontab >/dev/null
        echo -e "$verde$negrita[OK]$fin_formato - Se programará la actualización diaria a las $hora"

        read -p "Hay una ejecución diaria del script programada, ¿deseas eliminarla? (s/n): " respuesta2
        if [ "$respuesta2" = "s" ]; then
            eliminar_linea_crontab
        fi
    fi
}

#Zona del script

#Control de argumentos
while getopts "acdhvp:" opcion; do
    case $opcion in
        a) comprobar_ejecucion_diaria; exit 0;;
        c) pregunta; exit 0;;
        d) eliminar_linea_crontab; exit 0;; 
        p) programar_ejecucion_basica "$OPTARG"; exit 0;;
        h) mostrar_ayuda; exit 0;;
        v) mostrar_version ;;
        ?) mostrar_ayuda; exit 1 ;;
    esac
done

validar_root
validar_conexion
actualizar_repo
log_message "Sistema actualizado correctamente."
