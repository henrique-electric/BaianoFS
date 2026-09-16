#ifndef BAIANO_SUPER_BLOCK_H
#define BAIANO_SUPER_BLOCK_H
#include <linux/fs.h>

// the Main
struct __baiano_superblock {
	__le64 magic;
	__le32 block_size;
	__le32 inode_cout;
} __packed;


#endif // !BAIANO_SUPER_BLOCK_H
