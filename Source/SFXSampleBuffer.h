//
//  SFXSampleBuffer.h
//  sfxrX
//
//  Created by Seth Willits on 8/29/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SFXSampleBuffer : NSObject {
	float * mBuffer;
	NSUInteger mNumberOfSamples;
}

@property (readwrite) float * buffer;
@property (readwrite) NSUInteger numberOfSamples;

+ (SFXSampleBuffer *)sampleBufferWithBuffer:(float *)buffer numberOfSamples:(NSUInteger)count;
- (void)normalize;

@end
