/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

@interface tvosShared : NSObject
+ (NSString*)getSharedID;
+ (NSURL*)getSharedURL;
+ (BOOL) IsTVOSSandboxed;
+ (BOOL)isJailbroken;
@end

@implementation tvosShared : NSObject

+ (NSString*)getSharedID {
  NSBundle* mainAppBundle = NSBundle.mainBundle;
  if ([mainAppBundle.bundleURL.pathExtension isEqualToString:@"appex"]) { // We're in a extension
    // Peel off two directory levels - Kodi.app/PlugIns/MY_APP_EXTENSION.appex
    mainAppBundle = [NSBundle bundleWithURL:mainAppBundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent];
  }
  return [@"group." stringByAppendingString:mainAppBundle.bundleIdentifier];
}

+ (NSURL*)getSharedURL {
  NSString* sharedID = [self getSharedID];
  if ([self isJailbroken])
    return [[NSURL fileURLWithPath:@"/var/mobile/Library/Caches"] URLByAppendingPathComponent:sharedID];
  else
  {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL* sharedUrl = [fileManager containerURLForSecurityApplicationGroupIdentifier:sharedID];
    sharedUrl = [sharedUrl URLByAppendingPathComponent:@"Library" isDirectory:YES];
    sharedUrl = [sharedUrl URLByAppendingPathComponent:@"Caches" isDirectory:YES];
    return sharedUrl;
  }
}

+ (BOOL) IsTVOSSandboxed
{
  static int ret = -1;
  if (ret == -1)
  {
    NSBundle* bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) { // We're in a extension
      // Peel off two directory levels - Kodi.app/PlugIns/MY_APP_EXTENSION.appex
      bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }

    ret = 1;// default to "sandboxed"

    // we re NOT sandboxed if we are installed in /var/mobile/Applications with greeng0blin jailbreak
    if ([[bundle executablePath] containsString:@"/var/mobile/Applications/"])
    {
      ret = 0;
    }
  }
  return ret == 1;
}

+ (BOOL)isJailbroken {
  return ![self IsTVOSSandboxed];
}

@end
