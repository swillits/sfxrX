//
//  AudioController.h
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "portaudio.h"


@class SoundEffect;
@interface AudioController : NSObject {
	PaStream * stream;
	BOOL mute_stream;
	BOOL playing_sample;
	
	SoundEffect * effect;
}

+ (AudioController *)sharedInstance;
- (BOOL)writeSoundEffect:(SoundEffect *)aSoundEffect toFile:(NSString *)path ofType:(NSString *)fileType error:(NSError **)error;
- (void)playSoundEffect:(SoundEffect *)aSoundEffect;
- (void)stop;


// Private
- (void)audioCallbackOutputBuffer:(void *)outputBuffer frameCount:(unsigned long)frameCount;
- (void)resetSample:(BOOL)restart;
- (void)synthSample:(unsigned long)length outputBuffer:(float *)buffer file:(FILE *)file;
- (void)writeSample:(float)sample toFile:(FILE *)file;

@end
