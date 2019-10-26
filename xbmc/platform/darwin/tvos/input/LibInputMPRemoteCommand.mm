/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputMPRemoteCommand.h"

#include "Application.h"
#include "input/actions/Action.h"
#include "messaging/ApplicationMessenger.h"

#import "platform/darwin/tvos/input/LibInputHandler.h"
#import "platform/darwin/tvos/XBMCController.h"

#import <MediaPlayer/MediaPlayer.h>

@implementation TVOSLibInputMPRemoteCommand

#pragma mark - control center
- (void)createCustomControlCenter
{
  MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

  // enable play button
  commandCenter.playCommand.enabled = YES;
  [commandCenter.playCommand addTarget:self action:@selector(onPlay:)];
  // enable pause button
  commandCenter.pauseCommand.enabled = YES;
  [commandCenter.pauseCommand addTarget:self action:@selector(onPause:)];
  // enable play/pause button
  commandCenter.togglePlayPauseCommand.enabled = YES;
  [commandCenter.togglePlayPauseCommand addTarget:self action:@selector(onPlayPause:)];
  // enable stop button
  commandCenter.stopCommand.enabled = YES;
  [commandCenter.stopCommand addTarget:self action:@selector(onStop:)];

  // disable seek
  commandCenter.seekForwardCommand.enabled = NO;
  [commandCenter.seekForwardCommand addTarget:self action:@selector(onSeekFF:)];

  commandCenter.seekBackwardCommand.enabled = NO;
  [commandCenter.seekBackwardCommand addTarget:self action:@selector(onSeekREW:)];

  // enable next/previous
  commandCenter.previousTrackCommand.enabled = YES;
  [commandCenter.previousTrackCommand addTarget:self action:@selector(onPrevItem:)];

  commandCenter.nextTrackCommand.enabled = YES;
  [commandCenter.nextTrackCommand addTarget:self action:@selector(onNextItem:)];

  // disable skip
  commandCenter.skipBackwardCommand.preferredIntervals = @[@(42)];  // Set your own interval
  commandCenter.skipBackwardCommand.enabled = NO;
  [commandCenter.skipBackwardCommand addTarget:self action:@selector(onSkipBack:)];

  commandCenter.skipForwardCommand.preferredIntervals = @[@(42)];  // Max 99
  commandCenter.skipForwardCommand.enabled = NO;
  [commandCenter.skipForwardCommand addTarget:self action:@selector(onSkipForward:)];

  // seek bar
  [commandCenter.changePlaybackPositionCommand addTarget:self action:@selector(onPlaybackPosition:)];

  commandCenter.changePlaybackRateCommand.enabled = NO;
  [commandCenter.changePlaybackRateCommand addTarget:self action:@selector(onPlaybackRate:)];

  // disable shuffle/repeat
  commandCenter.changeRepeatModeCommand.enabled = NO;
  [commandCenter.changeRepeatModeCommand addTarget:self action:@selector(onChangeRepeat:)];

  commandCenter.changeShuffleModeCommand.enabled = NO;
  [commandCenter.changeShuffleModeCommand addTarget:self action:@selector(onShuffle:)];

  // ratings
  commandCenter.ratingCommand.enabled = NO;
  [commandCenter.ratingCommand addTarget:self action:@selector(onRating:)];

  commandCenter.likeCommand.enabled = YES;
  [commandCenter.likeCommand addTarget:self action:@selector(onRatingLike:)];

  commandCenter.dislikeCommand.enabled = YES;
  [commandCenter.dislikeCommand addTarget:self action:@selector(onRatingDislike:)];

  // bookmark
  commandCenter.bookmarkCommand.enabled = YES;
  [commandCenter.bookmarkCommand addTarget:self action:@selector(onBookmark:)];

  // Change Audio Language Track
  commandCenter.enableLanguageOptionCommand.enabled = YES;
  [commandCenter.enableLanguageOptionCommand addTarget:self action:@selector(onEnableLanguage:)];

  commandCenter.disableLanguageOptionCommand.enabled = NO;
  [commandCenter.disableLanguageOptionCommand addTarget:self action:@selector(onDisableLangage:)];

}

- (MPRemoteCommandHandlerStatus)onPlaybackPosition:(MPChangePlaybackPositionCommandEvent*) event
{
  g_application.SeekTime(event.positionTime);
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onPlay:(MPRemoteCommandEvent*)event
{
  if (g_application.GetAppPlayer().IsPlaying())
  {
    KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
      TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_PLAYER_PLAYPAUSE)));

    // break screensaver
    g_application.ResetSystemIdleTimer();
    g_application.ResetScreenSaver();
  }
  else
  {
    [g_xbmcController.inputHandler sendButtonPressed:5 /* Select */];
  }

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onPause:(MPRemoteCommandEvent*)event
{
  if (g_application.GetAppPlayer().IsPlaying())
  {
    if (g_application.GetAppPlayer().IsPaused())
      [g_xbmcController.inputHandler sendButtonPressed:13 /* Play */];
    else
      [g_xbmcController.inputHandler sendButtonPressed:14 /* Pause */];
  }
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onPlayPause:(MPRemoteCommandEvent*)event
{
  if (g_application.GetAppPlayer().IsPlaying())
  {
    if (g_application.GetAppPlayer().IsPaused())
      [g_xbmcController.inputHandler sendButtonPressed:13 /* Play */];
    else
      [g_xbmcController.inputHandler sendButtonPressed:14 /* Pause */];
  }
  else
  {
    [g_xbmcController.inputHandler sendButtonPressed:5 /* Select */];
  }
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onStop:(MPRemoteCommandEvent*)event
{
  [g_xbmcController.inputHandler sendButtonPressed:15 /* Stop */];
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onSeekFF:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onSeekREW:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onSkipForward:(MPRemoteCommandEvent*)event
{
  [g_xbmcController.inputHandler sendButtonPressed:18 /* FastForward */];
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onSkipBack:(MPRemoteCommandEvent*)event
{
  [g_xbmcController.inputHandler sendButtonPressed:19 /* Rewind */];
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onNextItem:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_NEXT_ITEM)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onPrevItem:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_PREV_ITEM)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onPlaybackRate:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onChangeRepeat:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onShuffle:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onRating:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onRatingLike:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_INCREASE_RATING)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onRatingDislike:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_DECREASE_RATING)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onBookmark:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_CREATE_BOOKMARK)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onEnableLanguage:(MPRemoteCommandEvent*)event
{
  KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(
    TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(new CAction(ACTION_AUDIO_NEXT_LANGUAGE)));

  // break screensaver
  g_application.ResetSystemIdleTimer();
  g_application.ResetScreenSaver();

  return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)onDisableLangage:(MPRemoteCommandEvent*)event
{
  return MPRemoteCommandHandlerStatusSuccess;
}

@end
