#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#import <objc/message.h>
#import <sys/param.h>
#import <signal.h>

#import <readline/readline.h>
#import <readline/history.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>

#include "builtin_debugger_cmds.h"

#define DEVICE_FAMILY_IPHONE 1
#define DEVICE_FAMILY_IPAD   2

#define DEVICE_RETINA_FALSE 0
#define DEVICE_RETINA_TRUE  1
#define DEVICE_RETINA_3_5   2
#define DEVICE_RETINA_4     4

@interface Delegate : NSObject
- (NSString *)replEval:(NSString *)expression;
@end

static bool spec_mode = false;
static int debug_mode = -1;
#define DEBUG_GDB 1
#define DEBUG_REPL 2
#define DEBUG_NOTHING 0

static Delegate *delegate = nil;
static NSMutableArray *app_windows_bounds = nil;
#if defined(SIMULATOR_IOS)
static NSTask *gdb_task = nil;
static id current_session = nil;
static BOOL debugger_killed_session = NO;
static NSString *xcode_path = nil;
static int simulator_retina_type = DEVICE_RETINA_FALSE;
#endif
static NSString *sdk_version = nil;
static NSString *replSocketPath = nil;

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
	encoding:NSUTF8StringEncoding error:&error]) {
	fprintf(stderr, "Cannot save REPL history file to `%s': %s\n",
		[HISTORY_FILE UTF8String], [[error description] UTF8String]);
    }
}

static void
load_repl_history(void)
{
    NSString *data = [NSString stringWithContentsOfFile:HISTORY_FILE
	encoding:NSUTF8StringEncoding error:nil];
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
#if defined(SIMULATOR_IOS)
	// requestEndWithTimeout: must be called only once.
	assert(current_session != nil);
	((void (*)(id, SEL, double))objc_msgSend)(current_session,
	    @selector(requestEndWithTimeout:), 0.0);
#else
	save_repl_history();
#endif
	terminated = true;
    }
}

#if defined(SIMULATOR_IOS)
static void
sigterminate(int sig)
{
    terminate_session();
    exit(0);
}

static void
sigforwarder(int sig)
{
    if (gdb_task != nil) {
	kill([gdb_task processIdentifier], sig);
    }
}
#endif

static void
sigcleanup(int sig)
{
    if (debug_mode == DEBUG_REPL) {
	save_repl_history(); 
    }
    exit(1);
}

#if defined(SIMULATOR_OSX)

static NSTask *osx_task = nil;

static void
sigint_osx(int sig)
{
    if (osx_task != nil) {
	kill([osx_task processIdentifier], sig);
    }
    if (debug_mode == DEBUG_REPL) {
	save_repl_history();
    }
    exit(0);
}

#endif

@implementation Delegate

static int expr_level = 0;

static NSString *
current_repl_prompt(NSString *top_level)
{
    char question = '?';
    if (top_level == nil) {
	static bool first_time = true;
	if (first_time) {
	    top_level = @"main";
	    first_time = false;
	}
	else {
	    top_level = [delegate replEval:@"self"];
	}
	question = '>';
    }

    if ([top_level length] > 30) {
	top_level = [[top_level substringToIndex:30]
	    stringByAppendingString:@"..."];
    }

    NSString *prompt = [NSString stringWithFormat:@"(%@)%c ",
	top_level, question];

    for (int i = 0; i < expr_level; i++) {
	prompt = [prompt stringByAppendingString:@"  "];
    }
    return prompt;
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
refresh_repl_prompt(NSString *top_level, bool clear)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        static int previous_prompt_length = 0;
        rl_set_prompt([current_repl_prompt(top_level) UTF8String]);
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
    });
}

static void
locate_app_windows_bounds(void)
{
    if (app_windows_bounds != nil) {
	return;
    }

    app_windows_bounds = [[NSMutableArray alloc] init];

    CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionAll,
	    kCGNullWindowID);
    NSRect bounds = NSZeroRect;
    bool bounds_ok = false;
