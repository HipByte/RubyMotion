#import <Foundation/Foundation.h>
#include <dlfcn.h>

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

#define LOG(fmt, ...) \
    do { \
	fprintf(stderr, "log: "); \
	fprintf(stderr, fmt, ##__VA_ARGS__); \
	fprintf(stderr, "\n"); \
    } \
    while (0)

#define PERFORM(what, call) \
    do { \
	LOG(what); \
	int code = call; \
	if (code != 0) { \
	    fprintf(stderr, "error when %s: code %d\n", what, code); \
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

static NSString *app_package_path = nil;
static NSData *app_package_data = nil;

static void
device_go(am_device_t dev)
{
    PERFORM("connecting to device", _AMDeviceConnect(dev));
    PERFORM("pairing device", _AMDeviceValidatePairing(dev));
    PERFORM("creating lockdown session", _AMDeviceStartSession(dev));

    int afc_fd = 0;
    PERFORM("starting file copy service", _AMDeviceStartService(dev,
		CFSTR("com.apple.afc"), &afc_fd, NULL));
    assert(afc_fd > 0);

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
    PERFORM("opening remove package path", _AFCFileRefOpen(afc_conn,
		[remote_pkg_path fileSystemRepresentation], 0x3 /* write */,
		&afc_fileref));
    assert(afc_fileref != NULL);

    PERFORM("writing data", _AFCFileRefWrite(afc_conn, afc_fileref,
		[app_package_data bytes], [app_package_data length]));

    PERFORM("closing remote package path", _AFCFileRefClose(afc_conn,
		afc_fileref));

    int ipc_fd = 0;
    PERFORM("starting installer proxy service", _AMDeviceStartService(dev,
		CFSTR("com.apple.mobile.installation_proxy"), &ipc_fd, NULL));
    assert(ipc_fd > 0);

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
    [handle release];
}

static void
device_subscribe_cb(am_device_notif_context_t ctx)
{
    am_device_t dev = am_device_from_notif_context(ctx);
    CFStringRef name = _AMDeviceGetName(dev);
    if (name != NULL) {
	LOG("found usb mobile device %s", [(id)name UTF8String]);
	device_go(dev);
	exit(0);
    }
}

int
main(int argc, char **argv)
{
    if (argc != 2) {
	fprintf(stderr, "usage: %s <path-to-app>\n", argv[0]);
	exit(1);
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    app_package_path = [[NSString stringWithUTF8String:argv[1]] retain];
    app_package_data =
	[[NSData dataWithContentsOfFile:app_package_path] retain];
    if (app_package_data == nil) {
	fprintf(stderr, "can't read data from %s\n",
		[app_package_path fileSystemRepresentation]);
	exit(1);
    }

    init_private_funcs();

    void *notif = NULL;
    PERFORM("subscribing to device notification",
	    _AMDeviceNotificationSubscribe(device_subscribe_cb, 0, 0, 0,
		&notif));

    [[NSRunLoop mainRunLoop] run];

    [pool release];
    return 0;
}
