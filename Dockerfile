FROM base/archlinux

RUN sed -i 's/^SigLevel    = Required DatabaseOptional/SigLevel = Never/' /etc/pacman.conf
RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S base-devel --noconfirm
RUN useradd brendan -m
RUN echo "brendan ALL=NOPASSWD: ALL" >> /etc/sudoers

USER brendan
WORKDIR /home/brendan

ENTRYPOINT makepkg -si
