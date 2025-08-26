#!/usr/bin/env bash
set -euo pipefail

# install-configs.sh
# Modos: --symlink (padrão), --copy, --move
# Flags: --replace (sem backup), --noconfirm, --dry-run, --repo DIR
#
# Uso exemplo:
#   ./install-configs.sh --move --noconfirm
#   ./install-configs.sh --copy
#   ./install-configs.sh --dry-run --replace

MODE="symlink"
REPLACE=0
NOCONFIRM=0
DRY_RUN=0
REPO_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --move) MODE="move"; shift ;;
    --copy) MODE="copy"; shift ;;
    --symlink) MODE="symlink"; shift ;;
    --replace) REPLACE=1; shift ;;
    --noconfirm) NOCONFIRM=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --repo) REPO_DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Uso: $0 [--move|--copy|--symlink] [--replace] [--noconfirm] [--dry-run] [--repo DIR]

--move      move arquivos do repositório para \$XDG_CONFIG_HOME (remove origens)
--copy      copia e substitui arquivos em \$XDG_CONFIG_HOME
--symlink   cria symlinks (padrão)
--replace   não cria backup ao sobrescrever (perigoso)
--noconfirm sobrescreve sem perguntar
--dry-run   mostra ações sem executá-las
--repo DIR  considerar DIR como repositório (default: script dir)
EOF
      exit 0 ;;
    *) printf 'Argumento desconhecido: %s\n' "$1" >&2; exit 1 ;;
  esac
done

log(){ printf '\033[36m:: %s\033[0m\n' "$1"; }
warn(){ printf '\033[33m!! %s\033[0m\n' "$1"; }
run(){
  printf '\033[33m+ %s\033[0m\n' "$(printf '%s ' "$@")"
  [ "$DRY_RUN" -eq 0 ] && "$@"
}
ask_yes_no(){
  local prompt="$1"
  if [ "$NOCONFIRM" -eq 1 ]; then
    return 0
  fi
  read -r -p "$prompt [Y/n] " ans
  case "$ans" in
    n|N) return 1 ;;
    *) return 0 ;;
  esac
}

# repo dir
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  REPO_DIR="$(cd "$REPO_DIR" && pwd)"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
TIMESTAMP="$(date +%s)"

log "Repo: $REPO_DIR"
log "Alvo de configuração: $CONFIG_DIR"
log "Modo: $MODE"
[ "$REPLACE" -eq 1 ] && log "Modo: substituir sem backups (REPLACE)"
[ "$DRY_RUN" -eq 1 ] && warn "DRY-RUN ativo. Nenhuma modificação será feita."

# exclusões top-level
EXCLUDE=(.git .github .gitignore README.md LICENSE install-configs.sh install.sh)

# pega top-level dirs e arquivos do repo (ignora itens de exclusão)
items=()
for p in "$REPO_DIR"/*; do
  name="$(basename "$p")"
  if [[ " ${EXCLUDE[*]} " =~ " ${name} " ]]; then
    continue
  fi
  # só top-level (arquivos e pastas)
  items+=("$name")
done

perform_replace() {
  local dest="$1"
  if [ "$REPLACE" -eq 1 ]; then
    run rm -rf "$dest"
    return 0
  fi

  # tenta mover existente para backup
  local bak="${dest}.bak.${TIMESTAMP}"
  run mv "$dest" "$bak"
  log "Backup criado: $bak"
}

install_item() {
  local name="$1"
  local src="$REPO_DIR/$name"
  local dest="$CONFIG_DIR/$name"

  # Se destino existe
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$MODE" = "symlink" ]; then
      if [ "$REPLACE" -eq 1 ]; then
        run rm -rf "$dest"
      else
        if ask_yes_no "Destino '$dest' existe. Sobrescrever?"; then
          perform_replace "$dest"
        else
          log "Pulando $name"
          return
        fi
      fi
    else
      if [ "$REPLACE" -eq 1 ]; then
        run rm -rf "$dest"
      else
        if ask_yes_no "Destino '$dest' existe. Sobrescrever (backup) ?"; then
          perform_replace "$dest"
        else
          log "Pulando $name"
          return
        fi
      fi
    fi
  fi

  # assegura diretório pai
  run mkdir -p "$(dirname "$dest")"

  case "$MODE" in
    symlink)
      log "Criando symlink: $src -> $dest"
      run ln -s "$(realpath "$src")" "$dest"
      ;;
    copy)
      log "Copiando (preservando) $src -> $dest"
      # copy: se for dir, cp -a; se for arquivo, cp -a
      if [ -d "$src" ]; then
        run cp -a "$src" "$dest"
      else
        run cp -a "$src" "$dest"
      fi
      ;;
    move)
      log "Movendo $src -> $dest (origem será removida do repositório)"
      run mv "$src" "$dest"
      ;;
    *)
      warn "Modo desconhecido: $MODE"
      ;;
  esac
}

# iterar itens
for name in "${items[@]}"; do
  install_item "$name"
done

# tratar tema específico quickshell/dms/docs/theme_monocrom.json
repo_theme="$REPO_DIR/quickshell/dms/docs/theme_monocrom.json"
target_theme="$CONFIG_DIR/quickshell/dms/docs/theme_monocrom.json"

if [ -f "$repo_theme" ]; then
  # criar dir alvo
  run mkdir -p "$(dirname "$target_theme")"

  if [ -e "$target_theme" ] || [ -L "$target_theme" ]; then
    if [ "$REPLACE" -eq 1 ]; then
      run rm -f "$target_theme"
    else
      if ask_yes_no "Arquivo '$target_theme' existe. Substituir (backup)?"; then
        perform_replace "$target_theme"
      else
        log "Pulando theme_monocrom.json"
        exit 0
      fi
    fi
  fi

  case "$MODE" in
    symlink)
      log "Ligando theme_monocrom.json"
      run ln -s "$(realpath "$repo_theme")" "$target_theme"
      ;;
    copy)
      log "Copiando theme_monocrom.json"
      run cp -a "$repo_theme" "$target_theme"
      ;;
    move)
      log "Movendo theme_monocrom.json (removerá do repositório)"
      run mv "$repo_theme" "$target_theme"
      ;;
  esac
else
  warn "theme_monocrom.json não encontrado em $repo_theme. Ignorando."
fi

log "Operação concluída."

log "Operação finalizada."
