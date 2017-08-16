/*
 *      Copyright (C) 2017 Team Kodi
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

#include "OSXScreenManager.h"
#include "ServiceBroker.h"
#include "guilib/DispResource.h"
#include "guilib/GraphicContext.h"
#include "platform/darwin/osx/CocoaInterface.h"
#include "settings/Settings.h"
#include "settings/DisplaySettings.h"
#include "utils/log.h"
#include "utils/StringUtils.h"
#include "windowing/osx/WinSystemOSX.h"

#include <algorithm>
#import <Cocoa/Cocoa.h>
#import <IOKit/graphics/IOGraphicsLib.h>

//------------------------------------------------------------------------------------------

// if there was a devicelost callback but no device reset for 3 secs
// a timeout fires the reset callback (for ensuring that e.x. AE isn't stuck)
#define LOST_DEVICE_TIMEOUT_MS 3000

//---------------------------------------------------------------------------------
CGDirectDisplayID GetDisplayID(int screen_index)
{
  CGDirectDisplayID displayArray[MAX_DISPLAYS];
  CGDisplayCount    numDisplays;
  
  // Get the list of displays.
  CGGetActiveDisplayList(MAX_DISPLAYS, displayArray, &numDisplays);
  return displayArray[screen_index];
}

CGDirectDisplayID GetDisplayIDFromScreen(NSScreen *screen)
{
  NSDictionary* screenInfo = [screen deviceDescription];
  NSNumber* screenID = [screenInfo objectForKey:@"NSScreenNumber"];
  
  return (CGDirectDisplayID)[screenID longValue];
}

size_t DisplayBitsPerPixelForMode(CGDisplayModeRef mode)
{
  size_t bitsPerPixel = 0;
  
  CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
  if(CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
  {
    bitsPerPixel = 32;
  }
  else if(CFStringCompare(pixEnc, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
  {
    bitsPerPixel = 16;
  }
  else if(CFStringCompare(pixEnc, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
  {
    bitsPerPixel = 8;
  }
  
  CFRelease(pixEnc);
  
  return bitsPerPixel;
}

// mimic former behavior of deprecated CGDisplayBestModeForParameters
CGDisplayModeRef BestMatchForMode(CGDirectDisplayID display, size_t bitsPerPixel, size_t width, size_t height, boolean_t &match)
{
  // Get a copy of the current display mode
  CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
  
  // Loop through all display modes to determine the closest match.
  // CGDisplayBestModeForParameters is deprecated on 10.6 so we will emulate it's behavior
  // Try to find a mode with the requested depth and equal or greater dimensions first.
  // If no match is found, try to find a mode with greater depth and same or greater dimensions.
  // If still no match is found, just use the current mode.
  CFArrayRef allModes = CGDisplayCopyAllDisplayModes(kCGDirectMainDisplay, NULL);
  for(int i = 0; i < CFArrayGetCount(allModes); i++)	{
    CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
    
    if(DisplayBitsPerPixelForMode(mode) != bitsPerPixel)
      continue;
    
    if((CGDisplayModeGetWidth(mode) == width) && (CGDisplayModeGetHeight(mode) == height))
    {
      CGDisplayModeRelease(displayMode); // rlease the copy we got before ...
      displayMode = mode;
      match = true;
      break;
    }
  }
  
  // No depth match was found
  if(!match)
  {
    for(int i = 0; i < CFArrayGetCount(allModes); i++)
    {
      CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
      if(DisplayBitsPerPixelForMode(mode) >= bitsPerPixel)
        continue;
      
      if((CGDisplayModeGetWidth(mode) == width) && (CGDisplayModeGetHeight(mode) == height))
      {
        displayMode = mode;
        match = true;
        break;
      }
    }
  }
  
  CFRelease(allModes);
  
  return displayMode;
}

int GetDisplayIndex(CGDirectDisplayID display)
{
  CGDirectDisplayID displayArray[MAX_DISPLAYS];
  CGDisplayCount    numDisplays;
  
  // Get the list of displays.
  CGGetActiveDisplayList(MAX_DISPLAYS, displayArray, &numDisplays);
  while (numDisplays > 0)
  {
    if (display == displayArray[--numDisplays])
      return numDisplays;
  }
  return -1;
}

NSString* screenNameForDisplay(CGDirectDisplayID displayID)
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  NSString *screenName = nil;
  
  // IODisplayCreateInfoDictionary leaks IOCFUnserializeparse, nothing we can do about it.
  NSDictionary *deviceInfo = (NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
  NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
  
  if ([localizedNames count] > 0) {
    screenName = [[localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]] retain];
  }
  
  [deviceInfo release];
  [pool release];
  
  return [screenName autorelease];
}

// try to find mode that matches the desired size, refreshrate
// non interlaced, nonstretched, safe for hardware
CGDisplayModeRef GetMode(int width, int height, double refreshrate, int screenIdx)
{
  if ( screenIdx >= (signed)[[NSScreen screens] count])
    return NULL;
  
  Boolean stretched;
  Boolean interlaced;
  Boolean safeForHardware;
  Boolean televisionoutput;
  int w, h, bitsperpixel;
  double rate;
  RESOLUTION_INFO res;
  
  CLog::Log(LOGDEBUG, "GetMode looking for suitable mode with %d x %d @ %f Hz on display %d\n", width, height, refreshrate, screenIdx);
  
  CFArrayRef displayModes = CGDisplayCopyAllDisplayModes(GetDisplayID(screenIdx), nullptr);
  
  if (NULL == displayModes)
  {
    CLog::Log(LOGERROR, "GetMode - no displaymodes found!");
    return NULL;
  }
  
  for (int i=0; i < CFArrayGetCount(displayModes); ++i)
  {
    CGDisplayModeRef displayMode = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModes, i);
    uint32_t flags = CGDisplayModeGetIOFlags(displayMode);
    stretched = flags & kDisplayModeStretchedFlag ? true : false;
    interlaced = flags & kDisplayModeInterlacedFlag ? true : false;
    bitsperpixel = DisplayBitsPerPixelForMode(displayMode);
    safeForHardware = flags & kDisplayModeSafetyFlags ? true : false;
    televisionoutput = flags & kDisplayModeTelevisionFlag ? true : false;
    w = CGDisplayModeGetWidth(displayMode);
    h = CGDisplayModeGetHeight(displayMode);
    rate = CGDisplayModeGetRefreshRate(displayMode);
    
    
    if ((bitsperpixel == 32)      &&
        (safeForHardware == YES)  &&
        (stretched == NO)         &&
        (interlaced == NO)        &&
        (w == width)              &&
        (h == height)             &&
        (rate == refreshrate || rate == 0))
    {
      CLog::Log(LOGDEBUG, "GetMode found a match!");
      return displayMode;
    }
  }
  
  CFRelease(displayModes);
  CLog::Log(LOGERROR, "GetMode - no match found!");
  return NULL;
}
//---------------------------------------------------------------------------------
static void DisplayReconfigured(CGDirectDisplayID display,
                                CGDisplayChangeSummaryFlags flags, void* userData)
{
  COSXScreenManager *screenManager = (COSXScreenManager*)userData;
  if (!screenManager)
    return;
  
  CLog::Log(LOGDEBUG, "COSXScreenManager::DisplayReconfigured with flags %d", flags);
  
  // we fire the callbacks on start of configuration
  // or when the mode set was finished
  // or when we are called with flags == 0 (which is undocumented but seems to happen
  // on some macs - we treat it as device reset)
  
  // first check if we need to call OnLostDevice
  if (flags & kCGDisplayBeginConfigurationFlag)
  {
    // pre/post-reconfiguration changes
    RESOLUTION res = g_graphicsContext.GetVideoResolution();
    if (res == RES_INVALID)
      return;
    
    NSScreen* pScreen = nil;
    unsigned int screenIdx = CDisplaySettings::GetInstance().GetResolutionInfo(res).iScreen;
    
    if ( screenIdx < [[NSScreen screens] count] )
    {
      pScreen = [[NSScreen screens] objectAtIndex:screenIdx];
    }
    
    // kCGDisplayBeginConfigurationFlag is only fired while the screen is still
    // valid
    if (pScreen)
    {
      CGDirectDisplayID xbmc_display = GetDisplayIDFromScreen(pScreen);
      if (xbmc_display == display)
      {
        // we only respond to changes on the display we are running on.
        screenManager->AnnounceOnLostDevice();
        screenManager->StartLostDeviceTimer();
      }
    }
  }
  else // the else case checks if we need to call OnResetDevice
  {
    // we fire if kCGDisplaySetModeFlag is set or if flags == 0
    // (which is undocumented but seems to happen
    // on some macs - we treat it as device reset)
    // we also don't check the screen here as we might not even have
    // one anymore (e.x. when tv is turned off)
    if (flags & kCGDisplaySetModeFlag || flags == 0)
    {
      screenManager->StopLostDeviceTimer(); // no need to timeout - we've got the callback
      screenManager->HandleOnResetDevice();
    }
  }
  
  if ((flags & kCGDisplayAddFlag) || (flags & kCGDisplayRemoveFlag))
    screenManager->UpdateResolutions();
}

COSXScreenManager::COSXScreenManager() : m_lostDeviceTimer(this)
{
  m_refreshRate = 0.0;
  m_delayDispReset = false;
  m_movedToOtherScreen = false;
  m_lastDisplayNr = -1;
  m_pAppWindow = nil;
  
  for (int i=0; i<MAX_DISPLAYS; i++)
  {
    m_blankingWindows[i] = 0;
  }
}

COSXScreenManager::~COSXScreenManager()
{
}

void COSXScreenManager::Init(CWinSystemOSX *windowing)
{
  m_pWindowing = windowing;
  CGDisplayRegisterReconfigurationCallback(DisplayReconfigured, (void*)this);
}

void COSXScreenManager::RegisterWindow(NSWindow *appWindow)
{
  m_pAppWindow = appWindow;
}

void COSXScreenManager::Deinit()
{
  UnblankDisplays();
  CGDisplayRemoveReconfigurationCallback(DisplayReconfigured, (void*)this);
  m_pWindowing = nil;
}

void COSXScreenManager::Register(IDispResource *resource)
{
  //printf("COSXScreenManager::Register\n");
  CSingleLock lock(m_resourceSection);
  m_resources.push_back(resource);
}

void COSXScreenManager::Unregister(IDispResource* resource)
{
  //printf("COSXScreenManager::Unregister\n");
  CSingleLock lock(m_resourceSection);
  std::vector<IDispResource*>::iterator i = find(m_resources.begin(), m_resources.end(), resource);
  if (i != m_resources.end())
    m_resources.erase(i);
}


void COSXScreenManager::AnnounceOnLostDevice()
{
  CSingleLock lock(m_resourceSection);
  // tell any shared resources
  CLog::Log(LOGDEBUG, "COSXScreenManager::AnnounceOnLostDevice");
  for (std::vector<IDispResource *>::iterator i = m_resources.begin(); i != m_resources.end(); i++)
    (*i)->OnLostDisplay();
}

void COSXScreenManager::HandleOnResetDevice()
{
  int delay = CServiceBroker::GetSettings().GetInt("videoscreen.delayrefreshchange");
  if (delay > 0)
  {
    m_delayDispReset = true;
    m_dispResetTimer.Set(delay * 100);
  }
  else
  {
    AnnounceOnResetDevice();
  }
}

void COSXScreenManager::AnnounceOnResetDevice()
{
  CSingleLock lock(m_resourceSection);
  // tell any shared resources
  CLog::Log(LOGDEBUG, "COSXScreenManager::AnnounceOnResetDevice");
  for (std::vector<IDispResource *>::iterator i = m_resources.begin(); i != m_resources.end(); i++)
    (*i)->OnResetDisplay();
}


void COSXScreenManager::StartLostDeviceTimer()
{
  if (m_lostDeviceTimer.IsRunning())
    m_lostDeviceTimer.Restart();
  else
    m_lostDeviceTimer.Start(LOST_DEVICE_TIMEOUT_MS, false);
}

void COSXScreenManager::StopLostDeviceTimer()
{
  m_lostDeviceTimer.Stop();
}

void COSXScreenManager::OnTimeout()
{
  HandleOnResetDevice();
}

void COSXScreenManager::UpdateResolutions()
{
  // Add desktop resolution
  int w, h;
  double fps;
  
  // first screen goes into the current desktop mode
  GetScreenResolution(&w, &h, &fps, 0);
  m_pWindowing->UpdateDesktopResolution(CDisplaySettings::GetInstance().GetResolutionInfo(RES_DESKTOP), 0, w, h, fps);
  
  NSString *dispName = screenNameForDisplay(GetDisplayID(0));
  
  if (dispName != nil)
  {
    CDisplaySettings::GetInstance().GetResolutionInfo(RES_DESKTOP).strOutput = [dispName UTF8String];
  }
  
  CDisplaySettings::GetInstance().ClearCustomResolutions();
  
  // see resolution.h enum RESOLUTION for how the resolutions
  // have to appear in the resolution info vector in CDisplaySettings
  // add the desktop resolutions of the other screens
  for(int i = 1; i < GetNumScreens(); i++)
  {
    RESOLUTION_INFO res;
    // get current resolution of screen i
    GetScreenResolution(&w, &h, &fps, i);
    m_pWindowing->UpdateDesktopResolution(res, i, w, h, fps);
    dispName = screenNameForDisplay(GetDisplayID(i));
    
    if (dispName != nil)
    {
      res.strOutput = [dispName UTF8String];
    }
    
    CDisplaySettings::GetInstance().AddResolutionInfo(res);
  }
  
  // now just fill in the possible reolutions for the attached screens
  // and push to the resolution info vector
  FillInVideoModes();
  
  CDisplaySettings::GetInstance().ApplyCalibrations();
}

void COSXScreenManager::GetScreenResolution(int* w, int* h, double* fps, int screenIdx)
{
  // Figure out the screen size. (default to main screen)
  if (screenIdx >= GetNumScreens())
    return;
  CGDirectDisplayID display_id = (CGDirectDisplayID)GetDisplayID(screenIdx);
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

void COSXScreenManager::EnableVSync(bool enable)
{
  // OpenGL Flush synchronised with vertical retrace
  GLint swapInterval = enable ? 1 : 0;
  [[NSOpenGLContext currentContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
}

void COSXScreenManager::HandleDelayedDisplayReset()
{
  if (m_delayDispReset && m_dispResetTimer.IsTimePast())
  {
    m_delayDispReset = false;
    AnnounceOnResetDevice();
  }
}

bool COSXScreenManager::SetLastDisplayNr(int lastDisplayNr)
{
  bool displayNumberChanged = m_lastDisplayNr != lastDisplayNr;
  m_lastDisplayNr = lastDisplayNr;
  return displayNumberChanged;
}

bool COSXScreenManager::SwitchToVideoMode(int width, int height, double refreshrate, int screenIdx)
{
  // SwitchToVideoMode will not return until the display has actually switched over.
  // This can take several seconds.
  if( screenIdx >= GetNumScreens())
    return false;
  
  boolean_t match = false;
  CGDisplayModeRef dispMode = NULL;
  // Figure out the screen size. (default to main screen)
  CGDirectDisplayID display_id = GetDisplayID(screenIdx);
  
  // find mode that matches the desired size, refreshrate
  // non interlaced, nonstretched, safe for hardware
  dispMode = GetMode(width, height, refreshrate, screenIdx);
  
  //not found - fallback to bestemdeforparameters
  if (!dispMode)
  {
    dispMode = BestMatchForMode(display_id, 32, width, height, match);
    
    if (!match)
      dispMode = BestMatchForMode(display_id, 16, width, height, match);
    
    // still no match? fallback to current resolution of the display which HAS to work [tm]
    if (!match)
    {
      int tmpWidth;
      int tmpHeight;
      double tmpRefresh;
      
      GetScreenResolution(&tmpWidth, &tmpHeight, &tmpRefresh, screenIdx);
      dispMode = GetMode(tmpWidth, tmpHeight, tmpRefresh, screenIdx);
      
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

void COSXScreenManager::FillInVideoModes()
{
  // Add full screen settings for additional monitors
  int numDisplays = [[NSScreen screens] count];
  
  for (int disp = 0; disp < numDisplays; disp++)
  {
    Boolean stretched;
    Boolean interlaced;
    Boolean safeForHardware;
    Boolean televisionoutput;
    int w, h, bitsperpixel;
    double refreshrate;
    RESOLUTION_INFO res;
    
    CFArrayRef displayModes = CGDisplayCopyAllDisplayModes(GetDisplayID(disp), nullptr);
    NSString *dispName = screenNameForDisplay(GetDisplayID(disp));
    
    if (dispName != nil)
    {
      CLog::Log(LOGNOTICE, "Display %i has name %s", disp, [dispName UTF8String]);
    }
    
    if (NULL == displayModes)
      continue;
    
    for (int i=0; i < CFArrayGetCount(displayModes); ++i)
    {
      CGDisplayModeRef displayMode = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModes, i);
      
      uint32_t flags = CGDisplayModeGetIOFlags(displayMode);
      stretched = flags & kDisplayModeStretchedFlag ? true : false;
      interlaced = flags & kDisplayModeInterlacedFlag ? true : false;
      bitsperpixel = DisplayBitsPerPixelForMode(displayMode);
      safeForHardware = flags & kDisplayModeSafetyFlags ? true : false;
      televisionoutput = flags & kDisplayModeTelevisionFlag ? true : false;
      
      if ((bitsperpixel == 32)      &&
          (safeForHardware == YES)  &&
          (stretched == NO)         &&
          (interlaced == NO))
      {
        w = CGDisplayModeGetWidth(displayMode);
        h = CGDisplayModeGetHeight(displayMode);
        refreshrate = CGDisplayModeGetRefreshRate(displayMode);
        if ((int)refreshrate == 0)  // LCD display?
        {
          // NOTE: The refresh rate will be REPORTED AS 0 for many DVI and notebook displays.
          refreshrate = 60.0;
        }
        CLog::Log(LOGNOTICE, "Found possible resolution for display %d with %d x %d @ %f Hz\n", disp, w, h, refreshrate);
        
        m_pWindowing->UpdateDesktopResolution(res, disp, w, h, refreshrate);
        
        // overwrite the mode str because  UpdateDesktopResolution adds a
        // "Full Screen". Since the current resolution is there twice
        // this would lead to 2 identical resolution entrys in the guisettings.xml.
        // That would cause problems with saving screen overscan calibration
        // because the wrong entry is picked on load.
        // So we just use UpdateDesktopResolutions for the current DESKTOP_RESOLUTIONS
        // in UpdateResolutions. And on all other resolutions make a unique
        // mode str by doing it without appending "Full Screen".
        // this is what linux does - though it feels that there shouldn't be
        // the same resolution twice... - thats why i add a FIXME here.
        res.strMode = StringUtils::Format("%dx%d @ %.2f", w, h, refreshrate);
        
        if (dispName != nil)
        {
          res.strOutput = [dispName UTF8String];
        }
        
        g_graphicsContext.ResetOverscan(res);
        CDisplaySettings::GetInstance().AddResolutionInfo(res);
      }
    }
    CFRelease(displayModes);
  }
}

int COSXScreenManager::GetNumScreens()
{
  int numDisplays = [[NSScreen screens] count];
  return(numDisplays);
}

int COSXScreenManager::GetCurrentScreen()
{
  
  // if user hasn't moved us in windowed mode - return the
  // last display we were fullscreened at
  if (!m_movedToOtherScreen)
    return m_lastDisplayNr;
  
  if (m_pAppWindow)
  {
    m_movedToOtherScreen = false;
    return GetDisplayIndex(GetDisplayIDFromScreen( [m_pAppWindow screen]));
  }
  return 0;
}

void COSXScreenManager::SetMovedToOtherScreen(bool moved)
{
  m_movedToOtherScreen = moved;
  if (moved)
  {
    m_lastDisplayNr = GetCurrentScreen();
    HandlePossibleRefreshrateChange();
  }
}

void COSXScreenManager::HandlePossibleRefreshrateChange()
{
  static double oldRefreshRate = m_refreshRate;
  Cocoa_CVDisplayLinkUpdate();
  int dummy = 0;
  
  GetScreenResolution(&dummy, &dummy, &m_refreshRate, GetCurrentScreen());
  
  if (oldRefreshRate != m_refreshRate)
  {
    oldRefreshRate = m_refreshRate;
    // send a message so that videoresolution (and refreshrate) is changed
    if (m_pAppWindow)
    {
      NSRect frame = [[m_pAppWindow contentView] frame];
      XBMC_Event msg{XBMC_VIDEORESIZE};
      msg.resize = {static_cast<int>(frame.size.width), static_cast<int>(frame.size.height)};
      CWinEvents::MessagePush(&msg);
    }
  }
}

void CloseWindow(NSWindow *window)
{
  [window close];
  if ([window isReleasedWhenClosed] == NO)
    [window release];
}

/*\brief Blank all display but the display with the given index
 *@param screen_index - the index of the display that should NOT be blanked
 */
