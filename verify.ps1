# Valida que todo lo del setup esté instalado (Windows / PowerShell).
# Uso: .\verify.ps1     Sale con código 1 si falta algo obligatorio.

$ErrorActionPreference = 'Continue'

# Toma el PATH actual del sistema (por si se instaló algo en esta misma terminal)
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

$script:fail = 0
$script:warn = 0

function Show-Result($status, $name, $detail) {
    $color = @{ OK = 'Green'; FALTA = 'Red'; AVISO = 'Yellow' }[$status]
    Write-Host ('{0,-6} {1,-30} {2}' -f $status, $name, $detail) -ForegroundColor $color
    if ($status -eq 'FALTA') { $script:fail++ }
    if ($status -eq 'AVISO') { $script:warn++ }
}

function Get-FirstLine($exe, $argList) {
    # Leer toda la salida antes de tomar la primera línea: cortar el pipe
    # (Select-Object -First) detiene el proceso y deja un $LASTEXITCODE falso.
    $out = @(& $exe @argList 2>&1)
    $script:lastCode = $LASTEXITCODE
    $first = $out | ForEach-Object { "$_" } | Where-Object { $_.Trim() } | Select-Object -First 1
    return "$first".Trim()
}

function Test-Tool($name, $exe, $argList, [switch]$Optional) {
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Show-Result $(if ($Optional) { 'AVISO' } else { 'FALTA' }) $name 'no está en el PATH'
        return
    }
    $line = Get-FirstLine $cmd.Source $argList
    if ($script:lastCode -ne 0) {
        # p. ej. el alias de Microsoft Store para python, que no es python de verdad
        Show-Result $(if ($Optional) { 'AVISO' } else { 'FALTA' }) $name "no funciona: $line"
        return
    }
    Show-Result 'OK' $name $line
}

Write-Host "`n--- Requisitos" -ForegroundColor Cyan
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Show-Result 'FALTA' 'node' 'no está en el PATH' } else {
    $v = [version]((node --version).TrimStart('v'))
    if ($v -ge [version]'24.15.0') { Show-Result 'OK' 'node' "v$v" }
    else { Show-Result 'AVISO' 'node' "v$v (context-mode pide 24.15.0+)" }
}
Test-Tool 'git'    git    @('--version')
Test-Tool 'gh'     gh     @('--version') -Optional
Test-Tool 'python (webapp-testing)'     python @('--version') -Optional
Test-Tool 'playwright (webapp-testing)' python @('-m', 'playwright', '--version') -Optional

$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) {
    $claude = Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Filter claude.exe -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if ($claude) { Show-Result 'OK' 'claude' "$(Get-FirstLine $claude @('--version')) ($claude)" }
else { Show-Result 'FALTA' 'claude' 'no encontrado' }

Write-Host "`n--- Herramientas del sistema" -ForegroundColor Cyan
Test-Tool 'ffmpeg'         ffmpeg         @('-version')
Test-Tool 'gstreamer'      gst-launch-1.0 @('--version')
Test-Tool 'nginx'          nginx          @('-v')
Test-Tool 'aws'            aws            @('--version')
Test-Tool 'gcloud'         gcloud         @('--version')

Write-Host "`n--- Plugins de Claude Code" -ForegroundColor Cyan
if ($claude) {
    $plugins = (& $claude plugin list 2>&1 | Out-String)
    foreach ($p in 'superpowers@claude-plugins-official', 'context-mode@context-mode') {
        if ($plugins -match [regex]::Escape($p)) { Show-Result 'OK' $p 'instalado' }
        else { Show-Result 'FALTA' $p 'no instalado' }
    }
}

Write-Host "`n--- Skills (~\.agents\skills)" -ForegroundColor Cyan
$skillsDir = Join-Path $HOME '.agents\skills'
$skills = @(Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$expected = @(
    @{ Name = 'handoff';                      From = 'mattpocock/skills' },
    @{ Name = 'tdd';                          From = 'mattpocock/skills' },
    @{ Name = 'web-design-guidelines';        From = 'vercel-labs/agent-skills' },
    @{ Name = 'vercel-react-best-practices';  From = 'vercel-labs/agent-skills' },
    @{ Name = 'webapp-testing';               From = 'anthropics/skills' },
    @{ Name = 'firecrawl';                    From = 'firecrawl init' },
    @{ Name = 'firecrawl-developer-index';    From = 'firecrawl init' }
)
foreach ($s in $expected) {
    if ($skills -contains $s.Name) { Show-Result 'OK' $s.Name $s.From }
    else { Show-Result 'FALTA' $s.Name "falta ($($s.From))" }
}
Write-Host "Total de skills: $($skills.Count)"

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "Faltan $($script:fail) cosas (y $($script:warn) avisos). Correr .\setup.ps1 de nuevo." -ForegroundColor Red
    exit 1
}
Write-Host "Todo instalado ($($script:warn) avisos)." -ForegroundColor Green
Write-Host 'Pendiente manual si no se hizo: aws configure / gcloud init'
exit 0
