#!/usr/bin/env bash
# Setup de plugins y skills de Claude Code (macOS / Linux).
# Uso: ./setup.sh

set -u

step() { printf '\n==> %s\n' "$1"; }

# --- Requisitos ---
step 'Revisando requisitos'
command -v node >/dev/null || { echo 'Falta Node.js (24.15+).'; exit 1; }
command -v git  >/dev/null || { echo 'Falta Git.'; exit 1; }
command -v claude >/dev/null || { echo 'Falta el CLI de Claude: npm install -g @anthropic-ai/claude-code'; exit 1; }

node_version="$(node --version | sed 's/^v//')"
if [ "$(printf '%s\n24.15.0\n' "$node_version" | sort -V | head -n1)" != "24.15.0" ]; then
  echo "Aviso: Node $node_version. context-mode pide 24.15.0 o mayor."
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

step 'Listo'
claude plugin list
echo "Skills instaladas: $(ls "$HOME/.agents/skills" | wc -l) en $HOME/.agents/skills"
echo 'Abrir una sesión nueva de Claude para que carguen los plugins.'
