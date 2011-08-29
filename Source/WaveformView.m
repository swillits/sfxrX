//
//  WaveformView.m
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import "WaveformView.h"
#import "Synthesizer.h"
#import "SoundEffect.h"




@interface WaveformView (Private)
- (void)updateWaveform;
@end



@implementation WaveformView

- (void)dealloc
{
	[self setEffect:nil];
	[mData release];
	[super dealloc];
}


- (void)setEffect:(SoundEffect *)effect
{
	NSSet * keyPaths = [SoundEffect keyPathsForWaveform];
	
	
	for (NSString * keyPath in keyPaths) {
		[mEffect removeObserver:self forKeyPath:keyPath];
	}
	
	[effect retain];
	[mEffect release];
	mEffect = effect;
	
	for (NSString * keyPath in keyPaths) {
		[mEffect addObserver:self forKeyPath:keyPath options:0 context:NULL];
	}
	
	
	[self updateWaveform];
}


- (SoundEffect *)effect
{
	return mEffect;
}




- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateWaveform];
}





- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	
	if (!mData) mData = [[[Synthesizer synthesizer] synthesizeEffect:mEffect] retain];
	unsigned long numSamples = ([mData length] / sizeof(float));
	const float * buffer = (const float *)[mData bytes];
	float maxValue = 0.0;
	
	for (int i = 0; i < numSamples; i++) {
		maxValue = MAX(maxValue, fabs(buffer[i]));
	}
	
	
	
	CGFloat xscale = (self.bounds.size.width / (float)(numSamples));
	CGFloat yscale = (self.bounds.size.height * 0.90) * 0.5 / maxValue;
	CGFloat xoff = 0.0;
	CGFloat yoff = (self.bounds.size.height / 2.0);
	
	NSBezierPath * path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(xoff, yoff)];
	
	for (int i = 0; i < numSamples; i++) {
		float x = (i * 1.0);
		float y = buffer[i];
		[path lineToPoint:NSMakePoint(xoff + x * xscale, yoff + y * yscale)];
	}
	
	[[NSColor greenColor] set];
	[path setLineWidth:1.0];
	[path stroke];
}


@end






@implementation WaveformView (Private)

- (void)updateWaveform
{
	[mData release];
	mData = nil;
	
	[self setNeedsDisplay:YES];
}

@end

