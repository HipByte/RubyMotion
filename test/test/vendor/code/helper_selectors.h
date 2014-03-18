#import <Foundation/Foundation.h>

@interface TestHelperSelectors : NSObject {
    // To be able to build on 32-bit (OS X 10.7) we need to specify ivars.
    NSMutableArray *_array;
    NSMutableDictionary *_dictionary;
    NSNumber *_aSetter;
}

@property (strong) NSNumber *aSetter;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

- (BOOL)isPredicate:(NSNumber *)aSetterValue;

@end
