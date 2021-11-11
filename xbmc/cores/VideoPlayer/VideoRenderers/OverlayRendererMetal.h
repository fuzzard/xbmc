/*
 *      Initial code sponsored by: Voddler Inc (voddler.com)
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "OverlayRenderer.h"

class CDVDOverlay;
class CDVDOverlayImage;
class CDVDOverlaySpu;
class CDVDOverlaySSA;
typedef struct ass_image ASS_Image;

namespace OVERLAY {

  class COverlayTextureMetal : public COverlay
  {
  public:
     explicit COverlayTextureMetal(CDVDOverlayImage* o);
     explicit COverlayTextureMetal(CDVDOverlaySpu* o);
    ~COverlayTextureMetal() override;

    void Render(SRenderState& state) override;

  };

  class COverlayGlyphMetal : public COverlay
  {
  public:
   COverlayGlyphMetal(ASS_Image* images, int width, int height);

   ~COverlayGlyphMetal() override;

   void Render(SRenderState& state) override;

  };

}
