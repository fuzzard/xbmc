/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "SMBWSDiscoveryListener.h"

#include "ServiceBroker.h"
#include "platform/posix/filesystem/SMBWSDiscovery.h"
#include "utils/StringUtils.h"
#include "utils/log.h"

#include <arpa/inet.h>
#include <stdio.h>
#include <sys/select.h>
#include <unistd.h>

#include <string>

using namespace WSDiscovery;

CWSDiscoveryListenerUDP::CWSDiscoveryListenerUDP() : CThread("WSDiscoveryListenerUDP")
{
}

CWSDiscoveryListenerUDP::~CWSDiscoveryListenerUDP()
{
}

void CWSDiscoveryListenerUDP::Stop()
{
  CThread::Stop(true);
}

void CWSDiscoveryListenerUDP::Start()
{
  if (!IsRunning())
  {
    CLog::Log(LOGINFO, "CWSDiscoveryListenerUDP::Start - Started");

    Create();
    SetPriority(GetMinPriority());
  }
}

void CWSDiscoveryListenerUDP::Process()
{
  fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (fd < 0)
  {
    // socket error
    return;
  }

  // set socket reuse
  int enable = 1;
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (char*) &enable, sizeof(enable)) < 0)
  {
    // setsockopt - reuse error
    return;
  }

  // set up destination address
  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(wsdUDP);

  // bind to receive address
  if (bind(fd, (struct sockaddr*) &addr, sizeof(addr)) < 0) 
  {
    // bind error
    return;
  }

  // use setsockopt() to request join a multicast group on all interfaces
  // maybe use firstconnected?
  struct ip_mreq mreq;
  mreq.imr_multiaddr.s_addr = inet_addr(WDSMultiGroup);
  mreq.imr_interface.s_addr = htonl(INADDR_ANY);
  if (setsockopt(fd, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char*) &mreq, sizeof(mreq)) < 0)
  {
    // setsockopt - membership error
    return;
  }

  // Disable receiving broadcast messages on loopback
  // So we dont receive messages we send.
  if (setsockopt(fd, IPPROTO_IP, IP_MULTICAST_LOOP, (char*)&disable, sizeof(disable)) < 0)
  {
		// setsockopt - disable loopback error
		return 1;
  }

  std::string bufferoutput;

  fd_set rset;
  int nready;

  FD_ZERO(&rset);

  // Send HELLO to the world
	AddCommand(WSD_ACT_HELLO);
	DispatchCommand();

	AddCommand(WSD_ACT_PROBE);
	DispatchCommand();


	while (!m_bstop)
	{
	  FD_SET(fd, &rset);
	  nready = select((fd + 1), &rset, NULL, NULL, NULL);

		// if udp socket is readable receive the message.
		if (FD_ISSET(fd, &rset))
		{
      bufferoutput = "";
  		char msgbuf[UDPBUFFSIZE];
	  	unsigned int addrlen = sizeof(addr);
		  int nbytes = recvfrom(fd, msgbuf, UDPBUFFSIZE, 0, (struct sockaddr*)&addr, &addrlen);
		  msgbuf[nbytes] = '\0';
			// turn msgbuf into std::string
			bufferoutput.append(msgbuf, nbytes);

			ParseBuffer(bufferoutput);
		}
    // Action any commands queued
		while(DispatchCommand()) {}
	}

  // Be a nice citizen and send BYE to the world
	AddCommand(WSD_ACT_BYE);
	DispatchCommand();

  return;
}

bool CWSDiscoveryListenerUDP::DispatchCommand()
{
  Command sendCommand;
  {
    CSingleLock lock(crit_commandqueue);
    if (m_commandbuffer.size() <= 0)
      return false;

    auto it = m_commandbuffer.begin();
    sendCommand = *it;
    m_commandbuffer.erase(it);
  }

  int ret;

  // As its udp, devices seem to send multiple messages
  // Windows seems to send 4-6 times for reference
  for (int i = 0; i < retries; i++)
  {  
		do
		{
			ret = sendto(fd, sendCommand.commandMsg.c_str(), sendCommand.commandMsg.size(), 0, (struct sockaddr*)& sendCommand.address, sizeof(sendCommand.address));
		}
		while (ret == -1 && !m_bstop);
    CThread::Sleep(1000ms);
	}
  
  CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::DispatchCommand - Command sent");

  return true;
}

void CWSDiscoveryListenerUDP::AddCommand(const std::string message, const std::string extraparameter /* = "" */)
{

  CSingleLock lock(crit_commandqueue);

  char* msg = nullptr;
  int size = buildSoapMessage(message, &msg, extraparameter);
  if (size < 0)
  {
    CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::AddCommand - Invalid Soap Message");
    return;
  }

  std::string fullmsg {msg};
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(wsdUDP);
  
  // maybe look to have inet_addr(XX) as argument
  addr.sin_addr.s_addr = inet_addr(WDSMultiGroup);;
  memset(&addr.sin_zero, 0, sizeof(addr.sin_zero));

  Command newCommand {{addr}, {fullmsg}};

  m_commandbuffer.push_back(newCommand);
}

