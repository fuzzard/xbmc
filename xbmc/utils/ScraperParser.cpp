/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "ScraperParser.h"

#include "CharsetConverter.h"
#include "HTMLUtil.h"
#include "RegExp.h"
#include "URL.h"
#include "addons/Scraper.h"
#include "guilib/LocalizeStrings.h"
#include "log.h"
#include "utils/StringUtils.h"
#include "utils/XBMCTinyXML2.h"
#ifdef HAVE_LIBXSLT
#include "utils/XSLTUtils.h"
#endif
#include "utils/XMLUtils.h"

#include <cstring>
#include <sstream>

#include <tinyxml2.h>

using namespace ADDON;
using namespace XFILE;

CScraperParser::CScraperParser()
{
  m_SearchStringEncoding = "UTF-8";
  m_scraper = NULL;
  m_isNoop = true;
}

CScraperParser::CScraperParser(const CScraperParser& parser)
{
  m_SearchStringEncoding = "UTF-8";
  m_scraper = NULL;
  m_isNoop = true;
  *this = parser;
}

CScraperParser &CScraperParser::operator=(const CScraperParser &parser)
{
  if (this != &parser)
  {
    Clear();
    if (parser.m_document)
    {
      m_scraper = parser.m_scraper;
      // store XML for further processing if window's load type is LOAD_EVERY_TIME or a reload is needed
      CXBMCTinyXML2* cloneDoc = nullptr;
      parser.m_document->DeepCopy(cloneDoc);
      m_document.reset(cloneDoc);
      LoadFromXML();
    }
    else
      m_scraper = NULL;
  }
  return *this;
}

CScraperParser::~CScraperParser()
{
  Clear();
}

void CScraperParser::Clear()
{
  m_document.reset();
  m_strFile.clear();
}

bool CScraperParser::Load(const std::string& strXMLFile)
{
  Clear();

  m_document = std::make_unique<CXBMCTinyXML2>();

  if (!m_document)
    return false;

  m_strFile = strXMLFile;

  if (m_document->LoadFile(strXMLFile.c_str()))
    return LoadFromXML();

  return false;
}

bool CScraperParser::LoadFromXML()
{
  if (!m_document)
    return false;

  auto rootElement = m_document->RootElement();
  std::string strValue = rootElement->Value();
  if (strValue == "scraper")
  {
    auto* childElement = rootElement->FirstChildElement("CreateSearchUrl");
    if (childElement)
    {
      m_isNoop = false;
      if (!(m_SearchStringEncoding = childElement->Attribute("SearchStringEncoding")))
        m_SearchStringEncoding = "UTF-8";
    }

    childElement = rootElement->FirstChildElement("CreateArtistSearchUrl");
    if (childElement)
    {
      m_isNoop = false;
      if (!(m_SearchStringEncoding = childElement->Attribute("SearchStringEncoding")))
        m_SearchStringEncoding = "UTF-8";
    }
    childElement = rootElement->FirstChildElement("CreateAlbumSearchUrl");
    if (childElement)
    {
      m_isNoop = false;
      if (!(m_SearchStringEncoding = childElement->Attribute("SearchStringEncoding")))
        m_SearchStringEncoding = "UTF-8";
    }

    return true;
  }
  return false;
}

