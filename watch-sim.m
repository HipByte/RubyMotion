// My env seems hosed, because I can only build with:
//
//  $ clang -isysroot /Applications/Xcode-Beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk -ObjC -fobjc-arc -framework Foundation -Xlinker -undefined -Xlinker dynamic_lookup -g -o watch-sim watch-sim.m
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import <dlfcn.h>
#import <libgen.h>

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

// IDEiOSSupportCore

@interface DVTiPhoneSimulator : NSObject // Real superclass: DVTAbstractiOSDevice
+ (instancetype)simulatorWithDevice:(SimDevice *)device;
- (DVTFuture *)installApplicationAtPath:(DVTFilePath *)path;
- (void)debugXPCServices:(NSArray *)services;
// @property(retain) DTXChannel *xpcAttachServiceChannel; // @synthesize xpcAttachServiceChannel=_xpcAttachServiceChannel;
- (DTXChannel *)xpcAttachServiceChannel;
// @property(retain) SimDevice *device;
- (SimDevice *)device;

// Actually defined in DVTDevice, so probably works on a physical device as
// well.
- (void)terminateWatchAppForCompanionIdentifier:(NSString *)bundleID options:(NSDictionary *)options;
- (void)launchWatchAppForCompanionIdentifier:(NSString *)bundleID options:(NSDictionary *)options;
@end

@protocol DTXAllowedRPC <NSObject>
@end

@protocol XCDTMobileIS_XPCDebuggingProcotol <DTXAllowedRPC>
- (void)outputReceived:(id)arg1 fromProcess:(int)arg2 atTime:(unsigned long long)arg3;
- (void)xpcServiceObserved:(id)arg1 withProcessIdentifier:(int)arg2 requestedByProcess:(int)arg3 options:(id)arg4;
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
  void *CoreSimulator = dlopen("/Applications/Xcode-Beta.app/Contents/Developer/Library/PrivateFrameworks/CoreSimulator.framework/CoreSimulator", RTLD_NOW);
  assert(CoreSimulator != NULL);
  SimDeviceSetClass = objc_getClass("SimDeviceSet");
  assert(SimDeviceSetClass != nil);
  SimDeviceClass = objc_getClass("SimDevice");
  assert(SimDeviceClass != nil);

  void *DVTFoundation = dlopen("/Applications/Xcode-Beta.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/DVTFoundation", RTLD_NOW);
  assert(DVTFoundation != NULL);
  DVTFilePathClass = objc_getClass("DVTFilePath");
  assert(DVTFilePathClass != nil);
  DVTXPCServiceInformationClass = objc_getClass("DVTXPCServiceInformation");
  assert(DVTXPCServiceInformationClass != nil);

  void *DevToolsCore = dlopen("/Applications/Xcode-Beta.app/Contents/OtherFrameworks/DevToolsCore.framework/DevToolsCore", RTLD_NOW);
  assert(DevToolsCore != NULL);
  void *IDEiOSSupportCore = dlopen("/Applications/Xcode-Beta.app/Contents/PlugIns/IDEiOSSupportCore.ideplugin/Contents/MacOS/IDEiOSSupportCore", RTLD_NOW);
  assert(IDEiOSSupportCore != NULL);
  DVTiPhoneSimulatorClass = objc_getClass("DVTiPhoneSimulator");
  assert(DVTiPhoneSimulatorClass != nil);

  void *DTXConnectionServices = dlopen("/Applications/Xcode-Beta.app/Contents/SharedFrameworks/DTXConnectionServices.framework/Versions/A/DTXConnectionServices", RTLD_NOW);
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

@interface Launcher : NSObject <XCDTMobileIS_XPCDebuggingProcotol>
@property (strong) NSString *buildDir;
@property (strong) NSString *appPath;
@property (strong) NSString *appBundleID;
@property (strong) NSString *extensionBundleID;
@property (strong) NSString *extensionBundleFilename;

@property (strong, nonatomic) DVTiPhoneSimulator *simulator;
@end

@implementation Launcher

