# 0) antes de fazer a instalação não esqueça de atualizar o sistema

# 0.1) Pacotes multimídia (PipeWire + GStreamer + FFmpeg)
sudo pacman -S \
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

# 0.2) Git + base-devel (para compilar AUR)
sudo pacman -S git base

# 0.3) Clonar e instalar yay (AUR helper)
    git clone https://aur.archlinux.org/yay.git
    ls # cheque se o yay instalou
    cd yay
    ls #tem que ter o arquivo makepkg
    makepkg -si
    cd
    rm -rf yay/

# 0.4) Instalar Hyprland e utilitários
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
    dg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    dunst \
    cliphist \
    mpv \
    pavucontrol \
    xdg-user-dirs-gtk \
    gnome-keyring \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    ttf-droid \
    ttf-iosevka-nerd

# 0.5) Instalar complementos com o AUR yay (mude o zen caso queira outro navegador)
yay -S --noconfirm hyprshot wlogout qview visual-studio-code-bin zen-browser-bin

# 0.6) abilitando o pipewire
systemctl --user enable pipewire pipewire-pulse wireplumber

# 0.7) depois disso reinicie o computador com
shutdown -r now

# ao iniciar a sessão execute 
hyprland

# 1) configurando o hyprland
sudo pacman -S nano
# instalando o ax-shell (reinicie o computador após a instalação)
curl -fsSL https://raw.githubusercontent.com/Axenide/Ax-Shell/main/install.sh | bash

# 2) fish
sudo pacman -S fish thefuck zoxide
# para ativar o fish para o sistema inteiro
sudo chsh -s /usr/bin/fish

# 3) theme do GTK e do QT e os icons 
sudo pacman -S breeze breeze5 breeze-gtk papirus-icon-theme
sudo pacman -S nwg-look
yay -S --noconfirm qt5ct-kde qt6ct-kde

foot mate-polkit gammastep starship fastfetch nwg-look





