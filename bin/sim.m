#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <sys/param.h>
#import <signal.h>

#import <readline/readline.h>
#import <readline/history.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>

@interface Delegate : NSObject
@end

static BOOL debug_mode = NO;
static NSTask *gdb_task = nil;
static BOOL debugger_killed_session = NO;
static id current_session = nil;
static NSString *xcode_path = nil;
static NSString *replSocketPath = nil;

static void
terminate_session(void)
{
    static bool terminated = false;
    if (!terminated) {
	// requestEndWithTimeout: must be called only once.
	assert(current_session != nil);
	((void (*)(id, SEL, double))objc_msgSend)(current_session,
	    @selector(requestEndWithTimeout:), 0.0);
	terminated = true;
    }
}

static void
sigterminate(int sig)
{
    terminate_session();
    exit(1);
}

static void
sigforwarder(int sig)
{
    if (gdb_task != nil) {
	kill([gdb_task processIdentifier], sig);
    }
}

@implementation Delegate

- (void)readEvalPrintLoop
{
    [[NSAutoreleasePool alloc] init];

    // Wait until the socket file is created.
    while (true) {
	if ([[NSFileManager defaultManager] fileExistsAtPath:replSocketPath]) {
	    break;
	}
	usleep(500000);
    }

    // Create the socket.
    const int fd = socket(PF_LOCAL, SOCK_STREAM, 0);
    if (fd == -1) {
	perror("socket()");
	terminate_session();
	return;
    }
    fcntl(fd, F_SETFL, O_NONBLOCK);

    // Prepare the name.
    struct sockaddr_un name;
    name.sun_family = PF_LOCAL;
    strncpy(name.sun_path, [replSocketPath fileSystemRepresentation],
	    sizeof(name.sun_path));

    // Connect.
    if (connect(fd, (struct sockaddr *)&name, SUN_LEN(&name)) == -1) {
	perror("connect()");
	terminate_session();
	return;
    }

    rl_readline_name = (char *)"RubyMotionRepl";
    using_history();

    while (true) {
	// Read expression from stdin.
	char *line = readline(">> ");
	if (line == NULL) {
	    terminate_session();
	    break;
	}

	// Trim expression.
	const char *b = line;
	while (isspace(*b)) { b++; }
	const char *e = line + strlen(line);
	while (isspace(*e)) { e--; }
	char buf[1024];
	const size_t line_len = e - b;
	if (line_len == 0) {
	    continue;
	}
	strlcpy(buf, b, line_len + 1);
	buf[line_len] = '\0';	
	add_history(buf);
	free(line);
	line = NULL;

	// Send expression to the simulator.
	if (send(fd, buf, line_len, 0) != line_len) {
	    terminate_session();
	    break;
	}

	// Receive & print the result.
	printf("=> ");
	bool received_something = false;
        while (true) {
	    ssize_t len = recv(fd, buf, sizeof buf, 0);
	    if (len == -1) {
		if (errno == EAGAIN) {
		    if (!received_something) {
			continue;
		    }
		    break;
		}
		perror("error when receiving data from repl socket");
		terminate_session();
		break;
	    }
	    buf[len] = '\0';
	    printf("%s", buf);
	    if (len < sizeof buf) {
		break;
	    }
	    received_something = true;
	}
	printf("\n");
    }	
}

