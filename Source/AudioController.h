//
//  AudioController.h
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "portaudio.h"
@class SFXEffect;
@class SFXSynthesizer;
@class SFXSampleBuffer;


@interface AudioController : NSObject {
	PaStream * stream;
	BOOL mMute;
	
	SFXSynthesizer * mSynthesizer;
	
	SFXSampleBuffer * mSampleBuffer;
	NSUInteger mNumSamplesPlayed;
}

@property (readwrite) BOOL mute;

+ (AudioController *)sharedInstance;
- (void)playSFXEffect:(SFXEffect *)aSFXEffect;
- (void)stop;

@end
