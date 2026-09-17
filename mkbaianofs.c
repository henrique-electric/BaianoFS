#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdlib.h>

#define BAIANOFS_BLSIZE 512
#define BAIANOFS_MAGIC 0x004F4E41494142
#define MAX_INODE_COUNT 200

enum inode_type {
	INODE_DIR,
	INODE_FILE,
	INODE_NOT_INIT
};

struct superblock {
	int64_t magic;
	int32_t blocksize;
	int32_t inode_count;
	int32_t first_inode_block;
	char padding[492];
} __attribute__((packed));

struct inode_struct {
	uint32_t size;
	uint32_t data_block;
	uint8_t  inode_type;
	char name[255];
} __attribute__((packed));

int main(int argc, char *argv[])
{
	int device = open(argv[1], O_APPEND);
	if (device < 0) {
		printf("Error opening device\n");
		exit(EXIT_FAILURE);
	}

	struct superblock *__sb = (struct superblock *) malloc(sizeof(struct superblock));
	if (!__sb) {
		printf("Error allocating a buffer for the superblock\n");
		exit(EXIT_FAILURE);
	}
	
	__sb->blocksize = BAIANOFS_BLSIZE;
	__sb->magic = BAIANOFS_MAGIC;
	__sb->inode_count = MAX_INODE_COUNT;
	__sb->first_inode_block = sizeof(struct superblock) + BAIANOFS_BLSIZE; // First inode on the inode block
	
	lseek(device, 0, SEEK_SET);	
	write(device, (void*)__sb, sizeof(struct superblock));

	lseek(device, sizeof(struct superblock) + BAIANOFS_BLSIZE, SEEK_SET);
	
	printf("Setting up the inode chunks\n");
	struct inode_struct *__inode_struct = (struct inode_struct *) malloc(sizeof(struct inode_struct));
	if (!__inode_struct) {
		printf("Error allocating buffer to write inode data\n");
		exit(EXIT_FAILURE);
	}
	

	// Allocate 200 inodes, not that much but i think it's good for a test filesystem
	for (int i = 0; i < MAX_INODE_COUNT; i ++) {
		__inode_struct->size = 0;
		__inode_struct->inode_type = INODE_NOT_INIT,
		memset(__inode_struct->name, 0x0, 255);
		lseek(device, BAIANOFS_BLSIZE, SEEK_CUR);
		write(device, (void*) __inode_struct, sizeof(struct inode_struct));
	}
	return EXIT_SUCCESS;
}
