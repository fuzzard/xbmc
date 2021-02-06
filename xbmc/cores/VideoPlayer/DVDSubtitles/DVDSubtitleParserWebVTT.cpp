/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

// Reference: https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API
// WEBVTT format

// - An optional byte order mark (BOM).
// - The string "WEBVTT".
// - An optional text header to the right of WEBVTT.
//   There must be at least one space after WEBVTT.
//   You could use this to add a description to the file.
//   You may use anything in the text header except newlines or the string "-->".
// - A blank line, which is equivalent to two consecutive newlines.
// - Zero or more cues or comments.
// - Zero or more blank lines.
// eg1. 
//      WEBVTT - This file has no cues.
//
// eg2.
//      WEBVTT - This file has cues.
//
//      14
//      00:01:14.815 --> 00:01:18.114
//      - What?
//      - Where are we now?

// Style and Note (comment) examples
// - STYLE unsupported
// - Comments are discarded and not used for output
// eg.
//     STYLE
//     ::cue {
//       background-image: linear-gradient(to bottom, dimgray, lightgray);
//       color: papayawhip;
//     }
//
//     NOTE comment blocks can be used between style blocks.
//
//     STYLE
//     ::cue(b) {
//       color: peachpuff;
//     }
//
//     00:00:00.000 --> 00:00:10.000
//     - Hello <b>world</b>.
//
//     NOTE style blocks cannot appear after the first cue.

// Cue identifier (optional)
// Is not required to start with a number, however often is. Must end with a single newline
//   eg. 1 - Title Crawl
//       2
//       Identifier string
// Cue Timing (Required) Cue Settings (Optional)
// - Cue Settings are optional but located after cue timing if provided
//    eg.  00:00:05.000 --> 00:00:10.000
//         00:00:05.000 --> 00:00:10.000 line:63% position:72% align:start
//         00:00:05.000 --> 00:00:10.000 line:0 position:20% size:60% align:start
//         00:00:05.000 --> 00:00:10.000 vertical:rt line:-1 align:end
// Cue Payload
// - The payload text may contain newlines but it cannot contain a blank line, which is equivalent
//   to two consecutive newlines. A blank line signifies the end of a cue.
// # Karaoke Style example
// - Same as 2 separate cues, but the part after the time will appear at that time
//    eg. 1
//        00:16.500 --> 00:18.500
//        When the moon <00:17.500>hits your eye
//
//        1
//        00:00:18.500 --> 00:00:20.500
//        Like a <00:19.000>big-a <00:19.500>pizza <00:20.000>pie
//
// # HTML Tags example
// Must contain closing tags
//    <i>Italics</i>
//    <b>BOLD</b>
//    <u>underline</u>          - not supported
//    <ruby></ruby><rt></rt>    - not supported
//    <v>voice</v>				- not supported

// ruby tag example
// <ruby>WWW<rt>World Wide Web</rt>oui<rt>yes</rt></ruby>
//
// World Wide Web yes
// WWW            oui


#include "DVDSubtitleParserWebVTT.h"

#include "DVDCodecs/Overlay/DVDOverlayText.h"
#include "DVDSubtitleTagWebVTT.h"
#include "cores/VideoPlayer/Interface/TimingConstants.h"
#include "utils/StringUtils.h"

CDVDSubtitleParserWebVTT::CDVDSubtitleParserWebVTT(std::unique_ptr<CDVDSubtitleStream> && pStream, const std::string& strFile)
    : CDVDSubtitleParserText(std::move(pStream), strFile)
{
}

CDVDSubtitleParserWebVTT::~CDVDSubtitleParserWebVTT()
{
  Dispose();
}

