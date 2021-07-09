/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "platform/posix/filesystem/SMBWSUtils.h"
#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"

//#include <memory>
#include <string>
#include <vector>

class CFileItemList;

namespace WSDiscovery
{
class WSDiscoveryUtils;
}

// Calculate broadcast address
//static constexpr std::string WSDip4multicast "239.255.255.250"
// Todo: ipv6
// static constexpr std::string WSDip6multicast "FF02::C"
using namespace WSDiscovery;

class CWSDiscovery
{
public:
  CWSDiscovery();
  ~CWSDiscovery() override;
  
	/*
	 * Get List of smb servers found by WSD
	 * out		(CFileItemList&) List of fileitems populated with smb addresses
	 * return (bool) true if >0 WSD addresses found
	*/
  bool GetServerList(CFileItemList& items);

  void StartServices();
  void StopServices();
  
  static long long GetInstanceID() { return wsd_instance_id };
  
  void SetItems(std::vector<wsd_req_info> entries);

private:
	/*
	 * Get broadcast IP address to send WSD messages
	 * return (std::string) broadcast ip address
	 */
  std::string GetBroadcastIP();

private:
  CCriticalSection m_critWSD;
  std::vector<SOCKET> m_ServerSockets = {};
  static long long wsd_instance_id;
  
  std::string m_broadcast;

//  CWSDiscoveryListenerTCP m_WSDListenerTCP;
  CWSDiscoveryListenerUDP m_WSDListenerUDP;
  
  std::vector<std::string> vec_strbuffer;

  std::vector<WSDiscoveryUtils::wsd_req_info> m_vecWSDInfo;
  
};
