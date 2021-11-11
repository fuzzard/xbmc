/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "GUITextureMetal.h"

#include "Texture.h"

CGUITexture* CGUITexture::CreateTexture(
    float posX, float posY, float width, float height, const CTextureInfo& texture)
{
  return new CGUITextureMetal(posX, posY, width, height, texture);
}

CGUITextureVulkan::CGUITextureVulkan(
    float posX, float posY, float width, float height, const CTextureInfo& texture)
  : CGUITexture(posX, posY, width, height, texture)
{
}

CGUITextureMetal* CGUITextureMetal::Clone() const
{
  return new CGUITextureMetal(*this);
}

void CGUITextureMetal::Begin(UTILS::Color color)
{
}

void CGUITextureMetal::End()
{
}

void CGUITextureMetal::Draw(
    float* x, float* y, float* z, const CRect& texture, const CRect& diffuse, int orientation)
{
}

void CGUITexture::DrawQuad(const CRect& rect,
                           UTILS::Color color,
                           CTexture* texture,
                           const CRect* texCoords)
{
}