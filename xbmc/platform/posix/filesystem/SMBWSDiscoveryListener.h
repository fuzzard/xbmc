/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "threads/CriticalSection.h"
#include "threads/Thread.h"

class CWSDiscoveryListenerUDP : private CThread
{
public:
  CWSDiscoveryListenerUDP();
  ~CWSDiscoveryListenerUDP() override;

protected:
  void Process() override;
  void Start();
  void Stop() override;

private:
	struct Command {
		struct sockaddr_in address;
		std::string commandMsg;
	};

	bool DispatchCommand();
	void AddCommand(const std::string message, const std::string extraparameter = "");

	/*
	 * Generates a SOAP message given a particular action type
	 * in				(string) action type
	 * in/out		(char**) created message
	 * in       (string) extra data field (currently used for resolve addresses)
	 * return  	(int) size of message, -1 is failure to create a message
	 */
	int buildSoapMessage(const std::string& action, char** msg, const std::string extraparameter);

private:
  
  // Socket FD for send/recv
  int fd;
	std::vector<Command> m_commandbuffer;
	CCriticalSection crit_commandqueue;
	CCriticalSection crit_wsdqueue;

  std::vector<WSDiscoveryUtils::wsd_req_info> m_vecWSDInfo;

	static const int retries = 4;
  
  // UDP packet max recv size
  static const int UDPBUFFSIZE = 65507;

  // WDS port in/out
  static const int wsdUDP = 3702;
  // Multicast group for WSD
  static const char* WDSMultiGroup = "239.255.255.250";
};

static const char soap_msg_templ[] =
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
	"<soap:Envelope "
	"xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" "
	"xmlns:wsa=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" "
	"xmlns:wsd=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\" "
	"xmlns:wsx=\"http://schemas.xmlsoap.org/ws/2004/09/mex\" "
	"xmlns:wsdp=\"http://schemas.xmlsoap.org/ws/2006/02/devprof\" "
	"xmlns:un0=\"http://schemas.microsoft.com/windows/pnpx/2005/10\" "
	"xmlns:pub=\"http://schemas.microsoft.com/windows/pub/2005/07\">\n"
	"<soap:Header>\n"
	"<wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>\n"
	"<wsa:Action>%s</wsa:Action>\n"
	"<wsa:MessageID>urn:uuid:%s</wsa:MessageID>\n"
	"<wsd:AppSequence InstanceId=\"%lld\" SequenceId=\"urn:uuid:%s\" "
	"MessageNumber=\"%u\" />\n"
	"%s"
	"</soap:Header>\n"
	"%s"
	"</soap:Envelope>\n";
	
static const char hello_body[] =
	"<soap:Body>\n"
	"<wsd:Hello>\n"
	"<wsa:EndpointReference>\n"
	"<wsa:Address>urn:uuid:%s</wsa:Address>\n"
	"</wsa:EndpointReference>\n"
	"<wsd:Types>wsdp:Device pub:Computer</wsd:Types>\n"
	"<wsd:MetadataVersion>2</wsd:MetadataVersion>\n"
	"</wsd:Hello>\n"
	"</soap:Body>\n";

static const char bye_body[] =
	"<soap:Body>\n"
	"<wsd:Bye>\n"
	"<wsa:EndpointReference>\n"
	"<wsa:Address>urn:uuid:%s</wsa:Address>\n"
	"</wsa:EndpointReference>\n"
	"<wsd:Types>wsdp:Device pub:Computer</wsd:Types>\n"
	"<wsd:MetadataVersion>2</wsd:MetadataVersion>\n"
	"</wsd:Bye>\n"
	"</soap:Body>\n";

static const char probe_body[] =
	"<soap:Body>\n"
  "<wsd:Probe>\n"
  "<wsd:Types>wsdp:Device</wsd:Types>\n"
  "</wsd:Probe>\n"
  "</soap:Body>\n";

static const char resolve_body[] =
	"<soap:Body>\n"
	"<wsd:Resolve>\n"
	"<wsa:EndpointReference>\n"
	"<wsa:Address>"
	"%s"
	"</wsa:Address>\n"
	"</wsa:EndpointReference>\n"
	"</wsd:Resolve>\n"
	"</soap:Body>\n";
