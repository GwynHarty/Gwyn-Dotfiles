#!/usr/bin/env bash
set -euo pipefail

# Uso: ./install.sh [--dry-run] [--noconfirm]

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
      exit 0;;
    *) printf 'Argumento desconhecido: %s\n' "$1" >&2; exit 1;;
  esac
done

log(){ printf '\033[36m:: %s\033[0m\n' "$1"; }
warn(){ printf '\033[33m!! %s\033[0m\n' "$1"; }
run(){
  printf '\033[33m+ %s\033[0m\n' "$(printf '%s ' "$@")"
  [ "$DRY_RUN" -eq 0 ] && "$@"
}

CONF_FLAG=""
[ "$NOCONFIRM" -eq 1 ] && CONF_FLAG="--noconfirm"

# pacman
PACMAN_PKGS=(pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber \
gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad \
gst-plugins-ugly ffmpeg nano fish thefuck zoxide nwg-look foot gammastep \
starship hyprland hypridle hyprcursor hyprpicker dolphin dolphin-plugins \
ark kio-admin mate-polkit qt5-wayland qt6-wayland xdg-desktop-portal-hyprland \
xdg-desktop-portal-gtk cliphist mpv pavucontrol xdg-user-dirs-gtk \
gnome-keyring ttf-font-awesome ttf-jetbrains-mono-nerd ttf-iosevka-nerd \
git base-devel cava wl-clipboard brightnessctl)

AUR_PKGS=(hyprshot wlogout qview visual-studio-code-bin zen-browser-bin quickshell-git \
ttf-material-symbols-variable-git inter-font ttf-fira-code qt5ct-kde qt6ct-kde \
dankmaterialshell-git matugen dgop colloid-gtk-theme-git)

SPOTIFY_PKGS=(spotify spicetify-cli spicetify-marketplace-bin)

if ! sudo -v >/dev/null 2>&1; then log "Pedindo credenciais sudo..."; fi

log "Instalando pacotes via pacman..."
run sudo pacman -Syu --needed $CONF_FLAG "${PACMAN_PKGS[@]}"

# AUR helper
if command -v paru >/dev/null; then AUR_HELPER="paru"
elif command -v yay >/dev/null; then AUR_HELPER="yay"
elif [ "$DRY_RUN" -eq 1 ]; then
  warn "paru/yay não encontrado. (dry-run) iria instalar yay."
  AUR_HELPER="yay"
else
  log "Instalando yay..."
  run sudo pacman -S --needed $CONF_FLAG git base-devel
  tmpdir="$(mktemp -d)"
  run git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  run bash -c "cd '$tmpdir/yay' && makepkg -si $CONF_FLAG"
  run rm -rf "$tmpdir"
  AUR_HELPER="yay"
fi
log "Helper AUR: $AUR_HELPER"

log "Instalando pacotes AUR..."
run "$AUR_HELPER" -S --needed "${AUR_PKGS[@]}" $CONF_FLAG

# Spotify + Spicetify
_has_spicetify=1
pacman -Q spicetify-cli >/dev/null 2>&1 && _has_spicetify=0

log "Instalando Spotify e Spicetify..."
run "$AUR_HELPER" -S --needed "${SPOTIFY_PKGS[@]}" $CONF_FLAG

if [ "$_has_spicetify" -ne 0 ]; then
  log "Configuração inicial Spicetify."
  run sudo chmod a+wr /opt/spotify || warn "chmod /opt/spotify falhou"
  run sudo chmod a+wr /opt/spotify/Apps -R
  run spicetify backup apply || warn "spicetify backup apply falhou"
fi

# Discord + Equicord/OpenAsar
log "Instalando Discord e Equicord..."
run "$AUR_HELPER" -S --needed discord equicord-installer-bin $CONF_FLAG
run sudo Equilotl -install -location /opt/discord
run sudo Equilotl -install-openasar -location /opt/discord
log "Removendo instalador..."
run "$AUR_HELPER" -Rns equicord-installer-bin $CONF_FLAG || warn "Remoção falhou"

# SpotX-Bash (Spotify adblocker)
log "Instalando SpotX-Bash (ad-blocker Spotify)..."
run bash <(curl -sSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh)

# User services
log "Habilitando serviços user: pipewire, pipewire-pulse, wireplumber..."
run systemctl --user enable --now pipewire pipewire-pulse wireplumber || \
  warn "Habilitação falhou. Ative manualmente."

log "Instalação finalizada."
