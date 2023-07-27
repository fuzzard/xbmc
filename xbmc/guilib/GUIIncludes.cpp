/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "GUIIncludes.h"

#include "GUIInfoManager.h"
#include "addons/Skin.h"
#include "guilib/GUIComponent.h"
#include "guilib/guiinfo/GUIInfoLabel.h"
#include "interfaces/info/SkinVariable.h"
#include "utils/StringUtils.h"
#include "utils/XBMCTinyXML2.h"
#include "utils/XMLUtils.h"
#include "utils/log.h"

#include <tinyxml2.h>

using namespace KODI::GUILIB;

CGUIIncludes::CGUIIncludes()
{
  m_constantAttributes.insert("x");
  m_constantAttributes.insert("y");
  m_constantAttributes.insert("width");
  m_constantAttributes.insert("height");
  m_constantAttributes.insert("center");
  m_constantAttributes.insert("max");
  m_constantAttributes.insert("min");
  m_constantAttributes.insert("w");
  m_constantAttributes.insert("h");
  m_constantAttributes.insert("time");
  m_constantAttributes.insert("acceleration");
  m_constantAttributes.insert("delay");
  m_constantAttributes.insert("start");
  m_constantAttributes.insert("end");
  m_constantAttributes.insert("center");
  m_constantAttributes.insert("border");
  m_constantAttributes.insert("repeat");

  m_constantNodes.insert("posx");
  m_constantNodes.insert("posy");
  m_constantNodes.insert("left");
  m_constantNodes.insert("centerleft");
  m_constantNodes.insert("right");
  m_constantNodes.insert("centerright");
  m_constantNodes.insert("top");
  m_constantNodes.insert("centertop");
  m_constantNodes.insert("bottom");
  m_constantNodes.insert("centerbottom");
  m_constantNodes.insert("width");
  m_constantNodes.insert("height");
  m_constantNodes.insert("offsetx");
  m_constantNodes.insert("offsety");
  m_constantNodes.insert("textoffsetx");
  m_constantNodes.insert("textoffsety");
  m_constantNodes.insert("textwidth");
  m_constantNodes.insert("spinposx");
  m_constantNodes.insert("spinposy");
  m_constantNodes.insert("spinwidth");
  m_constantNodes.insert("spinheight");
  m_constantNodes.insert("radioposx");
  m_constantNodes.insert("radioposy");
  m_constantNodes.insert("radiowidth");
  m_constantNodes.insert("radioheight");
  m_constantNodes.insert("sliderwidth");
  m_constantNodes.insert("sliderheight");
  m_constantNodes.insert("itemgap");
  m_constantNodes.insert("bordersize");
  m_constantNodes.insert("timeperimage");
  m_constantNodes.insert("fadetime");
  m_constantNodes.insert("pauseatend");
  m_constantNodes.insert("depth");
  m_constantNodes.insert("movement");
  m_constantNodes.insert("focusposition");

  m_expressionAttributes.insert("condition");

  m_expressionNodes.insert("visible");
  m_expressionNodes.insert("enable");
  m_expressionNodes.insert("usealttexture");
  m_expressionNodes.insert("selected");
}

CGUIIncludes::~CGUIIncludes() = default;

void CGUIIncludes::Clear()
{
  m_includes.clear();
  m_defaults.clear();
  m_constants.clear();
  m_skinvariables.clear();
  m_files.clear();
  m_expressions.clear();
}

void CGUIIncludes::Load(const std::string &file)
{
  if (!Load_Internal(file))
    return;
  FlattenExpressions();
  FlattenSkinVariableConditions();
}

