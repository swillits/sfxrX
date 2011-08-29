//
//  SFXDocument.m
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import "SFXDocument.h"
#import "SFXAudioPlayer.h"
#import "SFXEffect.h"
#import "WaveformView.h"



@implementation SFXDocument

- (NSString *)windowNibName
{
	return @"SFXDocument";
}


- (void)awakeFromNib
{
	rememberedSoundEffects = [[NSMutableArray alloc] init];
	[[rememberSegmentedControl cell] setEnabled:NO forSegment:1];
	
	[rememberedSoundsTable setTarget:self];
	[rememberedSoundsTable setDoubleAction:@selector(editTemporarySound:)];
	
	[playButton setKeyEquivalent:@" "];
	
	[docWindow center];
	[docWindow makeKeyAndOrderFront:nil];
	
	
	self.volume = 10.0;
	
	
	if (!self.soundEffect) {
		self.soundEffect = [SFXEffect soundEffect];
	} else {
		[waveformView setEffect:self.soundEffect];
	}
}


- (void)dealloc;
{
	[rememberedSoundEffects release];
	[super dealloc];
}





#pragma mark -
#pragma mark File Read Write

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	return [self.soundEffect dataOfType:SfxFileTypeDocument];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	SFXEffect * effect = nil;
	
	
	@try {
		effect = [[[SFXEffect alloc] initWithData:data] autorelease];
	}
	@catch (NSException * e) {
		*outError = nil;
	}
	
	
	self.soundEffect = effect;
	return (effect != nil);
}




#pragma mark -
#pragma mark Properties

@synthesize volume;

- (SFXEffect *)soundEffect;
{
	return mSFXEffect;
}


- (void)setSoundEffect:(SFXEffect *)effect;
{
	if (effect == mSFXEffect) {
		return;
	}
	
	
	if (mSFXEffect) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setSoundEffect:) object:mSFXEffect];
	}
	
	[mSFXEffect autorelease];
	mSFXEffect = [effect retain];
	
	
	[waveformView setEffect:effect];
	[self play:nil];
}





#pragma mark -
#pragma mark Preset Actions

- (IBAction)preset:(id)sender;
{
	[self setSoundEffect:[SFXEffect soundEffectFromPreset:[sender tag]]];
}


- (IBAction)randomize:(id)sender;
{
	SFXEffect * effect = [[self.soundEffect copy] autorelease];
	[effect randomize];
	[self setSoundEffect:effect];
}


- (IBAction)mutate:(id)sender;
{
	[self.soundEffect mutate];
	[self play:nil];
}







#pragma mark -
#pragma mark Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
	SFXEffect * effect = (SFXEffect *)[[rememberedController selectedObjects] lastObject];
	if (effect) [[SFXAudioPlayer sharedInstance] playSoundEffect:effect];
	[[rememberSegmentedControl cell] setEnabled:(effect != nil) forSegment:1];
}


- (void)editTemporarySound:(id)sender;
{
	if ([rememberedSoundsTable clickedRow] != NSNotFound) {
		[self setSoundEffect:[[rememberedController selectedObjects] objectAtIndex:0]];
	}
}




#pragma mark -
#pragma mark Tool Actions

- (IBAction)remember:(id)sender;
{
	if ([rememberSegmentedControl selectedSegment] == 0) {
		if (self.soundEffect) {
			[rememberedController addObject:[[self.soundEffect copy] autorelease]];
		}
	} else {
		[rememberedController remove:nil];
	}
}


- (IBAction)play:(id)sender;
{
	[[SFXAudioPlayer sharedInstance] playSoundEffect:self.soundEffect];
}



- (IBAction)export:(id)sender;
{
	NSSavePanel * panel = [NSSavePanel savePanel];
	[panel beginSheetForDirectory:nil file:[self.soundEffect.name stringByAppendingPathExtension:@"wav"] modalForWindow:docWindow modalDelegate:self
		didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)exportPanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[panel orderOut:nil];
	if (returnCode != NSOKButton) return;
	
	NSData * data = [self.soundEffect dataOfType:SfxFileTypeWav];
	NSError * error = nil;
	
	if (![data writeToURL:[panel URL] options:0 error:&error]) {
		[docWindow presentError:error modalForWindow:docWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}


@end








#pragma mark  
@implementation SFXDocWindowContentView

- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if ([[theEvent characters] isEqual:@" "]) {
		[(SFXDocument *)[[self window] delegate] play:nil];
		return YES;
	}
	
	return NO;
}


@end