void COSXScreenManager::BlankOtherDisplays(int screen_index)
{
  Cocoa_RunBlockOnMainQueue(^{
    
    CGCaptureAllDisplays();
    NSUInteger numDisplays = std::min((NSUInteger)MAX_DISPLAYS,[[NSScreen screens] count]);
  
    // Blank.
    for (int i=0; i<numDisplays; i++)
    {
      if (i != screen_index && m_blankingWindows[i] == 0)
      {
        // Get the size.
        NSScreen* pScreen = [[NSScreen screens] objectAtIndex:i];
        NSRect    screenRect = [pScreen frame];
      
        // Build a blanking window.
        screenRect.origin = NSZeroPoint;
        m_blankingWindows[i] = [[NSWindow alloc] initWithContentRect:screenRect
                                                 styleMask:NSBorderlessWindowMask
                                                 backing:NSBackingStoreBuffered
                                                 defer:NO
                                                 screen:pScreen];

        [m_blankingWindows[i] setBackgroundColor:[NSColor blackColor]];
        [m_blankingWindows[i] setLevel:CGShieldingWindowLevel()];
        [m_blankingWindows[i] makeKeyAndOrderFront:nil];
      }
      else// ensure the screen that shouldn't be blanked really isn't
      {
        CloseWindow(m_blankingWindows[i]);
        m_blankingWindows[i] = 0;
      }
    }
    CGReleaseAllDisplays();
  });
}

void COSXScreenManager::UnblankDisplays(void)
{
  Cocoa_RunBlockOnMainQueue(^{
    
    CGCaptureAllDisplays();
    NSUInteger numDisplays = std::min((NSUInteger)MAX_DISPLAYS,[[NSScreen screens] count]);
  
    for (int i=0; i<numDisplays; i++)
    {
      if (m_blankingWindows[i] != 0)
      {
        // Get rid of the blanking windows we created.
        CloseWindow(m_blankingWindows[i]);
        m_blankingWindows[i] = 0;
      }
    }
    CGReleaseAllDisplays();
  });
}

