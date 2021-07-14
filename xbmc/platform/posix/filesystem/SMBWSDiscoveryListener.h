/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "threads/CriticalSection.h"
#include "threads/Thread.h"

#include <string>
#include <vector>

#include <netinet/in.h>

namespace WSDiscovery
{
struct wsd_req_info;
}

namespace WSDiscovery
{
class CWSDiscoveryListenerUDP : public CThread
{
public:
  CWSDiscoveryListenerUDP();
  ~CWSDiscoveryListenerUDP();

  void Start();
  void Stop();

protected:
  void Process() override;

private:
  struct Command
  {
    struct sockaddr_in address;
    std::string commandMsg;
  };

  bool DispatchCommand();
  void AddCommand(const std::string message, const std::string extraparameter = "");
  void ParseBuffer(const std::string& buffer);

  /*
	 * Generates a SOAP message given a particular action type
	 * in				(string) action type
	 * in/out		(string) created message
	 * in       (string) extra data field (currently used for resolve addresses)
	 * return  	(bool) true if full message crafted
	 */
  bool buildSoapMessage(const std::string& action,
                        std::string& msg,
                        const std::string extraparameter);

private:
  template<std::size_t SIZE>
  const std::string wsd_tag_find(const std::string& xml,
                                 const std::array<std::pair<std::string, std::string>, SIZE>& tag);

  void PrintWSDInfo(const WSDiscovery::wsd_req_info& info);

  const bool equalsAddress(const WSDiscovery::wsd_req_info& lhs,
                           const WSDiscovery::wsd_req_info& rhs);

  // Socket FD for send/recv
  int fd;
  std::vector<Command> m_commandbuffer;
  CCriticalSection crit_commandqueue;
  CCriticalSection crit_wsdqueue;

  std::vector<WSDiscovery::wsd_req_info> m_vecWSDInfo;

  const std::string wsd_instance_address;

  const int retries = 4;

  // Max udp packet size (+ UDP header + IP header overhead = 65535)
  const int UDPBUFFSIZE = 65507;

  // Port for unicast/multicast WDS traffic
  const int wsdUDP = 3702;

  // ipv4 multicast group WSD - https://specs.xmlsoap.org/ws/2005/04/discovery/ws-discovery.pdf
  const char* WDSMultiGroup = "239.255.255.250";
};
} // namespace WSDiscovery