bool CGUIIncludes::Load_Internal(const std::string &file)
{
  // check to see if we already have this loaded
  if (HasLoaded(file))
    return true;

  CXBMCTinyXML2 doc;
  if (!doc.LoadFile(file))
  {
    CLog::Log(LOGINFO, "Error loading include file {}: {} (line: {})", file, doc.ErrorStr(),
              doc.ErrorLineNum());
    return false;
  }

  auto* root = doc.RootElement();
  if (!root || !StringUtils::EqualsNoCase(root->Value(), "includes"))
  {
    CLog::Log(LOGERROR, "Error loading include file {}: Root element <includes> required.", file);
    return false;
  }

  // load components
  LoadDefaults(root);
  LoadConstants(root);
  LoadExpressions(root);
  LoadVariables(root);
  LoadIncludes(root);
  m_files.push_back(file);

  return true;
}

void CGUIIncludes::LoadDefaults(const tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  const auto* child = node->FirstChildElement("default");
  while (child)
  {
    const char *type = child->Attribute("type");
    if (type && child->FirstChild())
    {
      auto elementDoc = std::make_unique<tinyxml2::XMLDocument>();
      tinyxml2::XMLNode* clonenode = child->DeepClone(elementDoc.get());
      elementDoc->InsertFirstChild(clonenode);
      m_defaults.insert(std::make_pair(std::string(type), std::move(elementDoc)));
    }

    child = child->NextSiblingElement("default");
  }
}

void CGUIIncludes::LoadExpressions(const tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  const auto* child = node->FirstChildElement("expression");
  while (child)
  {
    const char *tagName = child->Attribute("name");
    if (tagName && child->FirstChild())
    {
      m_expressions.insert(std::make_pair(tagName, std::string("[") +
                                                       std::string(child->FirstChild()->Value()) +
                                                       std::string("]")));
    }

    child = child->NextSiblingElement("expression");
  }
}

void CGUIIncludes::LoadConstants(const tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  const auto* child = node->FirstChildElement("constant");
  while (child)
  {
    const char *tagName = child->Attribute("name");
    if (tagName && child->FirstChild())
      m_constants.insert(std::make_pair(tagName, child->FirstChild()->Value()));

    child = child->NextSiblingElement("constant");
  }
}

void CGUIIncludes::LoadVariables(const tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  const auto* child = node->FirstChildElement("variable");
  while (child)
  {
    const char* tagName = child->Attribute("name");
    if (tagName && child->FirstChild())
    {
      auto elementDoc = std::make_unique<tinyxml2::XMLDocument>();
      tinyxml2::XMLNode* clonenode = child->DeepClone(elementDoc.get());
      elementDoc->InsertFirstChild(clonenode);
      m_skinvariables.insert(std::make_pair(std::string(tagName), std::move(elementDoc)));
    }

    child = child->NextSiblingElement("variable");
  }
}

void CGUIIncludes::LoadIncludes(const tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  auto* child = node->FirstChildElement("include");
  while (child)
  {
    const char *tagName = child->Attribute("name");
    if (tagName && child->FirstChild())
    {
      // we'll parse and store parameter list with defaults when include definition is first encountered
      // if there's a <definition> tag only use its body as the actually included part
      const auto* definitionTag = child->FirstChildElement("definition");
      const tinyxml2::XMLElement& includeBody = definitionTag ? *definitionTag : *child;

      // if there's a <param> tag there also must be a <definition> tag
      Params defaultParams;
      bool haveParamTags = GetParameters(child, "default", defaultParams);
      if (haveParamTags && !definitionTag)
        CLog::Log(LOGWARNING, "Skin has invalid include definition: {}", tagName);
      else
      {
        auto elementDoc = std::make_unique<tinyxml2::XMLDocument>();
        tinyxml2::XMLNode* clonenode = includeBody.DeepClone(elementDoc.get());
        elementDoc->InsertFirstChild(clonenode);
        auto pair = std::make_pair(std::move(elementDoc), std::move(defaultParams));
        m_includes.insert({std::string(tagName), std::move(pair)});
      }
    }
    else if (child->Attribute("file"))
    {
      std::string file = g_SkinInfo->GetSkinPath(child->Attribute("file"));
      const char *condition = child->Attribute("condition");

      if (condition)
      { // load include file if condition evals to true
        if (CServiceBroker::GetGUI()->GetInfoManager().Register(condition)->Get(
                INFO::DEFAULT_CONTEXT))
          Load_Internal(file);
      }
      else
        Load_Internal(file);
    }
    child = child->NextSiblingElement("include");
  }
}

