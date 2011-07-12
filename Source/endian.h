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

short sexchange(short halfword) {
    //A word is 32 bits on PPC. Anything else confuses me.
    int lowerbyte = halfword & 0x00FF;
    int upperbyte = (halfword >> 8) & 0x00FF;
    return ( upperbyte | (((short)lowerbyte) << 8) );
}

int sexchange32(int word) {
    int lowerhword = word & 0x0000FFFF;
    int upperhword = (word >> 16) & 0x0000FFFF;
    return ( sexchange(upperhword) | (((int)sexchange(lowerhword)) << 16) );
}

long long sexchange64(long long doubleword) {
    /* 64-bit byte swap just for good measure. */
    long long lowerdword = doubleword & 0x00000000FFFFFFFF;
    long long upperdword = (doubleword >> 32) & 0x00000000FFFFFFFF;
    return ( sexchange32(upperdword) | (((long long)sexchange32(lowerdword)) << 32) );
}

float sexchangefloat(float value) {
    union {
        float f;
        unsigned char c[4];
    } val1, val2;
    
    val1.f = value;
    val2.c[0] = val1.c[3];
    val2.c[1] = val1.c[2];
    val2.c[2] = val1.c[1];
    val2.c[3] = val1.c[0];
    
    return val2.f;
}

short be_swap(short halfword) {
    /* swaps if big endian. */
#ifdef __BIG_ENDIAN__
    return sexchange(halfword);
#else
	return halfword;
#endif
}

int be_swap32(int word) {
    /* swaps if big endian. */
#ifdef __BIG_ENDIAN__
    return sexchange32(word);
#else
	return word;
#endif
}

long long be_swap64(long long doubleword) {
#ifdef __BIG_ENDIAN__
    return sexchange64(doubleword);
#else
	return doubleword;
#endif
}

float be_swapf(float val) {
#ifdef __BIG_ENDIAN__
    return sexchangefloat(val);
#else
	return val;
#endif
}

void le_write(void* multibyte, int elements, int bytecount, FILE* file) {
    switch(bytecount) {
        case 2: {
            short data = *((short*)multibyte);
            data = be_swap(data);
            fwrite(&data, elements, bytecount, file);
            break;
        }
        case 4: {
            int data = *((int*)multibyte);
            data = be_swap32(data);
            fwrite(&data, elements, bytecount, file);
            break;
        }
        case 8: {
            long long data = *((long long*)multibyte);
            data = be_swap64(data);
            fwrite(&data, elements, bytecount, file);
            break;
        }
        default:
            //if it's 1 byte, fine.
            fwrite(multibyte, elements, bytecount, file);
            break;
    }
}

void le_writef(void* multibyte, int elements, int bytecount, FILE* file) {
    /* write out floats. */
    float data = *((float*)multibyte);
    data = be_swapf(data);
    fwrite(&data, elements, bytecount, file);
}

void le_read(void* multibyte, int elements, int bytecount, FILE* file) {
    
    switch(bytecount) {
        case 2: {
            short data = 0;
            fread(&data, elements, bytecount, file);
            data = be_swap(data);
            memcpy(multibyte, &data, sizeof(data));
            break;
        }
        case 4: {
            int data = 0;
            fread(&data, elements, bytecount, file);
            data = be_swap32(data);
            memcpy(multibyte, &data, sizeof(data));
            break;
        }
        case 8: {
            long long data = 0;
            fread(&data, elements, bytecount, file);
            data = be_swap64(data);
            memcpy(multibyte, &data, sizeof(data));
        }
        default:
            //if it's 1 byte, fine.
            fread(multibyte, elements, bytecount, file);
            break;
    }
}

void le_readf(void* multibyte, int elements, int bytecount, FILE* file) {
    /* the extra f is for floats. */
    float data = 0;
    fread(&data, elements, bytecount, file);
    data = be_swapf(data);
    memcpy(multibyte, &data, sizeof(float));
}