/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "PeripheralBusDarwinEmbedded.h"

#include "ServiceBroker.h"
#include "addons/kodi-addon-dev-kit/include/kodi/addon-instance/PeripheralUtils.h"
#include "peripherals/bus/PeripheralBus.h"
#include "peripherals/devices/PeripheralJoystick.h"
#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"
#include "utils/log.h"

#include "platform/darwin/ios-common/peripherals/InputKey.h"

#import <Foundation/Foundation.h>
#import <GameController/GCController.h>

#pragma mark - objc interface

@interface CBPeripheralBusDarwinEmbedded : NSObject
{
  PERIPHERALS::CPeripheralBusDarwinEmbedded* parentClass;
  NSMutableArray* controllerArray;
  std::vector<kodi::addon::PeripheralEvent> m_digitalEvents;
  std::vector<kodi::addon::PeripheralEvent> m_axisEvents;
  CCriticalSection m_eventMutex;
  BOOL dpadLeftPressed;
  BOOL dpadRightPressed;
  BOOL dpadUpPressed;
  BOOL dpadDownPressed;
}
- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)parentClass;
- (PERIPHERALS::PeripheralScanResults)GetInputDevices;
- (std::vector<kodi::addon::PeripheralEvent>)GetButtonEvents;
- (std::vector<kodi::addon::PeripheralEvent>)GetAxisEvents;
- (GCCONTROLLER_TYPE)GetControllerType:(int)deviceID;
- (std::string)GetDeviceLocation:(int)deviceId;
@end

#define JOYSTICK_PROVIDER_DARWINEMBEDDED "darwinembedded"

static const std::string DeviceLocationPrefix = "darwinembedded/inputdevice/";

struct PeripheralBusDarwinEmbeddedWrapper
{
  CBPeripheralBusDarwinEmbedded* callbackClass;
};

PERIPHERALS::CPeripheralBusDarwinEmbedded::CPeripheralBusDarwinEmbedded(CPeripherals& manager)
  : CPeripheralBus("PeripBusDarwinEmbedded", manager, PERIPHERAL_BUS_DARWINEMBEDDED)
{
  m_peripheralDarwinEmbedded = std::make_unique<PeripheralBusDarwinEmbeddedWrapper>();
  m_peripheralDarwinEmbedded->callbackClass =
      [[CBPeripheralBusDarwinEmbedded alloc] initWithName:this];
  m_bNeedsPolling = false;

  // get all currently connected input devices
  m_scanResults = GetInputDevices();
}

