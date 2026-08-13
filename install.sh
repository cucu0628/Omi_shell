#!/usr/bin/env bash
set -euo pipefail

if (( EUID == 0 )); then
  printf 'Hiba: ne futtasd sudo-val; a script szükség esetén maga kér jogosultságot.\n' >&2
  exit 1
fi

command -v pacman >/dev/null 2>&1 || {
  printf 'Hiba: ez a telepítő csak Arch Linux/CachyOS rendszeren használható.\n' >&2
  exit 1
}

# Runtime tools for every built-in shell feature and bundled integration.
repo_packages=(
  base-devel
  bash
  bluez
  bluez-utils
  blueman
  btop
  cava
  cliphist
  coreutils
  curl
  desktop-file-utils
  fastfetch
  findutils
  fzf
  gawk
  git
  glib2
  grep
  grim
  hyprland
  imagemagick
  inetutils
  iproute2
  jq
  kconfig
  kitty
  libnotify
  libqalculate
  matugen
  network-manager-applet
  networkmanager
  noto-fonts-emoji
  pam
  pavucontrol
  pipewire
  pipewire-pulse
  polkit
  power-profiles-daemon
  procps-ng
  qt6ct
  quickshell
  satty
  sddm
  sed
  slurp
  sudo
  ttf-nerd-fonts-symbols-mono
  wireplumber
  wl-clipboard
  xdg-desktop-portal-gtk
  xdg-user-dirs
  xdg-utils
  xorg-xrandr
)

aur_packages=(
  wayfreeze-git
  yaru-icon-theme
)

printf 'Repository-csomagok ellenőrzése és telepítése...\n'
sudo pacman -S --needed "${repo_packages[@]}"

if command -v paru >/dev/null 2>&1; then
  aur_helper=paru
elif command -v yay >/dev/null 2>&1; then
  aur_helper=yay
elif pacman -Si paru >/dev/null 2>&1; then
  printf 'A paru telepítése a rendszer repository-jából...\n'
  sudo pacman -S --needed paru
  aur_helper=paru
else
  printf 'A paru felépítése AUR-ból...\n'
  build_dir=$(mktemp -d)
  trap 'rm -rf "$build_dir"' EXIT
  git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
  (
    cd "$build_dir/paru"
    makepkg -si
  )
  aur_helper=paru
fi

printf 'AUR-csomagok ellenőrzése és telepítése...\n'
"$aur_helper" -S --needed "${aur_packages[@]}"

printf '\nMinden Vellum Shell-függőség telepítve van.\n'
printf 'A NetworkManager és Bluetooth szolgáltatásokat szükség esetén külön engedélyezd.\n'
