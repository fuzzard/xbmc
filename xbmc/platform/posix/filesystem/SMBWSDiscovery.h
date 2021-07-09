/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"

#include "platform/posix/filesystem/SMBWSDiscoveryListener.h"

#include <memory>
#include <string>
#include <vector>

class CFileItemList;

namespace WSDiscovery
{
class CWSDiscoveryListenerUDP;
}

// Calculate broadcast address
//static constexpr std::string WSDip4multicast "239.255.255.250"
// Todo: ipv6
// static constexpr std::string WSDip6multicast "FF02::C"
//using namespace WSDiscovery;
namespace WSDiscovery
{
struct wsd_req_info
{
  std::string action;
  std::string msgid;
  std::string types;
  std::string address;
  std::string xaddrs;

  bool operator==(const wsd_req_info& item) const
  {
    return ((item.xaddrs == xaddrs) && (item.address == address));
  }
};

class CWSDiscovery
{
public:
  CWSDiscovery();
  ~CWSDiscovery();

  /*
	 * Get List of smb servers found by WSD
	 * out		(CFileItemList&) List of fileitems populated with smb addresses
	 * return (bool) true if >0 WSD addresses found
	*/
  bool GetServerList(CFileItemList& items);

  void StartServices();
  void StopServices();

  long long GetInstanceID() { return wsd_instance_id; };

  void SetItems(std::vector<WSDiscovery::wsd_req_info> entries);

private:
  /*
	 * Get broadcast IP address to send WSD messages
	 * return (std::string) broadcast ip address
	 */
  std::string GetBroadcastIP();

private:
  CCriticalSection m_critWSD;

  /*
	 * MUST be incremented by >= 1 each time the service has gone down, lost state,
	 * and came back up again. SHOULD NOT be incremented otherwise. Means to set
	 * this value include, but are not limited to:
	 * • A counter that is incremented on each 'cold' boot
	 * • The boot time of the service, expressed as seconds elapsed since midnight
	 * January 1, 1970 
	 */
  long long wsd_instance_id;

  std::string m_broadcast;

  std::unique_ptr<WSDiscovery::CWSDiscoveryListenerUDP> m_WSDListenerUDP;

  std::vector<std::string> vec_strbuffer;

  std::vector<WSDiscovery::wsd_req_info> m_vecWSDInfo;
};
} // namespace WSDiscovery
