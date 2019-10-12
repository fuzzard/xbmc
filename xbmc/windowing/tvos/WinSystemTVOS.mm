/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */


#include "WinSystemTVOS.h"

#include "OSScreenSaverTVOS.h"
#include "VideoSyncTVos.h"
#include "WinEventsTVOS.h"
#include "cores/AudioEngine/Sinks/AESinkDARWINIOS.h"
#include "cores/RetroPlayer/process/ios/RPProcessInfoIOS.h"
#include "cores/RetroPlayer/rendering/VideoRenderers/RPRendererOpenGLES.h"
#include "cores/VideoPlayer/DVDCodecs/DVDFactoryCodec.h"
#include "cores/VideoPlayer/DVDCodecs/Video/VTB.h"
#include "cores/VideoPlayer/Process/ios/ProcessInfoIOS.h"
#include "cores/VideoPlayer/VideoRenderers/HwDecRender/RendererVTBGLES.h"
#include "cores/VideoPlayer/VideoRenderers/LinuxRendererGLES.h"
#include "cores/VideoPlayer/VideoRenderers/RenderFactory.h"
#include "filesystem/SpecialProtocol.h"
#include "guilib/DispResource.h"
#include "guilib/Texture.h"
#include "messaging/ApplicationMessenger.h"
#include "settings/DisplaySettings.h"
#include "settings/Settings.h"
#include "settings/SettingsComponent.h"
#include "threads/SingleLock.h"
#include "utils/StringUtils.h"
#include "utils/log.h"
#include "windowing/GraphicContext.h"
#include "windowing/OSScreenSaver.h"

#include "platform/darwin/DarwinUtils.h"
#include "platform/darwin/tvos/XBMCController.h"

#include <memory>
#include <vector>

#include <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <QuartzCore/CADisplayLink.h>

#define AVMediaType AVMediaType_FFMPEG
#import <AVFoundation/AVPlayer.h>
#undef AVMediaType

#define CONST_HDMI "HDMI"

// if there was a devicelost callback
// but no device reset for 3 secs
// a timeout fires the reset callback
// (for ensuring that e.x. AE isn't stuck)
constexpr uint32_t LOST_DEVICE_TIMEOUT_MS{3000};

// IOSDisplayLinkCallback is declared in the lower part of the file
@interface IOSDisplayLinkCallback : NSObject
{
@private
  CVideoSyncTVos* videoSyncImpl;
}
@property(nonatomic, setter=SetVideoSyncImpl:) CVideoSyncTVos* videoSyncImpl;
- (void)runDisplayLink;
@end

using namespace KODI;
using namespace MESSAGING;

struct CADisplayLinkWrapper
{
  CADisplayLink* impl;
  IOSDisplayLinkCallback* callbackClass;
};

std::unique_ptr<CWinSystemBase> CWinSystemBase::CreateWinSystem()
{
  std::unique_ptr<CWinSystemBase> winSystem(new CWinSystemTVOS());
  return winSystem;
}

void CWinSystemTVOS::MessagePush(XBMC_Event* newEvent)
{
  dynamic_cast<CWinEventsTVOS&>(*m_winEvents).MessagePush(newEvent);
}

size_t CWinSystemTVOS::GetQueueSize()
{
  return dynamic_cast<CWinEventsTVOS&>(*m_winEvents).GetQueueSize();
}

void CWinSystemTVOS::AnnounceOnLostDevice()
{
  CSingleLock lock(m_resourceSection);
  // tell any shared resources
  CLog::Log(LOGDEBUG, "CWinSystemTVOS::AnnounceOnLostDevice");
  for (std::vector<IDispResource*>::iterator i = m_resources.begin(); i != m_resources.end(); i++)
    (*i)->OnLostDisplay();
}

