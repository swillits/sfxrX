//
//  SFXSynthesizer.m
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import "SFXSynthesizer.h"
#import "SFXEffect.h"
#import "SFXSampleBuffer.h"



static int phase;
static double fperiod;
static double fmaxperiod;
static double fslide;
static double fdslide;
static int period;
static float square_duty;
static float square_slide;
static int env_stage;
static int env_time;
static int env_length[3];
static float env_vol;
static float fphase;
static float fdphase;
static int iphase;
static float phaser_buffer[1024];
static int ipp;
static float noise_buffer[32];
static float fltp;
static float fltdp;
static float fltw;
static float fltw_d;
static float fltdmp;
static float fltphp;
static float flthp;
static float flthp_d;
static float vib_phase;
static float vib_speed;
static float vib_amp;
static int rep_time;
static int rep_limit;
static int arp_time;
static int arp_limit;
static double arp_mod;

//static int wav_bits=16;
//static int wav_freq=44100;






@interface SFXSynthesizer ()
- (void)resetSample:(BOOL)restart;
- (void)synthSample:(unsigned long)length outputBuffer:(float *)buffer;
@end



@implementation SFXSynthesizer
@synthesize volume = masterVolume;


+ (SFXSynthesizer *)synthesizer;
{
	return [[[[self class] alloc] init] autorelease];
}



- (id)init;
{
	self = [super init];
	
	masterVolume = 0.05;//1.0;
	
	return self;
}



- (NSUInteger)sampleRate
{
	return 44100;
}



- (void)resetSample:(BOOL)restart;
{
	if(!restart)
		phase=0;
		
	fperiod=100.0/(mEffect.base_freq * mEffect.base_freq+0.001);
	period=(int)fperiod;
	fmaxperiod=100.0/(mEffect.freq_limit*mEffect.freq_limit+0.001);
	fslide=1.0-pow((double)mEffect.freq_ramp, 3.0)*0.01;
	fdslide=-pow((double)mEffect.freq_dramp, 3.0)*0.000001;
	square_duty=0.5f-mEffect.duty*0.5f;
	square_slide=-mEffect.duty_ramp*0.00005f;
	if(mEffect.arp_mod>=0.0f)
		arp_mod=1.0-pow((double)mEffect.arp_mod, 2.0)*0.9;
	else
		arp_mod=1.0+pow((double)mEffect.arp_mod, 2.0)*10.0;
	arp_time=0;
	arp_limit=(int)(pow(1.0f-mEffect.arp_speed, 2.0f)*20000+32);
	if(mEffect.arp_speed==1.0f)
		arp_limit=0;
	if(!restart)
	{
		// reset filter
		fltp=0.0f;
		fltdp=0.0f;
		fltw=pow(mEffect.lpf_freq, 3.0f)*0.1f;
		fltw_d=1.0f+mEffect.lpf_ramp*0.0001f;
		fltdmp=5.0f/(1.0f+pow(mEffect.lpf_resonance, 2.0f)*20.0f)*(0.01f+fltw);
		if(fltdmp>0.8f) fltdmp=0.8f;
		fltphp=0.0f;
		flthp=pow(mEffect.hpf_freq, 2.0f)*0.1f;
		flthp_d=1.0+mEffect.hpf_ramp*0.0003f;
		// reset vibrato
		vib_phase=0.0f;
		vib_speed=pow(mEffect.vib_speed, 2.0f)*0.01f;
		vib_amp=mEffect.vib_strength*0.5f;
		// reset envelope
		env_vol=0.0f;
		env_stage=0;
		env_time=0;
		env_length[0]=(int)(mEffect.env_attack  * mEffect.env_attack  * 100000.0f);
		env_length[1]=(int)(mEffect.env_sustain * mEffect.env_sustain * 100000.0f);
		env_length[2]=(int)(mEffect.env_decay   * mEffect.env_decay   * 100000.0f);

		fphase=pow(mEffect.pha_offset, 2.0f)*1020.0f;
		if(mEffect.pha_offset<0.0f) fphase=-fphase;
		fdphase=pow(mEffect.pha_ramp, 2.0f)*1.0f;
		if(mEffect.pha_ramp<0.0f) fdphase=-fdphase;
		iphase=abs((int)fphase);
		ipp=0;
		
		int phaserIndex;
		for(phaserIndex = 0; phaserIndex < 1024; phaserIndex++)
			phaser_buffer[phaserIndex] = 0.0f;
		
		int noiseIndex;
		for(noiseIndex = 0; noiseIndex < 32; noiseIndex++)
			noise_buffer[noiseIndex] = frnd(2.0f)-1.0f;

		rep_time=0;
		rep_limit=(int)(pow(1.0f-mEffect.repeat_speed, 2.0f)*20000+32);
		if(mEffect.repeat_speed==0.0f)
			rep_limit=0;
	}
}




