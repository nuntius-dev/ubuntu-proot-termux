🐧 Ubuntu PRoot Termux (XFCE + Antigravity IDE + Chrome)

Este repositorio contiene un script de instalación 100% automatizado (zero-touch) para desplegar un entorno de escritorio Ubuntu completo (XFCE) directamente en tu dispositivo Android usando Termux y PRoot.

El script está optimizado para desarrolladores e incluye las versiones oficiales de Google Chrome (ARM64) y Antigravity IDE, listos para usarse con los parches necesarios para funcionar en contenedores (solucionando el error de inicio de sesión de Google/OAuth).

✨ Características

· Automatizado: No requiere interacción del usuario (ni nombres, ni contraseñas, ni repositorios manuales).
· Entorno Gráfico: Instala XFCE4 preconfigurado para correr sobre VNC.
· Chrome Parcheado: Incluye un "Wrapper" automático que inyecta --no-sandbox para que Chrome funcione y permita inicios de sesión desde aplicaciones de terceros.
· Seguridad y Rendimiento: Configura sudoers correctamente y aplica bloqueos de suspensión (WakeLock) para evitar congelamientos.

---

🚀 Instalación Rápida (1 Comando)

Antes de comenzar, asegúrate de tener instalada la versión de Termux desde F-Droid (no uses la versión de la Play Store, está obsoleta).

1. Abre Termux y concede permisos de almacenamiento (escribe y si te lo pregunta):
   
2. Copia, pega y ejecuta este comando para iniciar la instalación mágica:
   

El proceso tomará unos minutos dependiendo de tu conexión a internet. ¡No cierres la aplicación!

💻 Uso y Acceso

Una vez que el script finalice, iniciar tu sistema es muy sencillo:

1. En la consola de Termux, escribe:
   
2. Abre tu cliente VNC favorito (como AVNC o RealVNC) y conéctate a:
   · Dirección: 127.0.0.1:5901 (o puerto local 5901)
   · Contraseña VNC: ubuntu

Nota: El usuario del sistema es ubuntu y su contraseña para usar el comando sudo también es ubuntu.

⚠️ Solución de Problemas (¡Importante!)

Termux se cierra solo o el sistema se congela (Phantom Process Killer)

A partir de Android 12, Google introdujo una medida estricta de batería que "mata" aplicaciones que generan muchos subprocesos, como lo hace este entorno de escritorio.

Para que tu Ubuntu funcione de forma fluida y no crashee, debes desactivar esta restricción mediante ADB usando una computadora o depuración inalámbrica.

Ejecuta estos dos comandos desde tu PC conectados a tu Android:

```bash
adb shell "device_config put activity_manager max_phantom_processes 2147483647"
adb shell "device_config set_sync_disabled_for_tests persistent"
```

(Ten en cuenta que en algunos dispositivos, este parche debe volver a aplicarse si reinicias el teléfono por completo).