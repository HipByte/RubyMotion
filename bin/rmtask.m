@interface RMTask : NSObject
@property (strong) NSDictionary *environment;
@property (strong) NSArray *arguments;
@property (strong) NSString *launchPath;
@property (assign) pid_t pid;
@property (assign) int terminationStatus;
@end

@implementation RMTask

+ (instancetype)launchedTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;
{
    RMTask *task = [self new];
    task.launchPath = path;
    task.arguments = arguments;
    [task launch];
    return [task autorelease];
}

- (void)dealloc;
{
    [_environment release]; _environment = nil;
    [_arguments release]; _arguments = nil;
    [_launchPath release]; _launchPath = nil;
    [super dealloc];
}

- (void)launch;
{
    // NSLog(@"LAUNCH: %@ - %@ - %@", self.launchPath, self.arguments, self.environment);
    NSParameterAssert(self.launchPath);
    NSDictionary *env = self.environment;
    const char *cpath = [self.launchPath UTF8String];
    const char *cargs[self.arguments.count + 1];
    size_t i = 0;
    for (NSString *arg in self.arguments) {
	cargs[i++] = [arg UTF8String];
    }
    cargs[i] = NULL;
    pid_t pid = fork();
    if (pid == -1) {
	assert(false && "failed to spawn process");
    }
    else if (pid == 0) {
	for (NSString *name in env) {
	    setenv([name UTF8String], [env[name] UTF8String], 1);
	}
	execvp(cpath, (char **)cargs);
	assert(false && "failed to exec process");
    }
    else {
	self.pid = pid;
    }
}

- (void)terminate;
{
    kill(self.pid, SIGTERM);
}

- (void)waitUntilExit;
{
    pid_t result = 0;
    while (result >= 0 && errno != EINTR) {
	result = waitpid(self.pid, NULL, 0);
    }
    self.terminationStatus = (int)result;
}

- (int)processIdentifier;
{
    return (int)self.pid;
}

@end
