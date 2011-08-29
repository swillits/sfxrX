//
//  AGBinaryDataStream.h
//  AraeliumFoundation
//
//  Created by Seth Willits on 11/15/09.
//  Copyright 2009 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AGBinaryStream.h"


@interface AGBinaryDataStream : AGBinaryStream {
	NSData * mData;
	uint64_t mPosition;
}

@end
