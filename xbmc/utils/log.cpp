/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "log.h"

#include "CompileInfo.h"
#include "filesystem/File.h"
#include "utils/URIUtils.h"

#if defined(TARGET_ANDROID)
#include "platform/android/utils/AndroidInterfaceForCLog.h"
#elif defined(TARGET_DARWIN)
#include "platform/darwin/utils/DarwinInterfaceForCLog.h"
#elif defined(TARGET_WINDOWS) || defined(TARGET_WIN10)
#include "platform/win32/utils/Win32InterfaceForCLog.h"
#else
#include "platform/posix/utils/PosixInterfaceForCLog.h"
#endif

#include <cstring>

#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/dist_sink.h>

static constexpr unsigned char Utf8Bom[3] = { 0xEF, 0xBB, 0xBF };
static const std::string LogFileExtension = ".log";
static const std::string LogPattern = "%T.%e T:%-5t %8l %n: %v";

bool CLog::m_initialized = false;
std::shared_ptr<spdlog::sinks::dist_sink_mt> CLog::m_sinks = nullptr;
Logger CLog::m_defaultLogger = nullptr;

#if defined(TARGET_ANDROID)
std::unique_ptr<IPlatformLog> CLog::m_platform = std::make_unique<CAndroidInterfaceForCLog>();
#elif defined(TARGET_DARWIN)
std::unique_ptr<IPlatformLog> CLog::m_platform = std::make_unique<CDarwinInterfaceForCLog>();
#elif defined(TARGET_WINDOWS) || defined(TARGET_WIN10)
std::unique_ptr<IPlatformLog> CLog::m_platform = std::make_unique<CWin32InterfaceForCLog>();
#else
std::unique_ptr<IPlatformLog> CLog::m_platform = std::make_unique<CPosixInterfaceForCLog>();
#endif

int CLog::m_logLevel = LOG_LEVEL_DEBUG;
int CLog::m_extraLogLevels = 0;

void CLog::Initialize(const std::string& path)
{
  if (m_initialized)
    return;

  InitializeSinks();

  m_initialized = true;

  if (path.empty())
    return;

  // put together the path to the log file(s)
  std::string appName = CCompileInfo::GetAppName();
  StringUtils::ToLower(appName);
  const std::string filePathBase = URIUtils::AddFileToFolder(path, appName);
  const std::string filePath = filePathBase + LogFileExtension;
  const std::string oldFilePath = filePathBase + ".old" + LogFileExtension;

  // handle old.log by deleting an existing old.log and renaming the last log to old.log
  XFILE::CFile::Delete(oldFilePath);
  XFILE::CFile::Rename(filePath, oldFilePath);

  // write UTF-8 BOM
  {
    XFILE::CFile file;
    if (file.OpenForWrite(filePath, true))
      file.Write(Utf8Bom, sizeof(Utf8Bom));
  }

  // create the file sink
  auto fileSink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(m_platform->GetLogFilename(filePath), false);
  fileSink->set_pattern(LogPattern);

  // add it to the existing sinks
  m_sinks->add_sink(fileSink);
}

void CLog::Uninitialize()
{
  // flush all loggers
  spdlog::apply_all(
    [](std::shared_ptr<spdlog::logger> logger)
    {
      logger->flush();
    });

  // destroy the default logger
  m_defaultLogger.reset();

  // flush the file sink
  if (m_sinks != nullptr)
  {
    m_sinks->flush();
    m_sinks.reset();
  }

  // shutdown spdlog
  spdlog::shutdown();

  m_initialized = false;
}

void CLog::SetLogLevel(int level)
{
  if (level < LOG_LEVEL_NONE || level > LOG_LEVEL_MAX)
    return;

  m_logLevel = level;

  auto spdLevel = spdlog::level::info;
#if defined(_DEBUG) || defined(PROFILE)
  spdLevel = spdlog::level::trace;
#else
  if (level <= LOG_LEVEL_NONE)
    spdLevel = spdlog::level::off;
  else if (level >= LOG_LEVEL_DEBUG)
    spdLevel = spdlog::level::trace;
  else
    spdLevel = spdlog::level::info;
#endif

  if (m_defaultLogger != nullptr && m_defaultLogger->level() == spdLevel)
    return;

  spdlog::set_level(spdLevel);
  Log(spdlog::level::info, "Log level changed to \"%s\"", spdlog::level::to_string_view(spdLevel));
}

bool CLog::IsLogLevelLogged(int loglevel)
{
  const int extras = (loglevel & ~LOGMASK);
  if (extras != 0 && (m_extraLogLevels & extras) == 0)
    return false;

  if (m_logLevel >= LOG_LEVEL_DEBUG)
    return true;
  if (m_logLevel <= LOG_LEVEL_NONE)
    return false;

  return (loglevel & LOGMASK) >= LOGNOTICE;
}

Logger CLog::Get(const std::string& loggerName)
{
  // make sure the default sinks are initialized
  InitializeSinks();

  try
  {
    return CreateLogger(loggerName);
  }
  catch (const spdlog::spdlog_ex&)
  {
    // otherwise retrieve the existing logger
    return spdlog::get(loggerName);
  }
}

void CLog::InitializeSinks()
{
  if (m_sinks != nullptr)
    return;

  // create the default sink(s)
  m_sinks = std::make_shared<spdlog::sinks::dist_sink_mt>();

  // add platform-specific debug sinks
  m_platform->AddSinks(m_sinks);

  // create the default logger
  m_defaultLogger = CreateLogger("root");

  // register the default logger with spdlog
  spdlog::set_default_logger(m_defaultLogger);

  // set the formatting pattern globally
  spdlog::set_pattern(LogPattern);

  // flush on debug logs
  spdlog::flush_on(spdlog::level::debug);

  // set the log level
  SetLogLevel(m_logLevel);
}

Logger CLog::CreateLogger(const std::string& loggerName)
{
  // create the logger
  auto logger = std::make_shared<spdlog::logger>(loggerName, m_sinks);

  // initialize the logger
  spdlog::initialize_logger(logger);

  return logger;
}
