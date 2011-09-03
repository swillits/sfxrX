//
//  SFXEffect.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "SFXEffect.h"
#import "SFXSynthesizer.h"
#import "SFXSampleBuffer.h"
#import "AGBinaryStream.h"



NSString * SfxFileTypeWav = @"WAV";
NSString * SfxFileTypeDocument = @"sfs";


@implementation SFXEffect

@synthesize name			= mName;
@synthesize wave_type		= mWave_type;
@synthesize sound_vol		= mSound_vol;
@synthesize base_freq		= mBase_freq;
@synthesize freq_limit		= mFreq_limit;
@synthesize freq_ramp		= mFreq_ramp;
@synthesize freq_dramp		= mFreq_dramp;
@synthesize duty			= mDuty;
@synthesize duty_ramp		= mDuty_ramp;
@synthesize vib_strength	= mVib_strength;
@synthesize vib_speed		= mVib_speed;
@synthesize vib_delay		= mVib_delay;
@synthesize env_attack		= mEnv_attack;
@synthesize env_sustain		= mEnv_sustain;
@synthesize env_decay		= mEnv_decay;
@synthesize env_punch		= mEnv_punch;
@synthesize filter_on		= mFilter_on;
@synthesize lpf_resonance	= mLpf_resonance;
@synthesize lpf_freq		= mLpf_freq;
@synthesize lpf_ramp		= mLpf_ramp;
@synthesize hpf_freq		= mHpf_freq;
@synthesize hpf_ramp		= mHpf_ramp;
@synthesize pha_offset		= mPha_offset;
@synthesize pha_ramp		= mPha_ramp;
@synthesize repeat_speed	= mRepeat_speed;
@synthesize arp_speed		= mArp_speed;
@synthesize arp_mod			= mArp_mod;


+ (NSSet *)keyPathsForWaveform;
{
	return [NSSet setWithObjects:@"wave_type", @"base_freq", @"freq_limit", @"freq_ramp", @"freq_dramp", @"duty", @"duty_ramp",
				@"vib_strength", @"vib_speed", @"vib_delay", @"env_attack", @"env_sustain", @"env_decay", @"env_punch", @"filter_on",
				@"lpf_resonance", @"lpf_freq", @"lpf_ramp", @"hpf_freq", @"hpf_ramp", @"pha_offset", @"pha_ramp", @"repeat_speed", @"arp_speed", @"arp_mod", nil];
}



+ (id)soundEffect;
{
	return [[[[self class] alloc] init] autorelease];
}



+ (id)soundEffectFromPreset:(int)preset;
{
	SFXEffect * effect = [[[[self class] alloc] init] autorelease];
	[effect resetFromPreset:preset];
	return effect;
}



- (id)initWithData:(NSData *)data
{
	if (!(self = [self init])) return nil;
	
	
	AGBinaryStream * bs = [[AGBinaryStream alloc] initWithData:data options:(AGBSOptionsRead | AGBSOptionsLittleEndian) error:nil];
	if (!bs) {
		[self release];
		return nil;
	}
	
	
	int version = 0;
	version = [bs readInt32];
	if (version!=100 && version!=101 && version!=102)
		return nil;
	
	mWave_type = [bs readInt32];
	
	
	mSound_vol = 0.5f;
	if (version == 102) {
        mSound_vol = [bs readFloat];
    }
    

	
	mBase_freq		= [bs readFloat];
	mFreq_limit		= [bs readFloat];
	mFreq_ramp		= [bs readFloat];
	
	if (version >= 101) {
        mFreq_dramp = [bs readFloat];
    }
	
	mDuty			= [bs readFloat];
	mDuty_ramp		= [bs readFloat];

	mVib_strength	= [bs readFloat];
	mVib_speed		= [bs readFloat];
	mVib_delay		= [bs readFloat];

	mEnv_attack		= [bs readFloat];
	mEnv_sustain	= [bs readFloat];
	mEnv_decay		= [bs readFloat];
	mEnv_punch		= [bs readFloat];
	
	[bs readUInt8]; // Unused bytes
	[bs readUInt8];
	[bs readUInt8];
	
	mFilter_on		= [bs readBool];
	mLpf_resonance	= [bs readFloat];
	mLpf_freq		= [bs readFloat];
	mLpf_ramp		= [bs readFloat];
	mHpf_freq		= [bs readFloat];
	mHpf_ramp		= [bs readFloat];
	
	mPha_offset		= [bs readFloat];
	mPha_ramp		= [bs readFloat];

	mRepeat_speed	= [bs readFloat];
	
	if (version >= 101) {
		mArp_speed = [bs readFloat];
		mArp_mod = [bs readFloat];
	}
	
	
	return self;
}




