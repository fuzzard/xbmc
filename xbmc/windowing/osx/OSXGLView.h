#pragma once

/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Appkit/AppKit.h>

@interface OSXGLView : NSOpenGLView
{
  NSOpenGLContext* m_glcontext;
  NSOpenGLPixelFormat* m_pixFmt;
  NSTrackingArea* m_trackingArea;
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)dealloc;
- (NSOpenGLContext*)getGLContext;

@end
