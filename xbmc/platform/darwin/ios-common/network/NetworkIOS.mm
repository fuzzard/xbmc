/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "NetworkIOS.h"

#import "utils/StringUtils.h"
#import "utils/log.h"

#import "platform/darwin/ios-common/network/route.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <resolv.h>
#import <sys/ioctl.h>
#import <sys/socket.h>
#import <sys/sockio.h>
#import <sys/sysctl.h>

CNetworkInterfaceIOS::CNetworkInterfaceIOS(CNetworkIOS* network, std::string interfaceName)
  : m_interfaceName(interfaceName)
  , m_network(network)
{
}

CNetworkInterfaceIOS::~CNetworkInterfaceIOS() = default;

std::string CNetworkInterfaceIOS::GetInterfaceName() const
{
  return m_interfaceName;
}

bool CNetworkInterfaceIOS::IsEnabled() const
{
  struct ifreq ifr;
  strcpy(ifr.ifr_name, m_interfaceName.c_str());
  if (ioctl(m_network->GetSocket(), SIOCGIFFLAGS, &ifr) < 0)
    return false;

  return ((ifr.ifr_flags & IFF_UP) == IFF_UP);
}

bool CNetworkInterfaceIOS::IsConnected() const
{
  struct ifreq ifr;
  int zero = 0;
  memset(&ifr, 0, sizeof(struct ifreq));
  strcpy(ifr.ifr_name, m_interfaceName.c_str());
  if (ioctl(m_network->GetSocket(), SIOCGIFFLAGS, &ifr) < 0)
    return false;

  // ignore loopback
  int iRunning = ((ifr.ifr_flags & IFF_RUNNING) && (!(ifr.ifr_flags & IFF_LOOPBACK)));

  if (ioctl(m_network->GetSocket(), SIOCGIFADDR, &ifr) < 0)
    return false;

  // return only interfaces which has ip address
  return iRunning && (0 != memcmp(ifr.ifr_addr.sa_data + sizeof(short), &zero, sizeof(int)));
}

std::string CNetworkInterfaceIOS::GetMacAddress() const
{
  return "";
}

void CNetworkInterfaceIOS::GetMacAddressRaw(char rawMac[6]) const
{
  memset(&rawMac[0], 0, 6);
}

std::string CNetworkInterfaceIOS::GetCurrentIPAddress() const
{
  std::string address;
  struct ifaddrs* interfaces = nullptr;
  struct ifaddrs* temp_addr = nullptr;

  // retrieve the current interfaces - returns 0 on success
  if (getifaddrs(&interfaces) == 0)
  {
    temp_addr = interfaces;
    while (temp_addr != nullptr)
    {
      if (StringUtils::StartsWith(temp_addr->ifa_name, m_interfaceName))
      {
        // dstaddr is nullptr on the AF_INET/AF_INET6 interface that is not actually working
        if ((temp_addr->ifa_flags & (IFF_UP & IFF_RUNNING)) == (IFF_UP & IFF_RUNNING) &&
            temp_addr->ifa_dstaddr != nullptr)
        {
          switch (temp_addr->ifa_addr->sa_family)
          {
          case AF_INET:
            char str4[INET_ADDRSTRLEN];
            inet_ntop(AF_INET,
                      &((reinterpret_cast<struct sockaddr_in*>(temp_addr->ifa_addr))->sin_addr),
                      str4, INET_ADDRSTRLEN);
            address = str4;
            break;
          case AF_INET6:
            char str6[INET6_ADDRSTRLEN];
            inet_ntop(AF_INET6,
                      &((reinterpret_cast<struct sockaddr_in6*>(temp_addr->ifa_addr))->sin6_addr),
                      str6, INET6_ADDRSTRLEN);
            address = str6;
            break;
          default:
            break;
          }
        }
      }
      temp_addr = temp_addr->ifa_next;
    }
  }

  if (interfaces != nullptr)
    freeifaddrs(interfaces);

  return address;
}

