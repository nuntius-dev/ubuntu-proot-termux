#!/bin/bash

# Detener posibles procesos conflictivos
killall termux-x11 2>/dev/null

# Iniciar el servidor X11
termux-x11 :1 &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1

# Esperar a que termux-x11 esté listo
sleep 2

# Configurar variables de entorno
export DISPLAY=:1
export PULSE_SERVER=127.0.0.1

# Iniciar Ubuntu con entorno gráfico
GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 proot-distro login ubuntu --shared-tmp -- /bin/bash -c "startxfce4"
