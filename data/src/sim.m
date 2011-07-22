#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <sys/param.h>

@interface Delegate : NSObject
@end

@implementation Delegate

- (void)session:(id)session didEndWithError:(NSError *)error
{
    if (error == nil) {
	//fprintf(stderr, "*** simulator session ended without error\n");
	exit(0);
    }
    else {
	fprintf(stderr, "*** simulator session ended with error: %s\n",
		[[error description] UTF8String]);
	exit(1);
    }
}

- (void)session:(id)session didStart:(BOOL)flag withError:(NSError *)error
{
    if (!flag || error != nil) {
	fprintf(stderr, "*** simulator session started with error: %s\n",
		[[error description] UTF8String]);
	exit(1);
    }
    //fprintf(stderr, "*** simulator session started\n");
}

@end

static void
usage(void)
{
    system("open http://www.youtube.com/watch?v=QH2-TGUlwu4");
    exit(1);
}

int
main(int argc, char **argv)
{
    [[NSAutoreleasePool alloc] init];

    if (argc != 4) {
	usage();
    }

    NSNumber *device_family = [NSNumber numberWithInt:atoi(argv[1])];
    NSString *sdk_version = [NSString stringWithUTF8String:argv[2]];
    NSString *app_path = [NSString stringWithUTF8String:realpath(argv[3], NULL)];

    [[NSBundle bundleWithPath:@"/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/iPhoneSimulatorRemoteClient.framework"] load];

    Class AppSpecifier =
	NSClassFromString(@"DTiPhoneSimulatorApplicationSpecifier");
    assert(AppSpecifier != nil);

    Class SystemRoot = NSClassFromString(@"DTiPhoneSimulatorSystemRoot");
    assert(SystemRoot != nil);

    Class SessionConfig = NSClassFromString(@"DTiPhoneSimulatorSessionConfig");
    assert(SessionConfig != nil);

    Class Session = NSClassFromString(@"DTiPhoneSimulatorSession");
    assert(Session != nil);

    // Create application specifier.
    id app_spec = ((id (*)(id, SEL, id))objc_msgSend)(AppSpecifier,
	    @selector(specifierWithApplicationPath:), app_path);
    assert(app_spec != nil);

    // Create system root.
    id system_root = ((id (*)(id, SEL, id))objc_msgSend)(SystemRoot,
	    @selector(rootWithSDKVersion:), sdk_version);
    assert(system_root != nil);

    // Create session config.
    id config = [[SessionConfig alloc] init];
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setApplicationToSimulateOnStart:), app_spec);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedApplicationLaunchArgs:), [NSArray array]);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedApplicationLaunchEnvironment:),
	[NSDictionary dictionary]);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(config,
	@selector(setSimulatedApplicationShouldWaitForDebugger:), NO);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedDeviceFamily:), device_family);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedSystemRoot:), system_root);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setLocalizedClientName:), @"NYANCAT");

    char path[MAXPATHLEN];
    fcntl(STDOUT_FILENO, F_GETPATH, &path);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedApplicationStdOutPath:),
	[NSString stringWithUTF8String:path]);

    fcntl(STDERR_FILENO, F_GETPATH, &path);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedApplicationStdErrPath:),
	[NSString stringWithUTF8String:path]);

    // Create session.
    id session = [[Session alloc] init];
    id delegate = [[Delegate alloc] init];
    ((void (*)(id, SEL, id))objc_msgSend)(session, @selector(setDelegate:),
	delegate);

    // Start session.
    NSError *error = nil;
    if (!((BOOL (*)(id, SEL, id, double, id *))objc_msgSend)(session,
		@selector(requestStartWithConfig:timeout:error:), config, 0.0,
		&error)) {
	fprintf(stderr, "*** can't start simulator: %s\n",
		[[error description] UTF8String]);
	exit(1);
    }

    // Open simulator to the foreground.
    system("open -a \"iPhone Simulator\"");

    [[NSRunLoop mainRunLoop] run];
    return 0;
}
