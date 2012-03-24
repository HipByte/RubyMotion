#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#import <objc/message.h>
#import <sys/param.h>
#import <signal.h>

#import <readline/readline.h>
#import <readline/history.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>

@interface Delegate : NSObject
- (NSString *)replEval:(NSString *)expression;
@end

static int debug_mode = -1;
#define DEBUG_GDB 1
#define DEBUG_REPL 2
#define DEBUG_NOTHING 0

static NSTask *gdb_task = nil;
static BOOL debugger_killed_session = NO;
static id current_session = nil;
static NSString *xcode_path = nil;
static NSString *replSocketPath = nil;

static NSRect simulator_app_bounds = { {0, 0}, {0, 0} };
static int repl_fd = -1;
static NSLock *repl_fd_lock = nil;

#define HISTORY_FILE @".repl_history"

static void
save_repl_history(void)
{
    NSMutableArray *lines = [NSMutableArray array];
    for (int i = 0; i < history_length; i++) {
	HIST_ENTRY *entry = history_get(history_base + i);
	if (entry == NULL) {
	    break;
	}
	[lines addObject:[NSString stringWithUTF8String:entry->line]];
    }
    NSString *data = [lines componentsJoinedByString:@"\n"];
    NSError *error = nil;
    if (![data writeToFile:HISTORY_FILE atomically:YES
	encoding:NSASCIIStringEncoding error:&error]) {
	fprintf(stderr, "Cannot save REPL history file to `%s': %s\n",
		[HISTORY_FILE UTF8String], [[error description] UTF8String]);
    }
}

