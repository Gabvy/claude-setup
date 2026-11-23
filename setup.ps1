# Setup de plugins y skills de Claude Code (Windows / PowerShell).
# Uso: .\setup.ps1   (si da error de ejecución: powershell -ExecutionPolicy Bypass -File .\setup.ps1)

$ErrorActionPreference = 'Continue'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# --- Requisitos ---
Write-Step 'Revisando requisitos'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Error 'Falta Node.js (24.15+).'; exit 1 }
$nodeVersion = [version]((node --version).TrimStart('v'))
if ($nodeVersion -lt [version]'24.15.0') { Write-Warning "Node ${nodeVersion}: context-mode pide 24.15.0 o mayor." }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error 'Falta Git (Git for Windows).'; exit 1 }

$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) {
    # La app de escritorio trae su propio claude.exe
    $claude = Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Filter claude.exe -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $claude) { Write-Error 'No encuentro el CLI de Claude. Instalar con: npm install -g @anthropic-ai/claude-code'; exit 1 }
Write-Host "Usando claude: $claude"

# --- Plugins ---
Write-Step 'Plugins de Claude Code'
& $claude plugin marketplace add anthropics/claude-plugins-official
& $claude plugin install superpowers@claude-plugins-official
& $claude plugin marketplace add mksglu/context-mode
& $claude plugin install context-mode@context-mode

# --- Skills ---
Write-Step 'Skills: mattpocock/skills (todas)'
npx -y skills add mattpocock/skills -y -g

Write-Step 'Skills: vercel-labs/agent-skills'
npx -y skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines -y -g
npx -y skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices -y -g

Write-Step 'Skills: anthropics/skills'
npx -y skills add https://github.com/anthropics/skills --skill webapp-testing -y -g

Write-Step 'Firecrawl (abre el navegador para login)'
npx -y firecrawl-cli@latest init --all --browser

Write-Step 'Listo'
& $claude plugin list
Write-Host "Skills instaladas: $((Get-ChildItem "$HOME\.agents\skills").Count) en $HOME\.agents\skills"
Write-Host 'Abrir una sesión nueva de Claude para que carguen los plugins.'
