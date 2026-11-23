#!/usr/bin/env bash
# Setup de plugins y skills de Claude Code (macOS / Linux).
# Uso: ./setup.sh [--skip-tools]

set -u

skip_tools=0
[ "${1:-}" = "--skip-tools" ] && skip_tools=1

step() { printf '\n==> %s\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }

install_tools_macos() {
  has brew || { echo 'Falta Homebrew: https://brew.sh'; return 1; }
  for f in ffmpeg gstreamer nginx awscli; do
    brew list "$f" >/dev/null 2>&1 && echo "$f: ya instalado" || brew install "$f"
  done
  has gcloud && echo 'gcloud: ya instalado' || brew install --cask gcloud-cli
  has python3 && echo "python3: ya instalado ($(python3 --version))" || brew install python@3.14
}

# Playwright para la skill webapp-testing. Con Python de brew o de Debian 12+,
# pip rechaza instalar fuera de un venv (PEP 668); con --user solo toca el usuario.
install_playwright() {
  python3 -m pip install --upgrade --user playwright 2>/dev/null \
    || python3 -m pip install --upgrade --user --break-system-packages playwright
  if [ "$(uname -s)" = Linux ]; then python3 -m playwright install --with-deps chromium
  else python3 -m playwright install chromium; fi
}

install_tools_linux() {
  has apt-get || { echo 'Sin apt-get: instalar ffmpeg, gstreamer, nginx, aws y gcloud con el gestor de la distro.'; return 1; }
  sudo apt-get update
  sudo apt-get install -y ffmpeg nginx unzip curl \
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    python3 python3-pip

  if has aws; then echo 'aws: ya instalado'; else
    arch="$(uname -m)"   # x86_64 o aarch64
    tmp="$(mktemp -d)"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "$tmp/awscliv2.zip" \
      && unzip -q "$tmp/awscliv2.zip" -d "$tmp" && sudo "$tmp/aws/install"
    rm -rf "$tmp"
  fi

  if has gcloud; then echo 'gcloud: ya instalado'
  elif has snap; then sudo snap install google-cloud-cli --classic
  else echo 'gcloud: instalar a mano -> https://cloud.google.com/sdk/docs/install'; fi
}

# --- Requisitos ---
step 'Revisando requisitos'
command -v node >/dev/null || { echo 'Falta Node.js (24.15+).'; exit 1; }
command -v git  >/dev/null || { echo 'Falta Git.'; exit 1; }
command -v claude >/dev/null || { echo 'Falta el CLI de Claude: npm install -g @anthropic-ai/claude-code'; exit 1; }

node_version="$(node --version | sed 's/^v//')"
if [ "$(printf '%s\n24.15.0\n' "$node_version" | sort -V | head -n1)" != "24.15.0" ]; then
  echo "Aviso: Node $node_version. context-mode pide 24.15.0 o mayor."
fi

# --- Herramientas del sistema ---
if [ "$skip_tools" -eq 0 ]; then
  step 'Herramientas del sistema'
  case "$(uname -s)" in
    Darwin) install_tools_macos ;;
    Linux)  install_tools_linux ;;
    *)      echo 'Sistema no reconocido: saltando herramientas.' ;;
  esac
  step 'Playwright (webapp-testing)'
  if has python3; then install_playwright; else echo 'Sin python3: saltando Playwright.'; fi
  echo 'Login después: aws configure / gcloud init'
fi

# --- Plugins ---
step 'Plugins de Claude Code'
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official
claude plugin marketplace add mksglu/context-mode
claude plugin install context-mode@context-mode

# --- Skills ---
step 'Skills: mattpocock/skills (todas)'
npx -y skills add mattpocock/skills -y -g

step 'Skills: vercel-labs/agent-skills'
npx -y skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines -y -g
npx -y skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices -y -g

step 'Skills: anthropics/skills'
npx -y skills add https://github.com/anthropics/skills --skill webapp-testing -y -g

step 'Firecrawl (abre el navegador para login)'
npx -y firecrawl-cli@latest init --all --browser

step 'Validando instalación'
bash "$(dirname "$0")/verify.sh"
echo 'Abrir una sesión nueva de Claude para que carguen los plugins.'
