#import <Foundation/Foundation.h>
#include "MobileDevice.h"

CFStringRef AMDeviceGetName(struct am_device *dev);

static void
die(const char *func, int retcode)
{
    printf("%s() error: code %d\n", func, retcode);
    exit(1);
}

static void
send_plist(NSFileHandle *handle, id plist)
{
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    uint32_t nlen = CFSwapInt32HostToBig([data length]);
    [handle writeData:[[[NSData alloc] initWithBytes:&nlen length:sizeof(nlen)] autorelease]];
    [handle writeData:data];
}

static id
read_plist(NSFileHandle *handle)
{
    NSData *datalen = [handle availableData];
    if ([datalen length] < 4) {
	printf("error: datalen packet not found\n");
	exit(1);
    }
    uint32_t *lenp = (uint32_t *)[datalen bytes];
    uint32_t len = CFSwapInt32BigToHost(*lenp);

    NSMutableData *data = [NSMutableData data];
    while (true) {
	NSData *chunk = [handle availableData];
	if (chunk == nil || [chunk length] == 0) {
	    break;
	}
	[data appendData:chunk];
	if ([data length] >= len) {
	    break;
	}
    }

    return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
}

static NSString *app_package_path = nil;
static NSData *app_package_data = nil;

static void
device_go(struct am_device *dev)
{
    printf("connecting to device\n");
    int retcode = AMDeviceConnect(dev);
    if (retcode != 0) {
	die("AMDeviceConnect", retcode);
    }

    printf("pairing device\n");
    retcode = AMDeviceValidatePairing(dev);
    if (retcode != 0) {
	die("AMDeviceValidatePairing", retcode);
    }

    printf("creating lockdown session\n");
    retcode = AMDeviceStartSession(dev);
    if (retcode != 0) {
	die("AMDeviceStartSession", retcode);
    }

    printf("starting afc service\n");
    struct afc_connection *conn = NULL;
    retcode = AMDeviceStartService(dev, CFSTR("com.apple.afc"), &conn, NULL);
    if (retcode != 0) {
	die("AMDeviceStartService", retcode);
    }
    assert(conn != NULL);

    printf("opening afc connection\n");
    struct afc_connection *afc = NULL;
    retcode = AFCConnectionOpen(conn, 0, &afc);
    if (retcode != 0) {
	die("AFCConnectionOpen", retcode);
    }
    assert(afc != NULL);

    printf("copying package into public staging directory\n");
    NSString *remote_pkg_path = [NSString stringWithFormat:@"PublicStaging/%@", [app_package_path lastPathComponent]];
    AFCDirectoryCreate(afc, "PublicStaging");
    afc_file_ref fileref;
    retcode = AFCFileRefOpen(afc, (char *)[remote_pkg_path fileSystemRepresentation], 0x3 /* write */, &fileref);
    if (retcode != 0) {
	die("AFCFileRefOpen", retcode);
    }
    retcode = AFCFileRefWrite(afc, fileref, (void *)[app_package_data bytes], [app_package_data length]);
    if (retcode != 0) {
	die("AFCFileRefWrite", retcode);
    }
    retcode = AFCFileRefClose(afc, fileref);
    if (retcode != 0) {
	die("AFCFileRefClose", retcode);
    }

    printf("starting installer proxy service\n");
    struct afc_connection *ipc = NULL;
    retcode = AMDeviceStartService(dev, CFSTR("com.apple.mobile.installation_proxy"), &ipc, NULL);
    if (retcode != 0) {
	die("AMDeviceStartService", retcode);
    }
    assert(ipc != NULL);
    NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:(int)ipc closeOnDealloc:NO];

    printf("send install command\n");
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
	if (percent == nil) {
	    break;
	}
	printf("progress... %d%%...\n", [percent intValue]);
    }

    printf("complete!\n");
    [handle release];
}

static void
device_subscribe_cb(struct am_device_notification_callback_info *info)
{
    CFStringRef name = AMDeviceGetName(info->dev);
    if (name != NULL) {
	printf("found usb mobile device %s\n", [(id)name UTF8String]);

	device_go(info->dev);
	exit(0);
    }
}

int
main(int argc, char **argv)
{
    if (argc != 2) {
	printf("usage: %s <path-to-app>\n", argv[0]);
	exit(1);
    }

    [[NSAutoreleasePool alloc] init];
    app_package_path = [[NSString stringWithUTF8String:argv[1]] retain];
    app_package_data = [[NSData dataWithContentsOfFile:app_package_path] retain];
    if (app_package_data == nil) {
	printf("can't read data from %s\n", [app_package_path fileSystemRepresentation]);
	exit(1);
    }

    struct am_device_notification *notif = NULL;
    const int retcode = AMDeviceNotificationSubscribe(device_subscribe_cb, 0, 0, 0, &notif);
    if (retcode != 0) {
	die("AMDeviceNotificationSubscribe", retcode);
    }

    printf("waiting for devices to show up\n");
    [[NSRunLoop mainRunLoop] run];
    return 0;
}
