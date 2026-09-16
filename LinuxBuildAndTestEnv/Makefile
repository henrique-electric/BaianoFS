DEV_BUILD_CONTAINER_NAME = dev
ARCH=x86_64

.PHONY: linux initramfs qemu

linux:
	$(MAKE) -C $(LINUX_SOURCE_TREE) O=build ARCH=x86_64 -j 12

initramfs:
	podman run --rm -v $(PWD):/workspace/linux $(DEV_BUILD_CONTAINER_NAME) build-initramfs.sh

qemu:
	qemu-system-$(ARCH) -initrd initramfs.cpio.gz -kernel $(LINUX_SOURCE_TREE)/build/arch/$(ARCH)/boot/bzImage -append "console=ttyS0" -nographic -m 2048 -hda disk.qcow2
