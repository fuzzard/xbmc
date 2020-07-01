/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "OSXGLWindow.h"

#include "Application.h"
#import "windowing/osx/OSXGLView.h"
#include "windowing/osx/WinEventsOSX.h"
#include "windowing/XBMC_events.h"
#include "messaging/ApplicationMessenger.h"

#include "platform/darwin/DarwinUtils.h"
#include "platform/darwin/osx/CocoaInterface.h"

#include "windowing/WinSystem.h"
#include "windowing/osx/WinSystemOSX.h"
#include "ServiceBroker.h"

#import "platform/darwin/osx/NSWindow+FullScreen.h"

//#import <Foundation/Foundation.h>

#include <cstring>

//------------------------------------------------------------------------------------------
@implementation OSXGLWindow

- (id)initWithContentRect:(NSRect)box styleMask:(uint)style
{
  self = [super initWithContentRect:box styleMask:style backing:NSBackingStoreBuffered defer:YES];
  [self setDelegate:self];
  [self setAcceptsMouseMovedEvents:YES];
  // autosave the window position/size
  [[self windowController]
      setShouldCascadeWindows:NO]; // Tell the controller to not cascade its windows.
  [self setFrameAutosaveName:@"OSXGLWindowPositionHeightWidth"]; // Specify the autosave name for
                                                                 // the window.

  g_application.m_AppFocused = true;

  return self;
}

- (void)dealloc
{
  [self setDelegate:nil];
}

- (BOOL)windowShouldClose:(id)sender
{
  // NSLog(@"windowShouldClose");

  if (!g_application.m_bStop)
  {
    XBMC_Event newEvent;
    memset(&newEvent, 0, sizeof(newEvent));
    newEvent.type = XBMC_QUIT;
    CWinSystemOSX* winSystem(dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem()));
    winSystem->MessagePush(&newEvent);
  }
  return NO;
}

- (void)windowDidExpose:(NSNotification*)aNotification
{
  // NSLog(@"windowDidExpose");
  g_application.m_AppFocused = true;
}

- (void)windowDidMove:(NSNotification*)aNotification
{
  // NSLog(@"windowDidMove");
  NSOpenGLContext* context = [NSOpenGLContext currentContext];
  if (context)
  {
    if ([context view])
    {
      NSPoint window_origin = [[[context view] window] frame].origin;
      XBMC_Event newEvent;
      memset(&newEvent, 0, sizeof(newEvent));
      newEvent.type = XBMC_VIDEOMOVE;
      newEvent.move.x = window_origin.x;
      newEvent.move.y = window_origin.y;
      CWinSystemOSX* winSystem(dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem()));
      winSystem->MessagePush(&newEvent);
    }
  }
}

- (void)windowDidResize:(NSNotification*)aNotification
{
  // NSLog(@"windowDidResize");
}

- (void)windowDidChangeScreen:(NSNotification*)notification
{
  // user has moved the window to a
  // different screen
  if (!CServiceBroker::GetWinSystem()->IsFullScreen())
  {
    CWinSystemOSX* winSystem(dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem()));
    winSystem->SetMovedToOtherScreen(true);
  }
    
}

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize
{
  // NSLog(@"windowWillResize");
  return frameSize;
}

- (void)windowWillStartLiveResize:(NSNotification*)aNotification
{
  // NSLog(@"windowWillStartLiveResize");
}

- (void)windowDidEndLiveResize:(NSNotification*)aNotification
{
  // NSLog(@"windowDidEndLiveResize");
  NSRect rect = [self contentRectForFrameRect:[self frame]];

  // send a message so that videoresolution (and refreshrate) is changed
  if (rect.size.width != 0 && rect.size.height != 0)
  {
    XBMC_Event msg{XBMC_VIDEORESIZE};
    msg.resize = {static_cast<int>(rect.size.width), static_cast<int>(rect.size.height)};
    CWinSystemOSX* winSystem(dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem()));
    winSystem->MessagePush(&msg);
  }
}

- (void)windowDidEnterFullScreen:(NSNotification*)pNotification
{
}

- (void)windowWillEnterFullScreen:(NSNotification*)pNotification
{

  // if osx is the issuer of the toggle
  // call XBMCs toggle function
  if (!dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->GetFullscreenWillToggle())
  {
    // indicate that we are toggling
    // flag will be reset in SetFullscreen once its
    // called from XBMCs gui thread
    dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->SetFullscreenWillToggle(true);

    KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);
  }
  else
  {
    // in this case we are just called because
    // of xbmc did a toggle - just reset the flag
    // we don't need to do anything else
    dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->SetFullscreenWillToggle(false);
  }
}

- (void)windowDidExitFullScreen:(NSNotification*)pNotification
{
  // if osx is the issuer of the toggle
  // call XBMCs toggle function
  if (!dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->GetFullscreenWillToggle())
  {
    // indicate that we are toggling
    // flag will be reset in SetFullscreen once its
    // called from XBMCs gui thread
    dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->SetFullscreenWillToggle(true);
    KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);
  }
  else
  {
    // in this case we are just called because
    // of xbmc did a toggle - just reset the flag
    // we don't need to do anything else
    dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem())->SetFullscreenWillToggle(false);
  }
}

- (void)windowWillExitFullScreen:(NSNotification*)pNotification
{
}

- (NSApplicationPresentationOptions)window:(NSWindow*)window
      willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
  return (proposedOptions | NSApplicationPresentationAutoHideToolbar);
}

- (void)windowDidMiniaturize:(NSNotification*)aNotification
{
  // NSLog(@"windowDidMiniaturize");
  g_application.m_AppFocused = false;
}

- (void)windowDidDeminiaturize:(NSNotification*)aNotification
{
  // NSLog(@"windowDidDeminiaturize");
  g_application.m_AppFocused = true;
}

- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
  // NSLog(@"windowDidBecomeKey");
  g_application.m_AppFocused = true;
  //CWinEventsOSXImp::EnableInput();
}

- (void)windowDidResignKey:(NSNotification*)aNotification
{
  // NSLog(@"windowDidResignKey");
  g_application.m_AppFocused = false;
  //CWinEventsOSXImp::DisableInput();
}

- (void)mouseDown:(NSEvent*)theEvent
{
  // NSLog(@"mouseDown");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
  // NSLog(@"rightMouseDown");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)otherMouseDown:(NSEvent*)theEvent
{
  // NSLog(@"otherMouseDown");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)mouseUp:(NSEvent*)theEvent
{
  // NSLog(@"mouseUp");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)rightMouseUp:(NSEvent*)theEvent
{
  // NSLog(@"rightMouseUp");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)otherMouseUp:(NSEvent*)theEvent
{
  // NSLog(@"otherMouseUp");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  // NSLog(@"mouseMoved");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)mouseDragged:(NSEvent*)theEvent
{
  // NSLog(@"mouseDragged");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)rightMouseDragged:(NSEvent*)theEvent
{
  // NSLog(@"rightMouseDragged");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
  {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)otherMouseDragged:(NSEvent*)theEvent
{
  // NSLog(@"otherMouseDragged");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)scrollWheel:(NSEvent*)theEvent
{
  // NSLog(@"scrollWheel");
  // if it is hidden - mouse is belonging to us!
  if (Cocoa_IsMouseHidden())
      {}
    //CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

/*- (BOOL)isFullScreen
{
  return (([self styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}*/

@end