void CScraperParser::ReplaceBuffers(std::string& strDest)
{
  // insert buffers
  size_t iIndex;
  for (int i=MAX_SCRAPER_BUFFERS-1; i>=0; i--)
  {
    iIndex = 0;
    std::string temp = StringUtils::Format("$${}", i + 1);
    while ((iIndex = strDest.find(temp,iIndex)) != std::string::npos)
    {
      strDest.replace(strDest.begin()+iIndex,strDest.begin()+iIndex+temp.size(),m_param[i]);
      iIndex += m_param[i].length();
    }
  }
  // insert settings
  iIndex = 0;
  while ((iIndex = strDest.find("$INFO[", iIndex)) != std::string::npos)
  {
    size_t iEnd = strDest.find(']', iIndex);
    std::string strInfo = strDest.substr(iIndex+6, iEnd - iIndex - 6);
    std::string strReplace;
    if (m_scraper)
      strReplace = m_scraper->GetSetting(strInfo);
    strDest.replace(strDest.begin()+iIndex,strDest.begin()+iEnd+1,strReplace);
    iIndex += strReplace.length();
  }
  // insert localize strings
  iIndex = 0;
  while ((iIndex = strDest.find("$LOCALIZE[", iIndex)) != std::string::npos)
  {
    size_t iEnd = strDest.find(']', iIndex);
    std::string strInfo = strDest.substr(iIndex+10, iEnd - iIndex - 10);
    std::string strReplace;
    if (m_scraper)
      strReplace = g_localizeStrings.GetAddonString(m_scraper->ID(), strtol(strInfo.c_str(),NULL,10));
    strDest.replace(strDest.begin()+iIndex,strDest.begin()+iEnd+1,strReplace);
    iIndex += strReplace.length();
  }
  iIndex = 0;
  while ((iIndex = strDest.find("\\n",iIndex)) != std::string::npos)
    strDest.replace(strDest.begin()+iIndex,strDest.begin()+iIndex+2,"\n");
}

void CScraperParser::ParseExpression(const std::string& input,
                                     std::string& dest,
                                     tinyxml2::XMLElement* element,
                                     bool bAppend)
{
  std::string strOutput = XMLUtils::GetAttribute(element, "output");

  auto* expressionElement = element->FirstChildElement("expression");
  if (expressionElement)
  {
    bool bInsensitive=true;
    const char* sensitive = expressionElement->Attribute("cs");
    if (sensitive)
      if (StringUtils::CompareNoCase(sensitive, "yes") == 0)
        bInsensitive=false; // match case sensitive

    CRegExp::utf8Mode eUtf8 = CRegExp::autoUtf8;
    const char* const strUtf8 = expressionElement->Attribute("utf8");
    if (strUtf8)
    {
      if (StringUtils::CompareNoCase(strUtf8, "yes") == 0)
        eUtf8 = CRegExp::forceUtf8;
      else if (StringUtils::CompareNoCase(strUtf8, "no") == 0)
        eUtf8 = CRegExp::asciiOnly;
      else if (StringUtils::CompareNoCase(strUtf8, "auto") == 0)
        eUtf8 = CRegExp::autoUtf8;
    }

    CRegExp reg(bInsensitive, eUtf8);
    std::string strExpression;
    if (expressionElement->FirstChild())
      strExpression = expressionElement->FirstChild()->Value();
    else
      strExpression = "(.*)";
    ReplaceBuffers(strExpression);
    ReplaceBuffers(strOutput);

    if (!reg.RegComp(strExpression.c_str()))
    {
      return;
    }

    bool bRepeat = false;
    const char* szRepeat = expressionElement->Attribute("repeat");
    if (szRepeat)
      if (StringUtils::CompareNoCase(szRepeat, "yes") == 0)
        bRepeat = true;

    const char* szClear = expressionElement->Attribute("clear");
    if (szClear)
      if (StringUtils::CompareNoCase(szClear, "yes") == 0)
        dest=""; // clear no matter if regexp fails

    bool bClean[MAX_SCRAPER_BUFFERS];
    GetBufferParams(bClean, expressionElement->Attribute("noclean"), true);

    bool bTrim[MAX_SCRAPER_BUFFERS];
    GetBufferParams(bTrim, expressionElement->Attribute("trim"), false);

    bool bFixChars[MAX_SCRAPER_BUFFERS];
    GetBufferParams(bFixChars, expressionElement->Attribute("fixchars"), false);

    bool bEncode[MAX_SCRAPER_BUFFERS];
    GetBufferParams(bEncode, expressionElement->Attribute("encode"), false);

    int iOptional = -1;
    expressionElement->QueryIntAttribute("optional", &iOptional);

    int iCompare = -1;
    expressionElement->QueryIntAttribute("compare", &iCompare);
    if (iCompare > -1)
      StringUtils::ToLower(m_param[iCompare-1]);
    std::string curInput = input;
    for (int iBuf=0;iBuf<MAX_SCRAPER_BUFFERS;++iBuf)
    {
      if (bClean[iBuf])
        InsertToken(strOutput,iBuf+1,"!!!CLEAN!!!");
      if (bTrim[iBuf])
        InsertToken(strOutput,iBuf+1,"!!!TRIM!!!");
      if (bFixChars[iBuf])
        InsertToken(strOutput,iBuf+1,"!!!FIXCHARS!!!");
      if (bEncode[iBuf])
        InsertToken(strOutput,iBuf+1,"!!!ENCODE!!!");
    }
    int i = reg.RegFind(curInput.c_str());
    while (i > -1 && (i < (int)curInput.size() || curInput.empty()))
    {
      if (!bAppend)
      {
        dest = "";
        bAppend = true;
      }
      std::string strCurOutput=strOutput;

      if (iOptional > -1) // check that required param is there
      {
        char temp[12];
        snprintf(temp, sizeof(temp), "\\%i", iOptional);
        std::string szParam = reg.GetReplaceString(temp);
        CRegExp reg2;
        reg2.RegComp("(.*)(\\\\\\(.*\\\\2.*)\\\\\\)(.*)");
        int i2=reg2.RegFind(strCurOutput.c_str());
        while (i2 > -1)
        {
          std::string szRemove(reg2.GetMatch(2));
          int iRemove = szRemove.size();
          int i3 = strCurOutput.find(szRemove);
          if (!szParam.empty())
          {
            strCurOutput.erase(i3+iRemove,2);
            strCurOutput.erase(i3,2);
          }
          else
            strCurOutput.replace(strCurOutput.begin()+i3,strCurOutput.begin()+i3+iRemove+2,"");

          i2 = reg2.RegFind(strCurOutput.c_str());
        }
      }

      int iLen = reg.GetFindLen();
      // nasty hack #1 - & means \0 in a replace string
      StringUtils::Replace(strCurOutput, "&","!!!AMPAMP!!!");
      std::string result = reg.GetReplaceString(strCurOutput);
      if (!result.empty())
      {
        std::string strResult(result);
        StringUtils::Replace(strResult, "!!!AMPAMP!!!","&");
        Clean(strResult);
        ReplaceBuffers(strResult);
        if (iCompare > -1)
        {
          std::string strResultNoCase = strResult;
          StringUtils::ToLower(strResultNoCase);
          if (strResultNoCase.find(m_param[iCompare-1]) != std::string::npos)
            dest += strResult;
        }
        else
          dest += strResult;
      }
      if (bRepeat && iLen > 0)
      {
        curInput.erase(0,i+iLen>(int)curInput.size()?curInput.size():i+iLen);
        i = reg.RegFind(curInput.c_str());
      }
      else
        i = -1;
    }
  }
}

