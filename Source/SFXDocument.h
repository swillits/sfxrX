//
//  SFXDocument.h
//  sfxrX
//
//  Created by Seth Willits on 8/28/11.
//  Copyright 2011 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SFXEffect;
@class WaveformView;


@interface SFXDocument : NSDocument {
	IBOutlet NSWindow * docWindow;
	IBOutlet NSArrayController * rememberedController;
	IBOutlet NSSegmentedControl * rememberSegmentedControl;
	IBOutlet NSButton * playButton;
	IBOutlet NSTableView * rememberedSoundsTable;
	IBOutlet NSDrawer * drawer;
	IBOutlet WaveformView * waveformView;
	
	NSMutableArray * rememberedSoundEffects;
	SFXEffect * mSFXEffect;
	
	float volume;
}

@property (readwrite, retain) SFXEffect * soundEffect;
@property (readwrite) float volume;


// Preset Actions
- (IBAction)preset:(id)sender;
- (IBAction)randomize:(id)sender;
- (IBAction)mutate:(id)sender;

// Tool Actions
- (IBAction)remember:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)export:(id)sender;


@end




@interface SFXDocWindowContentView : NSView { }
@end