#if defined(SIMULATOR_IOS)
    int device_family = DEVICE_FAMILY_IPHONE;
#endif
    for (NSDictionary *dict in (NSArray *)windows) {
#define validate(obj, klass) \
    if (obj == nil || ![obj isKindOfClass:[klass class]]) { \
	continue; \
    }
	id name = [dict objectForKey:@"kCGWindowName"];
	validate(name, NSString);

#if defined(SIMULATOR_IOS)
	static NSArray *patterns = nil;
	if (patterns == nil) {
	    patterns = [[NSArray alloc] initWithObjects:
		[NSString stringWithFormat:@"iPhone - iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPad - iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPad / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone (Retina 3.5-inch) - iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone (Retina 3.5-inch) / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone Retina (3.5-inch) / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone (Retina 4-inch) - iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone (Retina 4-inch) / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPhone Retina (4-inch) / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPad (Retina) - iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPad (Retina) / iOS %@", sdk_version],
		[NSString stringWithFormat:@"iPad Retina / iOS %@", sdk_version],
		nil];
	}

	bool found = false;
	for (NSString *pattern in patterns) {
	    if ([name rangeOfString:pattern].location != NSNotFound) {
		found = true;
		break;
	    }
	}
	if (!found) {
	    continue;
	}
	if ([name rangeOfString:@"Retina"].location != NSNotFound) {
	    simulator_retina_type = DEVICE_RETINA_TRUE;
	    if ([name rangeOfString:@"3.5-inch"].location != NSNotFound) {
		simulator_retina_type = DEVICE_RETINA_3_5;
	    }
	    else if ([name rangeOfString:@"4-inch"].location != NSNotFound) {
		simulator_retina_type = DEVICE_RETINA_4;
	    }
	}
	if ([name rangeOfString:@"iPad"].location != NSNotFound) {
	    device_family = DEVICE_FAMILY_IPAD;
	}

	static bool displayed_mouse_over_message = false;
	if (simulator_retina_type && !displayed_mouse_over_message) {
	    printf("--------------------------------------------------------------------------------\n");
	    printf("For Retina, we need 50 %% window scale for mouse over feature.\n");
	    printf("Please press command + 3 in iOS simulator.\n");
	    printf("--------------------------------------------------------------------------------\n");
	    displayed_mouse_over_message = true;
	}
#else // !SIMULATOR_IOS
	int window_pid = [[dict objectForKey:@"kCGWindowOwnerPID"] intValue];
        if (window_pid != [osx_task processIdentifier]) {
	    continue;
	}
	if ([[dict objectForKey:@"kCGWindowName"]
		isEqualToString:@"__HIGHLIGHT_OVERLAY__"]) {
	    continue;
	}
//NSLog(@"found %@", dict);
#endif

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

#if defined(SIMULATOR_IOS)
	// Inset the main view frame.
	if (device_family == DEVICE_FAMILY_IPHONE) {
	    switch (simulator_retina_type) {
		case DEVICE_RETINA_4:
		    bounds.origin.y += 25;
		    bounds.size.height -= 50;
		    break;

		case DEVICE_RETINA_3_5:
		    bounds.origin.y += 25;
		    bounds.size.height -= 50;
		    break;

		default:
		    if (bounds.size.width < bounds.size.height) {
			bounds.origin.x += 30;
			bounds.size.width -= 60;
			bounds.origin.y += 120;
			bounds.size.height -= 240;
		    }
		    else {
			bounds.origin.x += 120;
			bounds.size.width -= 240;
			bounds.origin.y += 30;
			bounds.size.height -= 60;
		    }
	    }
	}
	else {
	    bounds.origin.y += 25;
	    bounds.size.height -= 50;
	}
#endif

	[app_windows_bounds addObject:[NSValue valueWithRect:bounds]];

#if defined(SIMULATOR_IOS)
	// On iOS there is only one app window (the simulator).
	break;
#endif
    }

    CFRelease(windows);

    if (!bounds_ok) {
#if defined(SIMULATOR_IOS)
	static bool error_printed = false;
	if (!error_printed) {
	    fprintf(stderr,
		    "Cannot locate the Simulator app, mouse over disabled\n");
	    error_printed = true;
	}
#endif
    }
}

