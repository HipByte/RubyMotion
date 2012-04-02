//
//  RMAppDelegate.m
//  RubyMotion Installer
//
//  Created by lrz on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RMAppDelegate.h"
#import "RMMainWindowController.h"

@implementation RMAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [RMMainWindowController open];
}

@end
