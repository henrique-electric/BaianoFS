#ifndef BAIANO_INODE_OPS_H
#define BAIANO_INODE_OPS_H

#include <linux/fs.h>

struct dentry* baiano_mkdir(struct mnt_idmap *idmap, struct inode *inode, struct dentry *dentry, umode_t mode);

#endif // !BAIANO_INODE_OPS_H

