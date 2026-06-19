# GioRoku — Manual de Usuario

> Tu televisión latina en Roku. Canal personalizado, sin suscripciones.

---

## Índice

1. [Requisitos](#requisitos)
2. [Arquitectura del sistema](#arquitectura)
3. [Configuración inicial de GitHub](#configuración-inicial-de-github)
4. [Cargar canales con M3U Loader](#cargar-canales-con-m3u-loader)
5. [Instalar la app en Roku (sideload)](#instalar-la-app-en-roku-sideload)
6. [Uso de la app en el Roku](#uso-de-la-app-en-el-roku)
7. [Portal de administración](#portal-de-administración)
8. [Actualizar canales](#actualizar-canales)
9. [Solución de problemas](#solución-de-problemas)

---

## Requisitos

| Componente | Requerimiento |
|---|---|
| Roku | Cualquier modelo con Developer Mode |
| GitHub | Cuenta gratuita + repositorio público |
| Navegador | Chrome, Firefox o Edge (para M3U Loader) |
| Lista M3U | URL pública o archivo .m3u descargado |

---

## Arquitectura

```
Tu lista .m3u
     │
     ▼
┌─────────────────────────┐
│  M3U Loader (HTML)      │  ← Abre en tu navegador
│  Parsea · Enriquece     │
│  Detecta país/categoría │
└────────────┬────────────┘
             │  Escribe JSON via GitHub API
             ▼
┌─────────────────────────┐
│  GitHub Pages           │  ← API pública gratuita
│  api/v1/status.json     │
│  api/v1/channels/...    │
│  api/v1/categories.json │
└────────────┬────────────┘
             │  HTTP GET
             ▼
┌─────────────────────────┐
│  GioRoku (Roku app)     │  ← Instalada por sideload
│  Splash → Home → Player │
└─────────────────────────┘
```

**Principio clave:** El Roku NUNCA lee archivos .m3u directamente.
Solo consume JSON desde tu GitHub Pages.

---

## Configuración inicial de GitHub

### 1. Crear el repositorio

1. Ve a [github.com/new](https://github.com/new)
2. Nombre: `GioRoku`
3. Visibilidad: **Public** (requerido para GitHub Pages gratuito)
4. Crear repositorio

### 2. Habilitar GitHub Pages

1. Ve a tu repositorio → **Settings** → **Pages**
2. Source: **Deploy from a branch**
3. Branch: **main** → folder **/ (root)**
4. Guardar

Después de ~2 minutos tu API estará en:
`https://TU_USUARIO.github.io/GioRoku/api/v1/status.json`

### 3. Crear un Personal Access Token (PAT)

1. Ve a [github.com/settings/tokens](https://github.com/settings/tokens)
2. → **Fine-grained tokens** → Generate new token
3. Nombre: `GioRoku M3U Loader`
4. Repository access: **Only select repositories** → GioRoku
5. Permissions → **Contents: Read and Write**
6. Generate token → **Copia el token** (solo se muestra una vez)

---

## Cargar canales con M3U Loader

El M3U Loader es una herramienta HTML que corre directo en tu navegador, sin instalar nada.

### Paso 1 — Configurar GitHub

```
┌─────────────────────────────────────────────────────────┐
│  ⚙️ Configuración de GitHub                              │
│                                                          │
│  Usuario/Org  [jgpazvega-ae    ]  Repo [GioRoku       ] │
│  Rama         [main            ]  PAT  [ghp_••••••••  ] │
│                                                          │
│  [💾 Guardar]  [🔌 Probar conexión]  [Siguiente →]      │
└─────────────────────────────────────────────────────────┘
```

1. Abre `m3u-loader.html` en tu navegador (doble clic en el archivo)
2. Llena los campos: **tu usuario de GitHub**, `GioRoku`, `main`, y tu **PAT**
3. Haz clic en **"Probar conexión"** — debe aparecer `✓ TuUsuario/GioRoku (public)`
4. Haz clic en **"Guardar credenciales"** (se guardan en localStorage, no salen del navegador)
5. Haz clic en **"Siguiente →"**

### Paso 2 — Cargar la lista M3U

**Opción A — Por URL:**
```
┌─────────────────────────────────────────────────────────┐
│  📋 Lista M3U                                            │
│  [🔗 URL]  [📁 Archivo .m3u]                            │
│                                                          │
│  URL: [https://iptv-org.github.io/iptv/...mx.m3u      ] │
│                                                    [Cargar] │
└─────────────────────────────────────────────────────────┘
```

Pega la URL de tu lista M3U y haz clic en **"Cargar"**.

> Si la URL tiene restricciones CORS, el loader automáticamente intenta via corsproxy.io.
> Si sigue fallando, descarga el archivo y usa la Opción B.

**Opción B — Por archivo:**

Arrastra tu archivo `.m3u` al área de carga, o haz clic para seleccionarlo.

### Paso 3 — Filtrar canales

```
┌─────────────────────────────────────────────────────────┐
│  🔍 Vista previa y filtros                               │
│                                                          │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                  │
│  │1,234 │ │  12  │ │   8  │ │  890 │                   │
│  │Total │ │Países│ │Cats. │ │Selecc│                   │
│  └──────┘ └──────┘ └──────┘ └──────┘                  │
│                                                          │
│  País: [México (456) ▼]  Cat: [Todas ▼]  [✕ Limpiar]  │
│                                                          │
│  #   Canal           País    Categoría   URL             │
│  1   Azteca 7        MX      Entretenimien https://...  │
│  2   Canal 5         MX      Entretenimien https://...  │
│  …                                                       │
└─────────────────────────────────────────────────────────┘
```

Puedes filtrar por **país** y/o **categoría** antes de publicar.
El contador "Seleccionados" muestra cuántos canales se van a publicar.

Haz clic en **"Publicar N canales →"**.

### Paso 4 — Publicar

```
┌─────────────────────────────────────────────────────────┐
│  🚀 Publicar en GitHub Pages                            │
│                                                          │
│  📦 Repositorio: jgpazvega-ae/GioRoku                   │
│  🌿 Rama:        main                                   │
│  📺 Canales:     1,234                                  │
│  📄 Archivos:    25 archivos JSON                       │
│                                                          │
│  [⬆️ Confirmar y publicar a GitHub Pages]               │
└─────────────────────────────────────────────────────────┘
```

Haz clic en **"Confirmar y publicar"**. Verás una barra de progreso:

```
(12/25) page/2.json                          48%
████████████████████░░░░░░░░░░░░░░░░░░░░

✓ api/v1/channels/page/1.json
✓ api/v1/channels/page/2.json
✓ api/v1/channels/country/MX.json
…
```

Al terminar:

```
✅ ¡Publicado con éxito! — 1,234 canales en GitHub Pages.
   En tu Roku: Settings → Developer → Force refresh now
```

GitHub Pages tarda ~1-2 minutos en propagar los cambios.

---

## Instalar la app en Roku (sideload)

### 1. Activar Developer Mode en el Roku

Con el control del Roku, desde la pantalla de inicio:

```
Home × 3  →  Up × 2  →  Right  →  Left  →  Right  →  Left  →  Right
```

Aparecerá el panel de Developer Mode. Actívalo y anota:
- **IP del Roku** (ej: `192.168.1.45`)
- **Contraseña de developer** (la creas tú)

### 2. Acceder al portal de sideload

Abre en tu navegador:
```
http://192.168.1.45    (IP de tu Roku)
```

Aparecerá un login. Usuario: `rokudev`, contraseña: la que definiste.

### 3. Instalar GioRoku.zip

```
┌─────────────────────────────────────────────────────────┐
│  Roku Developer Application Installer                    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Upload a Channel                                │    │
│  │                                                  │    │
│  │  [Seleccionar archivo]  GioRoku.zip              │    │
│  │                                                  │    │
│  │               [Install]                          │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

1. En "Upload a Channel", selecciona el archivo `GioRoku.zip`
2. Haz clic en **"Install"**
3. El Roku instalará la app y la lanzará automáticamente

> ⚠️ El ZIP debe tener `manifest` en la raíz (no dentro de una carpeta).
> El archivo `GioRoku.zip` que descargaste ya está correctamente empaquetado.

---

## Uso de la app en el Roku

### Pantalla de inicio (Splash)

Al abrir GioRoku verás:

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│                    GioRoku                               │
│              Tu televisión latina, en Roku               │
│                                                          │
│         ████████████░░░░░░░░░░░░░░░░░  70%             │
│                 Cargando canales…                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

La app carga la API de GitHub Pages. Si no hay conexión:

```
┌─────────────────────────────────────────────────────────┐
│     Sin conexión. Verifica tu red o recarga el canal.    │
│                                                          │
│        Presiona OK para reintentar  |  Back para salir   │
└─────────────────────────────────────────────────────────┘
```

Presiona **OK** para reintentar.

### Pantalla principal (Home)

```
┌─────────────────────────────────────────────────────────┐
│  Inicio │ Live TV │ Guía │ Favoritos │ Buscar │ Ajustes │
│─────────────────────────────────────────────────────────│
│                                                          │
│  ► Continuar viendo                                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│  │ AZ7  │ │ C5   │ │ TVN  │ │ ...  │ │ ...  │         │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘         │
│                                                          │
│  ► Favoritos                                             │
│  ┌──────┐ ┌──────┐ ...                                  │
│                                                          │
│  ► Destacados                                            │
│  ► Todos los canales                                     │
└─────────────────────────────────────────────────────────┘
```

**Navegación:**
- `↑ / ↓` — Mover entre filas
- `← / →` — Mover entre canales en una fila
- `OK / Select` — Reproducir canal
- `↑` desde contenido — Ir a la barra de navegación
- `↓` desde navbar — Volver al contenido

### Reproducción (Player)

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│              [VIDEO EN VIVO]                             │
│                                                          │
│  ┌──── Info overlay (auto-oculta en 5s) ───────────┐   │
│  │  🔴 Azteca 7    México · Entretenimiento         │   │
│  │  📺 Noticiero en vivo                            │   │
│  │  ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░  ────────────────────────  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Controles durante reproducción:**
| Tecla | Acción |
|---|---|
| `OK` | Mostrar/ocultar controles |
| `↑` | Canal anterior |
| `↓` | Canal siguiente |
| `*` (Options) | Menú: Favoritos / Info |
| `Replay` | Reiniciar stream |
| `Back` | Volver al Home |

### Live TV

Lista completa de canales con filtros por país y categoría.
Presiona `*` sobre un canal para agregarlo a favoritos.

### Guía de Programación

Muestra la programación del día (si el EPG está configurado).
Sin EPG configurado: muestra "En vivo" para todos los canales.

### Búsqueda

Escribe con el teclado virtual. Busca en nombre, país y categoría.
Presiona `↓` para mover el foco a los resultados.

### Ajustes

- **Fuente API**: URL de GitHub Pages (configurable)
- **Force refresh now**: Fuerza recarga de la API
- **Versión de caché**: Timestamp de los datos actuales

---

## Portal de administración

El portal admin es una SPA de React desplegada en GitHub Pages.

**URL:** `https://TU_USUARIO.github.io/GioRoku/admin/`

(Disponible después de que el workflow `deploy-admin.yml` corra al hacer merge a `main`)

### Dashboard

Muestra:
- Canales totales / en línea / fuera de línea
- Distribución por país y categoría (gráficas)
- Estado del pipeline

### Gestión de canales

- Filtrar y buscar canales
- Ver/editar metadatos
- Activar/desactivar canales

> El portal necesita un PAT configurado en el navegador para poder escribir cambios.
> Configurar en: Settings → GitHub Token dentro del portal.

---

## Actualizar canales

Para actualizar la lista de canales:

### Método 1 — M3U Loader (recomendado)

1. Abre `m3u-loader.html` en tu navegador
2. Carga tu nueva lista M3U (URL o archivo)
3. Filtra si es necesario
4. Haz clic en "Publicar"
5. En el Roku: **Settings → Force refresh now**

Los cambios se reflejan en ~2 minutos (GitHub Pages cache).

### Método 2 — Pipeline Python (avanzado)

```bash
# Instalar dependencias
cd backend && pip install -r requirements.txt

# Configurar fuentes en backend/config/sources.json
# (agregar tu URL de M3U)

# Ejecutar pipeline completo
python run_pipeline.py --stage all

# O etapas individuales
python run_pipeline.py --stage fetch
python run_pipeline.py --stage validate
python run_pipeline.py --stage generate
```

### Método 3 — GitHub Actions (automático)

El workflow `daily-refresh.yml` corre automáticamente todos los días.
También se puede lanzar manualmente: Actions → Daily Channel Refresh → Run workflow.

---

## Solución de problemas

### "Sin conexión" en el Roku

1. Verifica que el Roku tiene internet
2. Abre en un navegador: `https://TU_USUARIO.github.io/GioRoku/api/v1/status.json`
   - Si no carga: GitHub Pages no está habilitado o los archivos no están en `main`
   - Si carga: el Roku debería conectar. Prueba Settings → Force refresh

### No aparecen canales después de publicar

- GitHub Pages puede tardar 2-5 minutos en propagar
- Verifica en tu navegador que `status.json` tiene `totalChannels > 0`
- En el Roku: Settings → Force refresh now

### Error al publicar en M3U Loader

| Error | Causa | Solución |
|---|---|---|
| `401` | Token inválido | Regenera el PAT en GitHub |
| `404` | Repo no encontrado | Verifica owner/repo en la config |
| `422` | Conflicto de SHA | El archivo fue modificado externamente. Recarga la página y vuelve a intentar |
| CORS | URL M3U bloqueada | Descarga el .m3u y usa la pestaña "Archivo" |

### La app en Roku no se instala

- Verifica que el Developer Mode esté activo
- El ZIP debe pesar menos de 4MB
- `manifest` debe estar en la raíz del ZIP (no en subcarpeta)
- Verifica la IP del Roku con: Ajustes → Red → Acerca de

### Pantalla negra al reproducir

- El stream puede estar caído. Espera 10s o presiona `Replay`
- Algunos streams requieren VPN o están geo-bloqueados
- El formato debe ser HLS (`.m3u8`) o MP4; RTMP no funciona en Roku

---

## Archivos de referencia

```
GioRoku/
├── tools/
│   └── m3u-loader.html     ← Herramienta de importación M3U
├── roku/                   ← Código fuente de la app Roku
│   ├── manifest            ← Metadata de la app
│   └── source/             ← BrightScript + XML
├── admin/                  ← Portal de administración (React)
├── backend/                ← Pipeline Python
│   ├── run_pipeline.py     ← CLI principal
│   └── config/sources.json ← Fuentes M3U
├── api/v1/                 ← Archivos JSON de la API
│   ├── status.json
│   ├── categories.json
│   ├── countries.json
│   └── channels/
│       └── page/1.json
└── docs/
    └── MANUAL.md           ← Este archivo
```

---

*GioRoku — Código abierto para uso personal. No distribuir contenido protegido por derechos de autor.*
