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
#include "cores/AudioEngine/Interfaces/AE.h"
#include "guilib/GUIComponent.h"
#include "guilib/GUIWindowManager.h"
#include "input/ButtonTranslator.h"
#include "input/CustomControllerTranslator.h"
#include "input/InputManager.h"
#include "input/Key.h"
#include "interfaces/AnnouncementManager.h"
#include "messaging/ApplicationMessenger.h"
#include "network/NetworkServices.h"
#include "platform/xbmc.h"
#include "settings/AdvancedSettings.h"
#include "utils/log.h"

#import "platform/darwin/ios-common/AnnounceReceiver.h"
#import "platform/darwin/ios-common/IOSKeyboardView.h"
#import "platform/darwin/ios-common/DarwinEmbedNowPlayingInfoManager.h"
#import "platform/darwin/tvos/TVOSDisplayManager.h"
#import "platform/darwin/tvos/TVOSEAGLView.h"
#import "platform/darwin/tvos/TVOSTopShelf.h"
#import "platform/darwin/tvos/XBMCApplication.h"
#import "windowing/tvos/WinEventsTVOS.h"
#import "windowing/tvos/WinSystemTVOS.h"

#import "system.h"

#import <AVKit/AVDisplayManager.h>
#import <AVKit/UIWindow.h>

using namespace KODI::MESSAGING;

XBMCController* g_xbmcController;

//--------------------------------------------------------------
#pragma mark - XBMCController implementation
@implementation XBMCController

@synthesize MPNPInfoManager;
@synthesize displayManager;
@synthesize glView;

#pragma mark - internal key press methods
- (void)sendButtonPressed:(int)buttonId
{
  int actionID;
  std::string actionName;

  // Translate using custom controller translator.
  if (CServiceBroker::GetInputManager().TranslateCustomControllerString(
          CServiceBroker::GetGUI()->GetWindowManager().GetActiveWindowOrDialog(), "SiriRemote",
          buttonId, actionID, actionName))
  {
    // break screensaver
    g_application.ResetSystemIdleTimer();
    g_application.ResetScreenSaver();

    // in case we wokeup the screensaver or screen - eat that action...
    if (g_application.WakeUpScreenSaverAndDPMS())
      return;
    CServiceBroker::GetInputManager().QueueAction(CAction(actionID, 1.0f, 0.0f, actionName));
  }
  else
  {
    CLog::Log(LOGDEBUG, "ERROR mapping customcontroller action. CustomController: %s %i",
              "SiriRemote", buttonId);
  }
}

#pragma mark - remote idle timer
//--------------------------------------------------------------

- (void)startRemoteTimer
{
  m_remoteIdleState = false;

  if (self.remoteIdleTimer != nil)
    [self stopRemoteTimer];
  if (m_shouldRemoteIdle)
  {
    NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:m_remoteIdleTimeout];
    NSTimer* timer = [[NSTimer alloc] initWithFireDate:fireDate
                                              interval:0.0
                                                target:self
                                              selector:@selector(setRemoteIdleState)
                                              userInfo:nil
                                               repeats:NO];

    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.remoteIdleTimer = timer;
  }
}

- (void)stopRemoteTimer
{
  if (self.remoteIdleTimer != nil)
  {
    [self.remoteIdleTimer invalidate];
    self.remoteIdleTimer = nil;
  }
  m_remoteIdleState = false;
}

- (void)setRemoteIdleState
{
  m_remoteIdleState = true;
}

#pragma mark - key press auto-repeat methods
//--------------------------------------------------------------
//--------------------------------------------------------------
// start repeating after 0.25s
#define REPEATED_KEYPRESS_DELAY_S 0.50
// pause 0.05s (50ms) between keypresses
#define REPEATED_KEYPRESS_PAUSE_S 0.05
//--------------------------------------------------------------

