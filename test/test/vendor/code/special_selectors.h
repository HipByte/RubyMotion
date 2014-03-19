#import <Foundation/Foundation.h>

@interface TestSpecialSelectors : NSObject {
    // To be able to build on 32-bit (OS X 10.7) we need to specify ivars.
    NSMutableArray *_array;
    NSMutableDictionary *_dictionary;
    NSNumber *_aSetter;
    NSNumber *_propertyForKVCValidation;
}

@property (strong) NSNumber *aSetter;
@property (assign) NSNumber *propertyForKVCValidation;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

- (BOOL)isPredicate:(NSNumber *)aSetterValue;

- (BOOL)__validate__:(NSError **)error;

@end
