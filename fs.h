#ifndef BAIANO_FS_H
#define BAIANO_FS_H
#include <linux/init.h>

// Forward declaration for fs_context struct
struct fs_context;

int init_context(struct fs_context *ctx);		// Function that sets up a context
int __baiano_fs_get_tree(struct fs_context *ctx);	// Get tree handler, used by the VFS to setup the super block and roots
int __init __baiano_register_fs(void);			// Function used to register the filesystem

#endif // !BAIANO_FS_H
