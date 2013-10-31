#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include "builtin_debugger_cmds.h"

typedef void *am_device_t;
typedef void *afc_conn_t;
typedef void *afc_fileref_t;
typedef void *am_device_notif_context_t;

static am_device_t
am_device_from_notif_context(am_device_notif_context_t info)
{
    return *(void **)info; 
}

typedef void (*am_device_subscribe_cb)(am_device_notif_context_t info);

#define SET_FUNC(name) \
    static fptr_##name _##name = NULL

#define LOOKUP_FUNC(handler, name) \
    do { \
	_##name = (fptr_##name)(dlsym(handler, #name)); \
	if (_##name == NULL) { \
	    printf("can't lookup function %s\n", #name); \
	    exit(1); \
	} \
    } \
    while (0)

typedef int (*fptr_AMDeviceNotificationSubscribe)(am_device_subscribe_cb,
	int, int, int, void **);
SET_FUNC(AMDeviceNotificationSubscribe);

typedef CFStringRef (*fptr_AMDeviceGetName)(am_device_t);
SET_FUNC(AMDeviceGetName);

typedef int (*fptr_AMDeviceLookupApplications)(am_device_t, int, void **);
SET_FUNC(AMDeviceLookupApplications);

typedef CFStringRef (*fptr_AMDeviceCopyValue)(am_device_t, unsigned int,
	CFStringRef);
SET_FUNC(AMDeviceCopyValue);

typedef int (*fptr_AMDeviceMountImage)(am_device_t, CFStringRef,
	CFDictionaryRef, void *, int);
SET_FUNC(AMDeviceMountImage);

typedef int (*fptr_AMDeviceConnect)(am_device_t);
SET_FUNC(AMDeviceConnect);

typedef int (*fptr_AMDeviceValidatePairing)(am_device_t);
SET_FUNC(AMDeviceValidatePairing);

typedef int (*fptr_AMDeviceStartSession)(am_device_t);
SET_FUNC(AMDeviceStartSession);

typedef int (*fptr_AMDeviceStartService)(am_device_t, CFStringRef, int *,
	void *);
SET_FUNC(AMDeviceStartService);

typedef int (*fptr_AFCConnectionOpen)(int, void *, afc_conn_t *conn);
SET_FUNC(AFCConnectionOpen);

typedef int (*fptr_AFCDirectoryCreate)(afc_conn_t, const char *);
SET_FUNC(AFCDirectoryCreate);

typedef int (*fptr_AFCFileRefOpen)(afc_conn_t, const char *, int,
	afc_fileref_t *);
SET_FUNC(AFCFileRefOpen);

typedef int (*fptr_AFCFileRefWrite)(afc_conn_t, afc_fileref_t, const void *,
	size_t);
SET_FUNC(AFCFileRefWrite);

typedef int (*fptr_AFCFileRefClose)(afc_conn_t, afc_fileref_t);
SET_FUNC(AFCFileRefClose);

static void
init_private_funcs(void)
{
    void *handler = dlopen("/System/Library/PrivateFrameworks/MobileDevice.framework/MobileDevice", 0);
    LOOKUP_FUNC(handler, AMDeviceNotificationSubscribe);
    LOOKUP_FUNC(handler, AMDeviceGetName);
    LOOKUP_FUNC(handler, AMDeviceLookupApplications);
    LOOKUP_FUNC(handler, AMDeviceCopyValue);
    LOOKUP_FUNC(handler, AMDeviceMountImage);
    LOOKUP_FUNC(handler, AMDeviceConnect);
    LOOKUP_FUNC(handler, AMDeviceValidatePairing);
    LOOKUP_FUNC(handler, AMDeviceStartSession);
    LOOKUP_FUNC(handler, AMDeviceStartService);
    LOOKUP_FUNC(handler, AFCConnectionOpen);
    LOOKUP_FUNC(handler, AFCDirectoryCreate);
    LOOKUP_FUNC(handler, AFCFileRefOpen);
    LOOKUP_FUNC(handler, AFCFileRefWrite);
    LOOKUP_FUNC(handler, AFCFileRefClose);
}

static bool debug_mode = false;
static bool discovery_mode = false;
static bool console_mode = false;

#define LOG(fmt, ...) \
    do { \
	if (debug_mode) { \
	    fprintf(stderr, "log: "); \
	    fprintf(stderr, fmt, ##__VA_ARGS__); \
	    fprintf(stderr, "\n"); \
	} \
    } \
    while (0)

#define PERFORM(what, call) \
    do { \
	LOG(what); \
	int code = call; \
	if (code != 0) { \
	    fprintf(stderr, "Error when %s: code %d\n", what, code); \
	    fprintf(stderr, "Make sure RubyMotion is using a valid (non-expired) provisioning profile\nand that no other process (iTunes, Xcode) is connected to your iOS device\nat the same time (even through Wi-Fi).\n"); \
	    exit(1); \
	} \
    } \
    while (0)

static void
send_plist(NSFileHandle *handle, id plist)
{
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist
	format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (data == nil) {
	fprintf(stderr, "error when serializing property list %s: %s\n",
		[[plist description] UTF8String],
		[[error description] UTF8String]);
	exit(1);
    }

    uint32_t nlen = CFSwapInt32HostToBig([data length]);
    [handle writeData:[[[NSData alloc] initWithBytes:&nlen
	length:sizeof(nlen)] autorelease]];
    [handle writeData:data];
}

static id
read_plist(NSFileHandle *handle)
{
    NSData *datalen = [handle readDataOfLength:4];
    if ([datalen length] < 4) {
	fprintf(stderr, "error: datalen packet not found\n");
	exit(1);
    }
    uint32_t *lenp = (uint32_t *)[datalen bytes];
    uint32_t len = CFSwapInt32BigToHost(*lenp);

    NSMutableData *data = [NSMutableData data];
    while (true) {
	NSData *chunk = [handle readDataOfLength:len];
	if (chunk == nil) {
	    break;
	}
	[data appendData:chunk];
	if ([chunk length] == len) {
	    break;
	}
	len -= [data length];
    }

    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data
	options:0 format:NULL error:&error];
    if (plist == nil) {
	fprintf(stderr, "error when deserializing property list data %s: %s\n",
		[[data description] UTF8String],
		[[error description] UTF8String]);
	exit(1);
    }
    return plist;
}

static NSString *device_id = nil;
static NSString *app_package_path = nil;
static NSData *app_package_data = nil;

static NSDictionary *
read_info_plist(void)
{
    NSString *app_path = [[app_package_path stringByDeletingPathExtension]
	stringByAppendingString:@".app"];

    NSDictionary *info_plist = [NSDictionary dictionaryWithContentsOfFile:
	[app_path stringByAppendingPathComponent:@"Info.plist"]];
    assert(info_plist != nil);

    return info_plist;
}

static NSString *
remote_app_path(am_device_t dev)
{
    NSDictionary *info_plist = read_info_plist();
    NSString *app_identifier = [info_plist objectForKey:@"CFBundleIdentifier"];
    assert(app_identifier != nil);

    NSDictionary *apps = nil;
    const int res = _AMDeviceLookupApplications(dev, 0, (void **)&apps);
    assert(res == 0);
    NSDictionary *app = [apps objectForKey:app_identifier];
    assert(app != nil);
    NSString *app_remote_path = [app objectForKey:@"Path"];
    assert(app_remote_path != nil);

    return app_remote_path;
}

static void
setup_device_connection(am_device_t dev)
{
    PERFORM("connecting to device", _AMDeviceConnect(dev));
    PERFORM("pairing device", _AMDeviceValidatePairing(dev));
    PERFORM("creating lockdown session", _AMDeviceStartSession(dev));
}

static void
install_application(am_device_t dev)
{
    setup_device_connection(dev);

    int afc_fd = 0;
    PERFORM("starting file copy service", _AMDeviceStartService(dev,
		CFSTR("com.apple.afc"), &afc_fd, NULL));
    assert(afc_fd > 0);

    int ipc_fd = 0;
    PERFORM("starting installer proxy service", _AMDeviceStartService(dev,
		CFSTR("com.apple.mobile.installation_proxy"), &ipc_fd, NULL));
    assert(ipc_fd > 0);

    afc_conn_t afc_conn = NULL;
    PERFORM("opening file copy connection", _AFCConnectionOpen(afc_fd, 0,
		&afc_conn));
    assert(afc_conn != NULL);

    NSString *staging_dir = @"PublicStaging";
    NSString *remote_pkg_path = [NSString stringWithFormat:@"%@/%@",
	     staging_dir, [app_package_path lastPathComponent]];
    PERFORM("creating staging directory", _AFCDirectoryCreate(afc_conn,
		[staging_dir fileSystemRepresentation]));

    afc_fileref_t afc_fileref = NULL;
    PERFORM("opening remote package path", _AFCFileRefOpen(afc_conn,
		[remote_pkg_path fileSystemRepresentation], 0x3 /* write */,
		&afc_fileref));
    assert(afc_fileref != NULL);

    PERFORM("writing data", _AFCFileRefWrite(afc_conn, afc_fileref,
		[app_package_data bytes], [app_package_data length]));

    PERFORM("closing remote package path", _AFCFileRefClose(afc_conn,
		afc_fileref));

    NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:ipc_fd
	closeOnDealloc:NO];

    LOG("sending install command");
    send_plist(handle, [NSDictionary dictionaryWithObjectsAndKeys:
	    @"Install", @"Command",
	    remote_pkg_path, @"PackagePath",
	    nil]);

    while (true) {
	id plist = read_plist(handle);
	if (plist == nil) {
	    break;
	}
	id error = [plist objectForKey:@"Error"];
	if (error != nil) {
	    fprintf(stderr, "error: %s\n", [[error description] UTF8String]);
	    exit(1);
	}
	id percent = [plist objectForKey:@"PercentComplete"];
	id status = [plist objectForKey:@"Status"];
	int percent_int = percent == nil
	    ? 100 : [percent intValue];
	const char *status_str = status == nil
	    ? "Unknown" : [status UTF8String];
	LOG("progress report: %d%% status: %s", percent_int, status_str);
	if (percent_int == 100) {
	    break;
	}
    }

    LOG("package has been successfully installed on device");
    printf("%s\n", [remote_app_path(dev) UTF8String]);
    [handle release];
}

