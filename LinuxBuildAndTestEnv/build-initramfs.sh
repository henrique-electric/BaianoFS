#!/usr/bin/env bash
# Builds a minimal initramfs (toybox <https://github.com/landley/toybox> +
# a tiny init script) statically linked for whatever target
# ARCH/CROSS_COMPILE currently point at, and packs it as a gzipped cpio
# archive.
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
BUILD_DIR="/tmp/toybox-build-${ARCH}"
ROOTFS="/tmp/initramfs-rootfs-${ARCH}"

echo "==> Building static toybox  (ARCH=${ARCH}  CROSS_COMPILE=${CROSS_COMPILE:-<none, native>})"

rm -rf "$BUILD_DIR" "$ROOTFS"
mkdir -p "$BUILD_DIR" "$ROOTFS"

cp -a "$TOYBOX_SRC"/. "$BUILD_DIR"/
cd "$BUILD_DIR"

# Toybox's own build (scripts/make.sh) takes CROSS_COMPILE and LDFLAGS
# straight from the environment rather than as make command-line
# arguments, and doesn't use an ARCH variable at all (the target follows
# whatever $CROSS_COMPILE points at) — export them explicitly rather than
# passing ARCH= like the kernel/busybox builds do.
export CROSS_COMPILE
export CC=gcc
export LDFLAGS="--static"

make defconfig
make -j"$(nproc)"

echo "==> Installing applet symlinks"
# `make install` (rather than install_flat) lays binaries out under
# bin/sbin/usr/bin/usr/sbin like a normal root filesystem, all symlinked
# back to the one static toybox binary.
PREFIX="$ROOTFS" make install

echo "==> Assembling root filesystem skeleton"
mkdir -p "$ROOTFS"/{proc,sys,dev,tmp,root,etc,mnt}

cat > "$ROOTFS/init" <<'INIT'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev || echo "warning: devtmpfs mount failed — no /dev nodes (enable CONFIG_DEVTMPFS in the kernel .config)"

echo
echo "Booted into initramfs (toybox)."
echo "This is a plain rescue shell — there's no real root filesystem here."
echo

exec /bin/sh
INIT
chmod +x "$ROOTFS/init"

echo "==> Packing cpio.gz"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/initramfs.cpio.gz"
( cd "$ROOTFS" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 ) > "$OUT_FILE"

echo "==> Done: $OUT_FILE"
