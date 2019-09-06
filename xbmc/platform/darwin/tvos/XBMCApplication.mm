/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "platform/darwin/tvos/XBMCApplication.h"

#import "platform/darwin/NSLogDebugHelpers.h"
#import "platform/darwin/tvos/PreflightHandler.h"
#import "platform/darwin/tvos/TVOSTopShelf.h"
#import "platform/darwin/tvos/XBMCController.h"

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation XBMCApplicationDelegate
XBMCController* m_xbmcController;

- (void)applicationWillResignActive:(UIApplication*)application
{
  [m_xbmcController pauseAnimation];
  [m_xbmcController becomeInactive];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
  [m_xbmcController resumeAnimation];
  [m_xbmcController enterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
  if (application.applicationState == UIApplicationStateBackground)
  {
    // the app is turn into background, not in by screen lock which has app state inactive.
    [m_xbmcController enterBackground];
  }
}

- (void)applicationWillTerminate:(UIApplication*)application
{
  [m_xbmcController stopAnimation];
}

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
  // check if apple removed our Cache folder first
  // this will trigger the restore if there is a backup available
  CPreflightHandler::CheckForRemovedCacheFolder();

  // This needs to run before anything does any CLog::Log calls
  // as they will directly cause guisetting to get accessed/created
  // via debug log settings.
  CPreflightHandler::MigrateUserdataXMLToNSUserDefaults();

  NSError* err = nullptr;
  if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err])
  {
    NSLog(@"AVAudioSession setCategory failed: %ld", static_cast<long>(err.code));
  }
  err = nil;
  if (![[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMoviePlayback error:&err])
  {
    NSLog(@"AVAudioSession setMode failed: %ld", static_cast<long>(err.code));
  }
  err = nil;
  if (![[AVAudioSession sharedInstance] setActive:YES error:&err])
  {
    NSLog(@"AVAudioSession setActive YES failed: %ld", static_cast<long>(err.code));
  }


  UIScreen* currentScreen = [UIScreen mainScreen];
  m_xbmcController = [[XBMCController alloc] initWithFrame:[currentScreen bounds]
                                                withScreen:currentScreen];
  [m_xbmcController startAnimation];
}

- (BOOL)application:(UIApplication*)app
            openURL:(NSURL*)url
            options:(NSDictionary<NSString*, id>*)options
{
  NSArray* urlComponents = [[url absoluteString] componentsSeparatedByString:@"/"];
  NSString* action = urlComponents[2];
  if ([action isEqualToString:@"display"] || [action isEqualToString:@"play"])
    CTVOSTopShelf::GetInstance().HandleTopShelfUrl(std::string{url.absoluteString.UTF8String},
                                                   true);
  return YES;
}

- (void)dealloc
{
  [m_xbmcController stopAnimation];
}
@end

static void SigPipeHandler(int s)
{
  NSLog(@"We Got a Pipe Signal: %d____________", s);
}

int main(int argc, char* argv[])
{
  @autoreleasepool
  {
    signal(SIGPIPE, SigPipeHandler);

    int retVal = 0;
    @try
    {
      retVal =
          UIApplicationMain(argc, argv, nil, NSStringFromClass([XBMCApplicationDelegate class]));
    }
    @catch (id theException)
    {
      ELOG(@"%@", theException);
    }
    @finally
    {
      ILOG(@"This always happens.");
    }

    return retVal;
  }
}
