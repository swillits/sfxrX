//
//  AGBinaryFileStream.m
//  AraeliumFoundation
//
//  Created by Seth Willits on 11/15/09.
//  Copyright 2009 Araelium Group. All rights reserved.
//

#import "AGBinaryFileStream.h"


@implementation AGBinaryFileStream

- (id)initWithFilePath:(NSString *)filePath options:(NSInteger)options error:(NSError **)error;
{
	if (![super init]) {
		[self release];
		return nil;
	}
	
	mFilePath = [filePath copy];
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
	[mFilePath release];
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
	
	// Make Options String
	char flags[4] = {'\0'}; NSInteger flag = 0;
	if ((options & AGBSOptionsRead) && (options & AGBSOptionsWrite)) {
		flags[flag++] = 'w';
		flags[flag++] = '+';
	} else if (options & AGBSOptionsRead) {
		flags[flag++] = 'r';
	} else if (options & AGBSOptionsWrite) {
		flags[flag++] = 'w';
	}
	
	// Always binary
	flags[flag] = 'b';
	
	
	// Open the File
	mFile = fopen([mFilePath fileSystemRepresentation], flags);
	if (!mFile) {
		if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSString stringWithFormat:@"Could not open file %@", mFilePath], NSLocalizedDescriptionKey,
				[NSString stringWithFormat:@"AGBinaryStream: failed to open %@. Error (%d) %s", mFilePath, errno, strerror(errno)], NSLocalizedFailureReasonErrorKey,
				nil]];
		
		return NO;
	}
	
	return YES;
}


- (void)close;
{
	if (mFile) {
		fclose(mFile);
		mFile = NULL;
	}
}


- (void)flush;
{
	if (mFile) {
		fflush(mFile);
	}
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
	return mFile;
}


- (NSData *)data;
{
	return nil;
}


- (BOOL)isEndOfFile;
{
	if (mFile) {
		return (feof(mFile) == 1);
	}
	
	return YES;
}



- (NSInteger)lastErrorCode;
{
	if (mFile)
		return ferror(mFile);
	return -1;
}


- (uint64_t)length;
{
	off_t currentPosition = [self position];
	uint64_t length = 0;
	
	if (mFile) {
		fseeko(mFile, 0, SEEK_END);
		length = [self position];
		[self setPosition:currentPosition];
	}
	
	return length;
}


- (void)setLength:(uint64_t)length;
{
	
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
	off_t position = 0;
	if (mFile) {
		position = ftello(mFile);
	}
	return position;
}


- (void)setPosition:(off_t)pos;
{
	fseeko(mFile, pos, SEEK_SET);
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
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	return fwrite(data, 1, length, mFile);
	
	// Using write is more efficient
	//[self offsetPosition:write(mFile->_file, data, length)];
}



- (void)writeDouble:(double)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	double value = data;
	uint64_t intValue = *(uint64_t*)&value;
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap64(intValue);
	}
	
	fwrite(&intValue, sizeof(uint64_t), 1, mFile);
}



- (void)writeFloat:(float)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	float value = data;
	uint32_t intValue = *(uint32_t*)&value;
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap32(intValue);
	}
	
	fwrite(&intValue, sizeof(uint32_t), 1, mFile);
}



- (void)writeBool:(BOOL)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	char value = 0;
	if (data) value = 1;
	fwrite(&value, sizeof(char), 1, mFile);
}


- (void)writeInt8:(int8_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int8_t value = data;
	fwrite(&value, sizeof(int8_t), 1, mFile);
}


- (void)writeInt16:(int16_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int16_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap16(data);
	fwrite(&value, sizeof(int16_t), 1, mFile);
}


- (void)writeInt32:(int32_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int32_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap32(data);
	fwrite(&value, sizeof(int32_t), 1, mFile);
}


- (void)writeInt64:(int64_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int64_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap64(data);
	fwrite(&value, sizeof(int64_t), 1, mFile);
}


- (void)writeUInt8:(uint8_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint8_t value = data;
	fwrite(&value, sizeof(uint8_t), 1, mFile);
}


- (void)writeUInt16:(uint16_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint16_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap16(data);
	fwrite(&value, sizeof(uint16_t), 1, mFile);
}


- (void)writeUInt32:(uint32_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint32_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap32(data);
	fwrite(&value, sizeof(uint32_t), 1, mFile);
}


- (void)writeUInt64:(uint64_t)data;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint64_t value = (mLittleEndian == BS_Byte_Order) ? data : BS_Swap64(data);
	fwrite(&value, sizeof(uint64_t), 1, mFile);
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
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	size_t result = fread(data, 1, length, mFile);
	AGBinaryStreamRaiseEOF(result, length);
	return result;
}


- (double)readDouble;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	double value;
	uint64_t intValue = 0;
	size_t result = fread(&intValue, sizeof(uint64_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap64(intValue);
	}
	
	value = *(double*)(&intValue);
	
	return value;
}



- (float)readFloat;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	float value;
	uint32_t intValue = 0;
	size_t result = fread(&intValue, sizeof(uint32_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	
	if (mLittleEndian != BS_Byte_Order) {
		intValue = BS_Swap32(intValue);
	}
	
	value = *(float*)(&intValue);
	
	return value;
}



- (BOOL)readBool;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	char value = 0;
	size_t result = fread(&value, sizeof(char), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	
	if (value != '\0')
		return YES;
	return NO;
}





- (int8_t)readInt8;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int8_t value = 0;
	size_t result = fread(&value, sizeof(int8_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	return value;
}


- (int16_t)readInt16;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int16_t value = 0;
	size_t result = fread(&value, sizeof(int16_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap16(value);
	return value;
}


- (int32_t)readInt32;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int32_t value = 0;
	size_t result = fread(&value, sizeof(int32_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap32(value);
	return value;
}


- (int64_t)readInt64;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	int64_t value = 0;
	size_t result = fread(&value, sizeof(int64_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap64(value);
	return value;
}


- (uint8_t)readUInt8;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint8_t value = 0;
	size_t result = fread(&value, sizeof(uint8_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	return value;
}


- (uint16_t)readUInt16;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint16_t value = 0;
	size_t result = fread(&value, sizeof(uint16_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap16(value);
	return value;
}


- (uint32_t)readUInt32;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint32_t value = 0;
	size_t result = fread(&value, sizeof(uint32_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap32(value);
	return value;
}


- (uint64_t)readUInt64;
{
	if (!mFile) [NSException raise:NSInternalInconsistencyException format:@"AGBinaryStream has no FILE"];
	uint64_t value = 0;
	size_t result = fread(&value, sizeof(uint64_t), 1, mFile);
	AGBinaryStreamRaiseEOF(result, 1);
	if (mLittleEndian != BS_Byte_Order) value = BS_Swap64(value);
	return value;
}


@end




