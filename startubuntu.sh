#!/bin/bash

# Detener posibles procesos conflictivos
if pgrep termux-x11 > /dev/null; then
    killall termux-x11
fi

# Iniciar el servidor X11
#termux-x11 :1 &
#am start --user 0 -n com.termux.x11/#com.termux.x11.MainActivity >/dev/null #2>&1

# Esperar a que termux-x11 esté listo
#while ! pgrep Xvnc > /dev/null; do
#    sleep 1
#done

# Configurar variables de entorno
#export DISPLAY=:1
#export PULSE_SERVER=127.0.0.1

# Iniciar Ubuntu con entorno gráfico
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 startxfce4
