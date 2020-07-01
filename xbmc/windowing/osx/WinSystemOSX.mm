/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "WinSystemOSX.h"

#include "AppInboundProtocol.h"
#include "CompileInfo.h"
#include "OSScreenSaverOSX.h"
#include "ServiceBroker.h"
#include "VideoSyncOsx.h"
#include "WinEventsOSX.h"
#include "cores/AudioEngine/AESinkFactory.h"
#include "cores/AudioEngine/Sinks/AESinkDARWINOSX.h"
#include "cores/RetroPlayer/process/osx/RPProcessInfoOSX.h"
#include "cores/RetroPlayer/rendering/VideoRenderers/RPRendererOpenGL.h"
#include "cores/VideoPlayer/DVDCodecs/DVDFactoryCodec.h"
#include "cores/VideoPlayer/DVDCodecs/Video/VTB.h"
#include "cores/VideoPlayer/Process/osx/ProcessInfoOSX.h"
#include "cores/VideoPlayer/VideoRenderers/HwDecRender/RendererVTBGL.h"
#include "cores/VideoPlayer/VideoRenderers/LinuxRendererGL.h"
#include "cores/VideoPlayer/VideoRenderers/RenderFactory.h"
#include "guilib/DispResource.h"
#include "guilib/GUIWindowManager.h"
#include "guilib/Texture.h"
#include "input/KeyboardStat.h"
#include "messaging/ApplicationMessenger.h"
#include "rendering/gl/RenderSystemGL.h"
#include "rendering/gl/ScreenshotSurfaceGL.h"
#include "settings/DisplaySettings.h"
#include "settings/Settings.h"
#include "settings/SettingsComponent.h"
#include "threads/SingleLock.h"
#include "utils/StringUtils.h"
#include "utils/SystemInfo.h"
#include "utils/log.h"
#include "windowing/osx/CocoaDPMSSupport.h"

#include "platform/darwin/DarwinUtils.h"
#include "platform/darwin/DictionaryUtils.h"
#include "platform/darwin/osx/CocoaInterface.h"
#import "platform/darwin/osx/OSXTextInputResponder.h"
#include "platform/darwin/osx/XBMCHelper.h"
#include "platform/darwin/osx/powermanagement/CocoaPowerSyscall.h"

#include "windowing/GraphicContext.h"
#include "windowing/WinSystem.h"
#include "ServiceBroker.h"

#include "windowing/osx/OSXScreenManager.h"
#include "windowing/osx/OSXGLView.h"
#include "windowing/osx/OSXGLWindow.h"

#include <cstdlib>
#include <signal.h>

#import <Cocoa/Cocoa.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "platform/darwin/osx/NSWindow+FullScreen.h"

// turn off deprecated warning spew.
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

using namespace KODI;
using namespace MESSAGING;
using namespace WINDOWING;

struct AppWindowWrapper
{
  __block NSWindow* window;
};

struct GLViewWrapper
{
  OSXGLView* view;
};

class CWinSystemOSXImpl
{
public:
  NSOpenGLContext* m_glContext;
  static NSOpenGLContext* m_lastOwnedContext;
};

CGDisplayFadeReservationToken DisplayFadeToBlack(bool fade)
{
  // Fade to black to hide resolution-switching flicker and garbage.
  CGDisplayFadeReservationToken fade_token = kCGDisplayFadeReservationInvalidToken;
  if (CGAcquireDisplayFadeReservation (5, &fade_token) == kCGErrorSuccess && fade)
    CGDisplayFade(fade_token, 0.3, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, 0.0, 0.0, 0.0, TRUE);

  return(fade_token);
}

void DisplayFadeFromBlack(CGDisplayFadeReservationToken fade_token, bool fade)
{
  if (fade_token != kCGDisplayFadeReservationInvalidToken)
  {
    if (fade)
      CGDisplayFade(fade_token, 0.5, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal, 0.0, 0.0, 0.0, FALSE);
    CGReleaseDisplayFadeReservation(fade_token);
  }
}

CFArrayRef GetAllDisplayModes(CGDirectDisplayID display)
{
  int value = 1;

  CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &value);
  if (!number)
  {
    CLog::Log(LOGERROR, "GetAllDisplayModes - could not create Number!");
    return NULL;
  }

  CFStringRef key = kCGDisplayShowDuplicateLowResolutionModes;
  CFDictionaryRef options = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&key, (const void **)&number, 1, NULL, NULL);
  CFRelease(number);

  if (!options)
  {
    CLog::Log(LOGERROR, "GetAllDisplayModes - could not create Dictionary!");
    return NULL;
  }

  CFArrayRef displayModes = CGDisplayCopyAllDisplayModes(display, options);
  CFRelease(options);

  if (!displayModes)
  {
    CLog::Log(LOGERROR, "GetAllDisplayModes - no displaymodes found!");
    return NULL;
  }

  return displayModes;
}



