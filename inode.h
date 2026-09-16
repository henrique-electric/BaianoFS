#ifndef BAIANOFS_INODE_H
#define BAIANOFS_INODE_H
#include <linux/fs.h>

struct __baiano_inode  {
	__u32 size;
	char name[255];
} __packed;

struct __vfs_baiano_inode {
	struct __baiano_inode in_disk_inode;
	struct inode kernel_vfs_inode;
} __packed;

struct inode *__baiano_alloc_inode(struct super_block *sb);
void __baiano_free_inode(struct inode *inode);

#endif // !BAIANOFS_INODE_H
