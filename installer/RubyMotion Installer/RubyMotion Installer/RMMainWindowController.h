//
//  RMMainWindowController.h
//  RubyMotion Installer
//
//  Created by lrz on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RMMainWindowController : NSWindowController <NSURLDownloadDelegate>
{
    IBOutlet NSView *view1, *view2, *view3, *view4, *view5;
    IBOutlet NSButton *seeLicenseButton;
    IBOutlet NSTextView *licenseTextView;
    IBOutlet NSTextField *licenseKeyTextField;
    IBOutlet NSTextField *licenseKeyDescriptiveLabel;
    IBOutlet NSProgressIndicator *installProgressIndicator;
    IBOutlet NSTextField *installProgressStatusLabel;
    IBOutlet NSButton *openGettingStartedGuideButton;
    NSString *licenseKey;
    int currentStep;
    NSURL *downloadURL;
    long long expectedDownloadLength;
    long long downloadDataReceived;
    NSString *installerPath;
    bool softwareInstalled;
    NSURLDownload *download;
}

+ (id)open;

- (IBAction)seeLicense:(id)sender;
- (IBAction)contactSupport:(id)sender;
- (IBAction)quitStep:(id)sender;
- (IBAction)nextStep:(id)sender;

@end