void BlankOtherDisplays(int screen_index)
{
/*  int i;
  int numDisplays = [[NSScreen screens] count];

  // zero out blankingWindows for debugging
  for (i=0; i<MAX_DISPLAYS; i++)
  {
    blankingWindows[i] = 0;
  }

  // Blank.
  for (i=0; i<numDisplays; i++)
  {
    if (i != screen_index)
    {
      // Get the size.
      NSScreen* pScreen = [[NSScreen screens] objectAtIndex:i];
      NSRect    screenRect = [pScreen frame];

      // Build a blanking window.
      screenRect.origin = NSZeroPoint;
      blankingWindows[i] = [[NSWindow alloc] initWithContentRect:screenRect
        styleMask:NSBorderlessWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:pScreen];

      [blankingWindows[i] setBackgroundColor:[NSColor blackColor]];
      [blankingWindows[i] setLevel:CGShieldingWindowLevel()];
      [blankingWindows[i] makeKeyAndOrderFront:nil];
    }
  }
 */
}

void UnblankDisplays(void)
{
/*  int numDisplays = [[NSScreen screens] count];
  int i = 0;

  for (i=0; i<numDisplays; i++)
  {
    if (blankingWindows[i] != 0)
    {
      // Get rid of the blanking windows we created.
      [blankingWindows[i] close];
      blankingWindows[i] = 0;
    }
  }
*/
}



void ShowHideNSWindow(NSWindow *wind, bool show)
{
  if (show)
    [wind orderFront:nil];
  else
    [wind orderOut:nil];
}

static NSWindow *curtainWindow;
void fadeInDisplay(NSScreen *theScreen, double fadeTime)
{
  int     fadeSteps     = 100;
  double  fadeInterval  = (fadeTime / (double) fadeSteps);

  if (curtainWindow != nil)
  {
    for (int step = 0; step < fadeSteps; step++)
    {
      double fade = 1.0 - (step * fadeInterval);
      [curtainWindow setAlphaValue:fade];

      NSDate *nextDate = [NSDate dateWithTimeIntervalSinceNow:fadeInterval];
      [[NSRunLoop currentRunLoop] runUntilDate:nextDate];
    }
  }
  [curtainWindow close];
  curtainWindow = nil;

  [NSCursor unhide];
}

void fadeOutDisplay(NSScreen *theScreen, double fadeTime)
{
  int     fadeSteps     = 100;
  double  fadeInterval  = (fadeTime / (double) fadeSteps);

  [NSCursor hide];

  curtainWindow = [[NSWindow alloc]
    initWithContentRect:[theScreen frame]
    styleMask:NSBorderlessWindowMask
    backing:NSBackingStoreBuffered
    defer:YES
    screen:theScreen];

  [curtainWindow setAlphaValue:0.0];
  [curtainWindow setBackgroundColor:[NSColor blackColor]];
  [curtainWindow setLevel:NSScreenSaverWindowLevel];

  [curtainWindow makeKeyAndOrderFront:nil];
  [curtainWindow setFrame:[curtainWindow
    frameRectForContentRect:[theScreen frame]]
    display:YES
    animate:NO];

  for (int step = 0; step < fadeSteps; step++)
  {
    double fade = step * fadeInterval;
    [curtainWindow setAlphaValue:fade];

    NSDate *nextDate = [NSDate dateWithTimeIntervalSinceNow:fadeInterval];
    [[NSRunLoop currentRunLoop] runUntilDate:nextDate];
  }
}


//------------------------------------------------------------------------------
NSOpenGLContext* CreateWindowedContext(NSOpenGLContext* shareCtx);


NSOpenGLContext* CreateWindowedContext(NSOpenGLContext* shareCtx)
{
  NSOpenGLPixelFormat* pixFmt;
  if (getenv("KODI_GL_PROFILE_LEGACY"))
  {
    NSOpenGLPixelFormatAttribute wattrs[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADepthSize,
        static_cast<NSOpenGLPixelFormatAttribute>(8),
        static_cast<NSOpenGLPixelFormatAttribute>(0)};
    pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:wattrs];
  }
  else
  {
    NSOpenGLPixelFormatAttribute wattrs_gl3[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADepthSize,
        static_cast<NSOpenGLPixelFormatAttribute>(24),
        static_cast<NSOpenGLPixelFormatAttribute>(0)};
    pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:wattrs_gl3];
  }

  auto newContext = [[NSOpenGLContext alloc] initWithFormat:pixFmt shareContext:shareCtx];

  if (!newContext)
  {
    // bah, try again for non-accelerated renderer
    NSOpenGLPixelFormatAttribute wattrs2[] =
    {
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFANoRecovery,
      NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)8,
      (NSOpenGLPixelFormatAttribute)0
    };
    newContext = [[NSOpenGLContext alloc]
        initWithFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:wattrs2]
          shareContext:shareCtx];
  }

  return newContext;
}

