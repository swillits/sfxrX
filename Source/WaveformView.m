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

const NSSize kWaveformImageDefaultSize = {.width = 1024.0, .height = 400.0};

@interface WaveformView (Private)
- (void)updateWaveform;
@end



@implementation WaveformView
    
- (NSOperationQueue *)waveformImageDrawingQueue
{
    if (!_waveformImageDrawingQueue)
    {
        _waveformImageDrawingQueue = [NSOperationQueue new];
        _waveformImageDrawingQueue.maxConcurrentOperationCount = 1;
    }
    
    return _waveformImageDrawingQueue;
}


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
	
	if (self.cachedWaveformImage)
    {
        [self.cachedWaveformImage drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}
    
- (void)invalidateCachedWaveformImage
{
    __block NSImage *waveformImage = nil;
    
    [self.waveformImageDrawingQueue cancelAllOperations];
    
    [self.waveformImageDrawingQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        waveformImage = [[NSImage alloc] initWithSize:kWaveformImageDefaultSize];
        
        [waveformImage lockFocus];
        {
            SFXSynthesizer * synth = [SFXSynthesizer synthesizer];
            if (!mSampleBuffer) mSampleBuffer = [[synth synthesizeEffect:mEffect] retain];
            unsigned long numSamples = mSampleBuffer.numberOfSamples;
            const float * buffer = mSampleBuffer.buffer;
            float maxValue = 0.0;
            
            for (int i = 0; i < numSamples; i++) {
                maxValue = MAX(maxValue, fabs(buffer[i]));
            }
            
            CGFloat boundsWidth = kWaveformImageDefaultSize.width;
            CGFloat boundsHeight = kWaveformImageDefaultSize.height;
            
            CGFloat xscale = (boundsWidth / (float)(numSamples));
            CGFloat yscale = (boundsHeight - 40.0) * 0.5 / maxValue;
            CGFloat xoff = 0.0;
            CGFloat yoff = (boundsHeight / 2.0);
            
            NSBezierPath * path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(xoff, yoff)];
            
            for (int i = 0; i < numSamples; i += 8) {
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
            
            float duration = (float)numSamples / (float)[synth sampleRate];
            attrStr = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%0.2f sec", duration] attributes:attribs] autorelease];
            [attrStr drawAtPoint:NSMakePoint(boundsWidth - 4.0 - [attrStr size].width, 2.0)];
        }
        [waveformImage unlockFocus];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cachedWaveformImage = waveformImage;
            [self setNeedsDisplay:YES];
        });
    }]];
}

- (void)updateWaveform
{
	[mSampleBuffer release];
	mSampleBuffer = nil;
	
    [self invalidateCachedWaveformImage];
}

@end

