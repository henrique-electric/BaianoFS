#include <linux/init.h>
#include <linux/mount.h>
#include <linux/fs_context.h>
#include <linux/fs/super.h>
#include <linux/fs/super_types.h>
#include <linux/buffer_head.h>

#include "super.h"
#include "fs.h"

#define DEFAULT_BSIZE 512
#define BAIANO_MAGIC 0x004F4E41494142	// I reversed, because i reversed on mkbaianofs.c, since the cpu is writing on little endian, I HAVE TO FIX THIS!!


// Filesystem type structure, basic info for the VFS when register it
static struct file_system_type __type = {
	.name = "baianofs",
	.fs_flags = FS_REQUIRES_DEV,
	.owner = THIS_MODULE,
	.init_fs_context = init_context,
};


// Operation callback functions for the VFS use during the mount
static const struct fs_context_operations __ctx_ops = {
	.get_tree = __baiano_fs_get_tree,
}; 


// fill_sb function used as callback by get_tree
static int __baiano_fill_superblock(struct super_block *sb, struct fs_context *fc) {
	sb_set_blocksize(sb, DEFAULT_BSIZE);
	struct buffer_head *bread_res = sb_bread(sb, 0);

	if (!bread_res)
		// Failed to read the superblock from disk
		return -EIO; 

	struct __baiano_superblock *__baiano_sb = (struct __baiano_superblock *) bread_res->b_data;
	if (le64_to_cpu(__baiano_sb->magic) != BAIANO_MAGIC)
		// The magic number on the in disk not the BaianoFS
		return -EINVAL;
	
	if (le64_to_cpu(__baiano_sb->magic) == BAIANO_MAGIC)
		// The device is a BaianoFS formatted disk let's print for debugging;
		printk("Found a BaianoFS Partition\n");

	sb->s_root = NULL;
	return 0;
}

int __baiano_fs_get_tree(struct fs_context *ctx) {
	return get_tree_bdev(ctx, __baiano_fill_superblock);
}

int init_context(struct fs_context *ctx) {
	ctx->fs_type = &__type;
	ctx->fs_private = NULL;
	ctx->ops = &__ctx_ops;

	return 0;
}

int __init __baiano_register_fs(void) {
	printk("\n\n\n\nRegistered BAIANOFS :)\n\n\n");
	return register_filesystem(&__type);
}

fs_initcall(__baiano_register_fs);