NSOpenGLContext* CWinSystemOSXImpl::m_lastOwnedContext = nil;

//------------------------------------------------------------------------------
CWinSystemOSX::CWinSystemOSX()
  : CWinSystemBase()
  , m_impl{new CWinSystemOSXImpl}
  , m_pScreenManager{new COSXScreenManager}
{
  m_appWindow = new AppWindowWrapper;

  dispatch_sync(dispatch_get_main_queue(), ^{
    m_appWindow->window = [[NSWindow alloc] init];
  });
  m_glView = new GLViewWrapper;
  dispatch_sync(dispatch_get_main_queue(), ^{
    m_glView->view = [[OSXGLView alloc] init];
  });

  m_fullscreenWillToggle = false;
  m_lastX = 0;
  m_lastY = 0;

  m_winEvents.reset(new CWinEventsOSX());

  CAESinkDARWINOSX::Register();
  CCocoaPowerSyscall::Register();
  m_dpms = std::make_shared<CCocoaDPMSSupport>();
  
}

CWinSystemOSX::~CWinSystemOSX()
{
  m_appWindow->window = nullptr;
  m_glView->view = nullptr;

  m_impl->m_glContext = nil;

  delete m_pScreenManager;
  delete m_appWindow;
  delete m_glView;
}

int CWinSystemOSX::GetCurrentScreen()
{
  return m_pScreenManager->GetCurrentScreen();
}

bool CWinSystemOSX::InitWindowSystem()
{
  if (!CWinSystemBase::InitWindowSystem())
    return false;

  m_pScreenManager->Init(this);

  return true;
}

bool CWinSystemOSX::DestroyWindowSystem()
{

  m_pScreenManager->Deinit();

  @autoreleasepool
  {
    // set this 1st, we should really mutex protext m_appWindow in this class
    m_bWindowCreated = false;
    if (m_appWindow->window)
    {
      auto oldAppWindow = m_appWindow->window;
      m_appWindow->window = nullptr;
      [oldAppWindow setContentView:nil];
    }
  }
  if (m_glView->view)
  {
    // normally, this should happen here but we are racing internal object destructors
    // that make GL calls. They crash if the GLView is released.
    //[(OSXGLView*)m_glView release];
    m_glView->view = nullptr;
  }

  return true;
}

bool CWinSystemOSX::CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res)
{
  @autoreleasepool
  {
    //printf("CWinSystemOSX::CreateNewWindow\n");
    m_nWidth      = res.iWidth;
    m_nHeight     = res.iHeight;
    m_bFullScreen = fullScreen;

    // for native fullscreen we always want to set the same windowed flags
    NSUInteger windowStyleMask;

    windowStyleMask = NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    NSString *title = [NSString stringWithUTF8String:name.c_str()];

    if (m_appWindow->window == nullptr)
    {
      NSWindow *appWindow = [[OSXGLWindow alloc] initWithContentRect:NSMakeRect(0, 0, m_nWidth, m_nHeight) styleMask:windowStyleMask];
      [appWindow setBackgroundColor:[NSColor blackColor]];
      [appWindow setOneShot:NO];
      [appWindow setMinSize:NSMakeSize(1000, 700)];

      NSWindowCollectionBehavior behavior = [appWindow collectionBehavior];
      behavior |= NSWindowCollectionBehaviorFullScreenPrimary;
      [appWindow setCollectionBehavior:behavior];

      // create new content view
      NSRect rect = [appWindow contentRectForFrameRect:[appWindow frame]];

      // create new view if we don't have one
      if(!m_glView->view)
        m_glView->view = [[OSXGLView alloc] initWithFrame:rect];
      OSXGLView *contentView = m_glView->view;

      // associate with current window
      [appWindow setContentView: contentView];
      [[contentView getGLContext] makeCurrentContext];
      [[contentView getGLContext] update];

      m_appWindow->window = appWindow;
      m_bWindowCreated = true;
      m_pScreenManager->RegisterWindow(appWindow);
    }

    [m_appWindow->window performSelectorOnMainThread:@selector(setTitle:) withObject:title waitUntilDone:YES];
    [m_appWindow->window performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:nil waitUntilDone:YES];

    HandleNativeMousePosition();
  }

  SetFullScreen(m_bFullScreen, res, false);

  // register platform dependent objects
  CDVDFactoryCodec::ClearHWAccels();
  VTB::CDecoder::Register();
  VIDEOPLAYER::CRendererFactory::ClearRenderer();
  CLinuxRendererGL::Register();
  CRendererVTB::Register();
  VIDEOPLAYER::CProcessInfoOSX::Register();
//  RETRO::CRPProcessInfoOSX::Register();
//  RETRO::CRPProcessInfoOSX::RegisterRendererFactory(new RETRO::CRendererFactoryOpenGL);
//  CScreenshotSurfaceGL::Register();

  return true;
}

