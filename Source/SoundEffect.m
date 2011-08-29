//
//  SoundEffect.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "SoundEffect.h"
#import "AudioController.h"
#import "endian.h"
#import "misc.h"



NSString * SfxFileTypeWav = @"WAV";
NSString * SfxFileTypeDocument = @"sfs";


@implementation SoundEffect

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
	return [NSSet setWithObjects:@"wave_type", @"sound_vol", @"base_freq", @"freq_limit", @"freq_ramp", @"freq_dramp", @"duty", @"duty_ramp",
				@"vib_strength", @"vib_speed", @"vib_delay", @"env_attack", @"env_sustain", @"env_decay", @"env_punch", @"filter_on",
				@"lpf_resonance", @"lpf_freq", @"lpf_ramp", @"hpf_freq", @"hpf_ramp", @"pha_offset", @"pha_ramp", @"repeat_speed", @"arp_speed", @"arp_mod", nil];
}



+ (id)soundEffect;
{
	return [[[[self class] alloc] init] autorelease];
}


+ (id)soundEffectFromPreset:(int)preset;
{
	SoundEffect * effect = [[[[self class] alloc] init] autorelease];
	[effect resetFromPreset:preset];
	return effect;
}


+ (id)soundEffectWithURL:(NSURL *)url;
{
	return [[[[self class] alloc] initWithURL:url] autorelease];
}


- (id)initWithURL:(NSURL *)url;
{
	if (!(self = [self init])) return nil;
	
	
	FILE * file = fopen([[url relativePath] fileSystemRepresentation], "rb");
	if(!file)
		return nil;
	
	int junk;
	int version=0;
	le_read(&version, 1, sizeof(int), file);
	if (version!=100 && version!=101 && version!=102)
		return nil;

	le_read(&mWave_type, 1, sizeof(int), file);

	mSound_vol=0.5f;
	if (version==102) {
        le_readf(&mSound_vol, 1, sizeof(float), file);
    }
	mSound_vol=1.5f;	
    

	le_readf(&mBase_freq, 1, sizeof(float), file);
	le_readf(&mFreq_limit, 1, sizeof(float), file);
	le_readf(&mFreq_ramp, 1, sizeof(float), file);
	if(version>=101) {
        le_readf(&mFreq_dramp, 1, sizeof(float), file);
    }
		
	le_readf(&mDuty, 1, sizeof(float), file);
	le_readf(&mDuty_ramp, 1, sizeof(float), file);

	le_readf(&mVib_strength, 1, sizeof(float), file);
	le_readf(&mVib_speed, 1, sizeof(float), file);
	le_readf(&mVib_delay, 1, sizeof(float), file);

	le_readf(&mEnv_attack, 1, sizeof(float), file);
	le_readf(&mEnv_sustain, 1, sizeof(float), file);
	le_readf(&mEnv_decay, 1, sizeof(float), file);
	le_readf(&mEnv_punch, 1, sizeof(float), file);

    /* 'sizeof(bool)' can't work in the next line; I have to hardcode it to 8 bits. A boolean is 8 bits on i386 and 32 bits on PPC, it seems. -Volt */
	le_read(&junk, 1, 3, file); 
	le_read(&mFilter_on, 1, 1, file);
	
	le_readf(&mLpf_resonance, 1, sizeof(float), file);
	le_readf(&mLpf_freq, 1, sizeof(float), file);
	le_readf(&mLpf_ramp, 1, sizeof(float), file);
	le_readf(&mHpf_freq, 1, sizeof(float), file);
	le_readf(&mHpf_ramp, 1, sizeof(float), file);
	
	le_readf(&mPha_offset, 1, sizeof(float), file);
	le_readf(&mPha_ramp, 1, sizeof(float), file);

	le_readf(&mRepeat_speed, 1, sizeof(float), file);

	if(version>=101)
	{
		le_readf(&mArp_speed, 1, sizeof(float), file);
		le_readf(&mArp_mod, 1, sizeof(float), file);
	}

	fclose(file);
	
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
	return NSCopyObject(self, 0, zone);
}


- (void)dealloc;
{
	[mName release];
	[super dealloc];
}



- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)fileType error:(NSError **)error;
{
	// ------- Wav -----------
	if ([fileType isEqualToString:SfxFileTypeWav]) {
		return [[AudioController sharedInstance] writeSoundEffect:self toFile:path ofType:fileType error:error];
	}
	
	
	
	// ------- Write it as a sfxr sound effect document ----------
	
	FILE * file = fopen([[path stringByExpandingTildeInPath] fileSystemRepresentation], "wb");
	if (!file)
		return NO;

	unsigned int zero = 0;
	int version=102;
	
	le_write(&version, 1, sizeof(int), file);
	le_write(&mWave_type, 1, sizeof(int), file);
	le_writef(&mSound_vol, 1, sizeof(float), file);
	le_writef(&mBase_freq, 1, sizeof(float), file);
	le_writef(&mFreq_limit, 1, sizeof(float), file);
	
	le_writef(&mFreq_ramp, 1, sizeof(float), file);
	le_writef(&mFreq_dramp, 1, sizeof(float), file);
	le_writef(&mDuty, 1, sizeof(float), file);
	le_writef(&mDuty_ramp, 1, sizeof(float), file);
	le_writef(&mVib_strength, 1, sizeof(float), file);
	
	le_writef(&mVib_speed, 1, sizeof(float), file);
	le_writef(&mVib_delay, 1, sizeof(float), file);
	le_writef(&mEnv_attack, 1, sizeof(float), file);
	le_writef(&mEnv_sustain, 1, sizeof(float), file);
	le_writef(&mEnv_decay, 1, sizeof(float), file);
	
	le_writef(&mEnv_punch, 1, sizeof(float), file);
	
	le_write(&zero, 1, 3, file);
	le_write(&mFilter_on, 1, 1, file);
	
	le_writef(&mLpf_resonance, 1, sizeof(float), file);
	le_writef(&mLpf_freq, 1, sizeof(float), file);
	le_writef(&mLpf_ramp, 1, sizeof(float), file);
	le_writef(&mHpf_freq, 1, sizeof(float), file);
	le_writef(&mHpf_ramp, 1, sizeof(float), file);
	
	le_writef(&mPha_offset, 1, sizeof(float), file);
	le_writef(&mPha_ramp, 1, sizeof(float), file);

	le_writef(&mRepeat_speed, 1, sizeof(float), file);

	le_writef(&mArp_speed, 1, sizeof(float), file);
	le_writef(&mArp_mod, 1, sizeof(float), file);

	fclose(file);
	
	return YES;
}


- (void)play;
{
	[[AudioController sharedInstance] playSoundEffect:self];
}






#pragma mark -

- (void)reset;
{
	self.wave_type		= 0;
	self.sound_vol		= 1.5;
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
