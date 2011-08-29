//
//  Controller.h
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface Controller : NSObject {
	IBOutlet NSWindow * preferencesWindow;
}

- (IBAction)showPreferences:(id)sender;

@end
