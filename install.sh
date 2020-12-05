#!/usr/bin/env sh

# # Intro
# Install archlinux as a guest (qemu / VirtualBox ...) with a script.
#
# **WARNING: /dev/sda (and /dev/sdb if it exists) will be eraised! (if `env
# INSTALL=1` is passed in)**
#
# When /dev/sdb is available, /dev/sda (/dev/sda1) will be mounted as /boot,
# and /dev/sdb will be used as super block (no partition, easier to resize).
#
# # Usage
# In archlinux iso session, download this script; then:
#
# ```sh
# # without INSTALL=1, help message will be printed.
# INSTALL=1 sh ./install.sh
# ```
#
# # NOTE
# - username (sudo-ed) / password / hostname: all are `box`.
# - timezone is set to Asia/Shanghai.

{  # ensure whole script is loaded.

set -e

if [ "$INSTALL" != 1 ]; then
    sed -nE '2,/^[^#]/ s/^# ?(.+|)$/\1/p' "$0"
    exit 0
fi

set -x

printf 'o\nn\n\n\n\n\nw\n' | fdisk /dev/sda
mkfs.ext4 /dev/sda1
if [ -e /dev/sdb ]; then
    mkfs.ext4 /dev/sdb
    mount /dev/sdb /mnt
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
else
    mount /dev/sda1 /mnt
fi
printf 'Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt bash -s <<\EOF
# chroot
set -ex
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
sed -i -r 's/^.*(en_US.UTF-8 UTF-8)$/\1/' /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'box\n' > /etc/hostname
printf '\
127.0.0.1 localhost
::1 localhost
127.0.1.1 box.localdomain box
' > /etc/hosts
pacman -S --noconfirm grub dhcpcd sudo
sed -i -r 's/^.*(%wheel ALL=\(ALL\) ALL)$/\1/' /etc/sudoers
printf 'box\nbox\n' | passwd
useradd -m -G wheel box
printf 'box\nbox\n' | passwd box
systemctl enable dhcpcd
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF
umount -R /mnt
reboot

}
