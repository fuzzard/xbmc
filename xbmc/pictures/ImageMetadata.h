/*
 *  Copyright (C) 2023 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "Exif.h"
#include "Iptc.h"

struct ImageMetadata
{
  ExifInfo exifInfo;
  IPTCInfo iptcInfo;
};