bool CWinSystemOSX::SwitchToVideoMode(int width, int height, double refreshrate)
{
  boolean_t match = false;
  CGDisplayModeRef dispMode = NULL;

    int screenIdx = m_pScreenManager->GetDisplayIndex(CServiceBroker::GetSettingsComponent()->GetSettings()->GetString(CSettings::SETTING_VIDEOSCREEN_MONITOR));

  // Figure out the screen size. (default to main screen)
  CGDirectDisplayID display_id = m_pScreenManager->GetDisplayID(screenIdx);

  // find mode that matches the desired size, refreshrate
  // non interlaced, nonstretched, safe for hardware
  dispMode = m_pScreenManager->GetMode(width, height, refreshrate, screenIdx);

  //not found - fallback to bestemdeforparameters
  if (!dispMode)
  {
    dispMode = m_pScreenManager->BestMatchForMode(display_id, 32, width, height, match);

    if (!match)
      dispMode = m_pScreenManager->BestMatchForMode(display_id, 16, width, height, match);

    // still no match? fallback to current resolution of the display which HAS to work [tm]
    if (!match)
    {
      int tmpWidth;
      int tmpHeight;
      double tmpRefresh;

      GetScreenResolution(&tmpWidth, &tmpHeight, &tmpRefresh, screenIdx);
      dispMode = m_pScreenManager->GetMode(tmpWidth, tmpHeight, tmpRefresh, screenIdx);

      // no way to get a resolution set
      if (!dispMode)
        return false;
    }

    if (!match)
      return false;
  }

  // switch mode and return success
  CGDisplayCapture(display_id);
  CGDisplayConfigRef cfg;
  CGBeginDisplayConfiguration(&cfg);
  CGConfigureDisplayWithDisplayMode(cfg, display_id, dispMode, nullptr);
  CGError err = CGCompleteDisplayConfiguration(cfg, kCGConfigureForAppOnly);
  CGDisplayRelease(display_id);

  m_refreshRate = CGDisplayModeGetRefreshRate(dispMode);

  Cocoa_CVDisplayLinkUpdate();

  return (err == kCGErrorSuccess);
}

// decide if the native mouse is over our window or not and
// hide or show the native mouse accordingly. This
// should be called after switching to windowed mode (or
// starting up in windowed mode) for making
// the native mouse visible or not based on the current
// mouse position
void CWinSystemOSX::HandleNativeMousePosition()
{
  // check if we have to hide the mouse in case the mouse over the window
  // the tracking area mouseenter, mouseexit are not called
  // so we have to decide here to initial hide the os cursor
  // same goes for having the mouse pointer outside of the window
  NSPoint mouse = [NSEvent mouseLocation];
  
  __block int winNumber;
  dispatch_sync(dispatch_get_main_queue(), ^{
    winNumber = m_appWindow->window.windowNumber;
  });
  
  
  if ([NSWindow windowNumberAtPoint:mouse belowWindowWithWindowNumber:0] == winNumber)
  {
    // warp XBMC cursor to our position
    NSPoint locationInWindowCoords = [m_appWindow->window mouseLocationOutsideOfEventStream];
    XBMC_Event newEvent;
    memset(&newEvent, 0, sizeof(newEvent));
    newEvent.type = XBMC_MOUSEMOTION;
    newEvent.motion.x =  locationInWindowCoords.x;
    newEvent.motion.y =  locationInWindowCoords.y;
    std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
    if (appPort)
      appPort->OnEvent(newEvent);
  }
  else// show native cursor as its outside of our window
  {
    Cocoa_ShowMouse();
  }
}

bool CWinSystemOSX::DestroyWindow()
{
  return true;
}

bool CWinSystemOSX::ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop)
{
  //printf("CWinSystemOSX::ResizeWindow\n");
  if (!m_appWindow->window)
    return false;

  if (newWidth < 0)
  {
    newWidth = [m_appWindow->window minSize].width;
  }

  if (newHeight < 0)
  {
    newHeight = [m_appWindow->window minSize].height;
  }

  
    NSWindow *window = m_appWindow->window;

    NSRect pos = [window frame];
    newLeft = pos.origin.x;
    newTop = pos.origin.y;
//dispatch_sync(dispatch_get_main_queue(), ^{
    NSRect myNewContentFrame = NSMakeRect(newLeft, newTop, newWidth, newHeight);
    NSRect myNewWindowRect = [window frameRectForContentRect:myNewContentFrame];
    [window setFrame:myNewWindowRect display:TRUE];
//  });

  CServiceBroker::GetWinSystem()->GetGfxContext().SetFPS(m_refreshRate);
}

