/*
 *      Copyright (C) 2010-2013 Team XBMC
 *      http://xbmc.org
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with XBMC; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#import "OSXGLWindow.h"

#include "Application.h"
#include "AppParamParser.h"
#include "AppInboundProtocol.h"
#include "ServiceBroker.h"
#include "guilib/GUIWindowManager.h"
#include "messaging/ApplicationMessenger.h"
#include "settings/DisplaySettings.h"
#include "settings/Settings.h"
#include "settings/SettingsComponent.h"
#include "guilib/GUIComponent.h"
#include "utils/log.h"

#import "platform/darwin/osx/XBMCApplication.h"

#import "windowing/osx/WinSystemOSX.h"

#include "windowing/osx/WinEventsOSX.h"

#include "platform/darwin/osx/CocoaInterface.h"
//#import "platform/darwin/osx/DarwinUtils.h"
#import "platform/darwin/osx/OSXGLView.h"

#import <AppKit/AppKit.h>

//------------------------------------------------------------------------------------------
@implementation OSXGLWindow

+(void) SetMenuBarVisible
{
  NSApplicationPresentationOptions options = NSApplicationPresentationDefault;
  [[NSApplication sharedApplication] setPresentationOptions:options];
}

+(void) SetMenuBarInvisible
{
  NSApplicationPresentationOptions options = NSApplicationPresentationHideMenuBar | NSApplicationPresentationHideDock;
  [[NSApplication sharedApplication] setPresentationOptions:options];
}

-(id) initWithContentRect:(NSRect)box styleMask:(uint)style
{
  self = [super initWithContentRect:box styleMask:style backing:NSBackingStoreBuffered defer:YES];
  [self setDelegate:self];
  [self setAcceptsMouseMovedEvents:YES];
  // autosave the window position/size
  [[self windowController] setShouldCascadeWindows:NO]; // Tell the controller to not cascade its windows.
  [self setFrameAutosaveName:@"OSXGLWindowPositionHeightWidth"];  // Specify the autosave name for the window.

  g_application.m_AppFocused = true;

  return self;
}

-(void) dealloc
{
  [self setDelegate:nil];
}

- (BOOL)windowShouldClose:(id)sender
{

  if (!g_application.m_bStop)
    KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_QUIT);

  return NO;
}

- (void)windowDidExpose:(NSNotification *)aNotification
{
  //NSLog(@"windowDidExpose");
  g_application.m_AppFocused = true;
}

- (void)windowDidMove:(NSNotification *)aNotification
{
  //NSLog(@"windowDidMove");
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
      std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
      if (appPort)
        appPort->OnEvent(newEvent);
    }
  }
}

- (void)windowDidResize:(NSNotification *)aNotification
{
  //NSLog(@"windowDidResize");
  NSRect rect = [self contentRectForFrameRect:[self frame]];

  if(!CServiceBroker::GetWinSystem()->IsFullScreen())
  {
    RESOLUTION res_index  = RES_DESKTOP;
    if(((int)rect.size.width == CDisplaySettings::GetInstance().GetResolutionInfo(res_index).iWidth) &&
       ((int)rect.size.height == CDisplaySettings::GetInstance().GetResolutionInfo(res_index).iHeight))
      return;
  }
  XBMC_Event newEvent;
  newEvent.type = XBMC_VIDEORESIZE;
  newEvent.resize.w = (int)rect.size.width;
  newEvent.resize.h = (int)rect.size.height;

  // check for valid sizes cause in some cases
  // we are hit during fullscreen transition from osx
  // and might be technically "zero" sized
  if (newEvent.resize.w != 0 && newEvent.resize.h != 0)
  {
    std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
    if (appPort)
      appPort->OnEvent(newEvent);
  }
}

-(void)windowDidChangeScreen:(NSNotification *)notification
{
  // user has moved the window to a
  // different screen
//  if (CServiceBroker::GetWinSystem()->IsFullScreen())
//    CServiceBroker::GetWinSystem()->SetMovedToOtherScreen(true);
}

-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
  //NSLog(@"windowWillResize");
  return frameSize;
}

-(void)windowWillStartLiveResize:(NSNotification *)aNotification
{
  //NSLog(@"windowWillStartLiveResize");
}

-(void)windowDidEndLiveResize:(NSNotification *)aNotification
{
  //NSLog(@"windowDidEndLiveResize");
}

-(void)windowDidEnterFullScreen: (NSNotification*)pNotification
{
}

-(void)windowWillEnterFullScreen: (NSNotification*)pNotification
{
  [self toggleFullscreen];
}

-(void)windowDidExitFullScreen: (NSNotification*)pNotification
{
  [self toggleFullscreen];
}

-(void)toggleFullscreen
{
  CWinSystemOSX* winSystem = dynamic_cast<CWinSystemOSX*>(CServiceBroker::GetWinSystem());
  // if osx is the issuer of the toggle
  // call XBMCs toggle function
  if (!winSystem->GetFullscreenWillToggle())
  {
    // indicate that we are toggling
    // flag will be reset in SetFullscreen once its
    // called from XBMCs gui thread
    winSystem->SetFullscreenWillToggle(true);
    KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);
  }
  else
  {
    // in this case we are just called because
    // of xbmc did a toggle - just reset the flag
    // we don't need to do anything else
    winSystem->SetFullscreenWillToggle(false);
  }
}

-(void)windowWillExitFullScreen: (NSNotification*)pNotification
{

}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
  //NSLog(@"windowDidMiniaturize");
  g_application.m_AppFocused = false;
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
  //NSLog(@"windowDidDeminiaturize");
  g_application.m_AppFocused = true;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  //NSLog(@"windowDidBecomeKey");
  g_application.m_AppFocused = true;
//  CWinEventsOSXImp::EnableInput();
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  //NSLog(@"windowDidResignKey");
  g_application.m_AppFocused = false;
//  CWinEventsOSXImp::DisableInput();
}

-(void) mouseDown:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) rightMouseDown:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) otherMouseDown:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) mouseUp:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) rightMouseUp:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) otherMouseUp:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) mouseMoved:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) mouseDragged:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) rightMouseDragged:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) otherMouseDragged:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

-(void) scrollWheel:(NSEvent *) theEvent
{
//  if (Cocoa_IsMouseHidden())
//    CWinEventsOSXImp::HandleInputEvent(theEvent);
}

- (void)keyDown:(NSEvent *)theEvent {
  CLog::Log(LOGDEBUG, "%s: Brent keypress Down", __PRETTY_FUNCTION__);

//  if (NSApplication.shared.keyWindow != self.view.window)
//    return;

  if (theEvent.type == NSEventTypeKeyDown)
  {
//    [g_xbmcApplication.inputHandler.inputKeyboard sendButtonPressed:theEvent];
  }
    
}

- (void)keyUp:(NSEvent *)theEvent {
  CLog::Log(LOGDEBUG, "%s: Brent keypress Up", __PRETTY_FUNCTION__);
  if (theEvent.type == NSEventTypeKeyUp)
  {
//    [g_xbmcApplication.inputHandler.inputKeyboard sendButtonReleased:theEvent];
  }
}
@end
