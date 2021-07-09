/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "SMBWSDiscovery.h"

#include "FileItem.h"
#include "ServiceBroker.h"
#include "URL.h"
#include "network/Network.h"
#include "threads/SingleLock.h"
#include "utils/StringUtils.h"
#include "utils/URIUtils.h"
#include "utils/log.h"

#include "platform/posix/filesystem/SMBWSDiscoveryListener.h"

#include <algorithm>
#include <chrono>
#include <memory>
#include <string>
#include <vector>

// GetBroadcastIP
#include <string.h>

#include <arpa/inet.h>
#include <netdb.h>

using namespace std::chrono;
using namespace WSDiscovery;

namespace WSDiscovery
{
CWSDiscovery::CWSDiscovery()
{
  // Set our wsd_instance ID to seconds since epoch
  auto epochduration = system_clock::now().time_since_epoch();
  wsd_instance_id = epochduration.count() * system_clock::period::num / system_clock::period::den;

  m_WSDListenerUDP = std::make_unique<CWSDiscoveryListenerUDP>();
}

CWSDiscovery::~CWSDiscovery()
{
  StopServices();
}

void CWSDiscovery::StopServices()
{
  m_WSDListenerUDP->Stop();
  CLog::Log(LOGINFO, "CWSDiscovery::StopServices - Stopped");
}

void CWSDiscovery::StartServices()
{
  m_WSDListenerUDP->Start();

  CLog::Log(LOGINFO, "CWSDiscovery::StartServices - Started");
}

bool CWSDiscovery::GetServerList(CFileItemList& items)
{
  {
    CSingleLock lock(m_critWSD);

    // delim1 used to strip protocol from xaddrs
    // delim2 used to strip anything past the port
    const std::string delim1 = "://";
    const std::string delim2 = ":5357";
    for (auto item : m_vecWSDInfo)
    {
      int found = item.xaddrs.find(delim1);
      if (found == std::string::npos)
        continue;

      std::string tmpxaddrs = item.xaddrs.substr(found + delim1.size());
      found = tmpxaddrs.find(delim2);
      // fallback incase xaddrs doesnt return back "GetMetadata" expected address format (delim2)
      if (found == std::string::npos)
      {
        found = tmpxaddrs.find("/");
      }
      std::string host = tmpxaddrs.substr(0, found);

      CFileItemPtr pItem = std::make_shared<CFileItem>(host);
      pItem->SetPath("smb://" + host + '/');
      pItem->m_bIsFolder = true;
      items.Add(pItem);
    }
  }
  return true;
}

void CWSDiscovery::SetItems(std::vector<wsd_req_info> entries)
{
  {
    CSingleLock lock(m_critWSD);
    m_vecWSDInfo = entries;
  }
}

/*
 * Get broadcast IP address to send WSD messages
 * return (std::string) broadcast ip address or empty if failed to find
 */
std::string CWSDiscovery::GetBroadcastIP()
{
  // Assumptions
  // Kodi only considers "first found" interface.
  // For simplicity, use this assumption for WSD for now

  CNetworkInterface* iface = CServiceBroker::GetNetwork().GetFirstConnectedInterface();
  if (!iface)
  {
    // No interfaces connected
    return "";
  }

  // string addresses may be ipv4 or ipv6. We need to know which to do calculation
  std::string strIPaddress(iface->GetCurrentIPAddress());
  std::string strIPnetmask(iface->GetCurrentNetmask());

  // Our final address for broadcast IP
  // Size big enough for both ip4/ip6 addresses
  char broadcast_address[INET6_ADDRSTRLEN];

  struct addrinfo hints;
  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = PF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_DEFAULT | AI_NUMERICHOST | AI_NUMERICSERV;

  struct addrinfo* resIP = NULL;
  int rc = getaddrinfo(strIPaddress.c_str(), NULL, &hints, &resIP);

  if (rc != 0)
  {
    // Error with IP Address
    return "";
  }

  struct addrinfo* resnetmask = NULL;
  rc = getaddrinfo(strIPnetmask.c_str(), NULL, &hints, &resnetmask);
  if (rc != 0)
  {
    freeaddrinfo(resIP);
    // Error with Netmask
    return "";
  }

  unsigned int broadcast;
  //char* broadcast6;
  switch (resIP->ai_family)
  {
    case AF_INET:
      // calc broadcast by (IP | ~Netmask)
      broadcast = ((struct sockaddr_in*)resIP->ai_addr)->sin_addr.s_addr |
                  ~((struct sockaddr_in*)resnetmask->ai_addr)->sin_addr.s_addr;
      inet_ntop(AF_INET, &broadcast, broadcast_address, INET_ADDRSTRLEN);
      break;
    case AF_INET6:
      // Todo: How do we handle this?
      // SSDP Broadcast address per https://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml
      //broadcast_address = "FF02:0:0:0:0:0:0:C";
      // inet_ntop(AF_INET6, &broadcast6, broadcast_address, INET6_ADDRSTRLEN);
      break;
  }
  freeaddrinfo(resnetmask);
  freeaddrinfo(resIP);
  return broadcast_address;
}
} // namespace WSDiscovery
