// My env seems hosed, because I can only build when specifying an explicit SDKROOT:
//
//  $ clang -isysroot path/to/MacOSX10.9.sdk -ObjC -fobjc-arc -framework Foundation -g watch-sim.m
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// CoreSimulator

@interface SimDeviceSet : NSObject
+ (instancetype)defaultSet;
- (NSArray *)devices;
@end

@interface SimDevice : NSObject
- (NSString *)name;
@end

// DVTFoundation

@interface DVTFilePath : NSObject
+ (instancetype)filePathForPathString:(NSString *)path;
@end

@interface DVTFuture : NSObject
- (long long)waitUntilFinished;
- (id)error;
@end

@interface DVTXPCServiceInformation : NSObject // Real superclass: DVTProcessInformation
- (instancetype)initWithServiceName:(NSString *)extensionBundleID
                                pid:(int)pid
                          parentPID:(int)parentPID;
- (void)setStartSuspended:(BOOL)flag;
- (void)setFullPath:(NSString *)path;
- (void)setEnvironment:(NSDictionary *)environment;
@end

// DTXConnectionServices

@protocol XCDTMobileIS_XPCDebuggingProcotol;

@interface DTXChannel : NSObject
// Normally defined as `DTXAllowedRPC`, but because it actually has to be a protocol that itself
// conforms to `DTXAllowedRPC`. I'm defining it as `XCDTMobileIS_XPCDebuggingProcotol` which is what
// `DVTiPhoneSimulator` implements.
//
- (void)setDispatchTarget:(id <XCDTMobileIS_XPCDebuggingProcotol>)target;
@end

// IDEFoundation

// There is no option for ‘interface’ launch mode, the key should simply be omitted completely, in
// which case it will be the default way the application is launched.
//
NSString * const kIDEWatchLaunchModeKey = @"IDEWatchLaunchMode";
NSString * const kIDEWatchLaunchModeGlance = @"IDEWatchLaunchMode-Glance";
NSString * const kIDEWatchLaunchModeNotification = @"IDEWatchLaunchMode-Notification";
NSString * const kIDEWatchNotificationPayloadKey = @"IDEWatchNotificationPayload";

// IDEiOSSupportCore

@interface DVTiPhoneSimulator : NSObject // Real superclass: DVTAbstractiOSDevice
+ (instancetype)simulatorWithDevice:(SimDevice *)device;
- (DVTFuture *)installApplicationAtPath:(DVTFilePath *)path;
- (void)debugXPCServices:(NSArray *)services;
- (DTXChannel *)xpcAttachServiceChannel;
- (SimDevice *)device;

// Actually defined in DVTDevice, so probably works on a physical device as
// well.
- (void)terminateWatchAppForCompanionIdentifier:(NSString *)ID options:(NSDictionary *)options;
- (void)launchWatchAppForCompanionIdentifier:(NSString *)ID options:(NSDictionary *)options;
@end

@protocol DTXAllowedRPC <NSObject>
@end

@protocol XCDTMobileIS_XPCDebuggingProcotol <DTXAllowedRPC>
- (void)outputReceived:(NSString *)output fromProcess:(int)pid atTime:(unsigned long long)time;
- (void)xpcServiceObserved:(NSString *)observedServiceID
     withProcessIdentifier:(int)pid
        requestedByProcess:(int)parentPID
                   options:(NSDictionary *)options;
@end

// Imported classes

static Class SimDeviceSetClass = nil;
static Class SimDeviceClass = nil;
static Class DVTFilePathClass = nil;
static Class DVTXPCServiceInformationClass = nil;
static Class DVTiPhoneSimulatorClass = nil;
static Class DTXChannelClass = nil;

