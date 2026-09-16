# Cross-compilation environment for building ARM64 (aarch64) and/or x86_64
# Linux kernels — plus a matching minimal initramfs — from macOS (or any
# host) via Docker.
#
# This image does NOT emulate the target — it uses cross-compiler toolchains
# (aarch64-linux-gnu-gcc, x86_64-linux-gnu-gcc) to produce binaries for
# either architecture regardless of what architecture Docker itself is
# running the container on. That means it's fast on both Apple Silicon and
# Intel Macs: no QEMU/binfmt emulation needed, and no rebuild of the image
# to switch target architectures — just change ARCH/CROSS_COMPILE on the
# `make` command line (and for busybox, `build-initramfs.sh` below).
#
# If you specifically need 32-bit ARM (armhf) instead, see the note at the
# bottom of this file.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Cross-compiler toolchains (arm64 + x86_64) + everything the kernel build
# system needs
RUN apt-get update && apt-get install -y --no-install-recommends \
    crossbuild-essential-arm64 \
    crossbuild-essential-amd64 \
    build-essential \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    cpio \
    kmod \
    rsync \
    fakeroot \
    dwarves \
    device-tree-compiler \
    git \
    wget \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    xz-utils \
    bzip2 \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# Toybox source (https://github.com/landley/toybox), baked into the image
# so building an initramfs doesn't need network access at container-run
# time (only at image-build time). It gets cross-compiled fresh for
# whichever target ARCH is active by build-initramfs.sh below, since a
# prebuilt binary would only match one of the two targets this image
# supports.
ARG TOYBOX_VERSION=0.8.14
RUN wget -q "https://github.com/landley/toybox/archive/refs/tags/${TOYBOX_VERSION}.tar.gz" -O /tmp/toybox.tar.gz \
    && mkdir -p /opt/toybox-src \
    && tar -xzf /tmp/toybox.tar.gz -C /opt/toybox-src --strip-components=1 \
    && rm /tmp/toybox.tar.gz

COPY build-initramfs.sh /usr/local/bin/build-initramfs.sh
RUN chmod +x /usr/local/bin/build-initramfs.sh

# Cross-compile environment variables so a bare `make` inside the container
# defaults to arm64 without having to type these on every invocation.
# Override on the command line to target x86_64 instead, e.g.:
#   make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- defconfig
ENV ARCH=arm64
ENV CROSS_COMPILE=aarch64-linux-gnu-

WORKDIR /workspace/linux

CMD ["bash"]

# --- 32-bit ARM (armhf) instead of arm64 ---
# Add this package to the apt-get install list above:
#   crossbuild-essential-armhf
# Then build with:
#   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- defconfig
