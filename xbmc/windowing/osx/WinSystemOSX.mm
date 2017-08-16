/*
 *      Copyright (C) 2005-2015 Team Kodi
 *      http://kodi.tv
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
 *  along with Kodi; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#include "WinSystemOSX.h"

#include "Application.h"
#include "cores/RetroPlayer/process/osx/RPProcessInfoOSX.h"
#include "cores/RetroPlayer/rendering/VideoRenderers/RPRendererOpenGL.h"
#include "cores/VideoPlayer/DVDCodecs/DVDFactoryCodec.h"
#include "cores/VideoPlayer/DVDCodecs/Video/VTB.h"
#include "cores/VideoPlayer/VideoRenderers/RenderFactory.h"
#include "cores/VideoPlayer/VideoRenderers/HwDecRender/RendererVTBGL.h"
#include "utils/log.h"
#include "platform/darwin/osx/CocoaInterface.h"
#include "platform/darwin/osx/OSXTextInputResponder.h"
#include "OSScreenSaverOSX.h"
#include "OSXGLView.h"
#include "OSXGLWindow.h"
#include "OSXScreenManager.h"
#include "ServiceBroker.h"
#include "settings/settings.h"
#include "VideoSyncOsx.h"


using namespace KODI;
using namespace KODI::WINDOWING;

//---------------------------------------------------------------------------------
//---------------------------------------------------------------------------------
CWinSystemOSX::CWinSystemOSX() : CWinSystemBase()
{
  m_eWindowSystem = WINDOW_SYSTEM_OSX;
  m_appWindow  = NULL;
  m_glView     = NULL;

  m_fullscreenWillToggle = false;
  m_lastX = 0;
  m_lastY = 0;
  m_pScreenManager = new COSXScreenManager();
}

CWinSystemOSX::~CWinSystemOSX()
{
  delete m_pScreenManager;
}

int CWinSystemOSX::GetNumScreens()
{
  return m_pScreenManager->GetNumScreens();
}

int CWinSystemOSX::GetCurrentScreen()
{
  return m_pScreenManager->GetCurrentScreen();
}

void CWinSystemOSX::EnableVSync(bool enable)
{
  m_pScreenManager->EnableVSync(enable);
}

void CWinSystemOSX::HandleDelayedDisplayReset()
{
  m_pScreenManager->HandleDelayedDisplayReset();
}

void CWinSystemOSX::Register(IDispResource *resource)
{
  m_pScreenManager->Register(resource);
}

void CWinSystemOSX::Unregister(IDispResource* resource)
{
  m_pScreenManager->Unregister(resource);
}

void CWinSystemOSX::SetMovedToOtherScreen(bool moved)
{
  m_pScreenManager->SetMovedToOtherScreen(moved);
}

void CWinSystemOSX::UpdateResolutions()
{
  CWinSystemBase::UpdateResolutions();
  
  m_pScreenManager->UpdateResolutions();
  bool blankOtherDisplays = CServiceBroker::GetSettings().GetBool(CSettings::SETTING_VIDEOSCREEN_BLANKDISPLAYS);
  if (blankOtherDisplays && m_bFullScreen)
  {
      m_pScreenManager->BlankOtherDisplays(m_pScreenManager->GetCurrentScreen());
  }
  else
  {
      m_pScreenManager->UnblankDisplays();
  }
}

void CWinSystemOSX::UpdateDesktopResolution(RESOLUTION_INFO& newRes, int screen, int width, int height, float refreshRate, uint32_t dwFlags)
{
  CWinSystemBase::UpdateDesktopResolution(newRes, screen, width, height, refreshRate, dwFlags);
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
  //printf("CWinSystemOSX::DestroyWindowSystem\n");
  
  m_pScreenManager->Deinit();

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // set this 1st, we should really mutex protext m_appWindow in this class
  m_bWindowCreated = false;
  if (m_appWindow)
  {
    NSWindow *oldAppWindow = (NSWindow*)m_appWindow;
    m_appWindow = NULL;
    [oldAppWindow setContentView:nil];
    [oldAppWindow release];
  }
  
  [pool release];
  
  if (m_glView)
  {
    // normally, this should happen here but we are racing internal object destructors
    // that make GL calls. They crash if the GLView is released.
    //[(OSXGLView*)m_glView release];
    m_glView = NULL;
  }
  
  return true;
}

bool CWinSystemOSX::DestroyWindow()
{
  // when using native fullscreen
  // we never destroy the window
  // we reuse it ...
  return true;
}

bool CWinSystemOSX::FlushBuffer(void)
{
  if (m_appWindow)
  {
    OSXGLView *contentView = [(NSWindow *)m_appWindow contentView];
    NSOpenGLContext *glcontex = [contentView getGLContext];
    [glcontex flushBuffer];
  }
  return true;
}

void CWinSystemOSX::NotifyAppFocusChange(bool bGaining)
{
  //printf("CWinSystemOSX::NotifyAppFocusChange\n");
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  if (m_bFullScreen && bGaining)
  {
    // find the window
    // TODO - why was this so complex!?!?!??!
    /*NSOpenGLContext* context = [NSOpenGLContext currentContext];
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
          [window orderFront:nil];
        }
      }
    }*/
    
    if (m_appWindow)
    {
      [(NSWindow *)m_appWindow orderFront:nil];
    }
  }
  [pool release];
}