#define CONCURRENT_BEGIN dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#define CONCURRENT_END });

static CGEventRef
event_tap_cb(CGEventTapProxy proxy, CGEventType type, CGEventRef event,
    void *ctx)
{
    static bool previousHighlight = false;

    if (!(CGEventGetFlags(event) & kCGEventFlagMaskCommand)) {
CONCURRENT_BEGIN
	if (previousHighlight) {
	    [delegate replEval:[NSString stringWithFormat:
		@"<<MotionReplCaptureView %f,%f,%d", 0.0, 0.0, 0]];
	    previousHighlight = false;
	}
	refresh_repl_prompt(nil, true);
CONCURRENT_END
	if (type == kCGEventLeftMouseDown) {
	    // Reset the simulator app bounds as it may have moved.
	    app_windows_bounds = nil;
	}
	return event;
    }

    __block CGPoint mouseLocation = CGEventGetLocation(event);
    const bool capture = type == kCGEventLeftMouseDown;

CONCURRENT_BEGIN
    locate_app_windows_bounds();
    NSString *res = @"nil";

    bool mouseInBounds = false;
    NSRect bounds = { {0, 0}, {0, 0} };
    if (app_windows_bounds != nil) {
	for (NSValue *val in app_windows_bounds) {
	    bounds = [val rectValue];
	    if (NSPointInRect(mouseLocation, bounds)) {
		mouseInBounds = true;
		break;
	    }
	}
    }

    if (mouseInBounds) {
	// We are over the Simulator.app main view.
	// Inset the mouse location.
	mouseLocation.x -= bounds.origin.x;
	mouseLocation.y -= bounds.origin.y;

	// Send coordinate to the repl.
	previousHighlight = true;
	res = [delegate replEval:[NSString stringWithFormat:
	    @"<<MotionReplCaptureView %f,%f,%d", mouseLocation.x,
	    mouseLocation.y, capture ? 2 : 1]];
    }
    else {
	if (previousHighlight) {
	    res = [delegate replEval:[NSString stringWithFormat:
		@"<<MotionReplCaptureView %f,%f,%d", 0.0, 0.0, 0]];
	    previousHighlight = false;
	}
    }

    if (capture) {
	refresh_repl_prompt(nil, true);
    }
    else {
	refresh_repl_prompt(res, true);
    }
CONCURRENT_END

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
	    &event_tap_cb, NULL);

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