static void
init_imported_classes(void) {
  void *CoreSimulator = dlopen("/Applications/Xcode-Beta.app/Contents/Developer/Library/" \
                               "PrivateFrameworks/CoreSimulator.framework/CoreSimulator", RTLD_NOW);
  assert(CoreSimulator != NULL);
  SimDeviceSetClass = objc_getClass("SimDeviceSet");
  assert(SimDeviceSetClass != nil);
  SimDeviceClass = objc_getClass("SimDevice");
  assert(SimDeviceClass != nil);

  void *DVTFoundation = dlopen("/Applications/Xcode-Beta.app/Contents/SharedFrameworks/" \
                               "DVTFoundation.framework/Versions/A/DVTFoundation", RTLD_NOW);
  assert(DVTFoundation != NULL);
  DVTFilePathClass = objc_getClass("DVTFilePath");
  assert(DVTFilePathClass != nil);
  DVTXPCServiceInformationClass = objc_getClass("DVTXPCServiceInformation");
  assert(DVTXPCServiceInformationClass != nil);

  void *DevToolsCore = dlopen("/Applications/Xcode-Beta.app/Contents/OtherFrameworks/" \
                              "DevToolsCore.framework/DevToolsCore", RTLD_NOW);
  assert(DevToolsCore != NULL);
  void *IDEiOSSupportCore = dlopen("/Applications/Xcode-Beta.app/Contents/PlugIns/" \
                                   "IDEiOSSupportCore.ideplugin/Contents/MacOS/IDEiOSSupportCore",
                                   RTLD_NOW);
  assert(IDEiOSSupportCore != NULL);
  DVTiPhoneSimulatorClass = objc_getClass("DVTiPhoneSimulator");
  assert(DVTiPhoneSimulatorClass != nil);

  void *DTXConnectionServices = dlopen("/Applications/Xcode-Beta.app/Contents/SharedFrameworks/" \
                                       "DTXConnectionServices.framework/Versions/A/" \
                                       "DTXConnectionServices", RTLD_NOW);
  assert(DTXConnectionServices != NULL);
  DTXChannelClass = objc_getClass("DTXChannel");
  assert(DTXChannelClass != nil);
}


// -------------------------------------------------------------------------------------------------
//
// Our Implementation
//
// -------------------------------------------------------------------------------------------------

// The channel listener class has to conform to a protocol that in turn has to conform to the
// `DTXAllowedRPC` protocol.
//
// Verification of this happens in the following order:
// * `-[DTXMessage invokeWithTarget:replyChannel:validator:]`
// * `shouldDispatchSelectorToObject`
// * `__shouldDispatchSelectorToObject_block_invoke_2`
//

@interface WatchKitLauncher : NSObject <XCDTMobileIS_XPCDebuggingProcotol>
@property (readonly) NSBundle *appBundle;
@property (readonly) NSBundle *watchKitExtensionBundle;
@property (readonly) DVTiPhoneSimulator *simulator;
@property (assign) BOOL verbose;
@property (assign) BOOL startSuspended;
@end

@implementation WatchKitLauncher

@synthesize watchKitExtensionBundle = _watchKitExtensionBundle;
@synthesize simulator = _simulator;

+ (instancetype)launcherWithAppBundlePath:(NSString *)appBundlePath;
{
  return [[self alloc] initWithAppBundle:[NSBundle bundleWithPath:appBundlePath]];
}

- (instancetype)initWithAppBundle:(NSBundle *)appBundle;
{
  NSParameterAssert(appBundle);
  if ((self = [super init])) {
    _appBundle = appBundle;
  }
  return self;
}

// Install the application to the `device`. This could be done in any number of ways, including the
// newly available `simctl` tool. But for now this tool replicates the behaviour seen in Xcode when
// launching extensions.
//
- (BOOL)installApplication;
{
  if (self.verbose) {
    const char *appPath = [self.appBundle.bundlePath UTF8String];
    const char *simDeviceName = [self.simulator.device.name UTF8String];
    printf("-> Installing `%s` to simulator device `%s`.\n", appPath, simDeviceName);
  }
  DVTFilePath *appFilePath = [DVTFilePathClass filePathForPathString:self.appBundle.bundlePath];
  DVTFuture *installation = [self.simulator installApplicationAtPath:appFilePath];
  [installation waitUntilFinished];
  if (installation.error != nil) {
    const char *error = [[installation.error description] UTF8String];
    fprintf(stderr, "[!] An error occurred while installing the application (%s)\n", error);
    return NO;
  }
  return YES;
}

// `launchMode` can be:
// * `nil`: the normal ‘interface’ application is launched.
// * `kIDEWatchLaunchModeGlance`: the ‘glance’ application is launched.
// * `kIDEWatchLaunchModeNotification`: the ‘notification’ application is launched.
//
// `notificationPayload` should be specified if `launchMode` is `kIDEWatchLaunchModeNotification`.
//
- (void)launchWithMode:(NSString *)launchMode
   notificationPayload:(NSDictionary *)notificationPayload;
{
  if (self.verbose) {
    printf("-> Launching application...\n");
  }
  DVTXPCServiceInformation *unstartedService = [self watchKitAppInformation];
  [self.simulator debugXPCServices:@[unstartedService]];
  DTXChannel *channel = self.simulator.xpcAttachServiceChannel;
  channel.dispatchTarget = self;

  NSString *appBundleID = self.appBundle.bundleIdentifier;
  // Reap any existing process
  [self.simulator terminateWatchAppForCompanionIdentifier:appBundleID options:@{}];

  // Start new process
  NSMutableDictionary *options = [NSMutableDictionary new];
  if (launchMode) {
    options[kIDEWatchLaunchModeKey] = launchMode;
    if ([launchMode isEqualToString:kIDEWatchLaunchModeNotification]) {
      NSParameterAssert(notificationPayload);
      options[kIDEWatchNotificationPayloadKey] = notificationPayload;
    }
  }
  [self.simulator launchWatchAppForCompanionIdentifier:appBundleID options:options];
}

