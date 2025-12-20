FROM quay.io/fedora/fedora-bootc:43

RUN dnf install -y 'dnf5-command(copr)' \
    && dnf copr enable -y wezfurlong/wezterm-nightly \
    && dnf config-manager addrepo --from-repofile=https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo \
    && dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
    && dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

COPY etc/yum.repos.d/tuxedo.repo /etc/yum.repos.d/tuxedo.repo

RUN rpm --import https://rpm.tuxedocomputers.com/fedora/43/0x54840598.pub.asc \
    && dnf install -y \
        cryptsetup lvm2 \
        policycoreutils-python-utils \
        glibc-langpack-en glibc-langpack-ru glibc-locale-source \
        sway swaylock swayidle swaybg waybar \
        polkit polkit-kde \
        dbus-daemon \
        pipewire pipewire-pulseaudio wireplumber pavucontrol \
        xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
        xdg-user-dirs \
        foot wezterm \
        wofi rofi \
        mako dunst \
        grim slurp wl-clipboard fzf flameshot \
        wdisplays wev \
        qt5-qtwayland qt5ct qt5-qtstyleplugins \
        gnome-themes-extra \
        xorg-x11-server-Xwayland \
        gsettings-desktop-schemas \
        fcitx5 fcitx5-gtk fcitx5-qt \
        wtype \
        light brightnessctl \
        terminator \
        firefox \
        thunar feh \
        cheese vlc \
        network-manager-applet blueman \
        zenity \
        git vim-enhanced \
        htop procps-ng \
        python3 python3-virtualenv python3-pip \
        sqlite kernel-tools syslinux \
        cowsay fortune-mod \
        et \
        NetworkManager-wifi wpa_supplicant \
        bluez bluetooth \
        samba-common \
        tailscale \
        VirtualBox-7.1 \
        virt-manager qemu-kvm libvirt \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin \
        podman podman-compose crun aardvark-dns \
        linux-firmware linux-firmware-whence \
        iwlwifi-mvm-firmware \
        intel-gpu-firmware intel-audio-firmware \
        kernel-modules-extra kernel-modules-internal \
        alsa-utils \
        acpid acpi upower \
        powertop tuned tuned-utils \
        tlp tlp-rdw thermald \
        yubikey-manager yubikey-personalization-gui \
        yubico-piv-tool pam-u2f \
        pcsc-lite pcsc-lite-ccid \
        opensc libfido2 \
        gdm plymouth \
        google-noto-emoji-color-fonts \
        flatpak \
        snapd \
        iptables iptables-services \
    && dnf install -y --setopt=tsflags=noscripts tuxedo-control-center \
    && dnf clean all

RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8
COPY etc/locale.conf /etc/locale.conf

COPY etc/et.cfg /etc/et.cfg

RUN mkdir -p /etc/Yubico \
    && touch /etc/Yubico/u2f_keys \
    && echo "auth    required            pam_u2f.so nouserok authfile=/etc/Yubico/u2f_keys cue" >> /etc/pam.d/common-auth

COPY etc/ssh/sshd_config.d/99-security.conf /etc/ssh/sshd_config.d/99-security.conf
COPY etc/sysctl.d/99-user.conf /etc/sysctl.d/99-user.conf
COPY etc/systemd/journald.conf.d/volatile.conf /etc/systemd/journald.conf.d/volatile.conf
COPY etc/dracut.conf.d/plymouth.conf /etc/dracut.conf.d/plymouth.conf
COPY etc/sysconfig/iptables /etc/sysconfig/iptables
COPY etc/sysconfig/ip6tables /etc/sysconfig/ip6tables

RUN rm /root \
    && mkdir /root \
    && curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install linux --no-confirm --no-start-daemon \
    && rm -rf /root \
    && ln -s /var/roothome /root

RUN mv /nix /var/nix \
    && mkdir /nix \
    && semanage fcontext -a -t var_run_t '/nix/var/nix/daemon-socket(/.*)?' \
    && semanage fcontext -a -t var_run_t '/nix/var/determinate(/.*)?' \
    && restorecon -Rv /var/nix/var/nix/daemon-socket \
    && restorecon -Rv /var/nix/var/determinate

COPY etc/systemd/system/nix.mount /etc/systemd/system/nix.mount
COPY etc/systemd/system/nix-daemon.socket.d/after-nix-mount.conf /etc/systemd/system/nix-daemon.socket.d/after-nix-mount.conf
COPY etc/systemd/system/nix-daemon.service.d/after-nix-mount.conf /etc/systemd/system/nix-daemon.service.d/after-nix-mount.conf

RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

RUN dnf install -y texinfo \
    && git clone https://github.com/erkin/ponysay.git /tmp/ponysay \
    && cd /tmp/ponysay \
    && ./setup.py install --freedom=partial \
    && rm -rf /tmp/ponysay \
    && dnf remove -y texinfo \
    && dnf clean all

RUN rm -rf /etc/skel \
    && git clone --depth 1 https://github.com/fspv/.bashrc /etc/skel \
    && rm -rf /etc/skel/.git

RUN ln -sf /bin/bash /bin/sh

COPY usr/share/X11/xkb/symbols/altgr_vim /usr/share/X11/xkb/symbols/altgr_vim
RUN sed -i '/name\[Group1\]= "English (US)"/i\    include "altgr_vim(altgr-vim)"' /usr/share/X11/xkb/symbols/us

COPY usr/bin/sway-with-debug-log /usr/bin/sway-with-debug-log
COPY usr/share/wayland-sessions/sway-debug.desktop /usr/share/wayland-sessions/sway-debug.desktop

RUN systemctl enable \
        NetworkManager \
        bluetooth \
        pcscd \
        acpid \
        thermald \
        docker \
        tailscaled \
        gdm \
        plymouth-start.service \
        iptables \
        ip6tables \
        nix.mount \
    && systemctl set-default graphical.target \
    && systemctl disable firewalld 2>/dev/null || true \
    && systemctl mask firewalld \
    && systemctl disable NetworkManager-wait-online.service \
    && systemctl mask NetworkManager-wait-online.service \
    && systemctl disable systemd-networkd-wait-online.service \
    && systemctl mask systemd-networkd-wait-online.service

COPY usr/lib/bootc/kargs.d/50-plymouth.toml /usr/lib/bootc/kargs.d/50-plymouth.toml

RUN dracut --force --regenerate-all