- (id)init;
{
	if (!(self = [super init])) return nil;
	mName = [@"Sound Effect" retain];
	[self reset];	
	return self;
}



- (id)copyWithZone:(NSZone *)zone;
{
	SFXEffect * effect = NSCopyObject(self, 0, zone);
	
	// Make sure to properly copy any pointers
	effect->mName = [mName copy];
	
	return effect;
}



- (void)dealloc;
{
	[mName release];
	[super dealloc];
}




- (NSData *)dataOfType:(NSString *)type;
{
	// ----------------------------------------------------
	//   WAV File
	// ----------------------------------------------------
	if ([type isEqualToString:SfxFileTypeWav]) {
		AGBinaryStream * bs = [[[AGBinaryStream alloc] initWithData:nil options:(AGBSOptionsWrite | AGBSOptionsLittleEndian) error:nil] autorelease];
		SFXSampleBuffer * sampleBuffer = [[SFXSynthesizer synthesizer] synthesizeEffect:self];
		const int wav_bits = 16;
		const int wav_freq = 44100;
		uint32_t bytesPerSec = (wav_freq * wav_bits / 8);
		uint16_t blockAlignment = (wav_bits / 8);
		off_t dataChunkSizePosition = 0;
		
		// RIFF chunk
		[bs writeData:"RIFF" length:4];         // RIFF
		[bs writeUInt32:0];                     // remaining file size (total minus 8 bytes)
		[bs writeData:"WAVE" length:4];         // "WAVE"
		
		// fmt chunk
		[bs writeData:"fmt " length:4];         // "fmt "
		[bs writeUInt32:16];                    // chunk size
		[bs writeUInt16:1];                     // compression code
		[bs writeUInt16:1];                     // channels
		[bs writeUInt32:wav_freq];              // sample rate
		[bs writeUInt32:bytesPerSec];           // bytes/sec
		[bs writeUInt16:blockAlignment];        // block align
		[bs writeUInt16:wav_bits];              // bits per sample
		
		// data chunk
		[bs writeData:"data" length:4];         // "data"
		[bs writeUInt32:0];                     // chunk size
		
		dataChunkSizePosition = ([bs position] - 4);
		
		int file_sampleswritten = 0;
		float filesample = 0.0f;
		int fileacc = 0;
		NSUInteger numberOfSamples = sampleBuffer.numberOfSamples;
		for (int i = 0; i < numberOfSamples; i++) {
			float sample = sampleBuffer.buffer[i];
			
			// Volume
			sample *= self.sound_vol;
			
			// quantize depending on format
			// accumulate/count to accomodate variable sample rate?
			
			filesample += sample;
			fileacc++;
			
			if (wav_freq == 44100 || fileacc == 2) {
				filesample/=fileacc;
				fileacc = 0;
				
				if (wav_bits == 16) {
					short isample = (uint16_t)(filesample * 32000);
					[bs writeUInt16:isample];
				} else {
					uint8_t isample = (uint8_t)(filesample * 127 + 128);
					[bs writeUInt8:isample];
				}
				
				filesample = 0.0f;
			}
			
			file_sampleswritten++;
		}
		
		// Go back and write the data chunk size
		[bs setPosition:dataChunkSizePosition];
		[bs writeUInt32:(file_sampleswritten * wav_bits / 8)];
		
		// Go back and write RIFF chunk size
		[bs setPosition:4];
		[bs writeUInt32:[bs length] - 8];
		
		return [bs data];
	}
	
	
	// ----------------------------------------------------
	//   sfxr sound effect document
	// ----------------------------------------------------
	if ([type isEqualToString:SfxFileTypeDocument]) {
		
		
		AGBinaryStream * bs = [[[AGBinaryStream alloc] initWithData:nil options:(AGBSOptionsWrite | AGBSOptionsLittleEndian) error:nil] autorelease];
		int version = 102;
		
		[bs writeUInt32:version];
		[bs writeUInt32:mWave_type];
		[bs writeFloat:mSound_vol];
		[bs writeFloat:mBase_freq];
		[bs writeFloat:mFreq_limit];
		[bs writeFloat:mFreq_ramp];
		[bs writeFloat:mFreq_dramp];
		[bs writeFloat:mDuty];
		[bs writeFloat:mDuty_ramp];
		[bs writeFloat:mVib_strength];
		[bs writeFloat:mVib_speed];
		[bs writeFloat:mVib_delay];
		[bs writeFloat:mEnv_attack];
		[bs writeFloat:mEnv_sustain];
		[bs writeFloat:mEnv_decay];
		[bs writeFloat:mEnv_punch];
		
		[bs writeUInt8:0]; // Unused bytes
		[bs writeUInt8:0];
		[bs writeUInt8:0];
		
		[bs writeBool:mFilter_on];
		[bs writeFloat:mLpf_resonance];
		[bs writeFloat:mLpf_freq];
		[bs writeFloat:mLpf_ramp];
		[bs writeFloat:mHpf_freq];
		[bs writeFloat:mHpf_ramp];
		[bs writeFloat:mPha_offset];
		[bs writeFloat:mPha_ramp];
		[bs writeFloat:mRepeat_speed];
		[bs writeFloat:mArp_speed];
		[bs writeFloat:mArp_mod];
		
		return [bs data];
	}
	
	
	return nil;
}






