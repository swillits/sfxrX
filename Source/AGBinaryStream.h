//
//  AGBinaryStream.h
//  Araelium Foundation
//
//  Created by Seth Willits on 1/31/07.
//  Copyright 2007 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
	AGBSOptionsRead				= 1 << 1,
	AGBSOptionsWrite			= 1 << 2,
	AGBSOptionsLittleEndian		= 1 << 3,
	AGBSOptionsBigEndian		= 1 << 4,
	AGBSOptionsDefault			= AGBSOptionsRead,
	AGBSOptionsDefaultL			= AGBSOptionsRead | AGBSOptionsLittleEndian,
	AGBSOptionsDefaultB			= AGBSOptionsRead | AGBSOptionsBigEndian
} AGBinaryStreamOptions;



#define AGBinaryStreamEndOfStreamException @"AGBinaryStreamEndOfStreamException"




@interface AGBinaryStream : NSObject {
	BOOL mLittleEndian;
}

@end



@interface AGBinaryStream (Methods)

- (id)initWithFilePath:(NSString *)filePath options:(NSInteger)options error:(NSError **)error;
- (id)initWithData:(NSData *)data options:(NSInteger)options error:(NSError **)error;
- (BOOL)open:(NSInteger)options error:(NSError **)error;
- (void)close;
- (void)flush;

- (FILE *)file;
- (NSData *)data;

- (BOOL)isEndOfFile;
- (NSInteger)lastErrorCode;
- (uint64_t)length;
- (void)setLength:(uint64_t)length;

- (BOOL)isLittleEndian;
- (void)setLittleEndian:(BOOL)set;
- (off_t)position;
- (void)setPosition:(off_t)pos;
- (void)offsetPosition:(off_t)pos;


- (size_t)writeData:(const void *)data length:(unsigned long)length;
- (void)writeDouble:(double)data;
- (void)writeFloat:(float)data;
- (void)writeBool:(BOOL)data;

- (void)writeInt8:(int8_t)data;
- (void)writeInt16:(int16_t)data;
- (void)writeInt32:(int32_t)data;
- (void)writeInt64:(int64_t)data;
- (void)writeUInt8:(uint8_t)data;
- (void)writeUInt16:(uint16_t)data;
- (void)writeUInt32:(uint32_t)data;
- (void)writeUInt64:(uint64_t)data;


- (size_t)readData:(void *)data length:(unsigned long)length;
- (double)readDouble;
- (float)readFloat;
- (BOOL)readBool;

- (int8_t)readInt8;
- (int16_t)readInt16;
- (int32_t)readInt32;
- (int64_t)readInt64;
- (uint8_t)readUInt8;
- (uint16_t)readUInt16;
- (uint32_t)readUInt32;
- (uint64_t)readUInt64;

@end



@interface AGBinaryStream (Additions)
- (void)writeString:(NSString *)string; // always utf8 encoding
- (NSString *)readString; // always utf8 encoding
- (NSData *)readDataOfLength:(unsigned long)length;
@end



// --------- Intended for internal use ------------ //

// Determines the Endianness of the Processor
#define BS_LITTLE_ENDIAN	1
#define BS_BIG_ENDIAN		0
#if defined(__LITTLE_ENDIAN__)
	#define BS_Byte_Order	BS_LITTLE_ENDIAN
#else
	#define BS_Byte_Order	BS_BIG_ENDIAN
#endif

// Byte swapping
#define BS_Swap16(arg)	CFSwapInt16(arg)
#define BS_Swap32(arg)	CFSwapInt32(arg)
#define BS_Swap64(arg)	CFSwapInt64(arg)

#define AGBinaryStreamRaiseEOF(result, size)	if (result != size) [NSException raise:AGBinaryStreamEndOfStreamException format:@"AGBinaryStream reached EOF"]

