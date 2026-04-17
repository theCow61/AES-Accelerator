
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  uint8_t data[16];
} aes_block_t;

typedef struct {
  uint8_t key[16];
} aes_key_t;

typedef struct {
  uint32_t words[4];
} aes_expanded_key_t;

typedef struct {
  aes_expanded_key_t expanded_keys[11];
} aes_expanded_keys_t;

const uint8_t aes_sbox[] = {
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7,	0xfd,	0x93,	0x26,	0x36,	0x3f,	0xf7,	0xcc,	0x34,	0xa5,	0xe5,	0xf1,	0x71,	0xd8,	0x31,	0x15,
  0x04,	0xc7,	0x23,	0xc3,	0x18,	0x96,	0x05,	0x9a,	0x07,	0x12,	0x80,	0xe2,	0xeb,	0x27,	0xb2,	0x75,
  0x09,	0x83,	0x2c,	0x1a,	0x1b,	0x6e,	0x5a,	0xa0,	0x52,	0x3b,	0xd6,	0xb3,	0x29,	0xe3,	0x2f,	0x84,
  0x53,	0xd1,	0x00,	0xed,	0x20,	0xfc,	0xb1,	0x5b,	0x6a,	0xcb,	0xbe,	0x39,	0x4a,	0x4c,	0x58,	0xcf,
	0xd0,	0xef,	0xaa,	0xfb,	0x43,	0x4d,	0x33,	0x85,	0x45,	0xf9,	0x02,	0x7f,	0x50,	0x3c,	0x9f,	0xa8,
	0x51,	0xa3,	0x40,	0x8f,	0x92,	0x9d,	0x38,	0xf5,	0xbc,	0xb6,	0xda,	0x21,	0x10,	0xff,	0xf3,	0xd2,
	0xcd,	0x0c,	0x13,	0xec,	0x5f,	0x97,	0x44,	0x17,	0xc4,	0xa7,	0x7e,	0x3d,	0x64,	0x5d,	0x19,	0x73,
	0x60,	0x81,	0x4f,	0xdc,	0x22,	0x2a, 0x90,	0x88,	0x46,	0xee,	0xb8,	0x14,	0xde,	0x5e,	0x0b,	0xdb,
	0xe0,	0x32,	0x3a,	0x0a,	0x49,	0x06,	0x24,	0x5c,	0xc2,	0xd3,	0xac,	0x62,	0x91,	0x95,	0xe4,	0x79,
	0xe7,	0xc8,	0x37,	0x6d,	0x8d,	0xd5,	0x4e,	0xa9,	0x6c,	0x56,	0xf4,	0xea,	0x65,	0x7a,	0xae,	0x08,
	0xba,	0x78,	0x25,	0x2e,	0x1c,	0xa6,	0xb4,	0xc6,	0xe8,	0xdd,	0x74,	0x1f,	0x4b,	0xbd,	0x8b,	0x8a,
	0x70,	0x3e,	0xb5,	0x66,	0x48,	0x03,	0xf6,	0x0e,	0x61,	0x35,	0x57,	0xb9,	0x86,	0xc1,	0x1d,	0x9e,
	0xe1,	0xf8,	0x98,	0x11,	0x69,	0xd9,	0x8e,	0x94,	0x9b,	0x1e,	0x87,	0xe9,	0xce,	0x55,	0x28,	0xdf,
	0x8c,	0xa1, 0x89,	0x0d,	0xbf,	0xe6, 0x42,	0x68,	0x41,	0x99,	0x2d,	0x0f,	0xb0,	0x54,	0xbb,	0x16
};

const uint8_t aes_round_constants[] = {
  0x1,
  0x2,
  0x4,
  0x8,
  0x10,
  0x20,
  0x40,
  0x80,
  0x1b,
  0x36,
  0xff // invalid
};

void aes_print_block(aes_block_t* block) {
  printf("\n");
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      printf("%02X ", block->data[i + 4*j]); // column major visual
    }
    printf("\n");
  }
}

