//
//  AGBinaryStream.m
//  Screenflick
//
//  Created by Seth Willits on 1/31/07.
//  Copyright 2007 Araelium Group. All rights reserved.
//

#import "AGBinaryStream.h"
//#import "AGBinaryFileStream.h"
//#import "AGBinaryDataStream.h"



@implementation AGBinaryStream

- (id)initWithFilePath:(NSString *)filePath options:(NSInteger)options error:(NSError **)error;
{
	[self release];
	return [[NSClassFromString(@"AGBinaryFileStream") alloc] initWithFilePath:filePath options:options error:error];
}


- (id)initWithData:(NSData *)data options:(NSInteger)options error:(NSError **)error;
{
	[self release];
	return [[NSClassFromString(@"AGBinaryDataStream") alloc] initWithData:data options:options error:error];
}


- (void)offsetPosition:(off_t)pos;
{
	[self setPosition:([self position] + pos)];
}


@end





//////////////////////////////////////////////////////////////////////////////////
//
//								  Additions
//
//////////////////////////////////////////////////////////////////////////////////


#pragma mark  
#pragma mark  

@implementation AGBinaryStream (Additions)

- (void)writeString:(NSString *)string; // always utf8 encoding
{
	[self writeBool:(string != nil)];
	
	NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
	uint32_t length = (uint32_t)[data length];
	
	[self writeUInt32:length];
	if (length > 0) {
		[self writeData:[data bytes] length:length];
	}
}


- (NSString *)readString;
{
	BOOL isValid = [self readBool];
	if (!isValid) {
		return nil;
	}
	
	uint32_t length = [self readUInt32];
	if (length == 0) {
		return @"";
	}
	
	NSMutableData * data = [NSMutableData dataWithLength:length];
	[self readData:[data mutableBytes] length:length];
	return [[[NSString alloc] initWithBytes:[data bytes] length:length encoding:NSUTF8StringEncoding] autorelease];
}


- (NSData *)readDataOfLength:(unsigned long)length;
{
	NSMutableData * data = [NSMutableData dataWithLength:length];
	[self readData:[data mutableBytes] length:length];
	return data;
}


@end





//////////////////////////////////////////////////////////////////////////////////
//
//								Byte Swapping
//
//////////////////////////////////////////////////////////////////////////////////
#pragma mark  
#pragma mark  
#pragma mark Byte Swapping


#ifndef BS_Swap16
static __inline__ uint16_t BS_Swap16(uint16_t D) {
	return((D<<8)|(D>>8));
}
#endif


#ifndef BS_Swap32
static __inline__ uint32_t BS_Swap32(uint32_t D) {
	return((D<<24)|((D<<8)&0x00FF0000)|((D>>8)&0x0000FF00)|(D>>24));
}
#endif


#ifndef BS_Swap64
static __inline__ uint64_t BS_Swap64(uint64_t val) {
	uint32_t hi, lo;

	/* Separate into high and low 32-bit values and swap them */
	lo = (uint32_t)(val&0xFFFFFFFF);
	val >>= 32;
	hi = (uint32_t)(val&0xFFFFFFFF);
	val = BS_Swap32(lo);
	val <<= 32;
	val |= BS_Swap32(hi);
	return(val);
}
#endif
