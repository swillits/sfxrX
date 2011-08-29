//
//  AudioController.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "AudioController.h"
#import "SoundEffect.h"
#import "misc.h"
#import "endian.h"


int AudioCallback(const void *inputBuffer, void *outputBuffer,
	unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void * userData );



static float master_vol = 0.05;

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

static int wav_bits=16;
static int wav_freq=44100;

static int file_sampleswritten;
static float filesample=0.0f;
static int fileacc=0;







@implementation AudioController

+ (AudioController *)sharedInstance;
{
	static AudioController * sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[AudioController alloc] init];
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
	
	return self;
}




- (BOOL)writeSoundEffect:(SoundEffect *)aSoundEffect toFile:(NSString *)path ofType:(NSString *)fileType error:(NSError **)error;
{
	FILE * foutput = fopen([[path stringByExpandingTildeInPath] fileSystemRepresentation], "wb");
	if (!foutput)
		return false;
		
	// write wav header
	unsigned int dword=0;
	unsigned short word=0;
    fwrite("RIFF", 4, 1, foutput); // "RIFF"
	dword=0;
	le_write(&dword, 1, 4, foutput); // remaining file size
    fwrite("WAVE", 4, 1, foutput); // "WAVE"

	fwrite("fmt ", 4, 1, foutput); // "fmt "
    dword=16;
	le_write(&dword, 1, 4, foutput); // chunk size
   	word=1;
	le_write(&word, 1, 2, foutput); // compression code
	word=1;
	le_write(&word, 1, 2, foutput); // channels
	dword=wav_freq;
	le_write(&dword, 1, 4, foutput); // sample rate
	dword=wav_freq*wav_bits/8;
	le_write(&dword, 1, 4, foutput); // bytes/sec
	word=wav_bits/8;
	le_write(&word, 1, 2, foutput); // block align
	word=wav_bits;
	le_write(&word, 1, 2, foutput); // bits per sample

	fwrite("data", 4, 1, foutput); // "data"
	dword=0;
	int foutstream_datasize=ftell(foutput);
	le_write(&dword, 1, 4, foutput); // chunk size

	// write sample data
	file_sampleswritten=0;
	filesample=0.0f;
	fileacc=0;
	
	
	[effect autorelease];
	effect = [aSoundEffect retain];
	
	mute_stream = true;
		
		[self resetSample:NO];
		playing_sample = YES;
		
		while (playing_sample) {
			[self synthSample:256 outputBuffer:NULL file:foutput];
		}
		
	mute_stream = false;
	
	
	
	// seek back to header and write size info
	fseek(foutput, 4, SEEK_SET);
	dword=0;
	dword=foutstream_datasize-4+file_sampleswritten*wav_bits/8;
	le_write(&dword, 1, 4, foutput); // remaining file size
	fseek(foutput, foutstream_datasize, SEEK_SET);
	dword=file_sampleswritten*wav_bits/8;
	le_write(&dword, 1, 4, foutput); // chunk size (data)
	fclose(foutput);
	
	return YES;
}



- (void)playSoundEffect:(SoundEffect *)aSoundEffect;
{
	[effect autorelease];
	effect = [aSoundEffect retain];
	
	[self resetSample:NO];
	playing_sample = YES;
}



- (void)stop;
{
	playing_sample = NO;
	[effect autorelease];
	effect = nil;
}




#pragma mark -


int AudioCallback(const void *inputBuffer, void *outputBuffer,
	unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void * userData )
{
	AudioController * controller = (AudioController *)userData;
	float * fout = (float *)outputBuffer;
	int i = 0;
	
	// Mute for safety
	for (i = 0; i < frameCount; i++) {
		*fout++ = 0.0f;
	}
	
	// Add the sound
	[controller audioCallbackOutputBuffer:outputBuffer frameCount:frameCount];
	
	return 0;
}



- (void)audioCallbackOutputBuffer:(void *)outputBuffer frameCount:(unsigned long)frameCount;
{
	float * fout = (float *)outputBuffer;
	
	if (playing_sample && !mute_stream) {
		[self synthSample:frameCount outputBuffer:fout file:NULL];
	}
}