uint32_t aes_g_function(uint32_t last_word_of_expanded_key, int round_iteration) {

  uint8_t byte0 = last_word_of_expanded_key;
  uint8_t byte1 = last_word_of_expanded_key >> 8;
  uint8_t byte2 = last_word_of_expanded_key >> 16;
  uint8_t byte3 = last_word_of_expanded_key >> 24;

  byte0 = aes_sbox[byte0];
  byte1 = aes_sbox[byte1];
  byte2 = aes_sbox[byte2];
  byte3 = aes_sbox[byte3];

  return (byte0 << 24) | (byte3 << 16) | (byte2 << 8) | (byte1 ^ aes_round_constants[round_iteration]);
}

void aes_key_expansion(aes_expanded_keys_t* expanded_keys, aes_block_t* key) {
  // 11 round keys (the first being for initial transofrmation)
  // 44 words
  
  // pre transformation expanded key
  expanded_keys->expanded_keys[0].words[0] = *((uint32_t*) &key->data[0]); // mind the endianess
  expanded_keys->expanded_keys[0].words[1] = *((uint32_t*) &key->data[4]);
  expanded_keys->expanded_keys[0].words[2] = *((uint32_t*) &key->data[8]);
  expanded_keys->expanded_keys[0].words[3] = *((uint32_t*) &key->data[12]);


  uint32_t last_word_g_ed = aes_g_function(expanded_keys->expanded_keys[0].words[3], 0);

  for (int i = 1; i < 11; i++) {
    expanded_keys->expanded_keys[i].words[0] = expanded_keys->expanded_keys[i - 1].words[0] ^ last_word_g_ed;
    expanded_keys->expanded_keys[i].words[1] = expanded_keys->expanded_keys[i - 1].words[1] ^ expanded_keys->expanded_keys[i].words[0];
    expanded_keys->expanded_keys[i].words[2] = expanded_keys->expanded_keys[i - 1].words[2] ^ expanded_keys->expanded_keys[i].words[1];
    expanded_keys->expanded_keys[i].words[3] = expanded_keys->expanded_keys[i - 1].words[3] ^ expanded_keys->expanded_keys[i].words[2];
    last_word_g_ed = aes_g_function(expanded_keys->expanded_keys[i].words[3], i);
  }
}

// only give scale 1 or 2 or 3
uint8_t gf_multiply_123(uint8_t scale, uint8_t number) {
  switch (scale) {
    case 1:
      return number;
    case 2:
      if (number >> 7) {
        return (number << 1) ^ 0x1b;
      }
      return number << 1;
    case 3:
      if (number >> 7) {
        return ((number << 1) ^ 0x1b) ^ number;
      }
      return (number << 1) ^ number;
    default:
      return 0;
  }
}



void aes_row_mix_and_sub(aes_block_t* inout) {
  /*
    *
    * b0  b4  b8  b12
    * b1  b5  b9  b13
    * b2  b6  b10 b14
    * b3  b7  b11 b15
    *
  */

  // all of this should be done combinatorial in parallel


  inout->data[0] = aes_sbox[inout->data[0]];
  inout->data[4] = aes_sbox[inout->data[4]];
  inout->data[8] = aes_sbox[inout->data[8]];
  inout->data[12] = aes_sbox[inout->data[12]];

  uint8_t temp_b1 = inout->data[1];
  uint8_t temp_b5 = inout->data[5];
  uint8_t temp_b9 = inout->data[9];
  uint8_t temp_b13 = inout->data[13];
  inout->data[1] = aes_sbox[temp_b5];
  inout->data[5] = aes_sbox[temp_b9];
  inout->data[9] = aes_sbox[temp_b13];
  inout->data[13] = aes_sbox[temp_b1];


  uint8_t temp_b2 = inout->data[2];
  uint8_t temp_b6 = inout->data[6];
  uint8_t temp_b10 = inout->data[10];
  uint8_t temp_b14 = inout->data[14];
  inout->data[2] = aes_sbox[temp_b10];
  inout->data[6] = aes_sbox[temp_b14];
  inout->data[10] = aes_sbox[temp_b2];
  inout->data[14] = aes_sbox[temp_b6];

  uint8_t temp_b3 = inout->data[3];
  uint8_t temp_b7 = inout->data[7];
  uint8_t temp_b11 = inout->data[11];
  uint8_t temp_b15 = inout->data[15];
  inout->data[3] = aes_sbox[temp_b15];
  inout->data[7] = aes_sbox[temp_b3];
  inout->data[11] = aes_sbox[temp_b7];
  inout->data[15] = aes_sbox[temp_b11];
}