static bool needtoshowme = true;

bool CWinSystemOSX::SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays)
{
/*  CSingleLock lock (m_critSection);
  __block NSWindow* window = m_appWindow->window;

  bool screenChanged = m_pScreenManager->SetLastDisplayNr(0);
  bool fullScreen2FullScreen = m_bFullScreen && fullScreen && screenChanged;
  m_nWidth      = res.iWidth;
  m_nHeight     = res.iHeight;
  m_bFullScreen = fullScreen;

  dispatch_sync(dispatch_get_main_queue(), ^{
    [window setAllowsConcurrentViewDrawing:NO];
  });

//  SetFullscreenWillToggle(m_bFullScreen != [window isFullScreen]);
SetFullscreenWillToggle(true);
  // toggle cocoa fullscreen mode
  // this should handle everything related to
  // window decorations and stuff like that.
  // this needs to be called before ResizeWindow
  // else we might not be able to get the full window size when
  // in fullscreen mode - but only the full height minus osx dock height.
  if (GetFullscreenWillToggle() || fullScreen2FullScreen)
  {
    // go to windowed mode first and move to the other screen
    // before toggle fullscreen again.
//    if (fullScreen2FullScreen && [window isFullScreen])
    if (fullScreen2FullScreen) // && [window isFullScreen])
    {
       dispatch_sync(dispatch_get_main_queue(), ^{
      NSScreen* pScreen = [[NSScreen screens] objectAtIndex:0];
      [window performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];
      NSRect rectOnNewScreen = [window constrainFrameRect:[window frame] toScreen:pScreen];
      ResizeWindow(rectOnNewScreen.size.width, rectOnNewScreen.size.width, rectOnNewScreen.origin.x, rectOnNewScreen.origin.y);
        });
    }
       dispatch_sync(dispatch_get_main_queue(), ^{
    [window performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];
      });
  }

  if (m_bFullScreen)
  {
    // switch videomode
    m_pScreenManager->SwitchToVideoMode(res.iWidth, res.iHeight, res.fRefreshRate, 0);
 
   dispatch_sync(dispatch_get_main_queue(), ^{
    NSScreen* pScreen = [[NSScreen screens] objectAtIndex:0];
    NSRect    screenRect = [pScreen frame];
    // ensure we use the screen rect origin here - because we might want to display on
    // a different monitor (which has the monitor offset in x and y origin ...)
    ResizeWindow(m_nWidth, m_nHeight, screenRect.origin.x, screenRect.origin.y);
  });
    // blank all other dispalys if requested
    if (blankOtherDisplays)
    {
//        m_pScreenManager->BlankOtherDisplays(res.iScreen);
    }
  }
  else
  {
    // Windowed Mode
    ResizeWindow(m_nWidth, m_nHeight, m_lastX, m_lastY);
    HandleNativeMousePosition();

    // its always safe to unblank other displays - even if they are not blanked...
    m_pScreenManager->UnblankDisplays();
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    [window setAllowsConcurrentViewDrawing:YES];
  });


  CRenderSystemGL::ResetRenderSystem(res.iWidth, res.iHeight);

  if (m_bVSync)
  {
    EnableVSync(m_bVSync);
  }

  return true;
  */
  
static NSWindow* windowedFullScreenwindow = NULL;
  static NSScreen* last_window_screen = NULL;
  static NSPoint last_window_origin;
  static NSView* last_view = NULL;
  static NSSize last_view_size;
  static NSPoint last_view_origin;
  static NSInteger last_window_level = NSNormalWindowLevel;
//  bool was_fullscreen = m_bFullScreen;
  NSOpenGLContext* cur_context;

  // Fade to black to hide resolution-switching flicker and garbage.
  CGDisplayFadeReservationToken fade_token = DisplayFadeToBlack(needtoshowme);

  // If we're already fullscreen then we must be moving to a different display.
  // or if we are still on the same display - it might be only a refreshrate/resolution
  // change request.
  // Recurse to reset fullscreen mode and then continue.
//  if (was_fullscreen && fullScreen)
//  {
//    needtoshowme = false;
//    ShowHideNSWindow([last_view window], needtoshowme);
//    RESOLUTION_INFO& window = CDisplaySettings::GetInstance().GetResolutionInfo(RES_WINDOW);
//    CWinSystemOSX::SetFullScreen(false, window, blankOtherDisplays);
//   needtoshowme = true;
//  }

  const std::shared_ptr<CSettings> settings = CServiceBroker::GetSettingsComponent()->GetSettings();
  m_lastDisplayNr = m_pScreenManager->GetDisplayIndex(settings->GetString(CSettings::SETTING_VIDEOSCREEN_MONITOR));
  m_nWidth = res.iWidth;
  m_nHeight = res.iHeight;
  m_bFullScreen = fullScreen;

  cur_context = [NSOpenGLContext currentContext];

  //handle resolution/refreshrate switching early here
  if (m_bFullScreen)
  {
    // switch videomode
    SwitchToVideoMode(res.iWidth, res.iHeight, res.fRefreshRate);
  }

  //no context? done.
  if (!cur_context)
  {
    DisplayFadeFromBlack(fade_token, needtoshowme);
    return false;
  }

//  if (windowedFullScreenwindow != NULL)
//  {
//    [windowedFullScreenwindow close];
//    windowedFullScreenwindow = nil;
//  }

  if (m_bFullScreen)
  {
    // FullScreen Mode
    NSOpenGLContext* newContext = NULL;

    // Save info about the windowed context so we can restore it when returning to windowed.
    last_view = [cur_context view];
    last_view_size = [last_view frame].size;
    last_view_origin = [last_view frame].origin;
    last_window_screen = [[last_view window] screen];
    last_window_origin = [[last_view window] frame].origin;
    last_window_level = [[last_view window] level];

    // This is Cocoa Windowed FullScreen Mode
    // Get the screen rect of our current display
    NSScreen* pScreen = [[NSScreen screens] objectAtIndex:m_lastDisplayNr];
    NSRect    screenRect = [pScreen frame];

    // remove frame origin offset of original display
    screenRect.origin = NSZeroPoint;

    // make a new window to act as the windowedFullScreen
    windowedFullScreenwindow = [[NSWindow alloc] initWithContentRect:screenRect
    styleMask:NSBorderlessWindowMask
    backing:NSBackingStoreBuffered
    defer:NO
    screen:pScreen];

    [windowedFullScreenwindow setBackgroundColor:[NSColor blackColor]];
    [windowedFullScreenwindow makeKeyAndOrderFront:nil];

    // make our window the same level as the rest to enable cmd+tab switching
    [windowedFullScreenwindow setLevel:NSNormalWindowLevel];
    // this will make our window topmost and hide all system messages
    //[windowedFullScreenwindow setLevel:CGShieldingWindowLevel()];

    // ...and the original one beneath it and on the same screen.
    [[last_view window] setLevel:NSNormalWindowLevel-1];
    [[last_view window] setFrameOrigin:[pScreen frame].origin];
    // expand the mouse bounds in SDL view to fullscreen
    [ last_view setFrameOrigin:NSMakePoint(0.0, 0.0)];
    [ last_view setFrameSize:NSMakeSize(m_nWidth, m_nHeight) ];

    NSView* blankView = [[NSView alloc] init];
    [windowedFullScreenwindow setContentView:blankView];
    [windowedFullScreenwindow setContentSize:NSMakeSize(m_nWidth, m_nHeight)];
    [windowedFullScreenwindow update];
    [blankView setFrameSize:NSMakeSize(m_nWidth, m_nHeight)];

    // Obtain windowed pixel format and create a new context.
    newContext = CreateWindowedContext(cur_context);
    [newContext setView:blankView];

    // Hide the menu bar.
    //SetMenuBarVisible(false);

    // Blank other displays if requested.
    if (blankOtherDisplays)
      BlankOtherDisplays(m_lastDisplayNr);

    // Hide the mouse.
    [NSCursor hide];

    // Release old context if we created it.
    if (CWinSystemOSXImpl::m_lastOwnedContext == cur_context)
    {
      [ NSOpenGLContext clearCurrentContext ];
      [ cur_context clearDrawable ];
    }

    // activate context
    [newContext makeCurrentContext];
    CWinSystemOSXImpl::m_lastOwnedContext = newContext;
  }
  else
  {
/*    // Windowed Mode
    // exit fullscreen
    [cur_context clearDrawable];

    [NSCursor unhide];

    // Show menubar.
    SetMenuBarVisible(true);

    // restore the windowed window level
    [[last_view window] setLevel:last_window_level];

    // Get rid of the new window we created.
    if (windowedFullScreenwindow != nil)
    {
      [windowedFullScreenwindow close];
      windowedFullScreenwindow = nil;
    }

    // Unblank.
    // Force the unblank when returning from fullscreen, we get called with blankOtherDisplays set false.
    //if (blankOtherDisplays)
    UnblankDisplays();

    // create our new context (sharing with the current one)
    auto newContext = CreateWindowedContext(cur_context);
    if (!newContext)
      return false;

    // Assign view from old context, move back to original screen.
    [newContext setView:last_view];
    [[last_view window] setFrameOrigin:last_window_origin];
    // return the mouse bounds in SDL view to previous size
    [ last_view setFrameSize:last_view_size ];
    [ last_view setFrameOrigin:last_view_origin ];
    // done with restoring windowed window, don't set last_view to NULL as we can lose it under dual displays.
    //last_window_screen = NULL;

    // Release the fullscreen context.
    if (CWinSystemOSXImpl::m_lastOwnedContext == cur_context)
    {
      [ NSOpenGLContext clearCurrentContext ];
      [ cur_context clearDrawable ];
    }

    // Activate context.
    [newContext makeCurrentContext];
    CWinSystemOSXImpl::m_lastOwnedContext = newContext;
    */
  }

  DisplayFadeFromBlack(fade_token, needtoshowme);

//  ShowHideNSWindow([last_view window], needtoshowme);
  // need to make sure SDL tracks any window size changes
//  ResizeWindow(m_nWidth, m_nHeight, -1, -1);
//  ResizeWindowInternal(m_nWidth, m_nHeight, -1, -1, last_view);
  // restore origin once again when going to windowed mode
//  if (!fullScreen)
//  {
//    [[last_view window] setFrameOrigin:last_window_origin];
//  }
//  HandlePossibleRefreshrateChange();

//  m_updateGLContext = 0;
  return true;
  
  
}