void CGUIIncludes::FlattenExpressions()
{
  for (auto& expression : m_expressions)
  {
    std::vector<std::string> resolved = std::vector<std::string>();
    resolved.push_back(expression.first);
    FlattenExpression(expression.second, resolved);
  }
}

void CGUIIncludes::FlattenExpression(std::string &expression, const std::vector<std::string> &resolved)
{
  std::string original(expression);
  GUIINFO::CGUIInfoLabel::ReplaceSpecialKeywordReferences(expression, "EXP", [&](const std::string &expressionName) -> std::string {
    if (std::find(resolved.begin(), resolved.end(), expressionName) != resolved.end())
    {
      CLog::Log(LOGERROR, "Skin has a circular expression \"{}\": {}", resolved.back(), original);
      return std::string();
    }
    auto it = m_expressions.find(expressionName);
    if (it == m_expressions.end())
      return std::string();

    std::vector<std::string> rescopy = resolved;
    rescopy.push_back(expressionName);
    FlattenExpression(it->second, rescopy);

    return it->second;
  });
}

void CGUIIncludes::FlattenSkinVariableConditions()
{
  for (auto& variable : m_skinvariables)
  {
    auto* valueNode = variable.second->FirstChildElement("value");
    while (valueNode)
    {
      const char *condition = valueNode->Attribute("condition");
      if (condition)
      {
        auto valueAttr = const_cast<tinyxml2::XMLElement*>(valueNode);
        valueAttr->SetAttribute("condition", ResolveExpressions(condition).c_str());
      }

      valueNode = valueNode->NextSiblingElement("value");
    }
  }
}

bool CGUIIncludes::HasLoaded(const std::string &file) const
{
  for (const auto& loadedFile : m_files)
  {
    if (loadedFile == file)
      return true;
  }
  return false;
}

void CGUIIncludes::Resolve(tinyxml2::XMLElement* node,
                           std::map<INFO::InfoPtr, bool>* xmlIncludeConditions /* = NULL */)
{
  if (!node)
    return;

  SetDefaults(node);
  ResolveConstants(node);
  ResolveExpressions(node);
  ResolveIncludes(node, xmlIncludeConditions);

  auto* child = node->FirstChildElement();
  while (child)
  {
    // recursive call
    Resolve(child, xmlIncludeConditions);
    child = child->NextSiblingElement();
  }
}

void CGUIIncludes::SetDefaults(tinyxml2::XMLElement* node)
{
  if (strcmp(node->Value(), "control") != 0)
    return;

  std::string type = XMLUtils::GetAttribute(node, "type");
  const auto it = m_defaults.find(type);
  if (it != m_defaults.end())
  {
    // we don't insert <left> et. al. if <posx> or <posy> is specified
    bool hasPosX(node->FirstChildElement("posx") != nullptr);
    bool hasPosY(node->FirstChildElement("posy") != nullptr);

    const auto& xmlDoc = (*it).second;
    auto* tag = xmlDoc->FirstChildElement();
    while (tag)
    {
      std::string value = tag->Value();
      bool skip(false);
      if (hasPosX && (value == "left" || value == "right" || value == "centerleft" || value == "centerright"))
        skip = true;
      if (hasPosY && (value == "top" || value == "bottom" || value == "centertop" || value == "centerbottom"))
        skip = true;
      // we insert at the end of block
      if (!skip)
      {
        auto clonedElement = tag->DeepClone(node->GetDocument());
        node->InsertEndChild(clonedElement);
      }
      tag = tag->NextSiblingElement();
    }
  }
}