static void
mount_cb(id dict, int arg)
{
    if (dict != nil && [dict isKindOfClass:[NSDictionary class]]) {
	id status = [dict objectForKey:@"Status"];
	if (status != nil && [status isKindOfClass:[NSString class]]) {
	    LOG("mounting status: %s", [status UTF8String]);
	}
    }
}

static int gdb_fd = 0;

#include <sys/socket.h>
#include <sys/un.h>

static void
fdvendor_callback(CFSocketRef s, CFSocketCallBackType callbackType,
	CFDataRef address, const void *data, void *info)
{
    CFSocketNativeHandle socket = (CFSocketNativeHandle)
	(*((CFSocketNativeHandle *)data));

    struct msghdr message;
    struct iovec iov[1];
    struct cmsghdr *control_message = NULL;
    char ctrl_buf[CMSG_SPACE(sizeof(int))];
    char dummy_data[1];

    memset(&message, 0, sizeof(struct msghdr));
    memset(ctrl_buf, 0, CMSG_SPACE(sizeof(int)));

    dummy_data[0] = ' ';
    iov[0].iov_base = dummy_data;
    iov[0].iov_len = sizeof(dummy_data);

    message.msg_name = NULL;
    message.msg_namelen = 0;
    message.msg_iov = iov;
    message.msg_iovlen = 1;
    message.msg_controllen = CMSG_SPACE(sizeof(int));
    message.msg_control = ctrl_buf;

    control_message = CMSG_FIRSTHDR(&message);
    control_message->cmsg_level = SOL_SOCKET;
    control_message->cmsg_type = SCM_RIGHTS;
    control_message->cmsg_len = CMSG_LEN(sizeof(int));

    *((int *) CMSG_DATA(control_message)) = gdb_fd;

    sendmsg(socket, &message, 0);
    CFSocketInvalidate(s);
    CFRelease(s);
}

