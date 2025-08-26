#!/usr/bin/env bash
set -euo pipefail

# install-configs.sh
# Uso:
#   ./install-configs.sh           -> interativo
#   ./install-configs.sh --noconfirm
#   ./install-configs.sh --dry-run
#   ./install-configs.sh --repo /caminho/para/Gwyn-Dotfiles

DRY_RUN=0
NOCONFIRM=0
REPO_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --noconfirm) NOCONFIRM=1; shift ;;
    --repo) REPO_DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Uso: $0 [--dry-run] [--noconfirm] [--repo /caminho/para/repo]

--dry-run    mostra ações sem executá-las
--noconfirm  sobrescreve alvos sem pedir confirmação
--repo DIR   usa DIR como repositório (default: diretório do script)
EOF
      exit 0
      ;;
    *) printf 'Argumento desconhecido: %s\n' "$1" >&2; exit 1 ;;
  esac
done

log(){ printf '\033[36m:: %s\033[0m\n' "$1"; }
warn(){ printf '\033[33m!! %s\033[0m\n' "$1"; }
run(){
  # mostra comando
  printf '\033[33m+ %s\033[0m\n' "$(printf '%s ' "$@")"
  [ "$DRY_RUN" -eq 0 ] && "$@"
}

# local do repositório (por padrão o diretório do script)
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  REPO_DIR="$(cd "$REPO_DIR" && pwd)"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

log "Repo: $REPO_DIR"
log "Config target: $CONFIG_DIR"
[ "$DRY_RUN" -eq 1 ] && warn "Modo dry-run ativado. Nenhuma modificação será feita."

# Lista de exclusão (nomes de pastas/arquivos que não devem ser instalados)
EXCLUDE=(.git .github .gitignore README.md LICENSE install-configs.sh install.sh)

# Gera array com diretórios do repo a serem instalados (somente top-level dirs)
dirs=()
for p in "$REPO_DIR"/*; do
  name="$(basename "$p")"
  # pular arquivos e itens da lista de exclusão
  if [ -d "$p" ] && [[ ! " ${EXCLUDE[*]} " =~ " ${name} " ]]; then
    dirs+=("$name")
  fi
done

# Instala cada diretório como symlink em $CONFIG_DIR/<nome>
for name in "${dirs[@]}"; do
  src="$REPO_DIR/$name"
  dest="$CONFIG_DIR/$name"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$NOCONFIRM" -eq 1 ]; then
      log "Sobrescrevendo $dest (noconfirm)..."
      run rm -rf "$dest"
    else
      read -r -p "Alvo '$dest' já existe. Sobrescrever? [Y/n] " ans
      case "$ans" in
        n|N) log "Pulando $name"; continue ;;
        *) 
          # cria backup se existir e não for já backup
          if [ -e "${dest}.bak" ] || [ -L "${dest}.bak" ]; then
            log "Backup ${dest}.bak já existe. Removendo alvo atual."
            run rm -rf "$dest"
          else
            log "Movendo $dest -> ${dest}.bak"
            run mv "$dest" "${dest}.bak"
          fi
          ;;
      esac
    fi
  fi

  log "Ligando $src -> $dest"
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$(realpath "$src")" "$dest"
done

# Agora instala (ou faz symlink) do arquivo theme_monocrom.json
repo_theme="$REPO_DIR/quickshell/dms/docs/theme_monocrom.json"
target_theme="$CONFIG_DIR/quickshell/dms/docs/theme_monocrom.json"

if [ -f "$repo_theme" ]; then
  # garante diretório alvo
  if [ ! -d "$(dirname "$target_theme")" ]; then
    log "Criando diretório $(dirname "$target_theme")"
    run mkdir -p "$(dirname "$target_theme")"
  fi

  if [ -e "$target_theme" ] || [ -L "$target_theme" ]; then
    if [ "$NOCONFIRM" -eq 1 ]; then
      log "Sobrescrevendo $target_theme (noconfirm)..."
      run rm -f "$target_theme"
    else
      read -r -p "Arquivo '$target_theme' já existe. Sobrescrever? [Y/n] " ans2
      case "$ans2" in
        n|N) log "Pulando theme_monocrom.json"; ;;
        *)
          run mv "$target_theme" "${target_theme}.bak" 2>/dev/null || run rm -f "$target_theme"
          log "Substituindo $target_theme"
          run ln -s "$(realpath "$repo_theme")" "$target_theme"
          ;;
      esac
    fi
  else
    log "Instalando theme_monocrom.json -> $target_theme"
    run ln -s "$(realpath "$repo_theme")" "$target_theme"
  fi
else
  warn "Arquivo $repo_theme não encontrado no repositório. Pulei instalação do theme."
fi

log "Operação finalizada."
