#ifndef BAIANOFS_FOPS_H
#define BAIANOFS_FOPS_H

#include <linux/fs.h>
#include <linux/compiler_types.h>

ssize_t baiano_write(struct file *file, char __user *buff, size_t size, loff_t offset);



#endif // !BAIANOFS_FOPS_H

