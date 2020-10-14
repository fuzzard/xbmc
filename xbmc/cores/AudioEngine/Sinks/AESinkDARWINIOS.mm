/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "cores/AudioEngine/Sinks/AESinkDARWINIOS.h"

#include "ServiceBroker.h"
#include "cores/AudioEngine/AESinkFactory.h"
#include "cores/AudioEngine/Sinks/darwin/CoreAudioHelpers.h"
#include "cores/AudioEngine/Utils/AERingBuffer.h"
#include "cores/AudioEngine/Utils/AEUtil.h"
#include "threads/Condition.h"
#include "utils/StringUtils.h"
#include "utils/log.h"
#include "windowing/WinSystem.h"

#include <sstream>

#import <AVFoundation/AVAudioSession.h>
#include <AudioToolbox/AudioToolbox.h>

#define CA_MAX_CHANNELS 8
static enum AEChannel CAChannelMap[CA_MAX_CHANNELS + 1] = {
    AE_CH_FL, AE_CH_FR, AE_CH_BL, AE_CH_BR, AE_CH_FC, AE_CH_LFE, AE_CH_SL, AE_CH_SR, AE_CH_NULL};

/***************************************************************************************/
/***************************************************************************************/
#if DO_440HZ_TONE_TEST
static void SineWaveGeneratorInitWithFrequency(SineWaveGenerator* ctx,
                                               double frequency,
                                               double samplerate)
{
  // Given:
  //   frequency in cycles per second
  //   2*PI radians per sine wave cycle
  //   sample rate in samples per second
  //
  // Then:
  //   cycles     radians     seconds     radians
  //   ------  *  -------  *  -------  =  -------
  //   second      cycle      sample      sample
  ctx->currentPhase = 0.0;
  ctx->phaseIncrement = frequency * 2 * M_PI / samplerate;
}

static int16_t SineWaveGeneratorNextSampleInt16(SineWaveGenerator* ctx)
{
  int16_t sample = INT16_MAX * sinf(ctx->currentPhase);

  ctx->currentPhase += ctx->phaseIncrement;
  // Keep the value between 0 and 2*M_PI
  while (ctx->currentPhase > 2 * M_PI)
    ctx->currentPhase -= 2 * M_PI;

  return sample / 4;
}
static float SineWaveGeneratorNextSampleFloat(SineWaveGenerator* ctx)
{
  float sample = MAXFLOAT * sinf(ctx->currentPhase);

  ctx->currentPhase += ctx->phaseIncrement;
  // Keep the value between 0 and 2*M_PI
  while (ctx->currentPhase > 2 * M_PI)
    ctx->currentPhase -= 2 * M_PI;

  return sample / 4;
}
#endif
/***************************************************************************************/
/***************************************************************************************/
@interface CAAudioUnitSink : NSObject
{
  //  CVideoSyncTVos* videoSyncImpl;
  bool m_setup;
  bool m_activated;
  AudioUnit m_audioUnit;
  AudioStreamBasicDescription m_outputFormat;
  AERingBuffer* m_buffer;

  bool m_mute;
  Float32 m_outputVolume;
  Float32 m_outputLatency;
  Float32 m_bufferDuration;

  unsigned int m_sampleRate;
  unsigned int m_frameSize;

  bool m_playing;
  volatile bool m_started;

  CAESpinSection m_render_section;
  volatile int64_t m_render_timestamp;
  volatile uint32_t m_render_frames;

  CCriticalSection mutex;
  XbmcThreads::ConditionVariable condVar;
}

- (bool)open:(AudioStreamBasicDescription)outputFormat;
- (bool)close;
- (bool)play:(bool)mute;
- (bool)mute:(bool)mute;
- (bool)pause;
- (void)drain;
- (void)getDelay:(AEDelayStatus&)status;
- (double)cacheSize;
- (unsigned int)write:(uint8_t*)data bytecount:(unsigned int)byte_count;
- (unsigned int)chunkSize;
- (unsigned int)getRealisedSampleRate;
- (Float64)getCoreAudioRealisedSampleRate;

- (void)setCoreAudioBuffersize;
- (bool)setCoreAudioInputFormat;
- (void)setCoreAudioPreferredSampleRate;
- (bool)setupAudio;
- (bool)checkSessionProperties;
- (bool)activateAudioSession;
- (bool)deactivateAudioSession:(int)retry;
- (void)deactivate;
@end

