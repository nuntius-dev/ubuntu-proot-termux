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

# Habilitar acceso al almacenamiento
termux-setup-storage

# Configuración para aplicaciones gráficas en Termux
echo "allow-external-apps = true" >> ~/.termux/termux.properties
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Configurar Termux X11 para el escritorio
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :1 >/dev/null &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Crear alias para iniciar Ubuntu fácilmente
echo "alias ubuntu='am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 && sleep 1 && GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 proot-distro login ubuntu --shared-tmp -- /bin/bash -c \"export PULSE_SERVER=127.0.0.1 && export XDG_RUNTIME_DIR=\\\\\${TMPDIR} && su - $username -c \\\"sh -c \\\\\\\"termux-x11 :1 -xstartup \\\\\\\\\\\\\\\"dbus-launch --exit-with-session xfce4-session\\\\\\\\\\\\\\\" && env DISPLAY=:1 startxfce4\\\\\\\"\\\"\"'" >> $HOME/.bashrc
source ~/.bashrc

# ===========================
# INSTALACIÓN DE UBUNTU (Proot)
# ===========================

# Instalar Ubuntu con proot-distro
proot-distro install ubuntu

# Actualizar Ubuntu y paquetes iniciales
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt update -y
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt upgrade -y
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 apt install -y sudo xfce4 xfce4-terminal dbus-x11

# Configuración de zona horaria según el dispositivo
timezone=$(getprop persist.sys.timezone)
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 rm /etc/localtime
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 cp /usr/share/zoneinfo/$timezone /etc/localtime

# Crear usuario en Ubuntu y configurar contraseña
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 useradd -m -g users -G wheel,audio,video,storage -s /bin/bash "$username"
echo "$username:$password" | proot-distro login ubuntu --shared-tmp -- chpasswd

# Configurar sudo para el usuario
chmod u+rw $HOME/../usr/var/lib/proot-distro/installed-rootfs/ubuntu/etc/sudoers
echo "$username ALL=(ALL) ALL" | tee -a $HOME/../usr/var/lib/proot-distro/installed-rootfs/ubuntu/etc/sudoers > /dev/null
chmod u-w $HOME/../usr/var/lib/proot-distro/installed-rootfs/ubuntu/etc/sudoers

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