PERIPHERALS::CPeripheralBusDarwinEmbedded::~CPeripheralBusDarwinEmbedded()
{
  m_peripheralDarwinEmbedded->callbackClass = nil;
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::InitializeProperties(CPeripheral& peripheral)
{
  // Returns true regardless, why is it necessary?
  if (!CPeripheralBus::InitializeProperties(peripheral))
    return false;

  if (peripheral.Type() != PERIPHERALS::PERIPHERAL_JOYSTICK)
  {
    CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: invalid peripheral type: %s",
              PERIPHERALS::PeripheralTypeTranslator::TypeToString(peripheral.Type()));
    return false;
  }

  // deviceId will be our playerIndex
  int deviceId;
  if (!GetDeviceId(peripheral.Location(), deviceId))
  {
    CLog::Log(LOGWARNING,
              "CPeripheralBusDarwinEmbedded: failed to initialize properties for peripheral \"%s\"",
              peripheral.Location().c_str());
    return false;
  }

  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: Initializing device \"{}\"",
            peripheral.DeviceName());

  CPeripheralJoystick& joystick = static_cast<CPeripheralJoystick&>(peripheral);

  joystick.SetRequestedPort(deviceId);
  joystick.SetProvider(JOYSTICK_PROVIDER_DARWINEMBEDDED);

  GCCONTROLLER_TYPE controllerType =
      [m_peripheralDarwinEmbedded->callbackClass GetControllerType:deviceId];

  switch (controllerType)
  {
    case GCCONTROLLER_TYPE::EXTENDED:
      // Extended Gamepad - possible 15, power button on xbox controller recognized in testing
      joystick.SetButtonCount(14);
      joystick.SetAxisCount(4);
      break;
    case GCCONTROLLER_TYPE::MICRO:
      // Micro Gamepad
      joystick.SetButtonCount(6);
      joystick.SetAxisCount(0);
      break;
    case GCCONTROLLER_TYPE::UNKNOWN:
    case GCCONTROLLER_TYPE::UNUSED:
      CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: Unknown Controller Type");
      return false;
  }

  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: Device has %u buttons and %u axes",
            joystick.ButtonCount(), joystick.AxisCount());

  return true;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::Initialise(void)
{
  CPeripheralBus::Initialise();
  TriggerDeviceScan();
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::PerformDeviceScan(PeripheralScanResults& results)
{
  CSingleLock lock(m_critSectionResults);
  results = m_scanResults;

  return true;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::SetScanResults(
    const PERIPHERALS::PeripheralScanResults resScanResults)
{
  CSingleLock lock(m_critSectionResults);
  m_scanResults = resScanResults;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::GetEvents(
    std::vector<kodi::addon::PeripheralEvent>& events)
{
  CSingleLock lock(m_critSectionStates);
  std::vector<kodi::addon::PeripheralEvent> digitalEvents;
  digitalEvents = [m_peripheralDarwinEmbedded->callbackClass GetButtonEvents];

  std::vector<kodi::addon::PeripheralEvent> axisEvents;
  axisEvents = [m_peripheralDarwinEmbedded->callbackClass GetAxisEvents];

  events.reserve(digitalEvents.size() + axisEvents.size()); // preallocate memory
  events.insert(events.end(), digitalEvents.begin(), digitalEvents.end());
  events.insert(events.end(), axisEvents.begin(), axisEvents.end());
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::GetDeviceId(const std::string& deviceLocation,
                                                            int& deviceId)
{
  if (deviceLocation.empty() || !StringUtils::StartsWith(deviceLocation, DeviceLocationPrefix) ||
      deviceLocation.size() <= DeviceLocationPrefix.size())
    return false;

  std::string strDeviceId = deviceLocation.substr(DeviceLocationPrefix.size());
  if (!StringUtils::IsNaturalNumber(strDeviceId))
    return false;

  deviceId = static_cast<int>(strtol(strDeviceId.c_str(), nullptr, 10));
  return true;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::ProcessEvents()
{
  std::vector<kodi::addon::PeripheralEvent> events;
  {
    CSingleLock lock(m_critSectionStates);

    // Todo: Multiple controller event processing
    GetEvents(events);
  }

  for (const auto& event : events)
  {
    PeripheralPtr device = GetPeripheral(GetDeviceLocation(event.PeripheralIndex()));
    if (!device || device->Type() != PERIPHERAL_JOYSTICK)
      continue;

    CPeripheralJoystick* joystick = static_cast<CPeripheralJoystick*>(device.get());
    switch (event.Type())
    {
      case PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON:
      {
        const bool bPressed = (event.ButtonState() == JOYSTICK_STATE_BUTTON_PRESSED);
        joystick->OnButtonMotion(event.DriverIndex(), bPressed);
        break;
      }
      case PERIPHERAL_EVENT_TYPE_DRIVER_AXIS:
      {
        joystick->OnAxisMotion(event.DriverIndex(), event.AxisState());
        break;
      }
      default:
        break;
    }
  }
  {
    CSingleLock lock(m_critSectionStates);
    // ToDo: Multiple controller handling
    PeripheralPtr device = GetPeripheral(GetDeviceLocation(0));

    if (device && device->Type() == PERIPHERAL_JOYSTICK)
      static_cast<CPeripheralJoystick*>(device.get())->ProcessAxisMotions();
  }
}

std::string PERIPHERALS::CPeripheralBusDarwinEmbedded::GetDeviceLocation(int deviceId)
{
  return [m_peripheralDarwinEmbedded->callbackClass GetDeviceLocation:deviceId];
}

PERIPHERALS::PeripheralScanResults PERIPHERALS::CPeripheralBusDarwinEmbedded::GetInputDevices()
{
  CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: scanning for input devices...");

  return [m_peripheralDarwinEmbedded->callbackClass GetInputDevices];
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::callOnDeviceAdded(const std::string strLocation)
{
  OnDeviceAdded(strLocation);
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::callOnDeviceRemoved(const std::string strLocation)
{
  OnDeviceRemoved(strLocation);
}

#pragma mark - objc implementation

@implementation CBPeripheralBusDarwinEmbedded

#pragma mark - callbackClass inputdevices

- (PERIPHERALS::PeripheralScanResults)GetInputDevices
{
  PERIPHERALS::PeripheralScanResults scanresults;

  if ([controllerArray count] == 0)
    return scanresults;

  for (GCController* controller in controllerArray)
  {
    PERIPHERALS::PeripheralScanResult peripheralScanResult;
    peripheralScanResult.m_type = PERIPHERALS::PERIPHERAL_JOYSTICK;
    peripheralScanResult.m_strLocation =
        [self GetDeviceLocation:static_cast<int>(controller.playerIndex)];
    peripheralScanResult.m_iVendorId = 0;
    peripheralScanResult.m_iProductId = 0;
    peripheralScanResult.m_mappedType = PERIPHERALS::PERIPHERAL_JOYSTICK;

    if (controller.extendedGamepad)
    {
      peripheralScanResult.m_strDeviceName = "Extended Gamepad";
    }
    else if (controller.microGamepad)
    {
      peripheralScanResult.m_strDeviceName = "Micro Gamepad";
    }

    peripheralScanResult.m_busType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_mappedBusType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_iSequence = 0;
    scanresults.m_results.push_back(peripheralScanResult);
  }

  return scanresults;
}

#pragma mark - init

- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)initClass
{
  self = [super init];

  [self addModeSwitchObserver];
  parentClass = initClass;

  controllerArray = [[NSMutableArray alloc] init];

  auto controllers = [GCController controllers];
  // Iterate through any pre-existing controller connections at startup to enable value handlers
  if ([controllers count] > 0)
  {
    for (GCController* controller in controllers)
    {
      [self controllerConnection:controller];
    }
  }

  return self;
}

#pragma mark - Notificaton Observer

- (void)addModeSwitchObserver
{
  // notifications for controller (dis)connect
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(controllerWasConnected:)
                                               name:GCControllerDidConnectNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(controllerWasDisconnected:)
                                               name:GCControllerDidDisconnectNotification
                                             object:nil];
}

#pragma mark - Controller connection

- (void)controllerWasConnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;

  [self controllerConnection:controller];
  parentClass->SetScanResults([self GetInputDevices]);
}

- (void)controllerConnection:(GCController*)controller
{
  for (id controlObj in controllerArray)
  {
    if ([controlObj isEqual:controller])
    {
      CLog::Log(LOGINFO,
                "CPeripheralBusDarwinEmbedded: ignoring input device with ID {} already known",
                [controller.vendorName UTF8String]);
      return;
    }
  }

  // ToDo: Manage multiple player controllers
  // Assign playerIndex - GCControllerPlayerIndex1 - GCControllerPlayerIndex4

  controller.playerIndex = GCControllerPlayerIndex1;

  // set microgamepad to absolute values for dpad (ie center touchpad is 0,0)
  if (controller.microGamepad != nil)
    controller.microGamepad.reportsAbsoluteDpadValues = YES;

  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: input device with ID {} playerIndex {} added ",
            [controller.vendorName UTF8String], (unsigned long)controller.playerIndex);
  [controllerArray addObject:controller];
  parentClass->SetScanResults([self GetInputDevices]);
  parentClass->callOnDeviceAdded([self GetDeviceLocation:static_cast<int>(controller.playerIndex)]);

  [self registerChangeHandler:controller];
}

- (void)registerChangeHandler:(GCController*)controller
{
  if (controller.extendedGamepad)
  {
    CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: extendedGamepad changehandler added");
    // register block for input change detection
    [self extendedValueChangeHandler:controller];
  }
  else if (controller.microGamepad)
  {
    CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: microGamepad changehandler added");
    [self microValueChangeHandler:controller];
  }
}

#pragma mark - Controller disconnection

- (void)controllerWasDisconnected:(NSNotification*)notification
{
  // a controller was disconnected
  GCController* controller = (GCController*)notification.object;

  // remove the device from the Controller Array
  for (NSInteger i = 0; i < controllerArray.count; ++i)
  {
    if (![controllerArray[i] isEqual:controller])
      continue;

    CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: input device \"{}\" removed",
              [controller.vendorName UTF8String]);
    controller.playerIndex = GCControllerPlayerIndexUnset;
    [controllerArray removeObjectAtIndex:i];
    parentClass->callOnDeviceRemoved(
        [self GetDeviceLocation:static_cast<int>(controller.playerIndex)]);
    parentClass->SetScanResults([self GetInputDevices]);
    return;
  }

  CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: failed to remove input device {} Not Found ",
            [controller.vendorName UTF8String]);
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
  for (GCController* controller in controllerArray)
  {
    if (controller.playerIndex == deviceID)
    {
      if (controller.extendedGamepad != nil)
        return GCCONTROLLER_TYPE::EXTENDED;
      else if (controller.microGamepad != nil)
        return GCCONTROLLER_TYPE::MICRO;
    }
  }
  return GCCONTROLLER_TYPE::UNKNOWN;
}

- (std::string)GetDeviceLocation:(int)deviceId
{
  return StringUtils::Format("%s%d", DeviceLocationPrefix.c_str(), deviceId);
}

#pragma mark - Logging Utils

- (void)displayMessage:(NSString*)message controllerID:(int)controllerID
{
  CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: inputhandler - ID {} - Action {}",
            controllerID, message.UTF8String);
}