static NSTask *gdb_task = nil;

static void
sigforwarder(int sig)
{
    if (gdb_task != nil) {
	kill([gdb_task processIdentifier], sig);
    }
}

#define WITH_DEBUG 1

static char
tohex(int x)
{
    assert(x >= 0 && x <= 16);
    static char *hexchars = "0123456789ABCDEF";
    return hexchars[x];
}

static void
gdb_send_str(const char *buf)
{
    send(gdb_fd, buf, strlen(buf), 0);
}

static NSData *
gdb_recv_pkt()
{
    NSMutableData *data = [NSMutableData data];
    while (true) {
	char buf[100];
	ssize_t len = recv(gdb_fd, buf, sizeof buf, 0);
	if (len <= 0) {
	    break;
	}
	assert(len <= sizeof buf);
	[data appendBytes:buf length:len];
    }
    if ([data length] > 0) {
	gdb_send_str("+");
    }
    return data;
}

static void 
gdb_send_pkt(const char *buf)
{
    char *buf2 = (char *)malloc(32*1024);
    assert(buf2 != NULL);
    memset(buf2, 0, 32*1024);

    long cnt = strlen(buf);
    unsigned char csum = 0;
    char *p = buf2;
    *p++ = '$';
    for (int i = 0; i < cnt; i++) {
	csum += buf[i];
	*p++ = buf[i];
    }
    *p++ = '#';
    *p++ = tohex((csum >> 4) & 0xf);
    *p++ = tohex(csum & 0xf);
    *p = '\0';

    gdb_send_str(buf2);
    gdb_recv_pkt();
    free(buf2);
}

