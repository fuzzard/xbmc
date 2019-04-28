/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */


#import "TVOSTopShelf.h"
#import "tvosShared.h"
#import "platform/darwin/AutoPool.h"

#include "Application.h"
#include "messaging/ApplicationMessenger.h"
#include "FileItem.h"
#include "DatabaseManager.h"
#include "guilib/GUIWindowManager.h"
#include "video/VideoDatabase.h"
#include "video/VideoThumbLoader.h"
#include "video/VideoInfoTag.h"
#include "video/dialogs/GUIDialogVideoInfo.h"
#include "video/windows/GUIWindowVideoNav.h"
#include "video/windows/GUIWindowVideoBase.h"
#include "filesystem/File.h"

#import "system.h"
#include "utils/log.h"
#include "guilib/LocalizeStrings.h"
#include "utils/StringUtils.h"
#include "utils/URIUtils.h"
#include "utils/Base64.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach_host.h>
#import <sys/sysctl.h>

static const int MaxItems = 5;

std::string CTVOSTopShelf::m_url;
bool CTVOSTopShelf::m_handleUrl;

CTVOSTopShelf::CTVOSTopShelf()
{
}

CTVOSTopShelf::~CTVOSTopShelf()
{
}

CTVOSTopShelf &CTVOSTopShelf::GetInstance()
{
  static CTVOSTopShelf sTopShelf;
  return sTopShelf;
}

void CTVOSTopShelf::SetTopShelfItems(CFileItemList& movies, CFileItemList& tv)
{
  CCocoaAutoPool pool;
  auto storeUrl = [tvosShared getSharedURL];
  if (!storeUrl)
    return;

  storeUrl = [storeUrl URLByAppendingPathComponent:@"RA" isDirectory:YES];
  const BOOL isJailbroken = [tvosShared isJailbroken];
  CLog::Log(LOGDEBUG, "TopShelf: using shared path %s (jailbroken: %s)\n", storeUrl.path.UTF8String, isJailbroken ? "yes" : "no");

  auto sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[tvosShared getSharedID]];
  auto sharedDictJailbreak = isJailbroken ? [[NSMutableDictionary alloc] initWithCapacity:2 + 2] : nil; // for jailbroken devices

  // store all old thumbs in array
  auto fileManager = NSFileManager.defaultManager;
  auto filePaths = [NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:storeUrl.path error:nil]];
  std::string raPath = [storeUrl.path UTF8String];
  CVideoThumbLoader thumbLoader;

  auto fillSharedDicts = [&](CFileItemList& videoItems, NSString* videosKey, NSString* videosTitleKey, uint32_t titleStringCode, std::function<std::string(CFileItemPtr videoItem)> getThumbnailForItem, std::function<std::string(CFileItemPtr videoItem)> getTitleForItem){
    if (videoItems.Size() <= 0)
    {
      // cleanup if there is no RA
      [sharedDefaults removeObjectForKey:videosKey];
      [sharedDefaults removeObjectForKey:videosTitleKey];
      return;
    }

    const int topShelfSize = std::min(videoItems.Size(), MaxItems);
    auto videosArray = [NSMutableArray arrayWithCapacity:topShelfSize];
    for (int i = 0; i < topShelfSize; ++i)
    {
      auto videoItem = videoItems.Get(i);
      if (!videoItem->HasArt("thumb"))
        thumbLoader.LoadItem(videoItem.get());

      auto thumbnailPath = getThumbnailForItem(videoItem);
      auto fileName = std::to_string(videoItem->GetVideoInfoTag()->m_iDbId) + URIUtils::GetFileName(thumbnailPath);
      auto destPath = URIUtils::AddFileToFolder(raPath, fileName);
      if (!XFILE::CFile::Exists(destPath))
        XFILE::CFile::Copy(thumbnailPath, destPath);
      else
      {
        // remove from array so it doesnt get deleted at the end
        [filePaths removeObject:[NSString stringWithUTF8String:fileName.c_str()]];
      }

      auto title = getTitleForItem(videoItem);
      CLog::Log(LOGDEBUG, "TopShelf: - adding video to '%s' array: %s\n", videosKey.UTF8String, title.c_str());
      [videosArray addObject:@{@"title": [NSString stringWithUTF8String:title.c_str()],
                               @"thumb": [NSString stringWithUTF8String:fileName.c_str()],
                               @"url": [NSString stringWithUTF8String:Base64::Encode(videoItem->GetVideoInfoTag()->GetPath()).c_str()]
                               }];
    }
    [sharedDefaults setObject:videosArray forKey:videosKey];
    [sharedDictJailbreak setObject:videosArray forKey:videosKey];

    auto tvTitle = [NSString stringWithUTF8String:g_localizeStrings.Get(titleStringCode).c_str()];
    [sharedDefaults setObject:tvTitle forKey:videosTitleKey];
    [sharedDictJailbreak setObject:tvTitle forKey:videosTitleKey];
  };

  fillSharedDicts(movies, @"movies", @"moviesTitle", 20386, [](CFileItemPtr videoItem){ return videoItem->GetArt("thumb"); }, [](CFileItemPtr videoItem){ return videoItem->GetLabel(); });

  CVideoDatabase videoDb;
  videoDb.Open();
  fillSharedDicts(tv, @"tv", @"tvTitle", 20387, [&videoDb](CFileItemPtr videoItem){
    int season = videoItem->GetVideoInfoTag()->m_iIdSeason;
    return season > 0 ? videoDb.GetArtForItem(season, MediaTypeSeason, "poster") : std::string{};
  }, [](CFileItemPtr videoItem){ return StringUtils::Format("%s s%02de%02d", videoItem->GetVideoInfoTag()->m_strShowTitle.c_str(), videoItem->GetVideoInfoTag()->m_iSeason,
                                                            videoItem->GetVideoInfoTag()->m_iEpisode); });
  videoDb.Close();

  // remove unused thumbs from cache folder
  for (NSString* strFiles in filePaths)
    [fileManager removeItemAtURL:[storeUrl URLByAppendingPathComponent:strFiles isDirectory:FALSE] error:nil];

  [sharedDictJailbreak writeToURL:[storeUrl URLByAppendingPathComponent:@"shared.dict"] atomically:YES];
  [sharedDefaults synchronize];

  [sharedDictJailbreak release];
  [sharedDefaults release];
}

void CTVOSTopShelf::RunTopShelf()
{
  if (m_handleUrl)
  {
    m_handleUrl = false;

    std::vector<std::string> split = StringUtils::Split(m_url, "/");

    std::string url = Base64::Decode(split[4]);

    if (split[2] == "display")
    {
      KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_MASK_WINDOWMANAGER + 9, -1, -1, static_cast<void*>(new CFileItem(url.c_str(), false)));
    }
    else //play
    {
      // its a bit ugly, but only way to get resume window to show
      std::string cmd = StringUtils::Format("PlayMedia(%s)", StringUtils::Paramify(url.c_str()).c_str());
      KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_EXECUTE_BUILT_IN, -1, -1, nullptr, cmd);
    }
  }
}

void CTVOSTopShelf::HandleTopShelfUrl(const std::string& url, const bool run)
{
  m_url = url;
  m_handleUrl = run;
}
