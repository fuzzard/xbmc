/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "platform/darwin/tvos/XBMCController.h"

#include "AppParamParser.h"
#include "Application.h"
#include "ServiceBroker.h"
#include "guilib/GUIComponent.h"
#include "guilib/GUIWindowManager.h"
#include "interfaces/AnnouncementManager.h"
#include "messaging/ApplicationMessenger.h"
#include "network/NetworkServices.h"
#include "platform/xbmc.h"
#include "settings/AdvancedSettings.h"
#include "settings/SettingsComponent.h"
#include "utils/log.h"

#import "platform/darwin/ios-common/AnnounceReceiver.h"
#import "platform/darwin/ios-common/DarwinEmbedNowPlayingInfoManager.h"
#import "platform/darwin/tvos/TVOSDisplayManager.h"
#import "platform/darwin/tvos/TVOSEAGLView.h"
#import "platform/darwin/tvos/TVOSTopShelf.h"
#import "platform/darwin/tvos/XBMCApplication.h"
#import "platform/darwin/tvos/input/LibInputHandler.h"
#import "platform/darwin/tvos/input/LibInputMPRemoteCommand.h"
#import "platform/darwin/tvos/input/LibInputRemote.h"
#import "platform/darwin/tvos/input/LibInputTouch.h"
#import "windowing/tvos/WinEventsTVOS.h"
#import "windowing/tvos/WinSystemTVOS.h"

#import "system.h"

#import <AVKit/AVDisplayManager.h>
#import <AVKit/UIWindow.h>

using namespace KODI::MESSAGING;

XBMCController* g_xbmcController;

#pragma mark - XBMCController implementation
@implementation XBMCController

@synthesize appAlive = m_appAlive;
@synthesize MPNPInfoManager;
@synthesize displayManager;
@synthesize inputHandler;
@synthesize glView;

#pragma mark - UIView Keyboard

- (void)activateKeyboard:(UIView*)view
{
  [self.view addSubview:view];
  glView.userInteractionEnabled = NO;
}

- (void)deactivateKeyboard:(UIView*)view
{
  [view removeFromSuperview];
  glView.userInteractionEnabled = YES;
  [self becomeFirstResponder];
}

- (void)nativeKeyboardActive:(bool)active;
{
  m_nativeKeyboardActive = active;
}

#pragma mark - View

- (void)insertVideoView:(UIView*)view
{
  [self.view insertSubview:view belowSubview:glView];
  [self.view setNeedsDisplay];
}

- (void)removeVideoView:(UIView*)view
{
  [view removeFromSuperview];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  glView = [[TVOSEAGLView alloc] initWithFrame:self.view.bounds withScreen:[UIScreen mainScreen]];

  // Check if screen is Retina
  displayManager.screenScale = [glView getScreenScale:[UIScreen mainScreen]];
  [self.view addSubview:glView];

  [inputHandler.inputTouch createSwipeGestureRecognizers];
  [inputHandler.inputTouch createPanGestureRecognizers];
  [inputHandler.inputTouch createPressGesturecognizers];
  [inputHandler.inputTouch createTapGesturecognizers];

  [inputHandler.inputMPCommand createCustomControlCenter];

  [displayManager addModeSwitchObserver];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self resumeAnimation];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self becomeFirstResponder];
//  [[UIApplication sharedApplication]
//      beginReceivingRemoteControlEvents]; // @todo MPRemoteCommandCenter
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self pauseAnimation];
  [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  [self resignFirstResponder];
  [super viewDidUnload];
}

- (UIView*)inputView
{
  // override our input view to an empty view
  // this prevents the on screen keyboard
  // which would be shown whenever this UIResponder
  // becomes the first responder (which is always the case!)
  // caused by implementing the UIKeyInput protocol
  return [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - FirstResponder

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

#pragma mark - FrameBuffer

- (void)setFramebuffer
{
  if (!m_pause)
    [glView setFramebuffer];
}

- (bool)presentFramebuffer
{
  if (!m_pause)
    return [glView presentFramebuffer];
  else
    return FALSE;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc. that aren't in use.
}

#pragma mark - BackgroundTask

- (void)enableBackGroundTask
{
  if (m_bgTask != UIBackgroundTaskInvalid)
  {
    [[UIApplication sharedApplication] endBackgroundTask:m_bgTask];
    m_bgTask = UIBackgroundTaskInvalid;
  }
  CLog::Log(LOGDEBUG, "%s: beginBackgroundTask", __PRETTY_FUNCTION__);
  // we have to alloc the background task for keep network working after screen lock and dark.
  m_bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
}

- (void)disableBackGroundTask
{
  if (m_bgTask != UIBackgroundTaskInvalid)
  {
    CLog::Log(LOGDEBUG, "%s: endBackgroundTask", __PRETTY_FUNCTION__);
    [[UIApplication sharedApplication] endBackgroundTask:m_bgTask];
    m_bgTask = UIBackgroundTaskInvalid;
  }
}

- (void)disableSystemSleep
{
}

- (void)enableSystemSleep
{
}

#pragma mark - ScreenSaver Idletimer

- (void)disableScreenSaver
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  });
}

