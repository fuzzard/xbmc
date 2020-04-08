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

#import <Foundation/Foundation.h>
#import <GameController/GCController.h>

#pragma mark - objc interface

@interface CBPeripheralBusDarwinEmbedded : NSObject
{
  PERIPHERALS::CPeripheralBusDarwinEmbedded* parentClass;
  NSMutableArray* controllerArray;
  std::vector<kodi::addon::PeripheralEvent> m_digitalEvents;
  CCriticalSection m_eventMutex;
  BOOL dpadLeftPressed;
  BOOL dpadRightPressed;
  BOOL dpadUpPressed;
  BOOL dpadDownPressed;
}
- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)parentClass;
- (PERIPHERALS::PeripheralScanResults)GetInputDevices;
- (void)removeModeSwitchObserver;
- (void)addModeSwitchObserver;
- (void)controllerWasConnected:(NSNotification*)notification;
- (void)controllerWasDisconnected:(NSNotification*)notification;
- (std::vector<kodi::addon::PeripheralEvent>)GetButtonEvents;
- (void)registerChangeHandler:(GCController*)controller;
- (void)displayMessage:(NSString*)message controllerID:(NSString*)controllerID;
- (int)GetControllerType:(int)deviceID;
- (std::string)GetDeviceLocation:(int)deviceId;
- (void)controllerConnection:(GCController*)controller;
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
  m_peripheralDarwinEmbedded = new PeripheralBusDarwinEmbeddedWrapper;
  m_peripheralDarwinEmbedded->callbackClass =
      [[CBPeripheralBusDarwinEmbedded alloc] initWithName:this];
  m_bNeedsPolling = false;

  // get all currently connected input devices
  m_scanResults = GetInputDevices();
}

PERIPHERALS::CPeripheralBusDarwinEmbedded::~CPeripheralBusDarwinEmbedded()
{
  m_peripheralDarwinEmbedded->callbackClass = nil;
  delete m_peripheralDarwinEmbedded;
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

  int controllerType = [m_peripheralDarwinEmbedded->callbackClass GetControllerType:deviceId];

  if (controllerType == 1)
  {
    // Extended Gamepad - possible 15, power button on xbox controller recognized in testing
    joystick.SetButtonCount(14);
    joystick.SetAxisCount(2);
  }
  else if (controllerType == 2)
  {
    // Micro Gamepad
    joystick.SetButtonCount(6);
    joystick.SetAxisCount(0);
  }
  else
  {
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
  {
    CSingleLock lock(m_critSectionStates);
    events = [m_peripheralDarwinEmbedded->callbackClass GetButtonEvents];
    // Todo: Handle axes events
    //    GetAxisEvents(events);
  }
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
    //    for (auto& joystickState : m_joystickStates)
    //      joystickState.second.GetEvents(events);
    // Todo: Multiple controller events
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
        //        joystick->OnAxisMotion(event.DriverIndex(), event.AxisState());
        break;
      }
      default:
        break;
    }
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

- (bool)InitializeProperties:(PERIPHERALS::CPeripheral*)peripheral
{
  return true;
}

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
    peripheralScanResult.m_iVendorId = 0; //[controller.vendorName UTF8String];
    peripheralScanResult.m_iProductId = 0; //[controller.vendorName UTF8String];
    peripheralScanResult.m_mappedType = PERIPHERALS::PERIPHERAL_JOYSTICK;

    if (controller.extendedGamepad != nil)
    {
      peripheralScanResult.m_strDeviceName = "Extended Gamepad";
    }
    else if (controller.microGamepad != nil)
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

- (void)dealloc
{
  [self removeModeSwitchObserver];
}

- (instancetype)initWithName:(PERIPHERALS::CPeripheralBusDarwinEmbedded*)initClass
{
  CLog::Log(LOGINFO, "CBPeripheralBusDarwinEmbedded: init");
  [self addModeSwitchObserver];
  parentClass = initClass;

  controllerArray = [[NSMutableArray alloc] init];

  // Iterate through any pre-existing controller connections at startup to enable value handlers
  if ([[GCController controllers] count] > 0)
  {
    for (GCController* controller in [GCController controllers])
    {
      [self controllerConnection:controller];
    }
  }

  return self;
}

#pragma mark - Notificaton Observer

- (void)removeModeSwitchObserver
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GCControllerDidConnectNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GCControllerDidDisconnectNotification
                                                object:nil];
}

