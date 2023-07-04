/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "GUIControlFactory.h"

#include "GUIAction.h"
#include "GUIBorderedImage.h"
#include "GUIButtonControl.h"
#include "GUIColorButtonControl.h"
#include "GUIColorManager.h"
#include "GUIControlGroup.h"
#include "GUIControlGroupList.h"
#include "GUIEditControl.h"
#include "GUIFadeLabelControl.h"
#include "GUIFixedListContainer.h"
#include "GUIFontManager.h"
#include "GUIImage.h"
#include "GUIInfoManager.h"
#include "GUILabelControl.h"
#include "GUIListContainer.h"
#include "GUIListGroup.h"
#include "GUIListLabel.h"
#include "GUIMoverControl.h"
#include "GUIMultiImage.h"
#include "GUIPanelContainer.h"
#include "GUIProgressControl.h"
#include "GUIRSSControl.h"
#include "GUIRadioButtonControl.h"
#include "GUIRangesControl.h"
#include "GUIRenderingControl.h"
#include "GUIResizeControl.h"
#include "GUIScrollBarControl.h"
#include "GUISettingsSliderControl.h"
#include "GUISliderControl.h"
#include "GUISpinControl.h"
#include "GUISpinControlEx.h"
#include "GUITextBox.h"
#include "GUIToggleButtonControl.h"
#include "GUIVideoControl.h"
#include "GUIVisualisationControl.h"
#include "GUIWrappingListContainer.h"
#include "LocalizeStrings.h"
#include "addons/Skin.h"
#include "cores/RetroPlayer/guicontrols/GUIGameControl.h"
#include "games/controllers/guicontrols/GUIGameController.h"
#include "input/Key.h"
#include "pvr/guilib/GUIEPGGridContainer.h"
#include "utils/CharsetConverter.h"
#include "utils/RssManager.h"
#include "utils/StringUtils.h"
#include "utils/XMLUtils.h"
#include "utils/log.h"

#include <tinyxml2.h>

using namespace KODI;
using namespace KODI::GUILIB;
using namespace PVR;

typedef struct
{
  const char* name;
  CGUIControl::GUICONTROLTYPES type;
} ControlMapping;

static const ControlMapping controls[] = {
    {"button", CGUIControl::GUICONTROL_BUTTON},
    {"colorbutton", CGUIControl::GUICONTROL_COLORBUTTON},
    {"edit", CGUIControl::GUICONTROL_EDIT},
    {"epggrid", CGUIControl::GUICONTAINER_EPGGRID},
    {"fadelabel", CGUIControl::GUICONTROL_FADELABEL},
    {"fixedlist", CGUIControl::GUICONTAINER_FIXEDLIST},
    {"gamecontroller", CGUIControl::GUICONTROL_GAMECONTROLLER},
    {"gamewindow", CGUIControl::GUICONTROL_GAME},
    {"group", CGUIControl::GUICONTROL_GROUP},
    {"group", CGUIControl::GUICONTROL_LISTGROUP},
    {"grouplist", CGUIControl::GUICONTROL_GROUPLIST},
    {"image", CGUIControl::GUICONTROL_IMAGE},
    {"image", CGUIControl::GUICONTROL_BORDEREDIMAGE},
    {"label", CGUIControl::GUICONTROL_LABEL},
    {"label", CGUIControl::GUICONTROL_LISTLABEL},
    {"list", CGUIControl::GUICONTAINER_LIST},
    {"mover", CGUIControl::GUICONTROL_MOVER},
    {"multiimage", CGUIControl::GUICONTROL_MULTI_IMAGE},
    {"panel", CGUIControl::GUICONTAINER_PANEL},
    {"progress", CGUIControl::GUICONTROL_PROGRESS},
    {"radiobutton", CGUIControl::GUICONTROL_RADIO},
    {"ranges", CGUIControl::GUICONTROL_RANGES},
    {"renderaddon", CGUIControl::GUICONTROL_RENDERADDON},
    {"resize", CGUIControl::GUICONTROL_RESIZE},
    {"rss", CGUIControl::GUICONTROL_RSS},
    {"scrollbar", CGUIControl::GUICONTROL_SCROLLBAR},
    {"slider", CGUIControl::GUICONTROL_SLIDER},
    {"sliderex", CGUIControl::GUICONTROL_SETTINGS_SLIDER},
    {"spincontrol", CGUIControl::GUICONTROL_SPIN},
    {"spincontrolex", CGUIControl::GUICONTROL_SPINEX},
    {"textbox", CGUIControl::GUICONTROL_TEXTBOX},
    {"togglebutton", CGUIControl::GUICONTROL_TOGGLEBUTTON},
    {"videowindow", CGUIControl::GUICONTROL_VIDEO},
    {"visualisation", CGUIControl::GUICONTROL_VISUALISATION},
    {"wraplist", CGUIControl::GUICONTAINER_WRAPLIST},
};

CGUIControl::GUICONTROLTYPES CGUIControlFactory::TranslateControlType(const std::string &type)
{
  for (const ControlMapping& control : controls)
    if (StringUtils::EqualsNoCase(type, control.name))
      return control.type;
  return CGUIControl::GUICONTROL_UNKNOWN;
}

std::string CGUIControlFactory::TranslateControlType(CGUIControl::GUICONTROLTYPES type)
{
  for (const ControlMapping& control : controls)
    if (type == control.type)
      return control.name;
  return "";
}

CGUIControlFactory::CGUIControlFactory(void) = default;

CGUIControlFactory::~CGUIControlFactory(void) = default;

bool CGUIControlFactory::GetIntRange(const tinyxml2::XMLNode* rootNode,
                                     const char* strTag,
                                     int& iMinValue,
                                     int& iMaxValue,
                                     int& iIntervalValue)
{
  const auto* node = rootNode->FirstChildElement(strTag);
  if (!node || !node->FirstChild())
    return false;
  iMinValue = atoi(node->FirstChild()->Value());
  const char* maxValue = strchr(node->FirstChild()->Value(), ',');
  if (maxValue)
  {
    maxValue++;
    iMaxValue = atoi(maxValue);

    const char* intervalValue = strchr(maxValue, ',');
    if (intervalValue)
    {
      intervalValue++;
      iIntervalValue = atoi(intervalValue);
    }
  }

  return true;
}

bool CGUIControlFactory::GetFloatRange(const tinyxml2::XMLNode* rootNode,
                                       const char* strTag,
                                       float& fMinValue,
                                       float& fMaxValue,
                                       float& fIntervalValue)
{
  const auto* node = rootNode->FirstChildElement(strTag);
  if (!node || !node->FirstChild())
    return false;
  fMinValue = (float)atof(node->FirstChild()->Value());
  const char* maxValue = strchr(node->FirstChild()->Value(), ',');
  if (maxValue)
  {
    maxValue++;
    fMaxValue = (float)atof(maxValue);

    const char* intervalValue = strchr(maxValue, ',');
    if (intervalValue)
    {
      intervalValue++;
      fIntervalValue = (float)atof(intervalValue);
    }
  }

  return true;
}

float CGUIControlFactory::ParsePosition(const char* pos, const float parentSize)
{
  char* end = NULL;
  float value = pos ? (float)strtod(pos, &end) : 0;
  if (end)
  {
    if (*end == 'r')
      value = parentSize - value;
    else if (*end == '%')
      value = value * parentSize / 100.0f;
  }
  return value;
}

bool CGUIControlFactory::GetPosition(const tinyxml2::XMLNode* node,
                                     const char* strTag,
                                     const float parentSize,
                                     float& value)
{
  const auto* element = node->FirstChildElement(strTag);
  if (!element || !element->FirstChild())
    return false;

  value = ParsePosition(element->FirstChild()->Value(), parentSize);
  return true;
}

bool CGUIControlFactory::GetDimension(const tinyxml2::XMLNode* rootNode,
                                      const char* strTag,
                                      const float parentSize,
                                      float& value,
                                      float& min)
{
  const auto* element = rootNode->FirstChildElement(strTag);
  if (!element || !element->FirstChild())
    return false;
  if (0 == StringUtils::CompareNoCase("auto", element->FirstChild()->Value(), 4))
  { // auto-width - at least min must be set
    value = ParsePosition(element->Attribute("max"), parentSize);
    min = ParsePosition(element->Attribute("min"), parentSize);
    if (!min) min = 1;
    return true;
  }
  value = ParsePosition(element->FirstChild()->Value(), parentSize);
  return true;
}