void CScraperParser::ParseXSLT(const std::string& input,
                               std::string& dest,
                               tinyxml2::XMLElement* element,
                               bool bAppend)
{
#ifdef HAVE_LIBXSLT
  auto* sheet = element->FirstChildElement();
  if (sheet)
  {
    tinyxml2::XMLPrinter printer;
    XSLTUtils xsltUtils;
    sheet->Accept(&printer);
    const char* charXslt{printer.CStr()};
    std::string strXslt{charXslt};
    ReplaceBuffers(strXslt);

    if (!xsltUtils.SetInput(input))
      CLog::Log(LOGDEBUG, "could not parse input XML");

    if (!xsltUtils.SetStylesheet(strXslt))
      CLog::Log(LOGDEBUG, "could not parse stylesheet XML");

    xsltUtils.XSLTTransform(dest);
  }
#endif
}

tinyxml2::XMLElement* FirstChildScraperElement(tinyxml2::XMLElement* element)
{
  for (auto* child = element->FirstChildElement(); child; child = child->NextSiblingElement())
  {
#ifdef HAVE_LIBXSLT
    if (strcmp(child->Value(), "XSLT") == 0)
      return child;
#endif
    if (strcmp(child->Value(), "RegExp") == 0)
      return child;
  }
  return nullptr;
}

