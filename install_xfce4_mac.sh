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

msg "=== Instalando Tema macOS (WhiteSur) y Plank Dock ==="

proot-distro login ubuntu -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive

    msg() { echo -e \"\033[0;32m[INFO]\033[0m \$1\"; }

    msg \"Instalando dependencias de compilación y Plank...\"
    apt update || true
    apt install -y git sassc libglib2.0-dev plank xz-utils sudo

    msg \"Preparando instalación de temas...\"
    
    # Creamos un script temporal para ejecutarlo disfrazados del usuario normal
    # Esto evita el bloqueo de seguridad del tema por intentar instalar como 'root'
    cat << 'EOF_USER' > /tmp/install_themes_as_user.sh
#!/bin/bash
mkdir -p ~/.themes ~/.icons ~/.config/autostart

echo "[INFO] Descargando y compilando WhiteSur GTK Theme..."
rm -rf ~/WhiteSur-gtk
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk
cd ~/WhiteSur-gtk
./install.sh -c Dark

echo "[INFO] Descargando y compilando WhiteSur Icon Theme..."
rm -rf ~/WhiteSur-icon
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon
cd ~/WhiteSur-icon
./install.sh

echo "[INFO] Limpiando archivos de instalación..."
rm -rf ~/WhiteSur-*

echo "[INFO] Configurando Dock y automatización visual..."
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
Exec=bash -c \"sleep 4; xfconf-query -c xsettings -p /Net/ThemeName -s 'WhiteSur-Dark' --create -t string; xfconf-query -c xsettings -p /Net/IconThemeName -s 'WhiteSur-dark' --create -t string; xfconf-query -c xfwm4 -p /general/theme -s 'WhiteSur-Dark' --create -t string; rm ~/.config/autostart/apply-mac-theme.desktop\"
Hidden=false
Name=Apply Mac Theme
EOF
EOF_USER

    # Damos permisos y ejecutamos el script disfrazados de 'ubuntu'
    chmod +x /tmp/install_themes_as_user.sh
    chown $USERNAME:$USERNAME /tmp/install_themes_as_user.sh
    
    msg \"Ejecutando instalación segura (esto tomará uno o dos minutos)...\"
    su - $USERNAME -c \"/tmp/install_themes_as_user.sh\"
    
    rm /tmp/install_themes_as_user.sh

    msg \"¡Personalización completada con éxito!\"
"

msg "El tema macOS se aplicará automáticamente la próxima vez que ejecutes 'startubuntu'."
