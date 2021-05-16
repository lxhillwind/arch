#!/usr/bin/env sh

{  # ensure whole script is loaded.
set -e

HELP='# Intro
Install alpine as a guest (qemu / VirtualBox ...) with a script.

**WARNING: /dev/sda (and /dev/sdb if it exists) will be eraised! (if `env
INSTALL=1` is passed in)**

When /dev/sdb is available, /dev/sda (/dev/sda1) will be mounted as /boot,
and /dev/sdb will be used as super block (no partition, easier to resize).

# Usage
In archlinux iso session, download this script; then:

```sh
# without INSTALL=1, help message will be printed.
INSTALL=1 sh ./install.sh
```

# NOTE
- username (sudo-ed) / password / hostname: all are `box`.
- In VirtualBox, network adapter should be virtio-net.
'

minirootfs_url='https://mirrors.bfsu.edu.cn/alpine/latest-stable/releases/x86_64/alpine-minirootfs-3.13.5-x86_64.tar.gz'

if [ "$INSTALL" != 1 ]; then
    printf "%s" "$HELP"
    exit 0
fi

set -x

if ! [ -f "${minirootfs_url##*/}" ]; then
    # download and check
    curl -LO "$minirootfs_url"
    curl -LO "$_".sha256
    sha256sum -c "${_##*/}"
fi

mkdir -p mnt  # not /mnt, since alpine will use it.
printf 'o\nn\n\n\n\n\nw\n' | fdisk /dev/sda
mkfs.ext4 /dev/sda1
if [ -e /dev/sdb ]; then
    mkfs.ext4 /dev/sdb
    mount /dev/sdb mnt
    mkdir mnt/boot
    mount /dev/sda1 mnt/boot
else
    mount /dev/sda1 mnt
fi

tar xf "${minirootfs_url##*/}"
sed -i s/dl-cdn.alpinelinux.org/mirrors.bfsu.edu.cn/ etc/apk/repositories
cp /etc/resolv.conf etc/
PATH=/bin:/sbin:/usr/sbin:"$PATH" \
arch-chroot ./ /bin/sh -s <<\EOF
apk add --allow-untrusted --repositories-file /etc/apk/repositories --initdb -p /mnt alpine-base
EOF

cp /etc/resolv.conf mnt/etc/
cp etc/apk/repositories mnt/etc/apk/
PATH=/bin:/sbin:/usr/sbin:"$PATH" \
arch-chroot ./mnt /bin/sh -s <<\EOF
# e2fsprogs: fsck at startup
apk add linux-virt grub grub-bios sudo e2fsprogs

# required to fix sysroot mount.
echo 'GRUB_CMDLINE_LINUX_DEFAULT=" rootfstype=ext4"' >> /etc/default/grub

grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# sudo
sed -i -r 's/^.*(%wheel ALL=\(ALL\) ALL)$/\1/' /etc/sudoers
printf 'box\nbox\n' | adduser -s /bin/sh -G wheel box

printf 'box\nbox\n' | passwd

# networking
printf 'auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp\n' > /etc/network/interfaces

printf 'box\n' > /etc/hostname
printf \
'127.0.0.1 localhost
::1 localhost
127.0.1.1 box.localdomain box
' > /etc/hosts

rc-update add localmount boot  # otherwise fs is mount readonly
rc-update add hostname boot  # hostname is required for networking
rc-update add networking boot
rc-update add ntpd
rc-update add mount-ro shutdown  # avoid inconsistent shutdown
EOF

# >, not >> here.
genfstab -U mnt > mnt/etc/fstab

umount -R mnt
reboot

}