void CGUIIncludes::ResolveConstants(tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  auto* child = node->FirstChild();
  if (child && child->ToText() && m_constantNodes.count(node->Value()))
  {
    child->SetValue(ResolveConstant(child->Value()).c_str());
  }
  else
  {
    auto* attribute = node->FirstAttribute();
    while (attribute)
    {
      if (m_constantAttributes.count(attribute->Name()))
      {
        auto attrib = const_cast<tinyxml2::XMLAttribute*>(attribute);
        attrib->SetAttribute(ResolveConstant(attribute->Value()).c_str());
      }

      attribute = attribute->Next();
    }
  }
}

void CGUIIncludes::ResolveExpressions(tinyxml2::XMLElement* node)
{
  if (!node)
    return;

  auto* child = node->FirstChild();
  if (child && child->ToText() && m_expressionNodes.count(node->Value()))
  {
    child->SetValue(ResolveExpressions(child->Value()).c_str());
  }
  else
  {
    auto* attribute = node->FirstAttribute();
    while (attribute)
    {
      if (m_expressionAttributes.count(attribute->Name()))
      {
        auto attrib = const_cast<tinyxml2::XMLAttribute*>(attribute);
        attrib->SetAttribute(ResolveExpressions(attribute->Value()).c_str());
      }

      attribute = attribute->Next();
    }
  }
}

void CGUIIncludes::ResolveIncludes(tinyxml2::XMLElement* node,
                                   std::map<INFO::InfoPtr, bool>* xmlIncludeConditions /* = NULL */)
{
  if (!node)
    return;

  auto* include = node->FirstChildElement("include");

  while (include)
  {
    // file: load includes from specified XML file
    const char *file = include->Attribute("file");
    if (file)
      Load(g_SkinInfo->GetSkinPath(file));

    // condition: process include if condition evals to true
    const char *condition = include->Attribute("condition");
    if (condition)
    {
      INFO::InfoPtr conditionID =
          CServiceBroker::GetGUI()->GetInfoManager().Register(ResolveExpressions(condition));
      bool value = false;

      if (conditionID)
      {
        value = conditionID->Get(INFO::DEFAULT_CONTEXT);

        if (xmlIncludeConditions)
          xmlIncludeConditions->insert(std::make_pair(conditionID, value));
      }

      if (!value)
      {
        include = include->NextSiblingElement("include");
        continue;
      }
    }

    Params params;
    std::string tagName;

    // determine which form of include call we have
    const char *name = include->Attribute("content");
    if (name && strcmp(name, "\0") != 0)
    {
      // <include content="MyControl" />
      // or
      // <include content="MyControl">
      //   <param name="posx" value="225" />
      //   <param name="posy">150</param>
      //   ...
      // </include>
      tagName = name;
      GetParameters(include, "value", params);
    }
    else
    {
      const auto* child = include->FirstChild();
      if (child && child->ToText())
      {
        // <include>MyControl</include>
        // old-style includes for backward compatibility
        tagName = child->Value();
      }
    }

    // check, whether the include exists and therefore should be replaced by its definition
    auto it = m_includes.find(tagName);
    if (it != m_includes.end())
    {
      auto includeDefinitionDoc = it->second.first.get();

      // combine passed include parameters with their default values into a single list (no overwrites)
      const Params& defaultParams = it->second.second;
      params.insert(defaultParams.begin(), defaultParams.end());

      // process include definition
      tinyxml2::XMLNode* includeDefinitionChild =
          includeDefinitionDoc->FirstChildElement()->FirstChild();
      while (includeDefinitionChild)
      {
        auto clonedElement = includeDefinitionChild->DeepClone(node->GetDocument());
        auto* insertedNode = node->InsertFirstChild(clonedElement);

        // process nested
        InsertNested(node, include, insertedNode->ToElement());

        // resolve parameters even if parameter list is empty (to remove param references)
        ResolveParametersForNode(insertedNode->ToElement(), params);

        includeDefinitionChild = includeDefinitionChild->NextSiblingElement();
      }

      // remove the include element itself
      node->DeleteChild(include);

      include = node->FirstChildElement("include");
    }
    else
    { // invalid include
      CLog::Log(LOGWARNING, "Skin has invalid include: {}", tagName);
      include = include->NextSiblingElement("include");
    }
  }
}

