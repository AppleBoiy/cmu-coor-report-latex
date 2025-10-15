#!/bin/bash

if ! command -v tlmgr &>/dev/null; then
  echo "BasicTeX not found. Installing BasicTeX..."
  brew install --cask basictex
else
  echo "BasicTeX is already installed."
fi

# Ensure tlmgr is in PATH
export PATH="/Library/TeX/texbin:$PATH"

echo "Updating tlmgr..."
sudo tlmgr update --self

PACKAGES=(
  latexmk
  titlesec
  tocloft
  tocbibind
  geometry
  fancyhdr
  setspace
  xcolor
  hyperref
  polyglossia
  fontspec
  pgf
)

for package in "${PACKAGES[@]}"; do
  echo "Installing $package..."
  sudo tlmgr install "$package"
done

sudo tlmgr install collection-latexextra

echo "Setup complete! You can now build your project."