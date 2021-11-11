/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "RendererMetal.h"

#include "RenderFactory.h"

CBaseRenderer* CRendererMetal::Create(CVideoBuffer* buffer)
{
  return new CRendererMetal();
}

bool CRendererMetal::Register()
{
  VIDEOPLAYER::CRendererFactory::RegisterRenderer("metal", CRendererMetal::Create);
  return true;
}
