#import <Foundation/Foundation.h>

@interface TestSubscripting : NSObject {
    NSMutableArray *_array;
    NSMutableDictionary *_dictionary;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

@end
