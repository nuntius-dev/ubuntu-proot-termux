#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  🚀 NUNTIUS DEV ENVIRONMENT - Ultimate Master v8.0
#  
#  Sitio Web: https://nuntius.dev
#  Incluye: XFCE4, Tema Mac, GPU Accel, Wine,
#           Antigravity IDE & Google Chrome
#######################################################

# ============== CONFIGURACIÓN ==============
TOTAL_STEPS=12
CURRENT_STEP=0
USERNAME="devroom"
DEBIAN_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/debian"
IDE_VERSION="1.23.2"
IDE_BUILD="4781536860569600"
ANTIGRAVITY_DL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${IDE_VERSION}-${IDE_BUILD}/linux-arm/Antigravity.tar.gz"

# ============== COLORES ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# ============== FUNCIONES DE UI ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))

    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
    BAR+="${NC}"

    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📊 PROGRESO NUNTIUS: ${WHITE}Paso ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${YELLOW}⏳${NC} ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r  ${GREEN}✓${NC} ${message}                    \n"
    else
        printf "\r  ${RED}✗${NC} ${message} ${RED}(falló)${NC}     \n"
        exit 1
    fi
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════════╗
    ║                                              ║
    ║   🚀  NUNTIUS DEV ENVIRONMENT v8.0  🚀       ║
    ║                                              ║
    ║            https://nuntius.dev               ║
    ║                                              ║
    ╚══════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

detect_device() {
    echo -e "${CYAN}[*] Detectando hardware de tu dispositivo...${NC}"
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")

    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" =~ (samsung|Samsung|oneplus|xiaomi) ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}🎮${NC} GPU Detectada: ${WHITE}Adreno (Qualcomm) - Turnip driver${NC}"
    else
        GPU_DRIVER="swrast"
        echo -e "  ${GREEN}🎮${NC} GPU Detectada: ${WHITE}Genérica - Software rendering${NC}"
    fi
    sleep 1
}

# ============== PASOS DE INSTALACIÓN ==============

step_base() {
    update_progress
    echo -e "${CYAN}[+] Preparando entorno base de Termux...${NC}"

    export DEBIAN_FRONTEND=noninteractive

    echo "tzdata tzdata/Areas select America" | debconf-set-selections 2>/dev/null || true
    echo "tzdata tzdata/Zones/America select Santiago" | debconf-set-selections 2>/dev/null || true
    ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime 2>/dev/null || true

    (yes | pkg update -y > /dev/null 2>&1 || true) & spinner $! "Actualizando listas..."
    (DEBIAN_FRONTEND=noninteractive yes "" | pkg upgrade -y -o Dpkg::Options::="--force-confnew" > /dev/null 2>&1 || true) & spinner $! "Actualizando paquetes del sistema..."
    (yes | pkg install -y x11-repo tur-repo > /dev/null 2>&1 || true) & spinner $! "Añadiendo repositorios avanzados..."
    (yes | pkg install -y proot-distro pulseaudio termux-x11-nightly aria2 wget > /dev/null 2>&1 || true) & spinner $! "Instalando dependencias core..."
}

step_gpu() {
    update_progress
    echo -e "${CYAN}[+] Configurando Aceleración de Hardware (GPU)...${NC}"
    
    # SOLUCIÓN V8: Purgar el loader genérico e instalar el nativo de Android
    (yes | pkg uninstall -y vulkan-loader-generic > /dev/null 2>&1 || true) & spinner $! "Resolviendo conflictos de dependencias Vulkan..."
    (yes | pkg install -y mesa-zink vulkan-loader-android > /dev/null 2>&1 || true) & spinner $! "Instalando backend de Vulkan nativo..."

    if [ "$GPU_DRIVER" == "freedreno" ]; then
        (yes | pkg install -y mesa-vulkan-icd-freedreno > /dev/null 2>&1 || true) & spinner $! "Instalando drivers Turnip (Adreno)..."
    else
        (yes | pkg install -y mesa-vulkan-icd-swrast > /dev/null 2>&1 || true) & spinner $! "Instalando drivers de compatibilidad..."
    fi

    mkdir -p ~/.config
    cat > ~/.config/nuntius-gpu.sh << 'GPUEOF'
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
GPUEOF
}

