//
//  Synthesizer.h
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SoundEffect;


@interface Synthesizer : NSObject {
	SoundEffect * mEffect;
	
	BOOL playing_sample;
	float masterVolume;
}

@property (readwrite, assign) float volume;

+ (Synthesizer *)synthesizer;
- (NSData *)synthesizeEffect:(SoundEffect *)effect;

@end