void CWinSystemTVOS::AnnounceOnResetDevice()
{
  CSingleLock lock(m_resourceSection);
  // tell any shared resources
  CLog::Log(LOGDEBUG, "CWinSystemTVOS::AnnounceOnResetDevice");
  for (std::vector<IDispResource*>::iterator i = m_resources.begin(); i != m_resources.end(); i++)
    (*i)->OnResetDisplay();
}

void CWinSystemTVOS::StartLostDeviceTimer()
{
  if (m_lostDeviceTimer.IsRunning())
    m_lostDeviceTimer.Restart();
  else
    m_lostDeviceTimer.Start(LOST_DEVICE_TIMEOUT_MS, false);
}

void CWinSystemTVOS::StopLostDeviceTimer()
{
  m_lostDeviceTimer.Stop();
}


int CWinSystemTVOS::GetDisplayIndexFromSettings()
{
  // ATV only supports 1 screen currently
  int screenIdx = 0;

  return screenIdx;
}

CWinSystemTVOS::CWinSystemTVOS()
  : CWinSystemBase()
  , m_lostDeviceTimer(this)
{
  m_bIsBackgrounded = false;
  m_pDisplayLink = new CADisplayLinkWrapper;
  m_pDisplayLink->callbackClass = [[IOSDisplayLinkCallback alloc] init];

  m_winEvents.reset(new CWinEventsTVOS());

  CAESinkDARWINIOS::Register();
}

CWinSystemTVOS::~CWinSystemTVOS()
{
  m_pDisplayLink->callbackClass = nil;
  delete m_pDisplayLink;
}

bool CWinSystemTVOS::InitWindowSystem()
{
  return CWinSystemBase::InitWindowSystem();
}

bool CWinSystemTVOS::DestroyWindowSystem()
{
  return true;
}

std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> CWinSystemTVOS::GetOSScreenSaverImpl()
{
  return std::unique_ptr<KODI::WINDOWING::IOSScreenSaver>(new COSScreenSaverTVOS);
}

bool CWinSystemTVOS::CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res)
{
  if (!SetFullScreen(fullScreen, res, false))
    return false;

  [g_xbmcController setFramebuffer];

  m_bWindowCreated = true;

  m_eglext = " ";

  const char* tmpExtensions = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
  if (tmpExtensions != nullptr)
  {
    m_eglext += tmpExtensions;
  }

  m_eglext += " ";

  CLog::Log(LOGDEBUG, "EGL_EXTENSIONS:%s", m_eglext.c_str());

  // register platform dependent objects
  CDVDFactoryCodec::ClearHWAccels();
  VTB::CDecoder::Register();
  VIDEOPLAYER::CRendererFactory::ClearRenderer();
  CLinuxRendererGLES::Register();
  CRendererVTB::Register();
  VIDEOPLAYER::CProcessInfoIOS::Register();
  RETRO::CRPProcessInfoIOS::Register();
  RETRO::CRPProcessInfoIOS::RegisterRendererFactory(new RETRO::CRendererFactoryOpenGLES);

  return true;
}

bool CWinSystemTVOS::DestroyWindow()
{
  return true;
}

bool CWinSystemTVOS::ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop)
{
  if (m_nWidth != newWidth || m_nHeight != newHeight)
  {
    m_nWidth = newWidth;
    m_nHeight = newHeight;
  }

  CRenderSystemGLES::ResetRenderSystem(newWidth, newHeight);

  return true;
}

bool CWinSystemTVOS::SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays)
{
  m_nWidth = res.iWidth;
  m_nHeight = res.iHeight;
  m_bFullScreen = fullScreen;

  CLog::Log(LOGDEBUG, "About to switch to %i x %i @ %.3f", m_nWidth, m_nHeight, res.fRefreshRate);
  SwitchToVideoMode(res.iWidth, res.iHeight, res.fRefreshRate);
  CRenderSystemGLES::ResetRenderSystem(res.iWidth, res.iHeight);

  return true;
}

bool CWinSystemTVOS::SwitchToVideoMode(int width, int height, double refreshrate)
{
  [g_xbmcController displayRateSwitch:refreshrate];
  return true;
}

