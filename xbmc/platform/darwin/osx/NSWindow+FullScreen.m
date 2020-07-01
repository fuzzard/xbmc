#import "NSWindow+FullScreen.h"

@implementation NSWindow (FullScreen)

- (BOOL)isFullScreen
{
  return (self.styleMask & NSFullScreenWindowMask);
}

@end
