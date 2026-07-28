#!/data/data/com.termux/files/usr/bin/bash
# install-ubuntu-termux.sh - Instalación automatizada Ubuntu + Antigravity + Chrome
# Repositorio: https://github.com/nuntius-dev/ubuntu-proot-termux

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

USERNAME="ubuntu"
VNCPASS="ubuntu"

msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_prerequisites() {
    msg "Verificando almacenamiento..."
    if [ ! -d "$HOME/storage" ]; then
        warn "Almacenamiento no configurado. Ejecuta 'termux-setup-storage' primero."
        exit 1
    fi
    msg "Configurando repositorios y dependencias..."
    pkg update -y
    pkg install -y x11-repo
    pkg update -y
    pkg install -y proot-distro termux-x11 wget curl
}

install_ubuntu() {
    # Verificamos si la carpeta física de Ubuntu existe
    if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
        msg "El contenedor de Ubuntu ya existe."
    else
        msg "Instalando Ubuntu RootFS..."
        proot-distro install ubuntu
    fi
}

configure_ubuntu() {
    msg "Configurando entorno gráfico y aplicaciones base..."
    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive
        
        apt update && apt upgrade -y
        apt install -y sudo wget curl nano xfce4 xfce4-goodies x11vnc xvfb dbus-x11 gnupg
        
        if ! id -u $USERNAME >/dev/null 2>&1; then
            useradd -m -s /bin/bash $USERNAME
        fi
        echo \"$USERNAME ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$USERNAME
        
        mkdir -p /home/$USERNAME/.vnc
        x11vnc -storepasswd \"$VNCPASS\" /home/$USERNAME/.vnc/passwd
        
        # Antigravity IDE
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
        echo \"deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-debian apt main\" > /etc/apt/sources.list.d/antigravity.list
        apt update && apt install -y antigravity
        
        # Google Chrome
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb -O /tmp/chrome.deb
        apt install -y /tmp/chrome.deb
        rm /tmp/chrome.deb
        
        if [ ! -f /usr/bin/google-chrome-stable-real ]; then
            mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real
            echo -e '#!/bin/bash\nexec /usr/bin/google-chrome-stable-real --no-sandbox \"\$@\"' > /usr/bin/google-chrome-stable
            chmod +x /usr/bin/google-chrome-stable
        fi
        
        # Accesos directos
        mkdir -p /home/$USERNAME/Desktop
        cat <<EOF > /home/$USERNAME/Desktop/antigravity.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity IDE
Exec=antigravity --no-sandbox
Icon=applications-development
Terminal=false
Categories=Development;IDE;
EOF
        cat <<EOF > /home/$USERNAME/Desktop/google-chrome.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Exec=/usr/bin/google-chrome-stable %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF
        
        chmod +x /home/$USERNAME/Desktop/*.desktop
        chown -R $USERNAME:$USERNAME /home/$USERNAME
    "
}

generate_start_script() {
    local script_path="$PREFIX/bin/startubuntu"
    msg "Generando script de inicio en $script_path..."
    cat > "$script_path" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -e
trap "pkill -f termux-x11; pkill -f x11vnc" EXIT
termux-wake-lock
termux-x11 :1 -ac &
sleep 2
proot-distro login ubuntu --user "$USERNAME" --shared-tmp -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=tcp:127.0.0.1:4713
    rm -f /tmp/.X1-lock
    x11vnc -display :1 -forever -usepw -bg
    startxfce4
"
EOF
    chmod +x "$script_path"
}

main() {
    msg "=== Instalación de Ubuntu XFCE Base ==="
    check_prerequisites
    install_ubuntu
    configure_ubuntu
    generate_start_script
    msg "¡Instalación base completada! Ejecuta 'startubuntu' para iniciar."
}

main
