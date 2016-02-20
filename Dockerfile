FROM babolivier/arch-pkg-env

RUN sudo pacman -S git --noconfirm

# Yaourt
RUN git clone https://aur.archlinux.org/package-query.git && cd package-query && makepkg -si --noconfirm
RUN git clone https://aur.archlinux.org/yaourt.git && cd yaourt && makepkg -si --noconfirm

#ENTRYPOINT makepkg -si