bool CGUIControlFactory::GetDimensions(const tinyxml2::XMLNode* node,
                                       const char* leftTag,
                                       const char* rightTag,
                                       const char* centerLeftTag,
                                       const char* centerRightTag,
                                       const char* widthTag,
                                       const float parentSize,
                                       float& left,
                                       float& width,
                                       float& min_width)
{
  float center = 0, right = 0;

  // read from the XML
  bool hasLeft = GetPosition(node, leftTag, parentSize, left);
  bool hasCenter = GetPosition(node, centerLeftTag, parentSize, center);
  if (!hasCenter && GetPosition(node, centerRightTag, parentSize, center))
  {
    center = parentSize - center;
    hasCenter = true;
  }
  bool hasRight = false;
  if (GetPosition(node, rightTag, parentSize, right))
  {
    right = parentSize - right;
    hasRight = true;
  }
  bool hasWidth = GetDimension(node, widthTag, parentSize, width, min_width);

  if (!hasLeft)
  { // figure out position
    if (hasCenter) // no left specified
    {
      if (hasWidth)
      {
        left = center - width/2;
        hasLeft = true;
      }
      else
      {
        if (hasRight)
        {
          width = (right - center) * 2;
          left = right - width;
          hasLeft = true;
        }
      }
    }
    else if (hasRight) // no left or centre
    {
      if (hasWidth)
      {
        left = right - width;
        hasLeft = true;
      }
    }
  }
  if (!hasWidth)
  {
    if (hasRight)
    {
      width = std::max(0.0f, right - left); // if left=0, this fills to size of parent
      hasLeft = true;
      hasWidth = true;
    }
    else if (hasCenter)
    {
      if (hasLeft)
      {
        width = std::max(0.0f, (center - left) * 2);
        hasWidth = true;
      }
      else if (center > 0 && center < parentSize)
      { // centre given, so fill to edge of parent
        width = std::max(0.0f, std::min(parentSize - center, center) * 2);
        left = center - width/2;
        hasLeft = true;
        hasWidth = true;
      }
    }
    else if (hasLeft) // neither right nor center specified
    {
      width = std::max(0.0f, parentSize - left); // if left=0, this fills to parent
      hasWidth = true;
    }
  }
  return hasLeft && hasWidth;
}

bool CGUIControlFactory::GetAspectRatio(const tinyxml2::XMLNode* rootNode,
                                        const char* strTag,
                                        CAspectRatio& aspect)
{
  std::string ratio;
  const auto* node = rootNode->FirstChildElement(strTag);
  if (!node || !node->FirstChild())
    return false;

  ratio = node->FirstChild()->Value();
  if (StringUtils::EqualsNoCase(ratio, "keep")) aspect.ratio = CAspectRatio::AR_KEEP;
  else if (StringUtils::EqualsNoCase(ratio, "scale")) aspect.ratio = CAspectRatio::AR_SCALE;
  else if (StringUtils::EqualsNoCase(ratio, "center")) aspect.ratio = CAspectRatio::AR_CENTER;
  else if (StringUtils::EqualsNoCase(ratio, "stretch")) aspect.ratio = CAspectRatio::AR_STRETCH;

  const char *attribute = node->Attribute("align");
  if (attribute)
  {
    std::string align(attribute);
    if (StringUtils::EqualsNoCase(align, "center")) aspect.align = ASPECT_ALIGN_CENTER | (aspect.align & ASPECT_ALIGNY_MASK);
    else if (StringUtils::EqualsNoCase(align, "right")) aspect.align = ASPECT_ALIGN_RIGHT | (aspect.align & ASPECT_ALIGNY_MASK);
    else if (StringUtils::EqualsNoCase(align, "left")) aspect.align = ASPECT_ALIGN_LEFT | (aspect.align & ASPECT_ALIGNY_MASK);
  }
  attribute = node->Attribute("aligny");
  if (attribute)
  {
    std::string align(attribute);
    if (StringUtils::EqualsNoCase(align, "center")) aspect.align = ASPECT_ALIGNY_CENTER | (aspect.align & ASPECT_ALIGN_MASK);
    else if (StringUtils::EqualsNoCase(align, "bottom")) aspect.align = ASPECT_ALIGNY_BOTTOM | (aspect.align & ASPECT_ALIGN_MASK);
    else if (StringUtils::EqualsNoCase(align, "top")) aspect.align = ASPECT_ALIGNY_TOP | (aspect.align & ASPECT_ALIGN_MASK);
  }
  attribute = node->Attribute("scalediffuse");
  if (attribute)
  {
    std::string scale(attribute);
    if (StringUtils::EqualsNoCase(scale, "true") || StringUtils::EqualsNoCase(scale, "yes"))
      aspect.scaleDiffuse = true;
    else
      aspect.scaleDiffuse = false;
  }
  return true;
}

bool CGUIControlFactory::GetInfoTexture(const tinyxml2::XMLNode* rootNode,
                                        const char* strTag,
                                        CTextureInfo& image,
                                        GUIINFO::CGUIInfoLabel& info,
                                        int parentID)
{
  GetTexture(rootNode, strTag, image);
  image.filename = "";
  GetInfoLabel(rootNode, strTag, info, parentID);
  return true;
}

bool CGUIControlFactory::GetTexture(const tinyxml2::XMLNode* rootNode,
                                    const char* strTag,
                                    CTextureInfo& image)
{
  const auto* element = rootNode->FirstChildElement(strTag);
  if (!element)
    return false;
  const char* border = element->Attribute("border");
  if (border)
  {
    GetRectFromString(border, image.border);
    const char* borderinfill = element->Attribute("infill");
    image.m_infill = (!borderinfill || !StringUtils::EqualsNoCase(borderinfill, "false"));
  }
  image.orientation = 0;
  const char* flipX = element->Attribute("flipx");
  if (flipX && StringUtils::CompareNoCase(flipX, "true") == 0)
    image.orientation = 1;
  const char* flipY = element->Attribute("flipy");
  if (flipY && StringUtils::CompareNoCase(flipY, "true") == 0)
    image.orientation = 3 - image.orientation; // either 3 or 2
  image.diffuse = XMLUtils::GetAttribute(element, "diffuse");
  image.diffuseColor.Parse(XMLUtils::GetAttribute(element, "colordiffuse"), 0);
  const char* background = element->Attribute("background");
  if (background && StringUtils::CompareNoCase(background, "true", 4) == 0)
    image.useLarge = true;
  image.filename = element->FirstChild() ? element->FirstChild()->Value() : "";
  return true;
}

void CGUIControlFactory::GetRectFromString(const std::string &string, CRect &rect)
{
  // format is rect="left[,top,right,bottom]"
  std::vector<std::string> strRect = StringUtils::Split(string, ',');
  if (strRect.size() == 1)
  {
    rect.x1 = (float)atof(strRect[0].c_str());
    rect.y1 = rect.x1;
    rect.x2 = rect.x1;
    rect.y2 = rect.x1;
  }
  else if (strRect.size() == 4)
  {
    rect.x1 = (float)atof(strRect[0].c_str());
    rect.y1 = (float)atof(strRect[1].c_str());
    rect.x2 = (float)atof(strRect[2].c_str());
    rect.y2 = (float)atof(strRect[3].c_str());
  }
}

bool CGUIControlFactory::GetAlignment(const tinyxml2::XMLNode* rootNode,
                                      const char* strTag,
                                      uint32_t& alignment)
{
  const auto* element = rootNode->FirstChildElement(strTag);
  if (!element || !element->FirstChild())
    return false;

  std::string strAlign = element->FirstChild()->Value();
  if (strAlign == "right" || strAlign == "bottom") alignment = XBFONT_RIGHT;
  else if (strAlign == "center") alignment = XBFONT_CENTER_X;
  else if (strAlign == "justify") alignment = XBFONT_JUSTIFIED;
  else alignment = XBFONT_LEFT;
  return true;
}

bool CGUIControlFactory::GetAlignmentY(const tinyxml2::XMLNode* rootNode,
                                       const char* strTag,
                                       uint32_t& alignment)
{
  const auto* element = rootNode->FirstChildElement(strTag);
  if (!element || !element->FirstChild())
  {
    return false;
  }

  std::string strAlign = element->FirstChild()->Value();

  alignment = 0;
  if (strAlign == "center")
  {
    alignment = XBFONT_CENTER_Y;
  }

  return true;
}

bool CGUIControlFactory::GetConditionalVisibility(const tinyxml2::XMLNode* control,
                                                  std::string& condition,
                                                  std::string& allowHiddenFocus)
{
  const auto* node = control->FirstChildElement("visible");
  if (!node) return false;
  std::vector<std::string> conditions;
  while (node)
  {
    const char *hidden = node->Attribute("allowhiddenfocus");
    if (hidden)
      allowHiddenFocus = hidden;
    // add to our condition string
    if (!node->NoChildren())
      conditions.emplace_back(node->FirstChild()->Value());
    node = node->NextSiblingElement("visible");
  }
  if (!conditions.size())
    return false;
  if (conditions.size() == 1)
    condition = conditions[0];
  else
  { // multiple conditions should be anded together
    condition = "[";
    for (unsigned int i = 0; i < conditions.size() - 1; i++)
      condition += conditions[i] + "] + [";
    condition += conditions[conditions.size() - 1] + "]";
  }
  return true;
}

