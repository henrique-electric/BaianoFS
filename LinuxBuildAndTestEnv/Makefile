DEV_BUILD_CONTAINER_NAME = dev

.PHONY: linux

linux:
	$(MAKE) -C $(LINUX_SOURCE_TREE) O=build ARCH=x86_64 -j 12

initramfs:
	podman run --rm -v $(PWD):/workspace/linux $(DEV_BUILD_CONTAINER_NAME) build-initramfs.sh

qemu:
	qemu-system-x86_64 -initrd initramfs.cpio -kernel $(LINUX_SOURCE_TREE)/build/arch/x86_64/boot/bzImage -append "console=ttyS0" -nographic -m 2048 -hda disk.qcow2
