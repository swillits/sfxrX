//
//  Controller.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Sparkle/Sparkle.h>
#import "Controller.h"
#import "SoundEffect.h"
#import "portaudio.h"
#import "WaveformView.h"



@implementation Controller

- (void)awakeFromNib;
{
	rememberedSoundEffects = [[NSMutableArray alloc] init];
	[[rememberSegmentedControl cell] setEnabled:NO forSegment:1];
	self.volume = 10.0;
	
	[rememberedSoundsTable setTarget:self];
	[rememberedSoundsTable setDoubleAction:@selector(editTemporarySound:)];
	
	
	[playButton setKeyEquivalent:@" "];
	
	[[self window] center];
	[[self window] makeKeyAndOrderFront:nil];
	
	[self setCurrentSoundEffect:[SoundEffect soundEffect]];
}



- (IBAction)showPreferences:(id)sender;
{
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront:nil];
}






#pragma mark -
#pragma mark Application Delegate

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
{
	SoundEffect * effect = [SoundEffect soundEffectWithURL:[NSURL fileURLWithPath:filename]];
	[self setCurrentSoundEffect:effect];
	return (effect != nil);
}




#pragma mark -
#pragma mark Properties

@synthesize volume;

- (SoundEffect *)currentSoundEffect;
{
	return currentSoundEffect;
}


- (void)setCurrentSoundEffect:(SoundEffect *)effect;
{
	if (effect == currentSoundEffect) {
		return;
	}
	
	
	if (currentSoundEffect) {
		[[[self window] undoManager] registerUndoWithTarget:self selector:@selector(setCurrentSoundEffect:) object:currentSoundEffect];
	}
	
	[self willChangeValueForKey:@"currentSoundEffect"];
		[currentSoundEffect autorelease];
		currentSoundEffect = [effect retain];
	[self didChangeValueForKey:@"currentSoundEffect"];
	
	
	[waveformView setEffect:effect];
	
	[self play:nil];
}





#pragma mark -
#pragma mark Preset Actions

- (IBAction)preset:(id)sender;
{
	[self setCurrentSoundEffect:[SoundEffect soundEffectFromPreset:[sender tag]]];
}


- (IBAction)randomize:(id)sender;
{
	SoundEffect * effect = [[currentSoundEffect copy] autorelease];
	[effect randomize];
	[self setCurrentSoundEffect:effect];
}


- (IBAction)mutate:(id)sender;
{
	[currentSoundEffect mutate];
	[self play:nil];
}







#pragma mark -
#pragma mark Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
	if ([[rememberedController selectedObjects] count] > 0) {
		[(SoundEffect *)[[rememberedController selectedObjects] objectAtIndex:0] play];
		[[rememberSegmentedControl cell] setEnabled:YES forSegment:1];
	} else {
		[[rememberSegmentedControl cell] setEnabled:NO forSegment:1];
	}
}


- (void)editTemporarySound:(id)sender;
{
	if ([rememberedSoundsTable clickedRow] != NSNotFound) {
		[self setCurrentSoundEffect:[[rememberedController selectedObjects] objectAtIndex:0]];
	}
}




#pragma mark -
#pragma mark Tool Actions

- (IBAction)remember:(id)sender;
{
	if ([rememberSegmentedControl selectedSegment] == 0) {
		if (currentSoundEffect) {
			[rememberedController addObject:currentSoundEffect];
		}
	} else {
		[rememberedController remove:nil];
	}
}


- (IBAction)play:(id)sender;
{
	[currentSoundEffect play];
}


- (IBAction)open:(id)sender;
{
	NSOpenPanel * panel = [NSOpenPanel openPanel];
	[panel beginSheetForDirectory:nil file:nil modalForWindow:[self window] modalDelegate:self
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)openPanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[panel orderOut:nil];
	if (returnCode != NSOKButton) return;
	
	[self setCurrentSoundEffect:[SoundEffect soundEffectWithURL:[NSURL fileURLWithPath:[panel filename]]]];
}


- (IBAction)save:(id)sender;
{
	NSSavePanel * panel = [NSSavePanel savePanel];
	[panel beginSheetForDirectory:nil file:[currentSoundEffect.name stringByAppendingPathExtension:@"sfs"] modalForWindow:[self window] modalDelegate:self
		didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)savePanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[panel orderOut:nil];
	if (returnCode != NSOKButton) return;
	
	NSError * error = nil;
	if (![currentSoundEffect writeToFile:[panel filename] ofType:SfxFileTypeDocument error:&error]) {
		[[self window] presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}


- (IBAction)export:(id)sender;
{
	NSSavePanel * panel = [NSSavePanel savePanel];
	[panel beginSheetForDirectory:nil file:[currentSoundEffect.name stringByAppendingPathExtension:@"wav"] modalForWindow:[self window] modalDelegate:self
		didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)exportPanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[panel orderOut:nil];
	if (returnCode != NSOKButton) return;
	
	NSError * error = nil;
	if (![currentSoundEffect writeToFile:[panel filename] ofType:SfxFileTypeWav error:&error]) {
		[[self window] presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}


@end