void CWinSystemOSX::UpdateResolutions()
{
  CWinSystemBase::UpdateResolutions();

  m_pScreenManager->UpdateResolutions();
  
  // blanking display stuff
}

void CWinSystemOSX::EnableVSync(bool enable)
{
  m_pScreenManager->EnableVSync(enable);
}

void CWinSystemOSX::HandleDelayedDisplayReset()
{
  m_pScreenManager->HandleDelayedDisplayReset();
}

void CWinSystemOSX::SetMovedToOtherScreen(bool moved)
{
  m_pScreenManager->SetMovedToOtherScreen(moved);
}

void CWinSystemOSX::UpdateDesktopResolution2(RESOLUTION_INFO& newRes, const std::string &output, int width, int height, float refreshRate, uint32_t dwFlags)
{
  UpdateDesktopResolution(newRes, output, width, height, refreshRate, dwFlags);
}

void CWinSystemOSX::MessagePush(XBMC_Event* newEvent)
{
  dynamic_cast<CWinEventsOSX&>(*m_winEvents).MessagePush(newEvent);
}

bool CWinSystemOSX::FlushBuffer(void)
{
/*  if (m_updateGLContext < 5)
  {
    [m_impl->m_glContext update];
    m_updateGLContext++;
  }

  [m_impl->m_glContext flushBuffer];

  */
  if (m_appWindow->window)
  {
    auto contentView = [m_appWindow->window contentView];
    NSOpenGLContext *glcontex = [contentView getGLContext];
    [glcontex flushBuffer];
  }

  return true;
}

