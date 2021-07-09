/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include <array>
#include <string>
#include <utility>

namespace WSDiscovery
{

// These are the only actions we care for
static const std::string WSD_ACT_HELLO = "http://schemas.xmlsoap.org/ws/2005/04/discovery/Hello";
static const std::string WSD_ACT_BYE = "http://schemas.xmlsoap.org/ws/2005/04/discovery/Bye";
static const std::string WSD_ACT_PROBEMATCH = "http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches";
static const std::string WSD_ACT_PROBE = "http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe";
static const std::string WSD_ACT_RESOLVE = "https://schemas.xmlsoap.org/ws/2005/04/discovery/Resolve";
static const std::string WSD_ACT_RESOLVEMATCHES = "https://schemas.xmlsoap.org/ws/2005/04/discovery/ResolveMatches";


// These are the xml start/finish tags we need info from
// An array of start/finish xml strings
static const std::array<std::pair<std::string, std::string>, 2> action_tag {{
	{"<wsa:Action>", "</wsa:Action>"},
	{"<wsa:Action SOAP-ENV:mustUnderstand=\"true\">", "</wsa:Action>"}
}};

static const std::array<std::pair<std::string, std::string>, 2> msgid_tag {{
	{"<wsa:MessageID>", "</wsa:MessageID>"},
	{"<wsa:MessageID SOAP-ENV:mustUnderstand=\"true\">", "</wsa:MessageID>"}
}};

static const std::array<std::pair<std::string, std::string>, 1> xaddrs_tag {{
	{"<wsd:XAddrs>", "</wsd:XAddrs>"}
}};

static const std::array<std::pair<std::string, std::string>, 1> address_tag {{
	{"<wsa:Address>", "</wsa:Address>"}
}};

static const std::array<std::pair<std::string, std::string>, 1> types_tag {{
	{"<wsd:Types>", "</wsd:Types>"}
}};

class CWSDiscoveryUtils
{
public:
  CWSDiscoveryUtils() = default;
  ~CWSDiscoveryUtils() = default;

  template<std::size_t SIZE>
  static const std::string wsd_tag_find(const std::string& xml, const std::array<std::pair<std::string, std::string>, SIZE>& tag);

  static void PrintWSDInfo(const wsd_req_info& info);

  // Max udp packet size (+ UDP header + IP header overhead = 65535)
  static const int UDPBUFFSIZE = 65507;

  // Port for unicast/multicast WDS traffic
  static const int wsdUDP = 3702;

  // ipv4 multicast group WSD - https://specs.xmlsoap.org/ws/2005/04/discovery/ws-discovery.pdf
  static const char* WDSMultiGroup = "239.255.255.250";

	struct wsd_req_info {
		std::string action;
		std::string msgid;
		std::string types;
		std::string address;
		std::string xaddrs;

		bool operator==(const wsd_req_info& item) const
		{
			return ((item.xaddrs == xaddrs) &&
							(item.address == address));
		}
	};

	bool equalsAddress(const wsd_req_info& lhs, const wsd_req_info& rhs)
	{
		return lhs.address == rhs.address;
	}
};
}