

typedef struct {
	unsigned char data[16];
} aes_block_t;


void aes_hw_init();

/*
 * in place encryption
 */
void aes_hw_encrypt(aes_block_t* key, aes_block_t* inout, int n_blocks);

void aes_hw_encrypt_nonblocking(aes_block_t* key, aes_block_t* inout, int n_blocks);

void aes_hw_encrypt_flushing(aes_block_t* key, aes_block_t* inout, int n_blocks);
