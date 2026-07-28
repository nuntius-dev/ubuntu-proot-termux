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

if ! proot-distro login ubuntu -- true >/dev/null 2>&1; then
    error "Ubuntu no está instalado. Ejecuta install-ubuntu-termux.sh primero."
fi

msg "=== Instalando Temas y Fondos (v11) ==="

proot-distro login ubuntu -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive

    msg() { echo -e \"\033[0;32m[INFO]\033[0m \$1\"; }

    msg \"Instalando dependencias necesarias...\"
    apt update || true
    apt install -y git plank sudo wget xz-utils sassc libglib2.0-dev

    msg \"Descargando fondo de macOS en la carpeta del sistema...\"
    # Aquí guardamos el fondo exactamente en la ruta que encontraste en tu captura
    wget -qO /usr/share/xfce4/backdrops/mac-wallpaper.jpg \"https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/master/1080p/BigSur-1.jpg\" || true

    msg \"Preparando instalación del tema oficial (WhiteSur)...\"
    
    cat << 'EOF_USER' > /tmp/install_themes_as_user.sh
#!/bin/bash
mkdir -p ~/.themes ~/.icons ~/.config/autostart

echo \"[INFO] Instalando WhiteSur GTK Theme...\"
rm -rf /tmp/WhiteSur-gtk
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk
cd /tmp/WhiteSur-gtk
# Lo instalamos localmente para asegurar permisos
./install.sh -d ~/.themes -N glassy -c Dark

echo \"[INFO] Instalando WhiteSur Icon Theme...\"
rm -rf /tmp/WhiteSur-icon
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon
cd /tmp/WhiteSur-icon
./install.sh -d ~/.icons

rm -rf /tmp/WhiteSur-*

echo \"[INFO] Configurando Dock y automatización...\"
cat <<EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
Name=Plank Dock
EOF

cat <<EOF > ~/.config/autostart/apply-mac-theme.desktop
[Desktop Entry]
Type=Application
Exec=bash -c \"sleep 5; xfconf-query -c xfwm4 -p /general/use_compositing -s true --create -t bool; xfconf-query -c xsettings -p /Net/ThemeName -s 'WhiteSur-Dark' --create -t string; xfconf-query -c xsettings -p /Net/IconThemeName -s 'WhiteSur-dark' --create -t string; xfconf-query -c xfwm4 -p /general/theme -s 'WhiteSur-Dark' --create -t string; xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /usr/share/xfce4/backdrops/mac-wallpaper.jpg --create -t string; xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image -s /usr/share/xfce4/backdrops/mac-wallpaper.jpg --create -t string; rm ~/.config/autostart/apply-mac-theme.desktop\"
Hidden=false
Name=Apply Mac Theme
EOF
EOF_USER

    chmod +x /tmp/install_themes_as_user.sh
    chown $USERNAME:$USERNAME /tmp/install_themes_as_user.sh
    
    msg \"Compilando temas (esto tomará un minuto)...\"
    su - $USERNAME -c \"/tmp/install_themes_as_user.sh\"
    
    rm /tmp/install_themes_as_user.sh
    msg \"¡Personalización completada!\"
"