static void
load_repl_history(void)
{
    NSString *data = [NSString stringWithContentsOfFile:HISTORY_FILE
	encoding:NSASCIIStringEncoding error:nil];
    if (data != nil) {
	NSArray *lines = [data componentsSeparatedByString:@"\n"];
	for (NSString *line in lines) {
	    line = [line stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	    add_history([line UTF8String]);
	}
    }
}

static void
terminate_session(void)
{
    static bool terminated = false;
    if (!terminated) {
	// requestEndWithTimeout: must be called only once.
	dispatch_sync(dispatch_get_main_queue(), ^{
	    assert(current_session != nil);
	    ((void (*)(id, SEL, double))objc_msgSend)(current_session,
	        @selector(requestEndWithTimeout:), 0.0);
	});
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
sigcleanup(int sig)
{
    if (debug_mode == DEBUG_REPL) {
	save_repl_history(); 
    }
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

static void
locate_simulator_app_bounds(void)
{
    if (!CGRectEqualToRect(simulator_app_bounds, CGRectZero)) {
	return;
    }	

    CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionAll,
	    kCGNullWindowID);
    NSRect bounds = NSZeroRect;
    bool bounds_ok = false;
    for (NSDictionary *dict in (NSArray *)windows) {
#define validate(obj, klass) \
    if (obj == nil || ![obj isKindOfClass:[klass class]]) { \
	continue; \
    }
	id name = [dict objectForKey:@"kCGWindowName"];
	validate(name, NSString);
	if (![name hasPrefix:@"iOS Simulator"]) {
	    continue;
	}

	id bounds_dict = [dict objectForKey:@"kCGWindowBounds"];
	validate(bounds_dict, NSDictionary);

	id x = [bounds_dict objectForKey:@"X"];
	id y = [bounds_dict objectForKey:@"Y"];
	id width = [bounds_dict objectForKey:@"Width"];
	id height = [bounds_dict objectForKey:@"Height"];

	validate(x, NSNumber);
	validate(y, NSNumber);
	validate(width, NSNumber);
	validate(height, NSNumber);

	bounds.origin.x = [x intValue];
	bounds.origin.y = [y intValue];
	bounds.size.width = [width intValue];
	bounds.size.height = [height intValue];

#undef validate
	bounds_ok = true;
	break;
    }
    CFRelease(windows);
    if (!bounds_ok) {
	fprintf(stderr,
		"Can't locate the Simulator app, mouse over disabled\n");
	return;
    }

    // Inset the main view frame.
    bounds.origin.x += 30;
    bounds.size.width -= 60;
    bounds.origin.y += 120;
    bounds.size.height -= 240;
    simulator_app_bounds = bounds;
}

static NSString *
current_repl_prompt(id delegate, NSString *top_level)
{
    char question = '?';
    if (top_level == nil) {
	top_level = [delegate replEval:@"self"];
	question = '>';
    }

    if ([top_level length] > 30) {
	top_level = [[top_level substringToIndex:30]
	    stringByAppendingString:@"..."];
    }

    return [NSString stringWithFormat:@"(%@)%c> ",
	   top_level, question];
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
// This readline function is not implemented in Snow Leopard.
// Code copied from http://cvsweb.netbsd.org/bsdweb.cgi/src/lib/libedit/readline.c?only_with_tag=MAIN
#if !defined(RL_PROMPT_START_IGNORE)
# define RL_PROMPT_START_IGNORE  '\1'
#endif
#if !defined(RL_PROMPT_END_IGNORE)
# define RL_PROMPT_END_IGNORE    '\2'
#endif
int
rl_set_prompt(const char *prompt)
{
    char *p;

    if (!prompt)
	prompt = "";
    if (rl_prompt != NULL && strcmp(rl_prompt, prompt) == 0) 
	return 0;
    if (rl_prompt)
	/*el_*/free(rl_prompt);
    rl_prompt = strdup(prompt);
    if (rl_prompt == NULL)
	return -1;

    while ((p = strchr(rl_prompt, RL_PROMPT_END_IGNORE)) != NULL)
	*p = RL_PROMPT_START_IGNORE;

    return 0;
}
#endif

static void
refresh_repl_prompt(id delegate, NSString *top_level, bool clear)
{
    static int previous_prompt_length = 0;
    rl_set_prompt([current_repl_prompt(delegate, top_level) UTF8String]);
    if (clear) {
	putchar('\r');
	for (int i = 0; i < previous_prompt_length; i++) {
	    putchar(' ');
	}
	putchar('\r');
	//printf("\n\033[F\033[J"); // Clear.
	rl_forced_update_display();
    }
    previous_prompt_length = strlen(rl_prompt);
}

static CGEventRef
event_tap_cb(CGEventTapProxy proxy, CGEventType type, CGEventRef event,
    void *ctx)
{
    static bool previousHighlight = false;
    Delegate *delegate = (Delegate *)ctx;

    if (!(CGEventGetFlags(event) & kCGEventFlagMaskCommand)) {
	if (previousHighlight) {
	    [delegate replEval:[NSString stringWithFormat:
		@"<<MotionReplCaptureView %f,%f,%d", 0, 0, 0]];
	    previousHighlight = false;
	}
	refresh_repl_prompt(delegate, nil, true);
	if (type == kCGEventLeftMouseDown) {
	    // Reset the simulator app bounds as it may have moved.
	    simulator_app_bounds = CGRectZero;
	}
	return event;
    }

    locate_simulator_app_bounds();
    CGPoint mouseLocation = CGEventGetLocation(event);
    const bool capture = type == kCGEventLeftMouseDown;
    NSString *res = @"nil";

    if (NSPointInRect(mouseLocation, simulator_app_bounds)) {
	// We are over the Simulator.app main view.
	// Inset the mouse location.
	mouseLocation.x -= simulator_app_bounds.origin.x;
	mouseLocation.y -= simulator_app_bounds.origin.y;

	// Send coordinate to the repl.
	previousHighlight = true;
	res = [delegate replEval:[NSString stringWithFormat:
	    @"<<MotionReplCaptureView %f,%f,%d", mouseLocation.x,
	    mouseLocation.y, capture ? 2 : 1]];
    }
    else {
	if (previousHighlight) {
	    res = [delegate replEval:[NSString stringWithFormat:
		@"<<MotionReplCaptureView %f,%f,%d", 0, 0, 0]];
	    previousHighlight = false;
	}
    }

    if (capture) {
	refresh_repl_prompt(delegate, nil, true);
	return NULL;
    }
    refresh_repl_prompt(delegate, res, true);
    return event;
}

static void
start_capture(id delegate)
{
    // We only want one kind of event at the moment: The mouse has moved
    CGEventMask emask = CGEventMaskBit(kCGEventMouseMoved)
	| CGEventMaskBit(kCGEventLeftMouseDown);

    // Create the Tap
    CFMachPortRef myEventTap = CGEventTapCreate(kCGSessionEventTap,
	    kCGTailAppendEventTap, kCGEventTapOptionListenOnly, emask,
	    &event_tap_cb, delegate);

    // Create a RunLoop Source for it
    CFRunLoopSourceRef eventTapRLSrc = CFMachPortCreateRunLoopSource(
	    kCFAllocatorDefault, myEventTap, 0);

    // Add the source to the current RunLoop
    CFRunLoopAddSource(CFRunLoopGetCurrent(), eventTapRLSrc,
	    kCFRunLoopDefaultMode);
}

static bool
send_string(NSString *string)
{
    const char *line = [string UTF8String];
    const size_t line_len = strlen(line);

    if (send(repl_fd, line, line_len, 0) != line_len) {
	if (errno == EPIPE) {
	    terminate_session();
	}
	else {
	    perror("error when sending data to repl socket");
	}
	return false;
    }
    return true;
}

static NSString *
receive_string(void)
{
    NSMutableString *res = [NSMutableString new];
    bool received_something = false;
    while (true) {
	char buf[1024 + 1];
	ssize_t len = recv(repl_fd, buf, sizeof buf, 0);
	if (len == -1) {
	    if (errno == EAGAIN) {
		if (!received_something) {
		    continue;
		}
		break;
	    }
	    if (errno == EPIPE) {
		terminate_session();
	    }
	    else {
		perror("error when receiving data from repl socket");
	    }
	    [res release];
	    return nil;
	}
	if (len > 0) {
	    buf[len] = '\0';
	    [res appendString:[NSString stringWithUTF8String:buf]];
	    if (len < sizeof buf) {
		break;
	    }
	}
	else {
	    if ([res length] == 0) {
		[res release];
		return nil;
	    }
	}
	received_something = true;
    }
    return [res autorelease];
}

- (NSString *)replEval:(NSString *)expression
{
    if (repl_fd <= 0) {
	return nil;
    }

    if (repl_fd_lock == nil) {
	repl_fd_lock = [NSLock new];
    }

    [repl_fd_lock lock];
    NSString *res = nil;
    if (send_string(expression)) {
	res = receive_string();
    }
    [repl_fd_lock unlock];

    return res;
}

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

    repl_fd = fd;

    rl_readline_name = (char *)"RubyMotionRepl";
    using_history();
    load_repl_history();

    char buf[1024];
    while (true) {
	// Read expression from stdin.
	char *line = readline([current_repl_prompt(self, nil) UTF8String]);
	if (line == NULL) {
	    terminate_session();
	    break;
	}

	// Trim expression.
	const char *b = line;
	while (isspace(*b)) { b++; }
	const char *e = line + strlen(line);
	while (isspace(*e)) { e--; }
	const size_t line_len = e - b;
	if (line_len == 0) {
	    continue;
	}
	strlcpy(buf, b, line_len + 1);
	buf[line_len] = '\0';	
	add_history(buf);
	free(line);
	line = NULL;

	NSString *res = [self replEval:[NSString stringWithUTF8String:buf]];
	if (res == nil) {
	    break;
	}

	printf("=> %s\n", [res UTF8String]);
    }	
}

- (void)session:(id)session didEndWithError:(NSError *)error
{
    if (gdb_task != nil) {
	[gdb_task terminate];
	[gdb_task waitUntilExit];
    }

    if (debug_mode == DEBUG_REPL) {
	save_repl_history();
    }

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

    if (debug_mode == DEBUG_GDB) {
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
    else if (debug_mode == DEBUG_REPL) {
	[NSThread detachNewThreadSelector:@selector(readEvalPrintLoop) toTarget:self withObject:nil];
	start_capture(self);
    }

    //fprintf(stderr, "*** simulator session started\n");
}

@end

static void
usage(void)
{
    system("open http://www.youtube.com/watch?v=1orMXD_Ijbs&feature=fvst");
    exit(1);
}

int
main(int argc, char **argv)
{
    [[NSAutoreleasePool alloc] init];

    if (argc != 6) {
	usage();
    }

    debug_mode = atoi(argv[1]);
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
    if (debug_mode == DEBUG_REPL) {
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
	@selector(setSimulatedApplicationShouldWaitForDebugger:),
	debug_mode == DEBUG_GDB);
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

    if (debug_mode != DEBUG_GDB) {
	// ^C should terminate the request.
	current_session = session;
	signal(SIGINT, sigterminate);
	signal(SIGPIPE, sigcleanup);
    }

    // Open simulator to the foreground.
    system("/usr/bin/open -a \"iPhone Simulator\"");

    [[NSRunLoop mainRunLoop] run];
    return 0;
}
