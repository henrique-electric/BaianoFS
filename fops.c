#include "fops.h"

ssize_t baiano_write(struct file *file, char *buff, size_t size, loff_t offset) {
	printk("It's time to write the data :)\n");
	return 0;
}
