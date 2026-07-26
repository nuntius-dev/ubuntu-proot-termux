#!/data/data/com.termux/files/usr/bin/bash
# install-ubuntu-termux.sh - Instalación automatizada de Ubuntu con XFCE
# Repositorio: https://github.com/nuntius-dev/ubuntu-proot-termux

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración por defecto (¡Zero-touch!)
USERNAME="ubuntu"
VNCPASS="ubuntu"
MIRROR="http://archive.ubuntu.com/ubuntu/"

msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_prerequisites() {
    msg "Verificando y actualizando repositorios base..."
    
    # 1. Primero instalamos el repositorio extra (equivalente a un add-apt-repository)
    pkg update -y
    pkg install -y x11-repo
    
    # 2. Actualizamos nuevamente para que Termux lea los paquetes de X11
    msg "Descargando dependencias de Termux..."
    pkg update -y
    
    # 3. Ahora sí, instalamos todo sin errores
    pkg install -y proot-distro termux-x11
    
    # Verificación silenciosa de almacenamiento
    if [ ! -d "$HOME/storage" ]; then
        warn "Almacenamiento no configurado."
        echo "Por favor, ejecuta 'termux-setup-storage' antes de usar este script."
        exit 1
    fi
}

install_ubuntu() {
    if proot-distro list | grep -q ubuntu; then
        msg "El contenedor de Ubuntu ya existe. Omitiendo instalación..."
        return 0
    fi
    msg "Instalando Ubuntu RootFS (esto tomará un momento)..."
    proot-distro install ubuntu
}

configure_ubuntu() {
    msg "Configurando entorno gráfico dentro de Ubuntu..."
    
    # Usamos el mismo principio que en tu Dockerfile: DEBIAN_FRONTEND=noninteractive
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt upgrade -y
        apt install -y sudo wget curl nano xfce4 xfce4-goodies x11vnc xvfb dbus-x11
        
        # Crear usuario predeterminado de forma silenciosa
        if ! id -u $USERNAME >/dev/null 2>&1; then
            useradd -m -s /bin/bash $USERNAME
            echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        fi
        
        # Inyectar la contraseña VNC automáticamente
        mkdir -p /home/$USERNAME/.vnc
        x11vnc -storepasswd \"$VNCPASS\" /home/$USERNAME/.vnc/passwd
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc
        chmod 600 /home/$USERNAME/.vnc/passwd
    "
}

generate_start_script() {
    local script_path="$PREFIX/bin/startubuntu"
    msg "Generando ejecutable de inicio en $script_path"
    
    cat > "$script_path" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -e

# Capturar señales para matar los procesos limpiamente al salir
trap "pkill -f termux-x11; pkill -f x11vnc" EXIT

# Iniciar servidor X11 de Termux
termux-x11 :1 -ac &
sleep 2

# Logearse de forma segura pasándole el tmp y el usuario
proot-distro login ubuntu --user "$USERNAME" --shared-tmp -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=tcp:127.0.0.1:4713
    rm -f /tmp/.X1-lock
    
    # Iniciar VNC y escritorio
    x11vnc -display :1 -forever -usepw -bg
    startxfce4
"
EOF
    chmod +x "$script_path"
}

main() {
    msg "=== Instalación Desatendida de Ubuntu XFCE ==="
    check_prerequisites
    install_ubuntu
    configure_ubuntu
    generate_start_script
    
    echo -e "\n${GREEN}==========================================${NC}"
    msg "¡Instalación completada con éxito!"
    msg "Usuario por defecto: $USERNAME"
    msg "Password VNC: $VNCPASS"
    echo -e "${GREEN}==========================================${NC}"
    msg "Para iniciar, ejecuta: ${YELLOW}startubuntu${NC}"
}

main
