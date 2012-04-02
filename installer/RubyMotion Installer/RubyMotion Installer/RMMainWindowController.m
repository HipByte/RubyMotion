//
//  RMMainWindowController.m
//  RubyMotion Installer
//
//  Created by lrz on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RMMainWindowController.h"

@implementation RMMainWindowController

+ (id)open
{
    RMMainWindowController *controller = [[RMMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    [controller window];
    return controller;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    currentStep = 1;
    softwareInstalled = false;
}

- (NSView *)viewForStep:(int)step
{
    switch (step) {
        case 1:
            return view1;
        case 2:
            return view2;
        case 3:
            return view3;
        case 4:
            return view4;
        case 5:
            return view5;
    }
    return nil;
}

- (void)contactSupport:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:info@hipbyte.com"]];
}

- (void)quitStep:(id)sender
{
    if (currentStep == 5) {
        if ([openGettingStartedGuideButton state] == NSOnState) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/Library/Motion/doc/Getting Started.html"]];
        }
    }
    [[NSApplication sharedApplication] terminate:sender];
}

static int numberOfShakes = 3;
static float durationOfShake = 0.5f;
static float vigourOfShake = 0.02f;

- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
	int index;
	for (index = 0; index < numberOfShakes; ++index)
	{
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
	}
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    return shakeAnimation;
}

- (void)shakeWindow
{
    [[self window] setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[[self window] frame]] forKey:@"frameOrigin"]];
    [[[self window] animator] setFrameOrigin:[[self window] frame].origin];
}

- (void)licenseKeyInvalid
{
    static int failures = 0;
    failures++;
    if (failures >= 3) {
        [licenseKeyDescriptiveLabel setTextColor:[NSColor redColor]];
    }
    [self shakeWindow];
}

static int
sudoCommand(const char *myToolPath, char **myArguments)
{
    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef = 0;
    
    if (myAuthorizationRef == 0) {
        myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
        if (myStatus != errAuthorizationSuccess) {
            goto DoneWorking;
        }
    }
    
    AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights myRights = {1, &myItems};
    
    myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
    
    if (myStatus != errAuthorizationSuccess) {
        goto DoneWorking;
    }
    
    FILE *myCommunicationsPipe = NULL;
    char myReadBuffer[128];
    
    myFlags = kAuthorizationFlagDefaults;
    myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, (char **)myArguments, &myCommunicationsPipe);
    
    if (myStatus == errAuthorizationSuccess) {
        while (true) {
            int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
            if (bytesRead < 1) {
                goto DoneWorking;
            }
            write (fileno (stdout), myReadBuffer, bytesRead);
        }
    }
    
DoneWorking:
    if (myAuthorizationRef != 0) {
        AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);
    }
    return myStatus;
}

#include <sys/types.h>
#include <sys/stat.h>


- (void)installPackage
{
    assert(installerPath != nil);

    [installProgressStatusLabel setStringValue:@"Installing files..."];
    
    NSString *installerExecPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"installer.sh"];
    
    [@"#!/bin/sh\n\n/usr/sbin/installer -pkg $1 -target / \n/bin/echo $2 > /Library/Motion/license.key \n" writeToFile:installerExecPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    chmod([installerExecPath fileSystemRepresentation], S_IXUSR | S_IXGRP | S_IXOTH);
    
    char *install_args[] = { (char *)[installerPath fileSystemRepresentation], (char *)[licenseKey UTF8String], NULL };
    int err = sudoCommand([installerExecPath fileSystemRepresentation], install_args);
    if (err != 0) {
        [[NSAlert alertWithMessageText:@"Installer Error" defaultButton:@"Quit" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"An error (%d) happened when installing the software on your system. Please launch the installer application again and contact support if the problem still persists.", err] runModal];
        [[NSApplication sharedApplication] terminate:nil];
    }

    softwareInstalled = true;
    [self nextStep:nil];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    [installProgressStatusLabel setStringValue:@"Downloading product..."];
    expectedDownloadLength = [response expectedContentLength];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    downloadDataReceived += length;
    [installProgressIndicator setIndeterminate:NO];
    [installProgressIndicator setDoubleValue:((100.0 / expectedDownloadLength) * downloadDataReceived)];    
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [self installPackage];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    [[NSAlert alertWithError:error] runModal];
}