struct CAAudioUnitSinkWrapper
{
  CAAudioUnitSink* callbackClass;
};

@implementation CAAudioUnitSink

- (unsigned int)chunkSize
{
  return m_bufferDuration * m_sampleRate;
}

- (double)cacheSize
{
  return (double)m_buffer->GetMaxSize() / (double)(m_frameSize * m_sampleRate);
}

- (unsigned int)getRealisedSampleRate
{
  return m_outputFormat.mSampleRate;
}

- (Float64)getCoreAudioRealisedSampleRate
{
  return [AVAudioSession sharedInstance].sampleRate;
}

- (void)getDelay:(AEDelayStatus&)status
{
  CAESpinLock lock(m_render_section);
  do
  {
    status.delay = (double)m_buffer->GetReadSize() / m_frameSize;
    status.delay += (double)m_render_frames;
    status.tick = m_render_timestamp;
  } while (lock.retry());

  status.delay /= m_sampleRate;
  status.delay += m_bufferDuration + m_outputLatency;
}

- (void)setCoreAudioBuffersize
{
  // set the buffer size, this affects the number of samples
  // that get rendered every time the audio callback is fired.
  NSTimeInterval preferredBufferSize =
      512 * m_outputFormat.mChannelsPerFrame / m_outputFormat.mSampleRate;
  CLog::Log(LOGINFO, "{} setting buffer duration to {}", __PRETTY_FUNCTION__, preferredBufferSize);

  NSError* error;
  if (![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:preferredBufferSize
                                                               error:&error])
  {
    CLog::Log(LOGWARNING, "{} preferredBufferSize couldn't be set (error: {})", __PRETTY_FUNCTION__,
              error.localizedDescription.UTF8String);
  }
}

- (bool)setCoreAudioInputFormat
{
  // Set the output stream format
  UInt32 ioDataSize = sizeof(AudioStreamBasicDescription);
  OSStatus status = AudioUnitSetProperty(m_audioUnit, kAudioUnitProperty_StreamFormat,
                                         kAudioUnitScope_Input, 0, &m_outputFormat, ioDataSize);
  if (status != noErr)
  {
    CLog::Log(LOGERROR, "%s error setting stream format on audioUnit (error: %d)",
              __PRETTY_FUNCTION__, (int)status);
    return false;
  }
  return true;
}

- (void)setCoreAudioPreferredSampleRate
{
  double preferredSampleRate = m_outputFormat.mSampleRate;
  CLog::Log(LOGINFO, "{} requesting hw samplerate {}", __PRETTY_FUNCTION__, preferredSampleRate);

  NSError* error;
  if (![[AVAudioSession sharedInstance] setPreferredSampleRate:preferredSampleRate error:&error])
  {
    CLog::Log(LOGWARNING, "{} preferredSampleRate couldn't be set (error: {})", __PRETTY_FUNCTION__,
              error.localizedDescription.UTF8String);
  }
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
  if ([keyPath isEqual:@"outputVolume"])
  {
    m_outputVolume = [[AVAudioSession sharedInstance] outputVolume];
  }
}

