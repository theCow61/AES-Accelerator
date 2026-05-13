
#include "aes_hw.h"
#include "xaxidma.h"

static XAxiDma axidma;

#define AES_HW_KEY_REG ((volatile aes_block_t*) (0x43C00000 + 4*12))


void aes_hw_init() {
	*AES_HW_KEY_REG = (aes_block_t) {0};
	XAxiDma_Config* dma_conf = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
	XAxiDma_CfgInitialize(&axidma, dma_conf);
}

void aes_hw_encrypt(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	*AES_HW_KEY_REG = *key;
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DMA_TO_DEVICE);
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DEVICE_TO_DMA);
	while (XAxiDma_Busy(&axidma, XAXIDMA_DEVICE_TO_DMA));
}

void aes_hw_encrypt_nonblocking(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	*AES_HW_KEY_REG = *key;
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DMA_TO_DEVICE);
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DEVICE_TO_DMA);
}

void aes_hw_encrypt_flushing(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	Xil_DCacheFlush();
	aes_hw_encrypt(key, inout, n_blocks);
	Xil_DCacheInvalidate();
}
