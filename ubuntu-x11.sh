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

# Cambiar el repositorio para evitar errores
termux-change-repo

# Instalar repositorio gráfico y paquetes iniciales
pkg install -y x11-repo
pkg update -y
pkg install -y dbus proot-distro pulseaudio virglrenderer-android x11vnc firefox pavucontrol-qt

# Verificar el fabricante del dispositivo
manufacturer=$(getprop ro.product.manufacturer)
if [ "$manufacturer" == "Samsung" ]; then
  echo -e 'LD_PRELOAD=/system/lib64/libskcodec.so\npulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1' | tee -a ../usr/etc/bash.bashrc
else
  pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
fi

# ===========================
# INSTALACIÓN DE UBUNTU (Proot)
# ===========================

# Instalar Ubuntu con proot-distro
proot-distro install ubuntu

# Actualizar Ubuntu y paquetes iniciales
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt update -y
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt upgrade -y
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt install -y sudo xfce4 xfce4-terminal dbus-x11

# Crear grupos necesarios si no existen
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f wheel"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f storage"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f audio"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f video"

# Crear usuario en Ubuntu y configurar contraseña
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "useradd -m -s /bin/bash $username"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '$username:$password' | chpasswd"

# Configurar sudo para el usuario
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "usermod -aG sudo $username"

# Crear directorios necesarios para VNC
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "mkdir -p /home/$username/.vnc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "touch /home/$username/.vnc/passvnc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "touch /home/$username/.x11vncrc"

# Configurar X11VNC con $username
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo 'zero' > /home/$username/.vnc/passvnc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-forever' > /home/$username/.x11vncrc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-shared' >> /home/$username/.x11vncrc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-passwdfile /home/$username/.vnc/passvnc' >> /home/$username/.x11vncrc"

# Eliminar paquetes innecesarios y bloquear snap
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# Bloquear instalación de snapd en Ubuntu
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF"

# ===================
# FINALIZAR CONFIGURACIÓN
# ===================
echo "Instalación completa. Usa el alias 'ubuntu' para iniciar sesión en tu entorno gráfico."
exit 0