#pragma mark - GCMicroGamepad valueChangeHandler

- (void)microValueChangeHandler:(GCController*)controller
{
  GCMicroGamepad* profile = controller.microGamepad;
  profile.valueChangedHandler = ^(GCMicroGamepad* gamepad, GCControllerElement* element) {
    NSString* message = @"";

    kodi::addon::PeripheralEvent newEvent = {};
    newEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));

    CSingleLock lock(m_eventMutex);

    // A button
    if (gamepad.buttonA == element)
    {
      message = [self setButtonState:gamepad.buttonA
                           withEvent:&newEvent
                         withMessage:@"A Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                    GCCONTROLLER_MICRO_GAMEPAD_BUTTON::A}];
    }
    // X button
    if (gamepad.buttonX == element)
    {
      message = [self setButtonState:gamepad.buttonX
                           withEvent:&newEvent
                         withMessage:@"X Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                    GCCONTROLLER_MICRO_GAMEPAD_BUTTON::X}];
    }
#if __TV_OS_VERSION_MAX_ALLOWED >= 130000 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    // buttonMenu
    if (@available(iOS 13.0, tvOS 13.0, *))
    {
      if (gamepad.buttonMenu == element)
      {
        message = [self setButtonState:gamepad.buttonMenu
                             withEvent:&newEvent
                           withMessage:@"Menu Button"
                         withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                      GCCONTROLLER_MICRO_GAMEPAD_BUTTON::MENU}];
      }
    }
#endif
    // d-pad
    if (gamepad.dpad == element)
    {
      if ((gamepad.dpad.up.isPressed && !dpadUpPressed) ||
          (!gamepad.dpad.up.isPressed && dpadUpPressed))
      {
        message = @"D-Pad Up";
        if (!dpadUpPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::UP}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::UP}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadUpPressed = !dpadUpPressed;
      }
      if ((gamepad.dpad.down.isPressed && !dpadDownPressed) ||
          (!gamepad.dpad.down.isPressed && dpadDownPressed))
      {
        message = @"D-Pad Down";
        if (!dpadDownPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.down
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::DOWN}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.down
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::DOWN}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadDownPressed = !dpadDownPressed;
      }
      if ((gamepad.dpad.left.isPressed && !dpadLeftPressed) ||
          (!gamepad.dpad.left.isPressed && dpadLeftPressed))
      {
        message = @"D-Pad Left";
        if (!dpadLeftPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.left
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::LEFT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.left
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::LEFT}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadLeftPressed = !dpadLeftPressed;
      }
      if ((gamepad.dpad.right.isPressed && !dpadRightPressed) ||
          (!gamepad.dpad.right.isPressed && dpadRightPressed))
      {
        message = @"D-Pad Right";
        if (!dpadRightPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.right
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::RIGHT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.right
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::RIGHT}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadRightPressed = !dpadRightPressed;
      }
    }

    m_digitalEvents.emplace_back(newEvent);
    // ToDo: Debug Purposes only - excessive log spam
    // utilise spdlog for input compononent logging
    // [self displayMessage:message controllerID:static_cast<int>(controller.playerIndex)];
  };
}

