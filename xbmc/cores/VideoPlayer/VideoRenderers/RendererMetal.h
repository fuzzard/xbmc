/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "BaseRenderer.h"

class CRendererMetal : public CBaseRenderer
{
public:
  CRendererMetal() = default;
  ~CRendererMetal() override = default;

  // Registration
  static CBaseRenderer* Create(CVideoBuffer* buffer);
  static bool Register();

  // Player functions
  bool Configure(const VideoPicture& picture, float fps, unsigned int orientation) override
  {
    return false;
  }
  bool IsConfigured() override { return false; }
  void AddVideoPicture(const VideoPicture& picture, int index) override {}
  void UnInit() override {}
  void Update() override {}
  void RenderUpdate(
      int index, int index2, bool clear, unsigned int flags, unsigned int alpha) override
  {
  }
  bool RenderCapture(CRenderCapture* capture) override { return false; }
  bool ConfigChanged(const VideoPicture& picture) override { return false; }

  // Feature support
  bool SupportsMultiPassRendering() override { return false; }
  bool Supports(ERENDERFEATURE feature) override { return false; }
  bool Supports(ESCALINGMETHOD method) override { return false; }
};