step_wine() {
    update_progress
    echo -e "${CYAN}[+] Instalando capa de compatibilidad Windows (Wine)...${NC}"
    (yes | pkg remove wine-stable -y > /dev/null 2>&1 || true)
    (yes | pkg install -y hangover-wine hangover-wowbox64 > /dev/null 2>&1 || true) & spinner $! "Instalando Hangover-Wine y Box64..."
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine /data/data/com.termux/files/usr/bin/wine 2>/dev/null || true
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/winecfg /data/data/com.termux/files/usr/bin/winecfg 2>/dev/null || true
}

step_debian() {
    update_progress
    echo -e "${CYAN}[+] Instalando Subsistema Debian...${NC}"
    if [ ! -d "$DEBIAN_ROOT" ]; then
        (proot-distro install debian > /dev/null 2>&1 || true) & spinner $! "Descargando imagen Debian..."
    else
        echo -e "  ${GREEN}✓${NC} Debian ya está instalado."
    fi
}

step_debian_packages() {
    update_progress
    echo -e "${CYAN}[+] Configurando entorno gráfico y paquetes base...${NC}"
    
    (proot-distro login debian -- sh -c "export DEBIAN_FRONTEND=noninteractive; export TZ=America/Santiago; apt update -y && apt install -y sudo xfce4 xfce4-terminal plank thunar git sassc wget curl dbus-x11 gnupg xdg-utils > /dev/null 2>&1 || true") & spinner $! "Instalando XFCE4 y utilidades..."
    
    (proot-distro login debian -- bash -c "if ! id -u $USERNAME >/dev/null 2>&1; then /usr/sbin/useradd -m -s /bin/bash $USERNAME; fi; passwd -d $USERNAME; mkdir -p /etc/sudoers.d; echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USERNAME; chmod 440 /etc/sudoers.d/$USERNAME" > /dev/null 2>&1 || true) & spinner $! "Creando usuario desarrollador..."
}

step_mac_theme() {
    update_progress
    echo -e "${CYAN}[+] Aplicando Nuntius UI (macOS Estética)...${NC}"
    cat << 'EOF_THEME' > "$DEBIAN_ROOT/tmp/theme.sh"
#!/bin/bash
mkdir -p ~/.themes ~/.icons ~/.config/autostart ~/Pictures
wget -qO ~/Pictures/mac-wallpaper.jpg "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/master/1080p/BigSur-1.jpg"
rm -rf ~/.themes/SmallSur && git clone --depth=1 https://github.com/jothi-prasath/SmallSur.git ~/.themes/SmallSur > /dev/null 2>&1
rm -rf /tmp/icon && git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/icon > /dev/null 2>&1
cd /tmp/icon && ./install.sh -d ~/.icons > /dev/null 2>&1
cat <<EOF > ~/.config/autostart/nuntius-ui.desktop
[Desktop Entry]
Type=Application
Exec=bash -c "sleep 3; xfconf-query -c xfce4-panel -p /panels -t int -s 1 -a; plank & xfconf-query -c xfwm4 -p /general/use_compositing -s true --create -t bool; xfconf-query -c xsettings -p /Net/ThemeName -s 'SmallSur' --create -t string; xfconf-query -c xsettings -p /Net/IconThemeName -s 'WhiteSur-dark' --create -t string; xfconf-query -c xfwm4 -p /general/theme -s 'SmallSur' --create -t string; xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s ~/Pictures/mac-wallpaper.jpg --create -t string; rm ~/.config/autostart/nuntius-ui.desktop"
Hidden=false
Name=Nuntius UI Init
EOF
EOF_THEME
    chmod +x "$DEBIAN_ROOT/tmp/theme.sh"
    (proot-distro login debian -- su - $USERNAME -c "/tmp/theme.sh" > /dev/null 2>&1 || true) & spinner $! "Compilando tema visual..."
}

step_ide() {
    update_progress
    echo -e "${CYAN}[+] Instalando Nuntius IDE (Google Antigravity)...${NC}"
    mkdir -p "$DEBIAN_ROOT/opt/ide"
    (aria2c -x 8 -s 8 -d "$DEBIAN_ROOT/opt/ide" -o Antigravity.tar.gz "$ANTIGRAVITY_DL" > /dev/null 2>&1 || true) & spinner $! "Descargando binarios del IDE..."
    (proot-distro login debian -- sh -c "cd /opt/ide && tar -xzf Antigravity.tar.gz && mv Antigravity-* Antigravity 2>/dev/null || true && chmod +x Antigravity/bin/antigravity && rm -f Antigravity.tar.gz") & spinner $! "Extrayendo entorno de desarrollo..."
}