tinyxml2::XMLElement* NextSiblingScraperElement(tinyxml2::XMLElement* element)
{
  for (auto* next = element->NextSiblingElement(); next; next = next->NextSiblingElement())
  {
#ifdef HAVE_LIBXSLT
    if (strcmp(next->Value(), "XSLT") == 0)
      return next;
#endif
    if (strcmp(next->Value(), "RegExp") == 0)
      return next;
  }
  return NULL;
}

void CScraperParser::ParseNext(tinyxml2::XMLElement* element)
{
  auto* pReg = element;
  while (pReg)
  {
    auto* pChildReg = FirstChildScraperElement(pReg);
    if (pChildReg)
      ParseNext(pChildReg);
    else
    {
      auto* pChildReg = pReg->FirstChildElement("clear");
      if (pChildReg)
        ParseNext(pChildReg);
    }

    int iDest = 1;
    bool bAppend = false;
    const char* szDest = pReg->Attribute("dest");
    if (szDest && strlen(szDest))
    {
      if (szDest[strlen(szDest)-1] == '+')
        bAppend = true;

      iDest = atoi(szDest);
    }

    const char *szInput = pReg->Attribute("input");
    std::string strInput;
    if (szInput)
    {
      strInput = szInput;
      ReplaceBuffers(strInput);
    }
    else
      strInput = m_param[0];

    const char* szConditional = pReg->Attribute("conditional");
    bool bExecute = true;
    if (szConditional)
    {
      bool bInverse=false;
      if (szConditional[0] == '!')
      {
        bInverse = true;
        szConditional++;
      }
      std::string strSetting;
      if (m_scraper && m_scraper->HasSettings())
        strSetting = m_scraper->GetSetting(szConditional);
      bExecute = bInverse != (strSetting == "true");
    }

    if (bExecute)
    {
      if (iDest-1 < MAX_SCRAPER_BUFFERS && iDest-1 > -1)
      {
#ifdef HAVE_LIBXSLT
        if (strcmp(pReg->Value(), "XSLT") == 0)
          ParseXSLT(strInput, m_param[iDest - 1], pReg, bAppend);
        else
#endif
          ParseExpression(strInput, m_param[iDest - 1],pReg,bAppend);
      }
      else
        CLog::Log(LOGERROR,"CScraperParser::ParseNext: destination buffer "
                           "out of bounds, skipping expression");
    }
    pReg = NextSiblingScraperElement(pReg);
  }
}

const std::string CScraperParser::Parse(const std::string& strTag,
                                       CScraper* scraper)
{
  auto* childElement = m_document->RootElement()->FirstChildElement(strTag.c_str());
  if (!childElement)
  {
    CLog::Log(LOGERROR, "{}: Could not find scraper function {}", __FUNCTION__, strTag);
    return "";
  }
  int iResult = 1; // default to param 1
  childElement->QueryIntAttribute("dest", &iResult);
  auto* pChildStart = FirstChildScraperElement(childElement);
  m_scraper = scraper;
  ParseNext(pChildStart);
  std::string tmp = m_param[iResult-1];

  const char* szClearBuffers = childElement->Attribute("clearbuffers");
  if (!szClearBuffers || StringUtils::CompareNoCase(szClearBuffers, "no") != 0)
    ClearBuffers();

  return tmp;
}