//- (void)startKeyPressTimer:(XBMCKey)keyId
- (void)startKeyPressTimer:(int)keyId
{
  [self startKeyPressTimer:keyId clickTime:REPEATED_KEYPRESS_PAUSE_S];
}

- (void)startKeyPressTimer:(int)keyId clickTime:(NSTimeInterval)interval
{
  if (self.pressAutoRepeatTimer != nil)
    [self stopKeyPressTimer];

  [self sendButtonPressed:keyId];

  NSNumber* number = @(keyId);
  NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:REPEATED_KEYPRESS_DELAY_S];

  // schedule repeated timer which starts after REPEATED_KEYPRESS_DELAY_S
  // and fires every REPEATED_KEYPRESS_PAUSE_S
  NSTimer* timer = [[NSTimer alloc] initWithFireDate:fireDate
                                            interval:interval
                                              target:self
                                            selector:@selector(keyPressTimerCallback:)
                                            userInfo:number
                                             repeats:YES];

  // schedule the timer to the runloop
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  self.pressAutoRepeatTimer = timer;
}
- (void)stopKeyPressTimer
{
  if (self.pressAutoRepeatTimer != nil)
  {
    [self.pressAutoRepeatTimer invalidate];
    self.pressAutoRepeatTimer = nil;
  }
}
- (void)keyPressTimerCallback:(NSTimer*)theTimer
{
  // if queue is empty - skip this timer event before letting it process
  CWinSystemTVOS* winSystem(dynamic_cast<CWinSystemTVOS*>(CServiceBroker::GetWinSystem()));
  if (!winSystem->GetQueueSize())
    [self sendButtonPressed:[theTimer.userInfo intValue]];
}

#pragma mark - remote helpers

//--------------------------------------------------------------
- (XBMCKey)getPanDirectionKey:(CGPoint)translation
{
  XBMCKey key = XBMCK_UNKNOWN;
  switch ([self getPanDirection:translation])
  {
  case UIPanGestureRecognizerDirectionDown:
    key = XBMCK_DOWN;
    break;
  case UIPanGestureRecognizerDirectionUp:
    key = XBMCK_UP;
    break;
  case UIPanGestureRecognizerDirectionLeft:
    key = XBMCK_LEFT;
    break;
  case UIPanGestureRecognizerDirectionRight:
    key = XBMCK_RIGHT;
    break;
  case UIPanGestureRecognizerDirectionUndefined:
    break;
  }

  return key;
}

//--------------------------------------------------------------
- (UIPanGestureRecognizerDirection)getPanDirection:(CGPoint)translation
{
  int x = (int)translation.x;
  int y = (int)translation.y;
  int absX = x;
  int absY = y;

  if (absX < 0)
    absX *= -1;

  if (absY < 0)
    absY *= -1;

  bool horizontal, veritical;
  horizontal = (absX > absY);
  veritical = !horizontal;

  // Determine up, down, right, or left:
  bool swipe_up, swipe_down, swipe_left, swipe_right;
  swipe_left = (horizontal && x < 0);
  swipe_right = (horizontal && x >= 0);
  swipe_up = (veritical && y < 0);
  swipe_down = (veritical && y >= 0);

  if (swipe_down)
    return UIPanGestureRecognizerDirectionDown;
  if (swipe_up)
    return UIPanGestureRecognizerDirectionUp;
  if (swipe_left)
    return UIPanGestureRecognizerDirectionLeft;
  if (swipe_right)
    return UIPanGestureRecognizerDirectionRight;

  return UIPanGestureRecognizerDirectionUndefined;
}

//--------------------------------------------------------------
- (BOOL)shouldFastScroll
{
  // we dont want fast scroll in below windows, no point in going 15 places in home screen
  int window = CServiceBroker::GetGUI()->GetWindowManager().GetActiveWindow();

  if (window == WINDOW_HOME || window == WINDOW_FULLSCREEN_LIVETV ||
      window == WINDOW_FULLSCREEN_VIDEO || window == WINDOW_FULLSCREEN_RADIO ||
      (window >= WINDOW_SETTINGS_START && window <= WINDOW_SETTINGS_SERVICE))
    return NO;

  return YES;
}