void CGUIIncludes::InsertNested(tinyxml2::XMLElement* controls,
                                tinyxml2::XMLElement* include,
                                tinyxml2::XMLElement* node)
{
  bool controlNode{false};

  if (strcmp(node->Value(), "nested") == 0)
  {
    controlNode = true;
  }

  if (strcmp(node->Value(), "nested") == 0 || node->FirstChildElement("nested"))
  {
    // copy all child elements except param elements
    auto* child = include->FirstChildElement();
    while (child)
    {
      if (strcmp(child->Value(), "param") != 0)
      {
        if (controlNode)
        {
          controls->InsertAfterChild(node, child);
        }
        else
        {
          node->InsertAfterChild(node->FirstChildElement("nested"), child);
        }
      }
      child = child->NextSiblingElement();
    }

    if (controlNode)
    {
      controls->DeleteChild(node);
    }
    else
    {
      node->DeleteChild(node->FirstChildElement("nested"));
    }
  }

}

bool CGUIIncludes::GetParameters(const tinyxml2::XMLElement* include,
                                 const char* valueAttribute,
                                 Params& params)
{
  bool foundAny = false;

  // collect parameters from include tag
  // <include content="MyControl">
  //   <param name="posx" value="225" /> <!-- comments and other tags are ignored here -->
  //   <param name="posy">150</param>
  //   ...
  // </include>

  if (include)
  {
    const auto* param = include->FirstChildElement("param");
    foundAny = param != NULL;  // doesn't matter if param isn't entirely valid
    while (param)
    {
      std::string paramName = XMLUtils::GetAttribute(param, "name");
      if (!paramName.empty())
      {
        std::string paramValue;

        // <param name="posx" value="120" />
        const char *value = param->Attribute(valueAttribute);         // try attribute first
        if (value)
          paramValue = value;
        else
        {
          // <param name="posx">120</param>
          const auto* child = param->FirstChild();
          if (child && child->ToText())
            paramValue = child->Value(); // and then tag value
        }

        params.insert({ paramName, paramValue });                     // no overwrites
      }
      param = param->NextSiblingElement("param");
    }
  }

  return foundAny;
}

void CGUIIncludes::ResolveParametersForNode(tinyxml2::XMLElement* node, const Params& params)
{
  if (!node)
    return;
  std::string newValue;
  // run through this element's attributes, resolving any parameters
  auto* attribute = node->FirstAttribute();
  while (attribute)
  {
    ResolveParamsResult result = ResolveParameters(attribute->Value(), newValue, params);
    if (result == SINGLE_UNDEFINED_PARAM_RESOLVED && strcmp(node->Value(), "param") == 0 &&
        strcmp(attribute->Name(), "value") == 0 && node->Parent() && strcmp(node->Parent()->Value(), "include") == 0)
    {
      // special case: passing <param name="someName" value="$PARAM[undefinedParam]" /> to the nested include
      // this usually happens when trying to forward a missing parameter from the enclosing include to the nested include
      // problem: since 'undefinedParam' is not defined, it expands to <param name="someName" value="" /> and overrides any default value set with <param name="someName" default="someValue" /> in the nested include
      // to prevent this, we'll completely remove this parameter from the nested include call so that the default value can be correctly picked up later
      node->Parent()->DeleteChild(node);
      return;
    }
    else if (result != NO_PARAMS_FOUND)
    {
      auto attrib = const_cast<tinyxml2::XMLAttribute*>(attribute);
      attrib->SetAttribute(newValue.c_str());
    }
    attribute = attribute->Next();
  }
  // run through this element's value and children, resolving any parameters
  auto* child = node->FirstChild();
  if (child)
  {
    if (child->ToText())
    {
      ResolveParamsResult result = ResolveParameters(child->Value(), newValue, params);
      if (result == SINGLE_UNDEFINED_PARAM_RESOLVED && strcmp(node->Value(), "param") == 0 &&
          node->Parent() && strcmp(node->Parent()->Value(), "include") == 0)
      {
        // special case: passing <param name="someName">$PARAM[undefinedParam]</param> to the nested include
        // we'll remove the offending param tag same as above
        node->Parent()->DeleteChild(node);
      }
      else if (result != NO_PARAMS_FOUND)
        child->SetValue(newValue.c_str());
    }
    else if (child->ToElement() || child->ToText())
    {
      do
      {
        // save next as current child might be removed from the tree
        auto* next = child->NextSiblingElement();

        if (child->ToElement())
          ResolveParametersForNode(static_cast<tinyxml2::XMLElement*>(child), params);

        child = next;
      }
      while (child);
    }
  }
}

