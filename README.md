# Intro
Install archlinux as a guest (qemu / VirtualBox ...) with a script.

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
- timezone is set to Asia/Shanghai.
