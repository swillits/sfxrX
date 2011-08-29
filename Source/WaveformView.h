//
//  WaveformView.h
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SoundEffect;


@interface WaveformView : NSView {
	SoundEffect * mEffect;
	NSData * mData;
}

@property (readwrite, retain) SoundEffect * effect;

@end
