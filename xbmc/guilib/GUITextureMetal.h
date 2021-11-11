/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "GUITexture.h"
#include "utils/ColorUtils.h"

class CGUITextureMetal : public CGUITexture
{
public:
  CGUITextureMetal(float posX, float posY, float width, float height, const CTextureInfo& texture);
  ~CGUITextureMetal() override = default;

  CGUITextureMetal* Clone() const override;

protected:
  void Begin(UTILS::COLOR::Color color);
  void Draw(float *x, float *y, float *z, const CRect &texture, const CRect &diffuse, int orientation);
  void End();
};