static NSArray *
repl_complete_data(const char *text)
{
    // Determine if we want to complete a method or not.
    size_t len = strlen(text);
    if (len == 0) {
	return NULL;
    }
    bool method = false;
    int i;
    for (i = len - 1; i >= 1; i--) {
	if (text[i] == ' ' || text[i] == '\t') {
	    break;
	}
	else if (text[i] == '.') {
	    method = true;
	    break;
	}
    }

    // Prepare the REPL expression to evaluate.
    char buf[1024];
    strlcpy(buf, "<<MotionReplPreserveLastExpr ", sizeof buf);
    if (method) {
	if (i >= sizeof(buf) - strlen(buf)) {
	    return NULL;
	}
	strncat(buf, text, i);
	strlcat(buf, ".methods", sizeof buf);
    }
    else {
	if (isupper(text[0])) {
	    strlcat(buf, "Object.constants", sizeof buf);
	}
	else if (text[0] == '@') {
	    strlcat(buf, "instance_variables", sizeof buf);
	}
	else {
	    strlcat(buf, "local_variables", sizeof buf);
	}
    }

    // Evaluate the expression.
    NSString *list = [delegate replEval:
	[NSString stringWithUTF8String:buf]];
    if ([list characterAtIndex:0] != '[') {
	// Not an array, likely an exception.
	return NULL;
    }
    // Ignore trailing '[' and ']'.
    list = [list substringWithRange:NSMakeRange(1, [list length] - 2)];

    // Split tokens.
    NSMutableArray *data = [[NSMutableArray alloc] init];
    NSArray *all = [list componentsSeparatedByString:@", "];

    // Prepare first part of completion.
    const char *p = &text[i];
    if (method) {
	p++;
    }
    NSString *last = [NSString stringWithUTF8String:p];
    const size_t last_length = [last length];

    // Filter all tokens based on the first part of completion.
    for (NSString *res in all) {
	size_t res_length = [res length];
	int skip_beg = 1; // Results are symbols, so we skip ':'.
	int skip_end = 0;
	if (res_length < last_length + 1) {
	    continue;
	}
	if ([res characterAtIndex:skip_beg] == '"') {
	    skip_beg++; // Special symbol, :"foo:bar:".
	    skip_end++;
	}
	if (res_length < last_length + skip_beg + skip_end) {
	    continue;
	}
	if (last_length == 0) {
	    if (method && [res characterAtIndex:skip_beg] == '_') {
		// Skip 'private' methods if we are searching for all
		// methods.
		continue;
	    }
	}
	else  {
	    NSString *first = [res substringWithRange:NSMakeRange(skip_beg,
		    last_length)];
	    if (![first isEqualToString:last]) {
		continue;
	    }
	}
	res = [res substringWithRange:NSMakeRange(skip_beg,
		[res length] - skip_beg - skip_end)];
	[data addObject:res];
    }

    // Now prepare the suggested completion result.
    int data_count = [data count];
    if (data_count >= 1) {
	NSString *suggested = nil;
	if (method) {
	    suggested = [NSString stringWithUTF8String:text];
	}
	else if (data_count == 1) {
	    suggested = [data objectAtIndex:0];
	}
	else {
	    int i = 0, low = 100000;
	    while (i < data_count) {
		int si = 0;
		while (true) {
		    if (i + 1 >= data_count) {
			break;
		    }
		    NSString *s1 = [data objectAtIndex:i];
		    NSString *s2 = [data objectAtIndex:i + 1];
		    if (si >= [s1 length] || si >= [s2 length]) {
			break;
		    }
		    if ([s1 characterAtIndex:si] != [s2 characterAtIndex:si]) {
			break;
		    }
		    si++;
		}
		if (low > si) {
		    low = si;
		}
		i++;
	    }
	    suggested = [[data objectAtIndex:0] substringToIndex:low];
	}
	[data insertObject:suggested atIndex:0];
    }

    return [data autorelease];
}