//--------------------------------------------------------------
- (void)setSiriRemote:(BOOL)enable
{
  m_mimicAppleSiri = enable;
}

//--------------------------------------------------------------
- (void)setRemoteIdleTimeout:(int)timeout
{
  m_remoteIdleTimeout = (float)timeout;
  [self startRemoteTimer];
}

- (void)setShouldRemoteIdle:(BOOL)idle
{
  m_shouldRemoteIdle = idle;
  [self startRemoteTimer];
}

//--------------------------------------------------------------
#pragma mark - gesture methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
  if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] &&
      [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
  {
    return YES;
  }
  if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
      [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
  {
    return YES;
  }
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
      [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
  {
    return YES;
  }
  return NO;
}

//--------------------------------------------------------------
// called before pressesBegan:withEvent: is called on the gesture recognizer
// for a new press. return NO to prevent the gesture recognizer from seeing this press
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceivePress:(UIPress*)press
{
  BOOL handled = YES;
  switch (press.type)
  {
  // single press key, but also detect hold and back to tvos.
  case UIPressTypeMenu:
    // menu is special.
    //  a) if at our home view, should return to atv home screen.
    //  b) if not, let it pass to us.
    if (CServiceBroker::GetGUI()->GetWindowManager().GetActiveWindow() == WINDOW_HOME &&
        !CServiceBroker::GetGUI()->GetWindowManager().HasVisibleModalDialog() &&
        !g_application.GetAppPlayer().IsPlaying())
      handled = NO;
    break;

  // single press keys
  case UIPressTypeSelect:
  case UIPressTypePlayPause:
    break;

  // auto-repeat keys
  case UIPressTypeUpArrow:
  case UIPressTypeDownArrow:
  case UIPressTypeLeftArrow:
  case UIPressTypeRightArrow:
    break;

  default:
    handled = NO;
  }

  return handled;
}

//--------------------------------------------------------------
- (void)createSwipeGestureRecognizers
{
  for (auto swipeDirection :
       {UISwipeGestureRecognizerDirectionLeft, UISwipeGestureRecognizerDirectionRight,
        UISwipeGestureRecognizerDirectionUp, UISwipeGestureRecognizerDirectionDown})
  {
    auto swipeRecognizer =
        [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeRecognizer.delaysTouchesBegan = NO;
    swipeRecognizer.direction = swipeDirection;
    swipeRecognizer.delegate = self;
    [glView addGestureRecognizer:swipeRecognizer];
  }
}

//--------------------------------------------------------------
- (void)createPanGestureRecognizers
{
  // for pan gestures with one finger
  auto pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  pan.delegate = self;
  [glView addGestureRecognizer:pan];
  m_clickResetPan = false;
}
//--------------------------------------------------------------
- (void)createTapGesturecognizers
{
  // tap side of siri remote pad
  for (auto t : {
         std::make_tuple(UIPressTypeUpArrow, @selector(tapUpArrowPressed:),
                         @selector(IRRemoteUpArrowPressed:)),
             std::make_tuple(UIPressTypeDownArrow, @selector(tapDownArrowPressed:),
                             @selector(IRRemoteDownArrowPressed:)),
             std::make_tuple(UIPressTypeLeftArrow, @selector(tapLeftArrowPressed:),
                             @selector(IRRemoteLeftArrowPressed:)),
             std::make_tuple(UIPressTypeRightArrow, @selector(tapRightArrowPressed:),
                             @selector(IRRemoteRightArrowPressed:))
       })
  {
    auto allowedPressTypes = @[ @(std::get<0>(t)) ];

    auto arrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:std::get<1>(t)];
    arrowRecognizer.allowedPressTypes = allowedPressTypes;
    arrowRecognizer.delegate = self;
    [glView addGestureRecognizer:arrowRecognizer];

    // @todo doesn't seem to work
    // we need UILongPressGestureRecognizer here because it will give
    // UIGestureRecognizerStateBegan AND UIGestureRecognizerStateEnded
    // even if we hold down for a long time. UITapGestureRecognizer
    // will eat the ending on long holds and we never see it.
    auto longArrowRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                             action:std::get<2>(t)];
    longArrowRecognizer.allowedPressTypes = allowedPressTypes;
    longArrowRecognizer.minimumPressDuration = 0.01;
    longArrowRecognizer.delegate = self;
    [glView addGestureRecognizer:longArrowRecognizer];
  }
}
//--------------------------------------------------------------
- (void)createPressGesturecognizers
{
  auto menuRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(menuPressed:)];
  menuRecognizer.allowedPressTypes = @[ @(UIPressTypeMenu) ];
  menuRecognizer.delegate = self;
  [glView addGestureRecognizer:menuRecognizer];

  auto playPauseTypes = @[ @(UIPressTypePlayPause) ];
  auto playPauseRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed:)];
  playPauseRecognizer.allowedPressTypes = playPauseTypes;
  playPauseRecognizer.delegate = self;
  [glView addGestureRecognizer:playPauseRecognizer];

  auto doublePlayPauseRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(doublePlayPausePressed:)];
  doublePlayPauseRecognizer.allowedPressTypes = playPauseTypes;
  doublePlayPauseRecognizer.numberOfTapsRequired = 2;
  doublePlayPauseRecognizer.delegate = self;
  [glView.gestureRecognizers.lastObject requireGestureRecognizerToFail:doublePlayPauseRecognizer];
  [glView addGestureRecognizer:doublePlayPauseRecognizer];

  auto longPlayPauseRecognizer =
      [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(longPlayPausePressed:)];
  longPlayPauseRecognizer.allowedPressTypes = playPauseTypes;
  longPlayPauseRecognizer.delegate = self;
  [glView addGestureRecognizer:longPlayPauseRecognizer];

  auto selectTypes = @[ @(UIPressTypeSelect) ];
  auto longSelectRecognizer =
      [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(SiriLongSelectHandler:)];
  longSelectRecognizer.allowedPressTypes = selectTypes;
  longSelectRecognizer.minimumPressDuration = 0.001;
  longSelectRecognizer.delegate = self;
  [glView addGestureRecognizer:longSelectRecognizer];

  auto selectRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(SiriSelectHandler:)];
  selectRecognizer.allowedPressTypes = selectTypes;
  selectRecognizer.delegate = self;
  [longSelectRecognizer requireGestureRecognizerToFail:selectRecognizer];
  [glView addGestureRecognizer:selectRecognizer];

  auto doubleSelectRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(SiriDoubleSelectHandler:)];
  doubleSelectRecognizer.allowedPressTypes = selectTypes;
  doubleSelectRecognizer.numberOfTapsRequired = 2;
  doubleSelectRecognizer.delegate = self;
  [longSelectRecognizer requireGestureRecognizerToFail:doubleSelectRecognizer];
  [glView.gestureRecognizers.lastObject requireGestureRecognizerToFail:doubleSelectRecognizer];
  [glView addGestureRecognizer:doubleSelectRecognizer];
}

