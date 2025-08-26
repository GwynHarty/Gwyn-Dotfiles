#!/usr/bin/env bash
set -euo pipefail

# install.sh
# Uso: chmod +x install.sh && ./install.sh [--dry-run] [--noconfirm]

DRY_RUN=0
NOCONFIRM=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --noconfirm) NOCONFIRM=1; shift ;;
    -h|--help)
      cat <<EOF
Uso: $0 [--dry-run] [--noconfirm]

--dry-run    mostra os comandos sem executá-los
--noconfirm  passa --noconfirm aos instaladores
EOF
      exit 0
      ;;
    *) printf 'Argumento desconhecido: %s\n' "$1" >&2; exit 1 ;;
  esac
done

log() { printf '\033[36m:: %s\033[0m\n' "$1"; }
warn() { printf '\033[33m!! %s\033[0m\n' "$1"; }

# executa ou mostra comando
run() {
  # imprime o comando
  printf '\033[33m+ %s\033[0m\n' "$(printf '%s ' "$@")"
  if [ "$DRY_RUN" -eq 0 ]; then
    "$@"
  fi
}

CONF_FLAG=""
if [ "$NOCONFIRM" -eq 1 ]; then
  CONF_FLAG="--noconfirm"
fi

# pacotes pacman
PACMAN_PKGS=(
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
  gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad
  gst-plugins-ugly ffmpeg nano fish thefuck zoxide nwg-look foot gammastep
  starship hyprland hypridle hyprcursor hyprpicker dolphin dolphin-plugins
  ark kio-admin mate-polkit qt5-wayland qt6-wayland xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk cliphist mpv pavucontrol xdg-user-dirs-gtk
  gnome-keyring ttf-font-awesome ttf-jetbrains-mono-nerd ttf-iosevka-nerd
  git base-devel cava wl-clipboard brightnessctl
)

# pacotes AUR gerais
AUR_PKGS=(
  hyprshot wlogout qview visual-studio-code-bin zen-browser-bin quickshell-git
  ttf-material-symbols-variable-git inter-font ttf-fira-code qt5ct-kde qt6ct-kde
  dankmaterialshell-git matugen dgop colloid-gtk-theme-git
)

# pacotes Spotify/Spicetify (instala via AUR helper)
SPOTIFY_PKGS=(spotify spicetify-cli spicetify-marketplace-bin)

# Atualiza cache sudo (só para forçar pedido de senha no início)
if ! sudo -v >/dev/null 2>&1; then
  log "Pedindo credenciais sudo..."
fi

# Instala pacotes via pacman
log "Instalando pacotes pacman..."
run sudo pacman -Syu --needed $CONF_FLAG "${PACMAN_PKGS[@]}"

# Detecta helper AUR preferido (paru > yay). Se não existir, instala yay (salvo --dry-run).
AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    warn "paru/yay não encontrado. (dry-run) iria instalar yay."
    AUR_HELPER="yay"
  else
    log "Nenhum helper AUR encontrado. Instalando yay..."
    run sudo pacman -S --needed $CONF_FLAG git base-devel
    tmpdir="$(mktemp -d)"
    run git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    run bash -c "cd '$tmpdir/yay' && makepkg -si $CONF_FLAG"
    run rm -rf "$tmpdir"
    AUR_HELPER="yay"
  fi
fi

log "Usando helper AUR: ${AUR_HELPER}"

# Instala pacotes AUR gerais
if [ "${#AUR_PKGS[@]}" -gt 0 ]; then
  log "Instalando pacotes AUR..."
  run "$AUR_HELPER" -S --needed "${AUR_PKGS[@]}" $CONF_FLAG
fi

# Instala Spotify + Spicetify (verifica se já havia spicetify antes)
_has_spicetify=1
if pacman -Q spicetify-cli >/dev/null 2>&1; then
  _has_spicetify=0
fi

log "Instalando Spotify e Spicetify..."
run "$AUR_HELPER" -S --needed "${SPOTIFY_PKGS[@]}" $CONF_FLAG

if [ "$_has_spicetify" -ne 0 ]; then
  log "Configuração inicial do Spicetify (primeira vez)."
  run sudo chmod a+wr /opt/spotify || warn "Falha ao chmod /opt/spotify."
  run sudo chmod a+wr /opt/spotify/Apps -R || true
  run spicetify backup apply || warn "spicetify backup apply falhou."
fi

# Instala Discord + Equicord/OpenAsar
log "Instalando Discord e Equicord..."
run "$AUR_HELPER" -S --needed discord equicord-installer-bin $CONF_FLAG

log "Executando Equilotl para instalar Equicord e OpenAsar em /opt/discord"
run sudo Equilotl -install -location /opt/discord
run sudo Equilotl -install-openasar -location /opt/discord

# Remove instalador equicord-installer-bin
log "Removendo instalador equicord-installer-bin (opcional)"
run "$AUR_HELPER" -Rns equicord-installer-bin $CONF_FLAG || warn "Falha ao remover equicord-installer-bin."

# Habilita serviços user
log "Habilitando serviços user: pipewire, pipewire-pulse, wireplumber..."
run systemctl --user enable --now pipewire pipewire-pulse wireplumber || \
  warn "Falha ao habilitar serviços user. Execute manualmente."

log "Instalação concluída."
