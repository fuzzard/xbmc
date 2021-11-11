/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "RenderCapture.h"

class CRenderCaptureMetal : public CRenderCaptureBase
{
public:
  CRenderCaptureMetal() = default;
  ~CRenderCaptureMetal() override = default;

  void BeginRender() {}
  void EndRender() {}
  void ReadOut() {}
};