// Install the application to the `device`. This could be done in any number of ways, including the
// newly available `simctl` tool. But for now this tool replicates the behaviour seen in Xcode when
// launching extensions.
//
// TODO: Return error?
//
- (BOOL)installApplication;
{
  DVTFilePath *appFilePath = [DVTFilePathClass filePathForPathString:self.appPath];
  NSLog(@"Installing `%@` to simulator device `%@`.", self.appPath, self.simulator.device.name);
  DVTFuture *installation = [self.simulator installApplicationAtPath:appFilePath];
  [installation waitUntilFinished];
  if (installation.error != nil) {
    NSLog(@"[!] An error occurred while installing the application (%@)", installation.error);
    return NO;
  }
  return YES;
}

- (void)launch;
{
  DVTXPCServiceInformation *unstartedService = [self serviceInformationWithPID:-1];
  [self.simulator debugXPCServices:@[unstartedService]];
  DTXChannel *channel = self.simulator.xpcAttachServiceChannel;
  channel.dispatchTarget = self;

  // Reap any existing process
  [self.simulator terminateWatchAppForCompanionIdentifier:self.appBundleID options:@{}];
  // Start new process
  [self.simulator launchWatchAppForCompanionIdentifier:self.appBundleID options:@{}];
}

// TODO Currently hardcoded to `iPhone 6`.
//
- (DVTiPhoneSimulator *)simulator;
{
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
  return _simulator;
}

- (DVTXPCServiceInformation *)serviceInformationWithPID:(int)pid;
{
  DVTXPCServiceInformation *service = nil;
  service = [[DVTXPCServiceInformationClass alloc] initWithServiceName:self.extensionBundleID
                                                                   pid:pid
                                                             parentPID:0];
  service.fullPath = [[self.appPath stringByAppendingPathComponent:@"PlugIns"]
                                    stringByAppendingPathComponent:self.extensionBundleFilename];
  service.startSuspended = YES;
  service.environment = @{
    @"NSUnbufferedIO": @"YES",
    @"DYLD_FRAMEWORK_PATH": self.buildDir,
    @"DYLD_LIBRARY_PATH": self.buildDir,
    @"__XCODE_BUILT_PRODUCTS_DIR_PATHS": self.buildDir,
    @"__XPC_DYLD_FRAMEWORK_PATH": self.buildDir,
    @"__XPC_DYLD_LIBRARY_PATH": self.buildDir
  };
  return service;
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
  if ([observedServiceID isEqualToString:self.extensionBundleID]) {
    NSLog(@"Requested XPC service has been observed with PID: %d.", pid);
    assert(pid > 0);
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"Attaching debugger...");
      char command[1024];
      sprintf(command, "lldb -p %d", pid);
      int status = system(command);

      NSLog(@"Exiting...");
      // Reap process. TODO exiting immediately afterwards makes reaping not actually work.
      [self.simulator terminateWatchAppForCompanionIdentifier:self.appBundleID options:@{}];
      // Exit launcher with status from LLDB. TODO Is that helpful?
      exit(status);
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

int
main(int argc, char **argv) {
  if (argc < 5) {
    fprintf(stderr, "Usage: %s path/to/build/WatchHost.app host-app.bundle.id extension.bundle.id path/to/build/WatchExtension.appex\n", basename(argv[0]));
    return 1;
  }

  init_imported_classes();

  NSString *appPath = [NSString stringWithUTF8String:argv[1]];
  NSString *appBundleID = [NSString stringWithUTF8String:argv[2]];
  NSString *extensionBundleID = [NSString stringWithUTF8String:argv[3]];
  NSString *extensionBuildPath = [NSString stringWithUTF8String:argv[4]];

  NSString *extensionBundleFilename = [extensionBuildPath lastPathComponent];
  NSString *buildDir = [appPath stringByDeletingLastPathComponent];

  Launcher *launcher = [Launcher new];
  launcher.buildDir = buildDir;
  launcher.appPath = appPath;
  launcher.appBundleID = appBundleID;
  launcher.extensionBundleID = extensionBundleID;
  launcher.extensionBundleFilename = extensionBundleFilename;

  assert(launcher.installApplication);
  [launcher launch];

  CFRunLoopRun();

  return 0;
}
