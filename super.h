#ifndef BAIANO_SUPER_BLOCK_H
#define BAIANO_SUPER_BLOCK_H
#include <linux/fs.h>

// the Main
struct __baiano_superblock {
	__u64 magic;
	__u32 block_size;
	__u32 inode_cout;
	__u32 first_inode_block;
	char  padding[492];
} __packed;


#endif // !BAIANO_SUPER_BLOCK_H
