#!/data/data/com.termux/files/usr/bin/bash
# install_xfce4_mac.sh - Add-on de Estética macOS para Ubuntu en Termux
# Repositorio: https://github.com/nuntius-dev/ubuntu-proot-termux

set -e
set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

USERNAME="ubuntu"

msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar si la carpeta física de Ubuntu existe
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    error "Ubuntu no está instalado. Ejecuta install-ubuntu-termux.sh primero."
fi

msg "=== Instalando Tema macOS (WhiteSur) y Plank Dock ==="

proot-distro login ubuntu -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive

    msg() { echo -e \"\033[0;32m[INFO]\033[0m \$1\"; }

    msg \"Instalando dependencias de compilación y Plank...\"
    apt update
    apt install -y git sassc libglib2.0-dev plank

    msg \"Descargando e instalando WhiteSur GTK Theme...\"
    rm -rf /tmp/WhiteSur-gtk
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk
    /tmp/WhiteSur-gtk/install.sh -t all -N glassy -s 220

    msg \"Descargando e instalando WhiteSur Icon Theme...\"
    rm -rf /tmp/WhiteSur-icon
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon
    /tmp/WhiteSur-icon/install.sh

    msg \"Limpiando archivos temporales...\"
    rm -rf /tmp/WhiteSur-*

    msg \"Configurando automatización del entorno visual...\"
    mkdir -p /home/$USERNAME/.config/autostart
    
    # 1. Auto-arranque del Dock
    cat <<EOF > /home/$USERNAME/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
Name=Plank Dock
EOF

    # 2. Script Kamikaze para aplicar el tema en el próximo inicio de sesión gráfico
    cat <<EOF > /home/$USERNAME/.config/autostart/apply-mac-theme.desktop
[Desktop Entry]
Type=Application
Exec=bash -c \"xfconf-query -c xsettings -p /Net/ThemeName -s 'WhiteSur-Dark' --create -t string; xfconf-query -c xsettings -p /Net/IconThemeName -s 'WhiteSur-dark' --create -t string; xfconf-query -c xfwm4 -p /general/theme -s 'WhiteSur-Dark' --create -t string; rm /home/$USERNAME/.config/autostart/apply-mac-theme.desktop\"
Hidden=false
Name=Apply Mac Theme
EOF

    chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
    msg \"¡Personalización completada con éxito!\"
"

msg "El tema macOS se aplicará automáticamente la próxima vez que ejecutes 'startubuntu'."