- (bool)setupAudio
{
  OSStatus status = noErr;
  if (m_setup && m_audioUnit)
    return true;

  // need to fetch maximumOutputNumberOfChannels when active
  //NSInteger maxchannels = [[AVAudioSession sharedInstance]  maximumOutputNumberOfChannels];
  NSError* err = nullptr;

  // darwin docs and technotes say,
  // deavtivate the session before changing the values
  if (![self deactivateAudioSession:3])
    CLog::Log(LOGWARNING, "AVAudioSession setActive NO failed");

  /*  [[AVAudioSession sharedInstance] setPreferredOutputNumberOfChannels:maxchannels error:&err];
  
  if (err != nil)
    CLog::Log(LOGWARNING, "%s setPreferredOutputNumberOfChannels failed", __PRETTY_FUNCTION__);
*/
  //AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
  //    sessionPropertyCallback, this);

  // Audio Unit Setup
  // Describe a default output unit.
  AudioComponentDescription description = {};
  description.componentType = kAudioUnitType_Output;
  description.componentSubType = kAudioUnitSubType_RemoteIO;
  description.componentManufacturer = kAudioUnitManufacturer_Apple;

  // Get component
  AudioComponent component;
  component = AudioComponentFindNext(NULL, &description);
  status = AudioComponentInstanceNew(component, &m_audioUnit);
  if (status != noErr)
  {
    CLog::Log(LOGERROR, "%s error creating audioUnit (error: %d)", __PRETTY_FUNCTION__,
              (int)status);
    return false;
  }

  [self setCoreAudioPreferredSampleRate];

  // Get the output samplerate for knowing what was setup in reality
  Float64 realisedSampleRate = [self getCoreAudioRealisedSampleRate];
  if (m_outputFormat.mSampleRate != realisedSampleRate)
  {
    CLog::Log(LOGINFO,
              "%s couldn't set requested samplerate %d, coreaudio will resample to %d instead",
              __PRETTY_FUNCTION__, (int)m_outputFormat.mSampleRate, (int)realisedSampleRate);
    // if we don't ca to resample - but instead let activeae resample -
    // reflect the realised samplerate to the outputformat here
    // well maybe it is handy in the future - as of writing this
    // ca was about 6 times faster then activeae ;)
    //m_outputFormat.mSampleRate = realisedSampleRate;
    //m_sampleRate = realisedSampleRate;
  }

  [self setCoreAudioBuffersize];
  if ([self setCoreAudioInputFormat])
    return false;

  // Attach a render callback on the unit
  AURenderCallbackStruct callbackStruct = {};
  callbackStruct.inputProc = renderCallback;
  callbackStruct.inputProcRefCon = (__bridge void*)(self);
  status = AudioUnitSetProperty(m_audioUnit, kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct));
  if (status != noErr)
  {
    CLog::Log(LOGERROR, "%s error setting render callback for audioUnit (error: %d)",
              __PRETTY_FUNCTION__, (int)status);
    return false;
  }

  status = AudioUnitInitialize(m_audioUnit);
  if (status != noErr)
  {
    CLog::Log(LOGERROR, "%s error initializing audioUnit (error: %d)", __PRETTY_FUNCTION__,
              (int)status);
    return false;
  }

  [self checkSessionProperties];

  m_setup = true;
  std::string formatString;
  CLog::Log(LOGINFO, "%s setup audio format: %s", __PRETTY_FUNCTION__,
            StreamDescriptionToString(m_outputFormat, formatString));

  // reactivate the session
  err = nullptr;
  if (![[AVAudioSession sharedInstance] setActive:YES error:&err])
    CLog::Log(LOGWARNING, "AVAudioSession setActive YES failed: %ld", (long)err.code);

  return m_setup;
}

- (bool)mute:(bool)mute
{
  m_mute = mute;

  return true;
}

- (unsigned int)write:(uint8_t*)data bytecount:(unsigned int)frames
{
  if (m_buffer->GetWriteSize() < frames * m_frameSize)
  { // no space to write - wait for a bit
    CSingleLock lock(mutex);
    unsigned int timeout = 900 * frames / m_sampleRate;
    if (!m_started)
      timeout = 4500;

    // we are using a timer here for being sure for timeouts
    // condvar can be woken spuriously as signaled
    XbmcThreads::EndTime timer(timeout);
    condVar.wait(mutex, timeout);
    if (!m_started && timer.IsTimePast())
    {
      CLog::Log(LOGERROR, "%s engine didn't start in %d ms!", __FUNCTION__, timeout);
      return INT_MAX;
    }
  }

  unsigned int write_frames = std::min(frames, m_buffer->GetWriteSize() / m_frameSize);
  if (write_frames)
    m_buffer->Write(data, write_frames * m_frameSize);

  return write_frames;
}

- (void)drain
{
  unsigned int bytes = m_buffer->GetReadSize();
  unsigned int totalBytes = bytes;
  int maxNumTimeouts = 3;
  unsigned int timeout = 900 * bytes / (m_sampleRate * m_frameSize);
  while (bytes && maxNumTimeouts > 0)
  {
    CSingleLock lock(mutex);
    XbmcThreads::EndTime timer(timeout);
    condVar.wait(mutex, timeout);

    bytes = m_buffer->GetReadSize();
    // if we timeout and don't
    // consume bytes - decrease maxNumTimeouts
    if (timer.IsTimePast() && bytes == totalBytes)
      maxNumTimeouts--;
    totalBytes = bytes;
  }
}

