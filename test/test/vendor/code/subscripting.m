#import "subscripting.h"

@interface TestSubscripting ()
@property (strong) NSMutableArray *array;
@property (strong) NSMutableDictionary *dictionary;
@end

@implementation TestSubscripting

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
  return self.array[index];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
{
  self.array[index] = object;
}

- (id)objectForKeyedSubscript:(id)key;
{
  return self.dictionary[key];
}

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;
{
  self.dictionary[key] = object;
}

@end