// TODO use mkstemp instead of tmpnam
- (void)attachDebuggerToPID:(int)pid;
{
  NSString *commands = [NSString stringWithFormat:@"" \
                         "process attach -p %d\n" \
                         "command script import /Library/RubyMotion/lldb/lldb.py\n" \
                         "breakpoint set --name rb_exc_raise\n" \
                         "breakpoint set --name malloc_error_break\n", pid];
  if (!self.startSuspended) {
    commands = [commands stringByAppendingString:@"continue\n"];
  }
  NSString *file = [NSString stringWithUTF8String:tmpnam(NULL)];
  NSError *error = nil;
  if (![commands writeToFile:file atomically:YES encoding:NSASCIIStringEncoding error:&error]) {
    fprintf(stderr, "[!] Unable to save debugger commands file to `%s` (%s)\n",
                    [file UTF8String], [[error description] UTF8String]);
    exit(1);
  }

  if (self.verbose) {
    printf("-> Attaching debugger...\n");
  }
  char command[1024];
  sprintf(command, "lldb -s %s", [file UTF8String]);
  int status = system(command);

  if (self.verbose) {
    printf("-> Exiting...\n");
  }

  // Reap process. TODO exiting immediately afterwards makes reaping not actually work.
  NSString *appBundleID = self.appBundle.bundleIdentifier;
  [self.simulator terminateWatchAppForCompanionIdentifier:appBundleID options:@{}];

  // Exit launcher with status from LLDB. TODO Is that helpful?
  exit(status);
}

#pragma mark - Accessors

- (NSBundle *)watchKitExtensionBundle;
{
  @synchronized(self) {
    if (_watchKitExtensionBundle == nil) {
      NSString *pluginsPath = self.appBundle.builtInPlugInsPath;
      NSError *error = nil;
      NSArray *plugins = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsPath
                                                                             error:&error];
      assert(error == nil);
      for (NSString *plugin in plugins) {
        if ([[plugin pathExtension] isEqualToString:@"appex"]) {
          NSString *extensionPath = [pluginsPath stringByAppendingPathComponent:plugin];
          NSBundle *extensionBundle = [NSBundle bundleWithPath:extensionPath];
          NSDictionary *extensionInfo = extensionBundle.infoDictionary;
          NSString *extensionType = extensionInfo[@"NSExtension"][@"NSExtensionPointIdentifier"];
          if ([extensionType isEqualToString:@"com.apple.watchkit"]) {
            _watchKitExtensionBundle = extensionBundle;
            break;
          }
        }
      }
      assert(_watchKitExtensionBundle != nil);
    }
  }
  return _watchKitExtensionBundle;
}

// TODO Currently hardcoded to `iPhone 6`.
//
- (DVTiPhoneSimulator *)simulator;
{
  @synchronized(self) {
    if (_simulator == nil) {
      SimDevice *device = nil;
      for (SimDevice *availableDevice in [[SimDeviceSetClass defaultSet] devices]) {
        if ([availableDevice.name isEqualToString:@"iPhone 6"]) {
          device = availableDevice;
          break;
        }
      }
      assert(device != nil);
      _simulator = [DVTiPhoneSimulatorClass simulatorWithDevice:device];
      assert(_simulator != nil);
    }
  }
  return _simulator;
}