class ParamReplacer
{
  const std::map<std::string, std::string>& m_params;
  // keep some stats so that we know exactly what's been resolved
  int m_numTotalParams = 0;
  int m_numUndefinedParams = 0;

public:
  explicit ParamReplacer(const std::map<std::string, std::string>& params) : m_params(params) {}
  int GetNumTotalParams() const { return m_numTotalParams; }
  int GetNumDefinedParams() const { return m_numTotalParams - m_numUndefinedParams; }
  int GetNumUndefinedParams() const { return m_numUndefinedParams; }

  std::string operator()(const std::string &paramName)
  {
    m_numTotalParams++;
    std::map<std::string, std::string>::const_iterator it = m_params.find(paramName);
    if (it != m_params.end())
      return it->second;
    m_numUndefinedParams++;
    return "";
  }
};

CGUIIncludes::ResolveParamsResult CGUIIncludes::ResolveParameters(const std::string& strInput, std::string& strOutput, const Params& params)
{
  ParamReplacer paramReplacer(params);
  if (GUIINFO::CGUIInfoLabel::ReplaceSpecialKeywordReferences(strInput, "PARAM", std::ref(paramReplacer), strOutput))
    // detect special input values of the form "$PARAM[undefinedParam]" (with no extra characters around)
    return paramReplacer.GetNumUndefinedParams() == 1 && paramReplacer.GetNumTotalParams() == 1 && strOutput.empty() ? SINGLE_UNDEFINED_PARAM_RESOLVED : PARAMS_RESOLVED;
  return NO_PARAMS_FOUND;
}

std::string CGUIIncludes::ResolveConstant(const std::string &constant) const
{
  std::vector<std::string> values = StringUtils::Split(constant, ",");
  for (auto& i : values)
  {
    std::map<std::string, std::string>::const_iterator it = m_constants.find(i);
    if (it != m_constants.end())
      i = it->second;
  }
  return StringUtils::Join(values, ",");
}

std::string CGUIIncludes::ResolveExpressions(const std::string &expression) const
{
  std::string work(expression);
  GUIINFO::CGUIInfoLabel::ReplaceSpecialKeywordReferences(work, "EXP", [&](const std::string &str) -> std::string {
    std::map<std::string, std::string>::const_iterator it = m_expressions.find(str);
    if (it != m_expressions.end())
      return it->second;
    return "";
  });

  return work;
}

const INFO::CSkinVariableString* CGUIIncludes::CreateSkinVariable(const std::string& name, int context)
{
  auto it = m_skinvariables.find(name);
  if (it != m_skinvariables.end())
  {
    auto child = it->second->FirstChild()->ToElement();
    return INFO::CSkinVariable::CreateFromXML(*child, context);
  }
  return NULL;
}
