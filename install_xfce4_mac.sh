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

msg "=== Instalando Tema SmallSur y Plank Dock ==="

proot-distro login ubuntu -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive

    msg() { echo -e \"\033[0;32m[INFO]\033[0m \$1\"; }

    msg \"Instalando dependencias base y Plank...\"
    apt update || true
    # Ya no necesitamos 'sassc' ni compiladores pesados
    apt install -y git plank sudo

    msg \"Preparando instalación de temas...\"
    
    cat << 'EOF_USER' > /tmp/install_themes_as_user.sh
#!/bin/bash
mkdir -p ~/.themes ~/.icons ~/.config/autostart

echo \"[INFO] Descargando e instalando SmallSur GTK Theme...\"
rm -rf ~/.themes/SmallSur
# Clonamos el tema directamente en la carpeta de temas de XFCE
git clone --depth=1 https://github.com/jothi-prasath/SmallSur.git ~/.themes/SmallSur

echo \"[INFO] Descargando e instalando WhiteSur Icon Theme...\"
rm -rf /tmp/WhiteSur-icon
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon
cd /tmp/WhiteSur-icon
./install.sh -d ~/.icons
rm -rf /tmp/WhiteSur-icon

echo \"[INFO] Configurando Dock y automatización visual...\"
cat <<EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
Name=Plank Dock
EOF

# Cambiamos la instrucción para que active 'SmallSur' en lugar del viejo WhiteSur
cat <<EOF > ~/.config/autostart/apply-mac-theme.desktop
[Desktop Entry]
Type=Application
Exec=bash -c \"sleep 4; xfconf-query -c xsettings -p /Net/ThemeName -s 'SmallSur' --create -t string; xfconf-query -c xsettings -p /Net/IconThemeName -s 'WhiteSur-dark' --create -t string; xfconf-query -c xfwm4 -p /general/theme -s 'SmallSur' --create -t string; rm ~/.config/autostart/apply-mac-theme.desktop\"
Hidden=false
Name=Apply Mac Theme
EOF
EOF_USER

    chmod +x /tmp/install_themes_as_user.sh
    chown $USERNAME:$USERNAME /tmp/install_themes_as_user.sh
    
    msg \"Ejecutando instalación ultra-rápida...\"
    su - $USERNAME -c \"/tmp/install_themes_as_user.sh\"
    
    rm /tmp/install_themes_as_user.sh

    msg \"¡Personalización completada con éxito!\"
"

msg "El tema macOS se aplicará automáticamente la próxima vez que ejecutes 'startubuntu'."
