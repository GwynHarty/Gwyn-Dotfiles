#!/bin/bash

set -e  # Encerra se qualquer comando falhar
set -u  # Encerra se tentar usar variáveis não definidas
set -o pipefail  # Garante que erros em pipes sejam tratados corretamente

# Instalação do PipeWire e pacotes multimídia
sudo pacman -S --noconfirm \
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
    
# Instalar o Git (caso ainda não esteja instalado)
sudo pacman -S --needed --noconfirm git base-devel

# Clonar e instalar o yay (AUR helper)
if [ ! -d "$HOME/yay" ]; then
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay/
else
    echo "yay já está clonado em ~/yay"
fi

sudo pacman -S hyprland hyprlock hypridle hyprcursor hyprpaper hyprpicker waybar kitty rofi-wayland dolphin dolphin-plugins ark kio-admin polkit-kde-agent qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk dunst cliphist mpv pavucontrol xdg-user-dirs-gtk ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts ttf-droid 