void CWSDiscoveryListenerUDP::ParseBuffer(const std::string& buffer)
{
  // MUST have an action tag
  std::string action = CWSDiscoveryUtils::wsd_tag_find(buffer, action_tag);
  if (action.empty())
  {
    CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::ParseBuffer - No Action tag found");
		return;
	}

  // Only actions we wish to handle when received
  if (!((action == WSD_ACT_HELLO) ||
       (action == WSD_ACT_BYE) ||
       (action == WSD_ACT_RESOLVEMATCHES) ||
       (action == WSD_ACT_PROBEMATCH)))
  {
    CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::ParseBuffer - Action not supported");
    return;
  }

  // MUST have a msgid tag
	std::string msgid = CWSDiscoveryUtils::wsd_tag_find(buffer, msgid_tag);
  if (msgid.empty())
  {
    CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::ParseBuffer - No msgid tag found");
		return;
	}

	std::string types = CWSDiscoveryUtils::wsd_tag_find(buffer, types_tag);
	std::string address = CWSDiscoveryUtils::wsd_tag_find(buffer, address_tag);
	std::string xaddrs = CWSDiscoveryUtils::wsd_tag_find(buffer, xaddrs_tag);

	if (xaddrs.empty() && (action != WSD_ACT_BYE))
	{
	  // Do a resolve against address
	  AddCommand(WSD_ACT_RESOLVE, address);
	  // Discard this message
	  return;
	}

  wsd_req_info info;

	info.action = action;
	info.msgid = msgid;
	info.xaddrs = xaddrs;
	info.types = types;
	info.address = address;

  {
    CSingleLock lock(crit_wsdqueue);
		auto searchitem = std::find_if(m_vecWSDInfo.begin(),
																	 m_vecWSDInfo.end(),
																	 [info](const wsd_req_info& item)
																					{return item == info;});
	
		if (searchitem == m_vecWSDInfo.end())
		{
			if (info.action != WSD_ACT_BYE)
			{
				CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::ParseBuffer - Actionable message");
				m_vecWSDInfo.emplace_back(info);
				CServiceBroker::GetWSDiscovery()->SetItems(m_vecWSDInfo);
				CWSDiscoveryUtils::PrintWSDInfo(info);
				return;
			}
			else
			{
				// WSD_ACT_BYE does not include an xaddrs tag
				// We only want to match the address when receiving a WSD_ACT_BYE message
				auto searchbye = std::find_if(m_vecWSDInfo.begin(),
																			m_vecWSDInfo.end(),
																			[info](const wsd_req_info& item)
																						{return equalsAddress(item, info);});
				if(searchbye != m_vecWSDInfo.end())
				{
					m_vecWSDInfo.erase(searchbye);
  				CServiceBroker::GetWSDiscovery()->SetItems(m_vecWSDInfo);
					return;
				}
			}
    }
	}

  // Only duplicate items get this far, silently drop
  return;
}

int CWSDiscoveryListenerUDP::buildSoapMessage(const std::string& action, char** msg, const std::string extraparameter)
{
  auto msg_uuid = StringUtils::CreateUUID();
  char* body;
  std::string relatesTo;
  int bodylen = 0;
  int messagenumber = 0;

  if (action == WSD_ACT_HELLO)
  {
		bodylen = asprintf(&body, hello_body, msg_uuid.c_str());
  }
  else if (action == WSD_ACT_BYE)
  {
		bodylen = asprintf(&body, bye_body, msg_uuid.c_str());
  }
  else if (action == WSD_ACT_PROBE)
  {
		bodylen = asprintf(&body, probe_body);
  }
  else if (action == WSD_ACT_RESOLVE)
  {
		bodylen = asprintf(&body, resolve_body, extraparameter.c_str());
  }
  else
  {
    // May lead to excessive logspam
		//CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::buildSoapMessage unimplemented WSD_ACTION");
		return -1;
  }

  if (bodylen == -1)
  {
    CLog::Log(LOGDEBUG,"CWSDiscoveryListenerUDP::buildSoapMessage body message failure");
    return -1;
  }
  // Todo: Look to use fmt instead of the asprintf usage
  
  int size = asprintf(msg, soap_msg_templ, action.c_str(), msg_uuid.c_str(),
                  wsd_instance_id, msg_uuid.c_str(), messagenumber, relatesTo.c_str(),
                  body);

  return size;
}