#pragma mark -

- (void)reset;
{
	self.wave_type		= 0;
	self.sound_vol		= 0.5;
	self.base_freq		= 0.3f;
	self.freq_limit		= 0.0f;
	self.freq_ramp		= 0.0f;
	self.freq_dramp		= 0.0f;
	self.duty			= 0.0f;
	self.duty_ramp		= 0.0f;
	self.vib_strength	= 0.0f;
	self.vib_speed		= 0.0f;
	self.vib_delay		= 0.0f;
	self.env_attack		= 0.0f;
	self.env_sustain	= 0.3f;
	self.env_decay		= 0.4f;
	self.env_punch		= 0.0f;
	self.filter_on		= NO;
	self.lpf_resonance	= 0.0f;
	self.lpf_freq		= 1.0f;
	self.lpf_ramp		= 0.0f;
	self.hpf_freq		= 0.0f;
	self.hpf_ramp		= 0.0f;
	self.pha_offset		= 0.0f;
	self.pha_ramp		= 0.0f;
	self.repeat_speed	= 0.0f;
	self.arp_speed		= 0.0f;
	self.arp_mod		= 0.0f;
}




- (void)resetFromPreset:(int)preset
{
	[self reset];
	
	
	switch (preset) {
	case SfxPresetPickupCoin:
		self.name = @"Pickup";
		self.base_freq=0.4f+frnd(0.5f);
		self.env_attack=0.0f;
		self.env_sustain=frnd(0.1f);
		self.env_decay=0.1f+frnd(0.4f);
		self.env_punch=0.3f+frnd(0.3f);
		if(rnd(1))
		{
			self.arp_speed=0.5f+frnd(0.2f);
			self.arp_mod=0.2f+frnd(0.4f);
		}
		break;
		
		
	case SfxPresetLaserShoot:
		self.name = @"Laser";
		self.wave_type=rnd(2);
		if(self.wave_type==2 && rnd(1))
			self.wave_type=rnd(1);
		self.base_freq=0.5f+frnd(0.5f);
		self.freq_limit = self.base_freq - 0.2f - frnd(0.6f);
		if(self.freq_limit < 0.2f) self.freq_limit = 0.2f;
		self.freq_ramp=-0.15f-frnd(0.2f);
		if(rnd(2)==0)
		{
			self.base_freq=0.3f+frnd(0.6f);
			self.freq_limit=frnd(0.1f);
			self.freq_ramp=-0.35f-frnd(0.3f);
		}
		if(rnd(1))
		{
			self.duty=frnd(0.5f);
			self.duty_ramp=frnd(0.2f);
		}
		else
		{
			self.duty=0.4f+frnd(0.5f);
			self.duty_ramp=-frnd(0.7f);
		}
		self.env_attack=0.0f;
		self.env_sustain=0.1f+frnd(0.2f);
		self.env_decay=frnd(0.4f);
		if(rnd(1))
			self.env_punch=frnd(0.3f);
		if(rnd(2)==0)
		{
			self.pha_offset=frnd(0.2f);
			self.pha_ramp=-frnd(0.2f);
		}
		if(rnd(1))
			self.hpf_freq=frnd(0.3f);
		break;
		
		
	case SfxPresetExplosion:
		self.name = @"Explosion";
		self.wave_type=3;
		if(rnd(1))
		{
			self.base_freq=0.1f+frnd(0.4f);
			self.freq_ramp=-0.1f+frnd(0.4f);
		}
		else
		{
			self.base_freq=0.2f+frnd(0.7f);
			self.freq_ramp=-0.2f-frnd(0.2f);
		}
		self.base_freq *= self.base_freq;
		if(rnd(4)==0)
			self.freq_ramp=0.0f;
		if(rnd(2)==0)
			self.repeat_speed=0.3f+frnd(0.5f);
		self.env_attack=0.0f;
		self.env_sustain=0.1f+frnd(0.3f);
		self.env_decay=frnd(0.5f);
		if(rnd(1)==0)
		{
			self.pha_offset=-0.3f+frnd(0.9f);
			self.pha_ramp=-frnd(0.3f);
		}
		self.env_punch=0.2f+frnd(0.6f);
		if(rnd(1))
		{
			self.vib_strength=frnd(0.7f);
			self.vib_speed=frnd(0.6f);
		}
		if(rnd(2)==0)
		{
			self.arp_speed=0.6f+frnd(0.3f);
			self.arp_mod=0.8f-frnd(1.6f);
		}
		break;
		
		
	case SfxPresetPowerup:
		self.name = @"Powerup";
		if(rnd(1))
			self.wave_type=1;
		else
			self.duty=frnd(0.6f);
		if(rnd(1))
		{
			self.base_freq=0.2f+frnd(0.3f);
			self.freq_ramp=0.1f+frnd(0.4f);
			self.repeat_speed=0.4f+frnd(0.4f);
		}
		else
		{
			self.base_freq=0.2f+frnd(0.3f);
			self.freq_ramp=0.05f+frnd(0.2f);
			if(rnd(1))
			{
				self.vib_strength=frnd(0.7f);
				self.vib_speed=frnd(0.6f);
			}
		}
		self.env_attack=0.0f;
		self.env_sustain=frnd(0.4f);
		self.env_decay=0.1f+frnd(0.4f);
		break;
		
		
	case SfxPresetHitHurt:
		self.name = @"Hit";
		self.wave_type=rnd(2);
		if(self.wave_type==2)
			self.wave_type=3;
		if(self.wave_type==0)
			self.duty = frnd(0.6f);
		self.base_freq   = 0.2f+frnd(0.6f);
		self.freq_ramp   =- 0.3f-frnd(0.4f);
		self.env_attack  = 0.0f;
		self.env_sustain = frnd(0.1f);
		self.env_decay   = 0.1f+frnd(0.2f);
		if(rnd(1))
			self.hpf_freq = frnd(0.3f);
		break;
		
		
	case SfxPresetJump:
		self.name = @"Jump";
		self.wave_type=0;
		self.duty=frnd(0.6f);
		self.base_freq=0.3f+frnd(0.3f);
		self.freq_ramp=0.1f+frnd(0.2f);
		self.env_attack=0.0f;
		self.env_sustain=0.1f+frnd(0.3f);
		self.env_decay=0.1f+frnd(0.2f);
		if(rnd(1))
			self.hpf_freq=frnd(0.3f);
		if(rnd(1))
			self.lpf_freq=1.0f-frnd(0.6f);
		break;
		
		
	case SfxPresetBlipSelect:
		self.name = @"Blip";
		self.wave_type=rnd(1);
		if(self.wave_type==0)
			self.duty=frnd(0.6f);
		self.base_freq=0.2f+frnd(0.4f);
		self.env_attack=0.0f;
		self.env_sustain=0.1f+frnd(0.1f);
		self.env_decay=frnd(0.2f);
		self.hpf_freq=0.1f;
		break;
		
	default:
		break;
	}
}