- (void)addModeSwitchObserver
{
  CLog::Log(LOGINFO, "CBPeripheralBusDarwinEmbedded: modeswitchObserver added");
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

  /* ToDo: Manage multiple player controllers
    switch ([[GCController controllers] count])
    {
      case 1:
        controller.playerIndex = GCControllerPlayerIndex1;
        break;
      case 2:
        controller.playerIndex = GCControllerPlayerIndex2;
        break;
      case 3:
        controller.playerIndex = GCControllerPlayerIndex3;
        break;
      case 4:
        controller.playerIndex = GCControllerPlayerIndex4;
     }
 */
  controller.playerIndex = GCControllerPlayerIndex1;
  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: input device with ID {} playerIndex {} added ",
            [controller.vendorName UTF8String], (unsigned long)controller.playerIndex);
  [controllerArray addObject:controller];
  parentClass->SetScanResults([self GetInputDevices]);
  parentClass->callOnDeviceAdded([self GetDeviceLocation:static_cast<int>(controller.playerIndex)]);

  // ToDo: changehandler only relevant to ios input at this stage
  [self registerChangeHandler:controller];
}

- (void)controllerWasDisconnected:(NSNotification*)notification
{
  // a controller was disconnected
  GCController* controller = (GCController*)notification.object;

  // remove the device from the Controller Array
  for (GCController* controlObj in controllerArray)
  {
    if ([controlObj isEqual:controller])
    {
      CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: input device \"{}\" removed",
                [controller.vendorName UTF8String]);
      controller.playerIndex = GCControllerPlayerIndexUnset;
      [controllerArray removeObject:controller];
      parentClass->callOnDeviceRemoved(
        [self GetDeviceLocation:static_cast<int>(controller.playerIndex)]);
      parentClass->SetScanResults([self GetInputDevices]);
      return;
    }
  }

  CLog::Log(LOGWARNING,
            "CPeripheralBusDarwinEmbedded: failed to remove input device {} Not Found ",
            [controller.vendorName UTF8String]);

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

