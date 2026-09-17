#include "inode_ops.h"

struct dentry* baiano_mkdir(struct mnt_idmap *idmap, struct inode *inode, struct dentry *dentry, umode_t mode) {
	printk("It's time to create a directory :)");	

	return NULL;
}