static char **
repl_complete(const char *text, int start, int end)
{
    NSArray *data = repl_complete_data(text);
    if (data == nil) {
	return NULL;
    }
    int data_count = [data count];
    if (data_count == 0) {
	return NULL;
    }
    char **res = (char **)malloc(sizeof(char *) * (data_count + 1));
    for (int i = 0; i < data_count; i++) {
	res[i + 0] = strdup([[data objectAtIndex:i] UTF8String]);
    }
    res[[data count]] = NULL;
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
    rl_attempted_completion_function = repl_complete;
    rl_basic_word_break_characters = strdup(" \t\n`<;|&(");

    NSString *expr = nil;
    while (true) {
	// Read expression from stdin.
	NSString *prompt = current_repl_prompt(nil);
	char *line_cstr = readline([prompt UTF8String]);
	if (line_cstr == NULL) {
	    terminate_session();
	    break;
	}
        NSString *line = [NSString stringWithUTF8String:line_cstr];
	free(line_cstr);
	line_cstr = NULL;
	if ([line length] == 0) {
	    continue;
	}

	// Parse the expression to see if it's complete.
	static NSDictionary *begin_tokens = nil;
	if (begin_tokens == nil) {
	    begin_tokens = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"1", @"class",
		@"1", @"module",
		@"1", @"def",
		@"1", @"begin",
		@"1", @"if",
		@"1", @"unless",
		@"1", @"case",
		@"1", @"while",
		@"1", @"for",
		@"1", @"do",
		nil];
	}
	NSMutableString *parse_data = [line mutableCopy];
	while (true) {
	    NSUInteger i, count;
again:
	    i = 0;
	    count = [parse_data length];
	    for (i = 0; i < count; i++) {
		UniChar c = [parse_data characterAtIndex:i];
		switch (c) {
		    case '\'':
		    case '"':
		    case '/':
		    case '`':
			for (NSUInteger k = i + 1; k < count; k++) {
			    UniChar c2 = [parse_data characterAtIndex:k];
			    if (c2 == '\\') {
				k++;
			    }
			    else if (c2 == c) {
				NSRange range = { i, k - i };
				[parse_data deleteCharactersInRange:range];
				goto again;
			    }
			}
			break;
		}
	    }
	    break;
	}
        NSArray *tokens = [parse_data componentsSeparatedByCharactersInSet:
	    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[parse_data release];
	int old_expr_level = expr_level;
	for (NSString *token in tokens) {
	    if ([begin_tokens objectForKey:token] != nil) {
		expr_level++;
	    }
	    else if ([token isEqualToString:@"end"]) {
		expr_level--;
	    }
	}

        if (expr == nil) {
	    expr = line;
	}
	else {
	    expr = [expr stringByAppendingString:@"\n"];
	    expr = [expr stringByAppendingString:line];
	}

	if (old_expr_level - 1 == expr_level) {
	    printf("\e[1A\r\e[0K%s%s\n",
		    [[prompt substringToIndex:[prompt length] - 2] UTF8String],
		    [line UTF8String]);
	}

        // The expression is not complete yet.
	if (expr_level > 0) {
	    continue;
	}

	// The expression is complete, add to history, eval it and print
	// the result.
	add_history([expr UTF8String]);
	NSString *res = [self replEval:expr];
	if (res == nil) {
	    if ([line compare:@"quit"] == NSOrderedSame
		    || [line compare:@"exit"] == NSOrderedSame) {
		terminate_session();
	    }
	    break;
	}
	printf("=> %s\n", [res UTF8String]);

	expr = nil;
	expr_level = 0;
    }
}

static NSString *
save_debugger_command(NSString *cmds)
{
#if defined(SIMULATOR_IOS)
# define SIMGDBCMDS_BASE	@"_simgdbcmds_ios"
#else
# define SIMGDBCMDS_BASE	@"_simgdbcmds_osx"
#endif
    NSString *cmds_path = [NSString pathWithComponents:
	[NSArray arrayWithObjects:NSTemporaryDirectory(), SIMGDBCMDS_BASE,
	nil]];

    NSError *error = nil;
    if (![cmds writeToFile:cmds_path atomically:YES
	    encoding:NSASCIIStringEncoding error:&error]) {
	fprintf(stderr,
		"can't write gdb commands file into path %s: %s\n",
		[cmds_path UTF8String],
		[[error description] UTF8String]);
	exit(1);
    }
    return cmds_path;
}

static NSString *
gdb_commands_file(void)
{
    NSString *cmds = @""\
		     "set breakpoint pending on\n"\
		     "break rb_exc_raise\n"\
		     "break malloc_error_break\n";
    cmds = [cmds stringByAppendingFormat:@"%s\n", BUILTIN_DEBUGGER_CMDS];
    NSString *user_cmds = [NSString stringWithContentsOfFile:
	@"debugger_cmds" encoding:NSUTF8StringEncoding error:nil];
    if (user_cmds != nil) {
	cmds = [cmds stringByAppendingString:user_cmds];
	cmds = [cmds stringByAppendingString:@"\n"];
    }
    if (getenv("no_continue") == NULL) {
	cmds = [cmds stringByAppendingString:
#if defined(SIMULATOR_IOS)
	    @"continue\n"
#else
	    @"run\n"
#endif
	    ];
    }

    return save_debugger_command(cmds);
}