bool CGUIControlFactory::GetConditionalVisibility(const tinyxml2::XMLNode* control,
                                                  std::string& condition)
{
  std::string allowHiddenFocus;
  return GetConditionalVisibility(control, condition, allowHiddenFocus);
}

bool CGUIControlFactory::GetAnimations(tinyxml2::XMLNode* control,
                                       const CRect& rect,
                                       int context,
                                       std::vector<CAnimation>& animations)
{
  auto* node = control->FirstChildElement("animation");
  bool ret = false;
  if (node)
    animations.clear();
  auto doc = control->GetDocument();
  while (node)
  {
    ret = true;
    if (node->FirstChild())
    {
      CAnimation anim;
      anim.Create(node, rect, context);
      animations.push_back(anim);
      if (StringUtils::CompareNoCase(node->FirstChild()->Value(), "VisibleChange") == 0)
      { // add the hidden one as well

        auto* hidden = doc->NewElement("hidden");
        const char* start = hidden->Attribute("start");
        const char* end = hidden->Attribute("end");
        if (start && end)
        {
          hidden->SetAttribute("end", start);
          hidden->SetAttribute("start", end);
        }
        else if (start)
          hidden->SetAttribute("end", start);
        else if (end)
          hidden->SetAttribute("start", end);
        CAnimation anim2;
        anim2.Create(hidden, rect, context);
        animations.push_back(anim2);
      }
    }
    node = node->NextSiblingElement("animation");
  }
  return ret;
}

bool CGUIControlFactory::GetActions(const tinyxml2::XMLNode* node,
                                    const char* strTag,
                                    CGUIAction& actions)
{
  actions.Reset();
  const auto* element = node->FirstChildElement(strTag);
  while (element)
  {
    if (element->FirstChild())
    {
      actions.Append(
          {XMLUtils::GetAttribute(element, "condition"), element->FirstChild()->Value()});
    }
    element = element->NextSiblingElement(strTag);
  }
  return actions.HasAnyActions();
}

bool CGUIControlFactory::GetHitRect(const tinyxml2::XMLNode* control,
                                    CRect& rect,
                                    const CRect& parentRect)
{
  const auto* node = control->FirstChildElement("hitrect");
  if (node)
  {
    rect.x1 = ParsePosition(node->Attribute("x"), parentRect.Width());
    rect.y1 = ParsePosition(node->Attribute("y"), parentRect.Height());
    if (node->Attribute("w"))
      rect.x2 = (float)atof(node->Attribute("w")) + rect.x1;
    else if (node->Attribute("right"))
      rect.x2 = std::min(ParsePosition(node->Attribute("right"), parentRect.Width()), rect.x1);
    if (node->Attribute("h"))
      rect.y2 = (float)atof(node->Attribute("h")) + rect.y1;
    else if (node->Attribute("bottom"))
      rect.y2 = std::min(ParsePosition(node->Attribute("bottom"), parentRect.Height()), rect.y1);
    return true;
  }
  return false;
}

bool CGUIControlFactory::GetScroller(const tinyxml2::XMLNode* control,
                                     const std::string& scrollerTag,
                                     CScroller& scroller)
{
  const auto* node = control->FirstChildElement(scrollerTag.c_str());
  if (node)
  {
    unsigned int scrollTime;
    if (XMLUtils::GetUInt(control, scrollerTag.c_str(), scrollTime))
    {
      scroller = CScroller(scrollTime, CAnimEffect::GetTweener(node));
      return true;
    }
  }
  return false;
}

bool CGUIControlFactory::GetColor(const tinyxml2::XMLNode* control,
                                  const char* strTag,
                                  UTILS::COLOR::Color& value)
{
  const auto* node = control->FirstChildElement(strTag);
  if (node && node->FirstChild())
  {
    value = CServiceBroker::GetGUI()->GetColorManager().GetColor(node->FirstChild()->Value());
    return true;
  }
  return false;
}

bool CGUIControlFactory::GetInfoColor(const tinyxml2::XMLNode* control,
                                      const char* strTag,
                                      GUIINFO::CGUIInfoColor& value,
                                      int parentID)
{
  const auto* node = control->FirstChildElement(strTag);
  if (node && node->FirstChild())
  {
    value.Parse(node->FirstChild()->Value(), parentID);
    return true;
  }
  return false;
}

void CGUIControlFactory::GetInfoLabel(const tinyxml2::XMLNode* controlNode,
                                      const std::string& labelTag,
                                      GUIINFO::CGUIInfoLabel& infoLabel,
                                      int parentID)
{
  std::vector<GUIINFO::CGUIInfoLabel> labels;
  GetInfoLabels(controlNode, labelTag, labels, parentID);
  if (labels.size())
    infoLabel = labels[0];
}

bool CGUIControlFactory::GetInfoLabelFromElement(const tinyxml2::XMLElement* element,
                                                 GUIINFO::CGUIInfoLabel& infoLabel,
                                                 int parentID)
{
  if (!element || !element->FirstChild())
    return false;

  std::string label = element->FirstChild()->Value();
  if (label.empty())
    return false;

  std::string fallback = XMLUtils::GetAttribute(element, "fallback");
  if (StringUtils::IsNaturalNumber(label))
    label = g_localizeStrings.Get(atoi(label.c_str()));
  if (StringUtils::IsNaturalNumber(fallback))
    fallback = g_localizeStrings.Get(atoi(fallback.c_str()));
  else
    g_charsetConverter.unknownToUTF8(fallback);
  infoLabel.SetLabel(label, fallback, parentID);
  return true;
}

void CGUIControlFactory::GetInfoLabels(const tinyxml2::XMLNode* controlNode,
                                       const std::string& labelTag,
                                       std::vector<GUIINFO::CGUIInfoLabel>& infoLabels,
                                       int parentID)
{
  // we can have the following infolabels:
  // 1.  <number>1234</number> -> direct number
  // 2.  <label>number</label> -> lookup in localizestrings
  // 3.  <label fallback="blah">$LOCALIZE(blah) $INFO(blah)</label> -> infolabel with given fallback
  // 4.  <info>ListItem.Album</info> (uses <label> as fallback)
  int labelNumber = 0;
  if (XMLUtils::GetInt(controlNode, "number", labelNumber))
  {
    std::string label = std::to_string(labelNumber);
    infoLabels.emplace_back(label);
    return; // done
  }
  const auto* labelNode = controlNode->FirstChildElement(labelTag.c_str());
  while (labelNode)
  {
    GUIINFO::CGUIInfoLabel label;
    if (GetInfoLabelFromElement(labelNode, label, parentID))
      infoLabels.push_back(label);
    labelNode = labelNode->NextSiblingElement(labelTag.c_str());
  }
  auto* infoNode = controlNode->FirstChildElement("info");
  if (infoNode)
  { // <info> nodes override <label>'s (backward compatibility)
    std::string fallback;
    if (infoLabels.size())
      fallback = infoLabels[0].GetLabel(0);
    infoLabels.clear();
    while (infoNode)
    {
      if (infoNode->FirstChild())
      {
        std::string info = StringUtils::Format("$INFO[{}]", infoNode->FirstChild()->Value());
        infoLabels.emplace_back(info, fallback, parentID);
      }
      infoNode = infoNode->NextSiblingElement("info");
    }
  }
}

// Convert a string to a GUI label, by translating/parsing the label for localisable strings
std::string CGUIControlFactory::FilterLabel(const std::string &label)
{
  std::string viewLabel = label;
  if (StringUtils::IsNaturalNumber(viewLabel))
    viewLabel = g_localizeStrings.Get(atoi(label.c_str()));
  else
    g_charsetConverter.unknownToUTF8(viewLabel);
  return viewLabel;
}

bool CGUIControlFactory::GetString(const tinyxml2::XMLNode* rootNode,
                                   const char* strTag,
                                   std::string& text)
{
  if (!XMLUtils::GetString(rootNode, strTag, text))
    return false;
  if (StringUtils::IsNaturalNumber(text))
    text = g_localizeStrings.Get(atoi(text.c_str()));
  return true;
}

std::string CGUIControlFactory::GetType(const tinyxml2::XMLElement* controlNode)
{
  std::string type = XMLUtils::GetAttribute(controlNode, "type");
  if (type.empty())  // backward compatibility - not desired
    XMLUtils::GetString(controlNode, "type", type);
  return type;
}

