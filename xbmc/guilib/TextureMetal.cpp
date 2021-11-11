/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "TextureMetal.h"

#include "Texture.h"

CTexture* CTexture::CreateTexture(unsigned int width, unsigned int height, unsigned int format)
{
  return new CTextureMetal(width, height, format);
}

CTextureMetal::CTextureMetal(unsigned int width, unsigned int height, unsigned int format)
  : CTexture(width, height, format)
{
}