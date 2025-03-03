# Verificar si Termux-X11 está activo en :2
if ! pgrep termux-x11 > /dev/null; then
    termux-x11 :2 &
    sleep 5
fi

# Configurar variables de entorno
export DISPLAY=:2
export PULSE_SERVER=127.0.0.1

# Configurar autorización
export XAUTHORITY=$HOME/.Xauthority
touch $XAUTHORITY
xauth generate :2 . trusted

# Iniciar Ubuntu con entorno gráfico
proot-distro login ubuntu --shared-tmp -- env DISPLAY=:2 startxfce4