//--------------------------------------------------------------
- (void)activateKeyboard:(UIView*)view
{
  [self.view addSubview:view];
  glView.userInteractionEnabled = NO;
}
//--------------------------------------------------------------
- (void)deactivateKeyboard:(UIView*)view
{
  [view removeFromSuperview];
  glView.userInteractionEnabled = YES;
  [self becomeFirstResponder];
}
//--------------------------------------------------------------
- (void)nativeKeyboardActive:(bool)active;
{
  m_nativeKeyboardActive = active;
}
//--------------------------------------------------------------
- (void)menuPressed:(UITapGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self sendButtonPressed:6];

    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}
//--------------------------------------------------------------
- (void)SiriLongSelectHandler:(UIGestureRecognizer*)sender
{
  // if we have clicked select while scrolling up/down we need to reset direction of pan
  m_clickResetPan = true;

  if (sender.state == UIGestureRecognizerStateBegan)
  {
    [self sendButtonPressed:7];
    [self startRemoteTimer];
  }
}

- (void)SiriSelectHandler:(UITapGestureRecognizer*)sender
{
  CLog::Log(LOGDEBUG, "SiriSelectHandler");
  switch (sender.state)
  {
  case UIGestureRecognizerStateEnded:
    [self sendButtonPressed:5];
    break;
  default:
    break;
  }
}

