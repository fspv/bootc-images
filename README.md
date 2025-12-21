This is a base image for the Fedora bootc install. It can be used to create an image for a specific device.

=== Example

```
FROM nuhotetotniksvoboden/bootc-desktop-base:latest

COPY etc/systemd/system/home-user-.cache.mount /etc/systemd/system/home-user-.cache.mount
COPY etc/Yubico/u2f_keys /etc/Yubico/u2f_keys

RUN groupadd -g 1111 user \
    && useradd -u 1111 -g 1111 -G wheel --no-create-home -d /home/user user

RUN usermod -a -G backlight user

# password is `user`
RUN echo 'user:$6$k0UedmcC4YeFj0uy$1JdV9FostSJcQYzNbHUsX9EUmDGtvddrfGtIDpRNow1aq06WlPJctERkd5jzCM6KejE4wIBxSLEZsSzE8n8mO/' | chpasswd -e

RUN rm -rf /home

RUN systemctl enable home-user-.cache.mount

RUN mkdir -p /boot /home \
   && echo "UUID=b8e739a6-c985-479f-80ca-2ee8fabe63ad /boot ext4 defaults,rw 0 2" >> /etc/fstab \
   && echo "/dev/vg/home /home ext4 defaults,nofail,x-systemd.device-timeout=60 0 2" >> /etc/fstab

RUN dracut --force --regenerate-all
```

Then you can build this image like this
```sh
sudo podman run --rm -it localhost/fedora-sway-bootc:latest bash
```

If you want to install the image on a hard drive, this is what you can do:

```sh
sudo podman run --rm -it --privileged \
    --pid=host \
    -v /dev:/dev \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    --security-opt label=type:unconfined_t \
    localhost/fedora-sway-bootc:latest \
    bootc install to-disk --wipe --filesystem ext4 /dev/sdb
```

Or you can create a qcow image to run a virtual machine from it, then first create a config

```toml
# config.toml
[[customizations.filesystem]]
mountpoint = "/"
minsize = "30 GiB"
```

then

```sh
mkdir output osbuild-store
sudo podman run --rm -it --privileged \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v $(pwd)/output:/output \
    -v $(pwd)/osbuild-store:/store \
    -v $(pwd)/config.toml:/config.toml:ro \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    --rootfs ext4 \
    --local \
    localhost/fedora-sway-bootc:latest \
    --config /config.toml
```

Then you can use for example virt-manager to spin up a VM from this disk.

There are other ways to install available as well https://bootc-dev.github.io/bootc//bootc-install.html

After the initial installation is done and you're running inside a bootc system, you have to do [this](https://bootc-dev.github.io/bootc//man/bootc-switch.8.html):

```sh
sudo bootc switch --transport containers-storage localhost/fedora-sway-bootc:latest
```

And then use https://bootc-dev.github.io/bootc//man/bootc-upgrade.8.html

```sh
sudo bootc upgrade
```

To update to a new version.