- (void)registerChangeHandler:(GCController*)controller
{
  CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: registerChangeHandler");
  if (controller.extendedGamepad != nil)
  {
    CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: extendedGamepad changehandler added");
    // register block for input change detection
    GCExtendedGamepad* profile = controller.extendedGamepad;
    profile.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
      NSString* controllerID =
          [NSString stringWithFormat:@"%d", static_cast<int>(controller.playerIndex)];
      NSString* message = @"";
      CGPoint position = CGPointMake(0, 0);

      kodi::addon::PeripheralEvent newEvent = {};
      newEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));

      CSingleLock lock(m_eventMutex);

      // left trigger
      if (gamepad.leftTrigger == element)
      {
        message = @"Left Trigger";

        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(9);

        if (gamepad.leftTrigger.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // right trigger
      if (gamepad.rightTrigger == element)
      {
        message = @"Right Trigger";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(11);

        if (gamepad.rightTrigger.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // left shoulder button
      if (gamepad.leftShoulder == element)
      {
        message = @"Left Shoulder Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(8);

        if (gamepad.leftShoulder.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // right shoulder button
      if (gamepad.rightShoulder == element)
      {
        message = @"Right Shoulder Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(10);

        if (gamepad.rightShoulder.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // A button
      if (gamepad.buttonA == element)
      {
        message = @"A Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(4);

        if (gamepad.buttonA.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // B button
      if (gamepad.buttonB == element)
      {
        message = @"B Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(5);

        if (gamepad.buttonB.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // X button
      if (gamepad.buttonX == element)
      {
        message = @"X Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(6);

        if (gamepad.buttonX.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // Y button
      if (gamepad.buttonY == element)
      {
        message = @"Y Button";
        newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
        newEvent.SetDriverIndex(7);

        if (gamepad.buttonY.isPressed)
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          message = [message stringByAppendingString:@" Pressed"];
        }
        else
        {
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
          message = [message stringByAppendingString:@" Released"];
        }
      }
      // buttonMenu
      if (@available(iOS 13.0, tvOS 11.0, *))
      {
        if (gamepad.buttonMenu == element)
        {
          message = @"Menu Button";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(12);

          if (gamepad.buttonMenu.isPressed)
          {
            newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
            message = [message stringByAppendingString:@" Pressed"];
          }
          else
          {
            newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
            message = [message stringByAppendingString:@" Released"];
          }
        }
        // buttonOptions
        if (gamepad.buttonOptions == element)
        {
          message = @"Options Button";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(13);

          if (gamepad.buttonOptions.isPressed)
          {
            newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
            message = [message stringByAppendingString:@" Pressed"];
          }
          else
          {
            newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
            message = [message stringByAppendingString:@" Released"];
          }
        }
      }
      // d-pad
      if (gamepad.dpad == element)
      {
        if (gamepad.dpad.up.isPressed && !dpadUpPressed)
        {
          message = @"D-Pad Up Pressed";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(0);
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          dpadUpPressed = YES;
        }
        else if (!gamepad.dpad.up.isPressed)
        {
          if (dpadUpPressed)
          {
            message = @" D-Pad Up Released ";
            kodi::addon::PeripheralEvent newReleaseEvent = {};
            newReleaseEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
            newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
            newReleaseEvent.SetDriverIndex(0);
            newReleaseEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);

            m_digitalEvents.emplace_back(newReleaseEvent);
            dpadUpPressed = NO;
          }
        }
        if (gamepad.dpad.down.isPressed && !dpadDownPressed)
        {
          message = @"D-Pad Down Pressed";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(1);
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          dpadDownPressed = YES;
        }
        else if (!gamepad.dpad.down.isPressed)
        {
          if (dpadDownPressed)
          {
            message = @" D-Pad Down Released ";
            kodi::addon::PeripheralEvent newReleaseEvent = {};
            newReleaseEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
            newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
            newReleaseEvent.SetDriverIndex(1);
            newReleaseEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);

            m_digitalEvents.emplace_back(newReleaseEvent);
            dpadDownPressed = NO;
          }
        }
        if (gamepad.dpad.left.isPressed && !dpadLeftPressed)
        {
          message = @"D-Pad Left Pressed";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(2);
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          dpadLeftPressed = YES;
        }
        else if (!gamepad.dpad.left.isPressed)
        {
          if (dpadLeftPressed)
          {
            message = @" D-Pad Up Released ";
            kodi::addon::PeripheralEvent newReleaseEvent = {};
            newReleaseEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
            newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
            newReleaseEvent.SetDriverIndex(2);
            newReleaseEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);

            m_digitalEvents.emplace_back(newReleaseEvent);
            dpadLeftPressed = NO;
          }
        }
        if (gamepad.dpad.right.isPressed && !dpadRightPressed)
        {
          message = @"D-Pad Right Pressed";
          newEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
          newEvent.SetDriverIndex(3);
          newEvent.SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
          dpadRightPressed = YES;
        }
        else if (!gamepad.dpad.right.isPressed)
        {
          if (dpadRightPressed)
          {
            message = @" D-Pad Up Released ";
            kodi::addon::PeripheralEvent newReleaseEvent = {};
            newReleaseEvent.SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);
            newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
            newReleaseEvent.SetDriverIndex(3);
            newReleaseEvent.SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);

            m_digitalEvents.emplace_back(newReleaseEvent);
            dpadRightPressed = NO;
          }
        }
      }
      // left stick
      if (gamepad.leftThumbstick == element)
      {
        if (gamepad.leftThumbstick.up.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.yAxis.value];
        }
        if (gamepad.leftThumbstick.down.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.yAxis.value];
        }
        if (gamepad.leftThumbstick.left.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.xAxis.value];
        }
        if (gamepad.leftThumbstick.right.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.xAxis.value];
        }
        position =
            CGPointMake(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value);
      }
      // right stick
      if (gamepad.rightThumbstick == element)
      {
        if (gamepad.rightThumbstick.up.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.yAxis.value];
        }
        if (gamepad.rightThumbstick.down.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.yAxis.value];
        }
        if (gamepad.rightThumbstick.left.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.xAxis.value];
        }
        if (gamepad.rightThumbstick.right.isPressed)
        {
          message =
              [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.xAxis.value];
        }
        position =
            CGPointMake(gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value);
      }

      m_digitalEvents.emplace_back(newEvent);
      [self displayMessage:message controllerID:controllerID];
    };
  }
  else if (controller.microGamepad != nil)
  {
    CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: microGamepad not supported currently");
  }
}

- (int)GetControllerType:(int)deviceID
{
  // ToDo: arbitrary numbers change to an enum
  for (GCController* controller in controllerArray)
  {
    if (controller.playerIndex == deviceID)
    {
      if (controller.extendedGamepad != nil)
        return 1;
      else if (controller.microGamepad != nil)
        return 2;
    }
  }
  return 0;
}

- (std::string)GetDeviceLocation:(int)deviceId
{
  return StringUtils::Format("%s%d", DeviceLocationPrefix.c_str(), deviceId);
}

- (void)displayMessage:(NSString*)message controllerID:(NSString*)controllerID
{
  CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: inputhandler - ID {} - Action {}",
            [controllerID UTF8String], [message UTF8String]);
}

@end
