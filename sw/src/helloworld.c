/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "micro-AES/micro_aes.h"
#include "aes_hw.h"
#include "xil_cache.h"
#include "ff.h"
#include "xtime_l.h"


aes_block_t plaintext[4000000] __attribute__((aligned(32))) = {0};
aes_block_t cipher[4000000] __attribute__((aligned(32))) = {0};


void print_block(aes_block_t* block) {
	for (int i = 0; i < 4; i++) {
		printf("%02X %02X %02X %02X\r\n", block->data[0 + i], block->data[4 + i], block->data[8 + i], block->data[12 + i]);
	}
}

int main()
{
    init_platform();

    print("Hello World\n\r");

    aes_hw_init();


    // test 1
    char test1_key[16] = "aaa aaa aaa aaaa";
    char test1_text[32] __attribute__((aligned(32))) = "hello hellohellohello hellohello";

    Xil_DCacheFlushRange(test1_text, sizeof(test1_text));
    aes_hw_encrypt(test1_key, test1_text, 2);
    Xil_DCacheInvalidateRange(test1_text, sizeof(test1_text));

    print_block(test1_text);
    print_block(test1_text + 16);


    // file test
    char file_test_key[16] = "protect strawbry";
    FATFS fs;
    FIL file;
    unsigned int bytes_read;
    if (f_mount(&fs, "0:/", 1) != FR_OK)
    	printf("Mount error\r\n");

    if (f_open(&file, "0:/strawbry.mp4", FA_READ) != FR_OK)
    	printf("File open error\r\n");

    FRESULT res;
    res = f_read(&file, plaintext, sizeof(plaintext), &bytes_read);
    f_close(&file);
    f_unmount("0:/");
    printf("Read result: %d\r\n", res);
    printf("Bytes: %d\r\n", bytes_read);

    int n_blocks = (bytes_read + 16 - 1) / 16;
    printf("Blocks: %d\r\n", n_blocks);

    printf("Testing sw encryption\r\n");

    XTime file_test_sw_start, file_test_sw_stop;
    XTime_GetTime(&file_test_sw_start);
    AES_ECB_encrypt(file_test_key, plaintext, n_blocks * 16, cipher);
    XTime_GetTime(&file_test_sw_stop);

    uint64_t sw_time_cycles = file_test_sw_stop - file_test_sw_start;
    float sw_time = ((double) sw_time_cycles) / COUNTS_PER_SECOND;


    printf("Testing hw encryption\r\n");
    XTime file_test_hw_start, file_test_hw_stop;
    XTime_GetTime(&file_test_hw_start);
    aes_hw_encrypt_flushing_large(file_test_key, plaintext, n_blocks);
    XTime_GetTime(&file_test_hw_stop);

    uint64_t hw_time_cycles = file_test_hw_stop - file_test_hw_start;
    float hw_time = ((double) hw_time_cycles) / COUNTS_PER_SECOND;

    printf("Finished encrypting\r\n");


    int matches = 1;
    for (int i = 0; i < n_blocks * 16; i++) {
    	if (((unsigned char*)plaintext)[i] != ((unsigned char*)cipher)[i]) {
    		matches = 0;
    		printf("Misses match at byte: %d\r\n", i);
    		break;
    	}
    }

    printf("Sw and Hw matches: %d\r\n", matches);
    printf("Sw cycles: %llu\tSw time: %f\t Sw throughput: %f GBps\r\n", sw_time_cycles, sw_time, (((float) bytes_read)/sw_time) / 1000000000.0);
    printf("Hw cycles: %llu\tHw time: %f\t Hw throughput: %f GBps\r\n", hw_time_cycles, hw_time, ((float) bytes_read)/hw_time / 1000000000.0);

    // cycles * seconds/cycles


    cleanup_platform();
    return 0;
}