- (void)resetSample:(BOOL)restart;
{
	if(!restart)
		phase=0;
		
	fperiod=100.0/(effect.base_freq * effect.base_freq+0.001);
	period=(int)fperiod;
	fmaxperiod=100.0/(effect.freq_limit*effect.freq_limit+0.001);
	fslide=1.0-pow((double)effect.freq_ramp, 3.0)*0.01;
	fdslide=-pow((double)effect.freq_dramp, 3.0)*0.000001;
	square_duty=0.5f-effect.duty*0.5f;
	square_slide=-effect.duty_ramp*0.00005f;
	if(effect.arp_mod>=0.0f)
		arp_mod=1.0-pow((double)effect.arp_mod, 2.0)*0.9;
	else
		arp_mod=1.0+pow((double)effect.arp_mod, 2.0)*10.0;
	arp_time=0;
	arp_limit=(int)(pow(1.0f-effect.arp_speed, 2.0f)*20000+32);
	if(effect.arp_speed==1.0f)
		arp_limit=0;
	if(!restart)
	{
		// reset filter
		fltp=0.0f;
		fltdp=0.0f;
		fltw=pow(effect.lpf_freq, 3.0f)*0.1f;
		fltw_d=1.0f+effect.lpf_ramp*0.0001f;
		fltdmp=5.0f/(1.0f+pow(effect.lpf_resonance, 2.0f)*20.0f)*(0.01f+fltw);
		if(fltdmp>0.8f) fltdmp=0.8f;
		fltphp=0.0f;
		flthp=pow(effect.hpf_freq, 2.0f)*0.1f;
		flthp_d=1.0+effect.hpf_ramp*0.0003f;
		// reset vibrato
		vib_phase=0.0f;
		vib_speed=pow(effect.vib_speed, 2.0f)*0.01f;
		vib_amp=effect.vib_strength*0.5f;
		// reset envelope
		env_vol=0.0f;
		env_stage=0;
		env_time=0;
		env_length[0]=(int)(effect.env_attack  * effect.env_attack  * 100000.0f);
		env_length[1]=(int)(effect.env_sustain * effect.env_sustain * 100000.0f);
		env_length[2]=(int)(effect.env_decay   * effect.env_decay   * 100000.0f);

		fphase=pow(effect.pha_offset, 2.0f)*1020.0f;
		if(effect.pha_offset<0.0f) fphase=-fphase;
		fdphase=pow(effect.pha_ramp, 2.0f)*1.0f;
		if(effect.pha_ramp<0.0f) fdphase=-fdphase;
		iphase=abs((int)fphase);
		ipp=0;
		
		int phaserIndex;
		for(phaserIndex = 0; phaserIndex < 1024; phaserIndex++)
			phaser_buffer[phaserIndex] = 0.0f;
		
		int noiseIndex;
		for(noiseIndex = 0; noiseIndex < 32; noiseIndex++)
			noise_buffer[noiseIndex] = frnd(2.0f)-1.0f;

		rep_time=0;
		rep_limit=(int)(pow(1.0f-effect.repeat_speed, 2.0f)*20000+32);
		if(effect.repeat_speed==0.0f)
			rep_limit=0;
	}
}




- (void)synthSample:(unsigned long)length outputBuffer:(float *)buffer file:(FILE *)file;
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
			if (effect.freq_limit > 0.0f) {
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
			env_vol=1.0f+pow(1.0f-(float)env_time/env_length[1], 1.0f)*2.0f*effect.env_punch;
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
				if (effect.wave_type == SfxNoise) {
					int noiseIndex;
					for (noiseIndex = 0; noiseIndex < 32; noiseIndex++)
						noise_buffer[noiseIndex] = frnd(2.0f)-1.0f;
				}
			}
			
			
			// base waveform
			float fp=(float)phase/period;
			switch(effect.wave_type)
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
			if(effect.lpf_freq!=1.0f)
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
		ssample=ssample/8*master_vol;

		ssample*=2.0f*effect.sound_vol;
	
		
		
		
		
		// --------------------------------------
		// WRITE SAMPLE TO BUFFER
		// --------------------------------------
		if (buffer != NULL) {
			if (ssample >  1.0f) ssample =  1.0f;
			if (ssample < -1.0f) ssample = -1.0f;
			*buffer++ = ssample;
		}
		
		
		
		// --------------------------------------
		// WRITE SAMPLE TO FILE
		// --------------------------------------
		[self writeSample:ssample toFile:file];
	}
}



- (void)writeSample:(float)sample toFile:(FILE *)file;
{
	if (file == NULL) return;
	
	// quantize depending on format
	// accumulate/count to accomodate variable sample rate?
	sample *= 4.0f; // arbitrary gain to get reasonable output volume...
	if (sample >  1.0f) sample =  1.0f;
	if (sample < -1.0f) sample = -1.0f;
	filesample += sample;
	fileacc++;
	if (wav_freq == 44100 || fileacc == 2) {
		filesample/=fileacc;
		fileacc = 0;
		
		if (wav_bits == 16) {
			short isample=(short)(filesample*32000);
			le_write(&isample, 1, 2, file);
		} else {
			unsigned char isample=(unsigned char)(filesample*127+128);
			le_write(&isample, 1, 1, file);
		}
		
		filesample = 0.0f;
	}
	
	file_sampleswritten++;
}


@end
