#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Execute como root: sudo $0"
  exit 1
fi

echo "Atualizando o sistema..."
sudo pacman -Syu --noconfirm

echo "Atualização Concluída."

echo "Instalndo git"
sudo pacman -S git

echo "Clonando repositório yay"
git clone 
