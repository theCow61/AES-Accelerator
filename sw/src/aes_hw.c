
#include "aes_hw.h"
#include "xaxidma.h"
#include "xtime_l.h"
#include <stdint.h>

static XAxiDma axidma;

#define AES_HW_KEY_REG ((volatile aes_block_t*) (XPAR_AES_0_S00_AXI_BASEADDR + 4*12))


void aes_hw_init() {
	*AES_HW_KEY_REG = (aes_block_t) {0};
	XAxiDma_Config* dma_conf = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
	XAxiDma_CfgInitialize(&axidma, dma_conf);
	XAxiDma_Reset(&axidma);
	while (!XAxiDma_ResetIsDone(&axidma));
	aes_block_t dummy __attribute__((aligned(8))) = {0};
	aes_hw_encrypt(&dummy, &dummy, 1);
}

void aes_hw_encrypt(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	*AES_HW_KEY_REG = *key;
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DMA_TO_DEVICE);
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DEVICE_TO_DMA);
	while (XAxiDma_Busy(&axidma, XAXIDMA_DEVICE_TO_DMA));
}

void aes_hw_encrypt_large(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	*AES_HW_KEY_REG = *key;
	int max_dma_size = (1 << XPAR_AXI_DMA_0_SG_LENGTH_WIDTH) - 1;
	int bytes_remaining = n_blocks * 16;
	while (bytes_remaining > 0) {
		int transfer = bytes_remaining > max_dma_size ? max_dma_size : bytes_remaining;
		transfer = (transfer / 16) * 16;
		transfer = transfer == 0 ? 16 : transfer;

		while (XAxiDma_Busy(&axidma, XAXIDMA_DMA_TO_DEVICE));
		XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, transfer, XAXIDMA_DMA_TO_DEVICE);

		while (XAxiDma_Busy(&axidma, XAXIDMA_DEVICE_TO_DMA));
		XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, transfer, XAXIDMA_DEVICE_TO_DMA);

		bytes_remaining -= transfer;
		inout += (transfer/16);
	}
	while (XAxiDma_Busy(&axidma, XAXIDMA_DEVICE_TO_DMA));
}

void aes_hw_encrypt_nonblocking(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	*AES_HW_KEY_REG = *key;
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DMA_TO_DEVICE);
	XAxiDma_SimpleTransfer(&axidma, (unsigned int*) inout, n_blocks * 16, XAXIDMA_DEVICE_TO_DMA);
}

void aes_hw_encrypt_flushing(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	Xil_DCacheFlushRange(inout, n_blocks * 16);
	aes_hw_encrypt(key, inout, n_blocks);
	Xil_DCacheInvalidateRange(inout, n_blocks * 16);
}

void aes_hw_encrypt_flushing_large(aes_block_t* key, aes_block_t* inout, int n_blocks) {
	Xil_DCacheFlushRange(inout, n_blocks * 16);
	aes_hw_encrypt_large(key, inout, n_blocks);
	Xil_DCacheInvalidateRange(inout, n_blocks * 16);
}

void aes_hw_time_test_encrypt(aes_block_t* key, aes_block_t* inout, int n_blocks, uint64_t* cycles, float* time) {
	Xil_DCacheFlushRange(inout, n_blocks * 16);
	XTime start, end;

	XTime_GetTime(&start);
	aes_hw_encrypt_large(key, inout, n_blocks);
	XTime_GetTime(&end);

	Xil_DCacheInvalidateRange(inout, n_blocks * 16);

	uint64_t test_cycles = end - start;
	*time = ((double) test_cycles) / COUNTS_PER_SECOND;
	*cycles = test_cycles;
}
