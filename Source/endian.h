#ifndef __endian_h__
#define __endian_h__
/*
 *  endian.h
 *  For sfxr. To swap endianness on a big endian machine like the PowerPC. This
 *  is admittedly pretty PPC biased in terms of data types and the like.
 *  I really don't know if it will carry over well verbatim to Intel machines.
 *
 *  Created by Ryan Burton on 19/12/07.
 *  Volt@absoluteterritory.org / http://www.absoluteterritory.org
 *
 */

#include <stdio.h>



short sexchange(short halfword);
int sexchange32(int word);
long long sexchange64(long long doubleword);
float sexchangefloat(float value);

short be_swap(short halfword);
int be_swap32(int word);

long long be_swap64(long long doubleword);
float be_swapf(float val);

void le_write(void* multibyte, int elements, int bytecount, FILE* file);
void le_writef(void* multibyte, int elements, int bytecount, FILE* file);

void le_read(void* multibyte, int elements, int bytecount, FILE* file);
void le_readf(void* multibyte, int elements, int bytecount, FILE* file);

#endif
