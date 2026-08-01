# 🐧 Nuntius Dev Environment (Debian / XFCE4 + Antigravity IDE + Chrome)

Este repositorio contiene un script de instalación **100% automatizado (zero-touch)** para desplegar un entorno de escritorio Linux completo (XFCE4) con estética macOS, aceleración gráfica por hardware (Turnip/Zink), Wine y herramientas de desarrollo directamente en tu dispositivo Android usando Termux y PRoot-distro.

El script está optimizado para desarrolladores e incluye las versiones oficiales de **Google Chrome (ARM64)** y **Antigravity IDE**, listos para usarse con optimizaciones de rendimiento y wrappers de seguridad para entornos en contenedores.

## ✨ Características

* **Automatizado (Zero-Touch):** Configuración de zonas horarias, repositorios avanzados y dependencias core de forma desatendida.
* **Aceleración por Hardware:** Detección automática de GPU (Adreno / Turnip) y configuración de Mesa Zink para máximo rendimiento gráfico.
* **Entorno Gráfico Moderno:** XFCE4 preconfigurado con paquetes de iconos y temas personalizados (SmallSur / WhiteSur).
* **Capa Windows (Wine):** Integración con Hangover-Wine y Box64 para ejecutar aplicaciones de Windows.
* **IDE y Navegador Nativos:** Incluye Google Antigravity IDE y Google Chrome con optimización `--no-sandbox`.

---

## 🚀 Instalación Rápida (1 Comando)

Antes de comenzar, asegúrate de tener instalada la versión de **Termux** desde [F-Droid](https://f-droid.org/packages/com.termux/) (evita la versión de la Google Play Store por estar obsoleta).

1. Abre Termux y asegúrate de permitir los permisos de almacenamiento cuando el script o el sistema te lo soliciten.
2. Copia, pega y ejecuta este comando para iniciar la instalación de Nuntius:
```bash
curl -sL https://raw.githubusercontent.com/nuntius-dev/ubuntu-proot-termux/main/debian.sh | bash

```



El proceso tomará unos minutos dependiendo de la velocidad de tu conexión a internet. ¡No cierres la aplicación durante el proceso!

---

## 💻 Uso y Acceso

Una vez que el script finalice la instalación, iniciar tu entorno gráfico es muy sencillo:

1. Abre la aplicación **Termux-X11** en tu Android previamente.
2. En la consola de Termux, escribe y ejecuta:
```bash
./start-nuntius.sh

```


3. Dirígete a tu app Termux-X11 para disfrutar del escritorio completo.

---

## 🛠️ Herramientas y Accesos Directos Incluidos

* **Antigravity IDE:** Entorno de desarrollo avanzado.
* **Google Chrome:** Navegador web optimizado para ARM64.
* **XFCE4 Terminal & Thunar:** Terminal y administrador de archivos.
* **Plank Dock:** Barra de tareas flotante con estética macOS.
