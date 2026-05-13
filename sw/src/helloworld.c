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
#include "platform.h"
#include "xil_printf.h"
#include <xaxidma.h>

char plaintext[16] __attribute__((aligned(64)));
char cipher[16] __attribute__((aligned(64)));

typedef struct {
	unsigned char data[16];
} aes_block_t;

int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application");


    char aes_plaintext[] = "hello hellohello";
    char key[] = "aaa aaa aaa aaaa";
    volatile unsigned char* key_address = (unsigned char*) (0x43C00000 + 12);
    *((volatile aes_block_t*) key_address) = *((aes_block_t*) key);

    printf("\r\nKey:\r\n");
    for (int i = 0; i < 16; i++) {
    	printf("key byte %02d: %02X\r\n", i, key_address[i]);
    }

    memcpy(plaintext, aes_plaintext, sizeof(aes_plaintext));
    Xil_DCacheFlush();

    XAxiDma AxiDma;


    XAxiDma_Config* dma_conf = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
    XAxiDma_CfgInitialize(&AxiDma, dma_conf);

    for (int j = 0; j < 1000000; j++) {
    XAxiDma_SimpleTransfer(&AxiDma, (unsigned int*) plaintext, sizeof(plaintext), 0);

    XAxiDma_SimpleTransfer(&AxiDma, (unsigned int*) cipher, sizeof(cipher), 1);

    while (XAxiDma_Busy(&AxiDma, 1));
    printf("\r\n");
    for (int i = 0; i < 16; i++) {
    	printf("%02x\r\n", cipher[i]);
    }
    }

    cleanup_platform();
    return 0;
}