static void
gdb_start_app(NSString *app_path)
{
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 500000;
    setsockopt(gdb_fd, SOL_SOCKET, SO_RCVTIMEO, (struct timeval *)&tv,
	    sizeof(struct timeval));

    char *cmds[] = {
        "XXX", // Will be replaced by the app path.
        "Hc0",
        "c",
        NULL,
    };

    const char *apppath = [app_path UTF8String];
    cmds[0] = malloc(2000);
    assert(cmds[0] != NULL);
    char *p = cmds[0];
    sprintf(p, "A%ld,0,", strlen(apppath) * 2);
    p += strlen(p);
    const char* q = apppath;
    while (*q) {
        *p++ = tohex((*q >> 4) & 0xf);
        *p++ = tohex(*q & 0xf);
        q++;
    }
    *p = '\0';

    char **cmd = cmds;
    while (*cmd != NULL) {
	gdb_send_pkt(*cmd);
	cmd++;
	gdb_recv_pkt();
	gdb_recv_pkt();
    }
}

static void
open_console(am_device_t dev)
{
    setup_device_connection(dev);

    int syslog_fd = 0;
    PERFORM("starting syslog relay service", _AMDeviceStartService(dev,
		CFSTR("com.apple.syslog_relay"), &syslog_fd, NULL));
    assert(syslog_fd > 0);

    while (true) {
	char buf[100];
	ssize_t len = recv(syslog_fd, buf, sizeof buf, 0);
	if (len == -1) {
	    fprintf(stderr, "error when reading syslog: %s",
		    strerror(errno));
	    break;
	}
	buf[len] = '\0';
	printf("%s", buf);
    }
}