// TODO Do we maybe need to set all those build paths in the env for dSYM location, or is it just in
// case a framework is loaded and is not inside the host app bundle?
//
- (DVTXPCServiceInformation *)watchKitAppInformation;
{
  NSString *name = self.watchKitExtensionBundle.bundleIdentifier;
  DVTXPCServiceInformation *app = [[DVTXPCServiceInformationClass alloc] initWithServiceName:name
                                                                                         pid:-1
                                                                                   parentPID:0];
  app.fullPath = self.watchKitExtensionBundle.bundlePath;
  app.startSuspended = YES;
  app.environment = @{ @"NSUnbufferedIO": @"YES" };
  //app.environment = @{
    //@"NSUnbufferedIO": @"YES",
    //@"DYLD_FRAMEWORK_PATH": buildDir,
    //@"DYLD_LIBRARY_PATH": buildDir,
    //@"__XCODE_BUILT_PRODUCTS_DIR_PATHS": buildDir,
    //@"__XPC_DYLD_FRAMEWORK_PATH": buildDir,
    //@"__XPC_DYLD_LIBRARY_PATH": buildDir
  //};
  return app;
}

#pragma mark - XCDTMobileIS_XPCDebuggingProcotol

// If our service has started, connect to it with LLDB from the main thread. Do not block the XPC
// queue any further, otherwise we won't get any output messages.
//
- (void)xpcServiceObserved:(NSString *)observedServiceID
     withProcessIdentifier:(int)pid
        requestedByProcess:(int)parentPID
                   options:(NSDictionary *)options;
{
  if ([observedServiceID isEqualToString:self.watchKitExtensionBundle.bundleIdentifier]) {
    if (self.verbose) {
      printf("-> Requested XPC service has been observed with PID: %d.\n", pid);
    }
    assert(pid > 0);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self attachDebuggerToPID:pid];
    });
  }
}

// Directly print from the XPC queue this is delivered on so that it's shown while LLDB is running.
//
- (void)outputReceived:(NSString *)output fromProcess:(int)pid atTime:(unsigned long long)time;
{
  printf("%s", [output UTF8String]);
}

@end

void
print_help_banner(void) {
  fprintf(stderr, "Usage: watch-sim path/to/build/WatchHost.app -type [Glance|Notification] " \
                  "-notification-payload [path/to/payload.json] -verbose [YES|NO] " \
                  "-start-suspended [YES|NO]\n");
}

int
main(int argc, char **argv) {
  NSArray *allArguments = [NSProcessInfo processInfo].arguments;
  NSMutableArray *arguments = [NSMutableArray new];
  for (NSInteger i = 1; i < argc; i++) {
    NSString *argument = allArguments[i];
    if ([argument hasPrefix:@"-"]) {
      // Skip next argument, which is the value for this option.
      i++;
    } else {
      [arguments addObject:argument];
    }
  }

  if (arguments.count != 1) {
    print_help_banner();
    return 1;
  }
  NSString *appPath = arguments[0];

  NSUserDefaults *options = [NSUserDefaults standardUserDefaults];
  BOOL verbose = [options boolForKey:@"verbose"];
  BOOL startSuspended = [options boolForKey:@"start-suspended"];
  NSString *launchMode = nil;
  NSDictionary *notificationPayload = nil;
  NSString *type = [[options valueForKey:@"type"] lowercaseString];
  if (type != nil) {
    if ([type isEqualToString:@"glance"]) {
      launchMode = kIDEWatchLaunchModeGlance;
    } else if ([type isEqualToString:@"notification"]) {
      // Get the obligatory notification payload (JSON) data.
      launchMode = kIDEWatchLaunchModeNotification;
      NSString *payloadFile = [options valueForKey:@"notification-payload"];
      if (payloadFile == nil) {
        fprintf(stderr, "[!] A `-notification-payload` is required with `-type Notification`.\n");
        print_help_banner();
        return 1;
      }
      NSData *payloadData = [NSData dataWithContentsOfFile:payloadFile];
      NSError *error = nil;
      notificationPayload = [NSJSONSerialization JSONObjectWithData:payloadData
                                                            options:0
                                                              error:&error];
      if (error != nil) {
        fprintf(stderr, "[!] Unable to load notification payload file `%s` (%s)\n",
                        [payloadFile UTF8String], [[error description] UTF8String]);
        return 1;
      }
      assert([notificationPayload isKindOfClass:[NSDictionary class]]);
    } else {
      fprintf(stderr, "[!] Unknown application type `%s`.\n", [type UTF8String]);
      print_help_banner();
      return 1;
    }
  }

  init_imported_classes();

  WatchKitLauncher *launcher = [WatchKitLauncher launcherWithAppBundlePath:appPath];
  launcher.verbose = verbose;
  launcher.startSuspended = startSuspended;
  assert(launcher.installApplication);
  [launcher launchWithMode:launchMode notificationPayload:notificationPayload];

  CFRunLoopRun();

  return 0;
}