- (void)mutate;
{
	if(rnd(1)) self.base_freq+=frnd(0.1f)-0.05f;
//	if(rnd(1)) self.freq_limit+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.freq_ramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.freq_dramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.duty+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.duty_ramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.vib_strength+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.vib_speed+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.vib_delay+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.env_attack+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.env_sustain+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.env_decay+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.env_punch+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.lpf_resonance+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.lpf_freq+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.lpf_ramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.hpf_freq+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.hpf_ramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.pha_offset+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.pha_ramp+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.repeat_speed+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.arp_speed+=frnd(0.1f)-0.05f;
	if(rnd(1)) self.arp_mod+=frnd(0.1f)-0.05f;
}



- (void)randomize;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"randomizeChangesWaveType"]) {
		self.wave_type=rnd(3);
	}
	self.base_freq=pow(frnd(2.0f)-1.0f, 2.0f);
	if(rnd(1))
		self.base_freq=pow(frnd(2.0f)-1.0f, 3.0f)+0.5f;
	self.freq_limit=0.0f;
	self.freq_ramp=pow(frnd(2.0f)-1.0f, 5.0f);
	if(self.base_freq>0.7f && self.freq_ramp>0.2f)
		self.freq_ramp=-self.freq_ramp;
	if(self.base_freq<0.2f && self.freq_ramp<-0.05f)
		self.freq_ramp=-self.freq_ramp;
	self.freq_dramp=pow(frnd(2.0f)-1.0f, 3.0f);
	self.duty=frnd(2.0f)-1.0f;
	self.duty_ramp=pow(frnd(2.0f)-1.0f, 3.0f);
	self.vib_strength=pow(frnd(2.0f)-1.0f, 3.0f);
	self.vib_speed=frnd(2.0f)-1.0f;
	self.vib_delay=frnd(2.0f)-1.0f;
	self.env_attack=frnd(2.0f)-1.0f;
	self.env_sustain=frnd(2.0f)-1.0f;
	self.env_decay=frnd(2.0f)-1.0f;
	self.env_punch=pow(frnd(0.8f), 2.0f);
	if(self.env_attack+self.env_sustain+self.env_decay<0.2f)
	{
		self.env_sustain+=0.2f+frnd(0.3f);
		self.env_decay+=0.2f+frnd(0.3f);
	}
	self.lpf_resonance=frnd(2.0f)-1.0f;
	self.lpf_freq=1.0f-pow(frnd(1.0f), 3.0f);
	self.lpf_ramp=pow(frnd(2.0f)-1.0f, 3.0f);
	if(self.lpf_freq<0.1f && self.lpf_ramp<-0.05f)
		self.lpf_ramp=-self.lpf_ramp;
	self.hpf_freq=pow(frnd(1.0f), 5.0f);
	self.hpf_ramp=pow(frnd(2.0f)-1.0f, 5.0f);
	self.pha_offset=pow(frnd(2.0f)-1.0f, 3.0f);
	self.pha_ramp=pow(frnd(2.0f)-1.0f, 3.0f);
	self.repeat_speed=frnd(2.0f)-1.0f;
	self.arp_speed=frnd(2.0f)-1.0f;
	self.arp_mod=frnd(2.0f)-1.0f;
}

@end
