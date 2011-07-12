//
//  SCToolStripView.m
//  Screenflick
//
//  Created by Seth Willits on 9/29/07.
//  Copyright 2007 Araelium Group. All rights reserved.
//

#import "SCToolStripView.h"


@implementation SCToolStripView

- (void)drawRect:(NSRect)rect;
{
	[[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] set];
	NSRectFill([self bounds]);
	
	NSGradient * gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
	[gradient drawInRect:NSMakeRect(0.0, [self bounds].size.height - 5.0, [self bounds].size.width, 5.0) angle:90.0];
	[gradient release];
	
	[[NSColor colorWithCalibratedWhite:0.40 alpha:1.0] set];
	NSRectFill(NSMakeRect(0.0, [self bounds].size.height - 1.0, [self bounds].size.width, 1.0));
}

@end
