//
//  WaveformView.m
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import "WaveformView.h"
#import "SFXSynthesizer.h"
#import "SFXEffect.h"
#import "SFXSampleBuffer.h"




@interface WaveformView (Private)
- (void)updateWaveform;
@end



@implementation WaveformView

- (void)dealloc
{
	[self setEffect:nil];
	[mSampleBuffer release];
	[super dealloc];
}


- (void)setEffect:(SFXEffect *)effect
{
	NSSet * keyPaths = [SFXEffect keyPathsForWaveform];
	
	
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


- (SFXEffect *)effect
{
	return mEffect;
}




- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateWaveform];
}





- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	
	SFXSynthesizer * synth = [SFXSynthesizer synthesizer];
	if (!mSampleBuffer) mSampleBuffer = [[synth synthesizeEffect:mEffect] retain];
	unsigned long numSamples = mSampleBuffer.numberOfSamples;
	const float * buffer = mSampleBuffer.buffer;
	float maxValue = 0.0;
	
	for (int i = 0; i < numSamples; i++) {
		maxValue = MAX(maxValue, fabs(buffer[i]));
	}
	
	
	
	CGFloat xscale = (self.bounds.size.width / (float)(numSamples));
	CGFloat yscale = (self.bounds.size.height - 40.0) * 0.5 / maxValue;
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
	
	
	
	
	NSDictionary * attribs = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont systemFontOfSize:11.0], NSFontAttributeName,
									[NSColor grayColor], NSForegroundColorAttributeName, nil];
	NSAttributedString * attrStr = nil;
	
	
//	attrStr = [[[NSAttributedString alloc] initWithString:@"0.0" attributes:attribs] autorelease];
//	[attrStr drawAtPoint:NSMakePoint(4.0, 2.0)];
	
	
	float duration = (float)numSamples / (float)[synth sampleRate];
	attrStr = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%0.2f sec", duration] attributes:attribs] autorelease];
	[attrStr drawAtPoint:NSMakePoint(self.bounds.size.width - 4.0 - [attrStr size].width, 2.0)];
}


@end






@implementation WaveformView (Private)

- (void)updateWaveform
{
	[mSampleBuffer release];
	mSampleBuffer = nil;
	
	[self setNeedsDisplay:YES];
}

@end