- (void)playPausePressed:(UITapGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self sendButtonPressed:12];
    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}

- (void)longPlayPausePressed:(UILongPressGestureRecognizer*)sender
{
  CLog::Log(LOGDEBUG, "Input: play/pause long press, state: %ld", static_cast<long>(sender.state));
}

- (void)doublePlayPausePressed:(UITapGestureRecognizer*)sender
{
  // state is only UIGestureRecognizerStateBegan and UIGestureRecognizerStateEnded
  CLog::Log(LOGDEBUG, "Input: play/pause double press");
}

- (void)SiriDoubleSelectHandler:(UITapGestureRecognizer*)sender
{
  CLog::Log(LOGDEBUG, "Input: select double press");
}

//--------------------------------------------------------------
- (IBAction)IRRemoteUpArrowPressed:(UIGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    [self startKeyPressTimer:1];
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self stopKeyPressTimer];
    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}
//--------------------------------------------------------------
- (IBAction)IRRemoteDownArrowPressed:(UIGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    [self startKeyPressTimer:2];
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self stopKeyPressTimer];
    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}
//--------------------------------------------------------------
- (IBAction)IRRemoteLeftArrowPressed:(UIGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    [self startKeyPressTimer:3];
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self stopKeyPressTimer];
    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}
//--------------------------------------------------------------
- (IBAction)IRRemoteRightArrowPressed:(UIGestureRecognizer*)sender
{
  switch (sender.state)
  {
  case UIGestureRecognizerStateBegan:
    [self startKeyPressTimer:4];
    break;
  case UIGestureRecognizerStateChanged:
    break;
  case UIGestureRecognizerStateEnded:
    [self stopKeyPressTimer];
    // start remote timeout
    [self startRemoteTimer];
    break;
  default:
    break;
  }
}

//--------------------------------------------------------------
- (IBAction)tapUpArrowPressed:(UIGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
    [self sendButtonPressed:1];

  [self startRemoteTimer];
}
//--------------------------------------------------------------
- (IBAction)tapDownArrowPressed:(UIGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
    [self sendButtonPressed:2];

  [self startRemoteTimer];
}
//--------------------------------------------------------------
- (IBAction)tapLeftArrowPressed:(UIGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
    [self sendButtonPressed:3];

  [self startRemoteTimer];
}
//--------------------------------------------------------------
- (IBAction)tapRightArrowPressed:(UIGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
    [self sendButtonPressed:4];

  [self startRemoteTimer];
}

