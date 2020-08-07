# Intro
Install archlinux as a guest (qemu / VirtualBox ...) with a script.

**WARNING: /dev/sda will be eraised! (if `env INSTALL=1` is passed in)**

# Usage
In archlinux iso session, download this script; then:

```sh
# without INSTALL=1, help message will be printed.
INSTALL=1 sh ./install.sh
```

# NOTE
- username (sudo-ed) / password / hostname: all are `box`.
- timezone is set to Asia/Shanghai.