#pragma mark - GCExtendedGamepad valueChangeHandler

- (void)extendedValueChangeHandler:(GCController*)controller
{
  auto profile = controller.extendedGamepad;
  profile.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
    NSString* message = @"";

    kodi::addon::PeripheralEvent newEvent = {};
    kodi::addon::PeripheralEvent axisEvent = {};
    newEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));
    axisEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));

    CSingleLock lock(m_eventMutex);

    // left trigger
    if (gamepad.leftTrigger == element)
    {
      message =
          [self setButtonState:gamepad.leftTrigger
                     withEvent:&newEvent
                   withMessage:@"Left Trigger"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFTTRIGGER}];
    }
    // right trigger
    if (gamepad.rightTrigger == element)
    {
      message =
          [self setButtonState:gamepad.rightTrigger
                     withEvent:&newEvent
                   withMessage:@"Right Trigger"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHTTRIGGER}];
    }
    // left shoulder button
    if (gamepad.leftShoulder == element)
    {
      message =
          [self setButtonState:gamepad.leftShoulder
                     withEvent:&newEvent
                   withMessage:@"Left Shoulder Button"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFTSHOULDER}];
    }
    // right shoulder button
    if (gamepad.rightShoulder == element)
    {
      message =
          [self setButtonState:gamepad.rightShoulder
                     withEvent:&newEvent
                   withMessage:@"Right Shoulder Button"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHTSHOULDER}];
    }
    // A button
    if (gamepad.buttonA == element)
    {
      message = [self setButtonState:gamepad.buttonA
                           withEvent:&newEvent
                         withMessage:@"A Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::A}];
    }
    // B button
    if (gamepad.buttonB == element)
    {
      message = [self setButtonState:gamepad.buttonB
                           withEvent:&newEvent
                         withMessage:@"B Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::B}];
    }
    // X button
    if (gamepad.buttonX == element)
    {
      message = [self setButtonState:gamepad.buttonX
                           withEvent:&newEvent
                         withMessage:@"X Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::X}];
    }
    // Y button
    if (gamepad.buttonY == element)
    {
      message = [self setButtonState:gamepad.buttonY
                           withEvent:&newEvent
                         withMessage:@"Y Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::Y}];
    }
    // buttonMenu
#if __TV_OS_VERSION_MAX_ALLOWED >= 130000 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, tvOS 13.0, *))
    {
      if (gamepad.buttonMenu == element)
      {
        message = [self setButtonState:gamepad.buttonMenu
                             withEvent:&newEvent
                           withMessage:@"Menu Button"
                         withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                      GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::MENU}];
      }
      // buttonOptions
      if (gamepad.buttonOptions == element)
      {
        message =
            [self setButtonState:gamepad.buttonOptions
                       withEvent:&newEvent
                     withMessage:@"Option Button"
                   withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::OPTION}];
      }
    }
#endif
    // d-pad
    if (gamepad.dpad == element)
    {
      if ((gamepad.dpad.up.isPressed && !dpadUpPressed) ||
          (!gamepad.dpad.up.isPressed && dpadUpPressed))
      {
        message = @"D-Pad Up";
        if (!dpadUpPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                        GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::UP}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                        GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::UP}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadUpPressed = !dpadUpPressed;
      }
      if ((gamepad.dpad.down.isPressed && !dpadDownPressed) ||
          (!gamepad.dpad.down.isPressed && dpadDownPressed))
      {
        message = @"D-Pad Down";
        if (!dpadDownPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.down
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::DOWN}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.down
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::DOWN}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadDownPressed = !dpadDownPressed;
      }
      if ((gamepad.dpad.left.isPressed && !dpadLeftPressed) ||
          (!gamepad.dpad.left.isPressed && dpadLeftPressed))
      {
        message = @"D-Pad Left";
        if (!dpadLeftPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.left
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.left
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFT}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadLeftPressed = !dpadLeftPressed;
      }
      if ((gamepad.dpad.right.isPressed && !dpadRightPressed) ||
          (!gamepad.dpad.right.isPressed && dpadRightPressed))
      {
        message = @"D-Pad Right";
        if (!dpadRightPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.right
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.right
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHT}];
          m_digitalEvents.emplace_back(newReleaseEvent);
        }
        dpadRightPressed = !dpadRightPressed;
      }
    }
    // left stick
    if (gamepad.leftThumbstick == element)
    {
      if (gamepad.leftThumbstick.up.isPressed && (gamepad.leftThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Up %f",
                                                          gamepad.leftThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_Y}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.leftThumbstick.down.isPressed && (gamepad.leftThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Down %f",
                                                          gamepad.leftThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_Y}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.leftThumbstick.left.isPressed && (gamepad.leftThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Left %f",
                                                          gamepad.leftThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_X}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.leftThumbstick.right.isPressed && (gamepad.leftThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Right %f",
                                                          gamepad.leftThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_X}];
        m_axisEvents.emplace_back(axisEvent);
      }
    }
    // right stick
    if (gamepad.rightThumbstick == element && (gamepad.rightThumbstick.yAxis.value != 0))
    {
      if (gamepad.rightThumbstick.up.isPressed)
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Up %f",
                                                          gamepad.rightThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_Y}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.rightThumbstick.down.isPressed && (gamepad.rightThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Down %f",
                                                          gamepad.rightThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_Y}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.rightThumbstick.left.isPressed && (gamepad.rightThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Left %f",
                                                          gamepad.rightThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_X}];
        m_axisEvents.emplace_back(axisEvent);
      }
      if (gamepad.rightThumbstick.right.isPressed && (gamepad.rightThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Right %f",
                                                          gamepad.rightThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_X}];
        m_axisEvents.emplace_back(axisEvent);
      }
    }

    m_digitalEvents.emplace_back(newEvent);
    // ToDo: Debug Purposes only - excessive log spam
    // utilise spdlog for input compononent logging
    //[self displayMessage:message controllerID:static_cast<int>(controller.playerIndex)];
  };
}