std::string CNetworkInterfaceIOS::GetCurrentNetmask() const
{
  std::string address;
  struct ifaddrs* interfaces = nullptr;
  struct ifaddrs* temp_addr = nullptr;

  // retrieve the current interfaces - returns 0 on success
  if (getifaddrs(&interfaces) == 0)
  {
    temp_addr = interfaces;
    while (temp_addr != nullptr)
    {
      if (StringUtils::StartsWith(temp_addr->ifa_name, m_interfaceName))
      {
        // dstaddr is nullptr on the AF_INET/AF_INET6 interface that is not actually working
        if ((temp_addr->ifa_flags & (IFF_UP & IFF_RUNNING)) == (IFF_UP & IFF_RUNNING) &&
            temp_addr->ifa_dstaddr != nullptr)
        {
          switch (temp_addr->ifa_addr->sa_family)
          {
          case AF_INET:
            char mask4[INET_ADDRSTRLEN];
            inet_ntop(AF_INET,
                      &((reinterpret_cast<struct sockaddr_in*>(temp_addr->ifa_netmask))->sin_addr),
                      mask4, INET_ADDRSTRLEN);
            address = mask4;
            break;
          case AF_INET6:
            char mask6[INET6_ADDRSTRLEN];
            inet_ntop(
                AF_INET6,
                &((reinterpret_cast<struct sockaddr_in6*>(temp_addr->ifa_netmask))->sin6_addr),
                mask6, INET6_ADDRSTRLEN);
            address = mask6;
            break;
          default:
            break;
          }
        }
      }
      temp_addr = temp_addr->ifa_next;
    }
  }

  if (interfaces != nullptr)
    freeifaddrs(interfaces);

  return address;
}

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a)-1) | (sizeof(long) - 1))) : sizeof(long))

std::string CNetworkInterfaceIOS::GetCurrentDefaultGateway() const
{
  std::string address;

  int mib[] = {CTL_NET, PF_ROUTE, 0, 0, NET_RT_FLAGS, RTF_GATEWAY};

  int afinet_type[] = {AF_INET, AF_INET6};

  size_t needed = 0;
  char* buf;
  char* p;
  struct rt_msghdr* rt;
  struct sockaddr* sa;
  struct sockaddr* sa_tab[RTAX_MAX];

  for (int ip_type = 0; ip_type <= 1; ip_type++)
  {
    mib[3] = afinet_type[ip_type];

    if (sysctl(mib, sizeof(mib) / sizeof(int), nullptr, &needed, nullptr, 0) < 0)
    {
      CLog::Log(LOGERROR, "sysctl: net.route.0.0.dump estimate");
      return address;
    }

    if ((buf = new char[needed]) == 0)
    {
      CLog::Log(LOGERROR, "malloc(%lu)", static_cast<unsigned long>(needed));
      return address;
    }

    if (sysctl(mib, sizeof(mib) / sizeof(int), buf, &needed, nullptr, 0) < 0)
    {
      CLog::Log(LOGERROR, "sysctl: net.route.0.0.dump");
      delete[] buf;
      return address;
    }

    for (p = buf; p < buf + needed; p += rt->rtm_msglen)
    {
      rt = reinterpret_cast<struct rt_msghdr*>(p);
      sa = reinterpret_cast<struct sockaddr*>(rt + 1);
      for (int i = 0; i < RTAX_MAX; i++)
      {
        if (rt->rtm_addrs & (1 << i))
        {
          sa_tab[i] = sa;
          sa = (struct sockaddr*)((char*)sa + ROUNDUP(sa->sa_len));
        }
        else
        {
          sa_tab[i] = NULL;
        }
      }

      if (((rt->rtm_addrs & (RTA_DST | RTA_GATEWAY)) == (RTA_DST | RTA_GATEWAY)) &&
          sa_tab[RTAX_DST]->sa_family == afinet_type[ip_type] &&
          sa_tab[RTAX_GATEWAY]->sa_family == afinet_type[ip_type])
      {
        if (afinet_type[ip_type] == AF_INET)
        {
          if ((reinterpret_cast<struct sockaddr_in*>(sa_tab[RTAX_DST]))->sin_addr.s_addr == 0)
          {
            char dstStr4[INET_ADDRSTRLEN];
            char srcStr4[INET_ADDRSTRLEN];
            memcpy(srcStr4,
                   &(reinterpret_cast<struct sockaddr_in*>(sa_tab[RTAX_GATEWAY]))->sin_addr,
                   sizeof(struct in_addr));
            if (inet_ntop(AF_INET, srcStr4, dstStr4, INET_ADDRSTRLEN) != nullptr)
              address = dstStr4;
            break;
          }
        }
        else if (afinet_type[ip_type] == AF_INET6)
        {
          if ((reinterpret_cast<struct sockaddr_in*>(sa_tab[RTAX_DST]))->sin_addr.s_addr == 0)
          {
            char dstStr6[INET6_ADDRSTRLEN];
            char srcStr6[INET6_ADDRSTRLEN];
            memcpy(srcStr6,
                   &(reinterpret_cast<struct sockaddr_in6*>(sa_tab[RTAX_GATEWAY]))->sin6_addr,
                   sizeof(struct in6_addr));
            if (inet_ntop(AF_INET6, srcStr6, dstStr6, INET6_ADDRSTRLEN) != nullptr)
              address = dstStr6;
            break;
          }
        }
      }
    }
    free(buf);
  }

  return address;
}


CNetworkIOS::CNetworkIOS()
  : CNetworkBase()
{
  m_sock = socket(AF_INET, SOCK_DGRAM, 0);
  queryInterfaceList();
}

