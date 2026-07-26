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
    # Actualizar repositorios y paquetes básicos
    pkg update -y || error "No se pudo actualizar pkg. Revisa tu conexión."
    pkg install -y proot-distro termux-x11 x11-repo || error "Fallo al instalar paquetes necesarios."
    
    # Verificar almacenamiento externo
    if [ ! -d "$HOME/storage" ]; then
        warn "No se detecta almacenamiento externo."
        echo "Por favor, ejecuta 'termux-setup-storage' y permite el acceso."
        echo "Luego reinicia Termux y vuelve a ejecutar este script."
        exit 1
    fi
    
    # Espacio libre (mínimo 4GB)
    free_space=$(df /data | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 4000000 ]; then
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
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt upgrade -y
        apt install -y sudo wget curl nano xfce4 xfce4-goodies x11vnc xvfb
        # Crear usuario
        useradd -m -s /bin/bash $USERNAME
        echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        # Configurar VNC
        mkdir -p /home/$USERNAME/.vnc
        echo '$VNCPASS' | x11vnc -storepasswd /home/$USERNAME/.vnc/passwd
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc
        # .xinitrc
        echo 'startxfce4 &' > /home/$USERNAME/.xinitrc
        chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc
    " || error "Falló la configuración dentro de Ubuntu."
}

generate_start_script() {
    local script_path="$PREFIX/bin/startubuntu.sh"
    msg "Generando script de inicio en $script_path"
    cat > "$script_path" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -e
# Iniciar servidor X11
termux-x11 :1 -ac &
sleep 2
# Iniciar Ubuntu con XFCE y VNC
proot-distro login ubuntu -- bash -c "
    export DISPLAY=:1
    x11vnc -display :1 -forever -usepw -passwd $VNCPASS &
    startxfce4
"
trap "pkill -f termux-x11; pkill -f x11vnc" EXIT
EOF
    chmod +x "$script_path"
    msg "Script de inicio creado en $script_path"
}

main() {
    msg "=== Instalación de Ubuntu con XFCE en Termux ==="
    check_prerequisites
    load_user_data
    install_ubuntu
    configure_ubuntu
    generate_start_script
    msg "¡Instalación completada!"
    msg "Usuario: $USERNAME"
    msg "Contraseña VNC: (la que configuraste)"
    msg "Para iniciar el entorno gráfico, ejecuta: startubuntu.sh"
}

main