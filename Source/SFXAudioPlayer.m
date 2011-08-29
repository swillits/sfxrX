//
//  AudioController.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "SFXAudioPlayer.h"
#import "SFXEffect.h"
#import "SFXSampleBuffer.h"
#import "SFXSynthesizer.h"



int AudioCallback(const void *inputBuffer, void *outputBuffer,
	unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void * userData );


@interface SFXAudioPlayer ()
- (void)audioCallbackOutputBuffer:(void *)outputBuffer frameCount:(unsigned long)frameCount;
@end




@implementation SFXAudioPlayer
@synthesize muted = mMuted;


+ (SFXAudioPlayer *)sharedInstance;
{
	static SFXAudioPlayer * sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[SFXAudioPlayer alloc] init];
	}
	return sharedInstance;
}



- (id)init;
{
	if (!(self = [super init])) return nil;
	
	
	Pa_Initialize();
					  
	PaError paerror;
	paerror = Pa_OpenDefaultStream(
				&stream,
				0,			// numInputChannels
				1,			// numOutputChannels
				paFloat32,	// sample format
				44100,		// sample rate
				512,		// samples per buffer
				AudioCallback, // stream callback
				self);		// user data
	Pa_StartStream(stream);
	
	
	mSynthesizer = [[SFXSynthesizer synthesizer] retain];
	
	
	return self;
}



- (void)dealloc;
{
	Pa_CloseStream(&stream);
	[mSampleBuffer release];
	[mSynthesizer release];
	[super dealloc];
}



- (void)playSoundEffect:(SFXEffect *)effect;
{
	@synchronized(self) {
		[mSampleBuffer release];
		mSampleBuffer = [[mSynthesizer synthesizeEffect:effect] retain];
		mNumSamplesPlayed = 0;
	}
}



- (void)stop;
{
	@synchronized(self) {
		[mSampleBuffer autorelease];
		mSampleBuffer = nil;
	}
}




#pragma mark -


int AudioCallback(const void *inputBuffer, void *outputBuffer,
	unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void * userData )
{
	float * fout = (float *)outputBuffer;
	int i = 0;
	
	// Mute for safety
	for (i = 0; i < frameCount; i++) {
		*fout++ = 0.0f;
	}
	
	// Add the sound
	[(SFXAudioPlayer *)userData audioCallbackOutputBuffer:outputBuffer frameCount:frameCount];
	
	return 0;
}



- (void)audioCallbackOutputBuffer:(void *)outputBuffer frameCount:(unsigned long)frameCount;
{
	@synchronized(self) {
		if (mSampleBuffer && !mMuted) {
			NSUInteger numUnplayedSamples = mSampleBuffer.numberOfSamples - mNumSamplesPlayed;
			NSUInteger numFramesToCopy = MIN(frameCount, numUnplayedSamples);
			
			// Copy the unplayed samples into the output buffer
			memcpy(outputBuffer, mSampleBuffer.buffer + mNumSamplesPlayed, sizeof(float) * numFramesToCopy);
			
			// Any remaining unset samples in the output buffer are already zeroed
			// - See AudioCallback()
			
			// Stop if the sound is done
			mNumSamplesPlayed += numFramesToCopy;
			if (mNumSamplesPlayed == mSampleBuffer.numberOfSamples) {
				[mSampleBuffer release];
				mSampleBuffer = nil;
			}
		}
	}
}


@end