#if defined(SIMULATOR_IOS)
static NSString *
lldb_commands_file(int pid)
{
    NSString *cmds = [NSString stringWithFormat:@""\
		     "process attach -p %d\n"\
		     "command script import /Library/RubyMotion/lldb/lldb.py\n"\
		     "breakpoint set --name rb_exc_raise\n"\
		     "breakpoint set --name malloc_error_break\n",
		     pid];
    NSString *user_cmds = [NSString stringWithContentsOfFile:
	@"debugger_cmds" encoding:NSUTF8StringEncoding error:nil];
    if (user_cmds != nil) {
	cmds = [cmds stringByAppendingString:user_cmds];
	cmds = [cmds stringByAppendingString:@"\n"];
    }
    if (getenv("no_continue") == NULL) {
	cmds = [cmds stringByAppendingString:
#if defined(SIMULATOR_IOS)
	    @"continue\n"
#else
	    @"run\n"
#endif
	    ];
    }

    return save_debugger_command(cmds);
}
#endif

#if defined(SIMULATOR_IOS)
- (void)session:(id)session didEndWithError:(NSError *)error
{
    if (gdb_task != nil) {
	[gdb_task terminate];
	[gdb_task waitUntilExit];
    }

    if (debug_mode == DEBUG_REPL) {
	save_repl_history();
    }

    if (spec_mode || error == nil || debugger_killed_session) {
	int status = 0;
	NSNumber *pidNumber = ((id (*)(id, SEL))objc_msgSend)(session,
		@selector(simulatedApplicationPID));
	if (pidNumber != nil && [pidNumber isKindOfClass:[NSNumber class]]) {
	    NSString *path = [NSString stringWithFormat:
		@"/tmp/.rubymotion_process_exited.%@",
		     [pidNumber description]];
	    NSString *res = [NSString stringWithContentsOfFile:path
		encoding:NSASCIIStringEncoding error:nil];
	    if (res != nil) {
		status = [res intValue];
	    }
	    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	}
	exit(status);
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

    // Open simulator to the foreground.
    if (!spec_mode) {
	NSArray *ary = [NSRunningApplication runningApplicationsWithBundleIdentifier:
	    @"com.apple.iphonesimulator"];
	if (ary != nil && [ary count] == 1) {
	    [[ary objectAtIndex:0] activateWithOptions:
		NSApplicationActivateIgnoringOtherApps];
	}
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

	// Run the debugger process.
	NSString *gdb_path = [xcode_path stringByAppendingPathComponent:@"Platforms/iPhoneSimulator.platform/Developer/usr/libexec/gdb/gdb-i386-apple-darwin"];
	NSString *lldb_path = [xcode_path stringByAppendingPathComponent:@"Platforms/iPhoneSimulator.platform/Developer/usr/bin/lldb"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:gdb_path]) {
	    gdb_task = [[NSTask launchedTaskWithLaunchPath:gdb_path
		arguments:[NSArray arrayWithObjects:@"--arch", @"i386", @"-q",
		@"--pid", [pidNumber description], @"-x", gdb_commands_file(), nil]] retain];
	}
	else if ([[NSFileManager defaultManager] fileExistsAtPath:lldb_path]) {
	    gdb_task = [[NSTask launchedTaskWithLaunchPath:lldb_path
		arguments:[NSArray arrayWithObjects:@"-a", @"i386",
		@"-s", lldb_commands_file([pidNumber intValue]), nil]] retain];
	}
	else {
	    fprintf(stderr, "can't locate a debugger (gdb `%s' or lldb `%s')\n",
		    [gdb_path UTF8String], [lldb_path UTF8String]);
	    exit(1);
	}
	[gdb_task waitUntilExit];
	gdb_task = nil;

	debugger_killed_session = YES;
	((void (*)(id, SEL, NSTimeInterval))objc_msgSend)(session,
	    @selector(requestEndWithTimeout:), 0);
    }
    else if (debug_mode == DEBUG_REPL) {
	[NSThread detachNewThreadSelector:@selector(readEvalPrintLoop)
	    toTarget:self withObject:nil];
	start_capture(self);
    }

    //fprintf(stderr, "*** simulator session started\n");
}
#endif

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

