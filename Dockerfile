FROM base/archlinux

CMD pacman -S base-devel

ENTRYPOINT makepkg -si
