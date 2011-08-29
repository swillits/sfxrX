//
//  Controller.m
//  sfxrX
//
//  Created by Seth Willits on 4/23/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "Controller.h"


@implementation Controller

- (IBAction)showPreferences:(id)sender;
{
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront:nil];
}

@end