- (void)enableScreenSaver
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
  });
}

- (bool)resetSystemIdleTimer
{
  // this is silly :)
  // when system screen saver kicks off, we switch to UIApplicationStateInactive, the only way
  // to get out of the screensaver is to call ourself to open an custom URL that is registered
  // in our Info.plist. The openURL method of UIApplication must be supported but we can just
  // reply NO and we get restored to UIApplicationStateActive.
  __block bool inActive = false;
  dispatch_async(dispatch_get_main_queue(), ^{
    inActive = [UIApplication sharedApplication].applicationState == UIApplicationStateInactive;
    if (inActive)
    {
      //@ ! Todo: change to appname rather than hardcode kodi
      NSURL* url = [NSURL URLWithString:@"kodi://wakeup"];
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
  });
  return inActive;
}

#pragma mark - AppFocus

- (void)enterBackground
{
  // We have 5 seconds before the OS will force kill us for delaying too long.
  XbmcThreads::EndTime timer(4500);

  // this should not be required as we 'should' get becomeInactive before enterBackground
  if (g_application.GetAppPlayer().IsPlaying() && !g_application.GetAppPlayer().IsPaused())
  {
    m_isPlayingBeforeInactive = YES;
    CApplicationMessenger::GetInstance().SendMsg(TMSG_MEDIA_PAUSE_IF_PLAYING);
  }

  CWinSystemTVOS* winSystem = dynamic_cast<CWinSystemTVOS*>(CServiceBroker::GetWinSystem());
  winSystem->OnAppFocusChange(false);

  // Apple says to disable ZeroConfig when moving to background
  //! @todo
  //CNetworkServices::GetInstance().StopZeroconf();

  if (m_isPlayingBeforeInactive)
  {
    // if we were playing and have paused, then
    // enable a background task to keep the network alive
    [self enableBackGroundTask];
  }
  else
  {
    // if we are not playing/pause when going to background
    // close out network shares as we can get fully suspended.
    g_application.CloseNetworkShares();
  }

  // OnAppFocusChange triggers an AE suspend.
  // Wait for AE to suspend and delete the audio sink, this allows
  // AudioOutputUnitStop to complete and AVAudioSession to be set inactive.
  // Note that to user, we moved into background to user but we
  // are really waiting here for AE to suspend.
  //! @todo
  /*
  while (!CAEFactory::IsSuspended() && !timer.IsTimePast())
    usleep(250*1000);
     */
}

- (void)enterForegroundDelayed:(id)arg
{
  // MCRuntimeLib_Initialized is only true if
  // we were running and got moved to background
  while (!g_application.IsInitialized())
    usleep(50 * 1000);

  CWinSystemTVOS* winSystem = dynamic_cast<CWinSystemTVOS*>(CServiceBroker::GetWinSystem());
  winSystem->OnAppFocusChange(true);

  // when we come back, restore playing if we were.
  if (m_isPlayingBeforeInactive)
  {
    CApplicationMessenger::GetInstance().SendMsg(TMSG_MEDIA_UNPAUSE);
    m_isPlayingBeforeInactive = NO;
  }
  // restart ZeroConfig (if stopped)
  //! @todo
  //CNetworkServices::GetInstance().StartZeroconf();

  // do not update if we are already updating
  if (!(g_application.IsVideoScanning() || g_application.IsMusicScanning()))
    g_application.UpdateLibraries();

  // this will fire only if we are already alive and have 'menu'ed out and back
  CServiceBroker::GetAnnouncementManager()->Announce(ANNOUNCEMENT::System, "xbmc", "OnWake");

  // this handles what to do if we got pushed
  // into foreground by a topshelf item select/play
  CTVOSTopShelf::GetInstance().RunTopShelf();
}

- (void)enterForeground
{
  // stop background task (if running)
  [self disableBackGroundTask];

  [NSThread detachNewThreadSelector:@selector(enterForegroundDelayed:)
                           toTarget:self
                         withObject:nil];
}

- (void)becomeInactive
{
  // if we were interrupted, already paused here
  // else if user background us or lock screen, only pause video here, audio keep playing.
  if (g_application.GetAppPlayer().IsPlayingVideo() && !g_application.GetAppPlayer().IsPaused())
  {
    m_isPlayingBeforeInactive = YES;
    CApplicationMessenger::GetInstance().SendMsg(TMSG_MEDIA_PAUSE_IF_PLAYING);
  }
}

#pragma mark - runtime routines

- (void)pauseAnimation
{
  m_pause = YES;
  g_application.SetRenderGUI(false);
}

- (void)resumeAnimation
{
  m_pause = NO;
  g_application.SetRenderGUI(true);
}

- (void)startAnimation
{
  if (!m_animating && [glView getCurrentEAGLContext])
  {
    // kick off an animation thread
    m_animationThreadLock = [[NSConditionLock alloc] initWithCondition:FALSE];
    m_animationThread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(runAnimation:)
                                                  object:m_animationThreadLock];
    [m_animationThread start];
    m_animating = YES;
  }
}

