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
+ (BOOL)isJailbroken;
+ (NSBundle*)mainAppBundle;
@end
