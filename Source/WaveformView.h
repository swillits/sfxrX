//
//  WaveformView.h
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SFXEffect;
@class SFXSampleBuffer;


@interface WaveformView : NSView {
	SFXEffect * mEffect;
	SFXSampleBuffer * mSampleBuffer;
    NSOperationQueue *_waveformImageDrawingQueue;
}
    
@property (nonatomic, strong) NSImage *cachedWaveformImage;
@property (nonatomic, strong) NSOperationQueue *waveformImageDrawingQueue;

@property (readwrite, retain) SFXEffect * effect;

@end
