/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "GUIFontTTFMetal.h"

#include "GUIFont.h"

CGUIFontTTF* CGUIFontTTF::CreateGUIFontTTF(const std::string& fileName)
{
  return new CGUIFontTTFMetal(fileName);
}

CGUIFontTTFMetal::CGUIFontTTFMetal(const std::string& strFileName) : CGUIFontTTF(strFileName)
{
}