/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "addons/kodi-addon-dev-kit/include/kodi/addon-instance/PeripheralUtils.h"
#include "peripherals/PeripheralTypes.h"
#include "threads/CriticalSection.h"

#import "platform/darwin/ios-common/peripherals/Input_Gamecontroller.h"
#include "platform/darwin/ios-common/peripherals/PeripheralBusDarwinEmbedded.h"

#include <string>
#include <vector>

#import <Foundation/Foundation.h>

@interface CBPeripheralBusDarwinEmbeddedManager : NSObject
{
  PERIPHERALS::CPeripheralBusDarwinEmbedded* parentClass;
  std::vector<kodi::addon::PeripheralEvent> m_digitalEvents;
  std::vector<kodi::addon::PeripheralEvent> m_axisEvents;
  CCriticalSection m_eventMutex;
}

@property(nonatomic, strong) Input_IOSGamecontroller* input_GC;

- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)parentClass;
- (PERIPHERALS::PeripheralScanResults)GetInputDevices;
- (void)DeviceAdded:(int)deviceID;
- (void)DeviceRemoved:(int)deviceID;
- (void)SetDigitalEvent:(kodi::addon::PeripheralEvent)event;
- (void)SetAxisEvent:(kodi::addon::PeripheralEvent)event;
- (std::vector<kodi::addon::PeripheralEvent>)GetButtonEvents;
- (std::vector<kodi::addon::PeripheralEvent>)GetAxisEvents;
- (GCCONTROLLER_TYPE)GetControllerType:(int)deviceID;
- (std::string)GetDeviceLocation:(int)deviceId;
- (void)displayMessage:(NSString*)message controllerID:(int)controllerID;
@end