static void
start_debug_server(am_device_t dev)
{
    // We need .app and .dSYM bundles nearby.

    NSString *app_path = [[app_package_path stringByDeletingPathExtension]
	stringByAppendingString:@".app"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:app_path]) {
	fprintf(stderr, "%s does not exist\n",
		[app_path fileSystemRepresentation]);
	return;
    }
	
    NSString *dsym_path = [[app_package_path stringByDeletingPathExtension]
	stringByAppendingString:@".dSYM"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dsym_path]) {
	fprintf(stderr, "%s does not exist\n",
		[dsym_path fileSystemRepresentation]);
	return;
    }

    // Locate DeveloperDiskImage.dmg on the filesystem.

    char *xcode_dir = getenv("XCODE_DIR");
    assert(xcode_dir != NULL);
    NSString *device_supports_path = [[NSString stringWithUTF8String:xcode_dir]
	stringByAppendingPathComponent:
	@"Platforms/iPhoneOS.platform/DeviceSupport"];

    NSString *product_version = (NSString *)_AMDeviceCopyValue(dev, 0,
	    CFSTR("ProductVersion"));
    assert(product_version != nil);

    NSString *device_support_path = nil;
    for (NSString *path in [[NSFileManager defaultManager]
	    contentsOfDirectoryAtPath:device_supports_path error:nil]) {
	NSRange r = [path rangeOfString:@" "];
	NSString *path_version = r.location == NSNotFound
	    ? path : [path substringToIndex:r.location];
	if ([product_version hasPrefix:path_version]) {
	    device_support_path =
		[device_supports_path stringByAppendingPathComponent:path];
	    break;
	}
    }

    if (device_support_path == nil) {
	fprintf(stderr,
		"cannot find developer disk image in `%s' for version `%s'\n",
		[device_supports_path fileSystemRepresentation],
		[product_version UTF8String]);
	return;
    }

    NSString *image_path = [device_support_path stringByAppendingPathComponent:
	@"DeveloperDiskImage.dmg"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:image_path]) {
	fprintf(stderr, "%s does not exist\n",
		[image_path fileSystemRepresentation]);
	return;
    }

    // Mount the .dmg remotely on the device.

    NSString *image_sig_path = [image_path stringByAppendingString:
	@".signature"]; 
    if (![[NSFileManager defaultManager] fileExistsAtPath:image_sig_path]) {
	fprintf(stderr, "%s does not exist\n",
		[image_sig_path fileSystemRepresentation]);
	return;
    }

    NSData *image_sig_data = [NSData dataWithContentsOfFile:image_sig_path];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
	image_sig_data, @"ImageSignature",
	@"Developer", @"ImageType",
	nil];

    LOG("mounting developer disk image: %s",
	    [image_path fileSystemRepresentation]);

    /*int result =*/ _AMDeviceMountImage(dev, (CFStringRef)image_path,
	    (CFDictionaryRef)options, mount_cb, 0);

    // Start debug server.

    gdb_fd = 0;
    PERFORM("starting debug server service", _AMDeviceStartService(dev,
		CFSTR("com.apple.debugserver"), &gdb_fd, NULL));
    assert(gdb_fd > 0);

    NSString *app_name = [read_info_plist() objectForKey:@"CFBundleName"];
    assert(app_name != nil);
    NSString *app_remote_path = remote_app_path(dev);

    // Do we need to attach a debugger? If not, we simply run the app.

    if (getenv("debug") == NULL) {
	NSDate *app_launch_date = [NSDate date];
	gdb_start_app(app_remote_path);
	fprintf(stderr,
		"*** Application is running on the device, use ^C to quit.\n");

	// Start the syslog service.
	int syslog_fd = 0;
	PERFORM("starting syslog relay service", _AMDeviceStartService(dev,
		    CFSTR("com.apple.syslog_relay"), &syslog_fd, NULL));
	assert(syslog_fd > 0);

	// Connect and read the output.
	NSMutableString *data = [NSMutableString string];
	NSString *syslog_match = [app_name stringByAppendingString:@"["];
	bool logs_since_app_launch_date = false;
	while (true) {
	    char buf[100];
	    ssize_t len = recv(syslog_fd, buf, sizeof buf, 0);
	    if (len == -1) {
		fprintf(stderr, "error when reading syslog: %s",
			strerror(errno));
		break;
	    }
	    assert(len <= sizeof buf);
	    buf[len] = '\0';

	    // Split the output into lines.
	    char *p = strrchr(buf, '\n');
	    if (p == NULL) {
		NSString *tmp = [[NSString alloc] initWithCString:buf
		    encoding:NSUTF8StringEncoding];
		if (tmp != nil) {
		    [data appendString:tmp];
		    [tmp release];
		}
	    }
	    else {
		NSString *tmp = [[NSString alloc] initWithBytes:buf
		    length:p-buf encoding:NSUTF8StringEncoding];
		if (tmp != nil) {
		    [data appendString:tmp];
		    [tmp release];
		}

		// Parse lines.
		NSArray *lines = [data componentsSeparatedByString:@"\n"];
		for (NSString *line in lines) {
		    // Filter by app name.
		    if ([line rangeOfString:syslog_match].location
			    == NSNotFound) {
			continue;
		    }
		    // Filter by date.
		    if (!logs_since_app_launch_date) {
			NSArray *words = [line componentsSeparatedByString:
			    @" "];
			int index_month = 0;
			int index_day   = 1;
			int index_time  = 2;
			if ([[words objectAtIndex:index_day] isEqualToString:@""]) {
			    index_day++;
			    index_time++;
			}
			NSString *str = [NSString stringWithFormat:
			    @"%@ %@ %@", [words objectAtIndex:index_month],
			    [words objectAtIndex:index_day], [words objectAtIndex:index_time]];
			NSDate *date = [NSDate dateWithNaturalLanguageString:
			    str];
			if ([date compare:app_launch_date]
				== NSOrderedDescending) {
			    logs_since_app_launch_date = true;
			}
			else {
			    continue;
			}
		    }
		    // Yeepee, we can print that one!
		    printf("%s\n", [line UTF8String]);
		}
		data = [[[NSMutableString alloc] initWithCString:p+1
		    encoding:NSUTF8StringEncoding] autorelease];
	    }
	}
	CFRunLoopRun();
	return;
    }

    // Connect the debug server socket to a UNIX socket file.
    // gdb-only, but since RubyMine also uses it, we keep it around.

    NSString *tmpdir = NSTemporaryDirectory();
    assert(tmpdir != nil);
    char gdb_unix_socket_path[PATH_MAX];
    snprintf(gdb_unix_socket_path, sizeof gdb_unix_socket_path,
	    "%s/rubymotion-remote-gdb-XXXXXX",
	    [tmpdir fileSystemRepresentation]);
    assert(mktemp(gdb_unix_socket_path) != NULL);

    unlink(gdb_unix_socket_path);

    CFSocketRef fdvendor = CFSocketCreate(NULL, AF_UNIX, 0, 0,
	    kCFSocketAcceptCallBack, &fdvendor_callback, NULL);

    struct sockaddr_un address;
    memset(&address, 0, sizeof(address));
    address.sun_family = AF_UNIX;
    strcpy(address.sun_path, gdb_unix_socket_path);
    address.sun_len = SUN_LEN(&address);

    CFDataRef address_data = CFDataCreate(NULL, (const UInt8 *)&address,
	    sizeof(address));

    int yes = 1;
    setsockopt(CFSocketGetNative(fdvendor), SOL_SOCKET, SO_REUSEADDR, &yes,
	    sizeof(yes));

    CFSocketSetAddress(fdvendor, address_data);
    CFRelease(address_data);
    CFRunLoopAddSource(CFRunLoopGetMain(),
	    CFSocketCreateRunLoopSource(NULL, fdvendor, 0),
	    kCFRunLoopCommonModes);

    // If we need to attach an external debugger, we can stop here.

    if (getenv("no_start")) {
	fprintf(stderr, "device_support_path: %s\nremote_app_path: %s\n"\
		"debug_server_socket_path: %s\n",
		[device_support_path fileSystemRepresentation],
		[app_remote_path fileSystemRepresentation],
		gdb_unix_socket_path);
	pause();
    }

    // Attach the debugger: gdb or lldb.

    NSString *gdb_path = [[NSString stringWithUTF8String:xcode_dir]
	stringByAppendingPathComponent:
	@"Platforms/iPhoneOS.platform/Developer/usr/libexec/gdb/gdb-arm-apple-darwin"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gdb_path]) {
	// Prepare gdb commands file.
	NSString *cmds_path = [NSString pathWithComponents:
	    [NSArray arrayWithObjects:NSTemporaryDirectory(), @"_deploygdbcmds",
	    nil]];
	NSString *cmds = [NSString stringWithFormat:@""\
	 "set shlib-path-substitutions /usr \"%@/Symbols/usr\" /System \"%@/Symbols/System\" /Developer \"%@/Symbols/Developer\" \"%@\" \"%@\"\n"\
	 "set remote max-packet-size 1024\n"\
	 "set inferior-auto-start-dyld 0\n"\
	 "set remote executable-directory %@\n"\
	 "set remote noack-mode 1\n"\
	 "set sharedlibrary load-rules \\\".*\\\" \\\".*\\\" container\n"\
	 "set minimal-signal-handling 1\n"\
	 "set mi-show-protections off\n"\
	 "target remote-mobile %s\n"\
	 "file \"%@\"\n"\
	 "add-dsym \"%@\"\n"\
	 "run\n"\
	 "set minimal-signal-handling 0\n"\
	 "set inferior-auto-start-dyld 1\n"\
	 "set inferior-auto-start-cfm off\n"\
	 "set sharedLibrary load-rules dyld \".*libobjc.*\" all dyld \".*CoreFoundation.*\" all dyld \".*Foundation.*\" all dyld \".*libSystem.*\" all dyld \".*AppKit.*\" all dyld \".*PBGDBIntrospectionSupport.*\" all dyld \".*/usr/lib/dyld.*\" all dyld \".*CarbonDataFormatters.*\" all dyld \".*libauto.*\" all dyld \".*CFDataFormatters.*\" all dyld \"/System/Library/Frameworks\\\\\\\\|/System/Library/PrivateFrameworks\\\\\\\\|/usr/lib\" extern dyld \".*\" all exec \".*\" all\n"\
	 "sharedlibrary apply-load-rules all\n",
		 device_support_path, device_support_path, device_support_path,
		 [[app_remote_path stringByDeletingLastPathComponent]
		     stringByReplacingOccurrencesOfString:@"/private/var"
		     withString:@"/var"], [app_path stringByDeletingLastPathComponent],
		 app_remote_path, gdb_unix_socket_path, app_path, dsym_path];
	cmds = [cmds stringByAppendingFormat:@"%s\n", BUILTIN_DEBUGGER_CMDS];
	NSString *user_cmds = [NSString stringWithContentsOfFile:
	    @"debugger_cmds" encoding:NSUTF8StringEncoding error:nil];
	if (user_cmds != nil) {
	    cmds = [cmds stringByAppendingString:user_cmds];
	    cmds = [cmds stringByAppendingString:@"\n"];
	}
	if (getenv("no_continue") == NULL) {
	    cmds = [cmds stringByAppendingString:@"continue\n"];
	}
	assert([cmds writeToFile:cmds_path atomically:YES
		encoding:NSUTF8StringEncoding error:nil]);

	// Start gdb.
	float product_version_f = [product_version floatValue];
	NSString *remote_arch = product_version_f < 5.0 ? @"armv6" : @"armv7";

	// Forward ^C to gdb.
	signal(SIGINT, sigforwarder);

	gdb_task = [[NSTask launchedTaskWithLaunchPath:gdb_path
	    arguments:[NSArray arrayWithObjects:@"--arch", remote_arch, @"-q",
	    @"-x", cmds_path, nil]] retain];
    }
    else {
	NSString *lldb_path = [[NSString stringWithUTF8String:xcode_dir]
	    stringByAppendingPathComponent:@"usr/bin/lldb"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:lldb_path]) {
	    fprintf(stderr, "Can't locate either gdb or lldb within Xcode");
	    exit(1);
	}

	NSString *tmpdir = NSTemporaryDirectory();
	assert(tmpdir != nil);
	char lldb_socket_path[PATH_MAX];
	snprintf(lldb_socket_path, sizeof lldb_socket_path,
		"%s/rubymotion-lldb-XXXXXX",
		[NSTemporaryDirectory() fileSystemRepresentation]);
	assert(mktemp(lldb_socket_path) != NULL);

	// Prepare lldb commands file.
       NSString *py_cmds = [NSString stringWithFormat:@""\
   	"import sys\n"\
   	"import lldb\n"\
   	"debugger = lldb.debugger\n"\
	/*"debugger.EnableLog(\"lldb\", [\"all\"])\n"*/\
        "error = lldb.SBError()\n"\
   	"target = debugger.CreateTarget(\"%@\", \"armv7s-apple-ios\", \"remote-ios\", False, error)\n"\
   	"module = target.FindModule(target.GetExecutable())\n"\
   	"filespec = lldb.SBFileSpec(\"%@\", False)\n"\
   	"module.SetPlatformFileSpec(filespec)\n"\
        "error = lldb.SBError()\n"\
	"listener = lldb.SBListener(\"my-listener\")\n"\
   	"process = target.ConnectRemote(listener, \"unix-accept://%s\", None, error)\n"\
	"broadcaster = process.GetBroadcaster()\n"\
	"broadcaster.AddListener(listener, lldb.SBProcess.eBroadcastBitStateChanged)\n"\
   	"while True:\n"\
        "  print \"Connecting...\"\n"\
        "  event = lldb.SBEvent()\n"\
   	"  if listener.WaitForEvent(1, event):\n"\
        "    if process.GetStateFromEvent(event) == lldb.eStateConnected:\n"\
        "      break\n"\
   	"print \"Launching...\"\n"\
        "error = lldb.SBError()\n"\
   	"ok = process.RemoteLaunch(None, None, None, None, None, None, 0, False, error)\n"\
   	"while True:\n"\
        "  event = lldb.SBEvent()\n"\
   	"  if listener.WaitForEvent(1, event):\n"\
        "    if process.GetStateFromEvent(event) == lldb.eStateRunning:\n"\
        "      break\n"\
        "    if process.GetStateFromEvent(event) == lldb.eStateStopped:\n"\
        "      print \"Running...\"\n"\
	"      process.Continue()\n"\
	"broadcaster.RemoveListener(listener)\n",
   	     app_path, app_remote_path, lldb_socket_path];
	NSString *py_cmds_path = [NSString pathWithComponents:
	    [NSArray arrayWithObjects:NSTemporaryDirectory(),
	    @"_deploylldbcmds.py", nil]];
	assert([py_cmds writeToFile:py_cmds_path atomically:YES
		encoding:NSUTF8StringEncoding error:nil]);

	NSString *cmds = [NSString stringWithFormat:
	    @"command script import %@", py_cmds_path];
	NSString *cmds_path = [NSString pathWithComponents:
	    [NSArray arrayWithObjects:NSTemporaryDirectory(),
	    @"_deploylldbcmds", nil]];
	assert([cmds writeToFile:cmds_path atomically:YES
		encoding:NSUTF8StringEncoding error:nil]);

	// Forward ^C to lldb.
	signal(SIGINT, sigforwarder);

	// Run lldb.
	gdb_task = [[NSTask launchedTaskWithLaunchPath:lldb_path
	    arguments:[NSArray arrayWithObjects:@"-s", cmds_path, nil]] retain];

	// Connect to the lldb UNIX socket.
	const int lldb_socket = socket(PF_LOCAL, SOCK_STREAM, 0);
	if (lldb_socket == -1) {
	    perror("socket()");
	    return;
	}

	fcntl(lldb_socket, F_SETFL, O_NONBLOCK);
	fcntl(gdb_fd, F_SETFL, O_NONBLOCK);

	struct sockaddr_un name;
	name.sun_family = PF_LOCAL;
	strncpy(name.sun_path, lldb_socket_path,
		sizeof(name.sun_path));

	while (true) {
	    if (connect(lldb_socket, (struct sockaddr *)&name, SUN_LEN(&name))
		    == -1) {
		if (errno != ENOENT) {
		    perror("connect()");
		    return;
		}
	    }
	    else {
		break;
	    }
	    usleep(200000);
	}

	// We are connected, start redirecting input to/from the debug server.
	char buf[1024];
	ssize_t len;
	while (true) {
	    fd_set read_fds;
	    FD_ZERO(&read_fds);
	    FD_SET(gdb_fd, &read_fds);
	    FD_SET(lldb_socket, &read_fds);

	    struct timeval tv;
	    tv.tv_sec = 0;
	    tv.tv_usec = 10000;
	    int n = select(lldb_socket + 1, &read_fds, NULL, NULL, &tv);
	    if (n == -1) {
		perror("select()");
		break;
	    }
	    if (n > 0) {
		if (FD_ISSET(lldb_socket, &read_fds)) {
		    len = read(lldb_socket, buf, sizeof buf);
		    if (len > 0) {
			write(gdb_fd, buf, len);
		    }
		}
		if (FD_ISSET(gdb_fd, &read_fds)) {
		    len = read(gdb_fd, buf, sizeof buf);
		    if (len > 0) {
			write(lldb_socket, buf, len);
		    }
		}
	    }
	}
    }

    [gdb_task waitUntilExit];
}