- (void)nextStep:(id)sender
{
    if (currentStep == 3 && licenseKey == nil) {
        NSString *givenLicenseKey = [licenseKeyTextField stringValue];
        givenLicenseKey = [givenLicenseKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        bool licenseKeyValid = true;
        if ([givenLicenseKey length] == 40) {
            for (int i = 0, count = [givenLicenseKey length]; i < count; i++) {
                UniChar c = [givenLicenseKey characterAtIndex:i];
                c = tolower(c);
                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) {
                    licenseKeyValid = false;
                    break;
                }
            }
        }
        else {
            licenseKeyValid = false;
        }

        if (!licenseKeyValid) {
            [self licenseKeyInvalid];
            return;
        }
        
        
        NSString *post = [NSString stringWithFormat:@"product=rubymotion&current_software_version=0.1&license_key=%@", givenLicenseKey];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];

        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:@"https://secure.rubymotion.com/update_software"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];

        [sender setEnabled:NO];
        [licenseKeyTextField setEnabled:NO];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *error) {

            [sender setEnabled:YES];
            [licenseKeyTextField setEnabled:YES];
            
            NSString *error_msg = nil;
            if (error != nil) {
                error_msg = [error localizedDescription];
            }
            else {
                NSString *response_string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (response_string == nil) {
                    error_msg = @"Server response not properly encoded.";
                }
                else if ([response_string hasPrefix:@"http"]) {
                    [downloadURL release];
                    downloadURL = [NSURL URLWithString:response_string];
                    if (downloadURL == nil) {
                        error_msg = @"Server sent an incorrect download URL";
                    }
                    else {
                        [downloadURL retain];
                        [licenseKey release];
                        licenseKey = [givenLicenseKey copy];
                        [self nextStep:sender];
                    }
                }
                else {
                    error_msg = response_string;
                }
            }
            if (error_msg != nil) {
                [[NSAlert alertWithMessageText:@"License Key Validation Error" defaultButton:@"Okay" alternateButton:@"" otherButton:@"" informativeTextWithFormat:error_msg] runModal];
                [self licenseKeyInvalid];
            }
        }];
        return;
    }
    
    if (currentStep == 4 && !softwareInstalled) {
        assert(downloadURL != nil);
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        if (download != nil) {
            [download cancel];
            [download release];
        }

        [installerPath release];
        installerPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"rubymotion.pkg"] copy];
        [[NSFileManager defaultManager] removeItemAtPath:installerPath error:nil];
        
        expectedDownloadLength = 0;
        downloadDataReceived = 0;

        download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
        [download setDestination:installerPath allowOverwrite:YES];
        return;
    }

    NSView *oldView = [self viewForStep:currentStep];
    NSView *newView = [self viewForStep:currentStep+1];
    if (oldView == nil || newView == nil) {
        return;
    }
    
    currentStep++;

    NSRect oldFrame = [oldView frame];
    NSRect newFrame = [newView frame];
    
    if (newFrame.size.height != oldFrame.size.height) {
        float delta = newFrame.size.height - oldFrame.size.height;
        NSRect windowFrame = [[self window] frame];
        windowFrame.origin.y -= (delta / 2.0);
        windowFrame.size.height += delta;
        [[self window] setFrame:windowFrame display:YES animate:YES];

        newFrame.origin = oldFrame.origin;
        newFrame.size.width = oldFrame.size.width;
    }

    [newView setFrame:newFrame];

    [[[oldView superview] animator] replaceSubview:oldView with:newView];
        
    switch (currentStep) {
        case 1:
            break;
        case 2:
            if (true) {
                NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"eula" ofType:@"rtf"];
                assert(licensePath != nil);
                NSData *data = [NSData dataWithContentsOfFile:licensePath];
                NSAttributedString *licenseString = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:   NULL] autorelease];
                [[licenseTextView textStorage] setAttributedString:licenseString];
            }
            break;
        case 3:
            break;
        case 4:
            [installProgressIndicator startAnimation:nil];
            [installProgressStatusLabel setStringValue:@"Initializing..."];
            [self performSelector:@selector(nextStep:) withObject:nil afterDelay:3];
            break;
        case 5:
            break;
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] terminate:nil];
}

@end