step_chrome() {
    update_progress
    echo -e "${CYAN}[+] Instalando Google Chrome...${NC}"
    (proot-distro login debian -- sh -c "export DEBIAN_FRONTEND=noninteractive; wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb -O /tmp/chrome.deb && apt install -y /tmp/chrome.deb > /dev/null 2>&1 && rm -f /tmp/chrome.deb || true") & spinner $! "Descargando e instalando Chrome..."

    (proot-distro login debian -- sh -c "if [ ! -f /usr/bin/google-chrome-stable-real ]; then mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real 2>/dev/null; echo -e '#!/bin/bash\nexec /usr/bin/google-chrome-stable-real --no-sandbox \"\$@\"' > /usr/bin/google-chrome-stable 2>/dev/null; chmod +x /usr/bin/google-chrome-stable 2>/dev/null; fi || true") & spinner $! "Aplicando optimización sandbox..."
}

step_shortcuts() {
    update_progress
    echo -e "${CYAN}[+] Creando accesos directos en el escritorio...${NC}"
    cat << 'EOF_SHORT' > "$DEBIAN_ROOT/tmp/shortcuts.sh"
#!/bin/bash
mkdir -p ~/Desktop
cat <<EOF > ~/Desktop/antigravity.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity IDE
Exec=/opt/ide/Antigravity/bin/antigravity --no-sandbox
Icon=applications-development
Terminal=false
Categories=Development;IDE;
EOF

cat <<EOF > ~/Desktop/google-chrome.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Exec=/usr/bin/google-chrome-stable %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x ~/Desktop/*.desktop
EOF_SHORT
    chmod +x "$DEBIAN_ROOT/tmp/shortcuts.sh"
    (proot-distro login debian -- su - $USERNAME -c "/tmp/shortcuts.sh" > /dev/null 2>&1 || true) & spinner $! "Generando iconos de acceso..."
}

step_audio() {
    update_progress
    echo -e "${CYAN}[+] Configurando Servidor de Audio...${NC}"
    if ! grep -q "module-native-protocol-tcp" ~/.zshrc 2>/dev/null && ! grep -q "module-native-protocol-tcp" ~/.bashrc 2>/dev/null; then
        echo "pulseaudio --start --exit-idle-time=-1; pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null" >> ~/.bashrc
    fi
    echo -e "  ${GREEN}✓${NC} PulseAudio configurado correctamente."
}

step_launchers() {
    update_progress
    echo -e "${CYAN}[+] Creando script de inicio Nuntius...${NC}"

    cat > ~/start-nuntius.sh << 'EOF_LAUNCH'
#!/data/data/com.termux/files/usr/bin/bash
echo "🚀 Iniciando Nuntius Dev Environment..."
source ~/.config/nuntius-gpu.sh 2>/dev/null
pkill -9 -f "termux.x11" 2>/dev/null
pulseaudio --kill 2>/dev/null
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1
termux-x11 :0 -ac &
sleep 2
proot-distro login debian --shared-tmp -- su - devroom -c "export DISPLAY=:0 && export PULSE_SERVER=127.0.0.1 && dbus-launch --exit-with-session startxfce4"
EOF_LAUNCH
    chmod +x ~/start-nuntius.sh
    echo -e "  ${GREEN}✓${NC} Lanzador creado en ~/start-nuntius.sh"
}

show_completion() {
    update_progress
    echo ""
    echo -e "${GREEN}  ╔════════════════════════════════════════════════╗"
    echo -e "  ║         ✅ INSTALACIÓN COMPLETADA ✅           ║"
    echo -e "  ╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}  Todo el software (Antigravity, Chrome, XFCE) está listo.${NC}"
    echo -e "${CYAN}  Para iniciar el entorno, escribe:${NC} ${GREEN}./start-nuntius.sh${NC}"
    echo ""
    echo -e "${GRAY}  * Abre la aplicación Termux-X11 antes de lanzar el script.${NC}"
    echo ""
}

# ============== EJECUCIÓN ==============
main() {
    show_banner
    detect_device
    step_base
    step_gpu
    step_wine
    step_debian
    step_debian_packages
    step_mac_theme
    step_ide
    step_chrome
    step_shortcuts
    step_audio
    step_launchers
    show_completion
}

main