static void
device_go(am_device_t dev)
{
    install_application(dev);
    if (getenv("install_only") == NULL) {
	start_debug_server(dev);
    }
}

static void
device_subscribe_cb(am_device_notif_context_t ctx)
{
    am_device_t dev = am_device_from_notif_context(ctx);
    CFStringRef name = _AMDeviceGetName(dev);
    if (name != NULL) {
	if (discovery_mode) {
	    printf("%s\n", [(id)name UTF8String]);
	    exit(0);
	}
	else if (console_mode) {
	    open_console(dev);
	    exit(0);
	}
	else if ([(id)name isEqualToString:device_id]) {
	    LOG("found usb mobile device %s", [(id)name UTF8String]);
	    device_go(dev);
	    exit(0);
	}
    }
}

static void
usage(void)
{
    system("open http://www.youtube.com/watch?v=1orMXD_Ijbs&feature=fvst");
    //fprintf(stderr, "usage: deploy [-d] <path-to-app>\n");
    exit(1);
}

int
main(int argc, char **argv)
{
    /*NSAutoreleasePool *pool =*/ [[NSAutoreleasePool alloc] init];

    for (int i = 1; i < argc; i++) {
	if (strcmp(argv[i], "-d") == 0) {
	    debug_mode = true;
	}
	else if (strcmp(argv[i], "-D") == 0) {
	    discovery_mode = true;
	}
	else if (strcmp(argv[i], "-c") == 0) {
	    console_mode = true;
	}
	else {
	    if (device_id == nil) {
		device_id = [[NSString stringWithUTF8String:argv[i]] retain];
	    }
	    else {
		if (app_package_path != nil) {
		    usage();
		}
		app_package_path = [[NSString stringWithUTF8String:argv[i]]
		    retain];
	    }
	} 
    }

    if (!discovery_mode && !console_mode) {
	if (device_id == nil || app_package_path == nil) {
	    usage();
	}
	app_package_data =
	    [[NSData dataWithContentsOfFile:app_package_path] retain];
	if (app_package_data == nil) {
	    fprintf(stderr, "can't read data from %s\n",
		    [app_package_path fileSystemRepresentation]);
	    exit(1);
	}
    }

    init_private_funcs();

    void *notif = NULL;
    PERFORM("subscribing to device notification",
	    _AMDeviceNotificationSubscribe(device_subscribe_cb, 0, 0, 0,
		&notif));

    // Run one second, should be enough to catch an attached device.
    [[NSRunLoop mainRunLoop] runUntilDate:
	[NSDate dateWithTimeIntervalSinceNow:1]];

    if (!discovery_mode) {
	fprintf(stderr, "error: can't find device ID %s\n",
		[device_id UTF8String]);
    }
    exit(1);
}