void CWinSystemOSX::NotifyAppFocusChange(bool bGaining)
{
  if (!(m_bFullScreen && bGaining))
    return;
  @autoreleasepool
  {
 /*   // find the window
    NSOpenGLContext* context = [NSOpenGLContext currentContext];
    if (context)
    {
      NSView* view;

      view = [context view];
      if (view)
      {
        NSWindow* window;
        window = [view window];
        if (window)
        {
          SetMenuBarVisible(false);
          [window orderFront:nil];
        }
      }
    }*/
    if (m_appWindow->window)
    {
      [m_appWindow->window orderFront:nil];
    }
  }
}

void CWinSystemOSX::ShowOSMouse(bool show)
{
 // Todo
}

bool CWinSystemOSX::Minimize()
{
  @autoreleasepool
  {
    [[NSApplication sharedApplication] miniaturizeAll:nil];
  }
  return true;
}

bool CWinSystemOSX::Restore()
{
  @autoreleasepool
  {
    [[NSApplication sharedApplication] unhide:nil];
  }
  return true;
}

bool CWinSystemOSX::Hide()
{
  @autoreleasepool
  {
    [[NSApplication sharedApplication] hide:nil];
  }
  return true;
}

std::string CWinSystemOSX::GetClipboardText(void)
{
  std::string utf8_text;

  const char *szStr = Cocoa_Paste();
  if (szStr)
    utf8_text = szStr;

  return utf8_text;
}

