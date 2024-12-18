#!/bin/bash

# Definir colores para los mensajes
export GREEN='\033[0;32m'
export UYELLOW='\033[4;33m'
export WHITE='\033[0;37m'

# Actualizar paquetes y repositorios
sudo apt update -y && sudo apt upgrade -y
echo -e "${UYELLOW}¿Deseas cambiar a un repositorio más rápido configurando un mirror? (y/n)${WHITE}"
read yn

case $yn in 
	y ) 
		echo -e "${GREEN}Configurando el mirror...${WHITE}"
		# Cambiar los repositorios a Debian Bullseye
		sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian bullseye main
deb-src http://deb.debian.org/debian bullseye main
deb http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian-security bullseye-security main
deb http://deb.debian.org/debian bullseye-updates main
deb-src http://deb.debian.org/debian bullseye-updates main
EOF
		sudo apt update -y
		;;
	* ) echo -e "${GREEN}Continuando con el repositorio actual.${WHITE}";;
esac

# Clonar el repositorio
echo -e "${GREEN}Clonando el repositorio...${WHITE}"
sudo apt install -y git
cd ~
git clone https://github.com/cheadrian/termux-chroot-proot-wine-box86_64
cd termux-chroot-proot-wine-box86_64/Scripts

# Ejecutar el script de instalación
echo -e "${GREEN}Ejecutando el script de instalación...${WHITE}"
sleep 1
chmod +x *.sh
./Stage_1_Install_Proot_VirGL_Box86_Wine.sh
