#!/bin/bash

# Verificar si Termux-X11 está activo
if ! pgrep termux-x11 > /dev/null; then
    termux-x11 :1 &
    sleep 5
fi

# Configurar variables de entorno
export DISPLAY=:1
export PULSE_SERVER=127.0.0.1

# Iniciar Ubuntu con entorno gráfico
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 startxfce4