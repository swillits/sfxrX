//
//  SoundEffect.h
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>




extern NSString * SfxFileTypeWav;
extern NSString * SfxFileTypeDocument;


enum {
	SfxSquarewave = 0,
	SfxSawtooth,
	SfxSinewave,
	SfxNoise,
	SfxTriangle,
};


enum {
	SfxPresetPickupCoin	= 0,
	SfxPresetLaserShoot = 1,
	SfxPresetExplosion	= 2,
	SfxPresetPowerup	= 3,
	SfxPresetHitHurt	= 4,
	SfxPresetJump		= 5,
	SfxPresetBlipSelect = 6
};


@interface SoundEffect : NSObject {
	NSString * mName;
	
	int   mWave_type;
	float mSound_vol;
	float mBase_freq;		// Start Frequency
	float mFreq_limit;		// Minimum Frequency
	float mFreq_ramp;		// Slide
	float mFreq_dramp;		// Delta Slide
	float mDuty;			// Square Duty
	float mDuty_ramp;		// Duty Sweep
	float mVib_strength;	// Vibrato Depth
	float mVib_speed;		// Vibrato Speed
	float mVib_delay;		// -- ?? --
	float mEnv_attack;		// Attack time
	float mEnv_sustain;		// Sustain Time
	float mEnv_decay;		// Decay Time
	float mEnv_punch;		// -- ?? --
	BOOL  mFilter_on;		// -- ?? --
	float mLpf_resonance;	// LPF Resonance
	float mLpf_freq;		// LPF Cutoff
	float mLpf_ramp;		// LPF Cutoff Sweep
	float mHpf_freq;		// HPF Cutoff
	float mHpf_ramp;		// HPF Cutoff Sweep
	float mPha_offset;		// Phaser Offset
	float mPha_ramp;		// Phaser Sweep
	float mRepeat_speed;	// Repeat Speed
	float mArp_speed;		// Change Speed
	float mArp_mod;			// Change Amount
}

+ (id)soundEffect;
+ (id)soundEffectFromPreset:(int)preset;
+ (id)soundEffectWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url;
- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)fileType error:(NSError **)error;

- (void)play;

- (void)randomize;
- (void)mutate;
- (void)reset;
- (void)resetFromPreset:(int)preset;

@property (retain) NSString * name;
@property int  wave_type;
@property float sound_vol;
@property float base_freq;
@property float freq_limit;
@property float freq_ramp;
@property float freq_dramp;
@property float duty;
@property float duty_ramp;
@property float vib_strength;
@property float vib_speed;
@property float vib_delay;
@property float env_attack;
@property float env_sustain;
@property float env_decay;
@property float env_punch;
@property BOOL  filter_on;
@property float lpf_resonance;
@property float lpf_freq;
@property float lpf_ramp;
@property float hpf_freq;
@property float hpf_ramp;
@property float pha_offset;
@property float pha_ramp;
@property float repeat_speed;
@property float arp_speed;
@property float arp_mod;

@end