void CScraperParser::Clean(std::string& strDirty)
{
  size_t i = 0;
  std::string strBuffer;
  while ((i = strDirty.find("!!!CLEAN!!!",i)) != std::string::npos)
  {
    size_t i2;
    if ((i2 = strDirty.find("!!!CLEAN!!!",i+11)) != std::string::npos)
    {
      strBuffer = strDirty.substr(i+11,i2-i-11);
      std::string strConverted(strBuffer);
      HTML::CHTMLUtil::RemoveTags(strConverted);
      StringUtils::Trim(strConverted);
      strDirty.replace(i, i2-i+11, strConverted);
      i += strConverted.size();
    }
    else
      break;
  }
  i=0;
  while ((i = strDirty.find("!!!TRIM!!!",i)) != std::string::npos)
  {
    size_t i2;
    if ((i2 = strDirty.find("!!!TRIM!!!",i+10)) != std::string::npos)
    {
      strBuffer = strDirty.substr(i+10,i2-i-10);
      StringUtils::Trim(strBuffer);
      strDirty.replace(i, i2-i+10, strBuffer);
      i += strBuffer.size();
    }
    else
      break;
  }
  i=0;
  while ((i = strDirty.find("!!!FIXCHARS!!!",i)) != std::string::npos)
  {
    size_t i2;
    if ((i2 = strDirty.find("!!!FIXCHARS!!!",i+14)) != std::string::npos)
    {
      strBuffer = strDirty.substr(i+14,i2-i-14);
      std::wstring wbuffer;
      g_charsetConverter.utf8ToW(strBuffer, wbuffer, false, false, false);
      std::wstring wConverted;
      HTML::CHTMLUtil::ConvertHTMLToW(wbuffer,wConverted);
      g_charsetConverter.wToUTF8(wConverted, strBuffer, false);
      StringUtils::Trim(strBuffer);
      ConvertJSON(strBuffer);
      strDirty.replace(i, i2-i+14, strBuffer);
      i += strBuffer.size();
    }
    else
      break;
  }
  i=0;
  while ((i=strDirty.find("!!!ENCODE!!!",i)) != std::string::npos)
  {
    size_t i2;
    if ((i2 = strDirty.find("!!!ENCODE!!!",i+12)) != std::string::npos)
    {
      strBuffer = CURL::Encode(strDirty.substr(i + 12, i2 - i - 12));
      strDirty.replace(i, i2-i+12, strBuffer);
      i += strBuffer.size();
    }
    else
      break;
  }
}

void CScraperParser::ConvertJSON(std::string &string)
{
  CRegExp reg;
  reg.RegComp("\\\\u([0-f]{4})");
  while (reg.RegFind(string.c_str()) > -1)
  {
    int pos = reg.GetSubStart(1);
    std::string szReplace(reg.GetMatch(1));

    std::string replace = StringUtils::Format("&#x{};", szReplace);
    string.replace(string.begin()+pos-2, string.begin()+pos+4, replace);
  }

  CRegExp reg2;
  reg2.RegComp("\\\\x([0-9]{2})([^\\\\]+;)");
  while (reg2.RegFind(string.c_str()) > -1)
  {
    int pos1 = reg2.GetSubStart(1);
    int pos2 = reg2.GetSubStart(2);
    std::string szHexValue(reg2.GetMatch(1));

    std::string replace = std::to_string(std::stol(szHexValue, NULL, 16));
    string.replace(string.begin()+pos1-2, string.begin()+pos2+reg2.GetSubLength(2), replace);
  }

  StringUtils::Replace(string, "\\\"","\"");
}

void CScraperParser::ClearBuffers()
{
  //clear all m_param strings
  for (std::string& param : m_param)
    param.clear();
}

void CScraperParser::GetBufferParams(bool* result, const char* attribute, bool defvalue)
{
  for (int iBuf=0;iBuf<MAX_SCRAPER_BUFFERS;++iBuf)
    result[iBuf] = defvalue;
  if (attribute)
  {
    std::vector<std::string> vecBufs;
    StringUtils::Tokenize(attribute,vecBufs,",");
    for (size_t nToken=0; nToken < vecBufs.size(); nToken++)
    {
      int index = atoi(vecBufs[nToken].c_str())-1;
      if (index < MAX_SCRAPER_BUFFERS)
        result[index] = !defvalue;
    }
  }
}

void CScraperParser::InsertToken(std::string& strOutput, int buf, const char* token)
{
  char temp[4];
  snprintf(temp, sizeof(temp), "\\%i", buf);
  size_t i2=0;
  while ((i2 = strOutput.find(temp,i2)) != std::string::npos)
  {
    strOutput.insert(i2,token);
    i2 += strlen(token) + strlen(temp);
    strOutput.insert(i2,token);
  }
}

void CScraperParser::AddDocument(const CXBMCTinyXML2* doc)
{
  auto* node = doc->RootElement()->FirstChild();
  auto rootElement = m_document->RootElement();
  while (node)
  {
    auto* clonedNode = node->DeepClone(reinterpret_cast<tinyxml2::XMLDocument*>(m_document.get()));
    rootElement->InsertEndChild(clonedNode);
    node = node->NextSibling();
  }
}

