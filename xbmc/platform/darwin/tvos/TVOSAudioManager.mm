/*
 *  Copyright (C) 2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "TVOSAudioManager.h"

#include "utils/log.h"

#import <AVFoundation/AVFoundation.h>

@implementation TVOSAudioManager

#pragma mark - audioRouteChange

- (void)handleAudioRouteChange:(NSNotification*)notification
{
  // Your tests on the Audio Output changes will go here
  NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
  switch (routeChangeReason)
  {
    case AVAudioSessionRouteChangeReasonUnknown:
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonUnknown");
        break;
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        // an audio device was added
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonNewDeviceAvailable");
        [self audioRouteChanged];
        [self dumpAudioDescriptions:@"AVAudioSessionRouteChangeReasonNewDeviceAvailable"];
        break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        // a audio device was removed
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
        [self audioRouteChanged];
        [self dumpAudioDescriptions:@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable"];
        break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
        // called at start - also when other audio wants to play
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonCategoryChange");
        [self dumpAudioDescriptions:@"AVAudioSessionRouteChangeReasonCategoryChange"];
        break;
    case AVAudioSessionRouteChangeReasonOverride:
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonOverride");
        break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonWakeFromSleep");
        break;
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory");
        break;
    case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
        CLog::Log(LOGDEBUG, "routeChangeReason : AVAudioSessionRouteChangeReasonRouteConfigurationChange");
        [self dumpAudioDescriptions:@"AVAudioSessionRouteChangeReasonRouteConfigurationChange"];
        break;
    default:
        CLog::Log(LOGDEBUG, "routeChangeReason : unknown notification %ld", static_cast<long>(routeChangeReason));
        break;
  }
}

#pragma mark - audioRouteInterrupted

- (void)handleAudioInterrupted:(NSNotification*)notification
{
  NSNumber* interruptionType = notification.userInfo[AVAudioSessionInterruptionTypeKey];
  switch (interruptionType.integerValue)
  {
    case AVAudioSessionInterruptionTypeBegan:
      // • Audio has stopped, already inactive
      // • Change state of UI, etc., to reflect non-playing state
      CLog::Log(LOGDEBUG, "audioInterrupted : AVAudioSessionInterruptionTypeBegan");
      // pausedForAudioSessionInterruption = YES;
      break;
    case AVAudioSessionInterruptionTypeEnded:
      {
        // • Make session active
        // • Update user interface
        NSNumber* interruptionOption = notification.userInfo[AVAudioSessionInterruptionOptionKey];
        BOOL shouldResume = interruptionOption.integerValue == AVAudioSessionInterruptionOptionShouldResume;
        if (shouldResume == YES)
        {
          // if shouldResume you should continue playback.
          CLog::Log(LOGDEBUG, "audioInterrupted : AVAudioSessionInterruptionTypeEnded: resume=yes");
        }
        else
        {
          CLog::Log(LOGDEBUG, "audioInterrupted : AVAudioSessionInterruptionTypeEnded: resume=no");
        }
        // pausedForAudioSessionInterruption = NO;
      }
      break;
    default:
      break;
  }
}

- (void)handleMediaServicesReset:(NSNotification*)notification
{
  // Dispose orphaned audio objects and create new audio objects
  // Reset any internal audio state being tracked, including all properties of AVAudioSession
  // When appropriate, reactivate the AVAudioSession using the setActive:error: method
  // test by choosing the "Reset Media Services" selection in the Settings app
}

- (void)audioRouteChanged
{
  if (CServiceBroker::GetActiveAE())
    CServiceBroker::GetActiveAE()->DeviceChange();
}

#pragma mark - Audio Notication register

- (void)registerAudioRouteNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaServicesReset:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
}

- (void)unregisterAudioRouteNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionMediaServicesWereResetNotification object:nil];
}

#pragma mark - Audio Logging

- (void)dumpAudioDescriptions(NSString& reason)
{
  CLog::Log(LOGDEBUG, "DumpAudioDescriptions: Reason: {}", [reason UTF8String]);

  AVAudioSession* myAudioSession = [AVAudioSession sharedInstance];

  NSArray* currentInputs = myAudioSession.currentRoute.inputs;
  CLog::Log(LOGDEBUG, "DumpAudioDescriptions: input count = {}", [currentInputs count]);
  for (auto input : currentInputs)
  {
    CLog::Log(LOGDEBUG, "DumpAudioDescriptions: Input portName, {}", [input.portName UTF8String]);
    for (auto channel : input.channels)
    {
      CLog::Log(LOGDEBUG, "DumpAudioDescriptions: channelLabel, {}", channel.channelLabel);
      CLog::Log(LOGDEBUG, "DumpAudioDescriptions: channelName , {}", [channel.channelName UTF8String]);
    }
  }

  NSArray* currentOutputs = myAudioSession.currentRoute.outputs;
  CLog::Log(LOGDEBUG, "DumpAudioDescriptions: output count = {}", [currentOutputs count]);
  for (auto output : currentOutputs)
  {
    CLog::Log(LOGDEBUG, "DumpAudioDescriptions : Output portName, %s", [output.portName UTF8String]);
    for (auto channel : portDesc.channels)
    {
      CLog::Log(LOGDEBUG, "DumpAudioDescriptions: channelLabel, %d", channel.channelLabel);
      CLog::Log(LOGDEBUG, "DumpAudioDescriptions: channelName , %s", [channel.channelName UTF8String]);
    }
  }
}

#pragma mark - init
- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  return self;
}

@end
