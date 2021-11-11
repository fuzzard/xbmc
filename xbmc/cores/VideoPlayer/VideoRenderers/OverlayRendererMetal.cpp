/*
 *      Initial code sponsored by: Voddler Inc (voddler.com)
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */
#include "OverlayRendererMetal.h"

#include "OverlayRenderer.h"
#include "OverlayRendererUtil.h"
#include "RenderManager.h"
#include "ServiceBroker.h"
#include "cores/VideoPlayer/DVDCodecs/Overlay/DVDOverlayImage.h"
#include "cores/VideoPlayer/DVDCodecs/Overlay/DVDOverlaySpu.h"
#include "cores/VideoPlayer/DVDCodecs/Overlay/DVDOverlaySSA.h"
#include "windowing/WinSystem.h"
#include "utils/MathUtils.h"
#include "utils/log.h"

#pragma mark - COverlayTextureMetal

COverlayTextureMetal::COverlayTextureMetal(CDVDOverlayImage* o)
{
}

COverlayTextureMetal::COverlayTextureMetal(CDVDOverlaySpu* o)
{

}


#pragma mark - COverlayGlyphMetal

COverlayGlyphMetal::COverlayGlyphMetal(ASS_Image* images, int width, int height)
{

}

COverlayGlyphMetal::~COverlayGlyphMetal()
{
  glDeleteTextures(1, &m_texture);
}

void COverlayGlyphMetal::Render(SRenderState& state)
{

}
