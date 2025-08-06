#!/bin/bash
set -euo pipefail

# 0) antes de fazer a instalação não esqueça de atualizar o sistema

# 1) Pacotes multimídia (PipeWire + GStreamer + FFmpeg)
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-jack \
    pipewire-pulse \
    wireplumber \
    gstreamer \
    gst-libav \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    ffmpeg

# 2) Git + base-devel (para compilar AUR)
sudo pacman -S --needed --noconfirm git base-devel

# 3) Clonar e instalar yay (AUR helper)
if [[ ! -d "$HOME/yay" ]]; then
    git clone https://aur.archlinux.org/yay.git "$HOME/yay"
    cd "$HOME/yay"
    makepkg -si --noconfirm
    cd -
    rm -rf "$HOME/yay"
else
    echo "▶ yay já está em ~/yay — pulando."
fi

# 4) Instalar Hyprland e utilitários
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprlock \
    hypridle \
    hyprcursor \
    hyprpaper \
    hyprpicker \
    waybar \
    kitty \
    rofi-wayland \
    dolphin \
    dolphin-plugins \
    ark \
    kio-admin \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    dunst \
    cliphist \
    mpv \
    pavucontrol \
    xdg-user-dirs-gtk \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    ttf-droid
    
# 5) Instalar complementos com o AUR yay (mude o zen caso queira outro navegador)
yay -S --noconfirm hyprshot wlogout qview visual-studio-code-bin zen-browser-bin

systemctl --user enable pipewire pipewire-pulse pipewireplumber

shutdown -r now