CNetworkIOS::~CNetworkIOS()
{
  if (m_sock != -1)
    close(CNetworkIOS::m_sock);

  std::vector<CNetworkInterface*>::iterator it = m_interfaces.begin();
  while (it != m_interfaces.end())
  {
    CNetworkInterface* nInt = *it;
    delete nInt;
    it = m_interfaces.erase(it);
  }
}

std::vector<CNetworkInterface*>& CNetworkIOS::GetInterfaceList()
{
  return m_interfaces;
}

CNetworkInterface* CNetworkIOS::GetFirstConnectedInterface()
{
  std::vector<CNetworkInterface*>& ifaces = GetInterfaceList();
  std::vector<CNetworkInterfaceIOS*>& iosifaces =
      reinterpret_cast<std::vector<CNetworkInterfaceIOS*>&>(ifaces);
  std::vector<CNetworkInterfaceIOS*>::const_iterator iter = iosifaces.begin();

  CNetworkInterfaceIOS* ifWifi = nullptr;
  CNetworkInterfaceIOS* ifWired = nullptr;
  CNetworkInterfaceIOS* ifCell = nullptr;
  CNetworkInterfaceIOS* ifVPN = nullptr;

  while (iter != iosifaces.end())
  {
    CNetworkInterfaceIOS* iface = *iter;
    if (iface && iface->IsConnected())
    {
      // Wifi interface
      if (StringUtils::StartsWith(iface->GetInterfaceName(), "en0"))
#if defined(TARGET_DARWIN_IOS)
        ifWifi = iface;
#elif defined(TARGET_DARWIN_TVOS)
        ifWired = iface;
      // Wired interface - TVOS
      else if (StringUtils::StartsWith(iface->GetInterfaceName(), "en1"))
        ifWifi = iface;
#endif
      // Cellular interface
      else if (StringUtils::StartsWith(iface->GetInterfaceName(), "pdp_ip"))
        ifCell = iface;
      // VPN interface
      else if (StringUtils::StartsWith(iface->GetInterfaceName(), "utun"))
        ifVPN = iface;
    }
    ++iter;
  }

  // Priority = VPN -> Wifi -> Cell
  if (ifVPN != nullptr)
    return static_cast<CNetworkInterface*>(ifVPN);
  else if (ifWired != nullptr)
    return static_cast<CNetworkInterface*>(ifWired);
  else if (ifWifi != nullptr)
    return static_cast<CNetworkInterface*>(ifWifi);
  else if (ifCell != nullptr)
    return static_cast<CNetworkInterface*>(ifCell);
  else
    return nullptr;
}

void CNetworkIOS::queryInterfaceList()
{
  m_interfaces.clear();

  struct ifaddrs* list;
  if (getifaddrs(&list) < 0)
    return;

  struct ifaddrs* cur;
  for (cur = list; cur != nullptr; cur = cur->ifa_next)
  {
    if (cur->ifa_addr->sa_family != AF_INET || (cur->ifa_flags & IFF_LOOPBACK) == IFF_LOOPBACK)
      continue;

    m_interfaces.push_back(new CNetworkInterfaceIOS(this, cur->ifa_name));
  }

  freeifaddrs(list);
}

std::vector<std::string> CNetworkIOS::GetNameServers()
{
  std::vector<std::string> nameServers;
  std::string ns;

  res_state res = static_cast<res_state>(malloc(sizeof(struct __res_state)));
  int result = res_ninit(res);

  if (result == 0)
  {
    union res_9_sockaddr_union* addr_union = static_cast<union res_9_sockaddr_union*>(
        malloc(res->nscount * sizeof(union res_9_sockaddr_union)));
    res_getservers(res, addr_union, res->nscount);

    for (int i = 0; i < res->nscount; i++)
    {
      if (addr_union[i].sin.sin_family == AF_INET)
      {
        char dstStr4[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), dstStr4, INET_ADDRSTRLEN);
        ns = dstStr4;
      }
      else if (addr_union[i].sin.sin_family == AF_INET6)
      {
        char dstStr6[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(addr_union[i].sin.sin_addr), dstStr6, INET6_ADDRSTRLEN);
        ns = dstStr6;
      }
      nameServers.push_back(ns);
    }
    free(addr_union);
  }
  else
  {
    CLog::Log(LOGERROR, "CNetworkIOS::GetNameServers - no nameservers could be fetched (error %d)",
              result);
  }

  res_ndestroy(res);
  return nameServers;
}

bool CNetworkIOS::PingHost(unsigned long remote_ip, unsigned int timeout_ms)
{
  return false;
}

bool CNetworkInterfaceIOS::GetHostMacAddress(unsigned long host_ip, std::string& mac) const
{
  return false;
}
