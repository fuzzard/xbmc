#pragma once

/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Cocoa/Cocoa.h>

@interface OSXGLWindow : NSWindow <NSWindowDelegate>
{
}

+(void) SetMenuBarVisible;
+(void) SetMenuBarInvisible;

-(id) initWithContentRect:(NSRect)box styleMask:(uint)style;
-(void) dealloc;
-(BOOL) windowShouldClose:(id) sender;
-(void) windowDidExpose:(NSNotification *) aNotification;
-(void) windowDidMove:(NSNotification *) aNotification;
-(void) windowDidResize:(NSNotification *) aNotification;
-(void) windowDidMiniaturize:(NSNotification *) aNotification;
-(void) windowDidDeminiaturize:(NSNotification *) aNotification;
-(void) windowDidBecomeKey:(NSNotification *) aNotification;
-(void) windowDidResignKey:(NSNotification *) aNotification;
-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
-(void) windowWillStartLiveResize:(NSNotification *)aNotification;
-(void) windowDidEndLiveResize:(NSNotification *)aNotification;
-(void) windowDidEnterFullScreen: (NSNotification*)pNotification;
-(void) windowWillEnterFullScreen: (NSNotification*)pNotification;
-(void) windowDidExitFullScreen: (NSNotification*)pNotification;
-(void) windowWillExitFullScreen: (NSNotification*)pNotification;
-(void) windowDidChangeScreen:(NSNotification *)notification;
@end