- (void)stopAnimation
{
  if (!m_animating && [glView getCurrentEAGLContext])
  {
    m_appAlive = NO;
    m_animating = NO;
    if (!g_application.m_bStop)
    {
      CApplicationMessenger::GetInstance().PostMsg(TMSG_QUIT);
    }

    CAnnounceReceiver::GetInstance()->DeInitialize();

    // wait for animation thread to die
    if (!m_animationThread.finished)
      [m_animationThreadLock lockWhenCondition:TRUE];
  }
}

- (void)runAnimation:(id)arg
{
  @autoreleasepool
  {
    [NSThread currentThread].name = @"XBMC_Run";

    // signal the thread is alive
    NSConditionLock* myLock = arg;
    [myLock lock];

    // Prevent child processes from becoming zombies on exit
    // if not waited upon. See also Util::Command
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_flags = SA_NOCLDWAIT;
    sa.sa_handler = SIG_IGN;
    sigaction(SIGCHLD, &sa, NULL);

    setlocale(LC_NUMERIC, "C");

    int status = 0;
    try
    {
      // set up some Kodi specific relationships
      //    XBMC::Context run_context; //! @todo
      m_appAlive = YES;
      // start up with gui enabled
      status = KODI_Run(true);
      // we exited or died.
      g_application.SetRenderGUI(false);
    }
    catch (...)
    {
      m_appAlive = FALSE;
      CLog::Log(LOGERROR, "%sException caught on main loop status=%d. Exiting", __PRETTY_FUNCTION__, status);
    }

    // signal the thread is dead
    [myLock unlockWithCondition:TRUE];

    [self enableScreenSaver];
    [self enableSystemSleep];
    [self performSelectorOnMainThread:@selector(CallExit) withObject:nil waitUntilDone:NO];
  }
}

#pragma mark - KODI_Run

int KODI_Run(bool renderGUI)
{
  int status = -1;

  CAppParamParser appParamParser; //! @todo : proper params
  if (!g_application.Create(appParamParser))
  {
    CLog::Log(LOGERROR, "ERROR: Unable to create application. Exiting");
    return status;
  }

  //this can't be set from CAdvancedSettings::Initialize()
  //because it will overwrite the loglevel set with the --debug flag
#ifdef _DEBUG
  CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_logLevel = LOG_LEVEL_DEBUG;
  CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_logLevelHint = LOG_LEVEL_DEBUG;
#else
  CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_logLevel = LOG_LEVEL_NORMAL;
  CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_logLevelHint = LOG_LEVEL_NORMAL;
#endif
  CLog::SetLogLevel(CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_logLevel);

  // not a failure if returns false, just means someone
  // did the init before us.
  if (!CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->Initialized())
  {
    //CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->Initialize();
    //! @todo
  }

  CAnnounceReceiver::GetInstance()->Initialize();

  if (renderGUI && !g_application.CreateGUI())
  {
    CLog::Log(LOGERROR, "ERROR: Unable to create GUI. Exiting");
    return status;
  }
  if (!g_application.Initialize())
  {
    CLog::Log(LOGERROR, "ERROR: Unable to Initialize. Exiting");
    return status;
  }

  try
  {
    status = g_application.Run(appParamParser);
  }
  catch (...)
  {
    CLog::Log(LOGERROR, "ERROR: Exception caught on main loop. Exiting");
    status = -1;
  }

  return status;
}

- (void)CallExit
{
  exit(0);
}

- (AVDisplayManager*)avDisplayManager __attribute__((availability(tvos, introduced = 11.2)))
{
  return self.view.window.avDisplayManager;
}

#pragma mark - EAGLContext

- (EAGLContext*)getEAGLContextObj
{
  return [glView getCurrentEAGLContext];
}

#pragma mark - remoteControlReceivedWithEvent forwarder
//  remoteControlReceived requires subclassing of UIViewController
//  Just implement as a forwarding class to CLibRemote so it doesnt need to subclass
- (void)remoteControlReceivedWithEvent:(UIEvent*)receivedEvent
{
  if (receivedEvent.type == UIEventTypeRemoteControl)
  {
    [inputHandler.inputRemote remoteControlEvent:receivedEvent];
  }
}

#pragma mark - init/deinit

- (void)dealloc
{
  [displayManager removeModeSwitchObserver];
  // stop background task (if running)
  [self disableBackGroundTask];

  [self stopAnimation];
}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  m_pause = NO;
  m_appAlive = NO;
  m_animating = NO;

  m_isPlayingBeforeInactive = NO;
  m_bgTask = UIBackgroundTaskInvalid;

  [self enableScreenSaver];

  g_xbmcController = self;
  MPNPInfoManager = [DarwinEmbedNowPlayingInfoManager new];
  displayManager = [TVOSDisplayManager new];
  inputHandler = [TVOSLibInputHandler new];

  return self;
}

@end
#undef BOOL
