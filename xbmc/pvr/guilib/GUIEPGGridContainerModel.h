/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "XBDateTime.h"

#include <functional>
#include <map>
#include <memory>
#include <unordered_map>
#include <utility>
#include <vector>

class CFileItem;
class CFileItemList;

namespace PVR
{
  struct GridItem
  {
    GridItem(const std::shared_ptr<CFileItem>& _item, float _width, int _startBlock, int _endBlock)
      : item(_item),
        originWidth(_width),
        width(_width),
        startBlock(_startBlock),
        endBlock(_endBlock)
    {
    }

    std::shared_ptr<CFileItem> item;
    float originWidth = 0.0f;
    float width = 0.0f;
    int startBlock = 0;
    int endBlock = 0;
  };

  class CPVREpgInfoTag;

  class CGUIEPGGridContainerModel
  {
  public:
    static const int MINSPERBLOCK = 5; // minutes
    static const int MAXBLOCKS = 33 * 24 * 60 / MINSPERBLOCK; //! 33 days of 5 minute blocks (31 days for upcoming data + 1 day for past data + 1 day for fillers)

    CGUIEPGGridContainerModel() = default;
    virtual ~CGUIEPGGridContainerModel() = default;

    void Initialize(const std::unique_ptr<CFileItemList>& items,
                    const CDateTime& gridStart,
                    const CDateTime& gridEnd,
                    int iFirstChannel,
                    int iChannelsPerPage,
                    int iFirstBlock,
                    int iBlocksPerPage,
                    int iRulerUnit,
                    float fBlockSize,
                    bool bFirstOpen);
    void SetInvalid();

    static const int INVALID_INDEX = -1;
    void FindChannelAndBlockIndex(int channelUid, unsigned int broadcastUid, int eventOffset, int& newChannelIndex, int& newBlockIndex) const;

    void FreeChannelMemory(int keepStart, int keepEnd);
    void FreeProgrammeMemory(int firstChannel, int lastChannel, int firstBlock, int lastBlock);
    void FreeRulerMemory(int keepStart, int keepEnd);

    std::shared_ptr<CFileItem> GetChannelItem(int iIndex) const { return m_channelItems[iIndex]; }
    bool HasChannelItems() const { return !m_channelItems.empty(); }
    int ChannelItemsSize() const { return static_cast<int>(m_channelItems.size()); }

    std::shared_ptr<CFileItem> GetRulerItem(int iIndex) const { return m_rulerItems[iIndex]; }
    int RulerItemsSize() const { return static_cast<int>(m_rulerItems.size()); }

    int GetBlockCount() const { return m_blocks; }
    std::shared_ptr<CFileItem> GetGridItem(int iChannel, int iBlock) const;
    int GetGridItemStartBlock(int iChannel, int iBlock) const;
    int GetGridItemEndBlock(int iChannel, int iBlock) const;
    float GetGridItemWidth(int iChannel, int iBlock) const;
    float GetGridItemOriginWidth(int iChannel, int iBlock) const;
    void SetGridItemWidth(int iChannel, int iBlock, float fWidth);

    bool IsZeroGridDuration() const { return (m_gridEnd - m_gridStart) == CDateTimeSpan(0, 0, 0, 0); }
    const CDateTime& GetGridStart() const { return m_gridStart; }
    const CDateTime& GetGridEnd() const { return m_gridEnd; }
    unsigned int GetGridStartPadding() const;

    unsigned int GetPageNowOffset() const;
    int GetNowBlock() const;

    CDateTime GetStartTimeForBlock(int block) const;
    int GetBlock(const CDateTime& datetime) const;
    int GetFirstEventBlock(const std::shared_ptr<CPVREpgInfoTag>& event) const;
    int GetLastEventBlock(const std::shared_ptr<CPVREpgInfoTag>& event) const;

  private:
    GridItem* GetGridItemPtr(int iChannel, int iBlock) const;
    std::shared_ptr<CFileItem> CreateGapItem(int iChannel) const;
    std::shared_ptr<CFileItem> GetGapItem(int iChannel, int iStartBlock) const;

    using EpgTagsMap = std::unordered_map<int, std::vector<std::shared_ptr<CFileItem>>>;
    const EpgTagsMap::const_iterator GetChannelEpgTags(int iChannel) const;

    mutable EpgTagsMap m_epgItems;

    CDateTime m_gridStart;
    CDateTime m_gridEnd;

    std::vector<std::shared_ptr<CFileItem>> m_channelItems;
    std::vector<std::shared_ptr<CFileItem>> m_rulerItems;

    struct GridCoordinates
    {
      GridCoordinates(int _channel, int _block) : channel(_channel), block(_block) {}

      bool operator==(const GridCoordinates& other) const
      {
        return (channel == other.channel && block == other.block);
      }

      int channel = 0;
      int block = 0;
    };

    struct GridCoordinatesHash
    {
      std::size_t operator()(const GridCoordinates& coordinates) const
      {
        return std::hash<int>()(coordinates.channel) ^ std::hash<int>()(coordinates.block);
      }
    };

    mutable std::unordered_map<GridCoordinates, GridItem, GridCoordinatesHash> m_gridIndex;
    mutable std::map<std::pair<int, int>, std::shared_ptr<CFileItem>> m_gapItems;

    int m_blocks = 0;
    float m_fBlockSize = 0.0f;

    int m_firstActiveChannel = 0;
    int m_lastActiveChannel = 0;
    int m_firstActiveBlock = 0;
    int m_lastActiveBlock = 0;

    bool m_bFirstOpen = true;
  };
}