#pragma mark - valuechangehandler event state change

- (NSString*)setButtonState:(GCControllerButtonInput*)button
                  withEvent:(kodi::addon::PeripheralEvent*)event
                withMessage:(NSString*)message
              withInputInfo:(InputValueInfo)inputInfo
{
  event->SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);

  switch (inputInfo.controllerType)
  {
    case GCCONTROLLER_TYPE::EXTENDED:
      event->SetDriverIndex(static_cast<unsigned int>(inputInfo.extendedButton));
      break;
    case GCCONTROLLER_TYPE::MICRO:
      event->SetDriverIndex(static_cast<unsigned int>(inputInfo.microButton));
      break;
    case GCCONTROLLER_TYPE::UNKNOWN:
    case GCCONTROLLER_TYPE::UNUSED:
      return [message
          stringByAppendingFormat:@" ERROR:: CONTROLLER_TYPE %d", inputInfo.controllerType];
      break;
  }

  if (button.isPressed)
  {
    event->SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
    return [message stringByAppendingString:@" Pressed"];
  }
  else
  {
    event->SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
    return [message stringByAppendingString:@" Released"];
  }
}

- (NSString*)setAxisValue:(GCControllerAxisInput*)axisValue
                withEvent:(kodi::addon::PeripheralEvent*)event
              withMessage:(NSString*)message
            withInputInfo:(InputValueInfo)inputInfo
{
  event->SetType(PERIPHERAL_EVENT_TYPE_DRIVER_AXIS);
  event->SetDriverIndex(static_cast<unsigned int>(inputInfo.extendedAxis));
  event->SetAxisState(axisValue.value);
  return message;
}

@end