- (void)session:(id)session didEndWithError:(NSError *)error
{
    if (gdb_task != nil) {
	[gdb_task terminate];
	[gdb_task waitUntilExit];
    }

    // In case we are stuck in readline()...
    system("/bin/stty echo");

    if (error == nil || debugger_killed_session) {
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

    if (debug_mode) {
	NSNumber *pidNumber = ((id (*)(id, SEL))objc_msgSend)(session,
		@selector(simulatedApplicationPID));
	if (pidNumber == nil || ![pidNumber isKindOfClass:[NSNumber class]]) {
	    fprintf(stderr, "can't get simulated application PID\n");
	    exit(1);
	}

	// Forward ^C to gdb.
	signal(SIGINT, sigforwarder);

	// Create the gdb commands file (used to 'continue' the process).
	NSString *cmds_path = [NSString pathWithComponents:
	    [NSArray arrayWithObjects:NSTemporaryDirectory(), @"_simgdbcmds",
	    nil]];
	//if (![[NSFileManager defaultManager] fileExistsAtPath:cmds_path]) {
	    NSString *cmds = @"set breakpoint pending on\nbreak rb_exc_raise\nbreak malloc_error_break\n";
	    if (getenv("no_continue") == NULL) {
		cmds = [cmds stringByAppendingString:@"continue\n"];
	    }
	    NSError *error = nil;
	    if (![cmds writeToFile:cmds_path atomically:YES
		    encoding:NSASCIIStringEncoding error:&error]) {
		fprintf(stderr,
			"can't write gdb commands file into path %s: %s\n",
			[cmds_path UTF8String],
			[[error description] UTF8String]);
		exit(1);
	    }
	//}

	// Run the gdb process.
	NSString *gdb_path = [xcode_path stringByAppendingPathComponent:@"Platforms/iPhoneSimulator.platform/Developer/usr/libexec/gdb/gdb-i386-apple-darwin"];
	gdb_task = [[NSTask launchedTaskWithLaunchPath:gdb_path
	    arguments:[NSArray arrayWithObjects:@"--arch", @"i386", @"--pid",
	    [pidNumber description], @"-x", cmds_path, nil]] retain];
	[gdb_task waitUntilExit];
	gdb_task = nil;

	debugger_killed_session = YES;
	((void (*)(id, SEL, NSTimeInterval))objc_msgSend)(session,
	    @selector(requestEndWithTimeout:), 0);
    }
    else {
	[NSThread detachNewThreadSelector:@selector(readEvalPrintLoop) toTarget:self withObject:nil];
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

    if (argc != 6) {
	usage();
    }

    debug_mode = atoi(argv[1]) == 1 ? YES : NO;
    NSNumber *device_family = [NSNumber numberWithInt:atoi(argv[2])];
    NSString *sdk_version = [NSString stringWithUTF8String:argv[3]];
    xcode_path = [[NSString stringWithUTF8String:argv[4]] retain];
    NSString *app_path =
	[NSString stringWithUTF8String:realpath(argv[5], NULL)];

    // Load the framework.
    [[NSBundle bundleWithPath:[xcode_path stringByAppendingPathComponent:@"Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/iPhoneSimulatorRemoteClient.framework"]] load];

    Class AppSpecifier =
	NSClassFromString(@"DTiPhoneSimulatorApplicationSpecifier");
    assert(AppSpecifier != nil);

    Class SystemRoot = NSClassFromString(@"DTiPhoneSimulatorSystemRoot");
    assert(SystemRoot != nil);

    Class SessionConfig = NSClassFromString(@"DTiPhoneSimulatorSessionConfig");
    assert(SessionConfig != nil);

    Class Session = NSClassFromString(@"DTiPhoneSimulatorSession");
    assert(Session != nil);

    // Prepare app environment.
    NSDictionary *appEnvironment = [[NSProcessInfo processInfo] environment];
    if (!debug_mode) {
	// Prepare repl socket path.
	NSString *tmpdir = NSTemporaryDirectory();
	assert(tmpdir != nil);
	char path[PATH_MAX];
	snprintf(path, sizeof path, "%s/rubymotion-repl-XXXXXX",
		[tmpdir fileSystemRepresentation]);
	assert(mktemp(path) != NULL);
	replSocketPath = [[[NSFileManager defaultManager]
	    stringWithFileSystemRepresentation:path length:strlen(path)]
	    retain];
	NSMutableDictionary *newEnv = [appEnvironment mutableCopy];
	[newEnv setObject:replSocketPath forKey:@"REPL_SOCKET_PATH"];

	// Make sure the unix socket path does not exist.
	[[NSFileManager defaultManager] removeItemAtPath:replSocketPath
	    error:nil];

	// Prepare repl dylib path.
	NSString *replPath = nil;
	replPath = [[NSFileManager defaultManager]
	    stringWithFileSystemRepresentation:argv[0] length:strlen(argv[0])];
	replPath = [replPath stringByDeletingLastPathComponent];
	replPath = [replPath stringByDeletingLastPathComponent];
	replPath = [replPath stringByAppendingPathComponent:@"data"];
	replPath = [replPath stringByAppendingPathComponent:sdk_version];
	replPath = [replPath stringByAppendingPathComponent:@"iPhoneSimulator"];
	replPath = [replPath stringByAppendingPathComponent:@"libmacruby-repl.dylib"];
	[newEnv setObject:replPath forKey:@"REPL_DYLIB_PATH"];

	appEnvironment = newEnv;
	[newEnv autorelease];
    }

    //[NSDictionary dictionaryWithObjectsAndKeys:@"/usr/lib/libgmalloc.dylib", @"DYLD_INSERT_LIBRARIES", nil]);

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
       appEnvironment);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(config,
	@selector(setSimulatedApplicationShouldWaitForDebugger:), debug_mode);
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

    if (!debug_mode) {
	// ^C should terminate the request.
	current_session = session;
	signal(SIGINT, sigterminate);
    }

    // Open simulator to the foreground.
    system("/usr/bin/open -a \"iPhone Simulator\"");

    [[NSRunLoop mainRunLoop] run];
    return 0;
}
