#!/bin/bash

# ===================
# INICIO DEL SCRIPT
# ===================

# Configurar nombre de usuario
read -r -p "Selecciona un nombre de usuario: " username </dev/tty

# Configurar contraseña para el usuario
read -r -s -p "Introduce una contraseña para $username: " password </dev/tty
echo # Salto de línea

# ===========================
# CONFIGURACIONES EN TERMUX
# ===========================

# Habilitar acceso al almacenamiento
termux-setup-storage

# Cambiar el repositorio para evitar errores
termux-change-repo

# Instalar repositorio gráfico y paquetes iniciales
pkg install -y x11-repo termux-x11-nightly
pkg update -y
pkg install -y dbus proot-distro pulseaudio virglrenderer-android x11vnc firefox pavucontrol-qt

# Verificar el fabricante del dispositivo
manufacturer=$(getprop ro.product.manufacturer)
if [ "$manufacturer" == "samsung" ]; then
  echo 'LD_PRELOAD=/system/lib64/libskcodec.so' >> ~/.bashrc
fi

# Iniciar Pulseaudio
echo 'pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1' >> ~/.bashrc
source ~/.bashrc

# ===========================
# INSTALACIÓN DE UBUNTU (Proot)
# ===========================

# Instalar Ubuntu con proot-distro
proot-distro install ubuntu

# Actualizar Ubuntu y paquetes iniciales
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "apt update -y && apt upgrade -y && apt install -y sudo xfce4 xfce4-terminal dbus-x11"

# Crear grupos y usuario en Ubuntu
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "
    groupadd -f wheel && groupadd -f audio && groupadd -f video
    useradd -m -s /bin/bash $username
    echo '$username:$password' | chpasswd
    usermod -aG sudo $username
"

# Configurar X11VNC
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "
    mkdir -p /home/$username/.vnc
    echo 'zero' > /home/$username/.vnc/passvnc
    echo '-forever\n-shared\n-passwdfile /home/$username/.vnc/passvnc' > /home/$username/.x11vncrc
"

# Bloquear instalación de snapd en Ubuntu
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "
    echo 'Package: snapd\nPin: release a=*\nPin-Priority: -10' | sudo tee /etc/apt/preferences.d/nosnap.pref
"

# ===================
# FINALIZAR CONFIGURACIÓN
# ===================
echo "alias ubuntu='proot-distro login ubuntu'" >> ~/.bashrc
source ~/.bashrc

# Configuración para aplicaciones gráficas en Termux
echo "allow-external-apps = true" >> ~/.termux/termux.properties
killall termux-x11 2>/dev/null
termux-x11 :1 >/dev/null &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

# Crear alias para iniciar entorno gráfico
echo "alias startubuntu='~/startubuntu.sh'" >> ~/.bashrc
source ~/.bashrc

echo "Instalación completa. Usa el comando 'startubuntu' para iniciar el entorno gráfico."