void CWinSystemOSX::ShowOSMouse(bool show)
{
#warning TODO - do the mouse hide and show stuff once we figured it out
  //printf("CWinSystemOSX::ShowOSMouse %d\n", show);
  if (show)
  {
    //Cocoa_ShowMouse();
  }
  else
  {
    //Cocoa_HideMouse();
  }
}

bool CWinSystemOSX::Minimize()
{
  //printf("CWinSystemOSX::Minimize\n");
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [[NSApplication sharedApplication] miniaturizeAll:nil];

  [pool release];
  return true;
}

bool CWinSystemOSX::Restore()
{
  //printf("CWinSystemOSX::Restore\n");
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [[NSApplication sharedApplication] unhide:nil];

  [pool release];
  return true;
}

bool CWinSystemOSX::Hide()
{
  //printf("CWinSystemOSX::Hide\n");
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [[NSApplication sharedApplication] hide:nil];

  [pool release];
  return true;
}

OSXTextInputResponder *g_textInputResponder = nil;
bool CWinSystemOSX::IsTextInputEnabled()
{
  //printf("CWinSystemOSX::IsTextInputEnabled\n");
  return g_textInputResponder != nil && [[g_textInputResponder superview] isEqual: [[NSApp keyWindow] contentView]];
}

void CWinSystemOSX::StartTextInput()
{
  //printf("CWinSystemOSX::StartTextInput\n");
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
  //printf("CWinSystemOSX::StopTextInput\n");
  if (g_textInputResponder) {
    [g_textInputResponder removeFromSuperview];
    [g_textInputResponder release];
    g_textInputResponder = nil;
  }
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
  if (m_appWindow)
  {
    NSWindow *win = (NSWindow *)m_appWindow;
    NSRect frame = [[win contentView] frame];
    point->y = frame.size.height - point->y;
  }
}

std::unique_ptr<IOSScreenSaver> CWinSystemOSX::GetOSScreenSaverImpl()
{
  return std::unique_ptr<IOSScreenSaver> (new COSScreenSaverOSX);
}

void CWinSystemOSX::EnableTextInput(bool bEnable)
{
  //printf("CWinSystemOSX::EnableTextInput\n");
  if (bEnable)
    StartTextInput();
  else
    StopTextInput();
}

bool CWinSystemOSX::Show(bool raise)
{
  //printf("CWinSystemOSX::Show\n");
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  if (raise)
  {
    [[NSApplication sharedApplication] unhide:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
    [[NSApplication sharedApplication] arrangeInFront:nil];
  }
  else
  {
    [[NSApplication sharedApplication] unhideWithoutActivation];
  }

  [pool release];
  return true;
}

CGLContextObj CWinSystemOSX::GetCGLContextObj()
{
  CGLContextObj cglcontex = NULL;
  if(m_appWindow)
  {
    OSXGLView *contentView = [(NSWindow*)m_appWindow contentView];
    cglcontex = [[contentView getGLContext] CGLContextObj];
  }

  return cglcontex;
}

// TODO from here on - all methods might be relevant to misbehavior!
bool CWinSystemOSX::CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res)
{
  //printf("CWinSystemOSX::CreateNewWindow\n");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  m_nWidth      = res.iWidth;
  m_nHeight     = res.iHeight;
  m_bFullScreen = fullScreen;

  // for native fullscreen we always want to set the same windowed flags
  NSUInteger windowStyleMask;

  windowStyleMask = NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
  NSString *title = [NSString stringWithUTF8String:name.c_str()];

  if (m_appWindow == NULL)
  {
    NSWindow *appWindow = [[OSXGLWindow alloc] initWithContentRect:NSMakeRect(0, 0, m_nWidth, m_nHeight) styleMask:windowStyleMask];
    [appWindow setBackgroundColor:[NSColor blackColor]];
    [appWindow setOneShot:NO];
    [appWindow setMinSize:NSMakeSize(500, 300)];

    NSWindowCollectionBehavior behavior = [appWindow collectionBehavior];
    behavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    [appWindow setCollectionBehavior:behavior];

    // create new content view
    NSRect rect = [appWindow contentRectForFrameRect:[appWindow frame]];

    // create new view if we don't have one
    if(!m_glView)
      m_glView = [[OSXGLView alloc] initWithFrame:rect];
    OSXGLView *contentView = (OSXGLView*)m_glView;

    // associate with current window
    [appWindow setContentView: contentView];
    [[contentView getGLContext] makeCurrentContext];
    [[contentView getGLContext] update];

    m_appWindow = appWindow;
    m_bWindowCreated = true;
    m_pScreenManager->RegisterWindow(appWindow);
  }
  
  [(NSWindow*)m_appWindow performSelectorOnMainThread:@selector(setTitle:) withObject:title waitUntilDone:YES];
  [(NSWindow*)m_appWindow performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:nil waitUntilDone:YES];

  HandleNativeMousePosition();
  [pool release];

  SetFullScreen(m_bFullScreen, res, false);

  // register platform dependent objects
  CDVDFactoryCodec::ClearHWAccels();
  VTB::CDecoder::Register();
  VIDEOPLAYER::CRendererFactory::ClearRenderer();
  CLinuxRendererGL::Register();
  CRendererVTB::Register();
  RETRO::CRPProcessInfoOSX::Register();
  RETRO::CRPProcessInfoOSX::RegisterRendererFactory(new RETRO::CRendererFactoryOpenGL);

  return true;
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
  if ([NSWindow windowNumberAtPoint:mouse belowWindowWithWindowNumber:0] == ((NSWindow *)m_appWindow).windowNumber)
  {
    // warp XBMC cursor to our position
    NSPoint locationInWindowCoords = [(NSWindow *)m_appWindow mouseLocationOutsideOfEventStream];
    XBMC_Event newEvent;
    memset(&newEvent, 0, sizeof(newEvent));
    newEvent.type = XBMC_MOUSEMOTION;
    newEvent.motion.x =  locationInWindowCoords.x;
    newEvent.motion.y =  locationInWindowCoords.y;
    g_application.OnEvent(newEvent);
  }
  else// show native cursor as its outside of our window
  {
    Cocoa_ShowMouse();
  }
}

