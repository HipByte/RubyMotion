// ### Inspect arguments for -[XRXcodeAnalysisService _launch:WithConfigFile:]
//
// $ gdb -p [Xcode PID]
// (gdb) b _launch:WithConfigFile:
// Breakpoint 1 at 0x1131fad3b
// (gdb) c
// Continuing.
// Breakpoint 1, 0x00000001131fad3b in -[XRXcodeAnalysisService _launch:WithConfigFile:] ()
// (gdb) po $rdx
// /Applications/Xcode.app/Contents/Applications/Instruments.app
// (gdb) po $rcx
// /var/folders/bz/4w413_r9207ccmg9n_2whlh40000gn/T/pbxperfconfig.plist
//
//
//
// ### Disassembled pseudo code extracted from IDEInstrumentsService:
//
// function methImpl_XRXcodeAnalysisService__launch_WithConfigFile_ {
//     var_72 = rdi;
//     var_64 = rsi;
//     r15 = *objc_retain;
//     rax = [rdx retain];
//     r14 = rax;
//     rax = [rcx retain];
//     rbx = rax;
//     rax = CFURLCreateWithFileSystemPath(0x0, r14, 0x0, 0x1);
//     r15 = rax;
//     rax = CFURLCreateWithFileSystemPath(0x0, rbx, 0x0, 0x0);
//     r12 = rax;
//     [rbx release];
//     var_56 = r12;
//     rax = CFArrayCreate(**kCFAllocatorSystemDefault, &var_56, 0x1, *kCFTypeArrayCallBacks);
//     var_16 = r15;
//     var_24 = rax;
//     var_32 = 0x0;
//     var_44 = 0x0;
//     var_40 = 0x10001;
//     rax = LSOpenFromURLSpec(&var_16, 0x0);
//     if (rax != 0x0) {
//             _DVTAssertionWarningHandler(&var_72, &var_64, "-[XRXcodeAnalysisService _launch:WithConfigFile:]", "/SourceCache/IDEDebugger/IDEDebugger-3528/PlugIns/Instruments/XRXcodeAnalysisService.m", 0x1ab, @"LSOpenFromURLSpec() returned %ld for trying to launch Instruments at path : %@");
//     }
//     if (r15 != 0x0) {
//             CFRelease(r15);
//     }
//     if (var_56 != 0x0) {
//             CFRelease(rdi);
//     }
//     if (rbx != 0x0) {
//             CFRelease(rbx);
//     }
//     rax = [r14 release];
//     return rax;
// }
//
//
//
// ### Observations
//
// * iOS Simulator: Instruments.app is responsible for (installing?) launching the built on the simulator.
// * iOS Device: Xcode installs the built on the device and Instruments.app launches it.
// * OS X: Nothing much needs to be done, Instruments.app launches the app.


#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

int main(int argc, char *argv[])
{
  if (argc != 3) {
    printf("Usage: %s path/to/Instruments.app path/to/pbxperfconfig.plist\n", argv[0]);
    return -1;
  }

  char *instrumentsPath = argv[1];
  char *configPath = argv[2];
  CFURLRef instrumentsURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8 *)instrumentsPath, strlen(instrumentsPath), false);
  CFURLRef configURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8 *)configPath, strlen(configPath), false);

  CFArrayRef itemURLs = CFArrayCreate(NULL, (const void **)&configURL, 1, &kCFTypeArrayCallBacks);

  LSLaunchURLSpec spec;
  spec.appURL = instrumentsURL;
  spec.itemURLs = itemURLs;
  spec.passThruParams = NULL;
  spec.launchFlags = 0;
  spec.asyncRefCon = NULL;

  OSStatus status = LSOpenFromURLSpec(&spec, NULL);
  if (status != 0) {
    fprintf(stderr, "Unable to launch Instruments: %d\n", status);
  }

  CFRelease(instrumentsURL);
  CFRelease(configURL);
  CFRelease(itemURLs);

  return status;
}
