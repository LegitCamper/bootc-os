# install jetbrains mono nerd font
cd /usr/share/fonts
mkdir -p JetBrainsMonoNerdFont
cd JetBrainsMonoNerdFont

curl -L -o JetBrainsMono.tar.xz \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz

tar -xJf JetBrainsMono.tar.xz --strip-components=0
rm JetBrainsMono.tar.xz

# Rebuild font cache
fc-cache -fv


# configures kvantum theme for qt
git clone https://github.com/catppuccin/Kvantum.git
mv Kvantum/themes/* /usr/share/Kvantum/
rm -r Kvantum


# grub theme
git clone https://github.com/catppuccin/grub.git
cp -r grub/src/* /usr/share/grub/themes/
rm -rf grub

GRUB_THEME_PATH="/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt"
GRUB_DEFAULT_FILE="/etc/default/grub"
echo "GRUB_THEME=\"$GRUB_THEME_PATH\"" >> "$GRUB_DEFAULT_FILE"

grub2-mkconfig -o /boot/grub2/grub.cfg
