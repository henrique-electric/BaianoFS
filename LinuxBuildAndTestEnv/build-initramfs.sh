#!/usr/bin/env bash
# Builds a minimal initramfs — toybox <https://github.com/landley/toybox>
# for the core utilities, GNU bash as the shell — statically linked for
# whatever target ARCH/CROSS_COMPILE currently point at, and packs it as a
# gzipped cpio archive.
#
# Uses the same ARCH/CROSS_COMPILE variables as the kernel build, so it
# follows whatever you last set them to:
#   build-initramfs.sh                                   # arm64 (image default)
#   ARCH=x86_64 CROSS_COMPILE= build-initramfs.sh         # x86_64
#
# Output: <out-dir>/initramfs-<ARCH>.cpio.gz  (out-dir defaults to the
# current directory, i.e. your mounted kernel source tree, so it ends up
# alongside the kernel Image on your Mac).

set -euo pipefail

: "${ARCH:?ARCH must be set, e.g. ARCH=arm64 or ARCH=x86_64}"
CROSS_COMPILE="${CROSS_COMPILE:-}"
OUT_DIR="${1:-$(pwd)}"

TOYBOX_SRC=/opt/toybox-src
TOYBOX_BUILD_DIR="/tmp/toybox-build-${ARCH}"
BASH_SRC=/opt/bash-src
BASH_BUILD_DIR="/tmp/bash-build-${ARCH}"
ROOTFS="/tmp/initramfs-rootfs-${ARCH}"

echo "==> Building static toybox  (ARCH=${ARCH}  CROSS_COMPILE=${CROSS_COMPILE:-<none, native>})"

rm -rf "$TOYBOX_BUILD_DIR" "$ROOTFS"
mkdir -p "$TOYBOX_BUILD_DIR" "$ROOTFS"

cp -a "$TOYBOX_SRC"/. "$TOYBOX_BUILD_DIR"/
( cd "$TOYBOX_BUILD_DIR"

  # Toybox's own build (scripts/make.sh) takes CROSS_COMPILE, CC and
  # LDFLAGS straight from the environment rather than as make
  # command-line arguments, and doesn't use an ARCH variable at all (the
  # target follows whatever $CROSS_COMPILE points at).
  #
  # CC must be forced to "gcc": it defaults to "cc", and the compiler
  # actually invoked is "${CROSS_COMPILE}${CC}" — but Ubuntu's
  # crossbuild-essential-arm64/amd64 packages only ship a "*-gnu-gcc"
  # binary, no "*-gnu-cc" symlink, so the default resolves to a compiler
  # that doesn't exist ("aarch64-linux-gnu-cc: not found"). This applies
  # to both targets, cross-compiled or native.
  export CROSS_COMPILE
  export CC=gcc
  export LDFLAGS="--static"

  make defconfig

  # login/su/mkpasswd all call crypt(3), which glibc >= 2.38 (Ubuntu
  # 24.04's glibc 2.39 included) no longer provides — it moved to
  # libxcrypt, a separate library this image doesn't build/link
  # statically for either target. Rather than chase a cross-compiled
  # static libcrypt.a, just don't build those three: this initramfs
  # boots straight to a root shell (bash, built below), so there's no
  # login prompt or /etc/shadow to make them useful anyway.
  for sym in LOGIN SU MKPASSWD; do
      sed -i "s/^CONFIG_${sym}=y/# CONFIG_${sym} is not set/" .config
  done

  make -j"$(nproc)"

  echo "==> Installing toybox applet symlinks"
  # `make install` (rather than install_flat) lays binaries out under
  # bin/sbin/usr/bin/usr/sbin like a normal root filesystem, all
  # symlinked back to the one static toybox binary.
  PREFIX="$ROOTFS" make install
)

echo "==> Building static GNU bash  (ARCH=${ARCH}  CROSS_COMPILE=${CROSS_COMPILE:-<none, native>})"

rm -rf "$BASH_BUILD_DIR"
mkdir -p "$BASH_BUILD_DIR" "$ROOTFS/bin"
cp -a "$BASH_SRC"/. "$BASH_BUILD_DIR"/

( cd "$BASH_BUILD_DIR"

  # Unlike toybox, bash's ./configure is a plain autotools script — it has
  # no notion of a CROSS_COMPILE prefix on its own, so CC has to be the
  # fully-prefixed compiler name ourselves, and --host has to be passed
  # explicitly so autoconf actually enters cross-compiling mode (without
  # it, configure's runtime feature probes try to *execute* the
  # just-compiled target binaries on this build machine and misbehave).
  # When CROSS_COMPILE is empty (native x86_64 build), both collapse to
  # the native case: CC=gcc, no --host.
  HOST_TRIPLE="${CROSS_COMPILE%-}"

  configure_args=(--without-bash-malloc --enable-static-link)
  [ -n "$HOST_TRIPLE" ] && configure_args+=(--host="$HOST_TRIPLE")

  # --enable-static-link makes configure add -static to LDFLAGS itself
  # (see configure.ac) when it detects gcc, so LDFLAGS doesn't need to be
  # set here as well.
  CC="${CROSS_COMPILE}gcc" ./configure "${configure_args[@]}"
  make -j"$(nproc)"

  # Skip `make install` entirely — it also installs docs, locales, and
  # the examples/loadables tree (whose install rules have had cross-build
  # breakage in the past), none of which this rescue initramfs needs. The
  # built "bash" binary sitting in the build dir is already everything we
  # want; strip it with the matching cross-strip to shrink it.
  cp bash "$ROOTFS/bin/bash"
  "${CROSS_COMPILE}strip" "$ROOTFS/bin/bash"
)

echo "==> Assembling root filesystem skeleton"
mkdir -p "$ROOTFS"/{proc,sys,dev,tmp,root,etc,mnt}

cat > "$ROOTFS/init" <<'INIT'
#!/bin/bash
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev || echo "warning: devtmpfs mount failed — no /dev nodes (enable CONFIG_DEVTMPFS in the kernel .config)"

echo
echo "Booted into initramfs (toybox + bash)."
echo "This is a plain rescue shell — there's no real root filesystem here."
echo

exec /bin/bash
INIT
chmod +x "$ROOTFS/init"

echo "==> Packing cpio.gz"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/initramfs.cpio.gz"
( cd "$ROOTFS" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 ) > "$OUT_FILE"

echo "==> Done: $OUT_FILE"