//--------------------------------------------------------------
- (IBAction)handlePan:(UIPanGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
  {
    if (m_appAlive) //NO GESTURES BEFORE WE ARE UP AND RUNNING
    {
      if (m_mimicAppleSiri)
      {
        static UIPanGestureRecognizerDirection direction = UIPanGestureRecognizerDirectionUndefined;
        // speed       == how many clicks full swipe will give us(1000x1000px)
        // minVelocity == min velocity to trigger fast scroll, add this to settings?
        float speed = 240.0;
        float minVelocity = 1300.0;
        switch (sender.state)
        {

        case UIGestureRecognizerStateBegan:
        {

          if (direction == UIPanGestureRecognizerDirectionUndefined)
          {
            m_lastGesturePoint = [sender translationInView:sender.view];
            m_lastGesturePoint.x = m_lastGesturePoint.x / 1.92;
            m_lastGesturePoint.y = m_lastGesturePoint.y / 1.08;

            m_direction = [self getPanDirection:m_lastGesturePoint];
            m_directionOverride = false;
          }

          break;
        }

        case UIGestureRecognizerStateChanged:
        {
          CGPoint gesturePoint = [sender translationInView:sender.view];
          gesturePoint.x = gesturePoint.x / 1.92;
          gesturePoint.y = gesturePoint.y / 1.08;

          CGPoint gestureMovement;
          gestureMovement.x = gesturePoint.x - m_lastGesturePoint.x;
          gestureMovement.y = gesturePoint.y - m_lastGesturePoint.y;
          direction = [self getPanDirection:gestureMovement];

          CGPoint velocity = [sender velocityInView:sender.view];
          CGFloat velocityX = (0.2 * velocity.x);
          CGFloat velocityY = (0.2 * velocity.y);

          if (ABS(velocityY) > minVelocity || ABS(velocityX) > minVelocity || m_directionOverride)
          {
            direction = m_direction;
            // Override direction to correct swipe errors
            m_directionOverride = true;
          }

          switch (direction)
          {
          case UIPanGestureRecognizerDirectionUp:
          {
            if ((ABS(m_lastGesturePoint.y - gesturePoint.y) > speed) ||
                ABS(velocityY) > minVelocity)
            {
              [self sendButtonPressed:8];
              if (ABS(velocityY) > minVelocity && [self shouldFastScroll])
              {
                [self sendButtonPressed:8];
              }
              m_lastGesturePoint = gesturePoint;
            }
            break;
          }
          case UIPanGestureRecognizerDirectionDown:
          {
            if ((ABS(m_lastGesturePoint.y - gesturePoint.y) > speed) ||
                ABS(velocityY) > minVelocity)
            {
              [self sendButtonPressed:9];
              if (ABS(velocityY) > minVelocity && [self shouldFastScroll])
              {
                [self sendButtonPressed:9];
              }
              m_lastGesturePoint = gesturePoint;
            }
            break;
          }
          case UIPanGestureRecognizerDirectionLeft:
          {
            // add 80 px to slow left/right swipes, it matched up down better
            if ((ABS(m_lastGesturePoint.x - gesturePoint.x) > speed + 80) ||
                ABS(velocityX) > minVelocity)
            {
              [self sendButtonPressed:10];
              if (ABS(velocityX) > minVelocity && [self shouldFastScroll])
              {
                [self sendButtonPressed:10];
              }
              m_lastGesturePoint = gesturePoint;
            }
            break;
          }
          case UIPanGestureRecognizerDirectionRight:
          {
            // add 80 px to slow left/right swipes, it matched up down better
            if ((ABS(m_lastGesturePoint.x - gesturePoint.x) > speed + 80) ||
                ABS(velocityX) > minVelocity)
            {
              [self sendButtonPressed:11];
              if (ABS(velocityX) > minVelocity && [self shouldFastScroll])
              {
                [self sendButtonPressed:11];
              }
              m_lastGesturePoint = gesturePoint;
            }
            break;
          }
          default:
          {
            break;
          }
          }
        }

        case UIGestureRecognizerStateEnded:
        {
          direction = UIPanGestureRecognizerDirectionUndefined;
          // start remote idle timer
          [self startRemoteTimer];
          break;
        }

        default:
          break;
        }
      }
      else // dont mimic apple siri remote
      {
        switch (sender.state)
        {
        case UIGestureRecognizerStateBegan:
        {
          m_currentClick = -1;
          m_currentKey = XBMCK_UNKNOWN;
          m_touchBeginSignaled = false;
          break;
        }
        case UIGestureRecognizerStateChanged:
        {
          int keyId = 0;
          if (!m_touchBeginSignaled && m_touchDirection)
          {
            switch (m_touchDirection)
            {
            case UISwipeGestureRecognizerDirectionRight:
              keyId = 11;
              break;
            case UISwipeGestureRecognizerDirectionLeft:
              keyId = 10;
              break;
            case UISwipeGestureRecognizerDirectionUp:
              keyId = 8;
              break;
            case UISwipeGestureRecognizerDirectionDown:
              keyId = 9;
              break;
            default:
              break;
            }
            m_touchBeginSignaled = true;
            [self startKeyPressTimer:keyId];
          }
          break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
          if (m_touchBeginSignaled)
          {
            m_touchBeginSignaled = false;
            m_touchDirection = NULL;
            [self stopKeyPressTimer];
          }
          // start remote idle timer
          [self startRemoteTimer];
          break;
        default:
          break;
        }
      }
    }
  }
}

//--------------------------------------------------------------
- (IBAction)handleSwipe:(UISwipeGestureRecognizer*)sender
{
  if (!m_remoteIdleState)
    m_touchDirection = sender.direction;

  // start remote idle timer
  [self startRemoteTimer];
}

#pragma mark -
- (void)insertVideoView:(UIView*)view
{
  [self.view insertSubview:view belowSubview:glView];
  [self.view setNeedsDisplay];
}

- (void)removeVideoView:(UIView*)view
{
  [view removeFromSuperview];
}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  m_pause = FALSE;
  m_appAlive = FALSE;
  m_animating = FALSE;

  m_isPlayingBeforeInactive = NO;
  m_bgTask = UIBackgroundTaskInvalid;

  [self enableScreenSaver];

  g_xbmcController = self;
  MPNPInfoManager = [DarwinEmbedNowPlayingInfoManager new];
  displayManager = [TVOSDisplayManager new];

  return self;
}
//--------------------------------------------------------------
- (void)dealloc
{
  [displayManager removeModeSwitchObserver];
  // stop background task (if running)
  [self disableBackGroundTask];

  [self stopAnimation];
}
//--------------------------------------------------------------
- (void)viewDidLoad
{
  [super viewDidLoad];

  glView = [[TVOSEAGLView alloc] initWithFrame:self.view.bounds withScreen:[UIScreen mainScreen]];

  // Check if screen is Retina
  displayManager.screenScale = [glView getScreenScale:[UIScreen mainScreen]];
  [self.view addSubview:glView];

  [self createSwipeGestureRecognizers];
  [self createPanGestureRecognizers];
  [self createPressGesturecognizers];
  [self createTapGesturecognizers];

  [displayManager addModeSwitchObserver];
}
//--------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
  [self resumeAnimation];
  [super viewWillAppear:animated];
}
//--------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self becomeFirstResponder];
  [[UIApplication sharedApplication]
      beginReceivingRemoteControlEvents]; // @todo MPRemoteCommandCenter
}
//--------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
  [self pauseAnimation];
  [super viewWillDisappear:animated];
}
//--------------------------------------------------------------
- (void)viewDidUnload
{
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  [self resignFirstResponder];
  [super viewDidUnload];
}
//--------------------------------------------------------------
- (UIView*)inputView
{
  // override our input view to an empty view
  // this prevents the on screen keyboard
  // which would be shown whenever this UIResponder
  // becomes the first responder (which is always the case!)
  // caused by implementing the UIKeyInput protocol
  return [[UIView alloc] initWithFrame:CGRectZero];
}
//--------------------------------------------------------------
- (BOOL)canBecomeFirstResponder
{
  return YES;
}
//--------------------------------------------------------------
- (void)setFramebuffer
{
  if (!m_pause)
    [glView setFramebuffer];
}
//--------------------------------------------------------------
- (bool)presentFramebuffer
{
  if (!m_pause)
    return [glView presentFramebuffer];
  else
    return FALSE;
}

