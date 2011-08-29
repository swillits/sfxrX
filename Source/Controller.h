//
//  Controller.h
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WaveformView;
@class SoundEffect;


@interface Controller : NSWindowController {
	IBOutlet NSWindow * preferencesWindow;
	IBOutlet NSArrayController * rememberedController;
	IBOutlet NSSegmentedControl * rememberSegmentedControl;
	IBOutlet NSButton * playButton;
	IBOutlet NSTableView * rememberedSoundsTable;
	IBOutlet NSDrawer * drawer;
	IBOutlet WaveformView * waveformView;
	
	NSMutableArray * rememberedSoundEffects;
	SoundEffect * currentSoundEffect;
	
	float volume;
}

@property (retain) SoundEffect * currentSoundEffect;
@property float volume;


// General Actions
- (IBAction)showPreferences:(id)sender;

// Preset Actions
- (IBAction)preset:(id)sender;
- (IBAction)randomize:(id)sender;
- (IBAction)mutate:(id)sender;

// Tool Actions
- (IBAction)remember:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)export:(id)sender;

@end
