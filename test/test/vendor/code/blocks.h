#import "Availability.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@interface TestBlocks : NSObject
typedef void (^SampleBlock)(NSString* string);
- (SampleBlock)map;
@end
