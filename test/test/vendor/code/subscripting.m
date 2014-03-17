#import "subscripting.h"

@interface TestSubscripting ()
@property (strong) NSMutableArray *array;
@property (strong) NSMutableDictionary *dictionary;
@end

@implementation TestSubscripting

@synthesize array = _array;
@synthesize dictionary = _dictionary;

- (instancetype)init;
{
  if ((self = [super init])) {
    _array = [NSMutableArray new];
    _dictionary = [NSMutableDictionary new];
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

@end