bool CWinSystemTVOS::GetScreenResolution(int* w, int* h, double* fps, int screenIdx)
{
  *w = [g_xbmcController getScreenSize].width;
  *h = [g_xbmcController getScreenSize].height;
  *fps = [g_xbmcController getDisplayRate];

  CLog::Log(LOGDEBUG, "Current resolution Screen: %i with %i x %i @  %.3f", screenIdx, *w, *h, *fps);
  return true;
}

void CWinSystemTVOS::UpdateResolutions()
{
  // Add display resolution
  int w, h;
  double fps;
  CWinSystemBase::UpdateResolutions();

  int screenIdx = GetDisplayIndexFromSettings();

  //first screen goes into the current desktop mode
  if (GetScreenResolution(&w, &h, &fps, screenIdx))
    UpdateDesktopResolution(CDisplaySettings::GetInstance().GetResolutionInfo(RES_DESKTOP),
                            CONST_HDMI, w, h, fps, 0);

  CDisplaySettings::GetInstance().ClearCustomResolutions();

  //now just fill in the possible resolutions for the attached screens
  //and push to the resolution info vector
  FillInVideoModes(screenIdx);
}

void CWinSystemTVOS::FillInVideoModes(int screenIdx)
{
  // Potential refresh rates
  std::vector<float> supportedDispRefreshRates = {23.976, 24.000, 25.000, 29.970, 30.000, 50.000, 59.940, 60.000};

  UIScreen* aScreen = UIScreen.screens[screenIdx];
  UIScreenMode* mode = aScreen.currentMode;
  int w = mode.size.width;
  int h = mode.size.height;

  for (float refreshrate : supportedDispRefreshRates)
  {
    RESOLUTION_INFO res;
    UpdateDesktopResolution(res, CONST_HDMI, w, h,
                          refreshrate, 0);
    CLog::Log(LOGNOTICE, "Found possible resolution for display %d with %d x %d RefreshRate:%.3f \n", screenIdx, w, h, refreshrate);

    CServiceBroker::GetWinSystem()->GetGfxContext().ResetOverscan(res);
    CDisplaySettings::GetInstance().AddResolutionInfo(res);
  }
}

bool CWinSystemTVOS::IsExtSupported(const char* extension) const
{
  if (strncmp(extension, "EGL_", 4) != 0)
    return CRenderSystemGLES::IsExtSupported(extension);

  std::string name = ' ' + std::string(extension) + ' ';

  return m_eglext.find(name) != std::string::npos;
}


bool CWinSystemTVOS::BeginRender()
{
  bool rtn;

  [g_xbmcController setFramebuffer];

  rtn = CRenderSystemGLES::BeginRender();
  return rtn;
}

bool CWinSystemTVOS::EndRender()
{
  bool rtn;

  rtn = CRenderSystemGLES::EndRender();
  return rtn;
}

void CWinSystemTVOS::Register(IDispResource* resource)
{
  CSingleLock lock(m_resourceSection);
  m_resources.push_back(resource);
}

void CWinSystemTVOS::Unregister(IDispResource* resource)
{
  CSingleLock lock(m_resourceSection);
  std::vector<IDispResource*>::iterator i = find(m_resources.begin(), m_resources.end(), resource);
  if (i != m_resources.end())
    m_resources.erase(i);
}

void CWinSystemTVOS::OnAppFocusChange(bool focus)
{
  CSingleLock lock(m_resourceSection);
  m_bIsBackgrounded = !focus;
  CLog::Log(LOGDEBUG, "CWinSystemTVOS::OnAppFocusChange: %d", focus ? 1 : 0);
  for (std::vector<IDispResource*>::iterator i = m_resources.begin(); i != m_resources.end(); i++)
    (*i)->OnAppFocusChange(focus);
}

