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

# Crear grupos necesarios
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f wheel"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f audio"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "groupadd -f video"

# Crear usuario en Ubuntu y configurar contraseña
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "useradd -m -s /bin/bash $username"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '$username:$password' | chpasswd"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "usermod -aG sudo $username"

# Configurar X11VNC con $username
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "mkdir -p /home/$username/.vnc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo 'zero' > /home/$username/.vnc/passvnc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-forever' > /home/$username/.x11vncrc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-shared' >> /home/$username/.x11vncrc"
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "echo '-passwdfile /home/$username/.vnc/passvnc' >> /home/$username/.x11vncrc"

# Bloquear instalación de snapd en Ubuntu
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 bash -c "cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF"

# ===================
# FINALIZAR CONFIGURACIÓN
# ===================
echo "alias ubuntu='proot-distro login ubuntu'" >> ~/.bashrc
source ~/.bashrc

# Configuración para aplicaciones gráficas en Termux
echo "allow-external-apps = true" >> ~/.termux/termux.properties
if pgrep termux-x11 > /dev/null; then
    killall termux-x11
fi
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
chmod +x ~/startubuntu.sh
# Crear alias para iniciar entorno gráfico
echo "alias startubuntu='~/startubuntu.sh'" >> ~/.bashrc
source ~/.bashrc

echo "Instalación completa. Usa el comando 'startubuntu' para iniciar el entorno gráfico."
