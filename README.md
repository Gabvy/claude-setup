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

## 5. Problemas conocidos

- **`--skill` lleva dos guiones.** Con `-skill x` o `skill=x` el filtro se ignora y se instalan **todas** las skills del repo.
- **`npx firecrawl-cli setup ...` falla en Windows** con `'"C:\Program' is not recognized`: el CLI no cita la ruta de `npx`. Solución: correr directamente el comando que imprime, por ejemplo:
  `npx -y skills@1.7.2 add firecrawl/skills --full-depth --global --yes --agent codex claude-code cursor github-copilot --skill firecrawl-developer-index`
  (`firecrawl-cli init --all` sí funciona).
- **`claude` no reconocido** en la terminal cuando solo está la app de escritorio: instalar el CLI con npm (ver arriba), o usar el `claude.exe` que trae la app en `%LOCALAPPDATA%\Claude-Data\...\claude-code\<versión>\...\claude.exe`.
- **Nombre repetido `code-review`**: la skill de mattpocock se llama igual que el comando integrado `/code-review`. Si se confunden, llamar a la skill por su nombre completo.
- **Seguridad**: las skills corren con todos los permisos del agente. El instalador muestra una evaluación (Gen / Socket / Snyk); `firecrawl-developer-index` salió *Med Risk* en Snyk.

## 6. Agregar algo nuevo

1. Instalarlo a mano y comprobar que funciona.
2. Agregar la línea a `setup.ps1` y `setup.sh`.
3. Agregar la fila a la tabla correspondiente de este README.