//--------------------------------------------------------------
//-------------------DisplayLink stuff
@implementation IOSDisplayLinkCallback
@synthesize videoSyncImpl;
//--------------------------------------------------------------
- (void)runDisplayLink
{
  @autoreleasepool
  {
    if (videoSyncImpl != nullptr)
      videoSyncImpl->TVosVblankHandler();
  }
}
@end

bool CWinSystemTVOS::InitDisplayLink(CVideoSyncTVos* syncImpl)
{
  unsigned int currentScreenIdx = GetDisplayIndexFromSettings();
  UIScreen* currentScreen = UIScreen.screens[currentScreenIdx];
  m_pDisplayLink->callbackClass.videoSyncImpl = syncImpl;
  m_pDisplayLink->impl = [currentScreen displayLinkWithTarget:m_pDisplayLink->callbackClass
                                                     selector:@selector(runDisplayLink)];

  [m_pDisplayLink->impl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  return m_pDisplayLink->impl != nil;
}

void CWinSystemTVOS::DeinitDisplayLink(void)
{
  if (m_pDisplayLink->impl)
  {
    [m_pDisplayLink->impl invalidate];
    m_pDisplayLink->impl = nil;
    [m_pDisplayLink->callbackClass SetVideoSyncImpl:nil];
  }
}
//------------DisplayLink stuff end
//--------------------------------------------------------------

void CWinSystemTVOS::PresentRenderImpl(bool rendered)
{
  //glFlush;
  if (rendered)
    [g_xbmcController presentFramebuffer];
}

bool CWinSystemTVOS::HasCursor()
{
  return false;
}

void CWinSystemTVOS::NotifyAppActiveChange(bool bActivated)
{
  if (bActivated && m_bWasFullScreenBeforeMinimize &&
      !CServiceBroker::GetWinSystem()->GetGfxContext().IsFullScreenRoot())
    CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);
}

bool CWinSystemTVOS::Minimize()
{
  m_bWasFullScreenBeforeMinimize =
      CServiceBroker::GetWinSystem()->GetGfxContext().IsFullScreenRoot();
  if (m_bWasFullScreenBeforeMinimize)
    CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);

  return true;
}

bool CWinSystemTVOS::Restore()
{
  return false;
}

bool CWinSystemTVOS::Hide()
{
  return true;
}

bool CWinSystemTVOS::Show(bool raise)
{
  return true;
}

CVEAGLContext CWinSystemTVOS::GetEAGLContextObj()
{
  return [g_xbmcController getEAGLContextObj];
}

void CWinSystemTVOS::GetConnectedOutputs(std::vector<std::string>* outputs)
{
  outputs->push_back("Default");
  outputs->push_back(CONST_HDMI);
}

bool CWinSystemTVOS::MessagePump()
{
  return m_winEvents->MessagePump();
}

bool CWinSystemTVOS::SetHDR(const VideoPicture* videoPicture)
{
  if (!videoPicture)
  {
    [g_xbmcController displayHDRSwitch:0 /* SDR */];
    return false;
  }

  if (!IsHDRDisplay())
    return false;

  //! @todo Detect DolbyVision from media?
  [g_xbmcController displayHDRSwitch:2 /* HDR */];
  return true;

}

bool CWinSystemTVOS::IsHDRDisplay()
{
  if (@available(tvOS 11.2, *))
  {
    AVPlayerHDRMode HDRMode = AVPlayer.availableHDRModes;
    CLog::Log(LOGDEBUG, "CWinSystemTVOS::IsHDRDisplay: %d", HDRMode);

    // SDR == 0, 1
    // HDR == 2, 3
    // DoblyVision == 4    
    if (static_cast<int>(HDRMode) > 1)
    {
      if (static_cast<int>(HDRMode) == 4)
        CLog::Log(LOGDEBUG, "CWinSystemTVOS::IsHDRDisplay: DolbyVision display detected");
      else
        CLog::Log(LOGDEBUG, "CWinSystemTVOS::IsHDRDisplay: HDR display detected");

      return true;
    }
  }
  return false;
}