#if defined(SIMULATOR_IOS)
# define MIN_ARGS 6
#else
# define MIN_ARGS 4
#endif
 
    if (argc < MIN_ARGS) {
	usage();
    }

    spec_mode = getenv("SIM_SPEC_MODE") != NULL;
    int argv_n = 1;
    debug_mode = atoi(argv[argv_n++]);
#if defined(SIMULATOR_IOS)
    NSNumber *device_family = [NSNumber numberWithInt:atoi(argv[argv_n++])];
#endif
    sdk_version = [[NSString stringWithUTF8String:argv[argv_n++]] retain];
#if defined(SIMULATOR_IOS)
    xcode_path = [[NSString stringWithUTF8String:argv[argv_n++]] retain];
#endif
    NSString *app_path =
	[NSString stringWithUTF8String:realpath(argv[argv_n++], NULL)];

    NSMutableArray *app_args = [NSMutableArray new];
    for (unsigned i = MIN_ARGS; i < argc; i++) {
	[app_args addObject:[NSString stringWithUTF8String:argv[i]]];
    }

#if defined(SIMULATOR_IOS)
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
#endif

    // Prepare app environment.
    NSMutableDictionary *appEnvironment = [[[NSProcessInfo processInfo]
	environment] mutableCopy];
    if (debug_mode != DEBUG_NOTHING) {
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
	[appEnvironment setObject:replSocketPath forKey:@"REPL_SOCKET_PATH"];

	// Make sure the unix socket path does not exist.
	[[NSFileManager defaultManager] removeItemAtPath:replSocketPath
	    error:nil];

	// Prepare repl dylib path.
	NSString *replPath = nil;
	replPath = [[NSFileManager defaultManager]
	    stringWithFileSystemRepresentation:argv[0] length:strlen(argv[0])];
	replPath = [replPath stringByDeletingLastPathComponent];
	replPath = [replPath stringByDeletingLastPathComponent];
	replPath = [replPath stringByDeletingLastPathComponent];
	replPath = [replPath stringByAppendingPathComponent:@"data"];
#if defined(SIMULATOR_IOS)
	replPath = [replPath stringByAppendingPathComponent:@"ios"];
#else
	replPath = [replPath stringByAppendingPathComponent:@"osx"];
#endif
	replPath = [replPath stringByAppendingPathComponent:sdk_version];
#if defined(SIMULATOR_IOS)
	replPath = [replPath stringByAppendingPathComponent:@"iPhoneSimulator"];
#else
	replPath = [replPath stringByAppendingPathComponent:@"MacOSX"];
#endif
	replPath = [replPath stringByAppendingPathComponent:@"libmacruby-repl.dylib"];
	[appEnvironment setObject:replPath forKey:@"REPL_DYLIB_PATH"];
    }

    char *malloc_debug_level = NULL;
    if ((malloc_debug_level = getenv("malloc_debug")) != NULL) {
	int level = atoi(malloc_debug_level);
	if (level >= 1) {
	    [appEnvironment setObject:@"1" forKey:@"MallocStackLoggingNoCompact"];
	}
        if (level >= 2) {
	    [appEnvironment setObject:@"/usr/lib/libgmalloc.dylib"
		forKey:@"DYLD_INSERT_LIBRARIES"];
	}
    }

