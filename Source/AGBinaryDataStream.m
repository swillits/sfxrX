//
//  AGBinaryDataStream.m
//  AraeliumFoundation
//
//  Created by Seth Willits on 11/15/09.
//  Copyright 2009 Araelium Group. All rights reserved.
//

#import "AGBinaryDataStream.h"


#define AGBinaryStreamRaiseIfNoData \
		if (!mData) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryDataStream has no data"];


#define AGBinaryDataStreamReadBytes(arg_data, arg_length) \
		if (mPosition + (arg_length) <= [mData length]) { \
			[mData getBytes:(arg_data) range:NSMakeRange(mPosition, (arg_length))]; \
			mPosition += (arg_length); \
		} else { \
			mPosition = [self length]; \
			[NSException raise:AGBinaryStreamEndOfStreamException format:@"AGBinaryStream reached EOF"]; \
		}

#define AGBinaryDataStreamWriteBytes(arg_data, arg_length) \
		if (mPosition + (arg_length) > [mData length]) { \
			[(NSMutableData *)mData increaseLengthBy:(mPosition + (arg_length)) - [mData length]]; \
		} \
		[(NSMutableData *)mData replaceBytesInRange:NSMakeRange(mPosition, (arg_length)) withBytes:(arg_data) length:(arg_length)]; \
		mPosition += (arg_length);


@implementation AGBinaryDataStream

- (id)initWithData:(NSData *)data options:(NSInteger)options error:(NSError **)error;
{
	if (![super init]) {
		[self release];
		return nil;
	}
	
	if (data) {
		mData = [data retain];
	} else {
		mData = [[NSMutableData alloc] init];
	}
	mLittleEndian = NO;
	
	
	if (![self open:options error:error]) {
		[self release];
		return nil;
	}
	
	
	return self;
}


- (void)dealloc;
{
	[self close];
	[mData release];
	[super dealloc];
}



- (BOOL)open:(NSInteger)options error:(NSError **)error;
{
	[self close];
	
	// Endianness
	if (options & AGBSOptionsLittleEndian) {
		mLittleEndian = YES;
	} else if (options & AGBSOptionsBigEndian) {
		mLittleEndian = NO;
	} else {
		#if BS_Byte_Order == BS_LITTLE_ENDIAN
			mLittleEndian = YES;
		#else
			mLittleEndian = NO;
		#endif
	}
	
	if (options & AGBSOptionsWrite) {
		if (![mData isKindOfClass:[NSMutableData class]]) {
			[mData autorelease];
			mData = [[NSMutableData alloc] initWithData:mData];
		}
	}
	
	return YES;
}


- (void)close;
{
	
}


- (void)flush;
{
	
}





//////////////////////////////////////////////////////////////////////////////////
//
//								Options and Such
//
//////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Accessors


- (FILE *)file;
{
	return NULL;
}


- (NSData *)data;
{
	return mData;
}


- (BOOL)isEndOfFile;
{
	return ([self position] == [self length]);
}



- (NSInteger)lastErrorCode;
{
	return 0;
}


- (uint64_t)length;
{
	return [mData length];
}


- (void)setLength:(uint64_t)length;
{
	[(NSMutableData *)mData setLength:length];
}


- (BOOL)isLittleEndian;
{
	return mLittleEndian;
}


- (void)setLittleEndian:(BOOL)set;
{
	mLittleEndian = set;
}


- (off_t)position;
{
	return (off_t)mPosition;
}


- (void)setPosition:(off_t)pos;
{
	mPosition = pos;
	if (mPosition > [self length]) {
		[(NSMutableData *)mData increaseLengthBy:(mPosition - [mData length])];
	}
}




//////////////////////////////////////////////////////////////////////////////////
//
//								File Writing
//
//////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Writing

- (size_t)writeData:(const void *)data length:(unsigned long)length;
{
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamWriteBytes(data, length)
	return length;
}


- (void)writeDouble:(double)data;
{
	AGBinaryStreamRaiseIfNoData
	double value = data;
	uint64_t intValue = *(uint64_t*)&value;
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap64(intValue);
	}
	
	AGBinaryDataStreamWriteBytes(&intValue, sizeof(intValue))
}


- (void)writeFloat:(float)data;
{
	AGBinaryStreamRaiseIfNoData
	float value = data;
	uint32_t intValue = *(uint32_t*)&value;
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap32(intValue);
	}
	
	AGBinaryDataStreamWriteBytes(&intValue, sizeof(intValue))
}


- (void)writeBool:(BOOL)data;
{
	AGBinaryStreamRaiseIfNoData
	char value = 0;
	if (data) value = 1;
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeInt8:(int8_t)data;
{
	AGBinaryStreamRaiseIfNoData
	int8_t value = data;
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeInt16:(int16_t)data;
{
	AGBinaryStreamRaiseIfNoData
	int16_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap16(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeInt32:(int32_t)data;
{
	AGBinaryStreamRaiseIfNoData
	int32_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap32(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeInt64:(int64_t)data;
{
	AGBinaryStreamRaiseIfNoData
	int64_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap64(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeUInt8:(uint8_t)data;
{
	AGBinaryStreamRaiseIfNoData
	uint8_t value = data;
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeUInt16:(uint16_t)data;
{
	AGBinaryStreamRaiseIfNoData
	uint16_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap16(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeUInt32:(uint32_t)data;
{
	AGBinaryStreamRaiseIfNoData
	uint32_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap32(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}


- (void)writeUInt64:(uint64_t)data;
{
	AGBinaryStreamRaiseIfNoData
	uint64_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap64(data);
	AGBinaryDataStreamWriteBytes(&value, sizeof(value))
}








//////////////////////////////////////////////////////////////////////////////////
//
//								File Reading
//
//////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Reading

- (size_t)readData:(void *)data length:(unsigned long)length;
{
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(data, length)
	return length;
}


- (double)readDouble;
{
	double value;
	uint64_t intValue = 0;
	
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&intValue, sizeof(uint64_t));
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap64(intValue);
	}
	
	value = *(double*)(&intValue);
	
	return value;
}


- (float)readFloat;
{
	float value;
	uint32_t intValue = 0;
	
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&intValue, sizeof(uint32_t));
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap32(intValue);
	}
	
	value = *(float*)(&intValue);
	
	return value;
}


- (BOOL)readBool;
{
	char value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	return (value != '\0');
}


- (int8_t)readInt8;
{
	int8_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	return value;
}


- (int16_t)readInt16;
{
	int16_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap16(value);
	return value;
}


- (int32_t)readInt32;
{
	int32_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap32(value);
	return value;
}


- (int64_t)readInt64;
{
	int64_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap64(value);
	return value;
}


- (uint8_t)readUInt8;
{
	uint8_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	return value;
}


- (uint16_t)readUInt16;
{
	uint16_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap16(value);
	return value;
}


- (uint32_t)readUInt32;
{
	uint32_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value));
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap32(value);
	return value;
}


- (uint64_t)readUInt64;
{
	uint64_t value = 0;
	AGBinaryStreamRaiseIfNoData
	AGBinaryDataStreamReadBytes(&value, sizeof(value))
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap64(value);
	return value;
}


@end


