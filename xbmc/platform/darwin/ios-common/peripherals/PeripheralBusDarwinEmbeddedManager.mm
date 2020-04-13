/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "PeripheralBusDarwinEmbeddedManager.h"

#include "peripherals/PeripheralTypes.h"
#include "threads/SingleLock.h"
#include "utils/StringUtils.h"
#include "utils/log.h"

#include "platform/darwin/ios-common/peripherals/InputKey.h"
#import "platform/darwin/ios-common/peripherals/Input_Gamecontroller.h"
#include "platform/darwin/ios-common/peripherals/PeripheralBusDarwinEmbedded.h"

#pragma mark - objc implementation

@implementation CBPeripheralBusDarwinEmbeddedManager

#pragma mark - callbackClass inputdevices

- (PERIPHERALS::PeripheralScanResults)GetInputDevices
{
  PERIPHERALS::PeripheralScanResults scanresults = {};

  scanresults = [self.input_GC GetGCDevices];

  return scanresults;
}

- (void)DeviceAdded:(int)deviceID
{
  parentClass->SetScanResults([self GetInputDevices]);
  parentClass->callOnDeviceAdded([self GetDeviceLocation:deviceID]);
}

- (void)DeviceRemoved:(int)deviceID
{
  parentClass->callOnDeviceRemoved([self GetDeviceLocation:deviceID]);
  parentClass->SetScanResults([self GetInputDevices]);
}

#pragma mark - init

- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)initClass
{
  self = [super init];

  parentClass = initClass;

  _input_GC = [[Input_IOSGamecontroller alloc] initWithName:self];

  return self;
}

- (void)SetDigitalEvent:(kodi::addon::PeripheralEvent)event
{
  CSingleLock lock(m_eventMutex);

  m_digitalEvents.emplace_back(event);
}

- (void)SetAxisEvent:(kodi::addon::PeripheralEvent)event
{
  CSingleLock lock(m_eventMutex);

  m_axisEvents.emplace_back(event);
}

#pragma mark - GetEvents

- (std::vector<kodi::addon::PeripheralEvent>)GetAxisEvents
{
  std::vector<kodi::addon::PeripheralEvent> events;
  CSingleLock lock(m_eventMutex);

  for (unsigned int i = 0; i < m_axisEvents.size(); i++)
    events.emplace_back(m_axisEvents[i]);

  m_axisEvents.clear();

  return events;
}

- (std::vector<kodi::addon::PeripheralEvent>)GetButtonEvents
{
  std::vector<kodi::addon::PeripheralEvent> events;

  CSingleLock lock(m_eventMutex);
  // Only report a single event per button (avoids dropping rapid presses)
  std::vector<kodi::addon::PeripheralEvent> repeatButtons;

  for (const auto& digitalEvent : m_digitalEvents)
  {
    auto HasButton = [&digitalEvent](const kodi::addon::PeripheralEvent& event) {
      if (event.Type() == PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON)
        return event.DriverIndex() == digitalEvent.DriverIndex();
      return false;
    };

    if (std::find_if(events.begin(), events.end(), HasButton) == events.end())
      events.emplace_back(digitalEvent);
    else
      repeatButtons.emplace_back(digitalEvent);
  }

  m_digitalEvents.swap(repeatButtons);

  return events;
}

#pragma mark - callbackClass Controller ID matching

- (GCCONTROLLER_TYPE)GetControllerType:(int)deviceID
{

  GCCONTROLLER_TYPE gcinputtype = [self.input_GC GetGCControllerType:deviceID];

  if (gcinputtype != GCCONTROLLER_TYPE::NOTFOUND)
    return gcinputtype;

  return GCCONTROLLER_TYPE::UNKNOWN;
}

- (std::string)GetDeviceLocation:(int)deviceId
{
  return StringUtils::Format("%s%d", parentClass->getDeviceLocationPrefix().c_str(), deviceId);
}

#pragma mark - Logging Utils

- (void)displayMessage:(NSString*)message controllerID:(int)controllerID
{
  CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbeddedManager: inputhandler - ID {} - Action {}",
            controllerID, message.UTF8String);
}

@end
