#import "Availability.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

struct MyStructHasName {
    id name;
};

struct MyStructTestConvert {
    long m_long;
    unsigned long m_ulong;
    long long m_longlong;
    unsigned long long m_ulonglong;
    double m_double;
};

struct MyStruct4C {
    char a, b, c, d;
};

struct MyStructHasStructPointer {
    struct MyStruct4C *field;
};

typedef id (^MyBlock)(void);

@protocol TestProtocol <NSObject>
- (BOOL)testProtocolFlag;
- (void)setTestProtocolFlag:(BOOL)testFlag;
@end

@protocol TestConformsToProtocol <NSObject>
@required
- (int)requiredMethod1;
- (int)requiredMethod2;
@optional
- (int)optionalMethod3;
@end

@interface TestMethod : NSObject <TestProtocol, NSCopying>
{
    BOOL _testProtocolFlag;
}

- (CGSize)methodReturningCGSize;
- (CGRect)methodReturningCGRect;
+ (BOOL)testMethodReturningCGSize:(TestMethod *)testMethod;
+ (BOOL)testMethodReturningCGRect:(TestMethod *)testMethod;

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
+ (BOOL)testMethodAcceptingUIInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (BOOL)testMethodAcceptingUIEdgeInsets:(UIEdgeInsets)insets;
#endif

+ (id)testMethodCallingBlock:(MyBlock)block;
+ (BOOL)testMethodAcceptingCFType:(CFStringRef)cfstring;
+ (BOOL)testMethodAcceptingMyStruct4C:(struct MyStruct4C)s;
+ (BOOL)testMethodAcceptingMyStruct4C:(struct MyStruct4C)s another:(struct MyStruct4C)s2;
+ (BOOL)testMethodAcceptingMyStruct4CValue:(NSValue *)val;

+ (BOOL)testValueForKey:(Class)klass expected:(id)expected;

+ (int)testPointerToStrings:(char **)strs length:(int)len;

- (int)methodReturningLargeInt;
- (id)methodSendingNew:(Class)klass;

+ (BOOL)testConformsToProtocol:(id <TestConformsToProtocol>)obj;

+ (instancetype)newRetainedInstance;
+ (instancetype)newbuildRetainedInstance;
- (instancetype)copyAndReturnRetainedInstance;
- (instancetype)retainedCopy;
- (instancetype)copyingAndReturningRetainedInstance;

+ (BOOL)isReturnValueRetained:(id)object forSelector:(SEL)sel;

@end

@interface TestIterator : NSObject <NSFastEnumeration>
@end

static inline int TestInlineFunction(int x, int y, int z) {
  return x + y + z;
}

extern int lowerCaseConstant;
@interface lowerCaseClass : NSObject
@end

#define TestStringConstant "foo"
#define TestNSStringConstant @"foo"

typedef int (^ReturnsIntBlock)();
void KreateStackBlock(void (^inputBlock)(ReturnsIntBlock));
ReturnsIntBlock KreateMallocBlock(int input);
ReturnsIntBlock KreateGlobalBlock();


typedef struct MyStructHasBool {
    BOOL bool_value;
} MyStructHasBool;

typedef struct MyUnionHasBool {
    MyStructHasBool st;
    int value;
} MyUnionHasBool;

@interface TestBoolType : NSObject
{
    NSNumber *_value;
}

@property (nonatomic, strong) NSNumber *value;

- (id)initWithBoolPtr:(BOOL*)val;
- (id)initWithStruct:(MyStructHasBool)val;
- (id)initWithUnion:(MyUnionHasBool)val;
- (BOOL)returnBool;

@end
