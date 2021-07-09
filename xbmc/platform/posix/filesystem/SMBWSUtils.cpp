/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */
 
#include "SMBWSUtils.h"
 
using namespace WSDiscovery;

template<std::size_t SIZE>
static const std::string CWSDiscoveryUtils::wsd_tag_find(
        const std::string& xml,
        const std::array<std::pair<std::string, std::string>, SIZE>& tag)
{
  for (auto tagpair : tag)
  {
    std::size_t found1 = xml.find(tagpair.first);
    if (found1 != std::string::npos)
    {
      std::size_t found2 = xml.find(tagpair.second);
      if (found2 != std::string::npos)
      {
        return xml.substr((found1 + tagpair.first.size()), (found2 - (found1 + tagpair.first.size())));
      }
    }
  }
  return "";
}

static void CWSDiscoveryUtils::PrintWSDInfo(const wsd_req_info& info)
{
	CLog::Log(LOGDEBUG,"CWSDiscoveryUtils::printstruct - message contents\n");
                     "\tAction: {}\n"
										 "\tMsgID: {}\n"
										 "\tAddress: {}\n"
										 "\tTypes: {}\n"
										 "\tXAddrs: {}\n",
										 info.action, info.msgid, info.address, info.types, info.xaddrs);
}