void CWinSystemOSX::ConvertLocationFromScreen(CGPoint *point)
{
  if (m_appWindow->window)
  {
    auto win = m_appWindow->window;
    NSRect frame = [[win contentView] frame];
    point->y = frame.size.height - point->y;
  }
}

void CWinSystemOSX::OnMove(int x, int y)
{
  //printf("CWinSystemOSX::OnMove\n");
  m_lastX      = x;
  m_lastY      = y;
}

std::unique_ptr<IOSScreenSaver> CWinSystemOSX::GetOSScreenSaverImpl()
{
  return std::unique_ptr<IOSScreenSaver> (new COSScreenSaverOSX);
}

OSXTextInputResponder *g_textInputResponder = nil;

void CWinSystemOSX::StartTextInput()
{
  NSView *parentView = [[NSApp keyWindow] contentView];

  /* We only keep one field editor per process, since only the front most
   * window can receive text input events, so it make no sense to keep more
   * than one copy. When we switched to another window and requesting for
   * text input, simply remove the field editor from its superview then add
   * it to the front most window's content view */

  if (!g_textInputResponder) {
    g_textInputResponder =
    [[OSXTextInputResponder alloc] initWithFrame: NSMakeRect(0.0, 0.0, 0.0, 0.0)];
  }

  if (![[g_textInputResponder superview] isEqual: parentView])
  {
//    DLOG(@"add fieldEdit to window contentView");
    [g_textInputResponder removeFromSuperview];
    [parentView addSubview: g_textInputResponder];
    [[NSApp keyWindow] makeFirstResponder: g_textInputResponder];
  }
}
void CWinSystemOSX::StopTextInput()
{
  if (g_textInputResponder)
  {
    [g_textInputResponder removeFromSuperview];
    g_textInputResponder = nil;
  }
}

void CWinSystemOSX::EnableTextInput(bool bEnable)
{
  //printf("CWinSystemOSX::EnableTextInput\n");
  if (bEnable)
    StartTextInput();
  else
    StopTextInput();
}


void CWinSystemOSX::Register(IDispResource *resource)
{
  CSingleLock lock(m_resourceSection);
  m_pScreenManager->Register(resource);
}

void CWinSystemOSX::Unregister(IDispResource* resource)
{
  CSingleLock lock(m_resourceSection);
  m_pScreenManager->Unregister(resource);
}

bool CWinSystemOSX::Show(bool raise)
{
  @autoreleasepool
  {
    auto app = [NSApplication sharedApplication];
    if (raise)
    {
      [app unhide:nil];
      [app activateIgnoringOtherApps:YES];
      [app arrangeInFront:nil];
    }
    else
    {
      [app unhideWithoutActivation];
    }
  }
  return true;
}

CGLContextObj CWinSystemOSX::GetCGLContextObj()
{
  CGLContextObj cglcontex = NULL;
  if(m_appWindow->window)
  {
    OSXGLView* contentView = [m_appWindow->window contentView];
    cglcontex = [[contentView getGLContext] CGLContextObj];
  }
  return cglcontex;
}

std::unique_ptr<CVideoSync> CWinSystemOSX::GetVideoSync(void *clock)
{
  std::unique_ptr<CVideoSync> pVSync(new CVideoSyncOsx(clock));
  return pVSync;
}

void CWinSystemOSX::GetConnectedOutputs(std::vector<std::string> *outputs)
{
  outputs->push_back("Default");

  int numDisplays = [[NSScreen screens] count];

  for (int disp = 0; disp < numDisplays; disp++)
  {
//    NSString *dispName = m_pScreenManager->screenNameForDisplay(m_pScreenManager->GetDisplayID(disp));
//    outputs->push_back([dispName UTF8String]);
  }
}

void CWinSystemOSX::FinishWindowResize(int newWidth, int newHeight)
{
  NSWindow *window = m_appWindow->window;
  OSXGLView *view = [window contentView];
  NSOpenGLContext *context = [view getGLContext];

  [context performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:YES];

  m_nWidth = newWidth;
  m_nHeight = newHeight;
}

void CWinSystemOSX::GetScreenResolution(int* w, int* h, double* fps, int screenIdx)
{
  CGDirectDisplayID display_id = (CGDirectDisplayID)m_pScreenManager->GetDisplayID(screenIdx);
  CGDisplayModeRef mode  = CGDisplayCopyDisplayMode(display_id);
  *w = CGDisplayModeGetWidth(mode);
  *h = CGDisplayModeGetHeight(mode);
  *fps = CGDisplayModeGetRefreshRate(mode);
  CGDisplayModeRelease(mode);
  if ((int)*fps == 0)
  {
    // NOTE: The refresh rate will be REPORTED AS 0 for many DVI and notebook displays.
    *fps = 60.0;
  }
}
