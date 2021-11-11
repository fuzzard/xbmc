/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "Texture.h"

class CTextureMetal : public CTexture
{
public:
  CTextureMetal(unsigned int width = 0,
                 unsigned int height = 0,
                 unsigned int format = XB_FMT_A8R8G8B8);
  ~CTextureMetal() override = default;

  void CreateTextureObject() override {}
  void DestroyTextureObject() override {}
  void LoadToGPU() override {}
  void BindToUnit(unsigned int unit) override {}
};