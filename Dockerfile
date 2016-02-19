FROM base/archlinux

RUN sed -i 's/^SigLevel    = Required DatabaseOptional/SigLevel = Never/' /etc/pacman.conf
RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S base-devel --noconfirm
RUN useradd pkg -m
RUN echo "pkg ALL=NOPASSWD: ALL" >> /etc/sudoers

USER pkg
WORKDIR /home/pkg

ENTRYPOINT makepkg -si
