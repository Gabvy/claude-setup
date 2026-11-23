#!/usr/bin/env bash
# Valida que todo lo del setup esté instalado (macOS / Linux).
# Uso: ./verify.sh     Sale con código 1 si falta algo obligatorio.

fail=0
warn=0

result() { # status name detail
  printf '%-6s %-30s %s\n' "$1" "$2" "$3"
  [ "$1" = FALTA ] && fail=$((fail + 1))
  [ "$1" = AVISO ] && warn=$((warn + 1))
  return 0
}

check() { # name optional(0/1) cmd args...
  local name="$1" optional="$2"; shift 2
  local missing=FALTA; [ "$optional" = 1 ] && missing=AVISO
  if ! command -v "$1" >/dev/null 2>&1; then result "$missing" "$name" 'no está en el PATH'; return; fi
  local out
  if out="$("$@" 2>&1)"; then result OK "$name" "$(printf '%s\n' "$out" | grep -m1 .)"
  else result "$missing" "$name" "no funciona: $(printf '%s\n' "$out" | grep -m1 .)"; fi
}

echo; echo '--- Requisitos'
if command -v node >/dev/null 2>&1; then
  v="$(node --version | sed 's/^v//')"
  if [ "$(printf '%s\n24.15.0\n' "$v" | sort -V | head -n1)" = "24.15.0" ]; then result OK node "v$v"
  else result AVISO node "v$v (context-mode pide 24.15.0+)"; fi
else result FALTA node 'no está en el PATH'; fi
check git 0 git --version
check gh 1 gh --version
check claude 0 claude --version
check 'python (webapp-testing)' 1 python3 --version
check 'playwright (webapp-testing)' 1 python3 -m playwright --version
case "$(uname -s)" in
  Darwin) pw_cache="$HOME/Library/Caches/ms-playwright" ;;
  *)      pw_cache="$HOME/.cache/ms-playwright" ;;
esac
chromium="$(ls -d "$pw_cache"/chromium-* 2>/dev/null | head -n1)"
if [ -n "$chromium" ]; then result OK 'chromium (playwright)' "$(basename "$chromium")"
else result AVISO 'chromium (playwright)' 'falta: python3 -m playwright install chromium'; fi

echo; echo '--- Herramientas del sistema'
check ffmpeg 0 ffmpeg -version
check gstreamer 0 gst-launch-1.0 --version
check nginx 0 nginx -v
check aws 0 aws --version
check gcloud 0 gcloud --version

echo; echo '--- Plugins de Claude Code'
if command -v claude >/dev/null 2>&1; then
  plugins="$(claude plugin list 2>&1)"
  for p in superpowers@claude-plugins-official context-mode@context-mode; do
    if printf '%s' "$plugins" | grep -qF "$p"; then result OK "$p" instalado; else result FALTA "$p" 'no instalado'; fi
  done
fi

echo; echo '--- Skills (~/.agents/skills)'
dir="$HOME/.agents/skills"
for s in handoff:mattpocock/skills tdd:mattpocock/skills \
         web-design-guidelines:vercel-labs/agent-skills vercel-react-best-practices:vercel-labs/agent-skills \
         webapp-testing:anthropics/skills firecrawl:'firecrawl init' firecrawl-developer-index:'firecrawl init'; do
  name="${s%%:*}"; from="${s#*:}"
  if [ -d "$dir/$name" ]; then result OK "$name" "$from"; else result FALTA "$name" "falta ($from)"; fi
done
echo "Total de skills: $(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')"

echo
if [ "$fail" -gt 0 ]; then
  echo "Faltan $fail cosas (y $warn avisos). Correr ./setup.sh de nuevo."
  exit 1
fi
echo "Todo instalado ($warn avisos)."
echo 'Pendiente manual si no se hizo: aws configure / gcloud init'