bool CGUIControlFactory::GetMovingSpeedConfig(const tinyxml2::XMLNode* rootNode,
                                              const char* strTag,
                                              UTILS::MOVING_SPEED::MapEventConfig& movingSpeedCfg)
{
  const auto* msNode = rootNode->FirstChildElement(strTag);
  if (!msNode)
    return false;

  float globalAccel{StringUtils::ToFloat(XMLUtils::GetAttribute(msNode, "acceleration"))};
  float globalMaxVel{StringUtils::ToFloat(XMLUtils::GetAttribute(msNode, "maxvelocity"))};
  uint32_t globalResetTimeout{
      StringUtils::ToUint32(XMLUtils::GetAttribute(msNode, "resettimeout"))};
  float globalDelta{StringUtils::ToFloat(XMLUtils::GetAttribute(msNode, "delta"))};

  const auto* configElement{msNode->FirstChildElement("eventconfig")};
  while (configElement)
  {
    const char* eventType = configElement->Attribute("type");
    if (!eventType)
    {
      CLog::LogF(LOGERROR, "Failed to parse XML \"eventconfig\" tag missing \"type\" attribute");
      continue;
    }

    const char* accelerationStr{configElement->Attribute("acceleration")};
    float acceleration = accelerationStr ? StringUtils::ToFloat(accelerationStr) : globalAccel;

    const char* maxVelocityStr{configElement->Attribute("maxvelocity")};
    float maxVelocity = maxVelocityStr ? StringUtils::ToFloat(maxVelocityStr) : globalMaxVel;

    const char* resetTimeoutStr{configElement->Attribute("resettimeout")};
    uint32_t resetTimeout =
        resetTimeoutStr ? StringUtils::ToUint32(resetTimeoutStr) : globalResetTimeout;

    const char* deltaStr{configElement->Attribute("delta")};
    float delta = deltaStr ? StringUtils::ToFloat(deltaStr) : globalDelta;

    UTILS::MOVING_SPEED::EventCfg eventCfg{acceleration, maxVelocity, resetTimeout, delta};
    movingSpeedCfg.emplace(UTILS::MOVING_SPEED::ParseEventType(eventType), eventCfg);

    configElement = configElement->NextSiblingElement("eventconfig");
  }
  return true;
}

