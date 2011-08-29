//
//  SFXSynthesizer.h
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SFXEffect;
@class SFXSampleBuffer;


@interface SFXSynthesizer : NSObject {
	SFXEffect * mEffect;
	
	BOOL playing_sample;
	float masterVolume;
}

@property (readwrite, assign) float volume;
@property (readonly) NSUInteger sampleRate;

+ (SFXSynthesizer *)synthesizer;
- (SFXSampleBuffer *)synthesizeEffect:(SFXEffect *)effect;

@end