- (void)synthSample:(unsigned long)length outputBuffer:(float *)buffer;
{
	int sampleIndex;
	
	for (sampleIndex = 0; sampleIndex < length; sampleIndex++)
	{
		// Stop synthesizing the sound
		if (!playing_sample) {
			return;
		}
		
		rep_time++;
		if (rep_limit != 0 && rep_time >= rep_limit) {
			rep_time=0;
			[self resetSample:YES];
		}
		
		// frequency envelopes/arpeggios
		arp_time++;
		if(arp_limit!=0 && arp_time>=arp_limit)
		{
			arp_limit=0;
			fperiod*=arp_mod;
		}
		fslide+=fdslide;
		fperiod*=fslide;
		if(fperiod>fmaxperiod)
		{
			fperiod=fmaxperiod;
			if (mEffect.freq_limit > 0.0f) {
				playing_sample = NO;
				usleep(100000);
			}
		}
		float rfperiod=fperiod;
		if(vib_amp>0.0f)
		{
			vib_phase+=vib_speed;
			rfperiod=fperiod*(1.0+sin(vib_phase)*vib_amp);
		}
		period=(int)rfperiod;
		if(period<8) period=8;
		square_duty+=square_slide;
		if(square_duty<0.0f) square_duty=0.0f;
		if(square_duty>0.5f) square_duty=0.5f;		
		// volume envelope
		env_time++;
		if(env_time>env_length[env_stage])
		{
			env_time=0;
			env_stage++;
			if (env_stage==3) {
				playing_sample = NO;
				usleep(100000);
			}
		}
		if(env_stage==0)
			env_vol=(float)env_time/env_length[0];
		if(env_stage==1)
			env_vol=1.0f+pow(1.0f-(float)env_time/env_length[1], 1.0f)*2.0f*mEffect.env_punch;
		if(env_stage==2)
			env_vol=1.0f-(float)env_time/env_length[2];

		// phaser step
		fphase+=fdphase;
		iphase=abs((int)fphase);
		if(iphase>1023) iphase=1023;

		if (flthp_d != 0.0f) {
			flthp *= flthp_d;
			if (flthp<0.00001f) flthp=0.00001f;
			if (flthp>0.1f) flthp=0.1f;
		}
		
		
		
		
		float ssample = 0.0f;
		int superIndex;
		for (superIndex = 0; superIndex < 8; superIndex++) // 8x supersampling
		{
			float sample=0.0f;
			phase++;
			
			if(phase>=period)
			{
//				phase=0;
				phase%=period;
				if (mEffect.wave_type == SfxNoise) {
					int noiseIndex;
					for (noiseIndex = 0; noiseIndex < 32; noiseIndex++)
						noise_buffer[noiseIndex] = frnd(2.0f)-1.0f;
				}
			}
			
			
			// base waveform
			float fp=(float)phase/period;
			switch(mEffect.wave_type)
			{
			case 0: // square
				if(fp < square_duty)
					sample = 0.5f;
				else
					sample =- 0.5f;
				break;
			case 1: // sawtooth
				sample=1.0f-fp*2;
				break;
			case 2: // sine
				sample = (float) sin(fp * 2 * M_PI);
				break;
			case 3: // noise
				sample = noise_buffer[phase*32/period];
				break;
			case 4: // triangle
				if (fp <= 0.25) {
					sample = 4.0 * fp;
				} else if (fp <= 0.5) {
					sample = 1.0 - 4.0 * (fp - 0.25);
				} else if (fp >= 0.75) {
					sample = 4.0 * (fp - 1.0);
				}
				
				break;
			}
			
			
			// lp filter
			float pp=fltp;
			fltw*=fltw_d;
			if(fltw<0.0f) fltw=0.0f;
			if(fltw>0.1f) fltw=0.1f;
			if(mEffect.lpf_freq!=1.0f)
			{
				fltdp+=(sample-fltp)*fltw;
				fltdp-=fltdp*fltdmp;
			}
			else
			{
				fltp=sample;
				fltdp=0.0f;
			}
			fltp+=fltdp;
			// hp filter
			fltphp+=fltp-pp;
			fltphp-=fltphp*flthp;
			sample=fltphp;
			// phaser
			phaser_buffer[ipp&1023]=sample;
			sample+=phaser_buffer[(ipp-iphase+1024)&1023];
			ipp=(ipp+1)&1023;
			// final accumulation and envelope application
			ssample+=sample*env_vol;
		}
		
		
		ssample = ssample / 8 * masterVolume;
		ssample *= 2.0f * mEffect.sound_vol;
	
		
		
		// --------------------------------------
		// WRITE SAMPLE TO BUFFER
		// --------------------------------------
		if (buffer != NULL) {
			if (ssample >  1.0f) ssample =  1.0f;
			if (ssample < -1.0f) ssample = -1.0f;
			*buffer++ = ssample;
		}
	}
}




- (SFXSampleBuffer *)synthesizeEffect:(SFXEffect *)effect;
{
	unsigned long samplesPerIteration = 512;
	unsigned long offset = 0;
	
	size_t bufferSize = sizeof(float) * samplesPerIteration;
	float * buffer = calloc(bufferSize, 1);
	
	
	mEffect = effect;
		
		[self resetSample:NO];
		
		playing_sample = YES;
		while (playing_sample) {
			[self synthSample:samplesPerIteration outputBuffer:buffer + offset];
	
			offset += samplesPerIteration;
			if (playing_sample) {
				bufferSize += samplesPerIteration * sizeof(float);
				buffer = realloc(buffer, bufferSize);
				memset(buffer + offset, 0, samplesPerIteration * sizeof(float));
			}
		}

	mEffect = nil;
	
	
	return [SFXSampleBuffer sampleBufferWithBuffer:buffer numberOfSamples:(bufferSize / sizeof(float))];
}

@end