CGUIControl* CGUIControlFactory::Create(int parentID,
                                        const CRect& rect,
                                        tinyxml2::XMLElement* controlNode,
                                        bool insideContainer)
{
  // get the control type
  std::string strType = GetType(controlNode);
  CGUIControl::GUICONTROLTYPES type = TranslateControlType(strType);

  int id = 0;
  float posX = 0, posY = 0;
  float width = 0, height = 0;
  float minHeight = 0, minWidth = 0;

  CGUIControl::ActionMap actions;

  int pageControl = 0;
  GUIINFO::CGUIInfoColor colorDiffuse(0xFFFFFFFF);
  GUIINFO::CGUIInfoColor colorBox(0xFF000000);
  int defaultControl = 0;
  bool  defaultAlways = false;
  std::string strTmp;
  int singleInfo = 0;
  int singleInfo2 = 0;
  std::string strLabel;
  int iUrlSet=0;
  std::string toggleSelect;

  float spinWidth = 16;
  float spinHeight = 16;
  float spinPosX = 0, spinPosY = 0;
  std::string strSubType;
  int iType = SPIN_CONTROL_TYPE_TEXT;
  int iMin = 0;
  int iMax = 100;
  int iInterval = 1;
  float fMin = 0.0f;
  float fMax = 1.0f;
  float fInterval = 0.1f;
  bool bReverse = true;
  bool bReveal = false;
  CTextureInfo textureBackground, textureLeft, textureRight, textureMid, textureOverlay;
  CTextureInfo textureNib, textureNibFocus, textureNibDisabled, textureBar, textureBarFocus,
      textureBarDisabled;
  CTextureInfo textureUp, textureDown;
  CTextureInfo textureUpFocus, textureDownFocus;
  CTextureInfo textureUpDisabled, textureDownDisabled;
  CTextureInfo texture, borderTexture;
  GUIINFO::CGUIInfoLabel textureFile;
  CTextureInfo textureFocus, textureNoFocus;
  CTextureInfo textureAltFocus, textureAltNoFocus;
  CTextureInfo textureRadioOnFocus, textureRadioOnNoFocus;
  CTextureInfo textureRadioOffFocus, textureRadioOffNoFocus;
  CTextureInfo textureRadioOnDisabled, textureRadioOffDisabled;
  CTextureInfo textureProgressIndicator;
  CTextureInfo textureColorMask, textureColorDisabledMask;

  GUIINFO::CGUIInfoLabel texturePath;
  CRect borderSize;

  float sliderWidth = 150, sliderHeight = 16;
  CPoint offset;

  bool bHasPath = false;
  CGUIAction clickActions;
  CGUIAction altclickActions;
  CGUIAction focusActions;
  CGUIAction unfocusActions;
  CGUIAction textChangeActions;
  std::string strTitle = "";
  std::string strRSSTags = "";

  float buttonGap = 5;
  int iMovementRange = 0;
  CAspectRatio aspect;
  std::string allowHiddenFocus;
  std::string enableCondition;

  std::vector<CAnimation> animations;

  CGUIControl::GUISCROLLVALUE scrollValue = CGUIControl::FOCUS;
  bool bPulse = true;
  unsigned int timePerImage = 0;
  unsigned int fadeTime = 0;
  unsigned int timeToPauseAtEnd = 0;
  bool randomized = false;
  bool loop = true;
  bool wrapMultiLine = false;
  ORIENTATION orientation = VERTICAL;
  bool showOnePage = true;
  bool scrollOut = true;
  int preloadItems = 0;

  CLabelInfo labelInfo, labelInfoMono;

  GUIINFO::CGUIInfoColor hitColor(0xFFFFFFFF);
  GUIINFO::CGUIInfoColor textColor3;
  GUIINFO::CGUIInfoColor headlineColor;

  float radioWidth = 0;
  float radioHeight = 0;
  float radioPosX = 0;
  float radioPosY = 0;

  float colorWidth = 0;
  float colorHeight = 0;
  float colorPosX = 0;
  float colorPosY = 0;

  std::string altLabel;
  std::string strLabel2;
  std::string action;

  int focusPosition = 0;
  int scrollTime = 200;
  int timeBlocks = 36;
  int rulerUnit = 12;
  bool useControlCoords = false;
  bool renderFocusedLast = false;

  CRect hitRect;
  CPoint camera;
  float stereo = 0.f;
  bool   hasCamera = false;
  bool resetOnLabelChange = true;
  bool bPassword = false;
  std::string visibleCondition;

  UTILS::MOVING_SPEED::MapEventConfig movingSpeedCfg;

  /////////////////////////////////////////////////////////////////////////////
  // Read control properties from XML
  //

  if (!controlNode->Attribute("id"))
    XMLUtils::GetInt(controlNode, "id", id); // backward compatibility - not desired
  //! @todo Perhaps we should check here whether id is valid for focusable controls
  //! such as buttons etc.  For labels/fadelabels/images it does not matter

  GetAlignment(controlNode, "align", labelInfo.align);
  if (!GetDimensions(controlNode, "left", "right", "centerleft", "centerright", "width",
                     rect.Width(), posX, width, minWidth))
  { // didn't get 2 dimensions, so test for old <posx> as well
    if (GetPosition(controlNode, "posx", rect.Width(), posX))
    { // <posx> available, so use it along with any hacks we used to support
      if (!insideContainer &&
          type == CGUIControl::GUICONTROL_LABEL &&
          (labelInfo.align & XBFONT_RIGHT))
        posX -= width;
    }
    if (!width) // no width specified, so compute from parent
      width = std::max(rect.Width() - posX, 0.0f);
  }
  if (!GetDimensions(controlNode, "top", "bottom", "centertop", "centerbottom", "height",
                     rect.Height(), posY, height, minHeight))
  {
    GetPosition(controlNode, "posy", rect.Height(), posY);
    if (!height)
      height = std::max(rect.Height() - posY, 0.0f);
  }

  XMLUtils::GetFloat(controlNode, "offsetx", offset.x);
  XMLUtils::GetFloat(controlNode, "offsety", offset.y);

  hitRect.SetRect(posX, posY, posX + width, posY + height);
  GetHitRect(controlNode, hitRect, rect);

  GetInfoColor(controlNode, "hitrectcolor", hitColor, parentID);

  GetActions(controlNode, "onup", actions[ACTION_MOVE_UP]);
  GetActions(controlNode, "ondown", actions[ACTION_MOVE_DOWN]);
  GetActions(controlNode, "onleft", actions[ACTION_MOVE_LEFT]);
  GetActions(controlNode, "onright", actions[ACTION_MOVE_RIGHT]);
  GetActions(controlNode, "onnext", actions[ACTION_NEXT_CONTROL]);
  GetActions(controlNode, "onprev", actions[ACTION_PREV_CONTROL]);
  GetActions(controlNode, "onback", actions[ACTION_NAV_BACK]);
  GetActions(controlNode, "oninfo", actions[ACTION_SHOW_INFO]);

  if (XMLUtils::GetInt(controlNode, "defaultcontrol", defaultControl))
  {
    const char* always = controlNode->FirstChildElement("defaultcontrol")->Attribute("always");
    if (always && StringUtils::CompareNoCase(always, "true", 4) == 0)
      defaultAlways = true;
  }
  XMLUtils::GetInt(controlNode, "pagecontrol", pageControl);

  GetInfoColor(controlNode, "colordiffuse", colorDiffuse, parentID);
  GetInfoColor(controlNode, "colorbox", colorBox, parentID);

  GetConditionalVisibility(controlNode, visibleCondition, allowHiddenFocus);
  XMLUtils::GetString(controlNode, "enable", enableCondition);

  CRect animRect(posX, posY, posX + width, posY + height);
  GetAnimations(controlNode, animRect, parentID, animations);

  GetInfoColor(controlNode, "textcolor", labelInfo.textColor, parentID);
  GetInfoColor(controlNode, "focusedcolor", labelInfo.focusedColor, parentID);
  GetInfoColor(controlNode, "disabledcolor", labelInfo.disabledColor, parentID);
  GetInfoColor(controlNode, "shadowcolor", labelInfo.shadowColor, parentID);
  GetInfoColor(controlNode, "selectedcolor", labelInfo.selectedColor, parentID);
  GetInfoColor(controlNode, "invalidcolor", labelInfo.invalidColor, parentID);
  XMLUtils::GetFloat(controlNode, "textoffsetx", labelInfo.offsetX);
  XMLUtils::GetFloat(controlNode, "textoffsety", labelInfo.offsetY);
  int angle = 0;  // use the negative angle to compensate for our vertically flipped cartesian plane
  if (XMLUtils::GetInt(controlNode, "angle", angle))
    labelInfo.angle = (float)-angle;
  std::string strFont, strMonoFont;
  if (XMLUtils::GetString(controlNode, "font", strFont))
    labelInfo.font = g_fontManager.GetFont(strFont);
  XMLUtils::GetString(controlNode, "monofont", strMonoFont);
  uint32_t alignY = 0;
  if (GetAlignmentY(controlNode, "aligny", alignY))
    labelInfo.align |= alignY;
  if (XMLUtils::GetFloat(controlNode, "textwidth", labelInfo.width))
    labelInfo.align |= XBFONT_TRUNCATED;

  GetActions(controlNode, "onclick", clickActions);
  GetActions(controlNode, "ontextchange", textChangeActions);
  GetActions(controlNode, "onfocus", focusActions);
  GetActions(controlNode, "onunfocus", unfocusActions);
  focusActions.EnableSendThreadMessageMode();
  unfocusActions.EnableSendThreadMessageMode();
  GetActions(controlNode, "altclick", altclickActions);

  std::string infoString;
  if (XMLUtils::GetString(controlNode, "info", infoString))
    singleInfo = CServiceBroker::GetGUI()->GetInfoManager().TranslateString(infoString);
  if (XMLUtils::GetString(controlNode, "info2", infoString))
    singleInfo2 = CServiceBroker::GetGUI()->GetInfoManager().TranslateString(infoString);

  GetTexture(controlNode, "texturefocus", textureFocus);
  GetTexture(controlNode, "texturenofocus", textureNoFocus);
  GetTexture(controlNode, "alttexturefocus", textureAltFocus);
  GetTexture(controlNode, "alttexturenofocus", textureAltNoFocus);

  XMLUtils::GetString(controlNode, "usealttexture", toggleSelect);
  XMLUtils::GetString(controlNode, "selected", toggleSelect);

  XMLUtils::GetBoolean(controlNode, "haspath", bHasPath);

  GetTexture(controlNode, "textureup", textureUp);
  GetTexture(controlNode, "texturedown", textureDown);
  GetTexture(controlNode, "textureupfocus", textureUpFocus);
  GetTexture(controlNode, "texturedownfocus", textureDownFocus);
  GetTexture(controlNode, "textureupdisabled", textureUpDisabled);
  GetTexture(controlNode, "texturedowndisabled", textureDownDisabled);

  XMLUtils::GetFloat(controlNode, "spinwidth", spinWidth);
  XMLUtils::GetFloat(controlNode, "spinheight", spinHeight);
  XMLUtils::GetFloat(controlNode, "spinposx", spinPosX);
  XMLUtils::GetFloat(controlNode, "spinposy", spinPosY);

  XMLUtils::GetFloat(controlNode, "sliderwidth", sliderWidth);
  XMLUtils::GetFloat(controlNode, "sliderheight", sliderHeight);
  if (!GetTexture(controlNode, "textureradioonfocus", textureRadioOnFocus) ||
      !GetTexture(controlNode, "textureradioonnofocus", textureRadioOnNoFocus))
  {
    GetTexture(controlNode, "textureradiofocus", textureRadioOnFocus); // backward compatibility
    GetTexture(controlNode, "textureradioon", textureRadioOnFocus);
    textureRadioOnNoFocus = textureRadioOnFocus;
  }
  if (!GetTexture(controlNode, "textureradioofffocus", textureRadioOffFocus) ||
      !GetTexture(controlNode, "textureradiooffnofocus", textureRadioOffNoFocus))
  {
    GetTexture(controlNode, "textureradionofocus", textureRadioOffFocus); // backward compatibility
    GetTexture(controlNode, "textureradiooff", textureRadioOffFocus);
    textureRadioOffNoFocus = textureRadioOffFocus;
  }
  GetTexture(controlNode, "textureradioondisabled", textureRadioOnDisabled);
  GetTexture(controlNode, "textureradiooffdisabled", textureRadioOffDisabled);
  GetTexture(controlNode, "texturesliderbackground", textureBackground);
  GetTexture(controlNode, "texturesliderbar", textureBar);
  GetTexture(controlNode, "texturesliderbarfocus", textureBarFocus);
  if (!GetTexture(controlNode, "texturesliderbardisabled", textureBarDisabled))
    GetTexture(controlNode, "texturesliderbar", textureBarDisabled); // backward compatibility
  GetTexture(controlNode, "textureslidernib", textureNib);
  GetTexture(controlNode, "textureslidernibfocus", textureNibFocus);
  if (!GetTexture(controlNode, "textureslidernibdisabled", textureNibDisabled))
    GetTexture(controlNode, "textureslidernib", textureNibDisabled); // backward compatibility

  GetTexture(controlNode, "texturecolormask", textureColorMask);
  GetTexture(controlNode, "texturecolordisabledmask", textureColorDisabledMask);

  XMLUtils::GetString(controlNode, "title", strTitle);
  XMLUtils::GetString(controlNode, "tagset", strRSSTags);
  GetInfoColor(controlNode, "headlinecolor", headlineColor, parentID);
  GetInfoColor(controlNode, "titlecolor", textColor3, parentID);

  if (XMLUtils::GetString(controlNode, "subtype", strSubType))
  {
    StringUtils::ToLower(strSubType);

    if ( strSubType == "int")
      iType = SPIN_CONTROL_TYPE_INT;
    else if ( strSubType == "page")
      iType = SPIN_CONTROL_TYPE_PAGE;
    else if ( strSubType == "float")
      iType = SPIN_CONTROL_TYPE_FLOAT;
    else
      iType = SPIN_CONTROL_TYPE_TEXT;
  }

  if (!GetIntRange(controlNode, "range", iMin, iMax, iInterval))
  {
    GetFloatRange(controlNode, "range", fMin, fMax, fInterval);
  }

  XMLUtils::GetBoolean(controlNode, "reverse", bReverse);
  XMLUtils::GetBoolean(controlNode, "reveal", bReveal);

  GetTexture(controlNode, "texturebg", textureBackground);
  GetTexture(controlNode, "lefttexture", textureLeft);
  GetTexture(controlNode, "midtexture", textureMid);
  GetTexture(controlNode, "righttexture", textureRight);
  GetTexture(controlNode, "overlaytexture", textureOverlay);

  // the <texture> tag can be overridden by the <info> tag
  GetInfoTexture(controlNode, "texture", texture, textureFile, parentID);

  GetTexture(controlNode, "bordertexture", borderTexture);

  // fade label can have a whole bunch, but most just have one
  std::vector<GUIINFO::CGUIInfoLabel> infoLabels;
  GetInfoLabels(controlNode, "label", infoLabels, parentID);

  GetString(controlNode, "label", strLabel);
  GetString(controlNode, "altlabel", altLabel);
  GetString(controlNode, "label2", strLabel2);

  XMLUtils::GetBoolean(controlNode, "wrapmultiline", wrapMultiLine);
  XMLUtils::GetInt(controlNode, "urlset", iUrlSet);

  if (XMLUtils::GetString(controlNode, "orientation", strTmp))
  {
    StringUtils::ToLower(strTmp);
    if (strTmp == "horizontal")
      orientation = HORIZONTAL;
  }
  XMLUtils::GetFloat(controlNode, "itemgap", buttonGap);
  XMLUtils::GetInt(controlNode, "movement", iMovementRange);
  GetAspectRatio(controlNode, "aspectratio", aspect);

  bool alwaysScroll;
  if (XMLUtils::GetBoolean(controlNode, "scroll", alwaysScroll))
    scrollValue = alwaysScroll ? CGUIControl::ALWAYS : CGUIControl::NEVER;

  XMLUtils::GetBoolean(controlNode, "pulseonselect", bPulse);
  XMLUtils::GetInt(controlNode, "timeblocks", timeBlocks);
  XMLUtils::GetInt(controlNode, "rulerunit", rulerUnit);
  GetTexture(controlNode, "progresstexture", textureProgressIndicator);

  GetInfoTexture(controlNode, "imagepath", texture, texturePath, parentID);

  XMLUtils::GetUInt(controlNode, "timeperimage", timePerImage);
  XMLUtils::GetUInt(controlNode, "fadetime", fadeTime);
  XMLUtils::GetUInt(controlNode, "pauseatend", timeToPauseAtEnd);
  XMLUtils::GetBoolean(controlNode, "randomize", randomized);
  XMLUtils::GetBoolean(controlNode, "loop", loop);
  XMLUtils::GetBoolean(controlNode, "scrollout", scrollOut);

  XMLUtils::GetFloat(controlNode, "radiowidth", radioWidth);
  XMLUtils::GetFloat(controlNode, "radioheight", radioHeight);
  XMLUtils::GetFloat(controlNode, "radioposx", radioPosX);
  XMLUtils::GetFloat(controlNode, "radioposy", radioPosY);

  XMLUtils::GetFloat(controlNode, "colorwidth", colorWidth);
  XMLUtils::GetFloat(controlNode, "colorheight", colorHeight);
  XMLUtils::GetFloat(controlNode, "colorposx", colorPosX);
  XMLUtils::GetFloat(controlNode, "colorposy", colorPosY);

  std::string borderStr;
  if (XMLUtils::GetString(controlNode, "bordersize", borderStr))
    GetRectFromString(borderStr, borderSize);

  XMLUtils::GetBoolean(controlNode, "showonepage", showOnePage);
  XMLUtils::GetInt(controlNode, "focusposition", focusPosition);
  XMLUtils::GetInt(controlNode, "scrolltime", scrollTime);
  XMLUtils::GetInt(controlNode, "preloaditems", preloadItems, 0, 2);

  XMLUtils::GetBoolean(controlNode, "usecontrolcoords", useControlCoords);
  XMLUtils::GetBoolean(controlNode, "renderfocusedlast", renderFocusedLast);
  XMLUtils::GetBoolean(controlNode, "resetonlabelchange", resetOnLabelChange);

  XMLUtils::GetBoolean(controlNode, "password", bPassword);

  // view type
  VIEW_TYPE viewType = VIEW_TYPE_NONE;
  std::string viewLabel;
  if (type == CGUIControl::GUICONTAINER_PANEL)
  {
    viewType = VIEW_TYPE_ICON;
    viewLabel = g_localizeStrings.Get(536);
  }
  else if (type == CGUIControl::GUICONTAINER_LIST)
  {
    viewType = VIEW_TYPE_LIST;
    viewLabel = g_localizeStrings.Get(535);
  }
  else
  {
    viewType = VIEW_TYPE_WRAP;
    viewLabel = g_localizeStrings.Get(541);
  }
  auto* itemElement = controlNode->FirstChildElement("viewtype");
  if (itemElement && itemElement->FirstChild())
  {
    std::string type = itemElement->FirstChild()->Value();
    if (type == "list")
      viewType = VIEW_TYPE_LIST;
    else if (type == "icon")
      viewType = VIEW_TYPE_ICON;
    else if (type == "biglist")
      viewType = VIEW_TYPE_BIG_LIST;
    else if (type == "bigicon")
      viewType = VIEW_TYPE_BIG_ICON;
    else if (type == "wide")
      viewType = VIEW_TYPE_WIDE;
    else if (type == "bigwide")
      viewType = VIEW_TYPE_BIG_WIDE;
    else if (type == "wrap")
      viewType = VIEW_TYPE_WRAP;
    else if (type == "bigwrap")
      viewType = VIEW_TYPE_BIG_WRAP;
    else if (type == "info")
      viewType = VIEW_TYPE_INFO;
    else if (type == "biginfo")
      viewType = VIEW_TYPE_BIG_INFO;
    const char *label = itemElement->Attribute("label");
    if (label)
      viewLabel = GUIINFO::CGUIInfoLabel::GetLabel(FilterLabel(label), INFO::DEFAULT_CONTEXT);
  }

  auto* cam = controlNode->FirstChildElement("camera");
  if (cam)
  {
    hasCamera = true;
    camera.x = ParsePosition(cam->Attribute("x"), width);
    camera.y = ParsePosition(cam->Attribute("y"), height);
  }

  if (XMLUtils::GetFloat(controlNode, "depth", stereo))
    stereo = std::max(-1.f, std::min(1.f, stereo));

  XMLUtils::GetInt(controlNode, "scrollspeed", labelInfo.scrollSpeed);

  GetString(controlNode, "scrollsuffix", labelInfo.scrollSuffix);

  XMLUtils::GetString(controlNode, "action", action);

  GetMovingSpeedConfig(controlNode, "movingspeed", movingSpeedCfg);

  /////////////////////////////////////////////////////////////////////////////
  // Instantiate a new control using the properties gathered above
  //

  CGUIControl *control = NULL;
  switch (type)
  {
  case CGUIControl::GUICONTROL_GROUP:
    {
      if (insideContainer)
      {
        control = new CGUIListGroup(parentID, id, posX, posY, width, height);
      }
      else
      {
        control = new CGUIControlGroup(
          parentID, id, posX, posY, width, height);
        static_cast<CGUIControlGroup*>(control)->SetDefaultControl(defaultControl, defaultAlways);
        static_cast<CGUIControlGroup*>(control)->SetRenderFocusedLast(renderFocusedLast);
      }
    }
    break;
  case CGUIControl::GUICONTROL_GROUPLIST:
    {
      CScroller scroller;
      GetScroller(controlNode, "scrolltime", scroller);

      control = new CGUIControlGroupList(
        parentID, id, posX, posY, width, height, buttonGap, pageControl, orientation, useControlCoords, labelInfo.align, scroller);
      static_cast<CGUIControlGroup*>(control)->SetDefaultControl(defaultControl, defaultAlways);
      static_cast<CGUIControlGroup*>(control)->SetRenderFocusedLast(renderFocusedLast);
      static_cast<CGUIControlGroupList*>(control)->SetMinSize(minWidth, minHeight);
    }
    break;
  case CGUIControl::GUICONTROL_LABEL:
    {
      static const GUIINFO::CGUIInfoLabel empty;
      const GUIINFO::CGUIInfoLabel& content = !infoLabels.empty() ? infoLabels[0] : empty;
      if (insideContainer)
      { // inside lists we use CGUIListLabel
        control = new CGUIListLabel(parentID, id, posX, posY, width, height, labelInfo, content, scrollValue);
      }
      else
      {
        control = new CGUILabelControl(
          parentID, id, posX, posY, width, height,
          labelInfo, wrapMultiLine, bHasPath);
        static_cast<CGUILabelControl*>(control)->SetInfo(content);
        static_cast<CGUILabelControl*>(control)->SetWidthControl(minWidth, (scrollValue == CGUIControl::ALWAYS));
      }
    }
    break;
  case CGUIControl::GUICONTROL_EDIT:
    {
      control = new CGUIEditControl(
        parentID, id, posX, posY, width, height, textureFocus, textureNoFocus,
        labelInfo, strLabel);

      GUIINFO::CGUIInfoLabel hint_text;
      GetInfoLabel(controlNode, "hinttext", hint_text, parentID);
      static_cast<CGUIEditControl*>(control)->SetHint(hint_text);

      if (bPassword)
        static_cast<CGUIEditControl*>(control)->SetInputType(CGUIEditControl::INPUT_TYPE_PASSWORD, 0);
      static_cast<CGUIEditControl*>(control)->SetTextChangeActions(textChangeActions);
    }
    break;
  case CGUIControl::GUICONTROL_VIDEO:
    {
      control = new CGUIVideoControl(
        parentID, id, posX, posY, width, height);
    }
    break;
  case CGUIControl::GUICONTROL_GAME:
    {
      control = new RETRO::CGUIGameControl(parentID, id, posX, posY, width, height);

      GUIINFO::CGUIInfoLabel videoFilter;
      GetInfoLabel(controlNode, "videofilter", videoFilter, parentID);
      static_cast<RETRO::CGUIGameControl*>(control)->SetVideoFilter(videoFilter);

      GUIINFO::CGUIInfoLabel stretchMode;
      GetInfoLabel(controlNode, "stretchmode", stretchMode, parentID);
      static_cast<RETRO::CGUIGameControl*>(control)->SetStretchMode(stretchMode);

      GUIINFO::CGUIInfoLabel rotation;
      GetInfoLabel(controlNode, "rotation", rotation, parentID);
      static_cast<RETRO::CGUIGameControl*>(control)->SetRotation(rotation);

      GUIINFO::CGUIInfoLabel pixels;
      GetInfoLabel(controlNode, "pixels", pixels, parentID);
      static_cast<RETRO::CGUIGameControl*>(control)->SetPixels(pixels);
    }
    break;
  case CGUIControl::GUICONTROL_FADELABEL:
    {
      control = new CGUIFadeLabelControl(
        parentID, id, posX, posY, width, height,
        labelInfo, scrollOut, timeToPauseAtEnd, resetOnLabelChange, randomized);

      static_cast<CGUIFadeLabelControl*>(control)->SetInfo(infoLabels);

      // check whether or not a scroll tag was specified.
      if (scrollValue != CGUIControl::FOCUS)
        static_cast<CGUIFadeLabelControl*>(control)->SetScrolling(scrollValue == CGUIControl::ALWAYS);
    }
    break;
  case CGUIControl::GUICONTROL_RSS:
    {
      control = new CGUIRSSControl(
        parentID, id, posX, posY, width, height,
        labelInfo, textColor3, headlineColor, strRSSTags);
      RssUrls::const_iterator iter = CRssManager::GetInstance().GetUrls().find(iUrlSet);
      if (iter != CRssManager::GetInstance().GetUrls().end())
        static_cast<CGUIRSSControl*>(control)->SetUrlSet(iUrlSet);
    }
    break;
  case CGUIControl::GUICONTROL_BUTTON:
    {
      control = new CGUIButtonControl(
        parentID, id, posX, posY, width, height,
        textureFocus, textureNoFocus,
        labelInfo, wrapMultiLine);

      CGUIButtonControl* bcontrol = static_cast<CGUIButtonControl*>(control);
      bcontrol->SetLabel(strLabel);
      bcontrol->SetLabel2(strLabel2);
      bcontrol->SetMinWidth(minWidth);
      bcontrol->SetClickActions(clickActions);
      bcontrol->SetFocusActions(focusActions);
      bcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTROL_TOGGLEBUTTON:
    {
      control = new CGUIToggleButtonControl(
        parentID, id, posX, posY, width, height,
        textureFocus, textureNoFocus,
        textureAltFocus, textureAltNoFocus,
        labelInfo, wrapMultiLine);

      CGUIToggleButtonControl* tcontrol = static_cast<CGUIToggleButtonControl*>(control);
      tcontrol->SetLabel(strLabel);
      tcontrol->SetAltLabel(altLabel);
      tcontrol->SetMinWidth(minWidth);
      tcontrol->SetClickActions(clickActions);
      tcontrol->SetAltClickActions(altclickActions);
      tcontrol->SetFocusActions(focusActions);
      tcontrol->SetUnFocusActions(unfocusActions);
      tcontrol->SetToggleSelect(toggleSelect);
    }
    break;
  case CGUIControl::GUICONTROL_RADIO:
    {
      control = new CGUIRadioButtonControl(
        parentID, id, posX, posY, width, height,
        textureFocus, textureNoFocus,
        labelInfo,
        textureRadioOnFocus, textureRadioOnNoFocus, textureRadioOffFocus, textureRadioOffNoFocus, textureRadioOnDisabled, textureRadioOffDisabled);

      CGUIRadioButtonControl* rcontrol = static_cast<CGUIRadioButtonControl*>(control);
      rcontrol->SetLabel(strLabel);
      rcontrol->SetLabel2(strLabel2);
      rcontrol->SetRadioDimensions(radioPosX, radioPosY, radioWidth, radioHeight);
      rcontrol->SetToggleSelect(toggleSelect);
      rcontrol->SetClickActions(clickActions);
      rcontrol->SetFocusActions(focusActions);
      rcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTROL_SPIN:
    {
      control = new CGUISpinControl(
        parentID, id, posX, posY, width, height,
        textureUp, textureDown, textureUpFocus, textureDownFocus,
        textureUpDisabled, textureDownDisabled,
        labelInfo, iType);

      CGUISpinControl* scontrol = static_cast<CGUISpinControl*>(control);
      scontrol->SetReverse(bReverse);

      if (iType == SPIN_CONTROL_TYPE_INT)
      {
        scontrol->SetRange(iMin, iMax);
      }
      else if (iType == SPIN_CONTROL_TYPE_PAGE)
      {
        scontrol->SetRange(iMin, iMax);
        scontrol->SetShowRange(true);
        scontrol->SetReverse(false);
        scontrol->SetShowOnePage(showOnePage);
      }
      else if (iType == SPIN_CONTROL_TYPE_FLOAT)
      {
        scontrol->SetFloatRange(fMin, fMax);
        scontrol->SetFloatInterval(fInterval);
      }
    }
    break;
  case CGUIControl::GUICONTROL_SLIDER:
    {
      control = new CGUISliderControl(
          parentID, id, posX, posY, width, height, textureBar, textureBarDisabled, textureNib,
          textureNibFocus, textureNibDisabled, SLIDER_CONTROL_TYPE_PERCENTAGE, orientation);

      static_cast<CGUISliderControl*>(control)->SetInfo(singleInfo);
      static_cast<CGUISliderControl*>(control)->SetAction(action);
    }
    break;
  case CGUIControl::GUICONTROL_SETTINGS_SLIDER:
    {
      control = new CGUISettingsSliderControl(
          parentID, id, posX, posY, width, height, sliderWidth, sliderHeight, textureFocus,
          textureNoFocus, textureBar, textureBarDisabled, textureNib, textureNibFocus,
          textureNibDisabled, labelInfo, SLIDER_CONTROL_TYPE_PERCENTAGE);

      static_cast<CGUISettingsSliderControl*>(control)->SetText(strLabel);
      static_cast<CGUISettingsSliderControl*>(control)->SetInfo(singleInfo);
    }
    break;
  case CGUIControl::GUICONTROL_SCROLLBAR:
    {
      control = new GUIScrollBarControl(
        parentID, id, posX, posY, width, height,
        textureBackground, textureBar, textureBarFocus, textureNib, textureNibFocus, orientation, showOnePage);
    }
    break;
  case CGUIControl::GUICONTROL_PROGRESS:
    {
      control = new CGUIProgressControl(
        parentID, id, posX, posY, width, height,
        textureBackground, textureLeft, textureMid, textureRight,
        textureOverlay, bReveal);

      static_cast<CGUIProgressControl*>(control)->SetInfo(singleInfo, singleInfo2);
    }
    break;
  case CGUIControl::GUICONTROL_RANGES:
    {
      control = new CGUIRangesControl(
        parentID, id, posX, posY, width, height,
        textureBackground, textureLeft, textureMid, textureRight,
        textureOverlay, singleInfo);
    }
    break;
  case CGUIControl::GUICONTROL_IMAGE:
    {
      // use a bordered texture if we have <bordersize> or <bordertexture> specified.
      if (borderTexture.filename.empty() && borderStr.empty())
        control = new CGUIImage(
          parentID, id, posX, posY, width, height, texture);
      else
        control = new CGUIBorderedImage(
          parentID, id, posX, posY, width, height, texture, borderTexture, borderSize);
      CGUIImage* icontrol = static_cast<CGUIImage*>(control);
      icontrol->SetInfo(textureFile);
      icontrol->SetAspectRatio(aspect);
      icontrol->SetCrossFade(fadeTime);
    }
    break;
  case CGUIControl::GUICONTROL_MULTI_IMAGE:
    {
      control = new CGUIMultiImage(
        parentID, id, posX, posY, width, height, texture, timePerImage, fadeTime, randomized, loop, timeToPauseAtEnd);
      static_cast<CGUIMultiImage*>(control)->SetInfo(texturePath);
      static_cast<CGUIMultiImage*>(control)->SetAspectRatio(aspect);
    }
    break;
  case CGUIControl::GUICONTAINER_LIST:
    {
      CScroller scroller;
      GetScroller(controlNode, "scrolltime", scroller);

      control = new CGUIListContainer(parentID, id, posX, posY, width, height, orientation, scroller, preloadItems);
      CGUIListContainer* lcontrol = static_cast<CGUIListContainer*>(control);
      lcontrol->LoadLayout(controlNode);
      lcontrol->LoadListProvider(controlNode, defaultControl, defaultAlways);
      lcontrol->SetType(viewType, viewLabel);
      lcontrol->SetPageControl(pageControl);
      lcontrol->SetRenderOffset(offset);
      lcontrol->SetAutoScrolling(controlNode);
      lcontrol->SetClickActions(clickActions);
      lcontrol->SetFocusActions(focusActions);
      lcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTAINER_WRAPLIST:
    {
      CScroller scroller;
      GetScroller(controlNode, "scrolltime", scroller);

      control = new CGUIWrappingListContainer(parentID, id, posX, posY, width, height, orientation, scroller, preloadItems, focusPosition);
      CGUIWrappingListContainer* wcontrol = static_cast<CGUIWrappingListContainer*>(control);
      wcontrol->LoadLayout(controlNode);
      wcontrol->LoadListProvider(controlNode, defaultControl, defaultAlways);
      wcontrol->SetType(viewType, viewLabel);
      wcontrol->SetPageControl(pageControl);
      wcontrol->SetRenderOffset(offset);
      wcontrol->SetAutoScrolling(controlNode);
      wcontrol->SetClickActions(clickActions);
      wcontrol->SetFocusActions(focusActions);
      wcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTAINER_EPGGRID:
    {
      CGUIEPGGridContainer *epgGridContainer = new CGUIEPGGridContainer(parentID, id, posX, posY, width, height, orientation, scrollTime, preloadItems, timeBlocks, rulerUnit, textureProgressIndicator);
      control = epgGridContainer;
      epgGridContainer->LoadLayout(controlNode);
      epgGridContainer->SetRenderOffset(offset);
      epgGridContainer->SetType(viewType, viewLabel);
      epgGridContainer->SetPageControl(pageControl);
    }
    break;
  case CGUIControl::GUICONTAINER_FIXEDLIST:
    {
      CScroller scroller;
      GetScroller(controlNode, "scrolltime", scroller);

      control = new CGUIFixedListContainer(parentID, id, posX, posY, width, height, orientation, scroller, preloadItems, focusPosition, iMovementRange);
      CGUIFixedListContainer* fcontrol = static_cast<CGUIFixedListContainer*>(control);
      fcontrol->LoadLayout(controlNode);
      fcontrol->LoadListProvider(controlNode, defaultControl, defaultAlways);
      fcontrol->SetType(viewType, viewLabel);
      fcontrol->SetPageControl(pageControl);
      fcontrol->SetRenderOffset(offset);
      fcontrol->SetAutoScrolling(controlNode);
      fcontrol->SetClickActions(clickActions);
      fcontrol->SetFocusActions(focusActions);
      fcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTAINER_PANEL:
    {
      CScroller scroller;
      GetScroller(controlNode, "scrolltime", scroller);

      control = new CGUIPanelContainer(parentID, id, posX, posY, width, height, orientation, scroller, preloadItems);
      CGUIPanelContainer* pcontrol = static_cast<CGUIPanelContainer*>(control);
      pcontrol->LoadLayout(controlNode);
      pcontrol->LoadListProvider(controlNode, defaultControl, defaultAlways);
      pcontrol->SetType(viewType, viewLabel);
      pcontrol->SetPageControl(pageControl);
      pcontrol->SetRenderOffset(offset);
      pcontrol->SetAutoScrolling(controlNode);
      pcontrol->SetClickActions(clickActions);
      pcontrol->SetFocusActions(focusActions);
      pcontrol->SetUnFocusActions(unfocusActions);
    }
    break;
  case CGUIControl::GUICONTROL_TEXTBOX:
    {
      if (!strMonoFont.empty())
      {
        labelInfoMono = labelInfo;
        labelInfoMono.font = g_fontManager.GetFont(strMonoFont);
      }
      control = new CGUITextBox(
        parentID, id, posX, posY, width, height,
        labelInfo, scrollTime, strMonoFont.empty() ? nullptr : &labelInfoMono);

      CGUITextBox* tcontrol = static_cast<CGUITextBox*>(control);

      tcontrol->SetPageControl(pageControl);
      if (infoLabels.size())
        tcontrol->SetInfo(infoLabels[0]);
      tcontrol->SetAutoScrolling(controlNode);
      tcontrol->SetMinHeight(minHeight);
    }
    break;
  case CGUIControl::GUICONTROL_MOVER:
    {
      control = new CGUIMoverControl(parentID, id, posX, posY, width, height, textureFocus,
                                     textureNoFocus, movingSpeedCfg);
    }
    break;
  case CGUIControl::GUICONTROL_RESIZE:
    {
      control = new CGUIResizeControl(parentID, id, posX, posY, width, height, textureFocus,
                                      textureNoFocus, movingSpeedCfg);
    }
    break;
  case CGUIControl::GUICONTROL_SPINEX:
    {
      control = new CGUISpinControlEx(
        parentID, id, posX, posY, width, height, spinWidth, spinHeight,
        labelInfo, textureFocus, textureNoFocus, textureUp, textureDown, textureUpFocus, textureDownFocus,
        textureUpDisabled, textureDownDisabled, labelInfo, iType);

      CGUISpinControlEx* scontrol = static_cast<CGUISpinControlEx*>(control);
      scontrol->SetSpinPosition(spinPosX);
      scontrol->SetText(strLabel);
      scontrol->SetReverse(bReverse);
    }
    break;
  case CGUIControl::GUICONTROL_VISUALISATION:
    control = new CGUIVisualisationControl(parentID, id, posX, posY, width, height);
    break;
  case CGUIControl::GUICONTROL_RENDERADDON:
    control = new CGUIRenderingControl(parentID, id, posX, posY, width, height);
    break;
  case CGUIControl::GUICONTROL_GAMECONTROLLER:
  {
    control = new GAME::CGUIGameController(parentID, id, posX, posY, width, height, texture);

    GAME::CGUIGameController* gcontrol = static_cast<GAME::CGUIGameController*>(control);

    // Set texture
    gcontrol->SetInfo(textureFile);

    // Set aspect ratio
    gcontrol->SetAspectRatio(aspect);

    // Set controller ID
    GUIINFO::CGUIInfoLabel controllerId;
    GetInfoLabel(controlNode, "controllerid", controllerId, parentID);
    gcontrol->SetControllerID(controllerId);

    // Set controller address
    GUIINFO::CGUIInfoLabel controllerAddress;
    GetInfoLabel(controlNode, "controlleraddress", controllerAddress, parentID);
    gcontrol->SetControllerAddress(controllerAddress);

    // Set controller diffuse color
    GUIINFO::CGUIInfoColor controllerDiffuse(0xFFFFFFFF);
    GetInfoColor(controlNode, "controllerdiffuse", controllerDiffuse, parentID);
    gcontrol->SetControllerDiffuse(controllerDiffuse);

    // Set port address
    GUIINFO::CGUIInfoLabel portAddress;
    GetInfoLabel(controlNode, "portaddress", portAddress, parentID);
    gcontrol->SetPortAddress(portAddress);

    break;
  }
  case CGUIControl::GUICONTROL_COLORBUTTON:
  {
    control = new CGUIColorButtonControl(parentID, id, posX, posY, width, height, textureFocus,
                                         textureNoFocus, labelInfo, textureColorMask,
                                         textureColorDisabledMask);

    CGUIColorButtonControl* rcontrol = static_cast<CGUIColorButtonControl*>(control);
    rcontrol->SetLabel(strLabel);
    rcontrol->SetImageBoxColor(colorBox);
    rcontrol->SetColorDimensions(colorPosX, colorPosY, colorWidth, colorHeight);
    rcontrol->SetClickActions(clickActions);
    rcontrol->SetFocusActions(focusActions);
    rcontrol->SetUnFocusActions(unfocusActions);
  }
  break;
  default:
    break;
  }

  // things that apply to all controls
  if (control)
  {
    control->SetHitRect(hitRect, hitColor);
    control->SetVisibleCondition(visibleCondition, allowHiddenFocus);
    control->SetEnableCondition(enableCondition);
    control->SetAnimations(animations);
    control->SetColorDiffuse(colorDiffuse);
    control->SetActions(actions);
    control->SetPulseOnSelect(bPulse);
    if (hasCamera)
      control->SetCamera(camera);
    control->SetStereoFactor(stereo);
  }
  return control;
}