// this is either called from SetFullScreen (so internally) or
bool CWinSystemOSX::ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop)
{
  //printf("CWinSystemOSX::ResizeWindow\n");
  if (!m_appWindow)
    return false;

  if (newWidth < 0)
  {
    newWidth = [(NSWindow *)m_appWindow minSize].width;
  }

  if (newHeight < 0)
  {
    newHeight = [(NSWindow *)m_appWindow minSize].height;
  }

  NSWindow *window = (NSWindow*)m_appWindow;

  NSRect pos = [window frame];
  newLeft = pos.origin.x;
  newTop = pos.origin.y;

  NSRect myNewContentFrame = NSMakeRect(newLeft, newTop, newWidth, newHeight);
  NSRect myNewWindowRect = [window frameRectForContentRect:myNewContentFrame];
  [window setFrame:myNewWindowRect display:TRUE];

  return true;
}

// this not only toggles full screen - it also
// needs to move from screen to screen if needed
// either when moving the windowed mode to a different
// screen and toggle fullscreen or by moveing from full
// screen #1 to #2 for example.
// the idea is to Make use of the native full screen
// handling as much as possible here and only do as
// much resizing/moving programmatically as needed.
bool CWinSystemOSX::SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays)
{
  CSingleLock lock (m_critSection);

  OSXGLWindow *window = (OSXGLWindow *)m_appWindow;

  bool screenChanged = m_pScreenManager->SetLastDisplayNr(res.iScreen);
  bool fullScreen2FullScreen = m_bFullScreen && fullScreen && screenChanged;
  m_nWidth      = res.iWidth;
  m_nHeight     = res.iHeight;
  m_bFullScreen = fullScreen;


  [window setAllowsConcurrentViewDrawing:NO];
  
  SetFullscreenWillToggle(m_bFullScreen != [window isFullScreen]);

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
    if (fullScreen2FullScreen && [window isFullScreen])
    {
      NSScreen* pScreen = [[NSScreen screens] objectAtIndex:res.iScreen];
      [window performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];
      NSRect rectOnNewScreen = [window constrainFrameRect:[window frame] toScreen:pScreen];
      ResizeWindow(rectOnNewScreen.size.width, rectOnNewScreen.size.width, rectOnNewScreen.origin.x, rectOnNewScreen.origin.y);
    }
    
    [window performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];
  }

  if (m_bFullScreen)
  {
    // switch videomode
    m_pScreenManager->SwitchToVideoMode(res.iWidth, res.iHeight, res.fRefreshRate, res.iScreen);
    NSScreen* pScreen = [[NSScreen screens] objectAtIndex:res.iScreen];
    NSRect    screenRect = [pScreen frame];
    // ensure we use the screen rect origin here - because we might want to display on
    // a different monitor (which has the monitor offset in x and y origin ...)
    ResizeWindow(m_nWidth, m_nHeight, screenRect.origin.x, screenRect.origin.y);
    
    // blank all other dispalys if requested
    if (blankOtherDisplays)
    {
        m_pScreenManager->BlankOtherDisplays(res.iScreen);
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

  [window setAllowsConcurrentViewDrawing:YES];

  return true;
}

void CWinSystemOSX::OnMove(int x, int y)
{
  //printf("CWinSystemOSX::OnMove\n");
  m_lastX      = x;
  m_lastY      = y;
}

std::unique_ptr<CVideoSync> CWinSystemOSX::GetVideoSync(void *clock)
{
  std::unique_ptr<CVideoSync> pVSync(new CVideoSyncOsx(clock));
  return pVSync;
}
