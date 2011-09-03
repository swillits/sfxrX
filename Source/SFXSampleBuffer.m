//
//  SFXSampleBuffer.m
//  sfxrX
//
//  Created by Seth Willits on 8/29/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import "SFXSampleBuffer.h"


@implementation SFXSampleBuffer
@synthesize numberOfSamples = mNumberOfSamples;


+ (SFXSampleBuffer *)sampleBufferWithBuffer:(float *)buffer numberOfSamples:(NSUInteger)count;
{
	SFXSampleBuffer * sb = [[[SFXSampleBuffer alloc] init] autorelease];
	
	sb.buffer = buffer;
	sb.numberOfSamples = count;
	
	return sb;
}


- (void)dealloc
{
	if (mBuffer) free(mBuffer);
	[super dealloc];
}


- (void)setBuffer:(float *)buffer
{
	if (mBuffer) free(mBuffer);
	mBuffer = buffer;
}


- (float *)buffer
{
	return mBuffer;
}



- (void)normalize
{
	float maxValue = 0.0;
	
	for (NSUInteger i = 0; i < mNumberOfSamples; i++) {
		maxValue = MAX(maxValue, fabs(mBuffer[i]));
	}
	
	for (NSUInteger i = 0; i < mNumberOfSamples; i++) {
		mBuffer[i] = mBuffer[i] / maxValue;
	}
}


@end