void aes_mix_column(uint8_t* column_start) {
  // matrix multiplication


  uint8_t product_b0 = gf_multiply_123(2, column_start[0]);
  uint8_t product_b1 = gf_multiply_123(3, column_start[1]);
  uint8_t product_b2 = gf_multiply_123(1, column_start[2]);
  uint8_t product_b3 = gf_multiply_123(1, column_start[3]);
  uint8_t new_b0 = product_b0 ^ product_b1 ^ product_b2 ^ product_b3;

  product_b0 = gf_multiply_123(1, column_start[0]);
  product_b1 = gf_multiply_123(2, column_start[1]);
  product_b2 = gf_multiply_123(3, column_start[2]);
  product_b3 = gf_multiply_123(1, column_start[3]);
  uint8_t new_b1 = product_b0 ^ product_b1 ^ product_b2 ^ product_b3;

  product_b0 = gf_multiply_123(1, column_start[0]);
  product_b1 = gf_multiply_123(1, column_start[1]);
  product_b2 = gf_multiply_123(2, column_start[2]);
  product_b3 = gf_multiply_123(3, column_start[3]);
  uint8_t new_b2 = product_b0 ^ product_b1 ^ product_b2 ^ product_b3;

  product_b0 = gf_multiply_123(3, column_start[0]);
  product_b1 = gf_multiply_123(1, column_start[1]);
  product_b2 = gf_multiply_123(1, column_start[2]);
  product_b3 = gf_multiply_123(2, column_start[3]);
  uint8_t new_b3 = product_b0 ^ product_b1 ^ product_b2 ^ product_b3;

  column_start[0] = new_b0;
  column_start[1] = new_b1;
  column_start[2] = new_b2;
  column_start[3] = new_b3;
}

void aes_add_round_key(aes_block_t* data, aes_expanded_key_t round_key) {
  uint32_t col0 = *((uint32_t*) (&data->data[0])) ^ round_key.words[0];
  uint32_t col1 = *((uint32_t*) (&data->data[4])) ^ round_key.words[1];
  uint32_t col2 = *((uint32_t*) (&data->data[8])) ^ round_key.words[2];
  uint32_t col3 = *((uint32_t*) (&data->data[12])) ^ round_key.words[3];

  *((uint32_t*) (&data->data[0])) = col0;
  *((uint32_t*) (&data->data[4])) = col1;
  *((uint32_t*) (&data->data[8])) = col2;
  *((uint32_t*) (&data->data[12])) = col3;
}

void aes_encrypt_block(aes_block_t* data, aes_block_t* key) {
  aes_expanded_keys_t expanded_keys = {0};

  aes_key_expansion(&expanded_keys, key);

  aes_add_round_key(data, expanded_keys.expanded_keys[0]);

  for (int i = 1; i < 10; i++) {
    aes_row_mix_and_sub(data);
    aes_mix_column(&data->data[0]);
    aes_mix_column(&data->data[4]);
    aes_mix_column(&data->data[8]);
    aes_mix_column(&data->data[12]);
    aes_add_round_key(data, expanded_keys.expanded_keys[i]);
  }

  aes_row_mix_and_sub(data);
  aes_add_round_key(data, expanded_keys.expanded_keys[10]);

}


int main() {

  char text_str[] = "hello hellohello";
  char key_str[] = "aaa aaa aaa aaaa";


  aes_block_t key = {0};
  aes_block_t inout = {0};
  memcpy(inout.data, text_str, 16);
  memcpy(key.data, key_str, 16);

  // aes_print_block(&inout);
  // aes_print_block(&key);

  aes_encrypt_block(&inout, &key);

  aes_print_block(&inout);
  return 0;
}