bool CDVDSubtitleParserWebVTT::Open(CDVDStreamInfo &hints)
{
  if (!CDVDSubtitleParserText::Open())
    return false;

  CDVDSubtitleTagWebVTT TagConv;
  if (!TagConv.Init())
    return false;

  char line[1024];
  std::string strLine;

  while (m_pStream->ReadLine(line, sizeof(line)))
  {
    strLine = line;
    StringUtils::Trim(strLine);

    if (strLine.length() > 0)
    {
      // Comment block - discard
      if (StringUtils::StartsWithNoCase(strLine, "NOTE"))
      {
        while (m_pStream->ReadLine(line, sizeof(line)))
        {
          strLine = line;
          StringUtils::Trim(strLine);

          // empty line, end of comment
          if (strLine.length() <= 0) break;
        }      
      }
      // CSS Style Block
      else if (StringUtils::StartsWithNoCase(strLine, "STYLE"))
      {
        //! @TODO css styling - just discard for now
        while (m_pStream->ReadLine(line, sizeof(line)))
        {
          strLine = line;
          StringUtils::Trim(strLine);

          // empty line, end style block
          if (strLine.length() <= 0) break;
        }  
      }
      char sep;
      int hh1, mm1, ss1, ms1, hh2, mm2, ss2, ms2;
      char cuesettings[4096] = {0};
      
      // WebVTT supports 2 time info formats
      // HH:MM:SS.MS or MM:SS.MS

      // optional cuesetting max 4095 chars.
      // Posix supports %ms which allocates to size, but windows does not, so go with
      // the fixed size buffer for agnostic platform support
      int c = sscanf(strLine.c_str(), "%d%c%d%c%d%c%d --> %d%c%d%c%d%c%d %4095c\n",
                     &hh1, &sep, &mm1, &sep, &ss1, &sep, &ms1,
                     &hh2, &sep, &mm2, &sep, &ss2, &sep, &ms2, &cuesettings);

      if (c == 14 || c == 15) // time info format - hh:mm:ss.ms
      {
        std::string strcuesettings(cuesettings);

        if (!strcuesettings.empty())
        {
          //! @TODO parse cuesettings to support them
        }
        
        CDVDOverlayText* pOverlay = new CDVDOverlayText();
        pOverlay->Acquire(); // increase ref count with one so that we can hold a handle to this overlay

        pOverlay->iPTSStartTime = ((double)(((hh1 * 60 + mm1) * 60) + ss1) * 1000 + ms1) * (DVD_TIME_BASE / 1000);
        pOverlay->iPTSStopTime  = ((double)(((hh2 * 60 + mm2) * 60) + ss2) * 1000 + ms2) * (DVD_TIME_BASE / 1000);

        while (m_pStream->ReadLine(line, sizeof(line)))
        {
          strLine = line;
          StringUtils::Trim(strLine);

          // empty line, next subtitle is about to start
          if (strLine.length() <= 0) break;

          TagConv.ConvertLine(pOverlay, strLine.c_str(), strLine.length());
        }
        TagConv.CloseTag(pOverlay);
        m_collection.Add(pOverlay);
      }
      else
      {
        // optional cuesetting max 4095 chars.
        // Posix supports %ms which allocates to size, but windows does not, so go with
        // the fixed size buffer for agnostic platform support
        c = sscanf(strLine.c_str(), "%d%c%d%c%d --> %d%c%d%c%d %4095c\n",
                   &mm1, &sep, &ss1, &sep, &ms1,
                   &mm2, &sep, &ss2, &sep, &ms2, &cuesettings);
        if (c == 10 || c == 11) // time info format - mm:ss.ms
        {
          std::string strcuesettings(cuesettings);

          if (!strcuesettings.empty())
          {
            //! @TODO parse cuesettings to support them
          }

          CDVDOverlayText* pOverlay = new CDVDOverlayText();
          pOverlay->Acquire(); // increase ref count with one so that we can hold a handle to this overlay

          pOverlay->iPTSStartTime = ((double)((mm1 * 60) + ss1) * 1000 + ms1) * (DVD_TIME_BASE / 1000);
          pOverlay->iPTSStopTime  = ((double)((mm2 * 60) + ss2) * 1000 + ms2) * (DVD_TIME_BASE / 1000);

          while (m_pStream->ReadLine(line, sizeof(line)))
          {
            strLine = line;
            StringUtils::Trim(strLine);

            // empty line, next subtitle is about to start
            if (strLine.length() <= 0) break;

            TagConv.ConvertLine(pOverlay, strLine.c_str(), strLine.length());
          }
          TagConv.CloseTag(pOverlay);
          m_collection.Add(pOverlay);
        }
      }
    }
  }
  m_collection.Sort();
  return true;
}