- (bool)open:(AudioStreamBasicDescription)outputFormat
{
  m_mute = false;
  m_setup = false;
  m_outputFormat = outputFormat;
  m_outputLatency = 0.0;
  m_bufferDuration = 0.0;
  m_outputVolume = 1.0;
  m_sampleRate = (unsigned int)outputFormat.mSampleRate;
  m_frameSize = outputFormat.mChannelsPerFrame * outputFormat.mBitsPerChannel / 8;

  // TODO: Reduce the size of this buffer, pre-calculate the size based on how large
  //         the buffers are that CA calls us with in the renderCallback - perhaps call
  //         the checkSessionProperties() before running this?
  m_buffer = new AERingBuffer(16384);

  return [self setupAudio];
}

- (bool)play:(bool)mute
{
  if (!m_playing)
  {
    if ([self activateAudioSession])
    {
      [self mute:mute];
      m_playing = !AudioOutputUnitStart(m_audioUnit);
    }
  }

  return m_playing;
}

- (bool)pause
{
  if (m_playing)
    m_playing = AudioOutputUnitStop(m_audioUnit);

  return m_playing;
}

- (bool)close
{
  [self deactivate];

  delete m_buffer;
  m_buffer = NULL;

  m_started = false;
  return true;
}

- (bool)checkSessionProperties
{
  m_outputVolume = [AVAudioSession sharedInstance].outputVolume;
  m_outputLatency = [AVAudioSession sharedInstance].outputLatency;
  m_bufferDuration = [AVAudioSession sharedInstance].IOBufferDuration;

  CLog::Log(LOGDEBUG, "{}: volume = {}, latency = {}, buffer = {}", __FUNCTION__, m_outputVolume,
            m_outputLatency, m_bufferDuration);
  return true;
}

#pragma mark - rendercallback
// Audio Render callbacks are highly advised to not use obj c constructs
// See http://atastypixel.com/blog/four-common-mistakes-in-audio-development/
static OSStatus renderCallback(void* inRefCon,
                               AudioUnitRenderActionFlags* ioActionFlags,
                               const AudioTimeStamp* inTimeStamp,
                               UInt32 inOutputBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList* ioData)
{
  CAAudioUnitSink* sink = (__bridge CAAudioUnitSink*)inRefCon;

  sink->m_render_section.enter();
  sink->m_started = true;

  for (unsigned int i = 0; i < ioData->mNumberBuffers; i++)
  {
    // buffers come from CA already zero'd, so just copy what is wanted
    unsigned int wanted = ioData->mBuffers[i].mDataByteSize;
    unsigned int bytes = std::min(sink->m_buffer->GetReadSize(), wanted);
    sink->m_buffer->Read((unsigned char*)ioData->mBuffers[i].mData, bytes);
    LogLevel(bytes, wanted);

    if (bytes == 0)
      *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
  }

  sink->m_render_timestamp = inTimeStamp->mHostTime;
  sink->m_render_frames = inNumberFrames;
  sink->m_render_section.leave();
  // tell the sink we're good for more data
  sink->condVar.notifyAll();

  return noErr;
}

inline void LogLevel(unsigned int got, unsigned int wanted)
{
  static unsigned int lastReported = INT_MAX;
  if (got != wanted)
  {
    if (got != lastReported)
    {
      CLog::Log(LOGWARNING, "DARWINIOS: %sflow (%u vs %u bytes)", got > wanted ? "over" : "under",
                got, wanted);
      lastReported = got;
    }
  }
  else
    lastReported = INT_MAX; // indicate we were good at least once
}

#pragma mark - Start/Stop AudioSession

- (void)deactivate
{
  if (m_activated)
  {
    pause();
    // detach the render callback on the unit
    AURenderCallbackStruct callbackStruct = {0};
    AudioUnitSetProperty(m_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input,
                         0, &callbackStruct, sizeof(callbackStruct));
    AudioUnitUninitialize(m_audioUnit);
    AudioComponentInstanceDispose(m_audioUnit), m_audioUnit = nullptr;

    m_setup = false;
    m_activated = false;
  }
}

- (bool)deactivateAudioSession:(int)retry
{
  if (--retry < 0)
    return false;

  bool rtn = false;

  //    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange,
  //      sessionPropertyCallback, this);
  //    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume,
  //      sessionPropertyCallback, this);

  // Audio session may not deactivate if in use with a higher priority elsewhere
  // ie. phonecall, notification. Possibly add a loop to retry
  if (![[AVAudioSession sharedInstance] setActive:NO error:nil])
  {
    CLog::Log(LOGWARNING, "AVAudioSession setActive NO failed, count %d", retry);
    usleep(10 * 1000);
    rtn = [self deactivateAudioSession:retry];
  }
  else
  {
    rtn = true;
  }
  return rtn;
}

