#!/data/data/com.termux/files/usr/bin/bash
# install-ubuntu-termux.sh - Instalación completa de Ubuntu con XFCE en Termux

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STATE_FILE="$HOME/.ubuntu-install-state"

msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() {
    msg "Limpiando archivos temporales..."
    rm -f /tmp/ubuntu-install-*.tmp
}
trap cleanup EXIT

check_prerequisites() {
    msg "Verificando requisitos..."
    pkg update -y || error "No se pudo actualizar pkg. Revisa tu conexión."
    pkg install -y proot-distro termux-x11 x11-repo || error "Fallo al instalar paquetes necesarios."

    if [ ! -d "$HOME/storage" ]; then
        warn "No se detecta almacenamiento externo."
        echo "Ejecuta 'termux-setup-storage', permite el acceso y vuelve a ejecutar el script."
        exit 1
    fi

    # Corrección: Comprobar la partición de Termux de manera segura sin necesidad de root
    local free_space
    free_space=$(df -k "$PREFIX" | awk 'NR==2 {print $4}')
    
    # Prevenir que la variable quede vacía y rompa el operador -lt
    if [ "${free_space:-0}" -lt 4000000 ]; then
        warn "Espacio libre inferior a 4GB. Puede fallar la instalación."
        read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
}

ask_user_data() {
    if [ -f "$STATE_FILE" ] && grep -q "USER_SET=1" "$STATE_FILE"; then
        msg "Datos de usuario ya configurados."
        return 0
    fi
    
    read -p "Nombre de usuario para Ubuntu: " username
    while [ -z "$username" ]; do
        warn "El nombre no puede estar vacío."
        read -p "Nombre de usuario: " username
    done
    
    read -s -p "Contraseña para VNC (dejar vacía para 'ubuntu'): " vnc_pass
    echo
    if [ -z "$vnc_pass" ]; then
        vnc_pass="ubuntu"
        warn "Contraseña VNC establecida a 'ubuntu' (cámbiala después)."
    fi
    
    read -p "Mirror de Ubuntu (opcional, Enter para predeterminado): " mirror
    [ -z "$mirror" ] && mirror="http://archive.ubuntu.com/ubuntu/"

    cat > "$STATE_FILE" <<EOF
USER_SET=1
USERNAME="$username"
VNCPASS="$vnc_pass"
MIRROR="$mirror"
EOF
    chmod 600 "$STATE_FILE"
}

load_user_data() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    else
        ask_user_data
        source "$STATE_FILE"
    fi
}

install_ubuntu() {
    if proot-distro list | grep -q ubuntu; then
        msg "Ubuntu ya está instalado."
        return 0
    fi
    msg "Instalando Ubuntu (puede tomar varios minutos)..."
    proot-distro install ubuntu || error "Falló la instalación de Ubuntu."
}

configure_ubuntu() {
    msg "Configurando Ubuntu..."
    
    # Corrección: Creamos el usuario pero instalamos todo primero desde el usuario ROOT invitado
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt upgrade -y
        apt install -y sudo wget curl nano xfce4 xfce4-goodies x11vnc xvfb dbus-x11
        
        # Crear usuario si no existe
        if ! id -u $USERNAME >/dev/null 2>&1; then
            useradd -m -s /bin/bash $USERNAME
            echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        fi
        
        # Configurar contraseña de VNC de manera correcta
        mkdir -p /home/$USERNAME/.vnc
        x11vnc -storepasswd \"$VNCPASS\" /home/$USERNAME/.vnc/passwd
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc
        chmod 600 /home/$USERNAME/.vnc/passwd
    " || error "Falló la configuración dentro de Ubuntu."
}

generate_start_script() {
    local script_path="$PREFIX/bin/startubuntu"
    msg "Generando ejecutable de inicio en $script_path"
    
    cat > "$script_path" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -e

# Corrección: El trap debe ir al principio para capturar caídas durante el proceso.
trap "pkill -f termux-x11; pkill -f x11vnc" EXIT

# Iniciar servidor X11 nativo
termux-x11 :1 -ac &
sleep 2

# Corrección: Obligatorio usar --shared-tmp para comunicar los sockets X11
# y logearse como --user \$USERNAME para aplicar tu configuración y seguridad
proot-distro login ubuntu --user "$USERNAME" --shared-tmp -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=tcp:127.0.0.1:4713
    
    # Limpiamos archivos temporales gráficos bloqueantes
    rm -f /tmp/.X1-lock
    
    # El archivo de contraseña ya existe gracias a x11vnc -storepasswd
    x11vnc -display :1 -forever -usepw -bg
    
    # Arrancar el escritorio
    startxfce4
"
EOF
    chmod +x "$script_path"
    msg "Script de inicio creado. Ahora puedes arrancarlo escribiendo: startubuntu"
}

main() {
    msg "=== Instalación de Ubuntu con XFCE en Termux ==="
    check_prerequisites
    load_user_data
    install_ubuntu
    configure_ubuntu
    generate_start_script
    
    echo -e "\n${GREEN}==========================================${NC}"
    msg "¡Instalación completada con éxito!"
    msg "Usuario de Ubuntu: $USERNAME"
    echo -e "${GREEN}==========================================${NC}"
    msg "Para iniciar el entorno gráfico en cualquier momento,"
    msg "simplemente escribe: ${YELLOW}startubuntu${NC}"
}

main
