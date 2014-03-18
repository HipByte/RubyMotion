#import "helper_selectors.h"

@interface TestHelperSelectors ()
@property (strong) NSMutableArray *array;
@property (strong) NSMutableDictionary *dictionary;
@end

@implementation TestHelperSelectors

// To be able to build on 32-bit (OS X 10.7) we need to synthesize properties.
@synthesize array = _array;
@synthesize dictionary = _dictionary;
@synthesize aSetter = _aSetter;

- (instancetype)init;
{
  if ((self = [super init])) {
    _array = [NSMutableArray new];
    // Otherwise replaceObjectAtIndex:withObject: won't work.
    [_array addObject:[NSNull null]];
    _dictionary = [NSMutableDictionary new];
    _aSetter = nil;
  }
  return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index;
{
  return [self.array objectAtIndex:index];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
{
  [self.array replaceObjectAtIndex:index withObject:object];
}

- (id)objectForKeyedSubscript:(id)key;
{
  return [self.dictionary objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;
{
  [self.dictionary setObject:object forKey:key];
}

- (BOOL)isPredicate:(NSNumber *)aSetterValue;
{
    return aSetterValue.integerValue == self.aSetter.integerValue;
}

@end
