# Claude setup

Guía corta para dejar Claude Code (CLI o app de escritorio) con los mismos plugins y skills en cualquier máquina.

Todo se instala **a nivel de usuario** (global), así que sirve para cualquier proyecto.

## Inicio rápido

Windows (PowerShell):

```powershell
git clone https://github.com/Gabvy/claude-setup.git
cd claude-setup
.\setup.ps1
```

macOS / Linux:

```sh
git clone https://github.com/Gabvy/claude-setup.git
cd claude-setup
./setup.sh
```

El script es idempotente: se puede correr de nuevo para actualizar. Lo interactivo es el login de Firecrawl (abre el navegador) y, en macOS/Linux, `sudo` para las herramientas del sistema.

Para saltar las herramientas del sistema y solo instalar plugins y skills: `.\setup.ps1 -SkipTools` o `./setup.sh --skip-tools`.

Al final, el setup corre la validación ([sección 5](#5-validar-la-instalación)). También se puede correr sola en cualquier momento: `.\verify.ps1` o `./verify.sh`.

| Archivo | Qué hace |
|---|---|
| `setup.ps1` / `setup.sh` | Instala todo (Windows / macOS-Linux) y termina validando |
| `verify.ps1` / `verify.sh` | Solo revisa lo instalado; sale con código 1 si falta algo obligatorio |

## 1. Requisitos

| Herramienta | Versión | Para qué |
|---|---|---|
| Node.js | **24.15.0 o mayor** | `npx skills`, Firecrawl y el plugin context-mode (que pide 24.15+) |
| Git | cualquiera (en Windows: Git for Windows) | clonar marketplaces; context-mode usa Git Bash en Windows |
| Claude Code CLI (`claude`) | última | instalar plugins |
| GitHub CLI (`gh`) | opcional | clonar este repo privado |
| Python + Playwright | opcional | lo usa la skill `webapp-testing` |

Si `claude` no está en el PATH (pasa con la app de escritorio), instalar el CLI:

```powershell
npm install -g @anthropic-ai/claude-code
```

## 2. Herramientas del sistema

| Herramienta | Windows (winget) | macOS (brew) | Linux (Debian/Ubuntu) | Para qué |
|---|---|---|---|---|
| FFmpeg | `Gyan.FFmpeg` | `ffmpeg` | `apt install ffmpeg` | audio y video |
| GStreamer | `gstreamerproject.gstreamer` | `gstreamer` | `apt install gstreamer1.0-tools gstreamer1.0-plugins-{base,good,bad,ugly} gstreamer1.0-libav` | pipelines de media (`gst-launch-1.0`) |
| nginx | `nginxinc.nginx` | `nginx` | `apt install nginx` | servidor web / proxy inverso |
| AWS CLI v2 | `Amazon.AWSCLI` | `awscli` | instalador oficial (zip) | `aws` |
| Google Cloud CLI | `Google.CloudSDK` | cask `gcloud-cli` | `snap install google-cloud-cli --classic` | `gcloud` |

Windows, a mano (una por una):

```powershell
winget install -e --id Gyan.FFmpeg
winget install -e --id gstreamerproject.gstreamer
winget install -e --id nginxinc.nginx
winget install -e --id Amazon.AWSCLI
winget install -e --id Google.CloudSDK
```

Después de instalar, **abrir una terminal nueva** para que tome el PATH, y hacer login:

```sh
aws configure          # o: aws configure sso
gcloud init            # login + proyecto por defecto
```

Notas:
- **gcloud en Windows tarda**: el instalador de `Google.CloudSDK` descarga sus componentes y puede pasar de 10 minutos sin mostrar avance. Dejarlo terminar.
- **"restart your shell"**: winget cambia el PATH del sistema, pero las terminales ya abiertas no lo ven. El script refresca el PATH de su propia sesión; en las demás hay que abrir una terminal nueva.
- **GStreamer en Windows** a veces no agrega su carpeta al PATH. El script agrega `C:\Program Files\gstreamer\1.0\msvc_x86_64\bin` al PATH del usuario si existe y falta.
- **nginx en Windows** se instala como binario, no como servicio: se arranca con `nginx` desde su carpeta y se detiene con `nginx -s stop`.
- **Linux**: AWS CLI usa el instalador oficial (`curl` + `unzip` + `sudo ./aws/install`); gcloud usa snap. Si no hay snap, seguir https://cloud.google.com/sdk/docs/install.

## 3. Plugins de Claude Code

| Plugin | Marketplace | Qué hace |
|---|---|---|
| `superpowers` | `claude-plugins-official` | Skills de proceso: brainstorming, planes, TDD, debugging, code review |
| `context-mode` | `mksglu/context-mode` | Mantiene la salida grande de las herramientas fuera del contexto (índice local en SQLite) |

```sh
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official

claude plugin marketplace add mksglu/context-mode
claude plugin install context-mode@context-mode
```

Verificar con `claude plugin list`. Los plugins se activan en la siguiente sesión.

## 4. Skills (`npx skills`)

Se instalan en `~/.agents/skills` y se enlazan a Claude Code, Codex, Cursor, Copilot y otros agentes.

| Origen | Skills | Comando |
|---|---|---|
| `mattpocock/skills` | Todas (≈39): handoff, tdd, grilling, prototype, research, pr, code-review… | `npx -y skills add mattpocock/skills -y -g` |
| `vercel-labs/agent-skills` | `web-design-guidelines` | `npx -y skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines -y -g` |
| `vercel-labs/agent-skills` | `vercel-react-best-practices` | `npx -y skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices -y -g` |
| `anthropics/skills` | `webapp-testing` | `npx -y skills add https://github.com/anthropics/skills --skill webapp-testing -y -g` |
| Firecrawl | Todas (≈32), incluida `firecrawl-developer-index` | `npx -y firecrawl-cli@latest init --all --browser` |

Firecrawl `init` pide login en el navegador (cuenta Firecrawl, team *Personal*). Pasos opcionales después: `firecrawl setup mcp` y `firecrawl make default`.

## 5. Validar la instalación

```powershell
.\verify.ps1      # Windows
```

```sh
./verify.sh       # macOS / Linux
```

Revisa cada cosa y marca `OK`, `AVISO` (opcional o versión baja) o `FALTA`:

- **Requisitos**: Node ≥ 24.15, Git, `gh`, `claude`, Python y Playwright (estos dos son opcionales, para `webapp-testing`).
- **Herramientas**: `ffmpeg`, `gst-launch-1.0`, `nginx`, `aws`, `gcloud`. Cada una debe responder a su comando de versión, no solo existir en el PATH: en Windows, `python` puede ser el acceso directo de Microsoft Store y no un Python real.
- **Plugins**: `superpowers` y `context-mode` en `claude plugin list`.
- **Skills**: `handoff`, `tdd`, `web-design-guidelines`, `vercel-react-best-practices`, `webapp-testing`, `firecrawl`, `firecrawl-developer-index` en `~/.agents/skills`, más el total.

No revisa los logins: `aws configure`, `gcloud init` y Firecrawl se hacen a mano.

### Última validación (Windows 11, 2026-11-23)

| Qué | Resultado |
|---|---|
| Node | 24.14.0: **AVISO** (falta subir a 24.15+ para context-mode) |
| Git / gh | 2.53.0 / 2.105.0 |
| Claude Code | 2.1.330 (el de la app de escritorio; `claude` no está en el PATH) |
| Python / Playwright | **AVISO**: no instalados (solo está el acceso directo de Microsoft Store) |
| FFmpeg | 8.0.1 (full build, gyan.dev) |
| GStreamer | 1.28.0 |
| nginx | 1.31.10 |
| AWS CLI | 2.42.1 (sin `aws configure` todavía) |
| Google Cloud SDK | 594.0.1 (sin `gcloud init` todavía) |
| Plugins | `superpowers` 7.0.2, `context-mode` 2.2.2 |
| Skills | 74 en `~/.agents/skills`, las 7 de control OK |

## 6. Problemas conocidos

- **`--skill` lleva dos guiones.** Con `-skill x` o `skill=x` el filtro se ignora y se instalan **todas** las skills del repo.
- **`npx firecrawl-cli setup ...` falla en Windows** con `'"C:\Program' is not recognized`: el CLI no cita la ruta de `npx`. Solución: correr directamente el comando que imprime, por ejemplo:
  `npx -y skills@1.7.2 add firecrawl/skills --full-depth --global --yes --agent codex claude-code cursor github-copilot --skill firecrawl-developer-index`
  (`firecrawl-cli init --all` sí funciona).
- **`claude` no reconocido** en la terminal cuando solo está la app de escritorio: instalar el CLI con npm (ver arriba), o usar el `claude.exe` que trae la app en `%LOCALAPPDATA%\Claude-Data\...\claude-code\<versión>\...\claude.exe`.
- **Nombre repetido `code-review`**: la skill de mattpocock se llama igual que el comando integrado `/code-review`. Si se confunden, llamar a la skill por su nombre completo.
- **Seguridad**: las skills corren con todos los permisos del agente. El instalador muestra una evaluación (Gen / Socket / Snyk); `firecrawl-developer-index` salió *Med Risk* en Snyk.

## 7. Agregar algo nuevo

1. Instalarlo a mano y comprobar que funciona.
2. Agregar la instalación a `setup.ps1` y `setup.sh`.
3. Agregar el chequeo a `verify.ps1` y `verify.sh`.
4. Agregar la fila a la tabla correspondiente de este README.
5. Correr `verify` y actualizar la tabla de "Última validación".