- (bool)activateAudioSession
{
  if (!m_activated)
  {
    if ([self setupAudio])
      m_activated = true;
  }

  return m_activated;
}

#pragma mark - init
- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  m_activated = false;
  m_buffer = nullptr;

  m_playing = false;
  m_started = false;

  m_render_timestamp = 0;
  m_render_frames = 0;

  //AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
  //    sessionPropertyCallback, this);

  [[AVAudioSession sharedInstance] addObserver:self
                                    forKeyPath:@"outputVolume"
                                       options:NSKeyValueObservingOptionNew
                                       context:nil];

  return self;
}

- (void)dealloc
{
  [self close];

  @try
  {
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];
  }
  @catch (NSException* exception)
  {
    // No observer active
  }
}

@end

/***************************************************************************************/
/***************************************************************************************/
static void EnumerateDevices(AEDeviceInfoList& list)
{
  CAEDeviceInfo device;

  device.m_deviceName = "default";
  device.m_displayName = "Default";
  device.m_displayNameExtra = "";
  // TODO screen changing on ios needs to call
  // devices changed once this is available in active
  if (false)
  {
    device.m_deviceType = AE_DEVTYPE_IEC958; //allow passthrough for tvout
    device.m_streamTypes.push_back(CAEStreamInfo::STREAM_TYPE_AC3);
    device.m_streamTypes.push_back(CAEStreamInfo::STREAM_TYPE_DTSHD_CORE);
    device.m_streamTypes.push_back(CAEStreamInfo::STREAM_TYPE_DTS_2048);
    device.m_streamTypes.push_back(CAEStreamInfo::STREAM_TYPE_DTS_1024);
    device.m_streamTypes.push_back(CAEStreamInfo::STREAM_TYPE_DTS_512);
    device.m_dataFormats.push_back(AE_FMT_RAW);
  }
  else
    device.m_deviceType = AE_DEVTYPE_PCM;

  // add channel info
  CAEChannelInfo channel_info;
  for (UInt32 chan = 0; chan < 2; ++chan)
  {
    if (!device.m_channels.HasChannel(CAChannelMap[chan]))
      device.m_channels += CAChannelMap[chan];
    channel_info += CAChannelMap[chan];
  }

  // there are more supported ( one of those 2 gets resampled
  // by coreaudio anyway) - but for keeping it save ignore
  // the others...
  device.m_sampleRates.push_back(44100);
  device.m_sampleRates.push_back(48000);

  device.m_dataFormats.push_back(AE_FMT_S16LE);
  //device.m_dataFormats.push_back(AE_FMT_S24LE3);
  //device.m_dataFormats.push_back(AE_FMT_S32LE);
  device.m_dataFormats.push_back(AE_FMT_FLOAT);
  device.m_wantsIECPassthrough = true;

  CLog::Log(LOGDEBUG, "EnumerateDevices:Device(%s)", device.m_deviceName.c_str());

  list.push_back(device);
}

/***************************************************************************************/
/***************************************************************************************/
AEDeviceInfoList CAESinkDARWINIOS::m_devices;

CAESinkDARWINIOS::CAESinkDARWINIOS() : m_audioSink(NULL)
{
}

void CAESinkDARWINIOS::Register()
{
  AE::AESinkRegEntry reg;
  reg.sinkName = "DARWINIOS";
  reg.createFunc = CAESinkDARWINIOS::Create;
  reg.enumerateFunc = CAESinkDARWINIOS::EnumerateDevicesEx;
  AE::CAESinkFactory::RegisterSink(reg);
}

IAESink* CAESinkDARWINIOS::Create(std::string& device, AEAudioFormat& desiredFormat)
{
  IAESink* sink = new CAESinkDARWINIOS();
  if (sink->Initialize(desiredFormat, device))
    return sink;

  delete sink;
  return nullptr;
}

Float64 getCoreAudioRealisedSampleRate()
{
  return [AVAudioSession sharedInstance].sampleRate;
}

