﻿/*
 *  Copyright (C) 2017-2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */
#pragma once

#include "VideoRenderers/ColorManager.h"
#include "VideoRenderers/RenderInfo.h"
#include "VideoRenderers/VideoShaders/WinVideoFilter.h"
#include "cores/VideoSettings.h"
#include "guilib/D3DResource.h"

#include <vector>

#include <d3d11.h>
#include <dxgi1_5.h>
extern "C" {
#include <libavutil/mastering_display_metadata.h>
}

struct VideoPicture;
class CVideoBuffer;

namespace win
{
  namespace helpers
  {
    template<typename T>
    bool contains(std::vector<T> vector, T item)
    {
      return find(vector.begin(), vector.end(), item) != vector.end();
    }
  }
}

enum RenderMethod
{
  RENDER_INVALID = 0x00,
  RENDER_DXVA = 0x01,
  RENDER_PS = 0x02,
  RENDER_SW = 0x03,
};

class CRenderBuffer
{
public:
  virtual ~CRenderBuffer() = default;

  unsigned GetWidth() const { return m_widthTex; }
  unsigned GetHeight() const { return m_heightTex; }

  virtual void AppendPicture(const VideoPicture& picture);
  virtual void ReleasePicture();
  virtual bool IsLoaded() { return false; }
  virtual bool UploadBuffer() { return false; }
  virtual HRESULT GetResource(ID3D11Resource** ppResource, unsigned* index) const;

  // implementation specified
  virtual bool GetDataPlanes(uint8_t*(&planes)[3], int(&strides)[3]) { return false; }
  virtual unsigned GetViewCount() const { return 0; }
  virtual ID3D11View* GetView(unsigned viewIdx) { return nullptr; }

  AVPixelFormat av_format;
  CVideoBuffer* videoBuffer = nullptr;
  unsigned int pictureFlags = 0;
  AVColorPrimaries primaries = AVCOL_PRI_BT709;
  AVColorSpace color_space = AVCOL_SPC_BT709;
  AVColorTransferCharacteristic color_transfer = AVCOL_TRC_BT709;
  bool full_range = false;
  int bits = 8;
  uint8_t texBits = 8;

  bool hasDisplayMetadata = false;
  bool hasLightMetadata = false;
  AVMasteringDisplayMetadata displayMetadata = {};
  AVContentLightMetadata lightMetadata = {};
  std::string stereoMode;
  uint64_t frameIdx = 0;

protected:
  CRenderBuffer(AVPixelFormat av_pix_format, unsigned width, unsigned height);
  void QueueCopyFromGPU();

  // video buffer size
  unsigned int m_width;
  unsigned int m_height;
  // real texture size
  unsigned int m_widthTex;
  unsigned int m_heightTex;
  // copy from GPU mem
  Microsoft::WRL::ComPtr<ID3D11Texture2D> m_staging;
  D3D11_TEXTURE2D_DESC m_sDesc{};
  bool m_bPending = false;
};

class CRendererBase
{
public:
  virtual ~CRendererBase();

  virtual CRenderInfo GetRenderInfo();
  virtual bool Configure(const VideoPicture &picture, float fps, unsigned int orientation);
  virtual bool Supports(ESCALINGMETHOD method) = 0;
  virtual bool WantsDoublePass() { return false; };
  virtual bool NeedBuffer(int idx) { return false; }

  void AddVideoPicture(const VideoPicture &picture, int index);
  void Render(int index, int index2, CD3DTexture& target, const CRect& sourceRect, 
              const CRect& destRect, const CRect& viewRect, unsigned flags);
  void Render(CD3DTexture& target, const CRect& sourceRect, const CRect& destRect, 
              const CRect& viewRect, unsigned flags = 0);

  void ManageTextures();
  int NextBuffer() const;
  void ReleaseBuffer(int idx);
  bool Flush(bool saveBuffers);
  void SetBufferSize(int numBuffers) { m_iBuffersRequired = numBuffers; }

  static DXGI_FORMAT GetDXGIFormat(const VideoPicture &picture);
  static DXGI_FORMAT GetDXGIFormat(CVideoBuffer* videoBuffer);
  static AVPixelFormat GetAVFormat(DXGI_FORMAT dxgi_format);
  static DXGI_HDR_METADATA_HDR10 GetDXGIHDR10MetaData(CRenderBuffer* rb);

protected:
  explicit CRendererBase(CVideoSettings& videoSettings);

  bool CreateIntermediateTarget(unsigned int width, unsigned int height, bool dynamic = false);
  void OnCMSConfigChanged(unsigned flags);
  void ReorderDrawPoints(const CRect& destRect, CPoint(&rotatedPoints)[4]) const;
  bool CreateRenderBuffer(int index);
  void DeleteRenderBuffer(int index);

  virtual void RenderImpl(CD3DTexture& target, CRect& sourceRect, CPoint (&destPoints)[4], uint32_t flags) = 0;
  virtual void FinalOutput(CD3DTexture& source, CD3DTexture& target, const CRect& sourceRect, const CPoint(&destPoints)[4]);

  virtual CRenderBuffer* CreateBuffer() = 0;
  virtual void UpdateVideoFilters();
  virtual void CheckVideoParameters();
  virtual void OnViewSizeChanged() {}
  virtual void OnOutputReset() {}
  virtual bool UseToneMapping() const { return m_toneMapping; }

  bool m_toneMapping = false;
  bool m_useDithering = false;
  bool m_cmsOn = false;
  bool m_clutLoaded = false;

  int m_iBufferIndex = 0;
  int m_iNumBuffers = 0;
  int m_iBuffersRequired = 0;
  int m_ditherDepth = 0;
  int m_cmsToken = -1;
  int m_lutSize = 0;
  unsigned m_sourceWidth = 0;
  unsigned m_sourceHeight = 0;
  unsigned m_viewWidth = 0;
  unsigned m_viewHeight = 0;
  unsigned m_renderOrientation = 0;
  float m_fps = 0.0f;
  uint64_t m_frameIdx = 0;

  AVPixelFormat m_format = AV_PIX_FMT_NONE;
  CD3DTexture m_IntermediateTarget;
  std::shared_ptr<COutputShader> m_outputShader;
  std::unique_ptr<CColorManager> m_colorManager;
  Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> m_pLUTView;
  CVideoSettings& m_videoSettings;
  std::map<int, CRenderBuffer*> m_renderBuffers;

  DXGI_HDR_METADATA_HDR10 m_lastHdr10 = {};
  DXGI_HDR_METADATA_HDR10 m_hdr10Display = {};
  int m_iCntMetaData = 0;
  bool m_isHdrEnabled = false;
  bool m_isHlgEnabled = false;
  bool m_isRec2020Enabled = false;
};
