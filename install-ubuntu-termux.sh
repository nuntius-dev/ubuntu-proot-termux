#!/data/data/com.termux/files/usr/bin/bash
# install-ubuntu-termux.sh - Instalación completa de Ubuntu con XFCE en Termux

set -e  # Detener ante cualquier error
set -u  # Detenerse si variable no definida

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Archivo de estado para reanudar
STATE_FILE="$HOME/.ubuntu-install-state"

# Función para imprimir mensajes
msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Función de limpieza al salir
cleanup() {
    msg "Limpiando archivos temporales..."
    rm -f /tmp/ubuntu-install-*.tmp
}
trap cleanup EXIT

# Verificar que Termux está actualizado y tiene almacenamiento
check_prerequisites() {
    msg "Verificando requisitos..."
    pkg list-installed >/dev/null || error "pkg no funciona. ¿Termux está actualizado?"
    if [ ! -d "$HOME/storage" ]; then
        warn "No se detecta almacenamiento externo. Ejecuta 'termux-setup-storage' y reinicia."
        read -p "¿Ya configuraste el almacenamiento? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            error "No se puede continuar sin almacenamiento."
        fi
    fi
    # Espacio libre mínimo recomendado: 4GB
    free_space=$(df /data | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 4000000 ]; then
        warn "Espacio libre inferior a 4GB. Puede fallar la instalación."
        read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
    # Verificar proot-distro
    if ! command -v proot-distro &>/dev/null; then
        msg "Instalando proot-distro..."
        pkg install -y proot-distro
    fi
}

# Función para preguntar datos del usuario
ask_user_data() {
    if [ -f "$STATE_FILE" ] && grep -q "USER_SET" "$STATE_FILE"; then
        msg "Datos de usuario ya configurados previamente."
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
    read -p "Mirror de Ubuntu (opcional, presiona Enter para usar el predeterminado): " mirror
    if [ -z "$mirror" ]; then
        mirror="http://archive.ubuntu.com/ubuntu/"
    fi
    # Guardar en archivo de estado
    echo "USER_SET" > "$STATE_FILE"
    echo "USERNAME=$username" >> "$STATE_FILE"
    echo "VNCPASS=$vnc_pass" >> "$STATE_FILE"
    echo "MIRROR=$mirror" >> "$STATE_FILE"
}

# Cargar datos guardados
load_user_data() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    else
        ask_user_data
        source "$STATE_FILE"
    fi
}

# Instalar Ubuntu con proot-distro
install_ubuntu() {
    if proot-distro list | grep -q ubuntu; then
        msg "Ubuntu ya está instalado."
        return 0
    fi
    msg "Instalando Ubuntu (esto puede tomar varios minutos)..."
    proot-distro install ubuntu || error "Falló la instalación de Ubuntu."
}

# Configurar el entorno dentro de Ubuntu
configure_ubuntu() {
    msg "Configurando Ubuntu..."
    # Actualizar e instalar paquetes dentro del contenedor
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
        # Crear archivo .xinitrc para iniciar XFCE
        echo 'startxfce4 &' > /home/$USERNAME/.xinitrc
        chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc
    " || error "Falló la configuración dentro de Ubuntu."
}

# Generar script de inicio startubuntu.sh
generate_start_script() {
    local script_path="$PREFIX/bin/startubuntu.sh"
    msg "Generando script de inicio en $script_path"
    cat > "$script_path" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Script para iniciar Ubuntu con XFCE y VNC

set -e

# Verificar que Termux-X11 esté instalado
if ! command -v termux-x11 &>/dev/null; then
    echo "Instalando Termux-X11..."
    pkg install -y termux-x11
fi

# Iniciar servidor X11 en segundo plano
termux-x11 :1 -ac &

# Esperar un momento
sleep 2

# Iniciar Ubuntu con proot y ejecutar X11VNC y XFCE
proot-distro login ubuntu -- bash -c "
    export DISPLAY=:1
    # Iniciar X11VNC con la contraseña guardada
    x11vnc -display :1 -forever -usepw -passwd $VNCPASS &
    # Iniciar XFCE
    startxfce4
"

# Si el usuario cierra, matar procesos
trap "pkill -f termux-x11; pkill -f x11vnc" EXIT
EOF
    chmod +x "$script_path"
    msg "Script de inicio creado en $script_path"
    msg "Ejecuta 'startubuntu.sh' para iniciar el entorno gráfico."
}

# Función principal
main() {
    msg "=== Instalación de Ubuntu con XFCE en Termux ==="
    check_prerequisites
    load_user_data
    install_ubuntu
    configure_ubuntu
    generate_start_script
    msg "¡Instalación completada con éxito!"
    msg "Recuerda que el usuario es '$USERNAME' y la contraseña VNC es la que configuraste."
    msg "Para iniciar, ejecuta: startubuntu.sh"
}

# Ejecutar
main