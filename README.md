## ISC-DHCP-SETUP

Este script automatiza la instalación y configuración de un servidor **ISC DHCP** en sistemas basados en Debian/Ubuntu.

⚙️ **Configuración rápida y asistida desde consola**: podrás definir fácilmente los siguientes parámetros:

- `interface`: Configuración de la interfaz de red
- `authoritative`: Habilita o no el modo autoritativo (`True` o `False`)
- `default-lease-time` y `max-lease-time`: Duración de las concesiones DHCP
- `network-ip`, `netmask`, `broadcast`, `gateway`: Configuración de red
- `ip range` (inicio y fin): Rango de direcciones IP asignables
- `dns-server`: Servidor DNS (por defecto: `8.8.8.8`)
- `domain`: Nombre de dominio

> ⚠️ Puedes dejar parámetros en blanco pulsando `ENTER`, pero **algunos son obligatorios** para que el servicio funcione correctamente.

---

## 🚀 Instalación

1. **Clona el repositorio**:
   ```bash
   git clone https://github.com/mr4h4/service-start
   ```

2. **Ejecuta el script**:
   ```bash
   cd isc-dhcp-setup
   sudo ./setup.sh
   ```

> 🛠️ El script comprobará si `isc-dhcp-server` está instalado. Si no lo está, lo instalará automáticamente y te guiará paso a paso para completar la configuración del servicio.

---

## ✅ Verificación del servicio (opcional)

Una vez completada la instalación y configuración, puedes verificar el estado del servicio con:

```bash
sudo systemctl status isc-dhcp-server
```

O revisar los logs del sistema para depurar posibles errores:

```bash
journalctl -u isc-dhcp-server -f
```

---

📦 Compatible con entornos locales y pequeñas redes LAN que necesiten una configuración rápida de DHCP sin intervención manual compleja.

---
