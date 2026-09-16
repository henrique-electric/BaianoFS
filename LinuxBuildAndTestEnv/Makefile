DEV_BUILD_CONTAINER_NAME = dev
ARCH=x86_64

.PHONY:  initramfs qemu

shell:
	docker run -it --rm -v $(LINUX_SOURCE_TREE):/workspace/linux $(DEV_BUILD_CONTAINER_NAME) 

initramfs:
	docker run --rm -v $(PWD):/workspace/linux $(DEV_BUILD_CONTAINER_NAME) build-initramfs.sh

qemu:
	qemu-system-$(ARCH) -initrd initramfs.cpio.gz -kernel $(LINUX_SOURCE_TREE)/build/arch/$(ARCH)/boot/bzImage -append "console=ttyS0" -nographic -m 2048 -hda disk.qcow2
