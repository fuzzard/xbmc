/*
 *  Copyright (C) 2010-2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "DarwinEmbedNowPlayingInfoManager.h"

#if defined(TARGET_DARWIN_IOS)
#import "platform/darwin/ios/XBMCController.h"
#elif defined(TARGET_DARWIN_TVOS)
#import "platform/darwin/tvos/XBMCController.h"
#endif

#import <Foundation/Foundation.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>

@implementation DarwinEmbedNowPlayingInfoManager

@synthesize playbackState;

#pragma mark - Now Playing routines
//--------------------------------------------------------------
- (void)setDarwinEmbedNowPlayingInfo:(NSDictionary*)info
{
  self.nowPlayingInfo = info;
  [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingInfo;
}
//--------------------------------------------------------------
- (void)onPlay:(NSDictionary*)item
{
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

  NSString* title = item[@"title"];
  if (title && title.length > 0)
    dict[MPMediaItemPropertyTitle] = title;
  NSString* album = item[@"album"];
  if (album && album.length > 0)
    dict[MPMediaItemPropertyAlbumTitle] = album;
  NSArray* artists = item[@"artist"];
  if (artists && artists.count > 0)
    dict[MPMediaItemPropertyArtist] = [artists componentsJoinedByString:@" "];
  if (NSNumber* track = item[@"track"])
    dict[MPMediaItemPropertyAlbumTrackNumber] = track;
  if (NSNumber* duration = item[@"duration"])
    dict[MPMediaItemPropertyPlaybackDuration] = duration;
  NSArray* genres = item[@"genre"];
  if (genres && genres.count > 0)
    dict[MPMediaItemPropertyGenre] = [genres componentsJoinedByString:@" "];

  NSString* thumb = [item objectForKey:@"thumb"];
  if (thumb && thumb.length > 0)
  {
    auto image = [UIImage imageWithContentsOfFile:thumb];
    if (image)
    {
      MPMediaItemArtwork* mArt = [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size requestHandler:^UIImage* _Nonnull(CGSize aSize) { return image; }];
      if (mArt)
        dict[MPMediaItemPropertyArtwork] = mArt;
    }
  }

  if (NSNumber* elapsed = item[@"elapsed"])
    dict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed;
  if (NSNumber* speed = item[@"speed"])
    dict[MPNowPlayingInfoPropertyPlaybackRate] = speed;
  if (NSNumber* current = item[@"current"])
    dict[MPNowPlayingInfoPropertyPlaybackQueueIndex] = current;
  if (NSNumber* total = item[@"total"])
    dict[MPNowPlayingInfoPropertyPlaybackQueueCount] = total;

  /*! @Todo additional properties?
   other properities can be set:
   MPMediaItemPropertyAlbumTrackCount
   MPMediaItemPropertyComposer
   MPMediaItemPropertyDiscCount
   MPMediaItemPropertyDiscNumber
   MPMediaItemPropertyPersistentID

   Additional metadata properties:
   MPNowPlayingInfoPropertyChapterNumber;
   MPNowPlayingInfoPropertyChapterCount;
   */

  [self setDarwinEmbedNowPlayingInfo:dict];

  self.playbackState = DARWINEMBED_PLAYBACK_PLAYING;

#if defined(TARGET_DARWIN_IOS)
  [g_xbmcController disableNetworkAutoSuspend];
#endif
}
//--------------------------------------------------------------
- (void)OnSpeedChanged:(NSDictionary*)item
{
  NSMutableDictionary* info = [self.nowPlayingInfo mutableCopy];
  if (NSNumber* elapsed = item[@"elapsed"])
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed;
  if (NSNumber* speed = item[@"speed"])
    info[MPNowPlayingInfoPropertyPlaybackRate] = speed;

  [self setDarwinEmbedNowPlayingInfo:info];
}
//--------------------------------------------------------------
- (void)onPause:(NSDictionary*)item
{
  self.playbackState = DARWINEMBED_PLAYBACK_PAUSED;

#if defined(TARGET_DARWIN_IOS)
  // schedule set network auto suspend state for save power if idle.
  [g_xbmcController rescheduleNetworkAutoSuspend];
#endif
}
//--------------------------------------------------------------
- (void)onStop:(NSDictionary*)item
{
  [self setDarwinEmbedNowPlayingInfo:nil];

  self.playbackState = DARWINEMBED_PLAYBACK_STOPPED;

#if defined(TARGET_DARWIN_IOS)
  // delay set network auto suspend state in case we are switching playing item.
  [g_xbmcController rescheduleNetworkAutoSuspend];
#endif
}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  playbackState = DARWINEMBED_PLAYBACK_STOPPED;

  return self;
}

@end