#if defined(SIMULATOR_IOS)
    // Create application specifier.
    id app_spec = ((id (*)(id, SEL, id))objc_msgSend)(AppSpecifier,
	    @selector(specifierWithApplicationPath:), app_path);
    assert(app_spec != nil);

    // Create system root.
    id system_root = ((id (*)(id, SEL, id))objc_msgSend)(SystemRoot,
	    @selector(rootWithSDKVersion:), sdk_version);
    if (system_root == nil) {
	fprintf(stderr, "iOS simulator for %s SDK not found.\n\n",
		[sdk_version UTF8String]);
	exit(1);
    }

    // Create session config.
    id config = [[SessionConfig alloc] init];
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setApplicationToSimulateOnStart:), app_spec);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedApplicationLaunchArgs:), app_args);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
       @selector(setSimulatedApplicationLaunchEnvironment:),
       appEnvironment);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(config,
	@selector(setSimulatedApplicationShouldWaitForDebugger:),
	(debug_mode == DEBUG_GDB || getenv("SIM_WAIT_FOR_DEBUGGER") != NULL));
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedDeviceFamily:), device_family);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setSimulatedSystemRoot:), system_root);
    ((void (*)(id, SEL, id))objc_msgSend)(config,
	@selector(setLocalizedClientName:), @"NYANCAT");

    char path[MAXPATHLEN] = {'\0'};
    const char *stdout_path = getenv("SIM_STDOUT_PATH");
    if (stdout_path == NULL) {
	if (fcntl(STDOUT_FILENO, F_GETPATH, &path) == -1) {
	    printf("*** stdout unavailable, output disabled\n");
	}
	else {
	    stdout_path = path;
	}
    }
    if (stdout_path != NULL) {
	((void (*)(id, SEL, id))objc_msgSend)(config,
	    @selector(setSimulatedApplicationStdOutPath:),
	    [NSString stringWithUTF8String:stdout_path]);
    }

    const char *stderr_path = getenv("SIM_STDERR_PATH");
    if (stderr_path == NULL) {
	if (fcntl(STDERR_FILENO, F_GETPATH, &path) == -1) {
	    printf("*** stderr unavailable, output disabled\n");
	}
	else {
	    stderr_path = path;
	}
    }
    if (stderr_path != NULL) {
	((void (*)(id, SEL, id))objc_msgSend)(config,
	    @selector(setSimulatedApplicationStdErrPath:),
	    [NSString stringWithUTF8String:stderr_path]);
    }

    // Create session.
    id session = [[Session alloc] init];
    delegate = [[Delegate alloc] init];
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

    [[NSRunLoop mainRunLoop] run];

#else // !SIMULATOR_IOS

    if (debug_mode != DEBUG_GDB) {
	signal(SIGINT, sigint_osx);
	signal(SIGPIPE, sigcleanup);

	delegate = [[Delegate alloc] init];
	[NSThread detachNewThreadSelector:@selector(readEvalPrintLoop)
	    toTarget:delegate withObject:nil];

	osx_task = [[NSTask alloc] init];
	[osx_task setEnvironment:appEnvironment];
	[osx_task setLaunchPath:app_path];
	[osx_task setArguments:app_args];
	[osx_task launch];

	// move to the foreground.
	usleep(0.1 * 1000000);
	ProcessSerialNumber psn;
	GetProcessForPID([osx_task processIdentifier], &psn);
	SetFrontProcess(&psn);

	start_capture(delegate);
	[osx_task waitUntilExit];
	int status = [osx_task terminationStatus];
	exit(status);
    }
    else {
	// Run the gdb process.
	// XXX using system(3) as NSTask isn't working well (termios issue).
	char line[1014];
	snprintf(line, sizeof line, "/usr/bin/gdb -x \"%s\" \"%s\"",
		[gdb_commands_file() fileSystemRepresentation],
		[app_path UTF8String]);
	system(line);
#if 0
	// Forward ^C to gdb.
	signal(SIGINT, sigforwarder);

	gdb_task = [[NSTask alloc] init];
	[gdb_task setEnvironment:appEnvironment];
	[gdb_task setLaunchPath:@"/usr/bin/gdb"];
	[gdb_task setArguments:[NSArray arrayWithObjects:@"-x",
	    gdb_commands_file(), app_path, nil]];
	[gdb_task launch];
	[gdb_task waitUntilExit];
	gdb_task = nil;
#endif
    }

#endif

    return 0;
}