bool CAESinkDARWINIOS::Initialize(AEAudioFormat& format, std::string& device)
{
  bool found = false;
  bool forceRaw = false;

  std::string devicelower = device;
  StringUtils::ToLower(devicelower);
  for (size_t i = 0; i < m_devices.size(); i++)
  {
    if (devicelower.find(m_devices[i].m_deviceName) != std::string::npos)
    {
      m_info = m_devices[i];
      found = true;
      break;
    }
  }

  if (!found)
    return false;

  AudioStreamBasicDescription audioFormat = {};

  if (format.m_dataFormat == AE_FMT_FLOAT)
    audioFormat.mFormatFlags |= kLinearPCMFormatFlagIsFloat;
  else // this will be selected when AE wants AC3 or DTS or anything other then float
  {
    audioFormat.mFormatFlags |= kLinearPCMFormatFlagIsSignedInteger;
    if (format.m_dataFormat == AE_FMT_RAW)
      forceRaw = true;
    format.m_dataFormat = AE_FMT_S16LE;
  }

  format.m_channelLayout = m_info.m_channels;
  format.m_frameSize =
      format.m_channelLayout.Count() * (CAEUtil::DataFormatToBits(format.m_dataFormat) >> 3);


  audioFormat.mFormatID = kAudioFormatLinearPCM;
  switch (format.m_sampleRate)
  {
    case 11025:
    case 22050:
    case 44100:
    case 88200:
    case 176400:
      audioFormat.mSampleRate = 44100;
      break;
    default:
    case 8000:
    case 12000:
    case 16000:
    case 24000:
    case 32000:
    case 48000:
    case 96000:
    case 192000:
    case 384000:
      audioFormat.mSampleRate = 48000;
      break;
  }

  if (forceRaw) //make sure input and output samplerate match for preventing resampling
    audioFormat.mSampleRate = getCoreAudioRealisedSampleRate();

  audioFormat.mFramesPerPacket = 1;
  audioFormat.mChannelsPerFrame = 2; // ios only supports 2 channels
  audioFormat.mBitsPerChannel = CAEUtil::DataFormatToBits(format.m_dataFormat);
  audioFormat.mBytesPerFrame = format.m_frameSize;
  audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
  audioFormat.mFormatFlags |= kLinearPCMFormatFlagIsPacked;

#if DO_440HZ_TONE_TEST
  SineWaveGeneratorInitWithFrequency(&m_SineWaveGenerator, 440.0, audioFormat.mSampleRate);
#endif

  m_audioSink = new CAAudioUnitSinkWrapper;
  [m_audioSink->callbackClass open:audioFormat];

  format.m_frames = [m_audioSink->callbackClass chunkSize];
  // reset to the realised samplerate
  format.m_sampleRate = [m_audioSink->callbackClass getRealisedSampleRate];
  m_format = format;

  [m_audioSink->callbackClass play:false];

  return true;
}

void CAESinkDARWINIOS::Deinitialize()
{
  m_audioSink->callbackClass = nil;
  delete m_audioSink;
  m_audioSink = nullptr;
}

void CAESinkDARWINIOS::GetDelay(AEDelayStatus& status)
{
  if (m_audioSink)
    [m_audioSink->callbackClass getDelay:status];
  else
    status.SetDelay(0.0);
}

double CAESinkDARWINIOS::GetCacheTotal()
{
  if (m_audioSink)
    return [m_audioSink->callbackClass cacheSize];
  return 0.0;
}

unsigned int CAESinkDARWINIOS::AddPackets(uint8_t** data, unsigned int frames, unsigned int offset)
{
  uint8_t* buffer = data[0] + offset * m_format.m_frameSize;
#if DO_440HZ_TONE_TEST
  if (m_format.m_dataFormat == AE_FMT_FLOAT)
  {
    float* samples = (float*)buffer;
    for (unsigned int j = 0; j < frames; j++)
    {
      float sample = SineWaveGeneratorNextSampleFloat(&m_SineWaveGenerator);
      *samples++ = sample;
      *samples++ = sample;
    }
  }
  else
  {
    int16_t* samples = (int16_t*)buffer;
    for (unsigned int j = 0; j < frames; j++)
    {
      int16_t sample = SineWaveGeneratorNextSampleInt16(&m_SineWaveGenerator);
      *samples++ = sample;
      *samples++ = sample;
    }
  }
#endif
  if (m_audioSink)
    return [m_audioSink->callbackClass write:buffer bytecount:frames];
  return 0;
}

void CAESinkDARWINIOS::Drain()
{
  if (m_audioSink)
    [m_audioSink->callbackClass drain];
}

bool CAESinkDARWINIOS::HasVolume()
{
  return false;
}

void CAESinkDARWINIOS::EnumerateDevicesEx(AEDeviceInfoList& list, bool force)
{
  m_devices.clear();
  EnumerateDevices(m_devices);
  list = m_devices;
}