//--------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc. that aren't in use.
}
//--------------------------------------------------------------
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
//--------------------------------------------------------------
- (void)disableBackGroundTask
{
  if (m_bgTask != UIBackgroundTaskInvalid)
  {
    CLog::Log(LOGDEBUG, "%s: endBackgroundTask", __PRETTY_FUNCTION__);
    [[UIApplication sharedApplication] endBackgroundTask:m_bgTask];
    m_bgTask = UIBackgroundTaskInvalid;
  }
}
//--------------------------------------------------------------
- (void)disableSystemSleep
{
}
//--------------------------------------------------------------
- (void)enableSystemSleep
{
}
//--------------------------------------------------------------
- (void)disableScreenSaver
{
  m_disableIdleTimer = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  });
}
//--------------------------------------------------------------
- (void)enableScreenSaver
{
  m_disableIdleTimer = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
  });
}

//--------------------------------------------------------------
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

//--------------------------------------------------------------
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
//--------------------------------------------------------------
- (void)pauseAnimation
{
  m_pause = TRUE;
  g_application.SetRenderGUI(false);
}
//--------------------------------------------------------------
- (void)resumeAnimation
{
  m_pause = FALSE;
  g_application.SetRenderGUI(true);
}
//--------------------------------------------------------------
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
    m_animating = TRUE;
  }
}
//--------------------------------------------------------------
- (void)stopAnimation
{
  if (!m_animating && [glView getCurrentEAGLContext])
  {
    m_appAlive = FALSE;
    m_animating = FALSE;
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

//--------------------------------------------------------------
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
      m_appAlive = TRUE;
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

- (void)CallExit
{
  exit(0);
}

//--------------------------------------------------------------
- (void)remoteControlReceivedWithEvent:(UIEvent*)receivedEvent
{
  if (receivedEvent.type == UIEventTypeRemoteControl)
  {
    switch (receivedEvent.subtype)
    {
    case UIEventSubtypeRemoteControlTogglePlayPause:
      CApplicationMessenger::GetInstance().PostMsg(
          TMSG_GUI_ACTION, WINDOW_INVALID, -1,
          static_cast<void*>(new CAction(ACTION_PLAYER_PLAYPAUSE)));
      break;
    case UIEventSubtypeRemoteControlPlay:
      [self sendButtonPressed:13];
      break;
    case UIEventSubtypeRemoteControlPause:
      [self sendButtonPressed:14];
      break;
    case UIEventSubtypeRemoteControlStop:
      [self sendButtonPressed:15];
      break;
    case UIEventSubtypeRemoteControlNextTrack:
      [self sendButtonPressed:16];
      break;
    case UIEventSubtypeRemoteControlPreviousTrack:
      [self sendButtonPressed:17];
      break;
    case UIEventSubtypeRemoteControlBeginSeekingForward:
      [self sendButtonPressed:18];
      break;
    case UIEventSubtypeRemoteControlBeginSeekingBackward:
      [self sendButtonPressed:19];
      break;
    case UIEventSubtypeRemoteControlEndSeekingForward:
    case UIEventSubtypeRemoteControlEndSeekingBackward:
      // restore to normal playback speed.
      if (g_application.GetAppPlayer().IsPlaying() && !g_application.GetAppPlayer().IsPaused())
        CApplicationMessenger::GetInstance().PostMsg(
            TMSG_GUI_ACTION, WINDOW_INVALID, -1,
            static_cast<void*>(new CAction(ACTION_PLAYER_PLAY)));
      break;
    default:
      break;
    }
    // start remote timeout
    [self startRemoteTimer];
  }
}

- (AVDisplayManager*)avDisplayManager __attribute__((availability(tvos, introduced = 11.2)))
{
  return self.view.window.avDisplayManager;
}

#pragma mark - private helper methods

- (EAGLContext*)getEAGLContextObj
{
  return [glView getCurrentEAGLContext];
}

@end
#undef BOOL
